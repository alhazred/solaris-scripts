#!/bin/ksh
# Cool little script to generate random numbers in shell script:

### This script generates 64 bit random numbers.  
### To get 32 bit, change count= to 6 and "u8" to "u4"



n=`dd if=/dev/urandom bs=1 count=8 2>/dev/null | od -t u8 | awk 'NR==1 {print $2}'`
echo "Random number is: $n"

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


