#!/usr/bin/ksh

#------------------------------------------------------------------------------
#Name : netcalc
#Author: Dwai Lahiri
#Date: 10/07/2003
#This script will calculate the net id for the provided IP address
#and netmask
#------------------------------------------------------------------------------

get_ip_nm()   
{
set ${IP_STRING}  #Split IP address by each octet
export W1=${1}
shift
export W2=${1}
shift
export W3=${1}
shift
export W4=${1}

set ${NETMASK_STRING}	#Split Netmask by each octet
export M1=${1}
shift
export M2=${1}
shift
export M3=${1}
shift
export M4=${1}
}

operate()	#Logical AND operation on each corresponding octet
{
export NID1=$(( $W1&$M1 ))
export NID2=$(( $W2&$M2 ))
export NID3=$(( $W3&$M3 ))
export NID4=$(( $W4&$M4 ))
}

print_usage()	#Print Usage and shout profanities
{
echo "Usage: $0 -a <IP ADDRESS> -m <NETMASK>"
exit 1
}


#####
#Main
#####

if [ $# -lt 4 ]; then		#Refuse to work without correct
  print_usage && exit 1		#number of arguments
else
  continue
fi

while getopts a:m: switch	#Use getopts to give a professional touch
do
  case ${switch} in
  a)
	test -z ${OPTARG} && print_usage
	IP=${OPTARG}
	;;
  m)
	test -z ${OPTARG} && print_usage
	NETMASK=${OPTARG}
	;;

  *)
	print_usage
	;;
  esac
done
shift `expr ${OPTIND} - 1`

#Filter out the dots (because IP is in dotted decimal convention)
#Insert spaces in between

IP_STRING=`echo ${IP}|awk -F. '{print $1,$2,$3,$4}'`	
NETMASK_STRING=`echo $NETMASK|awk -F. '{print $1,$2,$3,$4}'`


#Run the subroutines...oops!! Functions!!
#
get_ip_nm && operate 

echo ${NID1}.${NID2}.${NID3}.${NID4}	#Return effective Net ID


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


