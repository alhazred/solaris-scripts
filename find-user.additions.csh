#!/bin/csh

### add-it.csh
###
### This script is used in conjuction with find-user.csh
### to compute disk space and percentage usage.
###
### Submitted By: Marc Jacquard
###               Marc.Jacquard@firstdatacorp.com
###
foreach i (`cat /tmp/short.list`)
	\echo $i": \c"
	cat /tmp/$i.list | ./add.awk
end

------ CUT-HERE -----------


ADD.AWK script
------ CUT-HERE -----------

#!/bin/csh

### add.awk
###
### add.awk is called by add-it for computation of numbers.
###
### Submitted By: Marc Jacquard
###               Marc.Jacquard@firstdatacorp.com
###
{
	FS=" "
	size = $1
	sum=sum+size
}

END {printf("%u GB[%5.2f %]\n",(sum*512)/(1024*1024*1024),
(((sum*512)/1024)/(176504832)*100))}








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


