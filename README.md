# CONTAINER EXAMPLES

Run `./getsrc.sh` first

## BUILD CONTAINER

`./build.sh hplmxp`

## RUN CONTAINER

`./run.sh`

## TESTS

Each test lives in `examples/<name>/` (e.g. `examples/hplmxp/`) with its own
`build.sh`/`run.sh`, Dockerfiles, and `common/`. Shared code lives in `util`
at the repo root; `image_files/` and `results/<name>/` are also shared/root-level.

Dispatch from the root:

``` bash
./build.sh hplmxp [KEY=VALUE ...]
./run.sh hplmxp [KEY=VALUE ...]
```

Or run a test's scripts directly:

``` bash
examples/hplmxp/build.sh [KEY=VALUE ...]
examples/hplmxp/run.sh [KEY=VALUE ...]
```

To add a test, create `examples/<name>/build.sh` and `run.sh` following the
existing `hplmxp` scripts as a template.
