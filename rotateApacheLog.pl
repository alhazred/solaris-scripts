#!/usr/bin/perl

# Author:  Wai Chan (waichan@hpu.edu)
# Create Date:  Apr 10, 2002
# Script Name:  rotateApacheLog.pl
# Description:  rotates Apache http access log when
#               - log is larger than the specified size limit.
#               - rotates instantly when argument "now" is used.
#               Schedule this script in cron.

# Modify the followin to fit your environment
#       $httpdPath      absolute path of apache bin
#       $logFile        absolute path of apache log
#       $logLimit       log file size limit (in KB)

$httpdPath="/usr/local/apache/bin/apachectl";
$logFile="/var/log/httpd-access.log";
$logLimit=200;

if (scalar(@ARGV)>0)
{
        if ($ARGV[0] eq "now")
        {
                rotate();
        }
        else
        {
                print "Incorrect Argument.\nThis script only supports \"now\" as argument.\n";
        }
}
else
{
        if (-e $logFile)
        {
                $size=-s $logFile;
                $ksize=$size/1024;
                if ($ksize>=$logLimit)
                {
                        rotate();
                }
        }
        else
        {
                die ("$logFile does not exist.\n");
        }              
}

sub rotate()
{
        $suffix=`date '+m%d'`;
        chomp($suffix);
        if ((-e $logFile) && (!(-e "$logFile.$suffix")))
        {
                rename($logFile, "$logFile.$suffix");
                open(NEWLOG, ">$logFile");
                close (NEWLOG);
                system("$httpdPath restart");
        }
        else
        {
                die ("$logFile does not exist OR $logFile.$suffix is already exist.\n");
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


