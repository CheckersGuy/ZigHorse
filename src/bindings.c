
#define AVX256

#ifdef size_hidden
#undef size_hidden
#endif

#define size_hidden 256
#include "hiddenActivation.c"

#define size_hidden 512
#include "hiddenActivation.c"
