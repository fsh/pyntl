#ifndef _ccore_h
#define _ccore_h

#include <iostream>
#include <sstream>
#include <vector>
#include <string>
#include <algorithm>
#include <cstdint>
#include <utility>

#include "Python.h"
#include "ntl_wrap.h"
// #include <NTL/ZZ.h>
#include <NTL/ZZ_limbs.h>

typedef std::vector<uint8_t> bytes_t;

static uint8_t bitrev_table[16] = {
  0x0, 0x8, 0x4, 0xc, 0x2, 0xa, 0x6, 0xe,
  0x1, 0x9, 0x5, 0xd, 0x3, 0xb, 0x7, 0xf, };
static inline uint8_t reverse_bits(uint8_t c) {
  return bitrev_table[c & 0x0f] << 4 | bitrev_table[c >> 4];
}


static bool bytevec_from_ZZ(bytes_t& out, const ZZ& num) {
  out.resize(NumBytes(num));
  BytesFromZZ(&out[0], num, out.size());
  return true;
}

static bool bytevec_from_PyLong(bytes_t& out, PyObject* obj, bool little_endian) {
  if (!PyLong_Check(obj)) {
    return false;
  }

  // Hack to get around the silly behavior of _PyLong_AsByteArray.
  // Force the long object to be positive.
  bool flip = false;
  if (Py_SIZE(obj) < 0) {
    Py_SIZE(obj) = -Py_SIZE(obj);
    flip = true;
  }
  
  size_t nbytes = (_PyLong_NumBits(obj) + 7) / 8;
  out.resize(nbytes);
  if (_PyLong_AsByteArray((PyLongObject *)obj, &out[0], nbytes, little_endian, 0) == -1) {
    PyErr_Clear();
    return false;
  }

  if (flip) {
    Py_SIZE(obj) = -Py_SIZE(obj);
  }

  return true;
}

static bool ZZ_from_PyLong(ZZ& out, PyObject* obj) {
  if (!PyLong_Check(obj)) {
    return false;
  }

  int overflow = 0;
  long res = PyLong_AsLongAndOverflow(obj, &overflow);

  if (!overflow) {
    out = res;
    return true;
  }

  bytes_t scratch;
  if (!bytevec_from_PyLong(scratch, obj, true)) {
    return false;
  }

  ZZFromBytes(out, &scratch[0], scratch.size());

  if (Py_SIZE(obj) < 0) {
    negate(out, out);
  }
  return true;
}

/* More sane ZZ<->GF2X conversions than the one that simply does (mod 2). */
void GF2X_from_ZZ(GF2X& dest, ZZ const& src) {
  bytes_t scratch(NumBytes(src));
  BytesFromZZ(&scratch[0], src, scratch.size());
  GF2XFromBytes(dest, &scratch[0], scratch.size());
}

void ZZ_from_GF2X(ZZ& dest, GF2X const& src) {
  bytes_t scratch(NumBytes(src));
  BytesFromGF2X(&scratch[0], src, scratch.size());
  ZZFromBytes(dest, &scratch[0], scratch.size());
}





/***
 * Some functions that are missing from the NTL library.
 */

/* ZZX exponentiation. */
static void power(ZZX& res, ZZX const& src, long e) {
  if (e == 0) {
    res = 1;
    return;
  } else if (e == 1) {
    res = src;
    return;
  } else if (e < 0) {
    // ERROR: just never do this.
    return;
  }

  ZZX half;
  power(half, src, e/2);
  mul(res, half, half);
  if (e & 1) {
    mul(res, res, src);
  }
}

/* ZZX evaluation. */
static void eval(ZZ& res, ZZX const& src, ZZ const& val) {
  if (deg(src) < 0) {
    res = 0;
    return;
  }

  res = src[0];
  ZZ x(1);
  for (auto i = 1; i <= deg(src); ++i) {
    x *= val;
    if (!IsZero(src[i])) {
      MulAddTo(res, src[i], x);
    }
  }
}

/* GF2X evaluation. */
static void eval(GF2& res, GF2X const& src, GF2 const& val) {
  if (IsZero(val)) {
    res = 0;
  } else {
    res = weight(src) % 2;
  }
}

/* GF2X monic: trivial. */
static void MakeMonic(GF2X& res) {
}

/* vector elementwise multiplication. */
template <class T>
static void mul_by_elts(T& dest, T const& a, T const& b) {
  long n = std::min(a.length(), b.length());
  dest.SetLength(n);
  for (auto i = 0; i < n; ++i) {
    dest[i] = a[i] * b[i];
  }
}


/* Python hashing. */
const long hash_mod = 2305843009213693951;

static long hash_ZZX(ZZX const& src) {
  long h = 0;
  for (auto i = 0; i <= deg(src); ++i) {
    h *= 257;
    h += rem(src[i], hash_mod);
  }
  return h;
}

static long hash_ZZ_pX(ZZ_pX const& src, ZZ const& mod) {
  long h = rem(mod, hash_mod);
  for (auto i = 0; i <= deg(src); ++i) {
    h *= 257;
    h += rem(rep(src[i]), hash_mod);
  }
  return h;
}

// static std::vector<std::pair<ZZ_pX,long>> factor_pX(ZZ_pX const& poly) {
//   std::vector<std::pair<ZZ_pX,long>> res;
//   vec_pair_ZZ_pX_long lst = CanZass(poly);
//   for (auto&& v : lst) {
//     res.push_back(std::make_pair(v.a, v.b));
//   }
//   return res;
// }

#endif
