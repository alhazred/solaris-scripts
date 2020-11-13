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

__SCRIPT_TEMPLATE_VERSION="1.03 02/19/2004"

__SHORT_DESC="split an ISO image into slices "
__SCRIPT_VERSION="1.00"

# set to 0 for scripts that must be executed by root only
__MUST_BE_ROOT=1

# set to 0 for scripts that can not run more than one instance at the same time
__ONLY_ONCE=1

__VERBOSE_MODE=1

__QUIET_MODE=1

# -----------------------------------------------------------------------------
#
# split_cdrom_isoimage.sh - split an ISO image into slices
#
# Author: Bernd Schemmer (Bernd.Schemmer@gmx.de)
#
# Version: ${__SCRIPT__VERSION}
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
__LIST_OF_TEMPFILES="${__TEMPFILE1} ${__TEMPFILE2}"

# lock file
__LOCKFILE="/tmp/${__SCRIPTNAME}.lock"
__LOCKFILE_CREATED=1

__EXITROUTINES=""

 typeset REST=
 who am i | read __USERID REST

# -----------------------------------------------------------------------------
# debugging routines
#

ShowGlobalVariables() {
 typeset CURVAR=

  LogMsg "Defined global variables: "
  for CURVAR in  __SCRIPT_VERSION \
                 __SCRIPT_TEMPLATE_VERSION __MUST_BE_ROOT __ONLY_ONCE \
                 __THISRC __VERBOSE_MODE  __QUIET_MODE \
                 __SCRIPTNAME __SCRIPTDIR  \
	         __HOSTNAME __OS __OS_VERSION __OS_RELEASE \
                 __MACHINE_CLASS __MACHINE_TYPE __MACHINE_ARC \
	         __START_DIR \
	         __LOCKFILE __LOCKFILE_CREATED \
                 __LOGFILE \
	         __TEMPFILE1 __TEMPFILE2 __LIST_OF_TEMPFILES \
	         __EXITROUTINES \
		 __USERID \
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
 
  


#
# Usage: LogMsg message_to_write
#
LogMsg() {
  typeset THISMSG="[$(date +"%d.%m.%Y %H:%M:%S")] $*"

  [  ${__QUIET_MODE} -ne 0 ] && echo ${THISMSG} 
  [ "${__LOGFILE}"x != ""x ] && [ -f ${__LOGFILE} ] &&  echo ${THISMSG} >>${__LOGFILE} 
}

#
# Usage: LogInfo message_to_write
#
LogInfo() {
  [ ${__VERBOSE_MODE} = 0 ] && LogMsg "INFO: $*"
}

#
# Usage: LogWarning message_to_write
#
LogWarning() {
  LogMsg "WARNING: $*"
}

#
# Usage: LogErrorMsg message_to_write
#
LogError() {
  LogMsg "ERROR: $*"
}

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

#
# Usage: CreateTemporayFiles
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

#
# Usage: DeleteTemporayFiles
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


#
# usage: BackupExistingFiles dir_to_backup backup_target_directory
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

#
# Usage: RestoreFilesFromBackup backup_dir dir_to_restore
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


#
# Function: Housekeeping
#
# Usage: cleanup
#
cleanup() {
  typeset EXIT_ROUTINE=
  
  DeleteTemporaryFiles
  
  [ ${__MUST_BE_ROOT} ] -eq 0 ] && RemoveLockFile

  if [ "${__EXITROUTINES}"x !=  ""x ] ; then
    LogInfo "Calling the exitroutines \"${__EXITROUTINES}\" ..."
    for EXIT_ROUTINE in ${__EXITROUTINES} ; do
      LogInfo "Calling the exitroutine \"${EXIT_ROUTINE}\" ..."
      eval ${EXIT_ROUTINE}
    done
  fi

}

#
# Usage: die returncode errorMessage
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
  __QUIET_MODE=1   
  LogMsg "${__SCRIPTNAME} ended on $( date )."
  LogMsg "The RC is ${THISRC}."
  
  exit ${THISRC}
}

#
# Trap handler
#
ScriptAbort() {
  die 501 "Script aborted by an external signal"
}

ShowUsage() {

cat <<EOT

  ${__SCRIPTNAME} ${__SCRIPT_VERSION} - ${__SHORT_DESC}

  Usage: ${__SCRIPTNAME} [-v] [-q] [-h] [-l logfile] [-i isoimage] [-o outputdir]
  
  Parameter:
    
      -v - turn verbose mode on
      -q - turn quiet mode on
      -h - show usage
      -l - set the logfile

      -i - iso image file
      -o - directory for the output files (def.: current directory)
EOT

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
# __EXITROUTINES="${EXITROUTINES} "  

  LogMsg "${__SCRIPTNAME} started on $( date ) "
  

  THIS_PARAMETER=$*
  set -- $( getopt vqhl:i:o: $* ) 
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

      "-v" ) __VERBOSE_MODE=0 ; shift
             ;;

      "-q" ) __QUIET_MODE=0 ; shift
             ;;

      "-i" ) ISO_IMAGE=$2; shift ; shift
             ;;

      "-o" ) OUTPUT_DIR=$2; shift ; shift
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

  if [ ${__MUST_BE_ROOT} -eq 0 ] ; then  
    UserIsRoot || die 498 "You must be root to execute this script" 
  fi

  if [ ${__ONLY_ONCE} = 0 ] ; then
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

  CreateTemporaryFiles

#  ShowGlobalVariables

split_slice() {

# split_slice - copy a slice from an ISO image
#
# Parameter:
# $1 - name of the iso image
# $2 - name of the vtoc file
# $3 - Offset of the start cylinder in the vtoc (decimal)
# $4 - name of the file for the slice image
#
  typeset ISO_IMAGE=$1
  typeset VTOC_FILE=$2
  typeset START_CYLINDER_POS=$3 
  typeset SLICE_FILE=$4  

# calculate the start cylinder and the length of the slice
  echo "  Calculating the slice infos ..."

  set -- `od -D -j ${START_CYLINDER_POS} -N 8 < ${VTOC_FILE}`
  START_CYLINDER=$2
  NO_OF_BLOCKS=$3

  if [ ${NO_OF_BLOCKS} = "0000000000" ] ; then
    echo "Slice not found. Skipping."
    return 0
  fi

  START_BLOCK=`echo ${START_CYLINDER}*640 | bc`

# create the slice
  echo "  Writing the slice (StartCylinder is ${START_BLOCK}, Length is ${NO_OF_BLOCKS}) ..."
  dd if=${ISO_IMAGE} of=${SLICE_FILE} bs=512 skip=${START_BLOCK} count=${NO_OF_BLOCKS}
  return $?
}

  echo $__SHORT_DESC
  echo

  if [ "$ISO_IMAGE"x = ""x ] ; then
    ShowUsage
    exit 0
  fi

  [ "${OUTPUT_DIR}"x = ""x ] && OUTPUT_DIR="."

  ISO_IMAGE_FILENAME=` basename ${ISO_IMAGE}` 

# create the vtoc
  VTOC_FILE=${OUTPUT_DIR}/${ISO_IMAGE_FILENAME}.vtoc
  echo "Creating the vtoc file in \"${VTOC_FILE}\" ..."
  dd if=${ISO_IMAGE} of=${VTOC_FILE} bs=512 count=1
  [ $? -ne 0 ] && die 4 "Can not create the vtoc file \"${VTOC_FILE}\" "
    
# slice 0
  SLICE_FILE=${OUTPUT_DIR}/${ISO_IMAGE_FILENAME}.s0
  echo "Creating slice 0 in \"${SLICE_FILE}\" ..."
  split_slice ${ISO_IMAGE} ${VTOC_FILE} 444 ${SLICE_FILE}

# slice 1
  SLICE_FILE=${OUTPUT_DIR}/${ISO_IMAGE_FILENAME}.s1
  echo "Creating slice 1 in \"${SLICE_FILE}\" ..."
  split_slice ${ISO_IMAGE} ${VTOC_FILE} 452 ${SLICE_FILE}

# slice 2
  SLICE_FILE=${OUTPUT_DIR}/${ISO_IMAGE_FILENAME}.s2
  echo "Creating slice 2 in \"${SLICE_FILE}\" ..."
  split_slice ${ISO_IMAGE} ${VTOC_FILE} 460 ${SLICE_FILE}

# slice 3
  SLICE_FILE=${OUTPUT_DIR}/${ISO_IMAGE_FILENAME}.s3
  echo "Creating slice 3 in \"${SLICE_FILE}\" ..."
  split_slice ${ISO_IMAGE} ${VTOC_FILE} 468 ${SLICE_FILE}

# slice 4
  SLICE_FILE=${OUTPUT_DIR}/${ISO_IMAGE_FILENAME}.s4
  echo "Creating slice 4 in \"${SLICE_FILE}\" ..."
  split_slice ${ISO_IMAGE} ${VTOC_FILE} 476 ${SLICE_FILE}

# slice 5
  SLICE_FILE=${OUTPUT_DIR}/${ISO_IMAGE_FILENAME}.s5
  echo "Creating slice 5 in \"${SLICE_FILE}\" ..."
  split_slice ${ISO_IMAGE} ${VTOC_FILE} 484 ${SLICE_FILE}

# slice 6
  SLICE_FILE=${OUTPUT_DIR}/${ISO_IMAGE_FILENAME}.s6
  echo "Creating slice 6 in \"${SLICE_FILE}\" ..."
  split_slice ${ISO_IMAGE} ${VTOC_FILE} 492 ${SLICE_FILE}

# slice 7
  SLICE_FILE=${OUTPUT_DIR}/${ISO_IMAGE_FILENAME}.s7
  echo "Creating slice 7 in \"${SLICE_FILE}\" ..."
  split_slice ${ISO_IMAGE} ${VTOC_FILE} 500 ${SLICE_FILE}

  echo " ... all done."

  die 0 
  
exit

