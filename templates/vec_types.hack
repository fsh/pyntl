
assert CTYPE in 'vec_ZZ vec_ZZ_p vec_ZZ_pE vec_GF2 vec_GF2E'.split()


def CDEF_RES(typename='CTYPE', varname='self.ctxt', sl=False):
  txt = ''
  txt += f"cdef Py{typename} res = Py{typename}.__new__(Py{typename})\n"
  txt += f"res.ctxt = {varname}\n" if HASCONTEXT else ''
  txt += f"{varname}.restore()\n" if HASCONTEXT else ''
  if sl:
    txt += f'res.val.SetLength(self.val.length())\n'
  return txt

def CONVERT_ARG(typename='CTYPE', varname='_arg'):
  txt = ''
  txt += f"cdef Py{typename} arg = self._convert_arg({varname})\n"
  txt += f"if arg is None:\n"
  txt += f"  return NotImplemented\n"
  return txt

SELF_INIT = ''
SELF_INIT += 'self.ctxt = ctxt\n' if HASCONTEXT else ''
SELF_INIT += 'ctxt.restore()\n' if HASCONTEXT else ''

if HASCONTEXT:
  SELF_ARG = f'Py{CTYPE} self, Py{BASETYPE}_Context ctxt'
else:
  SELF_ARG = f'Py{CTYPE} self'


REPLACEMENTS.update(
  {x: eval(x)
   for x in 'CTYPE BASETYPE SELF_INIT SELF_ARG'.split()})


#FILE ntl_CTYPE.pxd

from .ntl_common cimport *
from .ntl_ZZ cimport *
from .ntl_BASETYPE cimport *
from .ntl_BASETYPEX cimport *
#IF CTYPE != 'vec_ZZ'
from .ntl_vec_ZZ cimport *
#ENDIF


cdef extern from "ntl_wrap.h":

  # base type
  cdef cppclass CTYPE_c "CTYPE":
    CTYPE_c operator=(const CTYPE_c&)
    long length()
    void SetLength(long)
    void SetLength(long, const BASETYPE_c&)
    BASETYPE_c& operator[](long)
    bint operator==(CTYPE_c&)
    bint operator!=(CTYPE_c&)

  long _ntlCTYPE_IsZero "IsZero"(const CTYPE_c&)

  void _ntlCTYPE_negate "negate"(CTYPE_c&, const CTYPE_c&)
  void _ntlCTYPE_add "add"(CTYPE_c&, const CTYPE_c&, const CTYPE_c&)
  void _ntlCTYPE_sub "sub"(CTYPE_c&, const CTYPE_c&, const CTYPE_c&)
  void _ntlCTYPE_mul "mul"(CTYPE_c&, const CTYPE_c&, const BASETYPE_c&)

  # from ccore.h
  void _ntlCTYPE_mul "mul_by_elts"(CTYPE_c&, const CTYPE_c&, const CTYPE_c&)
  # void _ntlCTYPE_mul "add"(CTYPE_c&, const CTYPE_c&, const BASETYPE_c&)
  # void _ntlCTYPE_mul "sub"(CTYPE_c&, const CTYPE_c&, const BASETYPE_c&)
  # void _ntlCTYPE_mul "sub"(CTYPE_c&, const BASETYPE_c&, const CTYPE_c&)

  void _ntlCTYPE_InnerProduct "InnerProduct"(BASETYPE_c&, const CTYPE_c&, const CTYPE_c&)
  void _ntlCTYPE_VectorCopy "VectorCopy"(CTYPE_c&, const CTYPE_c&, long)

  #IF CTYPE != "vec_ZZ"
  void _ntlCTYPE_conv "conv"(CTYPE_c&, const vec_ZZ_c&)
  #ENDIF
  #IF CTYPE == "vec_GF2" or CTYPE == "vec_ZZ_p"
  void _ntlCTYPE_conv "conv"(vec_ZZ_c&, const CTYPE_c&)
  #ENDIF
  
  void _ntlCTYPE_conv "conv"(BASETYPEX_c&, const CTYPE_c&)
  void _ntlCTYPE_conv "conv"(CTYPE_c&, const BASETYPEX_c&)
  
  # #IF CTYPE == "ZZ_pEX"
  # void _ntlCTYPE_conv "conv"(ZZ_pEX_c&, const ZZ_p_c&)
  # void _ntlCTYPE_conv "conv"(ZZ_pEX_c&, const ZZ_pX_c&)
  # #ENDIF


cdef class PyCTYPE(object):
  cdef CTYPE_c val
  #IF HASCONTEXT
  cdef PyBASETYPE_Context ctxt
  #ENDIF

  cdef PyCTYPE _convert_arg(PyCTYPE self, object arg)
  cdef bint _init_from_seq(PyCTYPE self, arg)
  # cdef bint _init_from_integer(PyCTYPE self, object arg)
  cdef bint _init_lift(PyCTYPE self, object arg)
  cdef bint _init_proj(PyCTYPE self, object arg, long n)
  
  # cpdef bint is_zero(PyCTYPE self)
  # cpdef bint is_one(PyCTYPE self)



cdef class PyCTYPE_Class(object):
  #IF HASCONTEXT
  cdef PyBASETYPE_Context ctxt
  #ENDIF
  pass



#FILE ntl_CTYPE.pyx


from .ntl_CTYPE cimport *
from .ccore cimport *

from collections.abc import Sequence



cdef class PyCTYPE_Class():
  __slots__ = ()
  
  def __init__(SELF_ARG):
    #MACRO SELF_INIT
    pass

  # #IF CTYPE != "ZZX"
  # def random(self, long deg, monic=False):
  #   if monic:
  #     return self.random(deg-1, False) + self.monomial(deg-1)
  #   #MACRO CDEF_RES()
  #   sig_on()
  #   _ntlCTYPE_random(res.val, deg)
  #   sig_off()
  #   return res
  # #ENDIF

  def __call__(self, arg=None):
    #IF HASCONTEXT
    return PyCTYPE(self.ctxt, arg)
    #ELSE
    return PyCTYPE(arg)
    #ENDIF



cdef class PyCTYPE():

  #INCLUDE arith_additive.ihack

  cdef bint _init_lift(PyCTYPE self, object arg):
    assert False

  cdef bint _init_proj(PyCTYPE self, object arg, long n):
    #IF CTYPE != "vec_ZZ"
    if isinstance(arg, Pyvec_ZZ):
      if n > 0 and (<Pyvec_ZZ>arg).val.length() != n:
        raise ValueError("vector length mismatch")
      _ntlCTYPE_conv(self.val, (<Pyvec_ZZ>arg).val)
      return True
    #ENDIF

    if n == 0:
      return False
    
    #MACRO CDEF_RES(BASETYPE)
    if res._init_proj(arg):
      self.val.SetLength(n, res.val)
      return True

    return False

  cdef PyCTYPE _convert_arg(PyCTYPE self, object arg):
    if isinstance(arg, PyCTYPE):
      if (<PyCTYPE>arg).val.length() != self.val.length():
        raise ValueError("vector length mismatch")
      #IF HASCONTEXT
      if (<PyCTYPE>arg).ctxt is not self.ctxt:
        raise TypeError("scalar modulus does not match")
      #ENDIF
      return arg

    #MACRO CDEF_RES()
    if res._init_proj(arg, self.val.length()):
      return res

    return None
  
  cdef bint _init_from_seq(PyCTYPE self, arg):
    if not isinstance(arg, Sequence):
      return False
    cdef long maxl = len(arg)
    self.val.SetLength(maxl)
    #IF HASCONTEXT
    cdef PyBASETYPE base = PyBASETYPE(self.ctxt)
    #ELSE
    cdef PyBASETYPE base = PyBASETYPE()
    #ENDIF
    for i in range(maxl):
      self.val[i] = base._convert_arg(arg[i]).val
    return True

  def __init__(SELF_ARG, arg=None, long length=0):
    #MACRO SELF_INIT
    if arg is None:
      self.val.SetLength(length)
      return

    if isinstance(arg, PyBASETYPEX):
      _ntlCTYPE_conv(self.val, (<PyBASETYPEX>arg).val)
      return
    
    if isinstance(arg, PyCTYPE):
      #IF HASCONTEXT
      if (<PyCTYPE>arg).ctxt is not self.ctxt:
        raise TypeError("modulus does not match")
      #ENDIF
      self.val = (<PyCTYPE>arg).val
      return

    if self._init_proj(arg, length):
      return
    
    if self._init_from_seq(arg):
      return
    
    raise TypeError("couldn't convert argument")
    

  def __str__(self):
    return any_to_pythonstr(self.val)

  def __repr__(self):
    return any_to_pythonstr(self.val)
  

  # cpdef bint is_zero(PyCTYPE self):
  #   "Tests if `self` is the additive unit."
  #   return _ntlCTYPE_IsZero(self.val)

  # cpdef bint is_one(PyCTYPE self):
  #   "Tests if `self` is the multiplicative unit."
  #   return _ntlCTYPE_IsOne(self.val)


  def __len__(self):
    return self.val.length()
  
  def __getitem__(self, _key):
    if isinstance(_key, slice):
      raise NotImplementedError("XXX")
    cdef long n = self.val.length()
    cdef long idx = _key
    if idx < 0:
      idx = n + idx
    if idx < 0 or idx >= n:
      raise IndexError("out of bounds")

    #MACRO CDEF_RES(BASETYPE)
    res.val = self.val[idx]
    return res

  # #IF CTYPE == "ZZX" or CTYPE == "ZZ_pX"
  # def __hash__(PyCTYPE self):
  #   #IF HASCONTEXT
  #   return hash_ZZ_pX(self.val, self.ctxt._mod.val)
  #   #ELSE
  #   return hash_ZZX(self.val)
  #   #ENDIF
  # #ENDIF
  
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

  def __matmul__(PyCTYPE self, _arg):
    #MACRO CONVERT_ARG()
    #MACRO CDEF_RES(BASETYPE)
    sig_on()
    _ntlCTYPE_InnerProduct(res.val, self.val, arg.val)
    sig_off()
    return res

  #IF CTYPE == "vec_GF2" or CTYPE == "vec_ZZ_p"
  def lift(PyCTYPE self):
    cdef Pyvec_ZZ res = Pyvec_ZZ.__new__(Pyvec_ZZ)
    _ntlCTYPE_conv(res.val, self.val)
    return res
  #ENDIF
