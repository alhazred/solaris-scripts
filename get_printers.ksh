#!/bin/ksh

###
### Print out the list of all the printers available
### 
### Use with the script 'printers_convert_html' to
### have it format the output of this file
### into HTML.
###
### Submitted by: Matthew.Baker@med.ge.com
###               Matthew.Baker@med.ge.com
###
HOST=$(hostname)
OUTFILE=/sccm/cfig/sysinfo/printers/$HOST

lpstat -p all | awk '{print $2}' > $OUTFILE




##############################################################################
### This script is submitted to BigAdmin by a user of the BigAdmin community.
### Sun Microsystems, Inc. is not responsible for the
### contents or the code enclosed. 
###
###
### Copyright 2005 Sun Microsystems, Inc. ALL RIGHTS RESERVED
### Use of this software is authorized pursuant to the
### terms of the license found at
### http://www.sun.com/bigadmin/common/berkeley_license.html
##############################################################################


