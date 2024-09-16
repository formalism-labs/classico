# Classico

![logo](docs/classico.jpg)

### Library cluster of automation facilities

Classico is a set of tools that help developers write scripts for automation needs of projects (e.g. build, testing, benchmarking, packaging, CI) across platforms.

### Installation
Clone the Classico repo into your codebase.

### Classico in bash
Start your script as follows, modifying the relative CLASSICO path specification if needed.
```
#!/bin/bash

PROGNAME="${BASH_SOURCE[0]}"
HERE="$(cd "$(dirname "$PROGNAME")" &>/dev/null && pwd)"
CLASSICO=$(cd $HERE/.. && pwd)
. $CLASSICO/shibumi/defs
```

### Classico  in Python
Start your script as follows, modifying the relative Paella root path specification if needed.
```
#!/usr/bin/env python3

import os, sys

HERE = os.path.dirname(__file__)
ROOT = os.path.abspath(os.path.join(HERE, ".."))
sys.path.insert(0, ROOT)
import paella  # noqa: F401
```

### Design choices

The scripts or tools written with Classico are typically part of the development infrastructure, thus agility is generally preferred over rigor.

Classico tools are implemented using different tools (mostly, bash any Python), which may invoke one another, rather than implementing the full functionality using a single tool. This in turn imposes restrictions on the distribution method: package managers (`pip`, `npm`, etc) are avoided, and Classico code is delivered in source form. Classico may however require installation of packages of tools it uses, typically inside sandboxes (i.e., Python's virtual environment).

#### Platforms

Operating on various version of various operating systems on various hardware architectures calls for a platform conceptual model. Our platform concept is built upon functional traits:
* Installer semantics: kind of system installer (e.g. apt, dnf) and naming of packages,
* Binary compatibility: sysems of the same platform should be able to run same binary files.
We introduce a one-word term (`osnick`) that encapsulates the these qualities on the OS side, and along the system architecture forms our concept of platform.

#### Functionality across languages

The general desire is to make useful idioms (like job runners) available across languages that Classico supports. Howerver, this is a rolling effort. Most likly new features will appear in Paella, then find their way into the other libs.

### Components

[bin](docs/bin.md): scripts for direct execution

[Shibumi](docs/shibumi/README.md): Bash code

[Paella](docs/paella/README.md): Python automation library

[Bento](docs/bento/README.md): Ruby automation library

[Julius](docs/julius/README.md): Node.js/TypeScript automation library

[Cetara](cetara/README.md): C/C++ code

[WD40](docs/wd40.md) Rust code

[mk](docs/mk/README.md): GNU Make-based build framework

[cmake](docs/cmake.md): CMake code

[sbin](docs/sbin.md): administrative scripts (for setting up Classico environment)

### Conventions

#### Script arguments
Bash scripts use the conventional "script prefix arguments as environment variables", with a static code block that describes the available option (with flags taking 0/1 values):
`ARG=val FLAG=1 ./script`
This allows to pass arguments between scripts via context. As said, more agile, less rigorous.
Python and Ruby scripts utilize the conventional wizdon of argparse and the like. However, env var args can be still be used.
makefiles use their natural postfix argument specification, which is similar to the bash model.

### Use cases

#### `get*` scripts

#### Installing rebuild requirements

#### Bash scripts

#### Python scripts

#### Ruby scripts

#### Automation in Windows

#### Enabling interactive tools
