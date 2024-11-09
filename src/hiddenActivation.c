

#ifdef size_hidden
#include "immintrin.h"
#include "stdint.h"
#include "templates.h"
#include <stdio.h>

void TEMPLATE(testing, size_hidden)() { printf("%d", size_hidden); }

void TEMPLATE(accum_activation8, size_hidden)(int16_t *acc, uint8_t *out) {

#ifdef AVX128
  int num_chunks = input_size / 8;
  __m128i *in_a = (__m128i *)acc;
  __m128i *output = (__m128i *)out;
  const __m128i max_val = _mm_set1_epi16(127);
  const __m128i min_val = _mm_set1_epi16(0);
  for (int i = 0; i < num_chunks / 4; ++i) {
    __m128i temp0 = _mm_load_si128(in_a + 2 * i);
    __m128i temp1 = _mm_load_si128(in_a + num_chunks / 2 + 2 * i);

    __m128i temp2 = _mm_load_si128(in_a + 2 * i + 1);
    __m128i temp3 = _mm_load_si128(in_a + num_chunks / 2 + 2 * i + 1);

    temp0 = _mm_max_epi16(temp0, min_val);
    temp0 = _mm_min_epi16(temp0, max_val);

    temp1 = _mm_max_epi16(temp1, min_val);
    temp1 = _mm_min_epi16(temp1, max_val);

    temp2 = _mm_max_epi16(temp2, min_val);
    temp2 = _mm_min_epi16(temp2, max_val);

    temp3 = _mm_max_epi16(temp3, min_val);
    temp3 = _mm_min_epi16(temp3, max_val);

    __m128i result0 = _mm_srai_epi16(_mm_mullo_epi16(temp0, temp1), 7);
    __m128i result1 = _mm_srai_epi16(_mm_mullo_epi16(temp2, temp3), 7);
    __m128i packed = _mm_packs_epi16(result0, result1);

    _mm_store_si128(output + i, packed);
  }
#endif
#ifdef AVX256
  const int num_chunks = size_hidden / 16;

  __m256i *in_a = (__m256i *)acc;
  __m256i *output = (__m256i *)out;
  const __m256i max_val = _mm256_set1_epi16(127);
  const __m256i min_val = _mm256_set1_epi16(0);
  for (int i = 0; i < num_chunks / 4; ++i) {
    __m256i temp0 = _mm256_load_si256(in_a + 2 * i);
    __m256i temp1 = _mm256_load_si256(in_a + num_chunks / 2 + 2 * i);

    __m256i temp2 = _mm256_load_si256(in_a + 2 * i + 1);
    __m256i temp3 = _mm256_load_si256(in_a + num_chunks / 2 + 2 * i + 1);

    temp0 = _mm256_max_epi16(temp0, min_val);
    temp0 = _mm256_min_epi16(temp0, max_val);

    temp1 = _mm256_max_epi16(temp1, min_val);
    temp1 = _mm256_min_epi16(temp1, max_val);

    temp2 = _mm256_max_epi16(temp2, min_val);
    temp2 = _mm256_min_epi16(temp2, max_val);

    temp3 = _mm256_max_epi16(temp3, min_val);
    temp3 = _mm256_min_epi16(temp3, max_val);

    __m256i result0 = _mm256_srai_epi16(_mm256_mullo_epi16(temp0, temp1), 7);
    __m256i result1 = _mm256_srai_epi16(_mm256_mullo_epi16(temp2, temp3), 7);
    __m256i packed = _mm256_permute4x64_epi64(
        _mm256_packs_epi16(result0, result1), 0b11011000);

    _mm256_store_si256(output + i, packed);
  }
#endif
}
#endif
