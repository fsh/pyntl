
assert CTYPE in 'ZZ ZZ_p ZZ_pE GF2 GF2E'.split()



def CDEF_RES(typename='CTYPE', varname='self.ctxt'):
  txt = ''
  txt += f"cdef Py{typename} res = Py{typename}.__new__(Py{typename})\n"
  txt += f"res.ctxt = {varname}\n" if HASCONTEXT else ''
  txt += f"{varname}.restore()\n" if HASCONTEXT else ''
  return txt

def CONVERT_ARG(typename='CTYPE', varname='_arg'):
  txt = ''
  txt += f"cdef Py{typename} arg = self._convert_arg({varname})\n"
  txt += f"if arg is None:\n"
  txt += f"  return NotImplemented\n"
  # _convert_arg() takes care of this?
  # txt += f"if arg.ctxt is not self.ctxt:\n" if BASETYPE else ''
  # txt += f"  raise TypeError('modulus must match')\n" if BASETYPE else ''
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

  long _ntlCTYPE_IsZero "IsZero"(const CTYPE_c&)
  long _ntlCTYPE_IsOne "IsOne"(const CTYPE_c&)

  void _ntlCTYPE_negate "negate"(CTYPE_c&, const CTYPE_c&)
  void _ntlCTYPE_negate "negate"(CTYPE_c, CTYPE_c)
  void _ntlCTYPE_add "add"(CTYPE_c&, const CTYPE_c&, const CTYPE_c&)
  void _ntlCTYPE_sub "sub"(CTYPE_c&, const CTYPE_c&, const CTYPE_c&)
  void _ntlCTYPE_mul "mul"(CTYPE_c&, const CTYPE_c&, const CTYPE_c&)

  long _ntlCTYPE_divide "divide"(CTYPE_c&, const CTYPE_c&, const CTYPE_c&)
  void _ntlCTYPE_div "div"(CTYPE_c&, const CTYPE_c& a, const CTYPE_c&)

  #IF INFINITE
  void _ntlCTYPE_DivRem "DivRem"(CTYPE_c&, CTYPE_c&, const CTYPE_c&, const CTYPE_c&)
  void _ntlCTYPE_rem "rem"(CTYPE_c&, const CTYPE_c&, const CTYPE_c&)
  long _ntlCTYPE_rem "rem"(const CTYPE_c&, long)

  void _ntlCTYPE_LeftShift "LeftShift"(CTYPE_c&, const CTYPE_c&, long n)
  void _ntlCTYPE_RightShift "RightShift"(CTYPE_c&, const CTYPE_c&, long n)

  void _ntlCTYPE_abs "abs"(CTYPE_c&, const CTYPE_c&)
  void _ntlCTYPE_power "power"(CTYPE_c&, const CTYPE_c&, long e)
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

#IF BASETYPE

cdef class PyCTYPE_Context(object):
  cdef CTYPE_Context_c ctxt
  cdef PyBASETYPE _mod
  cdef object __weakref__

  cdef void restore(self)
  
  @staticmethod
  cdef PyCTYPE_Context _get(PyBASETYPE m)
  cpdef PyBASETYPE modulus(self)

cpdef PyCTYPE_Ring(arg)

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
  #ENDIF

  cpdef bint is_zero(self)
  cpdef bint is_one(self)

  #IF BASETYPE
  cpdef PyBASETYPE lift(PyCTYPE self)
  cpdef PyCTYPE_Context parent(self)
  #ENDIF

  #IF CTYPE == "ZZ"
  cpdef bytes bytes(PyCTYPE self, str endian=*)
  #ENDIF

  #IF CTYPE == 'ZZ'
  cpdef object mod(PyCTYPE self, _arg)
  #ENDIF

  cdef bint _init_lift(PyCTYPE self, object arg)
  cdef bint _init_proj(PyCTYPE self, object arg)



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
from .ntl_CTYPEX cimport PyCTYPEX, PyCTYPEX_Class




#IF BASETYPE

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


cpdef PyCTYPE_Ring(arg):
  cdef PyBASETYPE m = <PyBASETYPE>arg if isinstance(arg, PyBASETYPE) else PyBASETYPE(arg)
  return PyCTYPE_Context._get(m)

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
    #ELIF BASETYPE
    #MACRO CDEF_RES(BASETYPE)
    #ENDIF
    res.val = _ntlCTYPE_rep(self.val)
    return res

  cpdef PyCTYPE_Context parent(self):
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

  #ENDIF



  
  #IF CTYPE == "ZZ"
  cpdef bytes bytes(PyCTYPE self, str endian='big'):
    cdef bytevec data
    bytevec_from_ZZ(data, self.val)
    cdef char* c_ptr
    if endian != 'little':
      reverse(data.begin(), data.end())
    c_ptr = <char*>&data[0]
    return c_ptr[:data.size()]
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

  cdef bint _init_lift(PyCTYPE self, object arg):
    assert False

  # projected init: restricted <-- general
  # ZZ <-- int
  # ZZ_p <-- int, ZZ
  # ZZ_pE <-- int, ZZ, ZZ_p, ZZ_pX
  # GF2 <-- int, ZZ
  # GF2E <-- int(->GF2X), ZZ(->GF2X), GF2X
  cdef bint _init_proj(PyCTYPE self, object arg):
    #IF CTYPE == "ZZ"
    if isinstance(arg, int):
      return ZZ_from_PyLong(self.val, arg)
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
      return
    cdef PyCTYPE tmp = self._convert_arg(arg)
    if tmp is None:
      raise TypeError("conversion failed")
    self.val = tmp.val

