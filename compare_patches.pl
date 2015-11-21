#!/usr/bin/perl

# 
# Compare patches installed across Sun servers
# NEPD Consulting
# Paul Guglielmino <paulg@nepd.com>
#
# Please send improvements or comments to me!
#

$version = "0.9";
$header = 1;

use Getopt::Long;

Getopt::Long::Configure( 'permute' );
GetOptions( 'xref=s' => \$xref, 'diffs' => \$want_only_diffs, 
	    'showrev' => \$showrev, 'patchk' => \$patchk,
	    'debug' => \$debug, 'help' => \$usage,
	    'version' => \$v, 'header!' => \$header );

if ( $usage ) { print_usage(); exit 0; }
if ( $v ) { print_version(); exit 0; }

#####
@server_files = ();
@server_patch_levels = {};

# To fix 0 indexed arrays
$numservers = -1;

foreach $datafile (@ARGV) {
  if ( ! -f $datafile ) {
    print "File $datafile not available, skipping\n";
  } else {
    push( @server_files, $datafile );
    $numservers++;
  }    
}

if ( $numservers == -1 ) {
  die "No files to analyze\n";
}

if ( $xref ) {
  open( XREF, "$xref" ) || 
    die "Can not open requested patchdiag.xref ($xref), Error: $!\n";

  while( <XREF> ) {
    next if ( /^#/ );	      
    @line = split( /\|/, $_ );
    $latest_patch{$line[0]} = $line[1];
    $debug && print "Xref matched patch: $line[0] - $line[1]\n";
  }

  close(XREF);
}

# Assume showrev output unless told otherwise
if ( $patchk ) {
  $sub_ref = \&parse_patchk_file;
} else {
  $sub_ref = \&parse_showrev_file;
}

for $i (0..$#server_files) {
  $debug && print "Parsing $server_files[$i] ...\n";
  open(F, "$server_files[$i]");
  &$sub_ref(F,$i);
  close(F);
}

if ( $header ) {
  print_header();
}

$patchdiffs = 0;
@all_patches = ();
%count = ();

foreach $s (keys %server_patch_levels) {
  foreach $p (keys %{$server_patch_levels{$s}}) {
    $count{$p} = 1;
  }
}

$numpatches = keys %count;
@all_patches = keys %count;

foreach $p (@all_patches) {
  $linestring = "";
  $diff_string = "";
  $diff_patch_flag = 0;
  $not_latest = 0;

  for $i (0..$numservers) {
    $linestring .= sprintf " %s: %2s |", $server_files[$i], $server_patch_levels{$i}{$p};
  }
  
  for $i (0..$numservers-1) {
    if ( $server_patch_levels{$i}{$p} != $server_patch_levels{$i+1}{$p} ) {
      $diff_patch_flag = 1;
    }
    if ( ($xref) && ($server_patch_levels{$i}{$p} < $latest_patch{$p}) ) {
      $debug && print "Found out of date patch: $p - $latest_patch{$p}\n";
      $not_latest = 1;
    }
  }

  if ( $diff_patch_flag ) {
    $patchdiffs++;
    $diff_string .= "*";
  } 

  if ( $not_latest ) {
    $diff_string .= "+";
  }

  if ( (!$want_only_diffs) ||
       ($diff_patch_flag && $want_only_diffs)  ) {
      printf "%-6s%-2s || %s\n", "$p", $diff_string, $linestring; 
    }

}

print "\nDiffs in patches: $patchdiffs out of total $numpatches\n";

exit 0;

sub parse_showrev_file {
  my($fh,$i) = @_;
  while( <$fh> ) {
    # Match only the lines that have installed patches
    if ( /^Patch: (\d{6})-(\d{2})/ ) {
      $debug && print "Matched patch: $1 - $2\n";
      # Load the patch and revision number into our hash if it:
      # Is not already there or if it is there with a lower revision number
      if ( (! defined $server_patch_levels{$i}{$1}) ||
	   ($server_patch_levels{$i}{$1} < $2) ) { 
	$server_patch_levels{$i}{$1} = $2;
      }
    }
  }
}

sub parse_patchk_file {
  my($fh,$i) = @_;
  while( <$fh> ) {
    if ( /^(\d{6})    (\d{2})/ ) {
      $debug && print "Matched patch: $1 - $2\n";
      # Load the patch and revision number into our hash if it:
      # Is not already there or if it is there with a lower revision number
      if ( (! defined $server_patch_levels{$i}{$1}) ||
           ($server_patch_levels{$i}{$1} < $2) ) {
        $server_patch_levels{$i}{$1} = $2;
      }

    }
  }
}

sub print_header {
  $servers = $#server_files;
  $line = "Patch ID ||  ";
  foreach $s (@server_files) {
    $len = length($s) - 1;
    $line .= "Rev #" . " "x$len . " | ";
  }
  print "$line\n";
}

sub print_usage {

  print<<EOT;

Show differences between patch levels on Solaris servers

Usage: $0 [OPTIONS]... [FILES]...
\t --help              [This message]
\t --debug             [Show debugging output]
\t --xref=<filename>   [Match patches against give xref file]
\t --diff              [Show only differences]
\t --header            [Print header (default)]
\t --showrev           [Input files are in showrev -p format (default)]
\t --patchk            [Input files are in Sun patchk.pl format]
\t --version           [Print version number]
EOT
}

sub print_version {
  print "$0: Version $version\n\n";
}





##############################################################################
### This script is submitted to BigAdmin by a user of the BigAdmin community.
### Sun Microsystems, Inc. is not responsible for the
### contents or the code enclosed. 
###
###
### Copyright 2008 Sun Microsystems, Inc. ALL RIGHTS RESERVED
### Use of this software is authorized pursuant to the
### terms of the license found at
### http://www.sun.com/bigadmin/common/berkeley_license.html
##############################################################################


