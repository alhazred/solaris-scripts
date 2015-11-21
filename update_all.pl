#!/usr/bin/perl

# Written by Steven Ho
# See the help message below for explanation.
#
$debug = 0;
$ENV{'PATH'} = "/bin:/usr/bin:/usr/local/bin:/usr/sbin:/usr/etc:/etc:/usr/ucb:/usr/lib:/usr/bsd:/sbin:.";

use Getopt::Long;
$args = join(" ", @ARGV);
$ret = GetOptions( "f=s", "c=s", "h", "help" );
help() unless $ret;
help() unless $args;
help() if $opt_h;
help("Error: -f is mandatory") unless $opt_f;
help("Error: -c is mandatory") unless $opt_c;

sub help {
	my($message) = @_;
	die <<EOH;
$message
$0: Run a command on a list of hosts in parallel,
	and save the output in a result file 
	(for example, update_all -f /etc/hosts -c hostname)

$0 options:

	-f <filename>	: list of hostnames (one name in each line)
			  list of hostnames in /etc/hosts format or in the 
			  format of hostname followed by colon or white spaces
	-c <command>	: command to run, if there is space in the command
			  then use double quote to quote it
	-help		: this message
EOH
}

sub get_name {
	my($rec) = @_;
	my $rtn = "", $name, $ip, @ign;
	($ip, $name, @ign) = split(" ", $rec);
	# just a regular name
	if($rec =~ /^(\S+)$/) {
		$rtn = $rec;
	}
	# /etc/hosts format
	if($ip =~ /^(\d+)\.(\d+)\.(\d+)\.(\d+)$/) {
		if($name =~ /^(\S+)$/) {
			$rtn = $name;
		}
		if($rtn eq "") {
			# "hostname:..." or "hostname ..." format
			if($rec =~ /(\S+)([: ])(.*)/) {
				$rtn = $1;
			}
			else {
				$rtn = "unknown_host";
			}
		}
	}
	return($rtn);
}

if($opt_c) {
	$todo = $opt_c;
}
$RM="rm";
$tmpdir="/tmp/update";
$tmpdir1=$tmpdir."1";
$result="result";

sub rexec_cmd {
	local($lhname, $ltodo) = @_;
	if($debug) { print "in rexec_cmd: $lhname $ltodo\n"; }
	$_ = `ping $lhname 2`;
	if (/is alive/) {
		if($debug) { printf "$lhname\n"; }
		unless (fork) {

		    unless (fork) {
			#sleep 1 until getppid == 1;
			open(PING, ">$tmpdir/pingable.$lhname") || die "can't open $tmpdir/pingable.$lhname";
			printf "$lhname\n";
			my $command = "rsh $lhname $ltodo";
			
			@ign = `rsh $lhname $ltodo 2>&1`;
			$result = join(" ", @ign);
			if (!$result) {
				printf PING "$lhname: no_output\n";
			}
			if ($debug) { print $result; }
			printf PING "$result";
			close(PING);
			exit(0);
		    }
		    exit(0);
		}
		wait;
		if ($debug) { print "parent sleeping...\n"; }
	}
}

system("touch $tmpdir");
system("mv $tmpdir $tmpdir1");
system("rm -r $tmpdir1&");
system("mkdir $tmpdir");

if($opt_f) { 
	open(FI, "cat $opt_f|") || die "can't read $opt_f\n";
	while(<FI>) {
		chomp;
		next if(/^#/);
		next if(/localhost/);
		$fhost = get_name($_);
		push(@list, $fhost);
		$result_ary{$fhost} = "$fhost: not_pingable";
		rexec_cmd($fhost, $todo);
	}
	close(FI);
	$list_total = @list;
	if ($debug) { print "---End of $opt_f---\n"; }
}

sleep 3;
$waiting = 0;
$slept = 0;
while($waiting == 0) {
	opendir(TDIR, "$tmpdir") || die "can't open $tmpdir";
	@all = readdir(TDIR);
	closedir(TDIR);
	$all_total = @all;
	# exclude . and ..
	$all_total--;
	$all_total--;
	if($debug) {
		print "slept: $slept, will sleep for 1 second\n";
	}
	if($debug) {
		print "list_total: $list_total; all_total: $all_total\n";
	}
	if(($all_total == $list_total) || ($slept > 4)) {
		$waiting = 1;
	}
	elsif ($all_total == ($list_total + $slept)) {
		$waiting = 1;
	}
	# wait until we get more rsh results
	sleep 1;
	$slept++;
}


foreach (@all) {
	if (/^pingable./) {
		($ping, $name) = split(/\./, $_);
		push(@newlist, $name);
		#print $_, "\n";
		$tmp_file = $tmpdir."/".$_;
		my ($dev, $ino, $mode, $nlink, $uid, $gid, $rdev, $size, $atime, $mtime, $ctime, $blksize, $blocks) = stat($tmp_file);
		if($size == 0) {
			$result_ary{$name} = "$name: pingable_no_result";
			next;
		}
		open(FPI, "$tmp_file") || die "can't open $_";
		while(<FPI>) {
			chomp;
			$_ = $name.": ".$_;
			if (/no_output/) {
				$result_ary{$name} = "$name: no_output";
					next;
			}
			else {
				$result_ary{$name} = $_;
			}
		}
	}
}
open(RESULT, ">$tmpdir/$result") || die "can't open $tmpdir/$result";
foreach $ent (@list) {
	print RESULT "$result_ary{$ent}\n";
	#print RESULT "$ent: $result_ary{$ent}\n";
}
close(RESULT);
$cmd = "chmod -R 777 $tmpdir";
system("$cmd");
print "\n**********************************************\n";
print "The output file is called $tmpdir/$result\n";
print "**********************************************\n";


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


