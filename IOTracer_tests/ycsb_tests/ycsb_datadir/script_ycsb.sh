#!/bin/bash
rm watch_ps_ycsb

lsof -i > watch_lsof_ycsb &
#watch -n 0.1 'ps -ef | tail -n 20 | tee --append watch_ps_ycsb; echo -------------------------------------------------------- >> watch_ps_ycsb' &
sudo bpftrace ../IOTracer/iotracer.bt > trace_output &
sleep 5


python2 ./bin/ycsb load mongodb -threads 4 -s -P workloads/workloadc -p mongodb.url=mongodb://localhost:27017/db_ycsb

python2 ./bin/ycsb run mongodb -threads 4 -s -P workloads/workloadc -p mongodb.url=mongodb://localhost:27017/db_ycsb

pkill watch
pkill bpftrace
pkill lsof
cat trace_output | grep -E "mongod|conn|Thread" > trace_output_ycsb

gedit watch_lsof_ycsb &
gedit watch_ps_ycsb
gedit trace_output_ycsb