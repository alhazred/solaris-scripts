#!/bin/ksh

###
### Script to build a list of printers in HTML
###
### NOTE: Use 'get_printers' script for output
###       file to be formatted.
###
### Submitted by: Matthew Baker
###               Matthew.Baker@med.ge.com
###

INDIR=/sccm/cfig/sysinfo/printers
OUTFILE=/docs/cfig/html/strong-printers.html
QUEUETMP=/tmp/queuetmp.$$

#
# do header
#
cat << EOF > $OUTFILE
<HTML>
<BODY>
<FONT SIZE=3>

<TABLE border=10>
<caption align=left><H2>Unix Printer Queues at Strong</H2></caption>
<caption align=bottom><H4>Last Modified on: $(date) </H4></caption>

EOF

###############################################################
# Here are the messy guts.  We are building a matrix by hand
# from the text files.  Filenames are the hostname, they
# contain the printer queue on that hostname.
#

#
# Get all the queues and hosts
#
QUEUES=$(cat $INDIR/* | sort -u)
HOSTS=$(ls $INDIR)

#
# Build the table
#

#
# first queue header line
#
print "<tr>" >> $QUEUETMP
print "<th>Hostname</th>" >> $QUEUETMP

for QUEUE in $QUEUES
do
	print "<th>${QUEUE}</th>" >> $QUEUETMP
done

print "</tr>" >> $QUEUETMP
print "" >> $QUEUETMP

cat $QUEUETMP >> $OUTFILE

#
# second each hosts queue line
#
CNT=1

for HOST in $HOSTS
do
	if (( $CNT % 3 == 0 ))
	then
		print "<tr> </tr>" >> $OUTFILE
		print "<tr> </tr>" >> $OUTFILE
	fi

	if (( $CNT % 9 == 0 ))
	then
		cat $QUEUETMP >> $OUTFILE
	fi
	
	print "<tr>" >> $OUTFILE
	print "<td>${HOST}</td>" >> $OUTFILE

	for QUEUE in $QUEUES
	do
		QueueOnHost=$(grep -wc $QUEUE $INDIR/$HOST)
		print "<td>${QueueOnHost}</td>" >> $OUTFILE
	done

	print "</tr>" >> $OUTFILE

	let CNT=$CNT+1
done



###############################################################
#
# do footer
#
cat << EOF >> $OUTFILE
</TABLE>
</BODY>
</HTML>
EOF




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


