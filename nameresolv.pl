#!/usr/bin/perl -w
#===============================================================================
#    FILE:  nameresolve.pl
#   USAGE:  ./nameresolve.pl <FileName1> <FileName2> ...
# CREATED:  Thu Oct 28 2004 14:15:48 EDT
#  AUTHOR:  KarthiK Kirubakaran 	Email: Karthik.Kirubakaran@gmail.com
# COMMENT:  Argument "<FileName1,2.." contains raw IP's in each line. 
#===============================================================================

use strict;

foreach (@ARGV){
	open (F,$_);
	my @IPs = <F>;
	foreach my $ip (@IPs){
		chomp($ip);
		die "\n\nNot a valid IP, exiting...\n\n" unless $ip=~/\d+\.\d+\.\d+\.\d+/;
		my $name = gethostbyaddr(pack('C4', split('\.',$ip)),2);
		print "$name\n";
	}
}






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


