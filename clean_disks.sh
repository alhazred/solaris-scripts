#!/bin/ksh
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

__SCRIPT_TEMPLATE_VERSION="1.08 07/05/2004"
__SHORT_DESC="wipe out disks"

__TRUE=0
__FALSE=1

__SCRIPT_VERSION="1.00"

# set to ${__TRUE} for scripts that must be executed by root only
__MUST_BE_ROOT=${__TRUE}

# set to ${__TRUE} for scripts that can not run more than one instance at the same time
__ONLY_ONCE=${__FALSE}

__VERBOSE_MODE=${__FALSE}

__QUIET_MODE=${__FALSE}


  DISKS_TO_EXCLUDE=""
  DEF_WRITE_COUNT=3
  WRITE_COUNT=${DEF_WRITE_COUNT}  
  XSERVER_ADDRESS=""
  
# -----------------------------------------------------------------------------
#
# script to wipeout harddisks
#
# Author: Bernd Schemmer (Bernd.Schemmer@gmx.de)
#
# Version: ${__SCRIPT__TEMPLATE_VERSION}
#
# Supported OS: Solaris 
#
# -----------------------------------------------------------------------------

#
# --------------------------------------
#
# Search the directory with this script and the other template scripts
#
###: $( ls -l $0 )
###REAL_SCRIPT=$_
###if [ "$OLD_PWD" = ""  ] ; then
###  OLD_PWD=1; export OLD_PWD
###  cd $(dirname $0)
###  THISDIR=$( $REAL_SCRIPT )
###else
###  cd $( dirname $0 )
###  echo $PWD/
###  exit
###fi

# -----------------------------------------------------------------------------
#

#  -- add exit routines here


# -----------------------------------------------------------------------------
# init the global variables
#

__THISRC=0

__USER_RESPONSE_IS=""

__SCRIPTNAME="$( basename $0 )"
__SCRIPTDIR="$( dirname $0 )"

__HOSTNAME="$( uname -n )"
__OS="$( uname -s)"
__OS_VERSION="$( uname -r)"
__OS_RELEASE="$( uname -v)"
__MACHINE_CLASS="$( uname -m )"
__MACHINE_TYPE="$( uname -i )"
__MACHINE_ARC="$( uname -p )"

__START_DIR="$( pwd )"

__LOGFILE="/var/tmp/${__SCRIPTNAME}.LOG"

# temporary files
__TEMPFILE1="/tmp/${__SCRIPTNAME}.$$.TEMP1"
__TEMPFILE2="/tmp/${__SCRIPTNAME}.$$.TEMP2"
__LIST_OF_TEMPFILES="${__TEMPFILE1} ${__TEMPFILE2} "

# lock file
__LOCKFILE="/tmp/${__SCRIPTNAME}.lock"
__LOCKFILE_CREATED=1

__EXITROUTINES=""

# reboot necessary ?
__REBOOT_REQUIRED=${__FALSE}
__REBOOT_PARAMETER=""

 typeset REST=
 who am i | read __USERID REST

# -----------------------------------------------------------------------------
# debugging routines
#

# --------------------------------------
# ShowGlobalVariables
#
# print all global variables and their values
#
# usage: ShwoGlobalVariables
#
# returns: -
#
ShowGlobalVariables() {
 typeset CURVAR=

  LogMsg "Defined global variables: "
  for CURVAR in  __SCRIPT_VERSION __SHORT_DESC \
                 __USER_RESPONSE_IS __TRUE __FALSE \
                 __SCRIPT_TEMPLATE_VERSION __MUST_BE_ROOT __ONLY_ONCE \
                 __THISRC __VERBOSE_MODE  __QUIET_MODE \
                 __SCRIPTNAME __SCRIPTDIR  __PROG_DIR \
	         __HOSTNAME __OS __OS_VERSION __OS_RELEASE \
                 __MACHINE_CLASS __MACHINE_TYPE __MACHINE_ARC \
	         __START_DIR \
	         __LOCKFILE __LOCKFILE_CREATED \
                 __LOGFILE \
	         __TEMPFILE1 __TEMPFILE2 __LIST_OF_TEMPFILES \
	         __EXITROUTINES \
		 __USERID \
		 __REBOOT_REQUIRED __REBOOT_PARAMETER  \
	       ;
 do
   eval "CURVALUE=\$${CURVAR}"
   LogMsg " \"${CURVAR}\" is \"${CURVALUE}\" "
 done	  

}


# -----------------------------------------------------------------------------
# sub routines
#

# --------------------------------------
# GetProgramDirectory
#
# get the directory where a program resides
#
# usage: GetProgramDir [programpath/]progranname
#
# returns: PRGDIR=<the directory with the program>
#
GetProgramDirectory() {
  
# resolve links - $1 may be a softlink
  typeset PRG="$1"
   
  while [ -h "$PRG" ] ; do
    ls=`ls -ld "$PRG"`
    link=`expr "$ls" : '.*-> \(.*\)$'`
    if expr "$link" : '.*/.*' > /dev/null; then
      PRG="$link"
    else
      PRG=`dirname "$PRG"`/"$link"
    fi
  done
 
  PRGDIR=`dirname "$PRG"`
}


# --------------------------------------
# UserIsRoot
#
# validate the user id
#
# usage: UserIsRoot
#
# returns: 0 - the user is root; else not
#
UserIsRoot() {
  typeset UID=`id | /usr/bin/sed 's/uid=\([0-9]*\)(.*/\1/'`
  [ ${UID} = 0 ] && return 0 || return 1
}


# --------------------------------------
# UserIs
#
# validate the user id
#
# usage: UserIs USERID
#
# where: USERID - userid (e.g oracle)
#
# returns: 0 - the user is this user
#          1 - the user is NOT this user
#          2 - the user does not exist on this machine
#          3 - missing parameter
#
UserIs() {
  typeset THISRC=3
  typeset USERID=""
  
  if [ "$1"x != ""x ] ; then
    THISRC=2
    USERID=` grep "^$1:" /etc/passwd | cut -d: -f3` 
    if [ "${USERID}"x != ""x ] ; then
      UID=`id | /usr/bin/sed 's/uid=\([0-9]*\)(.*/\1/'`
      [ ${UID} = ${USERID} ] && THISRC=0 || THISRC=1   
    fi
  fi

  return ${THISRC}
}

# ======================================
 
# --------------------------------------
# LogMsg
#
# print a message to STDOUT and write it also to the logfile
#
# usage: LogMsg message
#
# returns: -
#
LogMsg() {
  typeset THISMSG="[$(date +"%d.%m.%Y %H:%M:%S")] $*"

  [  ${__QUIET_MODE} -ne ${__TRUE} ] && echo "${THISMSG}" 
  [ "${__LOGFILE}"x != ""x ] && [ -f ${__LOGFILE} ] &&  echo "${THISMSG}" >>${__LOGFILE} 
}

# --------------------------------------
# LogInfo
#
# print a message to STDOUT and write it also to the logfile 
# only if in verbose mode
#
# usage: LogInfo message
#
# returns: -
#
LogInfo() {
  [ ${__VERBOSE_MODE} = ${__TRUE} ] && LogMsg "INFO: $*"
}

# --------------------------------------
# LogWarning
#
# print a warning to STDOUT and write it also to the logfile
#
# usage: LogWarning message
#
# returns: -
#
LogWarning() {
  LogMsg "WARNING: $*"
}

# --------------------------------------
# LogError
#
# print an error message to STDOUT and write it also to the logfile
#
# usage: LogError message
#
# returns: -
#
LogError() {
  LogMsg "ERROR: $*"
}

# ======================================

# --------------------------------------
# CreateLockFile
#
# Create the lock file if possible
#
# usage: CreateLockFile
#
# returns: 0 - lock file created
#          1 - lock file already exist
#          2 - error creating the lock file
#
CreateLockFile() {
  [ -f ${__LOCKFILE} ] && return 1
  echo "lockfile of $0 (PID $$) " >${__LOCKFILE}
  if [ $? -eq 0 ] ; then
    __LOCKFILE_CREATED=0
    return 0
  fi
  return 2
}

# --------------------------------------
# RemoveLockFile
#
# Remove the lock file if possible
#
# usage: RemoveLockFile
#
# returns: 0 - lock file removed
#          1 - lock file does not exist
#          2 - error removing the lock file
#
RemoveLockFile() {
  [ ! -f ${__LOCKFILE} ] && return 1
  if [ ${__LOCKFILE_CREATED} = 0 ] ; then
    rm ${__LOCKFILE} 1>/dev/null 2>/dev/null
    [ $? -eq 0 ] && return 0
  fi  
  return 2
}

# ======================================

# --------------------------------------
# CreateTemporaryFiles
#
# create the temporary files
#
# usage: CreateTemporaryFiles
#
# returns: -
#
CreateTemporaryFiles() {
  typeset CURFILE=

  __TEMPFILE_CREATED=0

  LogInfo "Creating the temporary files \"${__LIST_OF_TEMPFILES}\" ..."
  for CURFILE in ${__LIST_OF_TEMPFILES} ; do
    LogInfo "Creating the temporary file \"${CURFILE}\" "
    echo >${CURFILE} || return $?
  done

  return 0
}

# --------------------------------------
# DeleteTemporaryFiles
#
# delete the temporary files
#
# usage: DeleteTemporaryFiles
#
# returns: -
#
DeleteTemporaryFiles() {
  typeset CURFILE=

  if [ "${__TEMPFILE_CREATED}"x = "0"x ] ; then
    LogInfo "Deleting the temporary files \"${__LIST_OF_TEMPFILES}\" ..."
    for CURFILE in ${__LIST_OF_TEMPFILES} ; do
      [ ! -f ${CURFILE} ] && continue

      LogInfo "Deleting the temporary file \"${CURFILE}\" "
      rm ${CURFILE} 
    done
  fi

  return 0
}

# ======================================

# ---------------------------------------
# BackupExistingFiles
#
# backup all files in a directory (without subdirectories)
#
# usage: BackupExistingFiles dir_to_backup backup_target_directory
#
# returns: -
#
BackupExistingFiles() {
  typeset THISRC=1
  typeset OLD_PWD=$( pwd )
  typeset i=
    
  if [  "$1"x != ""x -a  "$2"x != ""x ] ; then
    if [ -d $1 -a -d $2 ] ; then
      LogMsg "Creating a backup of \"$1\" in \"$2\" "
      THISRC=0
      cd $1
      for i in * ; do
        LogInfo "Copying \"$1/$i\" to \"$2/$i\" "
	if [ -f $1/$i ] ; then
          cp $1/$i $2/$i
          [ $? -gt ${THISRC} ] && THISRC=$?
	fi
      done
    fi 
  fi

  cd ${OLD_PWD}
  return ${THISRC}
}

# ---------------------------------------
# RestoreFilesFromBackup
#
# restore all files in a directory (without subdirectories)
#
# usage: RestoreFilesFromBackup backup_dir dir_to_restore
#
# returns: -
#
RestoreFilesFromBackup() {
  typeset THISRC=1
  typeset OLD_PWD=$( pwd )
  typeset i=
  
  if [  "$1"x != ""x -a  "$2"x != ""x ] ; then
    if [ -d $1 -a -d $2 ] ; then
      LogMsg "Restoring the backup from \"$1\" to \"$2\" "
  
      THISRC=0
      cd $1
      for i in * ; do
        LogInfo "Copying \"$1/$i\" to \"$2/$i\" "
	if [ -f $1/$i ] ; then 
	  cp $1/$i $2/$i
	  [ $? -gt ${THISRC} ] && THISRC=$?
        fi	
      done
    fi 
  fi

  cd ${OLD_PWD}
  return ${THISRC}
}


# ======================================

# ---------------------------------------
# cleanup
#
# house keeping at program end
#
# usage: cleanup
#
# returns: -
#
cleanup() {
  typeset EXIT_ROUTINE=
  
  DeleteTemporaryFiles
  
  [ ${__MUST_BE_ROOT} ] -eq ${__TRUE} ] && RemoveLockFile

  if [ "${__EXITROUTINES}"x !=  ""x ] ; then
    LogInfo "Calling the exitroutines \"${__EXITROUTINES}\" ..."
    for EXIT_ROUTINE in ${__EXITROUTINES} ; do
      LogInfo "Calling the exitroutine \"${EXIT_ROUTINE}\" ..."
      eval ${EXIT_ROUTINE}
    done
  fi
}

# ---------------------------------------
# die
#
# print an message and end the program
#
# usage: die returncode message
#
# returns: -
#
die() {
  typeset THISRC=$1
  shift
  if [ "$*"x != ""x ] ; then
    if [ ${THISRC} = 0 ] ; then 
      LogMsg "$*" 
    else
      LogError "$*"
    fi
  fi
  cleanup

  LogMsg "The log file used was \"${__LOGFILE}\" "
  __QUIET_MODE=${__FALSE}
  LogMsg "${__SCRIPTNAME} ended on $( date )."
  LogMsg "The RC is ${THISRC}."
  
  exit ${THISRC}
}

# --------------------------------------
# AskUser
#
# Ask the user (or use defaults depending on the parameter -n and -y)
#
# Usage: AskUser "message" 
#        
# returns USER_INPUT contains the user input
#
AskUser() {

  typeset THISRC=""
  
  case ${__USER_RESPONSE_IS} in 
     
   "y" ) USER_INPUT="y" ; THISRC=${__TRUE} ; shift
         ;;

   "n" ) USER_INPUT="n" ; THISRC=${__FALSE} ; shift
         ;;
	   
     * ) printf "$* "
         read USER_INPUT
         ;;
  esac	  

  return ${THISRC}
}

# --------------------------------------
# CheckReboot
#
# Check if a reboot is necessary
#
# Usage: CheckReboot
#
CheckReboot() {
  typeset USER_INPUT=
  
  if [ ${__REBOOT_REQUIRED} -eq 0 ] ; then
    LogMsg "The changes made to the system require a reboot"

    AskUser "Do you want to reboot new (y/n, default is NO)?"
    if [ ${USER_INPUT} = "y" ] ; then
      LogMsg "Rebooting now ..."
      echo "???" reboot ${__REBOOT_PARAMETER}
    fi
  fi
}

# ---------------------------------------
# ScriptAbort
#
# script handler for signals
#
# usage: -
#
# returns: -
#
ScriptAbort() {
  die 501 "Script aborted by an external signal"
}

# ======================================

# ---------------------------------------
# ShowUsage
#
# print the usage help
#
# usage: ShowUsage
#
# returns: -
#
ShowUsage() {

cat <<EOT

  ${__SCRIPTNAME} ${__SCRIPT_VERSION} - ${__SHORT_DESC}

  Usage: ${__SCRIPTNAME} [-v] [-q] [-h] [-l logfile] [-y|-n] [-x] 
                        [-N count] [-x exclude_disk] [-X xserveraddr]
  
  Parameter:

      -N - "count" is the no of writes (def.:${DEF_WRITE_COUNT})
      -x - do not wipe the disk "exclude_disk"
      -X - start every format in an xterm a on the xserver "xserveraddr"

      -v - turn verbose mode on
      -q - turn quiet mode on
      -h - show usage
      -l - set the logfile
      -y - assume yes to all questions
      -n - assume no to all questions

EOT

  return 0      
}

# ---------------------------------------
# DetectBootDisk
#
# try to detect the boot disk
#
# usage: DetectBootDisk
#
# returns: ROOTDISK contains a list of boot disks (or "" if no root disks are detected)
#          ROOTDISK_OK is $__TRUE if we're sure or $__FALSE if not
#
# Notes: This code works only for plain slices and SDS mirrors correct; 
#        for Veritas volumes it may or may not work
#
#        14.07.2004: NOT USED AT THIS TIME BECAUSE I HAVE TO DO FURTHER TESTING /bs
#
DetectBootDisk() {

  ROOTDISK=""
  ROOTDISK_OK="${__FALSE}"
  
  typeset METADEVICE=""
  typeset ROOTDISK1=""
  typeset ROOTDISK2=""
  
# try to get the root disk ...
  set -- `df -k | grep -i "/$"`
  oIFS="$IFS"
  IFS="/"
  set -- $1
  IFS="$oIFS"

  if [ "$3"x = "md"x ] ; then
# the root disk is a meta device (SDS)
  METADEVICE=$5
  set -- `metastat -p $5`
    if [ "$2" = "-m" ] ; then
# the root disk is a mirrored metadevice
      set -- `metastat -p $3` 
      ROOTDISK1=${4%%s*}
      set -- `metastat -p $4` 
      ROOTDISK1=${4%%s*}
      ROOTDISK="${ROOTDISK1} ${ROOTDISK2}"
    else 
# the root disk is a simple meta device (SDS)
      ROOTDISK=${4%%s*}
    fi
  elif [ "$3"x = "vx"x ] ; then
# the root disk is a veritas device (VxVM)
    set -- `vxdisk -q -g rootdg list`
    ROOTDISK=${1%%s*}
  else
  # the root disk is a plain slice
    ROOTDISK=${4%%s*}
    ROOTDISK_OK=${__TRUE}
  fi

return 0
}

# -----------------------------------------------------------------------------
# main
#

# use a temporary log file until we know the real log file

  
  __TEMPFILE_CREATED=1
  __MAIN_LOGFILE=${__LOGFILE}
  
  __LOGFILE="${__LOGFILE}.$$.TEMP"
  echo >${__LOGFILE}

  trap ScriptAbort 1 2 3 4 6 9 15
  
# add additional exit routines
# __EXITROUTINES="${EXITROUTINES} CheckReboot"  

  LogMsg "${__SCRIPTNAME} started on $( date ) "
  
  THIS_PARAMETER=$*
  set -- $( getopt ynvqhl:x:N:X: $* ) 
  if [ $? != 0 ] ; then
    LogError "Error evaluating the parameter \"${THIS_PARAMETER}\" "
    ShowUsage
    die 1
  fi
  PROCESSED_PARAMETER=$*
   
  for i in $* ; do
   
    case $i in 

      "-l" ) NEW_LOGFILE=$2; shift ; shift
             ;;
	     
      "-h" ) ShowUsage ; shift 
             die 1
             ;;

      "-v" ) __VERBOSE_MODE=${__TRUE} ; shift
             ;;

      "-q" ) __QUIET_MODE=${__TRUE} ; shift
             ;;

      "-y" ) __USER_RESPONSE_IS="y"; shift 
             ;;

      "-n" ) __USER_RESPONSE_IS="n"; shift 
             ;;     

      "-x" ) DISKS_TO_EXCLUDE="${DISKS_TO_EXCLUDE} $2"; shift; shift
             ;;

      "-N" ) WRITE_COUNT=$2 ; shift ; shift
             ;;
      
      "-X" ) XSERVER_ADDRESS=$2; shift ; shift
             ;;
	     
      "--" ) shift; break 
             ;;
	          	    
    esac
  done

  LogInfo "Parameter after the options are: " "\"$*\" "
  
# copy the temporary log file to the real log file

  LogInfo "Script template used is \"${__SCRIPT_TEMPLATE_VERSION}\" ."

  [ "${NEW_LOGFILE}"x != ""x ] && __MAIN_LOGFILE=${NEW_LOGFILE}
  LogInfo "Initializing the log file\"${__MAIN_LOGFILE}\" "

  touch ${__MAIN_LOGFILE} 2>/dev/null
  cat ${__LOGFILE} >>${__MAIN_LOGFILE} 2>/dev/null
  if [ $? -ne 0 ]   ; then
    LogWarning "Error writing to the logfile \"${__MAIN_LOGFILE}\"."
    LogWarning "Using the log file \"${__LOGFILE}\" "
  else
    rm ${__LOGFILE} 2>/dev/null
    __LOGFILE=${__MAIN_LOGFILE}       
  fi

  LogMsg "Using the log file \"${__LOGFILE}\" "
  LogInfo "Parameter before getopt processing are: \"${THIS_PARAMETER}\" "
  LogInfo "Parameter after getopt processing are: \"${PROCESSED_PARAMETER}\" "

  if [ ${__MUST_BE_ROOT} -eq ${__TRUE} ] ; then  
    UserIsRoot || die 498 "You must be root to execute this script" 
  fi

  if [ ${__ONLY_ONCE} = ${__TRUE} ] ; then
    CreateLockFile
    if [ $? -ne 0 ] ; then
      cat <<EOF

  ERROR:

  Either another instance of this script is already running
  or the last execution of this script crashes.
  In the first case wait until the other instances ends; 
  in the second case delete the lock file 
  
      ${__LOCKFILE} 

  manually and restart the script.

EOF
    die 499
    fi
  fi
  
  GetProgramDirectory $0
  __PROG_DIR=${PRGDIR}

  CreateTemporaryFiles

#  ShowGlobalVariables
#  echo \"${__PROG_DIR}\"

# input file for format
  FORMAT_INPUTFILE="/tmp/format.$$.input"
  
# logfile for format
  FORMAT_LOGFILE="/tmp/format.$$:log"
  
# scripts for the xterms 
  XTERM_SCRIPTS="/tmp/$__SCRIPTNAME.$$"
  
  
# check the bootdisk parameter (if any)
  for i in ${DISKS_TO_EXCLUDE} ; do
    [ ! -c /dev/rdsk/${i} -a ! -c /dev/rdsk/${i}s0 ] && die 4 "The disk \"/dev/rdsk/${i}\" does not exist."
  done   

# create the input file for format
  cat <<EOT >>${FORMAT_INPUTFILE}
analyze 
setup 
yes 
no 
${WRITE_COUNT} 
yes 
no 
yes 
126 
yes 
no 
yes 
yes 
write 
quit 
quit 
EOT
 
  LogMsg "Building the list of existing disks ...." 

# create the egrep pattern for the disks to exclude
  EGREP_PATTERN=""
  for i in ${DISKS_TO_EXCLUDE} ;  do
    if [ "${EGREP_PATTERN}"x = ""x ] ; then
      EGREP_PATTERN="${i%%s*}"
    else
      EGREP_PATTERN="${EGREP_PATTERN}|${i%%s*}"
    fi
  done
  
# create a list of all existing disks
  if [ "${EGREP_PATTERN}"x = ""x ] ; then
    DEVICE_LIST=`echo| format | grep ". c" | awk '{ print $2 } ;' | sed s/s[0-9]//g `
  else
    DEVICE_LIST=`echo| format | grep ". c" | awk '{ print $2 } ;' | sed s/s[0-9]//g | egrep -v ${EGREP_PATTERN} `
  fi


# check if we should and can use an xterm
  if [ "${XSERVER_ADDRESS}"x != ""x ] ; then
    LogMsg "Using xterm(s) on \"${XSERVER_ADDRESS}\" for the output"
    set  -- `which xterm` 
    XTERM_BIN="$1"
    [ "${XTERM_BIN}"x = "no"x ] && XTERM_BIN="/usr/openwin/bin/xterm"
    [ ! -f ${XTERM_BIN} ] && die 7 "Can not find the xterm binary!"
  fi

  
  if [ "${DISKS_TO_EXCLUDE}"x != ""x ] ; then
    LogMsg "Skipping the disks"
    for i in ${DISKS_TO_EXCLUDE} ; do
      LogMsg "    $i"
    done
  else
    LogMsg "No devices to skip (no -x parameter)"
  fi
  
  [ "${DEVICE_LIST}"x = ""x ] && die 0 "No disks to wipe found"

  LogMsg "Wiping the disks "
  for i in ${DEVICE_LIST} ; do
    LogMsg "    $i"
  done
  LogMsg " ${WRITE_COUNT} times."
  AskUser "Start wiping these disks now? "
  
  if [ "${USER_INPUT}"x = "y"x ] ; then
  
# format every disk
    for i in ${DEVICE_LIST}; do 
      if [ "${XSERVER_ADDRESS}"x = ""x ] ; then
        LogMsg "Wiping $i ..."
        format -f ${FORMAT_INPUTFILE} -l ${FORMAT_LOGFILE}_${i} -d ${i}  >/dev/null 2>&1 & 
      else
        LogMsg "Starting an xterm to wipe the disk $i ..."

	CUR_SCRIPT=${XTERM_SCRIPTS}.$i.sh
	cp $0 ${CUR_SCRIPT}

	echo "format -f ${FORMAT_INPUTFILE} -l ${FORMAT_LOGFILE}_${i} -d ${i}" >${CUR_SCRIPT}
        ${XTERM_BIN} -d ${XSERVER_ADDRESS} -e ${CUR_SCRIPT} &
      fi        
    done 

    die 0 
  else
    die 1 "Program aborted by the user"
  fi
  
  die 0 
  
exit
