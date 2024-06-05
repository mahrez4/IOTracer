# IOTracer

## Dependencies:

### Ubuntu 22.04:
```
sudo apt-get install python3-pip bpfcc-tools linux-headers-$(uname -r)
```
```
sudo pip install prometheus-client
```

## Execution:

```
sudo python3 bcc_iotracer.py --help
```

```
sudo python3 bcc_iotracer.py [--dir/--file] -i [inode] -t [comm1,comm2,comm3...] -l [levels(v,p,f,b,s,d)] > trace_output
```

## Examples

### Trace all the system at the VFS, Page, FileSystem and Block levels

```
sudo python3 bcc_iotracer.py -l vpfb > trace_system
```
### Trace FIO only
 
```
sudo python3 bcc_iotracer.py -t fio --file -i [inode of fio file] -l vpfb > trace_output
```

### Trace Postmark only

```
sudo python bcc_iotracer.py -t postmark --dir -i [inode of postmark dir] -l vpfb > trace_postmark
```

### IOZONE

sudo python bcc_iotracer.py -t iozone --dir -i 25082 -l vpfbsd > trace_iozone ; iozone -I -i 0 -r 4k -s 500m

### dd
sudo python bcc_iotracer.py -t dd --dir -i 25082 -l vpfbsd > trace_dd; dd if=output1 of=output2 bs=4k count=100000 iflag=dsync  oflag=dsync conv=fdatasync

### cat
sudo python bcc_iotracer.py -t cat --dir -i 25082 -l vpfbsd > trace_cat

### cp
sudo python bcc_iotracer.py -t cp --dir -i 25082 -l vpfbsd > trace_cp

### YCSB 

sudo python bcc_iotracer.py -t java --dir -i 113 -l vpfbsd > trace_ycsb

sudo python bcc_iotracer.py -t mongod --dir -i 6586329 -l vpfb > trace_ycsb

### SQLITE

sudo python bcc_iotracer.py -t sqlite3 --file -i 7496544 -l vpfbs > trace_sqlite

********************************************

3878953
sudo ./iotracer.sh i 3080762 o trace_output_bcc l vb
