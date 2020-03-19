#!/usr/local/bin/perl
# Script to interface with whois_old
# To fix whois broken by NSI on 12/1/99
# Also adds some shortcut functionality
# Written 12/13/99 by Robert G. Ferrell
# RGF 1/31/2000  Added RIPE & APNIC Autoredirect
# RGF 3/1/2000   Added NSLOOKUP Autoredirect for Non-US domains
# RGF 4/17/2000  Added Japanese NIC redirect
# RGF 5/11/2000  Added Korean NIC redirect
# RGF 5/22/2000	 Added English Language diectory to KNIC
# RGF 6/26/2000	 Added register.com redirect
# RGF 2/8/2001	 Added second level ARIN redirect

$who = qq(/bin/whois_old);
$dns = qq(INSERT YOUR NAME SERVER HERE);
chomp($host = $ARGV[0]);
chomp($target = $ARGV[1]);
$args = 0;
$args = 1 if (defined($ARGV[1]));

if ($args == 0) {
	$h = qq(whois.networksolutions.com);
	$t = $host;
	&go;
} elsif ($args == 1) {
	if ($host eq "u") {
		$h = qq(whois.networksolutions.com);
		$t = $target;
		&go;
	} elsif ($host eq "a") {
		$h = qq(whois.apnic.net);
		$t = $target;
		&go;
	} elsif ($host eq "e") {
		$h = qq(whois.ripe.net);
		$t = $target;
		&go;
	} elsif ($host eq "n") {
		$h = qq(whois.arin.net);
		$t = $target;
		&go_arin;
	} elsif ($host eq "m") {
		$h = qq(whois.nic.mil);
		$t = $target;
		&go;
	} elsif ($host eq "g") {
		$h = qq(whois.nic.gov);
		$t = $target;
		&go;
	} elsif ($host eq "j") {
		$h = qq(whois.nic.ad.jp);
		$t = $target . "/e";
		&go;
	} elsif ($host eq "k") {
		$h = qq(whois.nic.or.kr/english);
		$t = $target;		
	} else {
		print <<"EOP";
		
Usage: whois [host] target

Valid host arguments are

a	APNIC
e	RIPE
g       GOV
m       MIL
n	ARIN
u	NSI
j       Japan NIC
k	South Korea NIC

default (no host) is NSI (whois.networksolutions.com)
If n or u options selected, should redirect automatically 
to RIPE, APNIC, JPNIC, or KRNIC, as appropriate

EOP
		exit();
	}
}

sub go {
	@result = qx($who -h $h $t);
	$non_us_test = grep(/NO MATCH/, @result);
	$reg_test = grep(/REGISTER\.COM,/, @result);	
	&go_ns if ($non_us_test);
	&do_reg if ($reg_test);	
	print "@result\n";
	exit();
}

sub do_reg {
	$h = qq(whois.register.com);
	$result = qx($who -h $h $t);
	print "###############################\n";
        print "# Using Register.com Database #\n";
        print "###############################\n";
	print "$result\n";
	exit();
}

sub go_arin {
	@result = qx($who -h $h $t);
	$ripe_test = grep(/RIPE NCC/, @result);
	$krnic_test = grep(/KRNIC/, @result);
	$jpnic_test = grep(/JPNIC/, @result);
	$apnic_test = grep(/APNIC/, @result);
	$block_test = grep(/\!xxx/, @result);
		
	if ($ripe_test != 0) {
		$h = qq(whois.ripe.net);
		$result = qx($who -h $h $t);
		print "#######################\n";
		print "# Using RIPE database #\n";
		print "#######################\n";
		print "$result\n";
		exit();
	} elsif ($krnic_test != 0) {
		$h = qq(whois.nic.or.kr);
		$result = qx($who -h $h $t);
		print "############################\n";
                print "# Using Korean NIC database #\n";
                print "############################\n";
		print "$result\n";
		exit();
	} elsif ($jpnic_test != 0) {
		$h = qq(whois.nic.ad.jp);
		$t = $t . "/e";
		$result = qx($who -h $h $t);
		print "############################\n";
                print "# Using Japan NIC database #\n";
                print "############################\n";
		print "$result\n";
		exit();
	} elsif ($apnic_test != 0) {
		$h = qq(whois.apnic.net);
		$result = qx($who -h $h $t);
		print "########################\n";
		print "# Using APNIC database #\n";
		print "########################\n";
		print "$result\n";
		exit();
	} elsif ($block_test != 0) {
		$h = qq(whois.arin.net);
		@extract = grep(/\(/, @result);
		$num = grep(/\(/, @result);
		$l_num = 1;
		foreach $l (@extract) {
			if ($l_num == $num) {
				($pre,$blk1,$blk2) = split(/\(/, $l);
				($net_blk,$rest) = split(/\)/, $blk1);
				$t = qq(!$net_blk);
			$result = qx($who -h $h $t);
			print "$result\n"; 		
			exit();
			} else { $l_num++; }
		}
			
	} else {
		print "@result\n";
	}	
	exit();
}

sub go_ns {
	$lookup = qx(nslookup $t | grep Address | grep -v '$dns');
	($add,$ip) = split(':', $lookup);
	$ip =~ s/\s//g;
	$h = qq(whois.arin.net);
	$t = $ip;
	&go_arin;
	exit();
}
