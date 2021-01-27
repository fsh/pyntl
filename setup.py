
from setuptools import setup, Extension
from setuptools.command.build_py import build_py

from Cython.Build import cythonize
import sys
import os

from pathlib import Path


ROOT = Path(__file__).parent
SRC_DIR = ROOT / 'ntl'

exts = []

# Avert your eyes. I will clean this up at some point.

from hacklate import Hacklate
from ntl_types import type_translations

def hacky_bullshit(hack, vals):
  typname = vals['CTYPE']
  pyx = SRC_DIR / f'ntl_{typname}.pyx'
  pxd = SRC_DIR / f'ntl_{typname}.pxd'

  # hacky template thing will check timestamp of files to test if
  # regeneration is necessary.
  hack.run(vals, output_dir=SRC_DIR)

  return Extension(
    name=f'ntl.ntl_{typname}',
    sources=[str(pyx)],
    include_dirs=['.'],
    libraries=['ntl'],
    language="c++",
  )


hack = Hacklate(ROOT / 'templates' / 'base_ring.hack')
for typ in 'ZZ ZZ_p ZZ_pE GF2 GF2E'.split():
  exts.append(hacky_bullshit(hack, dict(CTYPE=typ, **type_translations[typ])))

hack = Hacklate(ROOT / 'templates' / 'poly_ring.hack')
for typ in 'ZZX ZZ_pX ZZ_pEX GF2X GF2EX'.split():
  exts.append(hacky_bullshit(hack, dict(CTYPE=typ, **type_translations[typ])))

hack = Hacklate(ROOT / 'templates' / 'vec_types.hack')
for typ in 'vec_ZZ vec_ZZ_p vec_ZZ_pE vec_GF2 vec_GF2E'.split():
  exts.append(hacky_bullshit(hack, dict(CTYPE=typ, **type_translations[typ])))

hack = Hacklate(ROOT / 'templates' / 'mat_types.hack')
for typ in 'mat_ZZ mat_ZZ_p mat_ZZ_pE mat_GF2 mat_GF2E'.split():
  exts.append(hacky_bullshit(hack, dict(CTYPE=typ, **type_translations[typ])))


setup(
  name='pyntl',
  description="Python bindings for the NTL library",
  version='0.0.5',
  author="Frank S. Hestvik",
  author_email="tristesse@gmail.com",
  url="https://gitlab.com/franksh/pyntl",
  packages=['ntl'],
  ext_modules=cythonize(exts, compiler_directives=dict(language_level=3)),
  install_requires=['cysignals'],
  # cmdclass={'build_py': gen_pxi},
)

