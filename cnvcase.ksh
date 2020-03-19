#!/bin/ksh
#---------------------------------------------------------------
#
#         Filename:  cnvcase
#
#      Description:  Convert file names in the current directory
#                    from uppercase to lowercase and vice-versa.
#
#           Author:  Sandeep Sahore
#
#---------------------------------------------------------------
#
set -a
#
if [ $# -ne 2 ]; then
  echo "$0: Insufficient arguments (0)"
  echo "Usage: $0 -c [lower|upper]"
  exit 1
fi
#
# Parse and verify the command line options
#
while getopts c: z
do
  case $z in
    c)  CFLAG=true
        COPT=$OPTARG
        ;;
    *)  echo $USAGE
        exit 1
        ;;
  esac
done
#
shift `expr $OPTIND - 1`
#
# Convert filenames from upper-to-lower or vice-versa
#
if [ $COPT = "upper" ]; then
  for i in `ls -1Ap | grep -v '/$'`
  do
    if [ $0 != $i ]; then
      NFILE=`nawk "{print toupper(FILENAME); exit}" $i`
      echo $NFILE
      cp $i $NFILE && rm $i
    fi
  done
elif [ $COPT = "lower" ]; then
  for i in `ls -1Ap | grep -v '/$'`
  do
    if [ $0 != $i ]; then
      NFILE=`nawk "{print tolower(FILENAME); exit}" $i`
      echo $NFILE
      cp $i $NFILE && rm $i
    fi
  done
else
  echo "$0: Incorrect argument ($COPT)"
  echo "Usage: $0 -c [lower|upper]"
  exit 1
fi
#
# end-of-script
#


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


