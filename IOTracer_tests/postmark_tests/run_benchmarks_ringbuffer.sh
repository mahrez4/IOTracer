#!/bin/bash

IOTRACER_PATH="../../bcc_iotracer.py"

traced_path="postmark/"

postmark_config="postmark/cfg.pm"

postmark="postmark/postmark"

inode=`stat -c '%i' $traced_path`

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

rm postmark_results_ringbuf_notracing

for (( i = 0; i < $exec_count; i++)); do
    sudo sync; echo 3 > /proc/sys/vm/drop_caches 
    $postmark < $postmark_config >> postmark_results_ringbuf_notracing
    echo -e "\n-------------------------------------------------------------------\n" >> postmark_results_ringbuf_notracing
done  

########

ringbuf_size=32
rm postmark_results_ringbuf_128kb

for (( i = 0; i < $exec_count; i++)); do
    sudo python3 $IOTRACER_PATH -t postmark --dir -i $inode -l b $block_device -size $ringbuf_size > traces_postmark/ringbuffer/trace_postmark_ringbuf_128kb_$i &
    sleep 4
    sudo sync; echo 3 > /proc/sys/vm/drop_caches 
    $postmark < $postmark_config >> postmark_results_ringbuf_128kb
    echo -e "\n-------------------------------------------------------------------\n" >> postmark_results_ringbuf_128kb
    sleep 1; pkill python3; sleep 1;
done    


########

ringbuf_size=1024
rm postmark_results_ringbuf_4mb

for (( i = 0; i < $exec_count; i++)); do
    sudo python3 $IOTRACER_PATH -t postmark --dir -i $inode -l b $block_device -size $ringbuf_size > traces_postmark/ringbuffer/trace_postmark_ringbuf_4mb_$i &
    sleep 4
    sudo sync; echo 3 > /proc/sys/vm/drop_caches 
    $postmark < $postmark_config >> postmark_results_ringbuf_4mb
    echo -e "\n-------------------------------------------------------------------\n" >> postmark_results_ringbuf_4mb
    sleep 1; pkill python3; sleep 1;
done    


########

ringbuf_size=32768
rm postmark_results_ringbuf_128mb

for (( i = 0; i < $exec_count; i++)); do
    sudo python3 $IOTRACER_PATH -t postmark --dir -i $inode -l b $block_device -size $ringbuf_size > traces_postmark/ringbuffer/trace_postmark_ringbuf_128mb_$i &
    sleep 4
    sudo sync; echo 3 > /proc/sys/vm/drop_caches 
    $postmark < $postmark_config >> postmark_results_ringbuf_128mb
    echo -e "\n-------------------------------------------------------------------\n" >> postmark_results_ringbuf_128mb
    sleep 1; pkill python3; sleep 1;
done    



########

ringbuf_size=262144
rm postmark_results_ringbuf_1G

for (( i = 0; i < $exec_count; i++)); do
    sudo python3 $IOTRACER_PATH -t postmark --dir -i $inode -l b $block_device -size $ringbuf_size > traces_postmark/ringbuffer/trace_postmark_ringbuf_1G_$i &
    sleep 4
    sudo sync; echo 3 > /proc/sys/vm/drop_caches 
    $postmark < $postmark_config >> postmark_results_ringbuf_1G
    echo -e "\n-------------------------------------------------------------------\n" >> postmark_results_ringbuf_1G
    sleep 1; pkill python3; sleep 1;
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
pattern="seconds total"

for file in postmark_results_ringbuf_* ; do
    echo "Processing file: $file"
    
    api=$(echo $file | awk -F '_' '{print $4}')
    runs=$(grep "$pattern" "$file" | awk -F ' ' '{print $1}' | tr '\n' ',' | sed 's/,$//')
    echo "$api,$runs" >> "$output_file"
done

echo "Run times extracted to $output_file"