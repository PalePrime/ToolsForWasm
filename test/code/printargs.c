#include <stdio.h>

int main(int argc, char* argv[]) {
    printf("Args (%i):", argc);
    for (int i = 0; i < argc; i++) {
        printf(" %s", argv[i]);
    }
    printf("\n");
}