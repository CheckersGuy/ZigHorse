
#ifdef size_hidden_active

#include "immintrin.h"
#include "stdint.h"
#include "templates.h"
#include <stdio.h>

#include "HiddenActivation.h"
void TEMPLATE(clipped8, size_hidden_active)(int32_t *input, uint8_t *output) {
#ifdef AVX128
  const int num_chunks = size_hidden_active / 4;
  __m128i *in = (__m128i *)input;
  __m128i *out = (__m128i *)output;
  const __m128i max_val = _mm_set1_epi16(127);
  const __m128i min_val = _mm_set1_epi16(0);
  const __m128i zero = _mm_setzero_si128();
  for (int i = 0; i < num_chunks / 4; ++i) {
    __m128i temp1 = _mm_load_si128(in + 4 * i);
    __m128i temp2 = _mm_load_si128(in + 4 * i + 1);
    __m128i temp3 = _mm_load_si128(in + 4 * i + 2);
    __m128i temp4 = _mm_load_si128(in + 4 * i + 3);

    __m128i packed1 = _mm_packs_epi32(temp1, temp2);
    __m128i packed2 = _mm_packs_epi32(temp3, temp4);

    __m128i result = _mm_max_epi8(_mm_packs_epi16(packed1, packed2), zero);
    _mm_store_si128(out + i, result);
  }
#endif
#ifdef AVX256
  const int num_chunks = size_hidden_active / 8;
  const __m256i *in = (__m256i *)input;
  __m256i *out = (__m256i *)output;
  const __m256i max_val = _mm256_set1_epi16(127);
  const __m256i min_val = _mm256_set1_epi16(0);
  const __m256i zero = _mm256_setzero_si256();
  const __m256i control = _mm256_set_epi32(7, 3, 6, 2, 5, 1, 4, 0);
  for (int i = 0; i < num_chunks / 4; ++i) {
    __m256i temp1 = _mm256_load_si256(in + 4 * i);
    __m256i temp2 = _mm256_load_si256(in + 4 * i + 1);
    __m256i temp3 = _mm256_load_si256(in + 4 * i + 2);
    __m256i temp4 = _mm256_load_si256(in + 4 * i + 3);

    __m256i packed1 = _mm256_packs_epi32(temp1, temp2);
    __m256i packed2 = _mm256_packs_epi32(temp3, temp4);

    __m256i result = _mm256_permutevar8x32_epi32(
        _mm256_max_epi8(_mm256_packs_epi16(packed1, packed2), zero), control);
    _mm256_store_si256(out + i, result);
  }
#endif
}

#endif
