#!/usr/bin/ksh
#
#
############################################################################
#
#
# rem_exec.ksh * 16.05.2001 * MP * execute a command on listed 
# remote systems 
#
#
############################################################################
#
#
# This script executes the command string supplied as $1 on all remote
# systems listed in $SYSLIST.
#
# Please note that you need to quote $1 using double quotes. See examples!
#
# rem_exec.ksh uses scp with the user id defined in $USER.
#
# To avoid password prompt you need to install the ssh auhtorized_keys file
# for the user defined as $USER on all remote systems.
#
# Examples:
#
# rem_exec.ksh "grep xyz /var/adm/messages"
# rem_exec.ksh "cd /usr/local/apache/conf; grep VirtualHost httpd.conf"
# rem_exec.ksh "cd /usr/local/apache/locks; touch httpd.lock"
#
#
############################################################################
#
#
if [ $# -lt 1 ]
 then
 echo "usage: $0 <command_string>"
 exit
fi
#
CMDSTRING=$1
#
SYSLIST="system1 system2 system3 system4"
USER=hpdmpoe
#
#
#
for MASCHINE in $SYSLIST
 do
 echo "connecting to: $MASCHINE"
 ssh -l $USER $MASCHINE "$CMDSTRING"
done
#
#

	




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


