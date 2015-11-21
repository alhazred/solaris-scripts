#!/bin/ksh
#
# Solaris Monitor Processes Script
# Purpose: Ensures processes are running. Notifies
# via e-mail.
# Usage: Execute from crontab every 15 minutes.
# Dependencies: mon_procs.dat – Contains the names
# of processes. /etc/aliases – status (email
# addresses of administrators)
# Outputs: Email
#
## Submitter Email: gideon@infostruct.net
#**************************************************************

# The directory this script resides in
ADMINDIR=/opt/admin/scripts

# The next variable can be set for multiple addresses
# (i.e. jsmith@yahoo.com,jsmith@hotmail.com)
MAILADD=monitor

SRVNM=`uname -n`

while read PROG
do
ANSWER=`ps -e -o comm | grep $PROG`
if test "$ANSWER" = "$PROG"; then
            sleep 1
else
            mail $MAILADD <<EOF
From: $0
To: $MAILADD
Subject: Missing process on $SRVNM
Checking $PROG on $SRVNM... not found!

EOF
fi
done < $ADMINDIR/mon_procs.dat

exit 0


# vi mon_proc.dat 
/usr/sbin/syslogd 


##############################################################################
### This script is submitted to BigAdmin by a user of the BigAdmin community.
### Sun Microsystems, Inc. is not responsible for the
### contents or the code enclosed. 
###
###
### Copyright 2007 Sun Microsystems, Inc. ALL RIGHTS RESERVED
### Use of this software is authorized pursuant to the
### terms of the license found at
### http://www.sun.com/bigadmin/common/berkeley_license.html
##############################################################################


