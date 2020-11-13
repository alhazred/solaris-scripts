#!/bin/sh
# CDDL HEADER START
#
# The contents of this file are subject to the terms of the
# Common Development and Distribution License, Version 1.0 only
# (the "License").  You may not use this file except in compliance
# with the License.
#
# You can obtain a copy of the license at usr/src/OPENSOLARIS.LICENSE
# or http://www.opensolaris.org/os/licensing.
# See the License for the specific language governing permissions
# and limitations under the License.
#
# When distributing Covered Code, include this CDDL HEADER in each
# file and include the License file at usr/src/OPENSOLARIS.LICENSE.
# If applicable, add the following below this CDDL HEADER, with the
# fields enclosed by brackets "[]" replaced with your own identifying
# information: Portions Copyright [yyyy] [name of copyright owner]
#
# CDDL HEADER END

# 
# simple script to mount and share CDROM images 
#
# History: 
#   24.10.2005 v1.00 /bs initial release
#   26.10.2005 v1.01 /bs added support for symbolic links
#   27.08.2009 v1.02 /bs corrected a syntax error
#
# Author
#   Bernd.Schemmer@gmx.de
#
# Defined return codes:
#
#   0 - everything okay
#   1 - usage message printed and exit
#
#
#

# ---------------------------------------
#
# save the parameter
#
  ACTION="$1"
  [ $# -ne 0 ] && shift
  ACTION_PARAMETER="$*"

# ---------------------------------------
#
# predefined variables
#

# return code of the script
  main_RC=0

  __TRUE=0
  __FALSE=1

  __EXIT_VIA_DIE=${__FALSE}

#
# set __VERBOSE to __TRUE for debugging (use LogInfo for debugging messages)
#
  __VERBOSE=${__FALSE}

  __THISSCRIPT=` basename $0` 

#
#  change the name of the logfile to your need; use __LOGFILE=""
#    to suppress using a logfile at all
#
  __LOGFILE="/var/tmp/${__THISSCRIPT}.log"

  __HOSTNAME=` uname -n `

  __OS=` uname -s `

# __OS_VERSION - Operating system version (e.g 5.8)
#
  __OS_VERSION=` uname -r `

  __RUNLEVEL=`who -r | tr -s " " | cut -f8 -d " " `

#
# set __USER_BREAK_ALLOWED to __FALSE to suppress user aborts with CTRL-C
#
  __USER_BREAK_ALLOWED=${__TRUE}

# set to the name of the application to start/stop with this script
#
  __APPLICATION="myapplication"

# ---------------------------------------
#
# define variables here
#
# Note: Do not use leading underscores (__) for variable names -
#      these names are reserved for internal variables
#

#
# config file; see below for the format of the config file entries
#
  CONF_FILE="/etc/share_cdrom_images.conf"

  TEMP_FILE="/tmp/share_cdrom_images.$$.temp"

# default mount options
  DEF_MOUNT_OPTIONS="-F hsfs -o ro"

# default share options
  DEF_SHARE_OPTIONS="-o ro"

#
# default cdrom images and mount points
#
# use NO for the mount options if you don't want to mount the file
# use NO for the share options if you don't want to share the file
#
  DEF_IMAGE_FILES="#
# image file                                           mount point                       mount options  share options  alias
# --------------------------------------------------------------------------------------------------------------------------
${CDROM_IMG_DIR}/soltools.img                       ;  /export/install/soltools          ; -            ; -            ; perftools
${CDROM_IMG_DIR}/sol-9-u6-supp.img                  ;  /export/install/sol9_supplement   ; -            ; -            ; sol9sup
${CDROM_IMG_DIR}/software_companion_sparc_sol9.img  ;  /export/install/sol9_companion    ; -            ; -            ; sol9comp
${CDROM_IMG_DIR}/software_companion_sparc_sol10.img ;  /export/install/sol10_companion   ; -            ; -            ; sol10comp
#"
 
 
# ---------------------------------------
#
# sub routines
#

# ---------------------------------------
#
# Usage: automatically called in the sub routine die
#
cleanup() {

  LogInfo "Doing house keeping ..."

  if [ "${ACTION}"x = "start"x ] ; then
:
  fi

  if [ "${ACTION}"x = "status"x ] ; then
:
  fi

  if [ "${ACTION}"x = "stop"x ] ; then
:
  fi

#
# house keeping for all runs
#
  [ -f "${TEMP_FILE}" ] && rm "${TEMP_FILE}" 1>/dev/null 2>/dev/null

}

# ---------------------------------------
# 
# Usage: LogMsg [message]
#
LogMsg() {
  LogMsg_THISMSG="$*"
  echo "${__THISSCRIPT} - ${LogMsg_THISMSG}"
  [ "${__LOGFILE}"x != ""x ] && echo "${__THISSCRIPT} - ${LogMsg_THISMSG}" >>echo "${__THISSCRIPT} - ${LogMsg_THISMSG}"
}

# ---------------------------------------
# 
# Usage: LogInfo [message]
#
# Note: LogInfo only prints messages if __VERBOSE is true
#
LogInfo() {
  [ ${__VERBOSE} -eq ${__TRUE} ] && LogMsg "INFO: $*"
}

# ---------------------------------------
#
# Usage: LogWarning [message]
#
LogWarning() {
  LogWarning_THISMSG="${__THISSCRIPT} - ERROR: $*!"
  echo "${LogWarning_THISMSG}" >&2
  [ "${__LOGFILE}"x != ""x ] && echo "${LogWarning_THISMSG}" >>${__LOGFILE}
}


# ---------------------------------------
#
# Usage: LogError [message]
#
# Note: Error messages are written to STDERR
#
LogError() {
  LogError_THISMSG="${__THISSCRIPT} - ERROR: $*!"
  echo "${LogError_THISMSG}" >&2
  [ "${__LOGFILE}"x != ""x ] && echo "${LogError_THISMSG}" >>${__LOGFILE}
}


# ---------------------------------------
#
# Usage: die [returncode] [message]
# 
die() {
  die_THISRC=$1
  [ $# -ne 0 ] && shift
  die_THISMSG="$*"
  __EXIT_VIA_DIE=${__TRUE}

  cleanup

  if [ $# -ne 0 ] ; then
    if [ "${die_THISRC}"x = "0"x ] ; then
      LogMsg "${die_THISMSG}"
    else
      LogError "${die_THISMSG}"
    fi
  fi

  exit ${die_THISRC}
}


# ---------------------------------------
# GENERAL_SIGNAL_HANDLER
#
# general trap handler 
#
# usage: called automatically (parameter $1 is the signal number)
#
# returns: -
#
GENERAL_SIGNAL_HANDLER() {

  case $1 in 

    1 )
        LogInfo "HUP signal received."
        ;;

    2 )
        if [ ${__USER_BREAK_ALLOWED} -eq ${__TRUE} ] ; then
          die 252 "Script aborted by the user via signal BREAK (CTRL-C)" 
        else
          LogInfo "Break signal (CTRL-C) received and ignored (Break is disabled)."
        fi
        ;;

    3 )
        die 251 "QUIT signal received" 
        ;;

   15 )
        die 253 "Script aborted by the external signal TERM" 
        ;;

   "exit" | 0 )
        if [ "${__EXIT_VIA_DIE}"x != "${__TRUE}"x ] ; then
          LogWarning "You should use the function \"die\" to end the program"
        fi    
        return
        ;;
       
    * ) die 254 "Unknown signal catched: $1 "
        ;;

  esac
}


Create_LOFI_Device() {
  CUR_IMAGE_FILE="$1"
  CUR_LOFI_DEVICE=""

  shift $#

  set -- `lofiadm | grep " ${CUR_IMAGE_FILE}$"` 
 
  if [ $? -ne 0 -a "$1"x = ""x ] ; then
    CUR_LOFI_DEVICE=$1
    LogMsg "Creating a lofi device for \"${CUR_IMAGE_FILE}\" ..."
    set -- ` lofiadm -a "${CUR_IMAGE_FILE}"`
    if [ $? -ne 0 ] ; then
      LogError "Can not create a lofi device for \"${CUR_IMAGE_FILE}\""
      return 1
    else
      CUR_LOFI_DEVICE="$1"
      return 0
    fi  
  else
    CUR_LOFI_DEVICE=$1  
    return 0
  fi

  return 1
}

Delete_LOFI_Device() {
  CUR_IMAGE_FILE="$1"
  CUR_LOFI_DEVICE=""

  shift $#
   
  set -- ` lofiadm | grep " ${CUR_IMAGE_FILE}$" ` 
  if [ $? -eq 0 -a "$1"x != ""x ] ; then
    CUR_LOFI_DEVICE="$1"
    LogMsg "Removing the lofi device \"${CUR_LOFI_DEVICE}\" for \"${CUR_IMAGE_FILE}\" ..."
    lofiadm -d "${CUR_IMAGE_FILE}"
    if [ $? -ne 0 ] ; then
      LogError "Can not remove the lofi device for \"${CUR_IMAGE_FILE}\ (\"${CUR_LOFI_DEVICE}\")"
      return 1
    fi  
  fi

  return 0
}

Check_LOFI_Device() {
  CUR_IMAGE_FILE="$1"
  CUR_LOFI_DEVICE=""

  shift $#
   
  set -- ` lofiadm | grep " ${CUR_IMAGE_FILE}$" ` 
  if [ $? -eq 0 -a "$1"x != ""x ] ; then
    CUR_LOFI_DEVICE="$1"   
    return 0
  else
    return 1    
  fi
}

Mount_CDROM_Image() {
  CUR_MOUNT_DEVICE="$1"
  CUR_MOUNT_POINT="$2"

  mount | grep "^${CUR_MOUNT_POINT} " 1>/dev/null 2>/dev/null
  if [ $? -ne 0 ] ; then
    LogMsg "Mounting \"${CUR_MOUNT_POINT}\" to \"${CUR_MOUNT_DEVICE}\" ..."
    mount ${MOUNT_OPTIONS} "${CUR_MOUNT_DEVICE}" "${CUR_MOUNT_POINT}" 1>/dev/null 
    if [ $? -ne 0 ] ; then
      LogError "Can not mount \"${CUR_MOUNT_POINT}\" to \"${CUR_MOUNT_DEVICE}\""
      return 1
    fi
  fi

  return 0
}

Umount_CDROM_Image() {
  CUR_MOUNT_POINT="$1"

  mount | grep "^${CUR_MOUNT_POINT} " 1>/dev/null 2>/dev/null
  if [ $? -eq 0 ] ; then
    LogMsg "Umounting \"${CUR_MOUNT_POINT}\" ..."
    umount "${CUR_MOUNT_POINT}" 1>/dev/null 
    if [ $? -ne 0 ] ; then
      LogError "Can not umount \"${CUR_MOUNT_POINT}\""
      return 1
    fi
  fi

  return 0
}

Check_Mount() {
  CUR_MOUNT_POINT="$1"

  mount | grep "^${CUR_MOUNT_POINT} " 1>/dev/null 2>/dev/null
  if [ $? -eq 0 ] ; then
    return 0
  else
    return 1
  fi
}

Share_Directory() {
  CUR_MOUNT_POINT="$1"

  share | grep " ${CUR_MOUNT_POINT} " 1>/dev/null 2>/dev/null
  if [ $? -ne 0 ] ; then
    LogMsg "Sharing \"${CUR_MOUNT_POINT}\" ..."
    share ${SHARE_OPTIONS} "${CUR_MOUNT_POINT}" 1>/dev/null 
    if [ $? -ne 0 ] ; then
      LogError "Can not share \"${CUR_MOUNT_POINT}\""
      return 1
    fi
  else
    LogMsg "\"${CUR_MOUNT_POINT}\" is already shared."
  fi

  return 0
}


Unshare_Directory() {
  CUR_MOUNT_POINT="$1"

  share | grep " ${CUR_MOUNT_POINT} " 1>/dev/null 2>/dev/null
  if [ $? -eq 0 ] ; then
    LogMsg "Unsharing \"${CUR_MOUNT_POINT}\" ..."
    unshare "${CUR_MOUNT_POINT}" 1>/dev/null 
    if [ $? -ne 0 ] ; then
      LogError "Can not unshare \"${CUR_MOUNT_POINT}\""
      return 1
    fi
  fi

  return 0
}

Check_Share() {
  CUR_MOUNT_POINT="$1"

  share | grep " ${CUR_MOUNT_POINT} " 1>/dev/null 2>/dev/null
  if [ $? -eq 0 ] ; then
    return 0
  else
    return 1    
  fi

}

# ---------------------------------------
# sample subroutine
#
mysubroutine() {
  mysubroutine_THISRC=0

  return ${mysubroutine_THISRC}
}

# ---------------------------------------
#
# main code
#

# install trap handler
  trap "GENERAL_SIGNAL_HANDLER  1"  1
  trap "GENERAL_SIGNAL_HANDLER  2"  2
  trap "GENERAL_SIGNAL_HANDLER  3"  3
  trap "GENERAL_SIGNAL_HANDLER 15" 15
  trap "GENERAL_SIGNAL_HANDLER exit" 0

# check the logfile
  if [ "${__LOGFILE}"x != ""x ] ; then
    touch ${__LOGFILE}
    [ $? -ne 0 ] && __LOGFILE=""
  fi

  if [ "${ACTION}"x != "start"x -a "${ACTION}"x != "stop"x  -a "${ACTION}"x != "status"x ] ; then
    echo "Usage: ${__THISSCRIPT} [start|stop|status] [image ...]"
    die 1
  fi

#
# check if the config file exists
#
  if [ ! -f "${CONF_FILE}" -a ! -h "${CONF_FILE}" ] ; then
    LogMsg "Config file \"${CONF_FILE}\" not found; using defaults."
    IMAGE_FILES="${DEF_IMAGE_FILES}"
  else
    LogMsg "Reading the config file \"${CONF_FILE}\" ..."
    IMAGE_FILES=`cat "${CONF_FILE}"`
  fi

#
# remove comments and empty lines form the list of images and mountpotints 
#
  echo "${IMAGE_FILES}" | grep -v "^#" | grep -v "^$" | tr -s " "  >${TEMP_FILE}

#
# now do for each entry
#
  cat ${TEMP_FILE} | while read CURLINE ; do
    oIFS="${IFS}"
    IFS=";"
    set -- ${CURLINE}
    [ "$1"x = ""x ] && continue
        
    IFS="${oIFS}"

# note: using these commands removes leading and trailing blanks
    IMAGE_FILE=`echo $1` 
    MOUNT_POINT=` echo $2` 
    MOUNT_OPTIONS=`echo $3` 
    SHARE_OPTIONS=`echo $4` 
    CUR_ALIAS=`echo $5`

# if there are additional parameter only process the images added to
# the commandline
#
    if [ "${ACTION_PARAMETER}"x != ""x ] ; then
      CONT_OK=1

      for CUR_PARM in ${ACTION_PARAMETER} ; do

        if [ "${CUR_PARM}"x = "${CUR_ALIAS}"x ] ; then
          CONT_OK=0
          break
        fi

        if [ "${CUR_PARM}"x = "${IMAGE_FILE}"x ] ; then
          CONT_OK=0
          break
        fi

        if [ "${CUR_PARM}"x = "` basename ${IMAGE_FILE}`"x ] ; then
          CONT_OK=0
          break
        fi
      done

      if [ ${CONT_OK} != 0 ] ; then
        continue
      fi     
    fi

    [ "${MOUNT_OPTIONS}"x = "-"x -o "${MOUNT_OPTIONS}"x = ""x ] && MOUNT_OPTIONS="${DEF_MOUNT_OPTIONS}"
    [ "${SHARE_OPTIONS}"x = "-"x -o "${SHARE_OPTIONS}"x = ""x ] && SHARE_OPTIONS="${DEF_SHARE_OPTIONS}"

    if [ "${MOUNT_OPTIONS}"x != "NO"x ] ; then
      if [ "${MOUNT_POINT}"x = ""x  ] ; then
        LogError "The line \"${CURLINE}\" of the config is invalid - ignored"
        continue
      fi

      if [ ! -d "${MOUNT_POINT}" ] ; then
        LogError "The mount point \"${MOUNT_POINT}\" does NOT exist"
        continue
      fi
    fi
    
    if [ ! -f ${IMAGE_FILE} -a ! -h ${IMAGE_FILE} ] ; then
      LogError "The image file \"${IMAGE_FILE}\" does NOT exist"
      continue
    fi

    case ${ACTION} in

      start )
        LogMsg "Starting the share for \"${IMAGE_FILE}\" (Mountpoint is \"${MOUNT_POINT}\") ..."

        Create_LOFI_Device "${IMAGE_FILE}" 
        if [ $? -eq 0 -a "${MOUNT_OPTIONS}"x != "NO"x ] ; then
          Mount_CDROM_Image  "${CUR_LOFI_DEVICE}" "${MOUNT_POINT}" 
          if [ $? -eq 0 -a "${SHARE_OPTIONS}"x != "NO"x ] ; then
            Share_Directory "${MOUNT_POINT}" 
          fi
        fi
        ;;

      stop  )
        LogMsg "Stopping the share for \"${IMAGE_FILE}\" (Mountpoint is \"${MOUNT_POINT}\") ..."
        Unshare_Directory  "${MOUNT_POINT}" && \
        Umount_CDROM_Image "${MOUNT_POINT}" && \
        Delete_LOFI_Device "${IMAGE_FILE}"
        ;;

      status )
        LogMsg "Checking the status of  \"${IMAGE_FILE}\" (Mountpoint is \"${MOUNT_POINT}\") ..."
        Check_LOFI_Device "${IMAGE_FILE}"
	if [ $? -eq 0 ] ; then
	  LogMsg "The lofi device exists (${CUR_LOFI_DEVICE})"
	else
	  LogMsg "The lofi device does not exist"
	fi

	Check_Mount "${MOUNT_POINT}"
	if [ $? -eq 0 ] ; then
	  LogMsg "The mount exists"
	else
	  LogMsg "The mount does not exist"
	fi

	Check_Share "${MOUNT_POINT}"
	if [ $? -eq 0 ] ; then
	  LogMsg "The directory is shared"
	else
	  LogMsg "The directory is not shared"
	fi
        ;;
	
    esac
  done

# ---------------------------------------
      
  die ${main_RC}

# ---------------------------------------
