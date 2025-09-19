
import os
import sys
from subprocess import Popen, PIPE
import tempfile

from .platform import platform_os, platform_shell

def eprint(*args, **kwargs):
    print(*args, file=sys.stderr, **kwargs)

class ShError(Exception):
    def __init__(self, err, out=None, retval=None):
        super().__init__(err)
        self.out = out
        self.retval = retval

def sh(cmd, join=False, lines=False, fail=True, classico=False):
    shell = isinstance(cmd, str)
    try:
        if shell:
            # Popen with shell=True defaults to /bin/sh so in order to use bash and
            # avoid quoting problems we write cmd into a temp file
            fd, cmd_file = tempfile.mkstemp(prefix=tempfile.gettempdir() + '/sh.')
            with open(cmd_file, 'w') as file:
                file.write(cmd)
            os.close(fd)
            if platform_shell() == 'msys2':
                cmd = "c:/msys64/usr/bin/env"
            elif platform_shell() == 'cygwin':
                cmd = "c:/cygwin64/usr/bin/env"
            else:
                cmd = "/usr/bin/env"
            cmd += f" bash {cmd_file}"
        proc = Popen(cmd, shell=shell, stdout=PIPE, stderr=PIPE)
        out, err = proc.communicate()
        out = out.decode('utf-8').strip()
        if lines is True:
            join = False
        if lines is True or join is not False:
            out = out.split("\n")
        if join is not False:
            s = join if type(join) is str else ' '
            out = s.join(out)
        if proc.returncode != 0 and fail is True:
            raise ShError(err.decode('utf-8'), out=out, retval=proc.returncode)
        return out
    except Exception as x:
        raise ShError(f"error executing: {cmd} [{x}]")
    finally:
        if shell and cmd_file:
            os.unlink(cmd_file)
