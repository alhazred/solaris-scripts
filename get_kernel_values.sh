#!/bin/ksh

#
# Script to get predefined kernel tunables
#
# $Log: get_kernel_values,v $
# Revision 1.2  2003/09/03 21:40:29  MS35068
# *** empty log message ***
#
# Revision 1.1  2003/09/03 21:39:42  MS35068
# Initial revision
#
# Written by Matthew Baker
#            Matthew.Baker@med.ge.com

HEX=0
P_32VALUE=D
P_64VALUE=E

if (( $# ))
then
	if [[ "$1" == "-x" ]]
	then
		HEX=1

	elif [[ "$1" == "-V" ]]
	then
		clear
		cat <<- EOF | more

		NOTE: ***NOT*** all kernel values can be changed dynamically!!!

		Watch: 32bit or 64bit kernel:
		/usr/bin/isainfo -kv  # see if 32 or 64 bit

		if 32,  64 bit
		   D       E
		   X       J
		   W       Z
			
		  D - long decimal, E - 8 bytes unsigned
		  X - 4 bytes hex,  J - 8 byes hex
		  W - 4-byte write, Z - 8-byte write to address
		
		To change, 

		use: adb -kw /dev/ksyms /dev/mem
		then i.e.: ncsize/W 0t8000
		then i.e.: max_page_get/Z 0x1ad3
		then i.e.: slowscan/Z 0x190    #set slowcan to 400

		or
		
		echo 'ncsize/W 0t8000' | adb -kw
		
		To list all possible kernel values:
			/usr/ccs/bin/nm /platform/`uname -m`/kernel/*unix | more
		EOF
		exit 0

	elif [[ "$1" == "-v" ]]
	then
		cat <<- EOF | more

			Last Updated: 12/21/2001
			ND - NOT Dynamic (needs reboot - modify in /etc/system)
			D - Dynamic (can change on active/running system, still need /etc/system to survive a reboot)

			NOTE: memory changes (as in slowcan, fastscan, ...  Will be lost if a memory DR occurs and they are not in the /etc/system file)


			autoup - ND: max age of any memory-resident pages that have been modified [def: 30, range: 4-240]

			bufhwm - ND: max amount of memory for caching I/O buffers [def: 2% of phys mem, range: 80KB to 20% of phys mem]

			cachefree - obsolete

			coredefault - x

			consistent_coloring - D: method to use for external CPU cache (0-uses virtual address bits, 1-physical address is set to virtual address, 2-bin hopping, 6-SBSD page coloring scheme)

			desfree - D:  amount of memory desired to be free at all time on the system [def: lotsfree/2, range: greater of 1/64 of physmem or 512 KB, range: default - 15% of physical memory]

			dnlc_dir_enable - D: enables large directory caching [def: 1, range: 0-1]

			dnlc_dir_min_size - D: min number of entries before caching one directory [def: 40, range: 0-MAXUNIT(no maximum)] 

			dnlc_dir_max_size - D: max number of entries cached for one directory [def: MAXUNIT (no maximum), range: 0-MAXUNIT] 

			doiflush - D: flush memory or not [def: 1, range:0-1]

			dopageflush - D: flush memory or not [def: 1, range:0-1]

			fastscan - D: max number of pages per secon the system looks at when scanning and pressure is high [def: lesser of 64MB and 1/2 of phys mem, range: 1 - 1/2 of phys mem]

			handspreadpages - D: two-hand clock [def: fastscan, range: 1-number of phys memory pages]

			hires_tick - ND: kernel clock tick resolution [def: 0, range: 0-1]

			ipc_tcp_conn_hash_size - ND: controls the hash table size in the IP module for all active (ESTABLISHED) TCP connections [def: 512 range: 512-1073741824]

			ip_icmp_err_interval & ip_icmp_err_burst - D: control rate of IP in generating ICMP error messages [def: 100 ms for interval, 10 for burst range: 0-99999 ms for interval, 1-99999 for burst]

			ip_forwarding & ip6_forwarding - D: control whether IP does forwarding between interfaces: [def: 0 (off), range: 0-1]

			 ip_forwarding & ip6_forwarding - D: control whether IP does forwarding for a particular interface: [def: 0 (off), range: 0-1]

			ip_respond_to_echo_broadcast & ip6_respond_to_echo_broadcast - D: control whether IP responds to broadcast ICMPv4 echo request or multicast ICMPv6 echo request: [def: 1 (on), range: 0-1]

			ip_send_redirects & ip6_send_redirects - D: control whether IP sends out a ICMP redirect message [def: 1 (on), range: 0-1]

			ip_forward_src_routed & ip6_forward_src_routed - D: Control whether IPv4 or IPv6 forwards packets with source IPv4 routing options or IPv6 routing headers [def: 1 (on), range: 0-1]

			ip_addrs_per_if - D: max num of logical interfaces assoc with real interface [def:256, range: 1-8192]

			ip_strict_dst_multihoming & ip6_strict_dst_multihoming - D: Determine whether a packet arriving on a non-forwarding interface can be accepted for an IP address that is not explicitly configured on that interface. If ip_forwarding is enabled, or xxx:ip_forwarding for the appropriate interfaces is enabled, then this parameter is ignored, because the packet is actually forwarded. [def: 0 (loose multihoming), range: 0-1(strict multihoming)]

			kmem_flags - D: debugging kernel flags [def: 0 (off), range: 0,1,2,4,8,256]

			kobj_map_space_len - D: Amount of kernel memory allocated to store symbol table info.  [def: 1Mb]

			lotsfree - D: Initial trigger for system pageing to beign (page scanner)[def: greater of 1/64 of physmem or 512 KB, range: default - max_number_of_phys_mem_pages ]

			lwp_default_stksize - D, size of the kernel stack for lwps (size in bytes and should be multiple of PAGESIZE) [0-262144]

			max_nprocs - ND, max number of processes that be can created (this value is used in computing others) [def: 10 + 16 * maxusers, range: 266-maxpid]

			max_page_get - D: limits the max num of pages that can be alloced in a system.  [def: half the number of pages in system, range: ???]

			maxpgio - ND: max num of page I/O requests than can be queued by paging system (divided by 4 to get the actual max used) [def: 40, range: 1-1024]

			maxphys - D (but may not effect all loaded structures): [def: 131072(sun4u), range: pagesize - MAXINT]

			maxpid | pidmax - ND: largets possible PID (solaris 8 and greater) [def: 30000, range: 266-999,999]

			maxuprc - ND: per user process limit [def: reserved_procs, range: 1-max_nprocs]

			maxusers - ND: system wide calculation value taken from RAM size (def: lesser of the amount of memory in MB and 2048, range in /etc/system: 8-4096)

			minfree - D: minimum acceptable memory level. [def: desfree/2, range: greater of 1/256 of physmem or 128 KB, range: default - max physical memory pages (7.5% of memory)]

			min_percent_cpu - D: min percent of CPU that pageout can consume [def: 4, range: 1-80] 

			moddebug - D: debug module loading process [def: 0 (off), common: 2,4,8] 

			ngroups_max - max number of supplementary groups per user

			ncsize - ND: directory name lookup cache - DNLC [def: 4 * (v.v_proc + maxusers) + 320, range: 0 - MAXINT]

			ndquot - ND: number of quota structure for UFS that should be allocated [def: maxusers * 40 / 4 + max_nprocs, range: 0 - MAXINT]

			noexec_user_stack - D: mark stack as not executable - for security (only needed for 32 bit only, 64 bit apps have it by default) [def: 0 (off), range: 0-1]

			nrnode - ND: max num of rnodes allocated  (NFS inode) [def: ncsize, range: ???]

			nstrpush - D: number of modules that can be inserted (pushed) into a tream [def: 9, range 9-16]

			npty - ND: total number of 4.0|4.1 pseudo-ttys configed [def: 48, range: ???]

			pageout_reserve - D: Number of pages reserved for the exclusive use of the pageout or scheduler threads.  [def: throttlefree/2, range: The minimum value is 64 Kbytes or 1/512th of physical memory, whichever is greater, expressed as pages. (no more than 2% of phys mem) ]

			pages_pp_maximum - D: number of pages the system require to be unlocked [def: max of triplet (200, tune_t_minarmem + 100, (10% of memory avail at boot)), max: 20% of phys mem]

			pages_before_pager - ND: part of sys threshold that immediately frees pages after an I/O completes instead of storing pages for possible reuse [def: 200, range:1-phys mem]

			physmem - D: size of physical memory [1-size_of_memory]

			priority_paging - ND: PRE 2.8, enabling the system to place a boundary around the file cache (ensure that FS I/O does not cause application paging)

			pt_cnt - ND: total number of 5.7 pseudo-ttys configsed [def: 0, range: 0 - MAXPID]

			pt_pctofmem: ND: max percent of phys mem that can be used by /dev/pts entries.  64 bit kernel uses 176 bytes per /dev/pts, 32 bit 112 bytes [def: 5, range: 0-100]

			pt_max_pty: D: max number of pty the system offers [def: 0 (uses system defined max (see pt_cnt), range: 0 - MAXUNIT]

			rechoose_interval - D: number of clock ticks before a process is deemed to have lost all affinity for the last CPU it ran on.  After this interval expires, any CPU is considered a candidate for scheduling a thread.  Valid only for threads.  [def: 3, range: 0 - MAXINT] 

			reserved_procs - ND: number of system process slots to be reserved in PID table for UID 0 process [def: 5, range: 5 - MAXINT]

			rlim_fd_cur - ND: current file descriptor (files open) limit (soft ulimit) def: 256, range: 1 - MAXINT)

			rlim_fd_max - ND: maximum file descriptor (files open) limit (hard ulimit) [def: 1024, range: 1 - MAXINT]

			rstchown - D: allow chown by users other than root [def:1 (on - can't chown unless root), range: 0-1]

			sadcnt - number of sad devices

			nautopush - ND: number of sad autopush structures [def:32]

			segkpsize - ND: amount of kernel pageable memory available primarily for kernel threads [def: 32_bit_kernel#512MB, 64_bit#2GB, range: 32_bit#512MB, 64_bit#512MB-2GB]

			slowscan - D: min number of pages per secon that the system looks at when reclaiming memory [def: lesser of 1/20 of phys mem or 100, range: 1 to fastscan/2 ]

			strmsgsz - D: max number of bytes a single system call can pass to a STREAM to be placed in the data part of a message.  If a write exceeds this size, it is broken into multiple messages [def: 65,536, range 0-262144]

			strctlsz - D: max number of bytes a single system call can pass to a STREAM to be placed in the control part of a message. [def: 1024, range 0-MAXINT]

			swapfs_reserve: N: when allocating for actual need on backing store, it keeps the system from deadlock if there is excessive consumption [def: lesser of 4MB or 1/16 phys mem, range: default - max number of phys mem pages]

			swapfs_minfree: N: amount of phys mem that is desired to be kept free for the rest of the system [def: larger of 2MB and 1/8 of phys mem, range: 1 - phys mem]

			throttlefree - D: memory level at which blocking memory allocation requests are put to sleep (def: minfree, range: greater of 1/256 of physmem or 128 KB, range: default - max physical memory pages (4% of physical memory) ]

			timer_max - ND: number of POSIX timers available [def: 32, range: 0 - MAXINT]

			tune_t_flckrec - max number of active frlocks

			tune_t_fsflushr - ND: fsflush run interval [1 - MAXINT]

			tune_t_gpgslo - ND: page stealing low water mark, see /usr/include/sys/tuneable.h

			tune_t_minarmem - ND: min available resident (not swappable) memory needed to avoid deadlock (in pages) [def: 25, range: 1-phys_mem)

			tune_t_minasmem - min available swappable memory needed to avoid deadlock (in pages) 

			tcp_conn_hash_size - ND: controls the hash table size in the tcp module for all tcp connections (def: 512 range: 512-1073741824)

			tcp_deferred_ack_interval - D: time-out value for tcp delayed ACKs time in milliseconds [def: 100, range: 1ms-1minute]

			tcp_deferred_acks_max - D: The maximum number of TCP segments (in units of maximum segment size MSS for individual connections) received before an acknowledgment (ACK) is generated. If set to 0 or 1, it means no delayed ACKs, assuming all segments are 1 MSS long.  Note that for remote destinations (not directly connected), the maximum number is fixed to 2, no matter what this parameter is set to. The actual number is dynamically calculated for each connection. The value is the default maximum. [def: 8, range: 0-16]

			tcp_wscale_always - D: If set to 1, TCP always sends SYN segment with the window scale option, even if the option value is 0. Note that if TCP receives a SYN segment with the window scale option, even if the parameter is set to 0, TCP responds with a SYN segment with the window scale option, and the option value is set according to the receive window size. [def: 0 (off), range: 0-1]]

			tcp_tstamp_always - D: If set to 1, TCP always sends SYN segment with the timestamp option. Note that if TCP receives a SYN segment with the timestamp option, TCP responds with a SYN segment with the timestamp option even if the parameter is set to 0. [def: 0 (off), range: 0-1]]

			tcp_xmit_hiwat - D: The default send window size in bytes. Refer to the following discussion of per-route metrics for setting a different value on a per route basis. [def: 16384, range: 4096-1073741824]

			tcp_recv_hiwat - D: The default receive window size in bytes. Refer to the following discussion of per-route metrics for setting a different value on a per-route basis. [def: 24576, range: 2048-1073741824]

			tcp_max_buf - D: The maximum buffer size in bytes. It controls how large the send and receive buffers are set to by an application using [def: 1048576, range: 8192 - 1073741824]

			tcp_cwnd_max - D: max value TCP congestion window (cwnd) in bytes [def: 1048576, range: 128-1073741824]

			tcp_slow_start_initial - D: DO NOT CHANGE! The maximum initial congestion window (cwnd) size in MSS of a TCP connection. 

			tcp_slow_start_after_idle - D: The congestion window size in MSS of a TCP connection after it has been idled (no segment received) for a period of one retransmission timeout (RTO). [def: 4, range: 1-16384]

			tcp_sack_permitted - D: If set to 2, TCP always sends SYN segment with the selective acknowledgment (SACK) permitted option. If TCP receives a SYN segment with a SACK-permitted option and this parameter is set to 1, TCP responds with a SACK-permitted option. If the parameter is set to 0, TCP does not send a SACK-permitted option, regardless of whether the incoming segment contains the SACK permitted option or not. [def: 2, range: 0 (disabled), 1 (passive enabled), 2 (active enabled)]

			tcp_rev_src_routes - D: If set to 0, TCP does not reverse the IP source routing option for incoming connections for security reasons. If set to 1, TCP does the normal reverse source routing. [def: 0 (off), range: 0-1]

			tcp_time_wait_interval - D: The time in milliseconds a TCP connection stays in TIME-WAIT state. Replaced tcp_close_wait_interval.  See by "ndd -get /dev/tcp | grep tcp_time_wait_interval". [def: 4 minutes, range: 1 second - 10 minutes]

			tcp_conn_req_max_q - D: The default maximum number of pending TCP connections for a TCP listener waiting to be accepted by accept(3SOCKET) [def: 128, range 1-4294967296]

			tcp_conn_req_max_q0 - D: The default maximum number of incomplete (three-way handshake not yet finished) pending TCP connections for a TCP listener. [def: 1024, range 1-4294967296]

			tcp_conn_req_min - D: The default minimum value of the maximum number of pending TCP connection requests for a listener waiting to be accepted. This is the lowest maximum value of listen(3SOCKET) an application can use. [def: 1, range: 1-1024]

			tmpfs_maxkmem - D: max amount of kernel memory that TMPFS can use for its datastructures (tmpnodes and directory entries) [range: number of bytes in one page to 25% of available kernel memory]

			tmpfs_minfree - D: min amount of swap space the TMPFS leaves for reset of system [def: 256Bytes, range: 0 - max swap space size]

			udp_xmit_hiwat - D: def max UDP socket datagram size in bytes [def: 8192, range: 4096, 65536]

			udp_recv_hiwat - D: def max UDP socket receive size in bytes [def: 8192, range: 4096, 65536]

			ufs_ninode - D: number of inodes to be help in memory [def: ncsize, range: 0 - MAXINT]

			ufs_LW - D: unflushed UFS data Low Water mark [def: 256 * 1024, range: 0 - MAXINT]

			ufs_HW - D: unflushed UFS data High Water mark  [def: 384 * 1024, range: 0 - MAXINT]

			ufs_WRITES - D: If ufs_WRITES is non-zero, the number of bytes outstanding for writes on a file is checked. See ufs_HW subsequently to determine whether the write should be issued or should be deferred until only ufs_LW bytes are outstanding. The total number of bytes outstanding is tracked on a per-file basis so that if the limit is passed for one file, it won't affect writes to other files. [def: 1 (on), range: 0-1]

			seminfo_semaem - ND: max value that a semaphore value in an undo structure can be set to [def: 16384, range: 1-65535]

			seminfo_semmsl - ND: max number of SV semaphores per semaphore identifier [def: 25, range: 1 - MAXINT]

			seminfo_semmap - ND: number of entries in the semaphore map [def: 10]

			seminfo_semmni - ND: max number of semaphore identifiers [def: 10, range: 1-65535]

			seminfo_semmns - ND: max number of SV semaphores on system [def: 60, range: 1 - MAXINT]

			seminfo_semmnu - ND: total number of undo structures supported by SV semaphore system [def: 30, range: 1 - MAXINT]

			seminfo_semopm - ND: max number of SV semaphone operations per semop call.  (number of sembufs in the sops array that is provided to the semop sys call) [def: 10, range: 1 - MAXINT]

			seminfo_semume - ND: max number of SV semaphore undo structures that can be undo by any one process [def: 10, range: 1 - MAXINT]

			seminfo_semvmx - ND: max value a semaphone can be set to [def: 32767, range: 1-65535]

			shminfo_shmmin - ND: DO NOT CHANGE! min size of SV shared memory segment that can be created [def: 1, range: 0-phys mem]

			shminfo_shmmni - ND: sys wide limit on num of shared memory segments that can be created [def: 100, range: 0 - MAXINT]

			shminfo_shmmax - ND: max size of SV shared memory segment that can be created [def: 1048576, range: 32bit# 0 - MAXINT, 64bit# 0 - MAXINT64]

			shminfo_shmseg - ND: limit on num of shared memory segments that any one process can create [def: 6, range: 0-32767]

			segspt_minfree - ND: pages of sys memory that cannot be allocated for ISM shared memory [def: 5% of avail sys memory when first ISM segment is created, range: 0-32767]

			scsi_options - see /usr/include/sys/scsi/targets/ssddef.h

			sd_io_time - see /usr/include/sys/scsi/targets/ssddef.h 

			sd_max_throttle - see /usr/include/sys/scsi/targets/ssddef.h 

		EOF
		exit 0

	else
		print "Usage: $0 [-v|-V|-x|-h]"
		print "       No args - print out kernel values"
		print "       where -v describes what the kernel values mean"
		print "       where -V lists how to change them"
		print "       where -x prints out values in hex"
		print "       where -h prints out usage"
		exit 1
	fi
fi

#
# Main - no command line args
#

# find out kernel bit type
BITS=$(isainfo -kv | cut -d' ' -f1 )

# if kernel bit type cannot be determined or is 32
if [[ -z $BITS || $BITS == "32-bit" ]]
then
	#32 bit
	#set 64 bit variables to 32 bit
	# not able to list any 64 as only 32 bit kernel
    # so list everything in 32 bit terms
	if (( HEX ))
	then
		P_32VALUE=X
		P_64VALUE=X
	else
		P_32VALUE=D
		P_64VALUE=D
	fi
else
	#64 bit
	#use real 64 bit prints
	#set 64 bit variables to appropriate type
	#set 32 bit variables to appropriate type
	#you still list some 32 bit variable in 64 bit kernel
	# as not everything is 64 bit variables
	if (( HEX ))
	then
		P_32VALUE=X
		P_64VALUE=J
	else
		P_32VALUE=D
		P_64VALUE=E
	fi
fi

#
# main area where we display the actual kernel values
#
cat << EOF | adb -k /dev/ksyms /dev/mem | \
		awk '{ if (NF ==2) printf ("%30s %-s \n", $1, $2)}' | \
		grep : | more
autoup/$P_32VALUE
bufhwm/$P_64VALUE
coredefault/$P_32VALUE
consistent_coloring/$P_32VALUE
desfree/$P_64VALUE
dnlc_dir_enable/$P_32VALUE
dnlc_dir_min_size/$P_32VALUE
dnlc_dir_max_size/$P_32VALUE
doiflush/$P_32VALUE
dopageflush/$P_32VALUE
fastscan/$P_64VALUE
handspreadpages/$P_64VALUE
hires_tick/$P_64VALUE
kmem_flags/$P_32VALUE
kobj_map_space_len/$P_32VALUE
lotsfree/$P_64VALUE
lwp_default_stksize/$P_32VALUE
max_nprocs/$P_32VALUE
max_page_get/$P_64VALUE
maxpid/$P_32VALUE
maxpgio/$P_64VALUE
maxuprc/$P_32VALUE
maxusers/$P_32VALUE
minfree/$P_64VALUE
min_percent_cpu/$P_32VALUE
maxphys/$P_64VALUE
physmax/$P_64VALUE
moddebug/$P_32VALUE
ngroups_max/$P_32VALUE
ncsize/$P_32VALUE
ndquot/$P_32VALUE
nautopush/$P_32VALUE
noexec_user_stack/$P_64VALUE
nrnode/$P_32VALUE
nstrpush/$P_32VALUE
npty/$P_32VALUE
pageout_reserve/$P_64VALUE
pages_pp_maximum/$P_64VALUE
pages_before_pager/$P_64VALUE
physmem/$P_64VALUE
priority_paging/$P_64VALUE
pt_cnt/$P_32VALUE
pt_pctofmem/$P_32VALUE
pt_max_pty/$P_32VALUE
rechoose_interval/$P_32VALUE
reserved_procs/$P_32VALUE
rlim_fd_cur/$P_32VALUE
rlim_fd_max/$P_32VALUE
rstchown/$P_32VALUE
sadcnt/$P_32VALUE
segkpsize/$P_64VALUE
slowscan/$P_64VALUE
strmsgsz/$P_64VALUE
strctlsz/$P_64VALUE
swapfs_reserve/$P_64VALUE
swapfs_minfree/$P_64VALUE
throttlefree/$P_64VALUE
tmpfs_maxkmem/$P_64VALUE
tmpfs_minfree/$P_64VALUE
timer_max/$P_32VALUE
tune_t_flckrec/$P_32VALUE
tune_t_fsflushr/$P_32VALUE
tune_t_gpgslo/$P_32VALUE
tune_t_minarmem/$P_32VALUE
tune_t_minasmem/$P_32VALUE
ipc_tcp_conn_hash_size/$P_32VALUE
ip_icmp_err_interval/$P_32VALUE
ip_icmp_err_burst/$P_32VALUE
ip_forwarding/$P_32VALUE
ip6_forwarding/$P_32VALUE
ip_respond_to_echo_broadcast/$P_32VALUE
ip6_respond_to_echo_broadcast/$P_32VALUE
ip_send_redirects/$P_32VALUE
ip6_send_redirects/$P_32VALUE
ip_forward_src_routed/$P_32VALUE
ip6_forward_src_routed/$P_32VALUE
ip_addrs_per_if/$P_32VALUE
ip_strict_dst_multihoming/$P_32VALUE
ip6_strict_dst_multihoming/$P_32VALUE
udp_xmit_hiwat/$P_32VALUE
udp_recv_hiwat/$P_32VALUE
ufs_ninode/$P_32VALUE
ufs_LW/$P_32VALUE
ufs_HW/$P_32VALUE
ufs_WRITES/$P_32VALUE
tcp_conn_hash_size/$P_32VALUE
tcp_deferred_ack_interval/$P_32VALUE
tcp_deferred_ack_max/$P_32VALUE
tcp_wscale_always/$P_32VALUE
tcp_tstamp_always/$P_32VALUE
tcp_conn_req_max_q/$P_32VALUE
tcp_conn_req_max_q0/$P_32VALUE
tcp_conn_req_min/$P_32VALUE
tcp_time_wait_interval/$P_32VALUE
tcp_rev_src_routes/$P_32VALUE
tcp_sack_permitted/$P_32VALUE
tcp_slow_start_after_idle/$P_32VALUE
tcp_slow_start_initial/$P_32VALUE
tcp_cwnd_max/$P_32VALUE
tcp_max_buf/$P_32VALUE
tcp_recv_hiwat/$P_32VALUE
tcp_xmit_hiwat/$P_32VALUE
seminfo_semaem/$P_32VALUE
seminfo_semmsl/$P_32VALUE
seminfo_semmap/$P_32VALUE
seminfo_semmni/$P_32VALUE
seminfo_semmns/$P_32VALUE
seminfo_semmnu/$P_32VALUE
seminfo_semopm/$P_32VALUE
seminfo_semume/$P_32VALUE
seminfo_semvmx/$P_32VALUE
shminfo_shmmin/$P_32VALUE
shminfo_shmmni/$P_32VALUE
shminfo_shmmax/$P_32VALUE
shminfo_shmseg/$P_32VALUE
segspt_minfree/$P_32VALUE
scsi_options/$P_32VALUE
sd_io_time/$P_32VALUE
sd_max_throttle/$P_32VALUE
EOF


##############################################################################
### This script is submitted to BigAdmin by a user of the BigAdmin community.
### Sun Microsystems, Inc. is not responsible for the
### contents or the code enclosed. 
###
###
### Copyright 2005 Sun Microsystems, Inc. ALL RIGHTS RESERVED
### Use of this software is authorized pursuant to the
### terms of the license found at
### http://www.sun.com/bigadmin/common/berkeley_license.html
##############################################################################


