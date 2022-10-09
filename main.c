#include <stdio.h>
#include <stdint.h>

#define RAND_MAX 4294967295  // (2 ^ 32) - 1
#define N 10
uint16_t result[N] = {17747 , 2055 , 3664 , 15611 , 9819 , 18005 , 7515 , 4525 , 17337 , 30985};
uint32_t seed = 1;

uint32_t umull32(uint32_t M, uint32_t m) {

    printf("M: 0x%08x m: 0x%08x\n", M, m);  // debug   %04x -> 4 numeros preenchidos a 0 (016), em format hexadecimal (x)

    int64_t p = (int64_t) m;
    uint8_t p_1 = 0;

    for (uint16_t i = 0; i < 32; i++) {
        printf("umull32 i: %d\n", i); // debug
        printf("Values: M = 0x%08x, p = 0x%016lx, p_1 = 0x%02x\n", M, p, p_1); // debug

        if ((p & 0x1) == 0 && p_1 == 1) {
           p += (int64_t) M << 32;  // cast M to 64!!!!!!
           printf("Sum M left shifted with p\n");
           printf("M: 0x%08x, p: 0x%016lx\n", M, p); // debug
       }

        if ((p & 0x1) == 1 && p_1 == 0) {
            p -= (int64_t) M << 32;
            printf("Sub M shifted with p\n");
            printf("M: 0x%08x, p: 0x%016lx\n", M, p); // debug
        }
        p_1 = p & 0x1;
        p >>= 1;

        printf("\nResult: 0x%08lx\n\n", p); // debug
    }
    printf("%d X %d = %ld\n\n", M, m, p);
    return p;
}


void srand (uint32_t nseed) {
    seed = nseed;
}


uint16_t rand (void) {
    seed = (umull32 ( seed , 214013 ) + 2531011 ) % RAND_MAX ;
    return (seed >> 16);
}


int originalMain() {
    uint8_t error = 0;
    uint16_t rand_number;
    uint16_t i;

    srand(5423);
    for(i = 0; error == 0 && i < N; i++) {
        printf("Main i:%d", i);
        rand_number = rand();
        printf("result[i] = 0x08%x\n", result[i]);
        printf("Rand_number: 0x08%x, result[i]: 0x08%x\n", rand_number, result[i]);
        if (rand_number != result[i]) {
            error = 1;
        }
    }
    return 0;
}


int main() {
    // umull32 Tests (uncomment the test to do)
    //printf("umull32 Test!\n");
    umull32(2, 3);
    //umull32(2147483647, 32767); // 4 bytes 0xFFFF  X 2 bytes 0xFF
    //umull32(RAND_MAX, RAND_MAX); // 8 bytes 0xFFFFFFFF X 8 bytes 0xFFFFFFFF
    // ---------------------------------------------

    // to launch original main, uncomment next line()
    //originalMain();

    return 0;
}
