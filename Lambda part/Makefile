# .PHONY: compile
# compile:
# 	mkdir -p build
# 	rm -f build/*
# 	(opam exec -- dune test --force) 2> build/out.asm

.PHONY: build
build:
	opam exec dune build

.PHONY: clean
clean:
	rm -rf build
	opam exec dune clean

.PHONY: deps
deps:
	opam install ppx_deriving
	opam install sedlex
	opam install menhir

.PHONY: test
test: build
	_build/default/test/test_Parser.exe test/lambda/y.lambda
	
run: build
	./_build/default/bin/compiler.exe test0.lambda ./build/y.asm
