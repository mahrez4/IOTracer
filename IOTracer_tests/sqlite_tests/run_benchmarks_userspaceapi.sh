#!/usr/bin/sh

IOTRACER_PATH="../../bcc_iotracer.py"

traced_path="."

sqlite_config="./gen_sql_data.sql"

inode=`stat -c '%i' $traced_path`

TIMEFORMAT="time= %R"

exec_count=5

########## 

rm sqlite_results_userspace_notracing db_sql.db

for (( i = 0; i < $exec_count; i++)); do
    sudo sync; echo 3 > /proc/sys/vm/drop_caches 
    { time sqlite3 db_sql.db < gen_sql_data.sql ; } 2>> sqlite_results_userspace_notracing >> /dev/null
    echo "\n------------------------------------------\n" >> sqlite_results_userspace_notracing
done  

##########

userspace_api=p

    sudo python $IOTRACER_PATH -t sqlite --dir -i $inode -l b -u $userspace_api > trace_sqlite_userspace_poll &
sleep 5

rm sqlite_results_userspace_poll db_sql.db

for (( i = 0; i < $exec_count; i++)); do
    sudo sync; echo 3 > /proc/sys/vm/drop_caches 
    { time sqlite3 db_sql.db < gen_sql_data.sql ; } 2>> sqlite_results_userspace_poll >> /dev/null
    echo "\n------------------------------------------\n" >> sqlite_results_userspace_poll
done    

pkill python

##########

userspace_api=c

sudo python $IOTRACER_PATH -t sqlite --dir -i $inode -l b -u $userspace_api > trace_sqlite_userspace_consume &
sleep 5

rm sqlite_results_userspace_consume db_sql.db

for (( i = 0; i < $exec_count; i++)); do
    sudo sync; echo 3 > /proc/sys/vm/drop_caches 
    { time sqlite3 db_sql.db < gen_sql_data.sql ; } 2>> sqlite_results_userspace_consume >> /dev/null
    echo "\n------------------------------------------\n" >> sqlite_results_userspace_consume
done

pkill python

## Output file for storing extracted run times
output_file="run_times_userspace_api.csv"

rm -rf $output_file
# Write header to the output file
header="API"
for (( i = 0; i < $exec_count; i++)); do
    header="$header,run_$i"
done

echo $header > "$output_file"

# Define the pattern to search for
pattern="time="

for file in sqlite_results_userspace* ; do
    echo "Processing file: $file"
    
    api=$(echo $file | awk -F '_' '{print $4}')
    runs=$(grep "$pattern" "$file" | awk -F ' ' '{print $2}' | tr '\n' ',' | sed 's/,$//')
    echo "$api,$runs" >> "$output_file"
done

echo "Run times extracted to $output_file"