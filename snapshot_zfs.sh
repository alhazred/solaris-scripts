#!/bin/pfsh

#set -x

###################################################################
#
# Version 0.1 5 Apl 07
#     Started from snapshot_ufs.sh 
#
#     GOAL: Have snapshots of / available on my laptop
#           when the zfs_boot code arrives in Nevada
#
###################################################################
#
# Version 0.2 10th April 
#     Added auths code and changed shell 
#     (should back port to snapshot_ufs.sh)
#
###################################################################
#
# Version 1.0 11th April 
#     Added Email and comments and general tidy for release
#
########################## READ ME PLEASE ###################################
#
# Variables: 
#    $FILESYSTEM        = What we are snapping
#    $ADMIN             = Who gets Emailed 
#    $SNAPSHOTS_TO_KEEP = Number snapshots to keep 
#    $TIME_STAMP        = A unquie name for the sanpshot based on the time
#
# Limitations:
#   1. This should prob. use -r in zfs snapshot but I don't neeed this for my goal
#      so if you modify to work with multiple volmues let me know.
#   2. I've only tested on Nevada 58+ should work on Solaris 10 U3 and above.
#   3. I should prob. handle the trailing / but, I don't neeed this
#      for my goal and as zfs boot has not put back I can't test just /
#      but my guess at this time is it will 'just work'.
#
# Bugs etc. to trevor.pretty@sun.com
#
# PLEASE PLEASE change where there is ### CHANGE THIS ###
# I don't want an Email :-)
#
###################################################################
#
#
## Set some variables
#
SCRIPT_NAME=$0
FILESYSTEM=$1
ADMIN="trevor.pretty@sun.com"  	### CHANGE THIS ###
SNAPSHOTS_TO_KEEP=5		### CHANGE THIS ###
TIME_STAMP=`date +%y_%m_%d_%H%M`  


## Declare some commands (just in case PATH is wrong)
#
MAIL=/bin/mailx
ID=/usr/xpg4/bin/id
ZFS=/usr/sbin/zfs

## Usage
# 
Usage()
{
        echo ""
        echo ""
        echo "Usage: $SCRIPT_NAME filesystem "
        echo ""
        echo "Examples"
        echo "		$SCRIPT_NAME / "
        echo "		$SCRIPT_NAME /fred "
	echo ""
	echo "Note: The filesystem cannot have a trailing /"
        echo ""
        exit 1
}

########### Main Part ###################

## Check Usage
#
if [ $# -ne 1 ]; then
	Usage
fi

## See if we have right authorization: Either we are root or allowed to manage ZFS
#
WHO=`/usr/xpg4/bin/id -n -u`
PROF=`/bin/profiles | grep "ZFS File System Management"`
if [ "$PROF" != "ZFS File System Management" ]; then
        if [  "$WHO" != "root"  ]; then
                echo "$SCRIPT_NAME: ERROR: you are not authorized to run this script."
                exit 1
        fi
fi


## Check the filesystem we have is mounted
#
set - `/bin/ls $FILESYSTEM 1>/dev/null 2>&1`
if [ $? -ne 0 ]; then
	echo ""
	echo "ERROR file system $FILESYSTEM is not mounted"
	exit 1
fi

## Check the filesystem we have is ZFS
#
TMP=`zfs mount | grep $FILESYSTEM | awk '{ print $2 }'`
if [ "$TMP" != "$FILESYSTEM" ]; then
	echo ""
	echo "ERROR: File system $FILESYSTEM is not ZFS"
	echo "       or you may have a trailing / in $FILESYSTEM"  
	exit 1
fi

## Get the zpool from the mount point
#
set - `/bin/df -h $FILESYSTEM | grep  $FILESYSTEM`
POOL=$1

## Create a new snapshot of $FILESYSTEM by using the $POOL
#  note: we use the pool as we could have a mount like this
#       Pool                = sap_pool/PRD/sapdata9
#       Mounted $FILESYSTEM = /sapdata9
#
echo ""
echo "Creating zfs snapshot $POOL@$TIME_STAMP"
$ZFS snapshot $POOL@$TIME_STAMP
if [ $? -ne 0 ]; then  
	# We should never see this
	echo ""
	echo "ERROR: Something went wrong with: $ZFS snapshot $POOL@$TIME_STAMP"
	echo "       Did you use a trailing / in $FILESYSTEM  ?"
	echo ""
	echo ""
	exit 1
fi

## Remove anything more than the SNAPSHOTS_TO_KEEP working from the oldest 
#
NUMBER_OF_SNAPSHOTS=`/bin/ls  $FILESYSTEM/.zfs/snapshot/ | wc -l`
while [ $NUMBER_OF_SNAPSHOTS -gt $SNAPSHOTS_TO_KEEP ]; do
	set - `/bin/ls -rt $FILESYSTEM/.zfs/snapshot/`
	OLDEST=$1
	$ZFS destroy $POOL@$OLDEST
	echo ""
	echo "Removed old snaphot $FILESYSTEM/.zfs/snapshot/$OLDEST"
	echo ""
	echo "Current snaphots for $FILESYSTEM"
	/bin/ls  -l $FILESYSTEM/.zfs/snapshot/
	NUMBER_OF_SNAPSHOTS=`/bin/ls $FILESYSTEM/.zfs/snapshot/ | wc -l`
done

#exit 0

## Email the admin 
#
# NOTE: Comment out this whole section if you just use cron
#       or uncomment the exit 0 about this.
#
echo ""  >> /tmp/tmp.$$
echo "Created $POOL@$TIME_STAMP" > /tmp/tmp.$$
echo ""  >> /tmp/tmp.$$
echo "Current snaphots for $FILESYSTEM" >> /tmp/tmp.$$
/bin/ls  -l $FILESYSTEM/.zfs/snapshot/ >> /tmp/tmp.$$
echo ""  >> /tmp/tmp.$$  
/bin/cat /tmp/tmp.$$ | $MAIL -r $ADMIN  -s "OK from $SCRIPT_NAME" $ADMIN
/bin/rm /tmp/tmp.$$  # Be a tidy kiwi :-)

exit 0







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


