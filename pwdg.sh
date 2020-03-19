#!/usr/bin/ksh
#filename: pwdg.sh
#Submitter:arjun.singh@pstsi.com
#Functionality:
#script will parse information stored in /etc/passwd and /etc/group file 
#and then generate a combined XML format output.Redirect the output and 
#see in XML browser.
#Usage:$0 > /tmp/userinfo.xml

LOGFILE=/tmp/pwdg.log
 
#read passwd and group file then generate the combined one line
#output for each user.

rm -f ${LOGFILE}
HEADER="user:password:uid:gid:comment:home:shell:groups"
echo ${HEADER} >${LOGFILE}

while read line
do
   user=$(echo ${line}|cut -d: -f1)
   tmp=""
   for gp in $(grep ${user} /etc/group|cut -d: -f1)
   do
      tmp=${tmp}","${gp}
   done
   echo ${line}:${tmp#","} >>${LOGFILE}
done < /etc/passwd

#now read the logfile and generate the XML format output
cat ${LOGFILE}|awk '{
if ( NR == 1 )
{
   head=$0
   parent="Users"
   heading="<?xml version=\"1.0\" encoding=\"ISO-8859-1\"\?>"
   split(head,node,":")
   print heading
   print "<"parent">"
}
else
{
   split($0,sub_node,":")
   print "<"node[1]">"
   print "<Name>"sub_node[1]"</Name>"
   print "<Password>"sub_node[2]"</Password>"
   print "<UID>"sub_node[3]"</UID>"
   print "<GID>"sub_node[4]"</GID>"
   print "<Comment>"sub_node[5]"</Comment>"
   print "<Home>"sub_node[6]"</Home>"
   print "<Shell>"sub_node[7]"</Shell>"
   print "<Groups>"sub_node[8]"</Groups>"
   print "</"node[1]">"
}
}
END{
  print "</"parent">"
}'
exit 0

###
### This script is submitted to BigAdmin by a user
### of the BigAdmin community. 
### Sun Microsystems, Inc. is not responsible for the
### contents or the code enclosed. 
###




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


