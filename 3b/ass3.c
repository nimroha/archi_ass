#include <stdio.h>
#include <stdlib.h>
#include <string.h>

extern void coroutines_init(int*);

int WorldLength, WorldWidth, generations, frequency;
int *world;

/* World formatted print */
void printWorld(int *world){
	int current_length, current_width;
	for(current_length = 0 ; current_length < WorldLength ; current_length++){
		if(current_length%2){
			fprintf(stderr, " ");
		}
		for(current_width = 0 ; current_width < WorldWidth ; current_width++){
			fprintf(stderr, "%d ", world[current_length*WorldWidth + current_width]);
		}
		fprintf(stderr, "\n");
	}
	/*for(current_length = 0 ; current_length < WorldLength ; current_length++){
		if(current_length%2){
			fprintf(stderr, " ");
		}
		for(current_width = 0 ; current_width < WorldWidth ; current_width++){
			fprintf(stderr, "%d ", *(world + current_length*WorldWidth + current_width));
			fprintf(stderr, "%p ", (world + current_length*WorldWidth + current_width));
		}
		fprintf(stderr, "\n");
	}*/
}

/* Free the 2d array */
void freeWorld(int *world){
    free(world);
}

int main(int argc, char** argv){ /* 1-name, 2-length, 3-width, 4-gen, 5-freq */

	int current_width=0, current_length=0, current_num;
	FILE *inFile;
	int d=0;

	if(argc < 6){
		fprintf(stderr, "Not enough arguments, exiting...\n");
		exit(EXIT_FAILURE);
	}

	if(argc == 7 && !strcmp(argv[1],"-d")){
		d = 1;		
	}

	/* Open input file */
	inFile = fopen(argv[d+1],"r");
	if(inFile == NULL){
		perror("File open error");
		exit(EXIT_FAILURE);
	}

	/* Get world sizes */
	if((WorldLength = atoi(argv[d+2])) == 0 || (WorldWidth = atoi(argv[d+3])) == 0){
		fprintf(stderr, "Given dimention is zero or NaN, exiting...\n");
		exit(EXIT_FAILURE);
	}

	/* Dynamic allocate for world matrix */
	world = (int *) malloc(WorldLength * WorldWidth * sizeof(int));

	/* Get run args */
	generations = atoi(argv[d+4]);
	frequency = atoi(argv[d+5]);

	/* Setup world matrix */
	while ((current_num = fgetc(inFile)) != EOF){
		current_num -= '0';
		switch(current_num){
			case 0:
				if(current_length < WorldLength && current_width < WorldWidth){
					world[current_length*WorldWidth + current_width] = 0;
					current_width++;
				}
				break;
			case 1:
				if(current_length < WorldLength && current_width < WorldWidth){
			    	world[current_length*WorldWidth + current_width] = 1;
			    	current_width++;
			    }
			    break;
			case 10-'0':
				current_width = 0;
				current_length++;
		}
	}

	if(d){
		printf("length=%d\nwidth=%d\nnumber of generations=%d\nprint frequency=%d\n",WorldLength, WorldWidth, generations, frequency);
		printWorld(world);

	}


	coroutines_init(world);
	

	/* Cleanup */
	freeWorld(world);
	fclose(inFile);


	exit(EXIT_SUCCESS);
}