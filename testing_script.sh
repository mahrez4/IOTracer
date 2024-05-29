#!/usr/bin/sh

IOTRACER_PATH="/home/mhrz/pfe/tools/IOTracer/bcc_iotracer.py"

traced_path="/home/mhrz/pfe/tools/testfile"

fio_config="/home/mhrz/pfe/tools/fio_config.fio"

inode=`stat -c '%i' $traced_path`

rm fio_results_ringbuf_notracing

for (( i = 0; i < 20; i++)); do
    sudo sync; echo 3 > /proc/sys/vm/drop_caches 
    fio $fio_config >> fio_results_ringbuf_notracing
    echo \n------------------------------------------\n >> fio_results_ringbuf_notracing
done