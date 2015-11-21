#!/usr/bin/perl -w

###
# IPtoHex
#
# Convert IP address to Hex-format.
# Very useful when creating jumpstart-server for Solaris
# where the tftp inetboot image has to be linked to IP address
# in Hex format.
#
# Script is run in hand.
#
# Programmed by: Yngve Berthelsen
# Date: 20061025
# E-Mail: mig@yngve.dk
#
# Last updated: 20061025
#
# History:


### Variables used in script

if(! $ARGV[0])
{
   printf("Convert IP adresses to Hexadecimal format\n");
   printf("Programmed by Yngve Berthelsen\n\n");
   printf("Usage: IPtoHex <IP adresse>\n");
   printf("Example: IPtoHex 127.0.0.1\n");
   exit 0;
}
else
{
   printf("Convert IP adresses to Hexadecimal format\n");
   printf("Programmed by Yngve Berthelsen\n\n");
   @IP = split(/\./, $ARGV[0]);
   printf("IP address %s, converts to Hex: %02X%02X%02X%02X\n",$ARGV[0],$IP[0],$IP[1],$IP[2],$IP[3]);
} 

# Exit
exit 0;




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


