#!/bin/ksh
#=========================================#
# Net statistics for Solaris 2.x via kstat
# by Michael Roth (michael.roth@upc.at), 2004
VERS=0.3
# Output for:
# -l ... Link Status
# -ip ... Incomming Packets
# -op ... Outgoing Packets
# -c ... Collisions
# -ips ... Incomming Packets per Second
# -rbs ... Received Kbytes per Second
# -ops ... Outgoing Packets per Second
# -obs ... Outgoing Kbytes per Second
# -ie ... Incomming Errors
# -oe ... Outgoing Errors
# -is ... Interface Speed
# -a ... All Infos for Interface
# -as ... All Infos for all Interfaces
#=========================================#

if [ "$#" -ne "2" -a ! "$1" = "-as" ]; then
 echo "$0 Version $VERS"
 echo "Usage: $0 -options <interface>"
 echo "\nPlease use the following options:"
 echo " -l ... Link Status"
 echo " -ip ... Incomming Packets"
 echo " -op ... Outgoing Packets"
 echo " -c ... Collisions"
 echo " -ips ... Incomming Packets per Second"
 echo " -rbs ... Received Kbytes per Second"
 echo " -ops ... Outgoing Packets per Second"
 echo " -obs ... Outgoing Kbytes per Second"
 echo " -ie ... Incomming Errors"
 echo " -oe ... Outgoing Errors"
 echo " -is ... Interface Speed"
 echo " -a ... All Infos for Interface"
 echo " -as ... All Infos for all Interfaces"
 exit 1
fi

# Variables
kstat=/usr/bin/kstat
ifconfig=/sbin/ifconfig
grep=/usr/bin/grep
awk=/usr/bin/awk
tr=/usr/bin/tr
ndd=/usr/sbin/ndd
bc=/usr/bin/bc
cut=/usr/bin/cut
wc=/usr/bin/wc
uname=/usr/bin/uname
hostname=`/usr/bin/uname -n`
interface="$2"
interface_inst=`echo "$interface" | $tr -d "[:alpha:]" | $bc`
interface_name=`echo "$interface" | $tr -d "[:digit:]"`

#echo "Interface-Name: $interface_name , Interface-Instance: $interface_inst"

if [ -z "$interface_inst" -a ! "$1" = "-as" ]; then
 echo "Please add the instance to the interface eg. hme0!"
 exit 1
fi

if [ -z "$interface_name" -a ! "$1" = "-as" ]; then
 echo "Please enter a valid interfacename."
 exit 1
fi

if [ ! "$1" = "-as" ]; then
"$kstat" -q "$interface_name" ||
 {
 echo "Interface $interface_name not found on System $hostname!"
 exit 1
 }
fi

#
# Define functions
#
 stat () {
 if [ -z "$interface" ]; then
  echo "Error - Interface not defined!"
  exit 1
 fi
 value=`$kstat $interface_name:$interface_inst:$interface:$option | grep "$option" | $tr -s " " | $cut -d " "  -f 2 | $bc`

 exit_stat="$?"
 }

 stat_calc () {
 if [ -z "$interface" ]; then
  echo "Error - Interface not defined!"
  exit 1
 fi
 result=`$kstat $interface_name:$interface_inst:$interface:$option 1 2 | grep $option | tr -s " " | cut -d " " -f 2 | tr "\n" " " | $awk '{ printf ("%d", ($2-$1)/1024 ) }'`

 exit_stat="$?"
 }

#
# Main
#

case "$1" in
 "-l")
  # Link status
  option=link_up
  stat
  echo "Interface $2 $option value is $value."
  exit "$exit_stat"
 ;;

 "-ip")
  # Incomming packets
  option=ipackets
  stat
  echo "Interface $2 has $value $option."
  exit "$exit_stat"
 ;;

 "-op")
  # Outgoing packets
  option=opackets
  stat
  echo "Interface $2 has $value $option."
  exit "$exit_stat"
 ;;

 "-c")
  # Collisions
  option=collisions
  stat
  echo "Interface $2 $option value is $value."
  exit "$exit_stat"
  ;;

  "-ips")
  # Incomming packets per second
  option=ipackets
  stat_calc
  echo "Interface $2 $option has $result packets/s."
  exit "$exit_stat"
  ;;

  "-rbs")
  # Received Kbytes per second
  option=rbytes
  stat_calc
  echo "Interface $2 $option has $result Kbyte/s."
  exit "$exit_stat"
  ;;

  "-ops")
  # Outgoing packets per second
  option=opackets
  stat_calc
  echo "Interface $2 $option has $result packets/s."
  exit "$exit_stat"
  ;;

  "-obs")
  # Outgoing Kbytes per second
  option=obytes
  stat_calc
  echo "Interface $2 $option has $result Kbyte/s."
  exit "$exit_stat"
  ;;

  "-ie")
  # Incomming errors
  option=ierrors
  stat
  echo "Interface $2 $option value is $value."
  exit "$exit_stat"
  ;;

  "-oe")
  # Outgoing Errors
  option=oerrors
  stat
  echo "Interface $2 $option value is $value."
  exit "$exit_stat"
  ;;

  "-is")
  # Interface Speed
  option=ifspeed
  stat
  echo "Interface $2 $option value is $value."
  exit "$exit_stat"
  ;;

  "-a")
  # All info for the interface
  i=$2
  option=ipackets
  stat_calc
  echo "Interface $i $option has $result packets/s."

  option=rbytes
  stat_calc
  echo "Interface $i $option has $result Kbytes/s."

  option=opackets
  stat_calc
  echo "Interface $i $option has $result packets/s."

  option=obytes
  stat_calc
  echo "Interface $i $option has $result Kbytes/s."

  option=collisions
  stat
  echo "Interface $i $option value is $value."

  option=ierrors
  stat
  echo "Interface $i $option value is $value."

  option=oerrors
  stat
  echo "Interface $i $option value is $value."

  option=ifspeed
  stat
  echo "Interface $i $option value is $value."

  option=link_duplex
  stat
  echo "Interface $i $option value is $value."

  option=link_up
  stat
  echo "Interface $i $option value is $value."

  echo "==="
  ;;

  "-as")
   # All info - output for all interfaces on the system
   echo "\nOutput for all Interfaces:\n"
   Interfaces=`$ifconfig -a | $grep "flags=" | grep -v "LOOPBACK" | $awk ' { printf $1 "\n" } ' | $tr -d ":"`
  
   for i in $Interfaces
   do
    interface_inst=`echo $i | $tr -d "[:alpha:]" | $bc`
    interface_name=`echo $i | $tr -d "[:digit:]"`
    interface=$i

    option=ipackets
    stat_calc
    echo "Interface $i $option has $result packets/s."

    option=rbytes
    stat_calc
    echo "Interface $i $option has $result Kbytes/s."

    option=opackets
    stat_calc
    echo "Interface $i $option has $result packets/s."

    option=obytes
    stat_calc
    echo "Interface $i $option has $result Kbytes/s."

    option=collisions
    stat
    echo "Interface $i $option value is $value."

    option=ierrors
    stat
    echo "Interface $i $option value is $value."

    option=oerrors
    stat
    echo "Interface $i $option value is $value."
    
    option=ifspeed
    stat
    echo "Interface $i $option value is $value."

    option=link_duplex
    stat
    echo "Interface $i $option value is $value."

    option=link_up
    stat
    echo "Interface $i $option value is $value."

    echo "==="
   done
  ;;

 *)
 echo "$0 Version $VERS"
 echo "\nUsage: $0 -options <interface>"
 echo "\nPlease use the following options:"
 echo " -l ... Link Status"
 echo " -ip ... Incomming Packets"
 echo " -op ... Outgoing Packets"
 echo " -c ... Collisions"
 echo " -ips ... Incomming Packets per Second"
 echo " -rbs ... Received Kbytes per Second"
 echo " -ops ... Outgoing Packets per Second"
 echo " -obs ... Outgoing Kbytes per Second"
 echo " -ie ... Incomming Errors"
 echo " -oe ... Outgoing Errors"
 echo " -is ... Interface Speed"
 echo " -a ... All Infos for Interface"
 echo " -as ... All Infos for all Interfaces"
 exit 1
 ;;

esac
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


