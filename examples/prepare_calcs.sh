#!/bin/bash

#mkdir -p gen
#mkdir -p gen-bin
#mkdir -p protos

#curl 'https://raw.githubusercontent.com/moul/pb/master/grpcbin/grpcbin.proto' > protos/grpcbin.proto

stack install --local-bin-path=gen-bin proto-lens-protoc

protolens="`pwd`/gen-bin/proto-lens-protoc"

if [ -x "${protolens}" ]
then
	echo "using ${protolens}" ;
else
	echo "no proto-lens-protoc"
	exit 2
fi;

protoc  "--plugin=protoc-gen-haskell-protolens=${protolens}" \
	--haskell-protolens_out=./gen \
	./protos/calcs.proto

echo "# Generated modules:"
find gen -name "*.hs" | sed -e 's/gen\///' | sed -e 's/\.hs$//' | tr '/' '.'

cp -r gen/* examples/src
