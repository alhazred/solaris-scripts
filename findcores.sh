#!/bin/ksh
# find core dumps and mail file info to root
# Des Warren, Paul Warren
# 7/3/01
### findcores.sh does a search for core files, runs a file 
### command on them to see which program created the core, 
### and mails the results before deleting the core.
###
### Submitter Name: Des Warren
### Submitter Email: dwarren@symantec.com

### Find the core files
find / -name core -type f > /tmp/cores$$

function mailcores
{
  for i in $( </tmp/cores$$ )
  do
    echo "" >> /tmp/mailcores
    file $i >> /tmp/mailcores
    echo "" >> /tmp/mailcores
    rm $i
  done
  mailx -s "core on `uname -n` " root < /tmp/mailcores
  rm /tmp/mailcores
  rm /tmp/cores$$
}

[[ -s /tmp/cores$$ ]] && mailcores


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


