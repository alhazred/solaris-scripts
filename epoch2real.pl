#!/usr/bin/perl

###
# epoch2real
#
# This script converts EPOC to real time. 
# We have to do this as several of our ATM 
# awitches currently are only using EPOCH time.
#
# Submitted By: Robert Banniza - robert@rootprompt.net
use Time::localtime;

while ($loop = 1) {
  print "Enter a time in EPOCH: ";
  $time = <STDIN>;
  $tm = localtime($time);
  printf("Dateline: %02d:%02d:%02d-%02d/%02d/%04d\n\n",
  $tm->hour, $tm->min, $tm->sec, $tm->mon+1, $tm->mday, $tm->year+1900);
  loop;
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


