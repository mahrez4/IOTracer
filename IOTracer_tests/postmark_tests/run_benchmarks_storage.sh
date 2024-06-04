#!/usr/bin/sh

IOTRACER_PATH="../../bcc_iotracer.py"

traced_path="postmark/"

postmark_config="postmark/cfg.pm"

postmark="postmark/postmark"

inode=`stat -c '%i' $traced_path`

exec_count=5

########## 

rm postmark_results_storage_notracing

for (( i = 0; i < $exec_count; i++)); do
    sudo sync; echo 3 > /proc/sys/vm/drop_caches 
    $postmark < $postmark_config >> postmark_results_storage_notracing
    echo -e "\n-------------------------------------------------------------------\n" >> postmark_results_storage_notracing
done  

storage_device=d

sudo python $IOTRACER_PATH -t postmark --file -i $inode -l b -s $storage_device > trace_postmark_storage_disk &
sleep 5

rm postmark_results_storage_disk

for (( i = 0; i < $exec_count; i++)); do
    sudo sync; echo 3 > /proc/sys/vm/drop_caches 
    $postmark < $postmark_config >> postmark_results_storage_disk
    echo -e "\n-------------------------------------------------------------------\n" >> postmark_results_storage_disk
done    

pkill python

storage_device=r

sudo python $IOTRACER_PATH -t postmark --file -i $inode -l b -s $storage_device > /tmp/trace_postmark_storage_ram &
sleep 5

rm postmark_results_storage_ram

for (( i = 0; i < $exec_count; i++)); do
    sudo sync; echo 3 > /proc/sys/vm/drop_caches 
    $postmark < $postmark_config >> postmark_results_storage_ram
    truncate -s 0 /tmp/trace_postmark_storage_ram 
    echo -e "\n-------------------------------------------------------------------\n" >> postmark_results_storage_ram
done    

pkill python

## disk file for storing extracted run times
disk_file="run_times_storage.csv"

rm -rf $disk_file
# Write header to the disk file
header="Trace storage"
for (( i = 0; i < $exec_count; i++)); do
    header="$header,run_$i"
done

echo $header > "$disk_file"

# Define the pattern to search for
pattern="seconds total"

for file in postmark_results_storage* ; do
    echo "Processing file: $file"
    
    api=$(echo $file | awk -F '_' '{print $4}')
    runs=$(grep "$pattern" "$file" | awk -F ' ' '{print $1}' | tr '\n' ',' | sed 's/,$//')
    echo "$api,$runs" >> "$disk_file"
done

echo "Run times extracted to $disk_file"