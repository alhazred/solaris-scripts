#!/bin/ksh
# This script will convert the gregorian date to julian date. script take date as a parameter.
# Usage: $0 -G <yyyy-mm-dd>
# -G : gregorian calendar date to julian date 
# the formula used for computing julian date from year, month and day in gregorian calendar is 
# for 0 hours GMT, on that date :-
# JD=367Y - INT(7(Y+INT((M+9)/12))/4)
#         - INT(3(INT((Y+(M-9)/7)/100)+1)/4)
#         + INT(275M/9)+D+1721028.5)
# INT denote the integer part, M for month, Y for year and D for day.
# The program will also convert the calculated julian date again into gregorian date. for reverse
# check.
# some sample conversion :
# 1990-07-01 2448073.5
# 1994-02-01 2449484.5
# 1999-11-01 2451483.5
# 2000-01-01 2451544.5
#
#
# NOTE - IMPORTANT: For Solaris this requires 'gawk' instead of 'awk'
#   for the lack of '-v' in /bin/awk on Solaris.
#   To run under other flavors of Unix, you should be able to replace
#   '/usr/local/bin/gawk' with 'awk'.

[ $# -lt 2 ] && echo "Usage: $0 -G <yyyy-mm-dd>" && exit 1

# assign the date and populate the year, month and day

dt=$2
y=$(echo $dt|cut -d"-" -f1)
m=$(echo $dt|cut -d"-" -f2)
d=$(echo $dt|cut -d"-" -f3)

# start computing the JD

a=$((367*$y))
x=$(($(($m+9))/12))
h=$(($y+$x))
i=$((7*$h))
k=$(($i/4))

c=$(($((3*$(($(($(($y+$(($(($m-9))/7))))/100))+1))))/4))

e1=$(($(($((275*$m))/9))+$d+1721028.5))
e=$(($((275*$m))/9))



JD=$(echo|/usr/local/bin/gawk -v a1=$a -v a2=$k -v a3=$c -v a4=$e -v a5=$d '{ x=a1-a2-a3+a4+a5+1721028.5; printf("%.1f\n",x);}')

echo "\n====================================="
echo "Julian date: $JD"

#
#The code from here onward convert julian date to gregorian date. reverse computation. 
#

Z=$(echo|/usr/local/bin/gawk -v x1=$JD '{x=x1+0.5; printf("%d",x)}')
W=$(($(($Z - 1867216.25))/36524.25))
X=$(($W/4))
A=$(($Z+1+$W-$X))
B=$(($A+1524))
C=$(echo|/usr/local/bin/gawk -v x1=$B '{x=(x1-122.1)/365.25; printf("%d",x)}')
D=$(echo|/usr/local/bin/gawk -v x1=$C '{x=x1*365.25; printf("%d",x)}')
E=$(echo|/usr/local/bin/gawk -v x1=$B -v x2=$D '{x=(x1-x2)/30.6001; printf("%d",x)}')
F=$(echo|/usr/local/bin/gawk -v x1=$E '{x=30.6001*x1; printf("%d",x)}')

DAY=$(($B-$D-$F))

#MON = E-1 or E-13 (must get number less than or equal to 12)
MON=$(($E-13))
if [ $MON -lt 1 ] || [ $MON -gt 12 ]
then
   MON=$(($E-1))
fi

if [ $MON -eq 1 ] || [ $MON -eq 2 ]
then
   YEAR=$(($C-4715)) # if Month is January or February
else
   YEAR=$(($C-4716)) # otherwise
fi

echo "Gregorian Date:"
echo "Day : $DAY"
echo "Mon : $MON"
echo "Year : $YEAR"
echo ""

exit 0


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


