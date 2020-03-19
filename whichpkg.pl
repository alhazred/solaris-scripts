#!/usr/bin/perl

# Assuming you have access to the jumpstart directory, 
# the script searches the pkgmap files for a (command) 
# string and list all the packages that contains the (command) string.
# See the help entry below.

# Manually set the $prod_root to the Product list in Jumpstart
$prod_root = "/disk1/jumpstart/Solaris_8/Product";

# Usage: whichpkg cmd
# Written by Steven Ho
use Getopt::Long;
$args = join(" ", @ARGV);
$ret = GetOptions( "all",
                   "help");

$args = shift(@ARGV);
help() unless $args;
help() unless $ret;
help() if $opt_help;
help("a name or string is required.") unless $args;

sub help {
  my($message) = @_;
  die <<EOH;
$message	
$0 Search the pkgmap files for a (command) string and list all the
	packages that contains the (command) string
	(*** Make sure you have the $prod_root path set 
	to your jumpstart Product directory)

$0 options: 
	-all		: use grep to do search
	-help		: print this help
	search_string	: command such as ls, libc.so.1

For example, $0 ls
		$0 pwd
		$0 libc.so.1
		$0 -all pwd
EOH
}

$search = "/".$args;


chdir("$prod_root");
opendir(DIR, "$prod_root") || die "can't read $prod_root";
@list = readdir(DIR);
closedir(DIR);
foreach $ent (@list) {
	next if $ent eq '.';
	next if $ent eq '..';
	next if $ent eq 'locale';
        next if $ent eq '.clustertoc';
        next if $ent eq '.order';
        next if $ent eq '.packagetoc';
        next if $ent eq '.pkghistory';
        next if $ent eq '.platform';
        next if $ent eq '.virtual_packagetoc_2';
        next if $ent eq '.virtual_packagetoc_3';
        next if $ent eq '.virtual_packages';

	if($debug) {
		print "$ent\n";
	}
	$pkgmap = $ent."/"."pkgmap";

	if($opt_all eq "") {
		@mytmp = ();
		open(FI, "$pkgmap") || die "can't read $pkgmap";
		while(<FI>) {
			chomp;
			if (/$search/) {
				if($_ =~ /(.+)$search(\s+)(.*)/) {
					push(@mytmp, $_);
				}
			}
		}
		close(FI);
		$mytmp_cnt = @mytmp;
		if($mytmp_cnt != 0) {
			print "$ent:\n";
			foreach $tent (@mytmp) {
				print "\t$tent\n";
			}
		}
		next;
	}
	$cmd = "grep $search $pkgmap";
	$output = `$cmd`;
	if($output ne "") {
		print "$ent:\n";
	}
	print "$output";
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


