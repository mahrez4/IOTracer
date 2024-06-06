#!/bin/bash
SCRIPTPATH="$( cd -- "$(dirname "$0")" >/dev/null 2>&1 ; pwd -P )"

cd $SCRIPTPATH
for dir in *_tests; do
    echo "Working on $dir"
    cd $dir
    ./run_benchmarks_ringbuffer.sh; ./run_benchmarks_userspaceapi.sh; ./run_benchmarks_kernelapi.sh; ./run_benchmarks_storage.sh
done
