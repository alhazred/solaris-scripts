#!/bin/sh

# ps_check
#
# Version 1.0
#
# Author: David Röhr <david(at)rohr.se>
#
#
# A script that checks diffrent processes. 
# If the process is down it sends an email to the sysadmin.
#
# If you want a process monitored, just add the script to the crontab.

SYSADMIN="root"
HOST="`hostname`"
#

isOk(){
            if ( ps -ef | grep $1 | grep -v grep > /dev/null ) ;  then
                 printf "OK" ;
            else
                 printf "FAIL" ;
            fi
}
lookup(){
            if [ `isOk $1` = "FAIL" ] ; then
                MSG="$HOST - $1 is down"
                echo $MSG | mailx -s $MSG $SYSADMIN ;
            fi
}

# Processes to lookup
#
# Example, lookup inetd
#
lookup <process>
