#!/bin/csh

# Allows to kill processes matching a given pattern.
# If run with -i option, asks for a confirmation.

if ( a$1 == a  ) then
    echo "Usage: $0 <command> [-i]"
    exit 0
endif
set DOLLAR=\$
set LBRACE={
set RBRACE=}
set QUOTE=\"
/usr/bin/ps -eo pid,user,time,comm | /usr/bin/nawk "${DOLLAR}4 ~
$QUOTE$1$QUOTE {print ${DOLLAR}1 }" > /tmp/~procs~
set PIDS=`cat /tmp/~procs~`
foreach PID ($PIDS)
  set LINE=`/usr/bin/ps -p $PID -o pid,user,time,comm|tail -1|tr -d "\012"`
  if ( a$2 == "a-i" ) then
    echo -n "Kill $QUOTE$LINE$QUOTE (y/n) ? "
    set reponse=$<
    if ( a$reponse != "ay" ) then
      continue
    endif
  endif
  echo -n "Killing $QUOTE$LINE$QUOTE ... "
 /usr/bin/kill -9 $PID
  echo done
end
/bin/rm /tmp/~procs~




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


