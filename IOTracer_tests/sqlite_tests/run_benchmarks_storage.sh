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

########## 


rm sqlite_results_storage_notracing db_sql.db

for (( i = 0; i < $exec_count; i++)); do
    sudo sync; echo 3 > /proc/sys/vm/drop_caches 
    { time sqlite3 db_sql.db < gen_sql_data.sql ; } 2>> sqlite_results_storage_notracing >> /dev/null
    echo -e "\n-------------------------------------------------------------------\n" >> sqlite_results_storage_notracing
    rm db_sql.db
done  

##########

storage_device=d
rm sqlite_results_storage_disk db_sql.db

for (( i = 0; i < $exec_count; i++)); do 
    sudo python3 $IOTRACER_PATH -t sqlite --dir -i $inode -l s -s $storage_device > traces_sqlite/storage/trace_sqlite_storage_disk_$i &
    sleep 4
    sudo sync; echo 3 > /proc/sys/vm/drop_caches 
    { time sqlite3 db_sql.db < gen_sql_data.sql ; } 2>> sqlite_results_storage_disk >> /dev/null
    echo -e "\n-------------------------------------------------------------------\n" >> sqlite_results_storage_disk
    sleep 1; pkill python3; sleep1;
    rm db_sql.db
done    

##########

storage_device=r
rm sqlite_results_storage_ram db_sql.db

for (( i = 0; i < $exec_count; i++)); do
    sudo python3 $IOTRACER_PATH -t sqlite --dir -i $inode -l s -s $storage_device > /tmp/trace_sqlite_storage_ram_$i &
    sleep 4
    sudo sync; echo 3 > /proc/sys/vm/drop_caches 
    { time sqlite3 db_sql.db < gen_sql_data.sql ; } 2>> sqlite_results_storage_ram >> /dev/null
    echo -e "\n-------------------------------------------------------------------\n" >> sqlite_results_storage_ram
    sleep 1; pkill python3; sleep1;
    rm db_sql.db
done    


## Output file for storing extracted run times
output_file="run_times_storage.csv"

rm -rf $output_file
# Write header to the output file
header="Trace storage"
for (( i = 0; i < $exec_count; i++)); do
    header="$header,run_$i"
done

echo $header > "$output_file"

# Define the pattern to search for
pattern="time="

for file in sqlite_results_storage* ; do
    echo "Processing file: $file"
    
    api=$(echo $file | awk -F '_' '{print $4}')
    runs=$(grep "$pattern" "$file" | awk -F ' ' '{print $2}' | tr '\n' ',' | sed 's/,$//')
    echo "$api,$runs" >> "$output_file"
done

echo "Run times extracted to $output_file"