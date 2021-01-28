
from setuptools import setup, Extension
from setuptools.command.build_py import build_py

from Cython.Build import cythonize
import sys
import os
from glob import glob
from pathlib import Path

# first run ```python hacklate.py``` this needs to be done manually
# because I suck. FIXME.

# and uhh, sdist/pip install still just does the cython thing, and
# requires Cython>=3.0a6. FIXME.

# compilation takes a long time. Every type is its own .so file. This
# is silly. FIXME.

# I'm not sure how to do it without cython's help, i.e. to auto-find
# and add the cysignal deps/includes so setuptools knows about it?
# FIXME.

ext = Extension(
  name=f'*',
  sources=['ntl/*.pyx'],
  include_dirs=['.'],
  libraries=['ntl'],
  language="c++",
)

setup(
  name='pyntl',
  description="Python bindings for the NTL library",
  version='0.0.5b',
  author="Frank S. Hestvik",
  author_email="tristesse@gmail.com",
  url="https://gitlab.com/franksh/pyntl",
  packages=['ntl'],
  ext_modules=cythonize(ext, compiler_directives=dict(language_level=3)),
  install_requires=['cysignals', 'Cython>=3.0a6'],
)

