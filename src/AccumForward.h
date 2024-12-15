
#ifdef size_outdim_accum
#include "stdint.h"
#include "templates.h"

void TEMPLATE(accum_forward,
              size_outdim_accum)(int16_t *ft_weights, int32_t *added,
                                 int32_t *removed, int32_t num_active,
                                 int32_t num_removed);

#endif
