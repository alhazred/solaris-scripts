#!/bin/ksh
##########################################################################
##			END TIME SCRIPT					##
##              By UDOMSAK NAKSENA ( udomsak.n@g-able.com )            	##
##########################################################################
# usage: 
#	timecountdown 13       ==> 13:00:00
#	timecountdown 13 20    ==> 13:20:00
# 	timecountdown 13 30 30 ==> 13:30:30
#

display_time () {
	clear
	echo "Set time to  : $lastH:$lastM:$lastS" 
	echo "Current time : `date +%T`" 
	echo "Remain time  : $1:$2:$3"
}
lastM=$2 ; lastM=${lastM:="00"}
lastS=$3 ; lastS=${lastS:="00"}
typeset -Z2 lastH=$1 lastM lastS
export lastH lastM lastS

let "last=(lastH*3600)+(lastM*60)+lastS"

until [ "$remain" == "0" -o "$H$M$S" == "000000" ] 
do
	nowH=`date +%H`
	nowM=`date +%M`
	nowS=`date +%S` 	

	let "now=(nowH*3600)+(nowM*60)+nowS"
	let "remain=last-now"
	let "H=remain/3600"
	let "M=(remain%3600)/60"
	let "S=remain%60"

	typeset -Z2 H M S
	display_time $H $M $S 
	sleep 1
done
	echo Time out
	# any command when end script



##############################################################################
### This script is submitted to BigAdmin by a user of the BigAdmin community.
### Sun Microsystems, Inc. is not responsible for the
### contents or the code enclosed. 
###
###
### Copyright 2008 Sun Microsystems, Inc. ALL RIGHTS RESERVED
### Use of this software is authorized pursuant to the
### terms of the license found at
### http://www.sun.com/bigadmin/common/berkeley_license.html
##############################################################################


