#!/bin/ksh

### This script may be used to manually mount CDROMS on Sun Boxes
### where Volume Management has been disabled
### disable VOLMGT by /etc/init.d/volmgt stop

### Script Name : mountcd
### Created by  : Priyank Pashine
### Version     : 1.0
### Date        : Wednesday, Sep 8, 2004


### Find how many disks on the box and store it result in /tmp/hdds
echo "0" | format 2>/dev/null >/tmp/temp
ctr=`grep " c.t." /tmp/temp | wc -l`
grep " c.t." /tmp/temp | head -`expr $ctr - 1` | tr -s " " " " | cut -d" " -f3 > /tmp/hdds


### Find out all SCSI Devices on the box and store result in
### /tmp/alldevs
ls /dev/dsk | cut -c1-6 | sort | uniq > /tmp/alldevs


### Where is the CDROM connected?
cddrive=`diff /tmp/hdds /tmp/alldevs | tail -1 | cut -c3-8`


### Finally mount the device
prtvtoc /dev/dsk/${cddrive}s0 | grep -v "^\*" | tr -s " " " " | cut -d" " -f2 >/tmp/numslices
slices=`cat /tmp/numslices | wc -l`

if [ $slices -eq 2 ]
        then mkdir /cdrom/s0 2>/dev/null
        mount -F hsfs -o ro /dev/dsk/${cddrive}s0 /cdrom 2>/dev/null

>>/dev/null

else
        mkdir /cdrom/s0 2>/dev/null
        mount -F hsfs -o ro /dev/dsk/${cddrive}s0 /cdrom/s0 2>/dev/null

>>/dev/null

        for ctr in 1 2 3 4 5
        do
                grep "$ctr" /tmp/numslices >/dev/null 2>/dev/null
                if [ $? -eq 0 ]
                        then mkdir /cdrom/s$ctr 2>/dev/null
                        mount -F ufs -o ro /dev/dsk/${cddrive}s$ctr /cdrom/s$ctr 2>/dev/null >/dev/null
                fi
        done
fi

### Remove all temporary files
#rm /tmp/temp /tmp/alldevs /tmp/hdds /tmp/numslices

########################
###       ENDS       ###
########################





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


