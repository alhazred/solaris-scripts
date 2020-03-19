#!/bin/bash
# 
# Copyright (c) 2003 by Sungard Availability Services
# All rights reserved.
#
# pkgque "@(#)	0.1	10/22/03 MJM"
db=/var/sadm/install/contents
date=`date +01/19/06M%S`

case "$1" in
'-f')
	[ -r $db ] && cat $db | grep $2 | while read line
	do
		pkg=${line##* }
		echo $pkg >> /tmp/$date.pkg
	done
	if [ ! -e /tmp/$date.pkg ]; then
		echo "  File $2 does not belong to a package." 
		echo ""
	else
		sort -u /tmp/$date.pkg | while read var; do pkginfo $var; done
		echo ""
		rm -f /tmp/$date.pkg
	fi
	;;

'-fl')
	[ -r $db ] && cat $db | grep $2 | while read line
	do
		pkg=${line##* }
		echo $pkg >> /tmp/$date.pkg
	done
	if [ ! -e /tmp/$date.pkg ]; then
		echo "  File $2 does not belong to a package." 
		echo ""
	else
		cat /tmp/$date.pkg | while read pack; do pkginfo -l $pack; done
		rm -f /tmp/$date.pkg
	fi
	;;

'-d')
	[ -r $db ] && cat $db | grep $2 | while read line
	do
		pkg=${line##* }
		echo $pkg >> /tmp/$date.pkg
	done 
	if [ ! -e /tmp/$date.pkg ]; then
		echo "  Directory $2 does not belong to a package." 
		echo ""
	else
		sort -u /tmp/$date.pkg | while read pack; do pkginfo $pack; done
		echo ""
		rm -f /tmp/$date.pkg
	fi
	;;

*)
	echo "pkgque: illegal option -- $1"
	echo ""
	echo "pkgque -d directory"
	echo "pkgque -f file"
	echo "pkgque -fl file"
	echo "where"
	echo "  -d	Directory you want to search the package database for"
	echo "  -f	File you want to search the package database for"
	echo "  -fl     Long Listing of Package correlating to the file"
	echo ""
	exit 1;;
esac
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


