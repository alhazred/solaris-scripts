#!/usr/local/bin/bash
#File: kick
#Purpose:  Kick user(s) off the system by user name.
#Usage: kick.sh [username]
#Warning: kick does not currently discern between multiply logins. Kick will kill all user process with the given name.
#Author: bernie724@yahoo.com (Bernie Thompson)
#History: Nov 28 2000
#Changes: (r.09) Nov 30 2000
#Todo: kick an array of users, 
#discern between multiply user process, 
#write rkick to manage remote users, send different signals...

un=$*
ypd=`domainname`

kick_user()
{
ps -u $un | awk '{print $1}' > /tmp/kl.$$
while read buffer
do
unp=`echo $buffer`
if [ "$unp" = "PID" ]
then
echo "Processing PID(s)"
else
echo "User $un with PID $unp is in the kill queue."
kill -9 $unp >> /dev/null
fi
done < /tmp/kl.$$
rm -r /tmp/kl.$$
}

eval_user()
{
who | awk '{print $1}' > /tmp/vu.$$
while read buffer
do
vu=`echo $buffer`
if [ "$vu" = "$un" ]
then 
vuf=$vu
fi
done < /tmp/vu.$$
rm -r /tmp/vu.$$
}
 
eval_ouser()
{
cat /etc/passwd | cut -d":" -f1 > /tmp/vou.$$
while read buffer
do
vou=`echo $buffer`
if [ "$vou" = "$un" ]
then
ovuf=$vou
fi
done < /tmp/vou.$$
rm -r /tmp/vou.$$
}

eval_youser()
{
ypcat passwd > /tmp/ypp.$$
cat /tmp/ypp.$$ | cut -d":" -f1 > /tmp/yvou.$$
while read buffer
do
yvou=`echo $buffer`
if [ "$yvou" = "$un" ]
then
ovuf=$yvou
fi
done < /tmp/yvou.$$
rm -r /tmp/yvou.$$
rm -r /tmp/ypp.$$
}

exit_user ()
{
if [ "$ovuf" = "" ]
then
echo "User $un does not exist. Exiting..."
exit 1
else 
echo "User $ovuf is offline. Exiting..."
exit 1
fi
}

if [ "$un" = "" ]
then
echo "Usage: kick.sh [username]"
exit 1
fi

# Root User cannot be kicked

if [ "$un" = "root" ]
then
echo "User $un cannot be kicked! Exiting..."
exit
fi

# TM user in vista cannot be kicked
if [ "$un" = "tm" ]
then
echo "User $un cannot be kicked! Exiting..."
exit
fi

# See if the user is online: punt or exit

eval_user
if [ "$vuf" = "" ]
then
eval_ouser
if [ "$ypd" != "" ]
then
eval_youser
fi
exit_user
else
kick_user
fi

# Check and Return User Status After Kick

vuf=""
eval_user
if [ "$vuf" = "" ]
then
echo "User $un Kicked!"
exit 1
else
echo "User $un still exists. Exiting..."
exit 1
fi


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


