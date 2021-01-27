#ifndef _ccore_templ_h
#define _ccore_templ_h

#include <string>
#include <sstream>
#include <vector>

template <class T>
static PyObject* any_to_pythonstr(T const& val) {
  std::ostringstream store;
  store << val;
  std::string st_str = store.str();
  return PyUnicode_DecodeFSDefaultAndSize(st_str.c_str(), st_str.length());
}

template <class T>
static int any_from_pythonstr(T& val, PyObject* obj) {
  PyObject* deref = NULL;
  if (PyUnicode_Check(obj)) {
    deref = obj = PyUnicode_EncodeFSDefault(obj);
    if (!obj) {
      return -1;
    }
  }

  char* cstr;
  Py_ssize_t len;
  int res = PyBytes_AsStringAndSize(obj, &cstr, &len);
  if (res != -1) {
    std::istringstream input(std::string(cstr, len));
    input >> val;
  }

  Py_XDECREF(deref);
  return res;
}

#endif
