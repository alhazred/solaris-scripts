#
# This is a template for the installations scripts used by pkgadd
# You can use it for reqeust, checkinstall, preinstall, postinstall, preremove, and postremove scripts
#
# Tested with Solaris 8 and 9 (Sparc)
#
# general function provided by the script:
#
# die returncode message
#
# create_link source target
# create_directory dir_to_create [owner [group [mode] ] 
# create_file dir_to_create [owner [group [mode]]]
# AddToPackage file|link|directory
#
# DeleteTemporaryFiles
# CreateTemporaryFiles
#
# LogError message
# LogWarning message
# LogInfo message
# LogMsg message
# WriteToLogFile message
#
__SCRIPT_TEMPLATE_VERSION="1.02 08/16/2004"
__SHORT_DESC="pkgadd install script template"

# save the original parameter of the request and checkinstall script
__ORIGINAL_PARAMETER="$*"
__PKGADD_INPUT="$1"

__TRUE=0
__FALSE=1

# set to __TRUE if an check script exists for this package!
CHECKREQUEST_EXISTS=${__FALSE}

__SCRIPT_VERSION="1.00"

# for debugging only
__QUIET_MODE=${__FALSE}

[ "${DEBUG_SCRIPTS}" = "y" ] && __VERBOSE_MODE=${__TRUE} || __VERBOSE_MODE=${__FALSE}

# default users for new directories
__DEFAULT_DIR_OWNER="root"
__DEFAULT_DIR_GROUP="other"
__DEFAULT_DIR_MODE="755"

# default users for new files
__DEFAULT_FILE_OWNER="root"
__DEFAULT_FILE_GROUP="other"
__DEFAULT_FILE_MODE="755"


__INSTALLF_USED=${__FALSE}

# necessary work around to fool the checks of pkgmk in Solaris 9
__INSTALLF_CMD="install"
__INSTALLF_CMD="${__INSTALLF_CMD}f"


if [ "${LOGFILE}"x = ""x ] ; then
  if [ "${INST_DATADIR}"x = ""x ] ; then
    LOGFILE="/var/tmp/${PKGINST}.$$.LOG"    
  else
    LOGFILE="/var/tmp/${PKGINST}.`basename ${INST_DATADIR}`.LOG"
  fi
  touch ${LOGFILE}
  chmod 777 ${LOGFILE}
fi  

# necessary work around to fool the checks of pkgmk in Solaris 9

if [ "${INST_DATADIR}"x != ""x ] ; then
  CHECKINSTALL_PASS_FILE="/tmp/${PKGINST}.`basename ${INST_DATADIR}`.CHECKFILE"
else
  CHECKINSTALL_PASS_FILE="/tmp/${PKGINST}.CHECKFILE"
fi

# variables defined by pkgadd:
#
# CLIENT_BASEDIR - base directory on the target system
#
# INST_DATADIR - the directory with the package to install
#
# PKGINST - instance identifier
#
# PKGSAV - directory where files can be save for use by the remove scripts
#
# PKG_INSTALL_ROOT - root file system on the target system (only exists
#                    if pkgadd is called with -R
# 
# UPDATE - exists only if a package with the same name, version and 
#          architecture is already installed
#

# exit codes
#
SUCCESSFULL_RC=0
FATAL_ERROR_RC=1
WARNING_RC=2
CLEAN_HALT_RC=3
REBOOT_REQUIRED_AFTER_ALL_PKGS_RC=10
REBOOT_REQUIRED_IMMEDIATELY_RC=20

__SCRIPTNAME="`basename $0`"
__SCRIPTDIR="`dirname $0`"

__HOSTNAME="` uname -n `"
__OS="`uname`"
__OS_VERSION="`uname -r`"
__OS_RELEASE="`uname -v`"
__MACHINE_CLASS="`uname -m`"
__MACHINE_TYPE="`uname -i`"
__MACHINE_ARC="`uname -p`"

__START_DIR="`pwd`"


# temporary files
__TEMPFILE1="/tmp/${__SCRIPTNAME}.$$.TEMP1"
__TEMPFILE2="/tmp/${__SCRIPTNAME}.$$.TEMP2"
__LIST_OF_TEMPFILES="${__TEMPFILE1} ${__TEMPFILE2}"


# --------------------------------------
# WriteToLogFile
#
# write a message to the logfile only
#
# usage: WriteToLogFile message
#
# returns: -
#
WriteToLogFile() {
  __LOGMSG=`date +%d.%m.%Y %H:%M:%S`
  __LOGMSG="[ ${__LOGMSG} ] $*"

  [ ! "${LOGFILE}"x = ""x ] && [ -f ${LOGFILE} ] &&  echo "${__LOGMSG}" >>${LOGFILE} 
}

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
  WriteToLogFile "$*"

  [  ${__QUIET_MODE} -ne ${__TRUE} ] && echo "${__LOGMSG}"
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
  __CURFILE=

  __TEMPFILE_CREATED=${__TRUE}

  LogInfo "Creating the temporary files \"${__LIST_OF_TEMPFILES}\" ..."
  for __CURFILE in ${__LIST_OF_TEMPFILES} ; do
    LogInfo "Creating the temporary file \"${__CURFILE}\" "
    echo >${__CURFILE} || return $?
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
  __CURFILE=

  if [ "${__TEMPFILE_CREATED}"x = "${__TRUE}"x ] ; then
    LogInfo "Deleting the temporary files \"${__LIST_OF_TEMPFILES}\" ..."
    for __CURFILE in ${__LIST_OF_TEMPFILES} ; do
      [ ! -f ${__CURFILE} ] && continue

      LogInfo "Deleting the temporary file \"${__CURFILE}\" "
      rm ${__CURFILE} 
    done
  fi

  return 0
}

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
  EXIT_ROUTINE=
  
  DeleteTemporaryFiles

  if  [ ${__INSTALLF_USED} = ${__TRUE} ] ; then
    ${__INSTALLF_CMD} -f ${PKGINST}
  fi  

  if [ "${__EXITROUTINES}"x !=  ""x ] ; then
    LogInfo "Calling the exitroutines \"${__EXITROUTINES}\" ..."
    for EXIT_ROUTINE in ${__EXITROUTINES} ; do
      LogInfo "Calling the exitroutine \"${EXIT_ROUTINE}\" ..."
      eval ${EXIT_ROUTINE}
    done
  fi
}


# -----------------------------------------
#
# usage: AddToPackage filename|dirname|linkname
#
AddToPackage() {

  if [ "$1"x != ""x ] ; then
    if [ -f $1 -o -d $1 -o -L $1 ] ; then
      ${__INSTALLF_CMD} ${PKGINST} ${1} 
      [ $? -eq 0 ] && __INSTALLF_USED=${__TRUE}
    fi
  fi

}

# -----------------------------------------
#
# usage: create_file dir_to_create [owner [group [mode]]]
#
#
create_file() {

  __NEW_FILE="$1"
  [ "${__NEW_FILE}"x = ""x ] && return 1

  __FILE_OWNER=$2
  __FILE_GROUP=$3
  __FILE_MODE=$4

# use defaults if necessary
  [ "${__FILE_OWNER}"x = ""x ] && __FILE_OWNER=${__DEFAULT_FILE_OWNER}
  [ "${__FILE_GROUP}"x = ""x ] && __FILE_GROUP=${__DEFAULT_FILE_GROUP}
  [ "${__FILE_MODE}"x = ""x ]  && __FILE_MODE=${__DEFAULT_FILE_MODE}
  
  THISRC=0
    
  if [ -d  ${__NEW_FILE} ] ; then
    LogMsg "The file \"${__NEW_FILE}\" already exists."
    THISRC=1
  fi

  if [ ${THISRC} -eq 0 ] ; then
    LogMsg "Creating the file \"${__NEW_FILE}\" ..."   
    touch ${__NEW_FILE}
    THISRC=$?
    [ ${THISRC} -ne 0 ] && LogError "Error ${THISRC} creating the file"
  fi

  if [ ${THISRC} -eq 0 ] ; then
    LogMsg "Changing the owner and group of \"${__NEW_FILE}\" to \"${__FILE_OWNER}:${__FILE_GROUP}\" ..."
    chown ${__FILE_OWNER}:${__FILE_GROUP} ${__NEW_FILE}
    THISRC=$?
    [ ${THISRC} -ne 0 ] && LogError "Error ${THISRC} changing the owner of the file"
  fi

  if [ ${THISRC} -eq 0 ] ; then
    LogMsg "Changing the mode of \"${__NEW_FILE}\" to \"${__FILE_MODE}\" ..."
    chmod  ${__FILE_MODE} ${__NEW_FILE}
    THISRC=$?
    [ ${THISRC} -ne 0 ] && LogError "Error ${THISRC} changing the mode of the file"
  fi
 
  [ "${THISRC}" -eq 0 ] && AddToPackage ${__NEW_FILE}

  return ${THISRC}
}


# -----------------------------------------
#
# usage: create_directory dir_to_create [owner [group [mode] ] 
#
create_directory() {

  __NEW_DIRECTORY="$1"
  [ "${__NEW_DIRECTORY}"x = ""x ] && return 1

  __DIR_OWNER=$2
  __DIR_GROUP=$3
  __DIR_MODE=$4

# use defaults if necessary
  [ "${__DIR_OWNER}"x = ""x ] && __DIR_OWNER=${__DEFAULT_DIR_OWNER}
  [ "${__DIR_GROUP}"x = ""x ] && __DIR_GROUP=${__DEFAULT_DIR_GROUP}
  [ "${__DIR_MODE}"x = ""x ]  && __DIR_MODE=${__DEFAULT_DIR_MODE}
  
  THISRC=0
    
  if [ -d  ${__NEW_DIRECTORY} ] ; then
    LogMsg "The directory \"${__NEW_DIRECTORY}\" already exists."
    THISRC=1
  fi

  if [ ${THISRC} -eq 0 ] ; then
    LogMsg "Creating the directory \"${__NEW_DIRECTORY}\" ..."   

# workaround for pkgmk checks in Solaris 9
    MKDIR="mkdir"
    ${MKDIR} -p ${__NEW_DIRECTORY}

    THISRC=$?
    [ ${THISRC} -ne 0 ] && LogError "Error ${THISRC} creating the directory"
  fi

  if [ ${THISRC} -eq 0 ] ; then
    LogMsg "Changing the owner and group of \"${__NEW_DIRECTORY}\" to \"${__DIR_OWNER}:${__DIR_GROUP}\" ..."
    chown ${__DIR_OWNER}:${__DIR_GROUP} ${__NEW_DIRECTORY}
    THISRC=$?
    [ ${THISRC} -ne 0 ] && LogError "Error ${THISRC} changing the owner of the directory"
  fi

  if [ ${THISRC} -eq 0 ] ; then
    LogMsg "Changing the mode of \"${__NEW_DIRECTORY}\" to \"${__DIR_MODE}\" ..."
    chmod  ${__DIR_MODE} ${__NEW_DIRECTORY}
    THISRC=$?
    [ ${THISRC} -ne 0 ] && LogError "Error ${THISRC} changing the mode of the directory"
  fi

  [ "${THISRC}" -eq 0 ] && AddToPackage ${__NEW_DIRECTORY}

  return ${THISRC}
}


# -----------------------------------------
#
# usage: create_link source target
#
create_link() {
  __LINK_SOURCE=$1
  __LINK_TARGET=$2

  THISRC=0
  
  if [ -h ${__LINK_TARGET} ] ; then
    LogMsg "The link \"${__LINK_TARGET}\" already exists."
    THISRC=1
  fi

  if [ "${THISRC}" -eq 0 ] ; then
    LogMsg "Creating the link ${__LINK_TARGET} -> ${__LINK_SOURCE}"
    ln -s ${__LINK_SOURCE} ${__LINK_TARGET}
    THISRC=$?
    [ ${THISRC} -ne 0 ] && LogError "Error ${THISRC} creating the link"     
  fi    

  [ "${THISRC}" -eq 0 ] && AddToPackage ${__LINK_TARGET}

  return ${THISRC}
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
  THISRC=$1
  shift
  if [ "$*"x != ""x ] ; then
    if [ ${THISRC} = 0 ] ; then 
      LogMsg "$*" 
    else
      LogError "$*"
    fi
  fi
  cleanup

  LogMsg "The log file used was \"${LOGFILE}\" "
  __QUIET_MODE=${__FALSE}
  LogMsg "${__SCRIPTNAME} ended on ` date `."
  LogMsg "The RC is ${THISRC}."

  exit ${THISRC}
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
  die ${FATAL_ERROR_RC} "Script aborted by an external signal"
}

# ---------------------------------------
# request script
#
# Note: A request script can only modify the system environment
#       variables BASEDIR and CLASSES
#       All user defined variables can be changed
#       The defaults for user defined variables should be
#       in the pkginfo file
#
#       The script is exeucted as user install or nobody
#       The request script is not executed if a response file is given.
#
execute_request() {

  LogMsg "request script is running"

# construct base directory
  if [ ${CLIENT_BASEDIR} ] ; then
    LOCAL_BASE=${BASEDIR}
  else
    LOCAL_BASE=${PKG_INSTALL_ROOT}${BASEDIR}
  fi

  if [ "${__OS_VERSION}" != "5.8" -a "${__OS_VERSION}" != "5.9" ] ; then
    USER_RESPONSE=`ckyorn -d n  -p "This script is only tested with Solaris 5.8 and 5.9! Do you want to continue [y,N]?"` 
    [ "${USER_RESPONSE}" != "y" -a "${USER_RESPONSE}" != "Y" ] && die 15 "Installation aborted by the user."
  fi

  BASEDIR=` ckpath -aoy -d ${BASEDIR} -p \
    "Where do you want the application installed (def.: ${BASEDIR}) "` 

  DEBUG_SCRIPTS=`ckyorn -d n -p "Turn debuggin on (def.: n)?"` 
    
# make the enviroment variables available to the installation service
# and the other packaging scripts 
  cat >>${__PKGADD_INPUT} <<!
BASEDIR=${BASEDIR}  
LOGFILE="${LOGFILE}"
DEBUG_SCRIPTS="${DEBUG_SCRIPTS}"
!

}



# ---------------------------------------
# check install script
#
# Note: A check install script can only modify the system environment
#       variables BASEDIR and CLASSES
#       All user defined variables can be changed
#       The defaults for user defined variables should be
#       in the pkginfo file
#       The script is exeucted as user install or nobody
#
execute_checkinstall() {

  LogMsg "checkinstall script is running"

# make the enviroment variables available to the installation service
# and the other packaging scripts 
  cat >>${__PKGADD_INPUT} <<!
LOGFILE="${LOGFILE}"
!

}

# ---------------------------------------
# pre install script
#
execute_preinstall() {

  LogMsg "preinstall script is running"
  create_directory "/opt/testpkg/testdir"  
  create_file "/opt/testpkg/testfile"
  create_link "/opt/testpkg/testfile" "/opt/testpkg/testlink"

}

# ---------------------------------------
# post install script
#
execute_postinstall() {

  LogMsg "postinstall script is running"
}


# ---------------------------------------
# pre remove script
#
execute_preremove() {

  LogMsg "preremove script is running"

}

# ---------------------------------------
# post remove script
#
execute_postremove() {

  LogMsg "postremove script is running"

}

# -----------------------------------------------------------------------------
# main
#

  for CURVAR in CLIENT_BASEDIR BASEDIR INST_DATADIR PKGINST PKGSAV \
                PKG_INSTALL_ROOT UPDATE \
                LOGFILE ; do
    eval CURVALUE="\$${CURVAR}"
    LogInfo "The value of \"\$${CURVAR}\" is \"${CURVALUE}\" "
  done

  LogInfo "The parameter for this script are \"${__ORIGINAL_PARAMETER}\" "
  LogInfo "The input file for pkgadd is \"${__PKGADD_INPUT}\" "


  for CURVAR in __SCRIPTNAME __SCRIPTDIR  \
                __HOSTNAME __OS __OS_VERSION __OS_RELEASE  \
                __MACHINE_CLASS __MACHINE_TYPE __MACHINE_ARC __START_DIR \
                CHECKINSTALL_PASS_FILE \
                 \
             ; do
    eval CURVALUE="\$$CURVAR"
    LogInfo "The value of \"\$${CURVAR}\" is \"${CURVALUE}\" "
  done
  
  __TEMPFILE_CREATED=${__FALSE}

  trap ScriptAbort 1 2 3 4 6 9 15
  
# add additional exit routines
# __EXITROUTINES="${EXITROUTINES} CheckReboot"  

  LogMsg "${__SCRIPTNAME} started on `date` "
  
  LogInfo "Script template used is \"${__SCRIPT_TEMPLATE_VERSION}\" ."

  LogMsg "Using the log file \"${LOGFILE}\" "

  if [ "${__OS_VERSION}" != "5.8" -a "${__OS_VERSION}" != "5.9" ] ; then
    LogWarning "This script is only tested with Solaris 5.8 and 5.9! Use at your own risk!"
  fi
  
#  CreateTemporaryFiles

# request* etc are necessary work arounds for pkgadd in Solaris 9
  
  case ${__SCRIPTNAME} in 

   request*)
      __SCRIPT_TYPE="request"
      execute_request
      ;;

   checkinstall*)

# work around for Solaris 9+ pkgadd behaviour
      if [ "${__OS_VERSION}" = "5.9" -o "${__OS_VERSION}" = "5.10" ] ; then
        if [ ! -f ${CHECKINSTALL_PASS_FILE} -a ${CHECKREQUEST_EXISTS} = ${__TRUE} ] ; then
          touch  ${CHECKINSTALL_PASS_FILE}
          chmod 777 ${CHECKINSTALL_PASS_FILE}
          __SCRIPT_TYPE="request"
          execute_request    
        else
          rm  ${CHECKINSTALL_PASS_FILE}
          __SCRIPT_TYPE="checkinstall"
          execute_checkinstall
        fi
      else
        execute_checkinstall
      fi
      ;;

   preinstall*)
      [ -f ${CHECKINSTALL_PASS_FILE} ] && rm  ${CHECKINSTALL_PASS_FILE}

      __SCRIPT_TYPE="preinstall"
      execute_preinstall
      ;;

   postinstall* )
      [ -f ${CHECKINSTALL_PASS_FILE} ] && rm  ${CHECKINSTALL_PASS_FILE}
      __SCRIPT_TYPE="postinstall"
      execute_postinstall
      ;;

   preremove* )
      __SCRIPT_TYPE="preremove"
      execute_preremove
      ;;

   postremove* )
      __SCRIPT_TYPE="postremove"
      execute_postremove
      ;;

   * )
      die ${FATAL_ERROR_RC} "I do not know who I am - exiting"
     ;; 

   esac
   
  die ${SUCCESSFULL_RC} 
  
exit

# additinal package files
#
# compver - define previous versions of the package that are compatible with
#           this version
#
# copyright - defines a copyright message 
#
# depend  - indicates other packages with  which this package has special
#           relationships
#
# space   - defines additionaldisk space requirements
#
#
# Creating a package:
#    pkgproto
#    pkgmk
#    pkgtrans
#
