#!/bin/bash

IOTRACER_PATH="../../bcc_iotracer.py"

mongosh < ycsb_datadir/drop_db

python2 ycsb_datadir/bin/ycsb load mongodb -s -P ycsb_datadir/workloads/workloadc -p mongodb.url=mongodb://localhost:27017/ycsb

exec_count=5
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

kernel_api=o

sudo python3 $IOTRACER_PATH -t Thread-,conn,java,mongod -l vfb -k $kernel_api > trace_ycsb_kernel_output &
sleep 5

rm ycsb_results_kernel_output

for (( i = 0; i < $exec_count; i++)); do
    sudo sync; echo 3 > /proc/sys/vm/drop_caches 
    python2 ycsb_datadir/bin/ycsb run mongodb -s -P ycsb_datadir/workloads/workloadc -p mongodb.url=mongodb://localhost:27017/ycsb >> ycsb_results_kernel_output
    echo -e "\n-------------------------------------------------------------------\n" >> ycsb_results_kernel_output
done    

pkill python3

kernel_api=s

sudo python3 $IOTRACER_PATH -t Thread-,conn,java,mongod -l vfb -k $kernel_api > trace_ycsb_kernel_submit &
sleep 5

rm ycsb_results_kernel_submit

for (( i = 0; i < $exec_count; i++)); do
    sudo sync; echo 3 > /proc/sys/vm/drop_caches 
    python2 ycsb_datadir/bin/ycsb run mongodb -s -P ycsb_datadir/workloads/workloadc -p mongodb.url=mongodb://localhost:27017/ycsb >> ycsb_results_kernel_submit
    echo -e "\n-------------------------------------------------------------------\n" >> ycsb_results_kernel_submit
done    

pkill python3


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