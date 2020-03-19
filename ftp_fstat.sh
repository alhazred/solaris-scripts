#!/bin/sh

### fstat
###
### Script to check whether a FTP download 
### session is in progress for a file
###
### Send all comments to: suniluce007@yahoo.com 
###
if [ $# -lt 1 ]
then
  echo "usage: ./fstat <filename> or * for all files in directory"
  exit
fi
cnt=$#
count=0
while [ $count -lt $cnt ]
do

if [ -d $1 ]
then
	tput smso
	echo "Skipping Directory entry $1...."
	tput rmso
	shift
	count=`expr $count + 1`
	continue
fi


if [ -f $1 ]
then
	fuser $1  > /tmp/a 2>/tmp/c
	if [ -s /tmp/a ]
		then
	 	b=`awk ' { print $1}' /tmp/a`
		ps -ef | grep $b | grep ftp | grep -v "grep" > /tmp/b
		if [ $? = 0 ] 
		then
   			tput smso
			echo "Still Downloading $1 ......"
   			tput rmso
 		else
   			echo "Downloading Completed or a ftp session is not "
			echo "currently in progress for the file $1"
		fi
	else
   		echo "Downloading Completed or a ftp session is not "
		echo "currently in progress for the file $1"
 	fi
else
 	echo "File $1 Does Not Exist. Please specify a valid file."
 	count=`expr $count + 1`
 	shift
 	continue
fi
	count=`expr $count + 1`
	shift
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


