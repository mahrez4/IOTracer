#!/usr/bin/sh

IOTRACER_PATH="../../bcc_iotracer.py"

source terasort_datadir/setup_env.sh

rm -rf terasort_datadir/input terasort_datadir/terasort_output

hadoop jar $HADOOP_HOME/share/hadoop/mapreduce/hadoop-mapreduce-examples-3.3.6.jar teragen 10000000 terasort_datadir/input

########## 

##set ring buffer size in number of pages 32:128KB, 1024:4MB,32768:128MB,262144:1G

##no tracing 

ringbuf_size=32

rm terasort_results_ringbuf_notracing

for (( i = 0; i < 20; i++)); do
    sudo sync; echo 3 > /proc/sys/vm/drop_caches 
    rm -rf terasort_datadir/terasort_output
    hadoop jar $HADOOP_HOME/share/hadoop/mapreduce/hadoop-mapreduce-examples-3.3.6.jar terasort terasort_datadir/input terasort_datadir/terasort_output 2>> terasort_results_ringbuf_notracing
    echo \n------------------------------------------\n >> terasort_results_ringbuf_notracing
done  


sudo python $IOTRACER_PATH -t LocalJobRunner,java,kworker,kswapd,pool -l vfb -size $ringbuf_size > trace_output_bcc &
sleep 5

rm terasort_results_ringbuf_128kb

for (( i = 0; i < 20; i++)); do
    sudo sync; echo 3 > /proc/sys/vm/drop_caches 
    rm -rf terasort_datadir/terasort_output
    hadoop jar $HADOOP_HOME/share/hadoop/mapreduce/hadoop-mapreduce-examples-3.3.6.jar terasort terasort_datadir/input terasort_datadir/terasort_output 2>> terasort_results_ringbuf_128kb
    echo \n------------------------------------------\n >> terasort_results_ringbuf_128kb
done    

pkill python

ringbuf_size=1024

sudo python $IOTRACER_PATH -t LocalJobRunner,java,kworker,kswapd,pool -l vfb -size $ringbuf_size > trace_output_bcc &
sleep 5

rm terasort_results_ringbuf_4mb

for (( i = 0; i < 20; i++)); do
    sudo sync; echo 3 > /proc/sys/vm/drop_caches 
    rm -rf terasort_datadir/terasort_output
    hadoop jar $HADOOP_HOME/share/hadoop/mapreduce/hadoop-mapreduce-examples-3.3.6.jar terasort terasort_datadir/input terasort_datadir/terasort_output 2>> terasort_results_ringbuf_4mb
    echo \n------------------------------------------\n >> terasort_results_ringbuf_4mb
done    

pkill python

ringbuf_size=32768
sudo python $IOTRACER_PATH -t LocalJobRunner,java,kworker,kswapd,pool -l vfb -size $ringbuf_size > trace_output_bcc &
sleep 5

rm terasort_results_ringbuf_128mb

for (( i = 0; i < 20; i++)); do
    sudo sync; echo 3 > /proc/sys/vm/drop_caches 
    rm -rf terasort_datadir/terasort_output
    hadoop jar $HADOOP_HOME/share/hadoop/mapreduce/hadoop-mapreduce-examples-3.3.6.jar terasort terasort_datadir/input terasort_datadir/terasort_output 2>> terasort_results_ringbuf_128mb
    echo \n------------------------------------------\n >> terasort_results_ringbuf_128mb
done    

pkill python

ringbuf_size=262144
sudo python $IOTRACER_PATH -t LocalJobRunner,java,kworker,kswapd,pool -l vfb -size $ringbuf_size > trace_output_bcc &
sleep 5

rm terasort_results_ringbuf_1G

for (( i = 0; i < 20; i++)); do
    sudo sync; echo 3 > /proc/sys/vm/drop_caches 
    rm -rf terasort_datadir/terasort_output
    hadoop jar $HADOOP_HOME/share/hadoop/mapreduce/hadoop-mapreduce-examples-3.3.6.jar terasort terasort_datadir/input terasort_datadir/terasort_output 2>> terasort_results_ringbuf_1G
    echo \n------------------------------------------\n >> terasort_results_ringbuf_1G
done    

pkill python

## Output file for storing extracted run times
output_file="run_times_ringbufsize.csv"

# Remove the output file if it exists
rm -rf "$output_file"

# Write header to the output file
header="Ringbuffer size"
for (( i = 0; i < 20; i++ )); do
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