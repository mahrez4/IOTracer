#!/bin/bash

IOTRACER_PATH="../../bcc_iotracer.py"

traced_path="."

sqlite_config="./gen_sql_data.sql"

inode=`stat -c '%i' $traced_path`

TIMEFORMAT="time= %R"

exec_count=5
if [ ! -z "$1" ]; then
    exec_count=$1
fi

 

##set ring buffer size in number of pages 32:128KB, 1024:4MB,32768:128MB,262144:1G

##no tracing 


rm sqlite_results_ringbuf_notracing db_sql.db

for (( i = 0; i < $exec_count; i++)); do
    sudo sync; echo 3 > /proc/sys/vm/drop_caches 
    { time sqlite3 db_sql.db < gen_sql_data.sql ; } 2>> sqlite_results_ringbuf_notracing >> /dev/null
    echo -e "\n-------------------------------------------------------------------\n" >> sqlite_results_ringbuf_notracing
done  

##########

ringbuf_size=32
rm sqlite_results_ringbuf_128kb db_sql.db

for (( i = 0; i < $exec_count; i++)); do
    sudo python3 $IOTRACER_PATH -t sqlite --dir -i $inode -l b $block_device -size $ringbuf_size >> /dev/null &
    sleep 4
    sudo sync; echo 3 > /proc/sys/vm/drop_caches 
    { time sqlite3 db_sql.db < gen_sql_data.sql ; } 2>> sqlite_results_ringbuf_128kb >> /dev/null
    echo -e "\n-------------------------------------------------------------------\n" >> sqlite_results_ringbuf_128kb
    sleep 1; pkill python3; sleep 1;
done    

##########

ringbuf_size=1024
rm sqlite_results_ringbuf_4mb db_sql.db

for (( i = 0; i < $exec_count; i++)); do
    sudo python3 $IOTRACER_PATH -t sqlite --dir -i $inode -l b $block_device -size $ringbuf_size >> /dev/null &
    sleep 4
    sudo sync; echo 3 > /proc/sys/vm/drop_caches 
    { time sqlite3 db_sql.db < gen_sql_data.sql ; } 2>> sqlite_results_ringbuf_4mb >> /dev/null
    echo -e "\n-------------------------------------------------------------------\n" >> sqlite_results_ringbuf_4mb
    sleep 1; pkill python3; sleep 1;
done    

##########

ringbuf_size=32768
rm sqlite_results_ringbuf_128mb db_sql.db

for (( i = 0; i < $exec_count; i++)); do
    sudo python3 $IOTRACER_PATH -t sqlite --dir -i $inode -l b $block_device -size $ringbuf_size >> /dev/null &
    sleep 4
    sudo sync; echo 3 > /proc/sys/vm/drop_caches 
    { time sqlite3 db_sql.db < gen_sql_data.sql ; } 2>> sqlite_results_ringbuf_128mb >> /dev/null
    echo -e "\n-------------------------------------------------------------------\n" >> sqlite_results_ringbuf_128mb
    sleep 1; pkill python3; sleep 1;
done    



##########

ringbuf_size=262144
rm sqlite_results_ringbuf_1G db_sql.db

for (( i = 0; i < $exec_count; i++)); do
    sudo python3 $IOTRACER_PATH -t sqlite --dir -i $inode -l b $block_device -size $ringbuf_size >> /dev/null &
    sleep 4
    sudo sync; echo 3 > /proc/sys/vm/drop_caches 
    { time sqlite3 db_sql.db < gen_sql_data.sql ; } 2>> sqlite_results_ringbuf_1G >> /dev/null
    echo -e "\n-------------------------------------------------------------------\n" >> /dev/null
    sleep 1; pkill python3; sleep 1;
done    



## Output file for storing extracted run times
output_file="run_times_ringbufsize.csv"

rm -rf $output_file
# Write header to the output file
header="Size"
for (( i = 0; i < $exec_count; i++)); do
    header="$header,run_$i"
done

echo $header > "$output_file"

# Define the pattern to search for
pattern="time="

for file in sqlite_results_ringbuf* ; do
    echo "Processing file: $file"
    
    api=$(echo $file | awk -F '_' '{print $4}')
    runs=$(grep "$pattern" "$file" | awk -F ' ' '{print $2}' | tr '\n' ',' | sed 's/,$//')
    echo "$api,$runs" >> "$output_file"
done

echo "Run times extracted to $output_file"
