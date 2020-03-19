#!/bin/ksh

# Quick script by rotten to report the MAC addresses on the server.

PATH=$PATH:/usr/sbin; export PATH

hostname=`hostname`

# We are only interested in devices that are configured on boot.

for nic in `ls /etc/hostname.*`
do

# Get the device name.
nicbit=`echo $nic | cut -d. -f2`

# This doesn't work very well on IPMP hosts where there is all sorts
# of extra garbage in the hostname file:
#nichost=`cat /etc/hostname.$nicbit`

# So instead we glean the IP address for the interface from ifconfig:
nicip=`ifconfig $nicbit | grep inet | awk '{ print $2 }'`

# Then we grab the first hostname from /etc/hosts with that IP address.
# It had better be in /etc/hosts - local interfaces are usually there and
# not stashed off box in a name service...
nichost=`grep $nicip /etc/hosts | grep -v "^#" | head -1 | awk '{ print $2 }'`

# There seems to be the occaisional case where the IP is not in /etc/hosts,
# but set directly in /etc/hostname.xxx.
# In this case the arp table probably lists the interface by IP rather than
# hostname.
if [[ -z $nichost ]]
then
nichost=$nicip
fi


# This line is just to see if we are doing ok so far.
#printf "DEBUG --> nicbit=%s\tnicip=%s\tnichost=%s\n" $nicbit $nicip $nichost

# Now we snag the MAC address from the arp table.
macbit=`arp -a | grep $nichost | head -1 | awk '{ print $5 }'`

# And neatly format the results. The "...." are so that the columns line up
# without too much white space.
printf "%s\t%s\t.... %s \n" $hostname $nicbit $macbit

done
