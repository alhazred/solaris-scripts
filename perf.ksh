#!/bin/ksh

######################################################################
#
# Script to monitor the server performance and to log outputs.
#
# Creates a directory '/tmp/PerformanceMonitoring/' with
# subdirectory for daily log files.
#
#
# Submitted by: Sudhakar Ramakrishnan
#
######################################################################

#Defining the date-stamp
Date="`date +%m/%d/%y %H:%M:%S`"
echo "Date: ${Date}"
echo ""

# Path of the log directory
Dir=/tmp/PerformanceMonitoring/logs_`date +%d_%m_%y`

# Path of the log file
LogFile=${Dir}/log.$$
[ -d $Dir ] || mkdir -p $Dir

# Start extracting and piping to the log file.
{

echo  "Extracting VMSTAT info...\n"
echo "----------------------------"
vmstat 2 5


echo  "Extracting MPSTAT info...\n"
echo "----------------------------"
mpstat 2 5


echo  "Extracting CPU utilization info...\n"
echo "-------------------------------------"
ps -eo pid,pcpu,args | sort +1n


/usr/bin/ps -el -o pcpu,pmem,fname,rss,vsz,pid,stime | sort +1n
echo "--------------------------------------"


echo  "Extracting information about VM...\n"
echo "--------------------------------------"
ps -eo pid,vsz,rss,pmem,args | sort +1n



echo  "Highest user processes...\n"
echo "--------------------------------------"
/usr/ucb/ps -aux



echo  "IOSTAT info...\n"
echo "--------------------------------------"
iostat -xtc 5 2


iostat -xcn 5 2


iostat 2 5




echo  "SAR Info...\n"
echo "--------------------------------------"
sar 2 5



echo  "Swap info...\n"
echo "--------------------------------------"
swap -s


swap -l


echo "Log file generated : $LogFile"

}|tee $LogFile 2>&1




##############################################################################
### This script is submitted to BigAdmin by a user of the BigAdmin community.
### Sun Microsystems, Inc. is not responsible for the
### contents or the code enclosed. 
###
###
### Copyright Sun Microsystems, Inc. ALL RIGHTS RESERVED
### Use of this software is authorized pursuant to the
### terms of the license found at
### http://www.sun.com/bigadmin/common/berkeley_license.jsp
##############################################################################

		