#!/bin/ksh

###
## bootmonitor
## System Boot Notification Script
##
## Notifies administrators when a server reboots.
## /etc/rc2.d/S99notify
## Sends e-mail notification to the administrators 
## when the system is booted.
##
## Submitter:  Gideon Rasmussen
## Submitter Email: gideon@infostruct.net
## *****************************************************************
PATH=/usr/sbin:/usr/bin

DATE="`date`"
SRVNM=`uname -n`

# The next variable can be set for multiple addresses
# (i.e. jsmith@yahoo.com,jsmith@hotmail.com)
MAILADD=monitor

mail $MAILADD <<EOF
From: $0
To: $MAILADD
Subject: Boot of $SRVNM

$DATE

$SRVNM has booted up. 

If this is news to you, please investigate.

EOF
exit 0


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


