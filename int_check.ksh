#!/bin/ksh

# 2004-01-20 Tom Kranz (tom@siliconbunny.com)

# This script is distributed under the GNU Public License (GPL) with the
# following extra conditions:
# - attritbution must be maintained
# - CD-ROM or similar media for commercial distribution without the prior 
#   approval of the author

# This script will take 2 arguments - first one being the interface name 
# (ce, hme etc.) and the second one the instance number

# We'll then call ndd and pull up some information about speed and
# duplex settings

# Path to ndd
NDD=/usr/sbin/ndd

# Make sure we got our command line args
if [[ ${1} == "" ]] || [[ ${2} == "" ]]
then
	echo ""
	echo "Usage:"
	echo "int_check.ksh <interface> <instance number>"
	echo ""
	echo "eg. int_check.ksh ce 0"
	echo ""
	exit 1
fi

# The parameters we want to check - all the usual suspects
PARMS="adv_autoneg_cap adv_1000fdx_cap adv_1000hdx_cap adv_100fdx_cap adv_100hdx_cap adv_10fdx_cap adv_10hdx_cap"

# Output time!
echo ""
echo "Port speed/duplex settings for ${1} instance ${2}:"

# We need to set the correct instance first
${NDD} -set /dev/${1} instance ${2}

# Loop through the ndd parameters, retrieve the values, and spit them out
for VAR in ${PARMS}
do
	VALUE=$(${NDD} -get /dev/${1} ${VAR})
	echo "${1}:${2}  ${VAR}			${VALUE}"
done
echo ""

exit 0




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


