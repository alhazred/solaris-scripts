#!/bin/csh -f

# whom (NIS)
# Author: Mohamed Abdelwahid "moe.abdelwahid@fmr.com"
# This script will identify any user using the ID
# set $1=user in a NIS environment.
#

if ! { ( ypmatch $1 passwd >& /dev/null ) } then
  echo $1 is NOT a known user
  exit 1
else

echo $1 is on the user list for this machine `hostname`,
echo the User real name is
        ypmatch $1 passwd| awk -F: '{print $5}'
echo
echo the Home Directory is
        ypmatch $1 passwd| awk -F: '{print $6}'
echo
echo And the SHELL is
        ypmatch $1 passwd| awk -F: '{print $7}'

endif




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


