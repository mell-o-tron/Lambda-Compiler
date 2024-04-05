all:
	nasm -o "./bins/1.bin" first_stage.asm
	nasm -o "./bins/2.bin" stage_2.asm
	cat ./bins/1.bin ./bins/2.bin > out.bin
	qemu-system-x86_64 -drive format=raw,file="out.bin",index=0,if=floppy,  -m 128M
