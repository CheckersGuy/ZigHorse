#ifdef size_outdim_accum
#include "immintrin.h"
#include "stdint.h"
#include "templates.h"
#include <stdio.h>

void TEMPLATE(acum_forward, size_outdim_accum)(int16_t *ft_weights,
                                               int32_t *added, int32_t *removed,
                                               int32_t num_active,
                                               int32_t num_removed) {
  __m256i *accu = (__m256i *)input;
  const int num_regs = 16; // number of available avx2 registers
  const int OutRegisters =
      size_outdim_accum / 16; // each register can hold 16 int16_t
  const int num_chunks = OutRegisters / num_regs; // we have 16 avx2 registers

  for (int k = 0; k < num_chunks; ++k) {
    __m256i regs[num_regs];

    for (int i = 0; i < num_regs; ++i) {
      regs[i] = _mm256_load_si256(accu + i + k * num_regs);
    }
    for (int i = 0; i < num_active; ++i) {
      const __m256i *weights =
          (__m256i *)(ft_weights + size_outdim_accum * added[i]);

      for (int j = 0; j < num_regs; ++j) {
        regs[j] = _mm256_add_epi16(
            _mm256_load_si256(weights + j + k * num_regs), regs[j]);
      }
    }

    for (int i = 0; i < num_removed; ++i) {
      const __m256i *weights =
          (__m256i *)(ft_weights + size_outdim_accum * removed[i]);
      for (int j = 0; j < num_regs; ++j) {
        regs[j] = _mm256_sub_epi16(
            regs[j], _mm256_load_si256(weights + j + k * num_regs));
      }
    }
    for (int i = 0; i < num_regs; ++i) {
      _mm256_store_si256(accu + i + k * num_regs, regs[i]);
    }
  }
}

#endif
