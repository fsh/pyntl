
from .all import *

class ZRing(PyZZ_Class):

  def __truediv__(self, _mod):
    mod = ZZ(_mod)
    return PyZZ_p_Ring(mod)

  def __call__(self, *args):
    return PyZZ(*args)

  @property
  def P(self):
    return PolyRing(PyZZX_Class())

ZZ = ZRing()


