#!/usr/bin/sh

IOTRACER_PATH="../../bcc_iotracer.py"

traced_path="./fio_file"

fio_config="./fio_config.fio"

inode=`stat -c '%i' $traced_path`

exec_count=5

########## 

rm fio_results_kernel_notracing

for (( i = 0; i < $exec_count; i++)); do
    sudo sync; echo 3 > /proc/sys/vm/drop_caches 
    fio $fio_config >> fio_results_kernel_notracing
    echo \n------------------------------------------\n >> fio_results_kernel_notracing
done  

kernel_api=o

sudo python $IOTRACER_PATH -t fio --file -i $inode -l b -k $kernel_api > trace_fio_kernel_output &
sleep 5

rm fio_results_kernel_output

for (( i = 0; i < $exec_count; i++)); do
    sudo sync; echo 3 > /proc/sys/vm/drop_caches 
    fio $fio_config >> fio_results_kernel_output
    echo \n------------------------------------------\n >> fio_results_kernel_output
done    

pkill python

kernel_api=s

sudo python $IOTRACER_PATH -t fio --file -i $inode -l b -k $kernel_api > trace_fio_kernel_submit &
sleep 5

rm fio_results_kernel_submit

for (( i = 0; i < $exec_count; i++)); do
    sudo sync; echo 3 > /proc/sys/vm/drop_caches 
    fio $fio_config >> fio_results_kernel_submit
    echo \n------------------------------------------\n >> fio_results_kernel_submit
done    

pkill python

## Output file for storing extracted run times
output_file="run_times_kernel_api.csv"

rm -rf $output_file
# Write header to the output file
header="API"
for (( i = 0; i < $exec_count; i++)); do
    header="$header,run_$i"
done

echo $header > "$output_file"

# Define the pattern to search for
pattern="run="

for file in fio_results_kernel*; do
    echo "Processing file: $file"
    
    api=$(echo $file | awk -F '_' '{print $4}')
    runs=$(grep "$pattern" "$file" | awk -F 'run=' '{print $2}' | awk -F '-' '{print $1}' | tr '\n' ',' | sed 's/,$//')    
    echo "$api,$runs" >> "$output_file"
done

echo "Run times extracted to $output_file"