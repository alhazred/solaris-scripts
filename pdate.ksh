#!/usr/bin/ksh
#
# Name         : pdate.ksh
# Purpose      : Get the previous system date
#                This script handles leap year properly and is Y2K compliant
# Author       : Wyatt Wong
# E-mail       : wyattwong@yahoo.com
# Last Modified: 28-Nov-2003

DATE='/usr/bin/date'

DEBUG=0                         # Used for testing the pdate.ksh script
if [ ${DEBUG} -ne 0 ]
then
  YEAR=2001                     # YEAR - for DEBUG use
  MONTH=11                      # MONTH - for DEBUG use
  DAY=24                        # DAY - for DEBUG use
  if [ ${MONTH} -lt 10 ]; then MONTH=0${MONTH}; fi
  if [ ${DAY} -lt 10 ]; then DAY=0${DAY}; fi
else
  YEAR=`${DATE} '+%Y'`          # Get System Year
  MONTH=`${DATE} '+%m'`         # Get System Month
  DAY=`${DATE} '+%d'`           # Get System Day
fi

# Start of main program

((DAY=DAY-1))                   # Decrement DAY by 1
  
# Perform adjustment to DAY, MONTH or YEAR if necessary

if [ ${DAY} -eq 0 ]             # Check if prev DAY wrap to the end of prev month 
then
  ((MONTH=MONTH-1))             # Decrement MONTH by 1 
  case ${MONTH} in
    0) DAY=31 MONTH=12          # MONTH is 0, set the date to 31 Dec of prev year
       ((YEAR = YEAR - 1));;    # and decrement YEAR by 1
    1|3|5|7|8|10|12) DAY=31;;   # Set DAY to 31 for large months
    4|6|9|11) DAY=30;;          # Set DAY to 30 for small months
    2) DAY=28                   # Set DAY to 28 for Feb and check for leap year
       ((R1 = ${YEAR}%4))       # Get remainder of YEAR / 4
       ((R2 = ${YEAR}%100))     # Get remainder of YEAR / 100
       ((R3 = ${YEAR}%400))     # Get remainder of YEAR / 400

       # A leap year is:
       # EITHER divisible by 4 and NOT divisible by 100
       # OR     divisible by 400
       #
       # So there are 97 leap years in 400 years period, century years 
       # that are not divisible by 400 are NOT leap years.
       
       if [ ${R1} -eq 0 -a ${R2} -ne 0 -o ${R3} -eq 0 ]
       then
         ((DAY=DAY+1))         # Add 1 day to February if it is a leap year
       fi;;
  esac

  # Prepend a ZERO if MONTH < 10 after it was decremented by 1
  #
  # Note that if there is no calculation on MONTH, it will have 2 digits
  # such as 01, 02, 03, etc. So there is no need to prepend ZERO to it

  if [ ${MONTH} -lt 10 ]
  then
    MONTH=0${MONTH}
  fi

# Prepend a ZERO if DAY < 10 after it was decremented by 1
elif [ ${DAY} -lt 10 ]
then
  DAY=0${DAY}
fi

print ${YEAR}${MONTH}${DAY}