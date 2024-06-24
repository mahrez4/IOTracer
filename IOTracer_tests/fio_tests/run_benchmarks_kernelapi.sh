#!/bin/bash

IOTRACER_PATH="../../bcc_iotracer.py"

traced_path="./fio_file"

fio_config="./fio_config.fio"

exec_count=5
if [ ! -z "$1" ]; then
    exec_count=$1
fi

########## 

rm fio_results_kernel_notracing

for (( i = 0; i < $exec_count; i++)); do
    sudo sync; echo 3 > /proc/sys/vm/drop_caches 
    fio $fio_config >> fio_results_kernel_notracing
    echo -e "\n-------------------------------------------------------------------\n" >> fio_results_kernel_notracing
done  

##########

inode=`stat -c '%i' $traced_path`
kernel_api=o
rm fio_results_kernel_output

for (( i = 0; i < $exec_count; i++)); do
    sudo python3 $IOTRACER_PATH -t fio --file -i $inode -l b -k $kernel_api > traces_fio/kernel_api/trace_fio_kernel_output_$i &
    sleep 5
    sudo sync; echo 3 > /proc/sys/vm/drop_caches 
    fio $fio_config >> fio_results_kernel_output
    echo -e "\n-------------------------------------------------------------------\n" >> fio_results_kernel_output
    pkill python3
done    

##########

kernel_api=s
rm fio_results_kernel_submit

for (( i = 0; i < $exec_count; i++)); do
    sudo python3 $IOTRACER_PATH -t fio --file -i $inode -l b -k $kernel_api > traces_fio/kernel_api/trace_fio_kernel_submit_$i &
    sleep 5
    sudo sync; echo 3 > /proc/sys/vm/drop_caches 
    fio $fio_config >> fio_results_kernel_submit
    echo -e "\n-------------------------------------------------------------------\n" >> fio_results_kernel_submit
    pkill python3
done    


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