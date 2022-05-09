{-# LANGUAGE DataKinds #-}
{-# LANGUAGE DeriveGeneric #-}
{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE NumericUnderscores #-}
{-# LANGUAGE PackageImports #-}
module BenchTool where


import Data.ByteString (ByteString)
import qualified Data.ByteString.Char8 as ByteString
import Data.String (fromString)
import Data.Maybe (fromMaybe)
import qualified Data.Text as Text
import Control.Monad (void, replicateM)
import Control.Monad.IO.Class (liftIO)
import Options.Generic
import Control.Concurrent.Async.Lifted (replicateConcurrently)
import Network.GRPC.HTTP2.Encoding as Encoding

-- client
import Network.GRPC.Client (open, singleRequest, streamReply, streamRequest, Timeout(..), StreamDone(..), CompressMode(..))
import qualified "http2-client" Network.HTTP2.Client as Client
import qualified Network.GRPC.Client.Helpers as Client

-- server
import qualified Network.Wai.Handler.WarpTLS as WarpTLS
import qualified Network.Wai.Handler.Warp as Warp
import Network.GRPC.Server as Server
-- import Network.GRPC.Server.Handlers as Server

-- proto-lens
import qualified Network.GRPC.HTTP2.ProtoLens as ProtoLens
import Lens.Micro ((&), (^.), (^?), (.~), to, _Right, _1, _2, _3)
import Data.Int (Int32)
import Data.ProtoLens (defMessage)
import Proto.Protos.Bench (Bench, BenchObject)
import Proto.Protos.Bench_Fields (strings, content, stats, count, req, iterations)

-- proto3-wire
-- import qualified Network.GRPC.HTTP2.Proto3Wire as Proto3Wire

data BenchMode = Client | Server
  deriving (Generic, Show, Read)
data BenchProgram = Unary | ServerStreaming | ClientStreaming
  deriving (Generic, Show, Read)
data TlsMode = WithTls | NoTls
  deriving (Generic, Show, Read)
data ProtoLib = ProtoLens | Proto3Wire
  deriving (Generic, Show, Read)
data GrpcCompression = NoCompression | GzipCompression
  deriving (Generic, Show, Read)


data ProgramOpts = ProgramOpts {
    mode :: BenchMode
  , program :: BenchProgram
  , tls :: TlsMode
  , protoLib :: ProtoLib
  , compression :: GrpcCompression
  , host :: Text
  , port :: Int
  , concurrentClients :: ConcurrentClients
  , repetitions :: Repetitions
  , concurrentQueries :: ConcurrentQueries
  } deriving (Generic, Show)

type Repetitions = Int
type ConcurrentClients = Int
type ConcurrentQueries = Int

instance ParseRecord ProgramOpts

instance ParseFields BenchMode
instance ParseRecord BenchMode
instance ParseField BenchMode

instance ParseFields BenchProgram
instance ParseRecord BenchProgram
instance ParseField BenchProgram

instance ParseFields TlsMode
instance ParseRecord TlsMode
instance ParseField TlsMode

instance ParseFields ProtoLib
instance ParseRecord ProtoLib
instance ParseField ProtoLib

instance ParseFields GrpcCompression
instance ParseRecord GrpcCompression
instance ParseField GrpcCompression



unaryRPC :: ProtoLens.RPC Bench "unaryQuery"
unaryRPC = ProtoLens.RPC

serverstreamRPC :: ProtoLens.RPC Bench "serverStreamQuery"
serverstreamRPC = ProtoLens.RPC

clientstreamRPC :: ProtoLens.RPC Bench "clientStreamQuery"
clientstreamRPC = ProtoLens.RPC

main :: IO ()
main = do
  opts <- getRecord "Bench program"
  case mode opts of
    Client -> runClient
        (program opts)
        (Text.unpack $ host opts)
        (fromIntegral $ port opts)
        (concurrentClients opts)
        (repetitions opts)
        (concurrentQueries opts)
        (tls opts)
        (compression opts)
    Server -> runServer
        (fromString $ Text.unpack $ host opts)
        (fromIntegral $ port opts)


runServer :: Warp.HostPreference -> Int -> IO ()
runServer h p = do
  let warpSettings = Warp.defaultSettings
          & Warp.setPort p
          & Warp.setHost h
  let tlsSettings = WarpTLS.defaultTlsSettings { WarpTLS.onInsecure = WarpTLS.AllowInsecure }
  Server.runGrpc
    tlsSettings
    warpSettings
    [ Server.unary unaryRPC handleUnary
    , Server.serverStream serverstreamRPC handleServerStream
    , Server.clientStream clientstreamRPC handleClientStream
    ]
    [ Encoding.uncompressed , Encoding.gzip
    ]
  where
    computeStats :: BenchObject -> BenchObject
    computeStats obj = 
        let cnt = fromIntegral (obj ^. strings . to (length)) :: Int32
        in obj & stats . count .~ cnt

    handleUnary :: Server.UnaryHandler IO BenchObject BenchObject
    handleUnary _ obj = pure $ computeStats obj

    handleServerStream :: Server.ServerStreamHandler IO BenchObject BenchObject Int
    handleServerStream _ obj = do
          pure (n, ServerStream func)
        where
          n :: Int
          n = obj ^. req . iterations . to fromIntegral

          func :: Int -> IO (Maybe (Int, BenchObject))
          func 0 = pure Nothing
          func k = pure (Just (k - 1, computeStats obj))

    handleClientStream :: Server.ClientStreamHandler IO BenchObject BenchObject Int
    handleClientStream _ = pure (0, ClientStream gotOne finalize)
       where
         gotOne :: Int -> BenchObject -> IO Int
         gotOne n _ = pure $ n + 1

         finalize :: Int -> IO BenchObject
         finalize n = pure $ defMessage & stats . count .~ (fromIntegral n)

runClient
  :: BenchProgram
  -> Client.HostName
  -> Client.PortNumber
  -> ConcurrentClients
  -> Repetitions
  -> ConcurrentQueries
  -> TlsMode
  -> GrpcCompression
  -> IO ()
runClient prog host_ port_ cC k zR tls_ comp = void $ do
    ret <- replicateConcurrently cC go
    print $ fmap sum $ sequence ret
  where
    go = case prog of
           Unary -> benchUnary
           ServerStreaming -> benchServerStream
           ClientStreaming -> benchClientStream
    encoding = case comp of
        NoCompression -> Encoding Encoding.uncompressed
        GzipCompression -> Encoding Encoding.gzip
    decoding = case comp of
        NoCompression -> Decoding Encoding.uncompressed
        GzipCompression -> Decoding Encoding.gzip
    tlsSetts = case tls_ of
      NoTls -> Client.tlsSettings False host_ port_
      WithTls -> Client.tlsSettings True host_ port_

    authority :: ByteString
    authority = ByteString.pack $ host_ <> ":" <> show port_

    message = defMessage
        & strings .~ [ defMessage
                       & content .~ w
                     | w <- ["hello", "world"]
                     ]

    message2 = defMessage
        & strings .~ [ defMessage
                       & content .~ w
                     | w <- ["hello", "world"]
                     ]
        & req . iterations .~ (fromIntegral k)

    handleClient handler = do
        conn <- Client.newHttp2FrameConnection host_ port_ tlsSetts
        Client.runHttp2Client conn 8192 8192 [] Client.defaultGoAwayHandler Client.ignoreFallbackHandler $ \client -> do
          let ifc = Client._incomingFlowControl client
          -- let ofc = Client._outgoingFlowControl client
          liftIO $ Client._addCredit ifc 10_000_000_000
          _ <- Client._updateWindow ifc
          handler client

    benchUnary = Client.runClientIO $ do
        handleClient $ \client -> do
          out <- replicateConcurrently zR $ do
              fmap length $ replicateM k $ do
                  msg <- open client authority [] (Timeout 100) encoding decoding
                      (singleRequest unaryRPC message)
                  -- extract stats
                  pure $! msg ^? _Right . _Right . _3 . _Right . stats . count

          pure $! sum out

    benchServerStream = Client.runClientIO $ do
        handleClient $ \client -> do
          out <- replicateConcurrently zR $ do
              ret <- open client authority [] (Timeout 100) encoding decoding
                  (streamReply serverstreamRPC (0::Int) message2 goStreamServer)

              pure $! fromMaybe 0 $! ret ^? _Right . _1 . to fromIntegral
          pure $! sum out

    goStreamServer n _ _ = pure (n + 1)

    benchClientStream = Client.runClientIO $ do
        handleClient $ \client -> do
          out <- replicateConcurrently zR $ do
              msg <- open client authority [] (Timeout 100) encoding decoding
                  (streamRequest clientstreamRPC k goStreamClient)

              pure $! fromIntegral . fromMaybe 0 $! msg ^? _Right . _2 . _Right . _3 . _Right . stats . count
          pure $! sum out

    compressmode = case comp of
        GzipCompression -> Compressed
        NoCompression -> Uncompressed

    goStreamClient 0 = pure (0, Left StreamDone)
    goStreamClient n = pure (n-1, Right (compressmode, message))
