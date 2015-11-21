#!/bin/sh
# David K McWilliams, 2002

# Runs with no command line modifiers 

# It will tell you the machine hostname & hostnames, ip addresses, subnet masks
# broadcast addresses, default gateways for each interface, real or virtual &
# DNS servers & host resolution order for the machine

# I use it as a good summary of machine network settings

PATH=/usr/sbin:/usr/bin

getinfo()
{
    IFACE=$1
    ADDR=`ifconfig $1| grep inet`
    IP=`echo $ADDR| awk '{ print $2 }'`
    if [ $IP ]
    then
        HOSTNAME=`cat /etc/hostname.$IFACE`
        hex2dec `echo $ADDR| awk '{ print $4 }'`
        BCAST=`echo $ADDR| awk '{ print $6 }'`
        DEFGW=`netstat -nr| grep '^'default| awk '{ print $2 }'`
	if [ -n $DEFGW ]
	then
	    :
        else
	    DEFGW="not set"
        fi
        echo "   $IFACE ($HOSTNAME) - $IP | $NETMASK | $BCAST - gw $DEFGW"
    else
        echo "   $IFACE is not configured"
    fi
}

hex2dec()
{
    NETMASK=$1
    first=`echo $NETMASK| cut -c1-2|tr "[:lower:]" "[:upper:]"`
    FIRST=`echo "ibase=16; $first"| bc`

    second=`echo $NETMASK| cut -c3-4|tr "[:lower:]" "[:upper:]"`
    SECOND=`echo "ibase=16; $second"| bc`

    third=`echo $NETMASK| cut -c5-6|tr "[:lower:]" "[:upper:]"`
    THIRD=`echo "ibase=16; $third"| bc`

    fourth=`echo $NETMASK| cut -c7-8|tr "[:lower:]" "[:upper:]"`
    FOURTH=`echo "ibase=16; $fourth"| bc`
    NETMASK=$FIRST.$SECOND.$THIRD.$FOURTH
}

echo "   Hostname - `hostname`"
for INTERFACE in `ifconfig -a| grep -v lo0| grep flags| awk '{ print $1 }'`
do
    IFACESZ=`echo $INTERFACE| wc -c`
    SIZE=`expr $IFACESZ - 2`
    IFACE=`echo "$INTERFACE"| cut -c1-$SIZE`
    getinfo $IFACE
done

printf "   DNS servers -"
for NSERVER in `grep nameserver /etc/resolv.conf| awk '{ print $2 }'`
do
    printf " $NSERVER"
done

printf "   Resolution Order -"
NUMFIELDS=`grep '^'hosts /etc/nsswitch.conf| awk '{ print NF }'`
count=2
while [ $count -le $NUMFIELDS ]
do
    FIELD=`grep '^'hosts /etc/nsswitch.conf| awk '{ print $"'$count'" }'`
    printf " $FIELD"
    count=`expr $count + 1`
done
echo
