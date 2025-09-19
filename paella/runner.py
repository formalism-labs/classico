
import os
import sys
from pathlib import Path
import subprocess
import tempfile

from .platform import OnPlatform, Platform, platform_os, platform_shell
from .error import *  # noqa: F403
import paella

#----------------------------------------------------------------------------------------------

class OutputMode:
    def __init__(self, x):
        lx = str(x).lower()
        if x or x == 1 or lx == "yes" or lx == "true":
            self.mode = "True"
        elif not x or x == 0 or lx == "no" or lx == "false":
            self.mode = "False"
        elif lx == "on_error":
            self.mode = "on_error"
        else:
            raise Error(f"Wrong output mode: {x}")

    def __eq__(self, x):
        return self.mode == OutputMode(x).mode

    def __ne__(self, x):
        return not self.__eq__(x)

    def __bool__(self):
        return self.mode == "True"

    def on_error(self):
        return self.mode == "on_error"

#----------------------------------------------------------------------------------------------

class Runner:
    def __init__(self, nop=False, output='on_error'):
        self.nop = nop
        if platform_os() == 'windows':
            try:
                sh("$WINDIR/system32/whoami.exe //groups | grep S-1-16-12288 &> /dev/null")
                self.is_root = True
            except:
                self.is_root = False
        else:
            self.is_root = os.geteuid() == 0
        self.has_sudo = sh('command -v sudo', fail=False) != ''
        self.output = OutputMode(output)

    # sudo: True/False/'file'
    def run(self, cmd, at=None, output=None, nop=None, _try=False, sudo=False, echo=True, classico=False):
        # We're running cmd(s) with a login shell ("bash -l") in order to run profile.d
        # scripts (installation commands may add such scripts and subsequent installation
        # commands may rely on them).
        # Howerver, "bash -l" will wreck PATH of active virtualenvs, thus python scripts will
        # fail. So if we're in one (i.e. VIRTUAL_ENV is not empty) PATH sould be restored
        # by re-invoking the activation script.
        if self.is_root or not self.has_sudo:
            sudo = False

        if output is None:
            output = self.output
        else:
            output = OutputMode(output)

        bash = platform_root() + "usr/bin/env bash"

        venv = ENV['VIRTUAL_ENV']
        if venv != '':
            if not os.path.isdir(venv):
                raise Error(f"virtual environment does not exist: {venv}")
            activate = f"{venv}/bin/activate"
            if not os.path.exists(activate):
                activate = activate = f"{venv}/Scripts/activate"
                if not os.path.exists(activate):
                    raise Error(f"cannot find activate script for venv {venv}")

        cmd_file = None        
        if cmd.find('\n') > -1:
            cmds1 = str.lstrip(textwrap.dedent(cmd))
            cmds = list(filter(lambda s: str.lstrip(s) != '', cmds1.split("\n")))
            if venv != '':
                cmds = [f". {activate}"] + cmds
            cmd = "; ".join(cmds)
            cmd_for_log = cmd
            if sudo is not False:
                cmd_file = paella.tempfilepath()
                paella.fwrite(cmd_file, cmd)
                cmd = f"bash -l {cmd_file}"
                cmd_for_log = f"sudo {cmd_for_log}"
        else:
            if venv != '':
                cmd = f"{{ . {activate}; {cmd}; }}"
            cmd_for_log = cmd

        if sudo is not False:
            if sudo == 'file':
                cmd_file = paella.tempfilepath()
                paella.fwrite(cmd_file, cmd)
                cmd = f"sudo bash -l {cmd_file}"
                cmd_for_log = f"sudo {cmd_for_log}"
            else:
                cmd = f"sudo bash -l -c '{cmd}'"

        if echo:
            print(cmd)
        if cmd_file is not None:
            print(f"# {cmd_for_log}")
        sys.stdout.flush()
        
        if nop is None:
            nop = self.nop
        if nop:
            return

        if not output:
            fd, temppath = tempfile.mkstemp()
            os.close(fd)
            cmd = f"{{ {cmd}; }} >{temppath} 2>&1"
        if at is None:
            rc = subprocess.call(bash.split(' ') + ["-l", "-e", "-c", cmd])
        else:
            with cwd(at):
                rc = subprocess.call(bash.split(' ') + ["-l", "-e", "-c", cmd])
        if rc > 0:
            if not output:
                if output.on_error():
                    os.system(f"cat {temppath}")
                eprint("command failed: " + cmd_for_log)
                sys.stderr.flush()
        if not output:
            os.remove(temppath)
        if cmd_file is not None:
            os.remove(cmd_file)
        if rc > 0 and not _try:
            sys.exit(1)
        return rc

    def has_command(self, cmd):
        return Runner.is_command(cmd)

    @staticmethod
    def is_command(cmd):
        if platform_os() != 'windows':
            return os.system(f"command -v {cmd} > /dev/null") == 0
        try:
            sh(f"command -v {cmd} > /dev/null")
            return True
        except:
            return False
