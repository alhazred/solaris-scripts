#!/usr/bin/perl -w
#
# Usage : just run it! calc the total swap space in human readable form
# Author : Paul Errington (ICT Technical)
#

my @result = `/usr/sbin/swap -l`;

shift @result;

my ($tblocks, $fblocks);

foreach my $swapfile (@result) {
        my @part = split(/\s+/, $swapfile);
        if(@part == 5) {
                $tblocks += $part[3];
                $fblocks += $part[4];
        }
}
$tblocks *= 512;
$fblocks *= 512;

my $padding="            ";
print substr("total(gb)".$padding, 0, 12),
        substr("free(gb)".$padding, 0, 12),
        substr("%available".$padding, 0, 12)."\n";

print substr(sprintf("%.2f", $tblocks/1024/1024/1024).$padding, 0, 12),
        substr(sprintf("%.2f", $fblocks/1024/1024/1024).$padding, 0, 12),
        substr(sprintf("%.0f", $fblocks/$tblocks*100).$padding, 0, 12)."\n";




##############################################################################
### This script is submitted to BigAdmin by a user of the BigAdmin community.
### Sun Microsystems, Inc. is not responsible for the
### contents or the code enclosed.
###
###
###  Copyright Sun Microsystems, Inc. ALL RIGHTS RESERVED
### Use of this software is authorized pursuant to the
### terms of the license found at
### http://www.sun.com/bigadmin/common/berkeley_license.jsp
##############################################################################