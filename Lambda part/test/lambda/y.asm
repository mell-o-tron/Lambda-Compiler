push_operand fun_5
push_operand fun_7
pop_operand ax
push_env ax
pop_operand ax
call ax

; Functions:
fun_5:
push_operand fun_2
push_operand fun_4
pop_operand ax
push_env ax
pop_operand ax
call ax
ret
fun_2:
push_operand [ENVIRONMENT_POINTER - 4]
push_operand fun_1
push_operand [ENVIRONMENT_POINTER - 2]
pop_operand ax
push_env ax
pop_operand ax
call ax
pop_operand ax
push_env ax
pop_operand ax
call ax
ret
fun_1:
push_operand [ENVIRONMENT_POINTER - 4]
push_operand [ENVIRONMENT_POINTER - 4]
pop_operand ax
push_env ax
pop_operand ax
call ax
ret
fun_4:
push_operand [ENVIRONMENT_POINTER - 4]
push_operand fun_3
push_operand [ENVIRONMENT_POINTER - 2]
pop_operand ax
push_env ax
pop_operand ax
call ax
pop_operand ax
push_env ax
pop_operand ax
call ax
ret
fun_3:
push_operand [ENVIRONMENT_POINTER - 4]
push_operand [ENVIRONMENT_POINTER - 4]
pop_operand ax
push_env ax
pop_operand ax
call ax
ret
fun_7:
push_operand fun_6
ret
fun_6:
push_operand [ENVIRONMENT_POINTER - 2]
push_operand 0
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
push_operand 1

jmp branch_4
branch_3:
push_operand [ENVIRONMENT_POINTER - 2]
push_operand [ENVIRONMENT_POINTER - 4]
push_operand [ENVIRONMENT_POINTER - 2]
push_operand 1
pop_operand ax
neg ax
push_operand ax
pop_operand ax
pop_operand bx
add ax, bx
push_operand ax
pop_operand ax
push_env ax
pop_operand ax
call ax
pop_operand ax
pop_operand bx
add ax, bx
push_operand ax

branch_4:
ret
