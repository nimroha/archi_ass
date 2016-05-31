section	.rodata
	num_fmt:       	DB   "World length - %d, width - %d", 10, 0 			

section .data
	                   	

section .bss
	world:			RESD 1 

section .text
	align 16
	global scheduler
	extern WorldLength
	extern WorldWidth
	extern printf
	extern printer

scheduler:
	push ebp  						; save stack pointer
    mov ebp, esp

    mov eax, dword [ebp+8]			; get world pointer
    mov dword [world], eax

	pushad
	push dword [WorldWidth]
    push dword [WorldLength]
    push num_fmt
    call printf
    add esp, 12
    popad

    push dword [world]
    call printer

    mov	esp, ebp					; Function exit code
	pop	ebp
	ret
