#!/bin/ksh
# Add for debug mode -x
#######################################################################
# Program: cdrwmgr.sh    
# Author:  Greg Kranz
# Date:    05/11/2001
# Version: 1.0 
# Purpose: This script helps manage the imaging and burning 
#          of data (ONLY!) CDRWs.  If you have a large quantity
#          to make, it loops you thru it.  The resulting CDs are
#          readable on Unix systems, and NT but not Windows 3.1,
#          95, or 98.  Basically full support for long file names 
#          is required.  
#
#          It can be used to make copies of data CDs.  CDRW supports
#          this capability directly but it is extremely slow.  It is
#          20x faster to image the CD, then burn the CDRW.
#
#          It does not check for disk space issues. A little du -sk 
#          action could fix this but it will add time.
#          
#
# Notes:   cdrw can make audio CDs but this script is not set up for it. 
#          ksh was used so I could use the select function.
#
#          
#          
#          
#           
# 
#######################################################################
# Change history:
#
# Verion Date   Name  Change
# 1.0    051101 PGK   First cut
# 1.1	 040202 PGK   Switch from .img to the standard .iso for file names                    
#                     
#                      
#                     
#
#######################################################################
#
# Setup initial variables

#------------------------ Functions ----------------------------------
make_image()
{

while true
do

#
# Get a name to use as the author of the CD
#
echo
echo " Enter your name (${oldusername}): \c"
read username

# Store the input for reuse later
	if [ -z "${username}" ]; then
		username=${oldusername}
	else
		oldusername=${username}
	fi
#
	if [ "${username}" = "q" ]; then
		return
	fi
#
	if [ "X${username}" = "X" ]; then
		echo "Error: You must enter a name."
	else
		break
	fi
done


while true
do

#
# Get the system name to use as the origin of the CD
#
echo
echo " Enter the system name where the data originated (${oldsysname}): \c"
read sysname
# Store the input for reuse later
	if [ -z "${sysname}" ]; then
		username=${oldsysname}
	else
		oldsysname=${sysname}
	fi
#
	if [ "${sysname}" = "q" ]; then
		return
	fi
#
	if [ "X${sysname}" = "X" ]; then
		echo "Error: You must enter a system name."
	else
		break
	fi
done

while true
do

#
#
echo
echo " Enter the path to the parent directory (${oldbulkpath}): \c"
read bulkpath

# Store the input for reuse later
	if [ -z "${bulkpath}" ]; then
		bulkpath=${oldbulkpath}
	else
		oldbulkpath=${bulkpath}
	fi
#
	if [ "${bulkpath}" = "q" ]; then
		return
	fi
#
	if [ "X${bulkpath}" = "X" ]; then
		echo "Error: You must enter a directory name."
	else
	if [ -d ${bulkpath} ]; then
		break
		else
		echo "Error: ${bulkpath} does not exist"
		fi
	fi
done

LIST="quit all `ls -1 ${bulkpath} | grep -v lost+found`"


PS3="Select a directory to image or 1 to quit or 2 for ALL (${oldname}): "
select NAME in $LIST ; do
        case "$NAME" in
        	quit ) 	return ;;
		QUIT )	$NAME=quit
			return ;;
	       	all )  	break ;;
		ALL ) 	$NAME=all
			break ;;
                * ) if [ -z "${NAME}" ]; then
			NAME=${oldname}
			else
			oldname=${NAME}
			fi
                	echo "$NAME selected." 
                    	break ;;
        esac
done


while true
do

#
#
# Where should the image file be create (ie written)
echo
echo "Enter the directory name where the image file will be written (${oldimagepath}): \c"
read imagepath

# Store the input for reuse later
	if [ -z "${imagepath}" ]; then
		imagepath=${oldimagepath}
	else
		oldimagepath=${imagepath}
	fi

	if [ -d ${imagepath} ]; then
		break
		else
		echo "Error: ${imagepath} does not exist"
		return
	fi
	
done
	

if [ ${NAME} = "all" ]; then
	echo "*** Runing in LOOP mode: all subdirectories will be imaged."
#
# running in loop mode.
#        
for each_name in `ls -1 ${bulkpath} | grep -v lost+found`
	do
		echo "Create image of: ${bulkpath}/${each_name}"
		mkisofs -A "${each_name}" -P "Tyco Electronics Inc, Copywrite Protected" \
		-l -r -d -L -p "${username}" -sysid "${sysname}" -V "${each_name}" \
		-o ${imagepath}/${each_name}.iso ${bulkpath}/${each_name}
	done

else
	echo
	echo "Creating cdrw image file.  This will take a while (5-10 min)."
	echo "Warning: Up to 650 MB of disk could be consumed."
	echo "Create image of: ${bulkpath}/${NAME}"
	echo "Image file name: ${imagepath}/${NAME}.iso"
	echo "Imaging command used: mkisofs -A ${NAME}" 
	echo "                      -P Tyco Electronics Inc, Copy Write Protected"
	echo "                      -l -r -d -L -p ${username} -sysid ${sysname} -V ${NAME}"
	echo "                      -o ${imagepath}/${NAME}.iso ${bulkpath}/${NAME}"
	echo
	mkisofs -A "${NAME}" -P "Tyco Electronics Inc, Copy Write Protected" \
	-l -r -d -L -p "${username}" -sysid "${sysname}" -V "${NAME}" \
	-o ${imagepath}/${NAME}.iso ${bulkpath}/${NAME}
fi


}

# -----------------------------------------------------------------
burn_prep ()
{


while true
do

echo
echo "Enter the directory name (${oldimagepath}) or q for quit: \c"
read imagepath

# Store the input for reuse later
	if [ -z "${imagepath}" ]; then
		imagepath=${oldimagepath}
	else
		oldimagepath=${imagepath}
	fi
#
	if [ "${imagepath}" = "q" ]; then
		return
	fi
#
	if [ -d ${imagepath} ]; then
		break
	else
		echo "Error: ${imagepath} does not exist"
	fi
done

#
# What device will we be using
while true
do

echo
cdrw -l
echo
echo "Enter the device name as shown above (${olddevice}) or q for quit: \c"
read device

# Store the input for reuse later
if [ -z "${device}" ]; then
	device=${olddevice}
	else
	olddevice=${device}
	fi
#
	if [ "${device}" = "q" ]; then
		return
	fi
#		
	devexists=`ls -1 ${device} | wc -l`
	
	if [ "${devexists}" -ne "0" ]; then
		break
	else
		echo "Error: device ${device} does not exist"
	fi
done

burn_image

}


# -----------------------------------------------------------------
burn_image ()
{

# All the error checking was done in burn_prep, so just do it.
orghome=`pwd`
cd ${imagepath}
# This while-do is here just so we can get the menu redisplayed the
# second time thru the loop (select-do-case).
while true
do
PS3="Enter image selection number or 1 to quit (${oldimagename}): "
select imagename in quit `ls -1 *.iso` ; do
        case "${imagename}" in
        	quit ) 	cd ${orghome}
        		return ;;
                * ) if [ -f ${imagename} ]; then
                		# Store the input for reuse later
				if [ -z "${imagename}" ]; then
					imagename=${oldimagename}
				else
					oldimagename=${imagename}
				fi
				#
                    		echo
                    		echo "Burning cdrw image ${imagepath}/${imagename}"
                    		echo " to device ${device}.  This will take a while (5-10 min)."
                    		echo
                    		cdrw -d ${device} -i ${imagename}
                    		eject ${device} 
                	else
                		echo "Unknown error."
                		cd ${orghome}
                		return
                	fi
                		echo "CD burn of image ${imagename} completed." 
                		break ;;
                
                
        esac
done
done

}

#------------------------ Main ----------------------------------
while true
do
	#
	# Display menu
	#
	
	echo "
	Select a task:
	
	1) Create an image file
	2) Burn an image to CD
	3) Exit
	
	Selection: \c"
	
	read choice
	
	case "$choice" in
	1)	make_image ;;
	2)	burn_prep;;
	3)	exit 0;;
	*)	echo "Bad selection\007";;
	esac
done




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


