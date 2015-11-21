#!/bin/ksh
#        Created by: K. March -- 24Mar03
## /tmp/$SUNdata (IP xxx.xxx.xxx.xxx ADDRESS) - March 12 2003
##        Should be run as uid: root
########################################################
SUNdata=/tmp/`uname -n`data.txt
LN=-------------------------------------------------------------------------
touch $SUNdata

## Display IP address of machine  #
echo "##/$SUNdata (`ifconfig hme0 | grep inet| awk '{print $2}'`) 
`/usr/bin/date`" >> $SUNdata
echo "##`uname -i|grep -v SUNW`" >> $SUNdata
echo "" >> $SUNdata
echo $LN >> $SUNdata

####### Get hostid  ######
echo "Hostid: `/usr/bin/hostid`" >> $SUNdata
echo "" >> $SUNdata
echo $LN >> $SUNdata

####### Get Serial #   ######
## Must be manually edited
echo "Serial Number:  _ _ _ _ _ _ _" >> $SUNdata
echo "" >> $SUNdata
echo $LN >> $SUNdata

####### Get uname -a ######
echo "uname -a:" >> $SUNdata
/usr/bin/uname -a >> $SUNdata
echo "" >> $SUNdata
echo $LN >> $SUNdata

####### Get /etc/release ####
echo "/etc/release:" >> $SUNdata
cat /etc/release >> $SUNdata
echo "" >> $SUNdata
echo $LN >> $SUNdata

####### Get Sys Memory  ######
echo "System Memory:" >> $SUNdata
prtconf | grep Mem >> $SUNdata
echo "" >> $SUNdata
echo $LN >> $SUNdata

####### Get Psrinfo  ######
echo "Processor information:" >> $SUNdata
/usr/sbin/psrinfo >> $SUNdata
echo "" >> $SUNdata
echo $LN >> $SUNdata

####### Get nic speed #####
## Assumes one is using eri for NIC  ##
echo "NIC speed: (ndd -get /dev/eri link_speed) [0=10; 1=100]: `ndd -get 
/dev/eri link_speed`" >> $SUNdata
echo "" >> $SUNdata
echo $LN >> $SUNdata

####### Get hosts info ####
echo "/etc/hosts:" >> $SUNdata
cat /etc/hosts >> $SUNdata
echo $LN >> $SUNdata

####### Get resolv.conf  ####
echo "/etc/resolv.conf:" >> $SUNdata
cat /etc/resolv.conf >> $SUNdata
echo "" >> $SUNdata
echo $LN >> $SUNdata

####### Get defaultrouter ####
echo "/etc/defaultrouter:" >> $SUNdata
cat /etc/defaultrouter >> $SUNdata
echo "" >> $SUNdata
echo $LN >> $SUNdata

####### Get passwd  ####
echo "/etc/passwd:" >> $SUNdata
cat /etc/passwd >> $SUNdata
echo "" >> $SUNdata
echo $LN >> $SUNdata

####### Get vfstab  ####
echo "/etc/vfstab:" >> $SUNdata
cat /etc/vfstab >> $SUNdata
echo "" >> $SUNdata
echo $LN >> $SUNdata

####### Get dfstab  ####
echo "/etc/dfs/dfstab:" >> $SUNdata
cat /etc/dfs/dfstab >> $SUNdata
echo "" >> $SUNdata
echo $LN >> $SUNdata

####### Get system  ####
echo "/etc/system:" >> $SUNdata
tail -40 /etc/system >> $SUNdata
echo "" >> $SUNdata
echo $LN >> $SUNdata

####### Get eeprom  ####
echo "eeprom values:" >> $SUNdata
/usr/sbin/eeprom >> $SUNdata
echo "" >> $SUNdata
echo $LN >> $SUNdata

####### Get nddsets  ####
echo "/etc/init.d/nddsets:" >> $SUNdata
cat /etc/init.d/nddsets >> $SUNdata
echo "" >> $SUNdata
echo $LN >> $SUNdata

##### !! Only get when a disk is mirrored  ########
##### Uncomment the following lines if needed #####

####### get metadb info ##
#metadb >> $SUNdata
#echo "" >> $SUNdata

###### get metastat
#metastat >> $SUNdata
#echo "" >> $SUNdata
# !!                                    ####
###################################################

### The following script defaults to grab
### information from a server with two disks.
### Uncomment lines based on number of disks in server.
####### Disk Partitions:
echo "" >> $SUNdata
echo "Disk Partitions:\c" >> $SUNdata

echo "0\n" "p\n" "p\n" | format >> $SUNdata
echo "" >> $SUNdata
echo "1\n" "p\n" "p\n" | format >> $SUNdata

#echo "" >> $SUNdata
#echo "2\n" "p\n" "p\n" | format >> $SUNdata
#echo "" >> $SUNdata
#echo "3\n" "p\n" "p\n" | format >> $SUNdata
#echo "" >> $SUNdata
#echo "4\n" "p\n" "p\n" | format >> $SUNdata
#echo "" >> $SUNdata
#echo "5\n" "p\n" "p\n" | format >> $SUNdata
#echo "" >> $SUNdata
#
echo $LN >> $SUNdata
## Mail file to specified e-mail address for archival.
##       uncomment as needed.
#mailx -s "System information for `uname -n`; collected on `date +u %m%d`" 
'place e-mail@address here' < $SUNdata
## END




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


