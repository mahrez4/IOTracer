#!/usr/bin/sh

IOTRACER_PATH="../../bcc_iotracer.py"

mongosh < ycsb_datadir/drop_db

python2 ycsb_datadir/bin/ycsb load mongodb -s -P ycsb_datadir/workloads/workloadc -p mongodb.url=mongodb://localhost:27017/ycsb

exec_count=4

########## 

##set ring buffer size in number of pages 32:128KB, 1024:4MB,32768:128MB,262144:1G

##no tracing 

rm ycsb_results_ringbuf_notracing

for (( i = 0; i < $exec_count; i++)); do
    sudo sync; echo 3 > /proc/sys/vm/drop_caches 
    python2 ycsb_datadir/bin/ycsb run mongodb -s -P ycsb_datadir/workloads/workloadc -p mongodb.url=mongodb://localhost:27017/ycsb >> ycsb_results_ringbuf_notracing
    echo \n------------------------------------------\n >> ycsb_results_ringbuf_notracing
done  

ringbuf_size=32
sudo python $IOTRACER_PATH -t Thread-,conn,java,mongod -l vfb -size $ringbuf_size > trace_ycsb_ringbuf_128kb &
sleep 5

rm ycsb_results_ringbuf_128kb

for (( i = 0; i < $exec_count; i++)); do
    sudo sync; echo 3 > /proc/sys/vm/drop_caches 
    python2 ycsb_datadir/bin/ycsb run mongodb -s -P ycsb_datadir/workloads/workloadc -p mongodb.url=mongodb://localhost:27017/ycsb >> ycsb_results_ringbuf_128kb
    echo \n------------------------------------------\n >> ycsb_results_ringbuf_128kb
done    

pkill python

ringbuf_size=1024

sudo python $IOTRACER_PATH -t Thread-,conn,java,mongod -l vfb -size $ringbuf_size > trace_ycsb_ringbuf_4mb &
sleep 5

rm ycsb_results_ringbuf_4mb

for (( i = 0; i < $exec_count; i++)); do
    sudo sync; echo 3 > /proc/sys/vm/drop_caches 
    python2 ycsb_datadir/bin/ycsb run mongodb -s -P ycsb_datadir/workloads/workloadc -p mongodb.url=mongodb://localhost:27017/ycsb >> ycsb_results_ringbuf_4mb
    echo \n------------------------------------------\n >> ycsb_results_ringbuf_4mb
done    

pkill python

ringbuf_size=32768
sudo python $IOTRACER_PATH -t Thread-,conn,java,mongod -l vfb -size $ringbuf_size > trace_ycsb_ringbuf_128mb &
sleep 5

rm ycsb_results_ringbuf_128mb

for (( i = 0; i < $exec_count; i++)); do
    sudo sync; echo 3 > /proc/sys/vm/drop_caches 
    python2 ycsb_datadir/bin/ycsb run mongodb -s -P ycsb_datadir/workloads/workloadc -p mongodb.url=mongodb://localhost:27017/ycsb >> ycsb_results_ringbuf_128mb
    echo \n------------------------------------------\n >> ycsb_results_ringbuf_128mb
done    

pkill python

ringbuf_size=262144
sudo python $IOTRACER_PATH -t Thread-,conn,java,mongod -l vfb -size $ringbuf_size > trace_ycsb_ringbuf_1gb &
sleep 5

rm ycsb_results_ringbuf_1gb

for (( i = 0; i < $exec_count; i++)); do
    sudo sync; echo 3 > /proc/sys/vm/drop_caches 
    python2 ycsb_datadir/bin/ycsb run mongodb -s -P ycsb_datadir/workloads/workloadc -p mongodb.url=mongodb://localhost:27017/ycsb >> ycsb_results_ringbuf_1gb
    echo \n------------------------------------------\n >> ycsb_results_ringbuf_1gb
done    

pkill python

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