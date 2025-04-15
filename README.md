<p align="center">
  <img src="docs/classico.jpg" alt="Logo" />
</p>
<h1 align="center">Classico</h1>
<h3 align="center">Library cluster of automation facilities</h3>
<p><br></p>

### What is Classico?

**Classico** is a set of tools that help developers write scripts for automation needs of projects (e.g. build, testing, benchmarking, packaging, CI) across platforms.

### Installation
Clone the Classico repo into your codebase.

### Classico in bash
Start your script as follows, modifying the relative `CLASSICO` path specification if needed.
```bash
#!/bin/bash

PROGNAME="${BASH_SOURCE[0]}"
HERE="$(cd "$(dirname "$PROGNAME")" &>/dev/null && pwd)"
CLASSICO=$(cd $HERE/.. && pwd)
. $CLASSICO/shibumi/defs
```

### Classico  in Python
Start your script as follows, modifying the relative Paella root path specification if needed.
```python
#!/usr/bin/env python3

import os, sys

HERE = os.path.dirname(__file__)
ROOT = os.path.abspath(os.path.join(HERE, ".."))
sys.path.insert(0, ROOT)
import paella  # noqa: F401
```

### Design choices

The scripts or tools written with **Classico** are typically part of the development infrastructure, thus agility is generally preferred over rigor.

Classico tools are implemented using different tools (mostly, bash any Python), which may invoke one another, rather than implementing the full functionality using a single tool. This in turn imposes restrictions on the distribution method: package managers (`pip`, `npm`, etc) are avoided, and Classico code is delivered in source form. Classico may however require installation of packages of tools it uses, typically inside sandboxes (i.e., Python's virtual environment).

#### Platforms

Operating on various version of various operating systems on various hardware architectures calls for a platform conceptual model. Our platform concept is built upon functional traits:
* Installer semantics: kind of system installer (e.g. apt, dnf) and naming of packages,
* Binary compatibility: sysems of the same platform should be able to run same binary files.
We introduce a one-word term (`osnick`) that encapsulates the these qualities on the OS side, and along the system architecture forms our concept of platform.

#### Functionality across languages

The general desire is to make useful idioms (like job runners) available across languages that Classico supports. Howerver, this is a rolling effort. Most likly new features will appear in Paella, then find their way into the other libs.

### Components

**Scripts:**

[bin](docs/bin.md): scripts for direct execution

[sbin](docs/sbin.md): Administrative scripts (for setting up Classico environment)

**Libraries:**

[Bento](docs/bento/README.md): Ruby library

[Cetara](cetara/README.md): C/C++ code

[Golani](docs/golani.md): Golang library

[Jasmine](docs/jasmine/README.md): Javascript/TypeScript library

[Paella](docs/paella/README.md): Python library

[Posh](docs/posh.md): PowerShell library

[Shibumi](docs/shibumi/README.md): Bash library

[WD40](docs/wd40.md): Rust library

**Build tools:**

[mk](docs/mk/README.md): GNU Make-based build framework

[cmake](docs/cmake.md): CMake code


### Conventions

#### Script arguments
Bash scripts use the conventional "script prefix arguments as environment variables", with a static code block that describes the available option (with flags taking 0/1 values):
`ARG=val FLAG=1 ./script`
This allows to pass arguments between scripts via context. As said, more agile, less rigorous.
Python and Ruby scripts utilize the conventional wizdon of argparse and the like. However, env var args can be still be used.
makefiles use their natural postfix argument specification, which is similar to the bash model.

### Use cases

#### `get*` scripts

#### Installing build requirements

#### Runners

#### Bash scripts

#### Python scripts

#### Ruby scripts

#### Automation in Windows

#### Enabling interactive tools
