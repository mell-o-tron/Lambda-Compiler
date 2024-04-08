.PHONY: compile
compile:
	mkdir -p build
	rm -f build/*
	(opam exec -- dune test --force) 2> build/out.asm

clean:
	rm -rf build
	opam exec dune clean