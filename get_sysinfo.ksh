#!/bin/ksh

###
### NOTE: Can be used with sysinfo_convert_html scripts
###       to output files into readable HTML pages.
###

###################################################
#
#	@(#)	sysinfo.node.ksh		Tony Radtke 11/11/99
#	@(#)	   Script to collect system 
#	@(#)	   configuration information
#	@(#)	   and SSA array WW Numbers
#
#	Usage: sysinfo.ksh
#
#	Data is output to a colon delimited file 
#		for future processing
#
# Submitted By: Matthew Baker
#               Matthew.Baker@med.ge.com
#
#	Sysinfo follow this order
#	Tag Descriptions
#		NODE		--  Hostname of server
#		HSTID		--  Server hostid
#		SERNUM		--  Server serialnumber
#		ARCH		--  Server architecture
#		PLAT		--  Server platform
#		OS		--  Version of Operating System
#		PATCH		--  Version of Kernel Patch
#		OBP		--  Version of OBP
#		CPU		--  Number of CPUs
#		CPUMHZ		--  Speed in Mhz of CPU(s)
#		MEM		--  Amount of memory in Mb
#		BRD		--  Number of System and I/O Boards
#		SSA		--  Number of Sun Storage Arrays
#		PHOTON		--  Number of Photon Disk Arrays
#		ARRAYLIST	--  List of phonton/a5000 arryas w/ number of disks in the array
#		NETRA		--  Number of Netra Disk Arrays
#		TOTDSK		--  Total number of disks
#		DSKSML		--  Number of disks smaller than 2Gb
#		DSK2GB		--  Number of disks between 2 and 4Gb
#		DSK4GB		--  Number of disks between 4 and 8Gb
#		DSK9GB		--  Number of disks between 8 and 18Gb
#		DSK18GB		--  Number of disks between 18 and 36Gb
#		DSK36GB		--  Number of disks between 36 and 73Gb
#		DSK73GB		--  Number of disks between 73 and 100Gb
#		DSK130GB	--  Number of disks between 100Gb and 150Gb
#		DSKBIG		--  Number of disks bigger than 150Gb
#		DSKEMC		--  Number of emc disks 8.51GB
#		DSKBCV		--  Number of BCV disks 8.51GB
#		SOC		    --  Number of FC/OM modules
#		QLGC		--  Number of SCSI Diff cards
#		N100BT		--  Number of 10/100 Network cards
#		GBNIC		--  Number of GB Network cards
#		GBIC		--  Number of GBIC modules
#		HBA			--  Number of HBA cards
#		HBA_TYPE    --  Type of HBA cards
#		HBA_DRV	 	--  Driver version of HBA cards
#		HBA_FIRM	--  Firmware version of HBA cards
#		HBA_FC		--  FCode version of HBA cards
#		FDDI		--  Number of FDDI cards
#		HSI			--  Number of High speed interfaces
#		VID			--  Number of video adapters
#		NET			--  Networks
#		VXVM		--  Veritas VM (or SUNW)
#		VXFS		--  Veritas VXFS
#		VCS		    --  Veritas VCS
#		PWRPTH		--  EMC PWRPTH
#		ECC			--  EMC ECC
#		ESN			--  EMC ESN Manager
#		VOLLOG		--  EMC Volume Logix
#		FZ			--  EMC Fibre Zone
#		NETBACKUP	--  Veritas Netbackup
#		PATROL		--  Patrol
#		AUTOSYS		--  Autosys
#		FORTE		--  Forte
#		NETSCAPE	--  Netscape
#		WEBLOGIC	--  WebLogic
#		BROADVISION	--  Broadvision
#		SQL_BKTRK	--  SQL Backtrack
#		PERL	    --  Perl
#		TRIPWIRE    --  TRIPWIRE
#		PAGE        --  Paging yes|no
#
###################################################
# Functions
	
#
# initialize logfiles ...
# Usage: sysinfo_init
sysinfo_init()
{
	if [ ! -d ${LOGDIR} ]
	then
		mkdir -m 755 -p ${LOGDIR}
	fi

	ARCH=$(prtconf -vp | grep banner-name: | \
				awk -F: '{print $2}' | cut -c4- | sed -e /\'/s/// | sed -n 1p)

#	if [ "$(uname -m)" == "sun4u" ]
#	then
#		ARCH=$(/usr/platform/sun4u/sbin/prtdiag | \
#				head -1 | awk '{print $7" "$8" "$9}')
#	else
#		ARCH=$(uname -i | awk -F, '{print $2}')
#	fi
#
	PLAT=$(uname -p)
}

#
# Gather processor information
# Usage: get_psr_info
get_psr_info()
{
	OUTFILE=/tmp/psrinfo.out.$$
	psrinfo -v > $OUTFILE
	CPU=$(grep -c "Status" $OUTFILE)
	CPUMHZ=$(grep "operates" $OUTFILE | awk '{print $6}' | sort -u)
	rm ${OUTFILE}
}

#
# Gather memory information
# Usage: get_mem_info
get_mem_info()
{
	# Memory size
	MEM=$(prtconf | grep "Memory size" | awk '{print $3}')
}

#
# Gather array information
# Usage: get_array_info
get_array_info()
{
	# Number of Sun Storage Arrays
	SSA=$(ls -l /dev/dsk/c*s2 | grep pln | \
			awk '{print substr($11,length($11)-15,6)}' | \
			sort -u | wc -l | awk '{print $1}')

	# Number of Netra disk arrays
	if [[ -e /opt/SUNWssmu/bin/ssmadmin ]]
	then
		/opt/SUNWssmu/bin/ssmadmin > /tmp/netra.$$ 2>&1
		NETRA=$(awk '/^Number/ {print $5}' /tmp/netra.$$ )
		rm /tmp/netra.$$
	fi

	if [[ -z $NETRA ]]
	then
		NETRA=0
	fi

	LUXADM_THERE="`ls -l /dev/dsk/c*s2 2> /dev/null | grep '/sf@'`"
	if [ -n "$LUXADM_THERE" ]
	then
		# Number of Photon disk arrays
		PHOTON=$(luxadm probe | grep -c SENA)
		
		# Output PHOTON Array WWN 
		# get a list of each array, then the number of slots they each have
		ARRAYLIST=""
		for ARRAY in $(luxadm probe | \
				awk '$1 == "SENA" {print $2}' | \
				awk -F: '{print $2}' | sort)
		do
			# use awk because not all slots are necessarily used
			# get disks (ID - 2000), get O.K. lines, get number of O.K.s via awk
			NUM_DISK=$(luxadm display $ARRAY | grep O\.K\. | grep 2000 | \
						awk '{
								for (i=1; i <= NF; i++)
									if ( $i == "(O.K.)")
									count++
								}
								END {
									print count
						}')
	
			ARRAYLIST="$ARRAYLIST ${ARRAY}-${NUM_DISK}"
		done
	fi

	if [[ -z $PHOTON ]]
	then
		PHOTON=0
	fi

	if [[ -z $ARRAYLIST ]]
	then
		ARRAYLIST="none"
	fi
}

#
# Gather disk information
# Usage: get_disk_info
get_disk_info()
{
	OUTFILE=/tmp/iostat.out.$$
	#
	# Remove duplicate entries based on disk world wide number
	# each version changes the iostat -En fields
	#
	if [[ $(uname -r) == 5.8 ]]
	then
		SIZE_FIELD=2
	elif [[ $(uname -r) == 5.7 ]]
	then
		SIZE_FIELD=2
	else # 5.6
		SIZE_FIELD=6
	fi

	#
	# the /\// and No: is to get rid of CDROMs from the mix
	#  the cdrom either has a date of nothing for a serial number
	#    if it is nothing, then "Serial No:" give "No:" to the var
	#
	# get the device name, size and serial number
	# delete bogus cdrom line "No:"
	# sort by serial number
	# delete lines that don't match cdrom lines
	#
	iostat -En | awk '$0 ~ /^c/ {printf "%s ",$1}
				$0 ~ /Serial/ {printf "%s ",$NF}
				$0 ~ /Size/ {printf "%s \n",$'$SIZE_FIELD'}' | \
				sed -e /No:/d | \
				sort -u -k 2,2 | \
				awk '$2 !~ /\// && $2 !~ /No:/ {print $0}' > $OUTFILE

	#
	# awk: add a 0 to $0 so you get an interger and not a string test
	#
	# Total number of disks
	TOTDSK=$(wc -l $OUTFILE | awk '{print $1}')

	# Total disks under 2Gb
	DSKSML=$(awk '{print $3}' $OUTFILE | awk  -F. '{print $1}' | \
				awk  '{$0+1; if ($0 < 2) print $0}' | \
				wc -l | awk '{print $1}')

	# Total disks between 2Gb and 4Gb
	DSK2GB=$(awk '{print $3}' $OUTFILE | awk  -F. '{print $1}' | \
				awk  '{$0+1; if ($0 >= 2  && $0 < 4) print $0}' | \
				wc -l | awk '{print $1}')

	# Total disks between 4Gb and 8Gb
	DSK4GB=$(awk '{print $3}' $OUTFILE | awk  -F. '{print $1}' | \
				awk  '{$0+1; if ($0 >= 4  && $0 < 8) print $0}' | \
				wc -l | awk '{print $1}')

	# Total disks between 8Gb and 18Gb
	DSK9GB=$(awk '{print $3}' $OUTFILE | awk  -F. '{print $1}' | \
				awk  '{$0+1; if ($0 >= 8  && $0 < 18) print $0}' | \
				wc -l | awk '{print $1}')

	# Total disks between 18Gb and 36Gb
	DSK18GB=$(awk '{print $3}' $OUTFILE | awk  -F. '{print $1}' | \
				awk  '{$0+1; if ($0 >= 18  && $0 < 36) print $0}' | \
				wc -l | awk '{print $1}')

	# Total disks between 36Gb and 73Gb
	DSK36GB=$(awk '{print $3}' $OUTFILE | awk  -F. '{print $1}' | \
				awk  '{$0+1; if ($0 >= 36  && $0 < 73) print $0}' | \
				wc -l | awk '{print $1}')

	# Total disks between 73Gb and 100Gb
	DSK73GB=$(awk '{print $3}' $OUTFILE | awk  -F. '{print $1}' | \
				awk  '{$0+1; if ($0 >= 73  && $0 < 100) print $0}' | \
				wc -l | awk '{print $1}')

	# Total disks between 100Gb and 150Gb
	DSK130GB=$(awk '{print $3}' $OUTFILE | awk  -F. '{print $1}' | \
				awk  '{$0+1; if ($0 >= 100  && $0 < 150) print $0}' | \
				wc -l | awk '{print $1}')

	# Total disks bigger than 150Gb
	DSKBIG=$(awk '{print $3}' $OUTFILE | awk  -F. '{print $1}' | \
				awk  '{$0+1; if ($0 >= 150) print $0}' | \
				wc -l | awk '{print $1}')

	rm $OUTFILE

	# Total disks of EMC @ 8.51GB LUN
	DSKEMC=$( /usr/symcli/bin/sympd list | \
				awk '/RW/ {if ($NF > 100) print $2}' | \
				sort -u | \
				wc -l | \
				sed -e 's/ //g')

	#DSKEMC=$( iostat -En | awk '$0 ~ /^c/ {printf "%s ",$1}
	#			$0 ~ /Serial/ {printf "%s ",$NF}
	#			$0 ~ /EMC/ {printf "%s ",$2}
	#			$0 ~ /Size/ {printf "%s \n",$'$SIZE_FIELD'}' | \
	#			grep EMC | \
	#			sed -e /No:/d | \
	#			sort -u -k 2,2 | \
	#			wc -l | \
	#			awk '{print $1}' )

	if (( DSKEMC > 1 ))
	then
		let DSKEMC=DSKEMC-1
	fi

	if  [[ -f /usr/symcli/bin/sympd ]]
	then
		DSKBCV=$(/usr/symcli/bin/sympd list | sort -u -k 2,2 | grep -c BCV)
	else
		DSKBCV=0
	fi

}

#
# Get system and I/O board information
# Usage: get_brd_info
get_brd_info()
{
	PRTCONF_FILE=/tmp/prtconf.out.$$
	prtconf -vp > $PRTCONF_FILE

	# yes it has prtdiag
	# else there is only prtconf (ultra 1 and 2, sparcstations)

	if [[ -f /usr/platform/$(uname -m)/sbin/prtdiag ]]
	then

		PRTDIAG_FILE=/tmp/prtdiag.out.$$
		/usr/platform/$(uname -m)/sbin/prtdiag  > $PRTDIAG_FILE

		# Number of Serial Optical Converter (SOC) cards
		SOC=$(grep -wc soc $PRTCONF_FILE)

	fi

		if [ -d /devices/fhc* ]
		then
			BRD=$(ls -d /devices/fhc* | wc -l | awk '{print $1}')
		elif [ -d /devices/io-unit* ]
		then
			BRD=$(ls -d /devices/io-unit* | wc -l | awk '{print $1}')
		elif [ -d /devices/iommu* ]
		then
			BRD=$(ls -d /devices/iommu* | wc -l | awk '{print $1}')
		elif [ -d /devices/sbus@* ]
		then
			BRD=$(ls -d /devices/sbus@* | wc -l | awk '{print $1}')
		else
			BRD=0
		fi
}

#
# Get board information
# Usage: get_slot_info
get_slot_info()
{
	PRTCONF_FILE=/tmp/prtconf.out.$$
	prtconf -vp > $PRTCONF_FILE

	# yes it has prtdiag
	# else there is only prtconf (ultra 1 and 2, sparcstations)

	if [[ -f /usr/platform/$(uname -m)/sbin/prtdiag ]]
	then

		PRTDIAG_FILE=/tmp/prtdiag.out.$$
		/usr/platform/$(uname -m)/sbin/prtdiag  > $PRTDIAG_FILE

		# Number of Serial Optical Converter (SOC) cards
		SOC=$(grep -wc soc $PRTCONF_FILE)

		# Number of SCSI Diff cards
		QLGC=$(egrep -ce "qlgc|fas" $PRTDIAG_FILE)

		# Number of 10/100 network cards
		N100BT=$(egrep -ce "hme|qec" $PRTDIAG_FILE)

		# Number of GB network cards
		GBNIC=$(egrep -c gem $PRTDIAG_FILE)

		# Number of GBIC cards
		GBIC=$(grep -wc socal $PRTCONF_FILE)

		# Number of HBA cards
		# get either sbus (fcaw) or PCI (fibre-channel)
		HBA=$(egrep -ce "fibre-channel|FCW|lpfc" $PRTDIAG_FILE)

		# Number of FDDI interfaces
		FDDI=$(grep -wc nf $PRTCONF_FILE)

		# Number of High Speed Interfaces
		HSI=$(grep -c HSI $PRTCONF_FILE)

		# Number of video adapters
		VID=$(egrep -ce "cg|ffb" $PRTCONF_FILE)

		rm $PRTDIAG_FILE
	else
		# Number of Serial Optical Converter (SOC) cards
		SOC=$(grep -cw soc $PRTCONF_FILE)

		# Number of SCSI Diff cards
		QLGC=$(grep -c "QLGC" $PRTCONF_FILE)

		# Number of 10/100 network cards
		N100BT=$(egrep -ce "hme|qec" $PRTCONF_FILE)

		# Number of GBIC cards
		GBIC=$(grep -cw socal $PRTCONF_FILE)

		# Number of GB network cards
		# cannot easily get this out of prtconf
		GBNIC=0

		# Number of HBA cards
		# get either sbus (fcaw) or PCI (fibre-channel)
		HBA=$(egrep -ce "fibre-channel|fcaw| lpfc" $PRTCONF_FILE | grep -c instance)

		# Number of FDDI interfaces
		FDDI=$(grep -c "nf " $PRTCONF_FILE)

		# Number of High Speed Interfaces
		HSI=$(grep -c "HSI" $PRTCONF_FILE)

		# Number of video adapters
		VID=$(egrep -ce "cg|ffb" $PRTCONF_FILE)
	fi

	rm $PRTCONF_FILE

}

#
# Get the HBA's type and version
# Usage: get_hba_info
get_hba_info()
{
	HBA_TYPE="na"
	HBA_DRV="na"
	HBA_FIRM="na"
	HBA_FC="na"

	# if there are HBAs
	if (( $HBA ))
	then
		#see what type
		# look for JNI/FCAW (SBUS), either SBUS or PCI
		if [[ -f /usr/platform/$(uname -m)/sbin/prtdiag ]]
		then
			HBA_TYPE=$(/usr/platform/$(uname -m)/sbin/prtdiag | \
					awk '/FCW/ {print $NF}' | \
					sed -n 1p)
		else
			HBA_TYPE=$(/usr/sbin/prtconf | \
					awk -F, '/fcaw/ {print $1}' | \
					sed -n 1p)
		fi

		#based on type, get info
		# JNI fcaw
		if [[ $HBA_TYPE == FCW || $HBA_TYPE == fcaw ]]
		then
			HBA_TYPE=$(pkginfo -l JNIfcaw | awk '/NAME/ {print $2}')
			HBA_DRV=$(pkginfo -l JNIfcaw | awk '/VERSION/ {print $2}')
			HBA_FIRM=$(pkginfo -l JNICfc64 | awk '/VERSION/ {print $2}')
            # no FC for JNI
			HBA_FC="na"

		else
		# Emulex lpfc
			HBA_TYPE=""
			HBA_DRV=""
			HBA_FIRM=""
			HBA_FC=""
			CNT=0
            LPFC_CMD=/usr/sbin/lpfc/lputil
			NUM_HBA=$($LPFC_CMD count)
		
			# we will loop for each one as you can mix different type
			# but this is probably not the best thing to do
			while (( CNT < $NUM_HBA ))
			do
				HBA_TYPE="$HBA_TYPE $($LPFC_CMD model $CNT)"
				HBA_DRV="$HBA_DRV $(pkginfo -l lpfc | awk '/VERSION/ {print $3}')"
				HBA_FIRM="$HBA_FIRM $($LPFC_CMD rev $CNT | \
							awk -F: '/Initial Firmware/ {print $2}')"

				# we use a dmesg output to a file on bootup because
				# many messages from boot don't get written out before
				# they get flushed/overwritten in the buffer
				if [[ -f /var/adm/dmesg.output ]]
				then
					HBA_FC="$HBA_FC $(grep lpfc /var/adm/dmesg.output | \
								grep Fcode | \
								sed -n \$p | \
								awk '{print $NF}')"
				else
					HBA_FC="$HBA_FC $(grep lpfc /var/adm/messages | \
								grep Fcode | \
								sed -n \$p | \
								awk '{print $NF}')"
				fi
	
				let CNT=$CNT+1
			done
	
			if [[ -z "$HBA_FC" ]]
			then
				HBA_FC="na"
			fi
		fi
	fi
}

#
# List the networks the system is on
# Usage: get_net_info
get_net_info()
{
	NET="$(ifconfig -a | grep inet | grep -v 127.0.0.1 | \
						grep -v inet6 | awk '{print $2}' | \
						tr "\n" "," | awk '{print substr($0,1,length($0)-1)}')"
}

#
# List the sw pkgs
#
get_sw_info()
{
	#
	# Veritas area
	#
	VXVM=$(pkginfo -l VRTSvxvm | \
			awk '/VERSION/ {print $2}'| \
			awk -F, '{print $1}')

	if [[ -z $VXVM ]]
	then
		VXVM=$(pkginfo -l SUNWvxvm | \
				awk '/VERSION/ {print $2}' | \
				awk -F, '{print $1}')
	fi

	if [[ -z $VXVM ]]
	then
		VXVM="na"
	fi

	VXFS=$(pkginfo -l VRTSvxfs | \
				awk '/VERSION/ {print $2}' | \
				awk -F, '{print $1}')

	if [[ -z $VXFS ]]
	then
		VXFS="na"
	fi

	VCS=$(pkginfo -l VRTSvcs | \
				awk '/VERSION/ {print $2}' | \
				awk -F, '{print $1}')

	if [[ -z $VCS ]]
	then
		VCS="na"
	fi

	#
	# EMC area
	#
	PWRPTH=$(pkginfo -l EMCpower | \
				awk '/VERSION/ {print $2}' | \
				awk -F, '{print $1}')

	if [[ -z $PWRPTH ]]
	then
		PWRPTH="na"
	fi

	if [ -d /usr/emc/ECC ]
	then
		ECC=1
	else
		ECC="na"
	fi

	if [ -d /usr/emc/ESN_Manager ]
	then
		ESN=1
	else
		ESN="na"
	fi

	if [ -d /usr/emc/VolumeLogix ]
	then
		VOLLOG=1
	else
		VOLLOG="na"
	fi

	if [ -d /usr/emc/FibreZone ]
	then
		FZ=1
	else
		FZ="na"
	fi

	#NETBACKUP
	if [[ -e /usr/openv/netbackup/bin/version ]]
	then
		NETBACKUP=$(awk '{print $2}' /usr/openv/netbackup/bin/version)
	else
		NETBACKUP="na"
	fi

	#PATROL
	if [[ -L /opt/sccm/patrol ]]
	then
		if [[ -f  /opt/sccm/patrol/PatrolAgent ]]
		then
			/opt/sccm/patrol/PatrolAgent -v 2> /tmp/Patrol_out.$$
			# must sleep to get file output - Patrol messes with this
			sleep 3
			PATROL=$(awk '{print $2}' /tmp/Patrol_out.$$)
		fi
	else
		PATROL="na"
	fi

	#AUTOSYS
	if [[ -e /opt/sccm/autosys/bin/autoflags ]]
	then
		AUTO1=$( /opt/sccm/autosys/bin/autoflags -v)
		AUTO2=$( /opt/sccm/autosys/bin/autoflags -r )
		AUTOSYS=${AUTO1}-R${AUTO2}
	else
		AUTOSYS="na"
	fi

	#FORTE
	if [[ -n $(ls -d /opt/sccm/forte* 2> /dev/null ) ]]
	then
		cd /opt/sccm
		for i in $(ls -d forte*)
		do
			INST=$(cat $i/FORTE.VER)
			FORTE="$FORTE ${i}-${INST}"
		done
	else
		FORTE="na"
	fi

	#NETSCAPE
	if [[ -e /opt/sccm/netscape/bin/https/bin/ns-httpd ]]
	then
		NETSCAPE=$(awk '/Version/ {print $2}' /opt/sccm/netscape/setup/setup.inf  )
		#NETSCAPE=$(/opt/sccm/netscape/bin/https/bin/ns-httpd -v | \
			#sed -n 2p | awk -F/ '{print $2}')
	else
		NETSCAPE="na"
	fi

	#WEBLOGIC
	#
	# should be better, but this works for now
	#
	DIRS="/opt/sccm/appserver/weblogic /opt/sccm/rtp/weblogic /opt/sccm/apps401k/weblogic /opt/sccm/weblogic /opt/sccm/bea /opt/sccm/jdk1.1.7B/weblogic /opt/sccm/netscape/weblogic"

	WEBLOGIC=""
	for DIR in $DIRS
	do
		#	
		# This is spastic, but works.  Later version of weblogics will
		# be installed in a consistent set of dirs and this will go away.
		#	
		# get the version dirs, if any	
		#	
		DIRVIR=$(ls -d $DIR/[1-9]* 2> /dev/null | awk -F/ '{print $NF}')

		#if any dirs found
		if [[ -n $DIRVIR ]]
		then
				WEBLOGIC="$WEBLOGIC $DIRVIR"
		fi
	done

	if [[ -z $WEBLOGIC ]]
	then
		WEBLOGIC="na"
	else
		WEBLOGIC=$(print $WEBLOGIC | sort -u)
		#WEBLOGIC=$(print $WEBLOGIC | tr ' ' '\015' | sort -u)
	fi

	#BROADVISION
	if [[ -L /opt/sccm/bv1to1 ]]
	then
		BROADVISION=$(ls -l /opt/sccm/bv1to1 | awk '{print $NF}'| cut -c8- )
	else
		BROADVISION="na"
	fi

	#SQL_BKTRK
	if [[ -e /opt/sccm/datatools/sbacktrack/VERSION ]]
	then
		SQL_BKTRK=$(awk '{print $5}' /opt/sccm/datatools/sbacktrack/VERSION )
	else
		SQL_BKTRK="na"
	fi

	#PERL
	if [[ -e /usr/bin/perl ]]
	then
		PERL=$(/usr/bin/perl -v | awk '/This is perl/ {print $5}')
	else
		PERL="na"
	fi

	#TRIPWIRE
	if [[ -f /usr/local/tripwire/tfs/README ]]
	then
		TRIPWIRE=$(sed -n 2p /usr/local/tripwire/tfs/README | awk '/Tripwire for Servers/ {print $4}')
	else
		TRIPWIRE="na"
	fi
}

##########################################################################
# Variables
##########################################################################

DMZ_SERVERS="barium coyote dacs1 ftp100 ftp900 husky hyena mdf2 puma reuters1 reuters2 scorpion thud tiger vulture"


NODE=$(hostname)
HSTID=$(hostid)
OS=$(uname -r)
OBP=$(prtconf -V | awk '{print $2}')
PATCH=$(uname -a | awk '{print $4}')

if [[ -f /etc/release ]]
then
	# the reason for the sed is there is preceeding white space in the line
	RELEASE=$(sed -n 1p /etc/release | sed 's/.* Solaris/Solaris/')
else
	RELEASE=none
fi

if [[ -s /etc/stronginfo ]]
then
	SERNUM=$(grep -v ^# /etc/stronginfo   | \
					awk -F\= '/^Serial Number/  {print $2}'| sed '/^ /s/^ //' )

	BUSUNIT=$(grep -v ^# /etc/stronginfo  |\
					awk -F\= '/^Business Unit/  {print $2}'| sed '/^ /s/^ //' )

	USAGE=$(grep -v ^# /etc/stronginfo    | \
					awk -F\= '/^Server Usage/   {print $2}'| sed '/^ /s/^ //' )

	LOCATION=$(grep -v ^# /etc/stronginfo | \
					awk -F\= '/^Location/       {print $2}'| sed '/^ /s/^ //' )

	SRVPURP=$(grep -v ^# /etc/stronginfo  | \
					awk -F\= '/^Server Purpose/ {print $2}'| sed '/^ /s/^ //' )

	OLDNAMES=$(grep -v ^# /etc/stronginfo  | \
					awk -F\= '/^OldNames/ {print $2}'| sed '/^ /s/^ //' )

	PAGE=$(grep -v ^# /etc/stronginfo  | \
					awk -F\= '/^Page/ {print $2}'| sed '/^ /s/^ //' )
fi

if [[ -z $SERNUM ]]
then
	PID=$$
	SERNUM=12${PID}21
fi

if [[ -z $BUSUNIT ]]
then
	BUSUNIT=1
fi

if [[ -z $USAGE ]]
then
	USAGE=1
fi

if [[ -z $LOCATION ]]
then
	LOCATION=1
fi

if [[ -z $SRVPURP ]]
then
	SRVPURP=1
fi

if [[ -z $OLDNAMES ]]
then
	OLDNAMES=na
fi

if [[ -z $PAGE ]]
then
	PAGE=na
fi

#LOGDIR="/sccm/cfig/sysinfo/$(${date} +%m%Y)"
LOGDIR="/sccm/cfig/sysinfo/sysinfo"
LOGFILE="$LOGDIR/$NODE.sysinfo.db"

#
# for DMZ nodes
#  nodes that do not have NFS access
#	write to local file, have another program that 
#   uses scp (secure rcp) to grap the files.
#
if [[ -n $(print $DMZ_SERVERS | grep -w $NODE) ]]
then
	LOGDIR="/var/tmp/configs"
	LOGFILE="$LOGDIR/$NODE.sysinfo.db"
fi


if [[ ! -d $LOGDIR ]]
then
	mkdir $LOGDIR
fi

# MAIN

sysinfo_init
get_psr_info
get_mem_info
get_array_info
get_disk_info
get_brd_info
get_slot_info
get_net_info
get_hba_info
get_sw_info


print "$NODE:$USAGE:$LOCATION:$BUSUNIT:$SRVPURP:\
$HSTID:$SERNUM:$ARCH:$PLAT:$OS:\
$RELEASE:$PATCH:$OBP:$CPU:$CPUMHZ:\
$MEM:$BRD:$SSA:$PHOTON:$ARRAYLIST:\
$NETRA:$TOTDSK:$DSKSML:$DSK2GB:$DSK4GB:\
$DSK9GB:$DSK18GB:$DSK36GB:$DSK73GB:$DSK130GB:$DSKBIG:\
$DSKEMC:$DSKBCV:$SOC:$QLGC:$N100BT:\
$GBNIC:$GBIC:$HBA:$HBA_TYPE:$HBA_DRV:$HBA_FIRM:$HBA_FC:$FDDI:$HSI:\
$VID:$NET:$VXVM:$VXFS:$VCS:$PWRPTH:\
$ECC:$ESN:$VOLLOG:$FZ:$NETBACKUP:\
$PATROL:$AUTOSYS:$FORTE:$NETSCAPE:$WEBLOGIC:\
$BROADVISION:$SQL_BKTRK:$PERL:$TRIPWIRE:$OLDNAMES:$PAGE" \
	> $LOGFILE

chmod 666 $LOGFILE

# call other program - bad way, but saves cron entries
if [[ -f ~sau/scripts/get_dbms ]]
then
	~sau/scripts/get_dbms
fi

if [[ -f ~sau/scripts/get_emc ]]
then
	~sau/scripts/get_emc
fi

if [[ -f ~sau/scripts/get_rup ]]
then
	~sau/scripts/get_rup
fi

if [[ -f ~sau/scripts/get_printers ]]
then
	~sau/scripts/get_printers
fi

if [[ -f ~sau/scripts/get_service_names ]]
then
	~sau/scripts/get_service_names
fi

if [[ -f ~sau/scripts/get_company_info ]]
then
	~sau/scripts/get_company_info
fi


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


