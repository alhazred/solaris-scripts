#!/bin/ksh
#
# This script produces a complete tree structure for the directory
# in which it is running.
#

#store the current directory
InitDir=`pwd`
line='|----'
dirStru()
{
incl='.....'
dname=$1
cd $dname >/dev/null
if [ $? -eq 0 ]
then
        for k in `ls`
        do
                if [[ -d $k ]]
                then
                  echo "    $line$k"
                  line=$incl$line
                  dirStru $k
                  cd ..
		  #remove smallest prefix pattern(.....)
                  line=${line#.....}
                fi
        done
fi
}

# main
#Tree sub-directory structure under $1 directory"

if [ $# -ne 1 ] 
then
   echo "Usage:$0 <directory-name>"
   exit 1
fi

echo "$1"
for i in `ls`
do
   if [[ -d $i ]]
   then
      echo " |..$i"
      dirStru $i
      cd $InitDir
   fi
done



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


