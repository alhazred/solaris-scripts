#!/bin/sh

########################################################################
# Author:      Chris Williams
#              E-mail: cbwilliams@mail.rit.edu
#                      kermit6306@yahoo.com
#              AIM:    kermit6306
#              WWW:    http://www.rit.edu/~cbw8398
# Filename:    dhinfo.sh
# Date:        March 16, 2003
# Description: Bourne Shell script. Displays important information 
#              from the DHCP server for a particular interface.
#              Sun Solaris DHCP client dhcpagent(1) must be installed 
#
# References:  Assigned Numbers RFC: http://www.ietf.org/rfc/rfc1700.txt
#              Sun manuals: dhcpinfo(1), dhcpagent(1) 
#
#
########################################################################

if [ $# -ne 1 ]; then
	echo "Usage: $0 <iface>"
	exit
fi

if [ ! -x /sbin/dhcpinfo ]; then
	echo "Error: /sbin/dhcpinfo not executable. Check \c"
	echo "dhcpagent installation."
	exit
fi

echo ""

# initialize variables
iface=$1
count=1
while test $count -lt 77
do
	result=`/sbin/dhcpinfo -i $iface $count`
        if [ ! -z "$result" ]; then
		case $count in
		1) echo "Subnet Mask: \c" ;;
		3) echo "Gateway: \c" ;;
		5) echo "Name Server: \c";;
		6) echo "Domain Server: \c";;
		12) echo "Hostname: \c";;
		15) echo "Domain Name: \c";;
		19) echo "IP Fowarding On/Off: \c";;
		20) echo "Source Routing On/Off: \c";;
		21) echo "Filtering Policy: \c";;
		28) echo "Broadcast Adress: \c";;
		23) echo "Default IP TTL: \c";;
		37) echo "Default TCP TTL: \c";;
		40) echo "NIS Domain: \c";;
		41) echo "NIS Server: \c";;
		44) echo "NetBIOS Server: \c";;
		50) echo "Requested IP Address: \c";;
		51) echo "IP Address Lease Time: \c";;
		53) echo "DCHP Message Type: \c";;
		54) echo "DHCP Server Name: \c";;
		56) echo "DHCP Error Message: \c";;
		esac
		echo $result
 		echo ""
	fi
	count=`expr $count + 1`
done
