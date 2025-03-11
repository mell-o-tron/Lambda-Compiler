
template_create_bigint:

push ax
pusha

mov ax, [OPERAND_POINTER - 2]   ; LL
mov [bigint_templ_param_0], ax

mov ax, [OPERAND_POINTER - 4]   ; LH
mov [bigint_templ_param_1], ax

mov ax, [OPERAND_POINTER - 6]   ; HL
mov [bigint_templ_param_2], ax

mov ax, [OPERAND_POINTER - 8]   ; HH
mov [bigint_templ_param_3], ax

mov eax, OPERAND_POINTER
sub eax, 8
mov OPERAND_POINTER, eax

xor eax, eax
xor ebx, ebx
mov ax, fckin_bigint_template
mov bx, [CURRENT_END]
mov [TEMPLATE_RESULT], bx


bigint_copy_loop:

; pusha
; mov bx, ax
; call print_dec
; popa

mov cx, [eax]
mov [ebx], cx
add ax, 2
add bx, 2

cmp ax, fckin_bigint_end
jb bigint_copy_loop

popa
mov ax, [TEMPLATE_RESULT]
push_operand eax
pop ax

pusha
mov eax, [CURRENT_END]
add eax, fckin_bigint_end - fckin_bigint_template + 2
mov word [CURRENT_END], ax
popa
ret


fckin_bigint_template:

mov ax, 0
mov bx, seekle
call bx

pop_operand ax

cmp ax, 0
je near bigint_templ_jmp_0
cmp ax, 1
je near bigint_templ_jmp_1
cmp ax, 2
je near bigint_templ_jmp_2
cmp ax, 3
je near bigint_templ_jmp_3

jmp death 				;;;; WRANGZ

bigint_templ_jmp_0:
db 0x66, 0xbf
bigint_templ_param_0:
dw 10
dw 0
mov [OPERAND_POINTER], edi
add OPERAND_POINTER, 2

bufferize
ret

bigint_templ_jmp_1:
db 0x66, 0xbf
bigint_templ_param_1:
dw 11
dw 0
mov [OPERAND_POINTER], edi
add OPERAND_POINTER, 2

bufferize
ret

bigint_templ_jmp_2:
db 0x66, 0xbf
bigint_templ_param_2:
dw 12
dw 0
mov [OPERAND_POINTER], edi
add OPERAND_POINTER, 2

bufferize
ret

bigint_templ_jmp_3:
db 0x66, 0xbf
bigint_templ_param_3:
dw 13
dw 0
mov [OPERAND_POINTER], edi
add OPERAND_POINTER, 2

bufferize
ret


fckin_bigint_end:
dw 0, 0
