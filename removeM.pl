#!/usr/bin/perl

#  Author: Wai Chan (waichan@hpu.edu)
#  Create Date: Apr 12, 2002
#  Script Name: removeM.pl
#  Description: remove ^M from a text file
#       Syntax: removeM textFilename0 textFilename1 ...

#  ^M in this script (line 24) is generated with:
#       control-V and control-M
#  You must type these yourself.  Don't copy and paste.

# Modify the following to fit your environment
#       $perlPath       absolute path of perl

$perlPath="/usr/bin/perl";

if (scalar(@ARGV)>0)
{
        foreach $filename (@ARGV)
        {
                if ((-e $filename) && (-T $filename))
                {
                        if (system("$perlPath -pi -e \"s:^M::g\" $filename") == 0)
                        {
                                print "^M has been removed from $filename\n";
                        }
                        else
                        {
                                print "script failed.\n"
                        }
                }
                else
                {
                        print "$filename does not exist, or is not a text file.\n";
                }
        }
}




##############################################################################
### This script is submitted to BigAdmin by a user of the BigAdmin community.
### Sun Microsystems, Inc. is not responsible for the
### contents or the code enclosed. 
###
###
### Copyright 2005 Sun Microsystems, Inc. ALL RIGHTS RESERVED
### Use of this software is authorized pursuant to the
### terms of the license found at
### http://www.sun.com/bigadmin/common/berkeley_license.html
##############################################################################


