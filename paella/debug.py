
import os
from .platform import platform_os

#----------------------------------------------------------------------------------------------

env_bb = os.environ.get('BB', '')
if platform_os() == 'windows' and env_bb == '1':
    env_bb = 'pdb'
if env_bb == '1':
    try:
        from pudb import set_trace as bb  # type: ignore[import-untyped]
    except ImportError:
        try:
            from ipdb import set_trace as bb  # type: ignore[import-untyped, import-not-found]
        except ImportError:
            from pdb import set_trace as bb
elif env_bb == 'pudb':
    from pudb import set_trace as bb
elif env_bb == 'pdb':
    from pdb import set_trace as bb
elif env_bb == 'ipdb':
    from ipdb import set_trace as bb
else:
    def bb(): pass

#----------------------------------------------------------------------------------------------
