#!/bin/bash

IOTRACER_PATH="../../bcc_iotracer.py"

mongosh < ycsb_datadir/drop_db

python2 ycsb_datadir/bin/ycsb load mongodb -s -P ycsb_datadir/workloads/workloadc -p mongodb.url=mongodb://localhost:27017/ycsb

block_device=""
exec_count=5
if [ ! -z "$2" ]; then
   block_device="-dev $2"
fi

if [ ! -z "$1" ]; then
    exec_count=$1
fi

########## 

##set ring buffer size in number of pages 32:128KB, 1024:4MB,32768:128MB,262144:1G

##no tracing 

rm ycsb_results_ringbuf_notracing

for (( i = 0; i < $exec_count; i++)); do
    sudo sync; echo 3 > /proc/sys/vm/drop_caches 
    python2 ycsb_datadir/bin/ycsb run mongodb -s -P ycsb_datadir/workloads/workloadc -p mongodb.url=mongodb://localhost:27017/ycsb >> ycsb_results_ringbuf_notracing
    echo -e "\n-------------------------------------------------------------------\n" >> ycsb_results_ringbuf_notracing
done  

##########

ringbuf_size=32
rm ycsb_results_ringbuf_128kb

for (( i = 0; i < $exec_count; i++)); do
    sudo python3 $IOTRACER_PATH -t Thread-,conn,java,mongod -l b $block_device -size $ringbuf_size > traces_ycsb/ringbuffer/trace_ycsb_ringbuf_128kb_$i &
    sleep 4
    sudo sync; echo 3 > /proc/sys/vm/drop_caches 
    python2 ycsb_datadir/bin/ycsb run mongodb -s -P ycsb_datadir/workloads/workloadc -p mongodb.url=mongodb://localhost:27017/ycsb >> ycsb_results_ringbuf_128kb
    echo -e "\n-------------------------------------------------------------------\n" >> ycsb_results_ringbuf_128kb
    sleep 1; pkill python3; sleep 1;
done    

##########

ringbuf_size=1024
rm ycsb_results_ringbuf_4mb

for (( i = 0; i < $exec_count; i++)); do
    sudo python3 $IOTRACER_PATH -t Thread-,conn,java,mongod -l b $block_device -size $ringbuf_size > traces_ycsb/ringbuffer/trace_ycsb_ringbuf_4mb_$i &
    sleep 4
    sudo sync; echo 3 > /proc/sys/vm/drop_caches 
    python2 ycsb_datadir/bin/ycsb run mongodb -s -P ycsb_datadir/workloads/workloadc -p mongodb.url=mongodb://localhost:27017/ycsb >> ycsb_results_ringbuf_4mb
    echo -e "\n-------------------------------------------------------------------\n" >> ycsb_results_ringbuf_4mb
    sleep 1; pkill python3; sleep 1;
done    

##########

ringbuf_size=32768
rm ycsb_results_ringbuf_128mb

for (( i = 0; i < $exec_count; i++)); do
    sudo python3 $IOTRACER_PATH -t Thread-,conn,java,mongod -l b $block_device -size $ringbuf_size > traces_ycsb/ringbuffer/trace_ycsb_ringbuf_128mb_$i &
    sleep 4
    sudo sync; echo 3 > /proc/sys/vm/drop_caches 
    python2 ycsb_datadir/bin/ycsb run mongodb -s -P ycsb_datadir/workloads/workloadc -p mongodb.url=mongodb://localhost:27017/ycsb >> ycsb_results_ringbuf_128mb
    echo -e "\n-------------------------------------------------------------------\n" >> ycsb_results_ringbuf_128mb
    sleep 1; pkill python3; sleep 1;
done    

##########

ringbuf_size=262144
rm ycsb_results_ringbuf_1gb

for (( i = 0; i < $exec_count; i++)); do
    sudo python3 $IOTRACER_PATH -t Thread-,conn,java,mongod -l b $block_device -size $ringbuf_size > traces_ycsb/ringbuffer/trace_ycsb_ringbuf_1gb_$i &
    sleep 4
    sudo sync; echo 3 > /proc/sys/vm/drop_caches 
    python2 ycsb_datadir/bin/ycsb run mongodb -s -P ycsb_datadir/workloads/workloadc -p mongodb.url=mongodb://localhost:27017/ycsb >> ycsb_results_ringbuf_1gb
    echo -e "\n-------------------------------------------------------------------\n" >> ycsb_results_ringbuf_1gb
    sleep 1; pkill python3; sleep 1;
done    


## Output file for storing extracted run times
output_file="run_times_ringbufsize.csv"

# Remove the output file if it exists
rm -rf "$output_file"

# Write header to the output file
header="Ringbuffer size"
for (( i = 0; i < $exec_count; i++ )); do
    header="$header,run_$i"
done
echo "$header" > "$output_file"


for file in ycsb_results_ringbuf*; do
    echo "Processing file: $file"
    api=$(echo "$file" | awk -F '_' '{print $4}')
    runs=$(grep "\[OVERALL\], RunTime(ms)," $file | awk -F", " '{print $3}'| sed -z 's/\n/,/g' | sed 's/\(.*\),/\1 /' )
    echo "$api,$runs" >> "$output_file"
done

echo "Run times extracted to $output_file"