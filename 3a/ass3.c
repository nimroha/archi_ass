#include <stdio.h>
#include <stdlib.h>
#include <string.h>

extern void initialize(char**);

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
			fprintf(stderr, "%p ", *(world + current_length) + current_width);
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


	if(argc < 6){
		fprintf(stderr, "Not enough arguments, exiting...\n");
		exit(EXIT_FAILURE);
	}

	initialize(argv);
	

	exit(EXIT_SUCCESS);
}