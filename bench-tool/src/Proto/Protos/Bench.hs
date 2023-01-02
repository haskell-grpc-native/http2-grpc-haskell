{- This file was auto-generated from protos/bench.proto by the proto-lens-protoc program. -}
{-# LANGUAGE ScopedTypeVariables, DataKinds, TypeFamilies, UndecidableInstances, GeneralizedNewtypeDeriving, MultiParamTypeClasses, FlexibleContexts, FlexibleInstances, PatternSynonyms, MagicHash, NoImplicitPrelude, DataKinds, BangPatterns, TypeApplications, OverloadedStrings, DerivingStrategies#-}
{-# OPTIONS_GHC -Wno-unused-imports#-}
{-# OPTIONS_GHC -Wno-duplicate-exports#-}
{-# OPTIONS_GHC -Wno-dodgy-exports#-}
module Proto.Protos.Bench (
        Bench(..), BenchObject(), BenchObject'Req(), BenchObject'Stats(),
        BenchObject'StringContent()
    ) where
import qualified Data.ProtoLens.Runtime.Control.DeepSeq as Control.DeepSeq
import qualified Data.ProtoLens.Runtime.Data.ProtoLens.Prism as Data.ProtoLens.Prism
import qualified Data.ProtoLens.Runtime.Prelude as Prelude
import qualified Data.ProtoLens.Runtime.Data.Int as Data.Int
import qualified Data.ProtoLens.Runtime.Data.Monoid as Data.Monoid
import qualified Data.ProtoLens.Runtime.Data.Word as Data.Word
import qualified Data.ProtoLens.Runtime.Data.ProtoLens as Data.ProtoLens
import qualified Data.ProtoLens.Runtime.Data.ProtoLens.Encoding.Bytes as Data.ProtoLens.Encoding.Bytes
import qualified Data.ProtoLens.Runtime.Data.ProtoLens.Encoding.Growing as Data.ProtoLens.Encoding.Growing
import qualified Data.ProtoLens.Runtime.Data.ProtoLens.Encoding.Parser.Unsafe as Data.ProtoLens.Encoding.Parser.Unsafe
import qualified Data.ProtoLens.Runtime.Data.ProtoLens.Encoding.Wire as Data.ProtoLens.Encoding.Wire
import qualified Data.ProtoLens.Runtime.Data.ProtoLens.Field as Data.ProtoLens.Field
import qualified Data.ProtoLens.Runtime.Data.ProtoLens.Message.Enum as Data.ProtoLens.Message.Enum
import qualified Data.ProtoLens.Runtime.Data.ProtoLens.Service.Types as Data.ProtoLens.Service.Types
import qualified Data.ProtoLens.Runtime.Lens.Family2 as Lens.Family2
import qualified Data.ProtoLens.Runtime.Lens.Family2.Unchecked as Lens.Family2.Unchecked
import qualified Data.ProtoLens.Runtime.Data.Text as Data.Text
import qualified Data.ProtoLens.Runtime.Data.Map as Data.Map
import qualified Data.ProtoLens.Runtime.Data.ByteString as Data.ByteString
import qualified Data.ProtoLens.Runtime.Data.ByteString.Char8 as Data.ByteString.Char8
import qualified Data.ProtoLens.Runtime.Data.Text.Encoding as Data.Text.Encoding
import qualified Data.ProtoLens.Runtime.Data.Vector as Data.Vector
import qualified Data.ProtoLens.Runtime.Data.Vector.Generic as Data.Vector.Generic
import qualified Data.ProtoLens.Runtime.Data.Vector.Unboxed as Data.Vector.Unboxed
import qualified Data.ProtoLens.Runtime.Text.Read as Text.Read
{- | Fields :
     
         * 'Proto.Protos.Bench_Fields.strings' @:: Lens' BenchObject [BenchObject'StringContent]@
         * 'Proto.Protos.Bench_Fields.vec'strings' @:: Lens' BenchObject (Data.Vector.Vector BenchObject'StringContent)@
         * 'Proto.Protos.Bench_Fields.stats' @:: Lens' BenchObject BenchObject'Stats@
         * 'Proto.Protos.Bench_Fields.maybe'stats' @:: Lens' BenchObject (Prelude.Maybe BenchObject'Stats)@
         * 'Proto.Protos.Bench_Fields.req' @:: Lens' BenchObject BenchObject'Req@
         * 'Proto.Protos.Bench_Fields.maybe'req' @:: Lens' BenchObject (Prelude.Maybe BenchObject'Req)@ -}
data BenchObject
  = BenchObject'_constructor {_BenchObject'strings :: !(Data.Vector.Vector BenchObject'StringContent),
                              _BenchObject'stats :: !(Prelude.Maybe BenchObject'Stats),
                              _BenchObject'req :: !(Prelude.Maybe BenchObject'Req),
                              _BenchObject'_unknownFields :: !Data.ProtoLens.FieldSet}
  deriving stock (Prelude.Eq, Prelude.Ord)
instance Prelude.Show BenchObject where
  showsPrec _ __x __s
    = Prelude.showChar
        '{'
        (Prelude.showString
           (Data.ProtoLens.showMessageShort __x) (Prelude.showChar '}' __s))
instance Data.ProtoLens.Field.HasField BenchObject "strings" [BenchObject'StringContent] where
  fieldOf _
    = (Prelude..)
        (Lens.Family2.Unchecked.lens
           _BenchObject'strings
           (\ x__ y__ -> x__ {_BenchObject'strings = y__}))
        (Lens.Family2.Unchecked.lens
           Data.Vector.Generic.toList
           (\ _ y__ -> Data.Vector.Generic.fromList y__))
instance Data.ProtoLens.Field.HasField BenchObject "vec'strings" (Data.Vector.Vector BenchObject'StringContent) where
  fieldOf _
    = (Prelude..)
        (Lens.Family2.Unchecked.lens
           _BenchObject'strings
           (\ x__ y__ -> x__ {_BenchObject'strings = y__}))
        Prelude.id
instance Data.ProtoLens.Field.HasField BenchObject "stats" BenchObject'Stats where
  fieldOf _
    = (Prelude..)
        (Lens.Family2.Unchecked.lens
           _BenchObject'stats (\ x__ y__ -> x__ {_BenchObject'stats = y__}))
        (Data.ProtoLens.maybeLens Data.ProtoLens.defMessage)
instance Data.ProtoLens.Field.HasField BenchObject "maybe'stats" (Prelude.Maybe BenchObject'Stats) where
  fieldOf _
    = (Prelude..)
        (Lens.Family2.Unchecked.lens
           _BenchObject'stats (\ x__ y__ -> x__ {_BenchObject'stats = y__}))
        Prelude.id
instance Data.ProtoLens.Field.HasField BenchObject "req" BenchObject'Req where
  fieldOf _
    = (Prelude..)
        (Lens.Family2.Unchecked.lens
           _BenchObject'req (\ x__ y__ -> x__ {_BenchObject'req = y__}))
        (Data.ProtoLens.maybeLens Data.ProtoLens.defMessage)
instance Data.ProtoLens.Field.HasField BenchObject "maybe'req" (Prelude.Maybe BenchObject'Req) where
  fieldOf _
    = (Prelude..)
        (Lens.Family2.Unchecked.lens
           _BenchObject'req (\ x__ y__ -> x__ {_BenchObject'req = y__}))
        Prelude.id
instance Data.ProtoLens.Message BenchObject where
  messageName _ = Data.Text.pack "bench.BenchObject"
  packedMessageDescriptor _
    = "\n\
      \\vBenchObject\DC2:\n\
      \\astrings\CAN\SOH \ETX(\v2 .bench.BenchObject.StringContentR\astrings\DC2.\n\
      \\ENQstats\CAN\STX \SOH(\v2\CAN.bench.BenchObject.StatsR\ENQstats\DC2(\n\
      \\ETXreq\CAN\ETX \SOH(\v2\SYN.bench.BenchObject.ReqR\ETXreq\SUB)\n\
      \\rStringContent\DC2\CAN\n\
      \\acontent\CAN\SOH \SOH(\tR\acontent\SUB\GS\n\
      \\ENQStats\DC2\DC4\n\
      \\ENQcount\CAN\SOH \SOH(\ENQR\ENQcount\SUB%\n\
      \\ETXReq\DC2\RS\n\
      \\n\
      \iterations\CAN\SOH \SOH(\ENQR\n\
      \iterations"
  packedFileDescriptor _ = packedFileDescriptor
  fieldsByTag
    = let
        strings__field_descriptor
          = Data.ProtoLens.FieldDescriptor
              "strings"
              (Data.ProtoLens.MessageField Data.ProtoLens.MessageType ::
                 Data.ProtoLens.FieldTypeDescriptor BenchObject'StringContent)
              (Data.ProtoLens.RepeatedField
                 Data.ProtoLens.Unpacked (Data.ProtoLens.Field.field @"strings")) ::
              Data.ProtoLens.FieldDescriptor BenchObject
        stats__field_descriptor
          = Data.ProtoLens.FieldDescriptor
              "stats"
              (Data.ProtoLens.MessageField Data.ProtoLens.MessageType ::
                 Data.ProtoLens.FieldTypeDescriptor BenchObject'Stats)
              (Data.ProtoLens.OptionalField
                 (Data.ProtoLens.Field.field @"maybe'stats")) ::
              Data.ProtoLens.FieldDescriptor BenchObject
        req__field_descriptor
          = Data.ProtoLens.FieldDescriptor
              "req"
              (Data.ProtoLens.MessageField Data.ProtoLens.MessageType ::
                 Data.ProtoLens.FieldTypeDescriptor BenchObject'Req)
              (Data.ProtoLens.OptionalField
                 (Data.ProtoLens.Field.field @"maybe'req")) ::
              Data.ProtoLens.FieldDescriptor BenchObject
      in
        Data.Map.fromList
          [(Data.ProtoLens.Tag 1, strings__field_descriptor),
           (Data.ProtoLens.Tag 2, stats__field_descriptor),
           (Data.ProtoLens.Tag 3, req__field_descriptor)]
  unknownFields
    = Lens.Family2.Unchecked.lens
        _BenchObject'_unknownFields
        (\ x__ y__ -> x__ {_BenchObject'_unknownFields = y__})
  defMessage
    = BenchObject'_constructor
        {_BenchObject'strings = Data.Vector.Generic.empty,
         _BenchObject'stats = Prelude.Nothing,
         _BenchObject'req = Prelude.Nothing,
         _BenchObject'_unknownFields = []}
  parseMessage
    = let
        loop ::
          BenchObject
          -> Data.ProtoLens.Encoding.Growing.Growing Data.Vector.Vector Data.ProtoLens.Encoding.Growing.RealWorld BenchObject'StringContent
             -> Data.ProtoLens.Encoding.Bytes.Parser BenchObject
        loop x mutable'strings
          = do end <- Data.ProtoLens.Encoding.Bytes.atEnd
               if end then
                   do frozen'strings <- Data.ProtoLens.Encoding.Parser.Unsafe.unsafeLiftIO
                                          (Data.ProtoLens.Encoding.Growing.unsafeFreeze
                                             mutable'strings)
                      (let missing = []
                       in
                         if Prelude.null missing then
                             Prelude.return ()
                         else
                             Prelude.fail
                               ((Prelude.++)
                                  "Missing required fields: "
                                  (Prelude.show (missing :: [Prelude.String]))))
                      Prelude.return
                        (Lens.Family2.over
                           Data.ProtoLens.unknownFields (\ !t -> Prelude.reverse t)
                           (Lens.Family2.set
                              (Data.ProtoLens.Field.field @"vec'strings") frozen'strings x))
               else
                   do tag <- Data.ProtoLens.Encoding.Bytes.getVarInt
                      case tag of
                        10
                          -> do !y <- (Data.ProtoLens.Encoding.Bytes.<?>)
                                        (do len <- Data.ProtoLens.Encoding.Bytes.getVarInt
                                            Data.ProtoLens.Encoding.Bytes.isolate
                                              (Prelude.fromIntegral len)
                                              Data.ProtoLens.parseMessage)
                                        "strings"
                                v <- Data.ProtoLens.Encoding.Parser.Unsafe.unsafeLiftIO
                                       (Data.ProtoLens.Encoding.Growing.append mutable'strings y)
                                loop x v
                        18
                          -> do y <- (Data.ProtoLens.Encoding.Bytes.<?>)
                                       (do len <- Data.ProtoLens.Encoding.Bytes.getVarInt
                                           Data.ProtoLens.Encoding.Bytes.isolate
                                             (Prelude.fromIntegral len) Data.ProtoLens.parseMessage)
                                       "stats"
                                loop
                                  (Lens.Family2.set (Data.ProtoLens.Field.field @"stats") y x)
                                  mutable'strings
                        26
                          -> do y <- (Data.ProtoLens.Encoding.Bytes.<?>)
                                       (do len <- Data.ProtoLens.Encoding.Bytes.getVarInt
                                           Data.ProtoLens.Encoding.Bytes.isolate
                                             (Prelude.fromIntegral len) Data.ProtoLens.parseMessage)
                                       "req"
                                loop
                                  (Lens.Family2.set (Data.ProtoLens.Field.field @"req") y x)
                                  mutable'strings
                        wire
                          -> do !y <- Data.ProtoLens.Encoding.Wire.parseTaggedValueFromWire
                                        wire
                                loop
                                  (Lens.Family2.over
                                     Data.ProtoLens.unknownFields (\ !t -> (:) y t) x)
                                  mutable'strings
      in
        (Data.ProtoLens.Encoding.Bytes.<?>)
          (do mutable'strings <- Data.ProtoLens.Encoding.Parser.Unsafe.unsafeLiftIO
                                   Data.ProtoLens.Encoding.Growing.new
              loop Data.ProtoLens.defMessage mutable'strings)
          "BenchObject"
  buildMessage
    = \ _x
        -> (Data.Monoid.<>)
             (Data.ProtoLens.Encoding.Bytes.foldMapBuilder
                (\ _v
                   -> (Data.Monoid.<>)
                        (Data.ProtoLens.Encoding.Bytes.putVarInt 10)
                        ((Prelude..)
                           (\ bs
                              -> (Data.Monoid.<>)
                                   (Data.ProtoLens.Encoding.Bytes.putVarInt
                                      (Prelude.fromIntegral (Data.ByteString.length bs)))
                                   (Data.ProtoLens.Encoding.Bytes.putBytes bs))
                           Data.ProtoLens.encodeMessage _v))
                (Lens.Family2.view (Data.ProtoLens.Field.field @"vec'strings") _x))
             ((Data.Monoid.<>)
                (case
                     Lens.Family2.view (Data.ProtoLens.Field.field @"maybe'stats") _x
                 of
                   Prelude.Nothing -> Data.Monoid.mempty
                   (Prelude.Just _v)
                     -> (Data.Monoid.<>)
                          (Data.ProtoLens.Encoding.Bytes.putVarInt 18)
                          ((Prelude..)
                             (\ bs
                                -> (Data.Monoid.<>)
                                     (Data.ProtoLens.Encoding.Bytes.putVarInt
                                        (Prelude.fromIntegral (Data.ByteString.length bs)))
                                     (Data.ProtoLens.Encoding.Bytes.putBytes bs))
                             Data.ProtoLens.encodeMessage _v))
                ((Data.Monoid.<>)
                   (case
                        Lens.Family2.view (Data.ProtoLens.Field.field @"maybe'req") _x
                    of
                      Prelude.Nothing -> Data.Monoid.mempty
                      (Prelude.Just _v)
                        -> (Data.Monoid.<>)
                             (Data.ProtoLens.Encoding.Bytes.putVarInt 26)
                             ((Prelude..)
                                (\ bs
                                   -> (Data.Monoid.<>)
                                        (Data.ProtoLens.Encoding.Bytes.putVarInt
                                           (Prelude.fromIntegral (Data.ByteString.length bs)))
                                        (Data.ProtoLens.Encoding.Bytes.putBytes bs))
                                Data.ProtoLens.encodeMessage _v))
                   (Data.ProtoLens.Encoding.Wire.buildFieldSet
                      (Lens.Family2.view Data.ProtoLens.unknownFields _x))))
instance Control.DeepSeq.NFData BenchObject where
  rnf
    = \ x__
        -> Control.DeepSeq.deepseq
             (_BenchObject'_unknownFields x__)
             (Control.DeepSeq.deepseq
                (_BenchObject'strings x__)
                (Control.DeepSeq.deepseq
                   (_BenchObject'stats x__)
                   (Control.DeepSeq.deepseq (_BenchObject'req x__) ())))
{- | Fields :
     
         * 'Proto.Protos.Bench_Fields.iterations' @:: Lens' BenchObject'Req Data.Int.Int32@ -}
data BenchObject'Req
  = BenchObject'Req'_constructor {_BenchObject'Req'iterations :: !Data.Int.Int32,
                                  _BenchObject'Req'_unknownFields :: !Data.ProtoLens.FieldSet}
  deriving stock (Prelude.Eq, Prelude.Ord)
instance Prelude.Show BenchObject'Req where
  showsPrec _ __x __s
    = Prelude.showChar
        '{'
        (Prelude.showString
           (Data.ProtoLens.showMessageShort __x) (Prelude.showChar '}' __s))
instance Data.ProtoLens.Field.HasField BenchObject'Req "iterations" Data.Int.Int32 where
  fieldOf _
    = (Prelude..)
        (Lens.Family2.Unchecked.lens
           _BenchObject'Req'iterations
           (\ x__ y__ -> x__ {_BenchObject'Req'iterations = y__}))
        Prelude.id
instance Data.ProtoLens.Message BenchObject'Req where
  messageName _ = Data.Text.pack "bench.BenchObject.Req"
  packedMessageDescriptor _
    = "\n\
      \\ETXReq\DC2\RS\n\
      \\n\
      \iterations\CAN\SOH \SOH(\ENQR\n\
      \iterations"
  packedFileDescriptor _ = packedFileDescriptor
  fieldsByTag
    = let
        iterations__field_descriptor
          = Data.ProtoLens.FieldDescriptor
              "iterations"
              (Data.ProtoLens.ScalarField Data.ProtoLens.Int32Field ::
                 Data.ProtoLens.FieldTypeDescriptor Data.Int.Int32)
              (Data.ProtoLens.PlainField
                 Data.ProtoLens.Optional
                 (Data.ProtoLens.Field.field @"iterations")) ::
              Data.ProtoLens.FieldDescriptor BenchObject'Req
      in
        Data.Map.fromList
          [(Data.ProtoLens.Tag 1, iterations__field_descriptor)]
  unknownFields
    = Lens.Family2.Unchecked.lens
        _BenchObject'Req'_unknownFields
        (\ x__ y__ -> x__ {_BenchObject'Req'_unknownFields = y__})
  defMessage
    = BenchObject'Req'_constructor
        {_BenchObject'Req'iterations = Data.ProtoLens.fieldDefault,
         _BenchObject'Req'_unknownFields = []}
  parseMessage
    = let
        loop ::
          BenchObject'Req
          -> Data.ProtoLens.Encoding.Bytes.Parser BenchObject'Req
        loop x
          = do end <- Data.ProtoLens.Encoding.Bytes.atEnd
               if end then
                   do (let missing = []
                       in
                         if Prelude.null missing then
                             Prelude.return ()
                         else
                             Prelude.fail
                               ((Prelude.++)
                                  "Missing required fields: "
                                  (Prelude.show (missing :: [Prelude.String]))))
                      Prelude.return
                        (Lens.Family2.over
                           Data.ProtoLens.unknownFields (\ !t -> Prelude.reverse t) x)
               else
                   do tag <- Data.ProtoLens.Encoding.Bytes.getVarInt
                      case tag of
                        8 -> do y <- (Data.ProtoLens.Encoding.Bytes.<?>)
                                       (Prelude.fmap
                                          Prelude.fromIntegral
                                          Data.ProtoLens.Encoding.Bytes.getVarInt)
                                       "iterations"
                                loop
                                  (Lens.Family2.set (Data.ProtoLens.Field.field @"iterations") y x)
                        wire
                          -> do !y <- Data.ProtoLens.Encoding.Wire.parseTaggedValueFromWire
                                        wire
                                loop
                                  (Lens.Family2.over
                                     Data.ProtoLens.unknownFields (\ !t -> (:) y t) x)
      in
        (Data.ProtoLens.Encoding.Bytes.<?>)
          (do loop Data.ProtoLens.defMessage) "Req"
  buildMessage
    = \ _x
        -> (Data.Monoid.<>)
             (let
                _v
                  = Lens.Family2.view (Data.ProtoLens.Field.field @"iterations") _x
              in
                if (Prelude.==) _v Data.ProtoLens.fieldDefault then
                    Data.Monoid.mempty
                else
                    (Data.Monoid.<>)
                      (Data.ProtoLens.Encoding.Bytes.putVarInt 8)
                      ((Prelude..)
                         Data.ProtoLens.Encoding.Bytes.putVarInt Prelude.fromIntegral _v))
             (Data.ProtoLens.Encoding.Wire.buildFieldSet
                (Lens.Family2.view Data.ProtoLens.unknownFields _x))
instance Control.DeepSeq.NFData BenchObject'Req where
  rnf
    = \ x__
        -> Control.DeepSeq.deepseq
             (_BenchObject'Req'_unknownFields x__)
             (Control.DeepSeq.deepseq (_BenchObject'Req'iterations x__) ())
{- | Fields :
     
         * 'Proto.Protos.Bench_Fields.count' @:: Lens' BenchObject'Stats Data.Int.Int32@ -}
data BenchObject'Stats
  = BenchObject'Stats'_constructor {_BenchObject'Stats'count :: !Data.Int.Int32,
                                    _BenchObject'Stats'_unknownFields :: !Data.ProtoLens.FieldSet}
  deriving stock (Prelude.Eq, Prelude.Ord)
instance Prelude.Show BenchObject'Stats where
  showsPrec _ __x __s
    = Prelude.showChar
        '{'
        (Prelude.showString
           (Data.ProtoLens.showMessageShort __x) (Prelude.showChar '}' __s))
instance Data.ProtoLens.Field.HasField BenchObject'Stats "count" Data.Int.Int32 where
  fieldOf _
    = (Prelude..)
        (Lens.Family2.Unchecked.lens
           _BenchObject'Stats'count
           (\ x__ y__ -> x__ {_BenchObject'Stats'count = y__}))
        Prelude.id
instance Data.ProtoLens.Message BenchObject'Stats where
  messageName _ = Data.Text.pack "bench.BenchObject.Stats"
  packedMessageDescriptor _
    = "\n\
      \\ENQStats\DC2\DC4\n\
      \\ENQcount\CAN\SOH \SOH(\ENQR\ENQcount"
  packedFileDescriptor _ = packedFileDescriptor
  fieldsByTag
    = let
        count__field_descriptor
          = Data.ProtoLens.FieldDescriptor
              "count"
              (Data.ProtoLens.ScalarField Data.ProtoLens.Int32Field ::
                 Data.ProtoLens.FieldTypeDescriptor Data.Int.Int32)
              (Data.ProtoLens.PlainField
                 Data.ProtoLens.Optional (Data.ProtoLens.Field.field @"count")) ::
              Data.ProtoLens.FieldDescriptor BenchObject'Stats
      in
        Data.Map.fromList [(Data.ProtoLens.Tag 1, count__field_descriptor)]
  unknownFields
    = Lens.Family2.Unchecked.lens
        _BenchObject'Stats'_unknownFields
        (\ x__ y__ -> x__ {_BenchObject'Stats'_unknownFields = y__})
  defMessage
    = BenchObject'Stats'_constructor
        {_BenchObject'Stats'count = Data.ProtoLens.fieldDefault,
         _BenchObject'Stats'_unknownFields = []}
  parseMessage
    = let
        loop ::
          BenchObject'Stats
          -> Data.ProtoLens.Encoding.Bytes.Parser BenchObject'Stats
        loop x
          = do end <- Data.ProtoLens.Encoding.Bytes.atEnd
               if end then
                   do (let missing = []
                       in
                         if Prelude.null missing then
                             Prelude.return ()
                         else
                             Prelude.fail
                               ((Prelude.++)
                                  "Missing required fields: "
                                  (Prelude.show (missing :: [Prelude.String]))))
                      Prelude.return
                        (Lens.Family2.over
                           Data.ProtoLens.unknownFields (\ !t -> Prelude.reverse t) x)
               else
                   do tag <- Data.ProtoLens.Encoding.Bytes.getVarInt
                      case tag of
                        8 -> do y <- (Data.ProtoLens.Encoding.Bytes.<?>)
                                       (Prelude.fmap
                                          Prelude.fromIntegral
                                          Data.ProtoLens.Encoding.Bytes.getVarInt)
                                       "count"
                                loop (Lens.Family2.set (Data.ProtoLens.Field.field @"count") y x)
                        wire
                          -> do !y <- Data.ProtoLens.Encoding.Wire.parseTaggedValueFromWire
                                        wire
                                loop
                                  (Lens.Family2.over
                                     Data.ProtoLens.unknownFields (\ !t -> (:) y t) x)
      in
        (Data.ProtoLens.Encoding.Bytes.<?>)
          (do loop Data.ProtoLens.defMessage) "Stats"
  buildMessage
    = \ _x
        -> (Data.Monoid.<>)
             (let
                _v = Lens.Family2.view (Data.ProtoLens.Field.field @"count") _x
              in
                if (Prelude.==) _v Data.ProtoLens.fieldDefault then
                    Data.Monoid.mempty
                else
                    (Data.Monoid.<>)
                      (Data.ProtoLens.Encoding.Bytes.putVarInt 8)
                      ((Prelude..)
                         Data.ProtoLens.Encoding.Bytes.putVarInt Prelude.fromIntegral _v))
             (Data.ProtoLens.Encoding.Wire.buildFieldSet
                (Lens.Family2.view Data.ProtoLens.unknownFields _x))
instance Control.DeepSeq.NFData BenchObject'Stats where
  rnf
    = \ x__
        -> Control.DeepSeq.deepseq
             (_BenchObject'Stats'_unknownFields x__)
             (Control.DeepSeq.deepseq (_BenchObject'Stats'count x__) ())
{- | Fields :
     
         * 'Proto.Protos.Bench_Fields.content' @:: Lens' BenchObject'StringContent Data.Text.Text@ -}
data BenchObject'StringContent
  = BenchObject'StringContent'_constructor {_BenchObject'StringContent'content :: !Data.Text.Text,
                                            _BenchObject'StringContent'_unknownFields :: !Data.ProtoLens.FieldSet}
  deriving stock (Prelude.Eq, Prelude.Ord)
instance Prelude.Show BenchObject'StringContent where
  showsPrec _ __x __s
    = Prelude.showChar
        '{'
        (Prelude.showString
           (Data.ProtoLens.showMessageShort __x) (Prelude.showChar '}' __s))
instance Data.ProtoLens.Field.HasField BenchObject'StringContent "content" Data.Text.Text where
  fieldOf _
    = (Prelude..)
        (Lens.Family2.Unchecked.lens
           _BenchObject'StringContent'content
           (\ x__ y__ -> x__ {_BenchObject'StringContent'content = y__}))
        Prelude.id
instance Data.ProtoLens.Message BenchObject'StringContent where
  messageName _ = Data.Text.pack "bench.BenchObject.StringContent"
  packedMessageDescriptor _
    = "\n\
      \\rStringContent\DC2\CAN\n\
      \\acontent\CAN\SOH \SOH(\tR\acontent"
  packedFileDescriptor _ = packedFileDescriptor
  fieldsByTag
    = let
        content__field_descriptor
          = Data.ProtoLens.FieldDescriptor
              "content"
              (Data.ProtoLens.ScalarField Data.ProtoLens.StringField ::
                 Data.ProtoLens.FieldTypeDescriptor Data.Text.Text)
              (Data.ProtoLens.PlainField
                 Data.ProtoLens.Optional (Data.ProtoLens.Field.field @"content")) ::
              Data.ProtoLens.FieldDescriptor BenchObject'StringContent
      in
        Data.Map.fromList
          [(Data.ProtoLens.Tag 1, content__field_descriptor)]
  unknownFields
    = Lens.Family2.Unchecked.lens
        _BenchObject'StringContent'_unknownFields
        (\ x__ y__
           -> x__ {_BenchObject'StringContent'_unknownFields = y__})
  defMessage
    = BenchObject'StringContent'_constructor
        {_BenchObject'StringContent'content = Data.ProtoLens.fieldDefault,
         _BenchObject'StringContent'_unknownFields = []}
  parseMessage
    = let
        loop ::
          BenchObject'StringContent
          -> Data.ProtoLens.Encoding.Bytes.Parser BenchObject'StringContent
        loop x
          = do end <- Data.ProtoLens.Encoding.Bytes.atEnd
               if end then
                   do (let missing = []
                       in
                         if Prelude.null missing then
                             Prelude.return ()
                         else
                             Prelude.fail
                               ((Prelude.++)
                                  "Missing required fields: "
                                  (Prelude.show (missing :: [Prelude.String]))))
                      Prelude.return
                        (Lens.Family2.over
                           Data.ProtoLens.unknownFields (\ !t -> Prelude.reverse t) x)
               else
                   do tag <- Data.ProtoLens.Encoding.Bytes.getVarInt
                      case tag of
                        10
                          -> do y <- (Data.ProtoLens.Encoding.Bytes.<?>)
                                       (do value <- do len <- Data.ProtoLens.Encoding.Bytes.getVarInt
                                                       Data.ProtoLens.Encoding.Bytes.getBytes
                                                         (Prelude.fromIntegral len)
                                           Data.ProtoLens.Encoding.Bytes.runEither
                                             (case Data.Text.Encoding.decodeUtf8' value of
                                                (Prelude.Left err)
                                                  -> Prelude.Left (Prelude.show err)
                                                (Prelude.Right r) -> Prelude.Right r))
                                       "content"
                                loop (Lens.Family2.set (Data.ProtoLens.Field.field @"content") y x)
                        wire
                          -> do !y <- Data.ProtoLens.Encoding.Wire.parseTaggedValueFromWire
                                        wire
                                loop
                                  (Lens.Family2.over
                                     Data.ProtoLens.unknownFields (\ !t -> (:) y t) x)
      in
        (Data.ProtoLens.Encoding.Bytes.<?>)
          (do loop Data.ProtoLens.defMessage) "StringContent"
  buildMessage
    = \ _x
        -> (Data.Monoid.<>)
             (let
                _v = Lens.Family2.view (Data.ProtoLens.Field.field @"content") _x
              in
                if (Prelude.==) _v Data.ProtoLens.fieldDefault then
                    Data.Monoid.mempty
                else
                    (Data.Monoid.<>)
                      (Data.ProtoLens.Encoding.Bytes.putVarInt 10)
                      ((Prelude..)
                         (\ bs
                            -> (Data.Monoid.<>)
                                 (Data.ProtoLens.Encoding.Bytes.putVarInt
                                    (Prelude.fromIntegral (Data.ByteString.length bs)))
                                 (Data.ProtoLens.Encoding.Bytes.putBytes bs))
                         Data.Text.Encoding.encodeUtf8 _v))
             (Data.ProtoLens.Encoding.Wire.buildFieldSet
                (Lens.Family2.view Data.ProtoLens.unknownFields _x))
instance Control.DeepSeq.NFData BenchObject'StringContent where
  rnf
    = \ x__
        -> Control.DeepSeq.deepseq
             (_BenchObject'StringContent'_unknownFields x__)
             (Control.DeepSeq.deepseq
                (_BenchObject'StringContent'content x__) ())
data Bench = Bench {}
instance Data.ProtoLens.Service.Types.Service Bench where
  type ServiceName Bench = "Bench"
  type ServicePackage Bench = "bench"
  type ServiceMethods Bench = '["clientStreamQuery",
                                "serverStreamQuery",
                                "unaryQuery"]
  packedServiceDescriptor _
    = "\n\
      \\ENQBench\DC26\n\
      \\n\
      \UnaryQuery\DC2\DC2.bench.BenchObject\SUB\DC2.bench.BenchObject\"\NUL\DC2?\n\
      \\DC1ServerStreamQuery\DC2\DC2.bench.BenchObject\SUB\DC2.bench.BenchObject\"\NUL0\SOH\DC2?\n\
      \\DC1ClientStreamQuery\DC2\DC2.bench.BenchObject\SUB\DC2.bench.BenchObject\"\NUL(\SOH"
instance Data.ProtoLens.Service.Types.HasMethodImpl Bench "unaryQuery" where
  type MethodName Bench "unaryQuery" = "UnaryQuery"
  type MethodInput Bench "unaryQuery" = BenchObject
  type MethodOutput Bench "unaryQuery" = BenchObject
  type MethodStreamingType Bench "unaryQuery" = 'Data.ProtoLens.Service.Types.NonStreaming
instance Data.ProtoLens.Service.Types.HasMethodImpl Bench "serverStreamQuery" where
  type MethodName Bench "serverStreamQuery" = "ServerStreamQuery"
  type MethodInput Bench "serverStreamQuery" = BenchObject
  type MethodOutput Bench "serverStreamQuery" = BenchObject
  type MethodStreamingType Bench "serverStreamQuery" = 'Data.ProtoLens.Service.Types.ServerStreaming
instance Data.ProtoLens.Service.Types.HasMethodImpl Bench "clientStreamQuery" where
  type MethodName Bench "clientStreamQuery" = "ClientStreamQuery"
  type MethodInput Bench "clientStreamQuery" = BenchObject
  type MethodOutput Bench "clientStreamQuery" = BenchObject
  type MethodStreamingType Bench "clientStreamQuery" = 'Data.ProtoLens.Service.Types.ClientStreaming
packedFileDescriptor :: Data.ByteString.ByteString
packedFileDescriptor
  = "\n\
    \\DC2protos/bench.proto\DC2\ENQbench\"\148\STX\n\
    \\vBenchObject\DC2:\n\
    \\astrings\CAN\SOH \ETX(\v2 .bench.BenchObject.StringContentR\astrings\DC2.\n\
    \\ENQstats\CAN\STX \SOH(\v2\CAN.bench.BenchObject.StatsR\ENQstats\DC2(\n\
    \\ETXreq\CAN\ETX \SOH(\v2\SYN.bench.BenchObject.ReqR\ETXreq\SUB)\n\
    \\rStringContent\DC2\CAN\n\
    \\acontent\CAN\SOH \SOH(\tR\acontent\SUB\GS\n\
    \\ENQStats\DC2\DC4\n\
    \\ENQcount\CAN\SOH \SOH(\ENQR\ENQcount\SUB%\n\
    \\ETXReq\DC2\RS\n\
    \\n\
    \iterations\CAN\SOH \SOH(\ENQR\n\
    \iterations2\193\SOH\n\
    \\ENQBench\DC26\n\
    \\n\
    \UnaryQuery\DC2\DC2.bench.BenchObject\SUB\DC2.bench.BenchObject\"\NUL\DC2?\n\
    \\DC1ServerStreamQuery\DC2\DC2.bench.BenchObject\SUB\DC2.bench.BenchObject\"\NUL0\SOH\DC2?\n\
    \\DC1ClientStreamQuery\DC2\DC2.bench.BenchObject\SUB\DC2.bench.BenchObject\"\NUL(\SOHJ\209\ENQ\n\
    \\ACK\DC2\EOT\NUL\NUL\ETB\SOH\n\
    \\b\n\
    \\SOH\f\DC2\ETX\NUL\NUL\DC2\n\
    \\b\n\
    \\SOH\STX\DC2\ETX\STX\NUL\SO\n\
    \\n\
    \\n\
    \\STX\ACK\NUL\DC2\EOT\EOT\NUL\b\SOH\n\
    \\n\
    \\n\
    \\ETX\ACK\NUL\SOH\DC2\ETX\EOT\b\r\n\
    \\v\n\
    \\EOT\ACK\NUL\STX\NUL\DC2\ETX\ENQ\STX6\n\
    \\f\n\
    \\ENQ\ACK\NUL\STX\NUL\SOH\DC2\ETX\ENQ\ACK\DLE\n\
    \\f\n\
    \\ENQ\ACK\NUL\STX\NUL\STX\DC2\ETX\ENQ\DC1\FS\n\
    \\f\n\
    \\ENQ\ACK\NUL\STX\NUL\ETX\DC2\ETX\ENQ'2\n\
    \\v\n\
    \\EOT\ACK\NUL\STX\SOH\DC2\ETX\ACK\STXD\n\
    \\f\n\
    \\ENQ\ACK\NUL\STX\SOH\SOH\DC2\ETX\ACK\ACK\ETB\n\
    \\f\n\
    \\ENQ\ACK\NUL\STX\SOH\STX\DC2\ETX\ACK\CAN#\n\
    \\f\n\
    \\ENQ\ACK\NUL\STX\SOH\ACK\DC2\ETX\ACK.4\n\
    \\f\n\
    \\ENQ\ACK\NUL\STX\SOH\ETX\DC2\ETX\ACK5@\n\
    \\v\n\
    \\EOT\ACK\NUL\STX\STX\DC2\ETX\a\STXD\n\
    \\f\n\
    \\ENQ\ACK\NUL\STX\STX\SOH\DC2\ETX\a\ACK\ETB\n\
    \\f\n\
    \\ENQ\ACK\NUL\STX\STX\ENQ\DC2\ETX\a\CAN\RS\n\
    \\f\n\
    \\ENQ\ACK\NUL\STX\STX\STX\DC2\ETX\a\US*\n\
    \\f\n\
    \\ENQ\ACK\NUL\STX\STX\ETX\DC2\ETX\a5@\n\
    \\n\
    \\n\
    \\STX\EOT\NUL\DC2\EOT\n\
    \\NUL\ETB\SOH\n\
    \\n\
    \\n\
    \\ETX\EOT\NUL\SOH\DC2\ETX\n\
    \\b\DC3\n\
    \\f\n\
    \\EOT\EOT\NUL\ETX\NUL\DC2\EOT\v\STX\r\ETX\n\
    \\f\n\
    \\ENQ\EOT\NUL\ETX\NUL\SOH\DC2\ETX\v\n\
    \\ETB\n\
    \\r\n\
    \\ACK\EOT\NUL\ETX\NUL\STX\NUL\DC2\ETX\f\EOT\ETB\n\
    \\SO\n\
    \\a\EOT\NUL\ETX\NUL\STX\NUL\ENQ\DC2\ETX\f\EOT\n\
    \\n\
    \\SO\n\
    \\a\EOT\NUL\ETX\NUL\STX\NUL\SOH\DC2\ETX\f\v\DC2\n\
    \\SO\n\
    \\a\EOT\NUL\ETX\NUL\STX\NUL\ETX\DC2\ETX\f\NAK\SYN\n\
    \\f\n\
    \\EOT\EOT\NUL\ETX\SOH\DC2\EOT\SO\STX\DLE\ETX\n\
    \\f\n\
    \\ENQ\EOT\NUL\ETX\SOH\SOH\DC2\ETX\SO\n\
    \\SI\n\
    \\r\n\
    \\ACK\EOT\NUL\ETX\SOH\STX\NUL\DC2\ETX\SI\EOT\DC4\n\
    \\SO\n\
    \\a\EOT\NUL\ETX\SOH\STX\NUL\ENQ\DC2\ETX\SI\EOT\t\n\
    \\SO\n\
    \\a\EOT\NUL\ETX\SOH\STX\NUL\SOH\DC2\ETX\SI\n\
    \\SI\n\
    \\SO\n\
    \\a\EOT\NUL\ETX\SOH\STX\NUL\ETX\DC2\ETX\SI\DC2\DC3\n\
    \\f\n\
    \\EOT\EOT\NUL\ETX\STX\DC2\EOT\DC1\STX\DC3\ETX\n\
    \\f\n\
    \\ENQ\EOT\NUL\ETX\STX\SOH\DC2\ETX\DC1\n\
    \\r\n\
    \\r\n\
    \\ACK\EOT\NUL\ETX\STX\STX\NUL\DC2\ETX\DC2\EOT\EM\n\
    \\SO\n\
    \\a\EOT\NUL\ETX\STX\STX\NUL\ENQ\DC2\ETX\DC2\EOT\t\n\
    \\SO\n\
    \\a\EOT\NUL\ETX\STX\STX\NUL\SOH\DC2\ETX\DC2\n\
    \\DC4\n\
    \\SO\n\
    \\a\EOT\NUL\ETX\STX\STX\NUL\ETX\DC2\ETX\DC2\ETB\CAN\n\
    \\v\n\
    \\EOT\EOT\NUL\STX\NUL\DC2\ETX\DC4\STX%\n\
    \\f\n\
    \\ENQ\EOT\NUL\STX\NUL\EOT\DC2\ETX\DC4\STX\n\
    \\n\
    \\f\n\
    \\ENQ\EOT\NUL\STX\NUL\ACK\DC2\ETX\DC4\v\CAN\n\
    \\f\n\
    \\ENQ\EOT\NUL\STX\NUL\SOH\DC2\ETX\DC4\EM \n\
    \\f\n\
    \\ENQ\EOT\NUL\STX\NUL\ETX\DC2\ETX\DC4#$\n\
    \\v\n\
    \\EOT\EOT\NUL\STX\SOH\DC2\ETX\NAK\STX\DC2\n\
    \\f\n\
    \\ENQ\EOT\NUL\STX\SOH\ACK\DC2\ETX\NAK\STX\a\n\
    \\f\n\
    \\ENQ\EOT\NUL\STX\SOH\SOH\DC2\ETX\NAK\b\r\n\
    \\f\n\
    \\ENQ\EOT\NUL\STX\SOH\ETX\DC2\ETX\NAK\DLE\DC1\n\
    \\v\n\
    \\EOT\EOT\NUL\STX\STX\DC2\ETX\SYN\STX\SO\n\
    \\f\n\
    \\ENQ\EOT\NUL\STX\STX\ACK\DC2\ETX\SYN\STX\ENQ\n\
    \\f\n\
    \\ENQ\EOT\NUL\STX\STX\SOH\DC2\ETX\SYN\ACK\t\n\
    \\f\n\
    \\ENQ\EOT\NUL\STX\STX\ETX\DC2\ETX\SYN\f\rb\ACKproto3"