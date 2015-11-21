#!/sbin/sh

# Last Author: Matthew Miller
# Original Author: Matthew Miller
#
# Email: matthew.miller@digex.com
# Script name: kernel_values.sh
# Descriptions: Tool views/modifies active kernel objects
# Version: 1.3
# Tested on: Solaris 8,9 (Not to be run on a non-Solaris system)
# Permissions: Requires root access
#
#      [Usage]: kernel_values.sh <object variable>
#               kernel_values.sh <object variable> w <new value in decimal>
#               kernel_values.sh listobjvalues
#               kernel_values.sh listobjects
#
# Syntax description:
#               
#               kernel_values.sh <object variable>
#                                               Give the value in decimal
#                                               of the kernel object variable
#		
#		kernel_values.sh <object variable> w <new value in decimal>
#                                               Modifies the kernel variable
#                                               using adb
#		
#		kernel_values.sh listobjvalues	Lists kernel object variables
#                                               and its corresponding value.
#
#				(Once started, ^D / ^C will not stop it)
#
#		kernel_values.sh listobjects
#                                               Displays kernel object
#                                               variables, no values
#
# Example:
# 
# Viewing a kernel value
#
#            # ./kernel_values.sh maxusers
#            (32bit) maxusers:       500             
#
# Modifing the value in realtime 
#    * change will not be effective after reboot, unless set in /etc/system
#
#            # ./kernel_values.sh maxusers w 510
#            Before: (32bit) maxusers: 500
#             After: (32bit) maxusers: 510
#
#
# License: Agreement discussed in version 2.0 of the GPL
#
# 
# Disclaimer: I hope that this script is valuable as a part of your 
# systems administration toolkit. Your use of the script contained, 
# however, is at your sole risk. All information and use is provided 
# "as -is", without any warranty, whether express or implied, of its 
# accuracy, completeness, fitness for a particular purpose, and title.  
# In short, this authored project is not guaranteed or supported in 
# any manner by the author.  Use at own risk.
# ~~~ ~~~~~~
#
########################################################################
#
# Friendly advise: When making kernel modifications to objects, use
# sunsolve.sun.com and docs.sun.com as a reference and remember this
# important rule ... its not can you ... its should you.
#

# functions

usage () {
		echo "  [Usage]: kernel_values.sh <object variable>"
		echo "           kernel_values.sh <object variable> w <new value in decimal>"
		echo "           kernel_values.sh listobjvalues"
		echo "           kernel_values.sh listobjects"
}

# main logic module

case "$2" in
'w')
case "$3" in
'')
		usage
		;;
*)
		/usr/ccs/bin/nm /dev/ksyms | /usr/bin/grep "\|OBJT" | /usr/bin/grep -v "\|_" | /usr/bin/awk -F\| '{printf "%s\n",$8}' | /usr/bin/grep "^$1$" > /dev/null || exit;

		BEFORE_VAR=`/usr/ccs/bin/nm /dev/ksyms | /usr/bin/grep "\|OBJT" | /usr/bin/grep -v "\|_" | /usr/bin/awk -F\| '{printf "%s %s\n",$3*1,$8}' | /usr/bin/grep " $1$" | /usr/bin/nawk '{if ($1 == "2") {printf "(%sbit) ",$1*8;system("echo "$2"/d | /usr/bin/adb -k | /usr/bin/grep : | /usr/bin/tail -1");} if ($1 == "4") {printf "(%sbit) ",$1*8;system("echo "$2"/D | /usr/bin/adb -k | /usr/bin/grep : | /usr/bin/tail -1");} if ($1 == "8") {printf "(%sbit) ",$1*8;system("echo "$2"/E | /usr/bin/adb -k | /usr/bin/grep : | /usr/bin/tail -1");}}'`
		echo $BEFORE_VAR | /usr/bin/grep 16bit > /dev/null&&echo "$1/w 0t$3" | /usr/bin/adb -kw > /dev/null
		echo $BEFORE_VAR | /usr/bin/grep 32bit > /dev/null&&echo "$1/W 0t$3" | /usr/bin/adb -kw > /dev/null
		echo $BEFORE_VAR | /usr/bin/grep 64bit > /dev/null&&echo "$1/Z 0t$3" | /usr/bin/adb -kw > /dev/null
		AFTER_VAR=`/usr/ccs/bin/nm /dev/ksyms | /usr/bin/grep "\|OBJT" | /usr/bin/grep -v "\|_" | /usr/bin/awk -F\| '{printf "%s %s\n",$3*1,$8}' | /usr/bin/grep " $1$" | /usr/bin/nawk '{if ($1 == "2") {printf "(%sbit) ",$1*8;system("echo "$2"/d | /usr/bin/adb -k | /usr/bin/grep : | /usr/bin/tail -1");} if ($1 == "4") {printf "(%sbit) ",$1*8;system("echo "$2"/D | /usr/bin/adb -k | /usr/bin/grep : | /usr/bin/tail -1");} if ($1 == "8") {printf "(%sbit) ",$1*8;system("echo "$2"/E | /usr/bin/adb -k | /usr/bin/grep : | /usr/bin/tail -1");}}'`
		/usr/bin/printf "Before: ";
		echo $BEFORE_VAR;
		/usr/bin/printf " After: ";
		echo $AFTER_VAR;
		;;
esac
	;;
*)
case "$1" in
'')
		usage
		;;
'listobjvalues')
		/usr/ccs/bin/nm /dev/ksyms | /usr/bin/grep "\|OBJT" | /usr/bin/grep -v "\|_" | /usr/bin/awk -F\| '{printf "%s %s\n",$3*1,$8}' | /usr/bin/nawk '{if ($1 == "2") {printf "(%sbit) ",$1*8;system("echo "$2"/d | /usr/bin/adb -k | /usr/bin/grep : | /usr/bin/tail -1");} if ($1 == "4") {printf "(%sbit) ",$1*8;system("echo "$2"/D | /usr/bin/adb -k | /usr/bin/grep : | /usr/bin/tail -1");} if ($1 == "8") {printf "(%sbit) ",$1*8;system("echo "$2"/E | /usr/bin/adb -k | /usr/bin/grep : | /usr/bin/tail -1");}}'
        	;;
'listobjects')
		/usr/ccs/bin/nm /dev/ksyms | /usr/bin/grep "\|OBJT" | /usr/bin/grep -v "\|_" | /usr/bin/awk -F\| '{printf "%s %s\n",$3*1,$8}' | /usr/bin/nawk '{if ($1 == "2") {printf "(%sbit) %s\n",$1*8,$2;} if ($1 == "4") {printf "(%sbit) %s\n",$1*8,$2;} if ($1 == "8") {printf "(%sbit) %s\n",$1*8,$2;}}'
		;;
*)
		/usr/ccs/bin/nm /dev/ksyms | /usr/bin/grep "\|OBJT" | /usr/bin/grep -v "\|_" | /usr/bin/awk -F\| '{printf "%s %s\n",$3*1,$8}' | /usr/bin/grep " $1$" | /usr/bin/nawk '{if ($1 == "2") {printf "(%sbit) ",$1*8;system("echo "$2"/d | /usr/bin/adb -k | /usr/bin/grep : | /usr/bin/tail -1");} if ($1 == "4") {printf "(%sbit) ",$1*8;system("echo "$2"/D | /usr/bin/adb -k | /usr/bin/grep : | /usr/bin/tail -1");} if ($1 == "8") {printf "(%sbit) ",$1*8;system("echo "$2"/E | /usr/bin/adb -k | /usr/bin/grep : | /usr/bin/tail -1");}}'
		;;
esac
	;;
esac



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


