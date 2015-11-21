#!/bin/ksh
# 
# Title: bkup_mounted_fs.ksh
# Description: This script will backup mounted filesystems only.
# Submitter Name: Erick Boongaling
# Submitter EMail: erick.boongaling@ros.com
# Submitter Company: Ross Stores, Inc.
#

fs_list=`df -k|grep "^/dev/dsk/"|awk '{print $6}'"`

for filesystem in $fs_list
do
    ufsdump 0ufl /dev/rmt/0n $filesystem
done  
