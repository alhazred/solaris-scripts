#!/bin/bash
# Created by Zoran Pucar
# sun@zoran.user.lysator.liu.se
# Feel free to give feedback!
# Check also my adduser script at
# www.lysator.liu.se/~zoran/adduser
# <a href="http://www.lysator.liu.se/~zoran">My Page</a>

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
        if [ "$ACTION" != "start" -a "$ACTION" != "stop" -a "$ACTION" != restart ]; then
        usage
        exit 1
        fi
        if [ "$ACTION" = restart ]; then
                ${INIT}/${PROGRAM} stop && echo "$PROGRAM stopped"
                ${INIT}/${PROGRAM} start && echo "$PROGRAM started"
        else
                ${INIT}/${PROGRAM} ${ACTION} && echo "$PROGRAM ${ACTION}ed"
        fi
else
        echo "program $PROGRAM not found in $INIT"
        usage
        exit 1
fi

