#!/usr/bin/bash
#
#
# Generates an e-mail to report on dwindling disk space on a system.  
# Should be run from cron every 10 minutes.  
#
# It uses this interval to generate a log file and provide some useful 
# information on the rate at which space is disappearing.
#

# NOTE:
#
# Depends on script by same author to translates any given number of seconds into English.
#
# The call to the script '/usr/local/bin/sec2english' - get this script from BigAdmin:
# http://www.sun.com/bigadmin/scripts/submittedScripts/sec2english.txt
#
#
# Author -- Louis Romero (louis_romero@hotmail.com)
#
LOGFILE=/var/log/dreport.log
MAILFILE=/tmp/dreport.mail
MAILTO=${1:-"root@localhost"}
date=`date "+%Y%M%d%H%M%S"`
rm $MAILFILE 2>/dev/null
#
# -- Generate new log entries
#
df -k | sed "1d" | nawk '{
	share=$1
	size=$2
	used=$3
	avail=$4
	pavail=$5
	mount=$6
	printf("%s,%s,%s,%s,%s,%s,%s,%s\n", date, srand(), $1, $2, $3, $4, $5, $6)
}' date=$date | sed "s/%//g" >> $LOGFILE

#
# -- Evaluate existing log entries
#
df -k | sed "1d" | awk '{print $NF}' | while read fs
do
	grep ",$fs$" $LOGFILE | tail -3 | nawk -F, '{
		logdate=$1
		share=$3
		if ( share ~ /swap/ )
			next
		size=$4
		used=$5
		mount=$8
		if ( avail=="" ) {
			avail=$6
		} else {
			adelta=( avail - $6 )	#Set delta to diff between previous avail to current avail
			if ( adelta > 0 ) {
				adelta*=-1
				edelta=(epoc - $2)
				avail=$6		#Set avail to current stream value
				if ( rate == "" )
					rate=adelta/edelta
				else {
					orate=rate
					rate=adelta/edelta
				}
				if ( filsecs == "" )
					filsecs=(avail/rate)
				else {
					ofilsecs=filsecs
					filsecs=(avail/rate)
				}
				if (orate < 1024) {
					opfix="KB"
					odenom=1
				} else {
					opfix="MB"
					odenom=1024
				}
				if (rate < 1024) {
					rpfix="KB"
					rdenom=1
				} else {
					rpfix="MB"
					rdenom=1024
				}
				twentyminrate=((orate + rate)/2)
				if ( twentyminrate > 1024 ) {
					twentyminpfix="MB"
					twentymindenom=1024
				} else {
					twentyminpfix="KB"
					twentymindenom=1
				}
				"/export/home/rweeks/workspaces/bigadmin/src/scripts/submittedScripts/ORIGINALS/sec2english " int(filsecs) | getline fullin
				if (orate > 0 && rate > 0 && filsecs < 60*90) {
					printf("File System             : %s\n", share)
					printf("Mount Point             : %s\n", mount)
					printf("Space Available         : %0.2f MB\n", avail/1024)
					printf("Fill Rate (last 20 mins): %0.2f %s/sec\n", twentyminrate/twentymindenom, twentyminpfix) 
					printf("Fill Rate (last 10 mins): %0.2f %s/sec\n", rate/rdenom, rpfix)
					printf("Estimated Time Remaining: %s\n\n", fullin)
				}
			}
		}
		epoc=$2
		pavail=$7
	}' MAILFILE=$MAILFILE 
done > $MAILFILE
if [ -s $MAILFILE ]
then
	cat $MAILFILE | mailx -r $MAILTO 'Disk Space Alert--`hostname`' 
	rm $MAILFILE
fi


##############################################################################
### This script is submitted to BigAdmin by a user of the BigAdmin community.
### Sun Microsystems, Inc. is not responsible for the
### contents or the code enclosed. 
###
###
###  Copyright Sun Microsystems, Inc. ALL RIGHTS RESERVED
### Use of this software is authorized pursuant to the
### terms of the license found at
### http://www.sun.com/bigadmin/common/berkeley_license.jsp
##############################################################################