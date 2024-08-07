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

rm ycsb_results_kernel_notracing

for (( i = 0; i < $exec_count; i++)); do
    sudo sync; echo 3 > /proc/sys/vm/drop_caches 
    python2 ycsb_datadir/bin/ycsb run mongodb -s -P ycsb_datadir/workloads/workloadc -p mongodb.url=mongodb://localhost:27017/ycsb >> ycsb_results_kernel_notracing
    echo -e "\n-------------------------------------------------------------------\n" >> ycsb_results_kernel_notracing
done  

##########

kernel_api=o
rm ycsb_results_kernel_output

for (( i = 0; i < $exec_count; i++)); do
    sudo python3 $IOTRACER_PATH -t Thread-,conn,java,mongod -l b $block_device -k $kernel_api > traces_ycsb/kernel_api/trace_ycsb_kernel_output_$i &
    sleep 4
    sudo sync; echo 3 > /proc/sys/vm/drop_caches 
    python2 ycsb_datadir/bin/ycsb run mongodb -s -P ycsb_datadir/workloads/workloadc -p mongodb.url=mongodb://localhost:27017/ycsb >> ycsb_results_kernel_output
    echo -e "\n-------------------------------------------------------------------\n" >> ycsb_results_kernel_output
    sleep 1; pkill python3; sleep 1;
done    

##########

kernel_api=s
rm ycsb_results_kernel_submit

for (( i = 0; i < $exec_count; i++)); do
    sudo python3 $IOTRACER_PATH -t Thread-,conn,java,mongod -l b $block_device -k $kernel_api > traces_ycsb/kernel_api/trace_ycsb_kernel_submit_$i &
    sleep 4
    sudo sync; echo 3 > /proc/sys/vm/drop_caches 
    python2 ycsb_datadir/bin/ycsb run mongodb -s -P ycsb_datadir/workloads/workloadc -p mongodb.url=mongodb://localhost:27017/ycsb >> ycsb_results_kernel_submit
    echo -e "\n-------------------------------------------------------------------\n" >> ycsb_results_kernel_submit
    sleep 1; pkill python3; sleep 1;
done    


# Output file for storing extracted run times
output_file="run_times_kernel_api.csv"

# Remove the output file if it exists
rm -rf "$output_file"

# Write header to the output file
header="Kernel Api"
for (( i = 0; i < $exec_count; i++ )); do
    header="$header,run_$i"
done
echo "$header" > "$output_file"


for file in ycsb_results_kernel*; do
    echo "Processing file: $file"
    api=$(echo "$file" | awk -F '_' '{print $4}')
    runs=$(grep "\[OVERALL\], RunTime(ms)," $file | awk -F", " '{print $3}'| sed -z 's/\n/,/g' | sed 's/\(.*\),/\1 /' )
    echo "$api,$runs" >> "$output_file"
done

echo "Run times extracted to $output_file"