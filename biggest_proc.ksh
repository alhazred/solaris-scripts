#!/bin/ksh
# Quick script to display the top 10 "biggest" processes
# as designated by their "private bytes" size in pmap output
#
# Updated for Solaris 10 which changed the fields in pmap output.
case $(uname -r) in
	5.8|5.9) field=6 ;;
	*) field=5 ;;
esac

id | grep '=0' > /dev/null
if [ $? -ne 0 ]; then
	echo "Must be run by root."
	exit
fi

echo "Figuring top 10 processes, this takes a moment..."
echo "PID: Size (in KB)"

# Run pmap on everything.  Errors to /dev/null -- some are expected.
pmap -x /proc/* 2>/dev/null | \
nawk -v FIELD=$field 'BEGIN { FIRST=1; } /total Kb/ {
	if (FIRST==0) { # NOT first pass
		print $FIELD;
	} else {
		print "1:",$FIELD; # on first pass, presume the PID is 1
		FIRST=0;
	}
	getline; # After the total line, the next line is the pid of the next record
	printf "%s ",$1; # Using printf to avoid generating a CR
} END { printf "\n"; }' | sort -n +1 | tail -10




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


