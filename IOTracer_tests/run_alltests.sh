#!/bin/bash
script_path="$( cd -- "$(dirname "$0")" >/dev/null 2>&1 ; pwd -P )"
cd $script_path

RED='\033[0;31m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color (reset)

show_help() {
    echo -e "Usage: ./run_alltests.sh [exec count] [directory of tests]"
    echo -e "Example: ./run_alltests.sh 10 fio_tests ---- run fio_tests with 10 executions"
    echo -e "if you don't specify the directory all tests are ran"
}



if [[ "$1" == "--help" || "$1" == "-h" ]]; then
    show_help
    exit 0
fi

if [ -z "$1" ] && [ -z "$2"]; then
    for dir in *_tests; do
        echo -e "\n${CYAN}  **** Working on $dir   ****${NC}\n"
        cd $script_path/$dir
        rm -rf traces_*/*/trace_*
        echo -e "\n${RED}   **** Starting Ringbuffer benchmark in $dir   ****${NC}\n"
        ./run_benchmarks_ringbuffer.sh
        echo -e "\n${RED}   **** Starting Userspace API benchmark in $dir   ****${NC}\n"
        ./run_benchmarks_userspaceapi.sh
        echo -e "\n${RED}   **** Starting Kernel API benchmark. in $dir   ****${NC}\n"
        ./run_benchmarks_kernelapi.sh 
        echo -e "\n${RED}   **** Starting Storage benchmark. in $dir   ****${NC}\n"
        ./run_benchmarks_storage.sh
    done
fi

if [ ! -z "$1" ] && [ -z "$2" ]; then
    for dir in *_tests; do
        echo -e "\n${CYAN}  **** Working on $dir   ****${NC}\n"
        cd $script_path/$dir
        rm -rf traces_*/*/trace_*
        echo -e "\n${RED}   **** Starting Ringbuffer benchmark in $dir   ****${NC}\n"
        ./run_benchmarks_ringbuffer.sh $1 
        echo -e "\n${RED}   **** Starting Userspace API benchmark in $dir   ****${NC}\n"
        ./run_benchmarks_userspaceapi.sh $1
        echo -e "\n${RED}   **** Starting Kernel API benchmark. in $dir   ****${NC}\n"
        ./run_benchmarks_kernelapi.sh $1
        echo -e "\n${RED}   **** Starting Storage benchmark. in $dir   ****${NC}\n"
        ./run_benchmarks_storage.sh $1
    done
fi

if [ ! -z "$1" ] && [ ! -z "$2" ]; then
    dir=$2
    echo -e "\n${CYAN}  **** Working on $dir   ****${NC}\n"
    cd $script_path/$dir
    rm -rf traces_*/*/trace_*
    echo -e "\n${RED}   **** Starting Ringbuffer benchmark in $dir   ****${NC}\n"
    ./run_benchmarks_ringbuffer.sh $1 
    echo -e "\n${RED}   **** Starting Userspace API benchmark in $dir   ****${NC}\n"
    ./run_benchmarks_userspaceapi.sh $1
    echo -e "\n${RED}   **** Starting Kernel API benchmark. in $dir   ****${NC}\n"
    ./run_benchmarks_kernelapi.sh $1
    echo -e "\n${RED}   **** Starting Storage benchmark. in $dir   ****${NC}\n"
    ./run_benchmarks_storage.sh $1
fi