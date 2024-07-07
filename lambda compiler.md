# Lambda Compiler Specs
The lambda compiler, whose official name is yet undecided, compiles a version of the $\lambda$-calculus to 16 bit NASM x86 assembly code, to be ran in Real Mode. The language provides ways to activate BIOS interrupts.

## Language
The language of the source files is the standard lambda calculus with De Bruijn indices extended with integers, booleans, conditionals, and *interrupts*:

$$e ::= \lambda e \mid ee \mid Ln \mid \text{if }e\text{ then } e \text{ else } e \mid n \in \mathbb Z \mid b \in \mathbb B \mid e \oplus_{A || B} e \mid \ominus_{A || B} \,\,e | \;\text{INT}(n, regs, cont)$$
Where $\oplus_A$, $\oplus_B$, $\ominus_A$, $\ominus_B$ are binary and unary, arithmetic and boolean operations resp. $Ln$ is the $n$-th DB index.

## Data Structures

The memory used by the compiled program is divided in three areas:

- The built-in stack
- The activation record (AR) linked list
- The operand stack

Additionally, some space is reserved for the result of interrupts.

## Usage of registers

(these interfere with `ret`.)

```
ECX : 	CURRENT_RECORD
EDX :	OPERAND_POINTER
ESI : 	AR_AREA_POINTER

AX, BX, DI : general purpose

```

## Compilation procedure

### Compiling constants
Compiling a constant consists of simply pushing it to the operand stack.

### Compiling operations

Compiling an operation consists of first compiling the operands, and then performing the operation between the top two elements of the operand stack. The result is then pushed upon the operand stack again.

### Compiling If statements

Compile the guard, and then perform a conditional jump based on whether its value is one. If it is, the next instruction should be the compilation of the positive branch, otherwise it should be that of the negative branch.

### Compiling De Bruijn Indices

When compiling $Ln$, one should retrieve the parameter of the function at distance $n$ from the current record in the AR linked list. It should do so by starting at the current record, and following $n$ links up the chain. The current record should be held in a known register (or memory location).

This is obtained by calling the function `seekle` after having moved the number $n$ to `ax`. 

```
seekle:
	; subtract ax from the CURRENT DEPTH

	mov bx, CURRENT_RECORD

	loople:
		cmp ax, 0
		je endle

		dec ax
		mov bx, [bx + 2]        ; set the record counter to the current record's definition record (parent)
		jmp loople

	endle:
		push_operand [bx + 4]  ; push the value of the actual parameter stored in the obtained record.
		cmp [bx + 6], 0
		je veryendle
		push_operand [bx + 6]
	veryendle:
	ret

```

### Compiling Lambdas

When a lambda is compiled, the result of compiling its body is written at the end of the result assembly file, after the `jmp $` instruction, as a function. 

```
fun_fresh:
	(compile body)
	mov CURRENT_RECORD, [CURRENT_RECORD]		; return to the index space of the caller
	ret
```

Additionally, we push a pair `(fun_ptr, record_ptr)` to the operand stack, in such a way that, when the compiled function is later called, the environment is restored by setting the appropriate record pointer.

```
push_operand fun_name
push_operand CURRENT_RECORD
```

### Compiling function application

There are two sorts of functional application. Application of a function to a non-function value, and application of a function to a function. In the case of application of a function to a function, we not only wish to record the argument (the function's address), but also the environment it was defined in. Records will thus have the following form:

```
word: CALLER_RECORD
word: DEFINITION_RECORD
word: PARAMETER
word: PAR_DEFINITION_RECORD		; 0 if does not apply
``` 

#### Case of function applied to non-function
- First compile the first expression (the function), thus pushing the function pointer **and the record pointer** upon the operand stack. 
- Then compile the actual argument, thus pushing it on the stack. 

- Then create a record in the record stack, containing the caller's location and the argument value, and make it the current record. 
- Then call the function. 
- After having returned from the function call, the result shall be on top of the operand stack; there is therefore no need to push it.

```
; the following push: 	fun_pointer - def_record - actual_arg
(compile e1)
(compile e2)

make_record  	; saves record caller and parameter, increments AR area pointer

call bx		; make_record puts fun pointer in bx

```

Where `make_record` is:

```
%macro 	make_record 0
		pop_operand ax		; argument
		pop_operand di		; environment (definition record)
		pop_operand bx		; function
		
		add AR_AREA_POINTER, 8
		
		mov eax, CURRENT_RECORD
		mov [AR_AREA_POINTER], ax					; save caller record
		mov [AR_AREA_POINTER + 2], di				; save definition record
		mov [AR_AREA_POINTER + 4], ax				; save parameter
		mov [AR_AREA_POINTER + 6], word 0			; non-function check
		
		mov CURRENT_RECORD, AR_AREA_POINTER
%endmacro
```

#### Case of function applied to function
Same as above, but instead of using `make_record` use the following:
```
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
```