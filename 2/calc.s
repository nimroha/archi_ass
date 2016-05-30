;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;    this is the current working file!    ;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


%define STACKSIZE 5
%define BUFFERSIZE 80

section .rodata
frmt_str:      DB   "%s", 0        											; format string
prompt_str:    DB   ">>calc: ",0,0              								; input message
in_str:        DB   "got %s", 0        										; format string
over_flow_str: DB   "Error: Operand Stack Overflow",10,0 					; stack overflow message
no_args_str:   DB   "Error: Insufficient Number of Arguments on Stack",10,0 ; insufficient arguments message
illegal_str:   DB   "Error: Illegal Input",10,0 							; illegal input message
ctr_str:       DB   "Number of operations: %d", 10, 0 						; exit message
nib_str:       DB   "%x", 0 												; nibble print
nib_str_zero:  DB   "%.2x", 0 												; zero nibble print
entry_line:	   DB 	">>", 0													; line entry...
new_line: 	   DB 	"", 10, 0												; new line...
read_str:      DB   "Read %s to buffer", 10, 0 								; read to buffer message
push_str:      DB   "Pushed %d to stack", 10, 0 							; push message
d_flag:        EQU  0x642d 													; -d in ascii

     
section .bss
buffer:        		RESB BUFFERSIZE ; input buffer
my_stack:      		RESD STACKSIZE ; operand stack
operand1:			RESD 1 ; address of head of first operand
operand2:			RESD 1 ; address of head of second operand
operand1_head:		RESD 1 ; address of head of first operand
operand2_head:		RESD 1 ; address of head of second operand




section .data
dbg:           DB 0 ; debug flag
op_num:        DD 0 ; number of operands in the stack
counter: 	  	DD 0 ; operation counter
head: 			DD 0 ; head of current operand
tail: 			DD 0 ; tail of current operand
last_non_zero:	DD 0 ; address of last non zero link in current list
current_num:	DB 0 ; helper to make sure the num sent to make link isnt corrupted by the call
tmp:			DD 0 ; helper to hold data between calls/pushad's/popad's



section .text 
     align 16 
     global main 
     extern printf 
     extern fprintf 
     extern malloc 
     extern free
     extern fgets 
     extern stderr 
     extern stdin 
     extern stdout 


%macro print 2-* ; %1=stream pointer %2...=format and args (unbound)
	pushad
	mov ecx, %0
	mov eax, %1
	%rotate 1
	dec ecx
	%%p_loop:
	    push %1
	    %rotate 1
	    loop %%p_loop, ecx
	push dword [eax]
	call fprintf 
	add esp, 4*%0
	popad
%endmacro


%macro debug 1-* ; enter as many arguments as needed
     cmp byte [dbg], 0
     je %%skip
          pushad
          mov ecx, %0
          %%p_loop:
               push %1
               %rotate 1
               loop %%p_loop, ecx
          push dword [stderr]
          call fprintf 
          add esp, 4+4*%0
          popad
     %%skip:
%endmacro

%macro make_link 1         ; %1=number
	 mov [current_num], %1
     pushad
     push 5
     call malloc
     mov dl, [current_num]
     mov byte [eax], dl
     mov dword [eax+1], 0
     									; ============== added linking to the macro, perhaps should just use a func ?
     cmp dword [head], 0				; check if its the first link, if so set as head and tail, if not link tail to the new link created
     jne %%link_tail
     mov [head], eax
     mov [tail], eax
     jmp %%check_zero
     %%link_tail:						; link a new link to the tail
     mov dword ebx, [tail]
     mov dword [ebx+1], eax				; set the new link as the NEXT of tail
     mov dword [tail], eax				; set tail to be the new link
     %%check_zero:
     cmp byte [current_num], 0
     je %%done
     mov [last_non_zero], eax
     %%done:

     add esp, 4
     popad
%endmacro

%macro link_value 2 ; %1=link address  %2=destination(byte)
	pushad
	mov eax, [%1]
	mov byte bl, [eax]
	mov byte [tmp], bl
	popad
	mov %2, 0
	mov byte %2, [tmp]
%endmacro

%macro link_pointer 2 ; %1=link address  %2=destination(dword)
	pushad
	mov eax, [%1]
	mov dword ebx, [eax+1]
	mov dword [tmp], ebx
	popad
	mov dword %2, [tmp]
%endmacro

%macro pop_my_stack 1  ; %1 address
	pushad
	dec dword [op_num]
    mov dword eax, [op_num]
	mov ebx, [my_stack+4*eax]
    mov [%1], ebx
    popad
%endmacro

%macro add_daa 4 ; %1 dest, %2 addition, %3 prev carry, %4 next carry
    add %1, %2
    daa 
    jnc %%no_daa_carry
    mov byte %4, 1
	%%no_daa_carry:
    add %1, %3
    daa
    jnc %%no_add_carry
    add byte %4, 1
	%%no_add_carry:

    mov %3, %4
    mov %4, 0
%endmacro

%macro debug_print 1   ; %1=head of number
	cmp byte [dbg], 0
	je %%skip
	mov eax, [%1]
	mov [tail], eax
	mov [head], eax
	print stderr, entry_line
	call print_num
	print stderr, new_line
	%%skip:
%endmacro

main: 

     push ebp  ; save stack pointer
     mov ebp, esp

     mov eax, [ebp+8]  ; num of arguments
     num:
     cmp eax, 2 
     jne call_calc
     mov eax, [ebp+12] ; get pointer to argv
     mov ebx, [eax+4] ; get pointer to first argument
     mov eax, [ebx] ; get first argument


     arg:
     cmp ax, d_flag     ; check if -d 
     jne call_calc
     mov byte [dbg], 1  ; raise dbg flag
     jmp call_calc

call_calc:
     pushad
     pushfd

	call my_calc 

     ; =============== Print number of operations ====================
     pushad
     push eax
     push ctr_str
     push dword [stdout]
     call fprintf
     add esp, 12
     popad

     popfd
     popad

     exit:
     mov eax, 1
     int 0x80
     nop
	

my_calc:
     push ebp
     mov ebp, esp

     mov eax, [counter]

     .get_input:
     print stdout, prompt_str

     mov dword [head], 0
     mov dword [tail], 0
     mov dword [last_non_zero], 0

    pushad
    push dword [stdin]
    push BUFFERSIZE
    push buffer
    call fgets ; does eax now hold the number of chars read??
    add esp, 12
    popad

inc dword [counter] 		; just to see

     mov al, [buffer]	 	; for switch case
     cmp al, 10				; ======== check if there was any input
     je my_calc.illegal 	
     mov ah, [buffer+1] 	; ======== to see if its a single char
     cmp ah, 10
     jne number
q:
     cmp al, 'q'
     je my_calc.quit
plus:
     cmp al, '+'
     je my_calc.add
p:
     cmp al, 'p'
     je my_calc.pop_print
d:
     cmp al, 'd'
     je my_calc.dup
and_:
     cmp al, '&'
     je my_calc.and
number:
     
	; ========= Check if there are any illegal chars, and convert ascii to numbers
	mov ecx,0
	.looptyloop:
		cmp byte [buffer+ecx], 10
		je number.confirmed
		cmp byte [buffer+ecx], 57
     	ja my_calc.illegal
     	cmp byte [buffer+ecx], 48
     	jb my_calc.illegal
     	sub byte [buffer+ecx], '0'
     	inc ecx
     	jmp number.looptyloop
    .confirmed:							; ========= ecx contains amount of digits
    	cmp dword [op_num], STACKSIZE
    	je number.overflow

	mov ebx, 0
	.zeroloop:
	cmp byte [buffer+ebx], 0
	jne number.not_zero
	inc ebx
	jmp number.zeroloop
	.not_zero:
	cmp ebx, ecx
	je number.last_nibble
	mov eax, ebx
	inc eax

    .linking:							; ========= Number linking block
    	cmp ecx, eax					; check if last nibble (requires "zero padding")
    	je number.last_nibble
    	cmp ecx, ebx 					; check if done
    	je number.done
    	mov byte dl, [buffer+ecx-1]		; get first nibble
    	dec ecx
    	shl byte [buffer+ecx-1], 4
    	add byte dl, [buffer+ecx-1]		; get second nibble
    	dec ecx

    	;mov [current_num], dl 			; make sure value doesnt get corrupted by malloc
    	make_link dl

    	jmp number.linking
    .last_nibble:
    	mov byte dl, [buffer+ecx-1]
    	make_link dl
    	dec ecx
    .done:


    	cmp byte [dbg], 1
    	jne number.no_debug
    	mov dword eax, [head]
    	mov dword [tail], eax
    	call print_num
    	print stdout, new_line			
    .no_debug:

    	

    	jmp my_calc.push

    .overflow:							; too many operands in stack
    	print stderr, over_flow_str
		jmp my_calc.get_input			

    


	




my_calc.illegal:
     print stderr, illegal_str
     jmp my_calc.get_input

my_calc.add:
     cmp word [op_num], 2
     jb skip_add

     ; === pop 2 numbers from my_stack
     pop_my_stack operand1 
     pop_my_stack operand2

     call _add

     jmp my_calc.get_input
     skip_add:
     print stderr, no_args_str
     jmp my_calc.get_input

my_calc.pop_print:
     cmp word [op_num], 1
     jb skip_pop

     ; ===pop 1 number from my_stack
	 pop_my_stack operand1

     call _pop_print
     
     jmp my_calc.get_input
     skip_pop:
     print stderr, no_args_str
     jmp my_calc.get_input

my_calc.dup:
     cmp word [op_num], 1
     jb skip_dup_underflow
     cmp word [op_num], 5
     je skip_dup_overflow

     ; === pop 1 number from my_stack and push to stack
     pop_my_stack operand1
     call _dup

     jmp my_calc.get_input
     skip_dup_underflow:
     print stderr, no_args_str
     jmp my_calc.get_input
     skip_dup_overflow:
     print stderr, over_flow_str
     jmp my_calc.get_input

my_calc.and:
     cmp word [op_num], 2
     jb skip_and
     
     ; === pop 2 numbers from my_stack
     pop_my_stack operand1 
     pop_my_stack operand2

     call _and
     
     jmp my_calc.get_input
     skip_and:
     print stderr, no_args_str
     jmp my_calc.get_input

my_calc.push:
	pushad
	call _push
    popad
    jmp my_calc.get_input



my_calc.quit:
quit:
     mov ecx, [op_num]
     cmp ecx,0
     je quit.free_done

     .loop:
     	pop_my_stack head
     	call free_num
     	loop quit.loop, ecx

     .free_done:
     mov eax, [counter]
     mov esp, ebp
     pop ebp
     ret  ; to main
     

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;  sub-routines  ;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

print_num:							; ======= prints the number pointed by head to stdout
	pushad
	mov dword eax, [tail]

	cmp dword [eax+1], 0			; base 
	je print_num.highnib
	mov dword ebx, [eax+1]
	mov dword [tail], ebx
	call print_num
	jmp print_num.lownib

	.highnib:
	mov ebx, 0
	mov bl, [eax]

	pushad
	push ebx
    push nib_str
    push dword [stdout]
    call fprintf
    add esp, 12
    popad
    jmp print_num.end

    .lownib:
    mov ebx, 0
	mov bl, [eax]

	pushad
	push ebx
    push nib_str_zero
    push dword [stdout]
    call fprintf
    add esp, 12
    popad

    .end:
    popad
ret 

debug_num:							; ======= prints the number pointed by head to stderr if debug prints activated
	pushad
	mov dword eax, [tail]

	cmp dword [eax+1], 0			; base 
	je debug_num.highnib
	mov dword ebx, [eax+1]
	mov dword [tail], ebx
	call debug_num
	jmp debug_num.lownib

	.highnib:
	mov ebx, 0
	mov bl, [eax]

	pushad
	push ebx
    push nib_str
    push dword [stderr]
    call fprintf
    add esp, 12
    popad
    jmp debug_num.end

    .lownib:
    mov ebx, 0
	mov bl, [eax]

	pushad
	push ebx
    push nib_str_zero
    push dword [stderr]
    call fprintf
    add esp, 12
    popad

    .end:
    popad
ret 

free_num:							; frees a number pointed by head
	push ebp
	mov ebp, esp
	pushad

	.loop:
		mov dword eax, [head]
		link_pointer head, ebx
	.a:

		pushad
		push eax
		call free
		add esp, 4
		popad

		mov [head], ebx
		cmp ebx, 0
		jne free_num.loop

	popad
	pop ebp
ret




_add:									; addition sub-routine
	push ebp
    mov ebp, esp

    mov eax, [operand1]
	mov [operand1_head], eax
	mov eax, [operand2]
	mov [operand2_head], eax

	mov ah, 0							; prev carry
	mov bh, 0							; next carry
    .loop:
	    link_value operand1, al
	    link_value operand2, bl
	    link_pointer operand1, ecx
	    link_pointer operand2, edx

		add_daa al, bl, ah, bh
	    make_link al


	    cmp ecx, 0
	    je _add.op1done
	    cmp edx, 0
	    je _add.op2done

	    mov [operand1], ecx
	    mov [operand2], edx
	    jmp _add.loop

	.op1done:
		cmp edx, 0
		je _add.done
		mov [operand1], edx
		jmp _add.onelist

	.op2done:
		cmp ecx, 0
		je _add.done
		mov [operand1], ecx

	.onelist:
		link_value operand1, al
		link_pointer operand1, ecx
		mov [operand1], ecx
	
		add_daa al, 0, ah, bh

		make_link al
		cmp ecx, 0
		jne _add.onelist

	.done:
		cmp ah, 0
		je _add.no_carry
		make_link ah
	.no_carry:

		cmp byte [dbg], 1
    	jne _add.no_debug
    	mov dword eax, [head]
    	mov dword [tail], eax
    	call debug_num
    	print stderr, new_line			
    .no_debug:

		call _push					; push the new list

		mov eax, [operand1_head]	; free op1
		mov [head], eax
		call free_num

		mov eax, [operand2_head]	; free op2
		mov [head], eax
		call free_num

    pop ebp 
ret ; to my_calc.and


_pop_print:							; === pops and prints higest operand on stack
	push ebp
	mov ebp, esp

	mov eax, [operand1]
	mov [tail], eax
	mov [head], eax
	print stdout, entry_line
	call print_num
	print stdout, new_line
	call free_num

	mov eax, 0
	pop ebp
ret ; to my_calc.pop_print




_dup:								; === duplicates highest operand on stack
	push ebp
    mov ebp, esp

    mov eax, [operand1]
	mov [operand1_head], eax

	.loop:
		link_value operand1, al
		link_pointer operand1, ecx

		make_link al
		cmp ecx, 0
		je _dup.done

		mov dword [operand1], ecx
		jmp _dup.loop

	.done:
		cmp byte [dbg], 1
    	jne _dup.no_debug1
    	mov dword eax, [head]
    	mov dword [tail], eax
    	call debug_num
    	print stderr, new_line			
    .no_debug1:
	call _push

	mov eax, [operand1_head]	; push op1
	mov [head], eax

		cmp byte [dbg], 1
    	jne _dup.no_debug2
    	mov dword eax, [head]
    	mov dword [tail], eax
    	call debug_num
    	print stderr, new_line			
    .no_debug2:
	call _push

    pop ebp 
ret


_and:								; === binary or on two highest operands
	push ebp
    mov ebp, esp

    mov eax, [operand1]
	mov [operand1_head], eax
	mov eax, [operand2]
	mov [operand2_head], eax

    .loop:
	    link_value operand1, al
	    link_value operand2, bl
	    link_pointer operand1, ecx
	    link_pointer operand2, edx

	    and bl, al
	    make_link bl

	    cmp ecx, 0
	    je _and.op1done
	    cmp edx, 0
	    je _and.op2done

	    mov [operand1], ecx
	    mov [operand2], edx
	    jmp _and.loop

	.op1done:
		cmp edx, 0
		je _and.check_zeroes
		mov [operand1], edx
		jmp _and.onelist

	.op2done:
		cmp ecx, 0
		je _and.check_zeroes
		mov [operand1], ecx

	.onelist:
		link_value operand1, al
		link_pointer operand1, ecx
		mov [operand1], ecx
	
		make_link al
		cmp ecx, 0
		jne _and.onelist


	.check_zeroes:
		mov dword eax, [head]		; save head link
		mov dword [tail], eax

		cmp dword [last_non_zero], 0
		je _and.onlyzeroes

		mov ebx, [last_non_zero]
		cmp dword [ebx+1], 0
		je _and.done

		mov eax, [ebx+1]			; free zeroes
		mov [head], eax
		call free_num
		mov dword [ebx+1], 0		
		mov dword eax, [tail]		; restore head link
		mov dword [head], eax
		jmp _and.done

	.onlyzeroes:
		call free_num				; free the zero sequence
		mov dword [head], 0
     	mov dword [tail], 0 
     	make_link byte 0

	.done:

		cmp byte [dbg], 1
    	jne _and.no_debug
    	mov dword eax, [head]
    	mov dword [tail], eax
    	call debug_num
    	print stderr, new_line			
    .no_debug:

		call _push					; push the new list

		mov eax, [operand1_head]	; free op1
		mov [head], eax
		call free_num

		mov eax, [operand2_head]	; free op2
		mov [head], eax
		call free_num

    pop ebp 
ret ; to my_calc.and

_push:									; === pushes an operand to stack (linked by head)
	push ebp
    mov ebp, esp
	mov eax, [head]
	mov ebx, [op_num]
    mov [my_stack+ebx*4], eax
    inc dword [op_num]
    ;debug_print head
    pop ebp
ret