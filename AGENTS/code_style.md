# CODE STYLE

This is how to write code for this project.

## FINDING THIS DIRECTORY

Perhaps the most important thing in any code is finding a 'North Star' directory that leads to all the necessary files and directories for running and collecting output. This is usually the directory that currently running code is found in. In bash, you should use this snippet at the top of every script to find the directory of the script is in to find all the necessary resources. Because this snippet is portable between bash and zsh.

``` bash
#!/usr/bin/env bash

export NAME=<TEST NAME> # IMB

THISFILE=${BASH_SOURCE[0]}
: ${THISFILE:=$0}

export THISDIR=$(dirname $(realpath ${THISFILE}))

```

## WRITING MY KINDA CODE

1. All command line options for these scripts are in KEY=VALUE form.
2. Every test script (and most other scripts) source `util.sh`. This contains all the defaults, functions, and vital variables for the tests.
3. When in doubt make a piece of logic a function in `util.sh`, even if there's only one use case for it at the moment.
4. When in doubt, export the variable. Globals are great!
5. All command line options are exported via util.sh:setvars.
    - The default options are set only if the variable is not set on the command line or in the environment.
    - The `setvar` function occurs first, then hard override any options for this particular test, then set the universal (for all tests) defaults, then set specific defaults for this test.
6. If you may want to toggle a value in the future make it an option with a default in util.sh:universal_opts (or in the test script itself if it's specific to a test).
    - Create this function when the number of repeated options becomes difficult to keep track of.
7. No shell code should use syntax that is exclusive to bash. It should be portable between bash and zsh.
8. Prefer python as a frontend/scripting language and post-processing language. Prefer C++ as a compiled language. Prefer bash for anything commandline related.
9. In general code should be written with an x86_64 architecture in mind.
10. If you need additional python packages, use `install/container_venv`.
