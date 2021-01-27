
from libcpp.vector cimport vector
from libcpp.string cimport string
from libcpp.algorithm cimport reverse
from libcpp.pair cimport pair
from cpython.object cimport Py_LT, Py_LE, Py_EQ, Py_NE, Py_GT, Py_GE
from cysignals.signals cimport sig_on, sig_off

from .ntl_ZZ cimport *

ctypedef unsigned char uint8_t
ctypedef vector[uint8_t] bytevec

cdef extern from "ccore.h":
  bint ZZ_from_PyLong(ZZ_c&, object)
  bint bytevec_from_ZZ(bytevec&, const ZZ_c&)
  bint bytevec_from_PyLong(bytevec&, object)
  
  # void zz_from_bytes(ZZ_c& dest, unsigned char* src, size_t len, bint order)
  # string zz_to_string(ZZ_c& src, int base)
  # void zz_from_string(ZZ_c& dest, string src, int base)

  # # vector[unsigned char] bytes_from_GF2X(GF2X_c& src)
  # # void GF2X_from_bytes(GF2X_c& dest, vector[unsigned char] src)

  # vector[pair[ZZ_pX_c,long]] factor_pX(const ZZ_pX_c& poly)
  # ZZ_c find_smooth_power(long bound, ZZ_p_c& a)

  # void conv_zz_to_gf2x(GF2X_c& dest, const ZZ_c& src)
  # void conv_gf2x_to_zz(ZZ_c& dest, const GF2X_c& src)


cdef extern from "ccore_templ.h":
  str any_to_pythonstr[T](T& x)
  int any_from_pythonstr[T](T& x, object b) except -1

