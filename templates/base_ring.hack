
assert CTYPE in 'ZZ ZZ_p ZZ_pE GF2 GF2E'.split()


def CDEF_RES(typename='CTYPE', varname='self.ctxt', target='res'):
  txt = ''
  txt += f"cdef Py{typename} {target} = Py{typename}.__new__(Py{typename})\n"
  txt += f"{target}.ctxt = {varname}\n" if HASCONTEXT else ''
  txt += f"{varname}.restore()\n" if HASCONTEXT else ''
  return txt

def CONVERT_ARG(typename='CTYPE', varname='_arg', target='arg'):
  txt = ''
  txt += f"cdef Py{typename} {target} = self._convert_arg({varname})\n"
  txt += f"if {target} is None:\n"
  txt += f"  return NotImplemented\n"
  return txt

SELF_INIT = 'self.ctxt = ctxt\n' if HASCONTEXT else ''
SELF_INIT += 'ctxt.restore()\n' if HASCONTEXT else ''

if BASETYPE:
  SELF_ARG = f'Py{CTYPE} self, Py{CTYPE}_Context ctxt'
else:
  SELF_ARG = f'Py{CTYPE} self'


REPLACEMENTS.update(
  {x: eval(x)
   for x in 'CTYPE BASETYPE SELF_INIT SELF_ARG'.split()})


#FILE ntl_CTYPE.pxd

from .ntl_common cimport *

#IF CTYPE != "ZZ"
from .ntl_ZZ cimport *
#ELSE
from .ntl_GF2 cimport *
#ENDIF
#IF CTYPE == "GF2E"
from .ntl_GF2 cimport *
#ENDIF
#IF CTYPE == "ZZ_pE"
from .ntl_ZZ_p cimport *
#ENDIF

#IF BASETYPE
from .ntl_BASETYPE cimport *
#ENDIF


cdef extern from "ntl_wrap.h":

  # base type
  cdef cppclass CTYPE_c "CTYPE":
    CTYPE_c operator=(long)
    CTYPE_c operator=(const CTYPE_c&)
    bint operator==(CTYPE_c&)
    bint operator!=(CTYPE_c&)
    #IF INFINITE
    bint operator<(CTYPE_c&)
    bint operator<=(CTYPE_c&)
    bint operator>(CTYPE_c&)
    bint operator>=(CTYPE_c&)
    #ENDIF
    #IF EXTENSION
    @staticmethod
    long degree()
    #ENDIF

  long _ntlCTYPE_IsZero "IsZero"(const CTYPE_c&)
  long _ntlCTYPE_IsOne "IsOne"(const CTYPE_c&)

  void _ntlCTYPE_negate "negate"(CTYPE_c&, const CTYPE_c&)
  void _ntlCTYPE_negate "negate"(CTYPE_c, CTYPE_c)
  void add(CTYPE_c&, const CTYPE_c&, const CTYPE_c&)
  void add(CTYPE_c&, const CTYPE_c&, long)
  void _ntlCTYPE_add "add"(CTYPE_c&, const CTYPE_c&, const CTYPE_c&)
  void _ntlCTYPE_sub "sub"(CTYPE_c&, const CTYPE_c&, const CTYPE_c&)
  void _ntlCTYPE_mul "mul"(CTYPE_c&, const CTYPE_c&, const CTYPE_c&)

  long _ntlCTYPE_divide "divide"(CTYPE_c&, const CTYPE_c&, const CTYPE_c&)
  void _ntlCTYPE_div "div"(CTYPE_c&, const CTYPE_c& a, const CTYPE_c&)

  #IF INFINITE
  void _ntlCTYPE_DivRem "DivRem"(CTYPE_c&, CTYPE_c&, const CTYPE_c&, const CTYPE_c&)
  void _ntlCTYPE_rem "rem"(CTYPE_c&, const CTYPE_c&, const CTYPE_c&)
  long _ntlCTYPE_rem "rem"(const CTYPE_c&, long)

  void LeftShift(CTYPE_c&, const CTYPE_c&, long n)
  void _ntlCTYPE_LeftShift "LeftShift"(CTYPE_c&, const CTYPE_c&, long n)
  void _ntlCTYPE_RightShift "RightShift"(CTYPE_c&, const CTYPE_c&, long n)

  void _ntlCTYPE_abs "abs"(CTYPE_c&, const CTYPE_c&)
  void _ntlCTYPE_power "power"(CTYPE_c&, const CTYPE_c&, long e)

  void _ntlCTYPE_GCD "GCD"(CTYPE_c&, const CTYPE_c&, const CTYPE_c&)
  void _ntlCTYPE_XGCD "XGCD"(CTYPE_c&, CTYPE_c&, CTYPE_c&, const CTYPE_c&, const CTYPE_c&)
  
  long ProbPrime(const ZZ_c&, long)
  void RandomPrime(ZZ_c&, long)
  void GenPrime(ZZ_c&, long) # long err = 80
  void GenGermainPrime(ZZ_c&, long) # long err = 80
  void CRT(ZZ_c&, ZZ_c&, const ZZ_c&, const ZZ_c&)
  
  long NumBits(const ZZ_c&)
  long bit(const ZZ_c&, long)
  long SetBit(ZZ_c&, long)
  void bit_and(ZZ_c&, const ZZ_c&, const ZZ_c&)
  void bit_or(ZZ_c&, const ZZ_c&, const ZZ_c&)
  void bit_xor(ZZ_c&, const ZZ_c&, const ZZ_c&)
  long weight(const ZZ_c&)
  void ZZFromBytes(ZZ_c&, const unsigned char*, long)
  long NumBytes(const ZZ_c&)
  #IF CTYPE == "ZZ"
  long rep(const GF2_c&)
  #ENDIF

  #ELSE
  void _ntlCTYPE_inv "inv"(CTYPE_c&, const CTYPE_c&)
  void _ntlCTYPE_power "power"(CTYPE_c&, const CTYPE_c&, const ZZ_c&)

  void _ntlCTYPE_random "random"(CTYPE_c&)
  #ENDIF

  #IF BASETYPE
  BASETYPE_c _ntlCTYPE_rep "rep"(const CTYPE_c&)

  cdef cppclass CTYPE_Context_c "CTYPEContext":
    CTYPE_Context_c()
    CTYPE_Context_c(const BASETYPE_c&)
    void restore()
  #ENDIF


  void _ntlCTYPE_conv "conv"(CTYPE_c&, const ZZ_c&)
  #IF BASETYPE
  void _ntlCTYPE_conv "conv"(CTYPE_c&, const BASETYPE_c&)
  #ENDIF
  #IF CTYPE == "ZZ_pE"
  void _ntlCTYPE_conv "conv"(ZZ_pE_c&, const ZZ_p_c&)
  #ENDIF

#IF HASCONTEXT

cdef class PyCTYPE_Context(object):
  cdef CTYPE_Context_c ctxt
  cdef PyBASETYPE _mod
  cdef object __weakref__

  cdef void restore(self)
  
  @staticmethod
  cdef PyCTYPE_Context _get(PyBASETYPE m)
  cpdef PyBASETYPE modulus(self)

cpdef PyCTYPE_Ring(arg)

#ELSE

cdef class PyCTYPE_Class():
  pass

#ENDIF


cdef class PyCTYPE(object):
  cdef CTYPE_c val
  #IF BASETYPE
  cdef PyCTYPE_Context ctxt
  #ENDIF
  
  cdef PyCTYPE _convert_arg(PyCTYPE self, object arg)
  #IF CTYPE == "ZZ"
  @staticmethod
  cdef PyZZ _convert_arg_zz(object arg)
  cdef bint _init_bytes(PyCTYPE self, bytes data, str endian)
  #ENDIF
  
  cpdef bint is_zero(self)
  cpdef bint is_one(self)

  #IF BASETYPE
  cpdef PyBASETYPE lift(PyCTYPE self)
  cpdef PyCTYPE_Context ring(PyCTYPE self)
  cpdef PyBASETYPE modulus(PyCTYPE self)
  #ENDIF

  #IF CTYPE == "ZZ"
  cpdef bytes bytes(PyCTYPE self, str endian=*)
  #ENDIF

  #IF CTYPE == 'ZZ'
  cpdef object mod(PyCTYPE self, _arg)
  #ENDIF

  #IF CTYPE == "ZZ" or EXTENSION
  cdef PyCTYPE _slice(PyCTYPE self, slice idx)
  #ENDIF

  cdef bint _init_lift(PyCTYPE self, object arg)
  cdef bint _init_proj(PyCTYPE self, object arg)
  cdef bint _init_from_seq(PyCTYPE self, arg)


#FILE ntl_CTYPE.pyx


from .ntl_CTYPE cimport *
from .ccore cimport *
import weakref
from collections.abc import Sequence


#IF CTYPE == "ZZ"
from .ntl_ZZ_p cimport *
from .ntl_ZZ_pE cimport *
#ENDIF
#IF CTYPE == "ZZ_p"
from .ntl_ZZ_pE cimport *
#ENDIF
#IF CTYPE == "GF2"
from .ntl_GF2E cimport *
#ENDIF
#IF EXTENSION
from .ntl_BASETYPE cimport *
#ENDIF
from .ntl_CTYPEX cimport PyCTYPEX, PyCTYPEX_Class


#IF HASCONTEXT
from .ntl_mat_CTYPE cimport Pymat_CTYPE_Class
from .ntl_vec_CTYPE cimport Pyvec_CTYPE_Class

cdef class PyCTYPE_Context():

  cdef void restore(self):
    #IF SUBDOUBLE
    self._mod.ctxt.restore()
    #ENDIF
    self.ctxt.restore()

  _moduli = dict()
  
  @staticmethod
  cdef PyCTYPE_Context _get(PyBASETYPE m):
    #IF BASETYPE == "ZZ"
    if m < 2:
    #ELSE
    if m.deg() < 1:
    #ENDIF
      raise ValueError("invalid modulus")
    if m in PyCTYPE_Context._moduli:
      ctxt = <PyCTYPE_Context>PyCTYPE_Context._moduli[m]()
      if ctxt is not None:
        return ctxt
    ctxt = PyCTYPE_Context(m)
    PyCTYPE_Context._moduli[m] = weakref.ref(ctxt)
    return ctxt

  def __init__(self, PyBASETYPE mod):
    self.ctxt = CTYPE_Context_c(mod.val)
    self._mod = mod

  cpdef PyBASETYPE modulus(self):
    return self._mod

  def __call__(PyCTYPE_Context self, *args):
    return PyCTYPE(self, *args)

  def __eq__(PyCTYPE_Context self, PyCTYPE_Context other):
    return other._mod == self._mod

  def random(PyCTYPE_Context self):
    #MACRO CDEF_RES(varname='self')
    _ntlCTYPE_random(res.val)
    return res
  
  @property
  def P(PyCTYPE_Context self):
    return PyCTYPEX_Class(self)

  @property
  def M(PyCTYPE_Context self):
    return Pymat_CTYPE_Class(self)

  @property
  def V(PyCTYPE_Context self):
    return Pyvec_CTYPE_Class(self)

  #IF EXTENSION
  @property
  def X(PyCTYPE_Context self):
    return PyCTYPE(self, [0,1])
  #ENDIF

cpdef PyCTYPE_Ring(arg):
  cdef PyBASETYPE m = <PyBASETYPE>arg if isinstance(arg, PyBASETYPE) else PyBASETYPE(arg)
  return PyCTYPE_Context._get(m)

#ELIF CTYPE == "ZZ"

cdef class PyZZ_Class():
  def __init__(PyZZ_Class self):
    pass

  def gen_prime(PyZZ_Class self, long bits):
    #MACRO CDEF_RES()
    sig_on()
    GenPrime(res.val, bits)
    sig_off()
    return res

  def gen_germain_prime(PyZZ_Class self, long bits):
    #MACRO CDEF_RES()
    sig_on()
    GenGermainPrime(res.val, bits)
    sig_off()
    return res

#ELIF CTYPE == "GF2"

cdef class PyGF2_Class():
  def __init__(PyZZ_Class self):
    pass

#ENDIF




cdef class PyCTYPE(object):

  __slots__ = ()

  @staticmethod
  def _require_context():
    #IF HASCONTEXT
    return True
    #ELSE
    return False
    #ENDIF

  #INCLUDE arith_additive.ihack

  #IF INFINITE
  #INCLUDE arith_infinite.ihack
  #ENDIF

  def __str__(self):
    return any_to_pythonstr(self.val)

  def __repr__(self):
    return any_to_pythonstr(self.val)


  cpdef bint is_zero(PyCTYPE self):
    "Tests if `self` is the additive unit."
    return _ntlCTYPE_IsZero(self.val)

  cpdef bint is_one(PyCTYPE self):
    "Tests if `self` is the multiplicative unit."
    return _ntlCTYPE_IsOne(self.val)

  


  
  def __index__(self):
    return self.__int__()

  def __int__(self):
    return int.from_bytes(self.bytes('little'), 'little')




  
  #IF BASETYPE
  
  cpdef PyBASETYPE lift(PyCTYPE self):
    #IF SUBDOUBLE
    #MACRO CDEF_RES(BASETYPE, 'self.ctxt._mod.ctxt')
    #ELSE
    cdef PyBASETYPE res = PyBASETYPE.__new__(PyBASETYPE)
    #ENDIF
    res.val = _ntlCTYPE_rep(self.val)
    return res

  cpdef PyCTYPE_Context ring(PyCTYPE self):
    return self.ctxt

  cpdef PyBASETYPE modulus(PyCTYPE self):
    return self.ctxt._mod

  #ENDIF
  

  
  def __mul__(PyCTYPE self, _arg):
    #MACRO CONVERT_ARG()
    #MACRO CDEF_RES()
    sig_on()
    _ntlCTYPE_mul(res.val, self.val, arg.val)
    sig_off()
    return res

  def __rmul__(PyCTYPE self, _arg):
    # Commutative.
    return self.__mul__(_arg)


  
  #IF CTYPE != "ZZ"

  def __invert__(PyCTYPE self):
    #MACRO CDEF_RES()
    _ntlCTYPE_inv(res.val, self.val)
    return res

  def __truediv__(PyCTYPE self, _arg):
    #MACRO CONVERT_ARG()
    #MACRO CDEF_RES()
    sig_on()
    _ntlCTYPE_div(res.val, self.val, arg.val)
    sig_off()
    return res

  def __rtruediv__(PyCTYPE self, _arg):
    return (~self) * _arg

  #IF CTYPE != "GF2"
  def __pow__(PyCTYPE self, _exp, _mod):
    if _mod is not None:
      return NotImplemented
    cdef PyZZ exp = PyZZ._convert_arg_zz(_exp)
    #MACRO CDEF_RES()
    sig_on()
    _ntlCTYPE_power(res.val, self.val, exp.val)
    sig_off()
    return res
  #ENDIF

  #ENDIF




  #IF CTYPE == "ZZ_p"
  def crt(PyZZ_p self, PyZZ_p arg):
    cdef PyZZ zz_m = PyZZ.__new__(PyZZ)
    zz_m.val = arg.ctxt._mod.val
    
    cdef ZZ_c zz_a = _ntlCTYPE_rep(arg.val)

    sig_on()
    CRT(zz_a, zz_m.val, _ntlCTYPE_rep(self.val), self.ctxt._mod.val)
    sig_off()
    
    cdef PyZZ_p res = PyZZ_p.__new__(PyZZ_p)
    res.ctxt = PyZZ_p_Context._get(zz_m)
    res.ctxt.restore()
    _ntlCTYPE_conv(res.val, zz_a)

    return res
  #ENDIF

  #IF INFINITE

  def __abs__(PyCTYPE self):
    #MACRO CDEF_RES()
    _ntlCTYPE_abs(res.val, self.val)
    return res
  
  def __lt__(PyCTYPE self, _arg):
    #MACRO CONVERT_ARG()
    return self.val < arg.val

  def __le__(PyCTYPE self, _arg):
    #MACRO CONVERT_ARG()
    return self.val <= arg.val
  
  def __ge__(PyCTYPE self, _arg):
    #MACRO CONVERT_ARG()
    return self.val >= arg.val
  
  def __gt__(PyCTYPE self, _arg):
    #MACRO CONVERT_ARG()
    return self.val > arg.val

  #ELIF CTYPE == "ZZ_p"

  def __lt__(PyCTYPE self, _arg):
    return self.lift() < _arg
  def __gt__(PyCTYPE self, _arg):
    return self.lift() > _arg
  def __le__(PyCTYPE self, _arg):
    return self.lift() <= _arg
  def __ge__(PyCTYPE self, _arg):
    return self.lift() >= _arg
  
  #ENDIF
  
  #IF CTYPE == "ZZ"

  @staticmethod
  def from_bytes(data, endian='big'):
    #MACRO CDEF_RES()
    if res._init_bytes(data, endian):
      return res
    return None

  @staticmethod
  def from_bits(data, order='lsb'):
    cdef long i
    #MACRO CDEF_RES()
    if order == 'lsb' or order == 'little':
      for bit in data:
        if bit:
          SetBit(res.val, i)
        i += 1
    elif order == 'msb' or order == 'big':
      for bit in data:
        LeftShift(res.val, res.val, 1)
        if bit:
          add(res.val, res.val, 1)
    else:
      raise ValueError("order must be one of 'lsb', 'msb', 'big', or 'little'")
    return res
  
  cdef bint _init_bytes(PyZZ self, bytes data, str endian):
    cdef unsigned char *p
    cdef bytes tmp
    if not endian or endian == 'big':
      tmp = data[::-1]
      p = tmp
    elif endian == 'little':
      p = data
    else:
      raise ValueError("endian must be 'big' or 'little'")
    ZZFromBytes(self.val, data, len(data))
    return True

  cpdef bytes bytes(PyCTYPE self, str endian='big'):
    cdef bytevec data
    bytevec_from_ZZ(data, self.val)
    cdef char* c_ptr
    if endian != 'little':
      reverse(data.begin(), data.end())
    c_ptr = <char*>&data[0]
    return c_ptr[:data.size()]

  def is_prime(PyZZ self, long trials=10):
    return <bint>ProbPrime(self.val, trials)

  def bit_length(PyZZ self):
    "Alias for `self.nbits()`"
    return NumBits(self.val)

  def nbits(PyZZ self):
    """The number of digits needed in binary notation.

    Invariant: 2**(n.nbits()-1) <= n < 2**n.nbits()
    """
    return NumBits(self.val)

  def bits(self, order='lsb', width=None):
    cdef long n = self.nbits()
    cdef long high = n if width is None else width
    cdef long take = min(high, n)
    cdef long i
    if order == 'lsb' or order == 'little':
      i = 0
      while i < take:
        yield bit(self.val, i)
        i += 1
      while i < high:
        yield 0
        i += 1
    elif order == 'msb' or order == 'big':
      i = high - 1
      while i >= take:
        yield 0
        i -= 1
      while i >= 0:
        yield bit(self.val, i)
        i -= 1
    else:
      raise ValueError("order must be one of 'lsb', 'msb', 'big', or 'little'")

  def __or__(PyZZ self, _arg):
    #MACRO CONVERT_ARG()
    #MACRO CDEF_RES()
    sig_on()
    bit_or(res.val, self.val, arg.val)
    sig_off()
    return res

  def __and__(PyZZ self, _arg):
    #MACRO CONVERT_ARG()
    #MACRO CDEF_RES()
    sig_on()
    bit_and(res.val, self.val, arg.val)
    sig_off()
    return res

  def __xor__(PyZZ self, _arg):
    #MACRO CONVERT_ARG()
    #MACRO CDEF_RES()
    sig_on()
    bit_xor(res.val, self.val, arg.val)
    sig_off()
    return res

  def __ror__(PyZZ self, _arg):
    return self.__or__(_arg)
  def __rand__(PyZZ self, _arg):
    return self.__and__(_arg)
  def __rxor__(PyZZ self, _arg):
    return self.__xor__(_arg)

  def weight(PyZZ self):
    return weight(self.val)

  def pow_div(PyZZ self, _arg):
    """The number of times `d` divides `self` together with the quotient.

    "s,q = n.pow_div(d)" means that n == d**s * q and d does not divide q.
    """
    #MACRO CONVERT_ARG()
    #MACRO CDEF_RES(target='res_q')
    #MACRO CDEF_RES(target='tmp')
    res_q.val = self.val
    cdef long s = 0
    while True:
      if not _ntlCTYPE_divide(tmp.val, res_q.val, arg.val):
        break
      res_q.val = tmp.val
      s += 1
    return (s, res_q)

  #ENDIF
  
  #IF CTYPE == "ZZ"
  def __hash__(self):
    cdef long pym =  2305843009213693951
    return _ntlCTYPE_rem(self.val, pym)
  #ELIF BASETYPE
  def __hash__(self):
    return hash(self.lift())
  #ENDIF
  

  #IF CTYPE == "ZZ"
  cpdef object mod(PyZZ self, _arg):
    pass
  #ENDIF


  #IF CTYPE == "ZZ"
  @staticmethod
  cdef PyZZ _convert_arg_zz(object arg):
    if isinstance(arg, PyZZ):
      return arg
    cdef PyZZ res = PyZZ.__new__(PyZZ)
    if not ZZ_from_PyLong(res.val, arg):
      return None
    return res
  #ENDIF

  cdef bint _init_from_seq(PyCTYPE self, arg):
    #IF not EXTENSION
    return False # XXX
    #ELSE
    if not isinstance(arg, Sequence):
      return False

    #IF SUBDOUBLE
    cdef PyBASETYPE base = PyBASETYPE(self.ctxt._mod.ctxt, arg)
    #ELSE
    cdef PyBASETYPE base = PyBASETYPE(arg)
    #ENDIF
    _ntlCTYPE_conv(self.val, base.val)
    return True
    #ENDIF

  cdef bint _init_lift(PyCTYPE self, object arg):
    assert False

  # projected init: restricted <-- general
  #
  # The only exception is that ZZ can swallow GF2.
  # ZZ <-- int, GF2
  # ZZ_p <-- int, ZZ
  # ZZ_pE <-- int, ZZ, ZZ_p, ZZ_pX
  # GF2 <-- int, ZZ
  # GF2E <-- int(->GF2X), ZZ(->GF2X), GF2X
  cdef bint _init_proj(PyCTYPE self, object arg):
    #IF CTYPE == "ZZ"
    if isinstance(arg, int):
      return ZZ_from_PyLong(self.val, arg)
    if isinstance(arg, PyGF2):
      self.val = rep((<PyGF2>arg).val)
      return True
    #ELSE

    cdef ZZ_c tmp
    #IF CTYPE != "GF2E"
    if isinstance(arg, int):
      if not ZZ_from_PyLong(tmp, arg):
        return False
      _ntlCTYPE_conv(self.val, tmp)
      return True
    if isinstance(arg, PyZZ):
      _ntlCTYPE_conv(self.val, (<PyZZ>arg).val)
      return True
    #ELSE
    cdef GF2X_c tmp2
    if isinstance(arg, int):
      if not ZZ_from_PyLong(tmp, arg):
        return False
      _ntlGF2X_conv(tmp2, tmp)
      _ntlCTYPE_conv(self.val, tmp2)
      return True
    if isinstance(arg, PyZZ):
      _ntlGF2X_conv(tmp2, (<PyZZ>arg).val)
      _ntlCTYPE_conv(self.val, tmp2)
      return True
    #ENDIF

    #IF CTYPE == "GF2E"
    if isinstance(arg, PyGF2X):
      _ntlCTYPE_conv(self.val, (<PyGF2X>arg).val)
      return True
    #ELIF CTYPE == "ZZ_pE"
    if isinstance(arg, PyZZ_p):
      if (<PyZZ_p>arg).ctxt is not self.ctxt._mod.ctxt:
        raise TypeError("ring modulus does not match")
      _ntlCTYPE_conv(self.val, (<PyZZ_p>arg).val)
      return True
    if isinstance(arg, PyZZ_pX):
      if (<PyZZ_pX>arg).ctxt is not self.ctxt._mod.ctxt:
        raise TypeError("ring modulus does not match")
      _ntlCTYPE_conv(self.val, (<PyZZ_pX>arg).val)
      return True
    #ENDIF
    #ENDIF
    return False

  cdef PyCTYPE _convert_arg(PyCTYPE self, object arg):
    if isinstance(arg, PyCTYPE):
      #IF HASCONTEXT
      if (<PyCTYPE>arg).ctxt is not self.ctxt:
        raise TypeError("modulus does not match")
      #ENDIF
      return arg
    #MACRO CDEF_RES()
    if res._init_proj(arg):
      return res
    return None

  
  def __init__(SELF_ARG, arg=None):
    #MACRO SELF_INIT
    if arg is None:
      return
    if isinstance(arg, PyCTYPE):
      #IF HASCONTEXT
      if (<PyCTYPE>arg).ctxt is not self.ctxt:
        raise TypeError("modulus does not match")
      #ENDIF
      self.val = (<PyCTYPE>arg).val
      return
    #IF CTYPE == "ZZ"
    if isinstance(arg, bytes):
      self._init_bytes(arg, 'big')
      return
    #ENDIF
    if self._init_proj(arg):
      return
    if self._init_from_seq(arg):
      return
    raise TypeError("conversion failed")


  #IF CTYPE == "ZZ" or EXTENSION
  def __iter__(self):
    for i in range(len(self)):
      yield self[i]
  
  def __len__(PyCTYPE self):
    #IF CTYPE == "ZZ"
    return NumBits(self.val)
    #ELSE
    self.ctxt.restore()
    return CTYPE_c.degree()
    #ENDIF
    
  def __getitem__(PyCTYPE self, _arg):
    if isinstance(_arg, slice):
      return self._slice(_arg)
    cdef long n = len(self)
    cdef long idx = _arg
    if idx < 0:
      idx = n + idx
    if idx < 0:
      raise IndexError("out of bounds")
    #IF CTYPE == "ZZ"
    return <bint>bit(self.val, idx)
    #ELSE
    if idx >= n:
      raise IndexError("out of bounds")
    #IF CTYPE == "GF2E"
    cdef PyGF2 res = PyGF2.__new__(PyGF2)
    #ELSE
    cdef PyZZ_p res = PyZZ_p.__new__(PyZZ_p)
    res.ctxt = self.ctxt._mod.ctxt
    res.ctxt.restore()
    #ENDIF
    res.val = coeff(_ntlCTYPE_rep(self.val), idx)
    return res
    #ENDIF

  cdef PyCTYPE _slice(PyCTYPE self, slice idx):
    #MACRO CDEF_RES()
    cdef long a, b, s
    a,b,s = idx.indices(len(self))
    #IF CTYPE == "ZZ"
    for i in range(a,b,s):
      if bit(self.val, i):
        SetBit(res.val, i)
    #ELSE
    cdef BASETYPE_c tmp
    tmp.SetLength((b-a)//s)
    cdef long j = 0
    for i in range(a,b,s):
      tmp[j] = _ntlCTYPE_rep(self.val)[i]
      j += 1
    _ntlCTYPE_conv(res.val, tmp)
    #ENDIF
    return res
  #ENDIF

  #IF EXTENSION
  def __lshift__(PyCTYPE self, _arg):
    cdef PyZZ arg = PyZZ._convert_arg_zz(_arg)
    return self * self.ctxt.X**arg

  def __rshift__(PyCTYPE self, _arg):
    cdef PyZZ arg = PyZZ._convert_arg_zz(_arg)
    return self * self.ctxt.X**-arg
  #ENDIF
