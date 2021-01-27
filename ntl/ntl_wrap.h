#ifndef NTLWRAP_H
#define NTLWRAP_H

#ifdef __cplusplus

// Base rings.
#include <NTL/ZZ.h>
#include <NTL/ZZ_p.h>
#include <NTL/ZZ_pE.h>
#include <NTL/GF2.h>
#include <NTL/GF2E.h>

// Polynomial rings.
#include <NTL/ZZX.h>
#include <NTL/GF2X.h>
#include <NTL/GF2EX.h>
#include <NTL/ZZ_pX.h>
#include <NTL/ZZ_pEX.h>

// Vectors.
#include <NTL/vec_ZZ.h>
#include <NTL/vec_ZZ_p.h>
#include <NTL/vec_ZZ_pE.h>
#include <NTL/vec_GF2.h>
#include <NTL/vec_GF2E.h>

// Matrices.
#include <NTL/mat_ZZ.h>
#include <NTL/mat_ZZ_p.h>
#include <NTL/mat_ZZ_pE.h>
#include <NTL/mat_GF2.h>
#include <NTL/mat_GF2E.h>


#include <NTL/ZZXFactoring.h>
#include <NTL/ZZ_pXFactoring.h>
#include <NTL/ZZ_pEXFactoring.h>
#include <NTL/GF2XFactoring.h>
#include <NTL/GF2EXFactoring.h>

#include <NTL/mat_poly_ZZ.h>
#include <NTL/HNF.h>
#include <NTL/LLL.h>
#include <NTL/lzz_p.h>
#include <NTL/lzz_pX.h>

using namespace NTL;
#endif

#endif
