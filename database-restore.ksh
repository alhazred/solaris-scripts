#! /usr/bin/ksh
#
#
# 1.01 * database-restore.ksh * 16.01.2003 * MP * restore db from sql files
#                                                 created by database-dump.ksh
#
#
#
############################################################################
# SYNTAX: database-restore.ksh                                             #
#                                                                          #
# This script restores MySQL databases from *.sql files that have been     #
# generated with database-dump.ksh previously.                             #
#                                                                          #
# This script expects it's source files in $DUMPDIR. It will process all   #
# files with the *.sql file name extension in $DUMPDIR.                    #
#                                                                          #
# You can modify all environment variables within this script to meet      #
# your system's needs.                                                     #
#                                                                          #
# Please be aware that the MySQL root password must be specified in plain  #
# text within this file (DB_PW)!                                           #
#                                                                          #
# The script is not designed to run in unattended mode, e.g. via crontab   #
#                                                                          #
############################################################################
#
#
#
DUMPDIR=/opt/mysql/dumpdir
MYSQLBIN=/usr/local/mysql/bin
DB_PW=mysql
#
#
#
cd $DUMPDIR
WOBINICH=`pwd`
if [ "$DUMPDIR" != "$WOBINICH" ]
 then
 echo "could not cd to ${DUMPDIR}. Exiting"
 exit
fi
#
for DATEI in `ls -1 *.sql`
 do
 DB=`echo $DATEI | cut -f1 -d:`
 echo "restoring database ${DB}...\c"
 ${MYSQLBIN}/mysql --user=root --password=$DB_PW \
  --execute="create database ${DB}"
 ${MYSQLBIN}/mysql --user=root --password=mysql $DB < ${DUMPDIR}/${DATEI}
 if [ $? -eq 0 ]
  then
  echo " restore of $DB successful"
 else
  echo " ERROR: restore of $DB not successful"
 fi
done
#
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


