section .rodata
frmt_str:      DB   "%s", 10, 0        ; format string
in_str:        DB   "calc: ",0     ; input message
in_str_len:    EQU   $ - in_str
over_str:      DB   "Error: Operand Stack Overflow",0 ; stack overflow message
no_args_str:   DB   "Error: Insufficient Number of Arguments on Stack",0 ; insufficient arguments message
illegal_str:   DB   "Error: Illegal Input",0 ; illegal input message


BUFFERSIZE:    EQU  80
d_flag:        DB   "-d"
     
section .bss
buffer:        RESB 80

section .data
dbg:           db 0


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

%macro print 1
     pushad
     jmp %%endstr
     %%str: db %1
     %%endstr:
     mov eax, 4
     mov ebx, 1
     mov edx, %%endstr - %%str
     mov ecx %%str
     int 0x80
     popad
%endmacro

%macro debug 1+
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


          

main: 
     
     pop eax              ; num of arguments
     cmp eax, 2
     jne my_calc
     pop ebx              ; program name
     pop ebx              ; first argument
     cmp ebx, d_flag ; check -d flag
     jne my_calc
     mov byte [dbg], 1        ; raise dbg flag
     jmp my_calc

my_calc:
     push esp            ; save stack pointer
     mov ebp, esp

     ;debug "in my_calc", 10, 0

     .prompt:
     pushad
     mov eax, 4
     mov ebx, 1
     mov ecx, in_str
     mov edx, in_str_len
     int 0x80

     print {"calc: ", 10, 0}
     
     .get_input:
     mov eax, 3
     mov ebx, 0
     mov ecx, buffer
     mov edx, BUFFERSIZE
     int 0x80

    ; debug "read input to buffer", 10, 0


     mov eax, 4
     mov ebx, 1
     mov ecx, buffer
     mov edx, BUFFERSIZE
     int 0x80
     popad


     mov eax, [buffer]


     mov eax, 4
     mov ebx, 1
     mov ecx, buffer+1
     mov edx, BUFFERSIZE
     int 0x80
q:
     cmp eax, 'q'
     je _quit
plus:
     cmp eax, '+'
     je _add
p:
     cmp eax, 'p'
     je _pop_print
d:
     cmp eax, 'd'
     je _duplicate
_and_:
     cmp eax, '&'
     je _and




_add:
_pop_print:
_duplicate:
_and:


_quit:
     ;;;;TODO: free all mallocs
     mov eax, 1
     int 0x80
     nop

     
