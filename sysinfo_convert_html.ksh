#!/bin/ksh

###
### Requires 'get_sysinfo' script to output
### files for formatting. 
###
### Script outputs HTML from colon delimited file.
### 
### Adjust the variables as needed for your environment
###

TMPFILE=/tmp/html-format.$$
SYS_INFILE=/sccm/cfig/sysinfo/sysinfo.db

#
# grab each individual config file and combine into one
#
cat /sccm/cfig/sysinfo/sysinfo/* > $SYS_INFILE

#
# do header
#
cat << EOF > $TMPFILE
<HTML>
<BODY>
<FONT SIZE=5>

<TABLE border=10>
<caption align=left><H2>Server Configs for Strong - Last Modified on: $(date) </H2></caption>


<tr>
    <th>Item</th>
    <th>Hostname</th>
    <th>Usage</th>
    <th>Location</th>
    <th>Busines Unit</th>
    <th>Server Purpose</th>
    <th>Hostid</th>
    <th>Serial Num</th>
    <th>Arch</th>
    <th>Platform</th>
    <th>OS Version</th>
    <th>Hardware Release</th>
    <th>Kernel Patch</th>
    <th>OBP</th>
    <th>CPU</th>
    <th>Speed</th>
    <th>Memory</th>
    <th>Boards</th>
    <th>SSA</th>
    <th>A5000</th>
    <th>A5000 ARRAY NAMES</th>
    <th>D130</th>
    <th>Total Disk</th>
    <th>SMALL</th>
    <th>2GB</th>
    <th>4GB</th>
    <th>8GB</th>
    <th>18GB</th>
    <th>36GB</th>
    <th>73GB</th>
    <th>130GB</th>
    <th>LARGE</th>
    <th>EMC</th>
    <th>BCVs</th>
    <th>SOC</th>
    <th>SCSI</th>
    <th>100Mb</th>
    <th>GB NIC</th>
    <th>GBIC</th>
    <th>HBA</th>
    <th>HBA Type</th>
    <th>HBA Driver</th>
    <th>HBA Firmware</th>
    <th>HBA Fcode</th>
    <th>FDDI</th>
    <th>HSI</th>
    <th>VID</th>
    <th>NET</th>
    <th>VXVM</th>
    <th>VXFS</th>
    <th>VCS</th>
    <th>PowerPath</th>
    <th>ECC</th>
    <th>ESN Manager</th>
    <th>Volume Logix</th>
    <th>Fibre Zone</th>
    <th>Netbackup</th>
    <th>Patrol</th>
    <th>Autosys</th>
    <th>Forte</th>
    <th>Netscape</th>
    <th>Weblogic</th>
    <th>Broadvision</th>
    <th>SQL Backtrack</th>
    <th>PERL</th>
    <th>TripWire</th>
    <th>Previous Hostnames</th>
    <th>Page unix if host down</th>
</tr>
EOF

#
# add html to each line for table formatting
#
CNT=1
while read -r line
do
	# translate colons to tables
	line=$(print "$line" | sed 's@:@</td><td>@g')

	# add table format for beginning and end of each line
	line=$(print "<td>${CNT}</td><td>${line}</td>")


	print "<tr>"  >> $TMPFILE
	print "$line" >> $TMPFILE
	print "</tr>" >> $TMPFILE

	if (( $CNT % 3 == 0 ))
	then
		print "<tr> </tr>" >> $TMPFILE
		print "<tr> </tr>" >> $TMPFILE
	fi
	
	if (( $CNT % 9 == 0 ))
	then
	cat <<- EOF >> $TMPFILE
		<tr>
    	<th>Item</th>
    	<th>Hostname</th>
    	<th>Usage</th>
    	<th>Location</th>
    	<th>Busines Unit</th>
    	<th>Server Purpose</th>
    	<th>Hostid</th>
    	<th>Serial Num</th>
    	<th>Arch</th>
    	<th>Platform</th>
    	<th>OS Version</th>
    	<th>Hardware Release</th>
    	<th>Kernel Patch</th>
    	<th>OBP</th>
    	<th>CPU</th>
    	<th>Speed</th>
    	<th>Memory</th>
    	<th>Boards</th>
    	<th>SSA</th>
    	<th>A5000</th>
    	<th>A5000 ARRAY NAMES</th>
    	<th>D130</th>
    	<th>Total Disk</th>
    	<th>SMALL</th>
    	<th>2GB</th>
    	<th>4GB</th>
    	<th>8GB</th>
    	<th>18GB</th>
    	<th>36GB</th>
    	<th>73GB</th>
    	<th>130GB</th>
    	<th>LARGE</th>
    	<th>EMC</th>
    	<th>BCVs</th>
    	<th>SOC</th>
    	<th>SCSI</th>
    	<th>100Mb</th>
    	<th>GB NIC</th>
    	<th>GBIC</th>
    	<th>HBA</th>
    	<th>HBA Type</th>
	    <th>HBA Driver</th>
	    <th>HBA Firmware</th>
    	<th>HBA Fcode</th>
    	<th>FDDI</th>
    	<th>HSI</th>
    	<th>VID</th>
    	<th>NET</th>
    	<th>VXVM</th>
    	<th>VXFS</th>
    	<th>VCS</th>
    	<th>PowerPath</th>
    	<th>ECC</th>
    	<th>ESN Manager</th>
    	<th>Volume Logix</th>
    	<th>Fibre Zone</th>
    	<th>Netbackup</th>
    	<th>Patrol</th>
    	<th>Autosys</th>
    	<th>Forte</th>
    	<th>Netscape</th>
    	<th>Weblogic</th>
    	<th>Broadvision</th>
    	<th>SQL Backtrack</th>
    	<th>PERL</th>
    	<th>TripWire</th>
	    <th>Previous Hostnames</th>
    	<th>Page unix if host down</th>
		</tr>
		EOF
	fi
	
	let CNT=$CNT+1

done < $SYS_INFILE


#
# do footer
#
cat << EOF >> $TMPFILE
</TABLE>
EOF

cat << EOF >> $TMPFILE
</BODY>
</HTML>
EOF

mv $TMPFILE /docs/cfig/html/strong-sysinfo.html


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


