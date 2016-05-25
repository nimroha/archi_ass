section .rodata
StrF:          DB   "%s", 0    ; Format string
InStr:         DB   "calc: ",0     ; Input message
BUFFERSIZE:    EQU  80
d_flag:        DB   "-d",0

     
section .bss
buffer:        RESB 80

section .data
dbg:           DB   0


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

     extern fputs 



main:
     push    ebp         ; set up stack frame
     mov     ebp,esp
b1:
	
	;push StrF
     push dword 1
     ;push dword InStr
b2:
     call printf
b3:
	add esp, 4

     mov     esp, ebp    ; takedown stack frame
     pop     ebp      ; same as "leave" op

     mov  eax,0          ;  normal, no error, return value
     ret            ; return
