#!/usr/bin/ksh
SYS_DIAG_VER='7.04b'
#############################################################################
#
#  **  sys_diag  **     Revision : 7.04b
#  ____________________________________
#
#  Last Mod : 06/13/2007		  * See RELEASE NOTES below *
#  Created  : 08/23/1999 Todd A. Jobson
#					 				      
#  Purpose/Function :
#             To probe system(s), snapshot the configuration & workload,
#	      generating a configuration/performance analysis (-g|G) rpt.
#	      If run with -g|-G, performance data is gathered/collected
#	      and the system's workload is characterized and profiled 
#	      (via snapshot data post-processing analysis) within the 
#	      report header as a color coded System Health Martix /
#             Dashboard, as well as reflecting other detailed findings.
#	      (including Peak and AVG utilization and/or throughput ..
#	      along with exception reporting beyond defined thresholds for
#	      cpu, kernel, memory, .. IO device, HBA, NIC, .. etc ..).
#
#     NOTE: * Do not use MS Internet Explorer browser.. for .html rpt viewing.
#	      It varies in the HTML stds for formating and iframe file inclusion
#	      (ending up opening many windows vs embedding output files within
#	      the single .html report). * USE Netscape, Mozilla, Firefox, .. *
#	      Ensure that your display resolution is set to the maximum 
#	      resolution, and font sizes use defaults ..smaller vs too large.
#	      * (for best viewing open browser to full screen) *
#
#     -->->-> See "Common Usage" below for several usage examples <-<-<-<--
#
#	      To investigate other capabilities, review the "Common Usage"
#	      section below, as well as the "README_sys_diag.txt" file
#	      [or via the command line help/usage arguments ./sys_diag -?|-h ]
#
#	      Graphing of vmstat and netstat data is easy via StarOffice/Excell.
#	      (Insert->Sheet from file; then select the vm or net .gr.txt file)
#	
#	      To capture all cmd line output (stdout/stderr) to a file use :
#
#		./sys_diag -g [..options..] 1>/var/tmp/sys_diag.out 2>&1
#
#	      To run as a cron entry (@9am every day), with data stored in (-d)
#		/var/tmp, with all cmd line output appended to sys_diag.out :
#		(set EDITOR=vi;export EDITOR .. as root run crontab -e adding)
#
#     0 9 * * * /var/tmp/sys_diag -g -d /var/tmp 1>>/var/tmp/sys_diag.out 2>&1
#
##############################################################################
#
#  Copyright 1999-2007  Todd A. Jobson   				      
#
#  NOTE: As long as the comments and Copyright statements are left
#  ***** in-tact, Todd Jobson will grant an implicit right to use
#  ***** license for the following script in its entirety.  Any
#  ***** comments and/or enhancements can be directed to 
#  ***** todd.jobson@comcast.net for incorporation within future releases.
#
#  Note: As with all external Solaris utilities, Sun Support will not
# 	 support this utility, but all underlying OS commands are supported.
#  !*!*! Also note that any issues that result from installing, running,
#  !*!*! or modifying this script will be the Personal responsibility of 
#  !*!*! the individual that installed, modified, and/or ran this utility.
#
#  Note: This script has been run on most Sun system types (x86, Sparc -> E25K).
#  ***** This script has been tested on Solaris 2.x -> Solaris 10
#  ***** However, given that caution is always the best policy, 
#  !*!*! test on a non-production system (Test/Staging/desktop..) first !!!!
#
#  Note: If you are having problems running this (weird errors..), do a
#	 cat -uvet ./sys_diag    to see if the file has gotten windows
#	 corrupted... aka.. added ^M 's to the end of every line.  If so,
#	 you can simply remove these within vi as :1,$s/^V^M//g (where
#	 the ^'s listed are actually the Ctrl key, using Ctrl-V first to
#	 allow the entry of Ctrl-M as a character to substitute with nothing.
#	 .. or you can just run "dos2unix orig_scriptname new_filename"
#
###############################################################################
#
# BACKGROUND / INTRODUCTION :
# 
# sys_diag is a Solaris utility (ksh script) that can perform several 
# functions, most notably, system configuration 'snapshot' and reporting 
# (detailed or high-level) plus workload characterization via performance
# data gathering (over some specified duration or time in point 'snapshot'), 
# high-level analysis, and reporting of findings/exceptions (based upon 
# perf thresholds that can be easily changed within the script header).   
# 
# The output is provided in a single .tar.Z of output and corresponding 
# data files, and a local sub-directory where report/data files are stored.  
# The report format is provided in .html, .txt, and .ps as a single file 
# for easy review (without requiring trudging through several subdirectories 
# of separate files to manually correlate and review).   
# 
# sys_diag runs on any Solaris 2.6 (or above) Sun platform, and even 
# includes reporting of new Solaris 10 capabilities (zone/containers, SVM, 
# zfspools, fmd, ipfilter/ipnat, link aggr, ...).   
# 
# Beyond the Sun configuration reporting commands [System/storage HW config, 
# OS config, kernel tunables, network/IPMP/Trunking/LLT config, FS/VM/NFS, 
# users/groups, security, NameSvcs, pkgs, patches, errors/warnings, and 
# system/network performance metrics...], sys_diag also captures relevant 
# application configuration details, such as Sun N1, Sun Cluster 2.x/3.x, 
# Veritas VCS/VM/vxfs.., Oracle .ora/listener files, etc.. detailed 
# configuration capture of key files, etc ...
# 
# Of all the capabilities, the greatest benefits are found by being able 
# to run this on a system and do the analysis  from one single report/
# file... offline/elsewhere (in addition to being capable of  historically 
# archiving system configurations, for disaster recovery.. or to allow for 
# tracking system chgs over time.. after things are built/tested/certified).  
# One nice feature for performance analysis is that the vmstat and netstat 
# data is exported in a text format friendly to import and created graphs 
# from in StarOffice or Excell.. as well as creating IO and NET device
# Averages from IOSTAT / Netstat data (# IO's per device, AVG R/W K, etc..)
# along with peak exceptions for CPU / MEM / IO / NET ..
# 
# Although I'm a SunCS employee, this has been personally developed over many 
# years, in my spare time in order to make my life a lot easier and 
# more efficient.  Hopefully others will find this utility capable of 
# doing the same for them, also making use of it's legwork.. to streamline 
# the admin/analysis activities required of them.  This has been an invaluable
# tool used to diagnose / analyze hundreds of performance and/or configs issues
# 
# Regarding the system overhead, sys_diag runs all commands in a serial 
# fashion (waiting for each command to complete before running the next) 
# impacting system performance the same as if an admin were typing these 
# commands one at a time on a console.. with the exception of the background 
# vmstat/mpstat/iostat/netstat that's done when (-g) gathering performance 
# data over some interval for report/analysis (which generally has minimal 
# impact on a system, especially if the sample interval [-I] is not every 
# second).
# 
# sys_diag is generally run from /var/tmp as "sys_diag -l"  for creating 
# a detailed long report, or via "sys_diag -g -l " for gathering 
# performance data and generating a long/detailed config/analysis report), 
# however offers many command line parameters documented within the header, 
# or via "sysdiag -?".   ** READ the Usage below, as well as the Performance
# Parameters sections for futher enlightenment.. ;) **
#
############################################################################
#
#  Common Usage:  sys_diag -l
#
#		(Generate a "long"/detailed system config report.)
#
#			This option creates text, HTML, and postscript
#			versions of the report file (.out,.html,.ps..)
#			in addition to tar'g and compressing all to .Z
###
#  	 sys_diag -g -l 
#
#	(The above syntax Gathers performance/utilization data according
#  	 to the *default* sampling rate of 2 seconds for 5 minutes total,
#	 in addition to generating a complete "long" system configuration
#	 It then parses the performance data captured and identifies any 
#	 preliminary discrepancies/findings based upon thresholds set. As 
#	 part of the .html report, a color coded Dashboard is created in 
#	 the report header "dashboard" that shows Health/status of subsystems.
#
#**>	 sys_diag -g -I 3 -T 1800 -l
#
#		uses the cmdline Interval parameter (-I) with a 3 second
#		sampling interval, -T with 1800 secs (1/2 hr) Total
#		elapsed time for data collection, then -l for a long
#		configuration report. (No need to edit PERF_SECS, below)
#
#	** For the BEST granularity, use 1 second intervals (-I 1),
#	   However, realize the more samples, the more data captured
#	   and the greater the size of the data to retrieve **
#
#	 *NOTE: See the Variable (Parameter) section inline below 
#		labeled "Performance Data Gathering Parameters"
#		for a detailed explanation of Perf Thresholds / Bounds
#		to test the data against and report exceptions for..
#		as well as the default settings for interval and duration
#		These parameters can be modified, but only affect -g || -G
#	   eg.  PERF_INTERVAL [sampling rate in secs] and PERF_SECS 
#		[Total duration in Seconds for data gathering/capture; 
#		300 seconds = 5 mins]
#
#### Other options...(see sys_diag -? for a complete listing.. or code below)
#
#	 -G	Detailed Performance data capture, includes longer
#		lockstat samples (and more of them), as well as
#		dtrace if it exists (see snap_bme_perf function).
#
#		NOTE: When -G is used, the starting/ending snapshots using lockstat/
#		Dtrace/pmap occur BEFORE/AFTER the standard (vmstat/mpstat/netstat..) 
#		data gathering, therefore the STARTing time for data collection
#		is likely to be 30 secs + AFTER sys_diag is started.
#		(this reduces the impact of Dtrace and Extended Lockstat/pmap
#		 probing activities on the system, by only running at the
#		 midpoint of data collection, where any overhead can be predicted)
#
#	 -A 	Runs ALL options, including data collection, asset
#		tracking, verbosity, etc..
#
#	 -C	Cleans up the data directory and removes it and the files
#		after the tar.Z directory archive is created.
#
#	 -D	Runs in DEBUG mode (echo ing all ksh to the cmd line)
#
#	 -t     Track system changes. Identify system configuration /file chgs
#		This can be used in conjunction with "-f input_file" option
#		to specify a configuration file listing to track changes of.
#		-> Save latest and previous copy of significant
#		config data + dir/file	listings and append 
#		any changes/diffs to logfile (reports CHANGES)
#		(see TRACK in the code for cfg.. data checked)
#
#	 -u	Turns off the default TAR creation/Compression of an
#		archive containing all report files generated...
#		(left untar ed, NO .tar.Z file is created of the dir)
#
#	 -V	*Runs in VERBOSE mode (adding verbose data such as
#		/etc/path_to_inst, interface snoop, and network
#		device driver settings..tcp/ip/udp ... and longer 
#		message/error/log listings).  Additionally, pmap is run if -g,
#		and the probe duration for Dtrace and lockstat sampling is widened
#		from 2 seconds (during -G) to 5 seconds (if -G && -V).  Ping is
#		also run against the default route and google.com to guage latency.
#
#	 -S 	SKIP Post-Processing of Performance data and .html rpt process'g
#
#	 -P	Complete the Post-Processing and rpt generation skipped with -S
#		** Also requires the use of -d *data_dir_path* as input **
#
#	 -d base_directory 	(where datafiles/dirs should reside)
#				 if not, use $SYSDIAG_HOME , else use the 
#			local directory, else (if cant write) PROMPT for path.
#
#	 -o output_filename 	(specify an output filename, otherwise
#				 use the default sysd_.. naming)
#
####################################################################################
#
# ***** ** ** ** ** ***   RELEASE NOTES :  *** ** ** ** ** ** ****
#
####################################################################################
#
#  CURRENT RELEASE :
#
#  R. 7.04b TJ 07/10/2007   Several README notes added.
#			    Added -cv to zoneadm list, zonecfg export, etc...
#			  * New HTML reformatting enhancements.. allowing for better
#				embedded file display capabilities (auto sizing, etc..).
#			  * Added Dtrace snapshots of file IO for wait-start/start (_diow).
#			  * Added cpustat capture of %FP ops, Ecache hits, I/DTLB_misses..
#			  * Added Deep (-G) Performance gathering -V (Verbose) distinction,
#				where Dtrace and lockstat snapshots are longer if -G && -V
#				(2 seconds with -G only, and 5 seconds with -G & -V).
#			  * Added list of Top 10 Slowest devices/ Avgs for -g ||-G.
#			  * Added hostname, date and Timestamp to the HTML rpt title bar
#			    Several other misc reformatting enhancements.
#  PRIOR RELEASES :
#
#  R. 7.03  TJ 06/13/2007  Several comments, instructions, and README notes added.
#			  *New HTML reformatting enhancements, heading, dashboard..
#			    including new iframes in HTML to list Dtrace/snapshot files.
#			   Added Mpstat PEAK High Water marks to the MP AVG data.
#			   Added Netstat %errors/ NIC to dashboard, & %cpu for TLB_misses.
#			   Added Dexplorer std_counts and Interrupt_times (and associated
#			    files _dsdtcnt_ , _dintrtm_).  Added "trapstat -t" to -g output.
#			   Fixed cpustat and cputrack syntax for pre US-IV+ cpu's.
#			   Captures output of cpustat system parameters avail if it fails.
#			   Added high level vxstat to .html output (detailed is in snap files).
#			   Added lustatus to capture Live Upgrade config if it exists.
#			   Added zpool iostats capture, in addition to DNS/named.stats .
#			   Added ping tests to default gateway and google.com (if -V || -n).
#			   Added logic to capture 10 top process pmap/pfiles if (-V && -G).
#			   Only runs pmap/pfiles (top 5 pids) capture if -G || (-g && -V).
#
#  R. 7.02  TJ 06/09/2007 *Fixed %free_swap calculations and tuned several post-proc'g 
#			   performance thresholds for more accurate dashboard color-coding.
#			 **Reduced the overhead on system if only running -g,
#			   removing many reporting sections unless -l or -V are used.
#			  *Restricted lockstat to 1 second samples for -g, and tuned -G.
#			   Added wsvc_t to iostat and Kthr_W to vmstat post-proc'g analysis.
#			 **Moved all top process detailed reporting for -G only, and
#			   added to that, cputrack on top pids along with pmap/io_by_pid.
#			 **Added Dtrace snaps of proc's causing High ICSW/SMTX/XCALLS (-G).
#			  *Added a Workload Characterization Dashboard section.
#			   Added several links to the Dashboard referencing
#			    	 other profiling data within the .html rpt.
#			   Added cpustat for system wide ITLB/DTLB_miss stats (if -G).
#			   Added kstat -n system_pages.
#			   Reorganized the TOC and section contents via topic/subsystem.
#			  *Added cputrack capture of Floating Point % ops for top PIDs.
#			   Added cpustat capture of Floating Point % ops for system.
#			 **Added the capability to track config file changes from an
#			   external file list, (beyond the build in list) by using
#			   the argument "-f input_filename" along with "-t" to track
#			   system configuration changes. The "input_file" contains a
#			   a list of absolute pathnames of files to be tracked.
#			   Added Interrupts section and link to dashboard (intrstat/vmstat -i).
#			   Added isainfo to reflect 32/64 bit kernel spt/mode.
#			   Added DNLC % hits for filesystem directory performance on IO.
#			  *Enhanced ksh command line input mechanisms and error checking.
#			   (as a result, the cmd line syntax is much more forgiving, now 
#			    allowing either "-I1" or "-I 1" or other additional whitespace).
#			   Extensive additions to the README_.. file for usage, etc.
#
#  R. 6.05  TJ 05/30/2007  Added vxstat snapshots at the beginning/middle/end of 
#			   -g | -G data collection (for checking FS I/O breakdown).
#			   Added mdb kernel memory profile if -G && -V.
#			   Added dtrace, vxstat, mdb filenames to README file descriptions.
#			   Fixed typo in HBA Controller throughput headers.
#			   Added the # of ESTABLISHED network connections to dashboard.
#			   Fixed pmap sorting and added -S for swap mem allocation.
#			   Cleaned up misc ksh conditional syntax, stdout/err msgs, etc..
#			  *Added tcp READ activity to the Dtrace dexplore function (-g|-G).
#			  *Added io_by_pid function to detail top procs IO activity
#			   (if -G). *io_by_pid was based upon iosnoop*.
#			   Refined/tuned the performance thresholds (RQ Avg, %SWAP,..).
#			   Added a sys_diag_perflog.out log file that the Perf data summary
#			   gets appended to after each -g|-G run.
#
#  R. 6.04  TJ 05/10/2007  Separate Logical NIC stats from Physical NIC (-g|-G).
#			   Added several config files to Asset Tracking (-t).
#			   Further refined the impact of -G on system utilization
#			   to reduce the duration of lockstat calls.
#			   Minor header formatting fixes and better accuracy of
#			   average/peak calculations using AWK.
#			   Creates a README file that has common usage and
#			   a description of all filenames stored in the data directory.
#
#  R. 6.03  TJ 04/27/2007  Added -S to SKIP Post-Processing of Performance data,
#			   .html report completion. Added -P (used with 
#			   -d sysdiag_data_dir_path) for completing the
#			   skipped performance Analysis Post-Processing of data.
#			   (for systems where little/no overhead is permitted by
#			   running a data capture utility.. to minimize the 
#			   impact on system performance and allow the postprocg 
#			   to run elsewhere. [-g can be run alone with -S ]
#			   Added WARNINGS for high #s of TIME_WAIT sockets and
#			   zombie/defunct process counts.
#		
#   R. 6.02	TJ 04/20/2007	Added PEAK VMSTAT cpu & memory values to dashbd.
#				Added IO Controller AVG and TOTAL Throughput to dash.
#				Added Peak IO device entries to the AVGs listing.
#				Added the NIC Kstat calculations listing PEAK
#				NIC RX_Pkts/sec and TOTAL Bytes per NIC. 
#				Added Dtrace segments (-G) with permission
#				from Brendan Gregg (see dexplore function comments).
#
#   R. 6.01	TJ 04/17/2007	Refined -g perf data capture to 
#				**run a lighter weight data capture (lockstat..)
#				-G is a deep performance analysis mode which
#				runs Dtrace and longer lockstat sampling..
#				Added vmstat graph fields. Added -C to cleanup
#				and remove the sys_diag directory after tar'g.
#				Added process list sorted output by # LWP/proc.
#				Fixed "-l" so that it no longer needs to be the
#				last command line parameter (any order works).
#				Fixed -h || -? to show common usage examples.
#
#   R. 6.0	TJ 03/01/2007	Added dtrace data via exec of dexplorer if
#				it exists in the current directory (5 sec
#				samples), assuming (added) -G is used vs -g.
#				Added performance data capture of lockstat & ps
#				at the beginning, middle, and end of the data
#				collection (snap_bme_perf function added).
#
#   R. 5.19	TJ 05/01/06	Added changes as per RFE's from brandand,
#				jgarber, jland, thobrown, jenssch from BigAdm.
#				More mkdir testing, Solaris_Rev fix, err msgs,
#				Fixed iostat %W calculation for IOSTAT Avgs.
#				Added kstat NIC counters (throughpt..)capture.
#				Added SunRay svr config info within App section.
#				Added seconds to log_stamp and perf filenames.
#				Fixed so if -d base_dir.. tar also points to it.
#
#   R. 5.18	TJ 01/31/06	Extended System Profilng, introduced a new
#				html header section "System Perf. Dashboard"
#				reflecting color coded system perf summary and
#				links to config and perf. analysis findings..
#
#   R. 5.17	TJ 01/03/06	Removed RFE Notes/comments, Added Intro,
#				changed -v for version#, -V for Verbose, ..
#				Added System Profiling Output, IO dev Avgs
#
#   R. 5.16	TJ 12/29/05	Added busstat, vxstat samples, vxtunefs,
#				"failure" as errors, lockstat -IW, tuned perf,
#				added zfs config listings, ..
#
#   R. 5.15	TJ 09/23/05	Added S10 zfs pool list, S10 IPNAT, ipfilter,
#				in addition to other misc.. formatting of rpt
#
#   R. 5.14	TJ 09/20/05	Optimized cmd line args , added .gr.txt
#				files for export/import of vmstat/netstat perf 
#				data into a spreadsht/graph util, added
#				extra error checking for not running
#				S10/S9 cmds on S8, expanded rcap/project data,
#				moved long (-l) pkginfo & ps listings to files
#
#   R. 5.13	TJ 08/02/05	Added system cpu and network interface avgs, +
#				VCS LLT/ Oracle RAC/CRS net interconn perf data
#
#   R. 5.12	TJ 08/02/05	Additional Veritas and Oracle RAC data..
#
#   R. 5.11	TJ 03/09/05	Minor reformatting, Expanded Perf Analysis
#
#   R. 5.10	TJ 02/10/05	Added X.25 utilities, Added Perf Parameters
#
#   R. 5.08	TJ 12/10/04	Added S10 perf utilities, re-org output, ..., 
#				misc. enhancements.. comments..
#
#   R. 5.01	TJ 10/13/04	Added S10 zone/containers, SRM,
#				MPxIO,..Several Misc. enhancements.. comments..
#
#   R. 4.05	TJ 02/20/04	Added N1 PS config rptg
#				Sections, + Misc... 
# 
#   R. 4.04	TJ 01/18/04	Added Veritas VCS main.cf config reporting..
#				and expanded SC3.x reporting, SVM,..
#
# ... all other prior release notes have been removed as it's history now..
# 
##############################################################################
##############################################################################
#
# RFE NOTES : ( ADD / CHANGE / FIX / Test ...)    :
#
##################################################################################
#  RFE Misc :	
#
#  Trace user-level lock stats for 5 secs (replace -A with -s10 for stack)
#  /usr/sbin/plockstat -A -e5 -p <pid>
#
#  S10 u1 Nemo Link Aggr : laadm show stats | dlam show ..
#
#  scdidadm | scgdevs
#
#  scnad -p | scnasdir -p  .... NCA, etc..
#
# pwdx working_dir of pid
#
# system calls by zone :
# dtrace -n 'syscall:::entry { @num[zonename] = count(); }'
#
# snmp bytes by nic :
# /usr/sfw/bin/snmpnetstat -v1 -c public -o (-i) localhost
#
# mdb finding leaks :
# ::findleaks
#
# Efficiency Rating for System :
#  cpustat -c pic0=Instr_cnt,sys   ... $4, each line per cpu Strand 
#  (HW thread Instruction Pipeline) .. 4 threads per core .. 32 for 8core T1..
#  .. or 2 cores * 1 Thread per US-IV/+.  (< US-IV = 1 thread [strand] per line).
#  Calculate Efficiency by % of possible Instructions based upon GHz (Bill inst/sec).
#  Eg. 4 lines of output for a T1 cpu (cpu 0-3 = 4 threads = 1 core) totaling 760 M
#	instr's .. is 63% (.63) efficient, since each core runs at 1.2 GHz...
#
#  other older Sparc E_Cache Latency:
#  cpustat -c pic0=Cycle_cnt,pic1=Re_EC_miss,sys 1 2  | tail -1
#  2.007   4 total 7212880624 780492504
#  (780492504 / 7212880624)*100 = 10.82 % cycles(time) waiting for cache to be filled
#
##################################################################################
##################################################################################

############### Performance Data Gathering Parameters ##############
#
# NOTE: THE FOLLOWING PARAMETERS ONLY AFFECT the -g (PERF ANALYSIS)
#
# PERF_SECS is the total elapsed seconds for data collection and can
#	be overridden on the command line with -T <secs>
#
# PERF_INTERVAL is the sampling interval in seconds and can be overridden
#	via the command line interval -I <secs>

PERF_SECS=300	## Total data gathering Time; 300 secs= 5 mins, 1800=30 mins..
PERF_INTERVAL=2 ## (frequency in # of seconds that samples are taken)

## the following fields are the actual vmstat/mpstat/iostat
## Rules / Thresholds that are tested for and flagged if outside bounds

VMSTAT_RUNQ_GT=0	## vmstat entry flagged only if RUNQ (R) field > X
VMSTAT_BLKD_GT=0	## vmstat entry flagged only if Kthr_B field > X
VMSTAT_WAIT_GT=0	## vmstat entry flagged only if Kthr_W field > X
VMSTAT_SCANRT_GT=0	## rate of system scanning for free mem pages
VMSTAT_PCTSYS_GT=40	## overall system cpu % SYS < X%
VMSTAT_PCTIDLE_LT=5	## overall system cpu % IDLE < X%
VMSTAT_PCT_YEL=4.0	## Vmstat CPU Warning Threshold > X% of samples
VMSTAT_PCT_RED=20.0	## Vmstat CPU Critical Threshold > X% of samples

MEM_PCT_YEL=1.0		## Vmstat MEM Warning Threshold > X% of samples
MEM_PCT_RED=15.0	## Vmstat MEM Critical Threshold > X% of samples
MEM_PCT_MIN=15		## % of physical RAM avail Minimum Threshold < X%
SWAP_PCT_MIN=25		## % Vmem:SWAP avail Minimum Threshold < X%

MPSTAT_ICSW_GT=90	## involuntary context switches per cpu entry > X & (if %Sys > MPSTAT_SYS)
MPSTAT_ICSW_IGT=300	## involuntary context switches per cpu entry > X & (if Idle < PCTIDLE_ILT)
MPSTAT_SMTX_GT=200	## shared mutex spins per cpu entry > X   & (if %Sys > MPSTAT_SYS)
MPSTAT_SYS_GT=40	## mpstat cpu % SYS (kernel) > X
MPSTAT_PCTWT_GT=0	## mpstat cpu waiting > X% of its time
MPSTAT_PCTIDLE_LT=1	## mpstat cpu entry flagged only if PCTIDLE < X 
MPSTAT_PCTIDLE_ILT=10	## mpstat cpu entry flagged if (ICSW > ICSW_IGT) & (PCTIDLE_ILT < X)
MPSTAT_PCT_YEL=8.0	## Mpstat Warning Threshold > X% of samples
MPSTAT_PCT_RED=20.0	## Mpstat Critical Threshold > X% of samples

IOSTAT_WAIT_GT=0	## iostat avg # transactions waiting on device queue
IOSTAT_ASVCTM_GT=19	## iostat avg device time to svc active rqst (asvc_t) > Xms
IOSTAT_WSVCTM_GE=1	## iostat avg device time rqst is in wait queue (wsvc_t) >= Xms
IOSTAT_PCTWT_GT=0	## transactions waiting > X% of the time on device (%w)
IOSTAT_PCTBSY_GT=95	## device busy % (%b) > X% of its time
IOSTAT_PCT_YEL=4.0	## Iostat Warning Threshold > X% of samples
IOSTAT_PCT_RED=19.0	## Iostat Critical Threshold > X% of samples

NETSTAT_RX_GT=18000	## network interface incoming packets per interval
NETSTAT_RX_ERR_GT=0	## network interface incoming packet errors per interval
NETSTAT_TX_GT=25000	## network interface outgoing packets per interval
NETSTAT_TX_ERR_GT=0	## network interface outgoing packet errors per interval
NETSTAT_COLL_GT=0	## network interface # collisions per interval
NETSTAT_PCT_YEL=1.0	## Netstat Warning Threshold > X% of samples
NETSTAT_PCT_RED=10.0	## Netstat Critical Threshold > X% of samples
#
######################################################################
#

SYSDIAG_HOME=''

## NOTE: CHANGE The following vars to reflect your patch utility location..

PATCH_UTILITY_DIR='/var/tmp/patchdiag-1.0.4'
PATCH_UTILITY_CMD='patchdiag -l'

ALL=0
APPS=0
CONFIG=0
CLEANUP=0
DEBUG=0
DURATION=0
#EXTRACT=0		## TBD .. as yet unused for.. Extract Config / Asset Mgmt
HA=0
INTERVAL=0
IO=0
LABEL=0
LONG=0
MENU=0
N1=0
NETWORK=0
ORACLE=0
PERF=0
PATCHMGT=0
POSTPERF=0
SKIP_POSTPERF=0
PROMPT=0
SECURITY=0
POST=0
TAR=1
TRACK=0			## Capture and TRACK Config / Asset Mgmt chgs
VERBOSE=0

typeset -i sum1=0
typeset -i sum2=0
typeset -i xxxx=0

typeset -x vmpid
typeset -x iopid
typeset -x mppid
typeset -x snooppid

io_secs=0
snooppid=0
no_nis=0
nisd=0
num=0
sud=0

typeset -x Solaris_Rev
#Solaris_Rev=`uname -a | cut -d" " -f3`
#Solaris_Rev=`uname -a | cut -d"." -f2 | cut -d" " -f1`
Solaris_Rev=`uname -a | cut -d" " -f3 | cut -d"." -f2`

User_Name=`/usr/bin/who | cut -d" " -f1`
Up_Time=`uptime`

SYSDIAG_PID=$$
CMD_LINE=$*
CMD=`basename $0`

filename=''
sysd_dir=''
home_dir=''
infile=''
interval_secs=0
duration_secs=0
duration_count=0
hname=`hostname`
outfile=''
outfile_ps=''
html_file=''
afile_log=''
snoop_file=''
name_svc1=''
name_svc2=''

SHELL=/bin/ksh;export SHELL

############################################################
### ** ** ** **  FUNCTION DECLARATIONS ** ** ** ** ** ** ## 
############################################################ 

####################  make_README  #############################
#
# Description: 'make_README' 
#		Create the sys_diag README file within the data directory.
#
# Parameters:
#       $1      sysd_dir
#	$2	DEBUG

function make_README {

        typeset -r sysd_dir=$1
        typeset -r debg=$2

	readme_file=$sysd_dir'/README_sys_diag.txt'

	if [[ $debg -ne 0 ]]
	then
		echo "make_README(): $readme_file\n\t$sysd_dir\n"
	fi

	/usr/bin/awk '{ print $0 }' << @EOF >> $readme_file 2>&1

README_sys_diag.txt	(copyright 1999-2007  Todd A. Jobson)


----------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------

________________________________

Outline of this README document :
________________________________


-       sys_diag v.7.04 Overview

-       Common Command Line usage and available parameters

-       Common line Usage Examples +

-       Examples for capturing sys_diag Command Line output

-       Examples of sys_diag Crontab entries

-       sys_diag DIRECTORIES and DATA FILE Descriptions



----------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------

_________________________

sys_diag v.7.04 Overview :
_________________________


  BACKGROUND / INTRODUCTION :
  
  sys_diag is a Solaris utility (ksh script) that can perform several 
  functions, most notably, system configuration 'snapshot' and reporting 
  (detailed or high-level) plus workload characterization via performance
  data gathering (over some specified duration or time in point 'snapshot'), 
  high-level analysis, and reporting of findings/exceptions (based upon 
  perf thresholds that can be easily changed within the script header).   
  
  The output is provided in a single .tar.Z of output and corresponding 
  data files, and a local sub-directory where report/data files are stored.  
  The report format is provided in .html, .txt, and .ps as a single file 
  for easy review (without requiring trudging through several subdirectories 
  of separate files to manually correlate and review).   
  
  sys_diag runs on any Solaris 2.6 (or above) Sun platform, and even 
  includes reporting of new Solaris 10 capabilities (zone/containers, SVM, 
  zfspools, fmd, ipfilter/ipnat, link aggr, Dtrace probing, etc...).   
  
  Beyond the Sun configuration reporting commands [System/storage HW config, 
  OS config, kernel tunables, network/IPMP/Trunking/LLT config, FS/VM/NFS, 
  users/groups, security, NameSvcs, pkgs, patches, errors/warnings, and 
  system/network performance metrics...], sys_diag also captures relevant 
  application configuration details, such as Sun N1, Sun Cluster 2.x/3.x, 
  Veritas VCS/VM/vxfs.., Oracle .ora/listener files, etc.. detailed 
  configuration capture of key files (and tracking of changes via -t), etc ...
  
  Of all the capabilities, the greatest benefits are found by being able 
  to run this single ksh script on a system and do the analysis  from one single report/
  file... offline/elsewhere (in addition to being capable of  historically 
  archiving system configurations, for disaster recovery.. or to allow for 
  tracking system chgs over time.. after things are built/tested/certified).  
  One nice feature for performance analysis is that the vmstat and netstat 
  data is exported in a text format friendly to import and created graphs 
  from in StarOffice or Excell.. as well as creating IO and NET device
  Averages from IOSTAT / Netstat data (# IO's per device, AVG R/W K, etc..)
  along with peak exceptions for CPU / MEM / IO / NET ..
  
  Although I'm a Sun employee, this has been personally developed over many 
  years, in my spare time in order to make my life a lot easier and 
  more efficient.  Hopefully others will find this utility capable of 
  doing the same for them, also making use of it's legwork.. to streamline 
  the admin/analysis activities required of them.  This has been an invaluable
  tool used to diagnose / analyze hundreds of performance and/or configs issues
  
  Regarding the system overhead, sys_diag runs all commands in a serial 
  fashion (waiting for each command to complete before running the next) 
  impacting system performance the same as if an admin were typing these 
  commands one at a time on a console.. with the exception of the background 
  vmstat/mpstat/iostat/netstat that's done when (-g) gathering performance 
  data over some interval for report/analysis (which generally has minimal 
  impact on a system, especially if the sample interval [-I] is not every 
  second).
  
  sys_diag is generally run from /var/tmp as "sys_diag -l"  for creating 
  a detailed long report, or via "sys_diag -g -l " for gathering 
  performance data and generating a long/detailed config/analysis report), 
  however offers many command line parameters documented within the header, 
  or via "sysdiag -?".   ** READ the Usage below, as well as the Performance
  Parameters sections for futher enlightenment.. ;) **

  NOTE: For the best .html viewing experience, Do NOT use MS Internet Explorer browser
        as it varies in support of HTML stds for formating and iframe file inclusion
        (ending up opening many windows vs embedding output files within
        the single .html report).  ** USE Netscape, Mozilla, Firefox, etc.. browsers, 
	ensuring that your display resolution is set to the maximum resolution, and 
	font sizes are defaults or not made too large (for best viewing open full screen)


 ** See http://blogs.sun.com/toddjobson/  for a blog relating to system performance, 
        capacity planning, and systems architecture / availability.

    For the last BigAdmin released version of sys_diag see :  
        http://www.sun.com/bigadmin/jsp/descFile.jsp?url=descAll/sys_diag__solaris_c


___________________________________________________________________________________________
___________________________________________________________________________________________

___________________________________________________

Common Command Line usage and available parameters :
___________________________________________________

COMMAND USAGE : 

	# sys_diag [-a -A -c -C -d_ -D -f_ -g -G -H -I_ -l -L_ -n -o_ -p -P -s -S -T_ -t -u -v -V -h|-? ]

        -a          Application details (included in -l/-A)

        -A          ALL Options are turned on, except Debug and -u

        -c          Configuration details (included in -l/-A)

        -C          Cleanup Files and remove Directory if tar works

        -d path     Base directory for data directory / files

        -D          Debug mode (ksh set -x .. echo statements/variables/evaluations)

	-f input_file	Used with -t to list configuration files to Track changes for

        -g          gather Performance data (2 sec intervals for 5 mins, unless -I |-T exist)

        -G          GATHER Extra Perf data (S10 Dtrace, more lockstats, pmap/pfiles) vs -g

        -h | -?     Help / Command Usage (this listing)

        -H          HA config and stats

        -I secs     Perf Gathering Sample Interval (default is 2 secs)

        -l          Long Listing (most details, but not -g,-V,-A,-t,-D)

        -L label_descr_nospaces   (Descriptive Label For Report)

        -n          Network configuration and stats (also included in -l/-A except ndd settings)

        -o outfile  Output filename (stored under sub-dir created)

        -p          Generate Postscript Report, along with .txt, and .html

        -P -d ./data_dir_path   Post-process the Perf data skipped with -S and finish .html rpt

        -s          SecurIty configuration

        -S          SKIP POST PROCESSing of Performance data (use -P -d data_dir to complete)

        -t          Track configuration / cfg_file changes (Saves/Rpts cfg/file chgs *see -f)

        -T secs     Perf Gathering Total Duration (default is 300 secs =5 mins)

        -u          unTar ed: (do NOT create a tar file)

        -v          version Information for sys_diag

        -V          Verbose Mode (adds path_to_inst, network dev's ndd settings, mdb, snoop..)
                    Longer message/error/log listings.  Additionally, pmap is run if -g ||-G,
                    and the probe duration for Dtrace and lockstat sampling is widened
                    from 2 seconds (during -G) to 5 seconds (if -G && -V).  Ping is
                    also run against the default route and google.com to guage latency.


  NOTE: NO args equates to a brief rpt (No -A,-g/I,-l,-t,-D,-V,..)

	** Also, note that option/parameter ordering is flexible, as well as use of white
	   space before arguments to parameters (or not).  The only requirement is to list
	   every option/parameter separately with a preceeding - (-g -l  , but not -gl).
	
	BOTH of the following command line syntax examples is functionally the same :

	eg.	./sys_diag -g -I 1 -T 1800 -t -f ./config_files -l
	    OR
		./sys_diag -g -l -t -f./config_files -I1 -T1800

----------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------

  eg.   Common Usage :
  -------------------

        ./sys_diag -l        Creates a LONG /detailed configuration rpt (.html/.txt)
                             Without -l, the config report created has basic system cfg details.

        ./sys_diag -g -l     gathers performance data at the default sampling rate of 2 secs
                             for a total duration of 5 mins, adding a color coded performnc
                             header/ Dashboard Summary section and any performance
                             findings/exceptions found to the long (-l) cfg rpt.  Also takes (3)
                             starting/midpt/endpoint snapshots using minimal lockstat/kstat (1sec)

			     NOTE: -g is meant to gather perf data without overhead, therefore
                                   only 1 second lockstat samples are taken.  Use -G and/or -V
                                   for more detailed system probing (see examples and notes below)
				   Using -V with -g, adds pmap/pfiles snapshots, vs. using -G
				   to also capture Dtrace and extended lockstat probing.

                           * Any time that sys_diag is run with either -g or -G, the performance
                             section of the command line output is appended to the file 
                             sys_diag_perflog.out, which gets copied and archived as part of the final 
                             .tar.Z output file. (*Examples for capturing ALL output are in the next section *)
				
        ./sys_diag -g -I 1 -T 600 -l   gathers perf data at 1 sec samples for 10 mins and 
                                       creates a long config rpt as noted above. Also does
                                       basic start/mid/endpoint sampling using lockstat/kstat/pmap.

        ./sys_diag -l -C      	       creates long config rpt, and Cleans up..
                              	       aka removes the data directory after tar.Z completes

        ./sys_diag -d base_directory_path  (changes the base dir for datafiles from curr dir)

        ./sys_diag -G -I 1 -T 600 -l   Gathers DEEP performance & Dtrace/lockstat/pmap data
                                       at 1 sec samples for 10 mins & creates a long cfg rpt
                                       (in addition to the standard data gathering from -g).

                *NOTE:  this runs all Dtrace/Lockstat/Pmap probing during 3 snapshot intervals 
                        (beginning_0/midpoint_1/ and endpoint_#2 snapshots), limiting probing 
                        overhead to BEFORE/AFTER the standard data gathering begins
                        (vmstat, mpstat, iostat, netstat, .. from -g).
                        The MIDPOINT probing occurs at a known point as not to confuse this 
                        activity for other system processing.

                       *Because of this, standard data collection may not start for 30+ seconds,
                        or until the beginning snapshot (snapshot_#0) is complete. 
                        (-g snapshot_#0 activities only take a couple seconds to complete, 
                        since they do not include any Dtrace/lockstat.. beyond 1 sec samples).

        ./sys_diag -G -V -I 1 -T 600    Gathers DEEP, VERBOSE, performance & Dtrace/lockstat/pmap 
					data at 1 sec samples for 10 mins (using 5 second Dtrace and 
					Lockstat snapshots, vs. 2 second probes for only -G.
                                        (in addition to the standard data gathering from -g).

        ./sys_diag -g -l -S  (gathers perf data, runs long config rpt, 
                              and SKIPS Post-Processing and .html report generation)

                     ** This allows for completing the post-processing/analysis activities 
                        either on another system, or at a later time, as long as the data_directory
                        exists (which can be extracted from the .tar.Z, then refered to as 
                        -d data_dir_path ).  ** See the next example using -P -d data_path **

        ./sys_diag -P -d ./data_dir_path  (Completes Skipped Post-Processing & .html rpt creation)


-----------------------------------------
 Capturing sys_diag command line output :
-----------------------------------------

      To capture all cmd line output (stdout/stderr) to a file use either :

         script [-a] /var/tmp/sys_diag.out	(then after running sys_diag, type exit)

       OR

        ./sys_diag -g [..other options..] 1>/var/tmp/sys_diag.out 2>&1
         (this will hide all command line output .. all instead going to the file)

          NOTE: If the filename used for capturing command line output is /var/tmp/sys_diag.out
                or uses the same path as the -d base_data_directory , then that file
                will be automatically copied as part of the .tar.Z created.

----------------------------------------------------------------------------------------------

-----------------------------------------
 Executing sys_diag via CRONTAB entries :
-----------------------------------------

  To run /var/tmp/sys_diag as a CRON entry (@9am every Friday), with data stored in 
  (-d) /var/tmp, with all cmd line output appended to /var/tmp/sys_diag.out :
  (set EDITOR=vi;export EDITOR .. as root run  "crontab -e" adding the following line)

    0 9 * * 5 /var/tmp/sys_diag -g -d /var/tmp 1>>/var/tmp/sys_diag.out 2>&1

  To run /var/tmp/sys_diag for tracking configuration and configuration file changes (-t)
  midnight every day, using an input file to specify the list of files to track
  and report on (-f /var/tmp/sysd_tfiles), storing the data directory for
  runs under the basedirectory (-d /var/tmp).  All output from sys_diag gets
  saved (appended) in /var/tmp/sys_diag.out

  0 0 * * * /var/tmp/sys_diag -t -l -f /var/tmp/sysd_tfiles -d /var/tmp 1>>/var/tmp/sys_diag.out 2>&1

  Note, that the following describes the first 5 fields for crontab entries :

     minute (0-59),
     hour (0-23),
     day of the month (1-31),
     month of the year (1-12),
     day of the week (0-6 with 0=Sunday).

     * Lising a field with either comma or dash separated list allows multiple
	times/days (eg.  0 9 * * 1-5 runs Mon-Fri @9am).. & ( 0 9 * * 1,5 runs on Mon & Fri's only) *

----------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------

_________________________________________________

sys_diag DIRECTORIES and DATA FILE Descriptions :
_________________________________________________


The following list is a description of the files you will encounter within the
default base directory that sys_diag uses for its data files (or identified with -d) :

[NOTE: "socrates" is the hostname of the system used to generate the following filenames.
     * most files use the following naming convention :   sysd_*_hostname_YYMMDD_HHMM ]

# ls ./sys*

-rwxr-xr-x   1 root     root      186900 May 11 03:44 sys_diag
drwxr-xr-x   1 root     root        2560 May 11 03:44 sysd_socrates_070511_0355
drwxr-xr-x   2 root     root        1024 May 11 03:56 sysd_cfg_mgt

The listing above shows the sys_diag script itself, as well as the 2 directories that
were created if run with the -A (or -t) options.   The sysd_hostname_YYMMDD_HHMM directory
is the data directory where all the data files are stored for the reporting and
performance data capture.   The last directory listed as sysd_cfg_mgt is only created/used
if you run with either -t or -A to initiate tracking of system configuration changes.


The details and descriptions of the contents of both directories is listed below :

# ls ./sysd_socrates_070511_0355/ :    SYS_DIAG DATA DIRECTORY (sysd_hostname_YYMMDD_HHMM)

Filename                                 Arg    Description
_______________________________________  _____  __________________________________________________

sys_diag                                  *     A copy of the sys_diag script used
sys_diag.out                              -     sys_diag command line output (if captured)
sys_diag_perflog.out                     -g|-G  Performance Summary cmdline output (history)

sysd_socrates_070511_0355.out.html        *     **Final (Main) .html Report**
sysd_socrates_070511_0355.out.ps         -p     Postscript Report 2 pages/pg landscape
sysd_socrates_070511_0355.out.dash.html  -g|-G  Performance Analysis Dashboard .html piece
sysd_socrates_070511_0355.out             *     Sys_diag main .txt output file (for .hmtl / .ps)

sysd_net1_socrates_070511_035522.out     -g|-G  NIC1s netstat output file (NIC1= lo0)
sysd_net1_socrates_070511_0357.gr.txt    -g|-G  NIC1s graph-reformatted netstat .txt output file
sysd_net1x_socrates_070511_0357.out      -g|-G  NIC1 netstat traffic (exceptions) beyond thresholds
sysd_net2_socrates_070511_035522.out     -g|-G  NIC2 netstat output file 
sysd_net2_socrates_070511_0357.gr.txt    -g|-G  NIC1 graph-reformatted netstat .txt output file
sysd_net2x_socrates_070511_0357.out      -g|-G  NIC1 netstat traffic (exceptions) beyond thresholds
.... etc.. for all network cards ...

sysd_ifcfg_socrates_070511_0356.out     -n|-l|-g  Network ifconfig -a  output for host socrates
sysd_netstata_socrates_070511_035608.out -n|-l|-g  netstat -a  output 
sysd_netstat0_socrates_070511_035504.out  -g|-G   netstat -i -a stats summary (snapshot #0)
sysd_netstat1_socrates_070511_035604.out  -g|-G   netstat -i -a stats summary (snapshot #1)
sysd_netstat2_socrates_070511_035722.out  -g|-G   netstat -i -a stats summary (snapshot #2)
sysd_netavg1_socrates_070511_0357.out     -g|-G   Network average/Peak calculations output file #1
sysd_netavg2_socrates_070511_0357.out     -g|-G   Network average/Peak calculations output file #2

sysd_knetb_hme0_socrates_070511_035522.out -g|-G  Kstat output beginning snapshot for hme0
sysd_knetb_lo0_socrates_070511_035522.out  -g|-G  Kstat output beginning snapshot for lo0
sysd_knete_hme0_socrates_070511_035721.out -g|-G  Kstat output ending snapshot for hme0
sysd_knete_lo0_socrates_070511_035721.out  -g|-G  Kstat output ending snapshot for lo0
.... etc.. for all network cards ...

sysd_io_socrates_070511_035503.out         -g|-G  iostat data captured (raw format)
sysd_iox_socrates_070511_0357.out          -g|-G  iostat exceptions beyond thresholds
sysd_ioavg_socrates_070511_0357.out        -g|-G  iostat device avgs & peaks from post-processing
sysd_iocavg_socrates_070511_0357.out       -g|-G  iostat controller averages
sysd_vxstat0_socrates_070511_035504.out    -g|-G  vxstat FS stats (snapshot #0)
sysd_vxstat1_socrates_070511_035604.out    -g|-G  vxstat FS stats (snapshot #1)
sysd_vxstat2_socrates_070511_035722.out    -g|-G  vxstat FS stats (snapshot #2)

sysd_mp_socrates_070511_035503.out         -g|-G  mpstat data captured (raw format)
sysd_mpx_socrates_070511_0357.out          -g|-G  mpstat exceptions beyond thresholds
sysd_mdb0_socrates_070511_035504.out    -G && -V  mdb kernel memory profile (snapshot #0)
sysd_mdb1_socrates_070511_035604.out    -G && -V  mdb kernel memory profile (snapshot #1)
sysd_mdb2_socrates_070511_035722.out    -G && -V  mdb kernel memory profile (snapshot #2)

sysd_memx_socrates_070511_0357.out         -g|-G  vmstat memory exceptions

sysd_vm_socrates_070511_035503.out         -g|-G  vmstat data captured (raw format)
sysd_vm_socrates_070511_035503.out.gr.txt  -g|-G  vmstat reformatted graph datafile (S08)
sysd_vmx_socrates_070511_0357.out          -g|-G  vmstat exceptions beyond thresholds
sysd_vmavg_socrates_070511_0357.out        -g|-G  vmstat averages and Peak entries

sysd_lI0_socrates_070511_035504.out     -g|-G   Lockstat -I -W -s (snap #0) 
sysd_lI1_socrates_070511_035604.out     -g|-G   Lockstat -I -W -s (snap #1)
sysd_lI2_socrates_070511_035722.out     -g|-G   Lockstat -I -W -s (snap #2)
sysd_lA0_socrates_070511_035513.out     -g|-G   Lockstat -A -D (snap #0)
sysd_lA1_socrates_070511_035613.out     -g|-G   Lockstat -A -D (snap #1)
sysd_lA2_socrates_070511_035730.out     -g|-G   Lockstat -A -D (snap #2)
sysd_ls0_socrates_070511_035504.out        -G   Lockstat -s -D (snap #0)
sysd_ls1_socrates_070511_035604.out        -G   Lockstat -s -D (snap #1)
sysd_ls2_socrates_070511_035722.out        -G   Lockstat -s -D (snap #2)
sysd_lP0_socrates_070511_035513.out        -G   Lockstat -AP -D (snap #0)
sysd_lP1_socrates_070511_035613.out        -G   Lockstat -AP -D (snap #1)
sysd_lP2_socrates_070511_035730.out        -G   Lockstat -AP -D (snap #2)

sysd_psc0_socrates_070511_035504.out    -g|-G   Ps sorted by cpu (snap #0)
sysd_psc1_socrates_070511_035604.out    -g|-G   Ps sorted by cpu (snap #1)
sysd_psc2_socrates_070511_035721.out    -g|-G   Ps sorted by cpu (snap #2)
sysd_psm0_socrates_070511_035504.out    -g|-G   Ps sorted by mem (snap #0)
sysd_psm1_socrates_070511_035604.out    -g|-G   Ps sorted by mem (snap #1)
sysd_psm2_socrates_070511_035721.out    -g|-G   Ps sorted by mem (snap #2)
sysd_PSc_socrates_070511_035543.out     -g|-G   Ps (baseline) sorted by %cpu
sysd_PSm_socrates_070511_035543.out     -g|-G   Ps (baseline) sorted by %mem

sysd_warn_socrates_070511_035503.out  -l|-g|-G    Warning Messages from dmesg/messages/syslog...
sysd_error_socrates_070511_035503.out -l|-g|-G    Error Messages from dmesg/messages/syslog...
sysd_pkg_socrates_070511_035503.out      -l       pkginfo -l  (listing)
sysd_snoop_socrates_070511_035522.out -g &(-n|-V) network snoop output
sysd_swapl_socrates_070511_035622.out -l|(-g|-G)  Physical Swap (swap -l) and phys RAM output
sysd_sys_socrates_070511_035503.out   -l|-c	  /etc/system kernel parameters/tunables file
sysd_lwp_socrates_070511_035543.out   -l|-g|-G    Top processes via ps ..sorted by # LWP

sysd_cputrk0_socrates_070511_035504.out  -G   Cputrack top PID data (TLB_misses & % FP) (snap #0)
sysd_cputrk1_socrates_070511_035604.out  -G   Cputrack top PID data (TLB_misses & % FP) (snap #1)
sysd_cputrk2_socrates_070511_035704.out  -G   Cputrack top PID data (TLB_misses & % FP) (snap #2)
sysd_pmap0_socrates_070511_035504.out    -G   Top 5 PID details (pmap, pfiles, ptree) (snap #0)
sysd_pmap1_socrates_070511_035604.out    -G   Top 5 PID details (pmap, pfiles, ptree) (snap #1)
sysd_pmap2_socrates_070511_035704.out    -G   Top 5 PID details (pmap, pfiles, ptree) (snap #2)

sysd_dpio0_socrates_070511_035504.out    -G   Dtrace : IOsnoop for top pids (snap #0)
sysd_dpio1_socrates_070511_035604.out    -G   Dtrace : IOsnoop for top pids (snap #1)
sysd_dpio2_socrates_070511_035704.out    -G   Dtrace : IOsnoop for top pids (snap #2)
sysd_diow0_socrates_070511_035504.out    -G   Dtrace : File IO/IO waits (snap #0)
sysd_diow1_socrates_070511_035604.out    -G   Dtrace : File IO/IO waits (snap #1)
sysd_diow2_socrates_070511_035704.out    -G   Dtrace : File IO/IO waits (snap #2)
sysd_dmpc0_socrates_070511_035504.out    -G   Dtrace : Top ICSW/SMTX/XCAL (#0, if -V||avg_icsw > HWM)
sysd_dmpc1_socrates_070511_035604.out    -G   Dtrace : Top ICSW/SMTX/XCAL (#1, if -V||avg_icsw > HWM)
sysd_dmpc2_socrates_070511_035704.out    -G   Dtrace : Top ICSW/SMTX/XCAL (#2, if -V||avg_icsw > HWM)

sysd_dsyscall_counts0_socrates_070511_035504.out  -G   Dtrace syscall counts by call (snap #0) 
sysd_dsyscall_counts1_socrates_070511_035604.out  -G   Dtrace syscall counts by call (snap #1) 
sysd_dsyscall_counts2_socrates_070511_035704.out  -G   Dtrace syscall counts by call (snap #2) 
sysd_dcalls_by_procs0_socrates_070511_035504.out  -G   Dtrace process syscalls (snap #0) 
sysd_dcalls_by_procs1_socrates_070511_035604.out  -G   Dtrace process syscalls (snap #1)
sysd_dcalls_by_procs2_socrates_070511_035704.out  -G   Dtrace process syscalls (snap #2)
sysd_dintrtm0_socrates_070511_035504.out	  -G   Dtrace Interrupt times (snap #0)
sysd_dintrtm1_socrates_070511_035604.out	  -G   Dtrace Interrupt times (snap #1)
sysd_dintrtm2_socrates_070511_035704.out	  -G   Dtrace Interrupt times (snap #2)
sysd_dsdtcnt0_socrates_070511_035504.out	  -G   Dtrace sdt_ counts (snap #0)
sysd_dsdtcnt1_socrates_070511_035604.out	  -G   Dtrace sdt_ counts (snap #1)
sysd_dsdtcnt2_socrates_070511_035704.out	  -G   Dtrace sdt_ counts (snap #2)
sysd_dsinfo_by_procs0_socrates_070511_035504.out  -G   Dtrace process sysinfo counts (snap #0)
sysd_dsinfo_by_procs1_socrates_070511_035604.out  -G   Dtrace process sysinfo counts (snap #1)
sysd_dsinfo_by_procs2_socrates_070511_035704.out  -G   Dtrace process sysinfo counts (snap #2)
sysd_dtcp_rx0_socrates_070511_035504.out          -G   Dtrace process tcp reads (snap #0)
sysd_dtcp_rx1_socrates_070511_035604.out          -G   Dtrace process tcp reads (snap #1)
sysd_dtcp_rx2_socrates_070511_035704.out          -G   Dtrace process tcp reads (snap #2)
sysd_dtcp_tx0_socrates_070511_035504.out          -G   Dtrace process tcp writes (snap #0)
sysd_dtcp_tx1_socrates_070511_035604.out          -G   Dtrace process tcp writes (snap #1)
sysd_dtcp_tx2_socrates_070511_035704.out          -G   Dtrace process tcp writes (snap #2)
sysd_dR_by_procs0_socrates_070511_035504.out      -G   Dtrace process read calls (snap #0)
sysd_dR_by_procs1_socrates_070511_035604.out      -G   Dtrace process read calls (snap #1)
sysd_dR_by_procs2_socrates_070511_035704.out      -G   Dtrace process read calls (snap #2)
sysd_dW_by_procs0_socrates_070511_035504.out      -G   Dtrace process write calls (snap #0)
sysd_dW_by_procs1_socrates_070511_035604.out      -G   Dtrace process write calls (snap #1)
sysd_dW_by_procs2_socrates_070511_035704.out      -G   Dtrace process write calls (snap #2)

lockstat_files.out                       -g|-G    Lockstat syntax and output file list
socrates_change_log.out                  -t|-A    Configuration Tracking change log copy
README_sys_diag.txt			 *	  This file.


** NOTE: the vmstat and netstat .gr.txt files above can easily be imported/inserted using
	 StarOffice 8 or Excel to Generate GRAPHS.  For Staroffice 8, Insert->sheet from file
	  (delimited by space).. then hiding any columns that you don't want graphed.. following
	  the wizard for graph choices/options.

	 For Excel, File->Open (type *.txt) -> Text Import Wizard (Delimited-> Space),
	  then after import, delete un-needed columns.

--------------------------------------------------------------------------------------------

		     **Configuration Managment / Tracking Directory**

# ls ./sysd_cfg_mgt

Filename                                    Description
_______________________________________    _________________________________________________

cfgadm_last.cfg                                 Last captured /usr/sbin/cfgadm output
eeprom_last.cfg                                 Last captured /usr/sbin/eeprom output
metastat_last.cfg                               Last captured /usr/sbin/metastat output
metadb_last.cfg                                 Last captured /usr/sbin/metadb output
psrinfo_last.cfg                                Last captured /usr/sbin/psrinfo output
prtconf_last.cfg                                Last captured /usr/sbin/prtconf output
prtdiag_last.cfg                                Last captured /usr/platform/*/sbin/prtdiag -v
sysdef_last.cfg                                 Last captured /usr/sbin/sysdef -D output

F_hosts_last.cfg                                  Last captured FILE: /etc/hosts
F_mnttab_last.cfg                                 Last captured FILE: /etc/mnttab
F_nsswitch_last.cfg                               Last captured FILE: /etc/nsswitch.conf
F_resolve_last.cfg                                Last captured FILE: /etc/resolv.conf
F_syslog_last.cfg                                 Last captured FILE: /etc/syslog.conf file 
F_system_last.cfg                                 Last captured FILE: /etc/system file

socrates_change_log.out                         Change log of past/current configuration chgs

070511_0356_cfgadm.cfg                    Date stamped historical cmd output files
070511_0356_df.cfg                        
070511_0356_eeprom.cfg
070511_0356_metastat.cfg                 
070511_0356_metadb.cfg
070511_0356_psrinfo.cfg
070511_0356_prtconf.cfg
070511_0356_prtdiag.cfg
070511_0356_sysdef.cfg

070511_0356_F_hosts.cfg                   Date stamped historical configuration FILES
070511_0356_F_mnttab.cfg
070511_0356_F_nsswitch.cfg
070511_0356_F_resolve.cfg
070511_0356_F_syslog.cfg
070511_0356_F_system.cfg

** NOTE: If the -f intput_file  option is used with -t, then all files listed within
	 the input_file (as one absolute file path per line) will also be tracked for chgs.
@EOF

}


##############################  dexplore #################################
#
# Description: 'dexplore' Runs Dtrace Segments from dexplorer (if S10).
#
# Parameters:
#       $1      $sysd_dir
#       $2      $PERF		# 1= g Perf (basic), 2= G Perf (extended Perf)
#       $3      $DEBUG		# Debug on / off , 1/0 ; 2= G Perf
#       $4      $snap_num 	# snap # 0 / 1 / 2 (beginning / Middle / End)
#       $5      $VERBOSE	# 1= VERBOSE T, 0= NOT verbose
#
function dexplore {

        typeset -r sdir=$1
        typeset -r perf=$2
        typeset -r debg=$3
        typeset -r snap_num=$4
        typeset -r verbose=$5
#
#  Several of the following Dtrace segments were created by Brandon Gregg and
#  authorized for inclusion within sys_diag (being extracted from dexplorer).
#  See http://www.brendangregg.com for the original script along with
#  the complete GNU General Public License
#  as published by the Free Software Foundation; either version 2
#  of the License, or (at your option) any later version.
#
#  23-Jun-2005  Brendan Gregg 
#
#  This function has modified the original code to run at a variable sampling
#  intervals (based upon -V or not), as well as adding TCP READ activity capture.
#
    if [[ $verbose -ne 0 ]]
    then
    	interval=5		# time of each VERBOSE sampling interval in secs
    else
    	interval=2		# time of each sampling interval in secs
    fi

    dtrace=/usr/sbin/dtrace		# path to dtrace

    if [[ $debg -ne 0 ]]
    then
	echo "dexplore(): $1,$2,$3\n"

        if [[ $debg -ge 2 ]]
        then
		set -x
	fi
    fi

    log_stamp='sys_diag:'`date '+%m%d_%H%M%S'`':'
    file_suffix=$snap_num'_'`uname -n`'_'`date '+%y%m%d_%H%M%S'`'.out'

    if [[ ( -x /usr/sbin/dtrace ) && ($Solaris_Rev -ge 10) && ($perf -eq 2) ]]
    then

#	echo "\n_____________________________________________________\n"

	if [[ `$dtrace -b1k -qn 'BEGIN { trace(pid); exit(0); }'` == "" ]]; then
		print "ERROR6: Unable to run dtrace!\n"
		print "Perhaps this is a permission problem? Try running as root."
		exit 6
	fi

	clean="sed /^\$/d"

	header='dtrace:::BEGIN {
		printf("%Y, ", walltimestamp);
		printf("%s %s %s %s %s, ", `utsname.sysname, `utsname.nodename,
		    `utsname.release, `utsname.version, `utsname.machine);
		printf("%d secs\n",'$interval');
	}
	profile:::tick-'$interval'sec { exit(0); }
	'
	header2='dtrace:::BEGIN {
		printf("%Y, ", walltimestamp);
		printf("%s %s %s %s %s, ", `utsname.sysname, `utsname.nodename,
		    `utsname.release, `utsname.version, `utsname.machine);
		printf("%d secs\n\n",'$interval');
		printf(" IO WAITs for the following files/devices (wait-start) :\n\n");
		printf("   %6s %-12s %10s %12s %20s \t%s\n", "PID", "CMD", "DEVICE", 
			"b_flags", "FILE", "dev_pathname");
	}
	profile:::tick-'$interval'sec { exit(0); }
	'


########################################
#
#  Net Tests, DTrace
#
# TCP TX

        echo "$log_stamp Dtrace: TCP write bytes by process ...(_dtcp_tx Snap $snap_num)"

	$dtrace -qn "$header"'
	fbt:ip:tcp_output:entry
	{
		this->size = msgdsize(args[1]);
		@size[pid, execname] = sum(this->size);
	}
	dtrace:::END
	{ 
		printf("%6s %-16s %12s\n", "PID", "CMD", "TX_BYTES");
		printa("%6d %-16s %@12d\n", @size);
	}
	' | $clean > $sdir/sysd_dtcp_tx$file_suffix
####
# TJ .. Added the following routine for TCP RX (tcp_input:entry) activity ..
####

        echo "$log_stamp Dtrace: TCP read bytes by process ... (_dtcp_rx Snap $snap_num)"

	$dtrace -qn "$header"'
	fbt:ip:tcp_input:entry
	{
		this->size = msgdsize(args[1]);
		@size[pid, execname] = sum(this->size);
	}
	dtrace:::END
	{ 
		printf("%6s %-16s %12s\n", "PID", "CMD", "RX_BYTES");
		printa("%6d %-16s %@12d\n", @size);
	}
	' | $clean > $sdir/sysd_dtcp_rx$file_suffix
####
# TJ .. Added the following segment to capture and list system wide IO Activity
####	including IO WAIT (io:::wait-start) as well as aggregated "io:::start" IO

        echo "$log_stamp Dtrace: systemwide IO / IO wait... (_diow Snap $snap_num)"

	$dtrace -qn "$header2"'
	io:::start
	{
		@files[pid, execname, args[1]->dev_statname, args[0]->b_flags,
		args[2]->fi_pathname, args[1]->dev_pathname] = sum(args[0]->b_bcount);
	}
	io:::wait-start
	{
		printf("** %6d %-12s %10s %12x %20s %s\n",
		  pid, execname, args[1]->dev_statname, args[0]->b_flags, 
		  args[2]->fi_pathname, args[1]->dev_pathname);
	}

        dtrace:::END
        {
		normalize(@files, 1024);
		printf("\n IO for the following files/devices (io:::start) :\n");
		printf("\n%6s %-12s %10s %12s %6s %20s \t%s\n", "PID", "CMD", "DEVICE", 
			"b_flags", "KB", "FILE", "dev_pathname");
                printa("%6d %-12.12s %10s %12x %@6d %s %s\n", @files);
        }
	' 1> $sdir/sysd_diow$file_suffix 2>&1

	if [[ -r /usr/lib/dtrace/io.d ]]
	then
		echo "** NOTE : USE The following reference for interpreting *b_flags* IO operations **\n" >> $sdir/sysd_diow$file_suffix
		head -27 /usr/lib/dtrace/io.d | tail +5 >> $sdir/sysd_diow$file_suffix
	fi
#
#  Proc Tests, DTrace
#

    	log_stamp='sys_diag:'`date '+%m%d_%H%M%S'`':'
	echo "$log_stamp Dtrace: Syscall count by process...   (_dcalls_ Snap $snap_num)"
	$dtrace -qn "$header"'
	syscall:::entry { @num[pid, execname, probefunc] = count(); }
	dtrace:::END
	{ 
		printf("%6s %-24s %-24s %8s\n",
		    "PID", "CMD", "SYSCALL", "COUNT");
		printa("%6d %-24s %-24s %@8d\n", @num);
	}
	' | $clean > $sdir/sysd_dcalls_by_procs$file_suffix

    	log_stamp='sys_diag:'`date '+%m%d_%H%M%S'`':'
	echo "$log_stamp Dtrace: Syscall count by syscall...   (_dsyscall_ Snap $snap_num)"
	$dtrace -qn "$header"'
	syscall:::entry { @num[probefunc] = count(); }
	dtrace:::END
	{ 
		printf("%-32s %16s\n", "SYSCALL", "COUNT");
		printa("%-32s %@16d\n", @num);
	}
	' | $clean > $sdir/sysd_dsyscall_counts$file_suffix

    	log_stamp='sys_diag:'`date '+%m%d_%H%M%S'`':'
	echo "$log_stamp Dtrace: Read bytes by process...      (_dR_ Snap $snap_num)"
	$dtrace -qn "$header"'
	sysinfo:::readch { @bytes[pid, execname] = sum(arg0); }
	dtrace:::END
	{ 
		printf("%6s %-16s %16s\n", "PID", "CMD", "BYTES");
		printa("%6d %-16s %@16d\n", @bytes);
	}
	' | $clean > $sdir/sysd_dR_by_procs$file_suffix

    	log_stamp='sys_diag:'`date '+%m%d_%H%M%S'`':'
	echo "$log_stamp Dtrace: Write bytes by process...     (_dW_ Snap $snap_num)"
	$dtrace -qn "$header"'
	sysinfo:::writech { @bytes[pid, execname] = sum(arg0); }
	dtrace:::END
	{ 
		printf("%6s %-16s %16s\n", "PID", "CMD", "BYTES");
		printa("%6d %-16s %@16d\n", @bytes);
	}
	' | $clean > $sdir/sysd_dW_by_procs$file_suffix

    	log_stamp='sys_diag:'`date '+%m%d_%H%M%S'`':'
	echo "$log_stamp Dtrace: Sysinfo counts by process...  (_dsinfo_ Snap $snap_num)"
	$dtrace -qn "$header"'
	sysinfo::: { @num[pid, execname, probename] = sum(arg0); }
	dtrace:::END
	{ 
		printf("%6s %-16s %-16s %16s\n", 
		    "PID", "CMD", "STATISTIC", "COUNT");
		printa("%6d %-16s %-16s %@16d\n", @num);
	}
	' | $clean > $sdir/sysd_dsinfo_by_procs$file_suffix


    	log_stamp='sys_diag:'`date '+%m%d_%H%M%S'`':'
	echo "$log_stamp Dtrace: Sdt_counts               ...  (_dsdtcnt_ Snap $snap_num)"
	$dtrace -qn "$header"'
        sdt:::{ @num[probefunc, probename] = count(); }
        dtrace:::END
        {
                printf("%-32s %-32s %10s\n", "FUNC", "NAME", "COUNT");
                printa("%-32s %-32s %@10d\n", @num);
        }
	' | $clean > $sdir/sysd_dsdtcnt$file_suffix


    	log_stamp='sys_diag:'`date '+%m%d_%H%M%S'`':'
	echo "$log_stamp Dtrace: Interupt Times [sdt:::intr].. (_dintrtm_ Snap $snap_num)"
	$dtrace -qn "$header"'
        sdt:::interrupt-start { self->ts = vtimestamp; }
        sdt:::interrupt-complete
        /self->ts && arg0 != 0/
        {
                this->devi = (struct dev_info *)arg0;
                self->name = this->devi != 0 ?
                    stringof(`devnamesp[this->devi->devi_major].dn_name) : "?";
                this->inst = this->devi != 0 ? this->devi->devi_instance : 0;
                @num[self->name, this->inst] = sum(vtimestamp - self->ts);
                self->name = 0;
        }
        sdt:::interrupt-complete { self->ts = 0; }
        dtrace:::END
        {
                printf("%11s    %16s\n", "DEVICE", "TIME (ns)");
                printa("%10s%-3d %@16d\n", @num);
        }
	' | $clean > $sdir/sysd_dintrtm$file_suffix




    fi
}



##############################  io_by_pid #################################
#
# Description: 'io_by_pid' Runs Dtrace Segments from iosnoop (if S10).
#
# Parameters:
#       $1      $sysd_dir
#       $2      $PID
#       $3      $DEBUG		# Debug on / off , 1/0 ; 2= G Perf
#       $4      $snap_num	# bme Snap # : 0 / 1 / 2 (beginning / Midpt / Endpt)
#       $5      $dpio_file 	# _dpio snapshot output file
#       $6      $VERBOSE 	# VERBOSE on / off , 1 or 0 
#
function io_by_pid {

        typeset -r sdir=$1
        typeset -r pid=$2
        typeset -r debg=$3
        typeset -r snap_num=$4
        typeset -r dio_file=$5
        typeset -r verbose=$6
#
# NOTE:  This function was based upon the Dtrace Toolkit script iosnoop
#
# iosnoop - print disk I/O events as they happen, with useful
#           details such as UID, PID, filename, command, etc. 
#           Written using DTrace (Solaris 10 3/05).
#
# This measures disk events that have made it past system caches.
#
# FIELDS:
#		UID		user ID
#		PID		process ID
#		PPID		parennt process ID
#		COMM		command name for the process
#		ARGS		argument listing for the process
#		SIZE		size of operation, bytes
#		BLOCK		disk block for the operation (location)
#		STIME	 	timestamp for the disk request, us
#		TIME		timestamp for the disk completion, us
#		DELTA		elapsed time from request to completion, us
#		DTIME		time for disk to complete request, us
#		STRTIME		timestamp for the disk completion, string
#		DEVICE  	device name
#		INS     	device instance number
#		D		direction, Read or Write
#		MOUNT		mount point
#		FILE		filename (basename) for io operation
# 
#
# COPYRIGHT: Copyright (c) 2005 Brendan Gregg.
# SEE ALSO: BigAdmin: DTrace, http://www.sun.com/bigadmin/content/dtrace
#	    Solaris Dynamic Tracing Guide, http://docs.sun.com
#	    DTrace Tools, http://www.brendangregg.com/dtrace.html
#
# CDDL HEADER START
#
#  The contents of this function are subject to the terms of the
#  Common Development and Distribution License, Version 1.0 only
#  (the "License").  You may not use this file except in compliance
#  with the License.
#  Brandon Gregg authorized inclusion within sys_diag with these comments.
#  See http://www.brendangregg.com for the original script along with
#  the complete GNU General Public License
#  as published by the Free Software Foundation; either version 2
#  of the License, or (at your option) any later version.
#
# 23-Jun-2005  Brendan Gregg 
# 17-Sep-2005  ver 1.55      "	Increased switchrate.
# 30-May-2007  Todd Jobson  Streamlined and embedded portion as function within sys_diag
#
#
    if [[ $verbose -ne 0 ]]
    then
    	interval=5		# time of each VERBOSE sampling interval in secs
    else
    	interval=2		# time of each sampling interval in secs
    fi

    dtrace=/usr/sbin/dtrace	# path to dtrace

	if [[ $debg -ne 0 ]]
	then
	    echo "io_by_pid(): $1\n\t$2\n\t$3\n\t$4\n\t$5\n"

	    if [[ $debg -ge 2 ]]
	    then
		set -x
	    fi
	fi

    log_stamp='sys_diag:'`date '+%m%d_%H%M%S'`':'
    file_suffix='_'`uname -n`'_'`date '+%y%m%d_%H%M%S'`'.out'

    if [[ -x /usr/sbin/dtrace ]]
    then

##############################
# --- Process Arguments ---
#

### default variables
opt_dump=0; opt_device=0; opt_delta=0; opt_devname=0; opt_file=0; opt_args=0; 
opt_mount=0; opt_start=0 opt_end=0; opt_endstr=0; opt_ins=0; opt_nums=0
opt_dtime=0; filter=0; device=.; filename=.; mount=.; pname=.
opt_name=0; opt_pid=0

opt_pid=1

filter=1

echo "$log_stamp Dtrace: IO by process $i ... (_dpio Snap $snap_num)"

header='inline int OPT_args 	= '$opt_args';
 inline int OPT_nums  	= '$opt_nums';
 inline int OPT_pid 	= '$opt_pid';
 inline int FILTER 	= '$filter';
 inline int PID 	= '$pid';
 inline string DEVICE 	= "'$device'";
 inline string FILENAME = "'$filename'";
 inline string MOUNT 	= "'$mount'";
 inline string NAME 	= "'$pname'";
 
 #pragma D option quiet
 #pragma D option switchrate=10hz

 dtrace:::BEGIN 
 {
	last_event[""] = 0;

	printf("%Y, ", walltimestamp);
	printf("%s %s %s %s %s, ", `utsname.sysname, `utsname.nodename,
	    `utsname.release, `utsname.version, `utsname.machine);
	printf("%d secs  for *PID* %d\n",'$interval','$pid');

 	printf("%5s %5s %1s %10s %8s %6s ", "UID", "PID", "D", "b_flags", "BLOCK", "SIZE");
	printf("%10s %s\n", "COMM", "PATHNAME");

	}
	profile:::tick-'$interval'sec { exit(0); }
'

# /usr/sbin/dtrace -n '

$dtrace -n "$header"'

 io:genunix::start
 { 
	/* default is to trace unless filtering, */
	self->ok = FILTER ? 0 : 1;

	/* check each filter, */
	(OPT_pid == 1 && PID == pid) ? self->ok = 1 : 1;
 }

 /*
  * Reset last_event for disk idle -> start
  * this prevents idle time being counted as disk time.
  */
 io:genunix::start
 /! pending[args[1]->dev_statname]/
 {
	/* save last disk event */
	last_event[args[1]->dev_statname] = timestamp;
 }

 /*
  * Store entry details
  */
 io:genunix::start
 /self->ok/
 {
	/* these are used as a unique disk event key, */
 	this->dev = args[0]->b_edev;
 	this->blk = args[0]->b_blkno;

	/* save disk event details, */
 	start_uid[this->dev, this->blk] = uid;
 	start_pid[this->dev, this->blk] = pid;
 	start_ppid[this->dev, this->blk] = ppid;
 	start_args[this->dev, this->blk] = (char *)curpsinfo->pr_psargs;
 	start_comm[this->dev, this->blk] = execname;
 	start_time[this->dev, this->blk] = timestamp;

	/* increase disk event pending count */
	pending[args[1]->dev_statname]++;

	self->ok = 0;
 }

 /*
  * Process and Print completion
  */
 io:genunix::done
 /start_time[args[0]->b_edev, args[0]->b_blkno]/
 {
	/* decrease disk event pending count */
	pending[args[1]->dev_statname]--;

	/*
	 * Process details
	 */

 	/* fetch entry values */
 	this->dev = args[0]->b_edev;
 	this->blk = args[0]->b_blkno;
 	this->suid = start_uid[this->dev, this->blk];
 	this->spid = start_pid[this->dev, this->blk];
 	this->sppid = start_ppid[this->dev, this->blk];
 	self->sargs = (int)start_args[this->dev, this->blk] == 0 ? 
 	    "" : start_args[this->dev, this->blk];
 	self->scomm = start_comm[this->dev, this->blk];
 	this->stime = start_time[this->dev, this->blk];
	this->etime = timestamp; /* endtime */
	this->delta = this->etime - this->stime;
	this->dtime = last_event[args[1]->dev_statname] == 0 ? 0 :
	    timestamp - last_event[args[1]->dev_statname];

 	/* memory cleanup */
 	start_uid[this->dev, this->blk]  = 0;
 	start_pid[this->dev, this->blk]  = 0;
 	start_ppid[this->dev, this->blk] = 0;
 	start_args[this->dev, this->blk] = 0;
 	start_time[this->dev, this->blk] = 0;
 	start_comm[this->dev, this->blk] = 0;
 	start_rw[this->dev, this->blk]   = 0;

	/* print main fields */
        printf("%5d %5d %1s %10x %8d %6d ",
 	    this->suid, this->spid, args[0]->b_flags & B_READ ? "R" : "W",
	    args[0]->b_flags, args[0]->b_blkno, args[0]->b_bcount);
	printf("%10s %s\n", self->scomm, args[2]->fi_pathname);

	/* save last disk event */
	last_event[args[1]->dev_statname] = timestamp;

	/* cleanup */
	self->scomm = 0;
	self->sargs = 0;
 }

 /*
  * Prevent pending from underflowing
  * this can happen if this program is started during disk events.
  */
 io:genunix::done
 /pending[args[1]->dev_statname] < 0/
 {
	pending[args[1]->dev_statname] = 0;
 }
' >> $dio_file
#' > $sdir'/sysd_dpio'$snap_num'_pid'$pid$file_suffix

	echo "\n____________________________________________________________________\n">> $dio_file

    fi
}


####################  snap_bme_perf ###########################
#
# Description: 'snap_bme_perf' Captures a snapshot of dtrace (if S10 and -G),
#		lockstat, and PS data (called at the beggining, mid, end.
#
# Parameters:
#       $1      $sysd_dir
#       $2      snap_num	#  0/1/2, Beg/Mid/Last snapshot 
#       $3      $DEBUG		# Debug on / off , 1/0 ; 2= G Perf
#       $4      $PERF		# 1= g Perf (basic), 2= G Perf (extended Perf)
#       $5      $VERBOSE	# 1= VERBOSE T, 0= NOT verbose
#
function snap_bme_perf {

        typeset -r sdir=$1
        typeset -r snap_num=$2
        typeset -r debg=$3
        typeset -r perf=$4
        typeset -r verbose=$5

        typeset -i num_cpus
#
    	if [[ $verbose -ne 0 ]]
    	then
    		interval=5		# time of each VERBOSE sampling interval in secs
    	else
    		interval=2		# time of each sampling interval in secs
    	fi

    	dtrace=/usr/sbin/dtrace		# path to dtrace

	if [[ $debg -ne 0 ]]
	then
	    echo "snap_bme_perf():\tsdir=$1,\tsnap_num=$2,\tdebg=$3,\tperf=$4,\tverbose=$5\n"
	    echo "\tvmpid=$vmpid\n\tiopid=$iopid\n\tmppid=$mppid\n"
	    echo "\tSolaris_Rev=$Solaris_Rev\n"

	    if [[ $debg -ge 2 ]]
	    then
		set -x
	    fi
	fi

	log_stamp='sys_diag:'`date '+%m%d_%H%M%S'`':'

	if [[ ($Solaris_Rev -ge 10) && ($perf -eq 2) ]]
	then
		dexplore $sdir $perf $debg $snap_num $VERBOSE	## gather Dtrace Metrics ..
		sleep 2
	fi

	ps_cpu_file=$sdir'/sysd_psc'$snap_num'_'`uname -n`'_'`date '+%y%m%d_%H%M%S'`'.out'
	ps_mem_file=$sdir'/sysd_psm'$snap_num'_'`uname -n`'_'`date '+%y%m%d_%H%M%S'`'.out'
	dpio_filename=$sdir'/sysd_dpio'$snap_num'_'`uname -n`'_'`date '+%y%m%d_%H%M%S'`'.out'

        echo "\n\n# ps -e -opcpu,pid,ppid,user,nlwp,pmem,vsz,rss,s,time,stime,pri,nice,args (by %CPU) :\n\n" >> $ps_cpu_file
        echo "$log_stamp # ps -e -o ...(by %CPU) ...           Snapshot # $snap_num"

        ps -e -opcpu,pid,ppid,user,nlwp,pmem,vsz,rss,s,time,stime,pri,nice,args | sort -r -k 1,1 >> $ps_cpu_file

        echo "\n\n# ps -e -opmem,pid,ppid,user,nlwp,vsz,rss,s,time,stime,pri,nice,pcpu,args (by %MEM) :\n\n" >> $ps_mem_file
        echo "$log_stamp # ps -e -o ...(by %MEM) ...           Snapshot # $snap_num"

        ps -e -opmem,pid,ppid,user,nlwp,vsz,rss,s,time,stime,pri,nice,pcpu,args | sort -r -k 1,1 >> $ps_mem_file


############ Investigate the top processes ###########

	if [[ $verbose -ne 0 ]]	###### IF VERBOSE
	then
		num_procs=10
	else
		num_procs=5
	fi

	if [[ ( ( -x /usr/proc/bin/pmap ) && ( $perf -ge 2 ) ) || ( $verbose -ne 0  )  ]]
	then

		pmap_file=$sdir'/sysd_pmap'$snap_num'_'`uname -n`'_'`date '+%y%m%d_%H%M%S'`'.out'
		cputrack_file=$sdir'/sysd_cputrk'$snap_num'_'`uname -n`'_'`date '+%y%m%d_%H%M%S'`'.out'

		for i in `ps -e -opcpu,pid | grep -v PID | sort -r -k 1,1 | /usr/bin/awk '{ print $2 }' | head -$num_procs`

		do		
      		    log_stamp='sys_diag:'`date '+%m%d_%H%M%S'`':'

		    if [[ $i -eq $$ ]] 	## If sys_diag, skip
		    then
			continue
		    fi

		    if [[ $snap_num -gt 0 ]]  ## if not the first snapshot (no bkgrnd pids yet)
		    then

			if [[ ( ( $i -eq $vmpid ) || ( $i -eq $iopid ) || ( $i -eq $mppid ) ) ]]
			then	
				continue	## IF PID = perf data collection pids, skip it..
			fi

			nn=1
			is_netpid=0

   			while [ $nn -le $num_nets ]
		      	do
				if [[ ( $i -eq $((netpid[$nn])) ) ]]
				then
					is_netpid=1
					nn=$(($nn+1))
					continue	## IF PID = any netstat perf capt pids, skip
				fi

				nn=$(($nn+1))
			done

			if [[ $is_netpid -ne 0 ]]
			then
				continue
			fi

# no longer used	if [[ $num_llts -gt 0 ]]	## LLTSTAT final status snap has totals
#			then
#	## This could do a while through all kstatpid[$num_llts]
#				if [[ $i -eq kstatpid[1] ]]
#				then
#					continue
#				fi
#			fi
		    fi

			/usr/proc/bin/pmap -x $i 1>/dev/null 2>&1
	
			if [[ $? -eq 0 ]]
			then
	    			if (( $Solaris_Rev > 8 ))
	    			then
					echo "\n# pmap -xs $i\n" >> $pmap_file
					echo "$log_stamp # pmap -xs $i ..."
					/usr/proc/bin/pmap -xs $i | head -500 1>> $pmap_file 2>&1
				else
					echo "\n# pmap -x $i\n" >> $pmap_file
					echo "$log_stamp # pmap -x $i ..."
					/usr/proc/bin/pmap -x $i | head -500 1>> $pmap_file 2>&1
				fi

	    			if (( $Solaris_Rev > 8 ))
	    			then
					echo "\n\n# pmap -S $i\n" >> $pmap_file
					echo "$log_stamp # pmap -S $i ..."
					/usr/proc/bin/pmap -S $i | head -500 1>> $pmap_file 2>&1

					echo "\n\n# pmap -r $i\n" >> $pmap_file
					echo "$log_stamp # pmap -r $i ..."
					/usr/proc/bin/pmap -r $i | head -500 1>> $pmap_file 2>&1
				fi

				echo "\n\n# ptree -a $i\n" >> $pmap_file
				echo "$log_stamp # ptree -a $i ..."
				/usr/proc/bin/ptree -a $i | head -500 1>> $pmap_file 2>&1

				if [[ ( -x /usr/proc/bin/pfiles ) && ($Solaris_Rev -gt 8) ]]
				then
					echo "\n\n# pfiles $i\n" >> $pmap_file
					echo "$log_stamp # pfiles $i ..."
					/usr/proc/bin/pfiles $i | head -500 1>> $pmap_file 2>&1
				fi

				if [[ ($Solaris_Rev -ge 10) && ($perf -ge 2) ]]
				then
					## capture IO activity for this PID using Dtrace ##

					io_by_pid $sysd_dir $i $DEBUG $snap_num $dio_filename $verbose
					sleep 1
					
					if [[ -x /usr/bin/cputrack ]]
					then
					    /usr/bin/cputrack -h | grep ITLB_miss 1>/dev/null 2>&1

					    if [[ $? -eq 0 ]]
					    then
#TJ ! Fix echo formats and other syntax on pic0...
        					echo "# cputrack -c pic0=ITLB_miss,pic1=Instr_cnt -c pic0=Instr_cnt,pic1=DTLB_miss -N 3 -p $i\n" >> $cputrack_file
        					echo "$log_stamp # cputrack -c pic0=ITLB_miss,pic1=Instr_cnt -c pic0=Instr_cnt,pic1=DTLB_miss -N 3 -p $i ..."
        					/usr/bin/cputrack -c pic0=ITLB_miss,pic1=Instr_cnt -c pic0=Instr_cnt,pic1=DTLB_miss -N 3 -p $i 1>> $cputrack_file 2>&1
						echo "\n____________________________________________________________________\n">> $cputrack_file
					    else
        					echo "# cputrack -c pic0=ITLB_miss,pic1=Instr_cnt -c pic0=Instr_cnt,pic1=DTLB_miss -N 3 -p $i ...FAILED\n" >> $cputrack_file
					    	/usr/bin/cputrack -h 1>> $cputrack_file 2>&1
					    fi

					    /usr/bin/cputrack -h | grep FP_instr_cnt 1>/dev/null 2>&1

					    if [[ $? -eq 0 ]]
					    then
        					echo "# cputrack -c pic0=FP_instr_cnt,pic1=Instr_cnt -N 3 -p $i\n" >> $cputrack_file
        					echo "$log_stamp # cputrack -c pic0=FP_instr_cnt,pic1=Instr_cnt -N 3 -p $i ..."
        					/usr/bin/cputrack -c pic0=FP_instr_cnt,pic1=Instr_cnt -N 3 -p $i 1>> $cputrack_file 2>&1
						echo "\n____________________________________________________________________\n">> $cputrack_file
					    else
        					echo "# cputrack -c pic0=FP_instr_cnt,pic1=Instr_cnt -N 3 -p $i  ... FAILED\n" >> $cputrack_file
					    	/usr/bin/cputrack -h | grep FA_pipe_completion 1>/dev/null 2>&1

					    	if [[ $? -eq 0 ]]
					    	then
        					    echo "# cputrack -c pic0=FA_pipe_completion,pic1=Instr_cnt -c pic0=Instr_cnt,pic1=FM_pipe_completion -N 3 -p $i\n" >> $cputrack_file
        					    echo "$log_stamp # cputrack -c pic0=FA_pipe_completion,pic1=Instr_cnt -c pic0=Instr_cnt,pic1=FM_pipe_completion -N 3 -p $i ..."
        					    /usr/bin/cputrack -c pic0=FA_pipe_completion,pic1=Instr_cnt -c pic0=Instr_cnt,pic1=FM_pipe_completion -N 3 -p $i 1>> $cputrack_file 2>&1
						    echo "\n____________________________________________________________________\n">> $cputrack_file
						else
        					        echo "# cputrack -c pic0=FA_pipe_completion,pic1=Instr_cnt -c pic0=Instr_cnt,pic1=FM_pipe_completion -N 3 -p $i ...FAILED\n" >> $cputrack_file
					    		/usr/bin/cputrack -h 1>> $cputrack_file 2>&1
						fi
					    fi

					fi
				fi
			fi
			echo "\n____________________________________________________________________\n" >> $pmap_file
		done

	fi	## End Top Procs 

	netstat_file=$sdir'/sysd_netstat'$snap_num'_'`uname -n`'_'`date '+%y%m%d_%H%M%S'`'.out'
	vxstat_file=$sdir'/sysd_vxstat'$snap_num'_'`uname -n`'_'`date '+%y%m%d_%H%M%S'`'.out'
	loutfile=$sdir'/lockstat_files.out'

	echo "$log_stamp # /usr/bin/netstat -i -a ..."
	/usr/bin/netstat -i -a > $netstat_file

	if [[ -x /usr/sbin/vxprint ]]
	then
	
	    for i in `/usr/sbin/vxprint -S | grep Disk | cut -c13-`
	    do
#		echo "# /usr/sbin/vxstat -g "$i"\n" >> $outfile
#		echo "$log_stamp # /usr/sbin/vxstat -g "$i" ..."
#		/usr/sbin/vxstat -g $i >> $outfile

#		echo "# /usr/sbin/vxstat -g "$i" -i 1 -c 5\n" >> $outfile
		echo "$log_stamp # /usr/sbin/vxstat -g "$i" -i 1 -c 5 ..."

# TJ Possibly change this from -c 5 to -c 1 so that the data can be parsed more easily..

		/usr/sbin/vxstat -g $i -i 1 -c 5 >> $vxstat_file
	    done
	fi
		
	if [[ $perf -eq 2 ]]	## IF -G deep perf gathering.. then check which OS.. S10/9/8..
	then

	   log_stamp='sys_diag:'`date '+%m%d_%H%M%S'`':'

	   if [[ $verbose -ne 0 ]]
	   then
	   	if [[ ( -x /usr/bin/mdb ) && ( $verbose -ne 0 ) ]]
	   	then
			mdb_file=$sdir'/sysd_mdb'$snap_num'_'`uname -n`'_'`date '+%y%m%d_%H%M%S'`'.out'
			echo "$log_stamp # Snapshot Kernel Memory Usage.. ::memstat | mdb -k ..."
			echo "::memstat" | /usr/bin/mdb -k > $mdb_file
	   	fi

		lockstat_interval=5
	   else
		lockstat_interval=2
	   fi

	   log_stamp='sys_diag:'`date '+%m%d_%H%M%S'`':'

	   if [[ -x /usr/sbin/lockstat  &&  ($Solaris_Rev -ge 10) ]]
	   then
		echo "" >> $outfile
    		lkstat_Ifile=$sdir'/sysd_lI'$snap_num'_'`uname -n`'_'`date '+%y%m%d_%H%M%S'`'.out'
		echo "##** (/usr/sbin/lockstat_-IW_-n_100000_-s_13_"$lockstat_interval"sec)  $lkstat_Ifile\n" >> $loutfile
		echo "$log_stamp # /usr/sbin/lockstat -IW -n 100000 -s 13 sleep $lockstat_interval ..."
		/usr/sbin/lockstat -IW -n 100000 -s 13 -o $lkstat_Ifile sleep $lockstat_interval

		sleep 1  # rest the system and catch up
	   	log_stamp='sys_diag:'`date '+%m%d_%H%M%S'`':'

		lkstat_Afile=$sdir'/sysd_lA'$snap_num'_'`uname -n`'_'`date '+%y%m%d_%H%M%S'`'.out'
		echo "##** (/usr/sbin/lockstat_-A_-n_90000_-D15_"$lockstat_interval"sec)  $lkstat_Afile\n" >> $loutfile
		echo "$log_stamp # /usr/sbin/lockstat -A -n 90000 -D15 sleep $lockstat_interval ..."
		/usr/sbin/lockstat -A -n 90000 -D15 -o $lkstat_Afile sleep $lockstat_interval

		sleep 1  # rest the system and catch up
	   	log_stamp='sys_diag:'`date '+%m%d_%H%M%S'`':'

		lkstat_sfile=$sdir'/sysd_ls'$snap_num'_'`uname -n`'_'`date '+%y%m%d_%H%M%S'`'.out'
		echo "##** (/usr/sbin/lockstat_-A_-s8_-n_90000_-D10_"$lockstat_interval"sec)  $lkstat_sfile\n" >> $loutfile
		echo "$log_stamp # /usr/sbin/lockstat -A -s8 -n 90000 -D10 sleep $lockstat_interval ..."
		/usr/sbin/lockstat -A -s8 -n 90000 -D10 -o $lkstat_sfile sleep $lockstat_interval

		sleep 1  # rest the system and catch up
	   	log_stamp='sys_diag:'`date '+%m%d_%H%M%S'`':'

		lkstat_Pfile=$sdir'/sysd_lP'$snap_num'_'`uname -n`'_'`date '+%y%m%d_%H%M%S'`'.out'
		echo "##** (/usr/sbin/lockstat_-AP_-n_90000_-D10_"$lockstat_interval"sec)  $lkstat_Pfile\n" >> $loutfile
		echo "$log_stamp # /usr/sbin/lockstat -AP -n 90000 -D10 sleep $lockstat_interval ..."
		/usr/sbin/lockstat -AP -n 90000 -D10 -o $lkstat_Pfile sleep $lockstat_interval

	   elif [[ -x /usr/sbin/lockstat  &&  ($Solaris_Rev -eq 9) ]]
	   then
		echo "##** (/usr/sbin/lockstat_-IW_-n_75000_-s13_2sec)  $lkstat_Ifile\n" >> $loutfile
		echo "$log_stamp # /usr/sbin/lockstat -IW -n 75000 -s13 sleep 2 ..."
    		lkstat_Ifile=$sdir'/sysd_lI'$snap_num'_'`uname -n`'_'`date '+%y%m%d_%H%M%S'`'.out'
		/usr/sbin/lockstat -IW -n 75000 -s 13 -o $lkstat_Ifile sleep 2

		lkstat_Afile=$sdir'/sysd_lA'$snap_num'_'`uname -n`'_'`date '+%y%m%d_%H%M%S'`'.out'
		echo "##** (/usr/sbin/lockstat_-A_-n_75000_-D15_2sec)  $lkstat_Afile\n" >> $loutfile
		echo "$log_stamp # /usr/sbin/lockstat -A -n 75000 -D15 sleep 2 ..."
		/usr/sbin/lockstat -A -n 75000 -D15 -o $lkstat_Afile sleep 2

		lkstat_sfile=$sdir'/sysd_ls'$snap_num'_'`uname -n`'_'`date '+%y%m%d_%H%M%S'`'.out'
		echo "##** (/usr/sbin/lockstat_-s10_-n_75000_-D10_1sec)  $lkstat_sfile\n" >> $loutfile
		echo "$log_stamp # /usr/sbin/lockstat -s10 -n 75000 -D10 sleep 1 ..."
		/usr/sbin/lockstat -s10 -n 75000 -D10 -o $lkstat_sfile sleep 1

		lkstat_Pfile=$sdir'/sysd_lP'$snap_num'_'`uname -n`'_'`date '+%y%m%d_%H%M%S'`'.out'
		echo "##** (/usr/sbin/lockstat_-AP_-n_50000_-D10_1sec)  $lkstat_Pfile\n" >> $loutfile
		echo "$log_stamp # /usr/sbin/lockstat -AP -n 50000 -D10 sleep 1 ..."
		/usr/sbin/lockstat -AP -n 50000 -D10 -o $lkstat_Pfile sleep 1

	   elif [[ -x /usr/sbin/lockstat  &&  ($Solaris_Rev -eq 8) ]]
	   then
    		lkstat_Ifile=$sdir'/sysd_lI'$snap_num'_'`uname -n`'_'`date '+%y%m%d_%H%M%S'`'.out'
		echo "##** (/usr/sbin/lockstat_-IW_-s_13_2sec)  $lkstat_Ifile\n" >> $loutfile
		echo "$log_stamp # /usr/sbin/lockstat -IW -s 13 sleep 2 ..."
		/usr/sbin/lockstat -IW -s 13 -o $lkstat_Ifile sleep 2

		lkstat_Afile=$sdir'/sysd_lA'$snap_num'_'`uname -n`'_'`date '+%y%m%d_%H%M%S'`'.out'
		echo "##** (/usr/sbin/lockstat_-A_-D15_2sec)  $lkstat_Afile\n" >> $loutfile
		echo "$log_stamp # /usr/sbin/lockstat -A -D15 sleep 2 ..."
		/usr/sbin/lockstat -A -D15 -o $lkstat_Afile sleep 5

		lkstat_sfile=$sdir'/sysd_ls'$snap_num'_'`uname -n`'_'`date '+%y%m%d_%H%M%S'`'.out'
		echo "##** (/usr/sbin/lockstat_-s10_-D10_1sec)  $lkstat_sfile\n" >> $loutfile
		echo "$log_stamp # /usr/sbin/lockstat -s10 -D10 sleep 1 ..."
		/usr/sbin/lockstat -s10 -D10 -o $lkstat_sfile sleep 1

		lkstat_Pfile=$sdir'/sysd_lP'$snap_num'_'`uname -n`'_'`date '+%y%m%d_%H%M%S'`'.out'
		echo "##** (/usr/sbin/lockstat_-AP_-D10_1sec)  $lkstat_Pfile\n" >> $loutfile
		echo "$log_stamp # /usr/sbin/lockstat -AP -D10 sleep 1 ..."
		/usr/sbin/lockstat -AP -D10 -o $lkstat_Pfile sleep 1
	   fi

	else	####### LIGHTWEIGHT LOCKSTAT from -g (vs -G above) #######

    		lkstat_Ifile=$sdir'/sysd_lI'$snap_num'_'`uname -n`'_'`date '+%y%m%d_%H%M%S'`'.out'
		echo "##** (/usr/sbin/lockstat_-IW_-s_10_1sec)  $lkstat_Ifile\n" >> $loutfile
		echo "$log_stamp # /usr/sbin/lockstat -IW -s 10 sleep 1 ..."
		/usr/sbin/lockstat -IW -s 10 -o $lkstat_Ifile sleep 1

		sleep 1  # rest the system and catch up
	   	log_stamp='sys_diag:'`date '+%m%d_%H%M%S'`':'

		lkstat_Pfile=$sdir'/sysd_lP'$snap_num'_'`uname -n`'_'`date '+%y%m%d_%H%M%S'`'.out'
		echo "##** (/usr/sbin/lockstat_-AP_-D13_1sec)  $lkstat_Pfile\n" >> $loutfile
		echo "$log_stamp # /usr/sbin/lockstat -AP -D13 -n50000 sleep 1 ..."
		/usr/sbin/lockstat -AP -D13 -n50000 -o $lkstat_Pfile sleep 1
	fi

############ Investigate the top MPSTAT Exceptions and Causes (ICSW, XCALLS, SMTX,..) ###########

  if [[ ( -x /usr/sbin/dtrace ) && ($Solaris_Rev -ge 10) && ($perf -ge 2) ]]
  then

#	echo "\n____________________________________________________________________\n"

	if [[ `$dtrace -b1k -qn 'BEGIN { trace(pid); exit(0); }'` == "" ]]; then
		print "ERROR6: Unable to run dtrace!\n"
		print "Perhaps this is a permission problem? Try running as root."
		exit 6
	fi

	clean="sed /^\$/d"

	header='dtrace:::BEGIN {
		printf("%Y, ", walltimestamp);
		printf("%s %s %s %s %s, ", `utsname.sysname, `utsname.nodename,
		    `utsname.release, `utsname.version, `utsname.machine);
		printf("%d secs\n",'$interval');
	}
	profile:::tick-'$interval'sec { exit(0); }
	'

############################################################################
#
#  MPSTAT AVG for last interval.. and IF > Thresholds for icsw, smtx.. then DTrace
#
     log_stamp='sys_diag:'`date '+%m%d_%H%M%S'`':'
     file_suffix=$snap_num'_'`uname -n`'_'`date '+%y%m%d_%H%M%S'`'.out'

     num_cpus=`psrinfo | wc -l`

     if [[ -x /usr/bin/mpstat ]]
     then
	mp_avg=`mpstat -q 1 2 | tail -$num_cpus | /usr/bin/awk '{ if ( $1 != "procs" ) { w+=$15 ; xcal+=$4 ; csw+=$7 ; icsw+=$8 ; migr+=$9 ; smtx+=$10 ; syscl+=$12 ; num++ } { num_lines++ } } END { printf "Wt=%d Xcal=%d csw=%d icsw=%d migr=%d smtx=%d syscl=%d",(w/num),(xcal/num),(csw/num),(icsw/num),(migr/num),(smtx/num),(syscl/num) }' num=0`

     	avg_icsw=`echo $mp_avg | /usr/bin/awk '{ print $4 }'`
     	avg_smtx=`echo $mp_avg | /usr/bin/awk '{ print $6 }'`

###   IF mpstat ICSW OR SMTX AVERAGES are higher than the THRESHOLD High Water Marks...

        if [[ ( ( $avg_icsw -ge $MPSTAT_ICSW_GT ) || ( $avg_smtx -ge $MPSTAT_SMTX_GT ) ) || ( $verbose -ne 0 ) ]]
       then

	echo $mp_avg > $sdir/sysd_dmpc$file_suffix
	echo "\n____________________________________________________________________\n" >> $sdir/sysd_dmpc$file_suffix
        echo "$log_stamp Dtrace: Involuntary Context Switches (icsw) by process .. (_dmpc Snap $snap_num)"
        echo "$log_stamp Dtrace: Involuntary Context Switches (icsw) caused by process ..\n" >> $sdir/sysd_dmpc$file_suffix

	$dtrace -qn "$header"'
	sysinfo:::inv_swtch
	{
		@[pid, execname] = count();
	}
	' | $clean >> $sdir/sysd_dmpc$file_suffix

	echo "\n____________________________________________________________________\n" >> $sdir/sysd_dmpc$file_suffix

    	log_stamp='sys_diag:'`date '+%m%d_%H%M%S'`':'

        echo "$log_stamp Dtrace: Cross CPU Calls (xcal) caused by process ........ (_dmpc Snap $snap_num)"
        echo "$log_stamp Dtrace: Cross CPU Calls (xcal) caused by process ..\n" >> $sdir/sysd_dmpc$file_suffix

	$dtrace -qn "$header"'
	sysinfo:::xcalls
	{
		@[pid, execname] = count();
	}
/*	dtrace:::END
	{ 
		printf("SYSINFO:::XCALLS .. COMPLETE.\n");
	}
*/
	' | $clean >> $sdir/sysd_dmpc$file_suffix

	echo "\n____________________________________________________________________\n" >> $sdir/sysd_dmpc$file_suffix

    	log_stamp='sys_diag:'`date '+%m%d_%H%M%S'`':'

        echo "$log_stamp Dtrace: MUTEX try lock (smtx) by lwp/process ............ (_dmpc Snap $snap_num)"
        echo "$log_stamp Dtrace: MUTEX try lock (smtx) by lwp/process ..\n" >> $sdir/sysd_dmpc$file_suffix

	$dtrace -qn "$header"'
	::lwp_mutex_trylock:entry
	{
		@[pid, execname] = count();
	}
	' | $clean >> $sdir/sysd_dmpc$file_suffix

     fi

    fi 		### END if -x /usr/bin/mpstat

  fi	  #### END if dtrace && S10 .. Investigate top contention Events ####


}    ## END snap_bme_perf
 
####################  gen_html_hdr  ###########################
#
# Description: 'gen_html_hdr' generates an HTML header for the
#		main sys_diag output file (outfile) .html rpt.
#
# Parameters:
#       $1      $outfile
#       $2      $html_file
#       $3      $DEBUG
#       $4      $dash_file
#       $5      $PERF
#       $6      $hostname
#
function gen_html_hdr {

        typeset -r ofile=$1
        typeset -r hfile=$2
        typeset -r debg=$3
        typeset -r dfile=$4
        typeset -r perf=$5
        typeset -r hname=$6

	if [[ $debg -ne 0 ]]
	then
	    echo "gen_html_hdr():$1,$2,$3,$4,$5,$6\n"

	    if [[ $debg -ge 2 ]]
	    then
		set -x
	    fi
	fi

	log_stamp='sys_diag:'`date '+%m%d_%H%M%S'`':'
	echo "$log_stamp ... gen_html_hdr ..."
	label_date=`date '+%m/%d/%y_%H:%M'`

	### Print the HEADER INFO ###

#	echo "<html><head><title>"$hname" (sys_diag v$SYS_DIAG_VER) : System Profile Report</title></head>\n" >> $hfile
	echo "<html><head><title>"$hname" : "$label_date" (sys_diag v$SYS_DIAG_VER) : System Profile Report</title></head>\n" >> $hfile

	echo "<body BGCOLOR="#FFFFFF">" >> $hfile	## Pure White

	echo "<table bgcolor=\"#e6e6e6\" border=\"2\" width=\"100%\"><tbody><tr><td><table bgcolor=\"#594fbf\" border=\"2\" width=\"100%\">" >> $hfile
  	echo "<tbody><tr><td><a name=\"concall\"></a><b><font color=\"#ffffff\"><h2>(sys_diag) : SYSTEM CONFIGURATION / PERFORMANCE PROFILE Report</h2></font></b></td></tr></tbody></table></td></tr><tr><td><hr>" >> $hfile

	echo "<p><b><pre> Hostname        \t:  <font size=\"+1\">"$hname"</font>\c" >> $hfile

	if [[ -x /usr/bin/zonename ]]
	then
		echo "\t\t     Zonename :  "`/usr/bin/zonename` >> $hfile
	else
		echo "\n" >> $hfile
	fi

	echo " uname -a        \t:  "`/usr/bin/uname -a`"\n" >> $hfile

	echo " hostid          \t:  "`/usr/bin/hostid`"\c" >> $hfile

	if [[ -x /usr/bin/isainfo ]]
	then
		echo "\t\t     Kernel   :  "`/usr/bin/isainfo -vk` >> $hfile
	else
		echo "\n" >> $hfile
	fi

	echo " domainname (DNS)\t:  "`/usr/bin/domainname` >> $hfile
	echo " system uptime   \t:  $Up_Time\n" >> $hfile
	echo " sys_diag uid    \t:  sys_diag (v$SYS_DIAG_VER) : "`id` >> $hfile
	echo " sys_diag args   \t:  sys_diag $CMD_LINE\n" >> $hfile

	if [[ -f /etc/ssphostname ]]
	then
		echo " ssphostname\t:  "`cat /etc/ssphostname`"\n" >> $hfile
	fi

	echo "<font size=\"+1\"><i>Report Label   : "`date`" :  $label </i></font>" >> $hfile
	echo "<i>Output File\t\t: $outfile </b></i></pre><hr><hr></td></tr></tbody></table>\n" >> $hfile

}

 
####################  gen_html_rpt  ###########################
#
# Description: 'gen_html_rpt' generates an HTML version of the
#		main sys_diag output file (outfile).
#
# Parameters:
#       $1      $outfile
#       $2      $html_file
#       $3      $DEBUG
#       $4      $dash_file
#       $5      $PERF
#       $6      $POSTPERF
#       $7      $hostname
# 	$8	$sysd_dir
#
function gen_html_rpt {

        typeset -r ofile=$1
        typeset -r hfile=$2
        typeset -r debg=$3
        typeset -r dfile=$4
        typeset -r perf=$5
        typeset -r postperf=$6
        typeset -r hname=$7
        typeset -r sysd=$8

	if [[ $debg -ne 0 ]]
	then
	    echo "gen_html_rpt(): $1\n\t$2\n\t$3\n\t$4\n\t$5\n\t$6\n\t$7\n"

	    if [[ $debg -ge 2 ]]
	    then
		set -x
	    fi
	fi

	log_stamp='sys_diag:'`date '+%m%d_%H%M%S'`':'
	echo "$log_stamp ... gen_html_rpt ..."

####### DASHBOARD Inserted ######

	if [[ ( $postperf -ne 0 ) || ( $perf -ne 0 ) ]]
	then
		cat $dfile >> $hfile
		echo "<hr><hr><br>" >> $hfile
	fi

	echo "<table bgcolor=\"#594fbf\" border=\"0\" width=\"100%\"><tbody><tr>" >> $hfile
	echo "<td>&nbsp;&nbsp; <a name=\"concall\"></a><b><font color=\"#ffffff\" size=\"+2\">TABLE OF CONTENTS :</font></b></td>" >> $hfile
	echo "<td align=\"right\"><a href=\"#top\"><b><font color=\"#ffffff\">Return to Top</font></b></a></td></tr></tbody></table><ul>" >> $hfile

	echo "\n<li><a href=\"#1\" class=\"named\"><b>Section 01>   System Configuration / Device Information</b></a></li>\n" >> $hfile
	echo "<li><a href=\"#2\" class=\"named\"><b>Section 02>   Workload Characterization</b></a></li>\n" >> $hfile
	echo "<li><a href=\"#3\" class=\"named\"><b>Section 03>   Performance Profiling (System / Kernel)</b></a></li>\n" >> $hfile
	echo "<li><a href=\"#4\" class=\"named\"><b>Section 04>   Kernel Zones / Tunables / SRM</b></a></li>\n" >> $hfile
	echo "<li><a href=\"#5\" class=\"named\"><b>Section 05>   Storage Device / Array Enclosure Information</b></a></li>\n" >> $hfile
	echo "<li><a href=\"#6\" class=\"named\"><b>Section 06>   Volume Manager Information</b></a></li>\n" >> $hfile
	echo "<li><a href=\"#7\" class=\"named\"><b>Section 07>   Filesystem Information</b></a></li>\n" >> $hfile
	echo "<li><a href=\"#8\" class=\"named\"><b>Section 08>   I/O Statistics</b></a></li>\n" >> $hfile
	echo "<li><a href=\"#9\" class=\"named\"><b>Section 09>   NFS Information</b></a></li>\n" >> $hfile
	echo "<li><a href=\"#10\" class=\"named\"><b>Section 10>   Networking Information</b></a></li>\n" >> $hfile
	echo "<li><a href=\"#11\" class=\"named\"><b>Section 11>   Tty / Modem Configurations</b></a></li>\n" >> $hfile
	echo "<li><a href=\"#12\" class=\"named\"><b>Section 12>   User / Account / Group Info</b></a></li>\n" >> $hfile
	echo "<li><a href=\"#13\" class=\"named\"><b>Section 13>   Services/ Naming Resolution (NIS/NIS+..)</b></a></li>\n" >> $hfile
	echo "<li><a href=\"#14\" class=\"named\"><b>Section 14>   Security / System Configuration Files</b></a></li>\n" >> $hfile
	echo "<li><a href=\"#15\" class=\"named\"><b>Section 15>   Clustering / HA Information</b></a></li>\n" >> $hfile
	echo "<li><a href=\"#16\" class=\"named\"><b>Section 16>   Sun N1 SP Configuration</b></a></li>\n" >> $hfile
	echo "<li><a href=\"#17\" class=\"named\"><b>Section 17>   Application / Oracle Config Files</b></a></li>\n" >> $hfile
	echo "<li><a href=\"#18\" class=\"named\"><b>Section 18>   Packages Installed</b></a></li>\n" >> $hfile
	echo "<li><a href=\"#19\" class=\"named\"><b>Section 19>   Patch Information</b></a></li>\n" >> $hfile
	echo "<li><a href=\"#20\" class=\"named\"><b>Section 20>   Crontab File Listings</b></a></li>\n" >> $hfile
	echo "<li><a href=\"#21\" class=\"named\"><b>Section 21>   FMD / System Messages / Log Files</b></a></li>\n" >> $hfile

	if [[ $TRACK -ne 0 ]]
	then
		echo "<li><a href=\"#22\" class=\"named\"><b>Section 22>   Asset / Configuration Management -CHANGES-</b></a></li>\n" >> $hfile
	fi

	if [[ ( $postperf -ne 0 ) || ( $perf -ne 0 ) ]]
	then
		echo "<li><a href=\"#23\" class=\"named\"><b>Section 23>   System Analysis : Initial Findings / Errors/Warnings</b></a></li>\n" >> $hfile
		echo "<li><a href=\"#24\" class=\"named\"><b>Section 24>   Performance Analysis : Potential Issues</b></a></li>\n" >> $hfile

		if [[ ( ( $perf -ge 1 ) || ( ( $postperf -ne 0 ) && ( $perf -eq 0 ) ) ) ]]
		then
			echo "<li><a href=\"#25\" class=\"named\"><b>Section 25>   Extended Analysis / Dtrace : Output Files</b></a></li>\n" >> $hfile
		fi
		echo "</ul>" >> $hfile
	else
		echo "</ul><h2> </h2>\n" >> $hfile
	fi

tail +70 $ofile | cut -c1-253 | /usr/bin/awk '{ if (( substr($0,1,3) == "## " ) && ( int(substr($0,4,2)) > 0 ))  { num=int(substr($0,4,2)) ; print "</pre></b><br><hr><br></p><table bgcolor=\"#594fbf\" border=\"0\" width=\"100%\"><tbody><tr><td>&nbsp;&nbsp;<a name=\""num"\" ><font size=+2 color=\"#ffffff\">( ",num," )<u>",substr($0,15,52),"</u></font></a></b></td> <td align=\"right\"><a href=\"#top\"><b><font color=\"#ffffff\">Return to Top</font></b></a></td></tr></tbody></table><p><b><pre>" } else { if ( substr($0,1,5) == "**** " ) { namestr=substr($0,6,9) ; print "</pre></b></p><a name=\""namestr"\" ><font size=+1 color=blue> ",$0,"</font></a><p><b><pre>"  } else { print $0 } } } END { print "</pre></p>" }' >> $hfile

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # ##
# Process and Include the *Dtrace* and Extended Analysis Files (3 columns per row 
#         of each type) listing the 3 snapshots taken for each type of data
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # ##

	echo "<hr>" >> $hfile

	if [[ -r `echo $sysd/sysd_pmap0_*` ]]
	then
	    echo "<hr><br><a name=\"Pmap Snaps\" ><font size=+1 color=blue>  **** Pmap/Pfile Snapshot Files (sysd_pmap) for Top %CPU PIDs **** </font></a>" >> $hfile
	
	    num_files=`ls $sysd/sysd_pmap*.out | wc -l`
	    if [[ $num_files -gt 2 ]]
	    then
		pct_wide=32
	    elif [[ $num_files -gt 1 ]]
	    then
		pct_wide=48
	    else
		pct_wide=96
	    fi

	    echo "<p><b><pre>\c" >> $hfile
	    for i in `ls $sysd/sysd_pmap*.out`
	    do
		fname=${i##*/}
                echo "$fname    \c" >> $hfile
	    done
	    echo "</b></p></pre>" >> $hfile

	    for i in `ls $sysd/sysd_pmap*.out`
	    do
		fname=${i##*/}
		echo "<iframe src=\"$fname\" width=\"$pct_wide%\"></iframe>" >> $hfile
	    done
	fi

	if [[ -r `echo $sysd/sysd_mdb0_*` ]]
	then
	    echo "<hr><br><a name=\"Mdb Snaps\" ><font size=+1 color=blue>  **** Mdb Memory Snapshot Files (sysd_mdb) **** </font></a>" >> $hfile

	    echo "<p><b><pre>\c" >> $hfile
	    for i in `ls $sysd/sysd_mdb*.out`
	    do
		fname=${i##*/}
		echo "$fname    \c" >> $hfile
	    done
	    echo "</b></p></pre>" >> $hfile
	
	    num_files=`ls $sysd/sysd_mdb*.out | wc -l`
	    if [[ $num_files -gt 2 ]]
	    then
		pct_wide=32
	    elif [[ $num_files -gt 1 ]]
	    then
		pct_wide=48
	    else
		pct_wide=96
	    fi

	    for i in `ls $sysd/sysd_mdb*.out`
	    do
		fname=${i##*/}
		echo "<iframe src=\"$fname\" width=\"$pct_wide%\"></iframe>" >> $hfile
	    done
	fi

	if [[ -s `echo $sysd/sysd_cputrk0_*` ]]
	then
	    echo "<hr><br><a name=\"Cputrack S\" ><font size=+1 color=blue>  **** Cputrack Snapshot Files (sysd_cputrk) for Top %CPU PIDs **** </font></a>" >> $hfile

	    echo "<p><b><pre>\c" >> $hfile
	    for i in `ls $sysd/sysd_cputrk*.out`
	    do
		fname=${i##*/}
		echo "$fname    \c" >> $hfile
	    done
	    echo "</b></p></pre>" >> $hfile
	
	    num_files=`ls $sysd/sysd_cputrk*.out | wc -l`
	    if [[ $num_files -gt 2 ]]
	    then
		pct_wide=32
	    elif [[ $num_files -gt 1 ]]
	    then
		pct_wide=48
	    else
		pct_wide=96
	    fi

	    for i in `ls $sysd/sysd_cputrk*.out`
	    do
		fname=${i##*/}
		echo "<iframe src=\"$fname\" width=\"$pct_wide%\"></iframe>" >> $hfile
	    done
	fi

## Dtrace output files ... 

	if [[ -r `echo $sysd/sysd_dpio0_*` ]]
	then
	    echo "<hr><br><a name=\"Dtrace pio\" ><font size=+1 color=blue>  **** Dtrace IO Snapshot Files (sysd_dpio) for Top %CPU PIDs **** </font></a>" >> $hfile

	    echo "<p><b><pre>\c" >> $hfile
	    for i in `ls $sysd/sysd_dpio*.out`
	    do
		fname=${i##*/}
		echo "$fname    \c" >> $hfile
	    done
	    echo "</b></p></pre>" >> $hfile
	
	    num_files=`ls $sysd/sysd_dpio*.out | wc -l`
	    if [[ $num_files -gt 2 ]]
	    then
		pct_wide=32
	    elif [[ $num_files -gt 1 ]]
	    then
		pct_wide=48
	    else
		pct_wide=96
	    fi

	    for i in `ls $sysd/sysd_dpio*.out`
	    do
		fname=${i##*/}
		echo "<iframe src=\"$fname\" width=\"$pct_wide%\"></iframe>" >> $hfile
	    done
	fi


	if [[ -r `echo $sysd/sysd_diow0_*` ]]
	then
	    echo "<hr><br><a name=\"Dtrace iow\" ><font size=+1 color=blue>  **** Dtrace File IO / IO wait Snapshots (sysd_diow) **** </font></a>" >> $hfile

	    echo "<p><b><pre>\c" >> $hfile
	    for i in `ls $sysd/sysd_diow*.out`
	    do
		fname=${i##*/}
		echo "$fname    \c" >> $hfile
	    done
	    echo "</b></p></pre>" >> $hfile
	
	    num_files=`ls $sysd/sysd_diow*.out | wc -l`
	    if [[ $num_files -gt 2 ]]
	    then
		pct_wide=32
	    elif [[ $num_files -gt 1 ]]
	    then
		pct_wide=48
	    else
		pct_wide=96
	    fi

	    for i in `ls $sysd/sysd_diow*.out`
	    do
		fname=${i##*/}
		echo "<iframe src=\"$fname\" width=\"$pct_wide%\"></iframe>" >> $hfile
	    done
	fi


	if [[ -r `echo $sysd/sysd_dR_by_procs0_*` ]]
	then
	    echo "<hr><br><a name=\"Dtrace dtR\" ><font size=+1 color=blue>  **** Dtrace READs (IO & Net) by process : Snapshot Files (sysd_dR) **** </font></a>" >> $hfile

	    echo "<p><b><pre>\c" >> $hfile
	    for i in `ls $sysd/sysd_dR*.out`
	    do
		fname=${i##*/}
		echo "$fname    \c" >> $hfile
	    done
	    echo "</b></p></pre>" >> $hfile
	
	    num_files=`ls $sysd/sysd_dR*.out | wc -l`
	    if [[ $num_files -gt 2 ]]
	    then
		pct_wide=32
	    elif [[ $num_files -gt 1 ]]
	    then
		pct_wide=48
	    else
		pct_wide=96
	    fi

	    for i in `ls $sysd/sysd_dR*.out`
	    do
		fname=${i##*/}
		echo "<iframe src=\"$fname\" width=\"$pct_wide%\"></iframe>" >> $hfile
	    done
	fi


	if [[ -r `echo $sysd/sysd_dW_by_procs0_*` ]]
	then
	    echo "<hr><br><a name=\"Dtrace dtW\" ><font size=+1 color=blue>  **** Dtrace WRITEs (IO & Net) by process : Snapshot Files (sysd_dW) **** </font></a>" >> $hfile

	    echo "<p><b><pre>\c" >> $hfile
	    for i in `ls $sysd/sysd_dW*.out`
	    do
		fname=${i##*/}
		echo "$fname    \c" >> $hfile
	    done
	    echo "</b></p></pre>" >> $hfile
	
	    num_files=`ls $sysd/sysd_dW*.out | wc -l`
	    if [[ $num_files -gt 2 ]]
	    then
		pct_wide=32
	    elif [[ $num_files -gt 1 ]]
	    then
		pct_wide=48
	    else
		pct_wide=96
	    fi

	    for i in `ls $sysd/sysd_dW*.out`
	    do
		fname=${i##*/}
		echo "<iframe src=\"$fname\" width=\"$pct_wide%\"></iframe>" >> $hfile
	    done
	fi


	if [[ -r `echo $sysd/sysd_dtcp_rx0_*` ]]
	then
	    echo "<hr><br><a name=\"Dtrace TcR\" ><font size=+1 color=blue>  **** Dtrace TCP RX Snapshot Files (sysd_dtcp_rx) **** </font></a>" >> $hfile

	    echo "<p><b><pre>\c" >> $hfile
	    for i in `ls $sysd/sysd_dtcp_rx*.out`
	    do
		fname=${i##*/}
		echo "$fname    \c" >> $hfile
	    done
	    echo "</b></p></pre>" >> $hfile
	
	    num_files=`ls $sysd/sysd_dtcp_rx*.out | wc -l`
	    if [[ $num_files -gt 2 ]]
	    then
		pct_wide=32
	    elif [[ $num_files -gt 1 ]]
	    then
		pct_wide=48
	    else
		pct_wide=96
	    fi

	    for i in `ls $sysd/sysd_dtcp_rx*.out`
	    do
		fname=${i##*/}
		echo "<iframe src=\"$fname\" width=\"$pct_wide%\"></iframe>" >> $hfile
	    done
	fi

	if [[ -r `echo $sysd/sysd_dtcp_tx0_*` ]]
	then
	    echo "<hr><br><a name=\"Dtrace TcT\" ><font size=+1 color=blue>  **** Dtrace TCP TX Snapshot Files (sysd_dtcp_tx) **** </font></a>" >> $hfile

	    echo "<p><b><pre>\c" >> $hfile
	    for i in `ls $sysd/sysd_dtcp_tx*.out`
	    do
		fname=${i##*/}
		echo "$fname    \c" >> $hfile
	    done
	    echo "</b></p></pre>" >> $hfile
	
	    num_files=`ls $sysd/sysd_dtcp_tx*.out | wc -l`
	    if [[ $num_files -gt 2 ]]
	    then
		pct_wide=32
	    elif [[ $num_files -gt 1 ]]
	    then
		pct_wide=48
	    else
		pct_wide=96
	    fi

	    for i in `ls $sysd/sysd_dtcp_tx*.out`
	    do
		fname=${i##*/}
		echo "<iframe src=\"$fname\" width=\"$pct_wide%\"></iframe>" >> $hfile
	    done
	fi


	if [[ -r `echo $sysd/sysd_dsinfo_by_procs0_*` ]]
	then
	    echo "<hr><br><a name=\"Dtrace sin\" ><font size=+1 color=blue>  **** Dtrace Sinfo Snapshot Files (sysd_dsinfo_by_procs) **** </font></a>" >> $hfile

	    echo "<p><b><pre>\c" >> $hfile
	    for i in `ls $sysd/sysd_dsinfo_by_procs*.out`
	    do
		fname=${i##*/}
		echo "$fname    \c" >> $hfile
	    done
	    echo "</b></p></pre>" >> $hfile
	
	    num_files=`ls $sysd/sysd_dsinfo_by_procs*.out | wc -l`
	    if [[ $num_files -gt 2 ]]
	    then
		pct_wide=32
	    elif [[ $num_files -gt 1 ]]
	    then
		pct_wide=48
	    else
		pct_wide=96
	    fi

	    for i in `ls $sysd/sysd_dsinfo_by_procs*.out`
	    do
		fname=${i##*/}
		echo "<iframe src=\"$fname\" width=\"$pct_wide%\"></iframe>" >> $hfile
	    done
	fi


	if [[ -r `echo $sysd/sysd_dcalls_by_procs0_*` ]]
	then
	    echo "<hr><br><a name=\"Dtrace cal\" ><font size=+1 color=blue>  **** Dtrace calls_by_process Snapshots (sysd_dcalls_by_procs) **** </font></a>" >> $hfile

	    echo "<p><b><pre>\c" >> $hfile
	    for i in `ls $sysd/sysd_dcalls_by_procs*.out`
	    do
		fname=${i##*/}
		echo "$fname    \c" >> $hfile
	    done
	    echo "</b></p></pre>" >> $hfile
	
	    num_files=`ls $sysd/sysd_dcalls_by_procs*.out | wc -l`
	    if [[ $num_files -gt 2 ]]
	    then
		pct_wide=32
	    elif [[ $num_files -gt 1 ]]
	    then
		pct_wide=48
	    else
		pct_wide=96
	    fi

	    for i in `ls $sysd/sysd_dcalls_by_procs*.out`
	    do
		fname=${i##*/}
		echo "<iframe src=\"$fname\" width=\"$pct_wide%\"></iframe>" >> $hfile
	    done
	fi


	if [[ -r `echo $sysd/sysd_dsyscall_counts0_*` ]]
	then
	    echo "<hr><br><a name=\"Dtrace Sys\" ><font size=+1 color=blue>  **** Dtrace System Call Snapshot Files (sysd_dsyscall) **** </font></a>" >> $hfile

	    echo "<p><b><pre>\c" >> $hfile
	    for i in `ls $sysd/sysd_dsyscall_counts*.out`
	    do
		fname=${i##*/}
		echo "$fname    \c" >> $hfile
	    done
	    echo "</b></p></pre>" >> $hfile
	
	    num_files=`ls $sysd/sysd_dsyscall_counts*.out | wc -l`
	    if [[ $num_files -gt 2 ]]
	    then
		pct_wide=32
	    elif [[ $num_files -gt 1 ]]
	    then
		pct_wide=48
	    else
		pct_wide=96
	    fi

	    for i in `ls $sysd/sysd_dsyscall_counts*.out`
	    do
		fname=${i##*/}
		echo "<iframe src=\"$fname\" width=\"$pct_wide%\"></iframe>" >> $hfile
	    done
	fi


	if [[ ( -r `echo $sysd/sysd_dmpc0_*` ) || ( -r `echo $sysd/sysd_dmpc1_*` ) || ( -r `echo $sysd/sysd_dmpc2_*` ) ]]
	then
	    echo "<hr><br><a name=\"Dtrace mpc\" ><font size=+1 color=blue>  **** Dtrace High ICSW/SMTX/XCAL Snapshot Files (sysd_dmpc) **** </font></a>" >> $hfile

	    echo "<p><b><pre>\c" >> $hfile
	    for i in `ls $sysd/sysd_dmpc*.out`
	    do
		fname=${i##*/}
		echo "$fname    \c" >> $hfile
	    done
	    echo "</b></p></pre>" >> $hfile
	
	    num_files=`ls $sysd/sysd_dmpc*.out | wc -l`
	    if [[ $num_files -gt 2 ]]
	    then
		pct_wide=32
	    elif [[ $num_files -gt 1 ]]
	    then
		pct_wide=48
	    else
		pct_wide=96
	    fi

	    for i in `ls $sysd/sysd_dmpc*.out`
	    do
		fname=${i##*/}
		echo "<iframe src=\"$fname\" width=\"$pct_wide%\"></iframe>" >> $hfile
	    done
#	else
#		echo "<pre><b>\n\tNOTE: AVG ICSW (Involuntary Context Switching) was < High_Threshold. Data was NOT captured.\n</b></pre>" >> $hfile
	fi


	if [[ -r `echo $sysd/sysd_dsdtcnt0_*` ]]
	then
	    echo "<hr><br><a name=\"Dtrace Sdt\" ><font size=+1 color=blue>  **** Dtrace Sdt_count Snapshot Files (sysd_dstdcnt) **** </font></a>" >> $hfile

	    echo "<p><b><pre>\c" >> $hfile
	    for i in `ls $sysd/sysd_dsdtcnt*.out`
	    do
		fname=${i##*/}
		echo "$fname    \c" >> $hfile
	    done
	    echo "</b></p></pre>" >> $hfile
	
	    num_files=`ls $sysd/sysd_dsdtcnt*.out | wc -l`
	    if [[ $num_files -gt 2 ]]
	    then
		pct_wide=32
	    elif [[ $num_files -gt 1 ]]
	    then
		pct_wide=48
	    else
		pct_wide=96
	    fi

	    for i in `ls $sysd/sysd_dsdtcnt*.out`
	    do
		fname=${i##*/}
		echo "<iframe src=\"$fname\" width=\"$pct_wide%\"></iframe>" >> $hfile
	    done
	fi


	if [[ -r `echo $sysd/sysd_dintrtm0_*` ]]
	then
	    echo "<hr><br><a name=\"Dtrace Int\" ><font size=+1 color=blue>  **** Dtrace Interrupt Time Snapshot Files (sysd_dintrtm) **** </font></a>" >> $hfile

	    echo "<p><b><pre>\c" >> $hfile
	    for i in `ls $sysd/sysd_dintrtm*.out`
	    do
		fname=${i##*/}
		echo "$fname    \c" >> $hfile
	    done
	    echo "</b></p></pre>" >> $hfile
	
	    num_files=`ls $sysd/sysd_dintrtm*.out | wc -l`
	    if [[ $num_files -gt 2 ]]
	    then
		pct_wide=32
	    elif [[ $num_files -gt 1 ]]
	    then
		pct_wide=48
	    else
		pct_wide=96
	    fi

	    for i in `ls $sysd/sysd_dintrtm*.out`
	    do
		fname=${i##*/}
		echo "<iframe src=\"$fname\" width=\"$pct_wide%\"></iframe>" >> $hfile
	    done
	fi

##
## TBD _lA _lP _ls _lI  (lockstat files)
##

	if [[ -r `echo $sysd/sysd_lP0_*` ]]
	then
	    echo "<hr><br><a name=\"Lockstat P\" ><font size=+1 color=blue>  **** Lockstat -P Snapshot Files (sysd_lP) **** </font></a>" >> $hfile

	    echo "<p><b><pre>\c" >> $hfile
	    for i in `ls $sysd/sysd_lP*.out`
	    do
		fname=${i##*/}
		echo "$fname    \c" >> $hfile
	    done
	    echo "</b></p></pre>" >> $hfile
	
	    num_files=`ls $sysd/sysd_lP*.out | wc -l`
	    if [[ $num_files -gt 2 ]]
	    then
		pct_wide=32
	    elif [[ $num_files -gt 1 ]]
	    then
		pct_wide=48
	    else
		pct_wide=96
	    fi

	    for i in `ls $sysd/sysd_lP*.out`
	    do
		fname=${i##*/}
		echo "<iframe src=\"$fname\" width=\"$pct_wide%\"></iframe>" >> $hfile
	    done
	fi


	if [[ -r `echo $sysd/sysd_lA0_*` ]]
	then
	    echo "<hr><br><a name=\"Lockstat A\" ><font size=+1 color=blue>  **** Lockstat -A Snapshot Files (sysd_lA) **** </font></a>" >> $hfile

	    echo "<p><b><pre>\c" >> $hfile
	    for i in `ls $sysd/sysd_lA*.out`
	    do
		fname=${i##*/}
		echo "$fname    \c" >> $hfile
	    done
	    echo "</b></p></pre>" >> $hfile
	
	    num_files=`ls $sysd/sysd_lA*.out | wc -l`
	    if [[ $num_files -gt 2 ]]
	    then
		pct_wide=32
	    elif [[ $num_files -gt 1 ]]
	    then
		pct_wide=48
	    else
		pct_wide=96
	    fi

	    for i in `ls $sysd/sysd_lA*.out`
	    do
		fname=${i##*/}
		echo "<iframe src=\"$fname\" width=\"$pct_wide%\"></iframe>" >> $hfile
	    done
	fi


	if [[ -r `echo $sysd/sysd_ls0_*` ]]
	then
	    echo "<hr><br><a name=\"Lockstat s\" ><font size=+1 color=blue>  **** Lockstat -A -s Snapshot Files (sysd_ls) **** </font></a>" >> $hfile

	    echo "<p><b><pre>\c" >> $hfile
	    for i in `ls $sysd/sysd_ls*.out`
	    do
		fname=${i##*/}
		echo "$fname    \c" >> $hfile
	    done
	    echo "</b></p></pre>" >> $hfile
	
	    num_files=`ls $sysd/sysd_ls*.out | wc -l`
	    if [[ $num_files -gt 2 ]]
	    then
		pct_wide=32
	    elif [[ $num_files -gt 1 ]]
	    then
		pct_wide=48
	    else
		pct_wide=96
	    fi

	    for i in `ls $sysd/sysd_ls*.out`
	    do
		fname=${i##*/}
		echo "<iframe src=\"$fname\" width=\"$pct_wide%\"></iframe>" >> $hfile
	    done
	fi


	if [[ -r `echo $sysd/sysd_lI0_*` ]]
	then
	    echo "<hr><br><a name=\"Lockstat A\" ><font size=+1 color=blue>  **** Lockstat -I Snapshot Files (sysd_lI) **** </font></a>" >> $hfile

	    echo "<p><b><pre>\c" >> $hfile
	    for i in `ls $sysd/sysd_lI*.out`
	    do
		fname=${i##*/}
		echo "$fname    \c" >> $hfile
	    done
	    echo "</b></p></pre>" >> $hfile
	
	    num_files=`ls $sysd/sysd_lI*.out | wc -l`
	    if [[ $num_files -gt 2 ]]
	    then
		pct_wide=32
	    elif [[ $num_files -gt 1 ]]
	    then
		pct_wide=48
	    else
		pct_wide=96
	    fi

	    for i in `ls $sysd/sysd_lI*.out`
	    do
		fname=${i##*/}
		echo "<iframe src=\"$fname\" width=\"$pct_wide%\"></iframe>" >> $hfile
	    done
	fi

###
	ifcfg_file=$sysd'/sysd_ifcfg_*.out'

	num_nets=0

	for j in `cat $ifcfg_file |  grep ": " | cut -d" " -f1`
	do
	    i=`echo $j | cut -d":" -f1`		# i = physical nic .. eg.. hme0

	    if [[ $i != $last_nic ]]
	    then
		netbfile=`echo $sysd'/sysd_knetb_'$i'_'*'.out'`
		netefile=`echo $sysd'/sysd_knete_'$i'_'*'.out'`

		if [[ ( -r `ls $netbfile` ) && ( -r `ls $netefile` ) ]]
		then
	    		echo "<hr><br><a name=\"Knet $num_nets\" ><font size=+1 color=blue>  **** Kstat NIC $i Snapshot Files (sysd_knetb/e_) **** </font></a>" >> $hfile

	    		echo "<p><b><pre>\c" >> $hfile
			netb=${netbfile##*/}
			nete=${netefile##*/}
			echo "$netb                   $nete" >> $hfile
	    		echo "</b></p></pre>" >> $hfile

			echo "<iframe src=\"$netb\" width=\"48%\"></iframe>" >> $hfile
			echo "<iframe src=\"$nete\" width=\"48%\"></iframe>" >> $hfile
		fi
	    
		last_nic=$i
	    fi

   	    num_nets=$(($num_nets+1))

	done
	echo "</body></html>" >> $hfile
}


####################  check_config  ###########################
#
# Description: 'check_config' compares new system configuration
#		details (command output and files) with previous
#		snapshots.  Discrepancies are flagged and logged.
#
# Parameters:
#       $1      last_file
#       $2      new_file
#       $3      log_file
#       $4      out_file
# xxxx  $5      first_page	## Not used
#       $5      DEBUG
#
function check_config {

        typeset -r last_file=$1
        typeset -r new_file=$2
        typeset -r log_file=$3
        typeset -r out_file=$4
#        typeset -r first_page=$5
        typeset -r debg=$5
#
# TJ 06/08/2007	  Fixed to only save files that have changed, else remove them
#
	if [[ $debg -ne 0 ]]
	then
	    echo "check_config(): $1,$2,$3,$4,$5\n"

	    if [[ $debg -ge 2 ]]
	    then
		set -x
	    fi
	fi

	if [[ ( ( -f `echo $last_file` ) && ( -f `echo $new_file` ) ) ]]
	then
		tmp_fname=$new_file
		tmp_fname=${new_file##*F_}

		if [[ $tmp_fname != $new_file ]]
		then
			isafile=1
		else
			tmp_fname=${new_file##*_}
			isafile=0
		fi

		if [[ $isafile -ne 0 ]]
		then
			echo "$log_stamp CONFIG CHK: COMPARING FILE: ${tmp_fname%%.cfg} \c"
		else
			echo "$log_stamp CONFIG CHK: COMPARING ${tmp_fname%%.cfg} \c"
		fi

		sum1=`sum $last_file | cut -d" " -f1`
		sum2=`sum $new_file | cut -d" " -f1`

		if [[ $sum1 -ne $sum2 ]]
		then
#			if [[ $first_page -eq 0 ]]
#			then
#				echo "" >> $out_file
#				echo "\n"
#				first_page=0
#			fi

			echo "\n\n\t************ ${tmp_fname%%.cfg} DIFFERENCES FOUND *************\n" >> $out_file
			echo " : ** DIFFERENCES FOUND **"
			echo "\n___________________________________________________________________________________\n" >> $out_file
			date >> $log_file
			echo "\n___________________________________________________________________________________\n" >> $log_file
			echo "\n# diff -c $last_file $new_file\n\n" | tee -a $log_file $out_file 1>/dev/null
			diff -c $last_file $new_file | tee -a $log_file $out_file 1>/dev/null
			echo "\n___________________________________________________________________________________\n" >> $out_file
			echo "\n___________________________________________________________________________________\n" >> $log_file
			cp $new_file $last_file
		else
			rm -f $new_file
			echo " "
		fi
	else				### If no "last" file exists, copy
		if [[ -f `echo $new_file` ]]
		then
			cp $new_file $last_file
		fi
	fi
}


####################  post_perf  #############################
#
# Description: 'post_perf' POST-Processes the Performance data
#		and completes the Performance Analysis and .html
#		file generation if the (-S) Skip PostProcessing
#		parameter was formerly used and now run with -P
#		to complete the report generation on the existing
#		datafiles (either in the current directory OR
#		specified from -d Data_DIRECTORY.
#
# Parameters:
#       $1      $sysd_dir
#       $2      $outfile
#       $3      $DEBUG
#       $4      $PERF
#       $5      $dash_file
#       $6      $home_dir
#
function post_perf {

        typeset -r sysd_dir=$1
        typeset -r outfile=$2
        typeset -r debg=$3
        typeset -r perf=$4
        typeset -r dash_file=$5
        typeset -r homedir=$6


# SCAN the Performance data files gathered for any possible issues

	vmstat_file=`echo $sysd_dir'/sysd_vm_'*'.out'`
	vm_file=${vmstat_file##$sysd_dir/}
	mpstat_file=$sysd_dir'/sysd_mp_*.out'
	iostat_file=$sysd_dir'/sysd_io_*.out'
	dirname=${sysd_dir##*/}
	host_name=`echo $dirname | cut -d"_" -f2`

	log_stamp='sys_diag:'`date '+%m%d_%H%M%S'`':'

	vmstat_graph_file=$sysd_dir'/'$vm_file'.gr.txt'
	ps_lwp_file=$sysd_dir'/sysd_lwp_*.out'
	lockstat_file=$sysd_dir'/sysd_lP0_*.out'
	swap_l_file=$sysd_dir'/sysd_swapl_*.out'
	scratchfile=$sysd_dir'/scratch_file'
	sysd_perflog=$homedir'/sys_diag_perflog.out'

	if [[ $debg -ne 0 ]]
	then
	    echo "post_perf(): sys_dir=$1\n\toutfile=$2\n\tdebg=$3\t\tperf=$4\n\tdash_file=$5\n\thomedir=$homedir\n\thost_name=$host_name\n\t$dirname\n\tvmstat_graph_file=$vmstat_graph_file\n\tswap_l_file=$swap_l_file\n\tsysd_perflog=$sysd_perflog\n\t"

	    if [[ $debg -ge 2 ]]
	    then
		set -x
	    fi
	fi

	num=0

	echo "" >> $outfile
	echo "\n$log_stamp ######  PERFORMANCE DATA : POTENTIAL ISSUES  ######"
	echo "\n_____________________________________________________________________________________\n"
	echo "## 24 #############  PERFORMANCE DATA : POTENTIAL ISSUES  ################\n\n" >> $outfile

	vmex_file=$sysd_dir'/sysd_vmx_'$host_name'_'`date '+%y%m%d_%H%M'`'.out'
	vmavg_file=$sysd_dir'/sysd_vmavg_'$host_name'_'`date '+%y%m%d_%H%M'`'.out'
##
	total_swap_k=0

	if [[ -f `echo $swap_l_file` ]]
	then
	     for s in `tail +2 $swap_l_file | /usr/bin/awk '{ print $4 }'`
	     do
		s=$(($s/2))
		total_swap_k=$(($total_swap_k+$s))
	     done

	     double_tswap=$(($total_swap_k*2))
	else
	     double_tswap=999999999	## else, if no swap -l output file, default to a big num
	fi

	total_ram_k=0

	if [[ -f $scratchfile ]]
	then
	    total_ram_k=$((`head -1 $scratchfile | /usr/bin/awk '{ print $3 }'`*1000))

	    tlb_miss=`tail -1 $scratchfile | grep NOTE`
	    tlb_spt=`echo $tlb_miss | wc -m`

	    dnlc_cache=`grep cache $scratchfile`
	else
	    total_ram_k=$((`/usr/sbin/prtconf | grep Memory | /usr/bin/awk '{ printf "%s", $3 }'`*1000))
	    dnlc_cache=`vmstat -s | grep cache | cut -d"(" -f2 | cut -d")" -f1`
	fi

	echo "\n$log_stamp ## Analyzing VMSTAT CPU Datafile :\n\t$vmstat_file ..."
	echo "\n___________________________________________________________________________________\n" >> $sysd_perflog
	banner `date '+%m%d_%H%M'` >> $sysd_perflog
	echo "\n___________________________________________________________________________________\n" >> $sysd_perflog
	echo "\n$log_stamp ## Analyzing VMSTAT CPU Datafile :\n\t$vmstat_file ..." >> $sysd_perflog

	echo "**** CPU (VMSTAT) Findings / Exceptions ****\nfor file:    $vmstat_file" >> $outfile
	echo "\n\t[entries where (RunQ > $VMSTAT_RUNQ_GT) or (Kthr_Blocked > $VMSTAT_BLKD_GT) or (Kthr_Wait > $VMSTAT_WAIT_GT)\n\t\tor (cpu_idle < $VMSTAT_PCTIDLE_LT) or ((%Sys > %Usr) and (cpu_idle < 15))]\n" >> $outfile


##? state || procs || device (ignore state change msgs / headers..though this is in -q for S10) 

	tail +4 $vmstat_file | grep -v "swap" | grep -v "kthr" | grep -v "State" | grep -v "procs" | /usr/bin/awk '{ if (( $1 > int(r) ) || ( $2 > int(x) ) || ( $3 > int(w) ) || (( $21 > $20 ) && ( $22 < int(15) )) || ( $22 < int(z) )) { num++; printf "%s\t\t%d\n", $0, num; } { num_lines++ } } END { print "NOTE:", (num/num_lines)*100 , "%", ":", num, "of",NR }' num=0 r=$VMSTAT_RUNQ_GT w=$VMSTAT_WAIT_GT x=$VMSTAT_BLKD_GT z=$VMSTAT_PCTIDLE_LT | sort -r -k 21,21 -k 22,22 > $vmex_file

#	tail +4 $vmstat_file | grep -v "swap" | grep -v "kthr" | grep -v "State" | grep -v "procs" | /usr/bin/awk '{ if (( $1 > int(r) ) || ( $2 > int(x) ) || ( $3 > int(w) ) || (( $21 > $20 ) && ( $22 < int(15) )) || ( $22 < int(z) )) { print $0 ; num++ } { num_lines++ } } END { print "NOTE:", (num/num_lines)*100 , "%", ":", num, "of",NR }' num=0 r=$VMSTAT_RUNQ_GT w=$VMSTAT_WAIT_GT x=$VMSTAT_BLKD_GT z=$VMSTAT_PCTIDLE_LT | sort -k 22,22 -k 20,20 > $vmex_file

##	tail +4 $vmstat_file | /usr/bin/awk '{ if (( $1 != "procs" ) && ( $1 != "r" ) && ( $1 != "\<\<State" ) && ( $1 != "kthr" )) { rqueue+=$1 ; bthrds+=$2 ; vmem+=$4 ; free+=$5 ; sr+=$12 ; user+=$20 ; sys+=$21 ; idle+=$22 ; num++ } { num_lines++ } } END { printf "TOTAL CPU AVGS :   RUNQ=%5.1f : BThr=%5.1f :   USR=%5.1f :  SYS=%5.1f :  IDLE=%5.1f\n",(rqueue/num),(bthrds/num),(user/num),(sys/num),(idle/num); print "\n"; printf "TOTAL MEM AVGS :   SR=%5.1f  :   SWAP_vm=%11.1f K  :  FREE_mem=%11.1f K\n",(sr/num),(vmem/num),(free/num) }' num=0 > $vmavg_file

	tail +4 $vmstat_file | /usr/bin/awk '{ if (( $1 != "procs" ) && ( $1 != "r" ) && ( $1 != "\<\<State" ) && ( $1 != "kthr" )) { if ( $1 > Prqueue ) { Prqueue=$1 }; if ( $2 > Pbthrds ) { Pbthrds=$2 }; if ( $4 < int(Pvmem) ) { Pvmem=$4 }; if ( $5 < int(Pfree) ) { Pfree=$5 }; if ( $12 > Psr ) { Psr=$12 }; if ( $20 > Puser ) { Puser=$20 }; if ( $21 > Psys ) { Psys=$21 }; if ( $22 < int(Pidle) ) { Pidle=$22 }; rqueue+=$1; bthrds+=$2; vmem+=$4 ; free+=$5 ; sr+=$12 ; user+=$20 ; sys+=$21 ; idle+=$22 ; num++ } { num_lines++ } } END { printf "TOTAL CPU AVGS :   RUNQ=%5.1f : BThr=%5.1f :   USR=%5.1f :  SYS=%5.1f :  IDLE=%5.1f\n",(rqueue/num),(bthrds/num),(user/num),(sys/num),(idle/num); printf " PEAK CPU HWMs :   RUNQ=%5d : BThr=%5d :   USR=%5d :  SYS=%5d :  IDLE=%5d",Prqueue,Pbthrds,Puser,Psys,Pidle; print "\n"; printf "TOTAL MEM AVGS :   SR=%5.1f  :   SWAP_free=%11.1f K  :  FREE_RAM=%11.1f K\n",(sr/num),(vmem/num),(free/num); printf " PEAK MEM Usage:   SR=%5d  :   SWAP_free=%11.1f K  :  FREE_RAM=%11.1f K\n",Psr,Pvmem,Pfree }' num=0 Pidle=100 Pvmem=$double_tswap Pfree=$total_ram_k >> $vmavg_file

	echo "\n`head -2 $vmavg_file`" >> $outfile

	echo "\n   * `grep "NOTE" $vmex_file` VMSTAT CPU entries are WARNINGS!! *\n"
	echo "\n   * `grep "NOTE" $vmex_file` VMSTAT CPU entries are WARNINGS!! *\n" >> $outfile
	echo "\n   * `grep "NOTE" $vmex_file` VMSTAT CPU entries are WARNINGS!! *\n" >> $sysd_perflog

	head -2 $vmavg_file
	head -2 $vmavg_file >> $sysd_perflog

	num_defunct=`grep defunct $sysd_dir/sysd_PSc* | grep -v grep | wc -l`

	if [[ $num_defunct -gt 1 ]]
	then
		echo "\n\tNOTE: ** $num_defunct DEFUNCT processes exist **" 
		echo "\n\tNOTE: ** $num_defunct DEFUNCT processes exist **\n" >> $outfile
	fi

#	vm_pct=`grep "NOTE" $vmex_file | cut -d" " -f2`
	vm_pct=`grep "NOTE" $vmex_file | /usr/bin/awk '{ printf "%5.1f", $2 }'`

	if [[ $vm_pct -gt 0 ]]
	then
		echo " VMSTAT (top) WARNINGs are sorted by %SYS && %USR cpu (each line ends with interval #)\n" >> $outfile
		echo "`/usr/bin/vmstat | head -2`" >> $outfile
		head -100 $vmex_file | grep -v "NOTE:" >> $outfile
	fi

	echo "Rq B Vmem Ram SR Intr SCall CSw Usr Sys Idle" > $vmstat_graph_file

	tail +4 $vmstat_file | /usr/bin/awk '{ if (( $1 != "procs" ) && ( $1 != "r" ) && ( $1 != "\<\<State" ) && ( $1 != "kthr" )) { print $1,$2,$4,$5,$12,$17,$18,$19,$20,$21,$22  } { num_lines++ } } END { num=0 } '  >> $vmstat_graph_file


####### (Check Free MEMORY and Available SWAP and Scan Rate Thresholds)

	echo "\n_____________________________________________________________________________________\n" >> $outfile
	echo "\n_____________________________________________________________________________________\n"
	echo "\n_____________________________________________________________________________________\n" >> $sysd_perflog

	memex_file=$sysd_dir'/sysd_memx_'$host_name'_'`date '+%y%m%d_%H%M'`'.out'

	echo "\n$log_stamp ## Analyzing VMSTAT MEMORY from Datafile :\n\t$vmstat_file ..."
	echo "\n**** MEMORY (VMSTAT) Findings ****\nfor file:    $vmstat_file" >> $outfile

	min_swap_k=`echo "$total_swap_k $SWAP_PCT_MIN" | /usr/bin/awk '{ swap_pct=int(s)/100; min_swap=int(t)*swap_pct; printf "%d", min_swap }' s=$SWAP_PCT_MIN t=$total_swap_k`

	min_ram_k=`echo "$total_ram_k $MEM_PCT_MIN" | /usr/bin/awk '{ mem_pct=int(m)/100; min_ram=int(t)*mem_pct; printf "%d", min_ram }' m=$MEM_PCT_MIN t=$total_ram_k`

	tail +4 $vmstat_file | grep -v "swap" | grep -v "kthr" | grep -v "State" | grep -v "procs" | /usr/bin/awk '{ free_swap=$4; if (( $12 > int(s) ) || ( free_swap < int(v) ) || ( $5 < int(m) )) { num++; printf "%s\t\t%d\n", $0, num; } { num_lines++ } } END { print "NOTE:", (num/num_lines)*100 , "%", ":", num, "of",NR }' num=0 v=$min_swap_k m=$min_ram_k s=$VMSTAT_SCANRT_GT | sort -k 5,5 > $memex_file

	mem_pct=`grep "NOTE" $memex_file | /usr/bin/awk '{ printf "%5.1f", $2 }'`

	echo "\n  [entries where (scan_rate (sr) > $VMSTAT_SCANRT_GT) or ( free_swap (swap) < $min_swap_k K [ < $SWAP_PCT_MIN % total_swap ($total_swap_k K) ] )\n\t\tor (free_mem < $min_ram_k K) [ < $MEM_PCT_MIN % total_ram ($total_ram_k K) ]\n" >> $outfile

	echo "\n`tail -2 $vmavg_file`" >> $outfile

	echo "\n   * `grep "NOTE" $memex_file` VMSTAT MEMORY entries are WARNINGS!! *\n" 
	echo "\n   * `grep "NOTE" $memex_file` VMSTAT MEMORY entries are WARNINGS!! *\n" >> $sysd_perflog
	echo "\n   * `grep "NOTE" $memex_file` VMSTAT MEMORY entries are WARNINGS!! *\n" >> $outfile

	tail -2 $vmavg_file
	tail -2 $vmavg_file >> $sysd_perflog

	if [[ $mem_pct -gt 0 ]]
	then
		echo "\n   VMSTAT (top 100) exceptions with least Memory Available (each line ends with interval #)\n" >> $outfile
		echo "`/usr/bin/vmstat | head -2`\n" >> $outfile
		head -100 $memex_file | grep -v "NOTE:" >> $outfile
	fi

#	echo "\n_____________________________________________________________________________________\n" >> $outfile
#
#	echo "\n\n**** LWP Procs listing from file: $ps_lwp_file ****" >> $outfile
#	echo "   PS (top 100) listing sorted by highest # LWPs\n" >> $outfile
#	head -100 $ps_lwp_file >> $outfile

	echo "\n_____________________________________________________________________________________\n" >> $outfile

	echo "\n_____________________________________________________________________________________\n"
	echo "\n_____________________________________________________________________________________\n" >> $sysd_perflog

	mpex_file=$sysd_dir'/sysd_mpx_'$host_name'_'`date '+%y%m%d_%H%M'`'.out'

	echo "\n$log_stamp ## Analyzing MPSTAT Datafile :\n\t$mpstat_file ..."
	echo "\n\n**** CPU (MPSTAT) Findings / Exceptions ****\nfor file:    $mpstat_file" >> $outfile
	echo "\n\t[entries where Cpu ( ((icsw > $MPSTAT_ICSW_GT) || (smtx > $MPSTAT_SMTX_GT)) && (%Sys > $MPSTAT_SYS_GT)) or\n\t\t ((icsw > $MPSTAT_ICSW_IGT) && (%Idle < $MPSTAT_PCTIDLE_ILT)) or (%Wait > $MPSTAT_PCTWT_GT) or (%Idle < $MPSTAT_PCTIDLE_LT)]" >> $outfile

	grep -v "CPU" $mpstat_file | grep -v "State" | /usr/bin/awk '{ if ( ((( $8 > int(w) ) || ( $10 > int(x) )) && ( $14 > int(v) )) || (( $8 > int(a) ) && ( $16 < int(b) )) || ( $15 > int(y) ) || ( $16 < int(z) )) { num++; printf "%s\t\t%d\n", $0, num; } { num_lines++ } } END { print "NOTE:", (num/NR)*100 , "%", ":", num, "of", NR }' num=0 v=$MPSTAT_SYS_GT w=$MPSTAT_ICSW_GT x=$MPSTAT_SMTX_GT y=$MPSTAT_PCTWT_GT z=$MPSTAT_PCTIDLE_LT a=$MPSTAT_ICSW_IGT b=$MPSTAT_PCTIDLE_ILT | sort -r -k 14,14 -k 9,9 > $mpex_file

#	mp_avgs=`grep -v "CPU" $mpstat_file | grep -v "State" | /usr/bin/awk '{ if ( $1 != "procs" ) { w+=$15 ; xcal+=$4 ; csw+=$7 ; icsw+=$8 ; migr+=$9 ; smtx+=$10 ; syscl+=$12 ; num++ } { num_lines++ } } END { printf "CPU MP AVGS :  Wt=%d : Xcal=%d : csw=%d : icsw=%d : migr=%d : smtx=%d : syscl=%d",(w/num),(xcal/num),(csw/num),(icsw/num),(migr/num),(smtx/num),(syscl/num) }' num=0`

	grep -v "CPU" $mpstat_file | grep -v "State" | /usr/bin/awk '{ if ( $1 != "procs" ) { if ( $15 > int(Pw) ) { Pw=$15 }; if ( $4 > int(Pxcal) ) { Pxcal=$4 }; if ( $7 > int(Pcsw) ) { Pcsw=$7 }; if ( $8 > int(Picsw) ) { Picsw=$8 }; if ( $9 > int(Pmigr) ) { Pmigr=$9 }; if ( $10 > int(Psmtx) ) { Psmtx=$10 }; if ( $12 > int(Psyscl) ) { Psyscl=$12 }; w+=$15 ; xcal+=$4 ; csw+=$7 ; icsw+=$8 ; migr+=$9 ; smtx+=$10 ; syscl+=$12 ; num++ } { num_lines++ } } END { printf "  CPU MP AVGS:  Wt=%2d: Xcal=%6d: csw=%6d: icsw=%6d: migr=%6d: smtx=%6d: syscl=%8d",(w/num),(xcal/num),(csw/num),(icsw/num),(migr/num),(smtx/num),(syscl/num); printf "\n PEAK MP HWMs:  Wt=%2d: Xcal=%6d: csw=%6d: icsw=%6d: migr=%6d: smtx=%6d: syscl=%8d",Pw,Pxcal,Pcsw,Picsw,Pmigr,Psmtx,Psyscl }' num=0 >> $scratchfile

	echo "\n" >> $outfile
	tail -2 $scratchfile >> $outfile
	mp_pct=`grep "NOTE" $mpex_file | /usr/bin/awk '{ printf "%5.1f", $2 }'`

	echo "\n   * `grep "NOTE" $mpex_file` MPSTAT CPU entries are WARNINGS!! *" 
	echo "\n   * `grep "NOTE" $mpex_file` MPSTAT CPU entries are WARNINGS!! *\n" >> $sysd_perflog
	echo "\n\n   * `grep "NOTE" $mpex_file` MPSTAT CPU entries are WARNINGS!! *\n" >> $outfile
	tail -2 $scratchfile >> $sysd_perflog
	echo "\n"
	tail -2 $scratchfile

	if [[ $tlb_spt -gt 1 ]]		## if the scratch file has an entry for TLB_Miss %g's
	then
		echo "\n\n  $tlb_miss\n" >> $outfile
		echo "\n\n  $tlb_miss\n" >> $sysd_perflog
		echo "\n\n  $tlb_miss\n"
	fi

	if [[ $mp_pct -gt 0 ]]
	then
		echo "   MPSTAT (top 100) WARNINGs are sorted by highest %Sys (each line ends with record #)\n" >> $outfile
		echo "`/usr/bin/mpstat | head -1`\n" >> $outfile
		head -100 $mpex_file | grep -v "NOTE:" >> $outfile
	fi

	echo "\n_____________________________________________________________________________________\n" >> $outfile
	echo "\n_____________________________________________________________________________________\n"
	echo "\n_____________________________________________________________________________________\n" >> $sysd_perflog


	echo "\n\n**** LOCKSTAT_listing from file: $lockstat_file ****" >> $outfile

	echo "$log_stamp # /usr/sbin/lockstat -A -P..." >> $outfile

	cat $lockstat_file >> $outfile

	echo "\n\n   NOTE: Review these LOCKSTAT rpts (among others) for locking/mtx correlation.\n" >> $outfile
	loutfile=$sysd_dir'/lockstat_files.out'
	cat $loutfile >> $outfile

##### IOSTAT Data Analysis ########

	echo "\n_____________________________________________________________________________________\n" >> $outfile
	io_pct=0

	ioex_file=$sysd_dir'/sysd_iox_'$host_name'_'`date '+%y%m%d_%H%M'`'.out'
	ioavg_file=$sysd_dir'/sysd_ioavg_'$host_name'_'`date '+%y%m%d_%H%M'`'.out'
	iocavg_file=$sysd_dir'/sysd_iocavg_'$host_name'_'`date '+%y%m%d_%H%M'`'.out'

	echo "\n$log_stamp ## Analyzing IOSTAT Datafile :\n\t$iostat_file ..."

	echo "\n\n**** IOSTAT Findings / Exceptions ****\nfor file:    $iostat_file" >> $outfile

	echo "\n   [entries where device (transacts_Waiting (wait) > $IOSTAT_WAIT_GT) or (wsvc_time_ms >= $IOSTAT_WSVCTM_GE) \n\t  or (asvc_time_ms > $IOSTAT_ASVCTM_GT) or (%W > $IOSTAT_PCTWT_GT) or (%Busy > $IOSTAT_PCTBSY_GT)]" >> $outfile


## Print device samples that are beyond thresholds (sorted by highest a_svct)

	grep -v "^    0.0    0.0" $iostat_file | grep -v "extended" | grep -v "r/s" | /usr/bin/awk '{ if (( $5 > int(w) ) || ( $7 >= int(v) ) || ( $8 > int(x) ) || ( $9 > int(y) ) || ( $10 > int(z) )) { num++; printf "%s\t\t%d\n", $0, num; } else { num_lines++ } } END { print "NOTE:", (num/NR)*100,"%",":",num,"of",NR }' v=$IOSTAT_WSVCTM_GE w=$IOSTAT_WAIT_GT x=$IOSTAT_ASVCTM_GT y=$IOSTAT_PCTWT_GT z=$IOSTAT_PCTBSY_GT | sort -r -k 8,8 > $ioex_file

	io_pct=`grep "NOTE" $ioex_file | /usr/bin/awk '{ printf "%5.1f", $2 }'`

	echo "\n   * `grep "NOTE" $ioex_file` IOSTAT entries are WARNINGS!! *" 
	echo "\n   * `grep "NOTE" $ioex_file` IOSTAT entries are WARNINGS!! *\n" >> $outfile

	if [[ $io_pct -gt 0 ]]
	then
		echo "   IOSTAT (top 100) WARNINGs reflect the slowest device entries (each line ends with record #)\n" >> $outfile
		echo "`head -2 $iostat_file`\n" >> $outfile
		head -100 $ioex_file | grep -v "NOTE:" >> $outfile
	fi
##
##
	echo "\n_________________________________________________________________\n" >> $outfile
	echo "\n\n**** IOSTAT DEVICE AVERAGES ****\nData file:    $ioavg_file\n   (*NOTE: only non-zero devices entries are reflected. Inactive devices are NOT reported*)\n" >> $outfile

## Print IO AVERAGE and PEAK HWM's per device (only for non-zero entries .. device activity)
##  let me say it again : ! Only non-zero device entries !! inactive devices aren't reported !!

	grep -v "^    0.0    0.0" $iostat_file | grep -v "^     " | grep -v "extended" | grep -v "r/s" | grep -v "mounted" | sort -k 11,11 | /usr/bin/awk '{ if (( $11 == ldev ) || ( dnum < 1 )) { rs+=$1; ws+=$2; kr+=$3; kw+=$4; ac+=$6; wt+=$7; at+=$8; w+=$9; b+=$10; ldev=$11; dnum++ } else { printf "Avg :%8.1f%8.1f%8.1f%8.1f %5.1f%7.1f%6.1f %4.1f%4d %-12s %d\nPeak:%8.1f%8.1f%8.1f%8.1f %5.1f%7.1f%6.1f %4.1f%4d\n",(rs/dnum),(ws/dnum),(kr/dnum),(kw/dnum),(ac/dnum),(wt/dnum),(at/dnum),(w/dnum),(b/dnum),ldev,dnum,Prs,Pws,Pkr,Pkw,Pac,Pwt,Pat,Pw,Pb; rs=$1; Prs=$1; ws=$2; Pws=$2; kr=$3; Pkr=$3; kw=$4; Pkw=$4; ac=$6; Pac=$6; wt=$7; Pwt=$7; at=$8; Pat=$8; w=$9; Pw=$9; b=$10; Pb=$10; ldev=$11; dnum=1 }; if ( $1 > int(Prs) ) { Prs=$1 }; if ( $2 > int(Pws) ) { Pws=$2 }; if ( $3 > int(Pkr) ) { Pkr=$3 }; if ( $4 > int(Pkw) ) { Pkw=$4 }; if ( $6 > int(Pac) ) { Pac=$6 }; if ( $7 > int(Pwt) ) { Pwt=$7 }; if ( $8 > int(Pat) ) { Pat=$8 }; if ( $9 > int(Pw) ) { Pw=$9 }; if ( $10 > int(Pb) ) { Pb=$10 } } END { printf "Avg :%8.1f%8.1f%8.1f%8.1f %5.1f%7.1f%6.1f %4.1f%4d %-12s %d\nPeak:%8.1f%8.1f%8.1f%8.1f %5.1f%7.1f%6.1f %4.1f%4d\n",(rs/dnum),(ws/dnum),(kr/dnum),(kw/dnum),(ac/dnum),(wt/dnum),(at/dnum),(w/dnum),(b/dnum),ldev,dnum,Prs,Pws,Pkr,Pkw,Pac,Pwt,Pat,Pw,Pb }' Prs=0 Pws=0 Pkr=0 Pkw=0 Pac=0 Pwt=0 Pat=0 Pw=0 Pb=0 > $ioavg_file

## I/O Per Controller (AVG and TOTALs for :  r, w, kr, kw)

	grep -v "^    0.0    0.0" $iostat_file | grep -v "^     " | grep -v "extended" | grep -v "r/s" | grep -v "mounted" | sort -k 11,11 | /usr/bin/awk '{ if (( $11 == ldev ) || ( dnum < 1 )) { crs+=$1; cws+=$2; ckr+=$3; ckw+=$4; ldev=$11; cdnum++; dnum++; if ( index($11,"t") == 0 ) { ctrlr=$11 } else { ctrlr=substr($11, 1, (index($11,"t")-1) ) } } else { if ( ctrlr != substr($11, 1, (index($11,"t")-1) )) { printf "------------\n%-4s: AVG  : %9.1f r/s | %9.1f w/s | %11.1f kr/s | %11.1f kw/s |\n%-4s: TOTAL: %9d r   | %9d w   | %11d kr   | %11d kw   | %d entries\n", ctrlr,(crs/cdnum), (cws/cdnum), (ckr/cdnum), (ckw/cdnum), ctrlr, crs,cws,ckr,ckw,cdnum; crs=$1; cws=$2; ckr=$3; ckw=$4; if ( index($11,"t") == 0 ) { ctrlr=$11 } else { ctrlr=substr($11, 1, (index($11,"t")-1) ) }; cdnum=1 } else { crs+=$1; cws+=$2; ckr+=$3; ckw+=$4; cdnum++ } ;  ldev=$11; dnum=1 } } END { printf "------------\n%-4s: AVG  : %9.1f r/s | %9.1f w/s | %11.1f kr/s | %11.1f kw/s |\n%-4s: TOTAL: %9d r   | %9d w   | %11d kr   | %11d kw   | %d entries\n", ctrlr,(crs/cdnum), (cws/cdnum), (ckr/cdnum), (ckw/cdnum), ctrlr, crs,cws,ckr,ckw,cdnum }' > $iocavg_file

	echo "\n\n TOP 10 Slowest IO Devices (* AVG of non-zero device entries *) :\n"
	echo "\n\n TOP 10 Slowest IO Devices (* AVG of non-zero device entries *) :\n" >> $sysd_perflog
	echo "\n\n TOP 10 Slowest IO Devices (* AVG of non-zero device entries *) :\n" >> $outfile

#	echo "     `/usr/bin/iostat -xn | head -2 | tail -1`  # I/O Samples\n"
	echo "     r/s     w/s    kr/s    kw/s  actv wsvc_t asvc_t  %w  %b device  # I/O Samples\n"
	echo "     r/s     w/s    kr/s    kw/s  actv wsvc_t asvc_t  %w  %b device  # I/O Samples\n" >> $sysd_perflog

	echo "     r/s     w/s    kr/s    kw/s  actv wsvc_t asvc_t  %w  %b device  # I/O Samples\n" >> $outfile

	grep "Avg" $ioavg_file | cut -d: -f2 | sort -r -k 7,7 | head -10
	grep "Avg" $ioavg_file | cut -d: -f2 | sort -r -k 7,7 | head -10 >> $sysd_perflog
	grep "Avg" $ioavg_file | cut -d: -f2 | sort -r -k 7,7 | head -10 >> $outfile

	echo "\n_____________________________________________________________________________________\n" >> $outfile
	echo "\n_____________________________________________________________________________________\n" >> $sysd_perflog
#	echo "\n\n  IO Device AVG and PEAK Values (*for active/non-zero device entries only*) :\n"
#	echo "          r/s     w/s    kr/s    kw/s  actv wsvc_t asvc_t  %w  %b device  # I/O Samples\n"
#	cat $ioavg_file
	echo "\n\n  IO Device AVG and PEAK Values (*for active/non-zero device entries only*) :\n" >> $sysd_perflog
	echo "          r/s     w/s    kr/s    kw/s  actv wsvc_t asvc_t  %w  %b device  # I/O Samples\n" >> $sysd_perflog
	cat $ioavg_file >> $sysd_perflog

	echo "\n  The following reflects DEVICE AVERAGES (*for active/non-zero device entries only*) :\n   ( # Samples = the # of non 0 iostat entries per device, used for the avg)\n" >> $outfile

#	echo "     `/usr/bin/iostat -xn | head -2`    # I/O Samples\n" >> $outfile
	echo "          r/s     w/s    kr/s    kw/s  actv wsvc_t asvc_t  %w  %b device  # I/O Samples\n">> $outfile
	cat $ioavg_file >> $outfile


	echo "\n_____________________________________________________________________________________\n" >> $outfile
	echo "\n_____________________________________________________________________________________\n"
	echo "\n_____________________________________________________________________________________\n" >> $sysd_perflog

	echo "CONTROLLER IO : AVG and TOTAL Throughput per HBA (*active/non-zero entries only*) :\n"
	echo "CONTROLLER IO : AVG and TOTAL Throughput per HBA (*active/non-zero entries only*) :\n" >> $sysd_perflog
	cat $iocavg_file

	echo "CONTROLLER IO :  AVG and TOTAL Throughput per HBA (for non zero entries) :\n" >> $outfile
	cat $iocavg_file >> $outfile
	cat $iocavg_file >> $sysd_perflog

	echo "\n_____________________________________________________________________________________\n" >> $outfile
	echo "\n_____________________________________________________________________________________\n"
	echo "\n_____________________________________________________________________________________\n" >> $sysd_perflog

#############
#
## MORE Data could go here if there was an easy to correlate the Hottest locks w file/device
#
#############
##	NOTE:  Network Performance analysis  :
##	(most systems dont see collisions, ..they cant exist with Full Duplex )
##
	netavg2_file=$sysd_dir'/sysd_netavg2_'$host_name'_'`date '+%y%m%d_%H%M'`'.out'
	netavg1_file=$sysd_dir'/sysd_netavg1_'$host_name'_'`date '+%y%m%d_%H%M'`'.out'

	echo "\n$log_stamp ## Analyzing NETSTAT Datafiles : ...\n"
	echo "\n$log_stamp ## Analyzing NETSTAT Datafiles : ...\n" >> $sysd_perflog
	echo "\n\n**** NETWORK Findings (Netstat / Kstat) : ****\n" >> $outfile
	echo "\n\t[entries where interface (RX_Pkts > $NETSTAT_RX_GT) or (Rx_Pkt_Errs > $NETSTAT_RX_ERR_GT) \n\t\tor (Tx_Pkts > $NETSTAT_TX_GT) or (Tx_Pkt_Errs > $NETSTAT_TX_ERR_GT) or (Collisions > $NETSTAT_COLL_GT)]\n" >> $outfile

	num_nets=0
	net_pct=0
	net_pct_nic=0

	ifcfg_file=$sysd_dir'/sysd_ifcfg_*.out'

########
###     Calcultate TOTAL_RX & TX Pkts for LOGICAL Interfaces only (from [netstat -i -a] files)
##
##      Note: These numbers are also included in the kstat (knet) data TOTALS for physical
##            NIC port totals (TOT_RX/TX_Bytes TOT_RX/TX_Packets).   
##	Also, given that the netstat snaps taken with snap_bme_perf() are taken before/after
##	the kstat (knetb/e_ files) .. the numbers may slightly vary.
###
	for j in `cat $ifcfg_file |  grep ": " | cut -d" " -f1`
	do
		i=`echo $j | cut -d":" -f1`	# i = physical nic .. eg.. hme0
		k=${j%%:}		# take off the last ":" from hme0:11:
		l=${k#$i:}		# strip off the logical interface number

		if [[ ( $i = $last_nic ) && ( $num_nets -gt 0 ) ]]
		then						#### this IS a Logical Interface
		    netb_file=$sysd_dir'/sysd_netstat0_*.out'
		    nete_file=$sysd_dir'/sysd_netstat2_*.out'

		    if [[ ( -f `echo $netb_file` ) &&  ( -f `echo $nete_file` ) ]]
		    then
			net_b_rxpkts=$((`grep $k $netb_file | /usr/bin/awk '{ print $5 }'`))
			net_e_rxpkts=$((`grep $k $nete_file | /usr/bin/awk '{ print $5 }'`))
			net_rxpkts=$(($net_e_rxpkts-$net_b_rxpkts))

			net_b_txpkts=$((`grep $k $netb_file | /usr/bin/awk '{ print $7 }'`))
			net_e_txpkts=$((`grep $k $nete_file | /usr/bin/awk '{ print $7 }'`))
			net_txpkts=$(($net_e_txpkts-$net_b_txpkts))

			echo "     : $j      \t\t\t\tTOT_RX_Packets\tTOT_TX_Packets" >> $outfile
			echo $net_e_rxpkts $net_b_rxpkts $net_e_txpkts $net_b_txpkts | /usr/bin/awk '{ printf "     : %-8s                                  %10.0f    %10.0f\n", lnic, ($1-$2), ($3-$4) }' lnic=$j >> $outfile
			echo "     : $j      \t\t\t\tTOT_RX_Packets\tTOT_TX_Packets" >> $netavg2_file
			echo $net_e_rxpkts $net_b_rxpkts $net_e_txpkts $net_b_txpkts | /usr/bin/awk '{ printf "     : %-8s                                  %10.0f    %10.0f\n", lnic, ($1-$2), ($3-$4) }' lnic=$j >> $netavg2_file

			echo "\n\t_________________________________________________________________________\n" >> $outfile

		    else
			echo "\n\t** $netb_file and/or $nete_file do NOT exist ! **\n"
		    fi

		    continue	# Logical Layered Virtual NIC Interface, skip..

		else
			last_nic=$i
		fi

   		num_nets=$(($num_nets+1))
		netstat_file=$sysd_dir'/sysd_net'$num_nets'_*.out'
 		netex_file=$sysd_dir'/sysd_net'$num_nets'x_'$host_name'_'`date '+%y%m%d_%H%M'`'.out'

		if [[ $debg -eq 1 ]]
		then
			echo "\t$ifcfg_file\n\t$i\t$num_nets\n\t$netstat_file\n\t$netex_file\n\t$netstat_graph_file\n"
		fi

		netstat_graph_file=$sysd_dir'/sysd_net'$num_nets'_'$host_name'_'`date '+%y%m%d_%H%M'`'.gr.txt'
#		netstat_graph_file=$sysd_dir'/'`echo $netstat_file | cut -d"/" -f3`'.gr.txt' # don't know how many sub-dirs deep !!

		if [[ $debg -eq 1 ]]
		then
			echo "\t$ifcfg_file\n\t$i\t$num_nets\n\t$netstat_file\n\t$netex_file\n\t$netstat_graph_file\n"
		fi

		tail +4 $netstat_file | /usr/bin/awk '{ if ((( $1 != "input" ) && ( $1 != "packets" )) && (( $1 > int(v) ) || ( $2 > int(w) ) || ( $3 > int(x) ) || ( $4 > int(y) ) || ( $5 < int(z) ))) { num++; printf "%s\t\t%d\n", $0, num; } { num_lines++ } } END { print "NOTE:", (num/num_lines)*100,"%",":", num, "of",num_lines }' num=0 v=$NETSTAT_RX_GT w=$NETSTAT_RX_ERR_GT x=$NETSTAT_TX_GT y=$NETSTAT_TX_ERR_GT z=$NETSTAT_COLL_GT > $netex_file


		net_pct_nic=`grep "NOTE" $netex_file | /usr/bin/awk '{ printf "%5.1f", $2 }'`

		echo "   * $i : `grep "NOTE" $netex_file` NETSTAT entries are WARNINGS!! *" >> $netavg1_file
		echo "\n   * $i : `grep "NOTE" $netex_file` NETSTAT entries are WARNINGS!! *" >> $outfile

		if [[ $net_pct_nic -gt 0 ]]
		then
			echo "\n** Top 20 samples for : $i from file: $netstat_file **" >> $outfile
			echo "`head -2 $netstat_file`\n" >> $outfile
			grep -v "NOTE" $netex_file | sort -r -k 1,1 | head -20 >> $outfile
		fi

		echo "\n------------    *MAX_RX_PKTS*  AVG_RX_PKTS AVG_RX_ERRS AVG_TX_PKTS AVG_TX_ERRS AVG_COLL" >> $outfile
		echo "\n------------    *MAX_RX_PKTS*  AVG_RX_PKTS AVG_RX_ERRS AVG_TX_PKTS AVG_TX_ERRS AVG_COLL" >> $netavg2_file

		net_avg=`tail +4 $netstat_file | /usr/bin/awk '{ if (( $1 != "input" ) && ( $1 != "packets" )) { rxpkts+=$1 ; rxerrs+=$2 ; txpkts+=$3 ; txerrs+=$4 ; collisions+=$5 ; num++ } { if ( $1 > rxpeak ) { rxpeak=$1 }; num_lines++ } } END { if ( num > 0 ) { printf "NET%-2d: %-5s:%10d    %10.1f     %6.1f    %10.1f     %6.1f    %6.1f", netnum, nic, rxpeak, (rxpkts/num), (rxerrs/num), (txpkts/num), (txerrs/num), (collisions/num) } }' netnum=$num_nets nic=$i rxpeak=0 num=0`

		echo "$net_avg" >> $outfile
		echo "$net_avg" >> $netavg2_file
########
##   	Calculate & print TOTAL Bytes per NIC if not lo0 (from kstat knetb/e_ files).
##  	NOTE: These numbers will already include the Logical interface activity Totals
##	and might vary slightly since the #s from netstat are captured bef/aft these kstat #s.
########
		if [[ $num_nets -gt 1 ]]
		then
			knetb_file=$sysd_dir'/sysd_knetb_'$i*'.out'
			knete_file=$sysd_dir'/sysd_knete_'$i*'.out'

			knet_b_rxbytes=$((`grep rbytes $knetb_file | head -1 | cut -f2`))
			knet_e_rxbytes=$((`grep rbytes $knete_file | head -1 | cut -f2`))
			knet_rxbytes=$(($knet_e_rxbytes-$knet_b_rxbytes))

			knet_b_txbytes=$((`grep obytes $knetb_file | head -1 | cut -f2`))
			knet_e_txbytes=$((`grep obytes $knete_file | head -1 | cut -f2`))
			knet_txbytes=$(($knet_e_txbytes-$knet_b_txbytes))

			knet_b_rxpkts=$((`grep ipackets $knetb_file | head -1 | cut -f2`))
			knet_e_rxpkts=$((`grep ipackets $knete_file | head -1 | cut -f2`))
			knet_rxpkts=$(($knet_e_rxpkts-$knet_b_rxpkts))

			knet_b_txpkts=$((`grep opackets $knetb_file | head -1 | cut -f2`))
			knet_e_txpkts=$((`grep opackets $knete_file | head -1 | cut -f2`))
			knet_txpkts=$(($knet_e_txpkts-$knet_b_txpkts))

			knet_b_secs=$((`head -1 $knetb_file`))
			knet_e_secs=$((`head -1 $knete_file`))
			knet_total_secs=$(($knet_e_secs-$knet_b_secs))

			echo "     : $i  :   TOT_RX_Bytes   TOT_TX_Bytes\tTOT_RX_Packets\tTOT_TX_Packets\tTOTAL_Seconds" >> $outfile
			echo $knet_rxbytes $knet_txbytes $knet_rxpkts $knet_txpkts $knet_total_secs | /usr/bin/awk '{ printf "                %12s   %12s     %11s     %11s   %11s\n", $1, $2, $3, $4, $5 }' >> $outfile

			echo "     : $i  :   TOT_RX_Bytes   TOT_TX_Bytes\tTOT_RX_Packets\tTOT_TX_Packets\tTOTAL_Seconds" >> $netavg2_file
			echo $knet_rxbytes $knet_txbytes $knet_rxpkts $knet_txpkts $knet_total_secs | /usr/bin/awk '{ printf "                %12s   %12s     %11s     %11s   %11s\n", $1, $2, $3, $4, $5 }' >> $netavg2_file

		fi


		echo "RX_pkts TX_pkts Total_RX Total_TX" > $netstat_graph_file

		tail +4 $netstat_file | /usr/bin/awk '{ if (( $1 != "input" ) && ( $1 != "packets" )) { print $1,$3,$6,$8 } { num_lines++ } } END { num=0 }' >> $netstat_graph_file


		echo "\n\t_________________________________________\n" >> $outfile

		if [[ $net_pct_nic -gt $net_pct ]]
		then
			net_pct=$net_pct_nic
		fi

	done

	cat $netavg1_file
	cat $netavg1_file >> $sysd_perflog
	cat $netavg2_file
	cat $netavg2_file >> $sysd_perflog

	num_timewait=`grep TIME_WAIT $sysd_dir/sysd_netstata_* | grep -v grep | wc -l`
	num_established=`grep ESTABLISHED $sysd_dir/sysd_netstata_* | grep -v grep | wc -l`

	if [[ $num_timewait -gt 0 ]]
	then
		echo "\n\tNOTE: ** $num_timewait TIME_WAIT sockets exist **" 
		echo "\n\tNOTE: ** $num_timewait TIME_WAIT sockets exist **" >> $outfile
	fi

	if [[ $num_established -gt 0 ]]
	then
		echo "\n\tNOTE: ** $num_established ESTABLISHED connections (sockets) exist **" 
		echo "\n\tNOTE: ** $num_established ESTABLISHED connections (sockets) exist **\n" >> $outfile
	fi

	echo "\n_____________________________________________________________________________________\n"
	echo "\n_____________________________________________________________________________________\n" >> $outfile
	echo "\n_____________________________________________________________________________________\n" >> $sysd_perflog

	if [[ -x /sbin/lltstat ]]		# VCS LLT interconnect stats,..if there
	then
#		echo "\n**** VCS LLTSTAT Interconnect Packets after $knet_total_secs seconds ****" >> $outfile
#		/sbin/lltstat -l >> $outfile
		cat `echo $sysd_dir'/sysd_llt_*.out'` >> $outfile

		echo "_____________________________________________________________________________________\n" >> $outfile
	fi

	if [[ $perf -ge 1 ]]
	then
		echo "## 25 ###########  Extended Analysis / Dtrace : Output Files  ############\n" >> $outfile
		if [[ $perf -lt 2 ]]
		then
			echo "\n\t\t ** NOTE: Only the -G output includes Dtrace snapshots **\n" >> $outfile
		fi
	fi

####################################################################
	##### Calculate the Dashboard States ######
####################################################################

	num_cpus=`psrinfo | wc -l`

	if [[ ( $vm_pct -gt $VMSTAT_PCT_RED ) || ( $mp_pct -gt $MPSTAT_PCT_RED ) ]]
	then
		cpu_color="RED"
		cpu_rgb="rgb(255, 0, 0)"
	elif [[ ( $vm_pct -gt $VMSTAT_PCT_YEL ) || ( $mp_pct -gt $MPSTAT_PCT_YEL ) ]]
	then

	######## ADD / FIX !! to change to YELLOW IF .. RUN QUEUE PEAK > ?? || AVG > ?? .25 ?? !!

		cpu_color="YEL"
		cpu_rgb="rgb(255, 255, 0)"
	else
		cpu_color="GRN"
		cpu_rgb="rgb(51, 204, 0)"
	fi

	if [[ $mem_pct -gt $MEM_PCT_RED ]]
	then
		mem_color="RED"
		mem_rgb="rgb(255, 0, 0)"
	elif [[ $mem_pct -gt $MEM_PCT_YEL ]]
	then
		mem_color="YEL"
		mem_rgb="rgb(255, 255, 0)"
	else
		mem_color="GRN"
		mem_rgb="rgb(51, 204, 0)"
	fi

	if [[ $io_pct -gt $IOSTAT_PCT_RED ]]
	then
		io_color="RED"
		io_rgb="rgb(255, 0, 0)"
	elif [[ $io_pct -gt $IOSTAT_PCT_YEL ]]
	then
		io_color="YEL"
		io_rgb="rgb(255, 255, 0)"
	else
		io_color="GRN"
		io_rgb="rgb(51, 204, 0)"
	fi

	if [[ $net_pct -gt $NETSTAT_PCT_RED ]]
	then
		net_color="RED"
		net_rgb="rgb(255, 0, 0)"
	elif [[ $net_pct -gt $NETSTAT_PCT_YEL ]]
	then
		net_color="YEL"
		net_rgb="rgb(255, 255, 0)"
	else
		net_color="GRN"
		net_rgb="rgb(51, 204, 0)"
	fi

	echo "* NOTE:\tCPU=$cpu_color  :  \c"
	echo "* Overall SUMMARY *:\tCPU=$cpu_color  :  \c" >> $sysd_perflog
	echo "MEM=$mem_color  :  \c"
	echo "MEM=$mem_color  :  \c" >> $sysd_perflog
	echo "IO=$io_color  :  \c"
	echo "IO=$io_color  :  \c" >> $sysd_perflog
	echo "NET=$net_color *\n"
	echo "NET=$net_color *\n" >> $sysd_perflog

	echo "_____________________________________________________________________________________\n"
	echo "_____________________________________________________________________________________\n" >> $sysd_perflog

########### Generate the HTML Performance Dashboard #############

	echo "<br><table bgcolor=\"#594fbf\" border=\"3\" width=\"100%\"><tbody><tr><td><a name=\"perfdash\"></a><b><font color=\"#ffffff\" size=\"+2\">SYSTEM PERFORMANCE DASHBOARD :</font></b></td></tr></tbody></table><br>" > $dash_file

## WORKLOAD Characterization Section  ##

	echo "<table style=\"margin-left: auto; margin-right: auto; text-align: left; width: 800px;\" border=\"2\" cellpadding=\"2\" cellspacing=\"2\"><tbody><tr><tr><td style=\"vertical-align: top; background-color: rgb(210, 210, 255);\"><span style=\"font-weight: bold; text-decoration: underline;\">Workload Characterization:</span><br><pre><table align=\"center\" border=\"1\" width=\"90%\"><tbody><tr><td><pre><b>" >> $dash_file

	prstat_file=`echo $sysd_dir'/sysd_prstat_*.out'`
	echo "`cat $prstat_file`</b>" >> $dash_file

	echo "</pre></td></tr></tbody></table>" >> $dash_file

	if [[ $num_defunct -gt 1 ]]
	then
		echo "<pre><b>\n\tNOTE: ** $num_defunct DEFUNCT (zombie) processes exist **</b></pre><br>" >> $dash_file
	fi

	echo "      <a href=\"#2\" class=\"named\">prstat</a>      <a href=\"#PS by %CP\" class=\"named\">Top %CPU</a>     <a href=\"#PS by %ME\" class=\"named\">Top %MEM</a>      <a href=\"#PS by LWP\" class=\"named\">Top LWPs<a>\c"  >> $dash_file

	if [[ -r `echo $sysd_dir/sysd_pmap0_*` ]]
	then
		echo "    <a href=\"#Pmap Snaps\" class=\"named\">Top PID pmap files</a>\c" >> $dash_file
	fi

	if [[ -r `echo $sysd_dir/sysd_dio0_*` ]]
	then
		echo "    <a href=\"#Dtrace pio\" class=\"named\">Top PID IO (Dtrace)</a>" >> $dash_file
	else
		echo " "
	fi

## TBD.. to EMBED file lnk: echo "<a href=\"file:///$etc_system_file#etc_system\" class=\"named\"></a>" >> $dash_file

## CPU / Kernel Profiling Section  ##

	echo "</b></pre></td></tr><tr><td style=\"vertical-align: top; background-color: $cpu_rgb;\"><span style=\"font-weight: bold; text-decoration: underline;\">CPU / Kernel Profiling :</span><br>" >> $dash_file

	echo "<pre>\t* `grep "NOTE" $vmex_file` VMSTAT CPU entries are WARNINGS!! *<br>" >> $dash_file
	echo "<table align=\"center\" border=\"1\" width=\"90%\"><tbody><tr><td><pre><b>" >> $dash_file

	head -2 $vmavg_file >> $dash_file
	echo "\n" >> $dash_file
	tail -2 $scratchfile >> $dash_file

	echo "</b></pre></td></tr></tbody></table>" >> $dash_file

	echo "\n   <a href=\"#1\" class=\"named\">CPU Config</a>    <b><a href=\"#CPU (VMST\" class=\"named\">*VMSTAT CPU Analysis*</a>    <a href=\"#CPU (MPST\" class=\"named\">*MPSTAT Analysis*</a></b>\c" >> $dash_file

	if [[ -r `echo $sysd_dir/sysd_lP0_*` ]]
	then
		echo "   <a href=\"#Lockstat A\" class=\"named\">Lockstat Files</a>\c" >> $dash_file
	else
		echo "   <a href=\"#LOCKSTAT_\" class=\"named\">*LOCKSTAT*</a>\c" >> $dash_file
	fi
 
##	echo "   <a href=\"#INTERRUPT\" class=\"named\">Interrupts</a>\c" >> $dash_file
	echo "   <a href=\"#CPU STATI\" class=\"named\">CPU Stats/Interrpts</a>\c" >> $dash_file

	if [[ -r `echo $sysd_dir/sysd_dsinfo_by_procs0_*` ]]
	then
		echo "   <a href=\"#Dtrace sin\" class=\"named\">Dtrace calls/counts</a>" >> $dash_file
	else
		echo " "
	fi

	echo "</pre></td></tr>" >> $dash_file

## Memory Profiling Section  ##

	echo "<tr> <td style=\"vertical-align: top; background-color: $mem_rgb;\"><span style=\"font-weight: bold; text-decoration: underline;\">MEMORY:</span><br>" >> $dash_file
	echo "<pre>\t* `grep "NOTE" $memex_file` VMSTAT MEMORY entries are WARNINGS!! *</pre>" >> $dash_file

	echo "<table align=\"center\" border=\"1\" width=\"90%\"><tbody><tr><td><pre><b>" >> $dash_file

	tail -2 $vmavg_file >> $dash_file

	echo "</b></pre></td></tr></tbody></table><pre>" >> $dash_file

	if [[ $tlb_spt -gt 1 ]]
	then
		echo "</b><br>\t$tlb_miss<br>" >> $dash_file
	fi

	echo "\n\t<a href=\"#1\" class=\"named\">Memory Config</a>    <b><a href=\"#MEMORY (V\" class=\"named\">*VMSTAT MEM Analysis*</a></b>    <a href=\"#SWAP SPAC\" class=\"named\">Swap</a>     <a href=\"#Kernel Me\" class=\"named\">Kernel Mem</a>    <a href=\"#IPCS Shar\" class=\"named\">Shared Mem</a>\c" >> $dash_file

	if [[ -r `echo $sysd_dir/sysd_mdb0_*` ]]
	then
		echo "    <a href=\"#Mdb Snaps\" class=\"named\">Mdb</a>" >> $dash_file
	else
		echo " "
	fi
	echo "</pre></td></tr>" >> $dash_file

## I/O Profiling Section  ##

	echo "<tr> <td style=\"vertical-align: top; background-color: $io_rgb;\"><span style=\"text-decoration: underline; font-weight: bold;\">IO:</span><br>" >> $dash_file

	echo "<pre>\t* `grep "NOTE" $ioex_file` IOSTAT entries are WARNINGS!!  \c" >> $dash_file
	echo "\t<b>* DNLC : * $dnlc_cache *</b><pre>" >> $dash_file

	echo "<table align=\"center\" border=\"1\" width=\"90%\"><tbody><tr><td><pre><b>" >> $dash_file

	echo "CONTROLLER IO :  AVG and TOTAL Throughput per HBA (for non zero entries) :\n" >> $dash_file
	cat $iocavg_file >> $dash_file

	echo "</b></pre></td></tr></tbody></table><pre>" >> $dash_file

	echo "<br>   <a href=\"#5\" class=\"named\">IO Config</a>    <a href=\"#7\" class=\"named\">FS Config</a>    <a href=\"#6\" class=\"named\">VM Config</a>     <b><a href=\"#IOSTAT Fi\" class=\"named\">*IOSTAT Analysis*</a>    <a href=\"#IOSTAT DE\" class=\"named\">*Device AVGs*</a></b>     <a href=\"#9\" class=\"named\">NFS</a>   <a href=\"#ZFS Confi\" class=\"named\">ZFS</a>\c" >> $dash_file

	if [[ -r `echo $sysd_dir/sysd_dR_by_procs0_*` ]]
	then
		echo "    <a href=\"#Dtrace dtR\" class=\"named\">Dtrace READ/WRITEs</a></pre></td></tr>" >> $dash_file
	else
		echo " </pre></td></tr>" >> $dash_file
	fi

## Network Profiling Section  ##

	echo "<tr> <td style=\"vertical-align: top; background-color: $net_rgb;\"><span style=\"font-weight: bold; text-decoration: underline;\">NETWORK:</span><br><pre>" >> $dash_file

	echo " \c" >> $dash_file
	cat $netavg1_file >> $dash_file
	echo "</pre>\c" >> $dash_file

	echo "<table align=\"center\" border=\"1\" width=\"90%\"><tbody><tr><td><pre><b>\c" >> $dash_file

	cat $netavg2_file >> $dash_file
	echo "</b></pre></td></tr></tbody></table><pre>\c" >> $dash_file

	if [[ $num_timewait -gt 9 ]]
	then
		echo "<br><b>\tNOTE: ** $num_timewait TIME_WAIT sockets exist **</b>" >> $dash_file
	fi

	echo "<br><b>\tNOTE: ** $num_established ESTABLISHED <a href=\"#NETWORK C\" class=\"named\">Connections</a> (sockets) exist **</b>" >> $dash_file

	echo "</b><br>   <a href=\"#10\" class=\"named\">Network Config</a>    <a href=\"#NETWORK E\" class=\"named\">Network ERRORS</a>    <b><a href=\"#NETWORK F\" class=\"named\">*NETSTAT Analysis*</a></b>    <a href=\"#Sun Trunk\" class=\"named\">Trunking/LinkAggr</a>\c" >> $dash_file

	if [[ -x /sbin/lltstat ]]	# VCS LLT interconnect stats
	then
		echo "   <a href=\"#VCS LLTST\" class=\"named\">lltstat</a>\c" >> $dash_file
	fi

	if [[ -r `echo $sysd_dir/sysd_dtcp_rx0_*` ]]
	then
		echo "   <a href=\"#Dtrace TcR\" class=\"named\">Dtrace tcp_R/W</a>\c" >> $dash_file
	fi

	if [[ $perf -ge 1 ]]
	then
		echo "   <a href=\"#Knet 0\" class=\"named\">Kstat NIC Files</a>" >> $dash_file
	else
		echo " "
	fi

	echo " </pre></td></tr></tbody></table>" >> $dash_file
}

#
### #################################################################### # #
## ## ## ## # # # ***** End FUNCTION Declarations ***** # # # ## ## ##### # #
### #################################################################### # #
#

log_stamp='sys_diag:'`date '+%m%d_%H%M%S'`':'


if ( [ -z $SYSDIAG_HOME ] || ( ! [ -w `echo $SYSDIAG_HOME` ] ))
then
	home_dir='.'
else
	home_dir=$SYSDIAG_HOME
fi

echo "\n"

##################### PARSE COMMAND LINE ARGUMENTS ###################

if [[ $# = 0 ]]
then
	echo "$log_stamp  DEFAULT Report, Not LONG, No gathering PERF, No TAR\n"
	ALL=1
	TAR=0
else

   i=$#

   while getopts acCd:Df:gGHI:lL:mnNo:pPRsST:tuvVxh?A arg
   do
	case $arg in 
	    a )
		echo "$log_stamp  APPS"
		APPS=1
		ORACLE=1
		;;
	    c )
        	echo "$log_stamp  CONFIG"
        	CONFIG=1
#		ALL=0
		;;
	    C )
        	echo "$log_stamp  CLEANUP"
        	CLEANUP=1
#		ALL=0
		;;
	    d )				# Data Directory / Base Dir. / Home
		home_dir=$OPTARG
       		echo "$log_stamp  HOME/DATA DIRECTORY: $home_dir"
        	DIR=1
		;;
	    D )
		echo "$log_stamp  DEBUG"
		DEBUG=2
		set -x
		;;
	    f )			# INPUT File (infile) ..TBD..
		infile=$OPTARG
        	FILE=1

    		if [[ -f $infile ]]
		then
       			echo "$log_stamp  INPUT FILE: \c"
			echo "$infile"
		else
			echo "\n **ERROR** FILE : $infile Does NOT Exist, ignoring it**\n"
		fi
		;;
	    g )
       		echo "$log_stamp  gather PERFORMANCE Data"
		IO=1
		PERF=1		# spawn gathering procs
		POSTPERF=1
#		ALL=0
		;;
	    G )
       		echo "$log_stamp  GATHER Extra PERFORMANCE DATA"
		IO=1
		PERF=2		# spawn EXTRA data gathering
		POSTPERF=1
#		ALL=0
		;;
	    H )
       		echo "$log_stamp  HA"
        	HA=1
#		ALL=0
		;;
	    I )
		interval_secs=$OPTARG
       		echo "$log_stamp  INTERVAL: \c"
        	INTERVAL=1

   		if [[ `echo $interval_secs | /usr/bin/awk '{ printf "%s", substr($0,1,1) }'` = [0-9] ]]
		then
			echo "$interval_secs"
		else
			echo "*ERROR* $interval_secs is NOT an INTEGER !**\n"
			exit 1
		fi
		;;
	    l )
		echo "$log_stamp  LONG"
		LONG=1
		ALL=1
		;;
	    L )			## Report header descriptive LABEL
		label=$OPTARG
		echo "$log_stamp  LABEL : $label"
		LABEL=1
		;;
	    m )			## TO BE ADDED ..for menu interface
       		echo "$log_stamp  MENU"
		MENU=1
#		ALL=0
		;;
	    n )
		echo "$log_stamp  NETWORK"
		NETWORK=1
#		ALL=0
		;;
 	    N )
 		echo "$log_stamp  N1"
 		N1=1
 		ALL=0
 		;;
	    o )
		outfile=$OPTARG
		echo "$log_stamp  OUTPUT FILE: $outfile"
		OUTPUT=1
		;;
	    p )				# Generate POSTSCRIPT rpt also
		echo "$log_stamp  POSTSCRIPT"
		POST=1
#		ALL=0
		;;
	    P )
		echo "$log_stamp  PERFORMANCE POST-PROCESSing"
		POSTPERF=1
#		ALL=0
		;;
	    R )
		echo "$log_stamp  ROOT prompt"
		PROMPT=1
#		ALL=0
		;;
	    s )
		echo "$log_stamp  SECURITY"
		SECURITY=1
#		ALL=0
		;;
	    S )
		echo "$log_stamp  SKIP POSTPROCESSing"
		SKIP_POSTPERF=1
#		ALL=0
		;;
	    T )
		duration_secs=$OPTARG
       		echo "$log_stamp  TIME Duration: \c"
        	DURATION=1

   		if [[ `echo $duration_secs | /usr/bin/awk '{ printf "%s", substr($0,1,1) }'` = [0-9] ]]
		then
			echo "$duration_secs"
		else
			echo "*ERROR* $duration_secs is NOT an INTEGER !**\n"
			exit 1
		fi
		;;
	    t )				## ASSET / CONFIG MGMT Tracking
		echo "$log_stamp  TRACK"
		TRACK=1
		;;
	    u )
		echo "$log_stamp  UNTARed"	## Turn off tar'ing..
		TAR=0
		;;
	    v )
		echo "\tSys_Diag version : $SYS_DIAG_VER"
		echo "\n\tCopyright 1999-2007 Todd A. Jobson"
		echo "\n\tfor command line usage, use -h or -?\n"
		exit 0
		;;
	    V )
		echo "$log_stamp  VERBOSE"
		VERBOSE=1
#		LONG=1
#		ALL=1
		;;
#	    x )				## TBD ... EXTRACT config files.. TBD..
#		echo "$log_stamp  EXTRACT"
#		EXTRACT=1
#		;;
	    h | \? )
 
        	echo "\nCOMMAND USAGE :\t# sys_diag [ -a -A -c -g -l .... ]\n"
		echo "\t-a\tApplication details\n"
		echo "\t-A\tALL Options are turned on, except Debug and -u\n"
		echo "\t-c\tConfiguration details (included in -l/-A)\n"
		echo "\t-C\tCleanup Files and remove Directory if tar works\n"
		echo "\t-d path   Base directory for data directory / files\n"
		echo "\t-D\tDebug ksh mode\n"
		echo "\t-f input_file\tUsed with -t to specify a list of files to Track changes of\n"
		echo "\t-g\tgather Performance data (defaults to 2 sec intervals for 5 mins)\n"
		echo "\t-G\tGATHER Extra Performance data (Dtrace, deeper lockstats), vs. -g\n"
		echo "\t-h / -?   Help / Command Usage (this listing)\n"
		echo "\t-H\tHA config and stats\n"
		echo "\t-I secs   Perf Gathering Sample Interval (default is 2 secs)\n"
		echo "\t-l\tLong Listing (most details, but not -g,-V,-A,-t,-D)\n"
		echo "\t-L label_descr_nospaces   (Descriptive Label For Report)\n"
# TBD		echo "\t-m\tMenu driven interface\n"
		echo "\t-n\tNetwork configuration and stats (included in -l/-A)\n"
#		echo "\t-N\tN1 configuration\n"
		echo "\t-o outfile   Output filename (stored under sub-dir created)\n"
		echo "\t-p\tGenerate Postscript Report, along with .txt, and .html\n"
		echo "\t-P -d ./data_dir_path\tPost-process the Perf data skipped with -S and finish .html rpt\n"
# TBD		echo "\t-R\tRoot User pwd prompt\n"
		echo "\t-s\tSecurIty configuration\n"
		echo "\t-S\tSKIP POST PROCESSing of Performance data (use -P -d data_dir to complete)\n"
		echo "\t-T secs   Perf Gathering Total Duration (default is 300 secs =5 mins)\n"
		echo "\t-t\tTrack configuration changes (Rpts config/file chgs, *see -f)\n"
		echo "\t-u\tunTar ed: (do NOT create a tar file)\n"
		echo "\t-v\tversion Information for sys_diag\n"
		echo "\t-V\tVerbose Mode (adds path_to_inst, network dev's, snoop..)\n"
		echo "\n  NOTE: NO args equates to a brief rpt (No -A,-g/I,-l,-t,-D,-V,..)\n"
		echo "  eg.\tCommon Usage :\n\n\t./sys_diag -l   (creates a detailed config rpt)\n"
		echo "\t./sys_diag -g -l   (gathers perf data at deflt 2 sec samples\n\t\t\t  for 5 mins, and creates a long config rpt)\n"
		echo "\t./sys_diag -g -I 1 -T 600 -l   (gathers perf data at 1 sec\n\t\t\t\t\tsamples for 10 mins and creates a long config rpt)\n"
		echo "\t./sys_diag -l -C   (creates long config rpt, and Cleans up..\n\t\t\t  aka removes the data directory after tar.Z completes)\n"
		echo "\t./sys_diag -d base_directory_path  (the base dir for datafiles)\n"
		echo "\t./sys_diag -G -I 1 -T 600 -l   (gathers deep perf data at 1 sec\n\t\t\t\t\tsamples for 10 mins and creates a long config rpt)\n"
		echo "\t./sys_diag -g -l -S  (gathers perf data, runs long config rpt, \n\t\t\t\tand SKIPS Post-Processing and .html report generation)\n"
		echo "\t./sys_diag -P -d ./data_dir_path  (Completes Skipped Post-Processing and .html report generation)\n"
        	exit 0
		;;
	    A )
		echo "$log_stamp  ALL"
		ALL=1
		APPS=1
		CONFIG=1
		HA=1
		IO=1
		LONG=1
		N1=1
		NETWORK=1
		ORACLE=1
		PATCHMGT=1
		PERF=1
		POSTPERF=1
		POST=1
		TRACK=1
		VERBOSE=1
		;;

	esac

    done

    shift $(($OPTIND - 1))
#   printf "Remaining arguments are: %s\n" "$*"		##  see man printf, %u will print unsigned integers

fi

#########  PARSE and/or INPUT $SYSDIAG_HOME value ###########


while ( [ -z $home_dir ] || ( ! [ -w `echo $home_dir` ] ))
do
	echo "\n\tNOTE: SYSDIAG_HOME :$SYSDIAG_HOME: is not set (or -d path :$home_dir: is NOT writable)."
	echo "\tEnter a valid directory for storing datafiles [./] >\c"
	read home_dir

	if [[ -z $home_dir ]]
	then
		home_dir='.'
	fi
done

#############  INITIALIZE and/or Assign datafile values  ##############


if [[ $DEBUG -ne 0 ]]
then
	echo "\n sysd_dir=$sysd_dir,\n filename=$filename,\n infile=$infile,\n outfile=$outfile,\n"
fi


if [[ ( $PERF -eq 0 ) && ( $POSTPERF -ne 0 ) ]]
then
	dirname=${home_dir##*/}
	filename=$dirname'.out'				# filename for .out rpt
	sysd_dir=`echo $home_dir`
	outfile=`echo $sysd_dir/$filename`
	tar_file=$dirname'.tar'
else
	filename='sysd_'$hname'_'`date '+%y%m%d_%H%M'`	# use for directory name
	sysd_dir=`echo $home_dir/$filename`

	if [[ -z $outfile ]]
	then
		outfile=`echo $sysd_dir/$filename.out`
	else
		outfile=`echo $sysd_dir/$outfile`
	fi
	tar_file=$home_dir'/'$filename.tar
fi

html_file="$outfile.html"

if [[ $DEBUG -ne 0 ]]
then
	echo "\n sysd_dir=$sysd_dir,\n filename=$filename,\n infile=$infile,\n outfile=$outfile,\n html_file=$html_file,\n dirname=$dirname,\ntar_file=$tar_file,\n home_dir=$home_dir\n"
fi

if [[ ( $PERF -eq 0 ) && ( $POSTPERF -ne 0 ) ]]	   ## If  -P post_perf   OR  regular proc'g..
then
	dash_file=$outfile'.dash.html'		# If -P .. then skip all the mkdir stuff
else						# If not -P .. then mkdir, etc..
    if ( ! [ -d $sysd_dir ] )	# if no directory exists.. then create it..
    then
	mkdir $sysd_dir
	ret=$?

	if [[ $ret -ne 0 ]]
	then
	    mkdir -p $sysd_dir
	    ret=$?

	    if [[ $ret -ne 0 ]]
	    then
		echo "ERROR: on  >> # mkdir $sysd_dir << , EXITING..\n" >> $outfile
		echo "$log_stamp ERROR on >> #mkdir $sysd_dir << , EXITING...."
		exit
	    fi
	fi
    fi

    cp $0 $sysd_dir		# handle if users renamed sys_diag

    if [[ -f $infile ]]
    then
	cp $infile $sysd_dir
    fi

    echo "$log_stamp # Creating ... README_sys_diag.txt ..."

    make_README $sysd_dir $DEBUG	## create the README file


	dash_file="$outfile.dash.html"
	system_file=$sysd_dir'/sysd_sys_'$hname'_'`date '+%y%m%d_%H%M%S'`'.out'
	pkginfo_file=$sysd_dir'/sysd_pkg_'$hname'_'`date '+%y%m%d_%H%M%S'`'.out'

	vmstat_file=$sysd_dir'/sysd_vm_'$hname'_'`date '+%y%m%d_%H%M%S'`'.out'
	mpstat_file=$sysd_dir'/sysd_mp_'$hname'_'`date '+%y%m%d_%H%M%S'`'.out'
	iostat_file=$sysd_dir'/sysd_io_'$hname'_'`date '+%y%m%d_%H%M%S'`'.out'

	analysis_efile=$sysd_dir'/sysd_error_'$hname'_'`date '+%y%m%d_%H%M%S'`'.out'
	analysis_wfile=$sysd_dir'/sysd_warn_'$hname'_'`date '+%y%m%d_%H%M%S'`'.out'

	vmstat_graph_file=$sysd_dir'/sysd_vm_'$hname'_'`date '+%y%m%d_%H%M%S'`'.gr.txt'
fi


if ( [ -f `echo $outfile` ] && ( ! [ -w `echo $outfile` ] ))
then
	echo "$log_stamp  ERROR: $outfile NOT Writeable as : `id`."
	exit
fi

log_stamp='sys_diag:'`date '+%m%d_%H%M%S'`':'
#
############## Start BACKGROUND Processing #################

if [[ $PERF -ne 0 ]]
then
	echo "\nsys_diag: ------- Beginning Process SNAPSHOT (# 0) -------\n"

	if [[ -x /usr/sbin/vxstat ]]		# Reset the Veritas Stats
	then
		/usr/sbin/vxstat -r
	fi

	### capture beginning snap of BME data (ps,lockstat, ..)

	snap_bme_perf $sysd_dir 0 $DEBUG $PERF $VERBOSE 
	sleep 1

	if [[ $interval_secs -ne 0 ]]
	then
		PERF_INTERVAL=$interval_secs
	fi

	if [[ $duration_secs -ne 0 ]]
	then
		PERF_SECS=$duration_secs
	fi

	duration_count=$(( ($PERF_SECS/$PERF_INTERVAL)-($PERF_SECS%$PERF_INTERVAL) ))

	echo "\nsys_diag: --**-- (Background) DATA COLLECTION FOR $PERF_SECS secs STARTED --**--\n"

	start_secs=$SECONDS
	SECONDS=0

  	if [[ ( -x /usr/bin/vmstat ) && ($Solaris_Rev -ge 10) ]]
	then
		echo "$log_stamp # /usr/bin/vmstat -q $PERF_INTERVAL $duration_count > $vmstat_file 2>&1 &"
		/usr/bin/vmstat -q $PERF_INTERVAL $duration_count > $vmstat_file 2>&1 &
		vmpid=$!
	else
		echo "$log_stamp # /usr/bin/vmstat $PERF_INTERVAL $duration_count > $vmstat_file 2>&1 &"
		/usr/bin/vmstat $PERF_INTERVAL $duration_count > $vmstat_file 2>&1 &
		vmpid=$!
	fi

	echo "$log_stamp # /usr/bin/iostat -xn $PERF_INTERVAL $duration_count > $iostat_file 2>&1 &"
	/usr/bin/iostat -s -xn $PERF_INTERVAL $duration_count > $iostat_file 2>&1 &
	iopid=$!

  	if [[ ( -x /usr/bin/mpstat ) && ($Solaris_Rev -ge 10) ]]
	then
		echo "$log_stamp # /usr/bin/mpstat -q $PERF_INTERVAL $duration_count > $mpstat_file 2>&1 &"
		/usr/bin/mpstat -q $PERF_INTERVAL $duration_count > $mpstat_file 2>&1 &
		mppid=$!
	else
		echo "$log_stamp # /usr/bin/mpstat $PERF_INTERVAL $duration_count > $mpstat_file 2>&1 &"
		/usr/bin/mpstat $PERF_INTERVAL $duration_count > $mpstat_file 2>&1 &
		mppid=$!
	fi

	num_nets=0

	for i in `/usr/sbin/ifconfig -a |  grep ": " | cut -d":" -f1`
	do

		if [[ ( $i = $last_nic ) && ( $num_nets -gt 0 ) ]]
		then
			continue	# Logical Layered Virtual NIC Interface, skip..
		else
			last_nic=$i
		fi
    		log_stamp='sys_diag:'`date '+%m%d_%H%M%S'`':'

   		num_nets=$(($num_nets+1))
		netstat_file=$sysd_dir'/sysd_net'$num_nets'_'`uname -n`'_'`date '+%y%m%d_%H%M%S'`'.out'
		echo "$log_stamp # /usr/bin/netstat -i -I $i $PERF_INTERVAL $duration_count > $netstat_file 2>&1 &"
		/usr/bin/netstat -i -I $i $PERF_INTERVAL $duration_count > $netstat_file 2>&1 &
		netpid[$num_nets]=$!

		kstat_file=$sysd_dir'/sysd_knetb_'$i'_'`uname -n`'_'`date '+%y%m%d_%H%M%S'`'.out'
		echo "$log_stamp # /usr/bin/kstat -p -T u -n $i 1> $kstat_file 2>&1"
		/usr/bin/kstat -p -T u -n $i 1> $kstat_file 2>&1
	done

	if [[ ( $VERBOSE -ne 0 ) || ( $NETWORK -ne 0 ) ]]
	then
		snoop_pkts=300		# SNOOP on next 300 packets..

		echo "\n" >> $outfile			
		echo "# /usr/sbin/snoop -c $snoop_pkts\n" >> $outfile
		echo "$log_stamp # /usr/sbin/snoop ..."

		snoop_file=$sysd_dir'/sysd_snoop_'`uname -n`'_'`date '+%y%m%d_%H%M%S'`'.out'
		/usr/sbin/snoop -c $snoop_pkts > $snoop_file 2>&1 &
		snooppid=$!

#		/usr/sbin/snoop -d nf0 -c 100 >> $outfile
#
#		for i in `/usr/sbin/ifconfig -a |  grep : | cut -d: -f1`
#		do
#			/usr/sbin/snoop -V -d $i -c 300 >> $outfile
#		done
	fi

	num_llts=0

	if [[ -x /sbin/lltstat ]]	# VCS LLT interconnect stats
	then
	    /sbin/lltstat -z	# RESET lltstat packet Counters to Zero

	    for i in `/sbin/lltstat -P | cut -d ":" -f1 | grep -v LLT` # lists LLT if's..
	    do
   		num_llts=$(($num_llts+1))

 		j=${i%%[0-9]*}    #### device name (ce, ge, hme, qfe..)
		k=${i#$j}	#### device instance (#)

		if [[ $DEBUG -eq 1 ]]
		then
			echo "\n\t$j:$k : num_llts=$num_llts\n"
		fi

# kstat of llts no longer needed with sysd_llt_ file
#
#		kstat_net_file=$sysd_dir'/sysd_llt'$num_llts'_'`uname -n`'_'`date '+%y%m%d_%H%M%S'`'.out'
#		echo "$log_stamp # /usr/bin/kstat -p -c net $j:$k:*:*packets $PERF_INTERVAL $duration_count > $kstat_net_file 2>&1 &" 
#		/usr/bin/kstat -p -c net $j:$k:*:*packets $PERF_INTERVAL $duration_count > $kstat_net_file 2>&1 &

#		kstatpid[$num_llts]=$!
	    done
#	else
#		echo "\n\n\t/sbin/lltstat ** NOT Found **\n\n" > $outfile
	fi

else
    log_stamp='sys_diag:'`date '+%m%d_%H%M%S'`':'

    if [[ ( $POSTPERF -ne 0 ) && ( $SKIP_POSTPERF -eq 0 ) ]]
    then

	############  IF -P and NOT -S, POST Process the Performance data   #################

	post_perf $sysd_dir $outfile $DEBUG $PERF $dash_file $home_dir # Post Processes Perf data .html rpt

	############  Generate .ps output (2 pages / pg landscape)   #################

	if [[ $POST -ne 0 ]]
	then
		outfile_ps="$outfile.ps"
		/usr/openwin/bin/mp -l $outfile > $outfile_ps
	fi

	############  Generate HTML (.html) REPORT ####################

	gen_html_rpt $outfile $html_file $DEBUG $dash_file $PERF $POSTPERF $hname $sysd_dir

	# TAR/Compress performance data and sys_diag report files ($sysd_dir)

	if [[ $TAR -ne 0 ]]
	then

	        echo "\n$log_stamp ## Generating TAR file : $tar_file ..."

		echo "\ttar -cvf $tar_file $sysd_dir 1>/dev/null"
		tar -cvf $tar_file $sysd_dir 1>/dev/null
		ret=$?

		if [[ $ret -eq 0 ]]
		then
			echo "\tcompress $tar_file\n"
			compress $tar_file

			echo "\nData files have been TARed and compressed in :\n\n\t*** $tar_file.Z ***\n\n"

			if (( CLEANUP )); then
				rm -r $sysd_dir
			fi
		fi
	else
		echo "\n** NO Archive was created of $sysd_dir\n\tTo manually create $tar_file.Z type :\n\n"
		echo "\ttar -cvf $tar_file $sysd_dir"
		echo "\tcompress $tar_file\n\n"

	fi

	echo "------- Sys_Diag Complete -------\n\n"

	exit

    fi

fi

############ START FOREGROUND PROCESSING ##################

log_stamp='sys_diag:'`date '+%m%d_%H%M%S'`':'

echo "\nsys_diag: ------- (Foreground) Gathering System Configuration Details -------"

echo "***************************************************************************" > $outfile
echo "* SYS_DIAG v$SYS_DIAG_VER\t\t"`date`" " >> $outfile
echo "*" >> $outfile

echo "* Hostname          :  "`hostname`"\c" >> $outfile

if [[ -x /usr/bin/zonename ]]
then
	echo "\t\t     Zonename :  "`/usr/bin/zonename` >> $outfile
else
	echo "\n" >> $outfile
fi

echo "$log_stamp # uname -a ..."
echo "* uname -a  :\n*\t"`/usr/bin/uname -a`" ">> $outfile

echo "$log_stamp # hostid ..."
echo "*\n* Hostid            :  "`/usr/bin/hostid`"\c " >> $outfile

if [[ -x /usr/bin/isainfo ]]
then
	echo "\t\t     Kernel   :  "`/usr/bin/isainfo -vk` >> $outfile
else
	echo "\n" >> $outfile
fi

echo "$log_stamp # domainname (DNS) ..."
echo "* domainname (DNS)  :  "`/usr/bin/domainname`" " >> $outfile

if [[ -f /etc/ssphostname ]]
then
	echo "$log_stamp # cat /etc/ssphostname ..."
	echo "*\n* ssphostname\t:  "`cat /etc/ssphostname`"*\n" >> $outfile
fi

echo "* uptime          :  $Up_Time" >> $outfile
echo "*\n* UID             :  "`id` >> $outfile
echo "* sys_diag args   :  $CMD_LINE" >> $outfile

echo "*\n* Report Label : $label"  >> $outfile
echo "* Output File  : $outfile" >> $outfile
echo "***************************************************************************" >> $outfile

echo "\n\n\tTABLE OF CONTENTS :\n" >> $outfile
echo "\t\tSection 01> *	System Configuration / Device Information\n" >> $outfile
echo "\t\tSection 02> *	Workload Characterization\n" >> $outfile
echo "\t\tSection 03> *	Peformance Profiling (System / Kernel)\n" >> $outfile
echo "\t\tSection 04> *	Kernel Zones / Tunables/ SRM\n" >> $outfile
echo "\t\tSection 05> *	Storage Device / Array Enclosure Information\n" >> $outfile
echo "\t\tSection 06> *	Volume Manager Information\n" >> $outfile
echo "\t\tSection 07> *	Filesystem Information\n" >> $outfile
echo "\t\tSection 08> *	I/O Statistics\n" >> $outfile
echo "\t\tSection 09> *	NFS Information\n" >> $outfile
echo "\t\tSection 10> *	Networking Information\n" >> $outfile
echo "\t\tSection 11> *	Tty / Modem Configurations\n" >> $outfile
echo "\t\tSection 12> *	User / Account / Group Info\n" >> $outfile
echo "\t\tSection 13> *	Naming Services (NIS/NIS+/...)\n" >> $outfile
echo "\t\tSection 14> *	Security / System Configuration Files\n" >> $outfile
echo "\t\tSection 15> *	Clustering / HA Information\n" >> $outfile
echo "\t\tSection 16> *	Sun N1 SP Configuration\n" >> $outfile
echo "\t\tSection 17> *	Application / Oracle Config Files\n" >> $outfile
echo "\t\tSection 18> *	Packages Installed\n" >> $outfile
echo "\t\tSection 19> *	Patch Information\n" >> $outfile
echo "\t\tSection 20> *	Crontab File Listings\n" >> $outfile
echo "\t\tSection 21> *	FMD / System Messages / Log Files\n" >> $outfile

if [[ $TRACK -ne 0 ]]
then
	echo "\t\tSection 22> *	Asset / Configuration Management -CHANGES-\n" >> $outfile
else
	echo "\t\tSection 22>  	Asset / Configuration Management -CHANGES-\n" >> $outfile
fi

if [[ $PERF -ne 0 ]]
then
	echo "\t\tSection 23> *	System Analysis : Initial Findings / Errors/Warnings\n" >> $outfile
	echo "\t\tSection 24> *	Performance Analysis : Potential Issues" >> $outfile

	if [[ $PERF -ge 1 ]]
	then
	    echo "\t\tSection 25> *	Extended Analysis / Dtrace : Output Files" >> $outfile
	fi
else
	echo "\t\tSection 23>   System Analysis : Initial Findings\n" >> $outfile
	echo "\t\tSection 24>   Performance Analysis : Potential Issues" >> $outfile
	echo "\t\tSection 25>  	Extended Analysis / Dtrace : Output Files" >> $outfile
fi

#######################  SYSTEM CONFIGURATION / DEVICE INFO   #####################

echo "\n$log_stamp ######  SYSTEM CONFIGURATION / DEVICE INFO  ######"
echo "" >> $outfile
echo "## 01 ################  SYSTEM CONFIGURATION / DEVICE INFO   ###################\n" >> $outfile

if [[ ($ALL -ne 0) || ($LONG -ne 0) || ($CONFIG -ne 0) || ($TRACK -ne 0) || ($PERF -ne 0) ]]
then
	if [[ -x /usr/platform/`uname -m`/sbin/prtdiag ]]
	then
		echo "# prtdiag\n" >> $outfile
		echo "$log_stamp # prtdiag ..."
		/usr/platform/`uname -m`/sbin/prtdiag -v >> $outfile
	else
		if [[ -x /usr/platform/sun4u/sbin/prtdiag ]]
		then
			echo "# prtdiag\n" >> $outfile
			echo "$log_stamp # prtdiag ..."
			/usr/platform/sun4u/sbin/prtdiag -v >> $outfile
		else
			if [[ -x /usr/platform/sun4u1/sbin/prtdiag ]]
			then
				echo "# prtdiag\n" >> $outfile
				echo "$log_stamp # prtdiag ..."
				/usr/platform/sun4u/sbin/prtdiag -v >> $outfile
			else
				echo "$log_stamp  prtdiag NOT found, skipping\n"
			fi
		fi
	fi
fi

scratch_file=$sysd_dir'/scratch_file'
log_stamp='sys_diag:'`date '+%m%d_%H%M%S'`':'

	if [[ -x /usr/sbin/prtconf ]]
	then
		echo "\n\n" >> $outfile
		echo "# prtconf | grep Memory\n" >> $outfile
		echo "$log_stamp # prtconf | grep Memory ..."
		/usr/sbin/prtconf | grep Memory >> $outfile
		/usr/sbin/prtconf | grep Memory >> $scratch_file
	fi

	if [[ -x /usr/sbin/psrinfo ]]
	then
		echo "# /usr/sbin/psrinfo -v\n" >> $outfile
		echo "$log_stamp # /usr/sbin/psrinfo -v ..."
		/usr/sbin/psrinfo -v >> $outfile

	    if (( $Solaris_Rev > 8 ))
	    then
		echo "\n" >> $outfile
		echo "# /usr/sbin/psrinfo -pv\n" >> $outfile
		echo "$log_stamp # /usr/sbin/psrinfo -pv ..."
		/usr/sbin/psrinfo -pv >> $outfile
	    fi
	fi

	if [[ -x /usr/sbin/psrset ]]
	then
		echo "\n\n# /usr/sbin/psrset -q\n" >> $outfile
		echo "$log_stamp # /usr/sbin/psrset -q ..."
		/usr/sbin/psrset -q >> $outfile
	fi

log_stamp='sys_diag:'`date '+%m%d_%H%M%S'`':'


if [[ $LONG -ne 0 ]] 	# Extended Configuration listing : kernel cage /DR /SAN device listings..
then
    if [[ -x /usr/sbin/cfgadm ]]
    then
	echo "# /usr/sbin/cfgadm -l\n" >> $outfile
	echo "$log_stamp # cfgadm  -l ..."
	/usr/sbin/cfgadm -l >> $outfile

	if [[ $? -eq 2 ]]
	then
		echo "\t/usr/sbin/cfgadm NOT supported on this platform.\n" >> $outfile
		echo "$log_stamp WARNING: /usr/sbin/cfgadm NOT supported on this platform."
	else
	    if (( $Solaris_Rev > 8 ))
	    then
		echo "\n# /usr/sbin/cfgadm -al\n" >> $outfile
		echo "$log_stamp # cfgadm  -al ..."
		/usr/sbin/cfgadm -al >> $outfile

		echo "\n# /usr/sbin/cfgadm -v\n" >> $outfile
		echo "$log_stamp # cfgadm  -v ..."
		/usr/sbin/cfgadm -v >> $outfile

		echo "\n# /usr/sbin/cfgadm -av | grep memory | grep perm \t(Caged Kernel boards) :\n" >> $outfile
		echo "$log_stamp # cfgadm  -av | grep memory | grep perm ..."
		/usr/sbin/cfgadm -av | grep memory | grep perm >> $outfile
	    fi
	fi

    else
	echo "\n/usr/sbin/cfgadm NOT found/executable, skipping.\n" >> $outfile
	echo "$log_stamp  /usr/sbin/cfgadm NOT found/executable, skipping.\n"
    fi
fi

################  E10K / SunFire / E25K Device/ SC Info #################
log_stamp='sys_diag:'`date '+%m%d_%H%M%S'`':'

echo "\n$log_stamp ######  E10K / E25K / SunFire System INFO  ######"
echo "" >> $outfile
echo "###############  E10K / E25K / SunFire System Information  ##############\n\n" >> $outfile

if [[ -d /opt/SUNWssp ]]			# E10K / SSP domain info
then
	echo "\n" >> $outfile
	echo "# domain_status\n" >> $outfile
	echo "$log_stamp # domain_status ..."
	domain_status >> $outfile

	echo "\n" >> $outfile
	echo "# domain_history\n" >> $outfile
	echo "$log_stamp # domain_history..."
	domain_history >> $outfile
else
	echo "\n\n/opt/SUNWssp NOT found, skipping.\n" >> $outfile
#	echo "$log_stamp  /opt/SUNWssp NOT found, skipping.\n"
fi

# test to see if on an SC .... or could look for /opt/SUNWSMS
#	interface=`/usr/sbin/ifconfig -a | grep scman`
#	if [ $? -eq 0 ]

if [[ -d /opt/SUNWSMS/bin ]] 	# E25K / SC domain info
then

#	if [ $PROMPT -ne 0 ] && [ $User_Name != "sms-svc" ] 
#	then
#		echo "Please enter sms-svc password :"
#		su - sms-svc
#
#		if [ $? -eq 0 ]
#		then
#			sud=1	# su was successfull..
#		fi
#	fi


	echo "\n" >> $outfile
	echo "# /opt/SUNWSMS/bin/showplatform\n" >> $outfile
	echo "$log_stamp # /opt/SUNWSMS/bin/showplatform ..."
	/opt/SUNWSMS/bin/showplatform >> $outfile

	echo "\n" >> $outfile
	echo "# /opt/SUNWSMS/bin/showplatform -v\n" >> $outfile
	echo "$log_stamp # /opt/SUNWSMS/bin/showplatform  -v..."
	/opt/SUNWSMS/bin/showplatform -v >> $outfile

	echo "\n" >> $outfile
	echo "# /opt/SUNWSMS/bin/showboards\n" >> $outfile
	echo "$log_stamp # /opt/SUNWSMS/bin/showboards ..."
	/opt/SUNWSMS/bin/showboards >> $outfile

	echo "" >> $outfile

	for i in `/opt/SUNWSMS/bin/showplatform | grep -i Running | /usr/bin/awk '{ print $1 }' `
	do
		echo "\n# /opt/SUNWSMS/bin/showobpparams -d $i\n" >> $outfile
		echo "$log_stamp # /opt/SUNWSMS/bin/showobpparams -d $i ..."
		/opt/SUNWSMS/bin/showobpparams -d $i >> $outfile
	done

	for i in `/opt/SUNWSMS/bin/showplatform | grep -i "Powered On" | /usr/bin/awk '{ print $1 }' `
	do
		echo "\n# /opt/SUNWSMS/bin/showobpparams -d $i\n" >> $outfile
		echo "$log_stamp # /opt/SUNWSMS/bin/showobpparams -d $i ..."
		/opt/SUNWSMS/bin/showobpparams -d $i >> $outfile
	done

	echo "\n" >> $outfile
	echo "# /opt/SUNWSMS/bin/showfailover -v\n" >> $outfile
	echo "$log_stamp # /opt/SUNWSMS/bin/showfailover -v ..."
	/opt/SUNWSMS/bin/showfailover -v >> $outfile


	if [[ -d /etc/opt/SUNWSMS/config ]]   # E25K / SC IP configs
	then
       	 echo "^L\n" >> $outfile
	 echo "_____________________________________________________\n" >> $outfile
       	 echo "# cat /etc/opt/SUNWSMS/config/MAN.cf\n" >> $outfile
       	 echo "$log_stamp # cat /etc/opt/SUNWSMS/config/MAN.cf ..."
       	 cat /etc/opt/SUNWSMS/config/MAN.cf >> $outfile
	 echo "_____________________________________________________\n" >> $outfile
	fi

#	if [ $PROMPT -ne 0 ] && [ $sud -eq 1 ]	# exit back from 'sms-svc'
#	then
#		sud=0
#		exit
#	fi

else
	NOT_SF_SC=1
fi
	
#	kcage=`grep kernel_cage_enable /etc/system | wc -l`
#
#	if [ $kcage -gt 1 ]
#	then
#		kernel_cage_enabled=`grep kernel_cage_enable /etc/system | cut -d"=" -f2`

        	echo "$log_stamp # Checking Kernel Cage settings ..."
        	echo "\n\n# grep kernel_cage_enable /etc/system\n" >> $outfile
		grep kernel_cage_enable /etc/system >> $outfile
        	echo "\n# grep kcage_split /etc/system\n" >> $outfile
		grep kcage_split /etc/system >> $outfile
#	else
#    		echo "  ** Kernel Cage is Disabled ** : DR is not possible **\n\n" >> $outfile
#    		echo "$log_stamp # ** Kernel Cage is Disabled ** : DR is not possible **"
#	fi


	echo "\n" >> $outfile
	echo "# eeprom\n" >> $outfile
	echo "$log_stamp # eeprom ..."
	/usr/sbin/eeprom >> $outfile
	echo "_____________________________________________________\n" >> $outfile

	if [[ -x /usr/bin/coreadm ]]		# core config..
	then
		echo "\n" >> $outfile
		echo "# /usr/bin/coreadm\n" >> $outfile
		echo "$log_stamp # /usr/bin/coreadm ..."
		/usr/bin/coreadm >> $outfile
		echo "_____________________________________________________\n" >> $outfile
	fi

	if [[ -x /usr/sbin/dumpadm ]]		# core config..
	then
		echo "\n\n" >> $outfile
		echo "# /usr/sbin/dumpadm\n" >> $outfile
		echo "$log_stamp # /usr/sbin/dumpadm ..."
		/usr/sbin/dumpadm >> $outfile
		echo "_____________________________________________________\n" >> $outfile
	fi

log_stamp='sys_diag:'`date '+%m%d_%H%M%S'`':'

if [[ ($LONG -ne 0) || ($VERBOSE -ne 0) ]]
then
        echo "\n" >> $outfile
        echo "# modinfo\n" >> $outfile
        echo "$log_stamp # modinfo ..."
        /usr/sbin/modinfo >> $outfile
	echo "_____________________________________________________\n" >> $outfile

	if [[ -f /etc/bootparams ]]	# diskless client bootparams..
	then
	    	echo "\n" >> $outfile
	    	echo "# cat /etc/bootparams\n" >> $outfile
	    	echo "$log_stamp # cat /etc/bootparams ..."
	    	cat /etc/bootparams >> $outfile
		echo "_____________________________________________________\n" >> $outfile
	fi

	if [[ -x /usr/sbin/lustatus ]]
	then
	    	echo "# /usr/sbin/lustatus\n" >> $outfile
	    	echo "$log_stamp # /usr/sbin/lustatus ..."
		/usr/sbin/lustatus 1>> $outfile 2>&1
		echo "_____________________________________________________\n" >> $outfile
	fi

	if [[ -d /export*/install ]]	  #### Local Jumpstart images..
	then
		echo "\n$log_stamp ### Probing Local Install / Jumpstart Images..."
		echo "" >> $outfile
		echo "\n\n#############  Local Jumpstart.. Install Images  ###########\n\n" >> $outfile
		echo "# ls -l /export*/install/*/*\n" >> $outfile
		echo "$log_stamp # ls -l /export*/install/*/* ..."
		ls -l /export*/install/*/* >> $outfile
		echo "_____________________________________________________\n" >> $outfile

		if [[ -f /export/*/*/sysidcfg ]]
		then
			echo "^L" >> $outfile
			echo "\n\n\t######  /export/*/*/sysidcfg   #####\n\n" >> $outfile
			echo "# cat /export/*/*/sysidcfg\n" >> $outfile
			echo "$log_stamp # cat /export/*/*/sysidcfg ..."
			cat /export/*/*/sysidcfg >> $outfile
			echo "_____________________________________________________\n" >> $outfile
		fi

		if [[ -f /export/install/profile/sysidcfg ]]
		then
			echo "^L" >> $outfile
			echo "\n\n\t######  /export/install/profile/sysidcfg   #####\n\n" >> $outfile
			echo "# cat /export/install/profile/sysidcfg\n" >> $outfile
			echo "$log_stamp # cat /export/install/profile/sysidcfg ..."
			cat /export/install/profile/sysidcfg >> $outfile
			echo "_____________________________________________________\n" >> $outfile
		fi

		if [[ -f /export/install/profile/rules ]]
                then
                        echo "^L" >> $outfile
                        echo "\n\n\t######  /export/install/profile/rules   #####\n\n" >> $outfile
                        echo "# cat /export/install/profile/rules\n" >> $outfile
                        echo "$log_stamp # cat /export/install/profile/rules ..."
                        cat /export/install/profile/rules >> $outfile
			echo "_____________________________________________________\n" >> $outfile
                fi
	fi

	if [[ ( $VERBOSE -ne 0 ) && ( -f /etc/path_to_inst ) ]]
	then

	    echo "\n" >> $outfile
	    echo "_____________________________________________________\n" >> $outfile
	    echo "# cat /etc/path_to_inst\n" >> $outfile
	    echo "$log_stamp # cat /etc/path_to_inst ..."
	    cat /etc/path_to_inst >> $outfile
	    echo "_____________________________________________________\n" >> $outfile

	fi

fi

log_stamp='sys_diag:'`date '+%m%d_%H%M%S'`':'


########################  WORKLOAD CHARACTERIZATION / PERFORMANCE PROFILING ###################

if [[ ( $ALL -ne 0 ) || ( $PERF -ne 0 ) ]]
then
	echo "\n" >> $outfile
	echo "\n$log_stamp ######  WORKLOAD CHARACTERIZATION  ######"
	echo "## 02 ##################  WORKLOAD CHARACTERIZATION ##################\n\n" >> $outfile
	log_stamp='sys_diag:'`date '+%m%d_%H%M%S'`':'

# Only do this section if LONG rpt or PERF Details needed..

    if [[ ( $LONG -ne 0 ) || ( $PERF -ne 0 ) ]]
    then

	if [[ -x /usr/bin/prstat ]]
	then
		prstat_file=$sysd_dir'/sysd_prstat_'`uname -n`'_'`date '+%y%m%d_%H%M%S'`'.out'
		/usr/bin/prstat -n 5 -c -a 1 1 >> $prstat_file

		echo "\n$log_stamp # prstat -c -a 1 1 \n" >> $outfile
		echo "$log_stamp # prstat -c -a 1 1 ..."
		/usr/bin/prstat -c -a 1 1 >> $outfile

		log_stamp='sys_diag:'`date '+%m%d_%H%M%S'`':'

		echo "\n_____________________________________________________\n" >> $outfile
		echo "\n$log_stamp # prstat -c -J 1 1 \n" >> $outfile
		echo "$log_stamp # prstat -c -J 1 1 ..."
		/usr/bin/prstat -c -J 1 1 >> $outfile

		log_stamp='sys_diag:'`date '+%m%d_%H%M%S'`':'

		if (( $Solaris_Rev >= 10 ))
		then
			echo "\n_____________________________________________________\n" >> $outfile
			echo "\n$log_stamp # prstat -c -Z 1 1 \n" >> $outfile
			echo "$log_stamp # prstat -c -Z 1 1 ..."
			/usr/bin/prstat -c -Z 1 1 >> $outfile
		fi

		log_stamp='sys_diag:'`date '+%m%d_%H%M%S'`':'

		echo "\n_____________________________________________________\n" >> $outfile
		echo "\n$log_stamp # prstat -c 1 2 \n" >> $outfile
		echo "$log_stamp # prstat -c 1 2 ..."
		/usr/bin/prstat -c 1 2 >> $outfile

		log_stamp='sys_diag:'`date '+%m%d_%H%M%S'`':'

		echo "\n_____________________________________________________\n" >> $outfile
		echo "\n$log_stamp # prstat -c -v 1 3\n" >> $outfile
		echo "$log_stamp # prstat -c -v 1 3 ..."
		/usr/bin/prstat -c -v 1 3 >> $outfile

	fi

	log_stamp='sys_diag:'`date '+%m%d_%H%M%S'`':'

	if [[ -x /usr/local/bin/top ]]
	then
		echo "" >> $outfile
		echo "\n_____________________________________________________\n" >> $outfile
		echo "# top -S -d1 300 \n" >> $outfile
		echo "$log_stamp # top -S -d1 300 ..."
		/usr/local/bin/top -S -d1 300 >> $outfile

		log_stamp='sys_diag:'`date '+%m%d_%H%M%S'`':'

		echo "" >> $outfile
		echo "\n_____________________________________________________\n" >> $outfile
		echo "# top -S -d1 -ores 100 \n" >> $outfile
		echo "$log_stamp # top -S -d1 -ores 100 ..."
		/usr/local/bin/top -S -d1 -ores 100 >> $outfile
	fi

#
	ps_cpu_file=$sysd_dir'/sysd_PSc_'`uname -n`'_'`date '+%y%m%d_%H%M%S'`'.out'
	ps_mem_file=$sysd_dir'/sysd_PSm_'`uname -n`'_'`date '+%y%m%d_%H%M%S'`'.out'
	ps_lwp_file=$sysd_dir'/sysd_lwp_'`uname -n`'_'`date '+%y%m%d_%H%M%S'`'.out'
	log_stamp='sys_diag:'`date '+%m%d_%H%M%S'`':'


	echo "\n_____________________________________________________\n" >> $outfile
	echo "\n\n**** PS by %CPU : listing from file: $ps_cpu_file ****" >> $outfile
        echo "\n\n$log_stamp # ps -e -opcpu,pid,ppid,user,nlwp,pmem,vsz,rss,s,time,stime,pri,nice,args (by %CPU) :\n\n" >> $outfile
        echo "$log_stamp # ps -e -opcpu,pid,ppid,user,nlwp,pmem,vsz,rss,s,time,stime,pri,nice,args (by %CPU) :\n\n" >> $ps_cpu_file
        echo "$log_stamp # ps -e -o ...(by %CPU) ..."
        ps -e -opcpu,pid,ppid,user,nlwp,pmem,vsz,rss,s,time,stime,pri,nice,args | head -1 >> $outfile
        ps -e -opcpu,pid,ppid,user,nlwp,pmem,vsz,rss,s,time,stime,pri,nice,args | head -1 >> $ps_cpu_file
        ps -e -opcpu,pid,ppid,user,nlwp,pmem,vsz,rss,s,time,stime,pri,nice,args | grep -v PPID | sort -r -k 1,1 | head -60 >> $outfile
        ps -e -opcpu,pid,ppid,user,nlwp,pmem,vsz,rss,s,time,stime,pri,nice,args | grep -v PPID | sort -r -k 1,1 >> $ps_cpu_file

	log_stamp='sys_diag:'`date '+%m%d_%H%M%S'`':'

	echo "\n_____________________________________________________\n" >> $outfile
	echo "\n\n**** PS by %MEM : listing from file: $ps_mem_file ****" >> $outfile
        echo "\n\n$log_stamp # ps -e -opmem,pid,ppid,user,nlwp,vsz,rss,s,time,stime,pri,nice,pcpu,args (by %MEM) :\n\n" >> $outfile
        echo "# ps -e -opmem,pid,ppid,user,nlwp,vsz,rss,s,time,stime,pri,nice,pcpu,args (by %MEM) :\n\n" >> $ps_mem_file
        echo "$log_stamp # ps -e -o ...(by %MEM) ..."
        ps -e -opmem,pid,ppid,user,nlwp,vsz,rss,s,time,stime,pri,nice,pcpu,args | head -1 >> $outfile
        ps -e -opmem,pid,ppid,user,nlwp,vsz,rss,s,time,stime,pri,nice,pcpu,args | head -1 >> $ps_mem_file
        ps -e -opmem,pid,ppid,user,nlwp,vsz,rss,s,time,stime,pri,nice,pcpu,args | grep -v PPID | sort -r -k 1,1 | head -60 >> $outfile
        ps -e -opid,ppid,user,nlwp,pmem,vsz,rss,s,time,stime,pri,nice,pcpu,args | grep -v PPID | sort -r -k 1,1 >> $ps_mem_file
	
	log_stamp='sys_diag:'`date '+%m%d_%H%M%S'`':'

	echo "\n_____________________________________________________\n" >> $outfile
	echo "\n\n**** PS by LWPs : listing from file: $ps_lwp_file ****" >> $outfile
        echo "\n\n$log_stamp # ps -e -onlwp,pid,ppid,user,pmem,vsz,rss,s,time,stime,pri,nice,pcpu,args (by LWP) :\n\n" >> $outfile
        echo "# ps -e -onlwp,pid,ppid,user,pmem,vsz,rss,s,time,stime,pri,nice,pcpu,args (by LWP) :\n\n" >> $ps_lwp_file
        echo "$log_stamp # ps -e -o ...(by LWP) ..."
        ps -e -onlwp,pid,ppid,user,pmem,vsz,rss,s,time,stime,pri,nice,pcpu,args | head -1 >> $outfile
        ps -e -onlwp,pid,ppid,user,pmem,vsz,rss,s,time,stime,pri,nice,pcpu,args | head -1 >> $ps_lwp_file
        ps -e -onlwp,pid,ppid,user,pmem,vsz,rss,s,time,stime,pri,nice,pcpu,args | grep -v PPID | sort -r -k 1,1 | head -60 >> $outfile
        ps -e -onlwp,pid,ppid,user,pmem,vsz,rss,s,time,stime,pri,nice,pcpu,args | grep -v PPID | sort -r -k 1,1 >> $ps_lwp_file

########################  PERFORMANCE PROFILING (System / Kernel) ###################

	echo "\n" >> $outfile
	echo "\n$log_stamp ######  PERFORMANCE PROFILING (System / Kernel) ######"
	echo "## 03 ##################  PERFORMANCE PROFILING (System / Kernel) ###################\n\n" >> $outfile

	################ MEMORY RELATED CONFIG / USAGE ######################

	log_stamp='sys_diag:'`date '+%m%d_%H%M%S'`':'

	echo "\n_____________________________________________________\n" >> $outfile
	echo "$log_stamp # vmstat 1 5 \n" >> $outfile
	echo "$log_stamp # vmstat 1 5 ..."
	vmstat 1 5 >> $outfile

	log_stamp='sys_diag:'`date '+%m%d_%H%M%S'`':'

	echo "\n_____________________________________________________\n" >> $outfile
	echo "\n\n$log_stamp # /usr/bin/mpstat 1 3\n" >> $outfile
	echo "$log_stamp # /usr/bin/mpstat 1 3 ..."
	/usr/bin/mpstat 1 3 >> $outfile

	if [[ -x /usr/bin/isainfo ]]
	then
		echo "\n_____________________________________________________\n" >> $outfile
		echo "\n\n$log_stamp # /usr/bin/isainfo -v\n" >> $outfile
		echo "$log_stamp # /usr/bin/isainfo -v ..."
		/usr/bin/isainfo -v >> $outfile
		/usr/bin/isainfo -vk >> $outfile
	fi

	log_stamp='sys_diag:'`date '+%m%d_%H%M%S'`':'

	echo "" >> $outfile
	echo "\n_____________________________________________________\n" >> $outfile
	echo "\n\n**** IPCS Shared Memory listing (Inter Process Communication) ****" >> $outfile
	echo "\n\n$log_stamp # /usr/bin/ipcs -a\n" >> $outfile
	echo "$log_stamp # /usr/bin/ipcs -a ..."
	/usr/bin/ipcs -a >> $outfile

	echo "\n_____________________________________________________\n" >> $outfile
	echo "\n\n**** SWAP SPACE Allocation / Usage ****" >> $outfile
        echo "\n\n# /usr/bin/pagesize\n" >> $outfile
        echo "$log_stamp # /usr/bin/pagesize ..."
        /usr/bin/pagesize >> $outfile

	swapl_file=$sysd_dir'/sysd_swapl_'`uname -n`'_'`date '+%y%m%d_%H%M%S'`'.out'

	echo "\n" >> $outfile
	echo "\n_____________________________________________________\n" >> $outfile
	echo "# /usr/sbin/swap -l\n" >> $outfile

	if [[ -x /usr/sbin/swap ]]
	then
		echo "$log_stamp # swap -l ..."
		/usr/sbin/swap -l >> $outfile
		/usr/sbin/swap -l > $swapl_file
	
        	echo "\n\n\n" >> $outfile
        	echo "# swap -s\n" >> $outfile
        	echo "$log_stamp # swap -s ..."
        	/usr/sbin/swap -s >> $outfile
	fi

#	echo "\n" >> $outfile
#	echo "# mem -p \n" >> $outfile
#	echo "$log_stamp # mem -p ..."
#	mem -p >> $outfile

	log_stamp='sys_diag:'`date '+%m%d_%H%M%S'`':'

	echo "\n_____________________________________________________\n" >> $outfile
	
	if [[ -x /usr/bin/vmstat ]]
	then
		echo "\n\n$log_stamp # /usr/bin/vmstat -s\n" >> $outfile
		echo "$log_stamp # /usr/bin/vmstat -s ..."
		/usr/bin/vmstat -s >> $outfile
		/usr/bin/vmstat -s | grep cache | cut -d"(" -f2 | cut -d")" -f1 >> $scratch_file
	fi

	log_stamp='sys_diag:'`date '+%m%d_%H%M%S'`':'

	if (( $Solaris_Rev < 10 ))
	then
		echo "\n_____________________________________________________\n" >> $outfile
		echo "\n\n**** Kernel Memory listing : System_Pages ****" >> $outfile
        	echo "\n\n# /usr/bin/netstat -k | grep pp_kernel\n" >> $outfile
        	echo "$log_stamp # /usr/bin/netstat -k | grep pp_kernel ..."
        	/usr/bin/netstat -k | grep pp_kernel >> $outfile
	else
		echo "\n_____________________________________________________\n" >> $outfile
		echo "\n\n**** Kernel Memory listing : System_Pages ****" >> $outfile

	    if [[ $PERF -eq 2 ]]
	    then	
		ls -l $sysd_dir/sysd_mdb*.out 1>/dev/null 2>&1
		ret=$?

		if [[ $ret -eq 0 ]]
		then
	    	     for m in $sysd_dir/sysd_mdb*.out
	    	     do
			echo "\n\t>>>>>>>  $m  <<<<<<<<\n" >> $outfile
			cat $m >> $outfile
			echo "\n" >> $outfile
			echo "\n_____________________________________________________\n" >> $outfile
	       	     done
		fi
	    fi

	    log_stamp='sys_diag:'`date '+%m%d_%H%M%S'`':'

            echo "\n\n$log_stamp # /usr/bin/kstat -n system_pages\n" >> $outfile
            echo "$log_stamp # /usr/bin/kstat -n system_pages ..."
            /usr/bin/kstat -n system_pages >> $outfile

	    if [[ $PERF -eq 2 ]]	## if -G
	    then
		echo "\n_____________________________________________________\n" >> $outfile
        	echo "\n\n# /usr/bin/kstat -n vm" >> $outfile
        	echo "$log_stamp # /usr/bin/kstat -n vm ..."
        	/usr/bin/kstat -n vm >> $outfile
	    fi
	fi

	log_stamp='sys_diag:'`date '+%m%d_%H%M%S'`':'

	if [[ -f /opt/RMCmem/bin/prtswap ]]
	then
		echo "\n\n# /opt/RMCmem/bin/prtswap -l\n" >> $outfile
		echo "$log_stamp # prtswap -l ..."
		/opt/RMCmem/bin/prtswap -l >> $outfile
	fi	
	if [[ -x /opt/RMCmem/bin/prtmem ]]
	then
		echo "\n\n# prtmem\n" >> $outfile
		echo "$log_stamp # prtmem ..."
		/opt/RMCmem/bin/prtmem >> $outfile
	fi

	if [[ -x /opt/RMCmem/bin/memps ]]		# FS Cache
	then
		echo "\n\n# memps -m\n" >> $outfile
		echo "$log_stamp # memps -m ..."
		/opt/RMCmem/bin/memps -m >> $outfile
	fi

      log_stamp='sys_diag:'`date '+%m%d_%H%M%S'`':'

      if [[ $PERF -ne 0 ]]
      then

	if [[ ( ( -x /usr/bin/busstat ) && ( $PERF -ge 2 ) ) ]]
	then
		/usr/bin/busstat -l | grep -i axq 1>/dev/null 2>&1

		if [[ $? -eq 0 ]]
		then
        		echo "\n" >> $outfile
			echo "\n_____________________________________________________\n" >> $outfile
        		echo "# busstat -w axq,pic0=cdc_hits,pic1=total_cdc_read 1 1\n" >> $outfile
        		echo "$log_stamp # busstat -w axq,pic0=cdc_hits,pic1=total_cdc_read 1 1 ..."
        		/usr/bin/busstat -w axq,pic0=cdc_hits,pic1=total_cdc_read 1 1 1>> $outfile 2>&1
		else
			/usr/bin/busstat -l 1>> $outfile 2>&1
		fi
	fi

	if [[ ( ( -x /usr/sbin/cpustat ) && ( $PERF -ge 2 ) ) ]]
	then
		echo "\n\n**** CPU STATISTICS : (ITLB/DTLB MISSES, %FP, EC_hits) ****" >> $outfile

		/usr/sbin/cpustat -h | grep ITLB_miss 1>/dev/null 2>&1

		if [[ $? -eq 0 ]]
		then
        	   echo "\n" >> $outfile
		   echo "\n_____________________________________________________\n" >> $outfile
        	   echo "\n# cpustat -c pic0=ITLB_miss,pic1=Instr_cnt,sys 1 2\n" >> $outfile
        	   echo "$log_stamp # cpustat -c pic0=ITLB_miss,pic1=Instr_cnt,sys 1 2 ..."
        	   /usr/sbin/cpustat -c pic0=ITLB_miss,pic1=Instr_cnt,sys 1 2 1>> $outfile 2>&1

        	   echo "\n# cpustat -c pic0=DTLB_miss,pic1=Instr_cnt,sys 1 2\n" >> $outfile
        	   echo "$log_stamp # cpustat -c pic0=DTLB_miss,pic1=Instr_cnt,sys 1 2 ..."
        	   /usr/sbin/cpustat -c pic0=DTLB_miss,pic1=Instr_cnt,sys 1 2 1>> $outfile 2>&1
		else
        	   	echo "\n# cpustat -c pic0=ITLB_miss,pic1=Instr_cnt,sys 1 2 ...FAILED\n" >> $outfile
			/usr/sbin/cpustat -h 1>> $outfile 2>&1
		fi

		/usr/sbin/cpustat -h | grep FP_instr_cnt 1>/dev/null 2>&1

		if [[ $? -eq 0 ]]	## This is US-T1 or >
		then
        		echo "# cpustat -c pic0=FP_instr_cnt,pic1=Instr_cnt,sys 1 2\n" >> $outfile
        		echo "$log_stamp # cpustat -c pic0=FP_instr_cnt,pic1=Instr_cnt,sys 1 2 ..."
        		/usr/sbin/cpustat -c pic0=FP_instr_cnt,pic1=Instr_cnt,sys 1 2 1>> $outfile 2>&1

		    	if [[ $? -ne 0 ]]	## calculate the % Floating Point OPs
		    	then
				#### %FP_operations = 100 * (FP_instr_cnt / Instr_cnt ) ####

#TJTJ	echo $fp_instr_cnt $tot_instr_cnt | /usr/bin/awk '{ fp_cnt=$1 ; num++; num_lines++ } END { printf "Wt=%d Xcal=%d csw=%d icsw=%d migr=%d smtx=%d syscl=%d",(w/num),(xcal/num),(csw/num),(icsw/num),(migr/num),(smtx/num),(syscl/num) }'

        		    cpustat_line=`/usr/sbin/cpustat -c pic0=FP_instr_cnt,pic1=Instr_cnt,sys 1 2 | grep total | tail -1`
			    fp_instr_cnt=$((`echo $cpustat_line | /usr/bin/awk '{ print $4 }'`))
			    tot_instr_cnt=$((`echo $cpustat_line | /usr/bin/awk '{ print $5 }'`))
			    pct_fp_ops=$(($fp_instr_cnt/$tot_instr_cnt))
			    pct_fp_ops=$(($pct_fp_ops*100))

			    echo "\n * NOTE :  $pct_fp_ops % Floating Point Operations ($fp_instr_cnt of $tot_instr_cnt) *\n\n" >> $outfile
		    	fi

			echo "\n____________________________________________________________________\n">> $outfile
		else
        		echo "# cpustat -c pic0=FP_instr_cnt,pic1=Instr_cnt,sys 1 2  ... FAILED\n" >> $outfile
		    	/usr/sbin/cpustat -h | grep FA_pipe_completion 1>/dev/null 2>&1

		    	if [[ $? -eq 0 ]]	## This is > US-III & < T1
		    	then
        		    echo "# cpustat -c pic0=FA_pipe_completion,pic1=Instr_cnt,sys -c pic1=FM_pipe_completion,pic0=Instr_cnt,sys 1 2\n" >> $outfile
        		    echo "$log_stamp # cpustat -c pic0=FA_pipe_completion,pic1=Instr_cnt,sys -c pic1=FM_pipe_completion,pic0=Instr_cnt,sys 1 2 ..."
        		    /usr/sbin/cpustat -c pic0=FA_pipe_completion,pic1=Instr_cnt,sys -c pic0=Instr_cnt,pic1=FM_pipe_completion,sys 1 2 1>> $outfile 2>&1

		    	    if [[ $? -eq 0 ]]	## calculate the % Floating Point OPs
		    	    then
				   #### %FP_operations= 100 * ( (FA_... + FM_... ) / Instr_cnt ) #### 
        		        fm_pipe_line=`/usr/sbin/cpustat -c pic0=FM_pipe_completion,pic1=Instr_cnt,sys 1 2 | grep total | tail -1`
        		        fa_pipe_line=`/usr/sbin/cpustat -c pic0=FA_pipe_completion,pic1=Instr_cnt,sys 1 2 | grep total | tail -1`
			        fm_instr_cnt=$((`echo $fm_pipe_line | /usr/bin/awk '{ print $4 }'`))
			        fa_instr_cnt=$((`echo $fa_pipe_line | /usr/bin/awk '{ print $4 }'`))
			        instr_cnt1=$((`echo $fm_pipe_line | /usr/bin/awk '{ print $5 }'`))
			        instr_cnt2=$((`echo $fa_pipe_line | /usr/bin/awk '{ print $5 }'`))
			        tot_fpinstr_cnt=$(($fm_instr_cnt+$fa_instr_cnt))
			        tot_instr_cnt=$(($instr_cnt1+$instr_cnt2))
			        pct_fp_ops=$(($tot_fpinstr_cnt/$tot_instr_cnt))
			        pct_fp_ops=$(($pct_fp_ops*100))

			        echo "\n * NOTE :  $pct_fp_ops % Floating Point Operations ($tot_fpinstr_cnt of $tot_instr_cnt) *\n\n" >> $outfile
			    fi
			fi
		fi
		/usr/sbin/cpustat -h | grep EC_hit 1>/dev/null 2>&1

		if [[ $? -eq 0 ]]	## calculate US-I/II/IIi E_cache hit ratio
		then
			#### %EC hits = 100 * (EC_hit / EC_ref) ####
        	    cpustat_line=`/usr/sbin/cpustat -c pic0=EC_ref,pic1=EC_hit,sys 1 2 | grep total | tail -1`
		    ec_refs=$((`echo $cpustat_line | /usr/bin/awk '{ print $4 }'`))
		    ec_hits=$((`echo $cpustat_line | /usr/bin/awk '{ print $5 }'`))
		    pct_ec_hits=$(($ec_hits/$ec_refs))
		    pct_ec_hits=$(($pct_ec_hits*100))

		    echo "\n * NOTE :  $pct_ec_hits % E_Cache Hits [EC hit ratio] ($ec_hits of $ec_refs) *\n\n" >> $outfile
		else
		  /usr/sbin/cpustat -h | grep EC_misses 1>/dev/null 2>&1

		  if [[ $? -eq 0 ]]	## calculate the US-III+/IV E_cache hit ratio
		  then
			#### %EC hits = 100 * (EC_hit / EC_ref) ####
        	    cpustat_line=`/usr/sbin/cpustat -c pic0=EC_ref,pic1=EC_misses,sys 1 2 | grep total | tail -1`
		    ec_refs=$((`echo $cpustat_line | /usr/bin/awk '{ print $4 }'`))
		    ec_misses=$((`echo $cpustat_line | /usr/bin/awk '{ print $5 }'`))
		    ec_hits=$(($ec_refs-$ec_misses))
		    pct_ec_hits=$(($ec_hits/$ec_refs))
		    pct_ec_hits=$(($pct_ec_hits*100))

		    echo "\n * NOTE :  $pct_ec_hits % E_Cache Hits [EC hit ratio] ($ec_hits of $ec_refs) *\n\n" >> $outfile
		    echo "\n____________________________________________________________________\n">> $outfile
		  else
		    /usr/sbin/cpustat -h 1>> $outfile 2>&1
		  fi

		fi
	fi

	if [[ -x /usr/sbin/trapstat ]]
	then
	    echo "" >> $outfile
	    echo "\n_____________________________________________________\n" >> $outfile
	    echo "# /usr/sbin/trapstat 1 3\n" >> $outfile
	    echo "\n$log_stamp # /usr/sbin/trapstat 1 2 ..."
	    /usr/sbin/trapstat 1 2 1>> $outfile 2>&1
	    ret=$?

	    if [[ $ret -eq 0 ]]
	    then
		echo "\n\n\n" >> $outfile
		echo "\n_____________________________________________________\n" >> $outfile
		echo "# /usr/sbin/trapstat -t 1 2\n" >> $outfile
		echo "$log_stamp # /usr/sbin/trapstat -t 1 2 ..."
		/usr/sbin/trapstat -t 1 2 >> $outfile
	    fi

	    if [[ ( ( $ret -eq 0 ) && ( $PERF -ge 2 ) ) ]]
	    then
		echo "\n\n\n" >> $outfile
		echo "\n_____________________________________________________\n" >> $outfile
		echo "# /usr/sbin/trapstat -l\n" >> $outfile
		echo "$log_stamp # /usr/sbin/trapstat -l ..."
		/usr/sbin/trapstat -l 1>> $outfile 2>&1

		if [[ $? -eq 0 ]]
		then
			echo "\n\n\n" >> $outfile
			echo "\n_____________________________________________________\n" >> $outfile
			echo "# /usr/sbin/trapstat -t 1 2\n" >> $outfile
			echo "$log_stamp # /usr/sbin/trapstat -t 1 2 ..."
			/usr/sbin/trapstat -t 1 2 >> $outfile

			trapstat_worked=1

			tlb_misses=`/usr/sbin/trapstat -t 1 2 | grep ttl | tail -1 | /usr/bin/awk '{ printf "  NOTE: %s%% CPU cycles handling TLB MISSES  (%s%% ITLB_misses: %s%% DTLB_misses)", $13, $4, $9 }'`
			echo "\n\n$tlb_misses\n\n" >> $outfile
			echo $tlb_misses >> $scratch_file

			echo "\n\n\n" >> $outfile
			echo "\n_____________________________________________________\n" >> $outfile
			echo "# /usr/sbin/trapstat -T 1 2\n" >> $outfile
			echo "$log_stamp # /usr/sbin/trapstat -T 1 2 ..."
			/usr/sbin/trapstat -T 1 2 >> $outfile
		fi
	    fi
	fi

	echo "\n\n**** INTERRUPT STATISTICS : ****" >> $outfile

	if [[ -x /usr/sbin/intrstat ]]
	then
		echo "" >> $outfile
		echo "\n_____________________________________________________\n" >> $outfile
		echo "# /usr/sbin/intrstat\n" >> $outfile
		echo "$log_stamp # /usr/sbin/intrstat 1 2 ..."
		/usr/sbin/intrstat 1 2 >> $outfile
	fi

	if [[ -x /usr/bin/vmstat ]]
	then
		echo "\n_____________________________________________________\n" >> $outfile
		echo "\n\n# /usr/bin/vmstat -i\n" >> $outfile
		echo "$log_stamp # /usr/bin/vmstat -i ..."
		/usr/bin/vmstat -i >> $outfile
	fi

	if [[ -r `echo $sysd/sysd_dintrtm0_*` ]]
	then
		echo "\n_____________________________________________________\n" >> $outfile
		echo "\n  NOTE : ** SEE ALSO the DTRACE Interrupt Statistics ** :\n" >> $outfile
		echo "<pre>\t<a href=\"#Dtrace Int\" class=\"named\">Dtrace Interrupt Stats</a></pre>" >> $outfile
	fi


      fi    # END PERF


    fi

fi


###################  KERNEL ZONES / SRM / Accounting / TUNABLES  ####################

if [[ ( $ALL -ne 0 ) || ( $CONFIG -ne 0 ) || ( $PERF -ne 0 ) ]]
then
	echo "" >> $outfile
	echo "\n$log_stamp ######  KERNEL ZONES/ SRM / Acctg / TUNABLES  ######"
	echo "## 04 ##############  KERNEL ZONES/ SRM/ Acctg / TUNABLES  #################\n\n" >> $outfile

	if [[ -x /usr/sbin/zoneadm ]]	# S10 Zones / Containers ..
	then
		echo "# /usr/sbin/zoneadm list -cv\n" >> $outfile
		echo "$log_stamp # /usr/sbin/zoneadm list -cv ..."
		/usr/sbin/zoneadm list -cv >> $outfile

		for i in `/usr/sbin/zoneadm list -cv | grep -v NAME | grep -v global | awk '{ print $2 }'`
		do
			echo "\n\n\t>>>>>>> Zone : $i : export <<<<<<<<\n" >> $outfile
			/usr/sbin/zonecfg -z $i export >> $outfile
		done
	fi

	if [[ -r /etc/zones/zone1.xml ]]
	then

	    for i in /etc/zones/zone*.xml
	    do
		echo "\n\t>>>>>>>  $i  <<<<<<<<\n" >> $outfile
		cat $i >> $outfile
		echo "\n" >> $outfile
		echo "\n_____________________________________________________\n" >> $outfile
	    done
	fi

	echo "\n_____________________________________________________\n" >> $outfile

	# SRM Projects ..

	if [[ ( -x /usr/bin/projects )  &&  ($Solaris_Rev -ge 10) ]]
	then
		echo "\n# /usr/bin/projects -l \n" >> $outfile
		echo "$log_stamp # /usr/bin/projects -l ..."
		/usr/bin/projects -l >> $outfile
	elif [[ ( -x /usr/bin/projects )  &&  ($Solaris_Rev -ge 8) ]]
	then
		echo "\n# /usr/bin/projects -v \n" >> $outfile
		echo "$log_stamp # /usr/bin/projects -v ..."
		/usr/bin/projects -v >> $outfile
	fi

	if [[ ( -x /usr/sbin/psrset ) ]]
	then
	    echo "\n\n# /usr/sbin/psrset -i\n" >> $outfile
	    echo "$log_stamp # /usr/sbin/psrset -i ..."
	    /usr/sbin/psrset -i >> $outfile

	    echo "\n\n# /usr/sbin/psrset -p\n" >> $outfile
	    echo "$log_stamp # /usr/sbin/psrset -p ..."
	    /usr/sbin/psrset -p >> $outfile

	    echo "\n\n# /usr/sbin/psrset -q\n" >> $outfile
	    echo "$log_stamp # /usr/sbin/psrset -q ..."
	    /usr/sbin/psrset -q >> $outfile
	fi

	if [[ -f /etc/pooladm.conf ]]
	then
	    echo "\n\n# cat /etc/pooladm.conf\n" >> $outfile
	    echo "$log_stamp # cat /etc/pooladm.conf ..."
	    cat /etc/pooladm.conf >> $outfile
	fi

        if [[ ( -x /usr/bin/svcs ) && ( -x /usr/bin/rcapstat ) ]]	# S10 SSM : Resource cap stats
        then
		rcap_online=`/usr/bin/svcs -av | grep -n rcap | /usr/bin/awk '{ print $1 }'`

		if [[ $rcap_online = "online" ]]
		then
			echo "\n" >> $outfile
			echo "# /usr/bin/rcapstat -g 1 5 \n" >> $outfile
			echo "$log_stamp # /usr/bin/rcapstat -g 1 5 ..."
			/usr/bin/rcapstat -g 1 5 >> $outfile

			echo "# /usr/bin/rcapstat 1 5 \n" >> $outfile
			echo "$log_stamp # /usr/bin/rcapstat 1 5 ..."
			/usr/bin/rcapstat 1 5 >> $outfile
		fi
        fi


	if [[ -x /usr/sbin/rctladm ]]	# SRM/OS resource controls ..
	then
		echo "\n\n# /usr/sbin/rctladm -l \n" >> $outfile
		echo "$log_stamp # /usr/sbin/rctladm -l ..."
		/usr/sbin/rctladm -l >> $outfile
	fi

	if [[ -x /usr/bin/priocntl ]]	# SRM/OS Class Priorities ..
	then
		echo "\n\n# /usr/bin/priocntl -l \n" >> $outfile
		echo "$log_stamp # /usr/bin/priocntl -l ..."
		/usr/bin/priocntl -l >> $outfile
	fi
	echo "\n_____________________________________________________\n" >> $outfile

	if [[ -x /usr/sbin/acctadm ]]	# Accounting ..
	then
		echo "\n\n# /usr/sbin/acctadm \n" >> $outfile
		echo "$log_stamp # /usr/sbin/acctadm ..."
		/usr/sbin/acctadm >> $outfile
	fi

	if [[ -x /usr/sbin/acctadm ]]	# Accounting ..
	then
		echo "\n\n# /usr/sbin/acctadm -r\n" >> $outfile
		echo "$log_stamp # /usr/sbin/acctadm -r..."
		/usr/sbin/acctadm -r >> $outfile
	fi

	echo "" >> $outfile
	echo "_____________________________________________________\n" >> $outfile
	echo "# tail -80 /etc/system \n" >> $outfile
	echo "$log_stamp # tail -80 /etc/system ..."
	tail -80 /etc/system >> $outfile
	cat /etc/system >> $system_file
	echo "_____________________________________________________\n" >> $outfile

	if [[ -x /usr/sbin/sysdef ]]
	then
        	echo "\n" >> $outfile
        	echo "# sysdef | tail -85\n" >> $outfile
        	echo "$log_stamp # sysdef  | tail -85 ..."
        	/usr/sbin/sysdef | tail -85 >> $outfile
		echo "_____________________________________________________\n" >> $outfile
	fi


     if [[ LONG -ne 0 ]]
     then
	echo "" >> $outfile
	echo "# tail -40 /etc/init.d/sysetup \n\n" >> $outfile
	echo "$log_stamp # tail -40 /etc/init.d/sysetup ..."
	tail -40 /etc/init.d/sysetup >> $outfile
	echo "_____________________________________________________\n" >> $outfile

 	if [[ -f /etc/power.conf ]]	# Solaris Power Management
 	then
		echo "" >> $outfile
		echo "# cat /etc/power.conf\n" >> $outfile
		echo "$log_stamp # cat /etc/power.conf ..."
		cat /etc/power.conf >> $outfile
		echo "_____________________________________________________\n" >> $outfile
 	fi
     fi

fi

#################   STORAGE / VOLUME MANAGER INFO    ##################

log_stamp='sys_diag:'`date '+%m%d_%H%M%S'`':'

if [[ ( $ALL -ne 0 ) || ( $CONFIG -ne 0 ) || ( $IO -ne 0 ) ]]
then
	echo "" >> $outfile
	echo "\n$log_stamp ######  STORAGE / ARRAY INFO  ######"
	echo "## 05 ###############  STORAGE / ARRAY ENCLOSURE INFO  ###############\n\n" >> $outfile
     if [ $LONG -ne 0 ]   ## IF -l LONG report, then show format, luxadm,...
     then

#	if [ $PROMPT -ne 0 ] && [ $User_Name != "root" ]  # su to 'root'
#	then
#		echo "Please enter Root Password :"
#		su - root
#
#		if [ $? -eq 0 ]
#		then
#			sud=1	# su was successfull..
#		fi
#	fi

	echo "# /usr/sbin/format\n" >> $outfile
	/usr/sbin/format -m << @EOI >> $outfile 2>&1
0
verify
disk 1
verify
disk 2
verify
disk 3
verify
disk 4
verify
disk 5
verify
disk 6
verify
quit
@EOI
	echo "\n" >> $outfile
	echo "\n" >> $outfile

#	if [ $PROMPT -ne 0 ] && [ $sud -eq 1 ]  # exit back from 'root'
#	then
#		sud=0
#		exit
#	fi

	echo "# prtconf -pv     {root/boot/disk DEVICES}\n" >> $outfile
	echo "$log_stamp # prtconf -pv ..."
	/usr/sbin/prtconf -pv | grep -i root >> $outfile
	/usr/sbin/prtconf -pv | grep -i boot >> $outfile
	/usr/sbin/prtconf -pv | grep -i disk >> $outfile
 
	log_stamp='sys_diag:'`date '+%m%d_%H%M%S'`':'

	if [[ -x /usr/sbin/luxadm ]]
	then
	     echo "\n# luxadm probe\n" >> $outfile
	     echo "$log_stamp # luxadm probe ..."
	     /usr/sbin/luxadm probe 1>> $outfile 2>&1
	     ret=$?

	     if [[ $ret -eq 0 ]]
	     then
		for i in `/usr/sbin/luxadm probe | grep "Name:" | /usr/bin/awk '{ print $2 }' | cut -d":" -f2`
		do
			echo "\n\t>>>>>>>  $i  <<<<<<<<\n" >> $outfile

			echo "# luxadm display $i\n" >> $outfile
			echo "$log_stamp # luxadm display $i ..."
			/usr/sbin/luxadm display $i >> $outfile
		done
	     fi
	else
		echo "\n\nNOTE:  /usr/sbin/luxadm NOT found, skipping.\n" >> $outfile
#		echo "$log_stamp  /usr/sbin/luxadm NOT found, skipping.\n"
	fi

	log_stamp='sys_diag:'`date '+%m%d_%H%M%S'`':'

	if [[ -x /usr/local/bin/lunmap ]]
	then
		echo "\n# /usr/local/bin/lunmap\n" >> $outfile
		echo "$log_stamp # /usr/local/bin/lunmap ..."
		/usr/local/bin/lunmap >> $outfile
	fi

	log_stamp='sys_diag:'`date '+%m%d_%H%M%S'`':'

	if [[ -x /usr/sbin/osa/lad ]]
	then
		echo "\n# /usr/sbin/osa/lad\n" >> $outfile
		echo "$log_stamp # /usr/sbin/osa/lad  ..."
		/usr/sbin/osa/lad >> $outfile

		for i in `/usr/sbin/osa/lad | cut -d" " -f1`
		do
			echo "\n\t>>>>>>>  $i  <<<<<<<<\n" >> $outfile

			echo "# raidutil -c $i -i\n" >> $outfile
			echo "$log_stamp # raidutil -c $i -i ..."
			/usr/sbin/osa/raidutil -c $i -i >> $outfile

			echo "\n\n# rdacutil -i $i\n" >> $outfile
			echo "$log_stamp # rdacutil -i $i ..."
			/usr/sbin/osa/rdacutil -i $i >> $outfile

			echo "\n\n# drivutil -d $i\n" >> $outfile
			echo "$log_stamp # drivutil -d $i ..."
			/usr/sbin/osa/drivutil -d $i >> $outfile

			echo "\n\n# drivutil -i $i\n" >> $outfile
			echo "$log_stamp # drivutil -i $i ..."
			/usr/sbin/osa/drivutil -i $i >> $outfile

			echo "\n\n# drivutil -I $i\n" >> $outfile
			echo "$log_stamp # drivutil -I $i ..."
			/usr/sbin/osa/drivutil -I $i >> $outfile

			echo "\n\n# drivutil -l $i\n" >> $outfile
			echo "$log_stamp # drivutil -l $i ..."
			/usr/sbin/osa/drivutil -l $i >> $outfile
		done

#	else
#		echo "$log_stamp  /usr/sbin/osa/lad  NOT found, skipping.\n"
	fi
     fi		# End If LONG rpt

	log_stamp='sys_diag:'`date '+%m%d_%H%M%S'`':'

	echo "" >> $outfile
	echo "$log_stamp ######  STORAGE VOLUME MANAGEMENT INFO  ######"
	echo "## 06 ################  STORAGE VOLUME MANAGEMENT INFO  ################\n\n" >> $outfile


	if [[ -d /usr/opt/SUNWmd ]]		## Check for SDS 4.x Config
	then

		echo "\n$log_stamp ######  SOLARIS Disk Suite (SDS 4.x) Info  ######"
		echo "\t##  Solaris Disk Suite (SDS 4.x) Info  ##\n\n" >> $outfile

		echo "# /usr/opt/SUNWmd/metadb\n" >> $outfile
		echo "$log_stamp # /usr/opt/SUNWmd/metadb ..."
		/usr/opt/SUNWmd/metadb >> $outfile

		echo "\n# /usr/opt/SUNWmd/metastat\n" >> $outfile
		echo "$log_stamp # /usr/opt/SUNWmd/metastat ..."
		/usr/opt/SUNWmd/metastat >> $outfile
	else
		echo "\n\nNOTE:  /usr/opt/SUNWmd  (SDS 4.x) NOT found, skipping.\n\n" >> $outfile
#		echo "$log_stamp  /usr/opt/SUNWmd  (SDS 4.x) NOT found, skipping.\n"
	fi

	if [[ -f /etc/lvm/md.tab ]]		## Check for SDS/SVM Config
	then
		echo "\n$log_stamp ######  SOLARIS (SDS/SVM) VOLUME MANAGER Info  ######"
		echo "\t##  SOLARIS (SDS/SVM) VOLUME MANAGER Info  ##\n\n" >> $outfile

	    if [[ -x /sbin/metadb ]]
	    then
		echo "# /sbin/metadb\n" >> $outfile
		echo "$log_stamp # /sbin/metadb ..."
		/sbin/metadb 1>> $outfile 2>&1

		echo "\n# /sbin/metastat\n" >> $outfile
		echo "$log_stamp # /sbin/metastat ..."
		/sbin/metastat 1>> $outfile 2>&1

		echo "\n# /sbin/metastat -p\n" >> $outfile
		echo "$log_stamp # /sbin/metastat -p..."
		/sbin/metastat -p 1>> $outfile 2>&1
	    elif [[ -x /usr/sbin/metadb ]]
	    then
		echo "# /usr/sbin/metadb\n" >> $outfile
		echo "$log_stamp # /usr/sbin/metadb ..."
		/usr/sbin/metadb 1>> $outfile 2>&1

		echo "\n# /usr/sbin/metastat -p\n" >> $outfile
		echo "$log_stamp # /usr/sbin/metastat -p..."
		/usr/sbin/metastat -p 1>> $outfile 2>&1
	    fi

	else
		echo "\n\nNOTE:  /etc/lvm/md.tab  (S9 LVM) NOT found, skipping.\n\n" >> $outfile
#		echo "$log_stamp  /etc/lvm/md.tab  (S9 LVM) NOT found, skipping.\n"
	fi


	if [[ -x /usr/sbin/vxdisk ]]
	then
		echo "\t_____________________________________________________\n" >> $outfile
		echo "\n$log_stamp ######  Veritas VOLUME MANAGER Info  ######"
		echo "\n\t##  Veritas VOLUME MANAGER Info  ##\n\n" >> $outfile

	     if [[ -x /usr/sbin/vxlicense ]]
	     then
		echo "# /usr/sbin/vxlicense -p\n" >> $outfile
		echo "$log_stamp # /usr/sbin/vxlicense -p ..."
		/usr/sbin/vxlicense -p >> $outfile
	     elif [[ -x /opt/VRTSvxfs/sbinvxlicense ]]
	     then
		echo "# /opt/VRTSvxfs/sbin/vxlicense -p\n" >> $outfile
		echo "$log_stamp # /opt/VRTSvxfs/sbin/vxlicense -p ..."
		/opt/VRTSvxfs/sbin/vxlicense -p >> $outfile
	     fi
		echo "\n\n# /usr/sbin/vxdisk list\n" >> $outfile
		echo "$log_stamp # /usr/sbin/vxdisk list ..."
		/usr/sbin/vxdisk list >> $outfile
	
		echo "\n" >> $outfile
		echo "# /usr/sbin/vxprint -S\n" >> $outfile
		echo "$log_stamp # /usr/sbin/vxprint -S ..."
		/usr/sbin/vxprint -S >> $outfile

		echo "\n" >> $outfile
		echo "# /usr/sbin/vxprint -Ath\n" >> $outfile
		echo "$log_stamp # /usr/sbin/vxprint -Ath ..."
		/usr/sbin/vxprint -Ath >> $outfile

		if [[ -x /opt/VRTSvxfs/sbin/vxtunefs ]]
		then
			for i in `df | grep -i "dev/vx/dsk" | cut -d" " -f1`
			do
				echo "\n" >> $outfile
				echo "# /opt/VRTSvxfs/sbin/vxtunefs "$i"\n" >> $outfile
				echo "$log_stamp # /opt/VRTSvxfs/sbin/vxtunefs "$i" ..."
				/opt/VRTSvxfs/sbin/vxtunefs $i >> $outfile
			done
		elif [[ -x /usr/sbin/vxtunefs ]]
		then
			for i in `df | grep -i "dev/vx/dsk" | cut -d" " -f1`
			do
				echo "\n" >> $outfile
				echo "# /usr/sbin/vxtunefs "$i"\n" >> $outfile
				echo "$log_stamp # /usr/sbin/vxtunefs "$i" ..."
				/usr/sbin/vxtunefs $i >> $outfile
			done
		fi

		echo "\n" >> $outfile
		echo "# /usr/sbin/vxdmpadm listctlr all\n" >> $outfile
		echo "$log_stamp # /usr/sbin/vxdmpadm listctlr all ..."
		/usr/sbin/vxdmpadm listctlr all >> $outfile

	else
		echo "\n\nNOTE:  /usr/sbin/vxdisk NOT found, skipping VX.\n\n" >> $outfile
#		echo "$log_stamp  /usr/sbin/vxdisk NOT found, skipping VX.\n"
	fi


	if [[ -x /usr/sbin/zpool ]]			## Solaris 10 ZFS 
	then
		echo "\n\n**** ZFS Configuration Details ***" >> $outfile

		echo "\n\n# /usr/sbin/zpool list\n" >> $outfile
		echo "$log_stamp # /usr/sbin/zpool list ..."
		/usr/sbin/zpool list >> $outfile

		echo "\n\n# /usr/sbin/zfs list\n" >> $outfile
		echo "$log_stamp # /usr/sbin/zfs list ..."
		/usr/sbin/zfs list >> $outfile

		echo "\n\n# /usr/sbin/zpool status -v\n" >> $outfile
		echo "$log_stamp # /usr/sbin/zpool status -v ..."
		/usr/sbin/zpool status -v >> $outfile

		echo "\n\n# /usr/sbin/zpool iostat -v 1 10\n" >> $outfile
		echo "$log_stamp # /usr/sbin/zpool iostat -v 1 10 ..."
		/usr/sbin/zpool iostat -v 1 10 >> $outfile
	fi

	#
	# NOTE: these commands run in the TS dispatcher class
	#
	#do ODM and QIO and vxfsstat
	#
#	if [ -x /opt/VRTS/bin/odmstat ]
#	then
#		priocntl -e -c TS /opt/VRTS/bin/odmstat -i 1 -c 5 -o local >> $outfile
#	fi

#	if [ -x /opt/VRTS/bin/qiostat ]
#	then
#      		priocntl -e -c TS /opt/VRTS/bin/qiostat -i 1 -c 5 -l -o local >> $outfile
#	fi

				## Check for Sun SAN FndaSuite/STMS/MPxIO
	if [[ $LONG -ne 0 ]]
	then
	    if [[ -f /kernel/drv/fp.conf ]]
	    then
		echo "_____________________________________________________\n" >> $outfile
		echo "\n$log_stamp ######  Sun STMS / MPxIO Info  ######"
		echo "\t##  Sun STMS / MPxIO Info  ##\n\n" >> $outfile

		echo "# cat /kernel/drv/fp.conf\n" >> $outfile
		echo "$log_stamp # cat /kernel/drv/fp.conf ..."
		cat /kernel/drv/fp.conf >> $outfile
		echo "_____________________________________________________\n" >> $outfile

		if [[ -f /kernel/drv/fcp.conf ]]	## 
		then
			echo "# cat /kernel/drv/fcp.conf\n" >> $outfile
			echo "$log_stamp # cat /kernel/drv/fcp.conf ..."
			cat /kernel/drv/fcp.conf >> $outfile
		echo "_____________________________________________________\n" >> $outfile
		fi

		if [[ -f /kernel/drv/scsi*vhci.conf ]]	## 
		then
			echo "# cat /kernel/drv/scsi*vhci.conf\n" >> $outfile
			echo "$log_stamp # cat /kernel/drv/scsi*vhci.conf ..."
			cat /kernel/drv/scsi*vhci.conf >> $outfile
		fi
	    else
		echo "\n\nNOTE:  /kernel/drv/fp.conf (MPxIO) NOT found, skipping.\n\n" >> $outfile
#		echo "$log_stamp  /kernel/drv/fp.conf (MPxIO) NOT found, skipping.\n"
	    fi
	fi

fi


#######################  FILESYSTEM INFO ##########################

if [[ ( $ALL -ne 0 ) || ( $CONFIG -ne 0 ) || ( $IO -ne 0 ) ]]
then
	echo "" >> $outfile
	echo "\n$log_stamp ######  FILESYSTEM INFO  ######"
	echo "## 07 #################  FILESYSTEM INFO ##########################\n\n" >> $outfile

	echo "# df\n" >> $outfile
	echo "$log_stamp # df ..."
	df >> $outfile

	echo "\n\n# df -k\n" >> $outfile
	echo "$log_stamp # df -k ..."
	df -k >> $outfile

	echo "\n" >> $outfile
	echo "# /usr/sbin/mount -v\n" >> $outfile
	echo "$log_stamp # mount -v ..."
	/usr/sbin/mount -v >> $outfile

	echo "\n" >> $outfile
	echo "# /usr/sbin/showmount -a\n" >> $outfile
	echo "$log_stamp # /usr/sbin/showmount -a ..."
	/usr/sbin/showmount -a 1>> $outfile 2>&1

	echo "" >> $outfile
	echo "_____________________________________________________\n" >> $outfile
	echo "# cat /etc/vfstab\n" >> $outfile
	echo "$log_stamp # cat /etc/vfstab ..."
	cat /etc/vfstab >> $outfile
	echo "_____________________________________________________\n" >> $outfile

	# Clusr logical /..../vfstab.logical_host files ..

	if [[ -d /etc/opt/SUNWcluster/conf/hanfs ]]
	then
	   	echo "\n" >> $outfile
	   	echo "# cat /etc/opt/SUNWcluster/conf/hanfs/vfstab...\n" >> $outfile
	   	echo "$log_stamp # cat /etc/opt/SUNWcluster/conf/hanfs/vfstab ..."
		for i in /etc/opt/SUNWcluster/conf/hanfs/vfstab.*
		do
			echo "\n\t>>>>>>>  $i  <<<<<<<<\n" >> $outfile
			cat $i >> $outfile
			echo "_____________________________________________________\n" >> $outfile
			echo "\n" >> $outfile
		done
	fi

	if [[ -f /usr/bin/cachefsstat ]]
	then
		echo "\n" >> $outfile
		echo "#  /usr/bin/cachefsstat\n" >> $outfile
		echo "$log_stamp # /usr/bin/cachefsstat ..."
		/usr/bin/cachefsstat >> $outfile
	fi	

fi


############################    I/O STATS    #############################

if [[ ( $ALL -ne 0 ) || ( $PERF -ne 0 ) || ( $IO -ne 0 ) ]]
then
	echo "" >> $outfile
	echo "\n$log_stamp ######  I/O STATS  ######"
	echo "## 08 ######################    I/O STATS    #############################\n\n" >> $outfile
	if [[ -x /usr/bin/iostat ]]
	then
		echo "# /usr/bin/iostat -nxe 3 2\n" >> $outfile
		echo "$log_stamp # /usr/bin/iostat -nxe 3 2 ..."
		/usr/bin/iostat -nxe 3 2 >> $outfile
	fi

	if [[ $? -ne 0 ]]
	then
		echo "\n\tERROR: You need to install an iostat patch..\n"
		echo "\t\tiostat is being re-run using only -x option\n"
		echo "\n\tERROR: You need to install an iostat patch\n" >> $outfile
		/usr/bin/iostat -x 3 2 >> $outfile
		echo "\n\n" >> $outfile
	else
		echo "\n\n\n# /usr/bin/iostat -xcC 3 2\n" >> $outfile
		echo "$log_stamp # /usr/bin/iostat -xcC 3 2 ..."
		/usr/bin/iostat -xcC 3 2 >> $outfile

		echo "\n\n\n# /usr/bin/iostat -xnE \n" >> $outfile
		echo "$log_stamp # /usr/bin/iostat -xnE ..."
		/usr/bin/iostat -xnE >> $outfile
	fi

	if [[ ( ( -x /usr/sbin/vxprint ) && ( $PERF -ne 0 ) ) ]]
	then
	    for i in `/usr/sbin/vxprint -S | grep Disk | cut -c13-`
	    do
# TJ Possibly change this from -c 5 to -c 1 so that the data can be parsed more easily..
		echo "$log_stamp # /usr/sbin/vxstat -g "$i" -i 1 -c 5 ..."
		echo "\n\n\n# /usr/sbin/vxstat -g $i -i 1 -c 3\n" >> $outfile
		/usr/sbin/vxstat -g $i -i 1 -c 3 >> $outfile
	    done
	fi
		
fi


############################   NFS INFO   ################################

if [[ ( $ALL -ne 0 ) || ( $PERF -ne 0 ) || ( $IO -ne 0 ) ]]
then
	echo "\n" >> $outfile
	echo "\n$log_stamp ######  NFS INFO  ######"
	echo "## 09 ######################   NFS INFO   ################################\n\n" >> $outfile
	echo "# /usr/bin/nfsstat\n" >> $outfile
	echo "$log_stamp # /usr/bin/nfsstat ..."
	/usr/bin/nfsstat >> $outfile

	echo "\n" >> $outfile
	echo "# /usr/bin/nfsstat -m\n" >> $outfile
	echo "$log_stamp # /usr/bin/nfsstat -m ..."
	/usr/bin/nfsstat -m >> $outfile
fi


#########################   NETWORKING INFO   ############################


if [[ ( $ALL -ne 0 ) || ( $PERF -ne 0 ) || ( $NETWORK -ne 0 ) ]]
then
	echo "" >> $outfile
	echo "\n$log_stamp ######  NETWORKING INFO  ######"
	echo "## 10 ###################   NETWORKING INFO   ############################\n\n" >> $outfile

   	if [[ -f /etc/hosts ]]
   	then
		echo "# cat /etc/hosts\n" >> $outfile
		echo "$log_stamp # cat /etc/hosts ..."
		cat /etc/hosts >> $outfile
		echo "\n_____________________________________________________\n" >> $outfile
	fi

	ifcfg_file=$sysd_dir'/sysd_ifcfg_'`uname -n`'_'`date '+%y%m%d_%H%M'`'.out'

	echo "\n\n# /usr/sbin/ifconfig -a\n" >> $outfile
	echo "$log_stamp # /usr/sbin/ifconfig -a ..."
	/usr/sbin/ifconfig -a >> $outfile
	/usr/sbin/ifconfig -a >> $ifcfg_file

	echo "\n_____________________________________________________\n" >> $outfile
	echo "# /usr/bin/netstat -i\n" >> $outfile
	echo "$log_stamp # /usr/bin/netstat -i ..."
	/usr/bin/netstat -i >> $outfile

	echo "\n_____________________________________________________\n" >> $outfile
	echo "\n\n# /usr/bin/netstat -r\n" >> $outfile
	echo "$log_stamp # /usr/bin/netstat -r ..."
	/usr/bin/netstat -r >> $outfile

	echo "\n\n# /usr/sbin/arp -a\n" >> $outfile
	echo "$log_stamp # /usr/sbin/arp -a ..."
	/usr/sbin/arp -a >> $outfile

	echo "\n_____________________________________________________\n" >> $outfile

	if [[ ( ( $VERBOSE -ne 0 ) || ( $NETWORK -ne 0 ) ) ]]
	then
		echo "\n\n# /usr/sbin/ping -s `netstat -r | grep default | /usr/bin/awk '{ print $2 }'` 56 10\n" >> $outfile
		echo "$log_stamp # /usr/sbin/ping -s `netstat -r | grep default | /usr/bin/awk '{ print $2 }'` 56 10 ..."
		/usr/sbin/ping -s `netstat -r | grep default | /usr/bin/awk '{ print $2 }'` 56 10 1>> $outfile 2>&1
		echo "\n_____________________________________________________\n" >> $outfile
		echo "\n\n# /usr/sbin/ping -s `netstat -r | grep default | /usr/bin/awk '{ print $2 }'` 1016 10\n" >> $outfile
		echo "$log_stamp # /usr/sbin/ping -s `netstat -r | grep default | /usr/bin/awk '{ print $2 }'` 1016 10 ..."
		/usr/sbin/ping -s `netstat -r | grep default | /usr/bin/awk '{ print $2 }'` 1016 10 1>> $outfile 2>&1
		echo "\n_____________________________________________________\n" >> $outfile
		echo "\n\n# /usr/sbin/ping -s google.com 56 10\n" >> $outfile
		echo "$log_stamp # /usr/sbin/ping -s google.com 56 10 ..."
		/usr/sbin/ping -s google.com 56 10 1>> $outfile 2>&1
		echo "\n_____________________________________________________\n" >> $outfile
		echo "\n\n# /usr/sbin/ping -s google.com 1016 10\n" >> $outfile
		echo "$log_stamp # /usr/sbin/ping -s google.com 1016 10 ..."
		/usr/sbin/ping -s google.com 1016 10 1>> $outfile 2>&1
		echo "\n_____________________________________________________\n" >> $outfile
	fi

	if [[ -x /sbin/lltstat ]]	# 	VCS LLT transport (private links)
   	then
		echo "\n_____________________________________________________\n" >> $outfile
		/sbin/lltstat -l 1>> $lltstat_file 2>&1
		echo "\n** VCS LLTSTAT Interconnect Packets after $SECONDS seconds **" >> $outfile
		/sbin/lltstat -l 1>> $outfile 2>&1
	fi

	echo "\n_____________________________________________________\n" >> $outfile

	echo "\n\n########## /etc/hostname.___ (Network Interface) files ##########\n" >> $outfile

	ls -l /etc/hostname.* 1>/dev/null 2>&1
	ret=$?

	if [[ $ret -eq 0 ]]
	then
	    for i in /etc/hostname.*
	    do
		echo "$log_stamp # cat $i ..."
		
		echo "\n\n\t>>>>>>>  $i  <<<<<<<<\n" >> $outfile
		cat $i >> $outfile
		echo "_____________________________________________________\n" >> $outfile
	    done
	fi

   	if [[ -f /etc/inet/networks ]]
   	then
		echo "\n\n" >> $outfile
		echo "# cat /etc/inet/networks\n" >> $outfile
		echo "$log_stamp # cat /etc/inet/networks ..."
		cat /etc/inet/networks >> $outfile
		echo "\n_____________________________________________________\n" >> $outfile
	fi

	name_svc=`grep "^networks:" /etc/nsswitch.conf | /usr/bin/awk '{ print $2 }'`
	if [[ $name_svc = "nis" ]]
	then
		echo "# /usr/bin/ypcat networks\n" >> $outfile
		echo "$log_stamp # /usr/bin/ypcat networks ..."
		/usr/bin/ypcat networks >> $outfile

		echo "\n\n# /usr/bin/ypcat ethers\n" >> $outfile
		echo "$log_stamp # /usr/bin/ypcat ethers ..."
		/usr/bin/ypcat ethers >> $outfile
		
	elif [[ $name_svc = "nisplus" ]]
	then
		echo "" >> $outfile
		echo "# /usr/bin/niscat networks.org_dir\n" >> $outfile
		echo "$log_stamp # /usr/bin/niscat networks.org_dir ..."
		/usr/bin/niscat networks.org_dir >> $outfile
	fi

   	if [[ -f /etc/ethers ]]
   	then
		echo "" >> $outfile
		echo "# cat /etc/ethers\n" >> $outfile
		echo "$log_stamp # cat /etc/ethers ..."
		cat /etc/ethers >> $outfile
		echo "\n_____________________________________________________\n" >> $outfile
	fi

   	if [[ -f /etc/defaultrouter ]]
   	then
		echo "\n\n# cat /etc/defaultrouter\n" >> $outfile
		echo "$log_stamp # cat /etc/defaultrouter ..."
		cat /etc/defaultrouter >> $outfile
		echo "\n_____________________________________________________\n" >> $outfile
#	else
#		echo "$log_stamp  /etc/defaultrouter  NOT found, skipping.\n"
	fi

   	if [[ -f /etc/notrouter ]]
   	then
		echo "\n\n\n\n*!*! /etc/notrouter exists. !*!* Note: This system is NOT a router.\n" >> $outfile
		echo "$log_stamp #  NOT a router ..."
	fi

   	if [[ -f /etc/netmasks ]]
   	then
		echo "\n\n\n# cat /etc/netmasks\n" >> $outfile
		echo "$log_stamp # cat /etc/netmasks ..."
		cat /etc/netmasks >> $outfile
		echo "\n_____________________________________________________\n" >> $outfile
#	else
#		echo "$log_stamp  /etc/netmasks  NOT found, skipping.\n"
	fi

   	if [[ -f /etc/gateways ]]
   	then
		echo "\n\n\n# cat /etc/gateways\n" >> $outfile
		echo "$log_stamp # cat /etc/gateways ..."
		cat /etc/gateways >> $outfile
		echo "\n_____________________________________________________\n" >> $outfile
#	else
#		echo "$log_stamp  /etc/gateways  NOT found, skipping.\n"
	fi
#
   	if [[ -f /etc/inet/ntp.server ]]
   	then
		echo "\n" >> $outfile
		echo "_____________________________________________________\n" >> $outfile
		echo "# tail -30 /etc/inet/ntp.server\n" >> $outfile
		echo "$log_stamp # tail -30 /etc/inet/ntp.server ..."
		tail -30 /etc/inet/ntp.server >> $outfile
		echo "\n_____________________________________________________\n" >> $outfile
	fi

	echo "\n\n**** Sun Trunking / Link Aggregation ****\n" >> $outfile

   	if [[ -d /etc/opt/SUNWqfetr/bin ]]	## Sun Trunking 1.0.1
   	then
		echo "\n\n\n# /etc/opt/SUNWqfetr/bin/qfetr -conf\n" >> $outfile
		echo "$log_stamp # /etc/opt/SUNWqfetr/bin/qfetr -conf ..."
		/etc/opt/SUNWqfetr/bin/qfetr -conf >> $outfile

		echo "\n\n\n# /etc/opt/SUNWqfetr/bin/qfetr -debug\n" >> $outfile
		echo "$log_stamp # /etc/opt/SUNWqfetr/bin/qfetr -debug ..."
		/etc/opt/SUNWqfetr/bin/qfetr -debug >> $outfile

		echo "\n\n\n# cat /etc/opt/SUNWqfetr/bin/qfetr.sh \n" >> $outfile
		echo "$log_stamp # cat /etc/opt/SUNWqfetr/bin/qfetr.sh ..."
		cat /etc/opt/SUNWqfetr/bin/qfetr.sh >> $outfile
		echo "\n_____________________________________________________\n" >> $outfile
	fi

   	if [[ -d /etc/opt/SUNWconn/bin ]]		## Sun Trunking 1.2.x
   	then
		echo "\n\n\n# /etc/opt/SUNWconn/bin/nettr -conf\n" >> $outfile
		echo "$log_stamp # /etc/opt/SUNWconn/bin/nettr -conf ..."
		/etc/opt/SUNWconn/bin/nettr -conf >> $outfile

		echo "\n\n\n# /etc/opt/SUNWconn/bin/nettr -debug\n" >> $outfile
		echo "$log_stamp # /etc/opt/SUNWconn/bin/nettr -debug ..."
		/etc/opt/SUNWconn/bin/nettr -debug >> $outfile

		echo "\n\n\n# cat /etc/opt/SUNWconn/bin/nettr.sh \n" >> $outfile
		echo "$log_stamp # cat /etc/opt/SUNWconn/bin/nettr.sh ..."
		cat /etc/opt/SUNWconn/bin/nettr.sh >> $outfile
		echo "\n_____________________________________________________\n" >> $outfile
	fi
#
 	if [[ -x /usr/sbin/dladm ]]		## Sun S10/ Nemo Link Aggr
   	then
		echo "\n\n\n# /usr/sbin/dladm show-dev\n" >> $outfile
		echo "$log_stamp # /usr/sbin/dladm show-dev ..."
		/usr/sbin/dladm show-dev >> $outfile

		echo "\n\n# /usr/sbin/dladm show-link\n" >> $outfile
		echo "$log_stamp # /usr/sbin/dladm show-link ..."
		/usr/sbin/dladm show-link >> $outfile

		echo "\n\n# /usr/sbin/dladm show-aggr\n" >> $outfile
		echo "$log_stamp # /usr/sbin/dladm show-aggr ..."
		/usr/sbin/dladm show-aggr >> $outfile
	fi

     echo "\n_______________________________________________________________________\n" >> $outfile

     if [[ ( ($LONG -ne 0 ) || ( $NETWORK -ne 0 ) ) ]]
     then

   	if [[ -x /usr/sbin/pntadm ]]		## DHCP config
   	then
		echo "\n\n\n# /usr/sbin/pntadm -L\n" >> $outfile
		echo "$log_stamp # /usr/sbin/pntadm -L ..."
		/usr/sbin/pntadm -L 1>> $outfile 2>&1
	fi

   	if [[ -r /etc/inet/dhcpsvc.conf ]]		## DHCP config
   	then
		echo "\n\n\n# cat /etc/inet/dhcpsvc.conf\n" >> $outfile
		echo "$log_stamp # cat /etc/inet/dhcpsvc.conf ..."
		cat /etc/inet/dhcpsvc.conf >> $outfile
	fi

   	if [[ -r /var/dhcp/dhcptab ]]		## DHCP config
   	then
		echo "\n\n\n# cat /var/dhcp/dhcptab\n" >> $outfile
		echo "$log_stamp # cat /var/dhcp/dhcptab ..."
		cat /var/dhcp/dhcptab >> $outfile
	fi

#### X.25 config capture 

   	if [[ -x /opt/SUNWconn/bin/X25info ]]		## X25 Links
   	then
		echo "\n\n\n# /opt/SUNWconn/bin/X25info\n" >> $outfile
		echo "$log_stamp # /opt/SUNWconn/bin/X25info ..."
		/opt/SUNWconn/bin/X25info >> $outfile
	fi


   	if [[ -x /opt/SUNWconn/bin/X25stat ]]		## X25 status
   	then
		echo "\n\n\n# /opt/SUNWconn/bin/X25stat\n" >> $outfile
		echo "$log_stamp # /opt/SUNWconn/bin/X25stat ..."
		/opt/SUNWconn/bin/X25stat >> $outfile
	fi

   	if [[ -x /opt/SUNWconn/bin/X25file ]]	## X25 link config files
   	then

		for i in `/opt/SUNWconn/bin/X25info | /usr/bin/awk '{ print $2 }'`
		do
			echo "\n# /opt/SUNWconn/bin/X25file -l $i\n" >> $outfile
			echo "$log_stamp # /opt/SUNWconn/bin/X25file -l $i ..."
			/opt/SUNWconn/bin/X25file -l $i >> $outfile

		done

	fi

     fi	## end IF LONG

	log_stamp='sys_diag:'`date '+%m%d_%H%M%S'`':'

	if [[ ( ( $VERBOSE -ne 0 ) || ( $NETWORK -ne 0 ) ) ]]
	then
		echo "\n" >> $outfile		# Kernel network driver params/stats
		echo "\n_______________________________________________________________________\n" >> $outfile

		echo "\n**** NETWORK (Kstat) Counters / Driver Settings ****\n" >> $outfile

		echo "$log_stamp # /usr/bin/kstat -c net ..."
		echo "# /usr/bin/kstat -c net \n" >> $outfile
		/usr/bin/kstat -c net >> $outfile
		echo "\n_______________________________________________________________________\n" >> $outfile

		log_stamp='sys_diag:'`date '+%m%d_%H%M%S'`':'


	################ Get the Network DRIVER SETTINGS ###############


		echo "\n\n# ndd -get /dev/tcp ..." >> $outfile
		echo "$log_stamp # ndd -get /dev/tcp ..."

		for i in `ndd /dev/tcp \? | grep read | grep -v \? | cut -d' ' -f1`
		do
			echo "/dev/tcp:  $i\t`/usr/sbin/ndd -get /dev/tcp $i`" >> $outfile 2>/dev/null
		done
		echo "\n_____________________________________________________\n" >> $outfile


		echo "\n\n# ndd -get /dev/udp ..." >> $outfile
		echo "$log_stamp # ndd -get /dev/udp ..."

		for i in `ndd /dev/udp \? | grep read | grep -v \? | cut -d' ' -f1`
		do
			echo "/dev/udp:  $i\t`/usr/sbin/ndd -get /dev/udp $i`" >> $outfile 2>/dev/null
		done
		echo "\n_____________________________________________________\n" >> $outfile

		echo "\n\n# ndd -get /dev/ip ..." >> $outfile
		echo "$log_stamp # ndd -get /dev/ip ..."

		for i in `ndd /dev/ip \? | grep read | grep -v \? | cut -d' ' -f1`
		do
			echo "/dev/ip:  $i\t`/usr/sbin/ndd -get /dev/ip $i`" >> $outfile 2>/dev/null
		done
		echo "\n_____________________________________________________\n" >> $outfile

		num_nets=0

# .....	Loop through all devices ........................................
#
		for i in `/usr/sbin/ifconfig -a |  grep ": " | grep "IPv4" | cut -d":" -f1`
		do
			log_stamp='sys_diag:'`date '+%m%d_%H%M%S'`':'
	
			j=${i%%[0-9]*}	#### device name 

			if [[ $j = "lo" ]]
			then
				continue
			fi

			if [[ ( $i = $last_nic ) && ( $num_nets -gt 0 ) ]]
			then
				continue	# Logical Layered Virtual NIC Interface, skip..
			else
				last_nic=$i
			fi

   			num_nets=$(($num_nets+1))

			echo "$log_stamp # ndd -set /dev/$j instance ${i#$j} ..."
			/usr/sbin/ndd -set /dev/$j instance ${i#$j} 2>/dev/null

			echo "\n\n# ndd -get /dev/$j ... instance ${i#$j}\n" >> $outfile
			echo "$log_stamp # ndd -get /dev/$j ..."

			for k in `ndd /dev/$j \? |grep read |grep -v \? |cut -d' ' -f1`
			do
				echo "/dev/$j:  $k\t`/usr/sbin/ndd -get /dev/$j $k`" >> $outfile
			done
			echo "\n_____________________________________________________\n" >> $outfile
		done
	fi

	if [[ ( $LONG -ne 0 ) || ( $VERBOSE -ne 0 ) || ( $PERF -ne 0 ) ]]
	then
		netstat_file=$sysd_dir'/sysd_netstata_'`uname -n`'_'`date '+%y%m%d_%H%M%S'`'.out'

		echo "\n\n" >> $outfile

		echo "\n**** NETWORK Connections ****\n" >> $outfile

		echo "# /usr/bin/netstat -a\n" >> $outfile
		echo "$log_stamp # /usr/bin/netstat -a ..."
		/usr/bin/netstat -a >> $outfile
		/usr/bin/netstat -a > $netstat_file

		echo "\n_____________________________________________________________________________\n" >> $outfile
		echo "\n**** NETWORK ERRORS / Statistics ****\n" >> $outfile

		echo "\nSUMMARY of Network ERRORS / Failures / Overflows :\n-----------------------------------------------------\n\n(*NOTE: ONLY non-zero parameters/entries are listed*)\n" >> $outfile
		echo "UDP :\n" >> $outfile
		/usr/bin/kstat -n udp | grep -i err | grep -v ' 0' >> $outfile
		/usr/bin/kstat -n udp | grep -i fail | grep -v ' 0' >> $outfile
		/usr/bin/kstat -n udp | grep -i overflow | grep -v ' 0' >> $outfile
		echo "\nTCP :\n" >> $outfile
		/usr/bin/kstat -n tcp | grep -i err | grep -v ' 0' >> $outfile
		/usr/bin/kstat -n tcp | grep -i fail | grep -v ' 0' >> $outfile
		/usr/bin/kstat -n tcp | grep -i overflow | grep -v ' 0' >> $outfile
		echo "\nIP :\n" >> $outfile
		/usr/bin/kstat -n ip | grep -i err | grep -v ' 0' >> $outfile
		/usr/bin/kstat -n ip | grep -i fail | grep -v ' 0' >> $outfile
		/usr/bin/kstat -n ip | grep -i overflow | grep -v ' 0' >> $outfile
		echo "\nICMP :\n" >> $outfile
		/usr/bin/kstat -n icmp | grep -i err | grep -v ' 0' >> $outfile
		/usr/bin/kstat -n icmp | grep -i overflow | grep -v ' 0' >> $outfile

		echo "\n_____________________________________________________________________________\n" >> $outfile
		echo "\n**** Interface ERRORS ****\n\nNote: NIC port error stats are only listed if *non-zero*\n\n" >> $outfile
		num_nets=0

		for i in `/usr/sbin/ifconfig -a |  grep ": " | cut -d":" -f1`
		do
			if [[ ( $i = $last_nic ) && ( $num_nets -gt 0 ) ]]
			then
				continue	# Logical Layered Virtual NIC Interface, skip..
			else
				last_nic=$i

				if [[ $num_nets -eq 0 ]]
				then
					continue	# lo0 loopback NIC, skip
				fi
			fi

   			num_nets=$(($num_nets+1))
			kstat_file=`echo $sysd_dir'/sysd_knetb_'$i'_*.out'`
			
			echo "* $i *" >> $outfile
			grep -h -i err $kstat_file | grep -v '	0' >> $outfile
			grep -h -i coll $kstat_file | grep -v '	0' >> $outfile
			grep -h -i buf $kstat_file | grep -v '	0' >> $outfile
			grep -h -i block $kstat_file | grep -v '	0' >> $outfile
			grep -h -i flo $kstat_file | grep -v '	0' >> $outfile
			grep -h -i miss $kstat_file | grep -v '	0' >> $outfile
			grep -h -i noxmt $kstat_file | grep -v '	0' >> $outfile
			grep -h -i xmtr $kstat_file | grep -v '	0' >> $outfile
			grep -h -i defer $kstat_file | grep -v '	0' >> $outfile
			echo "\n_____________________________________\n" >> $outfile
		done	

		log_stamp='sys_diag:'`date '+%m%d_%H%M%S'`':'
		echo "\n_____________________________________________________________________________\n" >> $outfile
		echo "\n\n\n# /usr/bin/netstat -s" >> $outfile
		echo "$log_stamp # /usr/bin/netstat -s ..."
		/usr/bin/netstat -s >> $outfile
		echo "\n_____________________________________________________________________________\n" >> $outfile
	fi
   
fi


############################ TTY / Modem Configs ##############################

if [[ ( $ALL -ne 0 ) || ( $NETWORK -ne 0 ) ]]
then
	echo "" >> $outfile
	echo "\n$log_stamp ######  TTY / MODEM INFO  ######"
	echo "## 11 ###################### TTY / MODEM INFO ################################\n\n" >> $outfile

	if [[ -x /usr/sbin/pmadm ]]
	then
		echo "# /usr/sbin/pmadm -l\n" >> $outfile
		echo "$log_stamp # /usr/sbin/pmadm -l ..."
		/usr/sbin/pmadm -l >> $outfile
	fi

	if [[ -f /etc/remote ]]
	then
		echo "\n_____________________________________________________\n" >> $outfile
		echo "# cat /etc/remote\n" >> $outfile
		echo "$log_stamp # cat /etc/remote ..."
		cat /etc/remote >> $outfile
		echo "\n_____________________________________________________\n" >> $outfile
	fi

	if [[ -f /etc/phones ]]
	then
		echo "\n" >> $outfile
		echo "# cat /etc/phones\n" >> $outfile
		echo "$log_stamp # cat /etc/phones ..."
		cat /etc/phones >> $outfile
	fi

	if [[ -f /var/adm/aculog ]]
	then
		echo "\n" >> $outfile
		echo "# cat /var/adm/aculog\n" >> $outfile
		echo "$log_stamp # cat /var/adm/aculog ..."
		tail -120 /var/adm/aculog >> $outfile 2>&1
	fi
fi


#######################  USER / ACCOUNT / GROUP Info  #####################

if [[ $ALL -ne 0 ]]
then
	echo "\n$log_stamp ######  USER / ACCOUNT / GROUP Info  ######"
	log_stamp='sys_diag:'`date '+%m%d_%H%M%S'`':'

	echo "" >> $outfile
	echo "## 12 #################  USERs/ ACCOUNTs/ GROUPs  ###################\n" >> $outfile
	echo "# /usr/bin/w\n" >> $outfile
	echo "$log_stamp # w ..."
	/usr/bin/w >> $outfile

	echo "\n" >> $outfile
	echo "# /usr/bin/who -a\n" >> $outfile
	echo "$log_stamp # who -a ..."
	/usr/bin/who -a >> $outfile

   	if [[ -f /etc/passwd ]]
   	then
		echo "" >> $outfile
		echo "\n_____________________________________________________\n" >> $outfile
		echo "# cat /etc/passwd\n" >> $outfile
		echo "$log_stamp # cat /etc/passwd ..."
		cat /etc/passwd >> $outfile
		echo "\n_____________________________________________________\n" >> $outfile
	fi
	name_svc=`grep "^passwd:" /etc/nsswitch.conf | /usr/bin/awk '{ print $2 }'`

	if [[ $name_svc = "nis" ]]
	then
		echo "" >> $outfile
		echo "# /usr/bin/ypcat passwd\n" >> $outfile
		echo "$log_stamp # /usr/bin/ypcat passwd ..."
		/usr/bin/ypcat passwd >> $outfile
		echo "\n_____________________________________________________\n" >> $outfile
	elif [[ $name_svc = "nisplus" ]]
	then
		echo "" >> $outfile
		echo "# /usr/bin/niscat passwd.org_dir\n" >> $outfile
		echo "$log_stamp # /usr/bin/niscat passwd.org_dir ..."
		/usr/bin/niscat passwd.org_dir >> $outfile
		echo "\n_____________________________________________________\n" >> $outfile
	fi

   	if [[ -f /etc/group ]]
   	then
		echo "" >> $outfile
		echo "# cat /etc/group\n" >> $outfile
		echo "$log_stamp # cat /etc/group ..."
		cat /etc/group >> $outfile
	fi
	name_svc=`grep "^group:" /etc/nsswitch.conf | /usr/bin/awk '{ print $2 }'`

	if [[ $name_svc = "nis" ]]
	then
		echo "" >> $outfile
		echo "# /usr/bin/ypcat group\n" >> $outfile
		echo "$log_stamp # /usr/bin/ypcat group ..."
		/usr/bin/ypcat group >> $outfile
	elif [[ $name_svc = "nisplus" ]]
	then
		echo "" >> $outfile
		echo "# /usr/bin/niscat groups.org_dir\n" >> $outfile
		echo "$log_stamp # /usr/bin/niscat groups.org_dir ..."
		/usr/bin/niscat groups.org_dir >> $outfile
	fi
fi

##################### SERVICES / NAMING RESOLUTION ######################

log_stamp='sys_diag:'`date '+%m%d_%H%M%S'`':'

if [[ ( $ALL -ne 0 ) || ( $CONFIG -ne 0 ) || ( $NETWORK -ne 0 ) ]]
then
	echo "" >> $outfile
	echo "\n$log_stamp ######  SERVICES / NAMING RESOLUTION  ######"
	echo "## 13 ###################### SERVICES / NAMING RESOLUTION ##############\n\n" >> $outfile

        if [[ -x /usr/bin/svcs ]]		# S10 SSM : Service Management
        then
                echo "# /usr/bin/svcs -v\n" >> $outfile
                echo "$log_stamp # /usr/bin/svcs -v ..."
                /usr/bin/svcs -v >> $outfile
        fi

        if [[ -f /etc/services ]]
        then
		echo "\n_____________________________________________________\n" >> $outfile
                echo "# cat /etc/services\n" >> $outfile
                echo "$log_stamp # cat /etc/services ..."
                cat /etc/services >> $outfile
		echo "\n_____________________________________________________\n" >> $outfile
        else
                echo "$log_stamp  /etc/services NOT found, skipping.\n"
        fi

        if [[ -f /etc/inetd.conf ]]
        then
                echo "\n" >> $outfile
                echo "# cat /etc/inetd.conf\n" >> $outfile
                echo "$log_stamp # cat /etc/inetd.conf ..."
                cat /etc/inetd.conf >> $outfile
		echo "\n_____________________________________________________\n" >> $outfile
        else
                echo "$log_stamp  /etc/inetd.conf NOT found, skipping.\n"
        fi

        if [[ -f /etc/inittab ]]
        then
                echo "\n\n" >> $outfile
                echo "# cat /etc/inittab\n" >> $outfile
                echo "$log_stamp # cat /etc/inittab ..."
                cat /etc/inittab >> $outfile
		echo "\n_____________________________________________________\n" >> $outfile
        else
                echo "$log_stamp  /etc/inittab NOT found, skipping.\n"
        fi

	if [[ -f /etc/nsswitch.conf ]]
	then
		echo "\n\n# cat /etc/nsswitch.conf\n" >> $outfile
		echo "$log_stamp # cat /etc/nsswitch.conf ..."
		cat /etc/nsswitch.conf >> $outfile
		echo "\n_____________________________________________________\n" >> $outfile
	else
		echo "$log_stamp  /etc/nsswitch.conf NOT found, skipping.\n"
	fi

	if [[ -f /etc/resolv.conf ]]
	then
		echo "\n" >> $outfile
		echo "# cat /etc/resolv.conf\n" >> $outfile
		echo "$log_stamp # cat /etc/resolv.conf ..."
		cat /etc/resolv.conf >> $outfile
		echo "\n_____________________________________________________\n" >> $outfile
	else
		echo "$log_stamp  /etc/resolv.conf NOT found, skipping.\n"
	fi

	if [[ -f /etc/auto_master ]]
	then
		echo "\n# cat /etc/auto_master\n" >> $outfile
		echo "$log_stamp # cat /etc/auto_master ..."
		cat /etc/auto_master >> $outfile
	else
		echo "\n# ypcat auto.master\n" >> $outfile
		echo "$log_stamp # ypcat auto.master ..."
		ypcat auto.master 1>> $outfile 2>&1
#		echo "$log_stamp  /etc/auto_master NOT found locally.\n"
	fi
	echo "\n_____________________________________________________\n" >> $outfile

	if [[ -f /etc/auto_home ]]
	then
		echo "\n# cat /etc/auto_home\n" >> $outfile
		echo "$log_stamp # cat /etc/auto_home ..."
		cat /etc/auto_home >> $outfile
		echo "\n_____________________________________________________\n" >> $outfile
#	else
#		echo "$log_stamp  /etc/auto_home NOT found locally, skipping.\n"
	fi

	if [[ -f /etc/named.conf ]]
	then
		echo "\n" >> $outfile
		echo "# cat /etc/named.conf\n" >> $outfile
		echo "$log_stamp # cat /etc/named.conf ..."
		cat /etc/named.conf >> $outfile
		echo "\n_____________________________________________________\n" >> $outfile
#	else
#		echo "$log_stamp  /etc/named.conf NOT found, skipping.\n"
	fi

	if [[ -f /var/log/named.stats ]]
	then
		echo "\n" >> $outfile
		echo "# tail -300 /var/log/named.stats\n" >> $outfile
		echo "$log_stamp # tail -300 /var/log/named.stats ..."
		tail -300 /var/log/named.stats >> $outfile
		echo "\n_____________________________________________________\n" >> $outfile
#	else
#		echo "$log_stamp  /var/log/named.stats NOT found, skipping.\n"
	fi

	if [[ -f /etc/named.boot ]]
	then
		echo "\n" >> $outfile
		echo "# cat /etc/named.boot\n" >> $outfile
		echo "$log_stamp # cat /etc/named.boot ..."
		cat /etc/named.boot >> $outfile
		echo "\n_____________________________________________________\n" >> $outfile
#	else
#		echo "$log_stamp  /etc/named.boot NOT found, skipping.\n"
	fi

	log_stamp='sys_diag:'`date '+%m%d_%H%M%S'`':'

	if [[ -x /usr/bin/ypwhich ]]
	then
		echo "\n# /usr/bin/ypwhich\n" >> $outfile
		echo "$log_stamp # /usr/bin/ypwhich ..."
		/usr/bin/ypwhich 1>> $outfile 2>&1
	fi

	if [[ $? -eq 0 ]]
	then
		echo "\n\n\n" >> $outfile
		echo "# /usr/bin/ypwhich -m\n" >> $outfile
		echo "$log_stamp # /usr/bin/ypwhich -m ..."
		/usr/bin/ypwhich -m 1>> $outfile 2>&1
		echo "\n_____________________________________________________\n" >> $outfile
	else
		no_nis=1
		echo "\n_____________________________________________________\n" >> $outfile
	fi

	if [[ -x /usr/bin/nisdefaults ]]
	then
		echo "" >> $outfile
		echo "# /usr/bin/nisdefaults\n" >> $outfile
		echo "$log_stamp # /usr/bin/nisdefaults ..."
		/usr/bin/nisdefaults 1>> $outfile 2>&1
	fi

	nisd=`ps -ef | grep nisd | wc -l`

	if [[ $nisd -gt 1 ]]
	then
		echo "" >> $outfile
		echo "# /usr/bin/nisls -l\n" >> $outfile
		echo "$log_stamp # /usr/bin/nisls -l ..."
		/usr/bin/nisls -l >> $outfile

		echo "" >> $outfile
		echo "# /usr/bin/niscat -o org_dir\n" >> $outfile
		echo "$log_stamp # /usr/bin/niscat -o org_dir..."
		/usr/bin/niscat -o org_dir >> $outfile

		echo "" >> $outfile
		echo "# /usr/bin/nislog\n" >> $outfile
		echo "$log_stamp # /usr/bin/nislog ..."
		/usr/bin/nislog >> $outfile

		echo "" >> $outfile
		echo "# /usr/lib/nis/nisstat\n" >> $outfile
		echo "$log_stamp # /usr/lib/nis/nisstat ..."
		/usr/lib/nis/nisstat >> $outfile
	fi

	name_svc1=`grep "^hosts:" /etc/nsswitch.conf | /usr/bin/awk '{ print $2 }'`
	name_svc2=`grep "^hosts:" /etc/nsswitch.conf | /usr/bin/awk '{ print $3 }'`

#	if [[ (( $name_svc1 = "nis" ) || ( ( $name_svc1 = "xfn" ) && ( $name_svc2 = "nis" ) )) ]]
#	if [ $name_svc1 = "nis" ] || [ $name_svc2 = "nis" ]

	log_stamp='sys_diag:'`date '+%m%d_%H%M%S'`':'

	if [[ $no_nis -eq 0 ]]
	then
		echo "" >> $outfile
		echo "# /usr/bin/ypcat hosts\n" >> $outfile
		echo "$log_stamp # /usr/bin/ypcat hosts ..."
		/usr/bin/ypcat hosts 1>> $outfile 2>&1
		echo "\n_____________________________________________________\n" >> $outfile
	fi

#	elif [ $name_svc1 = "nisplus" ] || ( [ $name_svc1 = "xfn" ] && [ $name_svc2 = "nisplus" ] )
#	if [ $name_svc1 = "nisplus" ] || [ $name_svc2 = "nisplus" ]

	if [[ $nisd -gt 1 ]]
	then
		echo "" >> $outfile
		echo "# /usr/bin/niscat hosts.org_dir\n" >> $outfile
		echo "$log_stamp # /usr/bin/niscat hosts.org_dir ..."
		/usr/bin/niscat hosts.org_dir 1>> $outfile 2>&1
		echo "\n_____________________________________________________\n" >> $outfile
	fi

#TJ TBD - DNC Config Capture ?? TBD
#
#	if [ $name_svc1 = "dns" ] || [ $name_svc2 = "dns" ]
#	then
#		echo "" >> $outfile
#		echo "# cat ??db.cache\n" >> $outfile
#		echo "$log_stamp # cat ??db.cache ..."
#		cat ??db.cache >> $outfile
#	
#		echo "" >> $outfile
#		echo "# cat ?? \n" >> $outfile
#		echo "$log_stamp # cat ?? ..."
#		cat ?? >> $outfile
#
#
#		nslookup -all ???????????????
#	fi

	if [[ -r /etc/named.conf ]]
	then
		echo "" >> $outfile
		echo "# cat /etc/named.conf\n" >> $outfile
		echo "$log_stamp # cat /etc/named.conf ..."
		cat /etc/named.conf >> $outfile
		echo "\n_____________________________________________________\n" >> $outfile
	fi
fi


##################### SECURITY+ CONFIG FILES  ######################

log_stamp='sys_diag:'`date '+%m%d_%H%M%S'`':'

if [[ ( $ALL -ne 0 ) || ( $CONFIG -ne 0 ) || ( $NETWORK -ne 0 ) ]]
then
        echo "" >> $outfile
	echo "\n$log_stamp ######  SECURITY / CONFIG FILES  ######"
        echo "## 14 ################  SECURITY+ / SYSTEM CONFIG FILES  ###############\n\n" >> $outfile

        if [[ -f /etc/hosts.equiv ]]
        then
                echo "\n\t**An /etc/hosts.equiv file DOES exist**\n" >> $outfile
                echo "# cat /etc/hosts.equiv\n" >> $outfile
                echo "$log_stamp # cat /etc/hosts.equiv ..."
                cat /etc/hosts.equiv >> $outfile
		echo "\n_____________________________________________________\n" >> $outfile
        else
                echo "\nNo /etc/hosts.equiv file exists.\n" >> $outfile
#               echo "$log_stamp  /etc/hosts.equiv NOT found, skipping.\n"
        fi

        if [[ -f /.rhosts ]]
        then
                echo "\n\n\t**An /.rhosts file DOES exist**\n" >> $outfile
                echo "# cat /.rhosts\n" >> $outfile
                echo "$log_stamp # cat /.rhosts ..."
                cat /.rhosts >> $outfile
		echo "\n_____________________________________________________\n" >> $outfile
        else
                echo "\n\nNo /.rhosts file exists.\n" >> $outfile
#               echo "$log_stamp  /.rhosts NOT found, skipping.\n"
        fi

        if [[ -f /etc/shadow ]]
        then
                echo "\n\n-------------------\n\n" >> $outfile
                echo "\t**An /etc/shadow file DOES exist**" >> $outfile
        else
                echo "$log_stamp  /etc/shadow NOT found !!\n"
                echo "\n\n\n" >> $outfile
                echo "!! NO /etc/shadow file exists !!" >> $outfile
        fi

        if [[ -f /etc/syslog.conf ]]
        then
                echo "\n" >> $outfile
		echo "\n_____________________________________________________\n" >> $outfile
                echo "# cat /etc/syslog.conf\n" >> $outfile
                echo "$log_stamp # cat /etc/syslog.conf ..."
                cat /etc/syslog.conf >> $outfile
		echo "\n_____________________________________________________\n" >> $outfile
#        else
#                echo "$log_stamp  /etc/syslog.conf NOT found, skipping.\n"
        fi

   	if [[ -r /etc/pam.conf ]]		## PAM config
   	then
		echo "\n\n\n# cat /etc/pam.conf\n" >> $outfile
		echo "$log_stamp # cat /etc/pam.conf ..."
		cat /etc/pam.conf >> $outfile
	fi

        if [[ -f /etc/default/login ]]
        then
                echo "\n" >> $outfile
		echo "\n_____________________________________________________\n" >> $outfile
                echo "# cat /etc/default/login\n" >> $outfile
                echo "$log_stamp # cat /etc/default/login ..."
                cat /etc/default/login >> $outfile
		echo "\n_____________________________________________________\n" >> $outfile
#        else
#                echo "$log_stamp  /etc/default/login NOT found, skipping.\n"
        fi

	if [[ -f /var/adm/sulog ]]
        then
                echo "\n" >> $outfile
                echo "# tail -250 /var/adm/sulog\n" >> $outfile
                echo "$log_stamp # tail -250 /var/adm/sulog ..."
                tail -250 /var/adm/sulog >> $outfile 2>&1
#        else
#                echo "$log_stamp  /var/adm/sulog NOT found, skipping.\n"
        fi

	if [[ -x /usr/bin/last ]]
        then
                echo "\n" >> $outfile
                echo "# /usr/bin/last reboot\n" >> $outfile
                echo "$log_stamp # /usr/bin/last reboot ..."
                /usr/bin/last reboot >> $outfile
        
                echo "\n" >> $outfile
                echo "# /usr/bin/last -200\n" >> $outfile
                echo "$log_stamp # /usr/bin/last -200  ..."
                /usr/bin/last -200 >> $outfile
#       else
#                echo "$log_stamp  /usr/bin/last  NOT found, skipping.\n"
        fi

	if [[ -x /usr/sbin/ipf ]]		## Solaris 10 IP Filtering
        then
                echo "\n" >> $outfile
                echo "# /usr/sbin/ipf -T list\n" >> $outfile
                echo "$log_stamp # /usr/sbin/ipf -T list ..."
                /usr/sbin/ipf -T list >> $outfile
        fi
	
	if [[ -f /etc/ipf/ipf.conf ]]
	then
                echo "\n" >> $outfile
                echo "# cat /etc/ipf/ipf.conf\n" >> $outfile
                echo "$log_stamp # cat /etc/ipf/ipf.conf  ..."
                cat /etc/ipf/ipf.conf >> $outfile
		echo "\n_____________________________________________________\n" >> $outfile

                echo "\n\n# cat /etc/ipf/pfil.ap\n" >> $outfile
                echo "$log_stamp # cat /etc/ipf/pfil.ap ..."
		echo "\n_____________________________________________________\n" >> $outfile
                cat /etc/ipf/pfil.ap >> $outfile
	fi

	if [[ -x /usr/sbin/ipnat ]]		## Solaris 10 IP NAT
        then
                echo "\n" >> $outfile
                echo "# /usr/sbin/ipnat -vls\n" >> $outfile
                echo "$log_stamp # /usr/sbin/ipnat -vls ..."
                /usr/sbin/ipnat -vls >> $outfile
        fi
	
fi

########################  CLUSTERING INFO  ################################


if [[ ( $ALL -ne 0 ) || ( $HA -ne 0 ) || ( $CONFIG -ne 0 ) ]]
then
log_stamp='sys_diag:'`date '+%m%d_%H%M%S'`':'

   echo "\n$log_stamp ######  HA/ CLUSTERING INFO  ######"
   echo "" >> $outfile
   echo "## 15 ##################  HA / CLUSTERING INFO  ##########################\n" >> $outfile

   if [[ -f /opt/SUNWcluster/bin/hastat ]]	# SC2.2
   then
	echo "# /opt/SUNWcluster/bin/hastat\n" >> $outfile
	echo "$log_stamp # /opt/SUNWcluster/bin/hastat ..."
	/opt/SUNWcluster/bin/hastat >> $outfile
   fi

   if [[ -f /opt/SUNWcluster/bin/scconf ]]	# SC2.2
   then
	echo "\n" >> $outfile
	echo "# /opt/SUNWcluster/bin/scconf `cat /etc/opt/SUNWcluster/conf/default_clustername` -p\n" >> $outfile
	echo "$log_stamp # /opt/SUNWcluster/bin/scconf `cat /etc/opt/SUNWcluster/conf/default_clustername` -p ..."
	/opt/SUNWcluster/bin/scconf `cat /etc/opt/SUNWcluster/conf/default_clustername` -p >> $outfile
   fi

   if [[ -x /opt/SUNWcluster/bin/pnmstat ]]	# SC2.2
   then
	echo "\n# /opt/SUNWcluster/bin/pnmstat\n" >> $outfile
	echo "$log_stamp # /opt/SUNWcluster/bin/pnmstat -l ..."
	/opt/SUNWcluster/bin/pnmstat -l >> $outfile
   fi

   if [[ -x /usr/cluster/bin/scconf ]]	# SC3.x
   then
	echo "\n" >> $outfile
	echo "# /usr/cluster/bin/scconf -p -v\n" >> $outfile
	echo "$log_stamp # /usr/cluster/bin/scconf -p -v ..."
	/usr/cluster/bin/scconf -p -v >> $outfile
   fi

   if [[ -x /usr/cluster/bin/scstat ]]	# SC3.x
   then
	echo "\n" >> $outfile
	echo "# /usr/cluster/bin/scstat\n" >> $outfile
	echo "$log_stamp # /usr/cluster/bin/scstat ..."
	/usr/cluster/bin/scstat >> $outfile
   fi

   if [[ -x /usr/cluster/bin/pnmstat ]]	# SC3.x
   then
	echo "\n" >> $outfile
	echo "# /usr/cluster/bin/pnmstat -l\n" >> $outfile
	echo "$log_stamp # /usr/cluster/bin/pnmstat -l ..."
	/usr/cluster/bin/pnmstat -l >> $outfile
   fi

   if [[ -x /usr/cluster/bin/scrgadm ]]	# SC3.x
   then
	echo "\n" >> $outfile
	echo "# /usr/cluster/bin/scrgadm -p\n" >> $outfile
	echo "$log_stamp # /usr/cluster/bin/scrgadm -p ..."
	/usr/cluster/bin/scrgadm -p >> $outfile
   fi

   if [[ -x /usr/cluster/bin/scrgadm ]]	# SC3.x
   then
	echo "\n" >> $outfile
	echo "# /usr/cluster/bin/scrgadm -p -v\n" >> $outfile
	echo "$log_stamp # /usr/cluster/bin/scrgadm -p -v ..."
	/usr/cluster/bin/scrgadm -p -v >> $outfile
   fi

#   if[ $HA -ne 0 ] || [ [ $VERBOSE -ne 0 ] && [ -f /usr/cluster/bin/scrgadm ] ]
   if [[ -f /usr/cluster/bin/scrgadm ]]
   then
	echo "\n" >> $outfile
	echo "# /usr/cluster/bin/scrgadm -p -vv\n" >> $outfile
	echo "$log_stamp # /usr/cluster/bin/scrgadm -p -vv ..."
	/usr/cluster/bin/scrgadm -p -vv >> $outfile

	#######  SC3 Data Svc Agent listings  ########

     print_hdr=1

     for i in `scrgadm -p -vv | grep "base directory:" | /usr/bin/awk '{ print $6 }'`
     do

	if [[ $print_hdr -eq 1 ]]
	then
		echo "\n$log_stamp ## Probing SC3 DATA SVC Agent FILES ..."
		echo "##############  Sun Cluster 3 DataSvc Agent Files ###########\n\n" >> $outfile
		print_hdr=0
	fi

	for j in $i/*	##### Go through the agent files per dir
	do
		file $j | grep -i "script"
		ret=$?

		if [[ $ret -ne 0 ]]	## not a shell script, skip
		then
			continue
		fi

		echo "" >> $outfile

		echo "\n\t>>>>>>>  $j  <<<<<<<<\n" >> $outfile
		cat $j >> $outfile
		echo "\n_____________________________________________________\n" >> $outfile
	done

     done

   fi

# 	Veritas VCS CONFIG DATA ............

log_stamp='sys_diag:'`date '+%m%d_%H%M%S'`':'

   if [[ -x /opt/VRTSvcs/bin/hastatus ]]	# VCS hastatus cluster summary
   then
	echo "\n" >> $outfile
   	echo "\n$log_stamp ######  Veritas VCS Clustering INFO  ######"
	echo "# /opt/VRTSvcs/bin/hastatus -sum\n" >> $outfile
	echo "$log_stamp # /opt/VRTSvcs/bin/hastatus -sum ..."
	/opt/VRTSvcs/bin/hastatus -sum >> $outfile
   fi

   if [[ -x /opt/VRTS/bin/hares ]]	# VCS hares cluster status
   then
	echo "\n" >> $outfile
   	echo "\n$log_stamp ######  Veritas VCS Clustering INFO  ######"
	echo "# /opt/VRTS/bin/hares -state\n" >> $outfile
	echo "$log_stamp # /opt/VRTS/bin/hares -state ..."
	/opt/VRTS/bin/hares -state >> $outfile
   fi


   if [[ -x /sbin/gabconfig ]]	# VCS/CRS Global membership Atomic Broadcast: GAB
   then
	echo "\n" >> $outfile
	echo "# /sbin/gabconfig -a\n" >> $outfile
	echo "$log_stamp # /sbin/gabconfig -a ..."
	/sbin/gabconfig -a >> $outfile
   fi

   if [[ -f /etc/llttab ]]	# VCS node/host entry table
   then
	echo "\n" >> $outfile
	echo "# cat /etc/llttab\n" >> $outfile
	echo "$log_stamp # cat /etc/llttab ..."
	cat /etc/llttab >> $outfile
   fi

   if [[ -f /etc/llhosts ]]	# VCS LLT host interconnects 
   then
	echo "\n" >> $outfile
	echo "# cat /etc/llhosts\n" >> $outfile
	echo "$log_stamp # cat /etc/llhosts ..."
	cat /etc/llhosts >> $outfile
   fi

   if [[ -x /sbin/lltstat ]]	# 	VCS LLT transport (private links)
   then
	echo "# /sbin/lltstat -P\n" >> $outfile
	echo "$log_stamp # /sbin/lltstat -P ..."
	/sbin/lltstat -P >> $outfile

	echo "# /sbin/lltstat -n\n" >> $outfile
	echo "$log_stamp # /sbin/lltstat -n ..."
	/sbin/lltstat -n >> $outfile

	echo "# /sbin/lltstat -c\n" >> $outfile
	echo "$log_stamp # /sbin/lltstat -c ..."
	/sbin/lltstat -c >> $outfile

	echo "# /sbin/lltstat -l\n" >> $outfile
	echo "$log_stamp # /sbin/lltstat -l ..."
	/sbin/lltstat -l >> $outfile
   fi

   if [[ -f /etc/VRTSvcs/conf/config/main.cf ]]	# VCS main config file
   then
	echo "" >> $outfile
	echo "\n_____________________________________________________\n" >> $outfile
	echo "# cat /etc/VRTSvcs/conf/config/main.cf\n" >> $outfile
	echo "$log_stamp # cat /etc/VRTSvcs/conf/config/main.cf ..."
	cat /etc/VRTSvcs/conf/config/main.cf >> $outfile
	echo "\n_____________________________________________________\n" >> $outfile
   fi

fi



###################  APPLICATION / ORACLE CONFIG FILES  ######################

log_stamp='sys_diag:'`date '+%m%d_%H%M%S'`':'


if [[ ( $ALL -ne 0 ) || ( $ORACLE -ne 0 ) || ( $N1 -ne 0 ) || ( $APPS -ne 0 ) ]]
then


################  N1 CONFIGURATION INFO  #################

#if [ $ALL -ne 0 ] || [ $N1 -ne 0 ] || [ $CONFIG -ne 0 ]
#then

   echo "\n$log_stamp ######  SUN N1 Configuration INFO  ######"
   echo "" >> $outfile
   echo "## 16 ##################  Sun N1 Config INFO  ################################\n" >> $outfile


   if [[ -f /opt/terraspring/sbin/farm ]]		# N1 - list farms
   then

      echo "" >> $outfile
      echo "# /opt/terraspring/sbin/farm -l\n" >> $outfile
      echo "$log_stamp # /opt/terraspring/sbin/farm -l ..."
      /opt/terraspring/sbin/farm -l >> $outfile


      for i in `/opt/terraspring/sbin/farm -l | grep -v "FARM_ID" | /usr/bin/awk '{ print $1 }'`
      do

   	if [[ -f /opt/terraspring/sbin/lr ]]	# N1 - list farm resources
   	then
		echo "" >> $outfile

		echo "\n\t>>>>>>>  FARM_ID=$i  <<<<<<<<\n" >> $outfile
		echo "# /opt/terraspring/sbin/lr -l $i\n" >> $outfile
		echo "$log_stamp # /opt/terraspring/sbin/lr -l $i..."
		/opt/terraspring/sbin/lr -l $i >> $outfile
   	fi

      done

   fi


   if [[ ( -f /opt/terraspring/sbin/device ) && ( $VERBOSE -ne 1 ) ]]
   then
	echo "" >> $outfile
	echo "# /opt/terraspring/sbin/device -l\n" >> $outfile
	echo "$log_stamp # /opt/terraspring/sbin/device -l ..."
	/opt/terraspring/sbin/device -l >> $outfile

   elif [[ ( -f /opt/terraspring/sbin/device ) && ( $VERBOSE -eq 1 ) ]]
   then
	echo "" >> $outfile
	echo "# /opt/terraspring/sbin/device -lv\n" >> $outfile
	echo "$log_stamp # /opt/terraspring/sbin/device -lv ..."
	/opt/terraspring/sbin/device -lv >> $outfile

#   else
#	echo "\n/opt/terraspring/sbin/device NOT found, skipping.\n" >> $outfile
#	echo "$log_stamp  /opt/terraspring/sbin/device NOT found, skipping.\n"
   fi


   if [[ ( -f /opt/terraspring/sbin/image ) && ( $VERBOSE -ne 1 ) ]]
   then
	echo "" >> $outfile
	echo "# /opt/terraspring/sbin/image -lv\n" >> $outfile
	echo "$log_stamp # /opt/terraspring/sbin/image -lv ..."
	/opt/terraspring/sbin/image -lv >> $outfile

   elif [[ ( -f /opt/terraspring/sbin/image ) && ( $VERBOSE -eq 1 ) ]]
   then
	echo "" >> $outfile
	echo "# /opt/terraspring/sbin/image -lV\n" >> $outfile
	echo "$log_stamp # /opt/terraspring/sbin/image -lV ..."
	/opt/terraspring/sbin/image -lV >> $outfile

#  else
#	echo "\n/opt/terraspring/sbin/image NOT found, skipping.\n" >> $outfile
#	echo "$log_stamp  /opt/terraspring/sbin/image NOT found, skipping.\n"
   fi


   if [[ -f /opt/terraspring/sbin/subnet ]]	# N1 - list subnets
   then
	echo "" >> $outfile
	echo "# /opt/terraspring/sbin/subnet -l\n" >> $outfile
	echo "$log_stamp # /opt/terraspring/sbin/subnet -l ..."
	/opt/terraspring/sbin/subnet -l >> $outfile
   fi


   if [[ -f /opt/terraspring/sbin/vlan ]]		# N1 - list vlans
   then
	echo "" >> $outfile
	echo "# /opt/terraspring/sbin/vlan -l\n" >> $outfile
	echo "$log_stamp # /opt/terraspring/sbin/vlan -l ..."
	/opt/terraspring/sbin/vlan -l >> $outfile
   fi


   if [[ -f /opt/terraspring/sbin/vlanconfig ]]	# N1
   then

	for i in `/opt/terraspring/sbin/device -l | grep -v "DEVICE_ID" | /usr/bin/awk '{ print $1 }'`
   	do
		echo "" >> $outfile
		echo "# /opt/terraspring/sbin/vlanconfig -lV $i\n" >> $outfile
		echo "$log_stamp # /opt/terraspring/sbin/vlanconfig -lV $i..."
		/opt/terraspring/sbin/vlanconfig -lV $i >> $outfile
	done
   fi

   if [[ ( -f /opt/terraspring/sbin/image ) && ( $VERBOSE -eq 1 ) ]]
   then

	for i in `/opt/terraspring/sbin/device -l | grep -v "DEVICE_ID" | /usr/bin/awk '{ print $1 }'`
   	do
		echo "" >> $outfile
		echo "# /opt/terraspring/sbin/showconf $i\n" >> $outfile
		echo "$log_stamp # /opt/terraspring/sbin/showconf $i..."
		/opt/terraspring/sbin/showconf $i >> $outfile
	done
   fi


   if [[ -f /opt/terraspring/sbin/request ]]	# N1
   then
	echo "" >> $outfile
	echo "# /opt/terraspring/sbin/request -l\n" >> $outfile
	echo "$log_stamp # /opt/terraspring/sbin/request -l ..."
	/opt/terraspring/sbin/request -l >> $outfile
   fi


   if [[ -f /opt/terraspring/sbin/aps ]]	# N1
   then
	echo "" >> $outfile
	echo "# /opt/terraspring/sbin/aps\n" >> $outfile
	echo "$log_stamp # /opt/terraspring/sbin/aps ..."
	/opt/terraspring/sbin/aps >> $outfile
   fi


   if [[ ( -f /opt/terraspring/sbin/wmld ) && ( $VERBOSE -eq 1 ) ]]
   then
	echo "" >> $outfile
	echo "# /opt/terraspring/sbin/wmld -c\n" >> $outfile
	echo "$log_stamp # /opt/terraspring/sbin/wmld -c ..."
	/opt/terraspring/sbin/wmld -c >> $outfile
   fi


   if [[ ( -f /var/adm/tspr.debug ) && ( $VERBOSE -ne 1 ) ]]
   then
	echo "\n" >> $outfile
	echo "\n_____________________________________________________\n" >> $outfile
	echo "# tail -120 /var/adm/tspr.debug\n" >> $outfile
	echo "$log_stamp # tail -120 /var/adm/tspr.debug ..."
	tail -120 /var/adm/tspr.debug >> $outfile 2>&1

   elif [[ ( -f /var/adm/tspr.debug ) && ( $VERBOSE -eq 1 ) ]]
   then
	echo "\n" >> $outfile
	echo "\n_____________________________________________________\n" >> $outfile
	echo "# tail -400 /var/adm/tspr.debug\n" >> $outfile
	echo "$log_stamp # tail -400 /var/adm/tspr.debug ..."
	tail -400 /var/adm/tspr.debug >> $outfile 2>&1
	echo "\n_____________________________________________________\n" >> $outfile
   fi


   if [[ ( -f /etc/opt/terraspring/tspr.properties ) && ( $VERBOSE -eq 1 ) ]]
   then
	echo "\n" >> $outfile
	echo "# cat /etc/etc/opt/terraspring/tspr.properties\n" >> $outfile
	echo "$log_stamp # cat /etc/opt/terraspring/tspr.properties ..."
	cat /etc/opt/terraspring/tspr.properties >> $outfile
   fi

#fi


#############   ORACLE CONFIG FILES  ##############

log_stamp='sys_diag:'`date '+%m%d_%H%M%S'`':'


#if [ $ALL -ne 0 ] || [ $ORACLE -ne 0 ] || [ $APPS -ne 0 ]
#then

   echo "" >> $outfile
   echo "\n$log_stamp ######  APPLICATION / ORACLE CONFIG FILES  ######"
   echo "## 17 #############  APPLICATION / ORACLE Config Files  ##############\n\n" >> $outfile

if [[ ${ORACLE_BASE:-UNSET} = "UNSET" ]]	## if not set, then set to default
then
	if [[ -d /opt/oracle ]]	## if not set, then set to default
	then
		ORACLE_BASE="/opt/oracle/"
	fi
fi

if [[ ${ORACLE_HOME:-UNSET} = "UNSET" ]]
then
	if [[ -d /opt/oracle/product/10g_dbs ]]	## if not set, then set to default
	then
		ORACLE_HOME="/opt/oracle/product/10g_dbs"
	fi
fi

if [[ ${ORA_CRS_HOME:-UNSET} = "UNSET" ]]
then
	if [[ -d /opt/oracle/product/10g_crs ]]	## if not set, then set to default
	then
		ORA_CRS_HOME="/opt/oracle/product/10g_crs"
	fi
fi


   if [[ -f /var/opt/oracle/oratab ]]
   then
	echo "# cat /var/opt/oracle/oratab\n" >> $outfile
	cat /var/opt/oracle/oratab >> $outfile

	ora_dir=`grep "^*:*" /var/opt/oracle/oratab | cut -d":" -f2`

	if [[ -d $ora_dir ]]
	then
		for i in $ora_dir/*/*/*.ora
		do
			echo "\n\t>>>>>>>  $i  <<<<<<<<\n" >> $outfile
			cat $i >> $outfile
			echo "\n_____________________________________________________\n" >> $outfile
			echo "\n" >> $outfile
		done

		for i in $ora_dir/*/*.ora
		do
			echo "\n\t>>>>>>>  $i  <<<<<<<<\n" >> $outfile
			cat $i >> $outfile
			echo "\n_____________________________________________________\n" >> $outfile
			echo "\n" >> $outfile
		done

		for i in $ora_dir/*.ora
		do
			echo "\n\t>>>>>>>  $i  <<<<<<<<\n" >> $outfile
			cat $i >> $outfile
			echo "\n_____________________________________________________\n" >> $outfile
			echo "\n" >> $outfile
		done
	fi

   fi

   if [[ -f /var/opt/oracle/tnsnames.ora ]]
   then
	echo "\n" >> $outfile
	echo "# cat /var/opt/oracle/tnsnames.ora\n" >> $outfile
	cat /var/opt/oracle/tnsnames.ora >> $outfile
	echo "\n_____________________________________________________\n" >> $outfile
   fi


   if [[ -f /var/opt/oracle/listener.ora ]]
   then
	echo "\n" >> $outfile
	echo "# cat /var/opt/oracle/listener.ora\n" >> $outfile
	cat /var/opt/oracle/listener.ora >> $outfile
	echo "\n_____________________________________________________\n" >> $outfile
   fi


   if [[ -f /var/opt/oracle/sqlnet.ora ]]
   then
	echo "\n" >> $outfile
	echo "# cat /var/opt/oracle/sqlnet.ora\n" >> $outfile
	cat /var/opt/oracle/sqlnet.ora >> $outfile
	echo "\n_____________________________________________________\n" >> $outfile
   fi


   if [[ -f /oracle/product/*/dbs/init.ora ]]
   then
	echo "\n" >> $outfile
	echo "# cat /oracle/product/*/dbs/init.ora\n" >> $outfile
	cat /oracle/product/*/dbs/init.ora >> $outfile
	echo "\n_____________________________________________________\n" >> $outfile
   fi


   if [[ -f /oracle/product/*/dbs/init?*.ora ]]
   then
	echo "\n" >> $outfile
	echo "# cat /oracle/product/*/dbs/init?*.ora\n" >> $outfile
#	cat /oracle/product/*/dbs/init?*.ora >> $outfile

	for i in /oracle/product/*/dbs/init?*.ora
	do
		echo "\n\t>>>>>>>  $i  <<<<<<<<\n" >> $outfile
		cat $i >> $outfile
		echo "\n" >> $outfile
		echo "\n_____________________________________________________\n" >> $outfile
	done

   else
   	if [[ -f /*/app/oracle/product/*/dbs/init?*.ora ]]
   	then
		echo "\n" >> $outfile
		echo "# cat /*/app/oracle/product/*/dbs/init?*.ora\n" >> $outfile
	
		for i in /*/app/oracle/product/*/dbs/init?*.ora
		do
			echo "\n\t>>>>>>>  $i  <<<<<<<<\n" >> $outfile
			cat $i >> $outfile
			echo "\n_____________________________________________________\n" >> $outfile
			echo "\n" >> $outfile
		done
	fi
   fi

   if [[ -x $ORA_CRS_HOME/bin/crs_stat ]]
   then
	echo "\n" >> $outfile
	echo "# $ORA_CRS_HOME/bin/crs_stat ...\n"
	echo "# $ORA_CRS_HOME/bin/crs_stat\n" >> $outfile
	$ORA_CRS_HOME/bin/crs_stat >> $outfile
   fi
	

######## SYMON / SUNMC (Sun Mgmt Center) .cfg files #########

   if [[ ( $VERBOSE -ne 0 ) && ( -d /var/opt/SUNWsymon/cfg/ ) ]]	
   then
	for i in /var/opt/SUNWsymon/cfg/*.cfg
	do
   		echo "" >> $outfile
   		echo "\n$log_stamp ##  SunMC Config Files ..."
   		echo "############  SUN Management Center Config Files  ###########\n\n" >> $outfile
		echo "\n\t>>>>>>>  $i  <<<<<<<<\n" >> $outfile
		cat $i >> $outfile
		echo "\n_____________________________________________________\n" >> $outfile
		echo "\n" >> $outfile
	done
   fi

log_stamp='sys_diag:'`date '+%m%d_%H%M%S'`':'

######## SunRay Server SW Config and Log files... #########
## TBD.. utfwadm, utcapture, /etc/opt/SUNWut/smartcard


   if [[ -x /opt/SUNWut/sbin/utsession ]]	## SunRay Sessions
   then
	echo "\n" >> $outfile
	echo "# /opt/SUNWut/sbin/utsession -p\n" >> $outfile
	/opt/SUNWut/sbin/utsession -p >> $outfile
	echo "\n\n\n" >> $outfile
   fi

   if [[ -x /opt/SUNWut/sbin/utgstatus ]]	## SunRay FailOver Group
   then
	echo "\n" >> $outfile
	echo "# /opt/SUNWut/sbin/utgstatus\n" >> $outfile
	/opt/SUNWut/sbin/utgstatus >> $outfile
	echo "\n\n\n" >> $outfile
   fi

   if [[ -x /opt/SUNWut/bin/utwho ]]	## SunRay Sessions
   then
	echo "\n" >> $outfile
	echo "# /opt/SUNWut/bin/utwho -c -a -H\n" >> $outfile
	/opt/SUNWut/bin/utwho -c -a -H >> $outfile
	echo "\n\n\n" >> $outfile
   fi

   if [[ -x /opt/SUNWut/sbin/utadm ]]	## SunRay Svr Priv net cfg
   then
	echo "\n" >> $outfile
	echo "# /opt/SUNWut/sbin/utadm -p\n" >> $outfile
	/opt/SUNWut/sbin/utadm -p >> $outfile
	echo "\n\n\n" >> $outfile
   fi

   if [[ -x /opt/SUNWut/sbin/utadm ]]	## SunRay Svr LAN cfg
   then
	echo "\n" >> $outfile
	echo "# /opt/SUNWut/sbin/utadm -l\n" >> $outfile
	/opt/SUNWut/sbin/utadm -l >> $outfile
	echo "\n\n\n" >> $outfile
   fi


   if [[ -x /opt/SUNWut/sbin/utfwload ]]	## SunRay Svr LAN cfg
   then
	echo "\n" >> $outfile
	echo "# /opt/SUNWut/sbin/utfwload -a -H\n" >> $outfile
	/opt/SUNWut/sbin/utfwload -a -H >> $outfile
	echo "\n\n\n" >> $outfile
   fi

   if [[ -x /opt/SUNWut/sbin/utdevadm ]]		## SunRay Svr Devices..
   then
	echo "\n" >> $outfile
	echo "# /opt/SUNWut/sbin/utdevadm\n" >> $outfile
	/opt/SUNWut/sbin/utdevadm >> $outfile
	echo "\n\n\n" >> $outfile
   fi

   if [[ -r /etc/opt/SUNWut/auth.props ]]
   then
	echo "\n" >> $outfile
	echo "# cat /etc/opt/SUNWut/auth.props\n" >> $outfile
	cat /etc/opt/SUNWut/auth.props >> $outfile
	echo "\n\n\n" >> $outfile
   fi

   if [[ -r /etc/opt/SUNWut/auth.permit ]]
   then
	echo "\n" >> $outfile
	echo "# cat /etc/opt/SUNWut/auth.permit\n" >> $outfile
	cat /etc/opt/SUNWut/auth.permit >> $outfile
	echo "\n\n\n" >> $outfile
   fi

   if [[ -r /etc/opt/SUNWut/policy/utpolicy ]]
   then
	echo "\n" >> $outfile
	echo "# cat /etc/opt/SUNWut/policy/utpolicy\n" >> $outfile
	cat /etc/opt/SUNWut/policy/utpolicy >> $outfile
	echo "\n\n\n" >> $outfile
   fi

   log_stamp='sys_diag:'`date '+%m%d_%H%M%S'`':'

   if [[ $VERBOSE -ne 0 ]]
   then

     if [[ -f /etc/opt/SUNWconn/ldap/current/dsserv.conf* ]]
     then

	echo "\n" >> $outfile
	echo "# cat /etc/opt/SUNWconn/ldap/current/dsserv.conf*\n" >> $outfile

	for i in /etc/opt/SUNWconn/ldap/current/dsserv.conf*
	do
		echo "\n\t>>>>>>>  $i  <<<<<<<<\n" >> $outfile
		cat $i >> $outfile
		echo "\n_____________________________________________________\n" >> $outfile
		echo "\n" >> $outfile
	done
     fi

     if [[ -f /var/adm/log/ut*.log ]]
     then
	echo "\n" >> $outfile
	echo "# cat /var/adm/log/ut*.log\n" >> $outfile

	for i in /var/adm/log/ut*.log
	do
		echo "\n\t>>>>>>>  $i  <<<<<<<<\n" >> $outfile
		cat $i >> $outfile
		echo "\n_____________________________________________________\n" >> $outfile
		echo "\n" >> $outfile
	done
     fi

   fi

   if [[ -r /etc/dt/config/Xservers ]]
   then
	echo "\n" >> $outfile
	echo "# cat /etc/dt/config/Xservers\n" >> $outfile
	cat /etc/dt/config/Xservers >> $outfile
	echo "\n\n\n" >> $outfile
   fi

   if [[ -r /etc/dt/config/Xconfig ]]
   then
	echo "\n" >> $outfile
	echo "# cat /etc/dt/config/Xconfig\n" >> $outfile
	cat /etc/dt/config/Xconfig >> $outfile
	echo "\n\n\n" >> $outfile
   fi


fi

log_stamp='sys_diag:'`date '+%m%d_%H%M%S'`':'

##########################  PACKAGE / PATCH INFO  #########################

if [[ ( $ALL -ne 0 ) || ( $CONFIG -ne 0 ) || ( $PATCHMGT -ne 0 ) ]]
then
	echo "" >> $outfile
	echo "\n$log_stamp ######  PACKAGE INFO / SOLARIS REGISTRY  ######"
	echo "## 18 ################  INSTALLED PACKAGES / SOLARIS REGISTRY ################\n\n" >> $outfile

	if [[ ( $Solaris_Rev -gt 8 ) && ( -x /usr/bin/prodreg ) ]]  # Solaris Product Registry
	then
		echo "# /usr/bin/prodreg browse\n" >> $outfile
		echo "$log_stamp # /usr/bin/prodreg browse ..."
		/usr/bin/prodreg browse >> $outfile
	fi

	echo "\n\n# /usr/bin/pkginfo\n" >> $outfile
	echo "$log_stamp # /usr/bin/pkginfo ..."
	/usr/bin/pkginfo >> $outfile

	if [[ $LONG -ne 0 ]]
	then
		echo "\n\n\n\n" >> $outfile
		echo "# /usr/bin/pkginfo -l  ***** STORED in : $pkginfo_file\n" >> $outfile
		echo "$log_stamp # /usr/bin/pkginfo -l ..."
		/usr/bin/pkginfo  -l >> $pkginfo_file
	fi

	echo "" >> $outfile
	echo "\n$log_stamp ######  PATCH INFO  ######"
	echo "## 19 ####################  INSTALLED PATCHES / INFO #####################\n\n" >> $outfile

	echo "# /usr/bin/showrev -p\n" >> $outfile
	echo "$log_stamp # /usr/bin/showrev -p ..."
	/usr/bin/showrev -p >> $outfile


	if [[ -d $PATCH_UTILITY_DIR ]]
	then
		echo "\n# $PATCH_UTILITY_CMD\n" >> $outfile
		echo "$log_stamp # $PATCH_UTILITY_CMD ..."
		$PATCH_UTILITY_DIR/$PATCH_UTILITY_CMD >> $outfile

	elif [[ -x /opt/patchdiag*/patchdiag ]]
	then
		echo "\n" >> $outfile
		echo "# patchdiag -l\n" >> $outfile
		echo "$log_stamp # patchdiag -l ..."
		/opt/patchdiag*/patchdiag -l >> $outfile

	elif [[ -x /usr/sadm/bin/smpatch ]]
	then
		echo "\n" >> $outfile
		echo "$log_stamp # /usr/sadm/bin/smpatch analyze  NOT RUN, passwd required...."
#		echo "# /usr/sadm/bin/smpatch analyze\n" >> $outfile
#		echo "$log_stamp # /usr/sadm/bin/smpatch analyze ..."
#		/usr/sadm/bin/smpatch analyze >> $outfile
	else
		echo "\n\n### NOTE: NO PATCH DIAGNOSTIC UTILITY found, skipping... ###\n\n" >> $outfile
		echo "$log_stamp  * NO Patch Diagnostic Utility found, skipping.\n"
	fi

fi



#######################  CRONTAB FILE LISTINGS  ######################

log_stamp='sys_diag:'`date '+%m%d_%H%M%S'`':'

if [[ ( $ALL -ne 0 ) || ( $CONFIG -ne 0 ) ]]
then

	print_hdr=1

	for i in /var/spool/cron/crontabs/*
	do
		echo "" >> $outfile

		if [[ $print_hdr -eq 1 ]]
		then
			echo "\n$log_stamp ######  CRONTAB FILE LISTINGS  ######"
			echo "## 20 #################  CRONTAB FILE LISTINGS  ######################\n\n" >> $outfile
			print_hdr=0
		fi

		echo "\n\t>>>>>>>  $i  <<<<<<<<\n" >> $outfile
		cat $i >> $outfile
	done


fi


########################  FMD / SYSTEM MESSAGES ...  #########################


log_stamp='sys_diag:'`date '+%m%d_%H%M%S'`':'
if [[ ( $ALL -ne 0 ) || ( $LONG -ne 0 ) || ( $PERF -ne 0 ) ]]
then
	echo "" >> $outfile
	echo "\n$log_stamp ######  FMD / SYSTEM MESSAGE/LOG FILES  ######"
	echo "## 21 #################  FMD / SYSTEM MESSAGE / LOG FILES  ######################\n\n" >> $outfile



	if [[ -x /usr/sbin/fmadm ]]	# S10 FMD...
	then
		echo "\n\n# /usr/sbin/fmadm config\n" >> $outfile
		echo "$log_stamp # /usr/sbin/fmadm config ..."
		/usr/sbin/fmadm config >> $outfile
	fi

	if [[ -x /usr/sbin/fmdump ]]	# S10 FMD...
	then
		echo "# /usr/sbin/fmdump\n" >> $outfile
		echo "$log_stamp # /usr/sbin/fmdump ..."
		/usr/sbin/fmdump >> $outfile
	fi

	if [[ -x /usr/sbin/fmstat ]]	# S10 FMD...
	then
		echo "\n\n# /usr/sbin/fmstat\n" >> $outfile
		echo "$log_stamp # /usr/sbin/fmstat ..."
		/usr/sbin/fmstat >> $outfile
	fi


	if [[ ( $LONG -ne 0 ) || ( $PERF -ne 0 ) ]]
	then
		echo "\n\n# tail -250 /var/adm/messages\n" >> $outfile
		echo "$log_stamp # tail -250 /var/adm/messages ..."
		tail -250 /var/adm/messages >> $outfile

		echo "\n\n######## [/var/adm/messages] *ERRORS* #########:\n" >> $analysis_efile
		grep -i -n error /var/adm/messages >> $analysis_efile
		grep -i -n failure /var/adm/messages >> $analysis_wfile
		
		echo "\n\n######## [/var/adm/messages] *WARNINGS* #######:\n" >> $analysis_wfile
		grep -i -n warning /var/adm/messages >> $analysis_wfile
		grep -i -n not /var/adm/messages >> $analysis_wfile


		echo "\n" >> $outfile
		echo "# /usr/bin/dmesg | tail -250\n" >> $outfile
		echo "$log_stamp # /usr/bin/dmesg ..."
		/usr/bin/dmesg | tail -250 >> $outfile

		echo "\n\n######## [/usr/bin/dmesg] *ERRORS* #########:\n" >> $analysis_efile
		/usr/bin/dmesg | grep -i -n error >> $analysis_efile
		/usr/bin/dmesg | grep -i -n failure >> $analysis_efile
		
		echo "\n\n######## [/usr/bin/dmesg] *WARNINGS* #######:\n" >> $analysis_wfile
		/usr/bin/dmesg | grep -i -n warning >> $analysis_wfile
		/usr/bin/dmesg | grep -i -n not >> $analysis_wfile


        	if [[ -d /opt/SUNWssp ]]
		then
			echo "\n" >> $outfile
			echo "# tail -250 $SSPOPT/adm/messages\n" >> $outfile
			echo "$log_stamp # tail -250 $SSPOPT/adm/messages ..."
			tail -250 $SSPOPT/adm/messages >> $outfile

			for i in /var/opt/SUNWssp/adm/*/messages
			do
				echo "\n\t>>>> tail -250 $i <<<<\n" >> $outfile
				tail -250 $i >> $outfile
				echo "\n" >> $outfile
			done
		fi

        	if [[ -d /opt/SUNWSMS ]]
		then
			echo "\n" >> $outfile
			echo "# /opt/SUNWSMS/bin/showlogs | tail -500\n" >> $outfile
			echo "$log_stamp # /opt/SUNWSMS/bin/showlogs | tail -500 ..."
			/opt/SUNWSMS/bin/showlogs | tail -500 >> $outfile

			echo "\n\n######## [/opt/SUNWSMS/bin/showlogs] *ERRORS* #########:\n" >> $analysis_efile
			/opt/SUNWSMS/bin/showlogs | grep -i -n error >> $analysis_efile
			
			echo "\n\n######## [/opt/SUNWSMS/bin/showlogs] *WARNINGS* #######:\n" >> $analysis_wfile
			/opt/SUNWSMS/bin/showlogs | grep -i -n warning >> $analysis_wfile
			/opt/SUNWSMS/bin/showlogs | grep -i -n not >> $analysis_wfile

		fi


        	if [[ -f /var/log/syslog ]]
        	then
                	echo "\n" >> $outfile
                	echo "# tail -500 /var/log/syslog\n" >> $outfile
                	echo "$log_stamp # tail -500 /var/log/syslog ..."
               		tail -500 /var/log/syslog >> $outfile

			echo "\n\n######## [/var/log/syslog] *ERRORS* #########:\n" >> $analysis_efile
			grep -i -n error /var/log/syslog >> $analysis_efile
			
			echo "\n\n######## [/var/log/syslog] *WARNINGS* #######:\n" >> $analysis_wfile
			grep -i -n warning /var/log/syslog >> $analysis_wfile
			grep -i -n not /var/log/syslog >> $analysis_wfile

        	else
               		echo "$log_stamp  /var/log/syslog NOT found, skipping.\n"
        	fi
	else
		echo "\n\n# tail -120 /var/adm/messages\n" >> $outfile
		echo "$log_stamp # tail -120 /var/adm/messages ..."
		tail -120 /var/adm/messages >> $outfile

		echo "\n" >> $outfile
		echo "# /usr/bin/dmesg | tail -120\n" >> $outfile
		echo "$log_stamp # /usr/bin/dmesg ..."
		/usr/bin/dmesg | tail -120 >> $outfile

        	if [[ -d /opt/SUNWssp ]]
		then
			echo "\n" >> $outfile
			echo "# tail -120 $SSPOPT/adm/messages\n" >> $outfile
			echo "$log_stamp # tail -120 $SSPOPT/adm/messages ..."
			tail -120 $SSPOPT/adm/messages >> $outfile

			for i in /var/opt/SUNWssp/adm/*/messages
			do
				echo "\n\t>>>> tail -120 $i <<<<\n" >> $outfile
				tail -120 $i >> $outfile
				echo "\n" >> $outfile
			done
		fi

        	if [[ -d /opt/SUNWSMS ]]		## SunFire 25K showlog info..
		then
			echo "\n" >> $outfile
			echo "# /opt/SUNWSMS/bin/showlogs | tail -120\n" >> $outfile
			echo "$log_stamp # /opt/SUNWSMS/bin/showlogs  | tail -120 ..."
			/opt/SUNWSMS/bin/showlogs | tail -120 >> $outfile
		fi

	fi

fi


#################  ASSET / CONFIGURATION MGMT - TRACKING ################

log_stamp='sys_diag:'`date '+%m%d_%H%M%S'`':'

if [[ $TRACK -ne 0 ]]
then

	if ( ! [ -w `echo $home_dir/sysd_cfg_mgt` ] )
	then
		mkdir $home_dir/sysd_cfg_mgt
		ret=$?

		if [[ $ret -ne 0 ]]
		then
			echo "ERROR: on  >> # mkdir $home_dir/sysd_cfg_mgt << , EXITING..\n" >> $outfile
			echo "$log_stamp ERROR on >> #mkdir $home_dir/sysd_cfg_mgt << , EXITING...."
			exit
		fi
		first_tracking=1
	else
		first_tracking=0
	fi

	afile_prtdiag=$home_dir'/sysd_cfg_mgt/'`date '+%y%m%d_%H%M'`'_prtdiag.cfg'
	afile_prtconf=$home_dir'/sysd_cfg_mgt/'`date '+%y%m%d_%H%M'`'_prtconf.cfg'
	afile_psrinfo=$home_dir'/sysd_cfg_mgt/'`date '+%y%m%d_%H%M'`'_psrinfo.cfg'
	afile_sysdef=$home_dir'/sysd_cfg_mgt/'`date '+%y%m%d_%H%M'`'_sysdef.cfg'
	afile_eeprom=$home_dir'/sysd_cfg_mgt/'`date '+%y%m%d_%H%M'`'_eeprom.cfg'
	afile_df=$home_dir'/sysd_cfg_mgt/'`date '+%y%m%d_%H%M'`'_df.cfg'
	afile_hosts=$home_dir'/sysd_cfg_mgt/'`date '+%y%m%d_%H%M'`'_F_hosts.cfg'
	afile_mnttab=$home_dir'/sysd_cfg_mgt/'`date '+%y%m%d_%H%M'`'_F_mnttab.cfg'
	afile_nsswitch=$home_dir'/sysd_cfg_mgt/'`date '+%y%m%d_%H%M'`'_F_nsswitch.cfg'
	afile_resolv=$home_dir'/sysd_cfg_mgt/'`date '+%y%m%d_%H%M'`'_F_resolve.cfg'
	afile_system=$home_dir'/sysd_cfg_mgt/'`date '+%y%m%d_%H%M'`'_F_system.cfg'
	afile_syslog=$home_dir'/sysd_cfg_mgt/'`date '+%y%m%d_%H%M'`'_F_syslog.cfg'
	afile_MANcf=$home_dir'/sysd_cfg_mgt/'`date '+%y%m%d_%H%M'`'_F_MANcf.cfg'
	afile_showplat=$home_dir'/sysd_cfg_mgt/'`date '+%y%m%d_%H%M'`'_showplat.cfg'
	afile_domainstatus=$home_dir'/sysd_cfg_mgt/'`date '+%y%m%d_%H%M'`'_domainstatus.cfg'
	afile_cfgadm=$home_dir'/sysd_cfg_mgt/'`date '+%y%m%d_%H%M'`'_cfgadm.cfg'
	afile_metadb=$home_dir'/sysd_cfg_mgt/'`date '+%y%m%d_%H%M'`'_metadb.cfg'
	afile_metastat=$home_dir'/sysd_cfg_mgt/'`date '+%y%m%d_%H%M'`'_metastat.cfg'
	afile_vxdisk=$home_dir'/sysd_cfg_mgt/'`date '+%y%m%d_%H%M'`'_vxdisk.cfg'
	afile_vxprint=$home_dir'/sysd_cfg_mgt/'`date '+%y%m%d_%H%M'`'_vxprint.cfg'

	afile_prtdiag_last=$home_dir'/sysd_cfg_mgt/prtdiag_last.cfg'
	afile_prtconf_last=$home_dir'/sysd_cfg_mgt/prtconf_last.cfg'
	afile_psrinfo_last=$home_dir'/sysd_cfg_mgt/psrinfo_last.cfg'
	afile_sysdef_last=$home_dir'/sysd_cfg_mgt/sysdef_last.cfg'
	afile_eeprom_last=$home_dir'/sysd_cfg_mgt/eeprom_last.cfg'
	afile_df_last=$home_dir'/sysd_cfg_mgt/df_last.cfg'
	afile_hosts_last=$home_dir'/sysd_cfg_mgt/fhosts_last.cfg'
	afile_mnttab_last=$home_dir'/sysd_cfg_mgt/fmnttab_last.cfg'
	afile_nsswitch_last=$home_dir'/sysd_cfg_mgt/fnsswitch_last.cfg'
	afile_resolv_last=$home_dir'/sysd_cfg_mgt/fresolve_last.cfg'
	afile_system_last=$home_dir'/sysd_cfg_mgt/fsystem_last.cfg'
	afile_syslog_last=$home_dir'/sysd_cfg_mgt/fsyslog_last.cfg'
	afile_MANcf_last=$home_dir'/sysd_cfg_mgt/fMANcf_last.cfg'
	afile_showplat_last=$home_dir'/sysd_cfg_mgt/showplat_last.cfg'
	afile_domainstatus_last=$home_dir'/sysd_cfg_mgt/domainstatus_last.cfg'
	afile_cfgadm_last=$home_dir'/sysd_cfg_mgt/cfgadm_last.cfg'
	afile_metadb_last=$home_dir'/sysd_cfg_mgt/metadb_last.cfg'
	afile_metastat_last=$home_dir'/sysd_cfg_mgt/metastat_last.cfg'
	afile_vxdisk_last=$home_dir'/sysd_cfg_mgt/vxdisk_last.cfg'
	afile_vxprint_last=$home_dir'/sysd_cfg_mgt/vxprint_last.cfg'

	afile_log=$home_dir'/sysd_cfg_mgt/'`uname -n`'_change_log.out'


	echo "" >> $outfile
	echo "\n$log_stamp ######  ASSET / CONFIG MGMT - TRACK'G ######"
	echo "## 22 #################  ASSET / CONFIG MGMT - TRACKING  ################\n\n" >> $outfile

	if [[ -x /usr/platform/`uname -m`/sbin/prtdiag ]]
	then
		echo "$log_stamp CONFIG CHK: STORING # /usr/platform/`uname -m`/sbin/prtdiag ..."
		/usr/platform/`uname -m`/sbin/prtdiag -v 1> $afile_prtdiag 2>&1

		if [[ $? -ne 0 ]]
		then
			rm $afile_prtdiag
		fi
	elif [[ -x /usr/platform/sun4u*/sbin/prtdiag ]]
	then
		echo "$log_stamp CONFIG CHK: STORING # /usr/platform/sun4u*/sbin/prtdiag ..."
		/usr/platform/sun4u*/sbin/prtdiag -v 1> $afile_prtdiag 2>&1
#
		if [[ $? -ne 0 ]]
		then
			rm $afile_prtdiag
		fi
	else
		echo "/usr/platform/sun4u*/sbin/prtdiag NOT found, skipping.\n" >> $outfile
		echo "$log_stamp  /usr/platform/sun4u*/sbin/prtdiag NOT found, skipping.\n"
	fi

	if [[ -x /usr/sbin/prtconf ]]
	then
		echo "$log_stamp CONFIG CHK: STORING # /usr/sbin/prtconf | grep Memory ..."
		/usr/sbin/prtconf | grep Memory 1> $afile_prtconf 2>&1
	fi

#	echo "\n" >> $outfile
#	echo "# vxprint -?\n" >> $outfile
#	echo "$log_stamp CONFIG CHK: # vxprint -? ..."
#	vxprint -? >> $outfile

	if [[ -x /usr/sbin/psrinfo ]]
	then
		echo "$log_stamp CONFIG CHK: STORING # /usr/sbin/psrinfo -v ..."
		/usr/sbin/psrinfo 1> $afile_psrinfo 2>&1
	fi

	if [[ -x /usr/sbin/sysdef ]]
	then
		echo "$log_stamp CONFIG CHK: STORING # /usr/sbin/sysdef -D..."
		/usr/sbin/sysdef -D 1> $afile_sysdef 2>&1
	fi

	if [[ -x /usr/sbin/eeprom ]]
	then
		echo "$log_stamp CONFIG CHK: STORING # /usr/sbin/eeprom ..."
		/usr/sbin/eeprom 1> $afile_eeprom 2>&1
	fi

	if [[ -x /usr/sbin/df ]]
	then
		echo "$log_stamp CONFIG CHK: STORING # /usr/sbin/df -k..."
		/usr/sbin/df -k 1> $afile_df 2>&1
	fi

	if [[ -x /opt/SUNWSMS/bin/showplatform ]]
	then
		echo "$log_stamp CONFIG CHK: STORING # showplatform -v ..."
		/opt/SUNWSMS/bin/showplatform -v 1> $afile_showplat 2>&1

		if [[ $? -ne 0 ]]
		then
			rm $afile_showplat
		fi
	fi

       	if [[ -d /opt/SUNWssp ]]			# E10K / SSP domain info
	then
		echo "$log_stamp CONFIG CHK: STORING # domain_status ..."
#		domain_status | tee $afile_domainstatus 1>/dev/null
		domain_status 1> $afile_domainstatus 2>&1

		if [[ $? -ne 0 ]]
		then
			rm $afile_domainstatus
		fi
	fi

	if [[ -x /usr/sbin/cfgadm ]]
	then
		echo "$log_stamp CONFIG CHK: STORING # /usr/sbin/cfgadm ..."
		/usr/sbin/cfgadm 1> $afile_cfgadm 2>&1

		if [[ $? -ne 0 ]]
		then
			rm $afile_cfgadm
		
			if [[ $ret -eq 2 ]]
			then
				echo "\t/usr/sbin/cfgadm NOT supported on this platform.\n" >> $outfile
				echo "$log_stamp WARNING: /usr/sbin/cfgadm NOT supported on this platform."
			fi
		fi
	fi

	if [[ -x /usr/sbin/metadb ]]		## Check for SDS/SLVM Config
	then
		echo "$log_stamp CONFIG CHK: STORING # /usr/sbin/metadb ..."
                /usr/sbin/metadb 1> $afile_metadb 2>&1

		if [[ $? -ne 0 ]]
		then
			rm $afile_metadb
		fi

		echo "$log_stamp CONFIG CHK: STORING # /usr/sbin/metastat ..."
                /usr/sbin/metastat 1> $afile_metastat 2>&1

		if [[ $? -ne 0 ]]
		then
			rm $afile_metastat
		fi
	fi

	if [[ -x /usr/sbin/vxdisk ]]
	then
		echo "$log_stamp CONFIG CHK: STORING # vxdisk list ..."
		/usr/sbin/vxdisk list 1> $afile_vxdisk 2>&1

		if [ $? -ne 0 ]
		then
			rm $afile_vxdisk
		fi
	fi

	if [[ -x /usr/sbin/vxprint ]]
	then
		echo "$log_stamp CONFIG CHK: STORING # vxprint -Ath ..."
		/usr/sbin/vxprint -Ath 1> $afile_vxprint 2>&1

		if [ $? -ne 0 ]
		then
			rm $afile_vxprint
		fi
	fi

### Configuration Files (Compare and/or Capture) ###

	if [[ -f /etc/hosts ]]
	then
		echo "$log_stamp CONFIG CHK: STORING * FILE: /etc/hosts ..."
#		cat /etc/hosts | tee $afile_hosts 1>/dev/null
		cp /etc/hosts $afile_hosts
	fi

	if [[ -f /etc/mnttab ]]
	then
		echo "$log_stamp CONFIG CHK: STORING * FILE: /etc/mnttab ..."
		cp /etc/mnttab $afile_mnttab
	fi

	if [[ -f /etc/nsswitch.conf ]]
	then
		echo "$log_stamp CONFIG CHK: STORING * FILE: /etc/nsswitch.conf ..."
		cp /etc/nsswitch.conf $afile_nsswitch
	fi

	if [[ -f /etc/resolv.conf ]]
	then
		echo "$log_stamp CONFIG CHK: STORING * FILE: /etc/resolv.conf ..."
		cp /etc/resolv.conf $afile_resolv
	fi

	if [[ -f /etc/system ]]
	then
		echo "$log_stamp CONFIG CHK: STORING * FILE: /etc/system ..."
		cp /etc/system $afile_system
	fi

	if [[ -f /etc/syslog.conf ]]
	then
		echo "$log_stamp CONFIG CHK: STORING * FILE: /etc/syslog.conf ..."
		cp /etc/syslog.conf $afile_syslog
	fi

	if [[ -f /etc/opt/SUNWSMS/config/MAN.cf ]]   # E25K / SC IP configs
	then
		echo "$log_stamp CONFIG CHK: STORING * FILE: /etc/opt/SUNWSMS/config/MAN.cf ..."
		cp /etc/opt/SUNWSMS/config/MAN.cf $afile_MANcf
	fi

	if [[ -f $infile ]]	## copy the configuration files from "-f infile" to new T/S files
	then
		config_date=`date '+%y%m%d_%H%M%S'`

		for I in `cat $infile`
		do	
			file_name=${I##*/}

			afile_infile=$home_dir'/sysd_cfg_mgt/'$config_date'_F_'$file_name'.cfg'
			
			if [[ -f $I ]]
			then
				echo "$log_stamp CONFIG CHK: STORING * (-f $infile) $I ..."
				cp $I $afile_infile
				ret=$?

				if [[ $ret -ne 0 ]]
				then
					echo "\n **ERROR copying $I to $afile_infile**\n"
				fi
			else
				echo "\n **ERROR** FILE : $I Does NOT Exist, ** NOT COPIED **\n"
			fi
		done
#	else
#		echo "\n **ERROR** FILE : $infile Does NOT Exist, ** NO FILES COPIED **\n"
	fi
#####
#
########## Compare latest to last Asset/Config files #############
#
    if [[ $first_tracking -eq 0 ]]	## IF this is not the first config capture/tracking
    then

	echo "______________________________________________________________________________________\n" >> $afile_log
	banner `date '+%m%d_%H%M'` >> $afile_log
	echo "______________________________________________________________________________________\n" >> $afile_log

#	first_page=1

	check_config $afile_prtdiag_last $afile_prtdiag $afile_log $outfile $DEBUG
	check_config $afile_prtconf_last $afile_prtconf $afile_log $outfile $DEBUG
	check_config $afile_psrinfo_last $afile_psrinfo $afile_log $outfile $DEBUG
	check_config $afile_sysdef_last $afile_sysdef $afile_log $outfile $DEBUG
	check_config $afile_eeprom_last $afile_eeprom $afile_log $outfile $DEBUG
#	check_config $afile_df_last $afile_df $afile_log $outfile $DEBUG

	check_config $afile_showplat_last $afile_showplat $afile_log $outfile $DEBUG
	check_config $afile_domainstatus_last $afile_domainstatus $afile_log $outfile $DEBUG
	check_config $afile_cfgadm_last $afile_cfgadm $afile_log $outfile $DEBUG

	if [[ -x /usr/sbin/metadb ]]
	then
		check_config $afile_metadb_last $afile_metadb $afile_log $outfile $DEBUG
		check_config $afile_metastat_last $afile_metastat $afile_log $outfile $DEBUG
	fi

	if [[ -x /usr/sbin/vxprint ]]
	then
		check_config $afile_vxdisk_last $afile_vxdisk $afile_log $outfile $DEBUG
		check_config $afile_vxprint_last $afile_vxprint $afile_log $outfile $DEBUG
	fi

	check_config $afile_hosts_last $afile_hosts $afile_log $outfile $DEBUG
	check_config $afile_mnttab_last $afile_mnttab $afile_log $outfile $DEBUG
	check_config $afile_nsswitch_last $afile_nsswitch $afile_log $outfile $DEBUG
	check_config $afile_resolv_last $afile_resolv $afile_log $outfile $DEBUG
	check_config $afile_system_last $afile_system $afile_log $outfile $DEBUG
	check_config $afile_syslog_last $afile_syslog $afile_log $outfile $DEBUG
	check_config $afile_MANcf_last $afile_MANcf $afile_log $outfile $DEBUG

	if [[ -f $infile ]]
	then
		for I in `cat $infile`
		do	
			file_name=${I##*/}

			afile_infile=$home_dir'/sysd_cfg_mgt/'$config_date'_F_'$file_name'.cfg'
			afile_infile_last=$home_dir'/sysd_cfg_mgt/F_'$file_name'_last.cfg'
			
			check_config $afile_infile_last $afile_infile $afile_log $outfile $DEBUG
		done
#	else
#		echo "\n **ERROR** FILE : $infile Does NOT Exist, ** NO FILES COPIED **\n"
	fi


	cp $afile_log $sysd_dir

    else    ## First Run with -C | -A ..so save latest datafiles as the _last config files

	if [[ -f `echo $afile_prtdiag` ]]
	then
		cp $afile_prtdiag $afile_prtdiag_last
	fi

	if [[ -f `echo $afile_prtconf` ]]
	then
		cp $afile_prtconf $afile_prtconf_last
	fi

	if [[ -f `echo $afile_psrinfo` ]]
	then
		cp $afile_psrinfo $afile_psrinfo_last
	fi

	if [[ -f `echo $afile_sysdef` ]]
	then
		cp $afile_sysdef $afile_sysdef_last
	fi

	if [[ -f `echo $afile_eeprom` ]]
	then
		cp $afile_eeprom $afile_eeprom_last
	fi

##	if [[ -f `echo $afile_df` ]]
##	then
##		cp $afile_df $afile_df_last
##	fi

## Config Files ##########

	if [[ -f `echo $afile_hosts` ]]
	then
		cp $afile_hosts $afile_hosts_last
	fi

	if [[ -f `echo $afile_mnttab` ]]
	then
		cp $afile_mnttab $afile_mnttab_last
	fi

	if [[ -f `echo $afile_nsswitch` ]]
	then
		cp $afile_nsswitch $afile_nsswitch_last
	fi

	if [[ -f `echo $afile_resolv` ]]
	then
		cp $afile_resolv $afile_resolv_last
	fi

	if [[ -f `echo $afile_system` ]]
	then
		cp $afile_system $afile_system_last
	fi

	if [[ -f `echo $afile_syslog` ]]
	then
		cp $afile_syslog $afile_syslog_last
	fi

	if [[ -f `echo $afile_MANcf` ]]
	then
		cp $afile_MANcf $afile_MANcf_last
	fi
#####
	if [[ -f `echo $afile_showplat` ]]
	then
		cp $afile_showplat $afile_showplat_last
	fi

	if [[ -f `echo $afile_domainstatus` ]]
	then
		cp $afile_domainstatus $afile_domainstatus_last
	fi

	if [[ -f `echo $afile_cfgadm` ]]
	then
		cp $afile_cfgadm $afile_cfgadm_last
	fi

	if [[ -f `echo $afile_metadb` ]]
	then
		cp $afile_metadb $afile_metadb_last
	fi

	if [[ -f `echo $afile_metastat` ]]
	then
		cp $afile_metastat $afile_metastat_last
	fi

	if [[ -f `echo $afile_vxdisk` ]]
	then
		cp $afile_vxdisk $afile_vxdisk_last
	fi

	if [[ -f $infile ]]	## Save copies of all config files from "-f infile" to _last.cfg
	then
		for I in `cat $infile`
		do	
			file_name=${I##*/}

			afile_infile=$home_dir'/sysd_cfg_mgt/'$config_date'_F_'$file_name'.cfg'
			afile_infile_last=$home_dir'/sysd_cfg_mgt/F_'$file_name'_last.cfg'
			
			if [[ -f $afile_infile ]]
			then
# keep this silent		echo "$log_stamp CONFIG CHK: STORING * (-f $infile) $I ..."
				cp $afile_infile $afile_infile_last
				ret=$?

				if [[ $ret -ne 0 ]]
				then
					echo "\n ** ERROR copying $afile_infile to $afile_infile_last **\n"
				fi
			else
				echo "\n **ERROR** FILE : $afile_infile Does NOT Exist, ** NOT COPIED **\n"
			fi
		done
#	else
#		echo "\n **ERROR** FILE : $infile Does NOT Exist, ** NO FILES COPIED **\n"
	fi

    fi	## END if/else ! FIRST_TRACKING


fi	#### END of ASSET/CONFIG MANAGEMENT SECTION ###


############################################################################
##########  wait and then KILL performance data collection  ##########

if [[ $PERF -ne 0 ]]
then
	log_stamp='sys_diag:'`date '+%m%d_%H%M%S'`':'

	wait_secs=$(($PERF_SECS-$SECONDS))	# seconds before end of collection

	half_secs=$(($PERF_SECS/2))
	secs_befmid=$(($wait_secs-$half_secs))	# seconds before half way point

	if [[ ( $secs_befmid -gt 0 ) || ( $wait_secs -gt 180 ) ]]
	then
		if [[ $secs_befmid -gt 0 ]]
		then
			echo "\n$log_stamp  ...WAITING $secs_befmid seconds for midpoint data collection...\n"
			sleep $secs_befmid

			echo "sys_diag: -------  MidPoint Process SNAPSHOT (# 1) -------\n"

			snap_bme_perf $sysd_dir 1 $DEBUG $PERF $VERBOSE

		else
			echo "sys_diag: -------  MidPoint Process SNAPSHOT (# 1) -------\n"

			snap_bme_perf $sysd_dir 1 $DEBUG $PERF $VERBOSE
		fi
	fi

	wait_secs=$(($PERF_SECS-$SECONDS))

	if [[ $wait_secs -gt 0 ]]
	then
		echo "\n$log_stamp  ... WAITING $wait_secs seconds for ENDPOINT data collection...\n"
		sleep $wait_secs
	fi

	if [[ $snooppid -gt 0 ]]
	then
		kill $snooppid 2>/dev/null
	fi
	
	kill $mppid $vmpid $iopid 2>/dev/null

	i=1
   	while [ $i -le $num_nets ]
   	do
		kill $((netpid[$i])) 2>/dev/null
		i=$(($i+1))
	done

#	i=1
#   	while [ $i -le $num_llts ]
#   	do
#		kill $((kstatpid[$i])) 2>/dev/null
#		i=$(($i+1))
#	done

	echo "\nsys_diag: -------  EndPoint Process SNAPSHOT (# 2) -------\n"

	### Snapshot the ending kstat network interface statistics

	num_nets=0

	for i in `/usr/sbin/ifconfig -a |  grep ": " | cut -d":" -f1`
	do
		if [[ ( $i = $last_nic ) && ( $num_nets -gt 0 ) ]]
		then
			continue	# Logical Layered Virtual NIC Interface, skip..
		else
			last_nic=$i
		fi
   		num_nets=$(($num_nets+1))

		kstat_file=$sysd_dir'/sysd_knete_'$i'_'`uname -n`'_'`date '+%y%m%d_%H%M%S'`'.out'
		echo "$log_stamp # /usr/bin/kstat -p -T u -n $i 2>&1"
		/usr/bin/kstat -p -T u -n $i > $kstat_file 2>&1

	done

	snap_bme_perf $sysd_dir 2 $DEBUG $PERF $VERBOSE   # final snap of END perf data


	lltfile=$sysd_dir'/sysd_llt_'`uname -n`'_'`date '+%y%m%d_%H%M%S'`'.out'
	if [[ -x /sbin/lltstat ]]		# VCS LLT interconnect stats,..if VCS
	then
		echo "\n**** VCS LLTSTAT Interconnect Packets after $knet_total_secs seconds ****\n" >> $lltfile
		/sbin/lltstat -l >> $lltfile
	fi

	echo "\n$log_stamp  ------- Data Collection COMPLETE -------"

	sleep 1
###

	echo "" >> $outfile
	echo "## 23 ##################  SYSTEM ANALYSIS : INITIAL FINDINGS #############\n\n" >> $outfile

	echo "\n\t****************** *! ERROR !* MESSAGES *******************:\n" >> $outfile
	cat $analysis_efile >> $outfile		## ERROR Message Listings

	echo "\n\t****************** *WARNING* MESSAGES *******************:\n" >> $outfile
	cat $analysis_wfile >> $outfile		## WARNING Message Listings

## ***	######### *** POST PPROCESSING OF PERFORMANCE DATA *** #############

	if [[ ( $POSTPERF -ne 0 ) && ( $SKIP_POSTPERF -eq 0 ) ]]
	then
	    echo "\n$log_stamp ######  SYSTEM ANALYSIS : INITIAL FINDINGS ... ######"
##
	    post_perf $sysd_dir $outfile $DEBUG $PERF $dash_file $home_dir # Post Processes the Perf data
	fi


fi	### END OF Performance Data Gathering and Analysis Section ###


html_file="$outfile.html"

gen_html_hdr $outfile $html_file $DEBUG $dash_file $PERF $hname


if [[ $SKIP_POSTPERF -eq 0 ]]	## IF you haven't skipped post processing with -S
then
	############  Generate .ps output (2 pages / pg landscape)   #################

	if [[ $POST -ne 0 ]]
	then
		outfile_ps="$outfile.ps"
		/usr/openwin/bin/mp -l $outfile > $outfile_ps
	fi

	############  Generate HTML (.html) REPORT ####################

	gen_html_rpt $outfile $html_file $DEBUG $dash_file $PERF $POSTPERF $hname $sysd_dir
else
        echo "\n$log_stamp ** !! WARNING !! POST PROCESSING HAS BEEN SKIPPED !! **\n\n\tRun the following to complete PostProcessing Analysis and .html Report Creation :\n\n\t\t# ./sys_diag -P -d $sysd_dir\n"
	
fi

if [[ $PERF -ne 0 ]]
then
	echo "\n\t Data Directory :\n\t$sysd_dir\n" >> $sysd_perflog
	echo "\n\t HTML Report File :\n\t$html_file\n" >> $sysd_perflog
	echo "\n\t Archived Data Files :\n\t$tar_file\n" >> $sysd_perflog
	echo "_____________________________________________________\n" >> $sysd_perflog
fi

#####################################################################
# TAR/Compress performance data and sys_diag report files ($sysd_dir)
#####################################################################

log_stamp='sys_diag:'`date '+%m%d_%H%M%S'`':'

if [[ $TAR -ne 0 ]]
then
#	tar_file="./sys_diag_$hname_`date '+%y%m%d_%H%M'`.tar"
#	tar_file="$home_dir/sys_diag_$hname_`date '+%y%m%d_%H%M'`.tar"

        echo "\n$log_stamp ## Generating TAR file : $tar_file ..."

	if [[ -f `echo $home_dir/sys_diag.out` ]]
	then
		cp $home_dir/sys_diag.out $sysd_dir
	elif [[ -f /var/tmp/sys_diag.out ]]
	then
		cp /var/tmp/sys_diag.out $sysd_dir
	fi

	if [[ $PERF -ne 0 ]]
	then
		cp $home_dir/sys_diag_perflog.out $sysd_dir
	fi

	if [[ -x /usr/sbin/tar ]]
	then
	    echo "\ttar -cvf $tar_file $sysd_dir 1>/dev/null"
	    tar -cvf $tar_file $sysd_dir 1>/dev/null
	    ret=$?

	    if [[ $ret -eq 0 ]]
	    then
		echo "\tcompress $tar_file\n"
		compress $tar_file
		ret=$?

		if [[ $ret -eq 0 ]]
		then
			echo "\nData files have been TARed and compressed in :\n\n\t***  $tar_file.Z  ***\n\n"
			if (( CLEANUP )); then
				rm -r $sysd_dir
			fi
		else
			echo "\n*WARNING*: Data files were *NOT* Compressed in :\n\t***  $tar_file.Z  ***\n\n\t**Check for ERROR Messages**\n\n"
		fi
	    else
		echo "\nData files were *NOT* TARed in :\n\n\t***  $tar_file  ***\n\n\t**Check for ERROR Messages**\n\n"
	    fi
	else
	    echo "\n** TAR could NOT be found ** NO Archive was created of $sysd_dir\n\tTo manually create $tar_file.Z type :\n\n"
	    echo "\ttar -cvf $tar_file $sysd_dir"
	    echo "\tcompress $tar_file\n\n"
	fi
else
	echo "\n** NO Archive was created of $sysd_dir\n\tTo manually create $tar_file.Z type :\n\n"
	echo "\ttar -cvf $tar_file $sysd_dir"
	echo "\tcompress $tar_file\n\n"

fi

############################################################################
echo "------- Sys_Diag Complete -------\n\n"
############################################################################


##############################################################################
### This script is submitted to BigAdmin by a user of the BigAdmin community.
### Sun Microsystems, Inc. is not responsible for the
### contents or the code enclosed. 
###
###
### Copyright 2008 Sun Microsystems, Inc. ALL RIGHTS RESERVED
### Use of this software is authorized pursuant to the
### terms of the license found at
### http://www.sun.com/bigadmin/common/berkeley_license.html
##############################################################################


