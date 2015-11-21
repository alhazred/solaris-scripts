#!/bin/sh

## Title:		df-sum
##
## Submitter:		Art Mulder
## Submitter Email:	amulder@irus.rri.on.ca
##
## A short script that runs "df" and totals up the results. 
## print results as: Hostname, Megabytes Avail, Megabytes Used
##
## -- Art Mulder, Jun2001
##
## - 4.Mar.2002 - tweak the awk line to elimnate the need for grep.
##       submitted by Carl.Marino@coutts.com 
##
## Example Output:
##  hostname.nowhere.com 37038 MB, 16058 MB used
      
hostnm=`hostname`

# We need to allow for different versions of 'df' on differt Unix OS's
ostype=`/bin/uname`
#echo $ostype
if [ $ostype = "Linux" -o $ostype = "SunOS" ]; then
  dfbinary="/bin/df -kl"
elif [ $ostype = "IRIX64" ]; then       ## Newer SGI's.  Irix 6.5 at least
  dfbinary="/bin/df -Pkl"
else                                    ## use the GNU version of df
  dfbinary="/irus/bin/df"
fi

##disksum=`$dfbinary | grep dev | awk '{t += $2; u += $3} \
disksum=`$dfbinary | awk '/dev/ {t += $2; u += $3} \
        END { printf("%d MB, %d MB used",t/1024,u/1024) }'`

echo $hostnm $disksum

# -- END --



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


