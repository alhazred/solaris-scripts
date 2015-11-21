#! /usr/bin/ksh
#
#
#
# 1.01 * myfind * 13.02.2003 * MP * File Find
VERS="1.01"
#
#
#
#
##################################################
# shell functions to be called from within Main: #
##################################################
#
setxy()
{
 tput cup $1 $2
}
#
#
AccDate()
{
 clear
 echo "Search File by Date of Last Access"
 echo
 echo "search files last accessed ${BOLD}__${UNBOLD} days ago \c"
 setxy 2 27
 read NoOfDays
 echo "start search in: \c"
 read StartDir
 find $StartDir -atime $NoOfDays -print | pg
 echo
 echo "[RETURN] to continue"
 read dummy
 return
}
#
#
ChgDate()
{
 clear
 echo "Search File by Date of Last Modification"
 echo
 echo "search files modified less than ${BOLD}__${UNBOLD} days ago \c"
 setxy 2 32
 read NoOfDays
 echo "start search in: \c"
 read StartDir
 NoOfDays=`expr $NoOfDays + 1`
 find $StartDir -ctime -${NoOfDays} -print | pg
 echo
 echo "[RETURN] to continue"
 read dummy
 return
}
#
#
FileSize()
{
 clear
 echo "Search File by File Size"
 echo
 echo "search files larger than ${BOLD}_______________${UNBOLD} bytes \c"
 setxy 2 25
 read NoOfBytes
 echo "start search in: \c"
 read StartDir
 find $StartDir -size +${NoOfBytes}c -print | pg
 echo
 echo "[RETURN] to continue"
 read dummy
 return
}
#
#
FileOwner()
{
 clear
 echo "Search File by File Owner"
 echo
 echo "search files belonging to user: \c"
 read Owner
 echo "start search in: \c"
 read StartDir
 ZAEHLER=0
 for DATEI in `find $StartDir -depth -print`
  do
  EIGNER=`ls -ld $DATEI | awk '{print $3}'`
  if [ "$EIGNER" = "$Owner" ]
   then
   echo $DATEI
   ZAEHLER=`expr $ZAEHLER + 1`
   if [ $ZAEHLER -gt 16 ]
    then
    ZAEHLER=0
    echo ":"
    read dummy
   fi
  fi
 done
 echo
 echo "[RETURN] to continue"
 read dummy
 return
}
#
#
FileGroup()
{
 clear
 echo "Search File by File Group"
 echo
 echo "search files belonging to group: \c"
 read Group
 echo "start search in: \c"
 read StartDir
 find $StartDir -group $Group -print | pg
 echo
 echo "[RETURN] to continue"
 read dummy
 return
}
#
#
ExactName()
{
 clear
 echo "Search File by exact File Name"
 echo
 echo "search for file: \c"
 read FileName
 echo "start search in: \c"
 read StartDir
 find $StartDir -name $FileName -print | pg
 echo
 echo "[RETURN] to continue"
 read dummy
 return
}
#
#
SimName()
{
 clear
 echo "Search File by File Name"
 echo
 echo "search file with name matching pattern: \c"
 read FileName
 echo "start search in: \c"
 read StartDir
 find $StartDir -name \*${FileName}\* -print | pg
 echo
 echo "[RETURN] to continue"
 read dummy
 return
}
#
###################
# MAIN main Main: #
###################
#
# Variables:
#
BOLD=`tput smso`
UNBOLD=`tput rmso`
#
#
#
while [ 1 ]
 do
 clear
 echo "File Find - ${VERS} - search for files by different criteria"
 echo
 echo
 echo " search by ..."
 echo
 echo " 1. access date"
 echo " 2. change date"
 echo " 3. file size"
 echo " 4. file owner"
 echo " 5. file owner group"
 echo " 6. file name - exact"
 echo " 7. file name - similar"
 echo
 echo " Q/q - quit"
 echo
 echo "SELECTION: \c"
 read ANTWORT
 if [ "x${ANTWORT}" = "x" ]
  then
  echo "invalid selection. [RETURN] to continue."
  read dummy
  continue
 elif [ "${ANTWORT}" = "q" -o "${ANTWORT}" = "Q" ]
  then
  exit
 fi
 case $ANTWORT in
  "1")  AccDate 
        ;;
  "2")  ChgDate
        ;;
  "3")  FileSize
        ;;
  "4")  FileOwner
        ;;
  "5")  FileGroup
        ;;
  "6")  ExactName
        ;;
  "7")  SimName
        ;;
  *)    echo "invalid selection. [RETURN] to continue."
        read dummy
        ;;
 esac
done
#


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


