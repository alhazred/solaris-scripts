#! /usr/bin/ksh
#
#
# 1.01 * database-dump.ksh * 16.01.2003 * MP * dump complete mysql database
# 1.02 * database-dump.ksh * 17.01.2003 * MP * reorganize with -del option
#
###############################################################################
# SYNTAX: database-dump.ksh [-del]                                            #
#         -del: delete dumpfiles of previous month in $DUMPDIR                #
#                                                                             #
# This script creates dumps of all databases existing in a MySQL system.      #
#                                                                             #
# The script performs the following steps:                                    #
#                                                                             #
# 1. detect names of all databases configured                                 #
# 2. dump each database to an sql style file: <database_name>:<timestamp>.sql #
#    The dump files are created in $DUMPDIR.                                  #
# 3. if the "-del" command line option was specified $DUMPDIR will be         #
#    reorganized on each 27th day of the month i.e. all                       #
#    files of the previous month will be deleted                              #
#                                                                             #
# You can modify all environment variables as appropriate.                    #
#                                                                             #
# The script creates some temporary files which it will remove after it's     #
# work is done.                                                               #
#                                                                             #
# All actions of this script are logged in $MYLOG                             #
#                                                                             #
# Please be aware, that the MySQL root password appears in plain text         #
# within this script (DB_PW)!                                                 #
#                                                                             #
# OS specifics:                                                               #
# -------------                                                               #
#                                                                             #
# Tru64: --fields-terminated-by option to mysqldump would not work, so it     #
#        has been skipped if OS_TYPE=OSF1                                     #
#                                                                             #
###############################################################################
#
###############################################################################
#                                                                             #
# Description of env variables used by this script:                           #
#                                                                             #
# DUMPDIR: This is the directory where database-dump.ksh creates it's dumps.  #
#          This is the location of the files <database_name>:<timestamp>.sql  #
#                                                                             #
# DBNAMES: The name of a temporary file created by this script. It lists the  #
#          names of all databases as retrieved from the MySQL system.         #
#                                                                             #
# DBNAMES_NEW: Same as above, but pure names without field separators a.s.o.  #
#                                                                             #
# SEDFILE: A temporary file containing "sed" commands.                        #
#                                                                             #
# MYSQLBIN: The directory of the MySQL binaries.                              #
#                                                                             #
# MYLOG:   Location of this script's own logfile                              #
#                                                                             #
# DB_PW:   MySQL root password for the system in use (plain text!)            #
#                                                                             #
###############################################################################
#
# PLEASE MODIFY AS NEEDED:
#
DUMPDIR=/opt/mysql/dumpdir
DBNAMES=${DUMPDIR}/dblist.$$
DBNAMES_NEW=${DUMPDIR}/dblist_new.$$
SEDFILE=${DUMPDIR}/sedinput.$$
MYSQLBIN=/usr/local/mysql/bin
MYLOG=/var/adm/database-dump.ksh.log
DB_PW=mysql
OS_TYPE=`uname`
#
#
if [ "x$1" = "x-del" ]
 then
 DEL=Y
else
 DEL=N
fi
#
#
###################
# MAIN main Main: #
###################
#
###########################################
# write start entry to my logfile $MYLOG: #
###########################################
#
echo "$0 starting: \c" > $MYLOG
date >> $MYLOG
#
#########################################
# create $DUMPDIR if it does not exist: #
#########################################
#
if [ ! -d $DUMPDIR ]
 then 
 echo "creating $DUMPDIR" >> $MYLOG
 mkdir -p $DUMPDIR
 if [ $? -ne 0 ]
  then
  echo "could not create ${DUMPDIR}. Exiting." >> $MYLOG
  exit
 else
  echo "$DUMPDIR created." >> $MYLOG
 fi
fi
#
##############################################################
# find all database names within this system (strip output): #
##############################################################
#
${MYSQLBIN}/mysqlshow --user=root --password=${DB_PW} \
 | grep -v "+" | grep -v "Databases" | tr ["|"] [" "] \
 > ${DBNAMES}
#
############################################################
# removing spaces from file containing all database names: #
############################################################
#
echo "1,\$s/ //g" > $SEDFILE
sed -f $SEDFILE $DBNAMES > ${DBNAMES_NEW}
#
#
#############################################
# dump all databases found in $DBNAMES_NEW: #
#############################################
#
for DB in `cat ${DBNAMES_NEW}`
 do
 TIME=`date +%y%m%d01/19/06M`
 if [ "$OS_TYPE" = "OSF1" ]
  then
  ${MYSQLBIN}/mysqldump --user=root --password=${DB_PW} --opt \
  $DB > ${DUMPDIR}/${DB}:${TIME}.sql 2> /dev/null
 else
  ${MYSQLBIN}/mysqldump --user=root --password=${DB_PW} --opt \
  --fields-terminated-by=: $DB > ${DUMPDIR}/${DB}:${TIME}.sql 2> /dev/null
 fi
 echo "file ${DB}:${TIME}.sql created in ${DUMPDIR}" >> $MYLOG
done
#
#
#
sleep 3
echo "removing temp files:" >> $MYLOG
echo $DBNAMES >> $MYLOG
echo ${DBNAMES_NEW} >> $MYLOG
echo $SEDFILE >> $MYLOG
rm $DBNAMES $SEDFILE ${DBNAMES_NEW} 2>> $MYLOG
#
#
###########################################################
# exit without reo of $DUMPDIR if -del was not specified: #
###########################################################
#
if [ "$DEL" != "Y" ]
 then
 echo "Exiting without reo" >> $MYLOG
 exit
fi
#
#
########################
# reorganize $DUMPDIR: #
########################
#
#
TAG=`date +%d`
if [ $TAG -eq 27 ]
 then
 MONAT=`date +%m`
 JAHR=`date +%y`
 if [ $MONAT -eq 1 ]
  then
  DELMON=12
  DELJAHR=`expr $JAHR - 1`
 else
  DELMON=`expr $MONAT - 1`
  DELJAHR=$JAHR
 fi
 LAENGE=`echo "$DELMON\c" | wc -c`
 if [ $LAENGE -lt 2 ]
  then
  DELMON="0${DELMON}"
 fi
 LAENGE=`echo "$DELJAHR\c" | wc -c`
 if [ $LAENGE -lt 2 ]
  then
  DELJAHR="0${DELJAHR}"
 fi
 cd $DUMPDIR
 WOBINICH=`pwd`
 if [ "$DUMPDIR" != "$WOBINICH" ]
  then
  exit
 else
  echo "reorganizing $DUMPDIR: " >> $MYLOG
  echo "removing files created in year: ${DELJAHR} month: ${DELMON}" >> $MYLOG
  for DATEI in `ls -1 *:${DELJAHR}${DELMON}*.sql 2> /dev/null`
   do
   echo "removing $DATEI" >> $MYLOG
   rm $DATEI
  done
 fi
fi
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


