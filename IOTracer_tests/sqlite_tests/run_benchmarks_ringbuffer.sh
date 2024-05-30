#!/usr/bin/sh

IOTRACER_PATH="../../bcc_iotracer.py"

traced_path="."

sqlite_config="./gen_sql_data.sql"

inode=`stat -c '%i' $traced_path`

TIMEFORMAT="time= %R"

exec_count=5

########## 

##set ring buffer size in number of pages 32:128KB, 1024:4MB,32768:128MB,262144:1G

##no tracing 

ringbuf_size=32

rm sqlite_results_ringbuf_notracing db_sql.db

for (( i = 0; i < $exec_count; i++)); do
    sudo sync; echo 3 > /proc/sys/vm/drop_caches 
    { time sqlite3 db_sql.db < gen_sql_data.sql ; } 2>> sqlite_results_ringbuf_notracing >> /dev/null
    echo "\n------------------------------------------\n" >> sqlite_results_ringbuf_notracing
done  


sudo python $IOTRACER_PATH -t sqlite --dir -i $inode -l b -size $ringbuf_size > trace_sqlite_ringbuf_128kb &
sleep 5

rm sqlite_results_ringbuf_128kb db_sql.db

for (( i = 0; i < $exec_count; i++)); do
    sudo sync; echo 3 > /proc/sys/vm/drop_caches 
    { time sqlite3 db_sql.db < gen_sql_data.sql ; } 2>> sqlite_results_ringbuf_128kb >> /dev/null
    echo "\n------------------------------------------\n" >> sqlite_results_ringbuf_128kb
done    

pkill python

ringbuf_size=1024

sudo python $IOTRACER_PATH -t sqlite --dir -i $inode -l b -size $ringbuf_size > trace_sqlite_ringbuf_4mb &
sleep 5

rm sqlite_results_ringbuf_4mb db_sql.db

for (( i = 0; i < $exec_count; i++)); do
    sudo sync; echo 3 > /proc/sys/vm/drop_caches 
    { time sqlite3 db_sql.db < gen_sql_data.sql ; } 2>> sqlite_results_ringbuf_4mb >> /dev/null
    echo "\n------------------------------------------\n" >> sqlite_results_ringbuf_4mb
done    

pkill python

ringbuf_size=32768

sudo python $IOTRACER_PATH -t sqlite --dir -i $inode -l b -size $ringbuf_size > trace_sqlite_ringbuf_128mb &
sleep 5

rm sqlite_results_ringbuf_128mb db_sql.db

for (( i = 0; i < $exec_count; i++)); do
    sudo sync; echo 3 > /proc/sys/vm/drop_caches 
    { time sqlite3 db_sql.db < gen_sql_data.sql ; } 2>> sqlite_results_ringbuf_128mb >> /dev/null
    echo "\n------------------------------------------\n" >> sqlite_results_ringbuf_128mb
done    

pkill python

ringbuf_size=262144

sudo python $IOTRACER_PATH -t sqlite --dir -i $inode -l b -size $ringbuf_size > trace_sqlite_ringbuf_1G &
sleep 5

rm sqlite_results_ringbuf_1G db_sql.db

for (( i = 0; i < $exec_count; i++)); do
    sudo sync; echo 3 > /proc/sys/vm/drop_caches 
    { time sqlite3 db_sql.db < gen_sql_data.sql ; } 2>> sqlite_results_ringbuf_1G >> /dev/null
    echo "\n------------------------------------------\n" >> sqlite_results_ringbuf_1G
done    

pkill python

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