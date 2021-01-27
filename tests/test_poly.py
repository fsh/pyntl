
from ntl.all import *


ZX = PyZZX([0,1])


def test_zzx_polynomials():
  P = ZX**4 + 2*ZX**3 + 3*ZX**2 + ZX
  Q = ZX**3 - 3*ZX**2 + 1

  assert P.truncate(3).deg() == 2
  

def test_zn_polynomials():
  F = PyZZ_p_Context(PyZZ(17))
  X = PyZZ_pX(F, [0,1])

  R = [X-i for i in range(17)]

  assert (R[1]*R[2]).gcd(R[1]*R[3]) == R[1]

  from math import prod

  assert prod(R) == X**17 - X

  P = 13*X + 1

  assert P.monic()[1] == 1
  assert P.monic()[0] * 13 == 1
