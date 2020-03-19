#!/bin/ksh
# @(#) yesterday.ksh Shell to deduct one day form given or current date
# SCCS= /export/home/zika/sccs/s.yesterday.ksh
# SCCS Ident = 1.2
# SCCS Delta Date : 06/01/11 Time: 12:35:26

##################################################
## 	Yesterday script by Udomsak Naksena	## 
##	First Logic Company Limited (Thailand)  ##
##	Email: udomsak@gmail.com                ##
##                                              ##
##      Updated 01/2006 - Zivojin Jovanovic     ##
##################################################
#
#	$ yesterday
#	$ yesterday [mm] [dd] [yyyy]
#
##################################################

# debug
# set -x

dd=$1 ; mm=$2 ;YY=$3
dd=${dd:=`date +%d`}
mm=${mm:=`date +%m`}
YY=${YY:=`date +%Y`}
HH=`date +%H`
MM=`date +%M`
SS=`date +%S`


# let "today=(dd*86400)+(HH*3600)+(MM*60)+SS"
# let "yesterday=today-86400"

y_YY=$YY
y_mm=$mm
let "y_dd=dd-1"
y_HH=$HH
y_MM=$MM
y_SS=$SS

if (( dd==1 )) 
then 	let y_mm=mm-1
	case $y_mm in
		1|3|5|7|8|10|0	) 	y_dd=31 ;;
		4|6|9|11 )		y_dd=30 ;;
		2)	if (( YY%4 == 0 ))
				then y_dd=29 
				else y_dd=28 
			fi
			;;
	esac	
	if (( mm==1 ))
	then	let y_YY=YY-1
		y_mm=12
	fi
fi

typeset -Z2  mm dd HH MM SS y_mm y_dd y_HH y_MM y_SS 
echo "Today     : $YY/$mm/$dd $HH:$MM:$SS"
echo "Yesterday : $y_YY/$y_mm/$y_dd $y_HH:$y_MM:$y_SS" 

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


