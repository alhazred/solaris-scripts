#!/bin/ksh

###
## catmail
##
## Reads files and sends them via email.
## Takes a file name as an argument on the command line. 
## To send multiple files: Comment out FILES lines, 
##    uncomment lines and list files in $DATFILE.

##
## Submitter:  Gideon Rasmussen
## Submitter Email: gideon@infostruct.net


MAILADD=foo@bar.com
FILE=$1
SRVNM=`uname -n`
#DATFILE=/opt/admin/scripts/catmail.dat

if [ -z "$FILE" ]; then

echo " "
echo "Syntax: $0 [file]"
echo  " "
exit 1
fi

### Uncomment out following 3 commented
### lines for multiple files read in from
### $DATFILE above
#while read -r FILE
#do
	if [ -f $FILE ]; then
		mail $MAILADD <<EOF

From: $0
To: $MAILADD
Subject: $FILE on $SRVNM

`cat $FILE`

EOF

	else
		echo "$FILE : File not found."
	fi

#done < $DATFILE

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


