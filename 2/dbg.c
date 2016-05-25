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
          mov ecx %%str
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