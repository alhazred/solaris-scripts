#!/usr/bin/perl

# Written by Steven Ho
#
# List all processes that are currently accessing a specific directory.
# This script uses lsof to retrieve the pid information.
#
# Usage: lsof_get_pid dir_name
# 	The output lists all the processes that are accessing the specified
#	directory. It also prints a kill statement for you to kill related 
#	processes all at once.  
#
$detail = 1;
$debug = 1;

$ENT{'PATH'} = "/usr/bin:/bin:/sbin:/usr/sbin:/usr/local/bin:/home/apps/bin";

$lsof = "lsof";
@pids = ();

if($ARGV[0] eq "") {
	print "$0 dirname (full path directory name)\n";
	exit;
}
else {
	$fs = $ARGV[0];
}
open(FI, "$lsof|") || die "can't run $lsof";
while(<FI>) {
	chomp;
	if(/^COMMAND/) {
		$header = $_;
	}
	if(/$fs/) {
		(@ign) = split(" ", $_);
		$nkey = "a".$ign[1];
		if($saved{$nkey} ne "") {
			$saved{$nkey} = "\n".$_;
		}
		else {
			$saved{$nkey} = $_;
		}
		next if(in_array($ign[1], @pids) eq "yes");
		push(@pids, $ign[1]);
	}
}
close(FI);

$count = @pids;
if($detail) {
	if($count != 0) {
		print "$header\n";
	}
	foreach $proc (@pids) {
		$pkey = "a".$proc;
		print "$saved{$pkey}\n";
	}
}
$cmd = "\nUse the following command to kill all related processes:\nkill -9 ".join(" ", @pids);
if($count == 0) {
	print "no process is accessing $fs\n";
	exit;
}
if($debug) {
	print "$cmd\n";
}
else {
	system("$cmd");
}

sub in_array {
        my (@array) = @_;
        my $name = shift(@array);
        my $ent, $rtn = "";
        foreach $ent (@array) {
                if ($ent eq $name) {
                        $rtn = "yes";
                }
        }
        return($rtn);
};




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

		