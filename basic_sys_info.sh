#!/bin/sh

#############################################################
# This gives basic sysinfo  
############################################################

echo "The System-Hostname=`hostname`"
echo "The System-Uptime= `uptime|awk '{ print $3,$4,$5 }'`"
sm=`prtconf -pv|grep banner-name|awk -F"'" '{ print $2 }'`
echo "The system-make=$sm"
mm=`prtconf -pv|grep Mem|awk ' { print $3,$4 }'` 
echo "The system-memory=$mm"
ps=`psrinfo|grep on-line|wc -l`
echo "The Sytem-process-count=,$ps"
mc=`ifconfig  -a|awk '/ether/ { print $2 }'`
echo "The System-MacAddress=$mc"
bt=`isainfo -kv`
echo "The System- kernel-type=$bt"




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


