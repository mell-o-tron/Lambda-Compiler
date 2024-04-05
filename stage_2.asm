[org 0x7e00]
[bits 16]

	; STACK SETUP
	; NOTE:
	; 	I made this separate from the one in stage 1, so that we can change the stack pointer more easily
	;	when writing the code for the environment stack

	cli
	mov ax, 0x00
	mov ds, ax
	mov es, ax
	mov ss, ax
	mov sp, 0x7C00		; stack pointer
	sti

	; TODO setup environment stack
	; idea: use some register that we won't use (like DX) to hold the pointer to the top of the environment stack

mov bx, STAGING
call print_string


	; GENERATED CODE WILL BE WRITTEN HERE


jmp $

%include"./utils/print_string.asm"

STAGING:
	db "Separation Confirmed.", 0x0A, 0x0D, 0x00

times 1024-($-$$) db 0x00
