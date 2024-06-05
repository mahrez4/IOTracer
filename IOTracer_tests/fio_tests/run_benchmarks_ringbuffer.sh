#!/bin/bash

IOTRACER_PATH="../../bcc_iotracer.py"

traced_path="./fio_file"

fio_config="./fio_config.fio"

inode=`stat -c '%i' $traced_path`

exec_count=5

########## 

##set ring buffer size in number of pages 32:128KB, 1024:4MB,32768:128MB,262144:1G

##no tracing 

ringbuf_size=32

rm fio_results_ringbuf_notracing

for (( i = 0; i < $exec_count; i++)); do
    sudo sync; echo 3 > /proc/sys/vm/drop_caches 
    fio $fio_config >> fio_results_ringbuf_notracing
    echo -e "\n-------------------------------------------------------------------\n" >> fio_results_ringbuf_notracing
done  


sudo python3 $IOTRACER_PATH -t fio --file -i $inode -l b -size $ringbuf_size > trace_fio_ringbuf_128kb &
sleep 5

rm fio_results_ringbuf_128kb

for (( i = 0; i < $exec_count; i++)); do
    sudo sync; echo 3 > /proc/sys/vm/drop_caches 
    fio $fio_config >> fio_results_ringbuf_128kb
    echo -e "\n-------------------------------------------------------------------\n" >> fio_results_ringbuf_128kb
done    

pkill python3

ringbuf_size=1024

sudo python3 $IOTRACER_PATH -t fio --file -i $inode -l b -size $ringbuf_size > trace_fio_ringbuf_4mb &
sleep 5

rm fio_results_ringbuf_4mb

for (( i = 0; i < $exec_count; i++)); do
    sudo sync; echo 3 > /proc/sys/vm/drop_caches 
    fio $fio_config >> fio_results_ringbuf_4mb
    echo -e "\n-------------------------------------------------------------------\n" >> fio_results_ringbuf_4mb
done    

pkill python3

ringbuf_size=32768

sudo python3 $IOTRACER_PATH -t fio --file -i $inode -l b -size $ringbuf_size > trace_fio_ringbuf_128mb &
sleep 5

rm fio_results_ringbuf_128mb

for (( i = 0; i < $exec_count; i++)); do
    sudo sync; echo 3 > /proc/sys/vm/drop_caches 
    fio $fio_config >> fio_results_ringbuf_128mb
    echo -e "\n-------------------------------------------------------------------\n" >> fio_results_ringbuf_128mb
done    

pkill python3

ringbuf_size=262144

sudo python3 $IOTRACER_PATH -t fio --file -i $inode -l b -size $ringbuf_size > trace_fio_ringbuf_1gb &
sleep 5

rm fio_results_ringbuf_1gb

for (( i = 0; i < $exec_count; i++)); do
    sudo sync; echo 3 > /proc/sys/vm/drop_caches 
    fio $fio_config >> fio_results_ringbuf_1gb
    echo -e "\n-------------------------------------------------------------------\n" >> fio_results_ringbuf_1gb
done    

pkill python3

## Output file for storing extracted run times
output_file="run_times_ringbufsize.csv"

rm -rf $output_file
# Write header to the output file
header="Size"
for (( i = 0; i < $exec_count; i++)); do
    header="$header,run_$i"
done

echo $header > "$output_file"

# Define the pattern to search for
pattern="run="

for file in fio_results_ringbuf_*; do
    echo "Processing file: $file"
    
    size=$(echo $file | awk -F '_' '{print $4}')
    runs=$(grep "$pattern" "$file" | awk -F 'run=' '{print $2}' | awk -F '-' '{print $1}' | tr '\n' ',' | sed 's/,$//')    
    echo "$size,$runs" >> "$output_file"
done

echo "Run times extracted to $output_file"