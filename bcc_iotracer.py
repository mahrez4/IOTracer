#!/usr/bin/python

from bcc import BPF
import ctypes as ct
import argparse
import sys
import signal
import sys
import os
import platform
from subprocess import check_output 
from prometheus_client import start_http_server, Summary, Counter, Enum


############################################################################################
############################################################################################
###################################### Functions ###########################################
############################################################################################
############################################################################################

def check_args(uspc_args, krnl_args, strg_args):
	err = 0
	if 's' not in krnl_args and not 'o' in krnl_args and not krnl_args=="dflt":
		print("Error: unknown kernel API.",file=sys.stderr, flush=True)
		err = 1
	if 'p' not in uspc_args and not 'c' in uspc_args and not uspc_args=="dflt":
		print("Error: unkown userspace API.",file=sys.stderr, flush=True)
		err = 1
	if 'r' not in strg_args and not 'd' in strg_args and not strg_args=="dflt":
		print("Error: unkown trace storage technique.",file=sys.stderr, flush=True)
		err = 1
	if len(krnl_args) > 1 and not krnl_args=="dflt":
		print("Error: kernel argument should be one character",file=sys.stderr, flush=True)
		err = 1
	if len(uspc_args) > 1 and not uspc_args=="dflt": 
		print("Error: userspace argument should be one character",file=sys.stderr, flush=True)
		err = 1
	if err:
		sys.exit(0)

def check_parameters(use_Perfbuf, use_Ringbuf, use_Submit, use_Output, use_Poll, use_Consume):
	err = 0
	print(f"perfbuf: {use_Perfbuf}, ringbuf: {use_Ringbuf}, use_Submit: {use_Submit}, use_Output: {use_Output}, use_Poll: {use_Poll}, use_Consume: {use_Consume} ",file=sys.stderr,flush=True)
	if use_Perfbuf and use_Ringbuf:
		print("Error: cannot use perf buffer and ring buffer simultaneously.",file=sys.stderr, flush=True)
		err = 1
	if err:
		sys.exit(0)

def signal_handler_exit(sig, frame):
	if store_RAM:
		print(trace,flush=True)
	s = ""
	for k,v in b["loss_counters"].items():
		if k.value == 0:
			event = "VFS_write_Entry"
		elif k.value == 1:
			event = "VFS_write_Leave"
		elif k.value == 2:
			event = "VFS_read_Entry"
		elif k.value == 3:
			event = "VFS_read_Leave"
		elif k.value == 4:
			event = "generic_file_write_iter_Entry"
		elif k.value == 5:
			event = "generic_file_write_iter_Leave"
		elif k.value == 6:
			event = "generic_file_read_iter_Entry"
		elif k.value == 7:
			event = "generic_file_read_iter_Leave"
		elif k.value == 8:
			event = "fs_file_write_iter_Entry"
		elif k.value == 9:
			event = "fs_file_write_iter_Leave"
		elif k.value == 10:
			event = "fs_file_read_iter_Entry"
		elif k.value == 11:
			event = "fs_file_read_iter_Leave"
		elif k.value == 12:
			event = "submit_bio_Entry"
		elif k.value == 15:
			event = "tp_sys_enter_write"
		elif k.value == 16:
			event = "tp_sys_exit_write"
		elif k.value == 17:
			event = "tp_sys_enter_read"
		elif k.value == 18:
			event = "tp_sys_exit_read"
		elif k.value == 19:
			event = "tp_sys_enter_pwrite64"
		elif k.value == 20:
			event = "tp_sys_exit_pwrite64"
		elif k.value == 21:
			event = "tp_sys_enter_pread64"
		elif k.value == 22:
			event = "tp_sys_exit_pread64"
		elif k.value == 23:
			event = "tp_sys_enter_pwritev"
		elif k.value == 24:
			event = "tp_sys_exit_pwritev"
		elif k.value == 25:
			event = "tp_sys_enter_preadv"
		elif k.value == 26:
			event = "tp_sys_exit_preadv"
		elif k.value == 27:
			event = "tp_sys_enter_pwritev2"
		elif k.value == 28:
			event = "tp_sys_exit_pwritev2"
		elif k.value == 29:
			event = "tp_sys_enter_preadv2"
		elif k.value == 30:
			event = "tp_sys_exit_preadv2"
		s += f"\nevent={event} ID={k.value}: {v.value}\t/\t"
		v.value = 0
	print(s,flush=True)
	print('Exiting...',flush=True)
	#sys.exit(0)
	os._exit(1)
	#os.system("pkill -9 -f 'python.*[^ ]*bcc_iotracer.py'")
	#if sig == signal.SIGINT:
	#	os.system('pkill python')
	#else:
	#	sys.exit(0)


def get_filesystem_type(path):
    with open('/proc/mounts', 'r') as f:
        mounts = f.readlines()
    path = os.path.abspath(path)
    for mount in mounts:
        mount_info = mount.split()
        device, mount_point, fs_type = mount_info[0], mount_info[1], mount_info[2]
        if path.startswith(mount_point):
            return fs_type
    return None

def afficher_evenement(cpu, data, size):
	global time  
	global store_RAM
	global trace
	
	evenement = b["events"].event(data)

	## decode problem is with bio_endio (maybe due to the hashmap communication)
	log = (evenement.timestamp,evenement.level.decode('utf-8'),evenement.op.decode('utf-8'),evenement.address,evenement.size,\
	evenement.probe.decode('utf-8'),evenement.label.decode('utf-8'),evenement.pid, evenement.tid,\
	evenement.comm.decode('utf-8'), evenement.inode, evenement.inodep)

	format_ = "%.0f\t%s\t%s\t%-22.0f\t%-20.0f\t%s\t%s\t%d\t%d\t%s\t%.0f\t%.0f"
	
	if store_RAM:
		trace.append(format_ % log)
	else:
		print(format_ % log)

	## prometheus state tracing

	sta = "SYS"
	if log[6]=='E':
		c.labels(level=log[1],operation=log[2]).inc()
		if log[1] == 'S':
			sta = "SYS"
		elif log[1] == 'V':
			sta = "VFS"
		elif log[1] == 'F':
			sta = "FS"
		elif log[1] == 'P':
			sta = "PAGE"
		elif log[1] == 'B':
			sta = "BLK"
		
		if log[2] == 'R':
			sta += "_READ"
		else:
			sta += "_WRITE"

		e.state(sta)
	c_sizes.labels(size=int(log[4])).inc()
	time += 1

    #evenement = b["events"].event(data)
    #print("%.0f, %.0f, %.0f, %s, %s, %d, %s" ,evenement.timestamp,evenement.address,evenement.size,evenement.level,evenement.op,evenement.pid,evenement.comm)

############################################################################################
############################################################################################
#################################### Functions End #########################################
############################################################################################
############################################################################################

# arguments
examples ="""
	./bcc_iotracer.py -t task_name -f [-d] -i inode -l levels
	# trace task (specified by its pid) I/O on a dir/file inode. if dir is chosen, no recusivity is done
"""


parser = argparse.ArgumentParser(
    description="Trace VFS and Block I/O",
    formatter_class=argparse.RawDescriptionHelpFormatter,
    epilog=examples)

parser.add_argument("-t", "--task",
                    help="trace this task only")

parser.add_argument("-f","--file", action="store_true",
                    help="trace only this file")

parser.add_argument("-d","--dir", action="store_true",
                    help="trace all files of this directory, recursiviy is not allowed")

parser.add_argument("-i", "--inode",
                    help="trace this file inode or all children files inode")

parser.add_argument("-l", "--level",
                    help="trace specified levels: v for vfs, p for page cache, f for fs and b for block")

parser.add_argument('-e', "--exits",action='store_true',
					help="register function exit events")

parser.add_argument('-k', "--kernel",
					help="select kernel API o:output, s:submit")

parser.add_argument('-u', "--userspace",
					help="select userspace API p:poll, c:consume")

parser.add_argument('-s', "--storage",
					help="select trace storage r:ram, d:disk")

parser.add_argument('-size', "--bufsize",
					help="set ring buffer size in number of pages 32:128KB, 1024:4MB,32768:128MB,262144:1G")

args = parser.parse_args()
name = args.task
inode = args.inode
level = args.level
trace_exits = args.exits

#print("task task_name:",name)

#pid = int(check_output(["pidof","-s",name]))
pid=-1

#print("task pid = ",pid , "task name", name, "inode = ",inode)

program = ""

# code replacements

IOTracer_dir = os.path.abspath(os.path.dirname(__file__))
IOTracer_path = os.path.join(IOTracer_dir, "bcc_iotracer.bpf.c")
with open(IOTracer_path, 'r') as file:
	program = file.read()

## USE RINGBUFFER OR PERFBUFFER

use_Ringbuf = 1
use_Perfbuf = 0
 
if args.kernel:
	arg_krnl = args.kernel.lower()
	if 'o' in args.kernel.lower():
		use_Output = 1
		use_Submit = 0
	if 's' in args.kernel.lower():
		use_Submit = 1
		use_Output = 0
else:
	# default
	arg_krnl = "dflt"
	use_Submit = 1 
	use_Output = 0
	if use_Perfbuf:
		use_Submit = 0

if args.userspace:
	arg_uspc = args.userspace.lower()
	if 'p' in args.userspace.lower():
		use_Poll = 1
		use_Consume = 0
	if 'c' in args.userspace.lower():
		use_Consume = 1
		use_Poll = 0
else:
	# default
	arg_uspc= "dflt"
	use_Poll = 1  
	use_Consume = 0

 
if args.storage:
	arg_strg = args.storage.lower()
	if 'r' in args.storage.lower():
		store_RAM = 1
	else:
		store_RAM = 0
else:
	store_RAM = 0
	arg_strg = "dflt"

check_args(arg_uspc,arg_krnl,arg_strg)

if args.bufsize:
	program = program.replace('RINGBUF_PAGE_CNT', '%s' % args.bufsize)
else:
	program = program.replace('RINGBUF_PAGE_CNT', '32768')


if use_Ringbuf:
	program = program.replace('USE_PERFBUF_RINGBUF', '#define ringbuf')
if use_Perfbuf:  
	program = program.replace('USE_PERFBUF_RINGBUF', '#define perfbuf')
	program = program.replace('USE_SUBMIT_OUTPUT', '') # if perfbuf if defined submit and output aren't defined

if use_Submit:
	program = program.replace('USE_SUBMIT_OUTPUT', '#define submit')
if use_Output:
	program = program.replace('USE_SUBMIT_OUTPUT','#define output')

if args.task:
	tasks = args.task.split(",")
	program = program.replace("MAX_COMMS","#define MAX_CMDS "+str(len(tasks)))
	comms_define = "char cmds[MAX_CMDS][20] = {"
	comms_lengths = "int len[MAX_CMDS] = {"
	for i in range(0,len(tasks)):
		if i == len(tasks)-1:
			comms_define += '"'+ tasks[i] +'"'
			comms_lengths += str(len(tasks[i]))
		else:
			comms_define += '"'+ tasks[i] +'", '
			comms_lengths += str(len(tasks[i])) +', '
	comms_define += "};"
	comms_lengths += "};"
	program = program.replace('COMMS_LIST', comms_define)
	program = program.replace('COMM_LENGHTS', comms_lengths)
	program = program.replace('FILTER_PID', 'pid != %s' % pid)
	program = program.replace('FILTER_CMD', '%s' % name)
	program = program.replace('TRACE_APP','#define app_only')
    #print("FILTER_CMD")
else:
	program = program.replace("MAX_COMMS","#define MAX_CMDS 0")
	program = program.replace('TRACE_APP','')
	program = program.replace('COMMS_LIST','char cmds[1][20] = {};')
	program = program.replace('COMM_LENGHTS','int len[1];')
	
#---------------------------------------------------------------------------------------#	
#---------------------------------------------------------------------------------------#

if trace_exits:
	program = program.replace('FILTER_FILE', '0')
	program = program.replace('FILTER_DIR', '0')

#---------------------------------------------------------------------------------------#
#---------------------------------------------------------------------------------------#

if args.inode:
    #print("FILTER_INODE")
	if args.file:
		program = program.replace('FILTER_FILE', 'i_ino != %s' % args.inode)		
		program = program.replace('FILTER_DIR', '0')
	    #print("FILTER_FILE")

	elif args.dir:
		program = program.replace('FILTER_FILE', '0')
		program = program.replace('FILTER_DIR', 'i_inop != %s' % args.inode)
	    #print("FILTER_DIR",args.inode)
	else:
		print("you must specify the filter: -f for file or -d for directory")
		sys.exit()

else:
	program = program.replace('FILTER_FILE', '0')
	program = program.replace('FILTER_DIR', '0')
    #print("you must specify the traced dir/file inode")
    #sys.exit()

check_parameters(use_Perfbuf, use_Ringbuf, use_Submit, use_Output, use_Poll, use_Consume)
b = BPF(text = program)


# Attach kprobes to the functions

######### VFS probes ############ 

if(level.find('v')!=-1 or level.find('V')!=-1 ):
	print("activate vfs probes")
	b.attach_kprobe(event="vfs_write", fn_name="VFS_write_Entry")
	b.attach_kprobe(event="vfs_read", fn_name="VFS_read_Entry")
	if trace_exits:
		b.attach_kretprobe(event="vfs_write", fn_name="VFS_write_Leave")
		b.attach_kretprobe(event="vfs_read", fn_name="VFS_read_Leave")

######### Page cache probes ############
	
if(level.find('p')!=-1 or level.find('P')!=-1 ): 
	print("activate page cache probes")
	b.attach_kprobe(event="__generic_file_write_iter", fn_name="generic_file_write_iter_Entry")
	b.attach_kprobe(event="generic_file_read_iter", fn_name="generic_file_read_iter_Entry")
	if trace_exits:
		b.attach_kretprobe(event="__generic_file_write_iter", fn_name="generic_file_write_iter_Leave")
		b.attach_kretprobe(event="generic_file_read_iter", fn_name="generic_file_read_iter_Leave")

######### FS probes ############

script_dir = os.path.dirname(os.path.abspath(__file__))

fs_type = get_filesystem_type(script_dir)

#btrfs
if fs_type == 'btrfs':
	if(level.find('f')!=-1 or level.find('F')!=-1 ):
		print("activate fs probes")
		b.attach_kprobe(event="btrfs_file_write_iter", fn_name="fs_file_write_iter_Entry")
		b.attach_kprobe(event="btrfs_file_read_iter", fn_name="fs_file_read_iter_Entry")
		if trace_exits:
			b.attach_kretprobe(event="btrfs_file_write_iter", fn_name="fs_file_write_iter_Leave")
			b.attach_kretprobe(event="btrfs_file_read_iter", fn_name="fs_file_read_iter_Leave")
#ext4
elif fs_type == 'ext4':
	if(level.find('f')!=-1 or level.find('F')!=-1 ):
		print("activate fs probes")
		b.attach_kprobe(event="ext4_file_write_iter", fn_name="fs_file_write_iter_Entry")
		b.attach_kprobe(event="ext4_file_read_iter", fn_name="fs_file_read_iter_Entry")
		if trace_exits:
			b.attach_kretprobe(event="ext4_file_write_iter", fn_name="fs_file_write_iter_Leave")
			b.attach_kretprobe(event="ext4_file_read_iter", fn_name="fs_file_read_iter_Leave")


######### BLK probes ############ 
	
if(level.find('b')!=-1 or level.find('B')!=-1 ):
	print("activate block probes")
	b.attach_kprobe(event="submit_bio", fn_name="submit_bio_Entry")
	if trace_exits:
		#b.attach_kretprobe(event="submit_bio", fn_name="submit_bio_Leave") # X 
		b.attach_kprobe(event="bio_endio", fn_name="bio_endio_Entry")
	
	## Block level testing
	
	#b.attach_tracepoint(tp="block:block_rq_issue",fn_name="tp_blk_rq_issue")  # Y BLUE
	#b.attach_tracepoint(tp="block:block_rq_complete",fn_name="tp_blk_rq_complete") # Y BLUE
	#b.attach_tracepoint(tp="block:block_io_start",fn_name="tp_blk_io_start") # Z TEAL
	#b.attach_tracepoint(tp="block:block_io_done",fn_name="tp_blk_io_done") # Z TEAL
	#b.attach_kprobe(event="blk_mq_start_request", fn_name="kp_blk_mq_start_request") # A BLACK 
	#b.attach_kprobe(event="blk_mq_end_request", fn_name="kp_blk_mq_end_request") # A BLACK
	#b.attach_kprobe(event="block:block_bio_queue",fn_name="tp_blk_bio_queue") # A BLACK 
	#b.attach_kprobe(event="block:block_bio_complete",fn_name="tp_blk_bio_complete") # A BLACK


if (level.find('d')!=-1 or level.find('D')!=-1):
	print("activating device driver probes")
	#b.attach_tracepoint(tp="nvme:nvme_setup_cmd", fn_name="tp_nvme_setup_cmd")
	b.attach_tracepoint(tp="scsi:scsi_dispatch_cmd_start", fn_name="tp_scsi_dispatch_cmd_start")
	if trace_exits:
		#b.attach_tracepoint(tp="nvme:nvme_complete_rq", fn_name="tp_nvme_complete_rq")
		b.attach_tracepoint(tp="scsi:scsi_dispatch_cmd_done", fn_name="tp_scsi_dispatch_cmd_done")



if (level.find('s')!=-1 or level.find('S')!=-1):
	print("activating syscall probes")
	#read and write
	b.attach_tracepoint(tp="syscalls:sys_enter_write",fn_name="tp_sys_enter_write")
	b.attach_tracepoint(tp="syscalls:sys_enter_read",fn_name="tp_sys_enter_read")
	if trace_exits:
		b.attach_tracepoint(tp="syscalls:sys_exit_write",fn_name="tp_sys_exit_write")
		b.attach_tracepoint(tp="syscalls:sys_exit_read",fn_name="tp_sys_exit_read")
	
	# pread64 and pwrite64
	b.attach_tracepoint(tp="syscalls:sys_enter_pwrite64",fn_name="tp_sys_enter_pwrite64")
	b.attach_tracepoint(tp="syscalls:sys_enter_pread64",fn_name="tp_sys_enter_pread64")
	if trace_exits:
		b.attach_tracepoint(tp="syscalls:sys_exit_pwrite64",fn_name="tp_sys_exit_pwrite64")
		b.attach_tracepoint(tp="syscalls:sys_exit_pread64",fn_name="tp_sys_exit_pread64")	



#class Data(ct.Structure):
#_fields_ = [("timestamp", ct.c_ulonglong),("address", ct.c_ulonglong), ("size", ct.c_ulonglong), ("pid", ct.c_int), \
    #("level", ct.c_char), ("op", ct.c_char), ("comm", ct.c_char_p)]

time = 0

################################## PROMETHEUS ############################################


c = Counter('nb_events_level_op', 'Number Of Traced I/O Events',["level", "operation"])
c_sizes = Counter('rq_sizes','Number of requests having size x',["size"])
e = Enum('my_task_state', 'Description of enum',
        states=['NULL', 'SYS_READ', 'SYS_WRITE', 'VFS_READ', 'VFS_WRITE', 'FS_READ', 'FS_WRITE', 'BLK_READ','BLK_WRITE','PAGE_WRITE','PAGE_READ'])
e.state('NULL')

start_http_server(8000)

################################## PROMETHEUS ############################################


trace = []


##32 for 128KB
#256 for 1MB
##1024 for 4MB
#8192 for 32MB

if use_Perfbuf:
	b["events"].open_perf_buffer(afficher_evenement,page_cnt=8192)
if use_Ringbuf:
	b["events"].open_ring_buffer(afficher_evenement)

signal.signal(signal.SIGINT, signal_handler_exit)
signal.signal(signal.SIGTERM, signal_handler_exit)

# ------------------ Report traces to user -----------------------
# -------------------------------------------------------------------------
#print("Pour stopper eBPF ..... Ctrl+C")

while 1:
	try:
		if use_Perfbuf:
			b.perf_buffer_poll()
		if use_Ringbuf:
			if use_Poll:
				b.ring_buffer_consume()
			if use_Consume:
				b.ring_buffer_poll()
	except KeyboardInterrupt:
		exit()
