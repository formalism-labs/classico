import os
import os.path
import pathlib

from .platform_base import platform_os, platform_shell, platform_root, WINDOWS

#----------------------------------------------------------------------------------------------

def relpath(dir, rel):
    return os.path.abspath(os.path.join(dir, rel))

#----------------------------------------------------------------------------------------------

def homedir():
    if platform_os() != 'windows':
        return f"{pathlib.Path.home()}"
    shell = platform_shell()
    if shell in ['msys2', 'cygwin', 'wsl']:
        return platform_root() + f"home/{os.getenv('USERNAME')}"
    return cygpath_m(pathlib.Path.home())
        
def ux_homedir():
    if platform_os() != 'windows':
        return f"{pathlib.Path.home()}"
    return f"/home/{os.getenv('USERNAME')}"

def win_homedir():
    if platform_os() != 'windows':
        return homedir()
    return cygpath_m(os.getenv('USERPROFILE'))

#----------------------------------------------------------------------------------------------

def cygpath_m(path: str) -> str:
    r'''
    Convert Windows path to cygpath -m style:
    - Drive letter: C:\Users\Admin -> c:/Users/Admin
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
    r'''
    Convert Windows path to absolute cygpath -m style
    '''
    if not WINDOWS:
        return os.path.abspath(path)
    if path.startswith('/') and not path[1:].startswith('/'):
        path = platform_root() + path[1:]
    return cygpath_m(os.path.abspath(path))

def cygpath_u(path):
    r'''
    Convert Windows path to cygpath -u style:
    - Drive letter: C:\Users\Admin -> /c/Users/Admin
    - UNC path: \\server\share\folder -> //server/share/folder
    - POSIX-like paths are returned unchanged
    '''
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

#----------------------------------------------------------------------------------------------

class Path:
    '''Path that preserves forward slashes on all platforms.
    Drop-in replacement for pathlib.Path; use to_winpath() for explicit Windows conversion.'''

    __slots__ = ('_path',)

    def __init__(self, *args):
        if not args:
            self._path = '.'
            return
        parts = []
        for a in args:
            s = str(a).replace('\\', '/')
            if s.startswith('/') or (len(s) >= 2 and s[1] == ':'):
                parts = [s]
            else:
                parts.append(s)
        self._path = self._normalize('/'.join(parts))

    @staticmethod
    def _normalize(p):
        if not p:
            return '.'
        anchor = ''
        rest = p
        if p.startswith('//'):
            anchor = '//'
            rest = p[2:]
        elif p.startswith('/'):
            anchor = '/'
            rest = p[1:]
        elif len(p) >= 2 and p[1] == ':' and p[0].isalpha():
            anchor = p[0].lower() + ':/'
            rest = p[2:].lstrip('/')
        segments = [s for s in rest.split('/') if s]
        result = anchor + '/'.join(segments)
        return result or '.'

    def __str__(self):
        return self._path

    def __repr__(self):
        return f"Path('{self._path}')"

    def __fspath__(self):
        return self._path

    def __truediv__(self, other):
        return Path(self._path, str(other))

    def __rtruediv__(self, other):
        return Path(str(other), self._path)

    def __eq__(self, other):
        if isinstance(other, Path):
            return self._path == other._path
        return NotImplemented

    def __ne__(self, other):
        if isinstance(other, Path):
            return self._path != other._path
        return NotImplemented

    def __lt__(self, other):
        if isinstance(other, Path):
            return self._path < other._path
        return NotImplemented

    def __le__(self, other):
        if isinstance(other, Path):
            return self._path <= other._path
        return NotImplemented

    def __gt__(self, other):
        if isinstance(other, Path):
            return self._path > other._path
        return NotImplemented

    def __ge__(self, other):
        if isinstance(other, Path):
            return self._path >= other._path
        return NotImplemented

    def __hash__(self):
        return hash(self._path)

    def __bool__(self):
        return True

    # --- properties ---

    @property
    def name(self):
        i = self._path.rfind('/')
        return self._path[i+1:] if i >= 0 else self._path

    @property
    def stem(self):
        n = self.name
        i = n.rfind('.')
        return n[:i] if i > 0 else n

    @property
    def suffix(self):
        n = self.name
        i = n.rfind('.')
        return n[i:] if i > 0 else ''

    @property
    def suffixes(self):
        n = self.name
        if '.' not in n:
            return []
        parts = n.split('.')
        return ['.' + s for s in parts[1:]]

    @property
    def parent(self):
        i = self._path.rfind('/')
        if i < 0:
            return Path('.')
        p = self._path[:i]
        if not p:
            return Path('/')
        if len(p) == 2 and p[1] == ':':
            return Path(p + '/')
        return Path(p)

    @property
    def parents(self):
        result = []
        p = self
        while True:
            pp = p.parent
            if pp == p:
                break
            result.append(pp)
            p = pp
        return tuple(result)

    @property
    def parts(self):
        if self._path == '.':
            return ()
        anchor = ''
        rest = self._path
        if self._path.startswith('//'):
            anchor = '//'
            rest = self._path[2:]
        elif self._path.startswith('/'):
            anchor = '/'
            rest = self._path[1:]
        elif len(self._path) >= 3 and self._path[1] == ':' and self._path[2] == '/':
            anchor = self._path[:3]
            rest = self._path[3:]
        segments = [s for s in rest.split('/') if s]
        if anchor:
            return (anchor,) + tuple(segments)
        return tuple(segments)

    @property
    def drive(self):
        if len(self._path) >= 2 and self._path[1] == ':' and self._path[0].isalpha():
            return self._path[:2]
        return ''

    @property
    def root(self):
        if self._path.startswith('//'):
            return '//'
        if self._path.startswith('/'):
            return '/'
        if len(self._path) >= 3 and self._path[1] == ':' and self._path[2] == '/':
            return '/'
        return ''

    @property
    def anchor(self):
        return self.drive + self.root

    # --- query methods ---

    def is_absolute(self):
        return self._path.startswith('/') or (len(self._path) >= 3 and self._path[1] == ':' and self._path[2] == '/')

    def exists(self):
        return os.path.exists(self._path)

    def is_file(self):
        return os.path.isfile(self._path)

    def is_dir(self):
        return os.path.isdir(self._path)

    def is_symlink(self):
        return os.path.islink(self._path)

    def stat(self):
        return os.stat(self._path)

    def lstat(self):
        return os.lstat(self._path)

    # --- derivation ---

    def resolve(self):
        return Path(cygpath_am(os.path.realpath(self._path)))

    def absolute(self):
        return Path(cygpath_am(os.path.abspath(self._path)))

    def relative_to(self, other):
        other_s = Path(other)._path
        if self._path == other_s:
            return Path('.')
        if self._path.startswith(other_s + '/'):
            return Path(self._path[len(other_s)+1:])
        raise ValueError(f"'{self._path}' is not relative to '{other_s}'")

    def with_name(self, name):
        return self.parent / name

    def with_stem(self, stem):
        return self.parent / (stem + self.suffix)

    def with_suffix(self, suffix):
        return self.parent / (self.stem + suffix)

    def joinpath(self, *args):
        return Path(self._path, *[str(a) for a in args])

    def match(self, pattern):
        import fnmatch
        return fnmatch.fnmatch(self.name, pattern)

    # --- filesystem operations ---

    def mkdir(self, parents=False, exist_ok=False):
        if parents:
            os.makedirs(self._path, exist_ok=exist_ok)
        else:
            if exist_ok and os.path.isdir(self._path):
                return
            os.mkdir(self._path)

    def touch(self, exist_ok=True):
        if self.exists():
            if not exist_ok:
                raise FileExistsError(self._path)
            os.utime(self._path, None)
        else:
            with open(self._path, 'a'):
                pass

    def unlink(self, missing_ok=False):
        try:
            os.remove(self._path)
        except FileNotFoundError:
            if not missing_ok:
                raise

    def rmdir(self):
        os.rmdir(self._path)

    def rename(self, target):
        os.rename(self._path, str(target))
        return Path(target)

    def replace(self, target):
        os.replace(self._path, str(target))
        return Path(target)

    # --- I/O ---

    def open(self, mode='r', **kwargs):
        return open(self._path, mode, **kwargs)

    def read_text(self, encoding=None, errors=None):
        kwargs = {}
        if encoding is not None:
            kwargs['encoding'] = encoding
        if errors is not None:
            kwargs['errors'] = errors
        with self.open('r', **kwargs) as f:
            return f.read()

    def read_bytes(self):
        with self.open('rb') as f:
            return f.read()

    def write_text(self, data, encoding=None, errors=None):
        kwargs = {}
        if encoding is not None:
            kwargs['encoding'] = encoding
        if errors is not None:
            kwargs['errors'] = errors
        with self.open('w', **kwargs) as f:
            return f.write(data)

    def write_bytes(self, data):
        with self.open('wb') as f:
            return f.write(data)

    # --- iteration ---

    def iterdir(self):
        for name in os.listdir(self._path):
            yield self / name

    def glob(self, pattern):
        import glob as _glob
        full = self._path.rstrip('/') + '/' + pattern
        for p in _glob.glob(full, recursive=True):
            yield Path(p)

    def rglob(self, pattern):
        return self.glob('**/' + pattern)

    # --- class methods ---

    @classmethod
    def home(cls):
        return cls(homedir())

    @classmethod
    def ux_home(cls):
        return cls(ux_homedir())

    @classmethod
    def win_home(cls):
        return cls(win_homedir())

    @classmethod
    def cwd(cls):
        return cls(cygpath_am(os.getcwd()))

    # --- conversion ---

    def to_winpath(self):
        '''Explicit conversion to pathlib.Path (native Windows format on Windows).'''
        return pathlib.Path(self._path)

    def to_uxpath(self):
        return cygpath_u(self._path)
