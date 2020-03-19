#!/bin/ksh
# Function :trapping ftp error codes, based on the standard codes returned by 
#           ftp command
# Note:
# Script read ftp password from a file, to avoid hardcoding.
# For security reasons make sure this password input file is read only by the
# owner and also make sure your home directory is not readable by others. 
# Instead of this you can use also use .netrc file in your $HOME dir for ftp 
# settings and macro. Read more about .netrc file and it's use for FTP.
# Here in this script, modify FTP the commands as per your need
#
# Usage: qftp <host_name> <ftp_login> <ftp_mode{asc|bin}>
#
# Submitter:arjun.singh@hpsglobal.com
  
if [ $# -ne 3 ]
then
  echo "Usage: $0 <host_name> <ftp_login> <ftp_mode{asc|bin}>"
  exit 1
fi

ip_address=$1
ip_user=$2
ftp_mode=$3
logfile=/tmp/qftp.log

#ignore signals
trap "" 1 2 3 15

#read password from a file
ip_pass=`cat ftp_pass`
[ -z "${ip_pass}" ] && echo "Password required quiting..." && exit 1

echo "FTP Connection Settings ->"
echo "--------------------------"
echo "ftp host     : ${ip_address}"
echo "ftp user     : ${ip_user}"
echo "ftp password : !!!!!!!!"
echo "ftp mode     : ${ftp_mode}"
echo "ftp logfile  : ${logfile}"
echo "Start Time   : $(date)"
echo "--------------------------"

#run ftp command

ftp -n -v ${ip_address} <<-EOFtp >${logfile} 2>&1
user ${ip_user} ${ip_pass}
${ftp_mode}
prompt off
lcd
cd /tmp
quit
EOFtp

#trap ftp code

awk ' BEGIN{
#list of standard ftp error codes
ftperr[202]="Command not implemented" 
ftperr[421]="Service not available,closing control connection"
ftperr[426]="Connection closed, transfer aborted"
ftperr[450]="File unavailable(e.g. file busy)"
ftperr[451]="Requested action aborted, local error in processing"
ftperr[452]="Requested action not taken. Insufficient storage space in system"
ftperr[500]="Syntax error, command unrecognized"
ftperr[501]="Syntax error in parameters or arguments"
ftperr[502]="Command not implemented"
ftperr[503]="Bad sequence of commands"
ftperr[504]="Command not implemented for that parameter"
ftperr[530]="User not logged in. Check username and password"
ftperr[550]="Requested action not taken. File unavailable" 
ftperr[552]="Requested file action aborted, storage allocation exceeded"
ftperr[553]="Requested action not taken. Illegal file name"
ftperr[999]="Invalid Command"
ftperr[777]="Unknown host"
ftperr[666]="A file or directory not exist"
#ftperr[226]="Transfer Complete"
ecode="000"
FOUND="F"
}
{
#check for error code
   for ( i in ftperr)
   {
      if ( i == $1 )
      {
         ecode=$1
         FOUND="T"
      }
      else if ( $0 ~ /Invalid/ )
      {
         ecode="999"
         FOUND="T"
      }
      else if ( $0 ~ /Unknown host/ || $0 ~ /Not connected/ )
      {
         ecode="777"
         FOUND="T"
      }
      else if ( $0 ~ /not exist/ || $0 ~ /No such/ )
      {
         ecode="666"
         FOUND="T"
      }

    if ( FOUND == "T" )
      {
         exit;
      }
   } 
}END {
if ( ecode == "000" )
   print ecode ":FTP Successfully done"
else
   print ecode ":"ftperr[ecode]
}' ${logfile}


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


