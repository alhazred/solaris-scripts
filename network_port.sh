#!/bin/sh
# Set 100/Full script
#
sh
ndd -set /dev/eri instance 0
ndd -set /dev/eri adv_autoneg_cap 0
ndd -set /dev/eri adv_100hdx_cap 0
ndd -set /dev/eri adv_100fdx_cap 1
for i in 0 1 2 3 4 5 6 7
do
  ndd -set /dev/qfe instance $i
  ndd -set /dev/qfe adv_autoneg_cap 0
  ndd -set /dev/qfe adv_100hdx_cap 0
  ndd -set /dev/qfe adv_100fdx_cap 1
done



#!/bin/sh
# View config
#
echo ==== eri0 ====
ndd -set /dev/eri instance 0
echo "link status = `ndd -get /dev/eri link_status`"
echo "link mode   = `ndd -get /dev/eri link_mode`"
echo "link speed  = `ndd -get /dev/eri link_speed`"
for i in 0 1 2 3 
do
  echo ==== qfe$i ====
  ndd -set /dev/qfe instance $i
  echo "link status = `ndd -get /dev/qfe link_status`"
  echo "link mode   = `ndd -get /dev/qfe link_mode`"
  echo "link speed  = `ndd -get /dev/qfe link_speed`"
done







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


