#!/usr/bin/perl -w

#------------------------------------------------------------------------------
# df Monitor : Monitor Disk free space (run from crontab) and emails warnings
# Author: Dwai Lahiri
#------------------------------------------------------------------------------

#use strict;

use Mail::Mailer;

my $df = "/usr/sbin/df";
my $dfopt = "-k";
my $mailx = "/usr/bin/mailx";	#if you want to use mailx for something
my $null = "/dev/null";		#If you want to use /dev/null for something

# Set the Alert and Critical thresholds -- can be modified to 
# read from a config file further down the road...
  
my $critlim = 80;
my $alrtlim = 70;

my $arr;
my $pval;

# the qx// directive same as `` (backticks)

my $hostname = qx/hostname/;		
chomp $hostname;
my $date = qx/date '+%m-%d-%Y:%H-%M'/;
chomp $date;

#Mail and Alerts Variables, Methods..
#Change the recipient address to your email/pager

my $alrt_recipient = "root\@$hostname";
my $crit_recipient = "root\@$hostname";
my $mailer = new Mail::Mailer;

my @out = qx/$df $dfopt/;
foreach my $line(@out) 
 {	#1
  if ($line !~ /^Filesystem|proc|fd|mnttab|cdrom|\/var\/run/)
  {	#2
    my @arr = split(' ', $line);
    print "$arr[0], $arr[4] \n";
    my @pval = split(/%/, $arr[4]);
    print "$pval[0] \n";
        if (($pval[0] >= $alrtlim) && ($pval[0] lt $critlim))
	{	#3
            my $alert = "Alert on $hostname $date -- $arr[5] at $pval[0] percent\n";
            print $alert;
	    #Send normal alert
	    $mailer->open({		
			To =>	"$alrt_recipient",
			Subject	=> "$alert",
	    });
	    print $mailer $alert;
	    $mailer->close;
        }	#3`
       else 
       {	#5
         if  ($pval[0] ge $critlim) 
	 {	#6
           my $crit = "Critical on $hostname $date -- $arr[5] at $pval[0] percent \n";
           print $crit;
	   #Send critical alert
	   $mailer->open({		
		To =>	"$crit_recipient",
		Subject	=> "$crit",
	   });
	   print $mailer $crit;
	   $mailer->close;
         }	#6`
      }		#5`
   }	#2`
}	#1`




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


