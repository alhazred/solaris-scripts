#!/usr/bin/sh
## Title: masskill.sh
## Script submitted to BigAdmin ~ http://www.bigadmin.com/scripts
##
## Submitter:  Jason DuMars
## Submitter Email: jdumars@adb.net
##
## Description: A handy way of killing 
##              multiple processes by keyword


# Check to make sure the argument root is not being passed
if [[ $1 = "root" ]]
	then echo "You cannot run masskill on keyword root!"

# Check for the help switch
elif [[ $1 = "-h" ]]
	then
		echo " "
		echo "  masskill reads in the argument you pass and searches for "
		echo "  processes that match the text either partially or fully."
		echo "  You must be careful not to use ambiguous searches.  For example"
		echo "  masskill pd would kill both ftpd AND httpd. The more specific"
		echo "  the request, the better.  You cannot send root as an argument."
		echo " "

# Check for a null entry and provide usage information
elif [[ -z $1 ]]
	then
     echo " "
     echo "	Usage:"
     echo "	   masskill <argument>"
     echo "	   masskill -h for help"
else
	# Search for the processes and create a temporary file
	ps -ef |grep $1 |cut -b10-14 >/tmp/killtmp.$$ 2>/dev/null

	# Read in arguments line by line from the killtmp file
	while read LINE
	  do
  	  kill $LINE 1>/dev/null 2>/dev/null
	done < /tmp/killtmp.$$

	# Remove temporary file from /tmp
	rm /tmp/killtmp.$$

	# Deliver the news to the user
	echo " "
	echo all processes containing text $1 have been killed...
	echo " "
fi


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


