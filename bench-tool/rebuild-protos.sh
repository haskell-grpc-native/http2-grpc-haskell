
protolens=`which proto-lens-protoc`
protoc  "--plugin=protoc-gen-haskell-protolens=${protolens}" \
	--haskell-protolens_out=./src \
	./protos/bench.proto
