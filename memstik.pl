#!/bin/perl
# memstik: setuid-root script to assist in bringing a memory stick
# into the system, or taking it out.  Assumes:
# 1) memory stick has previously been partitioned with one big slice 2,
#    newfs-ed, and perms/owner of root directory set.
# 2) memory stick's filesystem will be mounted on existing dir /memstik.
# 3) keeping the memory stick device out of vold's hands is desirable.
# A 32MB stick is usually setup, via "format -e", as a drive with
# 16 heads, 16 sectors, and 256 physical cylinders.
# to install: chmod 4550 memstik; chown 0 memstik; chgrp 1565 memstik

 $ENV{PATH} = "/bin:/usr/sbin";
 $user = "era";			# allow only this user execution
 ($j,$j,$uid) = getpwnam($user);
 if ($< != 0 && $< != $uid)	# allow only root and $user
 { print "You do not have permission to run this program.\n";  exit 2; }
 $< = $>;		# make real uid == effective uid
 $func = $ARGV[0];
 usage() if $func ne "in" && $func ne "out";
 if ($func eq "in")
 {
   print "insert mem stick in USB port, type \'y\' when ready:";
   $ans = <STDIN>;  $ans =~ /^(.*)$/;  $ans = $1;  # untaint
   chomp $ans;  exit(4) if $ans ne "y";
   system("devfsadm -C");
   $dev = `ls -l /dev/dsk/*s2 | awk '/usb/{print \$9}'`;
   $dev =~ /^(.*)$/;  $dev = $1;		# untaint
   if ($dev !~ "/dev/dsk/c[0-9]t[0-9]d[0-9]s2")
   { print "ERROR: can't find name \"$dev\" in USB!\n";  exit 8; }
   $ret = system("mount $dev /memstik");  $ret /= 256;
   if ($ret != 0)
   { print "ERROR: cannot mount /memstik, exiting\n";  exit 12; }
   print "memory stick device $dev mounted on /memstik.\n";
 }
 if ($func eq "out")
 {
   $ret = system("umount /memstik");  $ret /= 256;
   print "WARNING: cannot unmount /memstik, continuing\n" if $ret != 0;
   print "remove mem stick from USB port, type \'y\' when ready:";
   $ans = <STDIN>;  $ans =~ /^(.*)$/;  $ans = $1;  # untaint
   chomp $ans;  exit(16) if $ans ne "y";
   system("devfsadm -C");
 }

 sub usage()
 {
   print "usage:\"memstik in\" to bring memory stick into system on /memstik\n";
   print "      \"memstik out\" to take memory stick out of system\n";
 }





##############################################################################
### This script is submitted to BigAdmin by a user of the BigAdmin community.
### Sun Microsystems, Inc. is not responsible for the
### contents or the code enclosed. 
###
###
### Copyright 2007 Sun Microsystems, Inc. ALL RIGHTS RESERVED
### Use of this software is authorized pursuant to the
### terms of the license found at
### http://www.sun.com/bigadmin/common/berkeley_license.html
##############################################################################


