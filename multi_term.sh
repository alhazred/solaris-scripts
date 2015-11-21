#!/usr/bin/bash

###
# multiterm
#
# If you want to monitor a process from home and 
# from work, make sure you are logged in at work 
# and at home and run this script.
#
# Usage:
# monitor_term <program_to_monitor> <tty_to_monitor>
#
# Example usage:
# monitor_term make /dev/pts/17   
#
# Submitted By: Robert Banniza - robert@rootprompt.net

[ $# -lt 2 ] && 
	echo "Usage: $0 program ttytoduplicate" && 
	exit 2 

### Assign the vars
thistty=`tty`
prog=$1
othertty=$2

### Monitor term
sh -c "$prog|tee -a $thistty" 1>$othertty 2>&1 0>$othertty 


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


