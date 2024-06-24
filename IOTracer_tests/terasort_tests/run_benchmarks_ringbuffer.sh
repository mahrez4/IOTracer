#!/bin/bash

IOTRACER_PATH="../../bcc_iotracer.py"

source terasort_datadir/setup_env.sh

rm -rf terasort_datadir/input terasort_datadir/terasort_output

hadoop jar $HADOOP_HOME/share/hadoop/mapreduce/hadoop-mapreduce-examples-3.3.6.jar teragen 10000000 terasort_datadir/input

exec_count=5
if [ ! -z "$1" ]; then
    exec_count=$1
fi

########## 

##set ring buffer size in number of pages 32:128KB, 1024:4MB,32768:128MB,262144:1G

##no tracing 



rm terasort_results_ringbuf_notracing

for (( i = 0; i < $exec_count; i++)); do
    sudo sync; echo 3 > /proc/sys/vm/drop_caches 
    rm -rf terasort_datadir/terasort_output
    hadoop jar $HADOOP_HOME/share/hadoop/mapreduce/hadoop-mapreduce-examples-3.3.6.jar terasort terasort_datadir/input terasort_datadir/terasort_output 2>> terasort_results_ringbuf_notracing
    echo -e "\n-------------------------------------------------------------------\n" >> terasort_results_ringbuf_notracing
done  

##########

ringbuf_size=32
rm terasort_results_ringbuf_128kb

for (( i = 0; i < $exec_count; i++)); do
    sudo python3 $IOTRACER_PATH -t LocalJobRunner,java,kworker,kswapd,pool -l vfb -size $ringbuf_size > traces_terasort/ringbuffer/trace_terasort_ringbuf_128kb_$i &
    sleep 5
    sudo sync; echo 3 > /proc/sys/vm/drop_caches 
    rm -rf terasort_datadir/terasort_output
    hadoop jar $HADOOP_HOME/share/hadoop/mapreduce/hadoop-mapreduce-examples-3.3.6.jar terasort terasort_datadir/input terasort_datadir/terasort_output 2>> terasort_results_ringbuf_128kb
    echo -e "\n-------------------------------------------------------------------\n" >> terasort_results_ringbuf_128kb
    pkill python3
done    

pkill python3

##########

ringbuf_size=1024
rm terasort_results_ringbuf_4mb

for (( i = 0; i < $exec_count; i++)); do
    sudo python3 $IOTRACER_PATH -t LocalJobRunner,java,kworker,kswapd,pool -l vfb -size $ringbuf_size > traces_terasort/ringbuffer/trace_terasort_ringbuf_4mb_$i &
    sleep 5
    sudo sync; echo 3 > /proc/sys/vm/drop_caches 
    rm -rf terasort_datadir/terasort_output
    hadoop jar $HADOOP_HOME/share/hadoop/mapreduce/hadoop-mapreduce-examples-3.3.6.jar terasort terasort_datadir/input terasort_datadir/terasort_output 2>> terasort_results_ringbuf_4mb
    echo -e "\n-------------------------------------------------------------------\n" >> terasort_results_ringbuf_4mb
    pkill python3
done    



##########

ringbuf_size=32768
rm terasort_results_ringbuf_128mb

for (( i = 0; i < $exec_count; i++)); do
    sudo python3 $IOTRACER_PATH -t LocalJobRunner,java,kworker,kswapd,pool -l vfb -size $ringbuf_size > traces_terasort/ringbuffer/trace_terasort_ringbuf_128mb_$i &
    sleep 5
    sudo sync; echo 3 > /proc/sys/vm/drop_caches 
    rm -rf terasort_datadir/terasort_output
    hadoop jar $HADOOP_HOME/share/hadoop/mapreduce/hadoop-mapreduce-examples-3.3.6.jar terasort terasort_datadir/input terasort_datadir/terasort_output 2>> terasort_results_ringbuf_128mb
    echo -e "\n-------------------------------------------------------------------\n" >> terasort_results_ringbuf_128mb
    pkill python3
done    

pkill python3

##########

ringbuf_size=262144
rm terasort_results_ringbuf_1G

for (( i = 0; i < $exec_count; i++)); do
    sudo python3 $IOTRACER_PATH -t LocalJobRunner,java,kworker,kswapd,pool -l vfb -size $ringbuf_size > traces_terasort/ringbuffer/trace_terasort_ringbuf_1G_$i &
    sleep 5
    sudo sync; echo 3 > /proc/sys/vm/drop_caches 
    rm -rf terasort_datadir/terasort_output
    hadoop jar $HADOOP_HOME/share/hadoop/mapreduce/hadoop-mapreduce-examples-3.3.6.jar terasort terasort_datadir/input terasort_datadir/terasort_output 2>> terasort_results_ringbuf_1G
    echo -e "\n-------------------------------------------------------------------\n" >> terasort_results_ringbuf_1G
    pkill python3
done    

pkill python3

## Output file for storing extracted run times
output_file="run_times_ringbufsize.csv"

# Remove the output file if it exists
rm -rf "$output_file"

# Write header to the output file
header="Ringbuffer size"
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

for file in terasort_results_ringbuf*; do
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
