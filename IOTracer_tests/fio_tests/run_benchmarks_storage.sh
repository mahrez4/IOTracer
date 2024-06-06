#!/bin/bash

IOTRACER_PATH="../../bcc_iotracer.py"

traced_path="./fio_file"

fio_config="./fio_config.fio"

exec_count=2

########## 

rm fio_results_storage_notracing

for (( i = 0; i < $exec_count; i++)); do
    sudo sync; echo 3 > /proc/sys/vm/drop_caches 
    fio $fio_config >> fio_results_storage_notracing
    echo -e "\n-------------------------------------------------------------------\n" >> fio_results_storage_notracing
done  

inode=`stat -c '%i' $traced_path`

storage_device=d

sudo python3 $IOTRACER_PATH -t fio --file -i $inode -l b -s $storage_device > trace_fio_storage_disk &
sleep 5

rm fio_results_storage_disk

for (( i = 0; i < $exec_count; i++)); do
    sudo sync; echo 3 > /proc/sys/vm/drop_caches 
    fio $fio_config >> fio_results_storage_disk
    echo -e "\n-------------------------------------------------------------------\n" >> fio_results_storage_disk
done    

pkill python3

storage_device=r

sudo python3 $IOTRACER_PATH -t fio --file -i $inode -l b > /tmp/trace_fio_storage_ram &
sleep 5

rm fio_results_storage_ram

for (( i = 0; i < $exec_count; i++)); do
    sudo sync; echo 3 > /proc/sys/vm/drop_caches 
    fio $fio_config >> fio_results_storage_ram
    truncate -s 0 /tmp/trace_fio_storage_ram
    echo -e "\n-------------------------------------------------------------------\n" >> fio_results_storage_ram
done    

pkill python3

## Output file for storing extracted run times
output_file="run_times_storage.csv"

rm -rf $output_file
# Write header to the output file
header="Trace storage"
for (( i = 0; i < $exec_count; i++)); do
    header="$header,run_$i"
done

echo $header > "$output_file"

# Define the pattern to search for
pattern="run="

for file in fio_results_storage*; do
    echo "Processing file: $file"
    
    api=$(echo $file | awk -F '_' '{print $4}')
    runs=$(grep "$pattern" "$file" | awk -F 'run=' '{print $2}' | awk -F '-' '{print $1}' | tr '\n' ',' | sed 's/,$//')    
    echo "$api,$runs" >> "$output_file"
done

echo "Run times extracted to $output_file"