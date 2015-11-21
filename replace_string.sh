#!/bin/bash

#--------------------------------------------------------------------------+
# Purpose  :Script for replacing words/characters in a set of files
#    Better than sed which does not do inline replacement
# Shell    :Bash
# OS       :Solaris
# Version  :1.0
#       Revision :0
# Author   :encrypted_2004@yahoo.com
#--------------------------------------------------------------------------+

### Get the original string
printf "Enter the String to be replaced: "
read ostring

### And the replacement
printf "Enter the String to be substituted: "
read rstring

### The file to do the replacing in
printf "Enter the Path of the file: "
read path

### Process
cd $path
process_string="s/${ostring}/${rstring}/"

### Walk through the files in the dir given
echo
echo
echo "Replacing ${ostring} with ${rstring}"
echo
for file in `ls`
do
	if [ -d $file ] ; then
		continue
	fi
	echo "Processing file: ${file}"
	/bin/perl -p -i -e ${process_string} $file
done
echo
echo

### Exit 
exit 0




##############################################################################
### This script is submitted to BigAdmin by a user of the BigAdmin community.
### Sun Microsystems, Inc. is not responsible for the
### contents or the code enclosed. 
###
###
### Copyright 2007 Sun Microsystems, Inc. ALL RIGHTS RESERVED
### Use of this software is authorized pursuant to the
### terms of the license found at
### http://www.sun.com/bigadmin/common/berkeley_license.html
##############################################################################


