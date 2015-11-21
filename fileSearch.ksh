#!/usr/bin/ksh
# this script use the find unix command to list the files older that specified 
# days and also files between two specified days
#
# Usage 1 : fileSearch.ksh -s <days> <path>
# Exp: fileSearch.ksh -s 450 /home/oracle/arch 
# (This will list the files older than 450 days in /home/oracle/arch directory)
#
# Usage 2 : fileSearch.ksh -s <days> -e <days> <path>
# Exp: fileSearch.ksh -s 450 -e 550 /home/oracle/arch 
# (This will list the files between 450 and 550 days older in /home/oracle/arch directory)


#set -x

sflag=0
eflag=0
LOG=/tmp/result.log
LOG1=/tmp/result1.log
LOG2=/tmp/result2.log

while getopts :s:e: days
do
   case ${days} in
   s)   day1="${OPTARG}";;
   e)   day2="${OPTARG}";;
   ?)  printf "Usage: %s: -s <days> [-e <days>] <path>\n" $0
       exit 2;;
   esac
done


if [ ! -z "${day1}" ]
then   
   RC=$(echo ${day1}|grep -c "[a-zA-Z]")
   if [ ${RC} -eq 1 ]
   then
      echo "Days can be number only.....\n"
      exit 2
   else
      sflag=1;
   fi
fi
 
if [ ! -z "${day2}" ]; then
   RC=$(echo $day2|grep -c "[a-zA-Z]")
   if [ ${RC} -eq 1 ]
   then
      echo "Days can be number only.....\n"
      exit 2
   else
      eflag=1;
   fi
fi
 
shift $(($OPTIND -1))
 
path=$1

if [ ${sflag} -eq 1 ] && [ ${eflag} -eq 1 ]
then
   find ${path} -mtime +${day1} > ${LOG1}
   find ${path} -mtime +${day2} > ${LOG2}
   comm -23 ${LOG1} ${LOG2} > ${LOG}
   echo "Check the result in ${LOG} file\n"
elif [ ${sflag} -eq 1 ]
then
   find ${path} -mtime +${day1} > ${LOG1}
   echo "Check the result in ${LOG1} file\n"
fi











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


