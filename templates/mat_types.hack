
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

vec_BASETYPE = "vec_" + BASETYPE

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

  void _ntlCTYPE_power "power"(CTYPE_c&, const CTYPE_c&, long e)
  void _ntlCTYPE_power "power"(CTYPE_c&, const CTYPE_c&, const ZZ_c&)

  void _ntlCTYPE_determinant "determinant"(CTYPE_c&, const CTYPE_c&, const CTYPE_c&)
  void _ntlCTYPE_transpose "transpose"(CTYPE_c&, const CTYPE_c&, long)

  void _ntlCTYPE_ident "ident"(CTYPE_c&, long)

  #IF CTYPE != "mat_ZZ"
  void _ntlCTYPE_conv "conv"(CTYPE_c&, const mat_ZZ_c&)
  #ELSE
  long _ntl_LLL "LLL"(ZZ_c&, mat_ZZ_c&, long, long, long)
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

  cdef PyCTYPE _submatrix(PyCTYPE self, slice rows, slice cols)
  cdef PyBASETYPE _element(self, long _r, long _c)
  cdef Pyvec_BASETYPE _vec_mul_right(PyCTYPE self, Pyvec_BASETYPE arg)
  cdef Pyvec_BASETYPE _vec_mul_left(PyCTYPE self, Pyvec_BASETYPE arg)
  cdef Pyvec_BASETYPE _subvec_row(PyCTYPE self, long row, slice cols)
  cdef Pyvec_BASETYPE _subvec_col(PyCTYPE self, long col, slice rows)

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

  # todo: random()

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


cdef long _check_index(long n, long i) except *:
  if i < 0:
    i = n + i
  if i < 0 or i >= n:
    raise IndexError("index out of bounds")
  return i


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
        raise ValueError("matrix size mismatch")
      _ntlCTYPE_conv(self.val, tmp.val)
      return True
    #ENDIF

    return False

  cdef PyCTYPE _convert_arg(PyCTYPE self, object arg):
    cdef PyCTYPE tmp
    if isinstance(arg, PyCTYPE):
      tmp = <PyCTYPE>arg
      # if tmp.val.NumRows() != self.val.NumRows() or tmp.val.NumCols() != self.val.NumCols():
      #   raise ValueError("matrix size mismatch")
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

  def nrows(self):
    return self.val.NumRows()

  def ncols(self):
    return self.val.NumCols()

  def __getitem__(PyCTYPE self, _key):
    cdef long i
    if isinstance(_key, tuple):
      a,b = _key
      if isinstance(a, slice):
        if isinstance(b, slice):
          return self._submatrix(a,b)
        else:
          return self._subvec_col(b, a)
      else:
        if isinstance(b, slice):
          return self._subvec_row(a, b)
        else:
          return self._element(a, b)
    if isinstance(_key, slice):
      return self._submatrix(_key, slice(None))
    else:
      return self._subvec_row(_key, slice(None))

  cdef PyBASETYPE _element(self, long _r, long _c):
    cdef long r = _check_index(self.val.NumRows(), _r)
    cdef long c = _check_index(self.val.NumCols(), _c)
    #MACRO CDEF_RES(BASETYPE)
    res.val = self.val[r][c]
    return res

  cdef PyCTYPE _submatrix(PyCTYPE self, slice rows, slice cols):
    cdef long r_a, r_b, r_s
    cdef long c_a, c_b, c_s
    r_a,r_b,r_s = rows.indices(self.nrows())
    c_a,c_b,c_s = cols.indices(self.ncols())
    #MACRO CDEF_RES()
    res.val.SetDims((r_b-r_a)//r_s, (c_b-c_a)//c_s)
    cdef long r, c
    r = 0
    for i in range(r_a,r_b,r_s):
      c = 0
      for j in range(c_a,c_b,c_s):
        res.val[r][c] = self.val[i][j]
        c += 1
      r += 1
    return res

  # #IF CTYPE == "ZZX" or CTYPE == "ZZ_pX"
  # def __hash__(PyCTYPE self):
  #   #IF HASCONTEXT
  #   return hash_ZZ_pX(self.val, self.ctxt._mod.val)
  #   #ELSE
  #   return hash_ZZX(self.val)
  #   #ENDIF
  # #ENDIF

  cdef Pyvec_BASETYPE _subvec_row(PyCTYPE self, long row, slice cols):
    row = _check_index(self.val.NumRows(), row)
    cdef long a, b, s
    a,b,s = cols.indices(self.ncols())
    #MACRO CDEF_RES(vec_BASETYPE)
    res.val.SetLength((b-a)//s)
    cdef long j = 0
    for i in range(a,b,s):
      res.val[j] = self.val[row][i]
      j += 1
    return res

  cdef Pyvec_BASETYPE _subvec_col(PyCTYPE self, long col, slice rows):
    col = _check_index(self.val.NumCols(), col)
    cdef long a, b, s
    a,b,s = rows.indices(self.nrows())
    #MACRO CDEF_RES(vec_BASETYPE)
    res.val.SetLength((b-a)//s)
    cdef long j = 0
    for i in range(a,b,s):
      res.val[j] = self.val[i][col]
      j += 1
    return res

  cdef Pyvec_BASETYPE _vec_mul_left(PyCTYPE self, Pyvec_BASETYPE arg):
    #MACRO CDEF_RES(vec_BASETYPE)
    sig_on()
    _ntlCTYPE_mul(res.val, arg.val, self.val)
    sig_off()
    return res

  cdef Pyvec_BASETYPE _vec_mul_right(PyCTYPE self, Pyvec_BASETYPE arg):
    #MACRO CDEF_RES(vec_BASETYPE)
    sig_on()
    _ntlCTYPE_mul(res.val, self.val, arg.val)
    sig_off()
    return res

  def __mul__(PyCTYPE self, _arg):
    if isinstance(_arg, Pyvec_BASETYPE):
      return self._vec_mul_left(_arg)
    #MACRO CONVERT_ARG()
    #MACRO CDEF_RES()
    sig_on()
    _ntlCTYPE_mul(res.val, self.val, arg.val)
    sig_off()
    return res

  def __rmul__(PyCTYPE self, _arg):
    if isinstance(_arg, Pyvec_BASETYPE):
      return self._vec_mul_right(_arg)
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

  def __pow__(PyCTYPE self, _exp, _mod):
    if _mod is not None:
      return NotImplemented
    cdef PyZZ exp = PyZZ._convert_arg_zz(_exp)
    #MACRO CDEF_RES()
    sig_on()
    _ntlCTYPE_power(res.val, self.val, exp.val)
    sig_off()
    return res

  #IF CTYPE == "mat_ZZ"
  def LLL(PyCTYPE self, delta=None, verbose=False):
    cdef long a = 3
    cdef long b = 4
    if delta is not None:
      if delta <= 0.25 or delta > 1.0:
        raise ValueError(f"delta ({delta}) must be in range (0.25,1.0]")
      a = delta * 16777216
      b = 16777216
    #MACRO CDEF_RES()
    res.val = self.val
    cdef ZZ_c det2
    sig_on()
    _ntl_LLL(det2, res.val, a, b, verbose)
    sig_off()
    return res
  #ENDIF

  #IF CTYPE == "mat_GF2" or CTYPE == "mat_ZZ_p"
  def lift(PyCTYPE self):
    cdef Pymat_ZZ res = Pymat_ZZ.__new__(Pymat_ZZ)
    _ntlCTYPE_conv(res.val, self.val)
    return res
  #ENDIF
