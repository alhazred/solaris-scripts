#!/bin/ksh

##
## search_dir
##
## A script that takes exactly 2 arguments:
##  A pattern and a directory
## Returns for each file that contains the pattern 
## the file name and the line number containing the pattern.
##
## Example:
## search_dir unix  /home/aetinger
## /home/aetinger/foo
##   2: unix is a general purpose operating system
##   6: unix is registered trademark
## /home/aetinger/test/junk
##   3: unix has over 100 utilities
##   17: like unix, linus is a moder operating system
##
##
## Alex Etinger
## aetinger@yahoo.com
##

#!/bin/ksh


if [[ $# -ne 2 ]]
then
        echo "Usage: $0 pattern directory"
        return 1
fi


list=$(find $2 -name "*" -type f -print)
cd $2

for item in $list
do
        item=${item#*/}
        item=/$item

        #echo $item
        #echo $PWD
        item=$PWD$item
        #echo $item

        grep -l $1 $item
        grep -n $1 $item

done

exit 0;


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


