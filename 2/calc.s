;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;    this is the current working file!    ;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


%define STACKSIZE 5
%define BUFFERSIZE 80

section .rodata
frmt_str:      DB   "%s", 0        ; format string
prompt_str:    DB   "calc: ",0               ; input message
over_str:      DB   "Error: Operand Stack Overflow",10,0 ; stack overflow message
no_args_str:   DB   "Error: Insufficient Number of Arguments on Stack",10,0 ; insufficient arguments message
illegal_str:   DB   "Error: Illegal Input",10,0 ; illegal input message
d_flag:        EQU  0x642d ; -d in ascii

     
section .bss
buffer:        RESB BUFFERSIZE ; input buffer
stack:         RESD STACKSIZE ; operand stack

section .data
dbg:           DB 0 ; debug flag
op_num:        DB 0 ; number of operands in the stack



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

%macro print_err 1 
     pushad
     push %1
     push dword [stderr]
     call fprintf
     add esp, 8
     popad
%endmacro

%macro print_out 1
     pushad
     push %1
     call printf
     add esp, 4
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

%macro debug 1-* ; enter as many arguments as needed but reverse order from C convention
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

%macro make_link 2         ; %1=number %2=pointer to previous link->next
     pushad
     push 5
     call malloc
     mov [%2], eax
     mov byte ptr [eax], %1
     mov dword ptr [eax+1], 0
     add esp, 4
     popad
%endmacro

%macro check_num 1
     cmp byte %1, 57
     ja _illegal
     cmp byte %1, 48
     jb _illegal
%endmacro

main: 



     push ebp  ; save stack pointer
     mov ebp, esp

     mov eax, [ebp+8]  ; num of arguments
     num:
     cmp eax, 2 
     jne my_calc
     mov eax, [ebp+12] ; get pointer to argv
     mov ebx, [eax+4] ; get pointer to first argument
     mov eax, [ebx] ; get first argument


     arg:
     cmp al, d_flag     ; check if -d 
     jne my_calc
     mov byte [dbg], 1        ; raise dbg flag
     jmp my_calc

my_calc:

     sys_debug "in my_calc", 10, 0

     

     .get_input:
     print_out prompt_str

     mov eax, 3 ; read to buffer
     mov ebx, 0
     mov ecx, buffer
     mov edx, BUFFERSIZE
     int 0x80

  

    
     pushad ;;TODO delete this
     mov eax, 4
     mov ebx, 1
     mov ecx, buffer
     mov edx, BUFFERSIZE
     int 0x80
     popad


     mov al, [buffer] ; for switch case
q:
     cmp al, 'q'
     je _quit
plus:
     cmp al, '+'
     je _add
p:
     cmp al, 'p'
     je _pop_print
d:
     cmp al, 'd'
     je _duplicate
and_:
     cmp al, '&'
     je _and
number:
     check_num al



jmp my_calc.get_input

_illegal:
     print_err illegal_str
     jmp my_calc.get_input

_add:
_pop_print:
_duplicate:
_and:


_quit:
     ;;;;TODO: free all mallocs
     mov eax, 1
     int 0x80
     nop

     
