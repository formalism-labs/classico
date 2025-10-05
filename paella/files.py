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

from .platform_base import platform_os, platform_shell, platform_root, WINDOWS

#----------------------------------------------------------------------------------------------

def fread(fname, mode='r', fail=True):
    def _open():
        with open(fname, mode) as file:
            return file.read()
    if not fail:
        try:
            return _open()
        except:
            return ""
    return _open()

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
    return PP(path)

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

#----------------------------------------------------------------------------------------------

def homedir():
    if platform_os() != 'windows':
        return Path.home()
    shell = platform_shell()
    if shell in ['msys2', 'cygwin', 'wsl']:
        return platform_root() + f"home/{os.getenv('USERNAME')}"
    return cygpath_m(Path.home())
        
def ux_homedir():
    if platform_os() != 'windows':
        return Path.home()
    return f"/home/{os.getenv('USERNAME')}"

def win_homedir():
    if platform_os() != 'windows':
        return homedir()
    return cygpath_m(os.getenv('USERPROFILE'))

#----------------------------------------------------------------------------------------------

def cygpath_m(path: str) -> str:
    r'''
    Convert Windows path to cygpath -m style:
    - Drive letter: C:\Users\Admin -> /c/Users/Admin
    - UNC path: \\server\share\folder -> //server/share/folder
    - POSIX-like paths are returned unchanged
    '''
    path = path.replace('\\', '/')

    # Windows drive letter
    if len(path) >= 2 and path[1] == ':' and path[0].isalpha():
        drive = path[0].lower()
        rest = path[2:].lstrip('/')
        return f'{drive}:/{rest}'

    # UNC paths
    if path.startswith('//') or path.startswith('\\\\'):
        # Remove leading slashes
        path = path.lstrip('/').lstrip('\\')
        parts = path.split('/', 2)  # server, share, rest
        if len(parts) >= 2:
            server, share = parts[0], parts[1]
            rest = parts[2] if len(parts) == 3 else ''
            return f'//{server}/{share}/{rest}'.rstrip('/')
        return f'//{path}'

    return path

def cygpath_am(path):
    if not WINDOWS:
        return os.path.abspath(path)
    if path.startswith('/') and not path[1:].startswith('/'):
        path = platform_root() + path[1:]
    return cygpath_m(os.path.abspath(path))

def cygpath_u(path):
    if not WINDOWS:
        return path
    path = cygpath_m(path)
    root = platform_root()
    if path.startswith(root):
        return path[len(root)-1:]
    if len(path) >= 2 and path[1] == ':' and path[0].isalpha():
        drive = path[0].lower()
        rest = path[2:].lstrip('/')
        return f'/{drive}/{rest}'
    return path
