

#define AVX256

#ifdef size_accum_active
#undef size_accum_active
#endif
#define size_accum_active 256
#include "AccumActivation.h"

#ifdef size_accum_active
#undef size_accum_active
#endif
#define size_accum_active 512
#include "AccumActivation.h"

////////////////////////////////////

#ifdef size_hidden_active
#undef size_hidden_active
#endif
#define size_hidden_active 256
#include "HiddenActivation.h"
