#!/bin/sh
#
#             title: Displays the amount of disk space
#          subtitle: Disk space mounted in MB or GB
#     creation date: 11 november 2002
# modification date: 26 janvier 2006
#           version: 1.0
#            author: Fabbri Pascal @ ?pfL
#                    Swiss Federal Institute of Technology Lausanne
#             email: pascal.fabbri@epfl.ch
#         file name: $HOME/scripts/dfh
#       description: Display the amount of disk space occupied by file systems
#                    in MB or in GB.
#

ECHO="/bin/echo"

if [ $# -gt 0 ] || [ $# -lt 2 ]
then
  case $1 in
    -g)
      sizeIn='GB'
      ;;
    -m)
      sizeIn='MB'
      ;;
    -h)
      ${ECHO} Usage: `basename $0` \[-m\|-g\]
      ${ECHO} "\t -m space in MegaByte (MB)"
      ${ECHO} "\t -g space in GigaByte (GB)"
      exit 1
      ;;
    *)
      sizeIn='MB'
      ;;
  esac
else
  ${ECHO} "Too many options !"
  exit 1
fi

DF="/bin/df"
AWK="/usr/bin/awk"

if [ -r '/usr/bin/uname' ]
then
  OSName=`/usr/bin/uname -s`
elif [ -r '/bin/uname' ]
then
  OSName=`/bin/uname -s`
else
  ${ECHO} "uname command not found !"
  exit 1
fi

AWK_FILE_GB='
    BEGIN {
      size=0
      used=0
      avail=0
      getline;
      printf "%-21s %6s %6s %6s %4s\n", \
             "","(gb)","(gb)","(gb)","(%)"
      printf "%-21s %6s %6s %6s %4s %s\n", \
             "Filesystem","size","used","avail","used","Mounted on"
    }
    {
      printf "%-21s %6.2f %6.2f %6.2f %4s %s\n", \
             $1,$2/1024/1024,$3/1024/1024,$4/1024/1024,$5,$6
      size+=$2
      used+=$3
      avail+=$4
    }
    END {
      printf "%-21s %6s %6s %6s\n", \
             "","------","------","------"
      printf "%-21s %6.2f %6.2f %6.2f\n", \
             "",size/1024/1024,used/1024/1024,avail/1024/1024
    }'

AWK_FILE_MB='
    BEGIN {
      size=0
      used=0
      avail=0
      getline;
      printf "%-21s %6s %6s %6s %4s\n", \
             "","(mb)","(mb)","(mb)","(%)"
      printf "%-21s %6s %6s %6s %4s %s\n", \
             "Filesystem","size","used","avail","used","Mounted on"
    }
    {
      printf "%-21s %6d %6d %6d %4s %s\n", \
             $1,$2/1024,$3/1024,$4/1024,$5,$6
      size+=$2
      used+=$3
      avail+=$4
    }
    END {
      printf "%-21s %6s %6s %6s\n", \
             "","------","------","------"
      printf "%-21s %6d %6d %6d\n", \
             "",size/1024,used/1024,avail/1024
    }'

case $sizeIn in
  GB)
    AWK_FILE=${AWK_FILE_GB}
    ;;
  MB)
    AWK_FILE=${AWK_FILE_MB}
    ;;
  *)
    ${ECHO} "Do nothing !"
    ;;
esac

case ${OSName} in
  SunOS)
    (${DF} -kF ufs; ${DF} -kF zfs | ${AWK} 'BEGIN{getline} {print}') | ${AWK} "${AWK_FILE}"
    ;;
  FreeBSD)
    ${DF} -kt ufs | ${AWK} "${AWK_FILE}"
    ;;
  Darwin)
    ${DF} -kt hfs,ufs,msdos | ${AWK} "${AWK_FILE}"
    ;;
  Linux)
    ${DF} -k | ${AWK} "${AWK_FILE}"
    ;;
  *)
  $ECHO Error: Unknown Operating System!
esac







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


