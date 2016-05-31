CC		:=	gcc 
CC_FLAGS	:=	-m32 -Wall -g
ASM		:=	nasm
ASM_FLAGS	:=	-f elf


all: 
	$(ASM) $(ASM_FLAGS) scheduler.s -o scheduler.o
	$(ASM) $(ASM_FLAGS) printer.s -o printer.o
	$(CC) $(CC_FLAGS) ass3.c scheduler.o printer.o -o ass3
	

# scheduler.o:	
# 	$(ASM) $(ASM_FLAGS) scheduler.s -o scheduler.o
	
# //task2:
# 	$(ASM) $(ASM_FLAGS)  task2.s -o task2.o
# 	$(CC) $(CC_FLAGS) main2.c  task2.o -o task2.bin

.PHONY: clean

clean:
	rm -f *.o ass3
