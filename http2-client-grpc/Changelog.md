# Changelog for http2-client-grpc

## Unreleased changes

- Support connecting to unix sockets and already connected sockets. [#44](https://github.com/haskell-grpc-native/http2-grpc-haskell/pull/44)
- Make `waitReply` not rely on the background thread. Decreases latency of `rawUnary` and related queries..

## 0.8.0.0

Fork `http2-client-grpc` to drop dependency on `proto-lens`.

## 0.6.0.0

Update to http2-client-0.9.0.0

## 0.5.0.4

Use proto-lens-0.4.0.0, this change is package-list incompatible but requires no code change.

## 0.5.0.3

Add helpers for new bidirectional and general streams.

## 0.5.0.2

Add bidirectional and general streams.
