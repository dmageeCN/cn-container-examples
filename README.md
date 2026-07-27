# CONTAINER EXAMPLES

## BUILD CONTAINER

``` bash
CNTR_VER=2.0
cntr_name=cn-amd:v${CNTR_VER}
cntr_name_apptainer=$(echo $k | tr ':' '_')
image_file="${THISDIR}/image_files/${cntr_name_apptainer}.sif"
docker build -t ${cntr_name} -f Dockerfile.amd --progress=plain .
apptainer build ${image_file} docker-daemon://${cntr_name}
```

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
