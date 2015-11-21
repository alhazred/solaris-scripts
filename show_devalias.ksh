#!/bin/ksh
# This script shows what aliases like "cdrom" get translated to by the 
# Openboot PROM on this server.  Useful to figure out if 
# "disk0" and /pci@1f,700000/scsi@2/disk@0,0
# are the same thing without going to the PROM.  
# Based on info in infodoc 45692 on sunsolve
# Mike Myers 11/2006

end_line=$(/usr/sbin/prtconf -vp | grep -n aliases | awk '{print $1}' | tr -d  :) 
end_line=$(( $end_line - 1 ))
start_line=$(/usr/sbin/prtconf -vp | head -${end_line} | grep -n Node |
tail -1 | awk '{print $1}' | tr -d : )
length=$(( $end_line - $start_line ))
/usr/sbin/prtconf -vp | head -${end_line} | tail -${length}

# Exit
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


