#!/sbin/sh
#
# NLB Kondor+ users environment synchronization script - UserSync
# Designed for SUN Solaris 8 & 9
# Created by   peter.cvar@snt.si    April, 2005 
#
# UserSync script is designed to synchronize /etc/passwd, /etc/shadow and 
# /etc/group files between two hosts in a cluster.
# UserSync script is started from cron on both hosts simultaneously. 
# Operation is performed only on host with imported cluster service group 
# (/reuters FS is mounted on that host). 
# Before the operation script checks if other host is alive. 
# /etc/passwd, /etc/shadow and /etc/group files are copied to other host 
# only if they are newer. 
# Previous files on dependent host are removed to /etc/passwd.old, 
# /etc/shadow.old and /etc/group.old
#
########## Variables definition - START ##########
server1=speedy
export server1
server2=corona
export server2
userslog=/var/tmp/usersync.log
export userslog
########## Variables definition - END ############

if [ ! -d /reuters/lost+found ]
then exit 90
fi

test2=`/usr/sbin/ping $server2 | /usr/bin/cut -f3 -d" "` 
if [ "$test2" != "alive" ]
then 
echo "#################################################" >> $userslog
echo "Server $server2 is not alive!" >> $userslog
exit 91
fi

echo "#################################################" >> $userslog
/usr/bin/date >> $userslog

pastest=`/usr/bin/rdist -v -y -c /etc/passwd $server2 | grep Warning | cut -f1 -d " "`
if [ "$pastest" != "Warning:" ]
then
/usr/bin/rsh $server2 cp /etc/passwd /etc/passwd.old
/usr/bin/rdist -y -q -c /etc/passwd $server2 
/usr/bin/rsh $server2 cp /etc/shadow /etc/shadow.old
/usr/bin/rdist -y -q -c /etc/shadow $server2 
echo "/etc/passwd file on server $server2 was updated" >> $userslog
echo "/etc/shadow file on server $server2 was updated" >> $userslog
else
/usr/bin/rdist -v -y -c /etc/passwd $server2 | grep -v updating >> $userslog
/usr/bin/rdist -v -y -c /etc/shadow $server2 | grep -v updating >> $userslog
fi

grptest=`/usr/bin/rdist -v -y -c /etc/group $server2 | grep Warning | cut -f1 -d " "`
if [ "$grptest" != "Warning:" ]
then
/usr/bin/rsh $server2 cp /etc/group /etc/group.old
/usr/bin/rdist -y -q -c /etc/group $server2 
echo "/etc/group file on server $server2 was updated" >> $userslog
else
/usr/bin/rdist -v -y -c /etc/group $server2 | grep -v updating >> $userslog
fi

exit 0


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


