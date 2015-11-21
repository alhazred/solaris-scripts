#!/bin/csh

###
### Find all files owned by all general users.
### Save the list of files owned by users in /tmp
### Example:   /tmp/nobody.list
###
### Submitted By: Marc Jacquard
###               Marc.Jacquard@firstdatacorp.com
###
### Adjust as needed
###

cd /
#cd /users
cat /etc/passwd|cut -f1 -d":"|grep -v root|grep -v daemon|grep -v bin|grep -v sys|grep -v adm|grep -v listen|grep -v nobody4|grep -v noaccess|grep -v nobody>/tmp/short.list
foreach i (`cat /tmp/short.list`)
  set summ=0
	#  find . -type f -user $i -exec du -s \{\} \;
  find . -type f -user $i -exec du -s \{\} \; >& /tmp/$i.list
  #find . -type f -user $i -exec du -s \{\} \; >& /tmp/space/$i.list
end



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


