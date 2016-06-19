%define BUFFERSIZE 80

section	.rodata
	world_size_fmt:       	DB  "World length - %d, width - %d", 10, 0 
	parameters_fmt:			DB	"Iterations - %d, print frequency - %d", 10, 0
	str_fmt:				DB	"%s", 10, 0			

section .data
	                   	

section .bss
	world:				RESD	1 
	global WorldLength
	WorldLength:		RESD	1
	global WorldWidth
	WorldWidth:			RESD 	1
	iterations:			RESD	1
	frequency:			RESD	1
	buffer:				RESB	BUFFERSIZE



section .text
	align 16
	global initialize
	extern printf
	extern printer
	extern atoi

%macro my_atoi 2
	pushad
	push %2
	call atoi
	add esp, 4
	mov %1, eax
	popad
%endmacro

initialize:
	push ebp  						; save stack pointer
    mov ebp, esp

	mov eax, dword [ebp+8]			; get argv
	mov [world], eax

	; === Open file
	mov ebx, [eax+4]				; get filename
	mov eax, 5  
	mov ecx, 0  
	int 80h  

	; === Read from file
	mov eax, 3  
	mov ebx, eax
	mov ecx, buffer 
	mov edx, BUFFERSIZE    
	int 80h

	; === Print buffer
    pushad
    push buffer
    push str_fmt
    call printf
    add esp, 8
    popad

	; === Get world dimensions from argv
	mov eax, [world]
	my_atoi dword [WorldLength], dword [eax+8]
	my_atoi dword [WorldWidth], dword [eax+12]
	pushad
	push dword [WorldWidth]
    push dword [WorldLength]
    push world_size_fmt
    call printf
    add esp, 12
    popad

    ; === Get run parameters from argv
    mov eax, [world]
	my_atoi dword [iterations], dword [eax+16]
	my_atoi dword [frequency], dword [eax+20]
	pushad
    push dword [frequency]
    push dword [iterations]
    push parameters_fmt
    call printf
    add esp, 12
    popad

    push dword [world]
    call printer
    add esp, 4

    



	mov	esp, ebp					; Function exit code
	pop	ebp
	ret