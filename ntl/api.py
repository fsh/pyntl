
from .ntl_ZZ import *
from .ntl_ZZ_p import *
from .ntl_ZZX import *
from .ntl_GF2 import *
from .ntl_GF2X import *

from .ntl_mat_ZZ import *
from .ntl_vec_ZZ import *
from .ntl_mat_GF2 import *
from .ntl_vec_GF2 import *

class AugmentedZZ(PyZZ_Class):

  def __truediv__(self, _mod):
    mod = ZZ(_mod)
    return PyZZ_p_Ring(mod)

  def __call__(self, *args):
    return PyZZ(*args)

  @property
  def P(self):
    return PyZZX_Class()

  @property
  def M(self):
    return Pymat_ZZ_Class()

  @property
  def V(self):
    return Pyvec_ZZ_Class()

  Polynomial = P
  Vector = V
  Matrix = M

  def __getattr__(self, k):
    if hasattr(PyZZ, k):
      return getattr(PyZZ, k)
    raise AttributeError(f"no such attribute: {k}")

class AugmentedGF2(PyGF2_Class):

  @property
  def P(self):
    return GF2X

  @property
  def M(self):
    return Pymat_GF2_Class()

  @property
  def V(self):
    return Pyvec_GF2_Class()

  Polynomial = P
  Vector = V
  Matrix = M


ZZ = AugmentedZZ()
GF2 = AugmentedGF2()
GF2X = PyGF2X_Class()

