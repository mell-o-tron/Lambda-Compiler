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

%macro call_interrupt 0
pop_operand ax
shl ax, 8
or ax, 0xcd
mov [should_print_here], ax

pop_operand al
pop_operand ah
pop_operand bl
pop_operand bh
pop_operand cl
pop_operand ch
pop_operand dl
pop_operand dh

should_print_here:
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
push_operand fun_18
push_operand CURRENT_RECORD
push_operand 8
make_record
call bx
debufferize
push_operand fun_16
push_operand CURRENT_RECORD
push_operand 7
make_record
call bx
debufferize
push_operand fun_14
push_operand CURRENT_RECORD
push_operand 6
make_record
call bx
debufferize
push_operand fun_12
push_operand CURRENT_RECORD
push_operand 5
make_record
call bx
debufferize
push_operand fun_10
push_operand CURRENT_RECORD
push_operand 4
make_record
call bx
debufferize
push_operand fun_8
push_operand CURRENT_RECORD
push_operand 3
make_record
call bx
debufferize
push_operand fun_6
push_operand CURRENT_RECORD
push_operand 2
make_record
call bx
debufferize
push_operand fun_4
push_operand CURRENT_RECORD
push_operand 1
make_record
call bx
debufferize
push_operand fun_2
push_operand CURRENT_RECORD
push_operand 0
make_record
call bx
debufferize
call_interrupt
popa
push_operand fun_20
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
fun_2:
mov ax, 0
call seekle
;optimized
mov bx, 0
pop_operand ax
cmp ax, bx 
jne branch_1_cmp_fail
push_operand 1 ; cmp true
jmp branch_2_end_cmp
branch_1_cmp_fail:
push_operand 0 ; cmp false
branch_2_end_cmp:
pop_operand ax
cmp ax, 1 
jne branch_39_else
; then:
push_operand 16

jmp branch_40_endif
branch_39_else:
; else:
mov ax, 0
call seekle
;optimized
mov bx, 1
pop_operand ax
cmp ax, bx 
jne branch_3_cmp_fail
push_operand 1 ; cmp true
jmp branch_4_end_cmp
branch_3_cmp_fail:
push_operand 0 ; cmp false
branch_4_end_cmp:
pop_operand ax
cmp ax, 1 
jne branch_37_else
; then:
push_operand 66

jmp branch_38_endif
branch_37_else:
; else:
mov ax, 0
call seekle
;optimized
mov bx, 2
pop_operand ax
cmp ax, bx 
jne branch_5_cmp_fail
push_operand 1 ; cmp true
jmp branch_6_end_cmp
branch_5_cmp_fail:
push_operand 0 ; cmp false
branch_6_end_cmp:
pop_operand ax
cmp ax, 1 
jne branch_35_else
; then:
push_operand 14

jmp branch_36_endif
branch_35_else:
; else:
mov ax, 0
call seekle
;optimized
mov bx, 3
pop_operand ax
cmp ax, bx 
jne branch_7_cmp_fail
push_operand 1 ; cmp true
jmp branch_8_end_cmp
branch_7_cmp_fail:
push_operand 0 ; cmp false
branch_8_end_cmp:
pop_operand ax
cmp ax, 1 
jne branch_33_else
; then:
push_operand 0

jmp branch_34_endif
branch_33_else:
; else:
mov ax, 0
call seekle
;optimized
mov bx, 4
pop_operand ax
cmp ax, bx 
jne branch_9_cmp_fail
push_operand 1 ; cmp true
jmp branch_10_end_cmp
branch_9_cmp_fail:
push_operand 0 ; cmp false
branch_10_end_cmp:
pop_operand ax
cmp ax, 1 
jne branch_31_else
; then:
push_operand 0

jmp branch_32_endif
branch_31_else:
; else:
mov ax, 0
call seekle
;optimized
mov bx, 5
pop_operand ax
cmp ax, bx 
jne branch_11_cmp_fail
push_operand 1 ; cmp true
jmp branch_12_end_cmp
branch_11_cmp_fail:
push_operand 0 ; cmp false
branch_12_end_cmp:
pop_operand ax
cmp ax, 1 
jne branch_29_else
; then:
push_operand 0

jmp branch_30_endif
branch_29_else:
; else:
mov ax, 0
call seekle
;optimized
mov bx, 6
pop_operand ax
cmp ax, bx 
jne branch_13_cmp_fail
push_operand 1 ; cmp true
jmp branch_14_end_cmp
branch_13_cmp_fail:
push_operand 0 ; cmp false
branch_14_end_cmp:
pop_operand ax
cmp ax, 1 
jne branch_27_else
; then:
push_operand 0

jmp branch_28_endif
branch_27_else:
; else:
mov ax, 0
call seekle
;optimized
mov bx, 7
pop_operand ax
cmp ax, bx 
jne branch_15_cmp_fail
push_operand 1 ; cmp true
jmp branch_16_end_cmp
branch_15_cmp_fail:
push_operand 0 ; cmp false
branch_16_end_cmp:
pop_operand ax
cmp ax, 1 
jne branch_25_else
; then:
push_operand 0

jmp branch_26_endif
branch_25_else:
; else:
mov ax, 0
call seekle
;optimized
mov bx, 8
pop_operand ax
cmp ax, bx 
jne branch_17_cmp_fail
push_operand 1 ; cmp true
jmp branch_18_end_cmp
branch_17_cmp_fail:
push_operand 0 ; cmp false
branch_18_end_cmp:
pop_operand ax
cmp ax, 1 
jne branch_23_else
; then:
push_operand 0

jmp branch_24_endif
branch_23_else:
; else:
mov ax, 0
call seekle
;optimized
mov bx, 9
pop_operand ax
cmp ax, bx 
jne branch_19_cmp_fail
push_operand 1 ; cmp true
jmp branch_20_end_cmp
branch_19_cmp_fail:
push_operand 0 ; cmp false
branch_20_end_cmp:
pop_operand ax
cmp ax, 1 
jne branch_21_else
; then:
push_operand fun_1
push_operand CURRENT_RECORD

jmp branch_22_endif
branch_21_else:
; else:
jmp death
branch_22_endif:

branch_24_endif:

branch_26_endif:

branch_28_endif:

branch_30_endif:

branch_32_endif:

branch_34_endif:

branch_36_endif:

branch_38_endif:

branch_40_endif:
bufferize
ret

fun_1:
push_operand 0
bufferize
ret

fun_4:
mov ax, 0
call seekle
;optimized
mov bx, 0
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
jne branch_79_else
; then:
push_operand 16

jmp branch_80_endif
branch_79_else:
; else:
mov ax, 0
call seekle
;optimized
mov bx, 1
pop_operand ax
cmp ax, bx 
jne branch_43_cmp_fail
push_operand 1 ; cmp true
jmp branch_44_end_cmp
branch_43_cmp_fail:
push_operand 0 ; cmp false
branch_44_end_cmp:
pop_operand ax
cmp ax, 1 
jne branch_77_else
; then:
push_operand 66

jmp branch_78_endif
branch_77_else:
; else:
mov ax, 0
call seekle
;optimized
mov bx, 2
pop_operand ax
cmp ax, bx 
jne branch_45_cmp_fail
push_operand 1 ; cmp true
jmp branch_46_end_cmp
branch_45_cmp_fail:
push_operand 0 ; cmp false
branch_46_end_cmp:
pop_operand ax
cmp ax, 1 
jne branch_75_else
; then:
push_operand 14

jmp branch_76_endif
branch_75_else:
; else:
mov ax, 0
call seekle
;optimized
mov bx, 3
pop_operand ax
cmp ax, bx 
jne branch_47_cmp_fail
push_operand 1 ; cmp true
jmp branch_48_end_cmp
branch_47_cmp_fail:
push_operand 0 ; cmp false
branch_48_end_cmp:
pop_operand ax
cmp ax, 1 
jne branch_73_else
; then:
push_operand 0

jmp branch_74_endif
branch_73_else:
; else:
mov ax, 0
call seekle
;optimized
mov bx, 4
pop_operand ax
cmp ax, bx 
jne branch_49_cmp_fail
push_operand 1 ; cmp true
jmp branch_50_end_cmp
branch_49_cmp_fail:
push_operand 0 ; cmp false
branch_50_end_cmp:
pop_operand ax
cmp ax, 1 
jne branch_71_else
; then:
push_operand 0

jmp branch_72_endif
branch_71_else:
; else:
mov ax, 0
call seekle
;optimized
mov bx, 5
pop_operand ax
cmp ax, bx 
jne branch_51_cmp_fail
push_operand 1 ; cmp true
jmp branch_52_end_cmp
branch_51_cmp_fail:
push_operand 0 ; cmp false
branch_52_end_cmp:
pop_operand ax
cmp ax, 1 
jne branch_69_else
; then:
push_operand 0

jmp branch_70_endif
branch_69_else:
; else:
mov ax, 0
call seekle
;optimized
mov bx, 6
pop_operand ax
cmp ax, bx 
jne branch_53_cmp_fail
push_operand 1 ; cmp true
jmp branch_54_end_cmp
branch_53_cmp_fail:
push_operand 0 ; cmp false
branch_54_end_cmp:
pop_operand ax
cmp ax, 1 
jne branch_67_else
; then:
push_operand 0

jmp branch_68_endif
branch_67_else:
; else:
mov ax, 0
call seekle
;optimized
mov bx, 7
pop_operand ax
cmp ax, bx 
jne branch_55_cmp_fail
push_operand 1 ; cmp true
jmp branch_56_end_cmp
branch_55_cmp_fail:
push_operand 0 ; cmp false
branch_56_end_cmp:
pop_operand ax
cmp ax, 1 
jne branch_65_else
; then:
push_operand 0

jmp branch_66_endif
branch_65_else:
; else:
mov ax, 0
call seekle
;optimized
mov bx, 8
pop_operand ax
cmp ax, bx 
jne branch_57_cmp_fail
push_operand 1 ; cmp true
jmp branch_58_end_cmp
branch_57_cmp_fail:
push_operand 0 ; cmp false
branch_58_end_cmp:
pop_operand ax
cmp ax, 1 
jne branch_63_else
; then:
push_operand 0

jmp branch_64_endif
branch_63_else:
; else:
mov ax, 0
call seekle
;optimized
mov bx, 9
pop_operand ax
cmp ax, bx 
jne branch_59_cmp_fail
push_operand 1 ; cmp true
jmp branch_60_end_cmp
branch_59_cmp_fail:
push_operand 0 ; cmp false
branch_60_end_cmp:
pop_operand ax
cmp ax, 1 
jne branch_61_else
; then:
push_operand fun_3
push_operand CURRENT_RECORD

jmp branch_62_endif
branch_61_else:
; else:
jmp death
branch_62_endif:

branch_64_endif:

branch_66_endif:

branch_68_endif:

branch_70_endif:

branch_72_endif:

branch_74_endif:

branch_76_endif:

branch_78_endif:

branch_80_endif:
bufferize
ret

fun_3:
push_operand 0
bufferize
ret

fun_6:
mov ax, 0
call seekle
;optimized
mov bx, 0
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
jne branch_119_else
; then:
push_operand 16

jmp branch_120_endif
branch_119_else:
; else:
mov ax, 0
call seekle
;optimized
mov bx, 1
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
jne branch_117_else
; then:
push_operand 66

jmp branch_118_endif
branch_117_else:
; else:
mov ax, 0
call seekle
;optimized
mov bx, 2
pop_operand ax
cmp ax, bx 
jne branch_85_cmp_fail
push_operand 1 ; cmp true
jmp branch_86_end_cmp
branch_85_cmp_fail:
push_operand 0 ; cmp false
branch_86_end_cmp:
pop_operand ax
cmp ax, 1 
jne branch_115_else
; then:
push_operand 14

jmp branch_116_endif
branch_115_else:
; else:
mov ax, 0
call seekle
;optimized
mov bx, 3
pop_operand ax
cmp ax, bx 
jne branch_87_cmp_fail
push_operand 1 ; cmp true
jmp branch_88_end_cmp
branch_87_cmp_fail:
push_operand 0 ; cmp false
branch_88_end_cmp:
pop_operand ax
cmp ax, 1 
jne branch_113_else
; then:
push_operand 0

jmp branch_114_endif
branch_113_else:
; else:
mov ax, 0
call seekle
;optimized
mov bx, 4
pop_operand ax
cmp ax, bx 
jne branch_89_cmp_fail
push_operand 1 ; cmp true
jmp branch_90_end_cmp
branch_89_cmp_fail:
push_operand 0 ; cmp false
branch_90_end_cmp:
pop_operand ax
cmp ax, 1 
jne branch_111_else
; then:
push_operand 0

jmp branch_112_endif
branch_111_else:
; else:
mov ax, 0
call seekle
;optimized
mov bx, 5
pop_operand ax
cmp ax, bx 
jne branch_91_cmp_fail
push_operand 1 ; cmp true
jmp branch_92_end_cmp
branch_91_cmp_fail:
push_operand 0 ; cmp false
branch_92_end_cmp:
pop_operand ax
cmp ax, 1 
jne branch_109_else
; then:
push_operand 0

jmp branch_110_endif
branch_109_else:
; else:
mov ax, 0
call seekle
;optimized
mov bx, 6
pop_operand ax
cmp ax, bx 
jne branch_93_cmp_fail
push_operand 1 ; cmp true
jmp branch_94_end_cmp
branch_93_cmp_fail:
push_operand 0 ; cmp false
branch_94_end_cmp:
pop_operand ax
cmp ax, 1 
jne branch_107_else
; then:
push_operand 0

jmp branch_108_endif
branch_107_else:
; else:
mov ax, 0
call seekle
;optimized
mov bx, 7
pop_operand ax
cmp ax, bx 
jne branch_95_cmp_fail
push_operand 1 ; cmp true
jmp branch_96_end_cmp
branch_95_cmp_fail:
push_operand 0 ; cmp false
branch_96_end_cmp:
pop_operand ax
cmp ax, 1 
jne branch_105_else
; then:
push_operand 0

jmp branch_106_endif
branch_105_else:
; else:
mov ax, 0
call seekle
;optimized
mov bx, 8
pop_operand ax
cmp ax, bx 
jne branch_97_cmp_fail
push_operand 1 ; cmp true
jmp branch_98_end_cmp
branch_97_cmp_fail:
push_operand 0 ; cmp false
branch_98_end_cmp:
pop_operand ax
cmp ax, 1 
jne branch_103_else
; then:
push_operand 0

jmp branch_104_endif
branch_103_else:
; else:
mov ax, 0
call seekle
;optimized
mov bx, 9
pop_operand ax
cmp ax, bx 
jne branch_99_cmp_fail
push_operand 1 ; cmp true
jmp branch_100_end_cmp
branch_99_cmp_fail:
push_operand 0 ; cmp false
branch_100_end_cmp:
pop_operand ax
cmp ax, 1 
jne branch_101_else
; then:
push_operand fun_5
push_operand CURRENT_RECORD

jmp branch_102_endif
branch_101_else:
; else:
jmp death
branch_102_endif:

branch_104_endif:

branch_106_endif:

branch_108_endif:

branch_110_endif:

branch_112_endif:

branch_114_endif:

branch_116_endif:

branch_118_endif:

branch_120_endif:
bufferize
ret

fun_5:
push_operand 0
bufferize
ret

fun_8:
mov ax, 0
call seekle
;optimized
mov bx, 0
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
jne branch_159_else
; then:
push_operand 16

jmp branch_160_endif
branch_159_else:
; else:
mov ax, 0
call seekle
;optimized
mov bx, 1
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
jne branch_157_else
; then:
push_operand 66

jmp branch_158_endif
branch_157_else:
; else:
mov ax, 0
call seekle
;optimized
mov bx, 2
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
jne branch_155_else
; then:
push_operand 14

jmp branch_156_endif
branch_155_else:
; else:
mov ax, 0
call seekle
;optimized
mov bx, 3
pop_operand ax
cmp ax, bx 
jne branch_127_cmp_fail
push_operand 1 ; cmp true
jmp branch_128_end_cmp
branch_127_cmp_fail:
push_operand 0 ; cmp false
branch_128_end_cmp:
pop_operand ax
cmp ax, 1 
jne branch_153_else
; then:
push_operand 0

jmp branch_154_endif
branch_153_else:
; else:
mov ax, 0
call seekle
;optimized
mov bx, 4
pop_operand ax
cmp ax, bx 
jne branch_129_cmp_fail
push_operand 1 ; cmp true
jmp branch_130_end_cmp
branch_129_cmp_fail:
push_operand 0 ; cmp false
branch_130_end_cmp:
pop_operand ax
cmp ax, 1 
jne branch_151_else
; then:
push_operand 0

jmp branch_152_endif
branch_151_else:
; else:
mov ax, 0
call seekle
;optimized
mov bx, 5
pop_operand ax
cmp ax, bx 
jne branch_131_cmp_fail
push_operand 1 ; cmp true
jmp branch_132_end_cmp
branch_131_cmp_fail:
push_operand 0 ; cmp false
branch_132_end_cmp:
pop_operand ax
cmp ax, 1 
jne branch_149_else
; then:
push_operand 0

jmp branch_150_endif
branch_149_else:
; else:
mov ax, 0
call seekle
;optimized
mov bx, 6
pop_operand ax
cmp ax, bx 
jne branch_133_cmp_fail
push_operand 1 ; cmp true
jmp branch_134_end_cmp
branch_133_cmp_fail:
push_operand 0 ; cmp false
branch_134_end_cmp:
pop_operand ax
cmp ax, 1 
jne branch_147_else
; then:
push_operand 0

jmp branch_148_endif
branch_147_else:
; else:
mov ax, 0
call seekle
;optimized
mov bx, 7
pop_operand ax
cmp ax, bx 
jne branch_135_cmp_fail
push_operand 1 ; cmp true
jmp branch_136_end_cmp
branch_135_cmp_fail:
push_operand 0 ; cmp false
branch_136_end_cmp:
pop_operand ax
cmp ax, 1 
jne branch_145_else
; then:
push_operand 0

jmp branch_146_endif
branch_145_else:
; else:
mov ax, 0
call seekle
;optimized
mov bx, 8
pop_operand ax
cmp ax, bx 
jne branch_137_cmp_fail
push_operand 1 ; cmp true
jmp branch_138_end_cmp
branch_137_cmp_fail:
push_operand 0 ; cmp false
branch_138_end_cmp:
pop_operand ax
cmp ax, 1 
jne branch_143_else
; then:
push_operand 0

jmp branch_144_endif
branch_143_else:
; else:
mov ax, 0
call seekle
;optimized
mov bx, 9
pop_operand ax
cmp ax, bx 
jne branch_139_cmp_fail
push_operand 1 ; cmp true
jmp branch_140_end_cmp
branch_139_cmp_fail:
push_operand 0 ; cmp false
branch_140_end_cmp:
pop_operand ax
cmp ax, 1 
jne branch_141_else
; then:
push_operand fun_7
push_operand CURRENT_RECORD

jmp branch_142_endif
branch_141_else:
; else:
jmp death
branch_142_endif:

branch_144_endif:

branch_146_endif:

branch_148_endif:

branch_150_endif:

branch_152_endif:

branch_154_endif:

branch_156_endif:

branch_158_endif:

branch_160_endif:
bufferize
ret

fun_7:
push_operand 0
bufferize
ret

fun_10:
mov ax, 0
call seekle
;optimized
mov bx, 0
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
jne branch_199_else
; then:
push_operand 16

jmp branch_200_endif
branch_199_else:
; else:
mov ax, 0
call seekle
;optimized
mov bx, 1
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
jne branch_197_else
; then:
push_operand 66

jmp branch_198_endif
branch_197_else:
; else:
mov ax, 0
call seekle
;optimized
mov bx, 2
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
jne branch_195_else
; then:
push_operand 14

jmp branch_196_endif
branch_195_else:
; else:
mov ax, 0
call seekle
;optimized
mov bx, 3
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
jne branch_193_else
; then:
push_operand 0

jmp branch_194_endif
branch_193_else:
; else:
mov ax, 0
call seekle
;optimized
mov bx, 4
pop_operand ax
cmp ax, bx 
jne branch_169_cmp_fail
push_operand 1 ; cmp true
jmp branch_170_end_cmp
branch_169_cmp_fail:
push_operand 0 ; cmp false
branch_170_end_cmp:
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
mov bx, 5
pop_operand ax
cmp ax, bx 
jne branch_171_cmp_fail
push_operand 1 ; cmp true
jmp branch_172_end_cmp
branch_171_cmp_fail:
push_operand 0 ; cmp false
branch_172_end_cmp:
pop_operand ax
cmp ax, 1 
jne branch_189_else
; then:
push_operand 0

jmp branch_190_endif
branch_189_else:
; else:
mov ax, 0
call seekle
;optimized
mov bx, 6
pop_operand ax
cmp ax, bx 
jne branch_173_cmp_fail
push_operand 1 ; cmp true
jmp branch_174_end_cmp
branch_173_cmp_fail:
push_operand 0 ; cmp false
branch_174_end_cmp:
pop_operand ax
cmp ax, 1 
jne branch_187_else
; then:
push_operand 0

jmp branch_188_endif
branch_187_else:
; else:
mov ax, 0
call seekle
;optimized
mov bx, 7
pop_operand ax
cmp ax, bx 
jne branch_175_cmp_fail
push_operand 1 ; cmp true
jmp branch_176_end_cmp
branch_175_cmp_fail:
push_operand 0 ; cmp false
branch_176_end_cmp:
pop_operand ax
cmp ax, 1 
jne branch_185_else
; then:
push_operand 0

jmp branch_186_endif
branch_185_else:
; else:
mov ax, 0
call seekle
;optimized
mov bx, 8
pop_operand ax
cmp ax, bx 
jne branch_177_cmp_fail
push_operand 1 ; cmp true
jmp branch_178_end_cmp
branch_177_cmp_fail:
push_operand 0 ; cmp false
branch_178_end_cmp:
pop_operand ax
cmp ax, 1 
jne branch_183_else
; then:
push_operand 0

jmp branch_184_endif
branch_183_else:
; else:
mov ax, 0
call seekle
;optimized
mov bx, 9
pop_operand ax
cmp ax, bx 
jne branch_179_cmp_fail
push_operand 1 ; cmp true
jmp branch_180_end_cmp
branch_179_cmp_fail:
push_operand 0 ; cmp false
branch_180_end_cmp:
pop_operand ax
cmp ax, 1 
jne branch_181_else
; then:
push_operand fun_9
push_operand CURRENT_RECORD

jmp branch_182_endif
branch_181_else:
; else:
jmp death
branch_182_endif:

branch_184_endif:

branch_186_endif:

branch_188_endif:

branch_190_endif:

branch_192_endif:

branch_194_endif:

branch_196_endif:

branch_198_endif:

branch_200_endif:
bufferize
ret

fun_9:
push_operand 0
bufferize
ret

fun_12:
mov ax, 0
call seekle
;optimized
mov bx, 0
pop_operand ax
cmp ax, bx 
jne branch_201_cmp_fail
push_operand 1 ; cmp true
jmp branch_202_end_cmp
branch_201_cmp_fail:
push_operand 0 ; cmp false
branch_202_end_cmp:
pop_operand ax
cmp ax, 1 
jne branch_239_else
; then:
push_operand 16

jmp branch_240_endif
branch_239_else:
; else:
mov ax, 0
call seekle
;optimized
mov bx, 1
pop_operand ax
cmp ax, bx 
jne branch_203_cmp_fail
push_operand 1 ; cmp true
jmp branch_204_end_cmp
branch_203_cmp_fail:
push_operand 0 ; cmp false
branch_204_end_cmp:
pop_operand ax
cmp ax, 1 
jne branch_237_else
; then:
push_operand 66

jmp branch_238_endif
branch_237_else:
; else:
mov ax, 0
call seekle
;optimized
mov bx, 2
pop_operand ax
cmp ax, bx 
jne branch_205_cmp_fail
push_operand 1 ; cmp true
jmp branch_206_end_cmp
branch_205_cmp_fail:
push_operand 0 ; cmp false
branch_206_end_cmp:
pop_operand ax
cmp ax, 1 
jne branch_235_else
; then:
push_operand 14

jmp branch_236_endif
branch_235_else:
; else:
mov ax, 0
call seekle
;optimized
mov bx, 3
pop_operand ax
cmp ax, bx 
jne branch_207_cmp_fail
push_operand 1 ; cmp true
jmp branch_208_end_cmp
branch_207_cmp_fail:
push_operand 0 ; cmp false
branch_208_end_cmp:
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
mov bx, 4
pop_operand ax
cmp ax, bx 
jne branch_209_cmp_fail
push_operand 1 ; cmp true
jmp branch_210_end_cmp
branch_209_cmp_fail:
push_operand 0 ; cmp false
branch_210_end_cmp:
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
mov bx, 5
pop_operand ax
cmp ax, bx 
jne branch_211_cmp_fail
push_operand 1 ; cmp true
jmp branch_212_end_cmp
branch_211_cmp_fail:
push_operand 0 ; cmp false
branch_212_end_cmp:
pop_operand ax
cmp ax, 1 
jne branch_229_else
; then:
push_operand 0

jmp branch_230_endif
branch_229_else:
; else:
mov ax, 0
call seekle
;optimized
mov bx, 6
pop_operand ax
cmp ax, bx 
jne branch_213_cmp_fail
push_operand 1 ; cmp true
jmp branch_214_end_cmp
branch_213_cmp_fail:
push_operand 0 ; cmp false
branch_214_end_cmp:
pop_operand ax
cmp ax, 1 
jne branch_227_else
; then:
push_operand 0

jmp branch_228_endif
branch_227_else:
; else:
mov ax, 0
call seekle
;optimized
mov bx, 7
pop_operand ax
cmp ax, bx 
jne branch_215_cmp_fail
push_operand 1 ; cmp true
jmp branch_216_end_cmp
branch_215_cmp_fail:
push_operand 0 ; cmp false
branch_216_end_cmp:
pop_operand ax
cmp ax, 1 
jne branch_225_else
; then:
push_operand 0

jmp branch_226_endif
branch_225_else:
; else:
mov ax, 0
call seekle
;optimized
mov bx, 8
pop_operand ax
cmp ax, bx 
jne branch_217_cmp_fail
push_operand 1 ; cmp true
jmp branch_218_end_cmp
branch_217_cmp_fail:
push_operand 0 ; cmp false
branch_218_end_cmp:
pop_operand ax
cmp ax, 1 
jne branch_223_else
; then:
push_operand 0

jmp branch_224_endif
branch_223_else:
; else:
mov ax, 0
call seekle
;optimized
mov bx, 9
pop_operand ax
cmp ax, bx 
jne branch_219_cmp_fail
push_operand 1 ; cmp true
jmp branch_220_end_cmp
branch_219_cmp_fail:
push_operand 0 ; cmp false
branch_220_end_cmp:
pop_operand ax
cmp ax, 1 
jne branch_221_else
; then:
push_operand fun_11
push_operand CURRENT_RECORD

jmp branch_222_endif
branch_221_else:
; else:
jmp death
branch_222_endif:

branch_224_endif:

branch_226_endif:

branch_228_endif:

branch_230_endif:

branch_232_endif:

branch_234_endif:

branch_236_endif:

branch_238_endif:

branch_240_endif:
bufferize
ret

fun_11:
push_operand 0
bufferize
ret

fun_14:
mov ax, 0
call seekle
;optimized
mov bx, 0
pop_operand ax
cmp ax, bx 
jne branch_241_cmp_fail
push_operand 1 ; cmp true
jmp branch_242_end_cmp
branch_241_cmp_fail:
push_operand 0 ; cmp false
branch_242_end_cmp:
pop_operand ax
cmp ax, 1 
jne branch_279_else
; then:
push_operand 16

jmp branch_280_endif
branch_279_else:
; else:
mov ax, 0
call seekle
;optimized
mov bx, 1
pop_operand ax
cmp ax, bx 
jne branch_243_cmp_fail
push_operand 1 ; cmp true
jmp branch_244_end_cmp
branch_243_cmp_fail:
push_operand 0 ; cmp false
branch_244_end_cmp:
pop_operand ax
cmp ax, 1 
jne branch_277_else
; then:
push_operand 66

jmp branch_278_endif
branch_277_else:
; else:
mov ax, 0
call seekle
;optimized
mov bx, 2
pop_operand ax
cmp ax, bx 
jne branch_245_cmp_fail
push_operand 1 ; cmp true
jmp branch_246_end_cmp
branch_245_cmp_fail:
push_operand 0 ; cmp false
branch_246_end_cmp:
pop_operand ax
cmp ax, 1 
jne branch_275_else
; then:
push_operand 14

jmp branch_276_endif
branch_275_else:
; else:
mov ax, 0
call seekle
;optimized
mov bx, 3
pop_operand ax
cmp ax, bx 
jne branch_247_cmp_fail
push_operand 1 ; cmp true
jmp branch_248_end_cmp
branch_247_cmp_fail:
push_operand 0 ; cmp false
branch_248_end_cmp:
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
mov bx, 4
pop_operand ax
cmp ax, bx 
jne branch_249_cmp_fail
push_operand 1 ; cmp true
jmp branch_250_end_cmp
branch_249_cmp_fail:
push_operand 0 ; cmp false
branch_250_end_cmp:
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
mov bx, 5
pop_operand ax
cmp ax, bx 
jne branch_251_cmp_fail
push_operand 1 ; cmp true
jmp branch_252_end_cmp
branch_251_cmp_fail:
push_operand 0 ; cmp false
branch_252_end_cmp:
pop_operand ax
cmp ax, 1 
jne branch_269_else
; then:
push_operand 0

jmp branch_270_endif
branch_269_else:
; else:
mov ax, 0
call seekle
;optimized
mov bx, 6
pop_operand ax
cmp ax, bx 
jne branch_253_cmp_fail
push_operand 1 ; cmp true
jmp branch_254_end_cmp
branch_253_cmp_fail:
push_operand 0 ; cmp false
branch_254_end_cmp:
pop_operand ax
cmp ax, 1 
jne branch_267_else
; then:
push_operand 0

jmp branch_268_endif
branch_267_else:
; else:
mov ax, 0
call seekle
;optimized
mov bx, 7
pop_operand ax
cmp ax, bx 
jne branch_255_cmp_fail
push_operand 1 ; cmp true
jmp branch_256_end_cmp
branch_255_cmp_fail:
push_operand 0 ; cmp false
branch_256_end_cmp:
pop_operand ax
cmp ax, 1 
jne branch_265_else
; then:
push_operand 0

jmp branch_266_endif
branch_265_else:
; else:
mov ax, 0
call seekle
;optimized
mov bx, 8
pop_operand ax
cmp ax, bx 
jne branch_257_cmp_fail
push_operand 1 ; cmp true
jmp branch_258_end_cmp
branch_257_cmp_fail:
push_operand 0 ; cmp false
branch_258_end_cmp:
pop_operand ax
cmp ax, 1 
jne branch_263_else
; then:
push_operand 0

jmp branch_264_endif
branch_263_else:
; else:
mov ax, 0
call seekle
;optimized
mov bx, 9
pop_operand ax
cmp ax, bx 
jne branch_259_cmp_fail
push_operand 1 ; cmp true
jmp branch_260_end_cmp
branch_259_cmp_fail:
push_operand 0 ; cmp false
branch_260_end_cmp:
pop_operand ax
cmp ax, 1 
jne branch_261_else
; then:
push_operand fun_13
push_operand CURRENT_RECORD

jmp branch_262_endif
branch_261_else:
; else:
jmp death
branch_262_endif:

branch_264_endif:

branch_266_endif:

branch_268_endif:

branch_270_endif:

branch_272_endif:

branch_274_endif:

branch_276_endif:

branch_278_endif:

branch_280_endif:
bufferize
ret

fun_13:
push_operand 0
bufferize
ret

fun_16:
mov ax, 0
call seekle
;optimized
mov bx, 0
pop_operand ax
cmp ax, bx 
jne branch_281_cmp_fail
push_operand 1 ; cmp true
jmp branch_282_end_cmp
branch_281_cmp_fail:
push_operand 0 ; cmp false
branch_282_end_cmp:
pop_operand ax
cmp ax, 1 
jne branch_319_else
; then:
push_operand 16

jmp branch_320_endif
branch_319_else:
; else:
mov ax, 0
call seekle
;optimized
mov bx, 1
pop_operand ax
cmp ax, bx 
jne branch_283_cmp_fail
push_operand 1 ; cmp true
jmp branch_284_end_cmp
branch_283_cmp_fail:
push_operand 0 ; cmp false
branch_284_end_cmp:
pop_operand ax
cmp ax, 1 
jne branch_317_else
; then:
push_operand 66

jmp branch_318_endif
branch_317_else:
; else:
mov ax, 0
call seekle
;optimized
mov bx, 2
pop_operand ax
cmp ax, bx 
jne branch_285_cmp_fail
push_operand 1 ; cmp true
jmp branch_286_end_cmp
branch_285_cmp_fail:
push_operand 0 ; cmp false
branch_286_end_cmp:
pop_operand ax
cmp ax, 1 
jne branch_315_else
; then:
push_operand 14

jmp branch_316_endif
branch_315_else:
; else:
mov ax, 0
call seekle
;optimized
mov bx, 3
pop_operand ax
cmp ax, bx 
jne branch_287_cmp_fail
push_operand 1 ; cmp true
jmp branch_288_end_cmp
branch_287_cmp_fail:
push_operand 0 ; cmp false
branch_288_end_cmp:
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
mov bx, 4
pop_operand ax
cmp ax, bx 
jne branch_289_cmp_fail
push_operand 1 ; cmp true
jmp branch_290_end_cmp
branch_289_cmp_fail:
push_operand 0 ; cmp false
branch_290_end_cmp:
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
mov bx, 5
pop_operand ax
cmp ax, bx 
jne branch_291_cmp_fail
push_operand 1 ; cmp true
jmp branch_292_end_cmp
branch_291_cmp_fail:
push_operand 0 ; cmp false
branch_292_end_cmp:
pop_operand ax
cmp ax, 1 
jne branch_309_else
; then:
push_operand 0

jmp branch_310_endif
branch_309_else:
; else:
mov ax, 0
call seekle
;optimized
mov bx, 6
pop_operand ax
cmp ax, bx 
jne branch_293_cmp_fail
push_operand 1 ; cmp true
jmp branch_294_end_cmp
branch_293_cmp_fail:
push_operand 0 ; cmp false
branch_294_end_cmp:
pop_operand ax
cmp ax, 1 
jne branch_307_else
; then:
push_operand 0

jmp branch_308_endif
branch_307_else:
; else:
mov ax, 0
call seekle
;optimized
mov bx, 7
pop_operand ax
cmp ax, bx 
jne branch_295_cmp_fail
push_operand 1 ; cmp true
jmp branch_296_end_cmp
branch_295_cmp_fail:
push_operand 0 ; cmp false
branch_296_end_cmp:
pop_operand ax
cmp ax, 1 
jne branch_305_else
; then:
push_operand 0

jmp branch_306_endif
branch_305_else:
; else:
mov ax, 0
call seekle
;optimized
mov bx, 8
pop_operand ax
cmp ax, bx 
jne branch_297_cmp_fail
push_operand 1 ; cmp true
jmp branch_298_end_cmp
branch_297_cmp_fail:
push_operand 0 ; cmp false
branch_298_end_cmp:
pop_operand ax
cmp ax, 1 
jne branch_303_else
; then:
push_operand 0

jmp branch_304_endif
branch_303_else:
; else:
mov ax, 0
call seekle
;optimized
mov bx, 9
pop_operand ax
cmp ax, bx 
jne branch_299_cmp_fail
push_operand 1 ; cmp true
jmp branch_300_end_cmp
branch_299_cmp_fail:
push_operand 0 ; cmp false
branch_300_end_cmp:
pop_operand ax
cmp ax, 1 
jne branch_301_else
; then:
push_operand fun_15
push_operand CURRENT_RECORD

jmp branch_302_endif
branch_301_else:
; else:
jmp death
branch_302_endif:

branch_304_endif:

branch_306_endif:

branch_308_endif:

branch_310_endif:

branch_312_endif:

branch_314_endif:

branch_316_endif:

branch_318_endif:

branch_320_endif:
bufferize
ret

fun_15:
push_operand 0
bufferize
ret

fun_18:
mov ax, 0
call seekle
;optimized
mov bx, 0
pop_operand ax
cmp ax, bx 
jne branch_321_cmp_fail
push_operand 1 ; cmp true
jmp branch_322_end_cmp
branch_321_cmp_fail:
push_operand 0 ; cmp false
branch_322_end_cmp:
pop_operand ax
cmp ax, 1 
jne branch_359_else
; then:
push_operand 16

jmp branch_360_endif
branch_359_else:
; else:
mov ax, 0
call seekle
;optimized
mov bx, 1
pop_operand ax
cmp ax, bx 
jne branch_323_cmp_fail
push_operand 1 ; cmp true
jmp branch_324_end_cmp
branch_323_cmp_fail:
push_operand 0 ; cmp false
branch_324_end_cmp:
pop_operand ax
cmp ax, 1 
jne branch_357_else
; then:
push_operand 66

jmp branch_358_endif
branch_357_else:
; else:
mov ax, 0
call seekle
;optimized
mov bx, 2
pop_operand ax
cmp ax, bx 
jne branch_325_cmp_fail
push_operand 1 ; cmp true
jmp branch_326_end_cmp
branch_325_cmp_fail:
push_operand 0 ; cmp false
branch_326_end_cmp:
pop_operand ax
cmp ax, 1 
jne branch_355_else
; then:
push_operand 14

jmp branch_356_endif
branch_355_else:
; else:
mov ax, 0
call seekle
;optimized
mov bx, 3
pop_operand ax
cmp ax, bx 
jne branch_327_cmp_fail
push_operand 1 ; cmp true
jmp branch_328_end_cmp
branch_327_cmp_fail:
push_operand 0 ; cmp false
branch_328_end_cmp:
pop_operand ax
cmp ax, 1 
jne branch_353_else
; then:
push_operand 0

jmp branch_354_endif
branch_353_else:
; else:
mov ax, 0
call seekle
;optimized
mov bx, 4
pop_operand ax
cmp ax, bx 
jne branch_329_cmp_fail
push_operand 1 ; cmp true
jmp branch_330_end_cmp
branch_329_cmp_fail:
push_operand 0 ; cmp false
branch_330_end_cmp:
pop_operand ax
cmp ax, 1 
jne branch_351_else
; then:
push_operand 0

jmp branch_352_endif
branch_351_else:
; else:
mov ax, 0
call seekle
;optimized
mov bx, 5
pop_operand ax
cmp ax, bx 
jne branch_331_cmp_fail
push_operand 1 ; cmp true
jmp branch_332_end_cmp
branch_331_cmp_fail:
push_operand 0 ; cmp false
branch_332_end_cmp:
pop_operand ax
cmp ax, 1 
jne branch_349_else
; then:
push_operand 0

jmp branch_350_endif
branch_349_else:
; else:
mov ax, 0
call seekle
;optimized
mov bx, 6
pop_operand ax
cmp ax, bx 
jne branch_333_cmp_fail
push_operand 1 ; cmp true
jmp branch_334_end_cmp
branch_333_cmp_fail:
push_operand 0 ; cmp false
branch_334_end_cmp:
pop_operand ax
cmp ax, 1 
jne branch_347_else
; then:
push_operand 0

jmp branch_348_endif
branch_347_else:
; else:
mov ax, 0
call seekle
;optimized
mov bx, 7
pop_operand ax
cmp ax, bx 
jne branch_335_cmp_fail
push_operand 1 ; cmp true
jmp branch_336_end_cmp
branch_335_cmp_fail:
push_operand 0 ; cmp false
branch_336_end_cmp:
pop_operand ax
cmp ax, 1 
jne branch_345_else
; then:
push_operand 0

jmp branch_346_endif
branch_345_else:
; else:
mov ax, 0
call seekle
;optimized
mov bx, 8
pop_operand ax
cmp ax, bx 
jne branch_337_cmp_fail
push_operand 1 ; cmp true
jmp branch_338_end_cmp
branch_337_cmp_fail:
push_operand 0 ; cmp false
branch_338_end_cmp:
pop_operand ax
cmp ax, 1 
jne branch_343_else
; then:
push_operand 0

jmp branch_344_endif
branch_343_else:
; else:
mov ax, 0
call seekle
;optimized
mov bx, 9
pop_operand ax
cmp ax, bx 
jne branch_339_cmp_fail
push_operand 1 ; cmp true
jmp branch_340_end_cmp
branch_339_cmp_fail:
push_operand 0 ; cmp false
branch_340_end_cmp:
pop_operand ax
cmp ax, 1 
jne branch_341_else
; then:
push_operand fun_17
push_operand CURRENT_RECORD

jmp branch_342_endif
branch_341_else:
; else:
jmp death
branch_342_endif:

branch_344_endif:

branch_346_endif:

branch_348_endif:

branch_350_endif:

branch_352_endif:

branch_354_endif:

branch_356_endif:

branch_358_endif:

branch_360_endif:
bufferize
ret

fun_17:
push_operand 0
bufferize
ret

fun_20:
mov ax, 0
call seekle
;optimized
mov bx, 0
pop_operand ax
cmp ax, bx 
jne branch_361_cmp_fail
push_operand 1 ; cmp true
jmp branch_362_end_cmp
branch_361_cmp_fail:
push_operand 0 ; cmp false
branch_362_end_cmp:
pop_operand ax
cmp ax, 1 
jne branch_399_else
; then:
push_operand 16

jmp branch_400_endif
branch_399_else:
; else:
mov ax, 0
call seekle
;optimized
mov bx, 1
pop_operand ax
cmp ax, bx 
jne branch_363_cmp_fail
push_operand 1 ; cmp true
jmp branch_364_end_cmp
branch_363_cmp_fail:
push_operand 0 ; cmp false
branch_364_end_cmp:
pop_operand ax
cmp ax, 1 
jne branch_397_else
; then:
push_operand 66

jmp branch_398_endif
branch_397_else:
; else:
mov ax, 0
call seekle
;optimized
mov bx, 2
pop_operand ax
cmp ax, bx 
jne branch_365_cmp_fail
push_operand 1 ; cmp true
jmp branch_366_end_cmp
branch_365_cmp_fail:
push_operand 0 ; cmp false
branch_366_end_cmp:
pop_operand ax
cmp ax, 1 
jne branch_395_else
; then:
push_operand 14

jmp branch_396_endif
branch_395_else:
; else:
mov ax, 0
call seekle
;optimized
mov bx, 3
pop_operand ax
cmp ax, bx 
jne branch_367_cmp_fail
push_operand 1 ; cmp true
jmp branch_368_end_cmp
branch_367_cmp_fail:
push_operand 0 ; cmp false
branch_368_end_cmp:
pop_operand ax
cmp ax, 1 
jne branch_393_else
; then:
push_operand 0

jmp branch_394_endif
branch_393_else:
; else:
mov ax, 0
call seekle
;optimized
mov bx, 4
pop_operand ax
cmp ax, bx 
jne branch_369_cmp_fail
push_operand 1 ; cmp true
jmp branch_370_end_cmp
branch_369_cmp_fail:
push_operand 0 ; cmp false
branch_370_end_cmp:
pop_operand ax
cmp ax, 1 
jne branch_391_else
; then:
push_operand 0

jmp branch_392_endif
branch_391_else:
; else:
mov ax, 0
call seekle
;optimized
mov bx, 5
pop_operand ax
cmp ax, bx 
jne branch_371_cmp_fail
push_operand 1 ; cmp true
jmp branch_372_end_cmp
branch_371_cmp_fail:
push_operand 0 ; cmp false
branch_372_end_cmp:
pop_operand ax
cmp ax, 1 
jne branch_389_else
; then:
push_operand 0

jmp branch_390_endif
branch_389_else:
; else:
mov ax, 0
call seekle
;optimized
mov bx, 6
pop_operand ax
cmp ax, bx 
jne branch_373_cmp_fail
push_operand 1 ; cmp true
jmp branch_374_end_cmp
branch_373_cmp_fail:
push_operand 0 ; cmp false
branch_374_end_cmp:
pop_operand ax
cmp ax, 1 
jne branch_387_else
; then:
push_operand 0

jmp branch_388_endif
branch_387_else:
; else:
mov ax, 0
call seekle
;optimized
mov bx, 7
pop_operand ax
cmp ax, bx 
jne branch_375_cmp_fail
push_operand 1 ; cmp true
jmp branch_376_end_cmp
branch_375_cmp_fail:
push_operand 0 ; cmp false
branch_376_end_cmp:
pop_operand ax
cmp ax, 1 
jne branch_385_else
; then:
push_operand 0

jmp branch_386_endif
branch_385_else:
; else:
mov ax, 0
call seekle
;optimized
mov bx, 8
pop_operand ax
cmp ax, bx 
jne branch_377_cmp_fail
push_operand 1 ; cmp true
jmp branch_378_end_cmp
branch_377_cmp_fail:
push_operand 0 ; cmp false
branch_378_end_cmp:
pop_operand ax
cmp ax, 1 
jne branch_383_else
; then:
push_operand 0

jmp branch_384_endif
branch_383_else:
; else:
mov ax, 0
call seekle
;optimized
mov bx, 9
pop_operand ax
cmp ax, bx 
jne branch_379_cmp_fail
push_operand 1 ; cmp true
jmp branch_380_end_cmp
branch_379_cmp_fail:
push_operand 0 ; cmp false
branch_380_end_cmp:
pop_operand ax
cmp ax, 1 
jne branch_381_else
; then:
push_operand fun_19
push_operand CURRENT_RECORD

jmp branch_382_endif
branch_381_else:
; else:
jmp death
branch_382_endif:

branch_384_endif:

branch_386_endif:

branch_388_endif:

branch_390_endif:

branch_392_endif:

branch_394_endif:

branch_396_endif:

branch_398_endif:

branch_400_endif:
bufferize
ret

fun_19:
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

times 16384-($-$$) db 0x00
