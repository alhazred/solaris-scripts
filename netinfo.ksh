#!/usr/bin/ksh
##########################################################################
# Shellscript:  netinfo 
# Author     :  Rob Brown <rob.brown@ioko.com>
# Category   :  Sys Admin
# CreateDate :  20-03-2006 
# Version    :  1.0
##########################################################################
# Description:
#	Cycle through all interfaces and show most commonly required info
#
##########################################################################
# Change history (most recent first)
#
# When          Who             Comments
# ----          ---             --------
# 20-03-2006    Rob Brown       Creation
##########################################################################

#
# Variables
#
IFCONFIG=/usr/sbin/ifconfig
AWK=/usr/bin/awk
KSTAT=/usr/bin/kstat
GREP=/usr/bin/grep

#
# Functions
#
sanity_chk()
{
	# Is user root?
	ID=`id`
	USER=`expr "${ID}" : 'uid=\([^(]*\).*'`
	if [ "${USER}" != "0" ]; then
		echo "You're not root, some output will be suppressed"
		ROOT_USER="false"
	else
		ROOT_USER="true"
	fi
}


print_detail()
{
	INTF_NAME=$1
	INTF_TYPE=$2
	INTF_STATUS=$3
	INTF_MAC=$4
	INTF_IP=$5
	INTF_NETMASK=$6
	INTF_BC=$7
	INTF_SPEED=$8
	INTF_DUPLEX=$9
	if [ "${INTF_TYPE}" = "V" ]; then
		INTF_NAME="|-->${INTF_NAME}"
	fi

	echo "${INTF_NAME} ${INTF_TYPE} ${INTF_STATUS} ${INTF_MAC} ${INTF_IP} ${INTF_NETMASK} ${INTF_BC} ${INTF_SPEED} ${INTF_DUPLEX}" | \
		${AWK} '{printf("%-11s %-5s %-10s %-17s %-15s %-10s %-15s %-10s %-10s\n",$1,$2,$3,$4,$5,$6,$7,$8,$9)}'
}


# Get information for the named interface
get_intf_detail()
{
	INTF_NAME=${1}
	# Test if interface is plumbed
	${IFCONFIG} ${INTF_NAME} 2>/dev/null 1>/dev/null
	IFCONFIG_RTRN_CODE=${?}
	if [ "${IFCONFIG_RTRN_CODE}" = "0" ]; then
		INTF_STATUS="plumbed"
		INTF_IP=`${IFCONFIG} ${INTF_NAME} |${GREP} inet |${AWK} '{print $2}'`
		INTF_NETMASK=`${IFCONFIG} ${INTF_NAME} |${GREP} inet |${AWK} '{print $4}'`
		INTF_BC=`${IFCONFIG} ${INTF_NAME} |${GREP} inet |${AWK} '{print $6}'`
		INTF_MAC=`${IFCONFIG} ${INTF_NAME} |${GREP} ether |${AWK} '{print $2}'`
		if [ "${ROOT_USER}" = "true" ]; then
			if [ "${INTF_TYPE}" = "P" ]; then
				case ${INTF_MODEL} in
					ce)
						DUPLEX=`${KSTAT} ${INTF_MODEL}:${INTF_INSTANCE} |${GREP} link_duplex |${AWK} '{ print $2 }'`
      						SPEED=`${KSTAT} ${INTF_MODEL}:${INTF_INSTANCE} |${GREP} link_speed |${AWK} '{ print $2 }'`
						case "${DUPLEX}" in
							1) INTF_DUPLEX="half" ;;
							2) INTF_DUPLEX="full" ;;
						esac
	
						case "${SPEED}" in
							10) INTF_SPEED="10Mbit/s" ;;
	
							1000) INTF_SPEED="1Gbit/s" ;;
						esac
					;;
	
					bge)
						DUPLEX=`${KSTAT} ${INTF_MODEL}:${INTF_INSTANCE}:parameters |${GREP} link_duplex |${AWK} '{ print $2 }'`
      						SPEED=`${KSTAT} ${INTF_MODEL}:${INTF_INSTANCE}:parameters |${GREP} link_speed |${AWK} '{ print $2 }'`
						case "${DUPLEX}" in
							1) INTF_DUPLEX="half" ;;
							2) INTF_DUPLEX="full" ;;
						esac
	
						case "${SPEED}" in
							10) INTF_SPEED="10Mbit/s" ;;
							100) INTF_SPEED="100Mbit/s" ;;
							1000) INTF_SPEED="1Gbit/s" ;;
						esac
					;;
	
					dmfe)
						# How do I do this with a dmfe?
						#DUPLEX=`${KSTAT} ${INTF_MODEL}:${INTF_INSTANCE} |${GREP} link_duplex |${AWK} '{ print $2 }'`
						DUPLEX="unknown"
      						SPEED=`${KSTAT} ${INTF_MODEL}:${INTF_INSTANCE} |${GREP} ifspeed |${AWK} '{ print $2 }'`
							INTF_DUPLEX="${DUPLEX}"
						case "${SPEED}" in
							10) INTF_SPEED="10Mbit/s" ;;
							100) INTF_SPEED="100Mbit/s" ;;
							1000) INTF_SPEED="1Gbit/s" ;;
						esac
					;;
	
					*)
						/usr/sbin/ndd -set /dev/${INTF_MODEL} instance ${INTF_INSTANCE}
						SPEED=`/usr/sbin/ndd -get /dev/${INTF_MODEL} link_speed`
      						DUPLEX=`/usr/sbin/ndd -get /dev/${INTF_MODEL} link_mode`
						case "$SPEED" in
							0) INTF_SPEED="10Mbit/s" ;;
							1) INTF_SPEED="100Mbit/s" ;;
							1000) INTF_SPEED="1Gbit/s" ;;
						esac
						case "$DUPLEX" in
							0) INTF_DUPLEX="half" ;;
							1) INTF_DUPLEX="full" ;;
							*) INTF_DUPLEX="${DUPLEX}" ;;
						esac
					;;
				esac
	
			else
				# It's a virtual Interface
				VIRT_TXT="^^^"
				INTF_SPEED="${VIRT_TXT}"
				INTF_DUPLEX="${VIRT_TXT}"
				INTF_MAC="${VIRT_TXT}"
			fi
			else
				# user isn't root
				NOT_ROOT_TXT="NotRoot"
				INTF_SPEED="${NOT_ROOT_TXT}"
				INTF_DUPLEX="${NOT_ROOT_TXT}"
				INTF_MAC="${NOT_ROOT_TXT}"
			fi

		else
			# It's an unplumbed interface
			INTF_STATUS="unplumbed"
			INTF_IP="-"
			INTF_NETMASK="-"
			INTF_BC="-"
			INTF_SPEED="-"
			INTF_DUPLEX="-"
			INTF_MAC="-"
		fi
}



sanity_chk

print_detail Interface Type Status MAC IP_Addr Netmask Broadcast Speed Duplex

for INTF_GRP in qfe le hme ce bge ge iprb dmfe
do
	while read LINE; do
		NETWORK_LINE=`echo ${LINE} |${GREP} "\"${INTF_GRP}\""`
		if [ "${NETWORK_LINE}" != "" ]; then
			INTF_TYPE="P"
			INTF_INSTANCE=`echo ${NETWORK_LINE} |${AWK} '{print $2}'`
			INTF_MODEL=`echo ${NETWORK_LINE} |${AWK} '{print $3}' |cut -f2 -d\"`
			INTF_NAME="${INTF_MODEL}${INTF_INSTANCE}"
	
			get_intf_detail ${INTF_NAME}
			print_detail ${INTF_NAME} ${INTF_TYPE} ${INTF_STATUS} ${INTF_MAC} ${INTF_IP} ${INTF_NETMASK} ${INTF_BC} ${INTF_SPEED} ${INTF_DUPLEX}

			# Check to see if INTF_NAME has any Virtual Interfaces
			for VIRT_NIC in `${IFCONFIG} -a |${GREP} "${INTF_NAME}" |${AWK} '{print $1}'`
			do
				VIRT_INTF_NAME=`echo ${VIRT_NIC} |${AWK} '{printf "%s", substr ($1,1,length($1)-1)}'`
				if [ "${VIRT_INTF_NAME}" != "${INTF_NAME}" ]; then
					INTF_TYPE="V"
					get_intf_detail ${VIRT_INTF_NAME}
					print_detail ${VIRT_INTF_NAME} ${INTF_TYPE} ${INTF_STATUS} ${INTF_MAC} ${INTF_IP} ${INTF_NETMASK} ${INTF_BC} ${INTF_SPEED} ${INTF_DUPLEX}
				fi
			done

		fi	
	done</etc/path_to_inst
done






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


