

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

#ifdef size_outdim_accum
#undef size_outdim_accum
#endif
#define size_outdim_accum 8192
#include "AccumForward.h"
