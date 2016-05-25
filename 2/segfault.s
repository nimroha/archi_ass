section .rodata
StrF:          DB   "%s", 10, 0    ; Format string
InStr:         DB   "calc: ",0     ; Input message
BUFFERSIZE:    EQU  80
     
section .bss
buffer:        RESB 80

section .data


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

%macro print 2
     push %1
     push %2
     call printf
     add esp, 8
%endmacro

main: 
     ;print InStr, StrF
     push InStr
     push StrF
     call printf
     add esp, 8
     
     push buffer
     ;push BUFFERSIZE
     ;push stdin
     ;call fgets
     ;add esp, 12

 