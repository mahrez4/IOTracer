# IOTracer

## dependencies: bpftrace

Installation:

`sudo apt-get update -y`

`sudo snap install --devmode bpftrace `

for more information: https://github.com/iovisor/bpftrace/blob/master/INSTALL.md

# On Debian:

`sudo apt install linux-headers-amd64 bpftrace`


## execution

`sudo bpftrace iotracer.bt [traced_command_name] [traced_file_inode] > trace_output`

sudo bpftrace iotracer.bt fio 3080762 > trace_output 

## Trace all the system 

sudo python bcc_iotracer.py -l vpfbsd > trace_system

sudo python bcc_iotracer.py -l vpfbsd |& tee trace_system

## MongoDB Directory without command filtering (all system):

sudo python bcc_iotracer.py --dir -i 4459594 -l vpfbsd > trace_mongod_dir

## FIO
 
sudo python bcc_iotracer.py -t fio --file -i 5181778 -l vpfbsd -e 1 > trace_output_bcc

## Postmark

echo 1 > /proc/sys/vm/drop_caches; sudo python bcc_iotracer.py -t postmark --dir -i 25082 -l b > trace_postmark

sudo python bcc_iotracer.py -t postmark --dir -i 25082 -l vpfbsd -e 1 > trace_postmark

sudo python bcc_iotracer.py -t postmark --dir -i 972 -l b > trace_postmark

sudo python bcc_iotracer.py -t postmark --dir -i 6413217 -l vpfbsd -e 1 > trace_postmark

## IOZONE

sudo python bcc_iotracer.py -t iozone --dir -i 25082 -l vpfbsd > trace_iozone ; iozone -I -i 0 -r 4k -s 500m

## dd
sudo python bcc_iotracer.py -t dd --dir -i 25082 -l vpfbsd > trace_dd; dd if=output1 of=output2 bs=4k count=100000 iflag=dsync  oflag=dsync conv=fdatasync

## cat
sudo python bcc_iotracer.py -t cat --dir -i 25082 -l vpfbsd > trace_cat

## cp
sudo python bcc_iotracer.py -t cp --dir -i 25082 -l vpfbsd > trace_cp

## YCSB 

sudo python bcc_iotracer.py -t java --dir -i 113 -l vpfbsd > trace_ycsb

sudo python bcc_iotracer.py -t mongod --dir -i 6586329 -l vpfb > trace_ycsb

sudo bpftrace -e 'tracepoint:syscalls:sys_enter_sendmsg { printf("Send: %s \t %d \t %d\n", comm, pid, tid); } tracepoint:syscalls:sys_enter_recvmsg { printf("Recv: %s \t %d \t %d\n", comm, pid, tid); }'

sudo bpftrace -e '
tracepoint:syscalls:sys_enter_sendmsg {
    $pid = pid;
    $saddr = ((struct sockaddr_in*)arg3)->sin_addr.s_addr;
    $daddr = ((struct sockaddr_in*)arg4)->sin_addr.s_addr;
    printf("Send: PID %d, Source IP: %s, Destination IP: %s\n", $pid, inet_ntoa($saddr), inet_ntoa($daddr));
}
tracepoint:syscalls:sys_enter_recvmsg {
    $pid = pid;
    $saddr = ((struct sockaddr_in*)arg3)->sin_addr.s_addr;
    $daddr = ((struct sockaddr_in*)arg4)->sin_addr.s_addr;
    printf("Recv: PID %d, Source IP: %s, Destination IP: %s\n", $pid, inet_ntoa($saddr), inet_ntoa($daddr));
}'


## SQLITE

sudo python bcc_iotracer.py -t sqlite3 --file -i 7496544 -l vpfbs > trace_sqlite

********************************************

3878953
sudo ./iotracer.sh i 3080762 o trace_output_bcc l vb
