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


//////////////////////////////////////////

/*
static void zz_from_bytes(ZZ& dest, uint8_t const* src, size_t len, int msb) {
  if (msb != 0) {
    // Little endian: NTL's default.
    ZZFromBytes(dest, src, len);
  } else {
    // Big endian.
    std::vector<uint8_t> scratch;
    scratch.resize(len);
    std::reverse_copy(src, src + len, scratch.begin());
    ZZFromBytes(dest, &scratch[0], len);
  }
}


static std::vector<uint8_t> bytes_from_ZZ(ZZ const& src) {
  std::vector<uint8_t> scratch(NumBytes(src));
  BytesFromZZ(&scratch[0], src, scratch.size());
  return scratch;
}
*/


// static bool zz_from_pylong(ZZ& out, PyObject* obj) {
//   if (!PyLong_Check(obj)) {
//     return false;
//   }

//   int error;
//   long temp = PyLong_AsLongAndOverflow(x, &error);

//   if (!error) {
//     out = temp;
//     return true;
//   }

//   mpz_set_PyIntOrLong(result->z, x);
//   mpz_mul(result->z, result->z, MPZ(y));
//   return (PyObject*)result;
// }

// static void GF2X_from_bytes(GF2X& dest, uint8_t const* src, size_t len, int msb) {
//   std::vector<uint8_t> scratch(len);

//   if (msb) {
//     std::reverse_copy(src, src + len, scratch.begin());
//   } else {
//     for (auto i = 0; i < len; ++i) {
//       scratch[i] = reverse_bits(src[i]);
//     }
//   }
//   GF2XFromBytes(dest, src, src + len);
// }

/*
static std::string zz_to_string(ZZ& src, int base) {
  if (base == 10) {
    std::ostringstream store;
    store << src;
    return store.str();
  } else {
    return std::string("not impl");
  }
}

static void zz_from_string(ZZ& dest, std::string const& src, int base) {
  if (base == 10) {
    std::istringstream store(src);
    store >> dest;
  } else {
    // XXX
    return;
  }
}

static void conv_gf2x_to_zz(ZZ& dest, GF2X const& src) {
  size_t sz = NumBytes(src);
  bytes_t tmp(sz);
  BytesFromGF2X(&tmp[0], src, sz);
  ZZFromBytes(dest, &tmp[0], sz);
}

static void conv_zz_to_gf2x(GF2X& dest, ZZ const& src) {
  size_t sz = NumBytes(src);
  bytes_t tmp(sz);
  BytesFromZZ(&tmp[0], src, sz);
  GF2XFromBytes(dest, &tmp[0], sz);
}

static std::vector<std::pair<ZZ_pX,long>> factor_pX(ZZ_pX const& poly) {
  std::vector<std::pair<ZZ_pX,long>> res;
  vec_pair_ZZ_pX_long lst = CanZass(poly);
  for (auto&& v : lst) {
    res.push_back(std::make_pair(v.a, v.b));
  }
  return res;
}

ZZ find_smooth_power(long bound, ZZ_p const& g) {
  PrimeSeq prime_seq;
  std::vector<long> small_primes;

  prime_seq.reset(3);
  for (long p = prime_seq.next(); p < bound; p = prime_seq.next()) {
    // std::cout << p << "\n";
    small_primes.push_back(p);
  }

  ZZ_p b;
  ZZ e = RandomBnd(ZZ_p::modulus());
  power(b, g, e);

  for (;; b *= g) {
    ZZ n(rep(b));
    MakeOdd(n);
    for (long p: small_primes) {
      while (divide(n, n, p)) {
        // std::cout << n << "\n";
      }
    }
    if (IsOne(n)) {
      return e;
    }
  }
}
*/

/* Copies the ZZ into the mpz_t
   Assumes output has been mpz_init'd.
   AUTHOR: David Harvey
   Joel B. Mohler moved the ZZX_getitem_as_mpz code out to this function (2007-03-13) */
/* static void ZZ_to_mpz(mpz_t output, const struct ZZ* x) */
/* { */
/*   mpz_import(output, x->size(), -1, sizeof(mp_limb_t), 0, 0, ZZ_limbs_get(*x)); */
/*   if (sign(*x) < 0) */
/*     mpz_neg(output, output); */
/* } */

/* Copies the mpz_t into the ZZ
   AUTHOR: Joel B. Mohler (2007-03-15) */
/* static void mpz_to_ZZ(struct ZZ* output, mpz_srcptr x) */
/* { */
/*   unsigned char stack_bytes[4096]; */
/*   size_t size = (mpz_sizeinbase(x, 2) + 7) / 8; */
/*   int use_heap = (size > sizeof(stack_bytes)); */
/*   void* bytes = use_heap ? malloc(size) : stack_bytes; */
/*   size_t words_written; */
/*   mpz_export(bytes, &words_written, -1, 1, 0, 0, x); */
/*   clear(*output); */
/*   ZZFromBytes(*output, (unsigned char *)bytes, words_written); */
/*   if (mpz_sgn(x) < 0) */
/*     NTL::negate(*output, *output); */
/*   if (use_heap) */
/*     free(bytes); */
/* } */

#endif
