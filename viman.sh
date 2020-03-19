#!/bin/sh

#####################
# @(#)viman: $version 1.1 blh$
# 
# View man page in favorite editor
# Uses $EDITOR env var.
#
# Usage: viman <man_page_to_view>
#####
TMP=/tmp/.myman$RANDOM
rm -rf $TMP
man $* 2>&1 | col -b | unexpand -a > $TMP
if [ `wc -l $TMP | sed 's/^ *//' | cut -d" " -f1` -lt 4 ];then
   cat $TMP | tr '\t' ' ' | sed -e 's/ man /       viman /' -e 's/:
viman/: viman/'
else
   $EDITOR $TMP
fi
rm -f $TMP
#####################





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


