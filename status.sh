#!/bin/ksh
#
# Solaris System Status Script
# Purpose: Produces a report with uptime, disk space,
# current and past logins, who has used the su
# command, interface and network configurations, and
# the current processes running.
# Usage: Execute from the command line or crontab (daily)
# Dependencies: /opt/admin/scripts/hrdwspecs.sh
# (included below)
# Outputs: E-mail
#
## Submitter Email: gideon@infostruct.net
#*******************************************

PATH=/usr/bin:/usr/sbin:/usr/ucb:/bin

SRVNM=`uname -n`

HOSTNAME=`uname -n`

function system_status
{
print "\nStatus Taken at: "`date`
print "\n\n"
echo "$SRVNM up for: "`uptime | awk '{ print $3 , $4 }`
print "\n\n"
echo 'Checking how Full the File Systems are:\n'
df -k
#print '\n\nChecking Backups:\n'
#cat /etc/dumpdates
#print '\n\nChecking Legato Backups:'
#for i in / /usr /var /opt /export/home /opt/tng /app
#do
#echo "\n$i:"
#echo " ssid        date   volume           lvl"
# mminfo -s legserv -c $HOSTNAME -r 'savetime,volume,level' -q name=$i
-t'1 week ago' -ot
#done
#The next 3 items are specific to Oracle databases
#print '\n\nAre the Oracle Databases up?:\n'
#ps -ef | grep [o]ra_
#print '\n\nAre the Oracle Listeners up?:\n'
#ps -ef | grep -i [l]istener
#ps -ef | grep [o]rasrv
#The next 2 items are specific to Sybase databases
#print '\n\nAre the Sybase Databases up?:\n'
#ps -ef | grep [d]ataserver
#ps -ef | grep [b]ackupserver
#print '\n\nChecking Print Queues:\n\n'
#lpstat -o
#print '\n\nChecking Printer Status:\n\n'
#lpstat -t
print '\n\nWho has Switched Users?:\n\n'
tail -20 /var/adm/sulog
print '\n\nWho Last Logged into the System?:\n\n'
last | head -20
print '\n\nWho is Currently Logged on?:\n\n'
who -a | head -20
print '\n\nNetwork Interface Status:\n\n'
netstat -i
print "\n\n"
ifconfig -a
print '\n\nNetwork Status:\n'
netstat -rn
print '\n\nHow Many Messages are in the Mail Queue?:\n\n'
#ls /usr/spool/mqueue | wc -l
mailq
print "\n"
#Call the hardware specifications script
/opt/admin/scripts/hrdwspecs.sh
print '\nProcesses Currently Running:\n\n'
ps -ef
print '\n\nSYSTEM STATUS COMPLETE\n\n'
# End system_status function
}

if [ -z "$1" ]; then

system_status

else

           mail $1 <<EOF
From: $0
To: $1
Subject: System Status for $SRVNM
`system_status`

EOF

fi
exit 0

# more /opt/admin/scripts/hrdwspecs.sh
#!/bin/ksh
#
# Solaris Hardware Specifications Script
# Purpose: Creates statistics for disk space, CPU, and
# memory
# Usage: Called by status.sh
# Dependencies: None
# Outputs: Standard out
#
#***************************************************************

PATH=/usr/bin:/usr/sbin
DATE=`date '+%m-%d-%y%n'`

SVRNM=`uname -n`

# Ensure that temp files get cleaned up upon exit
trap '/bin/rm -fr $tmp; exit' 0 1 2 3 15
WRKFILE=/tmp/prog$$

df -k >> $WRKFILE

# Delete the first line and swap entry

{
vi $WRKFILE <<EOF
:1
dd
/swap
dd
:wq!
EOF
} > /dev/null

# If the cdrom drive is mounted, delete its entry too

CDR=`cat $WRKFILE | grep -c cdrom`

if [ "$CDR" -gt "0" ]; then

{
vi $WRKFILE <<EOF
/cdrom
dd
:wq!
EOF
} > /dev/null

fi

integer KTOTL=0
integer KUSED=0
integer KAVAIL=0

while read -r FS TOTL USED AVAIL CAP MNT
do

if [ "$TOTL" -gt "0" ]; then
((KTOTL = KTOTL + TOTL))
fi

if [ "$USED" -gt "0" ]; then
((KUSED = KUSED + USED))
fi

if [ "$AVAIL" -gt "0" ]; then
((KAVAIL = KAVAIL + AVAIL))
fi

done < $WRKFILE

# Translate KB to GB
((GTOTL = KTOTL / 1048576))
((GUSED = KUSED / 1048576))
((GAVAIL = GTOTL - GUSED))

echo " "
echo "$SVRNM Total Disk Space Usage:"
echo " "
echo "GB                USED            AVAIL"
echo "-----------------------------------------"
echo "$GTOTL            $GUSED          $GAVAIL"
echo " "
echo " "
echo "$SVRNM CPU Specifications:"
echo " "
/usr/platform/`arch -k`/sbin/prtdiag | grep Configuration | awk {'print
$9,$10,$11,$12'}
echo " "
echo " "
echo "$SVRNM Memory Specifications:"
echo " "
/usr/platform/`arch -k`/sbin/prtdiag | grep 'Memory size' | awk {'print
$3,$4'}
echo " "
echo " "

rm $WRKFILE
exit 0




##############################################################################
### This script is submitted to BigAdmin by a user of the BigAdmin community.
### Sun Microsystems, Inc. is not responsible for the
### contents or the code enclosed. 
###
###
### Copyright 2008 Sun Microsystems, Inc. ALL RIGHTS RESERVED
### Use of this software is authorized pursuant to the
### terms of the license found at
### http://www.sun.com/bigadmin/common/berkeley_license.html
##############################################################################


