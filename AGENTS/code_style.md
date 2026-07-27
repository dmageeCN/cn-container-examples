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
3. When in doubt make a piece of logic a function in util.sh, even if there's only one use case for it at the moment.
4. When in doubt, export the variable. Globals are great!
5. All command line options are exported via util.sh:setvars.
    - The default options are set only if the variable is not set on the command line or in the environment.
    - The `setvar` function occurs first, then hard override any options for this particular test, then set the universal (for all tests) defaults, then set specific defaults for this test.
6. If you may want to toggle a value in the future make it a variable with a default in util.sh:universal_opts (or in the test script itself if it's specific to a test).
7. Tests should write to the logs defined by 'set_logs'. It's preferred to tee the output to the terminal; but, if the test must send it's output to a temporary file, use RUN_TMP and >.
8. No shell code should use syntax that is exclusive to bash. It should be portable between bash and zsh.
