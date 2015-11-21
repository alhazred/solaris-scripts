#!/bin/sh
# logstrokes version 1.2
# writes all keystrokes to [logfile] and sends them to 
# the shell to be executed
# Allows you to create a shell script for a series 
# of commands as you do them
#
# usage: logstrokes [file to log to]
# when done, ctr-c to stop logging

# comments / improvements: support@webmastersguide.com

# history:
# 1.2 Fixed script so logfile could be entered as
#     either a full path or a relative path, without a switch
#
# 1.1 Initial release - required r switch

case $1 in
"")echo "usage: logstrokes [file to log to]"; exit 1;;
-*) shift;;
esac

case $1 in
/.*) logfile="$1";;
*) logfile="`pwd`/$1";;
esac
echo "logging to $logfile"

touch $logfile
chmod 755 $logfile

while :
do
	echo -n "[`pwd`]# "
	read args
	echo "$args" >>$logfile
	$args
done
