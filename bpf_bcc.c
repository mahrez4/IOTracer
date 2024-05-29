
#include <linux/fs.h>
#include <linux/aio.h>
#include <linux/uio.h>
#include <linux/bio.h>
#include <linux/blk_types.h>
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
	char 	comm[16];
	char 	probe;
	char 	label; // E/L (Enter/Leave)
	u32 	inode;
	u32 	inodep;
};


BPF_PERF_OUTPUT(events);
BPF_HASH(counters, u64, u64);

ssize_t VFS_write_Entry(struct pt_regs *ctx,struct file * file, const char __user * buf, size_t count, loff_t * pos){
	unsigned long i_ino = file->f_inode->i_ino;
	char comm2[16];
	char comm1[16] = "FILTER_CMD";
	bpf_get_current_comm(&comm2, sizeof(comm2));
	if (__builtin_memcmp (comm1, comm2, 16) != 0)
		return 0;
		
	if(FILTER_FILE)
		return 0;

	unsigned long i_inop = file->f_path.dentry->d_parent->d_inode->i_ino;
	if(FILTER_DIR)
		return 0;

	uint64_t pid_tgid = bpf_get_current_pid_tgid();
	struct data_log log = {};
	log.timestamp = bpf_ktime_get_ns();
	log.address = file->f_pos;	
	log.size = count;
	log.tid = bpf_get_current_pid_tgid();
	log.pid = (pid_t)(pid_tgid >> 32);
	log.level = 'V';
	log.op  = 'W';
	log.probe = '1';
	log.label = 'E';
	log.inode = i_ino;
	log.inodep = i_inop;
	bpf_get_current_comm(&log.comm, sizeof(log.comm));
	//events.perf_submit(ctx, &log, sizeof(log));
	if (events.perf_submit(ctx, &log, sizeof(log)) != 0) {
		u64 key = 0;
		u64 init = 1;
    	u64 *value = counters.lookup(&key);
		if (value != 0) {
			*value = *value + 1;
		}
		else {
			counters.update(&key, &init);
		}
	}
	return 0;
}

ssize_t VFS_write_Leave(struct pt_regs *ctx,struct file * file, const char __user * buf, size_t count, loff_t * pos){
	char comm2[16];
	char comm1[16] = "FILTER_CMD";
	bpf_get_current_comm(&comm2, sizeof(comm2));
	if (__builtin_memcmp (comm1, comm2, 16) != 0)
		return 0;


	unsigned long i_ino  = file->f_inode->i_ino;
	
	if(FILTER_FILE)
		return 0;

	unsigned long i_inop = file->f_path.dentry->d_parent->d_inode->i_ino;
	if(FILTER_DIR)
		return 0;

	uint64_t pid_tgid = bpf_get_current_pid_tgid();
	struct data_log log = {};
	log.timestamp = bpf_ktime_get_ns();
	log.address = file->f_pos;	
	log.size = count;
	log.tid = bpf_get_current_pid_tgid();
	log.pid = (pid_t)(pid_tgid >> 32);
	log.level = 'V';
	log.op  = 'W';
	log.probe = '1';
	log.label = 'L';
	log.inode = i_ino;
	log.inodep = i_inop;
	bpf_get_current_comm(&log.comm, sizeof(log.comm));
	//events.perf_submit(ctx, &log, sizeof(log));
	if (events.perf_submit(ctx, &log, sizeof(log)) != 0) {
		u64 key = 1;
		u64 init = 1;
    	u64 *value = counters.lookup(&key);
		if (value != 0) {
			*value = *value + 1;
		}
		else {
			counters.update(&key, &init);
		}
	}
	return 0;
}

ssize_t VFS_read_Entry(struct pt_regs *ctx,struct file * file, const char __user * buf, size_t count, loff_t * pos){
	char comm2[16];
	char comm1[16] = "FILTER_CMD";
	bpf_get_current_comm(&comm2, sizeof(comm2));
	if (__builtin_memcmp (comm1, comm2, 16) != 0)
		return 0;
	unsigned long i_ino  = file->f_inode->i_ino;
	if(FILTER_FILE)
		return 0;
	unsigned long i_inop = file->f_path.dentry->d_parent->d_inode->i_ino;
	if(FILTER_DIR)
		return 0;
	uint64_t pid_tgid = bpf_get_current_pid_tgid();
	struct data_log log = {};
	log.timestamp = bpf_ktime_get_ns();
	log.address = file->f_pos;	
	log.size = count;
	log.tid = bpf_get_current_pid_tgid();
	log.pid = (pid_t)(pid_tgid >> 32);
	log.level = 'V';
	log.op  = 'R';
	log.probe = '2';
	log.label = 'E';
	log.inode = i_ino;
	log.inodep = i_inop;
	bpf_get_current_comm(&log.comm, sizeof(log.comm));
	//events.perf_submit(ctx, &log, sizeof(log));
	if (events.perf_submit(ctx, &log, sizeof(log)) != 0) {
		u64 key = 2;
		u64 init = 1;
    	u64 *value = counters.lookup(&key);
		if (value != 0) {
			*value = *value + 1;
		}
		else {
			counters.update(&key, &init);
		}
	}
	return 0;
}

ssize_t VFS_read_Leave(struct pt_regs *ctx,struct file * file, const char __user * buf, size_t count, loff_t * pos){
	char 	comm2[16];
	char comm1[16] = "FILTER_CMD";
	bpf_get_current_comm(&comm2, sizeof(comm2));
	if (__builtin_memcmp (comm1, comm2, 16) != 0)
		return 0;

	unsigned long i_ino  = file->f_inode->i_ino;
	if(FILTER_FILE)
		return 0;
	
	unsigned long i_inop = file->f_path.dentry->d_parent->d_inode->i_ino;
	if(FILTER_DIR)
		return 0;

	uint64_t pid_tgid = bpf_get_current_pid_tgid();
	struct data_log log = {};
	log.timestamp = bpf_ktime_get_ns();
	log.address = file->f_pos;	
	log.size = count;
	log.tid = bpf_get_current_pid_tgid();
	log.pid = (pid_t)(pid_tgid >> 32);
	log.level = 'V';
	log.op  = 'R';
	log.probe = '2';
	log.label = 'L';
	log.inode = i_ino;
	log.inodep = i_inop;
	bpf_get_current_comm(&log.comm, sizeof(log.comm));
	//events.perf_submit(ctx, &log, sizeof(log));
	if (events.perf_submit(ctx, &log, sizeof(log)) != 0) {
		u64 key = 3;
		u64 init = 1;
    	u64 *value = counters.lookup(&key);
		if (value != 0) {
			*value = *value + 1;
		}
		else {
			counters.update(&key, &init);
		}
	}
	return 0;
}

int generic_file_write_iter_Entry(struct pt_regs *ctx, struct kiocb *iocb, struct iov_iter *from){
	unsigned long i_ino  = iocb->ki_filp->f_inode->i_ino;
	
	if(FILTER_FILE)
		return 0;
	unsigned long i_inop = iocb->ki_filp->f_path.dentry->d_parent->d_inode->i_ino;
	if(FILTER_DIR)
		return 0;
	uint64_t pid_tgid = bpf_get_current_pid_tgid();
	struct data_log log = {};
	size_t s = iov_iter_count(from);
	log.timestamp = bpf_ktime_get_ns();
	log.address = iocb->ki_pos;
	log.size = from->count;
	log.tid = bpf_get_current_pid_tgid();
	log.pid = (pid_t)(pid_tgid >> 32);
	log.level = 'V';
	log.op  = 'W';
	log.probe = '7';
	log.label = 'E';
	log.inode = i_ino;
	log.inodep = i_inop;
	bpf_get_current_comm(&log.comm, sizeof(log.comm));
	//events.perf_submit(ctx, &log, sizeof(log));
	if (events.perf_submit(ctx, &log, sizeof(log)) != 0) {
		u64 key = 4;
		u64 init = 1;
    	u64 *value = counters.lookup(&key);
		if (value != 0) {
			*value = *value + 1;
		}
		else {
			counters.update(&key, &init);
		}
	}
	return 0;
}


int generic_file_write_iter_Leave(struct pt_regs *ctx, struct kiocb *iocb, struct iov_iter *from){
	char 	comm2[16];
	char comm1[16] = "FILTER_CMD";
	bpf_get_current_comm(&comm2, sizeof(comm2));
	if (__builtin_memcmp (comm1, comm2, 16) != 0)
		return 0;

	unsigned long i_ino  = iocb->ki_filp->f_inode->i_ino;
	
	if(FILTER_FILE)
		return 0;
	unsigned long i_inop = iocb->ki_filp->f_path.dentry->d_parent->d_inode->i_ino;
	if(FILTER_DIR)
		return 0;
	uint64_t pid_tgid = bpf_get_current_pid_tgid();
	struct data_log log = {};
	size_t s = iov_iter_count(from);
	log.timestamp = bpf_ktime_get_ns();
	log.address = iocb->ki_pos;
	log.size = from->count;
	log.tid = bpf_get_current_pid_tgid();
	log.pid = (pid_t)(pid_tgid >> 32);
	log.level = 'V';
	log.op  = 'W';
	log.probe = '7';
	log.label = 'L';
	log.inode = i_ino;
	log.inodep = i_inop;
	bpf_get_current_comm(&log.comm, sizeof(log.comm));
	//events.perf_submit(ctx, &log, sizeof(log));
	if (events.perf_submit(ctx, &log, sizeof(log)) != 0) {
		u64 key = 5;
		u64 init = 1;
    	u64 *value = counters.lookup(&key);
		if (value != 0) {
			*value = *value + 1;
		}
		else {
			counters.update(&key, &init);
		}
	}
	return 0;
}


int generic_file_read_iter_Entry(struct pt_regs *ctx, struct kiocb *iocb, struct iov_iter *iter){
	unsigned long i_ino  = iocb->ki_filp->f_inode->i_ino;
	
	if(FILTER_FILE)
		return 0;
	unsigned long i_inop = iocb->ki_filp->f_path.dentry->d_parent->d_inode->i_ino;
	if(FILTER_DIR)
		return 0;
	uint64_t pid_tgid = bpf_get_current_pid_tgid();
	struct data_log log = {};
	log.timestamp = bpf_ktime_get_ns();
	log.address = iocb->ki_pos; 
	log.size = iter->count;
	log.tid = bpf_get_current_pid_tgid();
	log.pid = (pid_t)(pid_tgid >> 32);
	log.level = 'V';
	log.op  = 'R';
	bpf_get_current_comm(&log.comm, sizeof(log.comm));
	log.probe = '9';
	log.label = 'E';
	log.inode = i_ino;
	log.inodep = i_inop;
	//events.perf_submit(ctx, &log, sizeof(log));
	if (events.perf_submit(ctx, &log, sizeof(log)) != 0) {
		u64 key = 6;
		u64 init = 1;
    	u64 *value = counters.lookup(&key);
		if (value != 0) {
			*value = *value + 1;
		}
		else {
			counters.update(&key, &init);
		}
	}
	return 0;
}


int generic_file_read_iter_Leave(struct pt_regs *ctx, struct kiocb *iocb, struct iov_iter *iter){
	char 	comm2[16];
	char comm1[16] = "FILTER_CMD";
	bpf_get_current_comm(&comm2, sizeof(comm2));
	if (__builtin_memcmp (comm1, comm2, 16) != 0)
		return 0;

	unsigned long i_ino  = iocb->ki_filp->f_inode->i_ino;
	
	if(FILTER_FILE)
		return 0;
	unsigned long i_inop = iocb->ki_filp->f_path.dentry->d_parent->d_inode->i_ino;
	if(FILTER_DIR)
		return 0;
	uint64_t pid_tgid = bpf_get_current_pid_tgid();
	struct data_log log = {};
	log.timestamp = bpf_ktime_get_ns();
	log.address = iocb->ki_pos; 
	log.size = iter->count;
	log.tid = bpf_get_current_pid_tgid();
	log.pid = (pid_t)(pid_tgid >> 32);
	log.level = 'V';
	log.op  = 'R';
	bpf_get_current_comm(&log.comm, sizeof(log.comm));
	log.probe = '9';
	log.label = 'L';
	log.inode = i_ino;
	log.inodep = i_inop;
	//events.perf_submit(ctx, &log, sizeof(log));
	if (events.perf_submit(ctx, &log, sizeof(log)) != 0) {
		u64 key = 7;
		u64 init = 1;
    	u64 *value = counters.lookup(&key);
		if (value != 0) {
			*value = *value + 1;
		}
		else {
			counters.update(&key, &init);
		}
	}
	return 0;
}


ssize_t btrfs_file_write_iter_Entry(struct pt_regs *ctx, struct kiocb *iocb, struct iov_iter *from){
	char comm2[16];
	char comm1[16] = "FILTER_CMD";
	bpf_get_current_comm(&comm2, sizeof(comm2));
	if (__builtin_memcmp (comm1, comm2, 16) != 0)
		return 0;
	unsigned long i_ino  = iocb->ki_filp->f_inode->i_ino;
	if(FILTER_FILE)
		return 0;
	unsigned long i_inop = iocb->ki_filp->f_path.dentry->d_parent->d_inode->i_ino;
	if(FILTER_DIR)
		return 0;
	uint64_t pid_tgid = bpf_get_current_pid_tgid();
	struct data_log log = {};
	size_t s = iov_iter_count(from);
	log.timestamp = bpf_ktime_get_ns();
	log.address = iocb->ki_pos;
	log.size = from->count;
	log.tid = bpf_get_current_pid_tgid();
	log.pid = (pid_t)(pid_tgid >> 32);
	log.level = 'F';
	log.op  = 'W';
	log.probe = '4';
	log.label = 'E';
	log.inode = i_ino;
	log.inodep = i_inop;
	bpf_get_current_comm(&log.comm, sizeof(log.comm));
	//events.perf_submit(ctx, &log, sizeof(log));
	if (events.perf_submit(ctx, &log, sizeof(log)) != 0) {
		u64 key = 8;
		u64 init = 1;
    	u64 *value = counters.lookup(&key);
		if (value != 0) {
			*value = *value + 1;
		}
		else {
			counters.update(&key, &init);
		}
	}
	return 0;
}


ssize_t btrfs_file_write_iter_Leave(struct pt_regs *ctx, struct kiocb *iocb, struct iov_iter *from){
	char comm2[16];
	char comm1[16] = "FILTER_CMD";
	bpf_get_current_comm(&comm2, sizeof(comm2));
	if (__builtin_memcmp (comm1, comm2, 16) != 0)
		return 0;

	unsigned long i_ino  = iocb->ki_filp->f_inode->i_ino;
	
	if(FILTER_FILE)
		return 0;
	unsigned long i_inop = iocb->ki_filp->f_path.dentry->d_parent->d_inode->i_ino;
	if(FILTER_DIR)
		return 0;
	uint64_t pid_tgid = bpf_get_current_pid_tgid();
	struct data_log log = {};
	size_t s = iov_iter_count(from);
	log.timestamp = bpf_ktime_get_ns();
	log.address = iocb->ki_pos;
	log.size = from->count;
	log.tid = bpf_get_current_pid_tgid();
	log.pid = (pid_t)(pid_tgid >> 32);
	log.level = 'F';
	log.op  = 'W';
	log.probe = '4';
	log.label = 'L';
	log.inode = i_ino;
	log.inodep = i_inop;
	bpf_get_current_comm(&log.comm, sizeof(log.comm));
	//events.perf_submit(ctx, &log, sizeof(log));
	if (events.perf_submit(ctx, &log, sizeof(log)) != 0) {
		u64 key = 9;
		u64 init = 1;
    	u64 *value = counters.lookup(&key);
		if (value != 0) {
			*value = *value + 1;
		}
		else {
			counters.update(&key, &init);
		}
	}
	return 0;
}


ssize_t btrfs_file_read_iter_Entry(struct pt_regs *ctx, struct kiocb *iocb, struct iov_iter *to){
	char comm2[16];
	char comm1[16] = "FILTER_CMD";
	bpf_get_current_comm(&comm2, sizeof(comm2));
	if (__builtin_memcmp (comm1, comm2, 16) != 0)
		return 0;

	unsigned long i_ino  = iocb->ki_filp->f_inode->i_ino;	
	if(FILTER_FILE)
		return 0;
	unsigned long i_inop = iocb->ki_filp->f_path.dentry->d_parent->d_inode->i_ino;
	if(FILTER_DIR)
		return 0;
	uint64_t pid_tgid = bpf_get_current_pid_tgid();
	struct data_log log = {};
	log.timestamp = bpf_ktime_get_ns();
	log.address = iocb->ki_pos; 
	log.size = to->count;
	log.tid = bpf_get_current_pid_tgid();
	log.pid = (pid_t)(pid_tgid >> 32);
	log.level = 'F';
	log.op  = 'R';
	bpf_get_current_comm(&log.comm, sizeof(log.comm));
	log.probe = '5';
	log.label = 'E';
	log.inode = i_ino;
	log.inodep = i_inop;
	//events.perf_submit(ctx, &log, sizeof(log));
	if (events.perf_submit(ctx, &log, sizeof(log)) != 0) {
		u64 key = 10;
		u64 init = 1;
    	u64 *value = counters.lookup(&key);
		if (value != 0) {
			*value = *value + 1;
		}
		else {
			counters.update(&key, &init);
		}
	}
	return 0;
}


ssize_t btrfs_file_read_iter_Leave(struct pt_regs *ctx, struct kiocb *iocb, struct iov_iter *to){
	char 	comm2[16];
	char comm1[16] = "FILTER_CMD";
	
	bpf_get_current_comm(&comm2, sizeof(comm2));
	if (__builtin_memcmp(comm1, comm2, 16) != 0)
		return 0;

	unsigned long i_ino  = iocb->ki_filp->f_inode->i_ino;
	
	if(FILTER_FILE)
		return 0;
	unsigned long i_inop = iocb->ki_filp->f_path.dentry->d_parent->d_inode->i_ino;
	if(FILTER_DIR)
		return 0;
	uint64_t pid_tgid = bpf_get_current_pid_tgid();
	struct data_log log = {};
	log.timestamp = bpf_ktime_get_ns();
	log.address = iocb->ki_pos; 
	log.size = to->count;
	log.tid = bpf_get_current_pid_tgid();
	log.pid = (pid_t)(pid_tgid >> 32);
	log.level = 'F';
	log.op  = 'R';
	bpf_get_current_comm(&log.comm, sizeof(log.comm));
	log.probe = '5';
	log.label = 'L';
	log.inode = i_ino;
	log.inodep = i_inop;
	events.perf_submit(ctx, &log, sizeof(log));
	return 0;
}
		
blk_qc_t submit_bio_Entry(struct pt_regs *ctx, struct bio* bio) {
	
	char comm2[16];
	char comm1[16] = "FILTER_CMD";
	bpf_get_current_comm(&comm2, sizeof(comm2));
	if (__builtin_memcmp(comm1, comm2, 16) != 0)
		return 0;
	
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

	uint64_t pid_tgid = bpf_get_current_pid_tgid();
	struct data_log log = {};
	log.timestamp = bpf_ktime_get_ns();
	log.address = bio->bi_iter.bi_sector; 
	log.size = ((bio->bi_iter).bi_size >> 9) * SECTOR_SIZE;
	log.tid = bpf_get_current_pid_tgid();
	log.pid = (pid_t)(pid_tgid >> 32);
	log.level = 'B';
	log.op  = (((bio->bi_opf & REQ_OP_MASK)) & 1) ? IO_WRITE_EVENT : IO_READ_EVENT;
	log.probe = '6';
	log.label = 'E';
	log.inode = i_ino;
	log.inodep = i_inop;
	
	bpf_get_current_comm(&log.comm, sizeof(log.comm));
	events.perf_submit(ctx, &log, sizeof(log));
	return 0;
}
		
blk_qc_t submit_bio_Leave(struct pt_regs *ctx, struct bio *bio){
	char comm2[16];
	char comm1[16] = "FILTER_CMD";
	bpf_get_current_comm(&comm2, sizeof(comm2));

	/********************************* NO FILTERING BECAUSE comm == swapper ***************************/
	/********************************* NO FILTERING BECAUSE comm == swapper ***************************/
	/********************************* NO FILTERING BECAUSE comm == swapper ***************************/

	//if (__builtin_memcmp (comm1, comm2, 16) != 0)
	//	return 0;
	
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
	struct data_log log = {};
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
	log.inodep = i_inop;
	
	bpf_get_current_comm(&log.comm, sizeof(log.comm));
	events.perf_submit(ctx, &log, sizeof(log));
	return 0;
}

/**********************************************************************************/
/**********************************************************************************/
/**********************************SYSCALLS****************************************/
/**********************************************************************************/
/**********************************************************************************/

struct my_syscalls_sys_enter_write {
	int __syscall_nr;
    unsigned int fd;
    const char * buf;
    size_t count;
};

int tp_sys_enter_write(struct my_syscalls_sys_enter_write *args) {
	char comm2[16];
	char comm1[16] = "FILTER_CMD";
	bpf_get_current_comm(&comm2, sizeof(comm2));
	if (__builtin_memcmp (comm1, comm2, 16) != 0)
		return 0;

	uint64_t pid_tgid = bpf_get_current_pid_tgid();
	struct data_log log = {};
	log.timestamp = bpf_ktime_get_ns();
	log.address = 888;
	log.size = args->count;
	log.tid = bpf_get_current_pid_tgid();
	log.pid = (pid_t)(pid_tgid >> 32);
	log.level = 'S';
	log.op  = 'W';
	log.probe = '0';
	log.label = 'E';
	log.inode = 888;
	log.inode = 888;
	bpf_get_current_comm(&log.comm, sizeof(log.comm));
	events.perf_submit(args, &log, sizeof(log));
	return 0;
}

int tp_sys_exit_write(struct my_syscalls_sys_enter_write *args) {
	char comm2[16];
	char comm1[16] = "FILTER_CMD";
	bpf_get_current_comm(&comm2, sizeof(comm2));
	if (__builtin_memcmp (comm1, comm2, 16) != 0)
		return 0;

	uint64_t pid_tgid = bpf_get_current_pid_tgid();
	struct data_log log = {};
	log.timestamp = bpf_ktime_get_ns();
	log.address = 888;
	log.size = args->count;
	log.tid = bpf_get_current_pid_tgid();
	log.pid = (pid_t)(pid_tgid >> 32);
	log.level = 'S';
	log.op  = 'W';
	log.probe = '0';
	log.label = 'L';
	log.inode = 888;
	log.inode = 888;
	bpf_get_current_comm(&log.comm, sizeof(log.comm));
	events.perf_submit(args, &log, sizeof(log));
	return 0;
}

int tp_sys_enter_read(struct my_syscalls_sys_enter_write *args) {
	char comm2[16];
	char comm1[16] = "FILTER_CMD";
	bpf_get_current_comm(&comm2, sizeof(comm2));
	if (__builtin_memcmp (comm1, comm2, 16) != 0)
		return 0;

	uint64_t pid_tgid = bpf_get_current_pid_tgid();
	struct data_log log = {};
	log.timestamp = bpf_ktime_get_ns();
	log.address = 888;
	log.size = args->count;
	log.tid = bpf_get_current_pid_tgid();
	log.pid = (pid_t)(pid_tgid >> 32);
	log.level = 'S';
	log.op  = 'R';
	log.probe = '0';
	log.label = 'E';
	log.inode = 888;
	log.inode = 888;
	bpf_get_current_comm(&log.comm, sizeof(log.comm));
	events.perf_submit(args, &log, sizeof(log));
	return 0;
}

int tp_sys_exit_read(struct my_syscalls_sys_enter_write *args) {
	char comm2[16];
	char comm1[16] = "FILTER_CMD";
	bpf_get_current_comm(&comm2, sizeof(comm2));
	if (__builtin_memcmp (comm1, comm2, 16) != 0)
		return 0;

	uint64_t pid_tgid = bpf_get_current_pid_tgid();
	struct data_log log = {};
	log.timestamp = bpf_ktime_get_ns();
	log.address = 888;
	log.size = args->count;
	log.tid = bpf_get_current_pid_tgid();
	log.pid = (pid_t)(pid_tgid >> 32);
	log.level = 'S';
	log.op  = 'R';
	log.probe = '0';
	log.label = 'L';
	log.inode = 888;
	log.inode = 888;
	bpf_get_current_comm(&log.comm, sizeof(log.comm));
	events.perf_submit(args, &log, sizeof(log));
	return 0;
}