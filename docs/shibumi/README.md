# Classico / Shibumi

### Setting up Shibumi
Start your script as follows, modifying the relative CLASSICO path specification if needed.
```
#!/bin/bash

PROGNAME="${BASH_SOURCE[0]}"
HERE="$(cd "$(dirname "$PROGNAME")" &>/dev/null && pwd)"
CLASSICO=$(cd $HERE/.. && pwd)
. $CLASSICO/shibumi/defs
```
### When to use bash

### Which bash version is required?

### Debugging
Start by installing `bashdb` using `bin/getbashdb` (a console bash debugger with an interface resembling `gdb`, implemented in bash).
Invoke `bashdb` with: `bashdb ./your-script args...`
Note that the print command is `pr`.

### Error handling

### Features
* Build-in error handling
* Command runner with support for "no operation" mode (`runn`)
* Cross-platform command installer (`xinstall`)
* `profile.d`-based mechanism for automatically-executable configuration code

### Functions
`eprint`
`fatal`
`platform_os`
`platform_arch`
`platform_windows`
`runn`
`run_in_docker`
`get_profile_d`
`setup_profile_d`
`add_to_profile_d`
`read_profile_d`
`activate_python`
`xinstall`
`trim`
`is_abspath`
`fixterm`
