#!/usr/bin/ksh
#-----------------------------------------------------------------------#
# SQG - Sendmail Queue Groomer
#
#       David G. Sullivan
#       dsullivan@grapevinesolutions.com
#       12/28/2003
#
#  Description:
#  A very simple script to keep normal sendmail queues clear of
#  undeliverable email.  Undeliverable email is moved to a separate
#  queue (morgue-queue) for processing from cron. Mail in the
#  morgue-queue is removed after X attempts at delivery.
#
#
#  Add the below command in cron to run every 30 minutes to process mail
#  in the morgue directory with a separate queue runner.
#
#  /usr/lib/sendmail -q -O QueueDirectory=/var/spool/mqueue/morgue-queue
#-----------------------------------------------------------------------#

#-----------------------------------------------------------------------#
# Operating parameters
#-----------------------------------------------------------------------#
integer queue_max=10    # Max delivery attempts for normal mail before
                                      # moving mail to morgue directory.

integer morgue_max=15   # Max delivery attempts for morgue mail before
                                       # deleting mail message.


#-----------------------------------------------------------------------#
# Command locations
#-----------------------------------------------------------------------#
SENDMAIL=/usr/lib/sendmail
DATE=/usr/bin/date
GREP=/usr/bin/grep
CUT=/usr/bin/cut
MV=/usr/bin/mv
RM=/usr/bin/rm
LS=/usr/bin/ls

#-----------------------------------------------------------------------#
# Directory locations
#-----------------------------------------------------------------------#
Mail_Queues="/var/spool/mqueue/queue-1,/var/spool/mqueue/queue-2,/var/spool/mqueue/queue-3"
Mail_Morgue=/var/spool/mqueue/morgue-queue

#-----------------------------------------------------------------------#
# Log file for morgue transactions (Mail delivery is still in syslog)
#-----------------------------------------------------------------------#
logfile=/var/log/morgue.log

#-----------------------------------------------------------------------#
# Check Mail Queues
#-----------------------------------------------------------------------#
IFS=","
for x in $Mail_Queues
 do

    for y in $($LS $x|$GREP ^qf*)
      do

         integer delv_attempts=$($GREP ^N $x/$y|$CUT -c 2-5)
         msgid=$(echo $y|$CUT -c 3-35)
         date=$($DATE)
         To=$($GREP ^rRFC822 $x/$y|awk '{print $2}')
         if (test $delv_attempts -ge $queue_max) then
           echo $date", MSGID: "$msgid" Moved, "$To >> $logfile
           $MV $x/qf$msgid $Mail_Morgue
           $MV $x/df$msgid $Mail_Morgue
         fi

      done
 done
IFS=" "

#-----------------------------------------------------------------------#
# Check Morgue Mail Queue
#-----------------------------------------------------------------------#
for y in $($LS $Mail_Morgue|$GREP ^qf*)
  do

      integer delv_attempts=$($GREP ^N $Mail_Morgue/$y|$CUT -c 2-5)
      msgid=$(echo $y|$CUT -c 3-35)
      date=$($DATE)
      To=$($GREP ^rRFC822 $Mail_Morgue/$y|awk '{print $2}')
      if (test $delv_attempts -ge $morgue_max) then
          echo $date", MSGID: "$msgid" Removed, "$To >> $logfile
          $RM $Mail_Morgue/qf$msgid
          $RM $Mail_Morgue/df$msgid
      fi

  done





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


