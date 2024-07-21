#!/bin/bash

IOTRACER_PATH="../../bcc_iotracer.py"

traced_path="./fio_file"

fio_config="./fio_config.fio"


exec_count=5
if [ ! -z "$1" ]; then
    exec_count=$1
fi

########## 

##set ring buffer size in number of pages 32:128KB, 1024:4MB,32768:128MB,262144:1G

##no tracing 

rm fio_results_ringbuf_notracing

for (( i = 0; i < $exec_count; i++)); do
    sudo sync; echo 3 > /proc/sys/vm/drop_caches 
    fio $fio_config >> fio_results_ringbuf_notracing
    echo -e "\n-------------------------------------------------------------------\n" >> fio_results_ringbuf_notracing
done  

########## 

inode=`stat -c '%i' $traced_path`
ringbuf_size=32
rm fio_results_ringbuf_128kb

for (( i = 0; i < $exec_count; i++)); do
    sudo python3 $IOTRACER_PATH -t fio --file -i $inode -l b $block_device -size $ringbuf_size >> /dev/null &
    sleep 4
    sudo sync; echo 3 > /proc/sys/vm/drop_caches 
    fio $fio_config >> fio_results_ringbuf_128kb
    echo -e "\n-------------------------------------------------------------------\n" >> fio_results_ringbuf_128kb
    pkill python3; sleep 1;
done    

########## 

ringbuf_size=1024
rm fio_results_ringbuf_4mb

for (( i = 0; i < $exec_count; i++)); do
    sudo python3 $IOTRACER_PATH -t fio --file -i $inode -l b $block_device -size $ringbuf_size >> /dev/null &
    sleep 4
    sudo sync; echo 3 > /proc/sys/vm/drop_caches 
    fio $fio_config >> fio_results_ringbuf_4mb
    echo -e "\n-------------------------------------------------------------------\n" >> fio_results_ringbuf_4mb
    pkill python3; sleep 1;
done    

########## 

ringbuf_size=32768
rm fio_results_ringbuf_128mb

for (( i = 0; i < $exec_count; i++)); do
    sudo python3 $IOTRACER_PATH -t fio --file -i $inode -l b $block_device -size $ringbuf_size >> /dev/null &
    sleep 4
    sudo sync; echo 3 > /proc/sys/vm/drop_caches 
    fio $fio_config >> fio_results_ringbuf_128mb
    echo -e "\n-------------------------------------------------------------------\n" >> fio_results_ringbuf_128mb
    pkill python3; sleep 1;
done    

########## 

ringbuf_size=262144
rm fio_results_ringbuf_1gb

for (( i = 0; i < $exec_count; i++)); do
    sudo python3 $IOTRACER_PATH -t fio --file -i $inode -l b $block_device -size $ringbuf_size >> /dev/null &
    sleep 4
    sudo sync; echo 3 > /proc/sys/vm/drop_caches 
    fio $fio_config >> fio_results_ringbuf_1gb
    echo -e "\n-------------------------------------------------------------------\n" >> fio_results_ringbuf_1gb
    pkill python3; sleep 1;
done    

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