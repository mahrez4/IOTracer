#!/usr/bin/sh

IOTRACER_PATH="/home/mhrz/pfe/tools/IOTracer/bcc_iotracer.py"

traced_path="/home/mhrz/pfe/tools/testfile"

fio_config="/home/mhrz/pfe/tools/fio_config.fio"

inode=`stat -c '%i' $traced_path`

rm fio_results_storage_notracing

for (( i = 0; i < 20; i++)); do
    sudo sync; echo 3 > /proc/sys/vm/drop_caches 
    fio $fio_config >> fio_results_storage_notracing
    echo \n------------------------------------------\n >> fio_results_storage_notracing
done  

storage_device=d

sudo python $IOTRACER_PATH -t fio --file -i $inode -l b -s $storage_device > trace_output_bcc &
sleep 5

rm fio_results_storage_disk

for (( i = 0; i < 20; i++)); do
    sudo sync; echo 3 > /proc/sys/vm/drop_caches 
    fio $fio_config >> fio_results_storage_disk
    echo \n------------------------------------------\n >> fio_results_storage_disk
done    

pkill python

storage_device=r

sudo python $IOTRACER_PATH -t fio --file -i $inode -l b -s > /tmp/trace_output_bcc &
sleep 5

rm fio_results_storage_ram

for (( i = 0; i < 20; i++)); do
    sudo sync; echo 3 > /proc/sys/vm/drop_caches 
    fio $fio_config >> fio_results_storage_ram
    echo \n------------------------------------------\n >> fio_results_storage_ram
done    

pkill python

## Output file for storing extracted run times
output_file="run_times_storage.csv"

rm -rf $output_file
# Write header to the output file
header="API"
for (( i = 0; i < 20; i++)); do
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