#!/bin/sh

### Reading/Writing  from the terminal in sh, ksh
###
### Often it is necessary to read input from a terminal in a script where
### the person starting the script has redirected standard in and 
### standard out. This can be achieved as in the following example:
 
echo "Is it OK to proceed (Y/N)"  > /dev/tty
 read ans < /dev/tty
if [ "$ans" = "Y" -o "$ans" = "y" ]
then
    echo "The answer was 'Y'"
else
    echo "The answer was not 'Y'"
fi

exit 0







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


