# IOTracer

## Dependencies

### Ubuntu 22.04:
```
sudo apt-get install python3-pip bpfcc-tools linux-headers-$(uname -r)
```
```
sudo pip install prometheus-client
```

## Execution

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
sudo python3 bcc_iotracer.py -t fio --file -i [inode of fio file] -l vpfb > trace_fio
```

### Trace Postmark only

```
sudo python3 bcc_iotracer.py -t postmark --dir -i [inode of postmark dir] -l vpfb > trace_postmark
```

### Trace multiple tasks

```
sudo python3 bcc_iotracer.py -t fio,postmark,cat,dd -l vpfb > trace_comms
```

### Specify kernel api, userspace api and ringbuffer size:

Kernel api: output

Userspace api: poll

Ringbuffer size: 1024 pages

```
sudo python3 bcc_iotracer.py -k o -u p -size 1024 -l vb > trace_output
```

## Running tests

More details in [README](IOTracer_tests/README.md)