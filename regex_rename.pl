#!/usr/bin/perl
# Usage: rename perlexpr [files]

($op = shift) || die "Usage: $0 [-v] perlexpr [files] or try -h\n";

if ($op eq "-h"){
   print "rename perl script\n";
   print "Usage: perlexpr [files]\n";
   print "i.e. add .gz extension: rename 's/(.*)/\$1.gz/' *\n";
   print "and back: rename -v 's/(.*)\.gz/\$1/' *\n\n";
   print "rename filenames with spaces to underscores:\n";
   print "rename -v 's/\\ /_/g' *\\ *\n";
   exit 0;
   }

if ($op eq "-v"){
   $VERBOSE=1;
   $op = shift;
   }

if (!@ARGV)
{
    @ARGV = <STDIN>;
    chop(@ARGV);
}

for (@ARGV)
{
    $was=$_;
    eval $op;
    die $@ if $@;
    if ((-e $_) && ($was ne $_)) {
        print STDERR "File exists: $was --> $_\n";
        next;
    }
    $VERBOSE && print "renaming $was --> $_\n";
    rename($was,$_) unless ($was eq $_);
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


