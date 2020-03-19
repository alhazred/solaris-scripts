#!/usr/local/bin/perl
# To Generate Nos with specified extension - Vinoth - vinothu@hotmail.com
# Change above perl path as per your installation.

if ( ! $ARGV[0] || ! $ARGV[1] ) {
                  print "\nUsage: GenerateNOs.pl <firstnum> <Count> [extension]\n\n";
                  exit(0);
                 }
if ( ! $ARGV[2] ){ 
         $ext="";
         }else{
          $ext=".$ARGV[2]";
         }

$i=0;
$St1="";
$St2="";

$START=$ARGV[0];

if ( $START =~ /^(.*?)(\d+)$/ ){

      $St1 = $1; 
      $St2 = $2; 

     for ( $i = 0; $i < $ARGV[1] ; $i++ ) {
          print $St1 . $St2++ . "$ext\n";
     }
} else {

     for ( $i = 0; $i < $ARGV[1] ; $i++ ) {
          print $START++ . "$ext\n";
     }
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


