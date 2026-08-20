# CONTAINER EXAMPLES

Run `./getsrc.sh` first.

## BUILD AND RUN CONTAINER

``` bash
./build.sh TEST_NAME KEY=VALUE
```

TEST_NAME=hplmxp or hpcg

The other argument can be `TYPE=cpu,nvidia,amd`. Will default to nvidia or amd if those GPUs are available. TYPE=cpu will override that.

``` bash
./run.sh TEST_NAME KEY=VALUE RUN_ARGS
```

The `run.sh` script takes the same args as build and also test specific args.
Descriptions of those args coming soon.
Look at the test directory run script for details (i.e. lines like: `${NXi:=560}`).

Runs can also be launched directly from the test directory.

``` bash
examples/hplmxp/run.sh [KEY=VALUE ...]
```

## STRUCTURE

Each test lives in `examples/<name>/` (e.g. `examples/hplmxp/`) with its own
`build.sh`/`run.sh`, Dockerfiles, and `common/`. Shared code lives in `util`
at the repo root; `image_files/` and `results/<name>/` are also shared/root-level.
