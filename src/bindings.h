#ifndef BINDINGS_H
#define BINDINGS_H
#include "templates.h"
#ifdef size_hidden
#undef size_hidden
#endif
#define size_hidden 256
#include "hiddenActivation.h"

#ifdef size_hidden
#undef size_hidden
#endif
#define size_hidden 512
#include "hiddenActivation.h"

#endif // !BINDINGS_H
