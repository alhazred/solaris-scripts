#! /usr/bin/ksh
#
#
#
####################################################################
#                                                                  #
# distrib.ksh * 16.05.2001 * MP * transfer files to remote systems #
#                                                                  #
####################################################################
#
#
# This script transfers a file to all systems defined in $SYSLIST.
#
# It uses ftp.
#
# The file to be transferred is passed to this script as $1 .
#
# The user id which is being used for the transferred is passed to this
# script as $2 .
#
# You need to make sure that the user id you want to use exists on all
# remote target systems. Also this user id must have the same password
# on all remote systems.
#
# The script will ask you for the user's password. The password is not
# being echoed on the screen as you type it in.
#
#
# The file is being transferred to the home directory corresponding to
# the user id you use.
#
# Examples:
#
# distrib.ksh /tmp/httpd.conf httpuser
#
# -> transfers file /tmp/httpd.conf to home dir of user "httpuser"
#
# distrib.ksh /etc/sendmail.cf mailuser
#
# -> transfers file /etc/sendmail.cf to home dir of user "mailuser"
#
###########################################################################
#
#
INPUT=/tmp/ftpinput.$$
#
# CHANGE THIS TO THE LIST OF SYSTEMS TO BE USED
# EXAMPLE: SYSLIST="192.168.1.10 my.host.com"
SYSLIST=""
#
#
#
if [ $# -lt 2 ]
 then
 echo "usage: $0 FILENAME USERNAME"
 exit
fi
#
TRANSFILE=$1
USERNAME=$2
echo
echo "password for $USERNAME on all remote systems: \c"
stty -echo
read PASSWORD
stty echo
#
#
echo
echo "Transfer file $TRANSFILE to home directory of user $USERNAME "
echo "on all systems listed below:"
echo
for MASCHINE in $SYSLIST
 do
 echo $MASCHINE
done
#
echo "start (y/n): \c"
read ANTWORT
if [ "$ANTWORT" != "y" ]
 then
 exit
fi
#
echo "user $USERNAME $PASSWORD" > $INPUT
echo "send $TRANSFILE" >> $INPUT
echo "by" >> $INPUT
#
for MASCHINE in $SYSLIST
 do
 echo "connecting to $MASCHINE"
 ftp -n $MASCHINE < $INPUT
 echo
 echo
done
#
rm $INPUT
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


