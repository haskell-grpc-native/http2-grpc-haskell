# A Simple GRPC Client/Server in Haskell
This directory contains a simple Client/Server example with a single RPC call.
The Client calls the server with a list of numbers, and the server sums up these numbers and sends the answer back to the client.

# The Protobuf Definition
The protobuf definition is in a single file, *calcs.proto*.
```
syntax = "proto3";

package calcs;

service Arithmetic {
  rpc Add(CalcNumbers) returns (CalcNumber) {}
}

message CalcNumbers {
    repeated CalcNumber values = 1;
  }

message CalcNumber {
  uint32 code = 1;
}
```

Each RPC call takes a single message, and returns a single message.  In this case the request is a *CalcNumbers* and the response is a *CalcNumber*.  Protobuf allows message types to be nested.  In this case *CalcHumbers* is comprised of a list of *CalcNumber* values.  *CalcNumber* itself is a [32 bit unsigned int](https://developers.google.com/protocol-buffers/docs/proto3#scalar_value_types).

# Getting it working
The *calcs.proto* definition file is used to generate Haskell code via the *protoc* tool, which needs to be installed separately.  There are two Haskell files generated. The simplest way to build the client and server is to copy these generaeted source files to somewhere accessible within your stack package.

## Starting the Server
The server is in ArithServer.hs, and can be started from *ghci*.

~~~
stack ghci
:l ArithServer
someFunc' []
~~~

This starts the server on port 3000.

## Starting the Client
The client is ArithClient.hs and can be started as shown below:

~~~
stack ghci
ArithClient.main
~~~

The client sends a single request to the server, processes the response and terminates.
Both client and server output a few log lines to show what is happening.