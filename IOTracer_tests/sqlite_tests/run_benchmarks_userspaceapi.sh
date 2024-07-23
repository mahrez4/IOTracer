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

rm sqlite_results_userspace_notracing db_sql.db

for (( i = 0; i < $exec_count; i++)); do
    sudo sync; echo 3 > /proc/sys/vm/drop_caches 
    { time sqlite3 db_sql.db < gen_sql_data.sql ; } 2>> sqlite_results_userspace_notracing >> /dev/null
    echo -e "\n-------------------------------------------------------------------\n" >> sqlite_results_userspace_notracing
    rm db_sql.db
done  

##########

userspace_api=p
rm sqlite_results_userspace_poll db_sql.db

for (( i = 0; i < $exec_count; i++)); do
    sudo python3 $IOTRACER_PATH -t sqlite --dir -i $inode -l s -u $userspace_api > traces_sqlite/userspace_api/trace_sqlite_userspace_poll_$i &
    sleep 4
    sudo sync; echo 3 > /proc/sys/vm/drop_caches 
    { time sqlite3 db_sql.db < gen_sql_data.sql ; } 2>> sqlite_results_userspace_poll >> /dev/null
    echo -e "\n-------------------------------------------------------------------\n" >> sqlite_results_userspace_poll
    sleep 4; pkill python3; sleep1;
    rm db_sql.db
done    



##########

userspace_api=c
rm sqlite_results_userspace_consume db_sql.db

for (( i = 0; i < $exec_count; i++)); do
    sudo python3 $IOTRACER_PATH -t sqlite --dir -i $inode -l s -u $userspace_api > traces_sqlite/userspace_api/trace_sqlite_userspace_consume_$i &
    sleep 4
    sudo sync; echo 3 > /proc/sys/vm/drop_caches 
    { time sqlite3 db_sql.db < gen_sql_data.sql ; } 2>> sqlite_results_userspace_consume >> /dev/null
    echo -e "\n-------------------------------------------------------------------\n" >> sqlite_results_userspace_consume
    sleep 4; pkill python3; sleep1;
    rm db_sql.db
done

##########

userspace_api=c
rm sqlite_results_userspace_consume-nowakeup db_sql.db

for (( i = 0; i < $exec_count; i++)); do
    sudo python3 $IOTRACER_PATH -t sqlite --dir -i $inode -l s -u $userspace_api -wkup n > traces_sqlite/userspace_api/trace_sqlite_userspace_consume-nowakeup_$i &
    sleep 4
    sudo sync; echo 3 > /proc/sys/vm/drop_caches 
    { time sqlite3 db_sql.db < gen_sql_data.sql ; } 2>> sqlite_results_userspace_consume-nowakeup >> /dev/null
    echo -e "\n-------------------------------------------------------------------\n" >> sqlite_results_userspace_consume-nowakeup
    sleep 4; pkill python3; sleep1;
done

##########

userspace_api=c
rm sqlite_results_userspace_consume-wakeup db_sql.db

for (( i = 0; i < $exec_count; i++)); do
    sudo python3 $IOTRACER_PATH -t sqlite --dir -i $inode -l s -u $userspace_api -wkup y > traces_sqlite/userspace_api/trace_sqlite_userspace_consume-wakeup_$i &
    sleep 4
    sudo sync; echo 3 > /proc/sys/vm/drop_caches 
    { time sqlite3 db_sql.db < gen_sql_data.sql ; } 2>> sqlite_results_userspace_consume-wakeup >> /dev/null
    echo -e "\n-------------------------------------------------------------------\n" >> sqlite_results_userspace_consume-wakeup
    sleep 4; pkill python3; sleep1;
done    

##########

userspace_api=c
rm sqlite_results_userspace_consume-sleep1s db_sql.db

for (( i = 0; i < $exec_count; i++)); do
    sudo python3 $IOTRACER_PATH -t sqlite --dir -i $inode -l s -u $userspace_api -sleep 1 > traces_sqlite/userspace_api/trace_sqlite_userspace_consume-sleep1s_$i &
    sleep 4
    sudo sync; echo 3 > /proc/sys/vm/drop_caches 
    { time sqlite3 db_sql.db < gen_sql_data.sql ; } 2>> sqlite_results_userspace_consume-sleep1s >> /dev/null
    echo -e "\n-------------------------------------------------------------------\n" >> sqlite_results_userspace_consume-sleep1s
    sleep 4; pkill python3; sleep1;
done    

##########

userspace_api=p
rm sqlite_results_userspace_poll-sleep1s db_sql.db

for (( i = 0; i < $exec_count; i++)); do
    sudo python3 $IOTRACER_PATH -t sqlite --dir -i $inode -l s -u $userspace_api -sleep 1 > traces_sqlite/userspace_api/trace_sqlite_userspace_poll-sleep1s_$i &
    sleep 4
    sudo sync; echo 3 > /proc/sys/vm/drop_caches 
    { time sqlite3 db_sql.db < gen_sql_data.sql ; } 2>> sqlite_results_userspace_poll-sleep1s >> /dev/null
    echo -e "\n-------------------------------------------------------------------\n" >> sqlite_results_userspace_poll-sleep1s
    sleep 4; pkill python3; sleep1;
done    

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