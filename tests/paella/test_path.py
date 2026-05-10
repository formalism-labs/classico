
import os
import sys
import tempfile
import pytest

HERE = os.path.dirname(__file__)
CLASSICO = os.path.abspath(os.path.join(HERE, "../.."))
sys.path.insert(0, CLASSICO)

from paella import Path

# --- construction and normalization ---

def test_backslash_converted():
    p = Path('c:\\Users\\foo')
    assert str(p) == 'c:/Users/foo'

def test_forward_slash_preserved():
    p = Path('c:/Users/foo')
    assert str(p) == 'c:/Users/foo'

def test_duplicate_slashes_collapsed():
    p = Path('c:/Users//foo///bar')
    assert str(p) == 'c:/Users/foo/bar'

def test_drive_letter_lowercased():
    p = Path('C:/Users')
    assert str(p) == 'c:/Users'

def test_empty_is_dot():
    p = Path()
    assert str(p) == '.'

def test_posix_path():
    p = Path('/home/user/file.txt')
    assert str(p) == '/home/user/file.txt'

def test_unc_path():
    p = Path('//server/share/dir')
    assert str(p) == '//server/share/dir'

def test_absolute_resets():
    p = Path('/a', '/b', 'c')
    assert str(p) == '/b/c'

def test_multi_arg_join():
    p = Path('/home', 'user', 'file.txt')
    assert str(p) == '/home/user/file.txt'

# --- repr and fspath ---

def test_repr():
    p = Path('/a/b')
    assert repr(p) == "Path('/a/b')"

def test_fspath():
    p = Path('/a/b')
    assert os.fspath(p) == '/a/b'

# --- / operator ---

def test_truediv():
    p = Path('/home/user') / 'docs' / 'file.txt'
    assert str(p) == '/home/user/docs/file.txt'

def test_truediv_absolute_resets():
    p = Path('/home/user') / '/etc/config'
    assert str(p) == '/etc/config'

def test_rtruediv():
    p = '/home' / Path('user')
    assert str(p) == '/home/user'

# --- properties ---

def test_name():
    assert Path('/a/b/file.txt').name == 'file.txt'
    assert Path('/a/b/').name == 'b'
    assert Path('file.txt').name == 'file.txt'

def test_stem():
    assert Path('/a/file.txt').stem == 'file'
    assert Path('/a/file.tar.gz').stem == 'file.tar'
    assert Path('/a/noext').stem == 'noext'

def test_suffix():
    assert Path('/a/file.txt').suffix == '.txt'
    assert Path('/a/file.tar.gz').suffix == '.gz'
    assert Path('/a/noext').suffix == ''

def test_suffixes():
    assert Path('/a/file.tar.gz').suffixes == ['.tar', '.gz']
    assert Path('/a/file.txt').suffixes == ['.txt']
    assert Path('/a/noext').suffixes == []

def test_parent():
    assert str(Path('/a/b/c').parent) == '/a/b'
    assert str(Path('/a').parent) == '/'
    assert str(Path('a').parent) == '.'
    assert str(Path('c:/Users').parent) == 'c:/'

def test_parent_root_is_self():
    p = Path('/')
    assert p.parent == p
    p2 = Path('c:/')
    assert p2.parent == p2

def test_parents():
    p = Path('/a/b/c')
    ps = p.parents
    assert [str(x) for x in ps] == ['/a/b', '/a', '/']

def test_parts_posix():
    assert Path('/home/user/file').parts == ('/', 'home', 'user', 'file')

def test_parts_drive():
    assert Path('c:/Users/foo').parts == ('c:/', 'Users', 'foo')

def test_parts_relative():
    assert Path('a/b/c').parts == ('a', 'b', 'c')

def test_parts_dot():
    assert Path('.').parts == ()

def test_drive():
    assert Path('c:/foo').drive == 'c:'
    assert Path('/foo').drive == ''

def test_root():
    assert Path('c:/foo').root == '/'
    assert Path('/foo').root == '/'
    assert Path('//server/share').root == '//'
    assert Path('foo').root == ''

def test_anchor():
    assert Path('c:/foo').anchor == 'c:/'
    assert Path('/foo').anchor == '/'
    assert Path('foo').anchor == ''

# --- query methods ---

def test_is_absolute():
    assert Path('/a').is_absolute()
    assert Path('c:/a').is_absolute()
    assert not Path('a/b').is_absolute()

# --- comparison and hashing ---

def test_equality():
    assert Path('/a/b') == Path('/a/b')
    assert Path('/a/b') != Path('/a/c')

def test_ordering():
    assert Path('/a') < Path('/b')
    assert Path('/b') > Path('/a')
    assert Path('/a') <= Path('/a')
    assert Path('/a') >= Path('/a')

def test_hash():
    s = {Path('/a'), Path('/a'), Path('/b')}
    assert len(s) == 2

def test_bool():
    assert bool(Path('.'))
    assert bool(Path('/a'))

# --- derivation ---

def test_relative_to():
    p = Path('/a/b/c')
    assert str(p.relative_to('/a/b')) == 'c'
    assert str(p.relative_to('/a')) == 'b/c'
    assert str(p.relative_to('/a/b/c')) == '.'

def test_relative_to_raises():
    with pytest.raises(ValueError):
        Path('/a/b').relative_to('/c')

def test_relative_to_no_partial_segment():
    with pytest.raises(ValueError):
        Path('/abc').relative_to('/ab')

def test_with_name():
    assert str(Path('/a/b/old.txt').with_name('new.py')) == '/a/b/new.py'

def test_with_stem():
    assert str(Path('/a/b/old.txt').with_stem('new')) == '/a/b/new.txt'

def test_with_suffix():
    assert str(Path('/a/b/file.txt').with_suffix('.md')) == '/a/b/file.md'

def test_joinpath():
    p = Path('/a').joinpath('b', 'c')
    assert str(p) == '/a/b/c'

def test_match():
    assert Path('/a/file.txt').match('*.txt')
    assert not Path('/a/file.txt').match('*.py')

# --- filesystem operations (using tmpdir) ---

def test_exists(tmp_path):
    f = Path(str(tmp_path)) / 'test.txt'
    assert not f.exists()
    with open(str(f), 'w') as fh:
        fh.write('hello')
    assert f.exists()

def test_is_file_is_dir(tmp_path):
    d = Path(str(tmp_path))
    assert d.is_dir()
    assert not d.is_file()
    f = d / 'file.txt'
    with open(str(f), 'w') as fh:
        fh.write('x')
    assert f.is_file()
    assert not f.is_dir()

def test_mkdir(tmp_path):
    d = Path(str(tmp_path)) / 'sub' / 'deep'
    assert not d.exists()
    d.mkdir(parents=True)
    assert d.is_dir()

def test_mkdir_exist_ok(tmp_path):
    d = Path(str(tmp_path)) / 'sub'
    d.mkdir()
    d.mkdir(exist_ok=True)

def test_touch(tmp_path):
    f = Path(str(tmp_path)) / 'touched'
    assert not f.exists()
    f.touch()
    assert f.exists()

def test_unlink(tmp_path):
    f = Path(str(tmp_path)) / 'to_delete'
    f.touch()
    assert f.exists()
    f.unlink()
    assert not f.exists()

def test_unlink_missing_ok(tmp_path):
    f = Path(str(tmp_path)) / 'nope'
    f.unlink(missing_ok=True)
    with pytest.raises(FileNotFoundError):
        f.unlink()

def test_rmdir(tmp_path):
    d = Path(str(tmp_path)) / 'emptydir'
    d.mkdir()
    d.rmdir()
    assert not d.exists()

def test_rename(tmp_path):
    src = Path(str(tmp_path)) / 'src.txt'
    dst = Path(str(tmp_path)) / 'dst.txt'
    src.touch()
    result = src.rename(dst)
    assert not src.exists()
    assert dst.exists()
    assert str(result) == str(dst)

def test_stat(tmp_path):
    f = Path(str(tmp_path)) / 'stat_test'
    f.touch()
    s = f.stat()
    assert s.st_size == 0

# --- I/O ---

def test_read_write_text(tmp_path):
    f = Path(str(tmp_path)) / 'rw.txt'
    f.write_text('hello world')
    assert f.read_text() == 'hello world'

def test_read_write_bytes(tmp_path):
    f = Path(str(tmp_path)) / 'rw.bin'
    f.write_bytes(b'\x00\x01\x02')
    assert f.read_bytes() == b'\x00\x01\x02'

def test_open(tmp_path):
    f = Path(str(tmp_path)) / 'opened.txt'
    with f.open('w') as fh:
        fh.write('data')
    with f.open('r') as fh:
        assert fh.read() == 'data'

# --- iteration ---

def test_iterdir(tmp_path):
    d = Path(str(tmp_path))
    (d / 'a.txt').touch()
    (d / 'b.txt').touch()
    names = sorted(p.name for p in d.iterdir())
    assert names == ['a.txt', 'b.txt']

def test_glob(tmp_path):
    d = Path(str(tmp_path))
    (d / 'a.py').touch()
    (d / 'b.py').touch()
    (d / 'c.txt').touch()
    matches = sorted(p.name for p in d.glob('*.py'))
    assert matches == ['a.py', 'b.py']

# --- class methods ---

def test_home():
    h = Path.home()
    assert h.is_absolute()
    assert h.exists()

def test_cwd():
    c = Path.cwd()
    assert c.is_absolute()
    assert c.exists()

# --- conversion ---

def test_to_winpath():
    import pathlib
    p = Path('c:/Users/foo')
    wp = p.to_winpath()
    assert isinstance(wp, pathlib.Path)

# --- forward slashes never lost ---

def test_resolve_keeps_forward_slashes(tmp_path):
    d = Path(str(tmp_path))
    r = d.resolve()
    assert '\\' not in str(r)

def test_absolute_keeps_forward_slashes(tmp_path):
    d = Path(str(tmp_path))
    a = d.absolute()
    assert '\\' not in str(a)

def test_cwd_keeps_forward_slashes():
    c = Path.cwd()
    assert '\\' not in str(c)

def test_home_keeps_forward_slashes():
    h = Path.home()
    assert '\\' not in str(h)
