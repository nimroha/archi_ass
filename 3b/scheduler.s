section	.rodata
	world_size_fmt:       	DB  "World length - %d, width - %d", 10, 0 
	parameters_fmt:			DB	"Iterations - %d, print frequency - %d", 10, 0		
	str_fmt:				DB	"%s", 10, 0	

section .data
	align 16
	generations: 	DD 	0
	frequency:		DD 	0
	    	

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

scheduler:
	push ebp  						; save stack pointer
    mov ebp, esp
	
	mov eax, dword [esp+8]
	mov dword [frequency], eax
	mov eax, dword [esp+12]
	mov dword [generations], eax


	; === Print world dimensions
	pushad
	push dword [WorldWidth]
    push dword [WorldLength]
    push world_size_fmt
    call printf
    add esp, 12
    popad

    ; === Print run parameters
	pushad
    push dword [frequency]
    push dword [generations]
    push parameters_fmt
    call printf
    add esp, 12
    popad

    ; === Get world size -> eax
	mov		eax, [WorldLength]
	mov		ecx, [WorldWidth]
	mul		ecx							; eax now contains number of cells
	mov		ecx, 0
	mov 	edx, 0


	.do:
	cmp ecx, eax
	je scheduler.done
	mov ebx, CORS
    add ebx, 24
    add ebx, edx
    add edx, 12
    call resume
    inc ecx
    jmp scheduler.do
	.done:


	; === Get world size -> eax
	mov		eax, [WorldLength]
	mov		ecx, [WorldWidth]
	mul		ecx							; eax now contains number of cells
	mov		ecx, 0
	mov 	edx, 0

	
	.do2:
	cmp ecx, eax
	je scheduler.done2
	mov ebx, CORS
    add ebx, 24
    add ebx, edx
    add edx, 12
    call resume
    inc ecx
    jmp scheduler.do2
	.done2:
    

    ; === Print world
    call printer

    

    mov	esp, ebp					; Function exit code
	pop	ebp
	jmp end_co