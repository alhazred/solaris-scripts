#!/bin/sh

#==================================================
#
#    diskinfo.sh -- Captures physical disk partition info and dumps
#    to screen
#
#    Written by J.J.Smith 170804
#
#==================================================
#
#    This script is inspired by:
#
#    SysAudit/SysConfig -- Capture UNIX machine information
#    Copyright (C) 1997  David J. Young <davidy@pencom.com>
#
#    SysAudit/SysConfig is free software; it can redistributed and/or modified
#    under the terms of the GNU General Public License as published by
#    the Free Software Foundation; either version 2 of the License, or
#    (at your option) any later version. See the GNU General Public License
#    for more details.
#
#    You should have received a copy of the GNU General Public License
#    along with this program; if not, write to the Free Software
#    Foundation, Inc., 675 Mass Ave, Cambridge, MA 02139, USA.
#
#===================================================
#
#    This script is distributed in the hope that it will be useful,
#    but comes without any waranty; the author will not be held liable for
#	any mishappenings.
#
#====================================================


echo "\n\n\n"
DISKS=`ls /dev/rdsk | cut -d"s" -f1 | sort | uniq`

Showpart()
{
format $i << __WWJD__
c
p
p
q
q
R
__WWJD__
}

for i in $DISKS
do
Showpart > /tmp/disk-info.$i
head -24 /tmp/disk-info.$i > /tmp/sysaudit-disk-info.$i
tail -2 /tmp/sysaudit-disk-info.$i > /tmp/sysaudit2-disk-info.$i
tail -34 /tmp/disk-info.$i > /tmp/audit-disk-info.$i
head -13 /tmp/audit-disk-info.$i > /tmp/sysaudit-disk-info.$i
tail -10 /tmp/sysaudit-disk-info.$i > /tmp/audit-disk-info.$i
echo
echo =======================
echo $i partition table:
echo =======================
echo
cat /tmp/sysaudit2-disk-info.$i
echo
cat /tmp/audit-disk-info.$i
echo
done

rm /tmp/sysaudit-disk-info.*
rm /tmp/audit-disk-info.*
rm /tmp/sysaudit2-disk-info.*
rm /tmp/disk-info.*












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


