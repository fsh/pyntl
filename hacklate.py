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
  


# Avert your eyes. I will clean this up at some point.

from ntl_types import type_translations

src_dir = Path('ntl')
templ_dir = Path('templates')

def hacky_bullshit(hack, vals):
  typname = vals['CTYPE']
  pyx = src_dir / f'ntl_{typname}.pyx'
  pxd = src_dir / f'ntl_{typname}.pxd'

  # hacky template thing will check timestamp of files to test if
  # regeneration is necessary.
  hack.run(vals, output_dir=src_dir)

hack = Hacklate(templ_dir / 'base_ring.hack')
for typ in 'ZZ ZZ_p ZZ_pE GF2 GF2E'.split():
  hacky_bullshit(hack, dict(CTYPE=typ, **type_translations[typ]))

hack = Hacklate(templ_dir / 'poly_ring.hack')
for typ in 'ZZX ZZ_pX ZZ_pEX GF2X GF2EX'.split():
  hacky_bullshit(hack, dict(CTYPE=typ, **type_translations[typ]))

hack = Hacklate(templ_dir / 'vec_types.hack')
for typ in 'vec_ZZ vec_ZZ_p vec_ZZ_pE vec_GF2 vec_GF2E'.split():
  hacky_bullshit(hack, dict(CTYPE=typ, **type_translations[typ]))

hack = Hacklate(templ_dir / 'mat_types.hack')
for typ in 'mat_ZZ mat_ZZ_p mat_ZZ_pE mat_GF2 mat_GF2E'.split():
  hacky_bullshit(hack, dict(CTYPE=typ, **type_translations[typ]))

