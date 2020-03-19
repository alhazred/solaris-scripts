#!/bin/sh
#
# Wrapper to all scripts in /etc/init.d.
# Takes 3 args: start, stop and restart
#
INIT=/etc/init.d
PROGRAM=$1
ACTION=$2
usage () {
echo "$0 program { start | stop | restart }"
}
USERID=`id | awk '{print $1}'`
if [ "$USERID" != "uid=0(root)" ]; then
        echo "You must be root to run this script"
        exit 1
fi
if [ -x "${INIT}/$PROGRAM" ]; then
        if [ "$ACTION" != "start" -a "$ACTION" != "stop" -a "$ACTION" !=
restart ]; then
        usage
        exit 1
        fi
        if [ "$ACTION" = restart ]; then
                ${INIT}/${PROGRAM} stop && echo "$PROGRAM stopped"
                ${INIT}/${PROGRAM} start && echo "$PROGRAM started"
        else
                ${INIT}/${PROGRAM} ${ACTION} && echo "$PROGRAM
${ACTION}ed"
        fi
else
        echo "program $PROGRAM not found in $INIT"
        usage
        exit 1
fi





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


