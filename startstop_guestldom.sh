#!/usr/bin/ksh
#
# history:
#
# 18.09.2008 v1.0.1/bs
#  - added code to handle partner machine down situations
#

# ---------------------------------------------------------------------
# constants
#

# ---------------------------------------------------------------------
# variables
#

# ---------------------------------------------------------------------
# functions
#

function logMsg {   
  echo "$*"
}

function logError {
  logMsg "ERROR: $*" >&2
}

function logInfo {
  [ "${VERBOSE}"x != ""x ] && logMsg "INFO: $*"
}


function die {
  typeset THISRC=$1
  [ $# -ne 0 ] && shift
  typeset THISMSG="$*"
  if [ "${THISRC}"x = "0"x ] ; then
    logMsg "${THISMSG}"
  else
    logError "${THISMSG}"
  fi
  exit ${THISRC}
}
  
# ---------------------------------------------------------------------
# main function
#

# the name of the LDom is the name of the script
#
GUEST_LDOM=$( basename $0 )

CUR_HOST=$( cut -f1 -d "." /etc/nodename )

case "${CUR_HOST}" in
   baggers0057 )  
     REMOTE_HOST="baggers0058" 
     ;;

   baggers0058 ) 
     REMOTE_HOST="baggers0057"
     ;;

   baggers0059 )
     REMOTE_HOST=""
     ;;

   * )
     REMOTE_HOST=""
     ;;

esac

logInfo "The name of the Guest LDom to work on is \"${GUEST_LDOM}\" "

if [ $# -ne 1 ] ; then
  die 0 "Usage: ${GUEST_LDOM} [start|force_start|stop|status]"
fi

ACTION="$1"

logMsg "Retrieving the status of the Guest LDom \"${GUEST_LDOM}\" ..."
GUEST_LDOM_STATUS=$( ldm list -p "${GUEST_LDOM}" | grep -v "VERSION"   | cut -f3 -d "|" )

logInfo "The status of the Guest LDom is \"${GUEST_LDOM_STATUS}\" "

case "${GUEST_LDOM_STATUS}" in

  "state=active" ) 
    GUEST_LDOM_STATUS="running" 
    ;;
  "state=bound" ) 
    GUEST_LDOM_STATUS="bound"
    ;;

  "state=inactive" ) 
    GUEST_LDOM_STATUS="inactive"
    ;;

  "" )
   die 5 "Guest LDom \"${GUEST_LDOM}\" is not defined on this machine"
  ;;
  
  * )
   die 10 "Guest LDom \"${GUEST_LDOM}\" is in an unknown state: \"${GUEST_LDOM_STATUS}\" "
  ;;
  
esac

logMsg "Retrieving the boot device for the Guest LDom \"${GUEST_LDOM}\" ..."
GUEST_LDOM_ROOT_DEVICE="$( ldm list -e "${GUEST_LDOM}"  | grep vdisk0 | awk '{ print $2 }' )"
logInfo "The vdisk0 device of the Guest LDom is \"${GUEST_LDOM_ROOT_DEVICE}\" "
[ "${GUEST_LDOM_ROOT_DEVICE}"x = ""x ] && die 15 "No vdisk0 device defined for the Guest LDom \"${GUEST_LDOM}\" "


# Note: This code assumes that the vdisk names are unique in the primary Ldom!!!!! /b
#
PRIMARY_VDISK="$( echo "${GUEST_LDOM_ROOT_DEVICE}" | cut -f1 -d "@" )"
logInfo "The primary vdisk device for the Guest LDom is \"${PRIMARY_VDISK}\" "
[ "${PRIMARY_VDISK}"x = ""x ] && die 20 "Internal error -- can not get the name for the backend device"


ROOT_DISK_FILE="$( ldm list -l primary | grep "${PRIMARY_VDISK}" | awk '{ print $NF }' )"
logInfo "The root disk file for the Guest LDom is \"${ROOT_DISK_FILE}\" "

[ "${ROOT_DISK_FILE}"x = ""x ] && die 25 "No backend device defined for \"${GUEST_LDOM_ROOT_DEVICE}\" in the Primary LDom"

logMsg "Checking the NFS mount ...."

MOUNT_POINT_FOUND=1
MOUNT_POINT="${ROOT_DISK_FILE}"
while [ ${MOUNT_POINT_FOUND} = 1 ] ; do
  MOUNT_POINT="$( dirname "${MOUNT_POINT}" )"
  [ "${MOUNT_POINT}"x = "/"x ] && break
  grep "${MOUNT_POINT}"  /etc/vfstab >/dev/null && MOUNT_POINT_FOUND=0
done

[ "${MOUNT_POINT}"x = ""x -o ${MOUNT_POINT_FOUND} = 1 ] && die 30 "Invalid path for the root device found"

logInfo "The mount point for the Guest LDom is \"${MOUNT_POINT}\" "

[ "${MOUNT_POINT}"x = ""x ] && die 30 "Invalid path for the root device found"

[ ! -d "${MOUNT_POINT}" ] && die 40 "The mount point \"${MOUNT_POINT}\" does not exist"

 VFSTAB_MOUNT_POINT="$( grep "${MOUNT_POINT}" /etc/vfstab  | awk '{ print $3 }' )"
[ "${VFSTAB_MOUNT_POINT}"x != "${MOUNT_POINT}"x ] &&  die 45 " \"${MOUNT_POINT}\" is not a mount point"

mount | grep "^${MOUNT_POINT}" >/dev/null &&  NFS_DIR_MOUNTED="yes" || NFS_DIR_MOUNTED="no"
logInfo "The nfs dir mount status is: \"${NFS_DIR_MOUNTED}\" "

case ${ACTION} in

  start | force_start )

    if [ "${ACTION}"x = "force_start"x -o "${REMOTE_HOST}"x = ""x ] ; then
      LogMsg "force_start used - will not check the status of the LDom \"${GUEST_LDOM}\" on the host \"${REMOTE_HOST}\" "
      REMOTE_LDOM_STATUS=""
    elif [ "${REMOTE_HOST}"x = ""x ] ; then
      logMsg "No remote host defined for this Primary LDom"
      REMOTE_LDOM_STATUS=""
    else
      logMsg "Checking the connection to the other node \"${REMOTE_HOST}\" (this may take a while) ..."
      ping ${REMOTE_HOST} 1024 1
      if [ $? -ne 0 ] ; then
        die 57 "The other node is either not up or not reachable - can not check if the LDom is running on that host! Use the parameter \"force_start\" instead of \"start\" to start the LDom anyway " 
      else
        logMsg "Checking if the LDom \"${GUEST_LDOM}\" is running on the other node \"${REMOTE_HOST}\" ..."
        REMOTE_LDOM_STATUS="$( rsh ${REMOTE_HOST} /opt/SUNWldm/bin/ldm list -p "${GUEST_LDOM}"  | cut -f 3 -d "|" | grep -v VERSION )"
        if [ "${REMOTE_LDOM_STATUS}"x = "state=active"x ] ; then
            die 55 "The Guest LDom \"${GUEST_LDOM}\" is running on the node ${REMOTE_HOST}"
        fi
      fi
    fi

    case ${GUEST_LDOM_STATUS} in
      
      running ) 
        die 0 "The Guest LDom \"${GUEST_LDOM}\" is already running on this machine"
        ;;

      bound )
        logMsg "Starting the Guest LDom \"${GUEST_LDOM}\"..."
        
        if [ "${NFS_DIR_MOUNTED}"x = "no"x ] ; then
          logMsg "Mounting the directory with the disk images ..."
          mount "${MOUNT_POINT}" || die 60 "Error mounting \"${MOUNT_POINT}\" "
        fi

        ldm start  "${GUEST_LDOM}"
        NEW_GUEST_LDOM_STATUS=$( ldm list -p "${GUEST_LDOM}" | grep -v "VERSION"   | cut -f3 -d "|" )
        [ "${NEW_GUEST_LDOM_STATUS}"x != "state=active"x ] && die 65 "Error starting the Guest LDom \"${GUEST_LDOM}\" "

        die 0 " Guest LDom \"${GUEST_LDOM}\" started."
        ;;

      inactive )
        logMsg "Starting the Guest LDom \"${GUEST_LDOM}\"..."

        if [ "${NFS_DIR_MOUNTED}"x = "no"x ] ; then
          logMsg "Mounting the directory with the disk images ..."
          mount "${MOUNT_POINT}" || die 70 "Error mounting \"${MOUNT_POINT}\" "
        fi

        ldm bind  "${GUEST_LDOM}"
        NEW_GUEST_LDOM_STATUS=$( ldm list -p "${GUEST_LDOM}" | grep -v "VERSION"   | cut -f3 -d "|" )
        [ "${NEW_GUEST_LDOM_STATUS}"x != "state=bound"x ] && die 75 "Error binding the Guest LDom \"${GUEST_LDOM}\" "

        ldm start  "${GUEST_LDOM}"
        NEW_GUEST_LDOM_STATUS=$( ldm list -p "${GUEST_LDOM}" | grep -v "VERSION"   | cut -f3 -d "|" )
        [ "${NEW_GUEST_LDOM_STATUS}"x != "state=active"x ] && die 80 "Error starting the Guest LDom \"${GUEST_LDOM}\" "

        die 0 " Guest LDom \"${GUEST_LDOM}\" started."
        ;;

      * ) die 85 "Unknown status of the Guest LDom \"${GUEST_LDOM}\": \"${GUEST_LDOM_STATUS}\" " 
        ;;

    esac
    ;;
  
  stop )

    case ${GUEST_LDOM_STATUS} in
    
      running ) 
        logMsg "Stopping the Guest LDom \"${GUEST_LDOM}\" ..."
        ldm stop "${GUEST_LDOM}"
        
        NEW_GUEST_LDOM_STATUS=$( ldm list -p "${GUEST_LDOM}" | grep -v "VERSION"   | cut -f3 -d "|" )
        [ "${NEW_GUEST_LDOM_STATUS}"x != "state=bound"x ] && die 90 "Error stopping the Guest LDom \"${GUEST_LDOM}\" "
        
        ldm unbind  "${GUEST_LDOM}"
        NEW_GUEST_LDOM_STATUS=$( ldm list -p "${GUEST_LDOM}" | grep -v "VERSION"   | cut -f3 -d "|" )
        [ "${NEW_GUEST_LDOM_STATUS}"x != "state=inactive"x ] && die 95 "Error unbinding the Guest LDom \"${GUEST_LDOM}\" "
        if [ "${NFS_DIR_MOUNTED}"x = "yes"x ] ; then
          umount "${MOUNT_POINT}" || die 100 "Error umounting \"${MOUNT_POINT}\" "
        fi
        die 0 "Guest LDom \"${GUEST_LDOM}\" stopped and filesystem umounted."
        ;;

      bound )
        ldm unbind "${GUEST_LDOM}"
        NEW_GUEST_LDOM_STATUS=$( ldm list -p "${GUEST_LDOM}" | grep -v "VERSION"   | cut -f3 -d "|" )
        [ "${NEW_GUEST_LDOM_STATUS}"x != "state=inactive"x ] && die 105  "Error unbinding the Guest LDom \"${GUEST_LDOM}\" "

        if [ "${NFS_DIR_MOUNTED}"x = "yes"x ] ; then
          umount "${MOUNT_POINT}" || die 110 "Error umounting \"${MOUNT_POINT}\" "
        fi

        die 0 "The Guest LDom \"${GUEST_LDOM}\" is now off on this machine"
        ;;

      inactive )

        if [ "${NFS_DIR_MOUNTED}"x = "yes"x ] ; then
          umount "${MOUNT_POINT}" || die 115 "Error umounting \"${MOUNT_POINT}\" "
        fi

        die 0 "The Guest LDom \"${GUEST_LDOM}\" is already off on this machine"
        ;;

      * ) die 120 "Unknown status of the Guest LDom \"${GUEST_LDOM}\": \"${GUEST_LDOM_STATUS}\" " 
        ;;

    esac
    ;;
    
  status )
    die 0 "The current status of the Guest LDom \"${GUEST_LDOM}\" is \"${GUEST_LDOM_STATUS}\" "
    ;;


  * ) 
    die 125 "Invalid argument \"${ACTION}\" "
    ;;

esac

die 0

