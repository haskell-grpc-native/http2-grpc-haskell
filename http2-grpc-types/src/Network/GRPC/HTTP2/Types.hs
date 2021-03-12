{-# LANGUAGE DataKinds #-}
{-# LANGUAGE KindSignatures #-}
{-# LANGUAGE LambdaCase #-}
{-# LANGUAGE OverloadedStrings #-}

-- | Module for GRPC <> HTTP2 mapping.
module Network.GRPC.HTTP2.Types where

import           Control.Exception (Exception)
import           Data.Maybe (fromMaybe)
import           Data.ByteString.Char8 (ByteString)
import qualified Data.ByteString.Char8 as ByteString
import           Data.CaseInsensitive (CI)

-- | HTTP2 Header Key.
type HeaderKey = CI ByteString

-- | HTTP2 Header Value.
type HeaderValue = ByteString

grpcTimeoutH :: HeaderKey
grpcTimeoutH = "grpc-timeout"

grpcEncodingH :: HeaderKey
grpcEncodingH = "grpc-encoding"

grpcAcceptEncodingH :: HeaderKey
grpcAcceptEncodingH = "grpc-accept-encoding"

grpcAcceptEncodingHVdefault :: HeaderValue
grpcAcceptEncodingHVdefault = "identity"

grpcStatusH :: HeaderKey
grpcStatusH = "grpc-status"

grpcMessageH :: HeaderKey
grpcMessageH = "grpc-message"

grpcContentTypeHV :: HeaderValue
grpcContentTypeHV = "application/grpc+proto"

-- https://grpc.io/grpc/core/impl_2codegen_2status_8h.html#a35ab2a68917eb836de84cb23253108eb
data GRPCStatusCode =
    OK
  | CANCELLED
  | UNKNOWN
  | INVALID_ARGUMENT
  | DEADLINE_EXCEEDED
  | NOT_FOUND
  | ALREADY_EXISTS
  | PERMISSION_DENIED
  | UNAUTHENTICATED
  | RESOURCE_EXHAUSTED
  | FAILED_PRECONDITION
  | ABORTED
  | OUT_OF_RANGE
  | UNIMPLEMENTED
  | INTERNAL
  | UNAVAILABLE
  | DATA_LOSS
  deriving (Show, Eq, Ord)

trailerForStatusCode :: GRPCStatusCode -> HeaderValue
trailerForStatusCode = \case
    OK
      -> "0"
    CANCELLED
      -> "1"
    UNKNOWN
      -> "2"
    INVALID_ARGUMENT
      -> "3"
    DEADLINE_EXCEEDED
      -> "4"
    NOT_FOUND
      -> "5"
    ALREADY_EXISTS
      -> "6"
    PERMISSION_DENIED
      -> "7"
    UNAUTHENTICATED
      -> "16"
    RESOURCE_EXHAUSTED
      -> "8"
    FAILED_PRECONDITION
      -> "9"
    ABORTED
      -> "10"
    OUT_OF_RANGE
      -> "11"
    UNIMPLEMENTED
      -> "12"
    INTERNAL
      -> "13"
    UNAVAILABLE
      -> "14"
    DATA_LOSS
      -> "15"

type GRPCStatusMessage = HeaderValue

data GRPCStatus = GRPCStatus !GRPCStatusCode !GRPCStatusMessage
  deriving (Show, Eq, Ord)

instance Exception GRPCStatus

statusCodeForTrailer :: HeaderValue -> Maybe GRPCStatusCode
statusCodeForTrailer = \case
    "0"
      -> Just OK
    "1"
      -> Just CANCELLED
    "2"
      -> Just UNKNOWN
    "3"
      -> Just INVALID_ARGUMENT
    "4"
      -> Just DEADLINE_EXCEEDED
    "5"
      -> Just NOT_FOUND
    "6"
      -> Just ALREADY_EXISTS
    "7"
      -> Just PERMISSION_DENIED
    "16"
      -> Just UNAUTHENTICATED
    "8"
      -> Just RESOURCE_EXHAUSTED
    "9"
      -> Just FAILED_PRECONDITION
    "10"
      -> Just ABORTED
    "11"
      -> Just OUT_OF_RANGE
    "12"
      -> Just UNIMPLEMENTED
    "13"
      -> Just INTERNAL
    "14"
      -> Just UNAVAILABLE
    "15"
      -> Just DATA_LOSS
    _
      -> Nothing

-- | Trailers for a GRPCStatus.
trailers :: GRPCStatus -> [(HeaderKey, HeaderValue)]
trailers (GRPCStatus s msg) =
    if ByteString.null msg then [status] else [status, message]
  where
    status = (grpcStatusH, trailerForStatusCode s)
    -- TODO: This should be encoded to percent-encoding
    message = (grpcMessageH, msg)

-- | In case a server replies with a gRPC status/message pair un-understood by this library.
newtype InvalidGRPCStatus = InvalidGRPCStatus [(HeaderKey, HeaderValue)]
  deriving (Show, Eq, Ord)

instance Exception InvalidGRPCStatus

-- | Read a 'GRPCStatus' from HTTP2 trailers.
readTrailers :: [(HeaderKey, HeaderValue)] -> Either InvalidGRPCStatus GRPCStatus
readTrailers pairs = maybe (Left $ InvalidGRPCStatus pairs) Right $ do
    status <- statusCodeForTrailer =<< lookup grpcStatusH pairs
    return $ GRPCStatus status message
  where
    -- TODO: This should be decoded from percent-encoding
    message = fromMaybe "" (lookup grpcMessageH pairs)

-- | A class to represent RPC information.
class IsRPC t where
  -- | Returns the HTTP2 :path for a given RPC.
  path :: t -> HeaderValue

-- | Timeout in seconds.
newtype Timeout = Timeout Int

showTimeout :: Timeout -> HeaderValue
showTimeout (Timeout n) = ByteString.pack $ show n ++ "S"

-- | The HTTP2-Authority portion of an URL (e.g., "dicioccio.fr:7777").
type Authority = HeaderValue
