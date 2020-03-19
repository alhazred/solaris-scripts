
lpget $1 > /dev/null
if [ $? -ne 0 ]
then
echo
echo "             *** Printer $1 doesn´t exist *** "
echo
exit 1
fi
profile=`id | cut -f1 -d" " | cut -f2 -d"(" | cut -f1 -d")"`
if [ $profile != "root" ]
then
clear
echo
echo "                        id=$profile"
echo
echo "  *** switch user to root before execute this script *** "
echo
exit 1
fi
machine=`uname -n`
clear
echo
lpstat -p $1
echo
lpstat -R $1 > lpout
if test -s lpout
then
echo " r-ID        J  o  b  N  a  m  e        UserName        Size(Bytes)   Submitted"
echo "-----   -----------------------------  -----------      -----------   ---------"
fi
for entry in `nawk '{sub(".*-", "",$2);print $2;}' lpout`; do
if test -f /var/spool/lp/tmp/$machine/$entry-0
then
jname=`grep F /var/spool/lp/tmp/$machine/$entry-0 | awk '{print $2}'`
usern=`grep $1-$entry lpout | awk '{print $3}'`
jsize=`grep $1-$entry lpout | awk '{print $4}'`
submt=`grep $1-$entry lpout | awk '{print $5,$6,$7}'`
else
jname=`echo "Unknowed_Job_Name_"`
usern=`grep $1-$entry lpout | awk '{print $3}'`
jsize=`grep $1-$entry lpout | awk '{print $4}'`
submt=`grep $1-$entry lpout | awk '{print $5,$6,$7}'`
fi
echo "$entry $jname $usern $jsize $submt" |
nawk '{ printf "%-7s %-31.27s %-15.12s %-11.11s %-2s %-2s %s\n", $1,$2,$3,$4,$5,$6,$7 }'
done




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


