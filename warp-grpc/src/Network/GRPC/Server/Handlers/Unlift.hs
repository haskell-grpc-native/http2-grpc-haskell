module Network.GRPC.Server.Handlers.Unlift (
  H.UnaryHandler
, unary
, H.ServerStreamHandler, H.ServerStream(..)
, serverStream
, H.ClientStreamHandler, H.ClientStream(..)
, clientStream
, H.BiDiStreamHandler, H.BiDiStep(..), H.BiDiStream(..)
, bidiStream
, H.GeneralStreamHandler, H.IncomingStream(..), H.OutgoingStream(..)
, generalStream
, H.ExplicitStreamHandler
, explicitStream
) where

import           Control.Monad.IO.Unlift
import           Network.GRPC.HTTP2.Encoding
import qualified Network.GRPC.Server.Handlers.Trans as H
import           Network.GRPC.Server.Wai (ServiceHandler)

unary
  :: (MonadUnliftIO m, GRPCInput r i, GRPCOutput r o)
  => r
  -> H.UnaryHandler m i o
  -> m ServiceHandler
unary rpc handler
  = withRunInIO (\f -> return $ H.unary f rpc handler)

serverStream
  :: (MonadUnliftIO m, GRPCInput r i, GRPCOutput r o)
  => r
  -> H.ServerStreamHandler m i o a
  -> m ServiceHandler
serverStream rpc handler
  = withRunInIO (\f -> return $ H.serverStream f rpc handler)

clientStream
  :: (MonadUnliftIO m, GRPCInput r i, GRPCOutput r o)
  => r
  -> H.ClientStreamHandler m i o a
  -> m ServiceHandler
clientStream rpc handler
  = withRunInIO (\f -> return $ H.clientStream f rpc handler)

bidiStream
  :: (MonadUnliftIO m, GRPCInput r i, GRPCOutput r o)
  => r
  -> H.BiDiStreamHandler m i o a
  -> m ServiceHandler
bidiStream rpc handler
  = withRunInIO (\f -> return $ H.bidiStream f rpc handler)

generalStream
  :: (MonadUnliftIO m, GRPCInput r i, GRPCOutput r o)
  => r
  -> H.GeneralStreamHandler m i o a b
  -> m ServiceHandler
generalStream rpc handler
  = withRunInIO (\f -> return $ H.generalStream f rpc handler)

explicitStream
  :: (MonadUnliftIO m, GRPCInput r i, GRPCOutput r o)
  => r
  -> H.ExplicitStreamHandler m i o
  -> m ServiceHandler
explicitStream rpc handler
  = withRunInIO (\f -> return $ H.explicitStream f rpc handler)
