CC		:=	gcc 
CC_FLAGS	:=	-m32 -Wall -g
ASM		:=	nasm
ASM_FLAGS	:=	-f elf 


all: clean calc

calc:	
	$(ASM) $(ASM_FLAGS) calc.s -o calc.o
	$(CC) $(CC_FLAGS) calc.o -o calc.bin
	
.PHONY: clean

clean:
	rm -f *.o calc