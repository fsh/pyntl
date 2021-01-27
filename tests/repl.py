
from ntl.all import *
from ntl.api import ZZ

X = PyZZX(1) << 1
F = ZZ/7

while not (Irr := F.P.random(5).monic()).is_irreducible(): pass

