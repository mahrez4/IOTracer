
#include <linux/fs.h>
#include <linux/aio.h>
#include <linux/uio.h>
#include <linux/bio.h>
#include <linux/blk_types.h>
#include <linux/blk-mq.h>
//#include <linux/genhd.h>
#include <linux/dcache.h> 
#include <linux/path.h>
#include <linux/sched.h>
#include <linux/mm.h>
#include <linux/mm_types.h>
#include <linux/file.h>

#define DIO_PAGES		64
#define IO_READ_EVENT  ('R')
#define IO_WRITE_EVENT ('W')
#define SECTOR_SIZE 512
#define RWBS_LEN 8

USE_PERFBUF_RINGBUF
USE_SUBMIT_OUTPUT
TRACE_APP
MAX_COMMS
KERNEL_VERSION

struct dio {
	int flags;			/* doesn't change */
	int op;
	int op_flags;
	blk_qc_t bio_cookie;
	struct gendisk *bio_disk;
	struct inode *inode;
	loff_t i_size;			/* i_size when submitted */
	dio_iodone_t *end_io;		/* IO completion function */
	void *private;			/* copy from map_bh.b_private */
	/* BIO completion state */
	spinlock_t bio_lock;		/* protects BIO fields below */
	int page_errors;		/* errno from get_user_pages() */
	int is_async;			/* is IO async ? */
	bool defer_completion;		/* defer AIO completion to workqueue? */
	bool should_dirty;		/* if pages should be dirtied */
	int io_error;			/* IO error in completion path */
	unsigned long refcount;		/* direct_io_worker() and bios */
	struct bio *bio_list;		/* singly linked via bi_private */
	struct task_struct *waiter;	/* waiting task (NULL if none) */
	/* AIO related stuff */
	struct kiocb *iocb;		/* kiocb */
	ssize_t result;                 /* IO result */
	/*
		* pages[] (and any fields placed after it) are not zeroed out at
		* allocation time.  Don't add new fields after pages[] unless you
		* wish that they not be zeroed.
		*/
	union {
		struct page *pages[DIO_PAGES];	/* page buffer */
		struct work_struct complete_work;/* deferred AIO completion */
	};
};

struct data_log{
	u64 	timestamp;
	u64 	address;
	u64		size;
	int 	pid;
	int 	tid;
	char 	level; // VFS, FS, Page cache, Block
	char 	op; // R/W
	char 	comm[20];
	char 	probe;
	char 	label; // E/L (Enter/Leave)
	u32 	inode;
	u32 	inodep;
};

#ifdef perfbuf
	BPF_PERF_OUTPUT(events);
#endif

#ifdef ringbuf
	BPF_RINGBUF_OUTPUT(events, RINGBUF_PAGE_CNT);
#endif



BPF_HASH(loss_counters, u64, u64);
BPF_HASH(submit_bio_info, struct bio *, struct data_log);

int static filter_comm(char *comm)
{
	COMMS_LIST
	COMM_LENGHTS
	int filter = 1;
	for (int i = 0; i < MAX_CMDS; i++) {
		#ifdef kernel5
			bool match = true;
			for (int j = 0; j < len[i]; ++j) {
				if (comm[j] != cmds[i][j]) {
					match = false;
					break;
				}
			}

			if (match) {
				filter = 0;
				break;
			}
		#endif
		#ifdef kernel6
			if (__builtin_memcmp(comm, cmds[i], len[i]) == 0) {
				filter = 0;
			}
		#endif
	}	
    return filter;
}

int static inc_counter_lost_event(u64 key) {
	u64 init = 1;
	u64 *value = loss_counters.lookup(&key);
	if (value != 0) {
		*value = *value + 1;
	}
	else {
		loss_counters.update(&key, &init);
	}
	return 1;
}

ssize_t VFS_write_Entry(struct pt_regs *ctx,struct file * file, const char __user * buf, size_t count, loff_t * pos){
	unsigned long i_ino = file->f_inode->i_ino;

	char comm[20];
	#ifdef app_only
		bpf_get_current_comm(&comm, sizeof(comm));
		if (filter_comm(comm))
			return 1;
	#endif
	if(FILTER_FILE)
		return 0;

	unsigned long i_inop = file->f_path.dentry->d_parent->d_inode->i_ino;
	if(FILTER_DIR)
		return 0;

	#ifdef submit  
		struct data_log *log = events.ringbuf_reserve(sizeof(struct data_log));
		if (!log) {
			return inc_counter_lost_event(0);
		}
	#else
		struct data_log log_struct = {};
		struct data_log *log = &log_struct;
	#endif

	uint64_t pid_tgid = bpf_get_current_pid_tgid();
	log->timestamp = bpf_ktime_get_ns();
	log->address = file->f_pos;	
	log->size = count;
	log->tid = bpf_get_current_pid_tgid();
	log->pid = (pid_t)(pid_tgid >> 32);
	log->level = 'V';
	log->op  = 'W';
	log->probe = '1';
	log->label = 'E';
	log->inode = i_ino;
	log->inodep = i_inop;
	bpf_get_current_comm(&log->comm, sizeof(log->comm));

	#ifdef perfbuf
		if (events.perf_submit(ctx, log, sizeof(*log)) != 0) {
			return inc_counter_lost_event(0);
		}
	#endif

	#ifdef ringbuf
		#ifdef output
			if (events.ringbuf_output(log, sizeof(*log), 0 ) != 0) {
				return inc_counter_lost_event(0);
			}
		#endif
		#ifdef submit
			events.ringbuf_submit(log, 0);
		#endif
	#endif
	return 0;
}

ssize_t VFS_write_Leave(struct pt_regs *ctx,struct file * file, const char __user * buf, size_t count, loff_t * pos){
	char comm[20];
	#ifdef app_only
		bpf_get_current_comm(&comm, sizeof(comm));
		if (filter_comm(comm))
			return 1;
	#endif

	unsigned long i_ino  = file->f_inode->i_ino;
	
	//if(FILTER_FILE)
	//	return 0;
	unsigned long i_inop = file->f_path.dentry->d_parent->d_inode->i_ino;
	//if(FILTER_DIR)
	//	return 0;

	/********************************* NO FILTERING BECAUSE i_ino and i_inop = 0 ***************************/
	/********************************* NO FILTERING BECAUSE i_ino and i_inop = 0 ***************************/
	/********************************* NO FILTERING BECAUSE i_ino and i_inop = 0 ***************************/

	#ifdef submit 
		struct data_log *log = events.ringbuf_reserve(sizeof(struct data_log));
		if (!log) {
			return inc_counter_lost_event(1);
		}
	#else
		struct data_log log_struct = {};
		struct data_log *log = &log_struct;
	#endif

	uint64_t pid_tgid = bpf_get_current_pid_tgid();
	log->timestamp = bpf_ktime_get_ns();
	log->address = file->f_pos;	
	log->size = PT_REGS_RC(ctx);
	log->tid = bpf_get_current_pid_tgid();
	log->pid = (pid_t)(pid_tgid >> 32);
	log->level = 'V';
	log->op  = 'W';
	log->probe = '1';
	log->label = 'L';
	log->inode = i_ino;
	log->inodep = i_inop;
	bpf_get_current_comm(&log->comm, sizeof(log->comm));

	#ifdef perfbuf
		if (events.perf_submit(ctx, log, sizeof(*log)) != 0) {
			return inc_counter_lost_event(1);
		}
	#endif

	#ifdef ringbuf
		#ifdef output
			if (events.ringbuf_output(log, sizeof(*log), 0 ) != 0) {
				return inc_counter_lost_event(1);
			}
		#endif
		#ifdef submit
			events.ringbuf_submit(log, 0);
		#endif
	#endif
	return 0;

}

ssize_t VFS_read_Entry(struct pt_regs *ctx,struct file * file, const char __user * buf, size_t count, loff_t * pos){
	char comm[20];
	#ifdef app_only
		bpf_get_current_comm(&comm, sizeof(comm));
		if (filter_comm(comm))
			return 1;
	#endif
	unsigned long i_ino  = file->f_inode->i_ino;

	if(FILTER_FILE)
		return 0;
		
	unsigned long i_inop = file->f_path.dentry->d_parent->d_inode->i_ino;
	if(FILTER_DIR)
		return 0;

	#ifdef submit  
		struct data_log *log = events.ringbuf_reserve(sizeof(struct data_log));
		if (!log) {
			return inc_counter_lost_event(2);
		}
	#else
		struct data_log log_struct = {};
		struct data_log *log = &log_struct;
	#endif

	uint64_t pid_tgid = bpf_get_current_pid_tgid();
	log->timestamp = bpf_ktime_get_ns();
	log->address = file->f_pos;	
	log->size = count;
	log->tid = bpf_get_current_pid_tgid();
	log->pid = (pid_t)(pid_tgid >> 32);
	log->level = 'V';
	log->op  = 'R';
	log->probe = '2';
	log->label = 'E';
	log->inode = i_ino;
	log->inodep = i_inop;
	bpf_get_current_comm(&log->comm, sizeof(log->comm));

	#ifdef perfbuf
		if (events.perf_submit(ctx, log, sizeof(*log)) != 0) {
			return inc_counter_lost_event(2);
		}
	#endif

	#ifdef ringbuf
		#ifdef output
			if (events.ringbuf_output(log, sizeof(*log), 0 ) != 0) {
				return inc_counter_lost_event(2);
			}
		#endif
		#ifdef submit
			events.ringbuf_submit(log, 0);
		#endif
	#endif
	return 0;
	
}

ssize_t VFS_read_Leave(struct pt_regs *ctx,struct file * file, const char __user * buf, size_t count, loff_t * pos){
	char comm[20];
	#ifdef app_only
		bpf_get_current_comm(&comm, sizeof(comm));
		if (filter_comm(comm))
			return 1;
	#endif

	unsigned long i_ino  = file->f_inode->i_ino;

	//if(FILTER_FILE)
	//	return 0;
	unsigned long i_inop = file->f_path.dentry->d_parent->d_inode->i_ino;
	//if(FILTER_DIR)
	//	return 0;

	/********************************* NO FILTERING BECAUSE i_ino and i_inop = 0 ***************************/
	/********************************* NO FILTERING BECAUSE i_ino and i_inop = 0 ***************************/
	/********************************* NO FILTERING BECAUSE i_ino and i_inop = 0 ***************************/
	
	#ifdef submit  
		struct data_log *log = events.ringbuf_reserve(sizeof(struct data_log));
		if (!log) {
			return inc_counter_lost_event(3);
		}
	#else
		struct data_log log_struct = {};
		struct data_log *log = &log_struct;
	#endif


	uint64_t pid_tgid = bpf_get_current_pid_tgid();
	log->timestamp = bpf_ktime_get_ns();
	log->address = file->f_pos;	
	log->size = PT_REGS_RC(ctx);
	log->tid = bpf_get_current_pid_tgid();
	log->pid = (pid_t)(pid_tgid >> 32);
	log->level = 'V';
	log->op  = 'R';
	log->probe = '2';
	log->label = 'L';
	log->inode = i_ino;
	log->inodep = i_inop;
	bpf_get_current_comm(&log->comm, sizeof(log->comm));
	#ifdef perfbuf
		if (events.perf_submit(ctx, log, sizeof(*log)) != 0) {
			return inc_counter_lost_event(3);
		}
	#endif

	#ifdef ringbuf
		#ifdef output
			if (events.ringbuf_output(log, sizeof(*log), 0 ) != 0) {
				return inc_counter_lost_event(3);
			}
		#endif
		#ifdef submit
			events.ringbuf_submit(log, 0);
		#endif
	#endif
	return 0;
}

int generic_file_write_iter_Entry(struct pt_regs *ctx, struct kiocb *iocb, struct iov_iter *from){
	unsigned long i_ino  = iocb->ki_filp->f_inode->i_ino;
	
	char comm[20];
	#ifdef app_only
		bpf_get_current_comm(&comm, sizeof(comm));
		if (filter_comm(comm))
			return 1;
	#endif

	if(FILTER_FILE)
		return 0;
	unsigned long i_inop = iocb->ki_filp->f_path.dentry->d_parent->d_inode->i_ino;
	if(FILTER_DIR)
		return 0;

	#ifdef submit  
		struct data_log *log = events.ringbuf_reserve(sizeof(struct data_log));
		if (!log) {
			return inc_counter_lost_event(4);
		}
	#else
		struct data_log log_struct = {};
		struct data_log *log = &log_struct;
	#endif

	uint64_t pid_tgid = bpf_get_current_pid_tgid();
	size_t s = iov_iter_count(from);
	log->timestamp = bpf_ktime_get_ns();
	log->address = iocb->ki_pos;
	log->size = from->count;
	log->tid = bpf_get_current_pid_tgid();
	log->pid = (pid_t)(pid_tgid >> 32);
	log->level = 'P';
	log->op  = 'W';
	log->probe = '7';
	log->label = 'E';
	log->inode = i_ino;
	log->inodep = i_inop;
	bpf_get_current_comm(&log->comm, sizeof(log->comm));
	#ifdef perfbuf
		if (events.perf_submit(ctx, log, sizeof(*log)) != 0) {
			return inc_counter_lost_event(4);
		}
	#endif

	#ifdef ringbuf
		#ifdef output
			if (events.ringbuf_output(log, sizeof(*log), 0 ) != 0) {
				return inc_counter_lost_event(4);
			}
		#endif
		#ifdef submit
			events.ringbuf_submit(log, 0);
		#endif
	#endif
	return 0;
}


int generic_file_write_iter_Leave(struct pt_regs *ctx, struct kiocb *iocb, struct iov_iter *from){
	
	char comm[20];
	#ifdef app_only
		bpf_get_current_comm(&comm, sizeof(comm));
		if (filter_comm(comm))
			return 1;
	#endif

	unsigned long i_ino  = iocb->ki_filp->f_inode->i_ino;
	
	//if(FILTER_FILE)
	//	return 0;
	unsigned long i_inop = iocb->ki_filp->f_path.dentry->d_parent->d_inode->i_ino;
	//if(FILTER_DIR)
	//	return 0;

	/********************************* NO FILTERING BECAUSE i_ino and i_inop = 0 ***************************/
	/********************************* NO FILTERING BECAUSE i_ino and i_inop = 0 ***************************/
	/********************************* NO FILTERING BECAUSE i_ino and i_inop = 0 ***************************/

	#ifdef submit  
		struct data_log *log = events.ringbuf_reserve(sizeof(struct data_log));
		if (!log) {
			return inc_counter_lost_event(5);
		}
	#else
		struct data_log log_struct = {};
		struct data_log *log = &log_struct;
	#endif

	uint64_t pid_tgid = bpf_get_current_pid_tgid();
	size_t s = iov_iter_count(from);
	log->timestamp = bpf_ktime_get_ns();
	log->address = iocb->ki_pos;
	log->size = from->count;
	log->tid = bpf_get_current_pid_tgid();
	log->pid = (pid_t)(pid_tgid >> 32);
	log->level = 'P';
	log->op  = 'W';
	log->probe = '7';
	log->label = 'L';
	log->inode = i_ino;
	log->inodep = i_inop;
	bpf_get_current_comm(&log->comm, sizeof(log->comm));
	#ifdef perfbuf
		if (events.perf_submit(ctx, log, sizeof(*log)) != 0) {
			return inc_counter_lost_event(5);
		}
	#endif

	#ifdef ringbuf
		#ifdef output
			if (events.ringbuf_output(log, sizeof(*log), 0 ) != 0) {
				return inc_counter_lost_event(5);
			}
		#endif
		#ifdef submit
			events.ringbuf_submit(log, 0);
		#endif
	#endif
	return 0;
}


int generic_file_read_iter_Entry(struct pt_regs *ctx, struct kiocb *iocb, struct iov_iter *iter){
	unsigned long i_ino  = iocb->ki_filp->f_inode->i_ino;
	
	char comm[20];
	#ifdef app_only
		bpf_get_current_comm(&comm, sizeof(comm));
		if (filter_comm(comm))
			return 1;
	#endif

	if(FILTER_FILE)
		return 0;
	unsigned long i_inop = iocb->ki_filp->f_path.dentry->d_parent->d_inode->i_ino;
	if(FILTER_DIR)
		return 0;

	#ifdef submit  
		struct data_log *log = events.ringbuf_reserve(sizeof(struct data_log));
		if (!log) {
			return inc_counter_lost_event(6);
		}
	#else
		struct data_log log_struct = {};
		struct data_log *log = &log_struct;
	#endif

	uint64_t pid_tgid = bpf_get_current_pid_tgid();
	log->timestamp = bpf_ktime_get_ns();
	log->address = iocb->ki_pos; 
	log->size = iter->count;
	log->tid = bpf_get_current_pid_tgid();
	log->pid = (pid_t)(pid_tgid >> 32);
	log->level = 'P';
	log->op  = 'R';
	bpf_get_current_comm(log->comm, sizeof(log->comm));
	log->probe = '9';
	log->label = 'E';
	log->inode = i_ino;
	log->inodep = i_inop;

	#ifdef perfbuf
		if (events.perf_submit(ctx, log, sizeof(*log)) != 0) {
			return inc_counter_lost_event(6);
		}
	#endif

	#ifdef ringbuf
		#ifdef output
			if (events.ringbuf_output(log, sizeof(*log), 0 ) != 0) {
				return inc_counter_lost_event(6);
			}
		#endif
		#ifdef submit
			events.ringbuf_submit(log, 0);
		#endif
	#endif
	return 0;
}


int generic_file_read_iter_Leave(struct pt_regs *ctx, struct kiocb *iocb, struct iov_iter *iter){
	
	char comm[20];
	#ifdef app_only
		bpf_get_current_comm(&comm, sizeof(comm));
		if (filter_comm(comm))
			return 1;
	#endif

	unsigned long i_ino  = iocb->ki_filp->f_inode->i_ino;
	
	//if(FILTER_FILE)
	//	return 0;
	unsigned long i_inop = iocb->ki_filp->f_path.dentry->d_parent->d_inode->i_ino;
	//if(FILTER_DIR)
	//	return 0;

	/********************************* NO FILTERING BECAUSE i_ino and i_inop = 0 ***************************/
	/********************************* NO FILTERING BECAUSE i_ino and i_inop = 0 ***************************/
	/********************************* NO FILTERING BECAUSE i_ino and i_inop = 0 ***************************/

	#ifdef submit  
		struct data_log *log = events.ringbuf_reserve(sizeof(struct data_log));
		if (!log) {
			return inc_counter_lost_event(7);
		}
	#else
		struct data_log log_struct = {};
		struct data_log *log = &log_struct;
	#endif

	uint64_t pid_tgid = bpf_get_current_pid_tgid();
	log->timestamp = bpf_ktime_get_ns();
	log->address = iocb->ki_pos; 
	log->size = iter->count;
	log->tid = bpf_get_current_pid_tgid();
	log->pid = (pid_t)(pid_tgid >> 32);
	log->level = 'P';
	log->op  = 'R';
	bpf_get_current_comm(log->comm, sizeof(log->comm));
	log->probe = '9';
	log->label = 'L';
	log->inode = i_ino;
	log->inodep = i_inop;
	
	#ifdef perfbuf
		if (events.perf_submit(ctx, log, sizeof(*log)) != 0) {
			return inc_counter_lost_event(7);
		}
	#endif

	#ifdef ringbuf
		#ifdef output
			if (events.ringbuf_output(log, sizeof(*log), 0 ) != 0) {
				return inc_counter_lost_event(7);
			}
		#endif
		#ifdef submit
			events.ringbuf_submit(log, 0);
		#endif
	#endif
	return 0;
}


ssize_t btrfs_file_write_iter_Entry(struct pt_regs *ctx, struct kiocb *iocb, struct iov_iter *from){
	char comm[20];
	#ifdef app_only
		bpf_get_current_comm(&comm, sizeof(comm));
		if (filter_comm(comm))
			return 1;
	#endif
	unsigned long i_ino  = iocb->ki_filp->f_inode->i_ino;
	if(FILTER_FILE)
		return 0;
	unsigned long i_inop = iocb->ki_filp->f_path.dentry->d_parent->d_inode->i_ino;
	if(FILTER_DIR)
		return 0;

	#ifdef submit  
		struct data_log *log = events.ringbuf_reserve(sizeof(struct data_log));
		if (!log) {
			return inc_counter_lost_event(8);
		}
	#else
		struct data_log log_struct = {};
		struct data_log *log = &log_struct;
	#endif

	uint64_t pid_tgid = bpf_get_current_pid_tgid();
	size_t s = iov_iter_count(from);
	log->timestamp = bpf_ktime_get_ns();
	log->address = iocb->ki_pos;
	log->size = from->count;
	log->tid = bpf_get_current_pid_tgid();
	log->pid = (pid_t)(pid_tgid >> 32);
	log->level = 'F';
	log->op  = 'W';
	log->probe = '4';
	log->label = 'E';
	log->inode = i_ino;
	log->inodep = i_inop;
	bpf_get_current_comm(&log->comm, sizeof(log->comm));
	#ifdef perfbuf
		if (events.perf_submit(ctx, log, sizeof(*log)) != 0) {
			return inc_counter_lost_event(8);
		}
	#endif

	#ifdef ringbuf
		#ifdef output
			if (events.ringbuf_output(log, sizeof(*log), 0 ) != 0) {
				return inc_counter_lost_event(8);
			}
		#endif
		#ifdef submit
			events.ringbuf_submit(log, 0);
		#endif
	#endif
	return 0;
}


ssize_t btrfs_file_write_iter_Leave(struct pt_regs *ctx, struct kiocb *iocb, struct iov_iter *from){
	char comm[20];
	#ifdef app_only
		bpf_get_current_comm(&comm, sizeof(comm));
		if (filter_comm(comm))
			return 1;
	#endif

	unsigned long i_ino  = iocb->ki_filp->f_inode->i_ino;
	
	//if(FILTER_FILE)
	//	return 0;
	unsigned long i_inop = iocb->ki_filp->f_path.dentry->d_parent->d_inode->i_ino;
	//if(FILTER_DIR)
	//	return 0;

	/********************************* NO FILTERING BECAUSE i_ino and i_inop = 0 ***************************/
	/********************************* NO FILTERING BECAUSE i_ino and i_inop = 0 ***************************/
	/********************************* NO FILTERING BECAUSE i_ino and i_inop = 0 ***************************/

	#ifdef submit  
		struct data_log *log = events.ringbuf_reserve(sizeof(struct data_log));
		if (!log) {
			return inc_counter_lost_event(9);
		}
	#else
		struct data_log log_struct = {};
		struct data_log *log = &log_struct;
	#endif

	uint64_t pid_tgid = bpf_get_current_pid_tgid();
	size_t s = iov_iter_count(from);
	log->timestamp = bpf_ktime_get_ns();
	log->address = iocb->ki_pos;
	log->size = PT_REGS_RC(ctx);
	log->tid = bpf_get_current_pid_tgid();
	log->pid = (pid_t)(pid_tgid >> 32);
	log->level = 'F';
	log->op  = 'W';
	log->probe = '4';
	log->label = 'L';
	log->inode = i_ino;
	log->inodep = i_inop;
	bpf_get_current_comm(&log->comm, sizeof(log->comm));

	#ifdef perfbuf
		if (events.perf_submit(ctx, log, sizeof(*log)) != 0) {
			return inc_counter_lost_event(9);
		}
	#endif

	#ifdef ringbuf
		#ifdef output
			if (events.ringbuf_output(log, sizeof(*log), 0 ) != 0) {
				return inc_counter_lost_event(9);
			}
		#endif
		#ifdef submit
			events.ringbuf_submit(log, 0);
		#endif
	#endif
	return 0;
}


ssize_t btrfs_file_read_iter_Entry(struct pt_regs *ctx, struct kiocb *iocb, struct iov_iter *to){
	char comm[20];
	#ifdef app_only
		bpf_get_current_comm(&comm, sizeof(comm));
		if (filter_comm(comm))
			return 1;
	#endif

	unsigned long i_ino  = iocb->ki_filp->f_inode->i_ino;	
	if(FILTER_FILE)
		return 0;
	unsigned long i_inop = iocb->ki_filp->f_path.dentry->d_parent->d_inode->i_ino;
	if(FILTER_DIR)
		return 0;

	#ifdef submit  
		struct data_log *log = events.ringbuf_reserve(sizeof(struct data_log));
		if (!log) {
			return inc_counter_lost_event(10);
		}
	#else
		struct data_log log_struct = {};
		struct data_log *log = &log_struct;
	#endif

	uint64_t pid_tgid = bpf_get_current_pid_tgid();
	log->timestamp = bpf_ktime_get_ns();
	log->address = iocb->ki_pos; 
	log->size = to->count;
	log->tid = bpf_get_current_pid_tgid();
	log->pid = (pid_t)(pid_tgid >> 32);
	log->level = 'F';
	log->op  = 'R';
	bpf_get_current_comm(&log->comm, sizeof(log->comm));
	log->probe = '5';
	log->label = 'E';
	log->inode = i_ino;
	log->inodep = i_inop;

	#ifdef perfbuf
		if (events.perf_submit(ctx, log, sizeof(*log)) != 0) {
			return inc_counter_lost_event(10);
		}
	#endif

	#ifdef ringbuf
		#ifdef output
			if (events.ringbuf_output(log, sizeof(*log), 0 ) != 0) {
				return inc_counter_lost_event(10);
			}
		#endif
		#ifdef submit
			events.ringbuf_submit(log, 0);
		#endif
	#endif
	return 0;
}


ssize_t btrfs_file_read_iter_Leave(struct pt_regs *ctx, struct kiocb *iocb, struct iov_iter *to){
	char comm[20];
	#ifdef app_only
		bpf_get_current_comm(&comm, sizeof(comm));
		if (filter_comm(comm))
			return 1;
	#endif

	unsigned long i_ino  = iocb->ki_filp->f_inode->i_ino;
	
	//if(FILTER_FILE)
	//	return 0;
	unsigned long i_inop = iocb->ki_filp->f_path.dentry->d_parent->d_inode->i_ino;
	//if(FILTER_DIR)
	//	return 0;

	/********************************* NO FILTERING BECAUSE i_ino and i_inop = 0 ***************************/
	/********************************* NO FILTERING BECAUSE i_ino and i_inop = 0 ***************************/
	/********************************* NO FILTERING BECAUSE i_ino and i_inop = 0 ***************************/

	#ifdef submit  
		struct data_log *log = events.ringbuf_reserve(sizeof(struct data_log));
		if (!log) {
			return inc_counter_lost_event(11);
		}
	#else
		struct data_log log_struct = {};
		struct data_log *log = &log_struct;
	#endif

	uint64_t pid_tgid = bpf_get_current_pid_tgid();
	log->timestamp = bpf_ktime_get_ns();
	log->address = iocb->ki_pos; 
	log->size = PT_REGS_RC(ctx);
	log->tid = bpf_get_current_pid_tgid();
	log->pid = (pid_t)(pid_tgid >> 32);
	log->level = 'F';
	log->op  = 'R';
	bpf_get_current_comm(&log->comm, sizeof(log->comm));
	log->probe = '5';
	log->label = 'L';
	log->inode = i_ino;
	log->inodep = i_inop;

	#ifdef perfbuf
		if (events.perf_submit(ctx, log, sizeof(*log)) != 0) {
			return inc_counter_lost_event(11);
		}
	#endif

	#ifdef ringbuf
		#ifdef output
			if (events.ringbuf_output(log, sizeof(*log), 0 ) != 0) {
				return inc_counter_lost_event(11);
			}
		#endif
		#ifdef submit
			events.ringbuf_submit(log, 0);
		#endif
	#endif
	return 0;
}
		
blk_qc_t submit_bio_Entry(struct pt_regs *ctx, struct bio* bio) {
	
	char comm[20];
	#ifdef app_only
		bpf_get_current_comm(&comm, sizeof(comm));
		if (filter_comm(comm))
			return 1;
	#endif
	
	struct dio * dio = (struct dio *) bio->bi_private;
	//unsigned long i_ino  = dio->refcount;
	unsigned long i_ino  = bio->bi_io_vec->bv_page->mapping->host->i_ino;
	
	//if(FILTER_FILE)
	//	return 0;

	unsigned long i_inop = dio->iocb->ki_filp->f_path.dentry->d_parent->d_inode->i_ino;

	//if(FILTER_DIR)
	//	return 0;

	/********************************* NO FILTERING BECAUSE i_ino and i_inop = 0 ***************************/
	/********************************* NO FILTERING BECAUSE i_ino and i_inop = 0 ***************************/
	/********************************* NO FILTERING BECAUSE i_ino and i_inop = 0 ***************************/

	#ifdef submit  
		struct data_log *log = events.ringbuf_reserve(sizeof(struct data_log));
		if (!log) {
			return inc_counter_lost_event(12);
		}
	#else
		struct data_log log_struct = {};
		struct data_log *log = &log_struct;
	#endif

	uint64_t pid_tgid = bpf_get_current_pid_tgid();
	log->timestamp = bpf_ktime_get_ns();
	log->address = bio->bi_iter.bi_sector;
	log->size = ((bio->bi_iter).bi_size >> 9) * SECTOR_SIZE;
	log->tid = bpf_get_current_pid_tgid();
	log->pid = (pid_t)(pid_tgid >> 32);
	log->level = 'B';
	log->op  = (((bio->bi_opf & REQ_OP_MASK)) & 1) ? IO_WRITE_EVENT : IO_READ_EVENT;
	log->probe = '6';
	log->label = 'E';
	log->inode = i_ino;
	log->inodep = i_inop;
	bpf_get_current_comm(&log->comm, sizeof(log->comm));

	#ifdef perfbuf
		if (events.perf_submit(ctx, log, sizeof(*log)) != 0) {
			return inc_counter_lost_event(12);
		}
		//submit_bio_info.update(&bio, &log);
	#endif

	#ifdef ringbuf
		#ifdef output
			if (events.ringbuf_output(log, sizeof(*log), 0 ) != 0) {
				return inc_counter_lost_event(12);
			}
		#endif
		#ifdef submit
			events.ringbuf_submit(log, 0);
		#endif
		//submit_bio_info.update(&bio, log);
	#endif
	return 0;
}

blk_qc_t bio_endio_Entry(struct pt_regs *ctx, struct bio *bio){
	
	//char comm[20];
	//#ifdef app_only
	//	bpf_get_current_comm(&comm, sizeof(comm));
	//	if (filter_comm(comm))
	//		return 1;
	//#endif
	/********************************* NO FILTERING BECAUSE comm == swapper ***************************/
	/********************************* NO FILTERING BECAUSE comm == swapper ***************************/
	/********************************* NO FILTERING BECAUSE comm == swapper ***************************/
	
	
	struct dio * dio = (struct dio *) bio->bi_private;
	//unsigned long i_ino  = dio->inode->i_ino;
	unsigned long i_ino  = bio->bi_io_vec->bv_page->mapping->host->i_ino;
	
	//if(FILTER_FILE)
	//	return 0;
	unsigned long i_inop = dio->iocb->ki_filp->f_path.dentry->d_parent->d_inode->i_ino;
	//if(FILTER_DIR)
	//	return 0;

	/********************************* NO FILTERING BECAUSE i_ino and i_inop = 0 ***************************/
	/********************************* NO FILTERING BECAUSE i_ino and i_inop = 0 ***************************/
	/********************************* NO FILTERING BECAUSE i_ino and i_inop = 0 ***************************/
	
	uint64_t pid_tgid = bpf_get_current_pid_tgid();
	/*struct data_log log = {};
	log.timestamp = bpf_ktime_get_ns();
	log.address = bio->bi_iter.bi_sector; 
	log.size = ((bio->bi_iter).bi_size >> 9) * SECTOR_SIZE;
	log.tid = bpf_get_current_pid_tgid();
	log.pid = (pid_t)(pid_tgid >> 32);
	log.level = 'B';
	log.op  = (((bio->bi_opf & REQ_OP_MASK)) & 1) ? IO_WRITE_EVENT : IO_READ_EVENT;
	log.probe = '6';
	log.label = 'L';
	log.inode = i_ino;
	log.inodep = i_inop;*/
	

	struct data_log *log;
	log = submit_bio_info.lookup(&bio);
	if (!log) {
        return 0; 
    }

	submit_bio_info.delete(&bio);
	log->timestamp = bpf_ktime_get_ns();
	log->probe = '6';
	log->label = 'L';
	
	#ifdef perfbuf
		events.perf_submit(ctx, &log, sizeof(log));
	#endif

	#ifdef ringbuf
		events.ringbuf_output(&log, sizeof(log), 0 );
	#endif
	return 0;

/* 	***************************************************************************************
		
	#ifdef submit  
		struct data_log *log = events.ringbuf_reserve(sizeof(struct data_log));
		if (!log) {
			return inc_counter_lost_event(0);
		}
	#else
		struct data_log log_struct = {};
		struct data_log *log = &log_struct;
	#endif

	uint64_t pid_tgid = bpf_get_current_pid_tgid();
	log->timestamp = bpf_ktime_get_ns();
	log->address = file->f_pos;	
	log->size = count;
	log->tid = bpf_get_current_pid_tgid();
	log->pid = (pid_t)(pid_tgid >> 32);
	log->level = 'V';
	log->op  = 'W';
	log->probe = '1';
	log->label = 'E';
	log->inode = i_ino;
	log->inodep = i_inop;
	bpf_get_current_comm(log->comm, sizeof(log->comm));

	#ifdef perfbuf
		if (events.perf_submit(ctx, log, sizeof(*log)) != 0) {
			return inc_counter_lost_event(0);
		}
	#endif

	#ifdef ringbuf
		#ifdef output
			if (events.ringbuf_output(log, sizeof(*log), 0 ) != 0) {
				return inc_counter_lost_event(0);
			}
		#endif
		#ifdef submit
			events.ringbuf_submit(log, 0);
		#endif
	#endif
	return 0; */

}

int kp_blk_mq_start_request(struct pt_regs *ctx, struct request *req) {

	/********************************* NO FILTERING BECAUSE comm == swapper ***************************/
	/********************************* NO FILTERING BECAUSE comm == swapper ***************************/
	/********************************* NO FILTERING BECAUSE comm == swapper ***************************/

	char comm[20];
	#ifdef app_only
		bpf_get_current_comm(&comm, sizeof(comm));
		if (filter_comm(comm))
			return 1;
	#endif
	
	struct dio * dio = (struct dio *) req->bio->bi_private;
	//unsigned long i_ino  = dio->inode->i_ino;
	unsigned long i_ino  = req->bio->bi_io_vec->bv_page->mapping->host->i_ino;
	
	//if(FILTER_FILE)
	//	return 0;
	unsigned long i_inop = dio->iocb->ki_filp->f_path.dentry->d_parent->d_inode->i_ino;
	//if(FILTER_DIR)
	//	return 0;

	/********************************* NO FILTERING BECAUSE i_ino and i_inop = 0 ***************************/
	/********************************* NO FILTERING BECAUSE i_ino and i_inop = 0 ***************************/
	/********************************* NO FILTERING BECAUSE i_ino and i_inop = 0 ***************************/
	
	uint64_t pid_tgid = bpf_get_current_pid_tgid();
	struct data_log log = {};
	log.timestamp = bpf_ktime_get_ns();
	log.address = req->bio->bi_iter.bi_sector; 
	log.size = ((req->bio->bi_iter).bi_size >> 9) * SECTOR_SIZE;
	log.tid = bpf_get_current_pid_tgid();
	log.pid = (pid_t)(pid_tgid >> 32);
	log.level = 'A';
	log.op  = (((req->bio->bi_opf & REQ_OP_MASK)) & 1) ? IO_WRITE_EVENT : IO_READ_EVENT;
	log.probe = '6';
	log.label = 'E';
	log.inode = i_ino;
	log.inodep = i_inop;
	
	bpf_get_current_comm(&log.comm, sizeof(log.comm));
	#ifdef perfbuf
		events.perf_submit(ctx, &log, sizeof(log));
	#endif
	return 0;
}

int kp_blk_mq_end_request(struct pt_regs *ctx, struct request *req, blk_status_t error) {

	/********************************* NO FILTERING BECAUSE comm == swapper ***************************/
	/********************************* NO FILTERING BECAUSE comm == swapper ***************************/
	/********************************* NO FILTERING BECAUSE comm == swapper ***************************/

	char comm[20];
	#ifdef app_only
		bpf_get_current_comm(&comm, sizeof(comm));
		if (filter_comm(comm))
			return 1;
	#endif
	
	struct dio * dio = (struct dio *) req->bio->bi_private;
	//unsigned long i_ino  = dio->inode->i_ino;
	unsigned long i_ino  = req->bio->bi_io_vec->bv_page->mapping->host->i_ino;
	
	//if(FILTER_FILE)
	//	return 0;
	unsigned long i_inop = dio->iocb->ki_filp->f_path.dentry->d_parent->d_inode->i_ino;
	//if(FILTER_DIR)
	//	return 0;

	/********************************* NO FILTERING BECAUSE i_ino and i_inop = 0 ***************************/
	/********************************* NO FILTERING BECAUSE i_ino and i_inop = 0 ***************************/
	/********************************* NO FILTERING BECAUSE i_ino and i_inop = 0 ***************************/
	
	uint64_t pid_tgid = bpf_get_current_pid_tgid();
	struct data_log log = {};
	log.timestamp = bpf_ktime_get_ns();
	log.address = req->bio->bi_iter.bi_sector; 
	log.size = ((req->bio->bi_iter).bi_size >> 9) * SECTOR_SIZE;
	log.tid = bpf_get_current_pid_tgid();
	log.pid = (pid_t)(pid_tgid >> 32);
	log.level = 'A';
	log.op  = (((req->bio->bi_opf & REQ_OP_MASK)) & 1) ? IO_WRITE_EVENT : IO_READ_EVENT;
	log.probe = '6';
	log.label = 'E';
	log.inode = i_ino;
	log.inodep = i_inop;
	
	bpf_get_current_comm(&log.comm, sizeof(log.comm));
	#ifdef perfbuf
		events.perf_submit(ctx, &log, sizeof(log));
	#endif
	return 0;
}

/**********************************************************************************/
/**********************************************************************************/
/*****************************     SYSCALLS     ***********************************/
/**********************************************************************************/
/**********************************************************************************/

struct tp_syscalls_read_write {
	int __syscall_nr;
    unsigned int fd;
    const char * buf;
    size_t count;
};

struct tp_blk_rq_issue {
	dev_t dev;
    sector_t sector;
    unsigned int nr_sector;
    unsigned int bytes;
    char rwbs[8];
    char comm[20];
    //__data_loc char[] cmd;
};

struct tp_blk_rq_complete {
	dev_t dev;
    sector_t sector;
    unsigned int nr_sector;
    int error;
    char rwbs[8];
    //__data_loc char[] cmd;
};

struct tp_blk_bio_complete {
	dev_t dev;
    sector_t sector;
    unsigned nr_sector;
    int error;
    char rwbs[8];
};

struct tp_nvme_setup_cmd_struct {
	char disk[32];
    int ctrl_id;
    int qid;
    u8 opcode;
    u8 flags;
    u8 fctype;
    u16 cid;
    u32 nsid;
    bool metadata;
    u8 cdw10[24];
}; 

struct tp_nvme_complete_rq_struct {
	char disk[32];
    int ctrl_id;
    int qid;
    int cid;
    u64 result;
    u8 retries;
    u8 flags;
    u16 status;
};

///
///
/// READ AND WRITE SYSCALLS
///
///

int tp_sys_enter_write(struct tp_syscalls_read_write *args) {
	char comm[20];
	#ifdef app_only
		bpf_get_current_comm(&comm, sizeof(comm));
		if (filter_comm(comm))
			return 1;
	#endif

	uint64_t pid_tgid = bpf_get_current_pid_tgid();
	struct data_log log = {};
	log.timestamp = bpf_ktime_get_ns();
	log.address = -1;
	log.size = args->count;
	log.tid = bpf_get_current_pid_tgid();
	log.pid = (pid_t)(pid_tgid >> 32);
	log.level = 'S';
	log.op  = 'W';
	log.probe = '0';
	log.label = 'E';
	log.inode = -1;
	log.inode = -1;
	bpf_get_current_comm(&log.comm, sizeof(log.comm));
	#ifdef perfbuf
		events.perf_submit(args, &log, sizeof(log));
	#endif
	return 0;
}

int tp_sys_exit_write(struct tp_syscalls_read_write *args) {
	char comm[20];
	#ifdef app_only
		bpf_get_current_comm(&comm, sizeof(comm));
		if (filter_comm(comm))
			return 1;
	#endif

	uint64_t pid_tgid = bpf_get_current_pid_tgid();
	struct data_log log = {};
	log.timestamp = bpf_ktime_get_ns();
	log.address = -1;
	log.size = args->count;
	log.tid = bpf_get_current_pid_tgid();
	log.pid = (pid_t)(pid_tgid >> 32);
	log.level = 'S';
	log.op  = 'W';
	log.probe = '0';
	log.label = 'L';
	log.inode = -1;
	log.inode = -1;
	bpf_get_current_comm(&log.comm, sizeof(log.comm));
	#ifdef perfbuf
		events.perf_submit(args, &log, sizeof(log));
	#endif
	return 0;
}

int tp_sys_enter_read(struct tp_syscalls_read_write *args) {
	char comm[20];
	#ifdef app_only
		bpf_get_current_comm(&comm, sizeof(comm));
		if (filter_comm(comm))
			return 1;
	#endif

	uint64_t pid_tgid = bpf_get_current_pid_tgid();
	struct data_log log = {};
	log.timestamp = bpf_ktime_get_ns();
	log.address = -1;
	log.size = args->count;
	log.tid = bpf_get_current_pid_tgid();
	log.pid = (pid_t)(pid_tgid >> 32);
	log.level = 'S';
	log.op  = 'R';
	log.probe = '0';
	log.label = 'E';
	log.inode = -1;
	log.inode = -1;
	bpf_get_current_comm(&log.comm, sizeof(log.comm));
	#ifdef perfbuf
		events.perf_submit(args, &log, sizeof(log));
	#endif
	return 0;
}

int tp_sys_exit_read(struct tp_syscalls_read_write *args) {
	char comm[20];
	#ifdef app_only
		bpf_get_current_comm(&comm, sizeof(comm));
		if (filter_comm(comm))
			return 1;
	#endif

	uint64_t pid_tgid = bpf_get_current_pid_tgid();
	struct data_log log = {};
	log.timestamp = bpf_ktime_get_ns();
	log.address = -1;
	log.size = args->count;
	log.tid = bpf_get_current_pid_tgid();
	log.pid = (pid_t)(pid_tgid >> 32);
	log.level = 'S';
	log.op  = 'R';
	log.probe = '0';
	log.label = 'L';
	log.inode = -1;
	log.inode = -1;
	bpf_get_current_comm(&log.comm, sizeof(log.comm));
	#ifdef perfbuf
		events.perf_submit(args, &log, sizeof(log));
	#endif
	return 0;
}

///
///
/// BLOCK LEVEL  
///
///

int tp_blk_rq_issue(struct tp_blk_rq_issue *args) {
	char comm[20];
	//#ifdef app_only
	//	bpf_get_current_comm(&comm, sizeof(comm));
	//	if (filter_comm(comm))
	//		return 1;
	//#endif

	uint64_t pid_tgid = bpf_get_current_pid_tgid();
	struct data_log log = {};
	log.timestamp = bpf_ktime_get_ns();
	log.address = -1;
	log.size = args->bytes;
	log.tid = bpf_get_current_pid_tgid();
	log.pid = (pid_t)(pid_tgid >> 32);
	log.level = 'Y';
	log.op  = 'R';
	log.probe = '0';
	log.label = 'L';
	log.inode = -1;
	log.inode = -1;
	bpf_get_current_comm(&log.comm, sizeof(log.comm));
	#ifdef perfbuf
		events.perf_submit(args, &log, sizeof(log));
	#endif
	return 0;
}


int tp_blk_rq_complete(struct tp_blk_rq_complete *args) {
	char comm[20];
	#ifdef app_only
		bpf_get_current_comm(&comm, sizeof(comm));
		if (filter_comm(comm))
			return 1;
	#endif

	uint64_t pid_tgid = bpf_get_current_pid_tgid();
	struct data_log log = {};
	log.timestamp = bpf_ktime_get_ns();
	log.address = -1;
	log.size = args->nr_sector;
	log.tid = bpf_get_current_pid_tgid();
	log.pid = (pid_t)(pid_tgid >> 32);
	log.level = 'Y';
	log.op  = 'R';
	log.probe = '0';
	log.label = 'L';
	log.inode = -1;
	log.inode = -1;
	bpf_get_current_comm(&log.comm, sizeof(log.comm));
	#ifdef perfbuf
		events.perf_submit(args, &log, sizeof(log));
	#endif
	return 0;
}

int tp_blk_io_start(struct tp_blk_rq_issue *args) {
	char comm[20];
	//#ifdef app_only
	//	bpf_get_current_comm(&comm, sizeof(comm));
	//	if (filter_comm(comm))
	//		return 1;
	//#endif

	uint64_t pid_tgid = bpf_get_current_pid_tgid();
	struct data_log log = {};
	log.timestamp = bpf_ktime_get_ns();
	log.address = -1;
	log.size = args->bytes;
	log.tid = bpf_get_current_pid_tgid();
	log.pid = (pid_t)(pid_tgid >> 32);
	log.level = 'Z';
	log.op  = 'R';
	log.probe = '0';
	log.label = 'L';
	log.inode = -1;
	log.inode = -1;
	bpf_get_current_comm(&log.comm, sizeof(log.comm));
	#ifdef perfbuf
		events.perf_submit(args, &log, sizeof(log));
	#endif
	return 0;
}


int tp_blk_io_done(struct tp_blk_rq_complete *args) {
	char comm[20];
	#ifdef app_only
		bpf_get_current_comm(&comm, sizeof(comm));
		if (filter_comm(comm))
			return 1;
	#endif

	uint64_t pid_tgid = bpf_get_current_pid_tgid();
	struct data_log log = {};
	log.timestamp = bpf_ktime_get_ns();
	log.address = -1;
	log.size = args->nr_sector;
	log.tid = bpf_get_current_pid_tgid();
	log.pid = (pid_t)(pid_tgid >> 32);
	log.level = 'Z';
	log.op  = 'R';
	log.probe = '0';
	log.label = 'L';
	log.inode = -1;
	log.inode = -1;
	bpf_get_current_comm(&log.comm, sizeof(log.comm));
	#ifdef perfbuf
		events.perf_submit(args, &log, sizeof(log));
	#endif
	return 0;
}

int tp_blk_bio_queue(struct tp_blk_bio_complete *args) {
	char comm[20];
	//#ifdef app_only
	//	bpf_get_current_comm(&comm, sizeof(comm));
	//	if (filter_comm(comm))
	//		return 1;
	//#endif

	uint64_t pid_tgid = bpf_get_current_pid_tgid();
	struct data_log log = {};
	log.timestamp = bpf_ktime_get_ns();
	log.address = -1;
	log.size = 9090;
	log.tid = bpf_get_current_pid_tgid();
	log.pid = (pid_t)(pid_tgid >> 32);
	log.level = 'A';
	log.op  = 'R';
	log.probe = '0';
	log.label = 'E';
	log.inode = -1;
	log.inode = -1;
	bpf_get_current_comm(&log.comm, sizeof(log.comm));
	#ifdef perfbuf
		events.perf_submit(args, &log, sizeof(log));
	#endif
	return 0;
}

int tp_blk_bio_complete(struct tp_blk_bio_complete *args) {
	char comm[20];
	//#ifdef app_only
	//	bpf_get_current_comm(&comm, sizeof(comm));
	//	if (filter_comm(comm))
	//		return 1;
	//#endif

	uint64_t pid_tgid = bpf_get_current_pid_tgid();
	struct data_log log = {};
	log.timestamp = bpf_ktime_get_ns();
	log.address = -1;
	log.size = 9090;
	log.tid = bpf_get_current_pid_tgid();
	log.pid = (pid_t)(pid_tgid >> 32);
	log.level = 'A';
	log.op  = 'R';
	log.probe = '0';
	log.label = 'L';
	log.inode = -1;
	log.inode = -1;
	bpf_get_current_comm(&log.comm, sizeof(log.comm));
	#ifdef perfbuf
		events.perf_submit(args, &log, sizeof(log));
	#endif
	return 0;
}

///
/// DEVICE DRIVER 
///

/*	char disk[32]
    int ctrl_id
    int qid
    u8 opcode
    u8 flags
    u8 fctype
    u16 cid
    u32 nsid
    bool metadata
    u8 cdw10[24] */ 

int tp_nvme_setup_cmd(struct tp_nvme_setup_cmd_struct *args) {
	char comm[20];
	#ifdef app_only
		bpf_get_current_comm(&comm, sizeof(comm));
		if (filter_comm(comm))
			return 1;
	#endif

	uint64_t pid_tgid = bpf_get_current_pid_tgid();
	struct data_log log = {};
	bpf_trace_printk("disk %s : ctrl_id %d : qid  %d",args->disk, args->ctrl_id, args->qid);
	bpf_trace_printk("opcode %d : flags %d : fctype %d", args->opcode, args->flags, args->fctype);
	bpf_trace_printk("cid %d : nsid %d : cdw10 %s", args->cid, args->nsid, args->cdw10);

	log.timestamp = bpf_ktime_get_ns();
	log.address = -1;
	log.size = 9090;
	log.tid = bpf_get_current_pid_tgid();
	log.pid = (pid_t)(pid_tgid >> 32);
	log.level = 'D';
	log.op  = 'R';
	log.probe = '0';
	log.label = 'E';
	log.inode = -1;
	log.inode = -1;
	bpf_get_current_comm(&log.comm, sizeof(log.comm));
	#ifdef perfbuf
		events.perf_submit(args, &log, sizeof(log));
	#endif
	return 0;
}

int tp_nvme_complete_rq(struct tp_nvme_complete_rq_struct *args) {
	char comm[20];
	//#ifdef app_only
	//	bpf_get_current_comm(&comm, sizeof(comm));
	//	if (filter_comm(comm))
	//		return 1;
	//#endif

	uint64_t pid_tgid = bpf_get_current_pid_tgid();
	struct data_log log = {};
	log.timestamp = bpf_ktime_get_ns();
	log.address = -1;
	log.size = 9090;
	log.tid = bpf_get_current_pid_tgid();
	log.pid = (pid_t)(pid_tgid >> 32);
	log.level = 'D';
	log.op  = 'R';
	log.probe = '0';
	log.label = 'L';
	log.inode = -1;
	log.inode = -1;
	bpf_get_current_comm(&log.comm, sizeof(log.comm));
	#ifdef perfbuf
		events.perf_submit(args, &log, sizeof(log));
	#endif
	return 0;
}