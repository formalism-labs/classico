
import sys
import os
import platform
from subprocess import Popen, PIPE
from .meta import Lazy

#----------------------------------------------------------------------------------------------

def platform_os():
    specs = {
        "linux": ["linux"],
        "macos": ["darwin"],
        "bsd": ["bsd", "freebsd", "openbsd", "netbsd"],
        "solaris": ["sunos", "solaris", "illumos"],
        "windows": ["cygwin", "msys", "windows"]
    }

    def find_spec(ostype):
        for os_, prefixes in specs.items():
            p = next((prefix for prefix in prefixes if ostype.startswith(prefix)), None)
            if p is not None:
                return os_

    ostype = platform.system().lower()
    os_ = find_spec(ostype)
    if os_ is None:
        ostype = sh('echo $OSTYPE')
        os_ = find_spec(ostype)
    if os_ is None:
        windir = os.getenv("WINDIR")
        if windir is not None and os.path.isdir(windir):
            return "windows"
    return None

# one could possibly condier using MSYSTEM on msys2, however this pseudo environment
# varialbe only exists in bash
def detect_windows_system_shell():
    if platform_os() != "windows":
        return None
    proc = Popen("cat /proc/version", shell=True, stdout=PIPE, stderr=PIPE)
    out, err = proc.communicate()
    out = out.decode('utf-8').strip()    
    if 'MINGW' in out or 'MSYS' in out:
        return 'msys2'
    if 'CYGWIN' in out:
        return 'cygwin'
    if 'wsl' in out:
        return 'wsl'
    return 'native'

def platform_shell():
    if platform_os() != "windows":
        return None
    return WINDOWS_SYSTEM_SHELL

def platform_arch():
    specs = {
        "x64": ["x86_64", "amd64"],
        "x86": ["i386", "i686"],
        "arm64v8": ["aarch64"],
        "arm32v7": ["armv7hl", "armv7l"],
        "arm32v6": ["armv6l"],
        "ppc": ["ppc64"],
        "s390x": ["s390x"],
        "s390_31": ["s390"],
    }

    def find_spec(mach):
        for arch, prefixes in specs.items():
            p = next((prefix for prefix in prefixes if mach.startswith(prefix)), None)
            if p is not None:
                return arch
    
    mach = platform.machine().lower()
    spec = find_spec(mach)
    if spec is None:
        mach = sh("uname -m").lower()
        spec = find_spec(mach)
    return spec

if platform_os() == "windows":
    WINDOWS_SYSTEM_SHELL = Lazy(detect_windows_system_shell)

def platform_root():
    if platform_os() != 'windows':
        return "/"
    shell = platform_shell()
    if shell == 'msys2':
        return "c:/msys64/"
    elif shell == 'cygwin':
        return "c:/cygwin64/"
    return "/"

WINDOWS = Lazy(lambda: platform_os() == 'windows')
