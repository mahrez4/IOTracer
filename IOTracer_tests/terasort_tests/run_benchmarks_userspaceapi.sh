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

rm terasort_results_userspace_notracing

for (( i = 0; i < $exec_count; i++)); do
    sudo sync; echo 3 > /proc/sys/vm/drop_caches 
    rm -rf terasort_datadir/terasort_output
    hadoop jar $HADOOP_HOME/share/hadoop/mapreduce/hadoop-mapreduce-examples-3.3.6.jar terasort terasort_datadir/input terasort_datadir/terasort_output 2>> terasort_results_userspace_notracing
    echo -e "\n-------------------------------------------------------------------\n" >> terasort_results_userspace_notracing
done  

##########

userspace_api=p
rm terasort_results_userspace_poll

for (( i = 0; i < $exec_count; i++)); do
    sudo python3 $IOTRACER_PATH -t LocalJobRunner,java,kworker,kswapd,pool -l b $block_device -u $userspace_api > traces_terasort/userspace_api/trace_terasort_userspace_poll_$i &
    sleep 4
    sudo sync; echo 3 > /proc/sys/vm/drop_caches 
    rm -rf terasort_datadir/terasort_output
    hadoop jar $HADOOP_HOME/share/hadoop/mapreduce/hadoop-mapreduce-examples-3.3.6.jar terasort terasort_datadir/input terasort_datadir/terasort_output 2>> terasort_results_userspace_poll
    echo -e "\n-------------------------------------------------------------------\n" >> terasort_results_userspace_poll
    sleep 4; pkill python3; sleep1;
done    


##########

userspace_api=c
rm terasort_results_userspace_consume

for (( i = 0; i < $exec_count; i++)); do
    sudo python3 $IOTRACER_PATH -t LocalJobRunner,java,kworker,kswapd,pool -l b $block_device -u $userspace_api > traces_terasort/userspace_api/trace_terasort_userspace_consume_$i &
    sleep 4
    sudo sync; echo 3 > /proc/sys/vm/drop_caches 
    rm -rf terasort_datadir/terasort_output
    hadoop jar $HADOOP_HOME/share/hadoop/mapreduce/hadoop-mapreduce-examples-3.3.6.jar terasort terasort_datadir/input terasort_datadir/terasort_output 2>> terasort_results_userspace_consume    
    echo -e "\n-------------------------------------------------------------------\n" >> terasort_results_userspace_consume
    sleep 4; pkill python3; sleep1;
done    


#######
##########

userspace_api=c
rm terasort_results_userspace_consume-nowakeup

for (( i = 0; i < $exec_count; i++)); do
    sudo python3 $IOTRACER_PATH -t LocalJobRunner,java,kworker,kswapd,pool -l b $block_device -u $userspace_api -wkup n > traces_terasort/userspace_api/trace_terasort_userspace_consume-nowakeup_$i &
    sleep 4
    sudo sync; echo 3 > /proc/sys/vm/drop_caches 
    rm -rf terasort_datadir/terasort_output
    hadoop jar $HADOOP_HOME/share/hadoop/mapreduce/hadoop-mapreduce-examples-3.3.6.jar terasort terasort_datadir/input terasort_datadir/terasort_output 2>> terasort_results_userspace_consume-nowakeup  
    echo -e "\n-------------------------------------------------------------------\n" >> terasort_results_userspace_consume-nowakeup
    sleep 4; pkill python3; sleep1;
done

##########

userspace_api=c
rm terasort_results_userspace_consume-wakeup

for (( i = 0; i < $exec_count; i++)); do
    sudo python3 $IOTRACER_PATH -t LocalJobRunner,java,kworker,kswapd,pool -l b $block_device -u $userspace_api -wkup y > traces_terasort/userspace_api/trace_terasort_userspace_consume-wakeup_$i &
    sleep 4
    sudo sync; echo 3 > /proc/sys/vm/drop_caches 
    rm -rf terasort_datadir/terasort_output
    hadoop jar $HADOOP_HOME/share/hadoop/mapreduce/hadoop-mapreduce-examples-3.3.6.jar terasort terasort_datadir/input terasort_datadir/terasort_output 2>> terasort_results_userspace_consume-wakeup  
    echo -e "\n-------------------------------------------------------------------\n" >> terasort_results_userspace_consume-wakeup
    sleep 4; pkill python3; sleep1;
done    

##########

userspace_api=c
rm terasort_results_userspace_consume-sleep1s

for (( i = 0; i < $exec_count; i++)); do
    sudo python3 $IOTRACER_PATH -t LocalJobRunner,java,kworker,kswapd,pool -l b $block_device -u $userspace_api -sleep 1 > traces_terasort/userspace_api/trace_terasort_userspace_consume-sleep1s_$i &
    sleep 4
    sudo sync; echo 3 > /proc/sys/vm/drop_caches 
    rm -rf terasort_datadir/terasort_output
    hadoop jar $HADOOP_HOME/share/hadoop/mapreduce/hadoop-mapreduce-examples-3.3.6.jar terasort terasort_datadir/input terasort_datadir/terasort_output 2>> terasort_results_userspace_consume-sleep1s  
    echo -e "\n-------------------------------------------------------------------\n" >> terasort_results_userspace_consume-sleep1s
    sleep 4; pkill python3; sleep1;
done    

##########

userspace_api=p
rm terasort_results_userspace_poll-sleep1s

for (( i = 0; i < $exec_count; i++)); do
    sudo python3 $IOTRACER_PATH -t LocalJobRunner,java,kworker,kswapd,pool -l b $block_device -u $userspace_api -sleep 1 > traces_terasort/userspace_api/trace_terasort_userspace_poll-sleep1s_$i &
    sleep 4
    sudo sync; echo 3 > /proc/sys/vm/drop_caches 
    rm -rf terasort_datadir/terasort_output
    hadoop jar $HADOOP_HOME/share/hadoop/mapreduce/hadoop-mapreduce-examples-3.3.6.jar terasort terasort_datadir/input terasort_datadir/terasort_output 2>> terasort_results_userspace_poll-sleep1s  
    echo -e "\n-------------------------------------------------------------------\n" >> terasort_results_userspace_poll-sleep1s
    sleep 4; pkill python3; sleep1;
done    


# Output file for storing extracted run times
output_file="run_times_userspace_api.csv"

# Remove the output file if it exists
rm -rf "$output_file"

# Write header to the output file
header="Userspace Api"
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

for file in terasort_results_userspace*; do
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
