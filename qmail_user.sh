#!/bin/sh

# Use this script to create a user in
# qmail and MySQL.
#
# Submitted by: Puran Singh
# 
#
dbpasswd='pooran'  #database password
dbname='bmail'   #database name
dbtable='buser' #user table

echo "Enter Username "
read user
euser=`mysql --password=$dbpasswd --database=$dbname --execute="select count(*) \
from $dbtable where id='$user'"`
euser=`echo $euser | cut -d ' ' -f2`
if [ $euser -eq 0 ]; then
echo "Enter Password"
read pass
echo "Enter Name"
read name
muid=`mysql --password=$dbpasswd --database=$dbname --execute='select \
max(uid) from $dbtable '`
muid=`echo $muid | cut -d ' ' -f2`
muid=`expr $muid + 1`
echo "ADDING USER IN DATABASE=="
pass="ENCRYPT('"$pass"')"
hom="/home/"$user
mysql --password=$dbpasswd --database=$dbname --execute="insert into $dbtable \
values('$user',NULL,$pass,'',$muid,$muid,'/bin/false','$hom',sysdate(), \
'2004-1-1','Y',5000,'$name')"
echo "USER SUCCESSFULLY ADDED IN THE DATABASE"
echo "Making Home Directory"
cd /home
mkdir $user
cd $user
maildirmake Maildir
chown -R $muid:$muid .

else
       echo "User Already Exists Please Try Some Other Username"
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


