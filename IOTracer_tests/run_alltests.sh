#!/bin/bash
script_path="$( cd -- "$(dirname "$0")" >/dev/null 2>&1 ; pwd -P )"
cd $script_path

for dir in *_tests; do
    echo "\n   **** Working on $dir   ****\n"
    cd $script_path/$dir
    echo "\n    **** Starting Ringbuffer benchmark in $dir   ****\n"
    ./run_benchmarks_ringbuffer.sh
    echo "\n    **** Starting Userspace API benchmark in $dir   ****\n"
    ./run_benchmarks_userspaceapi.sh
    echo "\n    **** Starting Kernel API benchmark. in $dir   ****\n"
    ./run_benchmarks_kernelapi.sh; 
    echo "\n    **** Starting Storage benchmark. in $dir   ****\n"
    ./run_benchmarks_storage.sh
done
