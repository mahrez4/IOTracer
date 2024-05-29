#!/usr/bin/sh

IOTRACER_PATH="../../bcc_iotracer.py"

mongosh < ycsb_datadir/drop_db

python2 ycsb_datadir/bin/ycsb load mongodb -s -P ycsb_datadir/workloads/workloadc -p mongodb.url=mongodb://localhost:27017/ycsb

exec_count=5

########## 

rm ycsb_results_userspace_notracing

for (( i = 0; i < $exec_count; i++)); do
    sudo sync; echo 3 > /proc/sys/vm/drop_caches 
    python2 ycsb_datadir/bin/ycsb run mongodb -s -P ycsb_datadir/workloads/workloadc -p mongodb.url=mongodb://localhost:27017/ycsb >> ycsb_results_userspace_notracing
    echo "\n------------------------------------------\n" >> ycsb_results_userspace_notracing
done  

##########

userspace_api=p

sudo python $IOTRACER_PATH -t Thread-,conn,java,mongod -l vfb -u $userspace_api > trace_ycsb_userspace_poll &
sleep 5

rm ycsb_results_userspace_poll

for (( i = 0; i < $exec_count; i++)); do
    sudo sync; echo 3 > /proc/sys/vm/drop_caches 
    python2 ycsb_datadir/bin/ycsb run mongodb -s -P ycsb_datadir/workloads/workloadc -p mongodb.url=mongodb://localhost:27017/ycsb >> ycsb_results_userspace_poll
    echo "\n------------------------------------------\n" >> ycsb_results_userspace_poll
done    

pkill python

##########

userspace_api=c

sudo python $IOTRACER_PATH -t Thread-,conn,java,mongod -l vfb -u $userspace_api > trace_ycsb_userspace_consume &
sleep 5

rm ycsb_results_userspace_consume

for (( i = 0; i < $exec_count; i++)); do
    sudo sync; echo 3 > /proc/sys/vm/drop_caches 
    python2 ycsb_datadir/bin/ycsb run mongodb -s -P ycsb_datadir/workloads/workloadc -p mongodb.url=mongodb://localhost:27017/ycsb >> ycsb_results_userspace_consume
    echo "\n------------------------------------------\n" >> ycsb_results_userspace_consume
done    

pkill python

#######

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


for file in ycsb_results_userspace*; do
    echo "Processing file: $file"
    api=$(echo "$file" | awk -F '_' '{print $4}')
    runs=$(grep "\[OVERALL\], RunTime(ms)," $file | awk -F", " '{print $3}'| sed -z 's/\n/,/g' | sed 's/\(.*\),/\1 /' )
    echo "$api,$runs" >> "$output_file"
done

echo "Run times extracted to $output_file"