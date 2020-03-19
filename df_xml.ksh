#!/bin/ksh
#parse df -k command output and generate a XML file
#submitted by : arjun.singh@hpsglobal.com
#usage:df_xml

df -k|awk '{
if ( NR == 1 )
{
   head=$0
   parent="Filesystems"
   heading="<?xml version=\"1.0\" encoding=\"ISO-8859-1\"\?>"
   split(head,node," ")
   print heading
   print "<"parent">"
}
else
{
   split($0,sub_node," ")
   print "<"node[1]">"
   print "  <name>"sub_node[1]"</name>"
   print "  <kbytes>"sub_node[2]"</kbytes>"
   print "  <used>"sub_node[3]"</used>"
   print "  <avail>"sub_node[4]"</avail>"
   print "  <capacity>"sub_node[5]"</capacity>"
   print "  <Mounted>"sub_node[6]"</Mounted>"
   print "</"node[1]">"
}
}
END{
  print "</"parent">"
}'




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


