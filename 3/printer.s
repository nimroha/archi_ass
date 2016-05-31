section	.rodata
	num_fmt: 		DB  "%d ", 0 	
	new_line:		DB	"",10 , 0	
	single_space:	DB	" ", 0	

section .data                    	

section .bss
	world:			RESD 1

section .text
	align 16
	global printer
	extern WorldLength
	extern WorldWidth
	extern printf

%macro print_num 1
	pushad
	push %1
	push num_fmt
	call printf
	add esp, 8
	popad 
%endmacro

%macro print_format 1
	pushad
	push %1
	call printf
	add esp, 4
	popad 
%endmacro

printer:
	push	ebp
	mov	ebp, esp	

	mov eax, dword [ebp+8]			; Get argument (double pointer to matrix)
	mov ebx, [eax]					; Get pointer to first row
	mov ecx, dword 0				; row counter
	mov edx, dword 0 				; col counter

	.col:
		test ecx, 1 				; check if requires an initial space (odd lines)
		jz printer.col_even
		print_format single_space
		.col_even:
		
		.row:
			print_num dword [ebx]
			add ebx, dword 4
			inc edx
			cmp edx, dword [WorldWidth]
			jb printer.row
		mov edx, dword 0
		print_format new_line

		inc ecx
		cmp ecx, dword [WorldWidth]
		jb printer.col




	mov	esp, ebp					; Function exit code
	pop	ebp
	ret

