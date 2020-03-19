#!/bin/sh

### To check users home directory for invalid .forward file 
### Vinoth 19.10.2000 (vinothu@hotmail.com)
### DEFINE DIR 1st LINE & DOMAIN NAME IN 2ND(domain) LINE



dir="/home2"
domain="test.com"
path=`ls -l $dir | grep "^d" | awk '{print $9}'`
log="$dir/frwdlog"
tput blink
echo " ";echo "Developed by - Vinoth - vinothu@hotmail.com";echo " "
tput rmso
cd "$dir"
for x in `echo $path`
 do
  cd $x
  echo "entering in to $x dir."
  if [ -f .forward ]
  then
    chk=`cat .forward | cut -d"@" -f2-`
    if [ "$chk" = "$domain" ]
    then
      echo "not found"
     else
      echo ".forward found in $x's directory" 
      echo ".forward found in $x's directory" >> $log
      cat .forward >> $log
      echo "----------------------------------------------------------" >> $log
      echo " " >> $log
     fi              
  fi
cd ..
done
echo " ";echo " ";echo "Check $log file for more information"


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


