from contextlib import contextmanager
import errno
import os
import os.path
import re
import shutil
import sys
import tempfile
try:
    from urllib2 import urlopen  # type: ignore[import-not-found]
except:
    from urllib.request import urlopen

#----------------------------------------------------------------------------------------------

def fread(fname, mode='r'):
    with open(fname, mode) as file:
        return file.read()

#----------------------------------------------------------------------------------------------

def fwrite(fname, text, mode='w', encode=True):
    with open(fname, mode) as file:
        return file.write(text)

#----------------------------------------------------------------------------------------------

def fappend(fname, text, mode='a', encode=True):
    with open(fname, mode) as file:
        return file.write(text)

#----------------------------------------------------------------------------------------------

def freplace(fname, between, text, all=False, append_if_missing=True, mode='r+', encode=True):
    """
    Replace text between two patterns (including the pattern lines) with the provided text.
    `between` should be a tuple/list: (from_pattern, to_pattern)
    If append_if_missing is True and the patterns are not found, append the text at the end.
    """
    from_pat, to_pat = between
    replaced = False
    output_lines = []
    found = False
    with open(fname, 'r') as file:
        in_block = False
        for line in file:
            if not in_block and re.search(from_pat, line):
                in_block = True
                found = True
                if not replaced or all:
                    output_lines.append(text if text.endswith('\n') else text + '\n')
                    replaced = True
                continue
            if in_block and re.search(to_pat, line):
                in_block = False
                continue
            if not in_block:
                output_lines.append(line)
    if append_if_missing and not found:
        if output_lines and not output_lines[-1].endswith('\n'):
            output_lines[-1] += '\n'
        output_lines.append(text if text.endswith('\n') else text + '\n')
    with open(fname, 'w') as file:
        file.writelines(output_lines)

#----------------------------------------------------------------------------------------------

def flines(fname, mode = 'r'):
    return [line.rstrip() for line in open(fname)]

#----------------------------------------------------------------------------------------------

def tempfilepath(prefix=None, suffix=None):
    if sys.version_info < (3, 0):
        if prefix is None:
            prefix = ''
        if suffix is None:
            suffix = ''
    fd, path = tempfile.mkstemp(prefix=prefix, suffix=suffix)
    os.close(fd)
    return path

#----------------------------------------------------------------------------------------------

def wget(url, dest="", destdir="", tempdir=False):
    if dest == "":
        dest = os.path.basename(url)
        if dest == "":
            dest = tempfilepath()
        elif tempdir:
            dir = tempfilepath()
            dest = os.path.join(dir, dest)
        elif destdir != "":
            dest = os.path.join(destdir, dest)
    else:
        if tempdir:
            dir = tempfile.mkdtemp()
            dest = os.path.join(dir, dest)
    ufile = urlopen(url)
    data = ufile.read()
    with open(dest, "wb") as file:
        file.write(data)
    return os.path.abspath(dest)

#----------------------------------------------------------------------------------------------

@contextmanager
def cwd(path):
    d0 = os.getcwd()
    os.chdir(str(path))
    try:
        yield
    finally:
        os.chdir(d0)

#----------------------------------------------------------------------------------------------

def mkdir_p(dir):
    if dir == '':
        return
    try:
        return os.makedirs(dir, exist_ok=True)
    except TypeError:
        pass
    try:
        return os.makedirs(dir)
    except OSError as e:
        if e.errno != errno.EEXIST or os.path.isfile(dir):
            raise

#----------------------------------------------------------------------------------------------

def rm_rf(path, careful=True):
    if careful and os.path.normpath(path) in [".", "..", "/", "//", ""]:
        return
    if os.path.isdir(path) and not os.path.islink(path):
        shutil.rmtree(path)
    elif os.path.islink(path) or os.path.exists(path):
        os.remove(path)

#----------------------------------------------------------------------------------------------

def relpath(dir, rel):
    return os.path.abspath(os.path.join(dir, rel))
