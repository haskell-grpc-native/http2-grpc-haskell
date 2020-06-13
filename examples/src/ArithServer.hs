{-# LANGUAGE FlexibleContexts #-}
{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE DataKinds #-}
module ArithServer where

import Network.GRPC.Server

import Lens.Micro
import Lens.Micro.Extras
import Data.ProtoLens.Message (defMessage)
import Network.Wai.Handler.WarpTLS 
import Network.Wai.Handler.Warp (defaultSettings, getPort)
--import Network.GRPC.HTTP2.Types (RPC(..))
import Network.GRPC.HTTP2.ProtoLens (RPC(..))
import Network.GRPC.HTTP2.Encoding (gzip)
import Proto.Protos.Calcs (Arithmetic, CalcNumbers, CalcNumber)
import Proto.Protos.Calcs_Fields 
import System.Environment (getArgs)

-- Eoin Cavanagh, modified from https://github.com/lucasdicioccio/warp-grpc-example/blob/master/src/Lib.hs

--main :: IO ()
--main = do
--  args <- getArgs
--  runGrpc defaultTlsSettings defaultSettings (handlers args) [gzip]

someFunc :: IO ()
someFunc = do
  args <- getArgs
  someFunc' args
 
someFunc' :: [String] -> IO ()
someFunc' p =  do
  print $ "starting on port " ++ ((show . getPort) defaultSettings)
  -- for simplicity, configures Warp to support insecure sessions
  -- not recommended for production use
  let insecureTlsSettings = defaultTlsSettings { onInsecure = AllowInsecure }
  runGrpc insecureTlsSettings defaultSettings (handlers p) [gzip]


handlers :: [String] -> [ServiceHandler]
handlers _ =
  [unary  (RPC :: RPC Arithmetic "add") handleAdd
  ]


-- sum up the values provided in the request and return the total
-- stubbed at the moment
handleAdd :: UnaryHandler IO CalcNumbers CalcNumber
handleAdd _ input = do
    print ("add"::[Char], view values input)
    let xs =  view values input
    print (show xs)
    --let xs' = (xs (^..) $ traversed . code) :: [Int]
    -- let xs' = (map code xs)
    -- let  s = sum xs
    -- return $ defMessage & code .~ (head (view values input))
    return $ performAdd input


performAdd :: CalcNumbers -> CalcNumber
performAdd nums = defMessage & code .~ total
  where
    nums' = view values nums
    total = sum (fmap (\l -> l ^. code) nums')
    
    
    
  