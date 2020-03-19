#!/bin/csh

### nisgrp.info.csh
###
### This script finds a (NIS+) group and shows who is a member 
### of that group.
### 
###
### Submitted By: Marc Jacquard
###               Marc.Jacquard@firstdatacorp.com

set gname = $1

if ("$1" == " ") then
        echo USAGE: nisgrp.info "<"group name">"
else

set answer = `niscat group.org_dir|grep "^$1"|awk -F":" '{print "Group
Name""="$1" ""GID""="$3" ""Members""="$4}'`
set count = `echo $answer|wc -c`

if ( "$count" != "0" ) then
     echo $answer
else
     echo There is no group with that name.
endif







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


