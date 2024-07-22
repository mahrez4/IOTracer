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

rm postmark_results_userspace_notracing

for (( i = 0; i < $exec_count; i++)); do
    sudo sync; echo 3 > /proc/sys/vm/drop_caches 
    $postmark < $postmark_config >> postmark_results_userspace_notracing
    echo -e "\n-------------------------------------------------------------------\n" >> postmark_results_userspace_notracing
done  

##########

userspace_api=p

rm postmark_results_userspace_poll

for (( i = 0; i < $exec_count; i++)); do
    sudo python3 $IOTRACER_PATH -t postmark --dir -i $inode -l b $block_device -u $userspace_api > traces_postmark/userspace_api/trace_postmark_userspace_poll_$i &
    sleep 4
    sudo sync; echo 3 > /proc/sys/vm/drop_caches 
    $postmark < $postmark_config >> postmark_results_userspace_poll
    echo -e "\n-------------------------------------------------------------------\n" >> postmark_results_userspace_poll
    pkill python3; sleep 1;
done    

##########

userspace_api=c

rm postmark_results_userspace_consume

for (( i = 0; i < $exec_count; i++)); do
    sudo python3 $IOTRACER_PATH -t postmark --dir -i $inode -l b $block_device -u $userspace_api > traces_postmark/userspace_api/trace_postmark_userspace_consume_$i &
    sleep 4
    sudo sync; echo 3 > /proc/sys/vm/drop_caches 
    $postmark < $postmark_config >> postmark_results_userspace_consume
    echo -e "\n-------------------------------------------------------------------\n" >> postmark_results_userspace_consume
    pkill python3; sleep 1;
done    

##########

userspace_api=c
rm postmark_results_userspace_consume-nowakeup

for (( i = 0; i < $exec_count; i++)); do
    sudo python3 $IOTRACER_PATH -t postmark --dir -i $inode -l b $block_device -u $userspace_api -wkup n > traces_postmark/userspace_api/trace_postmark_userspace_consume-nowakeup_$i &
    sleep 4
    sudo sync; echo 3 > /proc/sys/vm/drop_caches 
    $postmark $postmark_config >> postmark_results_userspace_consume-nowakeup
    echo -e "\n-------------------------------------------------------------------\n" >> postmark_results_userspace_consume-nowakeup
    pkill python3; sleep 1;
done

##########

userspace_api=c
rm postmark_results_userspace_consume-wakeup

for (( i = 0; i < $exec_count; i++)); do
    sudo python3 $IOTRACER_PATH -t postmark --dir -i $inode -l b $block_device -u $userspace_api -wkup y > traces_postmark/userspace_api/trace_postmark_userspace_consume-wakeup_$i &
    sleep 4
    sudo sync; echo 3 > /proc/sys/vm/drop_caches 
    $postmark $postmark_config >> postmark_results_userspace_consume-wakeup
    echo -e "\n-------------------------------------------------------------------\n" >> postmark_results_userspace_consume-wakeup
    pkill python3; sleep 1;
done    

##########

userspace_api=c
rm postmark_results_userspace_consume-sleep1s

for (( i = 0; i < $exec_count; i++)); do
    sudo python3 $IOTRACER_PATH -t postmark --dir -i $inode -l b $block_device -u $userspace_api -sleep 1 > traces_postmark/userspace_api/trace_postmark_userspace_consume-sleep1s_$i &
    sleep 4
    sudo sync; echo 3 > /proc/sys/vm/drop_caches 
    $postmark $postmark_config >> postmark_results_userspace_consume-sleep1s
    echo -e "\n-------------------------------------------------------------------\n" >> postmark_results_userspace_consume-sleep1s
    pkill python3; sleep 1;
done    

##########

userspace_api=p
rm postmark_results_userspace_poll-sleep1s

for (( i = 0; i < $exec_count; i++)); do
    sudo python3 $IOTRACER_PATH -t postmark --dir -i $inode -l b $block_device -u $userspace_api -sleep 1 > traces_postmark/userspace_api/trace_postmark_userspace_poll-sleep1s_$i &
    sleep 4
    sudo sync; echo 3 > /proc/sys/vm/drop_caches 
    $postmark $postmark_config >> postmark_results_userspace_poll-sleep1s
    echo -e "\n-------------------------------------------------------------------\n" >> postmark_results_userspace_poll-sleep1s
    pkill python3; sleep 1;
done    

## Output file for storing extracted run times
output_file="run_times_userspace_api.csv"

rm -rf $output_file
# Write header to the output file
header="API"
for (( i = 0; i < $exec_count; i++)); do
    header="$header,run_$i"
done

echo $header > "$output_file"

# Define the pattern to search for
pattern="seconds total"

for file in postmark_results_userspace* ; do
    echo "Processing file: $file"
    
    api=$(echo $file | awk -F '_' '{print $4}')
    runs=$(grep "$pattern" "$file" | awk -F ' ' '{print $1}' | tr '\n' ',' | sed 's/,$//')
    echo "$api,$runs" >> "$output_file"
done

echo "Run times extracted to $output_file"