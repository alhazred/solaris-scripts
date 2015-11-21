#!/bin/ksh

# ********************************************************************
# 
# File:         do_backup
# Author:       Eric Nielsen,
# Created:      04/10/96
# Modified:    
#
# Description:  This script runs the backups for host sec. The host
# 		sec has two file systems, one mounted on / and the
		second mounted on /export. 
# ********************************************************************


# ********************************************************************
#
#       Check to be sure user is root
#
# ********************************************************************
 
        USER=`/bin/id | grep root | wc -l`
        if [ $USER -eq 0 ]
        then
 
                echo ""
                echo "You must be root to run this script"
                echo ""
                exit 1
        fi

# ********************************************************************
#
#       Argument Processing
#
# ********************************************************************
 
        if [ $# -ne 1 ]
        then
		/usr/bin/cat<<eof
			Usage:do_backup <backup level>
			   <0>		Full backup 
			   <1>		All changes since level 0 
			   <2>	        All changes since level 1
			   <3>		All changes since level 2
			   <4>		All changes since level 3
			   <5>		All changes since level 4
			   <6>		All changes since level 5
			   <7>		All changes since level 6
			   <8>		All changes since level 7
			   <9>		All changes since level 8
		       
			Example: do_backup 1
eof
exit
        fi

# ********************************************************************
#
#	Initialize Variables
#
# ********************************************************************

# set BACKUPHOME to the directory you want the log files stored. 
BACKUPHOME=/backups
UFSDUMPHOME=/usr/sbin
EJECT=

# Set these variables to the filesystems you want to backup  
# You can also define additional ones and annd dump corrisponding dump lines below
ROOTFILESYSTEM=/
EXPORTFILESYSTEM=/export


if [ $1 -eq 0 ]
then
	DATE=`/usr/bin/date '+%d%b%y-%H:%M:%S'`.full
else

	DATE=`/usr/bin/date '+%d%b%y-%H:%M:%S'`

fi



# ********************************************************************
#
#	Dump the file systems
#
# ********************************************************************

# rewind the tape 
/usr/bin/mt -f /dev/rmt/0 rewind

# echo the report header to the logfile and to standard out  
echo "**************************************************************** " | tee -a ${BACKUPHOME}/logs/log.${DATE}
echo "*Starting Backups, Level $1, $DATE " | tee -a ${BACKUPHOME}/logs/log.${DATE}
echo "****************************************************************" | tee -a ${BACKUPHOME}/logs/log.${DATE}
echo " " | tee -a ${BACKUPHOME}/logs/log.${DATE}
echo "****************************************************************" | tee -a ${BACKUPHOME}/logs/log.${DATE}


# Dump a filesystem specified by $EXPORTFILESYSTEM  
echo "#1. Dumping sec:/dev/md/dsk/d1 ${EXPORTFILESYSTEM}"  | tee -a ${BACKUPHOME}/logs/log.${DATE}
echo "****************************************************************" | tee -a ${BACKUPHOME}/logs/log.${DATE}
${UFSDUMPHOME}/ufsdump ${1}fu /dev/rmt/0n ${EXPORTFILESYSTEM} 2>&1 | tee -a ${BACKUPHOME}/logs/log.${DATE}
echo "****************************************************************" | tee -a ${BACKUPHOME}/logs/log.${DATE}
echo " " | tee -a ${BACKUPHOME}/logs/log.${DATE}
echo "****************************************************************" | tee -a ${BACKUPHOME}/logs/log.${DATE}

# Dump a filesystem specified by $ROOTFILESYSTEM  
echo "#2. Dumping sec:/dev/rdsk/c0t3d0s0, ${ROOTFILESYSTEM}"  | tee -a ${BACKUPHOME}/logs/log.${DATE}
echo "****************************************************************" | tee -a ${BACKUPHOME}/logs/log.${DATE}
${UFSDUMPHOME}/ufsdump ${1}fu /dev/rmt/0n ${ROOTFILESYSTEM}" 2>&1 | tee -a ${BACKUPHOME}/logs/log.${DATE}
echo "****************************************************************" | tee -a ${BACKUPHOME}/logs/log.${DATE}
echo " " | tee -a ${BACKUPHOME}/logs/log.${DATE}
echo "****************************************************************" | tee -a ${BACKUPHOME}/logs/log.${DATE}

# Dump a filesystem specified by $ROOTFILESYSTEM  
echo "****************************************************************" | tee -a ${BACKUPHOME}/logs/log.${DATE}
echo "*Finishing Backups, Level $1, $DATE" | tee -a ${BACKUPHOME}/logs/log.${DATE}
echo "****************************************************************" | tee -a ${BACKUPHOME}/logs/log.${DATE}

# ********************************************************************
#
#	Rewind the tape, eject the tape if backup Level 0 
#
#       Take the tape offiline and eject the tape if this is a level zero in
#       order to allow someone to change the tape.  
#
# ********************************************************************

/usr/bin/mt -f /dev/rmt/0 rewind
if [ $1 -eq 0 ]
then


	/usr/bin/mt -f /dev/rmt/0 offline
fi
/bin/date | tee -a ${BACKUPHOME}/logs/log.${DATE}

# ********************************************************************
#
#	The end                                
#
# ********************************************************************
