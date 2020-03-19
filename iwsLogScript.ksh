#!/bin/ksh
#
# IWS Log Script
# Dependancies: None
#
# This script copies the I-Planet Web Server log files to a log directory.
# It names the resulting log files with the host name and date.
#
# WARNING: THIS SCRIPT DELETES ANY FILES OLDER THAN 7 DAYS in the
# $LOGDIR directory!!!
#
## Submitter Email: gideon@infostruct.net
#*****************************************************************

PATH=/usr/sbin:/usr/bin

# Where the log files will be written to
LOGDIR=/app/weblog

DATE=`date '+%m-%d-%y%n'`

if [ ! -d $LOGDIR ] ; then
      mkdir -p $LOGDIR
fi

HOSTNAME=`uname -n`

WEBDIR=/app/netscape/suitespot/https-$HOSTNAME/logs

# IWS output file
FILE=$WEBDIR/access

# Resulting log file
LOGFILE=$LOGDIR/access.$HOSTNAME

# Log the output
cp $FILE $LOGFILE

# Over-write the IWS access log file while preserving the first line.
# The first line provides log formatting information. If it is deleted,
# the web server will not start and give a formatting error message.
head -1 $LOGFILE > $FILE

# Delete any log files older than 7 days
find $LOGDIR -mtime +7 -exec rm {} \;

# Ensure that the log files do not take up more than 50 MB

# The maximum size $OUTPUTDIR is allowed to reach before log files
# are deleted. (51200=50 MB)
MAXSIZ=51200

# The next variable can be set for multiple addresses
# (i.e. jsmith@yahoo.com,jsmith@hotmail.com)
MAILADD=status

LOGDU=`du -sk $LOGDIR | awk '{ print $1 }`

        if [ "$LOGDU" -gt "$MAXSIZ" ]; then
           mail $MAILADD <<EOF
From: $0
Subject: Web Log Size on $HOSTNAME
$LOGDIR is $LOGDU KB. $0 notifies of
more than 50 MB of log files in this directory.
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
### Copyright 2005 Sun Microsystems, Inc. ALL RIGHTS RESERVED
### Use of this software is authorized pursuant to the
### terms of the license found at
### http://www.sun.com/bigadmin/common/berkeley_license.html
##############################################################################


