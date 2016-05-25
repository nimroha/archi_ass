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

%macro print 1+
     jmp %%endstr
     %%str: db %1
     %%endstr:
     pushad
     mov ecx, %%str
     mov edx, %%endstr - %%str
     mov ebx, 1
     mov eax, 4
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
a1:
     ;pop eax                  ; num of arguments
a2:
     cmp eax, 2
     jne my_calc
b1:
     pop ebx                  ; program name
b2:
     pop ebx                  ; first argument
b3:
     cmp ebx, [d_flag]        ; check -d flag
     jne my_calc
     mov byte [dbg], 1        ; raise dbg flag
     jmp my_calc

my_calc:
     pushad
     ;mov eax, 4
     ;mov ebx, 1
     ;mov ecx, InStr
     ;mov edx, 6
     ;int 0x80

     print "calc: ",0
     debug "Dcalc: ",0
     

     
     mov eax, 3
     mov ebx, 0
     mov ecx, buffer
     mov edx, BUFFERSIZE
     int 0x80
     

     
     mov eax, 4
     mov ebx, 1
     mov ecx, buffer
     mov edx, BUFFERSIZE
     int 0x80
     popad

     mov al, [buffer]

     cmp al,'p'
     je _pop_print
     cmp al,'q'
     je _quit
     cmp al,'d'
     je _duplicate
     cmp al,'+'
     je _plus
     cmp al,'&'
     je _and
     jmp end

_pop_print:
     ;mov eax, 4
     ;mov ebx, 1
     ;mov ecx, pStr 
     ;mov edx, pLen
     ;int 0x80
     print "Seen p",10,0
     jmp end
_quit:
     print "Seen q",10,0
     jmp end
_duplicate:
     print "Seen d",10,0
     jmp end
_plus:
     print "Seen +",10,0
     jmp end
_and:
     print "Seen &",10,0
     jmp end

end:
     jmp my_calc


 