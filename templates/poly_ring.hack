
assert CTYPE in 'ZZX ZZ_pX ZZ_pEX GF2X GF2EX'.split()

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

if HASCONTEXT:
  SELF_ARG = f'Py{CTYPE} self, Py{BASETYPE}_Context ctxt'
else:
  SELF_ARG = f'Py{CTYPE} self'


REPLACEMENTS.update(
  {x: eval(x)
   for x in 'CTYPE BASETYPE SELF_INIT SELF_ARG'.split()})



#FILE ntl_CTYPE.pxd


from .ntl_common cimport *

from .ntl_BASETYPE cimport *
#IF BASETYPE != "ZZ"
from .ntl_ZZ cimport *
from .ntl_ZZX cimport *
#ENDIF


cdef extern from "ntl_wrap.h":

  # polynomial type
  cdef cppclass CTYPE_c "CTYPE":
    CTYPE_c()
    CTYPE_c(INIT_MONO_STRUCT, long, long)
    CTYPE_c operator=(long)
    CTYPE_c operator=(const CTYPE_c&)

    BASETYPE_c& operator[](long)
    bint operator==(CTYPE_c&)
    bint operator!=(CTYPE_c&)

    void SetLength(long)
    void normalize()


  long _ntlCTYPE_IsZero "IsZero"(const CTYPE_c&)
  long _ntlCTYPE_IsOne "IsOne"(const CTYPE_c&)

  void _ntlCTYPE_negate "negate"(CTYPE_c&, const CTYPE_c&)
  void _ntlCTYPE_add "add"(CTYPE_c&, const CTYPE_c&, const CTYPE_c&)
  void _ntlCTYPE_sub "sub"(CTYPE_c&, const CTYPE_c&, const CTYPE_c&)
  void _ntlCTYPE_mul "mul"(CTYPE_c&, const CTYPE_c&, const CTYPE_c&)

  long _ntlCTYPE_divide "divide"(CTYPE_c&, const CTYPE_c&, const CTYPE_c&)
  void _ntlCTYPE_div "div"(CTYPE_c&, const CTYPE_c& a, const CTYPE_c&)

  void _ntlCTYPE_DivRem "DivRem"(CTYPE_c&, CTYPE_c&, const CTYPE_c&, const CTYPE_c&)
  void _ntlCTYPE_rem "rem"(CTYPE_c&, const CTYPE_c&, const CTYPE_c&)

  void _ntlCTYPE_LeftShift "LeftShift"(CTYPE_c&, const CTYPE_c&, long n)
  void _ntlCTYPE_RightShift "RightShift"(CTYPE_c&, const CTYPE_c&, long n)

  # ZZX power comes from ccore.h
  void _ntlCTYPE_power "power"(CTYPE_c&, const CTYPE_c&, long e)

  long _ntlCTYPE_deg "deg"(const CTYPE_c&)
  BASETYPE_c _ntlCTYPE_coeff "coeff"(const CTYPE_c&, long)
  BASETYPE_c _ntlCTYPE_LeadCoeff "LeadCoeff"(const CTYPE_c&)
  BASETYPE_c _ntlCTYPE_ConstTerm "ConstTerm"(const CTYPE_c&)
  void _ntlCTYPE_diff "diff"(CTYPE_c&, const CTYPE_c&)
  void _ntlCTYPE_reverse "reverse"(CTYPE_c&, const CTYPE_c&, long n)
  void _ntlCTYPE_trunc "trunc"(CTYPE_c&, const CTYPE_c&, long m)
  void _ntlCTYPE_GCD "GCD"(CTYPE_c&, const CTYPE_c&, const CTYPE_c&)
  #IF CTYPE == "ZZX"
  void _ntlCTYPE_XGCD "XGCD"(ZZ_c&, CTYPE_c&, CTYPE_c&, const CTYPE_c&, const CTYPE_c&)
  void _ntlCTYPE_content "content"(BASETYPE_c&, const CTYPE_c&)
  void _ntlCTYPE_PrimitivePart "PrimitivePart"(CTYPE_c&, const CTYPE_c&)
  #ELSE
  void _ntlCTYPE_XGCD "XGCD"(CTYPE_c&, CTYPE_c&, CTYPE_c&, const CTYPE_c&, const CTYPE_c&)
  void _ntlCTYPE_MakeMonic "MakeMonic"(CTYPE_c&)
  void _ntlCTYPE_random "random"(CTYPE_c&, long)
  bint _ntlCTYPE_IterIrredTest "IterIrredTest"(const CTYPE_c&)
  #ENDIF
  # GF2X and ZZX eval comes from ccore.h
  void _ntlCTYPE_eval "eval"(BASETYPE_c&, const CTYPE_c&, const BASETYPE_c&)
  #IF CTYPE == "GF2X"
  long _ntlCTYPE_weight "weight"(const CTYPE_c&)
  uint64_t ntl_hash(const GF2X_c&)
  #ENDIF

  uint64_t ntl_hash(const ZZX_c&)
  #IF CTYPE == "ZZ_pX"
  long hash_ZZ_pX(const ZZ_pX_c&, const ZZ_c&)
  #ENDIF

  #IF CTYPE != "ZZX"
  # berlekamp only for pX and GF2EX?
  # void _ntlCTYPE_berlekamp "berlekamp"(Vec[Pair[CTYPE_c,long]]&, const CTYPE_c&, long verbose)
  void _ntlCTYPE_CanZass "CanZass"(Vec[Pair[CTYPE_c,long]]&, const CTYPE_c&, long verbose)
  void _ntlCTYPE_BuildIrred "BuildIrred"(CTYPE_c&, long n)
  void _ntlCTYPE_BuildRandomIrred "BuildRandomIrred"(CTYPE_c&, const CTYPE_c&)
  #IF CTYPE == "GF2X"
  void _ntlCTYPE_BuildSparseIrred "BuildSparseIrred"(CTYPE_c&, long n)
  #ENDIF
  #ENDIF

  void _ntlCTYPE_conv "conv"(CTYPE_c&, const BASETYPE_c&)
  #IF CTYPE != "ZZX"
  void _ntlCTYPE_conv "conv"(CTYPE_c&, const ZZX_c&)
  #ENDIF
  #IF CTYPE == "GF2X" or CTYPE == "ZZ_pX"
  void _ntlCTYPE_conv "conv"(ZZX_c&, const CTYPE_c&)
  #ENDIF
  #IF CTYPE == "GF2X"
  void _ntlCTYPE_conv "GF2X_from_ZZ"(GF2X_c&, const ZZ_c&)
  #ELSE
  void _ntlCTYPE_conv "conv"(CTYPE_c&, const ZZ_c&)
  #ENDIF
  #IF CTYPE == "ZZ_pEX"
  void _ntlCTYPE_conv "conv"(ZZ_pEX_c&, const ZZ_p_c&)
  void _ntlCTYPE_conv "conv"(ZZ_pEX_c&, const ZZ_pX_c&)
  #ENDIF


cdef class PyCTYPE(object):
  cdef CTYPE_c val
  #IF HASCONTEXT
  cdef PyBASETYPE_Context ctxt
  #ENDIF

  cdef PyCTYPE _convert_arg(PyCTYPE self, object arg)
  cdef bint _init_from_seq(PyCTYPE self, arg)
  
  cpdef long deg(PyCTYPE self)
  cdef _slice(PyCTYPE self, slice idx)

  cpdef bint is_zero(PyCTYPE self)
  cpdef bint is_one(PyCTYPE self)

  #IF CTYPE in 'ZZX ZZ_pX GF2X'.split()
  cpdef object mod(PyCTYPE self, _arg)
  #ENDIF

  cdef bint _init_from_integer(PyCTYPE self, object arg)
  cdef bint _init_lift(PyCTYPE self, object arg)
  cdef bint _init_proj(PyCTYPE self, object arg)


cdef class PyCTYPE_Class(object):
  #IF HASCONTEXT
  cdef PyBASETYPE_Context ctxt
  #ENDIF
  pass



#FILE ntl_CTYPE.pyx



from .ntl_CTYPE cimport *
#IF CTYPE == 'ZZX'
from .ntl_ZZ_p cimport *
from .ntl_ZZ_pX cimport PyZZ_pX
from .ntl_ZZ_pE cimport *
#ELIF CTYPE == 'ZZ_pX'
from .ntl_ZZ_pE cimport *
#ELIF CTYPE == 'GF2X'
from .ntl_GF2E cimport *
#ENDIF

from .ccore cimport *
import weakref
from collections.abc import Sequence



cdef class PyCTYPE_Class():
  __slots__ = ()
  
  def __init__(SELF_ARG):
    #MACRO SELF_INIT
    pass

  #IF CTYPE != "ZZX"
  def random(self, long deg, monic=False):
    if monic:
      return self.random(deg-1, False) + self.monomial(deg-1)
    #MACRO CDEF_RES()
    sig_on()
    _ntlCTYPE_random(res.val, deg)
    sig_off()
    return res
  #ENDIF

  def monomial(self, long deg):
    #MACRO CDEF_RES()
    sig_on()
    res.val = CTYPE_c(INIT_MONO, deg, 1)
    sig_off()
    return res

  #IF CTYPE != "ZZX"
  
  def irreducible(self, deg, kind='default'):
    #MACRO CDEF_RES()
    cdef long n
    #IF CTYPE == "GF2X"
    if kind == 'sparse':
      n = <long>deg
      _ntlCTYPE_BuildSparseIrred(res.val, n)
      return res
    #ENDIF
    if kind == 'default':
      n = <long>deg
      _ntlCTYPE_BuildIrred(res.val, n)
      return res

    cdef PyCTYPE irr
    try:
      irr = deg
    except TypeError:
      irr = self.irreducible(deg, 'default')
    
    #IF HASCONTEXT
    if deg.ctxt is not self.ctxt:
      raise ValueError("modulus mismatch")
    #ENDIF
    _ntlCTYPE_BuildRandomIrred(res.val, irr.val)
    return res

  #ENDIF

  def __call__(self, arg=None):
    #IF HASCONTEXT
    return PyCTYPE(self.ctxt, arg)
    #ELSE
    return PyCTYPE(arg)
    #ENDIF

  #IF not BASETYPE.endswith("E")
  def __truediv__(self, other):
    return self.mod(other)

  def mod(self, other):
    #IF CTYPE == 'GF2X'
    return PyGF2E_Ring(other)
    #ELIF CTYPE == 'ZZ_pX' or CTYPE == 'ZZX'
    return PyZZ_pE_Ring(other)
    #ENDIF
  #ENDIF

  


cdef class PyCTYPE():

  #INCLUDE arith_additive.ihack
  #INCLUDE arith_infinite.ihack

  cdef bint _init_lift(PyCTYPE self, object arg):
    assert False


  cdef bint _init_from_integer(PyCTYPE self, object arg):
    cdef ZZ_c tmp
    if isinstance(arg, int):
      if not ZZ_from_PyLong(tmp, arg):
        return False
      _ntlCTYPE_conv(self.val, tmp)
      return True
    if isinstance(arg, PyZZ):
      _ntlCTYPE_conv(self.val, (<PyZZ>arg).val)
      return True
    return False
    
  # projected init: restricted <-- general
  # ZZX <-- int, ZZ
  # ZZ_pX <-- int, ZZ, ZZ_p, ZZX
  # ZZ_pEX <-- int, ZZ, ZZ_p, ZZ_pE, ZZ_pX, ZZX
  # GF2X <-- int(->GF2X), ZZ(->GF2X), ZZX
  cdef bint _init_proj(PyCTYPE self, object arg):
    if self._init_from_integer(arg):
      return True

    #IF CTYPE != "ZZX"
    if isinstance(arg, PyZZX):
      _ntlCTYPE_conv(self.val, (<PyZZX>arg).val)
      return True

    if isinstance(arg, PyBASETYPE):
      #IF HASCONTEXT
      if (<PyBASETYPE>arg).ctxt is not self.ctxt:
        raise TypeError("base ring modulus does not match")
      #ENDIF
      _ntlCTYPE_conv(self.val, (<PyBASETYPE>arg).val)
      return True

    #IF CTYPE == "ZZ_pEX"
    if isinstance(arg, PyZZ_p):
      if (<PyZZ_p>arg).ctxt is not self.ctxt._mod.ctxt:
        raise TypeError("modulus does not match")
      _ntlCTYPE_conv(self.val, (<PyZZ_p>arg).val)
      return True

    if isinstance(arg, PyZZ_pX):
      if (<PyZZ_pX>arg).ctxt is not self.ctxt._mod.ctxt:
        raise TypeError("modulus does not match")
      _ntlCTYPE_conv(self.val, (<PyZZ_pX>arg).val)
      return True
    #ENDIF

    #ENDIF

  # ZZ_pX <- ZZX, ZZ_p, ZZ, int
  # ZZX <- ZZ, int
  # ZZ_pEX <- ZZX, ZZ, int, ZZ_pE
  cdef PyCTYPE _convert_arg(PyCTYPE self, object arg):
    if isinstance(arg, PyCTYPE):
      #IF HASCONTEXT
      if (<PyCTYPE>arg).ctxt is not self.ctxt:
        raise TypeError("base ring modulus does not match")
      #ENDIF
      return arg

    #MACRO CDEF_RES()
    if res._init_proj(arg):
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
    self.val.normalize()
    return True

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

    if self._init_proj(arg):
      return
    
    if self._init_from_seq(arg):
      return
    
    raise TypeError("couldn't convert argument")
    

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


  def __len__(self):
    return _ntlCTYPE_deg(self.val) + 1

  cpdef long deg(PyCTYPE self):
    "The degree of the polynomial (-1 for the empty polynomial)."
    return _ntlCTYPE_deg(self.val)

  
  def __getitem__(PyCTYPE self, _key):
    if isinstance(_key, slice):
      return self._slice(_key)
    cdef long n = len(self)
    cdef long idx = _key
    if idx < 0:
      idx = n + idx
    if idx < 0 or idx >= n:
      raise IndexError("out of bounds")

    #MACRO CDEF_RES(BASETYPE)
    res.val = _ntlCTYPE_coeff(self.val, idx)
    return res

  cdef _slice(PyCTYPE self, slice idx):
    cdef long a, b, s
    a,b,s = idx.indices(_ntlCTYPE_deg(self.val) + 1)
    #MACRO CDEF_RES()
    cdef long j = 0
    res.val.SetLength((b-a)//s)
    for i in range(a,b,s):
      res.val[j] = self.val[i]
      j += 1
    return res

  #IF CTYPE == "ZZ_pX"
  def lift(PyCTYPE self):
    cdef PyZZX res = PyZZX.__new__(PyZZX)
    _ntlCTYPE_conv(res.val, self.val)
    return 
  #ENDIF

  #IF CTYPE == "ZZX" or CTYPE == "ZZ_pX" or CTYPE == "GF2X"
  def __hash__(PyCTYPE self):
    #IF HASCONTEXT
    return hash_ZZ_pX(self.val, self.ctxt._mod.val)
    #ELSE
    return ntl_hash(self.val)
    #ENDIF
  #ENDIF

  def constant(PyCTYPE self):
    #MACRO CDEF_RES(BASETYPE)
    res.val = _ntlCTYPE_ConstTerm(self.val)
    return res

  def lead_coeff(PyCTYPE self):
    #MACRO CDEF_RES(BASETYPE)
    res.val = _ntlCTYPE_LeadCoeff(self.val)
    return res

  def is_monic(PyCTYPE self):
    return self.lead_coeff().is_one()

  #IF CTYPE == "ZZX"
  
  def content(PyCTYPE self):
    #MACRO CDEF_RES(BASETYPE)
    _ntlCTYPE_content(res.val, self.val)
    return res

  def primitive(PyCTYPE self):
    #MACRO CDEF_RES()
    _ntlCTYPE_PrimitivePart(res.val, self.val)
    return res
  
  #ELSE

  def make_monic(PyCTYPE self):
    #MACRO CDEF_RES()
    res.val = self.val
    sig_on()
    _ntlCTYPE_MakeMonic(res.val)
    sig_off()
    return res

  def factor(PyCTYPE self, method=None, verbose=None):
    if not self.is_monic():
      return self.make_monic().factor(method=method, verbose=verbose)
    #IF HASCONTEXT
    self.ctxt.restore()
    #ENDIF
    cdef Vec[Pair[CTYPE_c,long]] facs
    # if method == "berlekamp":
    #   _ntlCTYPE_berlekamp(facs, self.val, 1 if verbose else 0)
    # else:
    _ntlCTYPE_CanZass(facs, self.val, 1 if verbose else 0)

    cdef long n = facs.length()
    cdef PyCTYPE tmp
    res = []
    for i in range(n):
      tmp = PyCTYPE.__new__(PyCTYPE)
      #IF HASCONTEXT
      tmp.ctxt = self.ctxt
      #ENDIF
      tmp.val = facs[i].a
      res.append( (tmp, facs[i].b) )
    
    return res
  #ENDIF

  def diff(PyCTYPE self):
    #MACRO CDEF_RES()
    sig_on()
    _ntlCTYPE_diff(res.val, self.val)
    sig_off()
    return res

  def reverse(PyCTYPE self, long n=0):
    #MACRO CDEF_RES()
    if n == 0:
      n = len(self)
    sig_on()
    _ntlCTYPE_reverse(res.val, self.val, n)
    sig_off()
    return res

  def truncate(PyCTYPE self, long n):
    #MACRO CDEF_RES()
    _ntlCTYPE_trunc(res.val, self.val, n)
    return res

  def __call__(PyCTYPE self, _arg):
    cdef PyBASETYPE arg
    if isinstance(_arg, PyBASETYPE):
      arg = <PyBASETYPE>_arg
    else:
    #IF HASCONTEXT
      arg = PyBASETYPE(self.ctxt, _arg)
    #ELSE
      arg = PyBASETYPE(_arg)
    #ENDIF
    #MACRO CDEF_RES(BASETYPE)
    sig_on()
    _ntlCTYPE_eval(res.val, self.val, arg.val)
    sig_off()
    return res
  
  def is_irreducible(PyCTYPE self, long method=0):
    # method ignored for now.
    #IF CTYPE == "ZZX"
    raise NotImplementedError("XXX: not implemented yet")
    #ELSE
    #IF HASCONTEXT
    self.ctxt.restore()
    #ENDIF
    return _ntlCTYPE_IterIrredTest(self.val)
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


  #IF CTYPE in 'ZZX ZZ_pX GF2X'.split()
  cpdef object mod(PyCTYPE self, _arg):
    #IF CTYPE == 'GF2X'
    if isinstance(_arg, (PyGF2X, int, PyZZ)):
      return PyGF2E(PyGF2E_Context._get(_arg), self)
    #ELSE
    
    #IF CTYPE == 'ZZX'
    if isinstance(_arg, (int, PyZZ)):
      return PyZZ_pX(PyZZ_p_Context._get(_arg), self)
    #ENDIF

    #IF CTYPE == 'ZZ_pX' or CTYPE == 'ZZX'
    cdef PyZZ_p arg
    if isinstance(_arg, PyZZ_pX):
      return PyZZ_pE(PyZZ_pE_Context._get(_arg), self)
    #ENDIF

    #ENDIF
    raise NotImplementedError("XXX: not implemented")
  #ENDIF



