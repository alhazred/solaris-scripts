#!/usr/bin/ksh
#
# Checks the speed and settings of Sun HME and QFE interfaces.
# Original script 'check_lan_speed.ksh' located
#    at http://www.angelfire.com/pq/osm/scripts/check_lan_speed.ksh
#
# Olivier S. Masse
# omasse@iname.com
#
# Enhancements Added
# --------------------
# Added checks for the speed and settings of Sun GE and CE interfaces
#
#       The documentation for the CE adapter can be found in Sun
#       part no. 816-1702-11 February 2003, Revision A
#
# Ed Gurski
# egurski@imf.org
# 3/5/03
#

AUTONEG="autoneg_cap" # Set Auto-negotiate parameter
FDX="fdx"              # Set speed suffix for CE interface

for i in `ifconfig -a | egrep "^ge|^hme|^qfe|^ce" | awk '/^[a-z]*[0-9]*: / {print $1}' | sed s/://`
do
	device=`echo $i | sed s/[0-9]*$//`
	instance=`echo $i | sed s/^[a-z]*//`
	ndd -set /dev/$device instance $instance
	if [ "$device" = "ce" ]  # Is this a GigaSwift Adapter?
		then                        # Yes,,,
		speed=`kstat ce:$instance|grep link_speed| # Get the link speed of the adapter
		while read a b                  # Read the link speed
		do
			echo "$b"                       # Set the link speed
		done`
		autoneg=`kstat ce:$instance|grep cap_autoneg| # Set the autonegotiate mode
		head -1|                        # Get only the first line
		while read a b
		do
			echo "$b"                       # Set the negotiate mode
		done`
		duplex=`kstat ce:$instance|grep cap_$speed$FDX| # Get the duplex mode of the adapter
		head -1|                        # Get only the first line
		while read a b
		do
			echo "$b"                       # Set the duplex mode
		done`
	else                                            # No,,,
		duplex=`ndd -get /dev/$device link_mode`
		speed=`ndd -get /dev/$device link_speed`
		if [ $speed = "1000" ]           # Is this a gigabit ethernet?
		then                            # Yes,,,
			AUTONEG="1000$AUTONEG"   # Set variable for gigabit ethernet
		fi
		autoneg=`ndd -get /dev/$device adv_$AUTONEG` # Get autonegotiate mode
	fi
	
	case "$speed" in
		"0") echo "$i is at 10 mbit \c";;
		"1") echo "$i is at 100 mbit \c";;
		"1000") echo "$i is at 1000 mbit \c";;  # Set link speed as gigabit
		*) echo "$i is at ??? mbit \c";;
	esac
	case "$duplex" in
		"0") echo "half duplex \c";;
		"1") echo "full duplex \c";;
		*) echo "??? duplex \c";;
	esac
	case "$autoneg" in
		"0") echo "with auto negotiation";;
		"1") echo "without auto negotiation";;
		*) echo "??? auto negotiation";;
	esac
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


