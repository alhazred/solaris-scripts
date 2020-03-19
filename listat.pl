#!/usr/bin/perl

# Listat: Generate statistical report about your mailing list
#          http://wordsmith.org/anu/listat
# by Anu Garg (garg at wordsmith.org)
#
# This script can be run from the command line or as a CGI
#

use Getopt::Long;

#-------------------------------------------------------------------------------
$| = 1;			# Force unbuffered I/O
my $subdomainlist = "subdomains.txt"; # Space delimited file with domain info
my $domainlist = "domains.txt";# Tab delimited file with domain info
my $flag_dir = "flags";	# Directory with flags images
my $addresslist = "";	# List file, one email address per line
my $textstats = "";		# Output file for text stats
my $htmlstats = "";		# Output file for HTML stats
my $sort_order = "count";	# Sort on: name(domain name) or count(domain count)
my $otherdom = "Numeric and other unrecognized domain names"; # Description for unrecognized domains
my $ver = "Listat ver. 2.0";	# Version information
my $homepage = "http://wordsmith.org/anu/listat";
my $listsize = 0;		# Number of addresses in the list
my $iscgi = 0;		# Is this script running as a cgi?
my $shortest_address_length = 9999;# Shortest address length on the list
my $longest_address_length = 0; # Shortest address length on the list
my $bad_count = 0;		# Count of addresses that can't be processed
my $verbose = 0;		# Verbose mode
my $bad_addresses = "";	# Listing of addresses with invalid domain
my $config = "listat.conf";	# Config file
my @subdomain = {};		# Subdomains for which subdomain report is done
my $topsubdomain;		# How many top subdomain to list for each subdom
#require "getopts.pl";	# To process command line arguments

# Read config file
open(CONFIG, $config) || die "$0: Unable to open $config for reading: $!\n";
while (<CONFIG>) {
	chomp;
	next if (/^#|^$/);	# Discard comment lines and blank lines
	my ($configoption, $configvalue) = split(/\s/);
	if ($configoption eq "LIST")			{$addresslist = $configvalue;}
	if ($configoption eq "TEXTREPORT")	{$textstats = $configvalue;}
	if ($configoption eq "HTMLREPORT")	{$htmlstats = $configvalue;}
	if ($configoption eq "SORTORDER")	{$sort_order = $configvalue;}
	if ($configoption eq "SUBDOMAIN")	{push(@subdomain, $configvalue);}
	if ($configoption eq "TOPSUBDOMAIN"){$topsubdomain = $configvalue;}
	if ($configoption eq "DOMAINLIST")	{$domainlist = $configvalue;}
	if ($configoption eq "SUBDOMAINLIST"){$subdomainlist = $configvalue;}
}
#}

# =s options takes a mandatory string argument
GetOptions('list=s', \$addresslist, 'help', \&usage, 'version', \&version, 'text=s', \$textstats, 'html=s', \$htmlstats, 'sort=s', \$sort_order, 'verbose'=>\$verbose);

#-------------------------------------------------------------------------------
open(DOMAINLIST, $domainlist) || die "$0: Unable to open $domainlist for reading: $!\n";
print "Reading domain information.\n" if $verbose;
my $country_name;
my %flag0;
my %flag1;
my %country;
my %count;
while (<DOMAINLIST>) {
	chomp;
	next if (/^#|^$/);	# Discard comment lines and blank lines
	my ($domain, $country_name, $flagsmall, $flaglarge) = split(/\t/);
	#print "$domain $flag0 $flag1 $country_name\n";
	$country_name =~ s/^\s+//; # trim leading space
	$country_name =~ s/\s+$//; # trim trailing space
	$country{$domain} = $country_name;
	$flag0{$domain} = $flagsmall;
	$flag1{$domain} = $flaglarge;
	$count{$domain} = 0;
}
close(DOMAINLIST);

my %subdomain;
if (@subdomain > 0){ # subdomain report requested
	print "Reading subdomain information.\n" if $verbose;
	open(SUBDOMAINLIST, $subdomainlist) || die "$0: Unable to open $subdomainlist for reading: $!\n";
	while (<SUBDOMAINLIST>) {
		chomp;
		next if (/^#|^$/);	# Discard comment lines and blank lines
		/^(\S+\.\S+)\s+(.*)/;
		$subdomain{$1} = $2;
	}
}

#-------------------------------------------------------------------------------
$iscgi = 1 if defined $ENV{'SCRIPT_URL'};
if ($iscgi){
	print "Content-type: text/html\n\n";
	read(STDIN, $buffer, $ENV{'CONTENT_LENGTH'}); # Get the input
	@pairs = split(/&/, $buffer); # Split the name-value pairs
	foreach $pair (@pairs)
	{
		($name, $value) = split(/=/, $pair);
		$value =~ tr/+/ /;
		$value =~ s/%([a-fA-F0-9][a-fA-F0-9])/pack("C", hex($1))/eg;
		$FORM{$name} = $value;
	}
	@addresslist = split("\n", $FORM{'addresses'});
	$sort_order = $FORM{'sort'} if defined $FORM{'sort'};
} else {
	open(ADDRESSLIST, $addresslist) || die "$0: Unable to open $addresslist for reading: $!\n";
	@addresslist = <ADDRESSLIST>;
}

my $address_sd_sum = 0;
my $address_total_length = 0;
my @bad_addresses = ();
my $newline_count;
my $address;
my $current_address_length;
my @shortest_addresses;
my @longest_addresses;
my %uniq_subdom;
my %HoH;
my %address_length_tally;
my $subdomn;

print "Processing addresses.\n" if $verbose;
foreach $address (@addresslist) {
	chomp($address);
	$address =~ s/\^s+//; $address =~ s/\s+$//;
	last if $address eq "";
	$listsize++;

	#'s/^[^@]*@([^@]*).*/\1/ ; s/:.*// ; s/.*\.//'
	$a = $address;			# e.g. @Tredydev.Unisys.Com:YAJI@BOMAHB
	# $a =~ s/^[^@]*@([^@]*).*/$1/;	# Tredydev.Unisys.Com:YAJI
	# $a =~ s/:.*//;			# Tredydev.Unisys.Com
	$a =~ s/.*[@\.](.*\..*)/$1/;		# Unisys.Com
	$a =~ tr/A-Z/a-z/;		# unisys.com
	$subdomn = $a;			# unisys.com
	$a =~ s/.*\.//;			# com

	if (defined($country{$a})) {
		$count{$a}++;
	} else {
		push(@bad_addresses, $address);
		$bad_count++;
	}

	$current_address_length = length($address);
	$address_length_tally{$current_address_length}++; # count of addresses of this length for finding mode
	$address_total_length += $current_address_length;

	if ($shortest_address_length > $current_address_length) {
		$shortest_address_length = $current_address_length;
		@shortest_addresses = ();
	}

	if ($longest_address_length < $current_address_length) {
		$longest_address_length = $current_address_length;
		@longest_addresses = ();
	}

	if ($longest_address_length == $current_address_length) {
		push(@longest_addresses, $address);
	}

	if ($shortest_address_length == $current_address_length) {
		push(@shortest_addresses, $address);
	}

	$uniq_subdom{$subdomn} = 1; # count unique subdomains on the list

	if (grep /^$a$/, @subdomain){ # subdomain report requested
		$HoH{$a}{$subdomn}++;
	}
}

if ($listsize < 1){
	print "Error: empty list.\n";
	print "Please go back, enter the list addresses, and try again.\n" if ($iscgi);
	die;
}

my $address_mean = $address_total_length/$listsize;
my $address_running_tally_total = 0;
my $listsize_odd = $listsize%2;
my $address_median_point = int (($listsize + $listsize_odd)/2);
my @address_keys = sort keys(%address_length_tally);
my $element_n;
my $element_n_found;
my $element_n1;
my $element_n1_found;;
my $diff;
my $diff_sqr;

foreach my $curr_len (@address_keys){
	# Standard Deviation
	my $dif = $curr_len - $address_mean;
	my $dif_sqr = $dif * $dif;
	$address_sd_sum += $address_length_tally{$curr_len} * $dif_sqr;

	# Median
	$address_running_tally_total += $address_length_tally{$curr_len};
	if (!$element_n_found && ($address_running_tally_total >= $address_median_point)) {
		$element_n = $curr_len;
		$element_n_found = 1;
	}
	if (!$element_n1_found && ($address_running_tally_total >= $address_median_point+1)) {
		$element_n1 = $curr_len;
		$element_n1_found = 1;
	}
}

my $address_sd;
my $address_median;
if ( $listsize > 1 ) {
	$address_sd = sqrt($address_sd_sum/($listsize - 1));
} else {
	$address_sd = 0;
	}

if ($listsize_odd) {
	$address_median = $element_n;
} else {
	$address_median = ($element_n + $element_n1) / 2 ;
}

# Calculate mode
my @countkeys = sort { $address_length_tally{$b} <=> $address_length_tally{$a} } keys(%address_length_tally);
my $address_modecount = 2; # How many times the mode value occurs
my $address_mode = "";
my @mode;

foreach my $key (@countkeys){
	if ($address_length_tally{$key} >= $address_modecount) {
		$address_modecount = $address_length_tally{$key};
		push(@mode, $key);
	} else { # get out ... we can do this since this is a sorted list.
		last;
	}
}

if (@mode > 0) {
	$address_mode = join(", ", @mode);
} else {
	$address_mode = "none";
}

my $unique_subdomains = keys(%uniq_subdom) + 0;

# Printing bad addresses
if ($bad_count > 0){
	print "Address(es) with unrecognized domains:\n";
	print join("\n", @bad_addresses);
	print "\n\n";
}

#-------------------------------------------------------------------------------
# print stats
my $longest_addresses;
my $shortest_addresses;
my @keys;

if($sort_order eq "name") {
	@keys = sort keys(%count);
} else {
	@keys = sort { $count{$b} <=> $count{$a} } keys(%count);# sort by count
}

my @subdomainkeys;

if ($iscgi){
	$TEXT = "STDOUT";
	$HTML = "STDOUT";
} else {
	open($TEXT, ">" . $textstats) || die "error opening $textstats for reading: $!\n";
	open($HTML, ">" . $htmlstats) || die "error opening $htmlstats for reading: $!\n";
}

#----------- Main report ---------------
printf "<h3>Stats in text format</h3>" if $iscgi;
printf "<pre>" if $iscgi;
printf($TEXT "Domain Report\n\n");
printf($TEXT "%-7s%6s %8s  %-20s\n\n", "Domain", "Count", "%", "Domain Description");

foreach my $key (@keys){
	if ($count{$key} > 0) {
		printf($TEXT "%-7s%6d %8.4f  %-20s\n", $key, $count{$key}, $count{$key}*100/$listsize, $country{$key});
	}
}

if ($bad_count > 0) {
	printf($TEXT "%-7s%6d %8.4f  %-20s\n", "Other", $bad_count, $bad_count*100/$listsize, $otherdom);
}
printf($TEXT "-------------\n");
printf($TEXT "%-7s%6d\n", "Total", $listsize);
printf($TEXT "-------------\n\n");

#----------- Subdomain report ----------
#printf($TEXT "Number of unique subdomains on the list: $unique_subdomains \n\n");
foreach my $dom ( sort keys %HoH ) {
	printf($TEXT "Top $topsubdomain subdomains in the domain '$dom':\n\n");
	printf($TEXT "%20s %6s %6s  %s\n\n", "Subdomain", "Count", "%age", "Description");
	@subdomainkeys = sort { $HoH{$dom}{$b} <=> $HoH{$dom}{$a} } keys %{ $HoH{$dom} };
	my $counter = $topsubdomain;
	foreach my $subdom (@subdomainkeys){
		if (!defined($subdomain{$subdom})){
			$subdomain{$subdom} = "";
		}
		printf($TEXT "%20s %6d %6.3f  %s\n", $subdom, $HoH{$dom}{$subdom}, $HoH{$dom}{$subdom}*100/$listsize, substr($subdomain{$subdom}, 0, 42)) if $counter-- > 0;
	}
	printf($TEXT "\n\n");
}

#----------- Stats report --------------
printf($TEXT "Stats on Address Lengths:\n\n");
printf($TEXT "Mean                   : %6.3f\n", $address_mean);
printf($TEXT "Median                 : %6.3f\n", $address_median);
printf($TEXT "Mode                   : %s\n",    $address_mode);
printf($TEXT "Standard Deviation     : %6.3f\n", $address_sd);

$longest_addresses = join(" ", @longest_addresses);
$shortest_addresses = join(" ", @shortest_addresses);

printf($TEXT "Longest address length : %d\n",    $longest_address_length);
printf($TEXT "Longest address(es)    : %s\n",    $longest_addresses);
printf($TEXT "Shortest address length: %d\n",    $shortest_address_length);
printf($TEXT "Shortest address(es)   : %s\n",    $shortest_addresses);
printf($TEXT "\nStats created with Listat by Anu Garg.\n");
printf($TEXT "( $homepage ).\n");

printf "</pre>" if $iscgi;
printf "<h3>Stats in html format</h3>" if $iscgi;

#----------- Main report ---------------
printf $HTML <<"EOT";

<style type="text/css">
img.centered {
    display: block;
    margin-left: auto;
    margin-right: auto }
</style>

EOT

printf($HTML "<CENTER>\n");
printf($HTML "<TABLE width=95%% BORDER=3 CELLPADDING=5 CELLSPACING=1>\n");
printf($HTML "<CAPTION>Domain Report</CAPTION>\n");
printf($HTML "<TR>\n");
printf($HTML "   <TH>Domain</TH>\n");
printf($HTML "   <TH>Count</TH>\n");
printf($HTML "   <TH>%%age</TH>\n");
printf($HTML "   <TH>Domain Description</TH>\n");
printf($HTML "   <TH>Flag</TH>\n");
printf($HTML "</TR>\n");

my $flagstr;
foreach my $key (@keys){
	if ($count{$key} > 0) {
		#print $key, "\t", $flag0{$key}, "\t", exists $flag0{$key}, "\t", defined $flag0{$key}, "\n";
		if(defined $flag0{$key}) { # if this domain has a flag specified in the domain file
			$flag0{$key} =~ s/^\s+//;
			$flag0{$key} =~ s/\s+$//;
			$flagstr = "<a href=$flag_dir/$flag1{$key}><img src=$flag_dir/$flag0{$key} class=\"centered\" alt=\"$country{$key} flag\" border=0></a>";
		} else {
			$flagstr = "";
		}
		printf($HTML "<TR>\n");
		printf($HTML "   <TD>%s</TD>\n", $key);
		printf($HTML "   <TD ALIGN=RIGHT>%4d</TD>\n", $count{$key});
		printf($HTML "   <TD ALIGN=RIGHT>%8.4f</TD>\n", $count{$key}*100/$listsize);
		printf($HTML "   <TD>%s</TD>\n", $country{$key});
		printf($HTML "   <TD>%s</TD>\n", $flagstr);
		printf($HTML "</TR>\n");
	}
}

if ($bad_count > 0) {
	printf($HTML "<TR>\n");
	printf($HTML "   <TD>Other</TD>\n");
	printf($HTML "   <TD ALIGN=RIGHT>%6d</TD>\n", $bad_count);
	printf($HTML "   <TD ALIGN=RIGHT>%8.4f</TD>\n", $bad_count*100/$listsize);
	printf($HTML "   <TD>%s</TD>\n", $otherdom);
	printf($HTML "</TR>\n");
}

printf($HTML "<TR>\n");
printf($HTML "   <TD><b>Total</TD>\n");
printf($HTML "   <TD ALIGN=RIGHT>%4d</TD>\n", $listsize);
printf($HTML "   <TD ALIGN=RIGHT>%6.3f</b></TD>\n", 100);
printf($HTML "</TR>\n");
printf($HTML "<TR>\n");
printf($HTML "   <TD COLSPAN=5 ALIGN=CENTER><FONT SIZE=-1>Stats created using <a href=\"$homepage\"><em>Listat</em></a> by Anu Garg.</FONT></TD>\n");
printf($HTML "</TR>\n");
printf($HTML "</TABLE>\n");

print "(Note: flag images are available for download in the package <a href=http://wordsmith.org/anu/listat/listat.zip>listat.zip</a>)" if $iscgi;

printf($HTML "<P>\n\n");

#----------- Subdomain report ----------
foreach my $dom ( sort keys %HoH ) {
	printf($HTML "<TABLE width=95%% BORDER=3 CELLPADDING=5 CELLSPACING=1>\n");
	printf($HTML "<CAPTION>Top $topsubdomain subdomains in the domain '$dom'</CAPTION>\n");
	printf($HTML "<TR>\n");
	printf($HTML "   <TH>%20s</TH>\n", "Subdomain");
	printf($HTML "   <TH>%6s</TH>\n", "Count");
	printf($HTML "   <TH>%6s</TH>\n", "%age");
	printf($HTML "   <TH>%s</TH>\n", "Description");
	printf($HTML "</TR>\n");
	my @subdomainkeys = sort { $HoH{$dom}{$b} <=> $HoH{$dom}{$a} } keys %{ $HoH{$dom} };
	my $counter = $topsubdomain;
	foreach my $subdom (@subdomainkeys){
		if ($counter-- > 0) {
			printf($HTML "<TR>\n");
			printf($HTML "   <TD>%20s</TD>\n", $subdom);
			printf($HTML "   <TD align=right>%6d</TD>\n", $HoH{$dom}{$subdom});
			printf($HTML "   <TD align=right>%6.3f</TD>\n", $HoH{$dom}{$subdom}*100/$listsize);
			printf($HTML "   <TD>%s</TD>\n", $subdomain{$subdom} . " ");
			printf($HTML "</TR>\n");
		}
	}
	printf($HTML "</TABLE>\n<P>\n\n");
}

#----------- Stats report --------------
printf($HTML "<TABLE width=95%% BORDER=3 CELLPADDING=5 CELLSPACING=1>\n");
printf($HTML "<CAPTION>Stats on Address Lengths</CAPTION>\n");
printf($HTML "<TR>\n");
printf($HTML "   <TD>Mean </TD>\n");
printf($HTML "   <TD>%6.3f</TD>\n", $address_mean);
printf($HTML "</TR>\n");
printf($HTML "<TR>\n");
printf($HTML "   <TD>Median </TD>\n");
printf($HTML "   <TD>%6.3f</TD>\n", $address_median);
printf($HTML "</TR>\n");
printf($HTML "<TR>\n");
printf($HTML "   <TD>Mode </TD>\n");
printf($HTML "   <TD>%s</TD>\n", $address_mode);
printf($HTML "</TR>\n");
printf($HTML "<TR>\n");
printf($HTML "   <TD>Standard Deviation </TD>\n");
printf($HTML "   <TD>%6.3f</TD>\n", $address_sd);
printf($HTML "</TR>\n");

$longest_addresses = "";
$shortest_addresses = "";

foreach my $temp (@longest_addresses){
	$longest_addresses .= "<a href=\"mailto:$temp\">$temp</a>" . " ";
}
foreach my $temp (@shortest_addresses){
	$shortest_addresses .= "<a href=\"mailto:$temp\">$temp</a>" . " ";
}

printf($HTML "<TR>\n");
printf($HTML "   <TD>Longest address length </TD>\n");
printf($HTML "   <TD>%d </TD>\n", $longest_address_length);
printf($HTML "</TR>\n");
printf($HTML "<TR>\n");
printf($HTML "   <TD>Longest address(es) </TD>\n");
printf($HTML "   <TD>%s </TD>\n", $longest_addresses);
printf($HTML "</TR>\n");
printf($HTML "<TR>\n");
printf($HTML "   <TD>Shortest address length</TD>\n");
printf($HTML "<TD>%d </TD>\n", $shortest_address_length);
printf($HTML "</TR>\n");
printf($HTML "<TR>\n");
printf($HTML "   <TD>Shortest address(es) </TD>\n");
printf($HTML "   <TD>%s </TD>\n", $shortest_addresses);
printf($HTML "</TR>\n");
printf($HTML "</TABLE>\n");
printf($HTML "</CENTER>\n");

print "Done.\n" if $verbose;

#-------------------------------------------------------------------------------
sub version{
	print <<"EOT";

$ver
(Listat = List + Stat)

A package for generating interesting statistical and demographical
information on email mailing list addresses.

$homepage

Copyright (c) 1997-2006 Anu Garg (garg AT wordsmith.org)

EOT
exit();
}

sub usage{
print <<"EOT";

Usage: $0 [switches] [arguments]

  -list Filename    List file with email addresses, one per line
  -text Filename    Output file for stats in text format
  -html Filename    Output file for stats in HTML format
  -sort name|count  Sort order: domain name or domain count
  -help             This help message
  -version          Version information
  -Verbose          Verbose mode

  Example: $0 -c -list list.txt -text output.txt -html output.html

EOT
exit();
}
