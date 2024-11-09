#include "bindings.h"
#include <stdio.h>
void foo(void) { printf("Das ist ein Test \n"); }

void foo2(int *pointer, int num_items) {
  for (int i = 0; i < num_items; ++i) {
    printf("Value %d at index %d \n", pointer[i], i);
  }
}
// vector addition of two arrays
// we make the assumption that num_elements is a multiple of 8
void testing_simd(int *a, int *b, int *result, int num_elements) {

  for (int i = 0; i < num_elements; i += 8) {
    // loading the two avx registers
    // adding the registers
    // storing the computation in result
    // will do that tomorrow:w!

    __m256i x = _mm256_load_si256((__m256i *)(a + i));
    __m256i y = _mm256_load_si256((__m256i *)(b + i));
    __m256i r = _mm256_add_epi32(x, y);
    _mm256_store_si256((__m256i *)(result + i), r);
  }
}
