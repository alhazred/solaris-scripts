#!/usr/bin/perl -w
#----------------------------------------------------------------------------
# File: logParser.pl
# Created: 05/10/2004
# Author : Dwai Lahiri
# Usage : 
#   logParser.pl -f <filename> -s <starting string> -e <ending string>
# Note: Can be used to get a pattern match range from a larger file
# For eg., from an existing syslog/maillog file, 
# parse and get output of entries within timestamp range : 01:56 - 02:27
# The user has to get the regex (strings) correctly entered at the cmdline
# for the script to do it's thing...
#----------------------------------------------------------------------------

use strict;
use Getopt::Std;
use Time::localtime;

my %Args;
my $date = qx/date '+m%d'/;
chomp $date;

getopts( "f:s:e:o:", \%Args );

my $filename = $Args{f} or print_usage() and die "Can't continue without a filename to parse... \n";
my $startstring = $Args{s} or print_usage() and die "You must enter a start string \n";
chomp $startstring;
my $endstring = $Args{e} or print_usage() and die "You must enter an ending string \n";
chomp $endstring;
my $outfile = $Args{o} or print_usage() and die "You must enter an output filename \n";

open(FILE, "< $filename") or die "Unable to open $filename : $! \n";
open(OUTFILE, ">> $outfile") or die "Unable to write to $outfile: $! \n";
if (-e $outfile) {
    qx/> $outfile/;
}
while (<FILE>) {
    if (/$startstring/ ... /$endstring/) {
            print OUTFILE $_;
    }
}
close(OUTFILE);
close(FILE);

sub print_usage {
    print "Usage: ./logParser.pl -f <input file> -s <\"start search string\"> -e <\"Ending search string\"> -o <output file> \n";
}



###
### This script is submitted to BigAdmin by a user
### of the BigAdmin community.
### Sun Microsystems, Inc. is not responsible for the
### contents or the code enclosed.
###



