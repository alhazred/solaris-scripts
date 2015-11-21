#!/bin/ksh
# This script shows how to use 'vi' editor non-interactively.
# Any vi command can be put in the same way. Just prefix the command 
# by ':' sign.
# Here the script  removes the blank line in a file and same the same.
# Take file to be modified as command line argument.
# Usage : $0 <filename>

[ $# -ne 1 ] && echo "Usage: $0 <filename>" && exit 1

vi <<-eof
:r $1
:%g/^[\t]*$/d
:wq!
eof



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


