#!/usr/bin/ksh
############################################################
# Script to change the IP Address and Hostname of a Server #
#                   By Prompting for a new                 #
#                   Hostrname & IP Address                 #
#                  Written by Neels Vermaak                #
############################################################
#
#####  Root ID ####
if [ `/usr/ucb/whoami` != "root" ]; then
   echo "WARNING: Sorry, only root may execute this script!"
   exit 1
fi

# Define Variables
BNT=`hostname`
/usr/bin/clear 

### Read IP Address and Changes it ###
CNT=`/usr/bin/more /etc/hosts | grep $BNT | awk {'print $1'}`
/usr/bin/echo "The IP Address of the Server is .......$CNT"
/usr/bin/echo "               "
/usr/bin/echo "What must the new IP Address be : \c"
    read answer
/usr/bin/perl -pi -e "s/$CNT/$answer/g;" /etc/inet/hosts
echo "The Servers new IP Address will be .......$answer" 

### Read Server Name and Change ###

/usr/bin/echo "                                  "
/usr/bin/echo "                                  "
/usr/bin/echo "Changing the hostname may take a few seconds ...... "
/usr/bin/echo "This script wont have access to" 
/usr/bin/echo "change the /etc/mnttab file , but this is ok"
/usr/bin/echo "                                  "
/usr/bin/echo "                                  "
/usr/bin/echo "The name of the Server is .....................`hostname`"
/usr/bin/echo "                                  "
/usr/bin/echo "What must the new Server name be : \c"
    read answer
/usr/bin/find /etc -type f -exec grep -il $BNT {} \; | while read F; do
/usr/bin/perl -pi -e "s/$BNT/$answer/g;" $F
done
	echo "The Servers new name will be ....................$answer"

# Boot the Server #
/usr/bin/echo "                                  "
/usr/bin/echo "                                  "
/usr/bin/echo "                                  "
/usr/bin/echo "Configuration files have changed and you need to reboot"
/usr/bin/echo "                       "
/usr/bin/echo "Can the Server be booted now ( y/n ) : \c"
    read answer
if [ "$answer" = "n" ] || [ "$answer" = "N" ]
    then
        echo "Aborting , Warning : System might become unstable if you dont boot"
        exit
fi
/usr/bin/echo "Server will reboot in about 10 Seconds"
/usr/bin/sleep 5
/usr/sbin/shutdown -i6 -y -g10
        exit






##############################################################################
### This script is submitted to BigAdmin by a user of the BigAdmin community.
### Sun Microsystems, Inc. is not responsible for the
### contents or the code enclosed. 
###
###
### Copyright 2007 Sun Microsystems, Inc. ALL RIGHTS RESERVED
### Use of this software is authorized pursuant to the
### terms of the license found at
### http://www.sun.com/bigadmin/common/berkeley_license.html
##############################################################################


