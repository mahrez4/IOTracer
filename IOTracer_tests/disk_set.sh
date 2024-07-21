#!/bin/bash

if [  ! -z  "$1" ]; then
    if [[ "$1" == "sda" ]]; then
        traced_path='IOTRACER_PATH="/home/ensta/IOTracer/bcc_iotracer.py"'
        sed -i "s|IOTRACER_PATH=\"../../bcc_iotracer.py\"|$traced_path|" *_tests/run_benchmarks*
        sed -i "s/^disk=.*/disk=$1/" run_alltests.sh
        db_path=/media/SSDSM87-S2D4NYAG905047/mongodb
        sed -i "s|dbPath: .*|dbPath: $db_path|" /etc/mongod.conf
        systemctl restart mongod
    fi
    if [[ "$1" == "sdb" ]]; then
        traced_path='IOTRACER_PATH="/home/ensta/IOTracer/bcc_iotracer.py"'
        sed -i "s|IOTRACER_PATH=\"../../bcc_iotracer.py\"|$traced_path|" *_tests/run_benchmarks*
        sed -i "s/^disk=.*/disk=$1/" run_alltests.sh
        db_path=/media/HDD/mongodb
        sed -i "s|dbPath: .*|dbPath: $db_path|" /etc/mongod.conf
        systemctl restart mongod
    fi
    if [[ "$1" == "sdc" ]]; then
        traced_path='IOTRACER_PATH="/home/ensta/IOTracer/bcc_iotracer.py"'
        sed -i "s|IOTRACER_PATH=\"../../bcc_iotracer.py\"|$traced_path|" *_tests/run_benchmarks*
        sed -i "s/^disk=.*/disk=$1/" run_alltests.sh
        db_path=/media/SSD850-S251NXAGA20303P/mongodb
        sed -i "s|dbPath: .*|dbPath: $db_path|" /etc/mongod.conf
        systemctl restart mongod
    fi
    if [[ "$1" == "sdd" ]]; then
        traced_path='IOTRACER_PATH="/home/ensta/IOTracer/bcc_iotracer.py"'
        sed -i "s|IOTRACER_PATH=\"../../bcc_iotracer.py\"|$traced_path|" *_tests/run_benchmarks*
        sed -i "s/^disk=.*/disk=$1/" run_alltests.sh
        db_path=/media/SSDSM87-S2D4NYAG905047/mongodb
        sed -i "s|dbPath: .*|dbPath: $db_path|" /etc/mongod.conf
        systemctl restart mongod
    fi
fi