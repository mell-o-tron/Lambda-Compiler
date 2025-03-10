; Chat j'ai peté  _(:D｣┌)⁼³₌₃

print_dec:
    push bp
    mov bp, sp

    ; Check for negative value in BX
    cmp bx, 0
    jge .print_positive
    ; Print '-' if negative and convert BX to positive
    mov ah, 0x0E
    mov al, '-'
    int 0x10
    neg bx

.print_positive:
    ; If the number is zero, print '0'
    cmp bx, 0
    jne .extract
    mov ah, 0x0E
    mov al, '0'
    int 0x10
    jmp .done

.extract:
    xor si, si          ; SI will count the number of digits

.extract_loop:
    xor dx, dx          ; Clear DX for division
    mov ax, bx          ; Move current number into AX
    mov cx, 10          ; Divisor = 10
    div cx              ; AX = quotient, DX = remainder
    push dx             ; Save remainder (digit)
    inc si              ; Count this digit
    mov bx, ax          ; Update BX with quotient
    cmp bx, 0
    jne .extract_loop   ; Continue until the number becomes 0

.print_loop:
    pop dx             ; Get next digit (in reverse order)
    add dl, '0'        ; Convert digit to ASCII ('0' = 48)
    mov ah, 0x0E
    mov al, dl
    int 0x10           ; Print the digit
    dec si
    cmp si, 0
    jne .print_loop

.done:
    
    mov ah, 0x0E
    mov al, ' '
    int 0x10

    pop bp
    ret
