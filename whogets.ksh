#!/bin/ksh

# Author:   C.S. Cupples
# Date:     June 2005
# Purpose:  Recurse NIS mail aliases to determine end recipients

usage () {
  UL=$(tput smul) ul=$(tput rmul)
  print -u2 -- "Usage: ${0##*/} ${UL}alias${ul} [ ${UL}alias${ul} ... ]"
  exit
}

whogets () {
  for rcpt in $*
  do ypmatch $rcpt aliases 2>&1 > /dev/null | head -1
  done | sed 's/^.* match key \(.*\) in map .*/\1/'
  rcpt=$(ypmatch $* aliases 2> /dev/null | sed 's/,//g')
  [[ -n $rcpt ]] && whogets $rcpt
}

(( $# == 0 )) && usage

whogets $* | sort -uf




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


