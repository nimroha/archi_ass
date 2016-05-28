;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;    this is the current working file!    ;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


%define STACKSIZE 5
%define BUFFERSIZE 80

section .rodata
frmt_str:      DB   "%s", 0        ; format string
prompt_str:    DB   "calc: ",0,0              ; input message
in_str:        DB   "got %s", 0        ; format string
over_flow_str: DB   "Error: Operand Stack Overflow",10,0 ; stack overflow message
no_args_str:   DB   "Error: Insufficient Number of Arguments on Stack",10,0 ; insufficient arguments message
illegal_str:   DB   "Error: Illegal Input",10,0 ; illegal input message
ctr_str:       DB   "Number of operations: %d", 10, 0 ; exit message
read_str:      DB   "Read %s to buffer", 10, 0 ; read to buffer message
push_str:      DB   "Pushed %d to stack", 10, 0 ; push message
d_flag:        EQU  0x642d ; -d in ascii

     
section .bss
buffer:        RESB BUFFERSIZE ; input buffer
my_stack:      RESD STACKSIZE ; operand stack

section .data
dbg:           DB 0 ; debug flag
op_num:        DD 0 ; number of operands in the stack
counter: 	  	DD 0 ; operation counter
head: 			DD 0 ; head of current operand
tail: 			DD 0 ; tail of current operand



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

%macro sys_debug 1+  ; not used!!!!!!!
     cmp byte [dbg], 0
     je %%skip
          pushad
          jmp %%endstr
          %%str: db %1
          %%endstr:
          mov eax, 4
          mov ebx, 2
          mov edx, %%endstr - %%str
          mov ecx, %%str
          int 0x80
          popad
     %%skip:
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
          add esp, 1+4*%0
          popad
     %%skip:
%endmacro

%macro make_link 1         ; %1=number
     pushad
     push 5
     call malloc
     mov byte [eax], %1
     mov dword [eax+1], 0
     									; ============== added linking to the macro, perhaps should just use a func ?
     cmp dword [head], 0				; check if its the first link, if so set as head and tail, if not link tail to the new link created
     jne %%link_tail
     mov [head], eax
     mov [tail], eax
     jmp %%done
     %%link_tail:						; link a new link to the tail
     mov dword [tail+1], eax			; set the new link as the NEXT of tail
     %%done:

     add esp, 4
     popad
%endmacro

%macro check_num 2 ; %1=byte to check %2=label to go
     cmp byte %1, 57
     ja %2
     cmp byte %1, 48
     jb %2
     sub al, '0'
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
     cmp al, d_flag     ; check if -d 
     jne call_calc
     mov byte [dbg], 1  ; raise dbg flag
     jmp call_calc

call_calc:
     pushad
     pushfd

	call my_calc 
     ctr:
     print stdout, ctr_str, eax

     ; =============== This actually prints the format ====================
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

     ; ================ trying to test whether linking was succesful
     mov eax, [head]
     mov byte bl, [eax]						; ========= x/10cb $eax
     abc:
     mov dword [head], 0
     mov dword [tail], 0

    pushad
    push dword [stdin]
    push BUFFERSIZE
    push buffer
    call fgets ; does eax now hold the number of chars read??
    add esp, 12
    popad

    print stdout, buffer 

    ; =============== This actually prints the format ====================
    pushad
    push buffer
    push in_str
    push dword [stdout]
    call fprintf
    add esp, 12
    popad

    ;debug buffer 			; !!!causes segfault!!!

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
     ;check_num al, my_calc.illegal  	; ========= replaced with a thorough check on buffer

	 ;cmp dword [op_num], STACKSIZE
     ;jne my_calc.push
     ;print stderr, over_flow_str

mov eax, buffer 						; ========= x/10cb $eax

check_my_num:							; ========= i am the replacement
	mov ecx,0
	.looptyloop:
		cmp byte [buffer+ecx], 10
		je check_my_num.confirmed
		cmp byte [buffer+ecx], 57
     	ja my_calc.illegal
     	cmp byte [buffer+ecx], 48
     	jb my_calc.illegal
     	sub byte [buffer+ecx], '0'
     	inc ecx
     	jmp check_my_num.looptyloop
    .confirmed:							; ========= ecx contains amount of digits
    	cmp dword [op_num], STACKSIZE
    	je check_my_num.overflow
    .linking:							; ========= THIS TILL END OF BLOCK IS STILL IN TESTING AND TOUGHTS
    	cmp ecx, 1						; check if last nibble (requires "zero padding")
    	je check_my_num.last_nibble
    	cmp ecx, 0 						; check if done
    	je check_my_num.done
    	mov byte dl, [buffer+ecx]		; get first nibble
    	dec ecx
    	shl byte [buffer+ecx], 4
    	add byte dl, [buffer+ecx]		; get second nibble
    	dec ecx

    	make_link dl

    	jmp check_my_num.linking
    .last_nibble:
    	mov byte dl, [buffer+ecx]
    	make_link dl
    	dec ecx
    .done:
    	jmp my_calc.push
    .overflow:
    	print stderr, over_flow_str
		jmp my_calc.get_input			; ======= END OF NOT FINISHED AND NOT WORKING BLOCK

    


	




my_calc.illegal:
     print stderr, illegal_str
     jmp my_calc.get_input

my_calc.add:
     cmp word [op_num], 2
     jb skip_add
     ;pop 2 numbers from my_stack and push to stack
     ;call _add
     ;push eax to my_stack
     ;print answer (eax)
     jmp my_calc.get_input
     skip_add:
     print stderr, no_args_str

my_calc.pop_print:
     cmp word [op_num], 1
     jb skip_pop
     ;pop 1 number from my_stack and push to stack
     ;call _pop_print
     ;print answer (eax)
     jmp my_calc.get_input
     skip_pop:
     print stderr, no_args_str

my_calc.dup:
     cmp word [op_num], 1
     jb skip_dup
     ;pop 1 number from my_stack and push to stack
     ;call _dup
     jmp my_calc.get_input
     skip_dup:
     print stderr, no_args_str

my_calc.and:
     cmp word [op_num], 2
     jb skip_and
     ;pop 2 numbers from my_stack and push to stack
     ;call _and
     ;push eax to my_stack
     ;print answer (eax)
     jmp my_calc.get_input
     skip_and:
     print stderr, no_args_str

my_calc.push:
	pushad
	mov eax, [head]
	mov ebx, [op_num]
    mov [my_stack+ebx], eax
    inc dword [op_num]
    popad
    jmp my_calc.get_input



my_calc.quit:
     ;;;;TODO: free all mallocs
     mov eax, [counter]
     mov esp, ebp
     pop ebp
     ret ; !!ret only works in local labels !!
     

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;  sub-routines  ;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

_add:

_pop_print:

_dup:

_and:

_push: