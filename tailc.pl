#!/usr/bin/perl
#
# Prints lines from $logfile in colour according to
# matches you define in %cfg
#
# Usage: tailc <# lines back in log to display (default=5)>
#
# supermike@blemished.net
#

$logfile='/var/log/all';

%cfg = (
'010|ipmon'			=> 'RED-bYELLOW',
'020| iplog'			=> 'CYAN',
'030|kernel'			=> 'PURPLE',
'040|crontab'			=> 'PURPLE',
'050|/USR/SBIN/CRON'		=> 'PURPLE',
'060|Login user'		=> 'BLUE',
'070|Logout user'		=> 'BLUE',
'080|sshd'			=> 'GREEN-bRED-BOLD-UL',
'090|ntpd'			=> 'GREEN',
'100|exim'			=> 'YELLOW',
'110|sendmail'			=> 'YELLOW-bBLUE',
'120|this message is annoying'	=> 'ignore',
'130|abc\d\d\d'			=> 'WHITE-INV',
'140|hello [tT]here'		=> 'WHITE',
'150|hello \w+'			=> 'YELLOW-bBLUE-UL',
);

%col = (
BEEP    => '',
BOLD    => "\033[01m",
UL      => "\033[02m",
INV     => "\033[03m",
RED	=> "\033[31m",
GREEN	=> "\033[32m",
YELLOW	=> "\033[33m",
BLUE	=> "\033[34m",
PURPLE	=> "\033[35m",
CYAN	=> "\033[36m",
WHITE	=> "\033[37m",
bRED	=> "\033[41m",
bGREEN	=> "\033[42m",
bYELLOW	=> "\033[43m",
bBLUE	=> "\033[44m",
bPURPLE	=> "\033[45m",
bCYAN	=> "\033[46m",
bWHITE	=> "\033[47m",
ignore  => 0,
);

$back = $ARGV[0] ? $ARGV[0] : 5;
$os = `/bin/uname`;
if ($os == 'SunOS') {
open(LOG, "tail -${back}f $logfile|") || die "Error opening $logfile: $!\n";
} else {
open(LOG, "tail -n $back --follow=name $logfile|") || die "Error opening $logfile: $!\n";
}
$def = "\033[0m"; # default colour

while (defined($line=<LOG>)) {
	chomp $line;
	$esc = $def;
	foreach $string (sort keys %cfg) {   
		$str = $string; $str =~ s/^\d+\|//;
		if ($line =~ /$str/) {
			@clr = split(/-/, $cfg{$string});
			undef $esc;
			foreach $c (@clr) { $esc .= $col{$c}; };
			last;
		}
       	}
	print "$esc$line$def\n" if $esc;
}
