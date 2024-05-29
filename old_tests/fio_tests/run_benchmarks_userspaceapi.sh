#!/usr/bin/sh

IOTRACER_PATH="/home/mhrz/pfe/tools/IOTracer/bcc_iotracer.py"

traced_path="/home/mhrz/pfe/tools/testfile"

fio_config="/home/mhrz/pfe/tools/fio_config.fio"

inode=`stat -c '%i' $traced_path`


########## 

rm fio_results_userspace_notracing

for (( i = 0; i < 20; i++)); do
    sudo sync; echo 3 > /proc/sys/vm/drop_caches 
    fio $fio_config >> fio_results_userspace_notracing
    echo "\n------------------------------------------\n" >> fio_results_userspace_notracing
done  

##########

userspace_api=p

sudo python $IOTRACER_PATH -t fio --file -i $inode -l b -u $userspace_api > trace_output_bcc &
sleep 5

rm fio_results_userspace_poll

for (( i = 0; i < 20; i++)); do
    sudo sync; echo 3 > /proc/sys/vm/drop_caches 
    fio $fio_config >> fio_results_userspace_poll
    echo "\n------------------------------------------\n" >> fio_results_userspace_poll
done    

pkill python

##########

userspace_api=c

sudo python $IOTRACER_PATH -t fio --file -i $inode -l b -u $userspace_api > trace_output_bcc &
sleep 5

rm fio_results_userspace_consume

for (( i = 0; i < 20; i++)); do
    sudo sync; echo 3 > /proc/sys/vm/drop_caches 
    fio $fio_config >> fio_results_userspace_consume
    echo "\n------------------------------------------\n" >> fio_results_userspace_consume
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
pattern="run="

for file in fio_results_userspace*; do
    echo "Processing file: $file"
    
    api=$(echo $file | awk -F '_' '{print $4}')
    runs=$(grep "$pattern" "$file" | awk -F 'run=' '{print $2}' | awk -F '-' '{print $1}' | tr '\n' ',' | sed 's/,$//')    
    echo "$api,$runs" >> "$output_file"
done

echo "Run times extracted to $output_file"