#!/bin/bash

IOTRACER_PATH="../../bcc_iotracer.py"

source terasort_datadir/setup_env.sh

rm -rf terasort_datadir/input terasort_datadir/terasort_output

hadoop jar $HADOOP_HOME/share/hadoop/mapreduce/hadoop-mapreduce-examples-3.3.6.jar teragen 10000000 terasort_datadir/input

block_device=""
exec_count=5
if [ ! -z "$2" ]; then
   block_device="-dev $2"
fi

if [ ! -z "$1" ]; then
    exec_count=$1
fi

##########

rm terasort_results_storage_notracing

for (( i = 0; i < $exec_count; i++)); do
    sudo sync; echo 3 > /proc/sys/vm/drop_caches 
    rm -rf terasort_datadir/terasort_output
    hadoop jar $HADOOP_HOME/share/hadoop/mapreduce/hadoop-mapreduce-examples-3.3.6.jar terasort terasort_datadir/input terasort_datadir/terasort_output 2>> terasort_results_storage_notracing
    echo -e "\n-------------------------------------------------------------------\n" >> terasort_results_storage_notracing
done  

##########

storage_device=d
rm terasort_results_storage_disk

for (( i = 0; i < $exec_count; i++)); do
    sudo python3 $IOTRACER_PATH -t LocalJobRunner,java,kworker,kswapd,pool -l b $block_device -s $storage_device > traces_terasort/storage/trace_terasort_storage_disk_$i &
    sleep 4
    sudo sync; echo 3 > /proc/sys/vm/drop_caches 
    rm -rf terasort_datadir/terasort_output
    hadoop jar $HADOOP_HOME/share/hadoop/mapreduce/hadoop-mapreduce-examples-3.3.6.jar terasort terasort_datadir/input terasort_datadir/terasort_output 2>> terasort_results_storage_disk
    echo -e "\n-------------------------------------------------------------------\n" >> terasort_results_storage_disk
    sleep 1; pkill python3; sleep 1;
done    

##########

storage_device=r
rm terasort_results_storage_ram

for (( i = 0; i < $exec_count; i++)); do
    sudo python3 $IOTRACER_PATH -t LocalJobRunner,java,kworker,kswapd,pool -l b $block_device -s $storage_device > /tmp/trace_terasort_storage_ram_$i &
    sleep 4
    sudo sync; echo 3 > /proc/sys/vm/drop_caches 
    rm -rf terasort_datadir/terasort_output
    hadoop jar $HADOOP_HOME/share/hadoop/mapreduce/hadoop-mapreduce-examples-3.3.6.jar terasort terasort_datadir/input terasort_datadir/terasort_output 2>> terasort_results_storage_ram
    echo -e "\n-------------------------------------------------------------------\n" >> terasort_results_storage_ram
    sleep 1; pkill python3; sleep 1;
done    

sleep 1; pkill python3; sleep 1;

## Output file for storing extracted run times
output_file="run_times_storage.csv"

# Remove the output file if it exists
rm -rf "$output_file"

# Write header to the output file
header="Trace storage"
for (( i = 0; i < $exec_count; i++ )); do
    header="$header,run_$i"
done
echo "$header" > "$output_file"

# Function to convert timestamps to seconds since epoch
convert_to_epoch() {
    date -d "$1" +%s.%3N
}

# Define the pattern to search for
start_pattern="INFO terasort.TeraSort: starting"
end_pattern="INFO terasort.TeraSort: done"

for file in terasort_results_storage*; do
    echo "Processing file: $file"
    
    # Initialize variables
    run_times=()
    start_time=""
    end_time=""

    # Read the log file line by line
    while read -r line; do
        # Check for "starting" lines
        if [[ $line =~ ([0-9]{4}-[0-9]{2}-[0-9]{2} [0-9]{2}:[0-9]{2}:[0-9]{2},[0-9]{3})\ $start_pattern ]]; then
            start_time=${BASH_REMATCH[1]}
            start_epoch=$(convert_to_epoch "$start_time")
        fi
        
        # Check for "done" lines
        if [[ $line =~ ([0-9]{4}-[0-9]{2}-[0-9]{2} [0-9]{2}:[0-9]{2}:[0-9]{2},[0-9]{3})\ $end_pattern ]]; then
            end_time=${BASH_REMATCH[1]}
            end_epoch=$(convert_to_epoch "$end_time")
            
            # Calculate runtime and store
            if [[ -n $start_epoch && -n $end_epoch ]]; then
                runtime=$(echo "$end_epoch - $start_epoch" | bc)
                run_times+=("$runtime")
                start_time=""
                end_time=""
            fi
        fi
    done < "$file"
    
    # Prepare the line for CSV
    api=$(echo "$file" | awk -F '_' '{print $4}')
    runs=$(printf ",%.3f" "${run_times[@]}")
    runs=$(echo "$runs" | sed 's/^,//')  # Remove leading comma
    echo "$api,$runs" >> "$output_file"
done

echo "Run times extracted to $output_file"