#!/bin/ksh
if [ $# -ne 1 ]; then
	echo ""
	echo "\tUsage: $0 newsize"
	echo ""
	echo "Where newsize is the size in kilobytes (default) that you want /tmp to be"
	echo "Alternatively you can specify size in (p)ages (m)egabytes or (g)igabytes"
	echo ""
	exit
fi

if [ -z `id | grep "uid=0"` ]; then
	echo "ERROR -- you must be root to run this script"
	exit
fi

pagesize=`pagesize`
pagesize=$(( $pagesize / 1024 ))
echo "Pages are ${pagesize}K"

newsize=`echo $1 |sed -e 's/\([kKmMgGpP]\)/ \1/' | tr '[a-z]' '[A-Z]'`
type=`echo "$newsize" | awk '{print $2}'`
newsize=`echo "$newsize" | awk '{print $1}'`

case "$type" in
	P) newsize=$(( $newsize * $pagesize ))
		;;
	M) newsize=$(( $newsize * 1024 ))
		;;
	G) newsize=$(( $newsize * 1024 * 1024 ))
		;;
esac

if [ "$newsize" -lt 102400 ]; then
	echo "ERROR -- this script won't let you go below 100MB (102400K)"
	echo ""
	exit
fi

tmp_size=`df -k /tmp | grep ^swap | awk '{print $2}'`
if [ "$tmp_size" -eq 0 ]; then
	echo "Error, cannot get size reading on /tmp"
	exit
fi

tmp_pages=$(( $tmp_size / $pagesize ))
echo "/tmp is ${tmp_size}K (${tmp_pages} pages)"

newsize_pages=$(( $newsize / $pagesize ))
echo "/tmp will be resized to ${newsize}K (${newsize_pages})"

if [ "$tmp_size" -gt "$newsize" ]; then
	echo "ERROR -- this script cannot be used to shrink /tmp"
	echo ""
	exit
fi

tmp_addresses=`echo "vfs" | crash | grep tmpfs | awk '{print $6}'`
if [ -z "$tmp_addresses" ]; then
	echo "Ach, cannot get addressed from crash..."
	exit
fi
for i in $tmp_addresses; do
	echo "Looking at address $i"
	mysize=`echo "${i}+18/e" | adb -k | grep -v physmem | awk '{print $2}'`
	if [ "$mysize" -eq tmp_pages ]; then
		if [ -z "$foundit" ]; then
			echo "Looks like $i is the one!"
			foundit=$i
		else
			echo "Interesting!  Looks like there's more than one match."
			echo "You're going to have to do this by hand"
			exit
		fi
	fi
done
if [ -z "$foundit" ]; then
	echo "Error -- cannot locate a tmpfs filesystem that's the size of /tmp"
	exit
fi

echo "Before:"
df -k /tmp
echo "${foundit}+18/Z 0T${newsize_pages}" | adb -k -w
#echo "${foundit}+18/Z 0T${newsize_pages}"
echo "After:"
df -k /tmp












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


