#!/usr/bin/ksh
# zone-clone: A tool for cloning a zone ;-)
#
# Version 1.0.0
# Maintainer: Bernd Finger
#
# In a loop, this tool creates a zone config file for the zonecfg
# command, and a sysidcfg file so that the zone will be usable
# immediately after booting.
# Then, the zone is configured and created as a copy of its source zone.
# Notes:
# 1) Zone "source-zone" must exist, booted once (to avoid the SMF import
#    for the clones), and halted.
# 2) Zone root path must be on ZFS. Otherwise, zones will be cloned by
#    copying instead of using snapshots.
#

#
# ATTENTION:
# Please test this script very carefully before using it!
#
# No warranty of any kind. Please use at your own risk.
#

NUM_ZONES=$1
if [[ ${NUM_ZONES}. = "." ]]; then
   echo "Please enter the number of zones you would like to create:"
   read NUM_ZONES
fi

#
# CUSTOMIZE:
#
# NUM_ZONES=5
STATUS_AFTER_INSTALL=ready
# STATUS_AFTER_INSTALL=running
BASE_IP_ADDRESS=192.168.0.
BASE_IP_NUM=4
# PHYSICAL=hme0                 # no longer necessary, as retrieved from ifconfig
NETMASK_BITS=19
# NETMASK=255.255.255.0         # no longer necessary, as calculated from NETMASK_BITS
ROUTER_HOST_IP=1
# DEFAULT_ROUTE=192.162.0.1     # no longer necessary, as calculated from
#                                 BASE_IP_ADDRESS and ROUTER_HOST_IP
BASE_ZONE_NAME=scotty-z-
BASE_ZONE_PATH=/zp1
SOURCE_ZONE_NAME=source-zone
USER_FOR_ROOT_PASSWD=adm
# ROOT_PASSWD=abcdefghijklm     # no longer necessary, as determined from USER_FOR_ROOT_PASSWD's /etc/shadow entry.
SYSTEM_LOCALE=en_US.ISO8859-15
TIMEZONE=Europe/Berlin
TERMINAL=xterms
KEYBOARD=German
SECURITY_POLICY=NONE
TIMESERVER=localhost
NAME_SERVICE=none
IPV6=yes
NFS4_DOMAIN=dynamic

#
# NO NEED TO CHANGE ANYTHING BELOW
#
# number of digits for creating zone names of equal lengths,
#   using the %0*d format specifier (see below):
#
NUM_DIGITS=$(echo ${NUM_ZONES} | nawk '{print length($1)}')

#
# determine default route from BASE_IP_ADDRESS and ROUTER_HOST_IP:
#
DEFAULT_ROUTE=${BASE_IP_ADDRESS}${ROUTER_HOST_IP}

#
# determine number of physical network interfaces. If more than one,
#   ask for the name to be entered manually:
#
if [[ ${PHYSICAL}. = "." ]]; then
   PHYSICAL=$(ifconfig -a | nawk 'BEGIN{FS=":"}/flags/ && !/lo0/{print $1}' | sort -u)
   NUM_PHYSICAL=$(echo $PHYSICAL | wc -w)
   if [ ${NUM_PHYSICAL} -gt 1 ]; then
      echo "More than one physical interface:"
      echo ${PHYSICAL}
      echo "Please enter interface manually:"
      read PHYSICAL
   fi
fi

#
# determine NETMASK from NETMASK_BITS:
#
if [[ ${NETMASK}. = "." ]]; then
   NETMASK=$(nawk 'BEGIN{num='${NETMASK_BITS}';
      for (i=1; i<=4; i++){
         if (num>=8) printf ("255");
         else if (num<=0) printf ("0");
         else printf ("%s", 256-2^(8-num));
         if (i<=3) printf (".")
         num-=8
      }
      printf ("\n")
   }')
fi

#
# get root user's password from /etc/shadow:
#
ROOT_PASSWD=$(nawk 'BEGIN{FS=":"}$1=="'${USER_FOR_ROOT_PASSWD}'"{print $2}' /etc/shadow)
if [[ ${ROOT_PASSWD}. = "NP". ]] || [[ ${ROOT_PASSWD}. = "*LK*". ]] || [[ -z ${ROOT_PASSWD} ]]; then
   echo "The password for the root user, taken from /etc/shadow entry for user ${USER_FOR_ROOT_PASSWD},"
   echo "   could not be set."
   echo "Exit."
   exit 1
else
   echo "Successfully retrieved password for the root user, from /etc/shadow entry for user ${USER_FOR_ROOT_PASSWD}."
fi

DATE=$(date +%Y%m%d.%H%M%S)
TMPDIR=/var/tmp/zones-${DATE}
mkdir -p ${TMPDIR}

ZFS=0
num=0
while true; do
   num=$(( ${num} + 1 ))
   TMP_FILE=${TMPDIR}/tmpfile.${ZONE_NAME}
   IP_NUM=$(( ${BASE_IP_NUM} + ${num} ))
   IP_ADDRESS=${BASE_IP_ADDRESS}${IP_NUM}
#
# Now we are building the name of the zone and the associated zone path...
#
   ZONE_NAME=$(nawk 'BEGIN{printf ("%s%0*d", "'${BASE_ZONE_NAME}'", '${NUM_DIGITS}', '${num}')}')
   ZONE_PATH=${BASE_ZONE_PATH}/${ZONE_NAME}
#
# ...creating the zone config file...
#
   ZONECFG_FILE=${TMPDIR}/zonecfg.${ZONE_NAME}
   echo "create"                                     	     >> ${ZONECFG_FILE}
   echo "set zonepath=${ZONE_PATH}"                  	     >> ${ZONECFG_FILE}
   echo "add net"                                    	     >> ${ZONECFG_FILE}
   echo "set address=${IP_ADDRESS}/${NETMASK_BITS}"  	     >> ${ZONECFG_FILE}
   echo "set physical=${PHYSICAL}"                   	     >> ${ZONECFG_FILE}
   echo "end"                                        	     >> ${ZONECFG_FILE}
   echo "verify"                                     	     >> ${ZONECFG_FILE}
   echo "commit"                                     	     >> ${ZONECFG_FILE}
   echo "exit"                                       	     >> ${ZONECFG_FILE}
#
# ...and the sysidcfg file:
#
   SYSIDCFG_FILE=${TMPDIR}/sysidcfg.${ZONE_NAME}
   echo "system_locale=${SYSTEM_LOCALE}"                     >> ${SYSIDCFG_FILE}
   echo "timezone=${TIMEZONE}"                               >> ${SYSIDCFG_FILE}
   echo "terminal=${TERMINAL}"                               >> ${SYSIDCFG_FILE}
   echo "keyboard=${KEYBOARD}"                               >> ${SYSIDCFG_FILE}
   echo "security_policy=${SECURITY_POLICY}"                 >> ${SYSIDCFG_FILE}
   echo "root_password=${ROOT_PASSWD}"                       >> ${SYSIDCFG_FILE}
   echo "timeserver=${TIMESERVER}"                           >> ${SYSIDCFG_FILE}
   echo "name_service=${NAME_SERVICE}"                       >> ${SYSIDCFG_FILE}
   echo "network_interface=primary {hostname=${ZONE_NAME}"   >> ${SYSIDCFG_FILE}
   echo "   ip_address=${IP_ADDRESS}"                        >> ${SYSIDCFG_FILE}
   echo "   netmask=${NETMASK}"                              >> ${SYSIDCFG_FILE}
   echo "   protocol_ipv6=${IPV6}"                           >> ${SYSIDCFG_FILE}
   echo "   default_route=${DEFAULT_ROUTE}"                  >> ${SYSIDCFG_FILE}
   echo "}"                                                  >> ${SYSIDCFG_FILE}
   echo "nfs4_domain=${NFS4_DOMAIN}"                         >> ${SYSIDCFG_FILE}

   if [[ ${num} -eq 1 ]]; then
#
# First iteration: We will check certain things before we actually execute:
#
      echo "Check:"
      echo "------"
      echo "Source zone:"
      zoneadm list -cv | grep ${SOURCE_ZONE_NAME}
      RC=$?
      if [ ${RC} -eq 1 ]; then
         echo "Source zone ${SOURCE_ZONE_NAME} does not exist."
         echo "Please configure, boot, and halt ${SOURCE_ZONE_NAME} first,"
         echo "before executing this script."
         sed 's,'${ZONE_NAME}','${SOURCE_ZONE_NAME}',' ${ZONECFG_FILE} > \
           ${TMPDIR}/zonecfg.${SOURCE_ZONE_NAME}
	 ZONECFG_FILE=${TMPDIR}/zonecfg.${SOURCE_ZONE_NAME}
         echo "You may want to use zone config file ${ZONECFG_FILE}"
	 echo "  and change the IP address for your source zone."
         echo "Then, execute:"
         echo "$ zonecfg -z ${SOURCE_ZONE_NAME} -f ${ZONECFG_FILE}"
         echo "$ zoneadm -z ${SOURCE_ZONE_NAME} install"
         sed 's,'${ZONE_NAME}','${SOURCE_ZONE_NAME}',' ${SYSIDCFG_FILE} > \
	   ${TMPDIR}/sysidcfg.${SOURCE_ZONE_NAME}
         SYSIDCFG_FILE=${TMPDIR}/sysidcfg.${SOURCE_ZONE_NAME}
         echo "Edit sysidcfg file ${SYSIDCFG_FILE}"
	 echo "  and copy to the zone's /etc path:"
         echo "$ cp ${SYSIDCFG_FILE} \\"
	 echo "${BASE_ZONE_PATH}/${SOURCE_ZONE_NAME}/root/etc/sysidcfg"
         echo "Then, boot the zone:"
         echo "$ zoneadm -z ${SOURCE_ZONE_NAME} boot"
         echo "Finally, log in to the zone and wait for the completion of the SMF import."
	 exit 1
      fi
#
# Find out if the source zone is halted:
#
      zoneadm list -cv | grep ${SOURCE_ZONE_NAME} | grep running >/dev/null 2>&1
      RC1=$?
      if [ ${RC1} -eq 0 ]; then
         echo "Source zone ${SOURCE_ZONE_NAME} is not halted."
         echo "Before this zone can be used for cloning, it has to be halted."
         echo "Press RETURN to halt the zone and continue."
         read a
         printf "Halting zone ${SOURCE_ZONE_NAME}..."
         zoneadm -z ${SOURCE_ZONE_NAME} halt
         echo "done."
      fi
#
# Examine the zonepath of the source zone:
#
      SOURCE_ZONE_PATH=$(zonecfg -z ${SOURCE_ZONE_NAME} info zonepath | cut -d " " -f 2)
#
# Let's test if this is on zfs. If yes, we will use snapshots:
#
      zfs list | grep ${SOURCE_ZONE_PATH} >/dev/null 2>&1
      RC2=$?
      if [[ ${RC2} -eq 0 ]]; then
         echo ${SOURCE_ZONE_PATH} | grep ${BASE_ZONE_PATH}
         RC3=$?
         if [[ ${RC3} -eq 0 ]]; then
            ZFS=1
         else
            echo "The root paths of the new zones are not on a zfs file system."
            echo "Press RETURN to create the zones anyway, <ctrl>-c to stop."
            read a
         fi
      else
         echo "Source zone ${SOURCE_ZONE_NAME} is not on a zfs file system."
         echo "Press RETURN to clone this zone anyway, <ctrl>-c to stop."
         read a
      fi
#
# Show sample configuration before starting the loop:
#
      echo "------"
      echo "Content of first zone config file:"
      cat ${ZONECFG_FILE}
      echo "------"
      echo "Content of first sysidcfg file:"
      cat ${SYSIDCFG_FILE}
      echo "------"
      echo ""
      nawk 'BEGIN{printf ("Highest IP address will be %s%s, for zone %s%0*d .\n",
      "'${BASE_IP_ADDRESS}'", '${BASE_IP_NUM}' + '${NUM_ZONES}',
      "'${BASE_ZONE_NAME}'", '${NUM_DIGITS}', '${NUM_ZONES}')}'
      echo ""
      echo "Press RETURN to start creating ${NUM_ZONES} zones."
      read a
   fi

#
# We need 2 iterations in case there is no snapshot for the source zone:
#
   if [[ ${num} -le 2 ]]; then
#
# Let's test if this is on zfs. If yes, we will use snapshots:
#
      if [[ ${ZFS} -eq 1 ]]; then
#      zfs list | grep ${SOURCE_ZONE_PATH} >/dev/null 2>&1
#      RC=$?
#      if [[ ${RC} -eq 0 ]]; then
         SOURCE_ZONE_SNAPSHOT=$(zfs list | nawk '/'${SOURCE_ZONE_NAME}'@SUNW/{print $1;exit}')
#
# Test if there's already a snapshot. In this case, use it.
#
         if [[ ${SOURCE_ZONE_SNAPSHOT}. != "." ]]; then
            CLONE_SNAP_ARGS="-s ${SOURCE_ZONE_SNAPSHOT} "
         fi
      fi
   fi
   printf "%s with zonepath=%s and ip addr=%s ...\n" ${ZONE_NAME} ${ZONE_PATH} ${IP_ADDRESS} 
#
# We configure the zone, using the zone config file from above
#
   zonecfg -z ${ZONE_NAME} -f ${ZONECFG_FILE}
#
# Perform the actual cloning:
#
   zoneadm -z ${ZONE_NAME} clone ${CLONE_SNAP_ARGS}${SOURCE_ZONE_NAME}
#
# Copy the sysidcfg file to its correct final location which is now accessible, after the
# cloning is finished
#
   rm -f ${ZONE_PATH}/root/etc/sysidcfg
   cp -p ${SYSIDCFG_FILE} ${ZONE_PATH}/root/etc/sysidcfg
   rm -f ${ZONE_PATH}/root/etc/.UNCONFIGURED
#
# ready or boot the zone:
#
   if [[ ${STATUS_AFTER_INSTALL} = "ready" ]]; then
      zoneadm -z ${ZONE_NAME} ready
   elif [[ ${STATUS_AFTER_INSTALL} = "running" ]]; then
      zoneadm -z ${ZONE_NAME} boot
   fi

   echo "... done."
#
# Exit after the number of zones to be created is reached.
#
   if [[ ${num} -ge ${NUM_ZONES} ]]; then
      exit
   fi
done




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


