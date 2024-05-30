#!/usr/bin/sh

IOTRACER_PATH="../../bcc_iotracer.py"

traced_path="."

sqlite_config="./gen_sql_data.sql"

inode=`stat -c '%i' $traced_path`

TIMEFORMAT="time= %R"

exec_count=5

########## 

rm sqlite_results_kernel_notracing db_sql.db

for (( i = 0; i < $exec_count; i++)); do
    sudo sync; echo 3 > /proc/sys/vm/drop_caches 
    { time sqlite3 db_sql.db < gen_sql_data.sql ; } 2>> sqlite_results_kernel_notracing >> /dev/null
    echo "\n------------------------------------------\n" >> sqlite_results_kernel_notracing
done  

kernel_api=o

sudo python $IOTRACER_PATH -t sqlite --file -i $inode -l b -k $kernel_api > trace_sqlite_kernel_output &
sleep 5

rm sqlite_results_kernel_output db_sql.db

for (( i = 0; i < $exec_count; i++)); do 
    sudo sync; echo 3 > /proc/sys/vm/drop_caches 
    { time sqlite3 db_sql.db < gen_sql_data.sql ; } 2>> sqlite_results_kernel_output >> /dev/null
    echo "\n------------------------------------------\n" >> sqlite_results_kernel_output
done    

pkill python

kernel_api=s

sudo python $IOTRACER_PATH -t sqlite --file -i $inode -l b -k $kernel_api > trace_sqlite_kernel_submit &
sleep 5

rm sqlite_results_kernel_submit db_sql.db

for (( i = 0; i < $exec_count; i++)); do
    sudo sync; echo 3 > /proc/sys/vm/drop_caches 
    { time sqlite3 db_sql.db < gen_sql_data.sql ; } 2>> sqlite_results_kernel_submit >> /dev/null
    echo "\n------------------------------------------\n" >> sqlite_results_kernel_submit
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
pattern="time="

for file in sqlite_results_kernel* ; do
    echo "Processing file: $file"
    
    api=$(echo $file | awk -F '_' '{print $4}')
    runs=$(grep "$pattern" "$file" | awk -F ' ' '{print $2}' | tr '\n' ',' | sed 's/,$//')
    echo "$api,$runs" >> "$output_file"
done

echo "Run times extracted to $output_file"