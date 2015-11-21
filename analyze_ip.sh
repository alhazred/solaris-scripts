#!/bin/sh

# --------------------------------------------------------------- #
#
# analyze_ip.sh Version 1.5
#
# Written by Martin Allert, arago AG, Germany
# Contact & Bugfixes: allert@arago.de
#
# This script analyzes your TCP/IP stack settings and your
# NIC configurations. The value in brackets are recommendations.
# Most of these settings are recommended for security reasons.
#
# Version 1.0 of this script analyzes only the first hme instance, until
# I found out, how to get all NIC's with their instances directly from
# the kernel and not from this unsafe dmesg command. :)
#
# Turn the VAL definition containing ndd from -get to -set and you 
# have a bootscript. Of course, comment out all settings at the end for the
# link partner queries :)
#
# Distribution of this script is only allowed 'as it is'.
#
# --------------------------------------------------------------- #

# --------------------------------------------------------------- #
# Some useful definitions                                         #
# --------------------------------------------------------------- #

UREVISION="`uname -r`"

# Static Definitions
BOLD="\033[1m"
NORMAL="\033[m"
ULINE="\033[4m"
RED="\033[31m"
YELLOW="\033[33m"
GREEN="\033[32m"

PREFIX=""
NICDEV=""
NICS="hme qfe eri"

# --------------------------------------------------------------- #
# We like Redhat, so we print it like their bootscripts :)        #
# --------------------------------------------------------------- #

fill () {
awk '{leninput=length($($NF)); fill=63-leninput ; for (i=1; i< fill; i++) fillchar=fillchar"." ; printf $($NF) fillchar}'
}

# --------------------------------------------------------------- #
# Walking network adapters
# --------------------------------------------------------------- #
echo
printf "${BOLD}${ULINE}1. Step: Walking network adapters${NORMAL}\n"
echo
printf "Searching for network devices " | fill

for NIC in ${NICS}
do
	ndd -get /dev/${NIC} \\? > /dev/null 2>&1
	returncode=$?
	
	# due to a bug in Solaris 7, ndd returns with error 12, although ndd
	# found the hme device
	if ( [ "${NIC}" = "hme" ] && [ "${UREVISION}" = "5.7" ] && [ ${returncode} -eq 12 ] )
	then
		returncode=0
	fi

	if [ ${returncode} -eq 0 ]
	then
		printf " ${BOLD}${NIC}${NORMAL}"
		NICDEV="${NICDEV} /dev/${NIC}"
	fi
done
export NICDEV
echo

# --------------------------------------------------------------- #
# Defining some formatted output                                  #
# --------------------------------------------------------------- #

getparams () {
VAL=`/usr/sbin/ndd -get $1 $2`
printf "Value of $1 $2 is: " | fill
printf " ${VAL} ($3)\n"
}

# --------------------------------------------------------------- #
# Checking the tcp/ip stack parameters
# --------------------------------------------------------------- #
echo
printf "${BOLD}${ULINE}2. Step: Checking tcp/ip stack parameters${NORMAL}\n"
echo

# Set the ARP-cache timeout to 1 Minute (60000 ms)
if [ ${UREVISION} = "5.6" -o ${UREVISION} = "5.7" ]; then
  printf "${BOLD}ARP Cache timeout${NORMAL}\n"
  getparams /dev/ip ip_ire_flush_interval 60000ms

fi
getparams /dev/arp arp_cleanup_interval 60000ms

# Disable IP-forwarding
printf "${BOLD}IP Forwarding On/Off${NORMAL}\n"
getparams /dev/ip ip_forwarding 0

# Deny IP-spoofed packets on multi-homed servers
printf "${BOLD}Deny IP-spoofed packets on multi-homed servers${NORMAL}\n"
getparams /dev/ip ip_strict_dst_multihoming 1

# Disable forwarding of  directed broadcasts
printf "${BOLD}Disable forwarding of directed broadcasts${NORMAL}\n"
getparams /dev/ip ip_forward_directed_broadcasts 0

# Drop source routed packets
printf "${BOLD}Drop source routed packets${NORMAL}\n"
getparams /dev/ip ip_forward_src_routed 0

# Do not respond to broadcast echo requests
printf "${BOLD}Do not respond to broadcast echo requests${NORMAL}\n"
getparams /dev/ip ip_respond_to_echo_broadcast 0

# Do not respond to timestamp broadcast requests
printf "${BOLD}Do not respond to timestamp broadcast requests${NORMAL}\n"
getparams /dev/ip ip_respond_to_timestamp_broadcast 0

# Do not respond to address mask broadcasts
printf "${BOLD}Do not respond to address mask broadcasts${NORMAL}\n"
getparams /dev/ip ip_respond_to_address_mask_broadcast 0

# Ignore ICMP redirects
printf "${BOLD}Ignore ICMP redirects${NORMAL}\n"
getparams /dev/ip ip_ignore_redirect 1

# Do not send ICMP redirects
printf "${BOLD}Do not send ICMP redirects${NORMAL}\n"
getparams /dev/ip ip_send_redirects 0

# Do not send ICMP timestamp requests
printf "${BOLD}Do not send ICMP timestamp requests${NORMAL}\n"
getparams /dev/ip ip_respond_to_timestamp 0

# Do we have strong iss random number generation?
printf "${BOLD}Strong iss random number generation${NORMAL}\n"
getparams /dev/tcp tcp_strong_iss 2

# Decrease the tcp time wait interval
if [ ${UREVISION} = "5.6" ]; then
printf "${BOLD}Decrease the tcp time wait interval${NORMAL}\n"
  getparams /dev/tcp tcp_close_wait_interval 60000ms
else
printf "${BOLD}Decrease the tcp time wait interval${NORMAL}\n"
  getparams /dev/tcp tcp_time_wait_interval 60000ms
fi

# Lower the smallest anon port
printf "${BOLD}Lower the smallest anon port${NORMAL}\n"
getparams /dev/tcp tcp_smallest_anon_port 8192

# Speed up the flushing of half-closed connection in state FIN_WAIT_2
printf "${BOLD}Flushing of half-closed connection in state FIN_WAIT_2${NORMAL}\n"
getparams /dev/tcp tcp_fin_wait_2_flush_interval 67500ms

# Increase the receive and transmit window sizes
printf "${BOLD}Increase the receive and transmit window sizes${NORMAL}\n"
getparams /dev/tcp tcp_xmit_hiwat 65535
getparams /dev/tcp tcp_recv_hiwat 65535

# decrease the retransmit interval
printf "${BOLD}Decrease the retransmit interval${NORMAL}\n"
getparams /dev/tcp tcp_rexmit_interval_max 60000ms

# increase number of half-open connections
printf "${BOLD}Increase number of half-open connections${NORMAL}\n"
getparams /dev/tcp tcp_conn_req_max_q0 4096

# increase number of simultaneous connections
printf "${BOLD}Increase number of simultaneous connections${NORMAL}\n"
getparams /dev/tcp tcp_conn_req_max_q 1024

# Decrease TCP connection abort interval
printf "${BOLD}Decrease TCP connection abort interval${NORMAL}\n"
getparams /dev/tcp tcp_ip_abort_interval 60000ms

# Decrease TCP Keepalive Interval
printf "${BOLD}Decrease TCP Keepalive Interval${NORMAL}\n"
getparams /dev/tcp tcp_keepalive_interval 60000ms

# Increasing maximum congestial window size
printf "${BOLD}Increasing maximum congestial window size${NORMAL}\n"
getparams /dev/tcp tcp_slow_start_initial 2

# --------------------------------------------------------------- #
# Checking network adapter settings
# --------------------------------------------------------------- #
echo
printf "${BOLD}${ULINE}3. Step: Checking NIC parameters${NORMAL}\n\n"

for device in ${NICDEV}
do
	printf "--> Scanning ${BOLD}${device}${NORMAL}\n"

	if [ "${device}" = "qfe" ]
	then
		PREFIX="qfe_"
	fi

# Is autnegotiation off?
printf "${BOLD}Is autonegotiation off?${NORMAL}\n"
getparams ${device} ${PREFIX}adv_autoneg_cap 0

# Do we have Full-Duplex on link?
printf "${BOLD}Do we have Full-Duplex on link?${NORMAL}\n"
getparams ${device} link_mode 1

# Do we have 100Mbit/s on link?
printf "${BOLD}Do we have 100Mbit/s on link?${NORMAL}\n"
getparams ${device} link_speed 1

# Do we have a link up?
printf "${BOLD}Do we have a link up?${NORMAL}\n"
getparams ${device} link_status 1

# Do we have link-partner autonegotiation?
printf "${BOLD}Do we have link-partner autonegotiation?${NORMAL}\n"
getparams ${device} lp_autoneg_cap 0

# Do we have link-partner 100fdx?
printf "${BOLD}Do we have link-partner 100fdx?${NORMAL}\n"
getparams ${device} lp_100fdx_cap 1

# Do we have link-partner 100hdx?
printf "${BOLD}Do we have link-partner 100hdx?${NORMAL}\n"
getparams ${device} lp_100hdx_cap 0

# Do we have link-partner 10fdx?
printf "${BOLD}Do we have link-partner 10fdx?${NORMAL}\n"
getparams ${device} lp_10fdx_cap 0

# Do we have link-partner 10hdx?
printf "${BOLD}Do we have link-partner 10hdx?${NORMAL}\n"
getparams ${device} lp_10hdx_cap 0

echo

done

