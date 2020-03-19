#!/bin/ksh
#
# Solaris Web Log Pull Script
# Purpose: Downloads web server log files
# with FTP and SCP. Files older than 1 day
# are rotated and compressed. Sends e-mail
# if there is a failure.
# Usage: Execute from crontab (daily)
# Dependencies: None
# Outputs: Log files and e-mail
# 
## Submitter Email: gideon@infostruct.net
#***************************************************

PATH=/usr/sbin:/usr/bin:/usr/local/bin

# Webtrends directory
# (The log files are named by server)
LOGDIR=/weblogs/site1

# Archive directory
ARCHDIR=/webarch/site1

DATE=`date '+%m-%d-%y%n'`

UMASK=033

HOSTNAME=`uname -n`

# The next variable can be set for multiple addresses
# (i.e. jsmith@yahoo.com,jsmith@hotmail.com)
MAILADD=status

#
## Process the site1 logs...
#

# Move existing log files to the archive directory

for i in `/usr/bin/ls $LOGDIR`
do

gzip $LOGDIR/$i
mv $LOGDIR/$i.gz $ARCHDIR/$i.$DATE.gz

done

# Download today's log files

scp "admin@logsrv1.abc.net#22:/weblog/access.logsrv1" $LOGDIR
if [ $? -gt 0 ]; then
           mail $MAILADD <<EOF
From: $0
Subject: Web Server Log Centralization
The download of log files from logsrv1 to sunsrv has failed.
The files must be downloaded immediately. See $0 for details.
Once the files have been downloaded, click "Analyze Now" for each
site1 Webtrends profile. Otherwise, there will be a missing
day in the web statistics.
EOF
fi;

#
## Process the site2 logs...
#

# Webtrends directories
# (Log files are not named by server)
LOGDIR1=/weblogs/site2/websrv1
LOGDIR2=/weblogs/site2/websrv2

# Archive directories
ARCHDIR1=/webarch/site2/websrv1
ARCHDIR2=/webarch/site2/websrv2

MONTH=`date '+%b'`
DAY=`date '+%d'`
DAYMONTH=$DAY$MONTH

# Move existing log files to the archive directories

for i in `/usr/bin/ls $LOGDIR1`
do

gzip $LOGDIR1/$i
mv $LOGDIR1/$i.gz $ARCHDIR1/$i.$DATE.gz

done

for i in `/usr/bin/ls $LOGDIR2`
do

gzip $LOGDIR2/$i
mv $LOGDIR2/$i.gz $ARCHDIR2/$i.$DATE.gz

done

# Download today's log files

ftp -n logsrv2 <<EOF
       u sysact passwd
       prompt
       lcd $LOGDIR1
       cd /websrv1/iplanet/site2/SSL
       mget access.$DAYMONTH*
       lcd $LOGDIR2
       cd /websrv2/iplanet/site2/SSL
       mget access.$DAYMONTH*
       bye
EOF

# Check to see if the transfer completed

for i in $LOGDIR1 $LOGDIR2
do

if [ `ls $i | wc -l` -lt 1 ]; then
           mail $MAILADD <<EOF
From: $0
Subject: Web Server Log Centralization
The download of log files from logsrv2 to sunsrv has failed.
The files must be downloaded immediately. See $0 for details.
Once the files have been downloaded, click "Analyze Now" for each
site2 Webtrends profile. Otherwise, there will be a missing
day in the web statistics.
EOF
fi;

done

# Uncompress the log files so Webtrends can process them
gunzip $LOGDIR1/access*
gunzip $LOGDIR2/access*

# Ensure that the log files do not take up more than 100 MB.

# The maximum size $ARCHDIR is allowed to reach before notification
# is sent. (102400=100 MB)
MAXSIZ=102400

ARCHDIR=/webarch

LOGDU=`du -sk $ARCHDIR | awk '{ print $1 }`

        if [ "$LOGDU" -gt "$MAXSIZ" ]; then
           mail $MAILADD <<EOF
From: $0
Subject: Web Log Size on $HOSTNAME
$ARCHDIR is $LOGDU KB. $0 notifies of
more than 100 MB of log files in this directory.
Thank you.
EOF
        fi

exit 0





##############################################################################
### This script is submitted to BigAdmin by a user of the BigAdmin community.
### Sun Microsystems, Inc. is not responsible for the
### contents or the code enclosed. 
###
###
### Copyright 2006 Sun Microsystems, Inc. ALL RIGHTS RESERVED
### Use of this software is authorized pursuant to the
### terms of the license found at
### http://www.sun.com/bigadmin/common/berkeley_license.html
##############################################################################


