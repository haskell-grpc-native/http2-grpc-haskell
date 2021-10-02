{-# LANGUAGE BangPatterns        #-}
{-# LANGUAGE DataKinds           #-}
{-# LANGUAGE FlexibleContexts    #-}
{-# LANGUAGE LambdaCase          #-}
{-# LANGUAGE OverloadedStrings   #-}
{-# LANGUAGE PackageImports      #-}
{-# LANGUAGE ScopedTypeVariables #-}
{-# LANGUAGE TypeFamilies        #-}

-- | A module adding support for gRPC over HTTP2.
--
-- This module provides helpers to encode gRPC queries on top of HTTP2 client.
--
-- The helpers we provide for streaming RPCs ('streamReply', 'streamRequest',
-- 'steppedBiDiStream') are a subset of what gRPC allows: the gRPC definition
-- of streaming RPCs offers a large amount of valid behaviors regarding timing
-- of headers, trailers, and end of streams.
--
-- The limitations of these functions should be clear from the type signatures.
-- But in general, the design is to only allow synchronous state machines. Such
-- state-machines cannot immediately react to server-sent messages but must
-- wait for the client code to poll for some server-sent information.  In
-- short, these handlers prevents programs from observing intermediary steps
-- which may be valid applications by gRPC standards. Simply put, it is not
-- possibly to simultaneously wait for some information from the server and
-- send some information.
-- For instance, in a client-streaming RPC, the server is allowed to send
-- trailers at any time, even before receiving any input message. The
-- 'streamRequest' functions disallows reading trailers until the client code
-- is done sending requests.
-- A result from this design choice is to offer a simple programming surface
-- for the most common use cases. Further, these simple state-machines require
-- little runtime overhead.
--
-- A more general handler 'generalHandler' is provided which runs two thread in
-- parallel. This handler allows to send an receive messages concurrently using
-- one loop each, which allows to circumvent the limitations of the above
-- handlers (but at a cost: complexity and threading overhead). It also means
-- that a sending action may be stuck indefinitely on flow-control and cannot
-- be cancelled without killing the 'RPC' thread. You see where we are going:
-- the more elaborate the semantics, the more a programmer has to think.
--
-- Though, all hope of expressing wacky application semantics is not lost: it
-- is always possible to write its own 'RPC' function.  Writing one's own 'RPC'
-- function allows to leverage the specific semantics of the RPC call to save
-- some overhead (much like the three above streaming helpers assume a simple
-- behavior from the server). Hence, it is generally a good idea to take
-- inspiration from the existing RPC functions and learn how to write one.
module Network.GRPC.Client (
  -- * Building blocks.
    RPCCall(..)
  , CIHeaderList
  , Authority
  , Timeout(..)
  , open
  , RawReply
  -- * Helpers
  , singleRequest
  , streamReply
  , streamRequest
  , steppedBiDiStream
  , generalHandler
  , CompressMode(..)
  , StreamDone(..)
  , BiDiStep(..)
  , RunBiDiStep
  , HandleMessageStep
  , HandleTrailersStep
  , IncomingEvent(..)
  , OutgoingEvent(..)
  -- * Errors.
  , InvalidState(..)
  , StreamReplyDecodingError(..)
  , UnallowedPushPromiseReceived(..)
  , InvalidParse(..)
  -- * Compression of individual messages.
  , Compression
  , gzip
  , uncompressed
  -- * Re-exports.
  , HeaderList
  ) where

import Control.Concurrent.Async.Lifted (concurrently)
import Control.Exception (SomeException, Exception(..), throwIO)
import Control.Monad.IO.Class (liftIO)
import Data.ByteString.Lazy (toStrict)
import Data.Binary.Builder (toLazyByteString)
import Data.Binary.Get (Decoder(..), pushChunk, pushEndOfInput)
import qualified Data.ByteString.Char8 as ByteString
import Data.ByteString.Char8 (ByteString)
import Data.CaseInsensitive (CI)
import qualified Data.CaseInsensitive as CI
import Data.Monoid ((<>))

import Network.GRPC.HTTP2.Types
import Network.GRPC.HTTP2.Encoding
import Network.HTTP2
import Network.HPACK
import "http2-client" Network.HTTP2.Client hiding (next)
import Network.HTTP2.Client.Helpers

type CIHeaderList = [(CI ByteString, ByteString)]

-- | A reply.
--
-- This reply object contains a lot of information because a single gRPC call
-- returns a lot of data. A future version of the library will have a proper
-- data structure with properly named-fields on the reply object.
--
-- For now, remember:
-- - 1st item: initial HTTP2 response
-- - 2nd item: second (trailers) HTTP2 response
-- - 3rd item: proper gRPC answer
type RawReply a = Either ErrorCode (CIHeaderList, Maybe CIHeaderList, Either String a)

-- | gRPC disables HTTP2 push-promises.
--
-- If a server attempts to send push-promises, this exception will be raised.
data UnallowedPushPromiseReceived = UnallowedPushPromiseReceived deriving Show
instance Exception UnallowedPushPromiseReceived where

-- | http2-client handler for push promise.
throwOnPushPromise :: PushPromiseHandler
throwOnPushPromise _ _ _ _ _ = lift $ throwIO UnallowedPushPromiseReceived

-- | Wait for an RPC reply.
waitReply
  :: (GRPCOutput r o)
  => r -> Decoding -> Http2Stream -> IncomingFlowControl
  -> ClientIO (RawReply o)
waitReply rpc decoding stream flowControl =
    format . fromStreamResult <$> waitStream stream flowControl throwOnPushPromise
  where
    decompress = _getDecodingCompression decoding
    format rsp = do
       (hdrs, dat, trls) <- rsp
       let hdrs2 = headerstoCIHeaders hdrs
       let trls2 = fmap headerstoCIHeaders trls
       let res =
             -- presence of a message indicate an error
             -- TODO: double check this is true in general
             case lookup grpcMessageH hdrs2 of
               Nothing     -> fromDecoder $ pushEndOfInput
                                          $ flip pushChunk dat
                                          $ decodeOutput rpc decompress
               Just errMsg -> Left $ ByteString.unpack errMsg

       return (hdrs2, trls2, res)

headerstoCIHeaders :: HeaderList -> CIHeaderList
headerstoCIHeaders hdrs = [(CI.mk k, v) | (k,v) <- hdrs]

-- | Exception raised when a ServerStreaming RPC results in a decoding
-- error.
newtype StreamReplyDecodingError = StreamReplyDecodingError String deriving Show
instance Exception StreamReplyDecodingError where

-- | Exception raised when a ServerStreaming RPC results in an invalid
-- state machine.
newtype InvalidState = InvalidState String deriving Show
instance Exception InvalidState where

-- | Newtype helper used to uniformize all type of streaming modes when
-- passing arguments to the 'open' call.
data RPCCall r a = RPCCall {
    rpcFromCall :: r
  , runRPC :: Http2Client -> Http2Stream
           -> IncomingFlowControl -> OutgoingFlowControl
           -> Encoding -> Decoding -> ClientIO a
  }

-- | Main handler to perform gRPC calls to a service.
open :: (IsRPC r)
     => Http2Client
     -- ^ A connected HTTP2 client.
     -> Authority
     -- ^ The HTTP2-Authority portion of the URL (e.g., "dicioccio.fr:7777").
     -> HeaderList
     -- ^ A set of HTTP2 headers (e.g., for adding authentication headers).
     -> Timeout
     -- ^ Timeout in seconds.
     -> Encoding
     -- ^ Compression used for encoding.
     -> Decoding
     -- ^ Compression allowed for decoding
     -> RPCCall r a
     -- ^ The actual RPC handler.
     -> ClientIO (Either TooMuchConcurrency a)
open conn authority extraheaders timeout encoding decoding call = do
    let rpc = rpcFromCall call
    let compress = _getEncodingCompression encoding
    let decompress = _getDecodingCompression decoding
    let request = [ (":method", "POST")
                  , (":scheme", "http")
                  , (":authority", authority)
                  , (":path", path rpc) 
                  , (CI.original grpcTimeoutH, showTimeout timeout)
                  , (CI.original grpcEncodingH, grpcCompressionHV compress)
                  , (CI.original grpcAcceptEncodingH, mconcat [grpcAcceptEncodingHVdefault, ",", grpcCompressionHV decompress])
                  , ("content-type", grpcContentTypeHV)
                  , ("te", "trailers")
                  ] <> extraheaders
    withHttp2Stream conn $ \stream ->
        let
            initStream = headers stream request setEndHeader
            handler isfc osfc = runRPC call conn stream isfc osfc encoding decoding
        in StreamDefinition initStream handler

-- | gRPC call for Server Streaming.
streamReply
  :: (GRPCInput r i, GRPCOutput r o)
  => r
  -- ^ RPC to call.
  -> a
  -- ^ An initial state.
  -> i
  -- ^ The input.
  -> (a -> HeaderList -> o -> ClientIO a)
  -- ^ A state-passing handler that is called with the message read.
  -> RPCCall r (a, HeaderList, HeaderList)
streamReply rpc v0 req handler = RPCCall rpc $ \conn stream isfc osfc encoding decoding ->
    let {
        loop v1 decode hdrs = _waitEvent stream >>= \case
            StreamPushPromiseEvent {} ->
                lift $ throwIO UnallowedPushPromiseReceived
            StreamHeadersEvent _ trls ->
                return (v1, hdrs, trls)
            StreamErrorEvent _ _ ->
                lift $ throwIO (InvalidState "stream error")
            StreamDataEvent _ dat -> do
                liftIO $ _addCredit isfc (ByteString.length dat)
                _ <- liftIO $ _consumeCredit isfc (ByteString.length dat)
                _ <- _updateWindow isfc
                handleAllChunks decoding v1 hdrs decode dat loop
    } in do
        let ocfc = _outgoingFlowControl conn
        let decompress = _getDecodingCompression decoding
        sendSingleMessage rpc req encoding setEndStream conn ocfc stream osfc
        _waitEvent stream >>= \case
            StreamHeadersEvent _ hdrs ->
                loop v0 (decodeOutput rpc decompress) hdrs
            _                         ->
                lift $ throwIO (InvalidState "no headers")
  where
    handleAllChunks decoding v1 hdrs decode dat exitLoop =
       case pushChunk decode dat of
           Done unusedDat _ (Right val) -> do
               v2 <- handler v1 hdrs val
               let decompress = _getDecodingCompression decoding
               handleAllChunks decoding v2 hdrs (decodeOutput rpc decompress) unusedDat exitLoop
           Done _ _ (Left err) ->
               lift $ throwIO (StreamReplyDecodingError $ "done-error: " ++ err)
           Fail _ _ err ->
               lift $ throwIO (StreamReplyDecodingError $ "fail-error: " ++ err)
           partial@(Partial _)    ->
               exitLoop v1 partial hdrs

data StreamDone = StreamDone

data CompressMode = Compressed | Uncompressed

-- | gRPC call for Client Streaming.
streamRequest
  :: (GRPCInput r i, GRPCOutput r o)
  => r
  -- ^ RPC to call.
  -> a
  -- ^ An initial state.
  -> (a -> ClientIO (a, Either StreamDone (CompressMode, i)))
  -- ^ A state-passing action to retrieve the next message to send to the server.
  -> RPCCall r (a, RawReply o)
streamRequest rpc v0 handler = RPCCall  rpc$ \conn stream isfc streamFlowControl encoding decoding ->
    let ocfc = _outgoingFlowControl conn
        go v1 = do
            (v2, nextEvent) <- handler v1
            case nextEvent of
                Right (doCompress, msg) -> do
                    let compress = case doCompress of
                            Compressed -> _getEncodingCompression encoding
                            Uncompressed -> uncompressed
                    sendSingleMessage rpc msg (Encoding compress) id
                                      conn ocfc stream streamFlowControl
                    go v2
                Left _ -> do
                    sendData conn stream setEndStream ""
                    reply <- waitReply rpc decoding stream isfc
                    pure (v2, reply)
    in go v0

-- | Serialize and send a single message.
sendSingleMessage
  :: (GRPCInput r i)
  => r
  -> i
  -> Encoding
  -> FlagSetter
  -> Http2Client
  -> OutgoingFlowControl
  -> Http2Stream
  -> OutgoingFlowControl
  -> ClientIO ()
sendSingleMessage rpc msg encoding flagMod conn connectionFlowControl stream streamFlowControl = do
    let compress = _getEncodingCompression encoding
    let goUpload dat = do
            let !wanted = ByteString.length dat
            gotStream <- _withdrawCredit streamFlowControl wanted
            got       <- _withdrawCredit connectionFlowControl gotStream
            liftIO $ _receiveCredit streamFlowControl (gotStream - got)
            if got == wanted
            then
                sendData conn stream flagMod dat
            else do
                sendData conn stream id (ByteString.take got dat)
                goUpload (ByteString.drop got dat)
    goUpload . toStrict . toLazyByteString . encodeInput rpc compress $ msg

-- | gRPC call for an unary request.
singleRequest
  :: (GRPCInput r i, GRPCOutput r o)
  => r
  -- ^ RPC to call.
  -> i
  -- ^ RPC's input.
  -> RPCCall r (RawReply o)
singleRequest rpc msg = RPCCall rpc $ \conn stream isfc osfc encoding decoding -> do
    let ocfc = _outgoingFlowControl conn
    sendSingleMessage rpc msg encoding setEndStream conn ocfc stream osfc
    waitReply rpc decoding stream isfc

-- | Handler for received message.
type HandleMessageStep i o a = HeaderList -> a -> o -> ClientIO a
-- | Handler for received trailers.
type HandleTrailersStep a = HeaderList -> a -> HeaderList -> ClientIO a

data BiDiStep i o a =
    Abort
  -- ^ Finalize and return the current state.
  | SendInput !CompressMode !i
  -- ^ Sends a single message.
  | WaitOutput (HandleMessageStep i o a) (HandleTrailersStep a)
  -- ^ Wait for information from the server, handlers can modify the state.

-- | State-based function.
type RunBiDiStep s meth a = a -> ClientIO (a, BiDiStep s meth a)

-- | gRPC call for a stepped bidirectional stream.
--
-- This helper limited.
--
-- See 'BiDiStep' and 'RunBiDiStep' to understand the type of programs one can
-- write with this function.
steppedBiDiStream
  :: (GRPCInput r i, GRPCOutput r o)
  => r
  -- ^ RPC to call.
  -> a
  -- ^ An initial state.
  -> RunBiDiStep i o a
  -- ^ The program.
  -> RPCCall r a
steppedBiDiStream rpc v0 handler = RPCCall rpc $ \conn stream isfc streamFlowControl encoding decoding ->
    let ocfc = _outgoingFlowControl conn
        decompress = _getDecodingCompression decoding
        newDecoder = decodeOutput rpc decompress

        goStep _ _ (v1, Abort) = do
            sendData conn stream setEndStream ""
            pure v1
        goStep hdrs decode (v1, SendInput doCompress msg) = do
            let compress = case doCompress of
                    Compressed -> _getEncodingCompression encoding
                    Uncompressed -> uncompressed
            sendSingleMessage rpc msg (Encoding compress) id conn ocfc stream streamFlowControl
            handler v1 >>= goStep hdrs decode
        goStep jhdrs@(Just hdrs) decode unchanged@(v1, WaitOutput handleMsg handleEof) =
            _waitEvent stream >>= \case
                StreamPushPromiseEvent {} ->
                    lift $ throwIO UnallowedPushPromiseReceived
                StreamHeadersEvent _ trls -> do
                    v2 <- handleEof hdrs v1 trls
                    -- TODO: consider failing the decoder here
                    handler v2 >>= goStep jhdrs newDecoder
                StreamErrorEvent _ _ ->
                    lift $ throwIO (InvalidState "stream error")
                StreamDataEvent _ dat -> do
                    liftIO $ _addCredit isfc (ByteString.length dat)
                    _ <- liftIO $ _consumeCredit isfc (ByteString.length dat)
                    _ <- _updateWindow isfc
                    case pushChunk decode dat of
                        Done unusedDat _ (Right val) -> do
                            v2 <- handleMsg hdrs v1 val
                            handler v2 >>= goStep jhdrs (pushChunk newDecoder unusedDat)
                        Done _ _ (Left err) ->
                            lift $ throwIO $ InvalidParse $ "done-err: " ++ err
                        Fail _ _ err ->
                            lift $ throwIO $ InvalidParse $ "done-fail: " ++ err
                        partial@(Partial _) ->
                            goStep jhdrs partial unchanged
        goStep Nothing decode unchanged =
            _waitEvent stream >>= \case
                StreamHeadersEvent _ hdrs ->
                   goStep (Just hdrs) decode unchanged
                _ ->
                   lift $ throwIO (InvalidState "no headers")

    in handler v0 >>= goStep Nothing newDecoder

-- | Exception raised when a BiDiStreaming RPC results in an invalid
-- parse.
newtype InvalidParse = InvalidParse String deriving Show
instance Exception InvalidParse where

-- | An event for the incoming loop of 'generalHandler'.
data IncomingEvent o a =
    Headers HeaderList
  -- ^ The server sent some initial metadata with the headers.
  | RecvMessage o
  -- ^ The server send a message.
  | Trailers HeaderList
  -- ^ The server send final metadata (the loop stops).
  | Invalid SomeException
  -- ^ Something went wrong (the loop stops).

-- | An event for the outgoing loop of 'generalHandler'.
data OutgoingEvent i b =
    Finalize
  -- ^ The client is done with the RPC (the loop stops).
  | SendMessage CompressMode i
  -- ^ The client sends a message to the server.

-- | General RPC handler for decorrelating the handling of received
-- headers/trailers from the sending of messages.
--
-- There is no constraints on the stream-arity of the RPC. It requires a bit of
-- viligence to avoid breaking the gRPC semantics but this one is easy to pay
-- attention to.
--
-- This handler runs two loops 'concurrently':
-- One loop accepts and chunks messages from the HTTP2 stream, then return events
-- and stops on Trailers or Invalid. The other loop waits for messages to send to
-- the server or finalize and returns.
generalHandler 
  :: (GRPCInput r i, GRPCOutput r o)
  => r
  -- ^ RPC to call.
  -> a
  -- ^ An initial state for the incoming loop.
  -> (a -> IncomingEvent o a -> ClientIO a)
  -- ^ A state-passing function for the incoming loop.
  -> b
  -- ^ An initial state for the outgoing loop.
  -> (b -> ClientIO (b, OutgoingEvent i b))
  -- ^ A state-passing function for the outgoing loop.
  -> RPCCall r (a,b)
generalHandler rpc v0 handle w0 next = RPCCall rpc $ \conn stream isfc osfc encoding decoding ->
    go conn stream isfc osfc encoding decoding
  where
    go conn stream isfc osfc encoding decoding =
        concurrently (incomingLoop Nothing newDecoder v0) (outGoingLoop w0)
      where
        ocfc = _outgoingFlowControl conn
        newDecoder = decodeOutput rpc decompress
        decompress = _getDecodingCompression decoding
        outGoingLoop v1 = do
             (v2, event) <- next v1
             case event of
                 Finalize -> do
                    sendData conn stream setEndStream ""
                    return v2
                 SendMessage doCompress msg -> do
                    let compress = case doCompress of
                            Compressed -> _getEncodingCompression encoding
                            Uncompressed -> uncompressed
                    sendSingleMessage rpc msg (Encoding compress) id conn ocfc stream osfc
                    outGoingLoop v2
        incomingLoop Nothing decode v1 =
                _waitEvent stream >>= \case
                    StreamHeadersEvent _ hdrs ->
                       handle v1 (Headers hdrs) >>= incomingLoop (Just hdrs) decode
                    _ ->
                       handle v1 (Invalid $ toException $ InvalidState "no headers")
        incomingLoop jhdrs decode v1 =
            _waitEvent stream >>= \case
                StreamHeadersEvent _ hdrs ->
                    handle v1 (Trailers hdrs)
                StreamDataEvent _ dat -> do
                    liftIO $ _addCredit isfc (ByteString.length dat)
                    _ <- liftIO $ _consumeCredit isfc (ByteString.length dat)
                    _ <- _updateWindow isfc
                    case pushChunk decode dat of
                        Done unusedDat _ (Right val) ->
                            handle v1 (RecvMessage val) >>= incomingLoop jhdrs (pushChunk newDecoder unusedDat)
                        partial@(Partial _) ->
                            incomingLoop jhdrs partial v1
                        Done _ _ (Left err) ->
                            handle v1 (Invalid $ toException $ InvalidParse $ "invalid-done-parse: " ++ err)
                        Fail _ _ err ->
                            handle v1 (Invalid $ toException $ InvalidParse $ "invalid-parse: " ++ err)
                StreamPushPromiseEvent {} ->
                    handle v1 (Invalid $ toException UnallowedPushPromiseReceived)
                StreamErrorEvent {} ->
                    handle v1 (Invalid $ toException $ InvalidState "stream error")
