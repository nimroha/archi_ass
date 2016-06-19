	STKSZ 				EQU 16*1024 	; individual stack size
	CODEP 				EQU 0 			; offset to func
	FLAGSP 				EQU 4			; offset to flags
	SPP 				EQU 8 			; offset to stack
	MAX_DIM				EQU 60

section	.rodata
	world_size_fmt: 	DB  "World length - %d, width - %d", 10, 0 
	parameters_fmt:		DB	"Iterations - %d, print frequency - %d", 10, 0
	str_fmt:			DB	"%s", 10, 0		
	num_fmt: 			DB  "%d", 10, 0
	cell_fmt:			DB	"Row: %d, Col: %d", 10, 0 	

	

section .data
	align 16

	CORS_OFF:	DB		0
	current:	DD 		0
	row:		DD 		0
	col: 		DD 		0
	row_check:	DD 		0
	col_check: 	DD 		0

	                 	

section .bss
	align 16
	global CORS
	CORS:		RESD	3*(MAX_DIM*MAX_DIM+2)		; pointer to coroutine structures
	STK:		RESB	STKSZ*(MAX_DIM*MAX_DIM+2)	; pointer to the full CORS stack

	CURR: 		RESD 	1
	SPT: 		RESD 	1 				; temp SP 
	SPMAIN: 	RESD 	1 				; main SP
	


section .text
	align 16
	global coroutines_init
	global resume
	global end_co
	extern world
	extern WorldLength
	extern WorldWidth
	extern generations
	extern frequency
	extern scheduler
	extern printer
	extern printf
	extern atoi


%macro print_num 1
	pushad
	push %1
	push num_fmt
	call printf
	add esp, 8
	popad 
%endmacro

%macro print_cell 2
	pushad
	push %2
	push %1
	push cell_fmt
	call printf
	add esp, 12
	popad 
%endmacro

%macro modulo 2
	pushad
	mov eax, %1
	mov ecx, %2
	add eax, %2
	mov edx, 0
	idiv ecx
	mov %1, edx
	popad
%endmacro

%macro check_cell 2
	push eax
	push ebx
	push edx
	mov eax, %1 					; row number
	mov ebx, dword [WorldWidth]		; row size
	mul ebx
	add eax, %2
	shl eax, 2
	mov ebx, dword [world]
	add ebx, eax
	cmp dword [ebx], dword 1
	jne %%done
	inc ecx
	%%done:
	pop edx
	pop ebx
	pop eax
%endmacro

%macro set_cell 2
	push eax
	push ebx
	push edx
	mov eax, %1 					; row number
	mov ebx, dword [WorldWidth]		; row size
	mul ebx
	add eax, %2
	shl eax, 2
	mov ebx, dword [world]
	add ebx, eax
	mov dword [ebx], ecx
	pop edx
	pop ebx
	pop eax
%endmacro



coroutines_init:

	push 	ebp  						; save stack pointer
    mov 	ebp, esp
    mov 	[SPMAIN], esp

    mov 	edx, 0						; initial offset in CORS

    mov eax, STK


	; === initialize scheduler
	mov		eax, scheduler				; set func
	mov		[CORS+edx], eax
	add 	edx, 4
	mov		eax, 0						; set flags
	mov		[CORS+edx], eax
	add 	edx, 4
	mov		eax, STK+STKSZ				; set stack
	mov 	ebx, dword [generations]
	mov 	dword [eax], ebx
	sub 	eax, 4
	mov 	ebx, dword [frequency]
	mov 	dword [eax], ebx
	sub 	eax, 4
	mov		[CORS+edx], eax
	add 	edx, 4

	xchg	edx, [CORS_OFF]
	call	init_co
	mov		edx, [CORS_OFF]


	; === initialize printer
	mov		eax, printer				; set func
	mov		[CORS+edx], eax
	add 	edx, 4
	mov		eax, 0						; set flags
	mov		[CORS+edx], eax
	add 	edx, 4
	mov		eax, STK+STKSZ*2			; set stack
	mov		[CORS+edx], eax
	add 	edx, 4

	xchg	edx, [CORS_OFF]
	call	init_co
	mov		edx, [CORS_OFF]

	; === initialize cells
	push 	edx	
	mov		eax, [WorldLength]
	mov		ecx, [WorldWidth]
	mul		ecx							; eax now contains number of cells
	mov		ecx, 0
	pop 	edx

	.cell_init:
	cmp 	ecx, eax					; ecx is the cell number
	je 		coroutines_init.done
	mov		ebx, cell					; set func
	mov		[CORS+edx], ebx
	add 	edx, 4
	mov		ebx, ecx					; set flag to be cell index
	mov		[CORS+edx], ebx
	add 	edx, 4
	push 	eax							; set stack address
	push 	ecx
	push 	edx							
	mov 	eax, STKSZ
	add 	ecx, 3
	mul 	ecx
	mov		ebx, STK
	add 	ebx, eax
	pop 	edx
	pop 	ecx
	pop 	eax
		
	mov		[CORS+edx], ebx
	add 	edx, 4

	xchg	edx, [CORS_OFF]
	call	init_co
	mov		edx, [CORS_OFF]

	inc 	ecx
	jmp 	coroutines_init.cell_init

	.done:

	
	mov 	ebx, CORS
	call 	do_resume



init_co:
	pushad
	push 	ebp  						; save stack pointer
	mov 	ebp, esp
	mov 	ebx, CORS					; ebx points to the CORS start
	add 	ebx, edx					; ebx points to structure start
	call 	co_init

	

	mov		esp, ebp					; Function exit code
	pop		ebp
	popad
	ret


co_init:
	pushad
	; bts		dword [ebx+FLAGSP], 0		; 
	; jc 		init_done
	mov 	eax, [ebx+CODEP] 			; initial PC
	mov		[SPT], esp 					; save SP
	mov		esp, [ebx+SPP]				; get COR SP
	mov 	ebp, esp					; 
	push 	eax							; push inital PC
	pushfd
	pushad
	mov		[ebx+SPP], esp				; save new SP
	mov 	esp, [SPT]					; resore original SP
init_done:
	popad
	ret






cell:
	; ============ First half: Check nearby cells for own future value

	pushad
	mov		eax, [CURR]
	mov 	eax, [eax+FLAGSP]		; get cell index (0-row*col)
	mov		dword [row], 0
	.next_row:
	cmp		eax, [WorldWidth]
	jb 		cell.this_row
	sub		eax, [WorldWidth]
	inc 	dword [row]
	jmp 	cell.next_row
	.this_row:
	mov 	[col], eax

	mov 	ecx, 0					; counter for sorrounding alive cells

	; print_cell dword [row], dword [col]


	; === ODD: (i-1, j-1), (i+1, j-1) ------ (i-1, j), (i+1, j) - (i, j-1), (i, j+1)
	; === EVEN: (i-1, j+1), (i+1, j+1) ------ (i-1, j), (i+1, j) - (i, j-1), (i, j+1)

	.j_minus:												; === (i-1,j) even/odd
		mov eax, [row]
		dec eax
		mov [row_check], eax
		mov eax, [col]
		mov [col_check], eax
		modulo dword [row_check], dword [WorldLength]
		; print_cell dword [row_check], dword [col_check]
		check_cell dword [row_check], dword [col_check]
	.j_plus:												; === (i+1,j) even/odd
		mov eax, [row]
		inc eax
		mov [row_check], eax
		mov eax, [col]
		mov [col_check], eax
		modulo dword [row_check], dword [WorldLength]
		; print_cell dword [row_check], dword [col_check]
		check_cell dword [row_check], dword [col_check]
	.i_minus:												; === (i,j-1) even/odd
		mov eax, [row]
		mov [row_check], eax
		mov eax, [col]
		dec eax
		mov [col_check], eax
		modulo dword [col_check], dword [WorldWidth]
		; print_cell dword [row_check], dword [col_check]
		check_cell dword [row_check], dword [col_check]
	.i_plus:												; === (i,j+1) even/odd
		mov eax, [row]
		mov [row_check], eax
		mov eax, [col]
		inc eax
		mov [col_check], eax
		modulo dword [col_check], dword [WorldWidth]
		; print_cell dword [row_check], dword [col_check]
		check_cell dword [row_check], dword [col_check]
	.i_minus_one:											; === (i-1,j-1) odd, (i-1,j+1) even
		mov eax, [row]
		dec eax
		mov [row_check], eax
		mov eax, [col]
		test dword [row], 1
		je cell.odd1
		inc eax
		jmp cell.even1
		.odd1:
		dec eax
		.even1:
		mov [col_check], eax
		modulo dword [row_check], dword [WorldLength]
		modulo dword [col_check], dword [WorldWidth]
		; print_cell dword [row_check], dword [col_check]
		check_cell dword [row_check], dword [col_check]
	.i_plus_one:											; === (i+1,j-1) odd, (i+1,j+1) even
		mov eax, [row]
		inc eax
		mov [row_check], eax
		mov eax, [col]
		test dword [row], 1
		je cell.odd2
		inc eax
		jmp cell.even2
		.odd2:
		dec eax
		.even2:		
		mov [col_check], eax
		modulo dword [row_check], dword [WorldLength]
		modulo dword [col_check], dword [WorldWidth]
		; print_cell dword [row_check], dword [col_check]
		check_cell dword [row_check], dword [col_check]

	; print_num ecx
	; === ecx now holds the number of living neighbours
	mov edx, ecx
	mov ecx, 0
	check_cell dword [row], dword [col] 					; set ecx to be the cell value
	; print_num ecx
	cmp ecx, 1
	je cell.alive
	.dead:
	cmp edx, 2
	jne cell.done
	mov ecx, 1												; dead cell has 2 neighbours -> alive
	jmp cell.done
	.alive:
	mov ecx, 0												; living cell is suspected to not have 3/4 neighbours -> currently dead
	cmp edx, 3
	jb cell.done
	cmp edx, 4
	ja cell.done
	mov ecx, 1												; living cell has 3/4 neighbours -> stays alive
	.done:

	; print_num ecx
	push 	ecx

	mov 	ebx, CORS 				; address of scheduler
	call 	resume


	; ============ Second Half: Value <- Future value
	pop 	ecx
	mov		eax, [CURR]
	mov 	eax, [eax+FLAGSP]
	mov 	ebx, dword [world]		; Get pointer to world
	.abc:
	mov 	dword [ebx+eax*4], ecx

	mov 	ebx, CORS 				; address of scheduler
	call 	resume

	jmp cell



resume: 						; save caller
	pushfd
	pushad
	mov 	edx, [CURR]
	mov 	[edx+SPP],esp 		; save current SP
do_resume: 						; restore resumed
	mov 	esp, [ebx+SPP]
	mov 	[CURR], ebx
	popad 						; restore resumed co-routine state
	popfd
	ret 						; return to next co-routine

end_co:
	mov 	esp, [SPMAIN] 
	
	pop		ebp
	ret
