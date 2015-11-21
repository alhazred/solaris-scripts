#!/bin/ksh
# auto-powerdown.ksh
CRITICALTEMP=79
MAXTEMP=83
FROM="kumar1a@nectech.co.uk"
TO="kumar1a@nectech.co.uk"
COPY="kumar1a@nectech.co.uk"
SHUTDOWN_CMD="/usr/sbin/shutdown -i0 -g5 -y"
sleep_time=60
no_of_loop=15
max_cpu=8
loopvar=0
while [ $loopvar -lt $max_cpu ]
do
count[$loopvar]=0
old_temperature[$loopvar]=0
loopvar=`expr $loopvar + 1`
done

function check_for_5_min {
cpu_id=$2
echo "cpu_id = $cpu_id"
new_temp[$cpu_id]=$1
old_temp=${old_temperature[$cpu_id]}
echo "New Temp  = ${new_temp[$cpu_id]} Old Temp = $old_temp count =
${count[$cpu_id]}"
if test ${new_temp[$cpu_id]} -gt $old_temp 
then
count[$cpu_id]=`expr ${count[$cpu_id]} + 1`
old_temperature[$cpu_id]=${new_temp[$cpu_id]}
fi
}

function ShutDown {
        MESSAGE=`echo "Temperature machine room > $CRITICALTEMP: Temp of
CPU $loopvar = ${new_temp[$loopvar]}"`
        echo "$MESSAGE"  | mailx -c $COPY -s "!!!!!!WARNING!!!!!"  $TO
        #rsh -l root -n mariner $SHUTDOWN_CMD
        #rsh -l root -n tfx $SHUTDOWN_CMD
        #rsh -l root -n liberator $SHUTDOWN_CMD
        #rsh -l root -n sputnik $SHUTDOWN_CMD
        #rsh -l root -n clanger $SHUTDOWN_CMD
        #rsh -l root -n galactica $SHUTDOWN_CMD
        #rsh -l root -n bopeep $SHUTDOWN_CMD
        #rsh -l root -n pathfinder $SHUTDOWN_CMD
        #/usr/sbin/expect-shut-nt
        #rsh -l root -n voyager $SHUTDOWN_CMD
        #rsh -l root -n orion shutdown -i5 -g900 -y
        #rsh -l root -n babylon5 $SHUTDOWN_CMD
        #rsh -l root -n holly shutdown -i5 -g600 -y
        #rsh -l root -n blakey shutdown
        #rsh -l root -n ds9 $SHUTDOWN_CMD
        #rsh -l root -n ds9 halt
        exit
}

temp_start=`/usr/platform/sun4u/sbin/prtdiag -v |grep -n "System
Temperatures"| cut -d: -f 1`
temp_start=`expr $temp_start + 4`
temp_end=`/usr/platform/sun4u/sbin/prtdiag -v |grep -n "Power Supplies"| cut
-d: -f 1`
temp_end=`expr $temp_end - 3`
while [ 1 ]
do
cpu_no=0
start=$temp_start
end=$temp_end

while [ $start -le $end ]
do
TEMP=`/usr/platform/sun4u/sbin/prtdiag -v | head -n $start | tail -1 | tr -s
" " "#" | cut -d# -f4`
if test $TEMP -gt $MAXTEMP 
then
ShutDown
fi
if test $TEMP -gt $CRITICALTEMP 
then
        check_for_5_min $TEMP $cpu_no
fi 
start=`expr $start + 1`
cpu_no=`expr $cpu_no + 1`
done
loopvar=0
while [ $loopvar -lt $max_cpu ]
do
if test ${count[$loopvar]} -gt  3
then
ShutDown $loopvar
fi
loopvar=`expr $loopvar + 1`
done
no_of_loop=`expr $no_of_loop - 1`
echo "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
echo "The Temperature Test done on All CPUS "
if test $no_of_loop -gt 0
then
sleep $sleep_time
else
exit
fi
done





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


