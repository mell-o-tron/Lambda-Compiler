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

%endmacro

%macro print_cur_record 0
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
make_HO_record

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
pusha
push_operand fun_1_tuple
push_operand CURRENT_RECORD
push_operand 8
make_record
call bx
debufferize
push_operand fun_1_tuple
push_operand CURRENT_RECORD
push_operand 7
make_record
call bx
debufferize
push_operand fun_1_tuple
push_operand CURRENT_RECORD
push_operand 6
make_record
call bx
debufferize
push_operand fun_1_tuple
push_operand CURRENT_RECORD
push_operand 5
make_record
call bx
debufferize
push_operand fun_1_tuple
push_operand CURRENT_RECORD
push_operand 4
make_record
call bx
debufferize
push_operand fun_1_tuple
push_operand CURRENT_RECORD
push_operand 3
make_record
call bx
debufferize
push_operand fun_1_tuple
push_operand CURRENT_RECORD
push_operand 2
make_record
call bx
debufferize
push_operand fun_1_tuple
push_operand CURRENT_RECORD
push_operand 1
make_record
call bx
debufferize
push_operand fun_1_tuple
push_operand CURRENT_RECORD
push_operand 0
make_record
call bx
debufferize
call_interrupt branch_1_else
popa
push_operand fun_1_tuple
push_operand CURRENT_RECORD
push_operand 9
make_record
call bx
debufferize
call_callback

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
fun_1_tuple:
mov ax, 0
call seekle
;optimized
mov bx, 0
pop_operand ax
cmp ax, bx 
jne branch_2_cmp_fail
push_operand 1 ; cmp true
jmp branch_3_end_cmp
branch_2_cmp_fail:
push_operand 0 ; cmp false
branch_3_end_cmp:
pop_operand ax
cmp ax, 1 
jne branch_327_else
; then:
push_operand 16

jmp branch_328_endif
branch_327_else:
; else:
mov ax, 0
call seekle
;optimized
mov bx, 1
pop_operand ax
cmp ax, bx 
jne branch_4_cmp_fail
push_operand 1 ; cmp true
jmp branch_5_end_cmp
branch_4_cmp_fail:
push_operand 0 ; cmp false
branch_5_end_cmp:
pop_operand ax
cmp ax, 1 
jne branch_325_else
; then:
push_operand 66

jmp branch_326_endif
branch_325_else:
; else:
mov ax, 0
call seekle
;optimized
mov bx, 2
pop_operand ax
cmp ax, bx 
jne branch_6_cmp_fail
push_operand 1 ; cmp true
jmp branch_7_end_cmp
branch_6_cmp_fail:
push_operand 0 ; cmp false
branch_7_end_cmp:
pop_operand ax
cmp ax, 1 
jne branch_323_else
; then:
push_operand 14

jmp branch_324_endif
branch_323_else:
; else:
mov ax, 0
call seekle
;optimized
mov bx, 3
pop_operand ax
cmp ax, bx 
jne branch_8_cmp_fail
push_operand 1 ; cmp true
jmp branch_9_end_cmp
branch_8_cmp_fail:
push_operand 0 ; cmp false
branch_9_end_cmp:
pop_operand ax
cmp ax, 1 
jne branch_321_else
; then:
push_operand 0

jmp branch_322_endif
branch_321_else:
; else:
mov ax, 0
call seekle
;optimized
mov bx, 4
pop_operand ax
cmp ax, bx 
jne branch_10_cmp_fail
push_operand 1 ; cmp true
jmp branch_11_end_cmp
branch_10_cmp_fail:
push_operand 0 ; cmp false
branch_11_end_cmp:
pop_operand ax
cmp ax, 1 
jne branch_319_else
; then:
push_operand 0

jmp branch_320_endif
branch_319_else:
; else:
mov ax, 0
call seekle
;optimized
mov bx, 5
pop_operand ax
cmp ax, bx 
jne branch_12_cmp_fail
push_operand 1 ; cmp true
jmp branch_13_end_cmp
branch_12_cmp_fail:
push_operand 0 ; cmp false
branch_13_end_cmp:
pop_operand ax
cmp ax, 1 
jne branch_317_else
; then:
push_operand 0

jmp branch_318_endif
branch_317_else:
; else:
mov ax, 0
call seekle
;optimized
mov bx, 6
pop_operand ax
cmp ax, bx 
jne branch_14_cmp_fail
push_operand 1 ; cmp true
jmp branch_15_end_cmp
branch_14_cmp_fail:
push_operand 0 ; cmp false
branch_15_end_cmp:
pop_operand ax
cmp ax, 1 
jne branch_315_else
; then:
push_operand 0

jmp branch_316_endif
branch_315_else:
; else:
mov ax, 0
call seekle
;optimized
mov bx, 7
pop_operand ax
cmp ax, bx 
jne branch_16_cmp_fail
push_operand 1 ; cmp true
jmp branch_17_end_cmp
branch_16_cmp_fail:
push_operand 0 ; cmp false
branch_17_end_cmp:
pop_operand ax
cmp ax, 1 
jne branch_313_else
; then:
push_operand 0

jmp branch_314_endif
branch_313_else:
; else:
mov ax, 0
call seekle
;optimized
mov bx, 8
pop_operand ax
cmp ax, bx 
jne branch_18_cmp_fail
push_operand 1 ; cmp true
jmp branch_19_end_cmp
branch_18_cmp_fail:
push_operand 0 ; cmp false
branch_19_end_cmp:
pop_operand ax
cmp ax, 1 
jne branch_311_else
; then:
push_operand 0

jmp branch_312_endif
branch_311_else:
; else:
mov ax, 0
call seekle
;optimized
mov bx, 9
pop_operand ax
cmp ax, bx 
jne branch_20_cmp_fail
push_operand 1 ; cmp true
jmp branch_21_end_cmp
branch_20_cmp_fail:
push_operand 0 ; cmp false
branch_21_end_cmp:
pop_operand ax
cmp ax, 1 
jne branch_309_else
; then:
push_operand fun_16
push_operand CURRENT_RECORD

jmp branch_310_endif
branch_309_else:
; else:
jmp death
branch_310_endif:

branch_312_endif:

branch_314_endif:

branch_316_endif:

branch_318_endif:

branch_320_endif:

branch_322_endif:

branch_324_endif:

branch_326_endif:

branch_328_endif:
bufferize
ret

fun_16:
pusha
push_operand fun_2_tuple
push_operand CURRENT_RECORD
push_operand 8
make_record
call bx
debufferize
push_operand fun_2_tuple
push_operand CURRENT_RECORD
push_operand 7
make_record
call bx
debufferize
push_operand fun_2_tuple
push_operand CURRENT_RECORD
push_operand 6
make_record
call bx
debufferize
push_operand fun_2_tuple
push_operand CURRENT_RECORD
push_operand 5
make_record
call bx
debufferize
push_operand fun_2_tuple
push_operand CURRENT_RECORD
push_operand 4
make_record
call bx
debufferize
push_operand fun_2_tuple
push_operand CURRENT_RECORD
push_operand 3
make_record
call bx
debufferize
push_operand fun_2_tuple
push_operand CURRENT_RECORD
push_operand 2
make_record
call bx
debufferize
push_operand fun_2_tuple
push_operand CURRENT_RECORD
push_operand 1
make_record
call bx
debufferize
push_operand fun_2_tuple
push_operand CURRENT_RECORD
push_operand 0
make_record
call bx
debufferize
call_interrupt branch_22_else
popa
push_operand fun_2_tuple
push_operand CURRENT_RECORD
push_operand 9
make_record
call bx
debufferize
call_callback
bufferize
ret

fun_2_tuple:
mov ax, 0
call seekle
;optimized
mov bx, 0
pop_operand ax
cmp ax, bx 
jne branch_23_cmp_fail
push_operand 1 ; cmp true
jmp branch_24_end_cmp
branch_23_cmp_fail:
push_operand 0 ; cmp false
branch_24_end_cmp:
pop_operand ax
cmp ax, 1 
jne branch_307_else
; then:
push_operand 16

jmp branch_308_endif
branch_307_else:
; else:
mov ax, 0
call seekle
;optimized
mov bx, 1
pop_operand ax
cmp ax, bx 
jne branch_25_cmp_fail
push_operand 1 ; cmp true
jmp branch_26_end_cmp
branch_25_cmp_fail:
push_operand 0 ; cmp false
branch_26_end_cmp:
pop_operand ax
cmp ax, 1 
jne branch_305_else
; then:
push_operand 97

jmp branch_306_endif
branch_305_else:
; else:
mov ax, 0
call seekle
;optimized
mov bx, 2
pop_operand ax
cmp ax, bx 
jne branch_27_cmp_fail
push_operand 1 ; cmp true
jmp branch_28_end_cmp
branch_27_cmp_fail:
push_operand 0 ; cmp false
branch_28_end_cmp:
pop_operand ax
cmp ax, 1 
jne branch_303_else
; then:
push_operand 14

jmp branch_304_endif
branch_303_else:
; else:
mov ax, 0
call seekle
;optimized
mov bx, 3
pop_operand ax
cmp ax, bx 
jne branch_29_cmp_fail
push_operand 1 ; cmp true
jmp branch_30_end_cmp
branch_29_cmp_fail:
push_operand 0 ; cmp false
branch_30_end_cmp:
pop_operand ax
cmp ax, 1 
jne branch_301_else
; then:
push_operand 0

jmp branch_302_endif
branch_301_else:
; else:
mov ax, 0
call seekle
;optimized
mov bx, 4
pop_operand ax
cmp ax, bx 
jne branch_31_cmp_fail
push_operand 1 ; cmp true
jmp branch_32_end_cmp
branch_31_cmp_fail:
push_operand 0 ; cmp false
branch_32_end_cmp:
pop_operand ax
cmp ax, 1 
jne branch_299_else
; then:
push_operand 0

jmp branch_300_endif
branch_299_else:
; else:
mov ax, 0
call seekle
;optimized
mov bx, 5
pop_operand ax
cmp ax, bx 
jne branch_33_cmp_fail
push_operand 1 ; cmp true
jmp branch_34_end_cmp
branch_33_cmp_fail:
push_operand 0 ; cmp false
branch_34_end_cmp:
pop_operand ax
cmp ax, 1 
jne branch_297_else
; then:
push_operand 0

jmp branch_298_endif
branch_297_else:
; else:
mov ax, 0
call seekle
;optimized
mov bx, 6
pop_operand ax
cmp ax, bx 
jne branch_35_cmp_fail
push_operand 1 ; cmp true
jmp branch_36_end_cmp
branch_35_cmp_fail:
push_operand 0 ; cmp false
branch_36_end_cmp:
pop_operand ax
cmp ax, 1 
jne branch_295_else
; then:
push_operand 0

jmp branch_296_endif
branch_295_else:
; else:
mov ax, 0
call seekle
;optimized
mov bx, 7
pop_operand ax
cmp ax, bx 
jne branch_37_cmp_fail
push_operand 1 ; cmp true
jmp branch_38_end_cmp
branch_37_cmp_fail:
push_operand 0 ; cmp false
branch_38_end_cmp:
pop_operand ax
cmp ax, 1 
jne branch_293_else
; then:
push_operand 0

jmp branch_294_endif
branch_293_else:
; else:
mov ax, 0
call seekle
;optimized
mov bx, 8
pop_operand ax
cmp ax, bx 
jne branch_39_cmp_fail
push_operand 1 ; cmp true
jmp branch_40_end_cmp
branch_39_cmp_fail:
push_operand 0 ; cmp false
branch_40_end_cmp:
pop_operand ax
cmp ax, 1 
jne branch_291_else
; then:
push_operand 0

jmp branch_292_endif
branch_291_else:
; else:
mov ax, 0
call seekle
;optimized
mov bx, 9
pop_operand ax
cmp ax, bx 
jne branch_41_cmp_fail
push_operand 1 ; cmp true
jmp branch_42_end_cmp
branch_41_cmp_fail:
push_operand 0 ; cmp false
branch_42_end_cmp:
pop_operand ax
cmp ax, 1 
jne branch_289_else
; then:
push_operand fun_15
push_operand CURRENT_RECORD

jmp branch_290_endif
branch_289_else:
; else:
jmp death
branch_290_endif:

branch_292_endif:

branch_294_endif:

branch_296_endif:

branch_298_endif:

branch_300_endif:

branch_302_endif:

branch_304_endif:

branch_306_endif:

branch_308_endif:
bufferize
ret

fun_15:
pusha
push_operand fun_3_tuple
push_operand CURRENT_RECORD
push_operand 8
make_record
call bx
debufferize
push_operand fun_3_tuple
push_operand CURRENT_RECORD
push_operand 7
make_record
call bx
debufferize
push_operand fun_3_tuple
push_operand CURRENT_RECORD
push_operand 6
make_record
call bx
debufferize
push_operand fun_3_tuple
push_operand CURRENT_RECORD
push_operand 5
make_record
call bx
debufferize
push_operand fun_3_tuple
push_operand CURRENT_RECORD
push_operand 4
make_record
call bx
debufferize
push_operand fun_3_tuple
push_operand CURRENT_RECORD
push_operand 3
make_record
call bx
debufferize
push_operand fun_3_tuple
push_operand CURRENT_RECORD
push_operand 2
make_record
call bx
debufferize
push_operand fun_3_tuple
push_operand CURRENT_RECORD
push_operand 1
make_record
call bx
debufferize
push_operand fun_3_tuple
push_operand CURRENT_RECORD
push_operand 0
make_record
call bx
debufferize
call_interrupt branch_43_else
popa
push_operand fun_3_tuple
push_operand CURRENT_RECORD
push_operand 9
make_record
call bx
debufferize
call_callback
bufferize
ret

fun_3_tuple:
mov ax, 0
call seekle
;optimized
mov bx, 0
pop_operand ax
cmp ax, bx 
jne branch_44_cmp_fail
push_operand 1 ; cmp true
jmp branch_45_end_cmp
branch_44_cmp_fail:
push_operand 0 ; cmp false
branch_45_end_cmp:
pop_operand ax
cmp ax, 1 
jne branch_287_else
; then:
push_operand 16

jmp branch_288_endif
branch_287_else:
; else:
mov ax, 0
call seekle
;optimized
mov bx, 1
pop_operand ax
cmp ax, bx 
jne branch_46_cmp_fail
push_operand 1 ; cmp true
jmp branch_47_end_cmp
branch_46_cmp_fail:
push_operand 0 ; cmp false
branch_47_end_cmp:
pop_operand ax
cmp ax, 1 
jne branch_285_else
; then:
push_operand 110

jmp branch_286_endif
branch_285_else:
; else:
mov ax, 0
call seekle
;optimized
mov bx, 2
pop_operand ax
cmp ax, bx 
jne branch_48_cmp_fail
push_operand 1 ; cmp true
jmp branch_49_end_cmp
branch_48_cmp_fail:
push_operand 0 ; cmp false
branch_49_end_cmp:
pop_operand ax
cmp ax, 1 
jne branch_283_else
; then:
push_operand 14

jmp branch_284_endif
branch_283_else:
; else:
mov ax, 0
call seekle
;optimized
mov bx, 3
pop_operand ax
cmp ax, bx 
jne branch_50_cmp_fail
push_operand 1 ; cmp true
jmp branch_51_end_cmp
branch_50_cmp_fail:
push_operand 0 ; cmp false
branch_51_end_cmp:
pop_operand ax
cmp ax, 1 
jne branch_281_else
; then:
push_operand 0

jmp branch_282_endif
branch_281_else:
; else:
mov ax, 0
call seekle
;optimized
mov bx, 4
pop_operand ax
cmp ax, bx 
jne branch_52_cmp_fail
push_operand 1 ; cmp true
jmp branch_53_end_cmp
branch_52_cmp_fail:
push_operand 0 ; cmp false
branch_53_end_cmp:
pop_operand ax
cmp ax, 1 
jne branch_279_else
; then:
push_operand 0

jmp branch_280_endif
branch_279_else:
; else:
mov ax, 0
call seekle
;optimized
mov bx, 5
pop_operand ax
cmp ax, bx 
jne branch_54_cmp_fail
push_operand 1 ; cmp true
jmp branch_55_end_cmp
branch_54_cmp_fail:
push_operand 0 ; cmp false
branch_55_end_cmp:
pop_operand ax
cmp ax, 1 
jne branch_277_else
; then:
push_operand 0

jmp branch_278_endif
branch_277_else:
; else:
mov ax, 0
call seekle
;optimized
mov bx, 6
pop_operand ax
cmp ax, bx 
jne branch_56_cmp_fail
push_operand 1 ; cmp true
jmp branch_57_end_cmp
branch_56_cmp_fail:
push_operand 0 ; cmp false
branch_57_end_cmp:
pop_operand ax
cmp ax, 1 
jne branch_275_else
; then:
push_operand 0

jmp branch_276_endif
branch_275_else:
; else:
mov ax, 0
call seekle
;optimized
mov bx, 7
pop_operand ax
cmp ax, bx 
jne branch_58_cmp_fail
push_operand 1 ; cmp true
jmp branch_59_end_cmp
branch_58_cmp_fail:
push_operand 0 ; cmp false
branch_59_end_cmp:
pop_operand ax
cmp ax, 1 
jne branch_273_else
; then:
push_operand 0

jmp branch_274_endif
branch_273_else:
; else:
mov ax, 0
call seekle
;optimized
mov bx, 8
pop_operand ax
cmp ax, bx 
jne branch_60_cmp_fail
push_operand 1 ; cmp true
jmp branch_61_end_cmp
branch_60_cmp_fail:
push_operand 0 ; cmp false
branch_61_end_cmp:
pop_operand ax
cmp ax, 1 
jne branch_271_else
; then:
push_operand 0

jmp branch_272_endif
branch_271_else:
; else:
mov ax, 0
call seekle
;optimized
mov bx, 9
pop_operand ax
cmp ax, bx 
jne branch_62_cmp_fail
push_operand 1 ; cmp true
jmp branch_63_end_cmp
branch_62_cmp_fail:
push_operand 0 ; cmp false
branch_63_end_cmp:
pop_operand ax
cmp ax, 1 
jne branch_269_else
; then:
push_operand fun_14
push_operand CURRENT_RECORD

jmp branch_270_endif
branch_269_else:
; else:
jmp death
branch_270_endif:

branch_272_endif:

branch_274_endif:

branch_276_endif:

branch_278_endif:

branch_280_endif:

branch_282_endif:

branch_284_endif:

branch_286_endif:

branch_288_endif:
bufferize
ret

fun_14:
pusha
push_operand fun_4_tuple
push_operand CURRENT_RECORD
push_operand 8
make_record
call bx
debufferize
push_operand fun_4_tuple
push_operand CURRENT_RECORD
push_operand 7
make_record
call bx
debufferize
push_operand fun_4_tuple
push_operand CURRENT_RECORD
push_operand 6
make_record
call bx
debufferize
push_operand fun_4_tuple
push_operand CURRENT_RECORD
push_operand 5
make_record
call bx
debufferize
push_operand fun_4_tuple
push_operand CURRENT_RECORD
push_operand 4
make_record
call bx
debufferize
push_operand fun_4_tuple
push_operand CURRENT_RECORD
push_operand 3
make_record
call bx
debufferize
push_operand fun_4_tuple
push_operand CURRENT_RECORD
push_operand 2
make_record
call bx
debufferize
push_operand fun_4_tuple
push_operand CURRENT_RECORD
push_operand 1
make_record
call bx
debufferize
push_operand fun_4_tuple
push_operand CURRENT_RECORD
push_operand 0
make_record
call bx
debufferize
call_interrupt branch_64_else
popa
push_operand fun_4_tuple
push_operand CURRENT_RECORD
push_operand 9
make_record
call bx
debufferize
call_callback
bufferize
ret

fun_4_tuple:
mov ax, 0
call seekle
;optimized
mov bx, 0
pop_operand ax
cmp ax, bx 
jne branch_65_cmp_fail
push_operand 1 ; cmp true
jmp branch_66_end_cmp
branch_65_cmp_fail:
push_operand 0 ; cmp false
branch_66_end_cmp:
pop_operand ax
cmp ax, 1 
jne branch_267_else
; then:
push_operand 16

jmp branch_268_endif
branch_267_else:
; else:
mov ax, 0
call seekle
;optimized
mov bx, 1
pop_operand ax
cmp ax, bx 
jne branch_67_cmp_fail
push_operand 1 ; cmp true
jmp branch_68_end_cmp
branch_67_cmp_fail:
push_operand 0 ; cmp false
branch_68_end_cmp:
pop_operand ax
cmp ax, 1 
jne branch_265_else
; then:
push_operand 97

jmp branch_266_endif
branch_265_else:
; else:
mov ax, 0
call seekle
;optimized
mov bx, 2
pop_operand ax
cmp ax, bx 
jne branch_69_cmp_fail
push_operand 1 ; cmp true
jmp branch_70_end_cmp
branch_69_cmp_fail:
push_operand 0 ; cmp false
branch_70_end_cmp:
pop_operand ax
cmp ax, 1 
jne branch_263_else
; then:
push_operand 14

jmp branch_264_endif
branch_263_else:
; else:
mov ax, 0
call seekle
;optimized
mov bx, 3
pop_operand ax
cmp ax, bx 
jne branch_71_cmp_fail
push_operand 1 ; cmp true
jmp branch_72_end_cmp
branch_71_cmp_fail:
push_operand 0 ; cmp false
branch_72_end_cmp:
pop_operand ax
cmp ax, 1 
jne branch_261_else
; then:
push_operand 0

jmp branch_262_endif
branch_261_else:
; else:
mov ax, 0
call seekle
;optimized
mov bx, 4
pop_operand ax
cmp ax, bx 
jne branch_73_cmp_fail
push_operand 1 ; cmp true
jmp branch_74_end_cmp
branch_73_cmp_fail:
push_operand 0 ; cmp false
branch_74_end_cmp:
pop_operand ax
cmp ax, 1 
jne branch_259_else
; then:
push_operand 0

jmp branch_260_endif
branch_259_else:
; else:
mov ax, 0
call seekle
;optimized
mov bx, 5
pop_operand ax
cmp ax, bx 
jne branch_75_cmp_fail
push_operand 1 ; cmp true
jmp branch_76_end_cmp
branch_75_cmp_fail:
push_operand 0 ; cmp false
branch_76_end_cmp:
pop_operand ax
cmp ax, 1 
jne branch_257_else
; then:
push_operand 0

jmp branch_258_endif
branch_257_else:
; else:
mov ax, 0
call seekle
;optimized
mov bx, 6
pop_operand ax
cmp ax, bx 
jne branch_77_cmp_fail
push_operand 1 ; cmp true
jmp branch_78_end_cmp
branch_77_cmp_fail:
push_operand 0 ; cmp false
branch_78_end_cmp:
pop_operand ax
cmp ax, 1 
jne branch_255_else
; then:
push_operand 0

jmp branch_256_endif
branch_255_else:
; else:
mov ax, 0
call seekle
;optimized
mov bx, 7
pop_operand ax
cmp ax, bx 
jne branch_79_cmp_fail
push_operand 1 ; cmp true
jmp branch_80_end_cmp
branch_79_cmp_fail:
push_operand 0 ; cmp false
branch_80_end_cmp:
pop_operand ax
cmp ax, 1 
jne branch_253_else
; then:
push_operand 0

jmp branch_254_endif
branch_253_else:
; else:
mov ax, 0
call seekle
;optimized
mov bx, 8
pop_operand ax
cmp ax, bx 
jne branch_81_cmp_fail
push_operand 1 ; cmp true
jmp branch_82_end_cmp
branch_81_cmp_fail:
push_operand 0 ; cmp false
branch_82_end_cmp:
pop_operand ax
cmp ax, 1 
jne branch_251_else
; then:
push_operand 0

jmp branch_252_endif
branch_251_else:
; else:
mov ax, 0
call seekle
;optimized
mov bx, 9
pop_operand ax
cmp ax, bx 
jne branch_83_cmp_fail
push_operand 1 ; cmp true
jmp branch_84_end_cmp
branch_83_cmp_fail:
push_operand 0 ; cmp false
branch_84_end_cmp:
pop_operand ax
cmp ax, 1 
jne branch_249_else
; then:
push_operand fun_13
push_operand CURRENT_RECORD

jmp branch_250_endif
branch_249_else:
; else:
jmp death
branch_250_endif:

branch_252_endif:

branch_254_endif:

branch_256_endif:

branch_258_endif:

branch_260_endif:

branch_262_endif:

branch_264_endif:

branch_266_endif:

branch_268_endif:
bufferize
ret

fun_13:
pusha
push_operand fun_5_tuple
push_operand CURRENT_RECORD
push_operand 8
make_record
call bx
debufferize
push_operand fun_5_tuple
push_operand CURRENT_RECORD
push_operand 7
make_record
call bx
debufferize
push_operand fun_5_tuple
push_operand CURRENT_RECORD
push_operand 6
make_record
call bx
debufferize
push_operand fun_5_tuple
push_operand CURRENT_RECORD
push_operand 5
make_record
call bx
debufferize
push_operand fun_5_tuple
push_operand CURRENT_RECORD
push_operand 4
make_record
call bx
debufferize
push_operand fun_5_tuple
push_operand CURRENT_RECORD
push_operand 3
make_record
call bx
debufferize
push_operand fun_5_tuple
push_operand CURRENT_RECORD
push_operand 2
make_record
call bx
debufferize
push_operand fun_5_tuple
push_operand CURRENT_RECORD
push_operand 1
make_record
call bx
debufferize
push_operand fun_5_tuple
push_operand CURRENT_RECORD
push_operand 0
make_record
call bx
debufferize
call_interrupt branch_85_else
popa
push_operand fun_5_tuple
push_operand CURRENT_RECORD
push_operand 9
make_record
call bx
debufferize
call_callback
bufferize
ret

fun_5_tuple:
mov ax, 0
call seekle
;optimized
mov bx, 0
pop_operand ax
cmp ax, bx 
jne branch_86_cmp_fail
push_operand 1 ; cmp true
jmp branch_87_end_cmp
branch_86_cmp_fail:
push_operand 0 ; cmp false
branch_87_end_cmp:
pop_operand ax
cmp ax, 1 
jne branch_247_else
; then:
push_operand 16

jmp branch_248_endif
branch_247_else:
; else:
mov ax, 0
call seekle
;optimized
mov bx, 1
pop_operand ax
cmp ax, bx 
jne branch_88_cmp_fail
push_operand 1 ; cmp true
jmp branch_89_end_cmp
branch_88_cmp_fail:
push_operand 0 ; cmp false
branch_89_end_cmp:
pop_operand ax
cmp ax, 1 
jne branch_245_else
; then:
push_operand 110

jmp branch_246_endif
branch_245_else:
; else:
mov ax, 0
call seekle
;optimized
mov bx, 2
pop_operand ax
cmp ax, bx 
jne branch_90_cmp_fail
push_operand 1 ; cmp true
jmp branch_91_end_cmp
branch_90_cmp_fail:
push_operand 0 ; cmp false
branch_91_end_cmp:
pop_operand ax
cmp ax, 1 
jne branch_243_else
; then:
push_operand 14

jmp branch_244_endif
branch_243_else:
; else:
mov ax, 0
call seekle
;optimized
mov bx, 3
pop_operand ax
cmp ax, bx 
jne branch_92_cmp_fail
push_operand 1 ; cmp true
jmp branch_93_end_cmp
branch_92_cmp_fail:
push_operand 0 ; cmp false
branch_93_end_cmp:
pop_operand ax
cmp ax, 1 
jne branch_241_else
; then:
push_operand 0

jmp branch_242_endif
branch_241_else:
; else:
mov ax, 0
call seekle
;optimized
mov bx, 4
pop_operand ax
cmp ax, bx 
jne branch_94_cmp_fail
push_operand 1 ; cmp true
jmp branch_95_end_cmp
branch_94_cmp_fail:
push_operand 0 ; cmp false
branch_95_end_cmp:
pop_operand ax
cmp ax, 1 
jne branch_239_else
; then:
push_operand 0

jmp branch_240_endif
branch_239_else:
; else:
mov ax, 0
call seekle
;optimized
mov bx, 5
pop_operand ax
cmp ax, bx 
jne branch_96_cmp_fail
push_operand 1 ; cmp true
jmp branch_97_end_cmp
branch_96_cmp_fail:
push_operand 0 ; cmp false
branch_97_end_cmp:
pop_operand ax
cmp ax, 1 
jne branch_237_else
; then:
push_operand 0

jmp branch_238_endif
branch_237_else:
; else:
mov ax, 0
call seekle
;optimized
mov bx, 6
pop_operand ax
cmp ax, bx 
jne branch_98_cmp_fail
push_operand 1 ; cmp true
jmp branch_99_end_cmp
branch_98_cmp_fail:
push_operand 0 ; cmp false
branch_99_end_cmp:
pop_operand ax
cmp ax, 1 
jne branch_235_else
; then:
push_operand 0

jmp branch_236_endif
branch_235_else:
; else:
mov ax, 0
call seekle
;optimized
mov bx, 7
pop_operand ax
cmp ax, bx 
jne branch_100_cmp_fail
push_operand 1 ; cmp true
jmp branch_101_end_cmp
branch_100_cmp_fail:
push_operand 0 ; cmp false
branch_101_end_cmp:
pop_operand ax
cmp ax, 1 
jne branch_233_else
; then:
push_operand 0

jmp branch_234_endif
branch_233_else:
; else:
mov ax, 0
call seekle
;optimized
mov bx, 8
pop_operand ax
cmp ax, bx 
jne branch_102_cmp_fail
push_operand 1 ; cmp true
jmp branch_103_end_cmp
branch_102_cmp_fail:
push_operand 0 ; cmp false
branch_103_end_cmp:
pop_operand ax
cmp ax, 1 
jne branch_231_else
; then:
push_operand 0

jmp branch_232_endif
branch_231_else:
; else:
mov ax, 0
call seekle
;optimized
mov bx, 9
pop_operand ax
cmp ax, bx 
jne branch_104_cmp_fail
push_operand 1 ; cmp true
jmp branch_105_end_cmp
branch_104_cmp_fail:
push_operand 0 ; cmp false
branch_105_end_cmp:
pop_operand ax
cmp ax, 1 
jne branch_229_else
; then:
push_operand fun_12
push_operand CURRENT_RECORD

jmp branch_230_endif
branch_229_else:
; else:
jmp death
branch_230_endif:

branch_232_endif:

branch_234_endif:

branch_236_endif:

branch_238_endif:

branch_240_endif:

branch_242_endif:

branch_244_endif:

branch_246_endif:

branch_248_endif:
bufferize
ret

fun_12:
pusha
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
call_interrupt branch_106_else
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
;optimized
mov bx, 0
pop_operand ax
cmp ax, bx 
jne branch_107_cmp_fail
push_operand 1 ; cmp true
jmp branch_108_end_cmp
branch_107_cmp_fail:
push_operand 0 ; cmp false
branch_108_end_cmp:
pop_operand ax
cmp ax, 1 
jne branch_227_else
; then:
push_operand 16

jmp branch_228_endif
branch_227_else:
; else:
mov ax, 0
call seekle
;optimized
mov bx, 1
pop_operand ax
cmp ax, bx 
jne branch_109_cmp_fail
push_operand 1 ; cmp true
jmp branch_110_end_cmp
branch_109_cmp_fail:
push_operand 0 ; cmp false
branch_110_end_cmp:
pop_operand ax
cmp ax, 1 
jne branch_225_else
; then:
push_operand 97

jmp branch_226_endif
branch_225_else:
; else:
mov ax, 0
call seekle
;optimized
mov bx, 2
pop_operand ax
cmp ax, bx 
jne branch_111_cmp_fail
push_operand 1 ; cmp true
jmp branch_112_end_cmp
branch_111_cmp_fail:
push_operand 0 ; cmp false
branch_112_end_cmp:
pop_operand ax
cmp ax, 1 
jne branch_223_else
; then:
push_operand 14

jmp branch_224_endif
branch_223_else:
; else:
mov ax, 0
call seekle
;optimized
mov bx, 3
pop_operand ax
cmp ax, bx 
jne branch_113_cmp_fail
push_operand 1 ; cmp true
jmp branch_114_end_cmp
branch_113_cmp_fail:
push_operand 0 ; cmp false
branch_114_end_cmp:
pop_operand ax
cmp ax, 1 
jne branch_221_else
; then:
push_operand 0

jmp branch_222_endif
branch_221_else:
; else:
mov ax, 0
call seekle
;optimized
mov bx, 4
pop_operand ax
cmp ax, bx 
jne branch_115_cmp_fail
push_operand 1 ; cmp true
jmp branch_116_end_cmp
branch_115_cmp_fail:
push_operand 0 ; cmp false
branch_116_end_cmp:
pop_operand ax
cmp ax, 1 
jne branch_219_else
; then:
push_operand 0

jmp branch_220_endif
branch_219_else:
; else:
mov ax, 0
call seekle
;optimized
mov bx, 5
pop_operand ax
cmp ax, bx 
jne branch_117_cmp_fail
push_operand 1 ; cmp true
jmp branch_118_end_cmp
branch_117_cmp_fail:
push_operand 0 ; cmp false
branch_118_end_cmp:
pop_operand ax
cmp ax, 1 
jne branch_217_else
; then:
push_operand 0

jmp branch_218_endif
branch_217_else:
; else:
mov ax, 0
call seekle
;optimized
mov bx, 6
pop_operand ax
cmp ax, bx 
jne branch_119_cmp_fail
push_operand 1 ; cmp true
jmp branch_120_end_cmp
branch_119_cmp_fail:
push_operand 0 ; cmp false
branch_120_end_cmp:
pop_operand ax
cmp ax, 1 
jne branch_215_else
; then:
push_operand 0

jmp branch_216_endif
branch_215_else:
; else:
mov ax, 0
call seekle
;optimized
mov bx, 7
pop_operand ax
cmp ax, bx 
jne branch_121_cmp_fail
push_operand 1 ; cmp true
jmp branch_122_end_cmp
branch_121_cmp_fail:
push_operand 0 ; cmp false
branch_122_end_cmp:
pop_operand ax
cmp ax, 1 
jne branch_213_else
; then:
push_operand 0

jmp branch_214_endif
branch_213_else:
; else:
mov ax, 0
call seekle
;optimized
mov bx, 8
pop_operand ax
cmp ax, bx 
jne branch_123_cmp_fail
push_operand 1 ; cmp true
jmp branch_124_end_cmp
branch_123_cmp_fail:
push_operand 0 ; cmp false
branch_124_end_cmp:
pop_operand ax
cmp ax, 1 
jne branch_211_else
; then:
push_operand 0

jmp branch_212_endif
branch_211_else:
; else:
mov ax, 0
call seekle
;optimized
mov bx, 9
pop_operand ax
cmp ax, bx 
jne branch_125_cmp_fail
push_operand 1 ; cmp true
jmp branch_126_end_cmp
branch_125_cmp_fail:
push_operand 0 ; cmp false
branch_126_end_cmp:
pop_operand ax
cmp ax, 1 
jne branch_209_else
; then:
push_operand fun_11
push_operand CURRENT_RECORD

jmp branch_210_endif
branch_209_else:
; else:
jmp death
branch_210_endif:

branch_212_endif:

branch_214_endif:

branch_216_endif:

branch_218_endif:

branch_220_endif:

branch_222_endif:

branch_224_endif:

branch_226_endif:

branch_228_endif:
bufferize
ret

fun_11:
pusha
push_operand fun_7_tuple
push_operand CURRENT_RECORD
push_operand 8
make_record
call bx
debufferize
push_operand fun_7_tuple
push_operand CURRENT_RECORD
push_operand 7
make_record
call bx
debufferize
push_operand fun_7_tuple
push_operand CURRENT_RECORD
push_operand 6
make_record
call bx
debufferize
push_operand fun_7_tuple
push_operand CURRENT_RECORD
push_operand 5
make_record
call bx
debufferize
push_operand fun_7_tuple
push_operand CURRENT_RECORD
push_operand 4
make_record
call bx
debufferize
push_operand fun_7_tuple
push_operand CURRENT_RECORD
push_operand 3
make_record
call bx
debufferize
push_operand fun_7_tuple
push_operand CURRENT_RECORD
push_operand 2
make_record
call bx
debufferize
push_operand fun_7_tuple
push_operand CURRENT_RECORD
push_operand 1
make_record
call bx
debufferize
push_operand fun_7_tuple
push_operand CURRENT_RECORD
push_operand 0
make_record
call bx
debufferize
call_interrupt branch_127_else
popa
push_operand fun_7_tuple
push_operand CURRENT_RECORD
push_operand 9
make_record
call bx
debufferize
call_callback
bufferize
ret

fun_7_tuple:
mov ax, 0
call seekle
;optimized
mov bx, 0
pop_operand ax
cmp ax, bx 
jne branch_128_cmp_fail
push_operand 1 ; cmp true
jmp branch_129_end_cmp
branch_128_cmp_fail:
push_operand 0 ; cmp false
branch_129_end_cmp:
pop_operand ax
cmp ax, 1 
jne branch_207_else
; then:
push_operand 16

jmp branch_208_endif
branch_207_else:
; else:
mov ax, 0
call seekle
;optimized
mov bx, 1
pop_operand ax
cmp ax, bx 
jne branch_130_cmp_fail
push_operand 1 ; cmp true
jmp branch_131_end_cmp
branch_130_cmp_fail:
push_operand 0 ; cmp false
branch_131_end_cmp:
pop_operand ax
cmp ax, 1 
jne branch_205_else
; then:
push_operand 10

jmp branch_206_endif
branch_205_else:
; else:
mov ax, 0
call seekle
;optimized
mov bx, 2
pop_operand ax
cmp ax, bx 
jne branch_132_cmp_fail
push_operand 1 ; cmp true
jmp branch_133_end_cmp
branch_132_cmp_fail:
push_operand 0 ; cmp false
branch_133_end_cmp:
pop_operand ax
cmp ax, 1 
jne branch_203_else
; then:
push_operand 14

jmp branch_204_endif
branch_203_else:
; else:
mov ax, 0
call seekle
;optimized
mov bx, 3
pop_operand ax
cmp ax, bx 
jne branch_134_cmp_fail
push_operand 1 ; cmp true
jmp branch_135_end_cmp
branch_134_cmp_fail:
push_operand 0 ; cmp false
branch_135_end_cmp:
pop_operand ax
cmp ax, 1 
jne branch_201_else
; then:
push_operand 0

jmp branch_202_endif
branch_201_else:
; else:
mov ax, 0
call seekle
;optimized
mov bx, 4
pop_operand ax
cmp ax, bx 
jne branch_136_cmp_fail
push_operand 1 ; cmp true
jmp branch_137_end_cmp
branch_136_cmp_fail:
push_operand 0 ; cmp false
branch_137_end_cmp:
pop_operand ax
cmp ax, 1 
jne branch_199_else
; then:
push_operand 0

jmp branch_200_endif
branch_199_else:
; else:
mov ax, 0
call seekle
;optimized
mov bx, 5
pop_operand ax
cmp ax, bx 
jne branch_138_cmp_fail
push_operand 1 ; cmp true
jmp branch_139_end_cmp
branch_138_cmp_fail:
push_operand 0 ; cmp false
branch_139_end_cmp:
pop_operand ax
cmp ax, 1 
jne branch_197_else
; then:
push_operand 0

jmp branch_198_endif
branch_197_else:
; else:
mov ax, 0
call seekle
;optimized
mov bx, 6
pop_operand ax
cmp ax, bx 
jne branch_140_cmp_fail
push_operand 1 ; cmp true
jmp branch_141_end_cmp
branch_140_cmp_fail:
push_operand 0 ; cmp false
branch_141_end_cmp:
pop_operand ax
cmp ax, 1 
jne branch_195_else
; then:
push_operand 0

jmp branch_196_endif
branch_195_else:
; else:
mov ax, 0
call seekle
;optimized
mov bx, 7
pop_operand ax
cmp ax, bx 
jne branch_142_cmp_fail
push_operand 1 ; cmp true
jmp branch_143_end_cmp
branch_142_cmp_fail:
push_operand 0 ; cmp false
branch_143_end_cmp:
pop_operand ax
cmp ax, 1 
jne branch_193_else
; then:
push_operand 0

jmp branch_194_endif
branch_193_else:
; else:
mov ax, 0
call seekle
;optimized
mov bx, 8
pop_operand ax
cmp ax, bx 
jne branch_144_cmp_fail
push_operand 1 ; cmp true
jmp branch_145_end_cmp
branch_144_cmp_fail:
push_operand 0 ; cmp false
branch_145_end_cmp:
pop_operand ax
cmp ax, 1 
jne branch_191_else
; then:
push_operand 0

jmp branch_192_endif
branch_191_else:
; else:
mov ax, 0
call seekle
;optimized
mov bx, 9
pop_operand ax
cmp ax, bx 
jne branch_146_cmp_fail
push_operand 1 ; cmp true
jmp branch_147_end_cmp
branch_146_cmp_fail:
push_operand 0 ; cmp false
branch_147_end_cmp:
pop_operand ax
cmp ax, 1 
jne branch_189_else
; then:
push_operand fun_10
push_operand CURRENT_RECORD

jmp branch_190_endif
branch_189_else:
; else:
jmp death
branch_190_endif:

branch_192_endif:

branch_194_endif:

branch_196_endif:

branch_198_endif:

branch_200_endif:

branch_202_endif:

branch_204_endif:

branch_206_endif:

branch_208_endif:
bufferize
ret

fun_10:
pusha
push_operand fun_8_tuple
push_operand CURRENT_RECORD
push_operand 8
make_record
call bx
debufferize
push_operand fun_8_tuple
push_operand CURRENT_RECORD
push_operand 7
make_record
call bx
debufferize
push_operand fun_8_tuple
push_operand CURRENT_RECORD
push_operand 6
make_record
call bx
debufferize
push_operand fun_8_tuple
push_operand CURRENT_RECORD
push_operand 5
make_record
call bx
debufferize
push_operand fun_8_tuple
push_operand CURRENT_RECORD
push_operand 4
make_record
call bx
debufferize
push_operand fun_8_tuple
push_operand CURRENT_RECORD
push_operand 3
make_record
call bx
debufferize
push_operand fun_8_tuple
push_operand CURRENT_RECORD
push_operand 2
make_record
call bx
debufferize
push_operand fun_8_tuple
push_operand CURRENT_RECORD
push_operand 1
make_record
call bx
debufferize
push_operand fun_8_tuple
push_operand CURRENT_RECORD
push_operand 0
make_record
call bx
debufferize
call_interrupt branch_148_else
popa
push_operand fun_8_tuple
push_operand CURRENT_RECORD
push_operand 9
make_record
call bx
debufferize
call_callback
bufferize
ret

fun_8_tuple:
mov ax, 0
call seekle
;optimized
mov bx, 0
pop_operand ax
cmp ax, bx 
jne branch_149_cmp_fail
push_operand 1 ; cmp true
jmp branch_150_end_cmp
branch_149_cmp_fail:
push_operand 0 ; cmp false
branch_150_end_cmp:
pop_operand ax
cmp ax, 1 
jne branch_187_else
; then:
push_operand 16

jmp branch_188_endif
branch_187_else:
; else:
mov ax, 0
call seekle
;optimized
mov bx, 1
pop_operand ax
cmp ax, bx 
jne branch_151_cmp_fail
push_operand 1 ; cmp true
jmp branch_152_end_cmp
branch_151_cmp_fail:
push_operand 0 ; cmp false
branch_152_end_cmp:
pop_operand ax
cmp ax, 1 
jne branch_185_else
; then:
push_operand 13

jmp branch_186_endif
branch_185_else:
; else:
mov ax, 0
call seekle
;optimized
mov bx, 2
pop_operand ax
cmp ax, bx 
jne branch_153_cmp_fail
push_operand 1 ; cmp true
jmp branch_154_end_cmp
branch_153_cmp_fail:
push_operand 0 ; cmp false
branch_154_end_cmp:
pop_operand ax
cmp ax, 1 
jne branch_183_else
; then:
push_operand 14

jmp branch_184_endif
branch_183_else:
; else:
mov ax, 0
call seekle
;optimized
mov bx, 3
pop_operand ax
cmp ax, bx 
jne branch_155_cmp_fail
push_operand 1 ; cmp true
jmp branch_156_end_cmp
branch_155_cmp_fail:
push_operand 0 ; cmp false
branch_156_end_cmp:
pop_operand ax
cmp ax, 1 
jne branch_181_else
; then:
push_operand 0

jmp branch_182_endif
branch_181_else:
; else:
mov ax, 0
call seekle
;optimized
mov bx, 4
pop_operand ax
cmp ax, bx 
jne branch_157_cmp_fail
push_operand 1 ; cmp true
jmp branch_158_end_cmp
branch_157_cmp_fail:
push_operand 0 ; cmp false
branch_158_end_cmp:
pop_operand ax
cmp ax, 1 
jne branch_179_else
; then:
push_operand 0

jmp branch_180_endif
branch_179_else:
; else:
mov ax, 0
call seekle
;optimized
mov bx, 5
pop_operand ax
cmp ax, bx 
jne branch_159_cmp_fail
push_operand 1 ; cmp true
jmp branch_160_end_cmp
branch_159_cmp_fail:
push_operand 0 ; cmp false
branch_160_end_cmp:
pop_operand ax
cmp ax, 1 
jne branch_177_else
; then:
push_operand 0

jmp branch_178_endif
branch_177_else:
; else:
mov ax, 0
call seekle
;optimized
mov bx, 6
pop_operand ax
cmp ax, bx 
jne branch_161_cmp_fail
push_operand 1 ; cmp true
jmp branch_162_end_cmp
branch_161_cmp_fail:
push_operand 0 ; cmp false
branch_162_end_cmp:
pop_operand ax
cmp ax, 1 
jne branch_175_else
; then:
push_operand 0

jmp branch_176_endif
branch_175_else:
; else:
mov ax, 0
call seekle
;optimized
mov bx, 7
pop_operand ax
cmp ax, bx 
jne branch_163_cmp_fail
push_operand 1 ; cmp true
jmp branch_164_end_cmp
branch_163_cmp_fail:
push_operand 0 ; cmp false
branch_164_end_cmp:
pop_operand ax
cmp ax, 1 
jne branch_173_else
; then:
push_operand 0

jmp branch_174_endif
branch_173_else:
; else:
mov ax, 0
call seekle
;optimized
mov bx, 8
pop_operand ax
cmp ax, bx 
jne branch_165_cmp_fail
push_operand 1 ; cmp true
jmp branch_166_end_cmp
branch_165_cmp_fail:
push_operand 0 ; cmp false
branch_166_end_cmp:
pop_operand ax
cmp ax, 1 
jne branch_171_else
; then:
push_operand 0

jmp branch_172_endif
branch_171_else:
; else:
mov ax, 0
call seekle
;optimized
mov bx, 9
pop_operand ax
cmp ax, bx 
jne branch_167_cmp_fail
push_operand 1 ; cmp true
jmp branch_168_end_cmp
branch_167_cmp_fail:
push_operand 0 ; cmp false
branch_168_end_cmp:
pop_operand ax
cmp ax, 1 
jne branch_169_else
; then:
push_operand fun_9
push_operand CURRENT_RECORD

jmp branch_170_endif
branch_169_else:
; else:
jmp death
branch_170_endif:

branch_172_endif:

branch_174_endif:

branch_176_endif:

branch_178_endif:

branch_180_endif:

branch_182_endif:

branch_184_endif:

branch_186_endif:

branch_188_endif:
bufferize
ret

fun_9:
push_operand 0
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
