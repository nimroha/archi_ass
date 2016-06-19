section	.rodata
	num_fmt: 		DB  "%d ", 0 	
	new_line:		DB	"",10 , 0	
	single_space:	DB	" ", 0	

section .data                    	

section .bss

section .text
	align 16
	global printer
	extern world
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

	mov ebx, dword [world]			; Get argument (double pointer to matrix)
	mov ecx, dword 0				; row counter
	mov edx, dword 0 				; col counter

	.col:
		test ecx, 1 				; check if requires an initial space (even lines)
		jz printer.col_odd
		print_format single_space
		.col_odd:
		
		.row:
			print_num dword [ebx]
			add ebx, dword 4
			inc edx
			cmp edx, dword [WorldWidth]
			jb printer.row
		print_format new_line

		mov edx, dword 0
		
		inc ecx
		cmp ecx, dword [WorldLength]
		jb printer.col


	mov	esp, ebp					; Function exit code
	pop	ebp
	ret

