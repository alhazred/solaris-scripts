#!/usr/local/bin/perl 

# 
# arp-ad.pl cleans up all entries in arp table 
#          similar to "arp -ad" in freeBSD 
# 
# Feb 14, 2000          Wai Chan        Created. 
#
# Submitter Name: Wai Chan 
# Submitter Email: waichan@hpu.edu 
# Submitter Company: Hawaii Pacific University

@arpTable=`arp -a`; 
$count=0; 
foreach $list (@arpTable) 
{ 
	if ($count++ > 2) 
	{ 
		($trash, $hostname, $trash)=split(' ',$list,3); 
		print(`arp -d $hostname`); 
	} 
} 
print($count-3); 







##############################################################################
### This script is submitted to BigAdmin by a user of the BigAdmin community.
### Sun Microsystems, Inc. is not responsible for the
### contents or the code enclosed. 
###
###
### Copyright 2008 Sun Microsystems, Inc. ALL RIGHTS RESERVED
### Use of this software is authorized pursuant to the
### terms of the license found at
### http://www.sun.com/bigadmin/common/berkeley_license.html
##############################################################################


