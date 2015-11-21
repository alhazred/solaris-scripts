#!/usr/bin/perl

#
# Copyright (c) 2002 Nuno M. Rodrigues.  All rights reserved.
# This program is free software; you can redistribute it and/or
# modify it under the same terms as Perl itself.
#
# $Id: ifstat,v 1.9 2002/08/24 16:43:56 nmr Exp nmr $
#

use Getopt::Std;
use Sun::Solaris::Kstat;
use POSIX qw(sysconf _SC_CLK_TCK);

# recognized interface names
use constant NICS => qr/le|qe|be|hme|qfe|iprb|rtls|elxl|bf|nf|vge/;


sub usage() {

	print STDERR "Usage: $0 [-I <interface>] [<interval [<count>]]\n";
	exit 1;
}

getopts('I:');

if (@ARGV > 2) { usage; }

if (defined($opt_I) && $opt_I !~ /@{[NICS]}\d/) {
	print STDERR "$0: Invalid interface: $opt_I\n";
	exit 1;
}

format STDOUT_TOP =
      if          kb/s       pkt/s       errs     colls
name     spd    in   out    in   out    in   out
.

format STDOUT =
@<<<<< @#### @#### @#### @#### @#### @#### @#### @#####
$name, $spd, $kbin,$kbout,$pktin,$pktout,$errsin,$errsout,$colls
.

$= = defined($ENV{ROWS}) ? $ENV{ROWS} : 24;

$ks = new Sun::Solaris::Kstat;

@nics = grep { /^@{[NICS]}$/ } keys %{$ks};
# in seconds
$prev = ();
$uptime = $ks->{unix}->{0}->{system_misc}->{clk_intr} / sysconf(_SC_CLK_TCK);
$time = $uptime;

sub usr1() {
	$ks->update;
	foreach $i (@nics) {
		foreach $j (keys %{$ks->{$i}}) {

			$name = "$i$j";

			# inefficient!!!
			if(defined($opt_I) && $opt_I !~ /$name/) { next; }		

			$spd = $ks->{$i}->{$j}->{"$i$j"}->{ifspeed} / 1000000;
			$kbin = ($ks->{$i}->{$j}->{"$i$j"}->{rbytes64} - $prev{$name}{rbytes64}) / 1024 / $time;
			$prev{$name}{rbytes64} = $ks->{$i}->{$j}->{"$i$j"}->{rbytes64};
			$kbout = ($ks->{$i}->{$j}->{"$i$j"}->{obytes64} - $prev{$name}{obytes64}) / 1024 / $time;
			$prev{$name}{obytes64} = $ks->{$i}->{$j}->{"$i$j"}->{obytes64};
			$pktin = ($ks->{$i}->{$j}->{"$i$j"}->{ipackets64} - $prev{$name}{ipackets64}) / $time;
			$prev{$name}{ipackets64} = $ks->{$i}->{$j}->{"$i$j"}->{ipackets64};
			$pktout = ($ks->{$i}->{$j}->{"$i$j"}->{opackets64} - $prev{$name}{opackets64}) / $time;
			$prev{$name}{opackets64} = $ks->{$i}->{$j}->{"$i$j"}->{opackets64};
			$errsin = $ks->{$i}->{$j}->{"$i$j"}->{ierrors};
			$errsout = $ks->{$i}->{$j}->{"$i$j"}->{oerrors};
			$colls = $ks->{$i}->{$j}->{"$i$j"}->{collisions};

			write STDOUT;
		}
	}

}

$SIG{USR1} = \&usr1;
&usr1;
for (;;) {
	if (defined($ARGV[0])) {
		$time = $ARGV[0];
		defined($ARGV[1]) and exit 0 if (--$ARGV[1] == 0);
	} else {
		exit 0;
	}
	sleep $time;
	kill "USR1", $$;
}
