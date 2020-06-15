{-# LANGUAGE DataKinds #-}
{-# LANGUAGE OverloadedStrings #-}

module ArithClient where

import Control.Monad (void)
import Control.Monad.IO.Class (liftIO)
import Proto.Protos.Calcs
import Proto.Protos.Calcs_Fields 
import Network.GRPC.Client
import Network.HTTP2.Client
import Network.GRPC.Client.Helpers
import Network.GRPC.HTTP2.Encoding
import Lens.Micro
import Network.GRPC.HTTP2.ProtoLens

import Data.ProtoLens

-- create a simple CalcNumbers via lens operations for later use
val1, val2, val3 :: CalcNumber
val1 = defMessage & (code .~ 7)
val2 = defMessage & (code .~ 77)
val3 = defMessage & (code .~ 777)

vals :: CalcNumbers
vals = defMessage & (values .~ [val1, val2, val3])
---

main :: IO ()
main = do
  let encoding = Encoding uncompressed
  let decoding = Decoding uncompressed
  let host = "127.0.0.1"
  let port = 3000
  void $ runClientIO $ do
    conn <- newHttp2FrameConnection host port (tlsSettings False host port)
    liftIO $ print $ "connecting on port " ++ (show port)
    runHttp2Client conn 8192 8192 [] defaultGoAwayHandler ignoreFallbackHandler $ \client -> do
      liftIO $ putStrLn "~~~connected~~~"
      let ifc = _incomingFlowControl client
      let ofc = _outgoingFlowControl client
      liftIO $ _addCredit ifc 10000000
      _ <- _updateWindow ifc
      reply <- open client "127.0.0.1" [] (Timeout 100) encoding decoding
        (singleRequest (RPC :: RPC Arithmetic "add") vals )

      liftIO $ print reply

