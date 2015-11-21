#!/bin/ksh
#check the ping status non-intractively
#Usage: $0 <hostname>

LOGFILE=/tmp/pingtest.log
HOSTNAME=$1

#execute ping and get the PID
ping ${HOSTNAME} >${LOGFILE} 2>&1 &
PID=$(echo $!)

#wait for a while and intrupt it
sleep 4
kill -INT ${PID} >/dev/null 2>&1

# check the logfile for the status 
# grep -q "transmitted" ${LOGFILE}
grep  "alive" ${LOGFILE}
RC=$(echo $?)
if [ ${RC} -eq 0 ]
then
  echo "Host name ${HOSTNAME} found and responding"
  exit 0
else
  echo "Host name ${HOSTNAME} NOT FOUND"
  exit 1
fi

###
### This script is submitted to BigAdmin by a user
### of the BigAdmin community. 
### Sun Microsystems, Inc. is not responsible for the
### contents or the code enclosed. 
###




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


