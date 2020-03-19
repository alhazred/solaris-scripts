#! /bin/ksh
#
# VISTO.SH - VIew STorage TOtals
# This script calculate and show
# the amount of physical and logical
# disks installed on Sun machines.
#
# Durval Felix De Medeiros
# Unix System Engineer
# Ericsson Telecommunications S.A.
# Sao Paulo - Brazil
# version 1.1.1 - Jan/2004
#

SWAP=`swap -l| grep -v free| awk '{soma+=$4} END {print soma/2}'`

clear
echo  " "
echo "                                   STORAGE REPORT                                        "
echo "-----------------------------------------------------------------------------------------"
if [ `uname -r` = "5.9" ]; then # df command with support to "-h" option
 df -hklF ufs
else
 df -klF ufs
fi
echo "-----------------------------------------------------------------------------------------"
iostat -En | grep -i size|grep -v "<-1 bytes>"|awk '{print $3}'| cut -d"<" -f2|awk '{soma+=$1/1000000000} END  {print "Installed (physical).: " soma"GB"}'
metastat > /dev/null 2>&1
if [ $? -eq 0 ]; then
 df -klF ufs| /usr/xpg4/bin/grep -vE 'kbytes|:|swap' | awk '{soma+=$2} END {print "Mounted..............:", soma/1000000"GB *NOTE - Some, or all filesystem are mirrored. See above."}'
else
 df -klF ufs| /usr/xpg4/bin/grep -vE 'kbytes|:|swap' | awk '{soma+=$2} END {print "Mounted..............:", soma/1000000"GB"}'
fi
df -klF ufs| /usr/xpg4/bin/grep -vE 'kbytes|:|swap' | awk '{soma+=$3} END {print "Used.................:", soma/1000000"GB"}'
df -klF ufs| /usr/xpg4/bin/grep -vE 'kbytes|:|swap' | awk '{soma+=$4} END {print "Avail................:", soma/1000000"GB"}'

if [ $SWAP -lt 1000000 ]; then # Swap size is lower than 1GB
 SWAP=`echo "scale = 3;$SWAP/1000"|bc`
 echo "Swap.................: ${SWAP}MB"
else
 SWAP=`echo "scale = 4;$SWAP/1000000"|bc`
 echo "Swap.................: ${SWAP}GB"
fi
echo "-----------------------------------------------------------------------------------------"
echo " "

	--------------------------------------------------------------END------------------------------------------------------------
	




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


