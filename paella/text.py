
import inspect
import jinja2
import re
import textwrap

#----------------------------------------------------------------------------------------------

class RegexpMatch:
    def __init__(self, r, s):
        self.m = re.match(r, s)

    def __bool__(self):
        return bool(self.m)

    def __nonzero__(self):
        return bool(self.m)

    def __getitem__(self, k):
        return self.m.group(k)

def match(r, s):
    return RegexpMatch(r, s)

#----------------------------------------------------------------------------------------------

def heredoc(s):
    if s.find('\n') > -1:
        s = str.lstrip(textwrap.dedent(s))
    return s 

#----------------------------------------------------------------------------------------------

def jjdoc(text, ctx=None):
    if text.find('\n') > -1:
        text = str.lstrip(textwrap.dedent(text))
    if ctx is None:
        frame = inspect.currentframe().f_back
        ctx = {**frame.f_globals, **frame.f_locals}        
    return jinja2.Template(text).render(**ctx)
    
#----------------------------------------------------------------------------------------------

def is_int(x):
    try:
        n = int(x)  # noqa: F841
        return True
    except:
        return False

def is_float(x):
    try:
        n = float(x)  # noqa: F841
        return True
    except:
        return False

def is_numeric(x):
    return re.match(r'^\d+$', x) is not None
