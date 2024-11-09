#ifndef BINDINGS
#define BINDINGS
#include "immintrin.h"
#include "stdio.h"
void foo(void);

void foo2(int *pointer, int num_items);

void testing_simd(int *a, int *b, int *result, int num_elements);
#endif // !BINDINGS
