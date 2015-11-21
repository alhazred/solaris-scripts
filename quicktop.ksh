#!/bin/ksh

###
## quicktop
##
## This a quick and handy version of the "top" program. 
## This will display system load averages and top processes
## by %CPU.  You don't need to install any packages or compile
## any software.  Just make this script executable. 
## It can run as any user and does not need to be set-UID either!

##
## Submitter:  Bill Sommers 
## Author:     Bill Sommers
## Submitter Email: bill_sommers@excite.com


DISPPROC=15                       # number of processes to display 
DELAY=5                           # delay between updates
clear
while (true)
do 
    clear
    echo "-------------------------------------------------------------------------------"
    echo "                                  Top Processes"
    /usr/bin/uname -a
    /usr/ucb/uptime
    /usr/bin/date
    echo "-------------------------------------------------------------------------------"
    /usr/ucb/ps -aux | head -$DISPPROC
    sleep $DELAY
done


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


