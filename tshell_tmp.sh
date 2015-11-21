# Author: Mohamed Abdelwahid "moe2266@charter.net"
# This script will try to use tcsh temporarily as the interactive shell

if ($?tcsh) then
  set shell=`which tcsh`
  setenv SHELL $shell
else
  set f = (`which tcsh`)
  if ($#f == 1) then
    echo "Starting tcsh..."
    exec $f -l
  endif
  unset f
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


