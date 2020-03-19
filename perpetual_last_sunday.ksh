#!/bin/ksh
# last_sunday.sh v1.0
# Written by Antoon Huiskens 03/04
# usage: last_sunday /usr/bin/whatevercommand  -you -want
# e.g. for use in cron jobs.
# Requirements: SUNWesu SUNWcsu (that's not too much to ask I hope?)
# alternatively, provide: ksh, date, cal, grep, tail, cut in $PATH
# Note: this trick with cal works ONLY for the last sunday. 
# Not for any other day, unless you modify it yourself
TODAY=$(date "+%d")
LAST_SUNDAY=$(cal | grep -v ^$ | tail -1 | cut -d" " -f1)
if [[ $TODAY -eq $LAST_SUNDAY ]]
then echo "Today is the last sunday!!!!"
#uncomment the next line to really execute the commands specified.
    # shift ; $*
else echo "tough luck!!"
fi



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


