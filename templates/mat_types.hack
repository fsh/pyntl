
assert CTYPE in 'mat_ZZ mat_ZZ_p mat_ZZ_pE mat_GF2 mat_GF2E'.split()


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
from .ntl_vec_BASETYPE cimport *
#IF CTYPE != 'mat_ZZ'
from .ntl_mat_ZZ cimport *
#ENDIF


cdef extern from "ntl_wrap.h":

  # base type
  cdef cppclass CTYPE_c "CTYPE":
    CTYPE_c operator=(const CTYPE_c&)
    void SetDims(long, long)
    long NumRows()
    long NumCols()
    vec_BASETYPE_c operator[](long)
    BASETYPE_c get(long, long)
    void put(long, long, const BASETYPE_c&)
    bint operator==(CTYPE_c&)
    bint operator!=(CTYPE_c&)

  long _ntlCTYPE_IsZero "IsZero"(const CTYPE_c&)

  void _ntlCTYPE_negate "negate"(CTYPE_c&, const CTYPE_c&)
  void _ntlCTYPE_add "add"(CTYPE_c&, const CTYPE_c&, const CTYPE_c&)
  void _ntlCTYPE_sub "sub"(CTYPE_c&, const CTYPE_c&, const CTYPE_c&)
  
  void _ntlCTYPE_mul "mul"(CTYPE_c&, const CTYPE_c&, const CTYPE_c&)
  void _ntlCTYPE_mul "mul"(CTYPE_c&, const CTYPE_c&, const BASETYPE_c&)
  void _ntlCTYPE_mul "mul"(vec_BASETYPE_c&, const CTYPE_c&, const vec_BASETYPE_c&)
  void _ntlCTYPE_mul "mul"(vec_BASETYPE_c&, const vec_BASETYPE_c&, const CTYPE_c&)

  void _ntlCTYPE_determinant "determinant"(CTYPE_c&, const CTYPE_c&, const CTYPE_c&)
  void _ntlCTYPE_transpose "transpose"(CTYPE_c&, const CTYPE_c&, long)

  void _ntlCTYPE_ident "ident"(CTYPE_c&, long)

  #IF CTYPE != "mat_ZZ"
  void _ntlCTYPE_conv "conv"(CTYPE_c&, const mat_ZZ_c&)
  #ENDIF
  #IF CTYPE == "mat_GF2" or CTYPE == "mat_ZZ_p"
  void _ntlCTYPE_conv "conv"(mat_ZZ_c&, const CTYPE_c&)
  #ENDIF
    
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
  cdef bint _init_proj(PyCTYPE self, object arg)
  
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

  def identity(self, long n):
    #MACRO CDEF_RES()
    _ntlCTYPE_ident(res.val, n)
    return res

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

  cdef bint _init_proj(PyCTYPE self, object arg):
    #IF CTYPE != "mat_ZZ"
    cdef Pymat_ZZ tmp
    if isinstance(arg, Pymat_ZZ):
      tmp = <Pymat_ZZ>arg
      if self.val.NumRows() > 0 and (tmp.val.NumRows() != self.val.NumRows() or tmp.val.NumCols() != self.val.NumCols()):
        raise ValueError("vector length mismatch")
      _ntlCTYPE_conv(self.val, tmp.val)
      return True
    #ENDIF

    return False

  cdef PyCTYPE _convert_arg(PyCTYPE self, object arg):
    cdef PyCTYPE tmp
    if isinstance(arg, PyCTYPE):
      tmp = <PyCTYPE>arg
      if tmp.val.NumRows() != self.val.NumRows() or tmp.val.NumCols() != self.val.NumCols():
        raise ValueError("matrix size mismatch")
      #IF HASCONTEXT
      if tmp.ctxt is not self.ctxt:
        raise TypeError("scalar modulus does not match")
      #ENDIF
      return arg

    #MACRO CDEF_RES()
    if res._init_proj(arg):
      return res

    return None
  
  cdef bint _init_from_seq(PyCTYPE self, arg):
    if not isinstance(arg, Sequence):
      return False
    cdef long rows = len(arg)
    cdef long cols = len(arg[0])
    self.val.SetDims(rows, cols)
    #IF HASCONTEXT
    cdef PyBASETYPE base = PyBASETYPE(self.ctxt)
    #ELSE
    cdef PyBASETYPE base = PyBASETYPE()
    #ENDIF
    for i in range(rows):
      argr = arg[i]
      for j in range(cols):
        self.val.put(i, j, base._convert_arg(argr[j]).val)
    return True

  def __init__(SELF_ARG, arg=None):
    #MACRO SELF_INIT
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
  

  # cpdef bint is_zero(PyCTYPE self):
  #   "Tests if `self` is the additive unit."
  #   return _ntlCTYPE_IsZero(self.val)

  # cpdef bint is_one(PyCTYPE self):
  #   "Tests if `self` is the multiplicative unit."
  #   return _ntlCTYPE_IsOne(self.val)


  def __len__(self):
    return self.val.NumRows()
  
  def __getitem__(self, _key):
    pass

    # MACRO CDEF_RES(BASETYPE)
    # res.val = self.val[idx]
    # return res

  # #IF CTYPE == "ZZ_pX"
  # def lift(PyCTYPE self):
  #   cdef PyZZX res = PyZZX.__new__(PyZZX)
  #   _ntlCTYPE_conv(res.val, self.val)
  #   return 
  # #ENDIF

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
    #MACRO CONVERT_ARG()
    #MACRO CDEF_RES()
    sig_on()
    _ntlCTYPE_mul(res.val, arg.val, self.val)
    sig_off()
    return res

  def __matmul__(PyCTYPE self, _arg):
    #MACRO CONVERT_ARG()
    #MACRO CDEF_RES()
    sig_on()
    _ntlCTYPE_mul(res.val, self.val, arg.val)
    sig_off()
    return res

