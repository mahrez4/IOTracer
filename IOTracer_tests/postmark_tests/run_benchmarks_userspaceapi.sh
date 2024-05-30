#!/usr/bin/sh

IOTRACER_PATH="../../bcc_iotracer.py"

traced_path="postmark/"

postmark_config="postmark/cfg.pm"

postmark="postmark/postmark"

inode=`stat -c '%i' $traced_path`

exec_count=5

########## 

rm postmark_results_userspace_notracing

for (( i = 0; i < $exec_count; i++)); do
    sudo sync; echo 3 > /proc/sys/vm/drop_caches 
    $postmark < $postmark_config >> postmark_results_userspace_notracing
    echo "\n------------------------------------------\n" >> postmark_results_userspace_notracing
done  

##########

userspace_api=p

sudo python $IOTRACER_PATH -t postmark --dir -i $inode -l b -u $userspace_api > trace_postmark_userspace_poll &
sleep 5

rm postmark_results_userspace_poll

for (( i = 0; i < $exec_count; i++)); do
    sudo sync; echo 3 > /proc/sys/vm/drop_caches 
    $postmark < $postmark_config >> postmark_results_userspace_poll
    echo "\n------------------------------------------\n" >> postmark_results_userspace_poll
done    

pkill python

##########

userspace_api=c

sudo python $IOTRACER_PATH -t postmark --dir -i $inode -l b -u $userspace_api > trace_postmark_userspace_consume &
sleep 5

rm postmark_results_userspace_consume

for (( i = 0; i < $exec_count; i++)); do
    sudo sync; echo 3 > /proc/sys/vm/drop_caches 
    $postmark < $postmark_config >> postmark_results_userspace_consume
    echo "\n------------------------------------------\n" >> postmark_results_userspace_consume
done    

pkill python

## Output file for storing extracted run times
output_file="run_times_userspace_api.csv"

rm -rf $output_file
# Write header to the output file
header="API"
for (( i = 0; i < 20; i++)); do
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