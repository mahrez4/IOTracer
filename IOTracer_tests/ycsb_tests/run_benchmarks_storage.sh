#!/bin/bash

IOTRACER_PATH="../../bcc_iotracer.py"

mongosh < ycsb_datadir/drop_db

python2 ycsb_datadir/bin/ycsb load mongodb -s -P ycsb_datadir/workloads/workloadc -p mongodb.url=mongodb://localhost:27017/ycsb

exec_count=5
if [ ! -z "$1" ]; then
    exec_count=$1
fi

##########

rm ycsb_results_storage_notracing

for (( i = 0; i < $exec_count; i++)); do
    sudo sync; echo 3 > /proc/sys/vm/drop_caches 
    python2 ycsb_datadir/bin/ycsb run mongodb -s -P ycsb_datadir/workloads/workloadc -p mongodb.url=mongodb://localhost:27017/ycsb >> ycsb_results_storage_notracing
    echo -e "\n-------------------------------------------------------------------\n" >> ycsb_results_storage_notracing
done  

##########

storage_device=d
rm ycsb_results_storage_disk

for (( i = 0; i < $exec_count; i++)); do
    sudo python3 $IOTRACER_PATH -t Thread-,conn,java,mongod  -l vfb -s $storage_device > traces_ycsb/ringbuffer/trace_ycsb_storage_disk_$i &
    sleep 5
    sudo sync; echo 3 > /proc/sys/vm/drop_caches 
    python2 ycsb_datadir/bin/ycsb run mongodb -s -P ycsb_datadir/workloads/workloadc -p mongodb.url=mongodb://localhost:27017/ycsb >> ycsb_results_storage_disk
    echo -e "\n-------------------------------------------------------------------\n" >> ycsb_results_storage_disk
    pkill python3
done    

##########

storage_device=r
rm ycsb_results_storage_ram

for (( i = 0; i < $exec_count; i++)); do
    sudo python3 $IOTRACER_PATH -t Thread-,conn,java,mongod  -l vfb -s $storage_device > /tmp/trace_ycsb_storage_ram_$i &
    sleep 5
    sudo sync; echo 3 > /proc/sys/vm/drop_caches 
    python2 ycsb_datadir/bin/ycsb run mongodb -s -P ycsb_datadir/workloads/workloadc -p mongodb.url=mongodb://localhost:27017/ycsb >> ycsb_results_storage_ram
    echo -e "\n-------------------------------------------------------------------\n" >> ycsb_results_storage_ram
    pkill python3
done    



## Output file for storing extracted run times
output_file="run_times_storage.csv"

# Remove the output file if it exists
rm -rf "$output_file"

# Write header to the output file
header="Trace storage"
for (( i = 0; i < $exec_count; i++ )); do
    header="$header,run_$i"
done
echo "$header" > "$output_file"


for file in ycsb_results_storage*; do
    echo "Processing file: $file"
    api=$(echo "$file" | awk -F '_' '{print $4}')
    runs=$(grep "\[OVERALL\], RunTime(ms)," $file | awk -F", " '{print $3}'| sed -z 's/\n/,/g' | sed 's/\(.*\),/\1 /' )
    echo "$api,$runs" >> "$output_file"
done

echo "Run times extracted to $output_file"