
from ntl.all import *
from pytest import fixture


def test_basic_Zp_arithmetic():
  a = PyZZ()
  g = PyZZ(7)
  assert g
  assert not a
  assert g == 7+a
  assert a+g == g
  assert type(int(g)) is int

  F = PyZZ_p_Context(g+10)
  assert F(7) == F(g)
  assert 7 == g
  assert F(g) == 7

  assert F(5) - 1 == 4
  assert -F(1) == 16
  assert ~F(3)*3 == 1
  assert F(-1) == 16
  assert F(-1) == 16+17

  assert (3/F(2))*2 == 3

  v = g*F(66)
  assert v == (7*66)%17


def test_basic_polynomials():
  F = PyZZ_p_Context(PyZZ(17))
  
  x0 = PyZZ_pX(F, 1)
  X = x0 << 1

  P = X**3 + 3*X - 1
  G = P**2

  assert P*P == G
  assert (P**2).deg() == 6
  assert G[0] == 1
