section	.rodata
	world_size_fmt:       	DB  "World length - %d, width - %d", 10, 0 
	parameters_fmt:			DB	"Iterations - %d, print frequency - %d", 10, 0		
	str_fmt:				DB	"%s", 10, 0	
	num_fmt: 				DB  "%d", 10, 0

section .data
	align 16
	generations: 	DD 	0
	frequency:		DD 	0
	world_size:		DD 	0
	total_resumes:	DD 	0
	    	

section .bss 


section .text
	align 16

	global scheduler
	extern CORS
	extern end_co
	extern resume
	extern world
	extern WorldLength
	extern WorldWidth
	;extern generations
	;extern frequency
	extern printf
	extern printer

%macro print_num 1
	pushad
	push %1
	push num_fmt
	call printf
	add esp, 8
	popad 
%endmacro

%macro check_print 0
	pushad
	mov eax, dword [total_resumes]
	mov ecx, dword [frequency]
	mov edx, 0
	idiv ecx
	cmp eax, 0
	je %%done
	cmp edx, 0
	jne %%done
	mov ebx, CORS
	add ebx, 12
	call resume
	%%done:
	popad
%endmacro


scheduler:
	push 	ebp  						; save stack pointer
    mov 	ebp, esp
	
	mov 	eax, dword [esp+8]
	mov 	dword [frequency], eax
	mov 	eax, dword [esp+12]
	mov 	dword [generations], eax


	; === Print world dimensions
	pushad
	push 	dword [WorldWidth]
    push 	dword [WorldLength]
    push 	world_size_fmt
    call 	printf
    add 	esp, 12
    popad

    ; === Print run parameters
	pushad
    push 	dword [frequency]
    push 	dword [generations]
    push 	parameters_fmt
    call 	printf
    add 	esp, 12
    popad

    ; === Get world size -> eax
	mov		eax, [WorldLength]
	mov		ecx, [WorldWidth]
	mul		ecx							; eax now contains number of cells
	mov		ecx, 0
	mov 	edx, 0
	mov 	dword [world_size], eax

	; === Multiply generations by 2
	mov 	eax, dword [generations]
	add 	dword [generations], eax

	.half_generation:
	mov 	eax, dword [generations]
	cmp 	dword [generations], 0
	je 		scheduler.half_generations_done
	mov		ecx, 0
	mov 	edx, 0
	.do:
	mov 	eax, dword [world_size]
	cmp		ecx, eax
	je 		scheduler.done
	mov 	ebx, CORS
    add 	ebx, 24
    add 	ebx, edx
    add 	edx, 12
    call 	resume

	inc		dword [total_resumes]
	check_print

    inc 	ecx
    jmp 	scheduler.do
	.done:
	dec		dword [generations]
	jmp 	scheduler.half_generation
	.half_generations_done:
    

    ; === Print world
    ;mov 	ebx, CORS
	;add 	ebx, 12
	;call 	resume

    

    mov		esp, ebp					; Function exit code
	pop		ebp
	jmp 	end_co