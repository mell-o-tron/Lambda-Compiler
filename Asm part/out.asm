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


%define CURRENT_RECORD ecx
%define OPERAND_POINTER esi
%define AR_AREA_POINTER edx

%define CURRENT_RECORD_BUF  0x500
%define OPERAND_POINTER_BUF 0x502
%define AR_AREA_POINTER_BUF 0x504
%define INT_RESULT			0x506
%define CURRENT_END			0x516
%define TEMPLATE_RESULT		0x518

%macro 	push_operand 1
		mov edi, %1
		mov [OPERAND_POINTER], edi
		add OPERAND_POINTER, 2
%endmacro

%macro 	pop_operand 1
		sub OPERAND_POINTER, 2
		mov %1, [OPERAND_POINTER]
%endmacro

%macro add_integers 0
add ax, bx
push_operand eax
%endmacro

%macro mul_integers 0
mul bx
push_operand eax
%endmacro

%macro div_integers 0

push edx
push ecx
mov edx, 0
mov cx, bx
div cx
pop ecx
pop edx

push_operand eax
%endmacro

%macro 	make_record 0

		add AR_AREA_POINTER, 8
		mov [AR_AREA_POINTER + 6], word 0			; non-function check
		pop_operand ax								; argument
		mov [AR_AREA_POINTER + 4], ax				; save parameter
		pop_operand ax								; environment (definition record)
		mov [AR_AREA_POINTER + 2], ax				; save definition record
		mov eax, CURRENT_RECORD
		mov [AR_AREA_POINTER], ax					; save caller record

		pop_operand bx								; function


		mov CURRENT_RECORD, AR_AREA_POINTER
;
; 		pusha
; 		print_cur_record
; 		popa
%endmacro

%macro 	make_HO_record 0
		add AR_AREA_POINTER, 8

		pop_operand ax								; par_def_record
		mov [AR_AREA_POINTER + 6], ax
		pop_operand ax								; argument
		mov [AR_AREA_POINTER + 4], ax				; save parameter
		pop_operand ax								; environment (definition record)
		mov [AR_AREA_POINTER + 2], ax				; save definition record

		mov eax, CURRENT_RECORD

		mov [AR_AREA_POINTER], ax					; save caller record

		pop_operand bx								; function

		mov CURRENT_RECORD, AR_AREA_POINTER

; 		pusha
; 		print_cur_record
; 		popa

%endmacro

%macro 	make_funky_record 0
		add AR_AREA_POINTER, 8

		pop_operand ax								; par_def_record
		mov [AR_AREA_POINTER + 6], ax
		pop_operand ax								; argument
		mov [AR_AREA_POINTER + 4], ax				; save parameter
		pop_operand ax								; throw away the definition record lol

		mov eax, CURRENT_RECORD
		mov [AR_AREA_POINTER + 2], ax				; definition record is current record

		mov [AR_AREA_POINTER], ax					; save caller record

		pop_operand bx								; function

		mov CURRENT_RECORD, AR_AREA_POINTER

; 		pusha
; 		print_cur_record
; 		popa

%endmacro

%macro print_cur_record 0
	pusha
	mov ebx, CURRENT_RECORD
	call print_dec
	popa

	pusha
	mov bx, REC_STRING
	call print_string
	popa

	pusha
	mov bx, [CURRENT_RECORD]
	call print_dec
	popa

	pusha
	mov bx, [CURRENT_RECORD + 2]
	call print_dec
	popa

	pusha
	mov bx, [CURRENT_RECORD + 4]
	call print_dec
	popa

	pusha
	mov bx, [CURRENT_RECORD + 6]
	call print_dec
	popa

	pusha
	mov bx, NEW_LINE
	call print_string
	popa
%endmacro


%macro 	say_here 0
	pusha
	mov bx, HERE_STRING
	pusha
	call near print_string
	popa
	popa
%endmacro

%macro print_fun_pointer 1
	pusha
	mov bx, fun_%1
	call print_dec
	popa
%endmacro

%macro nl 0
	pusha
	mov bx, NEW_LINE
	call print_string
	popa
%endmacro

%macro call_debug_info 0
	pusha
	mov bx, FUN_STRING
	call print_string
	popa

	pusha
	mov bx, $
	sub bx, 9
	call print_dec
	popa

	pusha
	mov bx, NEW_LINE
	call print_string
	popa

	pusha
	mov bx, PAR_STRING
	call print_string
	popa

	mov ax, 0
	call printle
	mov ax, 1
	call printle
	mov ax, 2
	call printle

	pusha
	mov bx, NEW_LINE
	call print_string
	popa
%endmacro

%macro bufferize 0
	mov ax, word [CURRENT_RECORD]
	mov [CURRENT_RECORD_BUF], ax
	mov eax, OPERAND_POINTER
	mov [OPERAND_POINTER_BUF], ax
	mov eax, AR_AREA_POINTER
	mov [AR_AREA_POINTER_BUF], ax
%endmacro

%macro debufferize 0
	mov ax, [AR_AREA_POINTER_BUF]
	mov AR_AREA_POINTER, eax
	mov ax, [CURRENT_RECORD_BUF]
	mov CURRENT_RECORD, eax
	mov ax, [OPERAND_POINTER_BUF]
	mov OPERAND_POINTER, eax
%endmacro

%macro call_interrupt 1
pop_operand ax
shl ax, 8
or ax, 0xcd
mov [should_call_here_%1], ax

pop_operand al
pop_operand ah
pop_operand bl
pop_operand bh
pop_operand cl
pop_operand ch
pop_operand dl
pop_operand dh

should_call_here_%1:
dw 0

mov [INT_RESULT], al
mov [INT_RESULT + 2], ah
mov [INT_RESULT + 4], bl
mov [INT_RESULT + 6], bh
mov [INT_RESULT + 8], cl
mov [INT_RESULT + 10], ch
mov [INT_RESULT + 12], dl
mov [INT_RESULT + 14], dh
%endmacro


%macro call_callback 0
call template_create_tuple
push_operand CURRENT_RECORD

make_funky_record

;
; pusha
; print_cur_record
; popa

call bx
debufferize
%endmacro

	cli
	mov ax, 0x00
	mov ds, ax
	mov es, ax
	mov ss, ax
	mov sp, 0x2D55		; stack pointer
	sti

	; setup stacks, TODO rescale these (also have [0x500,  0x2D50])

	mov AR_AREA_POINTER, 0x2D55
	mov OPERAND_POINTER, 0x55AA
	mov CURRENT_RECORD, AR_AREA_POINTER
	mov word [CURRENT_END], start_of_end

mov bx, STAGING
call print_string



; push_env print_number

; GENERATED CODE WILL BE WRITTEN HERE
push_operand fun_5
push_operand CURRENT_RECORD
push_operand fun_8
push_operand CURRENT_RECORD
make_HO_record
call bx
debufferize
push_operand 65
make_record
call bx
debufferize

; test print

pop_operand bx
call print_dec



mov bx, END_STRING
call print_string

jmp $

death:

mov bx, DEAD_STRING
call print_string

jmp $
fun_5:
push_operand fun_2
push_operand CURRENT_RECORD
push_operand fun_4
push_operand CURRENT_RECORD
make_HO_record
call bx
debufferize
bufferize
ret

fun_2:
mov ax, 1
call seekle
push_operand fun_1
push_operand CURRENT_RECORD
make_HO_record
call bx
debufferize
bufferize
ret

fun_1:
mov ax, 1
call seekle
mov ax, 1
call seekle
make_HO_record
call bx
debufferize
mov ax, 0
call seekle
make_record
call bx
debufferize
bufferize
ret

fun_4:
mov ax, 1
call seekle
push_operand fun_3
push_operand CURRENT_RECORD
make_HO_record
call bx
debufferize
bufferize
ret

fun_3:
mov ax, 1
call seekle
mov ax, 1
call seekle
make_HO_record
call bx
debufferize
mov ax, 0
call seekle
make_record
call bx
debufferize
bufferize
ret

fun_8:
push_operand fun_7
push_operand CURRENT_RECORD
bufferize
ret

fun_7:
push_operand fun_6_tuple
push_operand CURRENT_RECORD
push_operand 8
make_record
call bx
debufferize
push_operand fun_6_tuple
push_operand CURRENT_RECORD
push_operand 7
make_record
call bx
debufferize
push_operand fun_6_tuple
push_operand CURRENT_RECORD
push_operand 6
make_record
call bx
debufferize
push_operand fun_6_tuple
push_operand CURRENT_RECORD
push_operand 5
make_record
call bx
debufferize
push_operand fun_6_tuple
push_operand CURRENT_RECORD
push_operand 4
make_record
call bx
debufferize
push_operand fun_6_tuple
push_operand CURRENT_RECORD
push_operand 3
make_record
call bx
debufferize
push_operand fun_6_tuple
push_operand CURRENT_RECORD
push_operand 2
make_record
call bx
debufferize
push_operand fun_6_tuple
push_operand CURRENT_RECORD
push_operand 1
make_record
call bx
debufferize
push_operand fun_6_tuple
push_operand CURRENT_RECORD
push_operand 0
make_record
call bx
debufferize
pusha
call_interrupt branch_1_else
popa
push_operand fun_6_tuple
push_operand CURRENT_RECORD
push_operand 9
make_record
call bx
debufferize
call_callback
bufferize
ret

fun_6_tuple:
mov ax, 0
call seekle
pop_operand ax
cmp ax, 0
je branch_11_switch
cmp ax, 1
je branch_10_switch
cmp ax, 2
je branch_9_switch
cmp ax, 3
je branch_8_switch
cmp ax, 4
je branch_7_switch
cmp ax, 5
je branch_6_switch
cmp ax, 6
je branch_5_switch
cmp ax, 7
je branch_4_switch
cmp ax, 8
je branch_3_switch
cmp ax, 9
je branch_2_switch
jmp death
branch_11_switch:
push_operand 16
bufferize
ret
branch_10_switch:
mov ax, 1
call seekle
bufferize
ret
branch_9_switch:
push_operand 14
bufferize
ret
branch_8_switch:
push_operand 0
bufferize
ret
branch_7_switch:
push_operand 0
bufferize
ret
branch_6_switch:
push_operand 0
bufferize
ret
branch_5_switch:
push_operand 0
bufferize
ret
branch_4_switch:
push_operand 0
bufferize
ret
branch_3_switch:
push_operand 0
bufferize
ret
branch_2_switch:
mov ax, 2
call seekle
mov ax, 1
call seekle
;optimized
mov bx, 1
pop_operand ax
add_integers
make_record
call bx
debufferize
bufferize
ret
bufferize
ret

; seekle here

seekle:
	;mov bx, word [CURRENT_DEPTH]
	;dec bx
	;sub bx, ax
	;mov ax, bx

	mov ebx, CURRENT_RECORD

	loople:
		cmp ax, 0
		je endle

		dec ax
		mov bx, [bx + 2]        ; set the record counter to the current record's definition record (parent)
		jmp loople

	endle:
		push_operand [bx + 4]  ; push the value of the actual parameter stored in the obtained record.

		;pusha
		;mov bx, [bx + 4]
		;call print_dec
		;popa

		cmp [bx + 6], word 0
		je veryendle
		push_operand [bx + 6]
	veryendle:
	ret


printle:
	mov ebx, CURRENT_RECORD

	priple:
		cmp ax, 0
		je prindle

		dec ax
		mov bx, [bx + 2]        ; set the record counter to the current record's definition record (parent)
		jmp priple

	prindle:
		pusha
		mov bx, [bx + 4]
		call print_dec
		popa
	ret


; template_create_tuple

template_create_tuple:

push ax
pusha

mov ax, [INT_RESULT]
mov [templ_param_0], ax

mov ax, [INT_RESULT + 2]
mov [templ_param_1], ax

mov ax, [INT_RESULT + 4]
mov [templ_param_2], ax

mov ax, [INT_RESULT + 6]
mov [templ_param_3], ax

mov ax, [INT_RESULT + 8]
mov [templ_param_4], ax

mov ax, [INT_RESULT + 10]
mov [templ_param_5], ax

mov ax, [INT_RESULT + 12]
mov [templ_param_6], ax

mov ax, [INT_RESULT + 14]
mov [templ_param_7], ax


xor eax, eax
xor ebx, ebx
mov ax, fckin_template
mov bx, [CURRENT_END]
mov [TEMPLATE_RESULT], bx


copy_loop:

; pusha
; mov bx, ax
; call print_dec
; popa

mov cx, [eax]
mov [ebx], cx
add ax, 2
add bx, 2

cmp ax, fckin_end
jb copy_loop

popa
mov ax, [TEMPLATE_RESULT]
push_operand eax
pop ax

pusha
mov eax, [CURRENT_END]
add eax, fckin_end - fckin_template + 2
mov word [CURRENT_END], ax
popa
ret


fckin_template:

mov ax, 0
mov bx, seekle
call bx

pop_operand ax

cmp ax, 0
je near templ_jmp_0
cmp ax, 1
je near templ_jmp_1
cmp ax, 2
je near templ_jmp_2
cmp ax, 3
je near templ_jmp_3
cmp ax, 4
je near templ_jmp_4
cmp ax, 5
je near templ_jmp_5
cmp ax, 6
je near templ_jmp_6
cmp ax, 7
je near templ_jmp_7
jmp death 				;;;; WRANGZ

templ_jmp_0:
db 0x66, 0xbf
templ_param_0:
dw 10
dw 0
mov [OPERAND_POINTER], edi
add OPERAND_POINTER, 2

bufferize
ret

templ_jmp_1:
db 0x66, 0xbf
templ_param_1:
dw 11
dw 0
mov [OPERAND_POINTER], edi
add OPERAND_POINTER, 2

bufferize
ret

templ_jmp_2:
db 0x66, 0xbf
templ_param_2:
dw 12
dw 0
mov [OPERAND_POINTER], edi
add OPERAND_POINTER, 2

bufferize
ret

templ_jmp_3:
db 0x66, 0xbf
templ_param_3:
dw 13
dw 0
mov [OPERAND_POINTER], edi
add OPERAND_POINTER, 2

bufferize
ret

templ_jmp_4:

db 0x66, 0xbf
templ_param_4:
dw 14
dw 0
mov [OPERAND_POINTER], edi
add OPERAND_POINTER, 2
pusha
mov bx, 10
mov ax, print_dec
call ax
popa

bufferize
ret

templ_jmp_5:
db 0x66, 0xbf
templ_param_5:
dw 15
dw 0
mov [OPERAND_POINTER], edi
add OPERAND_POINTER, 2

bufferize
ret

templ_jmp_6:
db 0x66, 0xbf
templ_param_6:
dw 16
dw 0
mov [OPERAND_POINTER], edi
add OPERAND_POINTER, 2

bufferize
ret

templ_jmp_7:
db 0x66, 0xbf
templ_param_7:
dw 17
dw 0
mov [OPERAND_POINTER], edi
add OPERAND_POINTER, 2

bufferize
ret

fckin_end:
dw 0, 0


%include"./utils/print_string.asm"
%include"./utils/print_dec.asm"

;print_number:
	;pop_env bx
	;push_operand bx
	;call print_dec
	;ret

STAGING:
	db "Separation Confirmed.", 0x0A, 0x0D, 0x00

HERE_STRING:
	db "Here!", 0x0A, 0x0D, 0x00

END_STRING:
	db "End.", 0x0A, 0x0D, 0x00

DEAD_STRING:
	db "Ded.", 0x0A, 0x0D, 0x00

FUN_STRING:
	db "Fun: ", 0x00

PAR_STRING:
	db "Par: ", 0x00

REC_STRING:
	db "Rec: ", 0x00

OP_STRING:
	db "Op: ", 0x00

NEW_LINE:
	db 0x0A, 0x0D, 0x00


start_of_end:

times 18432-($-$$) db 0x00
