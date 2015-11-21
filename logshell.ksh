#!/bin/ksh
# Quick Shell logging.
#
# Will log all input after run into the log /tmp/my.log
#
# Mike Roth, 2005

### Remove the current log
rm -f /tmp/my.log

### Log out all commands needed
while true
do
 read log?" [logging] # "
 echo "\nCommand: $log\n" >> /tmp/my.log
 exec $log | tee -a /tmp/my.log
done

### Exit out
exit 0




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


