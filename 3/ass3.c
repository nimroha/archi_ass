#include <stdio.h>
#include <stdlib.h>
#include <string.h>

extern void scheduler(void);

int WorldLength, WorldWidth;

/* World formatted print */
void printWorld(int **world){
	int current_length, current_width;
	for(current_length = 0 ; current_length < WorldLength ; current_length++){
		if(current_length%2){
			fprintf(stderr, " ");
		}
		for(current_width = 0 ; current_width < WorldWidth ; current_width++){
			fprintf(stderr, "%d ", world[current_length][current_width]);
		}
		fprintf(stderr, "\n");
	}
	for(current_length = 0 ; current_length < WorldLength ; current_length++){
		if(current_length%2){
			fprintf(stderr, " ");
		}
		for(current_width = 0 ; current_width < WorldWidth ; current_width++){
			fprintf(stderr, "%d ", *(*(world + current_length) + current_width) );
			fprintf(stderr, "%p ", world + current_length*WorldWidth + current_width);
		}
		fprintf(stderr, "\n");
	}
}

/* Free the 2d array */
void freeWorld(int **world){
	int i;
	for (i=0 ; i < WorldLength ; i++)
    {
      	free(world[i]);
    }
    free(world);
}

int main(int argc, char** argv){ /* 1-name, 2-length, 3-width, 4-gen, 5-freq */

	int generations, frequency;
	int current_width=0, current_length=0, current_num;
	int **world;
	int i;
	FILE *inFile;

	if(argc < 6){
		fprintf(stderr, "Not enough arguments, exiting...\n");
		exit(EXIT_FAILURE);
	}

	/* Open input file */
	inFile = fopen(argv[1],"r");
	if(inFile == NULL){
		perror("File open error");
		exit(EXIT_FAILURE);
	}

	/* Get world sizes */
	if((WorldLength = atoi(argv[2])) == 0 || (WorldWidth = atoi(argv[3])) == 0){
		fprintf(stderr, "Given dimention is zero or NaN, exiting...\n");
		exit(EXIT_FAILURE);
	}

	/* Dynamic allocate for world matrix */
	world = malloc(WorldLength * sizeof(int*));
    for (i=0 ; i < WorldLength ; i++)
    {
      	world[i] = malloc(WorldWidth * sizeof(int));
    }

	/* Get run args */
	generations = atoi(argv[4]);
	frequency = atoi(argv[5]);

	/* Setup world matrix */
	while ((current_num = fgetc(inFile)) != EOF){
		current_num -= '0';
		switch(current_num){
			case 0:
				world[current_length][current_width] = 0;
				current_width++;
				break;
			case 1:
			    world[current_length][current_width] = 1;
			    current_width++;
			    break;
			case 10-'0':
				current_width = 0;
				current_length++;
		}
	}

	/* Print test */
	printWorld(world);

	scheduler();

	/* Cleanup */
	freeWorld(world);
	fclose(inFile);


	exit(EXIT_SUCCESS);
}