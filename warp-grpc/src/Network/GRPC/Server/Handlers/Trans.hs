{-# LANGUAGE ScopedTypeVariables #-}
{-# LANGUAGE DataKinds #-}
{-# LANGUAGE RankNTypes #-}
{-# LANGUAGE LambdaCase #-}
{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE TypeFamilies #-}
{-# LANGUAGE CPP #-}
module Network.GRPC.Server.Handlers.Trans where

import           Control.Concurrent.Async (concurrently)
import           Control.Monad (void, (>=>))
import           Control.Monad.IO.Class
import           Data.Binary.Get (pushChunk, Decoder(..))
import qualified Data.ByteString.Char8 as ByteString
import           Data.ByteString.Char8 (ByteString)
import           Data.ByteString.Lazy (toStrict)
import           Network.GRPC.HTTP2.Encoding
import           Network.GRPC.HTTP2.Types (path, GRPCStatus(..), GRPCStatusCode(..))
#if MIN_VERSION_wai(3,2,2)
import           Network.Wai (Request, getRequestBodyChunk, strictRequestBody)
#else
import           Network.Wai (Request, requestBody, strictRequestBody)
#endif

#if MIN_VERSION_base(4,11,0)
#else
import Data.Monoid ((<>))
#endif

import Network.GRPC.Server.Wai (WaiHandler, ServiceHandler(..), closeEarly)
import Data.IORef

#if !MIN_VERSION_wai(3,2,2)
getRequestBodyChunk :: Request -> IO ByteString
getRequestBodyChunk = requestBody
#endif

-- | Handy type to refer to Handler for 'unary' RPCs handler.
type UnaryHandler m i o = Request -> i -> m o

-- | Handy type for 'server-streaming' RPCs.
--
-- We expect an implementation to:
-- - read the input request
-- - return an initial state and an state-passing action that the server code will call to fetch the output to send to the client (or close an a Nothing)
-- See 'ServerStream' for the type which embodies these requirements.
type ServerStreamHandler m i o a = Request -> i -> m (a, ServerStream m o a)

newtype ServerStream m o a = ServerStream {
    serverStreamNext :: a -> m (Maybe (a, o))
  }

-- | Handy type for 'client-streaming' RPCs.
--
-- We expect an implementation to:
-- - acknowledge a the new client stream by returning an initial state and two functions:
-- - a state-passing handler for new client message
-- - a state-aware handler for answering the client when it is ending its stream
-- See 'ClientStream' for the type which embodies these requirements.
type ClientStreamHandler m i o a = Request -> m (a, ClientStream m i o a)

data ClientStream m i o a = ClientStream {
    clientStreamHandler   :: a -> i -> m a
  , clientStreamFinalizer :: a -> m o
  }

-- | Handy type for 'bidirectional-streaming' RPCs.
--
-- We expect an implementation to:
-- - acknowlege a new bidirection stream by returning an initial state and one functions:
-- - a state-passing function that returns a single action step
-- The action may be to
-- - stop immediately
-- - wait and handle some input with a callback and a finalizer (if the client closes the stream on its side) that may change the state
-- - return a value and a new state
--
-- There is no way to stop locally (that would mean sending HTTP2 trailers) and
-- keep receiving messages from the client.
type BiDiStreamHandler m i o a = Request -> m (a, BiDiStream m i o a)

data BiDiStep m i o a
  = Abort
  | WaitInput !(a -> i -> m a) !(a -> m a)
  | WriteOutput !a o

newtype BiDiStream m i o a = BiDiStream {
    bidirNextStep :: a -> m (BiDiStep m i o a)
  }

-- | Construct a handler for handling a unary RPC.
unary
  :: (MonadIO m, GRPCInput r i, GRPCOutput r o)
  => (forall x. m x -> IO x)
  -> r
  -> UnaryHandler m i o
  -> ServiceHandler
unary f rpc handler =
    ServiceHandler (path rpc) (handleUnary f rpc handler)

-- | Construct a handler for handling a server-streaming RPC.
serverStream
  :: (MonadIO m, GRPCInput r i, GRPCOutput r o)
  => (forall x. m x -> IO x)
  -> r
  -> ServerStreamHandler m i o a
  -> ServiceHandler
serverStream f rpc handler =
    ServiceHandler (path rpc) (handleServerStream f rpc handler)

-- | Construct a handler for handling a client-streaming RPC.
clientStream
  :: (MonadIO m, GRPCInput r i, GRPCOutput r o)
  => (forall x. m x -> IO x)
  -> r
  -> ClientStreamHandler m i o a
  -> ServiceHandler
clientStream f rpc handler =
    ServiceHandler (path rpc) (handleClientStream f rpc handler)

-- | Construct a handler for handling a bidirectional-streaming RPC.
bidiStream
  :: (MonadIO m, GRPCInput r i, GRPCOutput r o)
  => (forall x. m x -> IO x)
  -> r
  -> BiDiStreamHandler m i o a
  -> ServiceHandler
bidiStream f rpc handler =
    ServiceHandler (path rpc) (handleBiDiStream f rpc handler)

-- | Construct a handler for handling a bidirectional-streaming RPC.
generalStream
  :: (MonadIO m, GRPCInput r i, GRPCOutput r o)
  => (forall x. m x -> IO x)
  -> r
  -> GeneralStreamHandler m i o a b
  -> ServiceHandler
generalStream f rpc handler =
    ServiceHandler (path rpc) (handleGeneralStream f rpc handler)

explicitStream
  :: (MonadIO m, GRPCInput r i, GRPCOutput r o)
  => (forall x. m x -> IO x)
  -> r
  -> ExplicitStreamHandler m i o
  -> ServiceHandler
explicitStream f rpc handler =
    ServiceHandler (path rpc) (handleExplicitStream f rpc handler)

-- | Handle unary RPCs.
handleUnary
  :: (MonadIO m, GRPCInput r i, GRPCOutput r o)
  => (forall x. m x -> IO x)
  -> r
  -> UnaryHandler m i o
  -> WaiHandler
handleUnary f rpc handler decoding encoding req write flush = f $
    handleRequestChunksLoop (decodeInput rpc $ _getDecodingCompression decoding)
                            handleMsg handleEof nextChunk
  where
    nextChunk = toStrict <$> strictRequestBody req
    handleMsg = errorOnLeftOver (handler req >=> liftIO . reply)
    handleEof = closeEarly (GRPCStatus INVALID_ARGUMENT "early end of request body")
    reply msg = write (encodeOutput rpc (_getEncodingCompression encoding) msg) >> flush

-- | Handle Server-Streaming RPCs.
handleServerStream
  :: (MonadIO m, GRPCInput r i, GRPCOutput r o)
  => (forall x. m x -> IO x)
  -> r
  -> ServerStreamHandler m i o a
  -> WaiHandler
handleServerStream f rpc handler decoding encoding req write flush = f $
    handleRequestChunksLoop (decodeInput rpc $ _getDecodingCompression decoding)
                            handleMsg handleEof nextChunk
  where
    nextChunk = toStrict <$> strictRequestBody req
    handleMsg = errorOnLeftOver (handler req >=> replyN)
    handleEof = closeEarly (GRPCStatus INVALID_ARGUMENT "early end of request body")
    replyN (v, sStream) = do
        let go v1 = serverStreamNext sStream v1 >>= \case
                Just (v2, msg) -> do
                    liftIO $ write (encodeOutput rpc (_getEncodingCompression encoding) msg)
                    liftIO flush
                    go v2
                Nothing -> pure ()
        go v

-- | Handle Client-Streaming RPCs.
handleClientStream
  :: forall m r i o a.
     (MonadIO m, GRPCInput r i, GRPCOutput r o)
  => (forall x. m x -> IO x)
  -> r
  -> ClientStreamHandler m i o a
  -> WaiHandler
handleClientStream f rpc handler0 decoding encoding req write flush =
    f $ handler0 req >>= go
  where
    go :: (a, ClientStream m i o a) -> m ()
    go (v, cStream) = handleRequestChunksLoop (decodeInput rpc $ _getDecodingCompression decoding)
                                              (handleMsg v) (handleEof v) nextChunk
      where
        nextChunk = getRequestBodyChunk req
        handleMsg v0 dat msg = clientStreamHandler cStream v0 msg >>= \v1 -> loop dat v1
        handleEof v0 = clientStreamFinalizer cStream v0 >>= reply
        reply msg = do
          liftIO $ write (encodeOutput rpc (_getEncodingCompression encoding) msg)
          liftIO flush
        loop chunk v1 = handleRequestChunksLoop
                          (flip pushChunk chunk $ decodeInput rpc (_getDecodingCompression decoding))
                          (handleMsg v1) (handleEof v1) nextChunk

-- | Handle Bidirectional-Streaming RPCs.
handleBiDiStream
  :: forall m r i o a.
     (MonadIO m, GRPCInput r i, GRPCOutput r o)
  => (forall x. m x -> IO x)
  -> r
  -> BiDiStreamHandler m i o a
  -> WaiHandler
handleBiDiStream f rpc handler0 decoding encoding req write flush =
    f $ handler0 req >>= go ""
  where
    nextChunk = getRequestBodyChunk req
    reply msg = write (encodeOutput rpc (_getEncodingCompression encoding) msg) >> flush
    go :: ByteString -> (a, BiDiStream m i o a) -> m ()
    go chunk (v0, bStream) = do
        let cont dat v1 = go dat (v1, bStream)
        step <- bidirNextStep bStream v0
        case step of
            WaitInput handleMsg handleEof ->
                handleRequestChunksLoop (flip pushChunk chunk
                                         $ decodeInput rpc
                                         $ _getDecodingCompression decoding)
                                        (\dat msg -> handleMsg v0 msg >>= cont dat)
                                        (handleEof v0 >>= cont "")
                                        nextChunk
            WriteOutput v1 msg -> do
                liftIO $ reply msg
                cont "" v1
            Abort -> return ()

-- | A GeneralStreamHandler combining server and client asynchronous streams.
type GeneralStreamHandler m i o a b =
    Request -> m (a, IncomingStream m i a, b, OutgoingStream m o b)

-- | Pair of handlers for reacting to incoming messages.
data IncomingStream m i a = IncomingStream {
    incomingStreamHandler   :: a -> i -> m a
  , incomingStreamFinalizer :: a -> m ()
  }

-- | Handler to decide on the next message (if any) to return.
newtype OutgoingStream m o a = OutgoingStream {
    outgoingStreamNext  :: a -> m (Maybe (a, o))
  }

-- | Handler for the somewhat general case where two threads behave concurrently:
-- - one reads messages from the client
-- - one returns messages to the client
handleGeneralStream
  :: forall m r i o a b.
     (MonadIO m, GRPCInput r i, GRPCOutput r o)
  => (forall x. m x -> IO x)
  -> r
  -> GeneralStreamHandler m i o a b
  -> WaiHandler
handleGeneralStream f rpc handler0 decoding encoding req write flush = void $
    f $ handler0 req >>= go
  where
    newDecoder = decodeInput rpc $ _getDecodingCompression decoding
    nextChunk = getRequestBodyChunk req
    reply msg = write (encodeOutput rpc (_getEncodingCompression encoding) msg) >> flush

    go :: (a, IncomingStream m i a, b, OutgoingStream m o b) -> m (a, b)
    go (in0, instream, out0, outstream) = liftIO $ concurrently
        (f $ incomingLoop newDecoder in0 instream)
        (f $ replyLoop out0 outstream)

    replyLoop :: b -> OutgoingStream m o b -> m b
    replyLoop v0 sstream@(OutgoingStream next) =
        next v0 >>= \case
            Nothing          -> return v0
            (Just (v1, msg)) -> liftIO (reply msg) >> replyLoop v1 sstream

    incomingLoop :: Decoder (Either String i) -> a -> IncomingStream m i a -> m a
    incomingLoop decode v0 cstream = do
        let handleMsg dat msg = do
                v1 <- incomingStreamHandler cstream v0 msg
                incomingLoop (pushChunk newDecoder dat) v1 cstream
        let handleEof = incomingStreamFinalizer cstream v0 >> pure v0
        handleRequestChunksLoop decode handleMsg handleEof nextChunk

type ExplicitStreamHandler m i o =
    Request -> m (Maybe i) -> (o -> m ()) -> m ()

handleExplicitStream
  :: forall m r i o.
     (MonadIO m, GRPCInput r i, GRPCOutput r o)
  => (forall x. m x -> IO x)
  -> r
  -> ExplicitStreamHandler m i o
  -> WaiHandler
handleExplicitStream f rpc handler0 decoding encoding req write flush = do
    currentDecoderVar <- newIORef newDecoder
    f $ handler0 req (liftIO $ getNextMsg currentDecoderVar) (liftIO . reply)
  where
    newDecoder = decodeInput rpc $ _getDecodingCompression decoding
    nextChunk = getRequestBodyChunk req
    reply msg = write (encodeOutput rpc (_getEncodingCompression encoding) msg) >> flush

    getNextMsg :: IORef (Decoder (Either String i)) -> IO (Maybe i)
    getNextMsg currentDecoderVar = do
      currentDecoder <- readIORef currentDecoderVar
      let handleMsg dat msg = do
            writeIORef currentDecoderVar $! pushChunk newDecoder dat
            return (Just msg)
      handleRequestChunksLoop currentDecoder handleMsg (return Nothing) nextChunk

-- | Helpers to consume input in chunks.
handleRequestChunksLoop
  :: (MonadIO m)
  => Decoder (Either String a)
  -- ^ Message decoder.
  -> (ByteString -> a -> m b)
  -- ^ Handler for a single message.
  -- The ByteString corresponds to leftover data.
  -> m b
  -- ^ Handler for handling end-of-streams.
  -> IO ByteString
  -- ^ Action to retrieve the next chunk.
  -> m b
{-# INLINEABLE handleRequestChunksLoop #-}
handleRequestChunksLoop decoder handleMsg handleEof nextChunk =
    case decoder of
        (Done unusedDat _ (Right val)) ->
            handleMsg unusedDat val
        (Done _ _ (Left err)) ->
            closeEarly (GRPCStatus INVALID_ARGUMENT (ByteString.pack $ "done-error: " ++ err))
        (Fail _ _ err)         ->
            closeEarly (GRPCStatus INVALID_ARGUMENT (ByteString.pack $ "fail-error: " ++ err))
        partial@(Partial _)    -> do
            chunk <- liftIO nextChunk
            if ByteString.null chunk
            then
                handleEof
            else
                handleRequestChunksLoop (pushChunk partial chunk) handleMsg handleEof nextChunk

-- | Combinator around message handler to error on left overs.
--
-- This combinator ensures that, unless for client stream, an unparsed piece of
-- data with a correctly-read message is treated as an error.
errorOnLeftOver :: MonadIO m => (a -> m b) -> ByteString -> a -> m b
errorOnLeftOver f rest
  | ByteString.null rest = f
  | otherwise            = const $ do
     liftIO (putStrLn "left-over")
     closeEarly (GRPCStatus INVALID_ARGUMENT ("left-overs: " <> rest))
