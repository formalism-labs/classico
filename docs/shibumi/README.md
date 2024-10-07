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
### When to use bash?
One might consider replacing bash with Python a no-brainer. Trying to pull this off in practice proves to be harder than expected, and bash proves itself as an agile tool despite having a weird syntax at times. `bashdb` also helps very much.

As a rule of thumb, I would suggest moving away from bash when encountring a need for an array or a dictionary, and staying with bash when doing job control.

#### Use of modern shells (zsh/fish) for scripting
Unless implementing shell-specific features (e.g. prompt manipulations) I'd recommend against using any other shell than bash. One of the greatest assets of bash is its beign ubiquitous across systems and its trivial configuration, making it consistent.
When requirig something more powerfull than bash I'd recommend going with Python.

### Which bash version is required?
Most of the code in Shibumi works with bash 4.x, and will of course work with bash 5.x which is the most common now.

### Beyond bash - GNU utilities

### Bash in Windows

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
