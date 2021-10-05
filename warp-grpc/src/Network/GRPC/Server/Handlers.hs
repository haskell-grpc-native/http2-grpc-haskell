module Network.GRPC.Server.Handlers (
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

import           Network.GRPC.HTTP2.Encoding
import qualified Network.GRPC.Server.Handlers.Trans as H
import           Network.GRPC.Server.Wai (ServiceHandler)

unary
  :: (GRPCInput r i, GRPCOutput r o)
  => r
  -> H.UnaryHandler IO i o
  -> ServiceHandler
unary = H.unary id

serverStream
  :: (GRPCInput r i, GRPCOutput r o)
  => r
  -> H.ServerStreamHandler IO i o a
  -> ServiceHandler
serverStream = H.serverStream id

clientStream
  :: (GRPCInput r i, GRPCOutput r o)
  => r
  -> H.ClientStreamHandler IO i o a
  -> ServiceHandler
clientStream = H.clientStream id

bidiStream
  :: (GRPCInput r i, GRPCOutput r o)
  => r
  -> H.BiDiStreamHandler IO i o a
  -> ServiceHandler
bidiStream = H.bidiStream id

generalStream
  :: (GRPCInput r i, GRPCOutput r o)
  => r
  -> H.GeneralStreamHandler IO i o a b
  -> ServiceHandler
generalStream = H.generalStream id

explicitStream
  :: (GRPCInput r i, GRPCOutput r o)
  => r
  -> H.ExplicitStreamHandler IO i o
  -> ServiceHandler
explicitStream = H.explicitStream id
