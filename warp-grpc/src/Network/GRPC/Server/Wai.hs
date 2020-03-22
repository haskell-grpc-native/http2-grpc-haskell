{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE ScopedTypeVariables #-}
{-# LANGUAGE CPP #-}

module Network.GRPC.Server.Wai where

import           Control.Exception (Handler(..), catches, SomeException, throwIO)
import           Control.Monad.IO.Class
import           Data.ByteString.Char8 (ByteString)
import qualified Data.ByteString.Char8 as ByteString
import           Data.ByteString.Lazy (fromStrict)
import           Data.Binary.Builder (Builder)
import           Data.IORef
import           Data.Maybe (fromMaybe)
import qualified Data.CaseInsensitive as CI
import qualified Data.List as List
import           Network.GRPC.HTTP2.Encoding (Compression, Encoding(..), Decoding(..), grpcCompressionHV, uncompressed)
import           Network.GRPC.HTTP2.Types (GRPCStatus(..), GRPCStatusCode(..), grpcStatusH, grpcMessageH, grpcContentTypeHV, grpcEncodingH, grpcAcceptEncodingH)
import           Network.HTTP.Types (status200, status404)
import           Network.Wai (Application, Request(..), rawPathInfo, responseLBS, responseStream, requestHeaders)
import           Network.Wai.Handler.Warp (http2dataTrailers, defaultHTTP2Data, modifyHTTP2Data)
#if MIN_VERSION_warp(3,3,0)
import           Network.HTTP2.Server (NextTrailersMaker(..))
#endif

#if MIN_VERSION_base(4,11,0)
#else
import Data.Monoid ((<>))
#endif

import Network.GRPC.Server.Helpers (modifyGRPCStatus)

-- | A Wai Handler for a request.
type WaiHandler =
     Decoding
  -- ^ Compression for the request inputs.
  -> Encoding
  -- ^ Compression for the request outputs.
  -> Request
  -- ^ Request object.
  -> (Builder -> IO ())
  -- ^ Write a data chunk in the reply.
  -> IO ()
  -- ^ Flush the output.
  -> IO ()

-- | Untyped gRPC Service handler.
data ServiceHandler = ServiceHandler {
    grpcHandlerPath :: ByteString
  -- ^ Path to the Service to be handled.
  , grpcWaiHandler  :: WaiHandler
  -- ^ Actual request handler.
  }

-- | Build a WAI 'Application' from a list of ServiceHandler.
--
-- Currently, gRPC calls are lookuped up by traversing the list of ServiceHandler.
-- This lookup may be inefficient for large amount of servics.
grpcApp :: [Compression] -> [ServiceHandler] -> Application
grpcApp compressions services =
    grpcService compressions services err404app
  where
    err404app :: Application
    err404app req rep =
        rep $ responseLBS status404 [] $ fromStrict ("not found: " <> rawPathInfo req)

-- | Aborts a GRPC handler with a given GRPCStatus.
closeEarly :: MonadIO m => GRPCStatus -> m a
closeEarly = liftIO . throwIO

-- | Build a WAI 'Middleware' from a list of ServiceHandler.
--
-- Currently, gRPC calls are lookuped up by traversing the list of ServiceHandler.
-- This lookup may be inefficient for large amount of services.
grpcService :: [Compression] -> [ServiceHandler] -> (Application -> Application)
grpcService compressions services app = \req rep -> do
    r <- newIORef []
#if MIN_VERSION_warp(3,3,0)
    modifyHTTP2Data req $ \h2data -> 
      Just $! (fromMaybe defaultHTTP2Data h2data) { http2dataTrailers = trailersMaker r }
#endif
    case lookupHandler (rawPathInfo req) services of
        Just handler ->
            -- Handler that catches early GRPC termination and other exceptions.
            --
            -- Other exceptions are turned into GRPC status INTERNAL (rather
            -- than returning a 500).
            --
            -- These exceptions are swallowed from the WAI "onException"
            -- handler, so we'll need a better way to handle this case.
            let grpcHandler write flush =
                    doHandle r handler req write flush
                    `catches` [ Handler $ \(e::GRPCStatus)    ->
                                 modifyGRPCStatus r req e
                              , Handler $ \(e::SomeException) -> 
                                 modifyGRPCStatus r req (GRPCStatus INTERNAL $ ByteString.pack $ show e)
                              ]
            in (rep $ responseStream status200 (hdrs200 req) grpcHandler)
        Nothing ->
            app req rep
  where
    bestCompression req   = lookupEncoding req compressions
    pickedCompression req = fromMaybe (Encoding uncompressed) (bestCompression req)

    hopefulDecompression req = lookupDecoding req compressions
    pickedDecompression req  = fromMaybe (Decoding uncompressed) (hopefulDecompression req)

    hdrs200 req = [
        ("content-type", grpcContentTypeHV)
      , ("grpc-encoding", grpcCompressionHV (_getEncodingCompression $ pickedCompression req))
      , ("trailer", CI.original grpcStatusH)
      , ("trailer", CI.original grpcMessageH)
      ]
    lookupHandler :: ByteString -> [ServiceHandler] -> Maybe WaiHandler
    lookupHandler p plainHandlers = grpcWaiHandler <$>
        List.find (\(ServiceHandler rpcPath _) -> rpcPath == p) plainHandlers
    doHandle r handler req write flush = do
        _ <- handler (pickedDecompression req) (pickedCompression req) req write flush
        modifyGRPCStatus r req (GRPCStatus OK "WAI handler ended.")

#if MIN_VERSION_warp(3,3,0)
    trailersMaker r Nothing = Trailers <$> readIORef r
    trailersMaker r _ = return $ NextTrailersMaker (trailersMaker r)
#endif

-- | Looks-up header for encoding outgoing messages.
requestAcceptEncodingNames :: Request -> [ByteString]
requestAcceptEncodingNames  req = maybe [] (ByteString.split ',') $
    lookup grpcAcceptEncodingH (requestHeaders req)

-- | Looks-up the compression to use from a set of known algorithms.
lookupEncoding :: Request -> [Compression] -> Maybe Encoding
lookupEncoding req compressions = Encoding <$>
    safeHead [ c | c <- compressions
                 , n <- requestAcceptEncodingNames req
                 , n == grpcCompressionHV c
             ]
  where
    safeHead [] = Nothing
    safeHead (x:_) = Just x

-- | Looks-up header for decoding incoming messages.
requestDecodingName :: Request -> Maybe ByteString
requestDecodingName req = lookup grpcEncodingH (requestHeaders req)

-- | Looks-up the compression to use for decoding messages.
lookupDecoding :: Request -> [Compression] -> Maybe Decoding
lookupDecoding req compressions = fmap Decoding $ do
    d <- requestDecodingName req
    lookup d [(grpcCompressionHV c, c) | c <- compressions]
