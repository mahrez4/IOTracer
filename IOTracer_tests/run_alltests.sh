#!/bin/bash
script_path="$( cd -- "$(dirname "$0")" >/dev/null 2>&1 ; pwd -P )"
cd $script_path

for dir in *_tests; do
    echo -e "\n  **** Working on $dir   ****\n"
    cd $script_path/$dir
    if [ ! -z "$1" ]; then
        echo -e "Execution count: $1"
        for bench in run_benchmarks*; do
            sed -i "s/exec_count=5/exec_count=$1/g" $bench
        done
    fi
    echo -e "\n   **** Starting Ringbuffer benchmark in $dir   ****\n"
    ./run_benchmarks_ringbuffer.sh
    echo -e "\n   **** Starting Userspace API benchmark in $dir   ****\n"
    ./run_benchmarks_userspaceapi.sh
    echo -e "\n   **** Starting Kernel API benchmark. in $dir   ****\n"
    ./run_benchmarks_kernelapi.sh 
    echo -e "\n   **** Starting Storage benchmark. in $dir   ****\n"
    ./run_benchmarks_storage.sh
    if [ ! -z "$1" ]; then
        for bench in run_benchmarks*; do
            sed -i "s/exec_count=$1/exec_count=5/g" $bench
        done
    fi
done