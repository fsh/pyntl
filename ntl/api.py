
from .ntl_ZZ import *
from .ntl_ZZ_p import *
from .ntl_ZZX import *

class ZRing(PyZZ_Class):

  def __truediv__(self, _mod):
    mod = ZZ(_mod)
    return PyZZ_p_Ring(mod)

  def __call__(self, *args):
    return PyZZ(*args)

  @property
  def P(self):
    return PyZZX_Class()

  def __getattr__(self, k):
    if hasattr(PyZZ, k):
      return getattr(PyZZ, k)
    raise AttributeError(f"no such attribute: {k}")

ZZ = ZRing()

