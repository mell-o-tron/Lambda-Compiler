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
%define OPERAND_POINTER edx
%define AR_AREA_POINTER esi

%define CURRENT_DEPTH 0x500

%macro 	push_operand 1
		mov edi, %1
		mov [OPERAND_POINTER], edi
		add OPERAND_POINTER, 2
%endmacro


%macro 	pop_operand 1
		sub OPERAND_POINTER, 2
		mov %1, [OPERAND_POINTER]
%endmacro

%macro 	make_record 0
		pop_operand ax		; argument
		pop_operand di		; environment (definition record)
		pop_operand bx		; function
		
		add AR_AREA_POINTER, 6
		
		mov [AR_AREA_POINTER], CURRENT_RECORD		; save caller record
		mov [AR_AREA_POINTER + 2], di				; save definition record
		mov [AR_AREA_POINTER + 4], ax				; save parameter
		
		mov CURRENT_RECORD, AR_AREA_POINTER
		inc word [CURRENT_DEPTH]
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
	
	mov word [CURRENT_DEPTH], 1

mov bx, STAGING
call print_string

; push_env print_number

; GENERATED CODE WILL BE WRITTEN HERE

; (((lam . lam . lam . (L0 + L1 + L2))5)7)9

; first compile ((lam . lam . lam . (L0 + L1 + L2))5)7

	; first compile (lam . lam . lam . (L0 + L1 + L2))5

		; first compile lam . lam . lam . (L0 + L1 + L2)		-- push function pointer and current record  -- go to compilation of test_fun
			push_operand test_fun
			push_operand CURRENT_RECORD

		; then compile 5
			push_operand 5

		; then make record and call function
			make_record
			call bx


		; now the top of the stack should contain the function with body = lam . (L0 + L1 + L2) in the environment with L2 = 5

	; then compile 7
	push_operand 7

	; then make record and call function
	make_record
	call bx
	
	; now the top of the stack should contain the function with body = (L0 + L1 + L2) in the environment with L2 = 5 and L1 = 7

; then compile 9
push_operand 9
; then make record and call function
make_record
call bx

; now top of the stack should contain result of L0 + L1 + L2


; test print
;	
pop_operand bx
call print_dec
;	
jmp $
	
	
; functions here


test_fun:		; body = lam . lam . (L0 + L1 + L2)
	; compile body	-- go to compilation of test_fun_2
	push_operand test_fun_2
	push_operand CURRENT_RECORD					; returns called function in the current environment
	
	mov CURRENT_RECORD, [CURRENT_RECORD]        ; return to the index space of the caller
	dec word [CURRENT_DEPTH]
    ret
	


test_fun_2:		; body = lam . (L0 + L1 + L2)
	; compile body	-- go to compilation of test_fun_3
	push_operand test_fun_3
	push_operand CURRENT_RECORD
	
	mov CURRENT_RECORD, [CURRENT_RECORD]        ; return to the index space of the caller
	dec word [CURRENT_DEPTH]
    ret


test_fun_3:		; body = (L0 + L1 + L2)
	mov ax, 0
	call seekle
	mov ax, 1
	call seekle
	mov ax, 2
	call seekle
	pop_operand bx
	pop_operand ax
	add ax, bx
	push_operand eax
	
	pop_operand bx
	pop_operand ax

	add ax, bx
	push_operand eax
	mov CURRENT_RECORD, [CURRENT_RECORD]        ; return to the index space of the caller
	dec word [CURRENT_DEPTH]
    ret
	
	
	
; seekle here

seekle:
	mov bx, word [CURRENT_DEPTH]
	
	;pusha
		;call print_dec
	;popa
	
	sub bx, ax
	mov ax, bx

	mov ebx, CURRENT_RECORD

	loople:
		cmp ax, 0
		je endle

		dec ax
		mov bx, [bx + 2]        ; set the record counter to the current record's definition record (parent)
		jmp loople

	endle:
		push_operand [bx + 4]  ; push the value of the actual parameter stored in the obtained record.
		pusha
		mov bx, [bx + 4]
		call print_dec
		popa
	ret


%include"./utils/print_string.asm"
%include"./utils/print_dec.asm"

;print_number:
	;pop_env bx
	;push_operand bx
	;call print_dec
	;ret

STAGING:
	db "Separation Confirmed.", 0x0A, 0x0D, 0x00

times 1024-($-$$) db 0x00
