#include <stdio.h>
#include <stdlib.h> 

int main(int argc, char* argv[]) {
    int *p1 = malloc(1000*sizeof(int));
    printf("Succes at 1000\n");
    free(p1);

    int *p2 = malloc(10000000*sizeof(int));
    printf("Succes at 10000000\n");
    free(p2);

}