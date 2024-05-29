import sys

def check_parameters(use_Perfbuf, use_Ringbuf, use_Submit, use_Output, use_Poll, use_Consume):
    if use_Perfbuf and use_Ringbuf:
        print("Error: cannot use perf buffer and ring buffer simultaneously.")
    if use_Submit and use_Output:
        print("Error: cannot use submit and output APIs simultaneously.")
    if use_Poll and use_Consume:
        print("Error: cannot use poll and submit APIs simultaneously.")
		
    #sys.exit()

def signal_handler(sig, frame):
	
	if store_RAM:
		print(trace)
	os.system('pkill python')
	print('Exiting...')
	sys.exit(0)

# afficher_evenement parses messages received from perf_buffer_poll
def afficher_evenement(cpu, data, size):
	global time  # Declare time as a global variable
	global csvwriter
	global store_RAM
	global trace
	s = ""
	# evenement = ct.cast(data, ct.POINTER(Data)).contents
	if time % 100 == 0:
		for k,v in b["counters"].items():
			s += f"ID {k.value}: {v.value}\t"
			v.value = 0
			#print(s)

	evenement = b["events"].event(data)

	## decode problem is with bio_endio (maybe due to the hashmap communication)
	log = (evenement.timestamp,evenement.level.decode('utf-8'),evenement.op.decode('utf-8'),evenement.address,evenement.size,\
	evenement.probe.decode('utf-8'),evenement.label.decode('utf-8'),evenement.pid, evenement.tid,\
	evenement.comm.decode('utf-8'), evenement.inode, evenement.inodep)

	format_ = "%.0f\t%s\t%s\t%-22.0f\t%-20.0f\t%s\t%s\t%d\t%d\t%s\t%.0f\t%.0f"
	
	#csvwriter.writerow(log)

	if store_RAM:
		trace.append(format_ % log)
	else:
		print(format_ % log)

	##prometheus state tracing

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
