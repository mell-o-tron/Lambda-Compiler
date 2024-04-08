; NOTE
; We use three stacks:
;  - the builtin stack
;  - the operand stack
;  - the environment stack
;
; There is only one environment because we use dynamic scoping, for simplicity.
; 
; Here is a sketch of the memory map:
; 
; 0x0      ...   0x4FF		unusable in real mode
; 0x500    ...   0x7DFF		memory we can use for the stacks (including overwriting bootsector)
; 0x7e00   ...   0x7FFFF	second stage bootloader
;
; We divide the stack memory in three parts, each of length 0x2855
;   - [0x500,  0x2D54]
; 	- [0x2D55, 0x55A9]
;	- [0x55AA, 0x7DFF]

[org 0x7e00]
[bits 16]

%define ENVIRONMENT_POINTER ecx
%define OPERAND_POINTER edx

%macro 	push_operand 1
		mov ax, %1
		mov [OPERAND_POINTER], ax
		add OPERAND_POINTER, 2
%endmacro

%macro 	push_env 1
		mov ax, %1
		mov [ENVIRONMENT_POINTER], ax
		add ENVIRONMENT_POINTER, 2
%endmacro

%macro 	pop_operand 1
		sub OPERAND_POINTER, 2
		mov %1, [OPERAND_POINTER]
%endmacro

%macro 	pop_env 1
		sub ENVIRONMENT_POINTER, 2
		mov %1, [ENVIRONMENT_POINTER]
%endmacro



	cli
	mov ax, 0x00
	mov ds, ax
	mov es, ax
	mov ss, ax
	mov sp, 0x2D55		; stack pointer
	sti

	; setup stacks
	
	mov ENVIRONMENT_POINTER, 0x2D55
	mov OPERAND_POINTER, 0x55AA
	

mov bx, STAGING
call print_string


	; GENERATED CODE WILL BE WRITTEN HERE
push_operand fun_1
push_operand 4
push_operand 6
pop_operand ax
pop_operand bx
cmp ax, bx 
jne branch_1
push_operand 1
jmp branch_2
branch_1:
push_operand 0
branch_2:
pop_operand ax
cmp ax, 1 
jne branch_3
push_operand 3

jmp branch_4
branch_3:
push_operand 64

branch_4:
pop_operand ax
push_env ax
pop_operand ax
call ax

	
	; test print
	
	pop_operand bx
	call print_dec
	
	jmp $
	
	
fun_1:
push_operand 5
push_operand [ENVIRONMENT_POINTER - 2]
pop_operand ax
pop_operand bx
add ax, bx
push_operand ax
ret


%include"./utils/print_string.asm"
%include"./utils/print_dec.asm"

STAGING:
	db "Separation Confirmed.", 0x0A, 0x0D, 0x00

times 1024-($-$$) db 0x00
