# A simple, silly little script for those times when you
# don't remember what AA02 is in decimal and you really need
# to know. ;)
# 2003 - Ed Mitchell

#!/usr/local/bin/perl
print "Enter MAC Address with colons or hex value: ";
chop($MAC=);
@fields=split(/:/, $MAC);
$j=0;
foreach $field (@fields) {
        $j=hex $field;
        push(@ascii, $j);
        }

foreach $dec (@ascii) {
        print $dec,"\n";
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


