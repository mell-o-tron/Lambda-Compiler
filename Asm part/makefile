all:
	cat "./logues/stage_2.asm.prologue" "../Lambda part/build/y.asm.program" "./logues/stage_2.asm.midlogue" "../Lambda part/build/y.asm.functions" "./logues/stage_2.asm.epilogue" > stage_2.asm
	./post_processor/post_proc.sh stage_2.asm
	mkdir -p ./bins
	nasm -o "./bins/1.bin" first_stage.asm
	nasm -o "./bins/2.bin" out.asm
	cat ./bins/1.bin ./bins/2.bin > out.bin
	qemu-system-x86_64 -drive format=raw,file="out.bin",index=0,if=floppy,  -m 128M

.PHONY: clean
clean:
	rm -rf "./bins/1.bin" "./bins/2.bin" stage_2.asm out.bin

run:
	mkdir -p ./bins
	nasm -o "./bins/1.bin" first_stage.asm
	nasm -o "./bins/2.bin" out.asm
	cat ./bins/1.bin ./bins/2.bin > out.bin
	qemu-system-x86_64 -drive format=raw,file="out.bin",index=0,if=floppy,  -m 128M
