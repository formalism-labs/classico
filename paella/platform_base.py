
import sys
import os
from subprocess import Popen, PIPE

#----------------------------------------------------------------------------------------------

def platform_os():
    specs = {
        "linux": ["linux"],
        "macos": ["darwin"],
        "solaris": ["solaris"],
        "bsd": ["bsd"],
        "windows": ["cygwin", "msys"]
    }

    ostype = os.getenv("OSTYPE")
    if ostype is None:
        windir = os.getenv("WINDIR")
        if windir is not None and os.path.isdir(windir):
            return "windows"
    for os_, prefixes in specs.items():
        p = next((prefix for prefix in prefixes if ostype.startswith(prefix)), None)
        if p is not None:
            return os_
    return None

# one could possibly condier using MSYSTEM on msys2, however this pseudo environment
# varialbe only exists in bash
def detect_windows_system_shell():
    if platform_os() != "windows":
        return None
    proc = Popen("cat /proc/version", shell=True, stdout=PIPE, stderr=PIPE)
    out, err = proc.communicate()
    out = out.decode('utf-8').strip()    
    if 'MINGW64' in out:
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
        "x86_64": ["x86_64", "amd64"],
        "x86": ["i386", "i686"],
        "arm64v8": ["aarch64"],
        "arm32v7": ["armv7hl", "armv7l"],
        "arm32v6": ["armv6l"],
        "ppc": ["ppc64"],
        "s390_31": ["s390"],
        "s390x": ["s390x"],
    }
    
    mach = sh("uname -m")
    for arch, prefixes in specs.items():
        p = next((prefix for prefix in prefixes if mach.startswith(prefix)), None)
        if p is not None:
            return arch
    return None

if platform_os() == "windows":
    WINDOWS_SYSTEM_SHELL = detect_windows_system_shell()

def platform_root():
    if platform_os() != 'windows':
        return "/"
    shell = platform_shell()
    if shell == 'msys2':
        return "c:/msys64/"
    elif shell == 'cygwin':
        return "c:/cygwin64/"
    return "/"

WINDOWS = platform_os() == 'windows'
