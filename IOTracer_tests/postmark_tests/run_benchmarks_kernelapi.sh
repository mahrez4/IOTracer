#!/usr/bin/sh

IOTRACER_PATH="/home/mhrz/pfe/tools/IOTracer/bcc_iotracer.py"

traced_path="/home/mhrz/pfe/tools/postmark"

postmark_config="/home/mhrz/pfe/tools/postmark/cfg.pm"

postmark="/home/mhrz/pfe/tools/postmark/postmark_final"

inode=`stat -c '%i' $traced_path`

rm postmark_results_kernel_notracing

for (( i = 0; i < 20; i++)); do
    sudo sync; echo 3 > /proc/sys/vm/drop_caches 
    $postmark < $postmark_config >> postmark_results_kernel_notracing
    echo "\n------------------------------------------\n" >> postmark_results_kernel_notracing
done  

kernel_api=o

sudo python $IOTRACER_PATH -t postmark --file -i $inode -l b -k $kernel_api > trace_output_bcc &
sleep 5

rm postmark_results_kernel_output

for (( i = 0; i < 20; i++)); do
    sudo sync; echo 3 > /proc/sys/vm/drop_caches 
    $postmark < $postmark_config >> postmark_results_kernel_output
    echo "\n------------------------------------------\n" >> postmark_results_kernel_output
done    

pkill python

kernel_api=s

sudo python $IOTRACER_PATH -t postmark --file -i $inode -l b -k $kernel_api > trace_output_bcc &
sleep 5

rm postmark_results_kernel_submit

for (( i = 0; i < 20; i++)); do
    sudo sync; echo 3 > /proc/sys/vm/drop_caches 
    $postmark < $postmark_config >> postmark_results_kernel_submit
    echo "\n------------------------------------------\n" >> postmark_results_kernel_submit
done    

pkill python

## Output file for storing extracted run times
output_file="run_times_kernel_api.csv"

rm -rf $output_file
# Write header to the output file
header="API"
for (( i = 0; i < 20; i++)); do
    header="$header,run_$i"
done

echo $header > "$output_file"

# Define the pattern to search for
pattern="seconds total"

for file in postmark_results_kernel* ; do
    echo "Processing file: $file"
    
    api=$(echo $file | awk -F '_' '{print $4}')
    runs=$(grep "$pattern" "$file" | awk -F ' ' '{print $1}' | tr '\n' ',' | sed 's/,$//')
    echo "$api,$runs" >> "$output_file"
done

echo "Run times extracted to $output_file"