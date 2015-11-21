#!/bin/sh

###
## replace_word.sh
##
## Replaces multiple entries for a word in a file
##
## Usage: ./replace_word [word1] [word2] [file]
##
## Submitter: Edmond Baroud 
## Submitter Email: ebaroud@yahoo.com

TMP=/tmp # your tmp dir
#
if [ "$1" = "" -o "$2" = "" -o "$3" = "" ]; then
	echo "usage ./change <word1> <word2> [filename]"
else
        sed "s/$1/$2/g" $3 > /${TMP}/change."$1".to."$2".tmp 2>/dev/null
 
# we did a cat here in order
# to keep the file's permissions and ownership the same
# instead of using move or copy.
cat /${TMP}/change.$1.to.$2.tmp > $3;
	rm /${TMP}/change.$1.to.$2.tmp
fi


##############################################################################
### This script is submitted to BigAdmin by a user of the BigAdmin community.
### Sun Microsystems, Inc. is not responsible for the
### contents or the code enclosed. 
###
###
### Copyright 2005 Sun Microsystems, Inc. ALL RIGHTS RESERVED
### Use of this software is authorized pursuant to the
### terms of the license found at
### http://www.sun.com/bigadmin/common/berkeley_license.html
##############################################################################


