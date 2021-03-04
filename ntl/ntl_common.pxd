
from libc.stdint cimport uint64_t

cdef extern from "ntl_wrap.h":
  cdef cppclass INIT_MONO_STRUCT:
    pass

  cdef INIT_MONO_STRUCT INIT_MONO

  cdef cppclass Pair[A,B]:
    A a
    B b
  
  cdef cppclass Vec[T]:
    long length()
    T operator[](long)
  
