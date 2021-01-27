import re
from pathlib import Path

templ_re = re.compile('^\s*#(IF|ELIF|ELSE|ENDIF)((?:\s+!?\S+)*)$')

class FakeNamespace(dict):
  def __getitem__(self, k):
    if not super().__contains__(k):
      return ''
    return super().__getitem__(k)


# def load_block(fil):
#   lns = []
#   nxt = None
#   for ln in fil:
#     if m := templ_re.match(ln):
#       nxt = (m[1], m[2].strip())
#       break
#     lns.append(ln)
#   return ''.join(lns), nxt

# def precomment(txt, what):
#   indent = re.match('^\s*', txt)[0]
#   if indent == txt:
#     return txt
#   if '\n' in indent:
#     indent = indent.split('\n')[-1]
#   return f'{indent}# ' + what + '\n' + txt

# def build_expr(stack):
#   st = []
#   for lev in stack:
#     nots, but = lev[:-1], lev[-1]
#     if nots:
#       condP = ' or '.join(nots)
#       st.append(f'((not ({condP})) and {but})')
#     else:
#       st.append(f'{but}')
#   if not st:
#     return 'True'
#   return ' and '.join(st)



# def load_mixins(fil):
#   stack = [ ]
#   ifbranch = []
#   res = []

#   while True:
#     lns,nxt = load_block(fil)
#     # print(f"DEBUG: {lns} {nxt}")

#     expr = build_expr(stack)
#     res.append((expr, precomment(lns, expr)))

#     if nxt is None:
#       break

#     nxt, arg = nxt
    
#     if nxt == 'IF':
#       stack.append([f'({arg})'])
#     elif nxt == 'ELSE':
#       stack[-1].append('True')
#     elif nxt == 'ELIF':
#       prev = ' or '.join(stack[-1])
#       stack[-1].append(f'({arg})')
#     elif nxt == 'ENDIF':
#       stack.pop()

#   return res


def multireplace(txt, alst, recursive=False):
  ":: str -> [(str,str)] -> str"

  start = txt
  for (k,v) in alst:
    txt = txt.replace(k, v)

  while recursive and txt != start:
    start = txt
    for (k,v) in alst:
      txt = txt.replace(k, v)

  return txt


# class Hacklate():
#   def __init__(self, fil):
#     self._blocks = load_mixins(fil)

#   def template(self, vals):
#     res = []
#     for pred, txt in self._blocks:
#       ns = FakeNamespace(vals)
#       if eval(pred, ns):
#         res.append(txt.format(**vals))
#     return ''.join(res)

# def iter_resplit(it, regex):
#   if isinstance(regex, str):
#     regex = re.compile(regex)
#   coll = []
#   for x in it:
#     if m := regex.match(x):
#       yield coll
#       yield m
#       coll = []
#     else:
#       coll.append(x)
#   yield coll



# re_defmacro = re.compile(r'#DEFMACRO\n([\s\S]+?)#ENDMACRO\n')

re_include = re.compile(r'^([ \t]*)#INCLUDE +(\S+)$', re.MULTILINE)
re_file = re.compile(r'^#FILE +(\S+)$', re.MULTILINE)
re_macros = re.compile(
  r'^([ \t]*)#(IF|ELIF|ELSE|ENDIF|MACRO|SAVETO|ENDSAVE)(?:[^\S\n]+(.*\S)[^\S\n]*)?$',
  re.MULTILINE)


class HackyMacros():
  def __init__(self, reldir, code, txt):
    self.code = code
    self.includes = []

    pre, *rest = re_include.split(txt)

    for indent,fname,trail in zip(rest[0::3], rest[1::3], rest[2::3]):
      self.includes.append(reldir / fname)
      pre += ''.join([indent + r for r in self.includes[-1].open()]) + trail

    self.txt = pre

  def eval(self, vals):
    state = dict()
    ctxt = dict(vals)
    ctxt['REPLACEMENTS'] = state

    exec(self.code, ctxt)
    
    xs = re_macros.split(self.txt)

    res = [xs[0]]
    if_active = []
    if_handled = []
    saves = []
    
    for indent, what, expr, trail in zip(xs[1::4], xs[2::4], xs[3::4], xs[4::4]):
      result = ''
      if expr and what != 'SAVETO':
        ctxt['INDENT'] = indent
        result = eval(expr, ctxt)

      if all(if_active):
        spwh = "\u200A".join(expr) if expr else '<NONE>'
        res.append(f'{indent}#{what} {spwh} (= "{bool(result)}")')

      if what == 'SAVETO':
        saves.append(expr)
        ctxt[expr] = [indent]
      elif what == 'ENDSAVE':
        w = saves.pop()
        ctxt[w] = '\n'.join(ctxt[w])
      elif what == 'ENDIF':
        if_active.pop()
        if_handled.pop()
      elif what == 'ELSE':
        if_active[-1] = False
        if not if_handled[-1]:
          if_handled[-1] = True
          if_active[-1] = True
      elif what == 'ELIF':
        if_active[-1] = False
        if not if_handled[-1] and result:
          if_handled[-1] = True
          if_active[-1] = True
      elif what == 'IF':
        if_active.append(bool(result))
        if_handled.append(bool(result))
      elif what == 'MACRO':
        if result:
          trail = ''.join(['\n' + indent + r for r in str(result).split('\n')]) + trail
      else:
        assert False

      if not all(if_active):
        res.append('\n')
        continue
      
      for line in trail.split('\n'):
        if not line.strip():
          continue
        for x in saves:
          ind = ctxt[x][0]
          assert line.startswith(ind)
          ctxt[x].append(line[len(ind):])
      
      res.append(trail)

    return ''.join(res), state


class Hacklate():
  def __init__(self, fname):
    fname = Path(fname)
    txt = fname.open().read()
    
    xs = re_file.split(txt)
    self.templates = dict()

    self.last_modified = fname.stat().st_mtime
    
    for targ,ftxt in zip(xs[1::2], xs[2::2]):
      hm = HackyMacros(fname.parent, xs[0], ftxt)
      self.templates[targ] = hm
      self.last_modified = max(0.0, self.last_modified, *[fn.stat().st_mtime for fn in hm.includes])
    
  def run_template(self, name, templ, vals, output_dir='.'):
    output_dir = Path(output_dir)
    target_file = output_dir / multireplace(name, [('CTYPE', vals['CTYPE'])]) # XXX hack

    if target_file.exists() and target_file.stat().st_mtime >= self.last_modified:
      print(f"[{target_file}] Up to date; skipping.")
      return
    
    print(f"[{target_file}] Regenerating with replacements {vals} ...")

    txt, st = templ.eval(vals)
    print(f'{st=}')
    txt = multireplace(txt, st.items())

    print(f"    ... {len(txt)} characters")
    with target_file.open('wt') as fil:
      fil.write(txt)
  
  def run(self, strmap, output_dir='.'):
    for fn, tl in self.templates.items():
      self.run_template(fn, tl, strmap, output_dir)
  





# def dedent(n, txt):
#   res = []
#   for ln in txt.split('\n'):
#     assert ln[:n].isspace()
#     res.append(ln)
#   return '\n'.join(res)

# def indent(n, txt):
#   return '\n'.join(' '*n + ln for ln in txt.split('\n'))


# def a():
#   while not matches('#IF (.*)'):
#     skip()

#   while not matches("#(ELIF|ELSE|ENDIF)"):
#     pass


# def active_if():
#   while not matches(f"^[ \t]*#(ELIF|ELSE|ENDIF)"):
#     passthrough

#   while not matches("^[ \t]*#ENDIF"):
#     skip
  
  

# def _if(self, indent, expr):
#   r"#IF (.*)"

#   res = eval(expr, ctxt)

#   if res:
#     eval to elif/else/endif
#   else:
#     skip to elif/else/endif

# class IfWatch:
#   def _if(self, expr):
#     r"#IF (.*)"
#     if self.eval(expr):
#       self.output_ln(f'# if {expr}')
#       self.push(IfActive(self))
#     else:
#       self.push(IfPending(self))

# class IfRunning:
#   def __init__(active):
#     self.active = active

#   def default(self, ln):
#     return ln if self.active else None

#   def _elif(self, expr):
#     r"#ELIF .*"
#     if self.active:
#       self.output_ln('# elif ... endif')
#       return DeadIf()
    
#     if self.eval(expr):
#       self.output_ln(f'# if ... elif {expr}')
#       self.active = True

#   def _else(self, indent):
#     r"#ELSE"
#     if self.active:
#       self.output_ln('# else ... endif')
#       return DeadIf()
    
#     self.output_ln(f'# if ... else')
#     self.active = True
#   def _endif(self):
#     r"#ENDIF"
#     return pop()
  
# class ActiveIf:
#   def _elif(self, indent, expr):
#     r"#ELIF .*"
#   def _else(self, indent):
#     r"#ELSE"
#   def _endif(self):
#     r"#ENDIF"
#     self.output_ln('# endif')
#     return None

# class IfDone:
#   def default(self, ln):
#     return None

#   def _endif(self):
#     r"#ENDIF"
#     raise StopIteration

  
# def _else(self):
#   pass


# def _save(self, indent, var):
#   r"#SAVETO (.*)"

#   self.ctxt[var] = []
  
#   def _saver(L):
#     self.ctxt[var].append(L)
#     return L
  
#   self.savers.append(_proc)
#   self.add_hook(_proc)

# def _endsave(self):
#   fn = self.savers.pop()
#   self.remove_hook(fn)
  
# def _eval(self, indent, expr):
#   r"#EVAL (.*)"
#   pass



# class saver:
#   def default(self, ln):
#     assert ln.startswith(self.indent)
#     self.ctxt[self.var].append(ln)
    
#   def _endsave(self):
#     r"^([ \t]*)#ENDSAVE"

#     self.ctxt[var] = lns
  
  
# re_defmacro = re.compile(r'#DEFMACRO\n([\s\S]+?)#ENDMACRO\n')

# # re_runmacro = re.compile(r'^([ \t]*)#RUNMACRO\s+(.*\S)\s*$', re.MULTILINE)
# re_file = re.compile(r'^#FILE +(\S+)$', re.MULTILINE)
# re_macros = re.compile(r'^([ \t]*)#(IF|ELIF|ELSE|ENDIF|MACRO)(?:[^\S\n]+(.*\S)[^\S\n]*)?$', re.MULTILINE)



