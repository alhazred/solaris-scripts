#!/bin/ksh
## last exit code defined is 95
## -----------------------------------------------------------------------------
##
## easycd.sh - process CDs, DVDs, or ISO images
##
## Author: Bernd Schemmer (Bernd.Schemmer@gmx.de)
##
## Version: see variable ${__SCRIPT_VERSION} below
##          (see variable ${__SCRIPT_TEMPLATE_VERSION} for the template 
##           version used)
##
## Supported OS: Solaris 8 and newer
##
##
## Description
## 
## shell script to process CDs, DVDs, or ISO images
##
## History
##
##  	05/01/03 /bs	initial release
##	05/02/01 /bs	minor corrections
##      05/02/15 /bs    minor corrections
##	05/04/07 /bs	added verify commands & switches
##      06/04/01 /bs    added parameter "-x createconfig"
##      06/02/14 /bs    added add. parameter for mkisofs 
##                      (parameter writecdrom writecd writedvd createISOimg)
##      06/07/14 /bs    corrected a bug in the color definition for COLOR_OFF
##                      
##
## Predefined return codes:
##
##    1 - show usage and exit
##    2 - invalid parameter found
##
##  498 - Script not executed by root
##  499 - Script is already running
##
##  500 - User break
##  501 - QUIT signal received
##  502 - CTRL-C signal received
##  503 - TERM signal received
##  504 - external signal received
##   

# -----------------------------------------------------------------------------

## __SHORT_DESC - short description (for help texts, etc)
##                Change to your need
##
typeset -r __SHORT_DESC=" wrapper script for cdrecord & co"

## __SCRIPT_VERSION - the version of your script 
##
typeset -r __SCRIPT_VERSION="0.06"

##
## --- defined read only variables
##
## __SCRIPT_TEMPLATE_VERSION - version of the template
##
typeset -r __SCRIPT_TEMPLATE_VERSION="1.15.1 14/12/2004"

## __TRUE - true (0)
## __FALSE - false (1)
##
typeset -r __TRUE=0
typeset -r __FALSE=1

## 
## --- defined variables that may be changed
##
## __MUST_BE_ROOT (def.: false)
##   set to ${__TRUE} for scripts that must be executed by root only
##
__MUST_BE_ROOT=${__TRUE}

## __ONLY_ONCE (def.: false)
##   set to ${__TRUE} for scripts that can not run more than one 
##   instance at the same time
##
__ONLY_ONCE=${__FALSE}

## __VERBOSE_MODE - print verbose messages (def. false)
##   use the parameter -v to set this variable to true
##
__VERBOSE_MODE=${__FALSE}

## __VERBOSE_LEVEL - count of -v parameter (def. 0)
##
typeset -i __VERBOSE_LEVEL=0

## __QUIET_MODE - print no messages (def.: false)
##   use the parameter -q to set this variable to true
##
__QUIET_MODE=${__FALSE}

## __USER_BREAK_ALLOWED - CTRL-C aborts program or not (def. true)
##   (no parameter to change this variable)
##
__USER_BREAK_ALLOWED=${__TRUE}

## __OVERWRITE mode - overwrite existing files or not (def. false
##   use the parameter -O to change this variable
__OVERWRITE_MODE=${__FALSE}

## __DEBUG_MODE - use single step mode for main (def. false)
##   use the parameter -D to set this variable
##
__DEBUG_MODE=${__FALSE}
__SCRIPT_ARRAY[0]=0

# internal variables for the single-step routine
typeset -i __BREAKPOINT_LINE=0 
typeset -i __STEP_COUNT=0
typeset -i __TRACE_COUNT=0

# -----------------------------------------------------------------------------
#
# aliase
alias traceon="set -x"
alias traceoff="set +x"

alias invers="echo \${__COLOR_REVERSE}\c"
alias normal="echo \${__COLOR_OFF}"
alias red_on_white="echo \${__COLOR_FG_RED}\${__COLOR_BG_WHITE}\c"

# -----------------------------------------------------------------------------
# init the global variables
#

## 
## --- defined variables that should not be changed
##

__THISRC=0

__USER_RESPONSE_IS=""


## __SCRIPTNAME - name of the script without the path
##
__SCRIPTNAME="$( basename $0 )"

## __SCRIPTDIR - path of the script (as entered by the user!)
##
__SCRIPTDIR="$( dirname $0 )"

## __REAL_SCRIPTDIR - path of the script (real path, maybe a link)
##
__REAL_SCRIPTDIR=$( cd -P -- "$(dirname -- "$(command -v -- "$0")")" && pwd -P )

## __CONFIG_FILE - name of the config file
##
__CONFIG_FILE="${__SCRIPTNAME%.*}.conf"
__BASE_CONFIG_FILE="easycd.conf"


## __HOSTNAME - hostname 
##
__HOSTNAME="$( uname -n )"

## __NODENAME - nodename
##
__NODENAME=${__HOSTNAME}
[ -f /etc/nodename ] && __NODENAME="$( cat /etc/nodename )"

## __OS - Operating system (e.g. SunOS)
##
__OS="$( uname -s )"

## __OS_VERSION - Operating system version (e.g 5.8)
##
__OS_VERSION="$( uname -r )"

## __OS_RELEASE - Operating system release (e.g. Generic_112233-08)
##
__OS_RELEASE="$( uname -v )"

## __MACHINE_CLASS - Machine class (e.g sun4u)
##
__MACHINE_CLASS="$( uname -m )"

## __MACHINE_TYPE - machine type (e.g. SUNW,Ultra-4)
##
__MACHINE_TYPE="$( uname -i )"

## __MACHINE_ARC - machine architecture (e.g. sparc)
##
__MACHINE_ARC="$( uname -p )"

## __START_DIR - working directory when starting the script
##
__START_DIR="$( pwd )"

## __LOGFILE - fully qualified name of the logfile used
##
__DEF_LOGFILE="/var/tmp/${__SCRIPTNAME}.$$.LOG"
__LOGFILE=${__DEF_LOGFILE}

##
## temporary files:
##
## __TEMPFILE1, __TEMPFILE2
__TEMPFILE1="/tmp/${__SCRIPTNAME}.$$.TEMP1"
__TEMPFILE2="/tmp/${__SCRIPTNAME}.$$.TEMP2"
__LIST_OF_TEMPFILES="${__TEMPFILE1} ${__TEMPFILE2}"

# lock file (used if $__ONLY_ONCE is true)
__LOCKFILE="/tmp/${__SCRIPTNAME}.lock"
__LOCKFILE_CREATED=${__FALSE}

##
## __EXITROUTINES - list of routines that should be executed before the 
##                  script ends
##
__EXITROUTINES=""

# reboot necessary ?
## __REBOOT_REQUIRED - set to true to reboot automatically at 
##                     script end (def. false)
##
__REBOOT_REQUIRED=${__FALSE}

## __REBOOT_PARAMETER - parameter for the reboot command (def.: none)
##
__REBOOT_PARAMETER=""

## __PRINT_LIST_OF_WARNINGS_MSGS
##   print the list of warning messages at program end (def. false)
##
__PRINT_LIST_OF_WARNINGS_MSGS=${__FALSE}

## No of warnings found
##
typeset -i __NO_OF_WARNINGS=0

## __PRINT_LIST_OF_ERROR_MSGS
##   print the list of error messages at program end (def. false)
##
__PRINT_LIST_OF_ERROR_MSGS=${__FALSE}

## List of warning messages
##
__LIST_OF_WARNINGS=""

## No of errors found
##
typeset -i __NO_OF_ERRORS=0

## List of error messages
##
__LIST_OF_ERRORS=""

## __LOGON_USERID - ID of the user opening the session  
##
 typeset REST=
 who am i | read __LOGIN_USERID __REST
 
## __USERID - ID of the user executing this script (e.g. xtrnaw7)
##
 __USERID=${__LOGIN_USERID}
 [ -x /usr/ucb/whoami ] && /usr/ucb/whoami | read __USERID __REST

## __RUNLEVEL - current runlevel
 who -r | read _DUMMY1 __DUMMY2 __RUNLEVEL __REST

 
# -----------------------------------------------------------------------------
# color variables

## __USE_COLORS - use colors (def. false) use the parameter -a to 
##                set this variable
__USE_COLORS=${__TRUE}

##
## Colorattributes:
## __COLOR_OFF, __COLOR_BOLD, __COLOR_NORMAL, - normal, __COLOR_UNDERLINE
## __COLOR_BLINK, __COLOR_REVERSE, __COLOR_INVISIBLE
##

__COLOR_OFF="\033[0m"
__COLOR_BOLD="\033[1m"
__COLOR_NORMAL="\033[2m"
__COLOR_UNDERLINE="\033[4m"
__COLOR_BLINK="\033[5m"
__COLOR_REVERSE="\033[7m"
__COLOR_INVISIBLE="\033[8m"


##
## Foreground Color variables:
## __COLOR_FG_BLACK, __COLOR_FG_RED,     __COLOR_FG_GREEN, __COLOR_FG_YELLOW
## __COLOR_FG_BLUE,  __COLOR_FG_MAGENTA, __COLOR_FG_CYAN,  __COLOR_FG_WHITE
##
## Background Color variables:
## __COLOR_BG_BLACK, __COLOR_BG_RED,     __COLOR_BG_GREEN, __COLOR_BG_YELLOW
## __COLOR_BG_BLUE,  __COLOR_BG_MAGENTA, __COLOR_BG_CYAN,  __COLOR_BG_WHITE
##

__COLOR_FG_BLACK="\033[30m"
__COLOR_FG_RED="\033[31m"
__COLOR_FG_GREEN="\033[32m"
__COLOR_FG_YELLOW="\033[33m"
__COLOR_FG_BLUE="\033[34m"
__COLOR_FG_MAGENTA="\033[35m"
__COLOR_FG_CYAN="\033[36m"
__COLOR_FG_WHITE="\033[37m"

__COLOR_BG_BLACK="\033[40m"
__COLOR_BG_RED="\033[41m"
__COLOR_BG_GREEN="\033[42m"
__COLOR_BG_YELLOW="\033[43m"
__COLOR_BG_BLUE="\033[44m"
__COLOR_BG_MAGENTA="\033[45m"
__COLOR_BG_CYAN="\033[46m"
__COLOR_BG_WHITE="\033[47m"


# position cursor:       ESC[row,colH or ESC[row;colf  (1,1 = upper left corner)
# Clear rest of line:    ESC[K
# Clear screen:          ESC[2J
# Save Cursor Pos        ESC[s
# Restore Cursor Pos     ESC[u
# Cursor Up # lines      ESC{colsA
# Cursor down # lines    ESC{colsB
# Cursor right # columns ESC{colsC
# Cursor left # columns  ESC{colsD
# Get Cursor Pos         ESC[6n
#


# -----------------------------------------------------------------------------

## 
## --- defined sub routines
##

## --------------------------------------
## File
##
## read the config file
##
## usage: ReadConfigFile [configfile]
##
## where:  configfile - name of the config file
##         default: search scriptname.conf in the current directory and
##         in the home directory (in this order)
##
## returns: ${__TRUE} - ok config read
##          ${__FALSE} - error config file not found or not readable
##
ReadConfigFile() {

  typeset THIS_CONFIG_FILE="$1"
  typeset THISRC=${__FALSE}
  
  if [ "${THIS_CONFIG_FILE}"x = ""x ] ; then
    THIS_CONFIG_FILE="./${__CONFIG_FILE}"
    if [ ! -f "${THIS_CONFIG_FILE}" ] ; then
      THIS_CONFIG_FILE="${HOME}/${__CONFIG_FILE}"
    fi    
  else
    [ ! -f "${THIS_CONFIG_FILE}" ] && THIS_CONFIG_FILE="${HOME}/${THIS_CONFIG_FILE}"
  fi

  [ "$( basename "${THIS_CONFIG_FILE}" )"x = "${THIS_CONFIG_FILE}"x ] && THIS_CONFIG_FILE="./${THIS_CONFIG_FILE}"
  
  if [ -f "${THIS_CONFIG_FILE}" ] ; then
    LogMsg "Reading the config file \"${THIS_CONFIG_FILE}\" ..." 
    . "${THIS_CONFIG_FILE}"
    THISRC=${__TRUE}    
  else
    LogInfo "Config file \"${THIS_CONFIG_FILE}\" NOT found" 
  fi

  return ${THISRC}
}

## --------------------------------------
## WriteConfigFile
##
## write the config file
##
## usage: WriteConfigFile [configfile]
##
## where:  configfile - name of the config file
##         default: write scriptname.conf in the current directory
##
## returns: ${__TRUE} - ok config written
##          ${__FALSE} - error writing the config file
##
WriteConfigFile() {
  typeset THIS_CONFIG_FILE="$1"
  typeset THISRC=${__FALSE}
  
  [ "${THIS_CONFIG_FILE}"x = ""x ] && THIS_CONFIG_FILE="./${__CONFIG_FILE}"

  LogMsg "Writing the config file \"${THIS_CONFIG_FILE}\" ..." 
   
cat <<EOT >"${THIS_CONFIG_FILE}"
# config file for $0
${CONFIG_PARAMETER}
EOT
  [ $? -eq 0 ] && THISRC=${__TRUE}
  
  return ${THISRC}
}


## --------------------------------------
## CreateConfigFile
##
## create the configuration file
##
## usage: CreateConfigFile [configfile]
##
## returns: ${__TRUE} - ok config written
##          ${__FALSE} - error writing the config file
##
CreateConfigFile() {
  typeset THIS_CONFIG="$1"
  [ "${THIS_CONFIG}"x = ""x ] && THIS_CONFIG="${HOME}/${__CONFIG_FILE}"

  typeset THISRC=${__TRUE}  

  if [ -f "${THIS_CONFIG}" -a ${__OVERWRITE_MODE} = ${__FALSE} ] ; then
    LogWarning "The config file \"${THIS_CONFIG}\" already exist"
  else
    WriteConfigFile ${THIS_CONFIG}
    THISRC=$?
  fi	

}

## --------------------------------------
## InstallScript
##
## create the symbolic links and the configuration file
##
## usage: InstallScript [configfile]
##
## returns: ${__TRUE} - ok config written
##          ${__FALSE} - error writing the config file
##
InstallScript() {
  typeset THIS_CONFIG="$1"

  [ "${THIS_CONFIG}"x = ""x ] && THIS_CONFIG="${HOME}/${__CONFIG_FILE}"

  typeset THISRC=${__TRUE}  

  if [ "${__SCRIPTNAME}"x = "easycd.sh"x ] ; then
    LogMsg "Creating the symbolic links in the current directory ..."
    for CURLINK in ${POSSIBLE_SCRIPT_NAMES} ; do
      LogMsg "Processing \"${CURLINK}\" ..."
      if [ -a ${CURLINK} ] ; then
        if [ ${__OVERWRITE_MODE} = ${__TRUE} ] ; then
          LogInfo "Removing the existing link \"${CURLINK}\" ..."
          rm ${CURLINK}
        else	  
          LogWarning "\"${CURLINK}\" already exists."
          continue
        fi  
      fi
    
      LogMsg "  Creating the link ${CURLINK} -> $0"
      ln -s $0 ${CURLINK}
    done
  fi

  CreateConfigFile "${THIS_CONFIG}"
  THISRC=$?
  
  return ${THISRC}
}


## --------------------------------------
## UnInstallScript
##
## remove the symbolic links 
##
## usage: UnInstallScript
##
##
## returns: ${__TRUE} - ok config written
##          ${__FALSE} - error writing the config file
##
UnInstallScript() {
  LogMsg "Deleting the symbolic links in the current directory ..."

  for CURLINK in ${POSSIBLE_SCRIPT_NAMES} ; do
    LogMsg "Processing \"${CURLINK}\" ..."
    if [ -a ${CURLINK} ] ; then
      LogMsg "  Removing the link \"${CURLINK}\" ..."
      rm ${CURLINK}
    else	  
      LogWarning "\"${CURLINK}\" does not exist."
      continue
    fi  
  done

  [ -f "${HOME}/${__CONFIG_FILE}" ] && LogWarning "Config file \"${HOME}/${__CONFIG_FILE}\" NOT deleted"

  return ${__TRUE}
}

## --------------------------------------
## SetWindowTitle
##
## change the title of an X window
##
## usage: SetWindowTitle "newtitle"
##
## returns: -
##
## Note
##
## Original Author of this function (xtitle) is:	
##  William Seppeler
##  Email:seppeler@yahoo.com
##
SetWindowTitle(){
  typeset NEW_TITLE="$*"

  typeset -r ESC='\033'
  typeset -r BEL='\007'

  case $TERM in
    xterm*|dtterm|aixterm|rxvt)
      print "${ESC}]0;${NEW_TITLE}${BEL}\c";;
    sun-cmd)
      print "${ESC}]l${NEW_TITLE}${ESC}\\\\\c";;
      #print "${ESC}]L${NEW_TITLE}${ESC}\\\\\c";;
    hpterm)
      print "${ESC}&f0k${#${NEW_TITLE}}D$*\c";;
      #print "${ESC}&f-1k${#${NEW_TITLE}}D$*\c";;
    iris-ansi)
      print "${ESC}P1.y${NEW_TITLE}${ESC}\\\\\c";;
     #print "${ESC}P3.y${NEW_TITLE}${ESC
  esac     
}

## --------------------------------------
## SetDISPLAY
##
## try to set the variable DISPLAY
##
## usage: SetDISPLAY
##
## returns: DISPLAY is set or not
##
SetDISPLAY(){
#
# If the DISPLAY variable is not set, then assume that the person
# is not at the console, so try to figure out where they are logged
# in from and send the display back to them.
#
  if [ -z "$DISPLAY" ] ; then
    tty=`tty | sed "s@/dev/@@"`
    if [ "$tty" != "not a tty" ] ; then
      machine=`who | grep $tty | sed -e 's/^.*(//' -e 's/)//'`
      DISPLAY="${machine}:0" ; export DISPLAY
    fi
  fi
}

## --------------------------------------
## CheckYNParameter
##
## check if a parameter is y, n, 0, or 1
##
## usage: CheckYNParameter parameter
##
## returns: ${__TRUE} - the parameter is equal to yes
##          ${__FALSE} - the parameter is equal to no
##          255 - the parameter is neither y nor no
##
CheckYNParameter(){
  typeset THISRC=255
  case $1 in
   "y" | "Y" | "yes" | "YES" | 0 ) THISRC=${__TRUE} ;;
   "n" | "N" | "no"  | "NO"  | 1 ) THISRC=${__FALSE} ;;
   * ) THISRC=255 ;;
  esac
  return ${THISRC}
}

## --------------------------------------
## ConvertToYesNo
##
## convert the value of a variable to y or n
##
## usage: ConvertToYesNo parameter
##
## returns: -
##          prints y, n or ? to STDOUT
##
ConvertToYesNo(){
  case $1 in
   "y" | "Y" | "yes" | "YES" | 0 ) echo "y" ;;
   "n" | "N" | "no"  | "NO"  | 1 ) echo "n" ;;
   * ) echo "?" ;;
  esac
}

## ---------------------------------------
## SwitchOption
##
## switch an option from true to false or vice versa
##
## usage: SwitchOption optionname
##
## returns: the new value (either ${__TRUE} or ${__FALSE} )
##
SwitchOption() {
  typeset THISRC=0

  typeset THIS_SWITCH=$1

  eval "[ \${${THIS_SWITCH}} = \${__TRUE} ] && ${THIS_SWITCH}=\${__FALSE} || ${THIS_SWITCH}=\${__TRUE}"

  eval THISRC=\${${THIS_SWITCH}}

}
 
## --------------------------------------
## CheckInputDevice
##
## check if the input device is a terminal
##
## usage: CheckInputDevice
##
## returns: 0 - the input device is a terminal (interactive)
##          1 - the input device is NOT a terminal
##
CheckInputDevice(){
  tty -s
  return $?
}
  
## --------------------------------------
## GetProgramDirectory
##
## get the directory where a program resides
##
## usage: GetProgramDirectory [programpath/]programname [resultvar]
##
## returns: 
##          the variable PRGDIR contains <the directory with the program>
##          if the parameter resultvar is missing
##
GetProgramDirectory() {
  typeset PRG=""
  typeset RESULTVAR=$2
    
  if [ ! -L $1 ] ; then
    PRG=$( cd -P -- "$(dirname -- "$(command -v -- "$1")")" && pwd -P )
  else  
# resolv links - $1 may be a softlink
    PRG="$1"
   
    while [ -h "$PRG" ] ; do
      ls=`ls -ld "$PRG"`
      link=`expr "$ls" : '.*-> \(.*\)$'`
      if expr "$link" : '.*/.*' > /dev/null; then
        PRG="$link"
      else
        PRG=`dirname "$PRG"`/"$link"
      fi
    done
    PRG="$(dirname $PRG)"
  fi

  if [ "${RESULTVAR}"x != ""x ] ; then
     eval ${RESULTVAR}=$PRG
  else 
    PRGDIR=$PRG
  fi
}

## --------------------------------------
## substr
##
## get a substring of a string
##
## usage: variable=` substr sourceStr pos length` 
##     or substr sourceStr pos length resultStr
##
## returns: 1 - parameter missing
##          0 - parameter okay
##
substr() {
  typeset resultstr=""
  typeset THISRC=1

  if [ "$1"x != ""x ] ; then 
    typeset s=$1
    typeset p=$2
    typeset l=$3
    [ "$l"x = ""x ] && l=${#s}
    [ "$p"x = ""x ] && p=1
    resultstr="$( echo $s | cut -c${p}-$((${p}+${l}-1)) )"
    THISRC=0
  else
    THISRC=1
    resultstr="$1"
  fi

  if [ "$4"x != ""x ] ; then
    eval $4=\"${resultstr}\" 
  else
    echo ${resultstr}
  fi

  return ${THISRC}
}

## --------------------------------------
## replacestr
##
## replace a substring with another substring
##
## usage: variable=` replacestr sourceStr oldsubStr newsubStr` 
##     or replacestr sourceStr oldsubStr newsubStr resultvariable
##
## returns: 0 - substring replaced
##          1 - substring not found
##          3 - error, parameter missing
##
##          writes the substr to STDOUT if resultvariable is missing
##
replacestr() {
  typeset THISRC=3
   
  typeset sourcestring=$1 
  typeset oldsubStr=$2
  typeset newsubStr=$3

  if [ "${sourcestring}"x != ""x -a "${oldsubStr}"x != ""x ] ; then
    if [[ "${sourcestring}" == *${oldsubStr}* ]] ; then
      sourcestring="${sourcestring%%${oldsubStr}*}${newsubStr}${sourcestring#*${oldsubStr}}" 
      THISRC=0
    else
      THISRC=1
    fi
  fi

  if [ "$4"x != ""x ] ; then
    eval $4=\"${sourcestring}\" 
  else
    echo $sourcestring
  fi

  return ${THISRC}
}

## --------------------------------------
## pos
##
## check if a string is a substring of another string
##
## usage: pos searchstring sourcestring
##
## returns: 0 - searchstring is not part of sourcestring
##          else the position of searchstring in sourcestring
##
pos() {
  typeset searchstring=$1
  typeset sourcestring=$2
 
  if [[ "${sourcestring}" == *${searchstring}* ]] ; then
    typeset f=${sourcestring%%${searchstring}*}
    return $((  ${#f}+1 ))
  else
    return 0
  fi
}

## --------------------------------------
## lastpos
##
## check if a string is a substring of another string
##
## usage: lastpos searchstring sourcestring
##
## returns: 0 - searchstring is not part of sourcestring
##          else the position of searchstring in sourcestring
##
lastpos() {
  typeset searchstring=$1
  typeset sourcestring=$2

  if [[ "${sourcestring}" == *${searchstring}* ]] ; then
    typeset f=${sourcestring%${searchstring}*}
    return $((  ${#f}+1 ))
  else 
    return  0
  fi
}


## --------------------------------------
## isNumber
##
## check if a value is an integer 
##
## usage: isNumber testValue 
##
## returns: 0 - testValue is a number else not
##
isNumber() {
  typeset TESTVAR="$(echo $1 | sed 's/[0-9]*//g' )"
  [ "${TESTVAR}"x = ""x ] && return ${__TRUE} || return ${__FALSE}
}

## --------------------------------------
## toUppercase
##
## convert a string to uppercase
##
## usage: toUppercase sourceString | read resultString
##    or   targetString=` toUppercase sourceString` 
##    or   toUppercase sourceString resultString
##
## returns: writes the converted string to STDOUT if resultString is missing
##
toUppercase() {
  typeset -u testvar=$1

  if [ "$2"x != ""x ] ; then
    eval $2=\"${testvar}\" 
  else
    echo ${testvar}
  fi
}

## --------------------------------------
## toLowercase
##
## convert a string to lowercase
##
## usage: toLowercase sourceString | read resultString
##    or   targetString=` toLowercase sourceString` 
##    or   toLowercase sourceString resultString
##
## returns: writes the converted string to STDOUT if resultString is missing
##
toLowercase() {
  typeset -l testvar=$1

  if [ "$2"x != ""x ] ; then
    eval $2=\"${testvar}\" 
  else
    echo ${testvar}
  fi
}

## --------------------------------------
## executeCommand
##
## execute a command
##
## usage: executeCommand command parameter
##
## returns: the RC of the executed command
##
executeCommand() {
  set +e
  eval "$@"
}

## --------------------------------------
## executeCommandAndLog
##
## execute a command and write STDERR and STDOUT to the logfile
##
## usage: executeCommandAndLog command parameter
##
## returns: the RC of the executed command
##
executeCommandAndLog() {
  set +e

  if [ "${__LOGFILE}"x != ""x -a -f ${__LOGFILE} ] ; then
    "$@" 2>&1 | tee -a ${__LOGFILE}
    return $?
  else    
    "$@"
    return $?
  fi
}

## --------------------------------------
## UserIsRoot
##
## validate the user id
##
## usage: UserIsRoot
##
## returns: 0 - the user is root; else not
##
UserIsRoot() {
  [ `id | /usr/bin/sed 's/uid=\([0-9]*\)(.*/\1/'` = 0 ] && return 0 || return 1
}


## --------------------------------------
## UserIs
##
## validate the user id
##
## usage: UserIs USERID
##
## where: USERID - userid (e.g oracle)
##
## returns: 0 - the user is this user
##          1 - the user is NOT this user
##          2 - the user does not exist on this machine
##          3 - missing parameter
##
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

## --------------------------------------
## GetCurrentUID
##
## get the UID of the current user
##
## usage: GetCurrentUID
##
## where: - 
##
## returns: the UID 
##
GetCurrentUID() {
  return  `id | /usr/bin/sed 's/uid=\([0-9]*\)(.*/\1/'`
}

## --------------------------------------
## GetUserName
##
## get the name of a user
##
## usage: GetUserName UID
##
## where: UID - userid (e.g 1686)
##
## returns: __USERNAME contains the user name or "" if
##          the userid does not exist on this machine
##
GetUserName() {
  [ "$1"x != ""x ] &&  __USERNAME=` grep ":$1:" /etc/passwd | cut -d: -f1`  || __USERNAME=""
}

## --------------------------------------
## GetUID
##
## get the UID for a username
##
## usage: GetUID username
##
## where: username - user name (e.g nobody)
##
## returns: __USER_ID contains the UID or "" if
##          the username does not exist on this machine
##
GetUID() {
  [ "$1"x != ""x ] &&  __USER_ID=` grep "^$1:" /etc/passwd | cut -d: -f3` || __USER_ID=""
}


# ======================================

## --------------------------------------
## LogMsgInvers
##
## print a message to STDOUT and write it also to the logfile
##
## usage: LogMsgInvers message
##
## returns: -
##
LogMsgInvers() {

  typeset THISMSG="[$(date +"%d.%m.%Y %H:%M:%S")] $*"
  
  typeset FORMATED_MSG="" 
  
  if [ "${__USE_COLORS}"x = "${__TRUE}"x ] ; then
    FORMATTED_MSG="${__COLOR_REVERSE}${THISMSG}${__COLOR_OFF}"
  else
    FORMATTED_MSG="${THISMSG}"
  fi         

  [  ${__QUIET_MODE} -ne ${__TRUE} ] && echo "${FORMATTED_MSG} "
  [ "${__LOGFILE}"x != ""x ] && [ -f ${__LOGFILE} ] &&  echo "${THISMSG}" >>${__LOGFILE} 
}

 
## --------------------------------------
## LogMsg
##
## print a message to STDOUT and write it also to the logfile
##
## usage: LogMsg message
##
## returns: -
##
LogMsg() {
  typeset THISMSG="[$(date +"%d.%m.%Y %H:%M:%S")] $*"

  [  ${__QUIET_MODE} -ne ${__TRUE} ] && echo "${THISMSG} "
  [ "${__LOGFILE}"x != ""x ] && [ -f ${__LOGFILE} ] &&  echo "${THISMSG}" >>${__LOGFILE} 
}

## --------------------------------------
## LogOnly
##
## write a message to the logfile
##
## usage: LogOnly message
##
## returns: -
##
LogOnly() {
  typeset THISMSG="[$(date +"%d.%m.%Y %H:%M:%S")] $*"

  [ "${__LOGFILE}"x != ""x ] && [ -f ${__LOGFILE} ] &&  echo "${THISMSG}" >>${__LOGFILE} 
}

## --------------------------------------
## LogInfo
##
## print a message to STDOUT and write it also to the logfile 
## only if in verbose mode
##
## usage: LogInfo message
##
## returns: -
##
LogInfo() {
  [ ${__VERBOSE_MODE} = ${__TRUE} ] && LogMsg "INFO: $*"
}

## --------------------------------------
## LogWarning
##
## print a warning to STDOUT and write it also to the logfile
##
## usage: LogWarning message
##
## returns: -
##
LogWarning() {
  LogMsg "WARNING: $*"
  (( __NO_OF_WARNINGS = __NO_OF_WARNINGS +1 ))
  __LIST_OF_WARNINGS="${__LIST_OF_WARNINGS}
WARNING: $*"  
}

## --------------------------------------
## LogError
##
## print an error message to STDOUT and write it also to the logfile
##
## usage: LogError message
##
## returns: -
##
LogError() {
  LogMsg "ERROR: $*"
  (( __NO_OF_ERRORS=__NO_OF_ERRORS + 1 ))  
  __LIST_OF_ERRORS="${__LIST_OF_ERRORS}
ERROR: $*"  
}


## ---------------------------------------
## BackupFileIfNecessary
##
## create a backup of a file if ${__OVERWRITE_MODE} is set to ${__FALSE}
##
## usage: BackupFileIfNecessary [file1} ... {filen}
##
## returns: 0 - done; else error
##
BackupFileIfNecessary() {
 typeset FILES_TO_BACKUP="$*"
 typeset CURFILE=""
 typeset THISRC=0
 
 if [ ${__OVERWRITE_MODE} = ${__FALSE} ] ; then
   for CURFILE in ${FILES_TO_BACKUP} ; do         
     [ ! -f ${CURFILE} ] && continue
     
     LogMsg "Creating a backup of \"${CURFILE}\" in \"${CURFILE}.$$\" ..."
     cp ${CURFILE} ${CURFILE}.$$
     THISRC=$?
     if [ ${THISRC} -ne 0 ] ; then
       LogError "Error creating the backup of the file ${CURFILE}"
       break
     fi
   done
 fi
}  
 
## ---------------------------------------
## CopyDirectory
##
## copy a directory 
##
## usage: CopyDirectory sourcedir targetDir
##
## returns: 0 - done; else error
##
CopyDirectory() {
  typeset THISRC=1
  if [ "$1"x != ""x -a "$2"x != ""x  ] ; then
     if [ -d $1 -a -d $2 ] ; then
        LogMsg "Copying all files from \"$1\" to \"$2\" ..."
        cd $1
        find . -depth -print | cpio -pdumv $2
        THISRC=$?
        cd ${OLDPWD}
     fi
  fi

  return ${THISRC}
}

## --------------------------------------
## GetIPAddress
##
## Get the IP address for a hostname from the nameserver 
## (if defined & alive)
##
## Usage: GetIPAddress | read IPADDRESS
##
GetIPAddress() {
  typeset THISHOST=$1
  typeset THISRC=""

  set -- $( grep "^nameserver" /etc/resolv.conf )
  if [ "$1"x = "nameserver"x ] ; then
    ping $2 1 2>&1 >/dev/null
    if [ $? -eq 0 ] ; then
      set -- $( which nslookup )
      if [ "$1"x != "no"x  ] ; then
        set -- `nslookup -silent ${THISHOST} | grep "^Address:" 2>/dev/null`
        [ "$3" = "Address:" ] && THISRC=$4
      fi
    fi
  fi
  echo ${THISRC}
}

## --------------------------------------
## AskUser
##
## Ask the user (or use defaults depending on the parameter -n and -y)
##
## Usage: AskUser "message" 
##        
## returns: ${__TRUE} - user input is yes
##          ${__FALSE} - user input is no
##          USER_INPUT contains the user input
##
AskUser() {

  typeset THISRC=""
  
  case ${__USER_RESPONSE_IS} in 
     
   "y" ) USER_INPUT="y" ; THISRC=${__TRUE} 
         ;;

   "n" ) USER_INPUT="n" ; THISRC=${__FALSE} 
         ;;
   
     * ) LogMsg "$*"
         read USER_INPUT
         [ "${USER_INPUT}" = "y" -o "${USER_INPUT}" = "Y" ] && THISRC=${__TRUE} || THISRC=${__FALSE}
         ;;
  esac  

  return ${THISRC}
}

## --------------------------------------
## RebootIfNecessary
##
## Check if a reboot is necessary
##
## Usage: RebootIfNecessary
##
RebootIfNecessary() {
 
  if [ ${__REBOOT_REQUIRED} -eq 0 ] ; then
    LogMsg "The changes made to the system require a reboot"

    AskUser "Do you want to reboot now (y/n, default is NO)?"
    if [ $? -eq ${__TRUE} ] ; then
      LogMsg "Rebooting now ..."
      echo "???" reboot ${__REBOOT_PARAMETER}
    fi
  fi
}

## ---------------------------------------
## die
##
## print a message and end the program
##
## usage: die returncode message
##
## returns: -
##
die() {
  typeset THISRC=$1
  shift
  if [ "$*"x != ""x ] ; then
    [ ${THISRC} = 0 ] && LogMsg "$*" || LogError "$*"
  fi
  cleanup

  if [ "${__NO_OF_WARNINGS}" != "0" -a ${__PRINT_LIST_OF_WARNINGS_MSGS} = ${__TRUE} ] ; then
    LogMsg "*** CAUTION: One or more WARNINGS found ***"
    LogMsg "*** please check the logfile ***"
    
    LogMsg "Summary of warnings:
${__LIST_OF_WARNINGS}
"
  fi    

  if [ "${__NO_OF_ERRORS}" != "0" -a ${__PRINT_LIST_OF_ERROR_MSGS} = ${__TRUE} ] ; then
    LogMsg "*** CAUTION: One or more ERRORS found ***"
    LogMsg "*** please check the logfile ***"
    LogMsg "Summary of error messages
${__LIST_OF_ERRORS}
"
  fi    

  LogMsg "The log file used was \"${__LOGFILE}\" "
  __QUIET_MODE=${__FALSE}
  LogMsg "${__SCRIPTNAME} ended on $( date )."
  LogMsg "The RC is ${THISRC}."

  SetWindowTitle ${TERM}
  if [ ${WAIT_FOR_USER} = ${__TRUE} ] ; then
    echo ""
    echo "Press return to end the script"
    READ USERINPUT
  fi
      
  __EXIT_VIA_DIE=${__TRUE} 
  exit ${THISRC}
}


# ======================================

## 
## --- defined internal sub routines (do NOT use!)
##

# --------------------------------------
## CreateLockFile
#
# Create the lock file if possible
#
# usage: CreateLockFile
#
# returns: 0 - lock file created
#          1 - lock file already exist
#          2 - error creating the lock file
#
# ${__RUNNING_PID} contains the PID of the running process (if any)
#
CreateLockFile() {
  __RUNNING_PID=""
  typeset rest=""

  if [ -f ${__LOCKFILE} ] ; then
    cat ${__LOCKFILE} | read __RUNNING_PID rest
    return 1
  fi   
 
  echo "$$ lockfile of $0 (PID $$) created at ` date`  " >${__LOCKFILE}
  if [ $? -eq 0 ] ; then
    __LOCKFILE_CREATED=${__TRUE}
    return 0
  fi
  return 2
}

# --------------------------------------
## RemoveLockFile
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
  if [ ${__LOCKFILE_CREATED} = ${__TRUE} ] ; then
    rm ${__LOCKFILE} 1>/dev/null 2>/dev/null
    [ $? -eq 0 ] && return 0
  fi  
  return 2
}

# ======================================

# --------------------------------------
## CreateTemporaryFiles
#
# create the temporary files
#
# usage: CreateTemporaryFiles
#
# returns: -
#
CreateTemporaryFiles() {
  typeset CURFILE=

  __TEMPFILE_CREATED=${__TRUE}

  LogInfo "Creating the temporary files \"${__LIST_OF_TEMPFILES}\" ..."
  for CURFILE in ${__LIST_OF_TEMPFILES} ; do
    LogInfo "Creating the temporary file \"${CURFILE}\" "
    echo >${CURFILE} || return $?
  done
  
  return 0
}

# --------------------------------------
## DeleteTemporaryFiles
#
# delete the temporary files
#
# usage: DeleteTemporaryFiles
#
# returns: -
#
DeleteTemporaryFiles() {
  typeset CURFILE=

  if [ "${__TEMPFILE_CREATED}"x = "${__TRUE}"x ] ; then
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


# ======================================

# ---------------------------------------
## cleanup
#
# house keeping at program end
#
# usage: cleanup
#
# returns: -
#
cleanup() {
  typeset EXIT_ROUTINE=

  if [ "${__EXITROUTINES}"x !=  ""x ] ; then
    LogInfo "Executing the exit routines \"${__EXITROUTINES}\" ..."
    for EXIT_ROUTINE in ${__EXITROUTINES} ; do
      LogInfo "Now calling the exit routine \"${EXIT_ROUTINE}\" ..."
      eval ${EXIT_ROUTINE}
    done
  fi
}


## 
## --- defined trap handler (you may change them)
##


## ---------------------------------------
## EXIT_SIGNAL_HANDLER
##
## trap handler for exit
##
## usage: called automatically
##
## returns: -
##
EXIT_SIGNAL_HANDLER() {
  typeset THISRC=$1
  if [ "${__EXIT_VIA_DIE}"x != "${__TRUE}"x ] ; then
    LogWarning "You should use the function \"die\" to end the program"
  fi    
  exit ${THISRC}
}


## ---------------------------------------
## HUP_SIGNAL_HANLDER
##
## script handler for signal HUP
##
## usage: called automatically
##
## returns: -
##
HUP_SIGNAL_HANDLER() {
  LogWarning "HUP signal received."
}

## ---------------------------------------
## QUIT_SIGNAL_HANDLER
##
## script handler for signal QUIT (ctrl-\)
##
## usage: called automatically
##
## returns: -
##
QUIT_SIGNAL_HANDLER() {
  die 501 "QUIT signal received" 
}

## ---------------------------------------
## BREAK_SIGNAL_HANLDER
##
## script handler for signal BREAK (ctrl-c)
##
## usage: called automatically
##
## returns: -
##
BREAK_SIGNAL_HANDLER() {
  if [ ${__USER_BREAK_ALLOWED} = ${__TRUE} ] ; then
    die 502 "Script aborted by the user via signal BREAK (CTRL-C)" 
  else
    LogInfo "Break signal (CTRL-C) received and ignored (Break is disabled)."
  fi
}


## ---------------------------------------
## TERM_SIGNAL_HANLDER
##
## script handler for signal TERM
##
## usage: called automatically
##
## returns: -
##
TERM_SIGNAL_HANDLER() {
  die 503 "Script aborted by the external signal TERM" 
}

## ---------------------------------------
## ScriptAbort
##
## script handler for signals not coverd by the other handlers
##
## usage: called automatically
##
## returns: -
##
ScriptAbort() {
  die 504 "Script aborted by an external signal"
}

# ======================================



## ---------------------------------------
## DebugHandler
##
## handler for single step mode
##
## usage: called automatically
##
## returns: the RC of the previous executed command
##
DebugHandler() {
  [ "${__DEBUG_MODE}" != ${__TRUE} ] && return ${__LAST_RC}

  stty erase ^H
  
  typeset __THIS_PID=$$

  typeset -i i=0
  typeset -i j=0

  if [ "${__USE_COLORS}"x = "${__TRUE}"x ] ; then
    typeset __LINE_COLOR="\033[0;36m\033[44m"
    typeset __CUR_LINE_COLOR="\033[0;34m\033[46m"
    typeset __DEBUG_MSG_COLOR="\033[0;31m\033[48m"
    typeset __COLOR_OFF="\033[0;m"   
  else
    typeset __LINE_COLOR=""
    typeset __CUR_LINE_COLOR=""
    typeset __DEBUG_MSG_COLOR=""
    typeset __COLOR_OFF=""
  fi

  COLUMNS=80
  [ -x /usr/openwin/bin/resize ] && eval $( /usr/openwin/bin/resize ) 
  eval "typeset -L${COLUMNS} LINE_VAR"
 
#  typeset  -L80 __LINE_VAR=""
  typeset __USERINPUT=""

  set -o emacs

# check for the break points
  if [ "${__BREAKPOINT_LINE}"x != "0"x ] ; then
    if [ "${__BREAKPOINT_LINE}" -ge "${__LINENO}" ] ; then
      __LINE_VAR="*** DEBUG: Break point at line ${__LINENO} found"
      print -u 2 "${__DEBUG_MSG_COLOR}${__LINE_VAR}"
      __BREAKPOINT_LINE=0
    else
      return ${__LAST_RC}
    fi
  fi

  if [ "${__STEP_COUNT}"x != "0"x ] ; then
    __STEP_COUNT=$(( __STEP_COUNT - 1 ))
    if [  "${__STEP_COUNT}"x = "0"x  ] ; then
      __LINE_VAR="*** DEBUG: Break point at line ${__LINENO} found"
      print -u 2 "${__DEBUG_MSG_COLOR}${__LINE_VAR}"
    else
      return ${__LAST_RC}
    fi
  fi


# read the script into an array (only once!)
  if [ ${__SCRIPT_ARRAY[0]} = 0 ] ; then
    typeset oIFS=$IFS
    IFS="\n"

    i=1

    while read -r __SCRIPT_ARRAY[$i] ; do
      i=$(( i+1 ))
    done <$0

    __SCRIPT_ARRAY[0]=$i

    IFS=$oIFS
  fi

# define the variables for the output 
  i=${__SCRIPT_ARRAY[0]}
  eval "typeset -R${#i} NUM_VAR"  
  j=$(( ${COLUMNS} - ${#i} -1 ))
  eval "typeset -L${j} __SRCLINE_VAR"  

  if [ "${__TRACE_COUNT}"x != "0"x ] ; then
    __SRCLINE_VAR="${NUM_VAR}>>> ${__SCRIPT_ARRAY[${__LINENO}]}"
    print -u 2 "${__CUR_LINE_COLOR}${__SRCLINE_VAR}"
    __TRACE_COUNT=$(( ${__TRACE_COUNT}-1 ))
    print "${__COLOR_OFF}"
    return ${__LAST_RC}
  fi 

# write the script to a file  
#  i=1
#  while [ i -lt ${__SCRIPT_ARRAY[0]} ] ; do 
#     echo "$i ${__SCRIPT_ARRAY[$i]}" >>./test.out
#     i=$(( i+1 ))
#  done
    
  __LINE_VAR=""   
  print -u 2 "${__DEBUG_MSG_COLOR}${__LINE_VAR}"

  __LINE_VAR="*** DEBUG: Executed line: ${__LINENO}"
  print -u 2 "${__DEBUG_MSG_COLOR}${__LINE_VAR}"
  __LINE_VAR="*** DEBUG: Line Context:"
  print -u 2 "${__DEBUG_MSG_COLOR}${__LINE_VAR}"

  [ ${__LINENO} -gt 5 ] && i=$(( ${__LINENO}-5 )) || i=1
  typeset CUR_SRC_WIN_START=$i
  j=$(( ${__LINENO}+5 ))
  [ ${j} -gt ${__SCRIPT_ARRAY[0]} ] && j=${__SCRIPT_ARRAY[0]}

# write the context of the line just executed   
  while [ i -lt j ] ; do
    NUM_VAR=$i
    if [ $i -eq ${__LINENO} ] ; then
      __SRCLINE_VAR="${NUM_VAR}>>> ${__SCRIPT_ARRAY[$i]}"
      print -u 2 "${__CUR_LINE_COLOR}${__SRCLINE_VAR}"
    else
      __SRCLINE_VAR="${NUM_VAR}    ${__SCRIPT_ARRAY[$i]}"
      print -u 2 "${__LINE_COLOR}${__SRCLINE_VAR}"
    fi
      i=$(( i+1 ))
  done   

# read the user input
#
  __LINE_VAR="*** DEBUG: \$\$ is ${__THIS_PID}; \$? is ${__LAST_RC}; \$! is ${__LAST_BG_RC}"
  print -u 2 "${__DEBUG_MSG_COLOR}${__LINE_VAR}"
  __LINE_VAR="*** DEBUG: Enter a command to execute or <enter> to execute the next command:"
  print -u 2 "${__DEBUG_MSG_COLOR}${__LINE_VAR}"

  while [ 1 = 1 ] ; do
    print -u 2 -n  "${__DEBUG_MSG_COLOR}DEBUG>>> "
    read __USERINPUT __USERPARMS __USERVALUE __USERVALUE2
  
    case ${__USERINPUT} in 

      "help" | "?" ) __LINE_VAR="*** DEBUG:Known commands"
           print -u 2 "${__DEBUG_MSG_COLOR}${__LINE_VAR}"
cat 1>&2 <<EOT

  help                   - print this text
  trace count            - execute count lines
  trace off              - turn single mode off
  trace at lineNo        - suspend single step until line linNo
  trace not lineNumber   - suspend single step for lineNumber statements
  show lineNo [count]    - show count (def. 10) lines after line lineNo
  exit [returncode]      - exit the program with RC returnCode (def.: 1)
  <return>               - execute next statement (single step)
  everything else        - execute the command 

EOT
           ;; 
   
   
      "" ) break 
           ;;
           
      "trace"  ) :
          case ${__USERPARMS}  in 

            "off" )
              __LINE_VAR="*** DEBUG: Turning single step mode off"
              print -u 2 "${__DEBUG_MSG_COLOR}${__LINE_VAR}"
              __DEBUG_MODE=${__FALSE} 
              break
              ;;
      
            "at" )
              if [ "${__USERVALUE}"x = ""x ] ; then
                __LINE_VAR="*** DEBUG: value missing"
                print -u 2 "${__DEBUG_MSG_COLOR}${__LINE_VAR}"
                continue
              fi

              isNumber ${__USERVALUE} 2>/dev/null
              if [ $? -ne 0 ] ; then
                __LINE_VAR="*** DEBUG: \"${__USERVALUE}\" is not a number"
                print -u 2 "${__DEBUG_MSG_COLOR}${__LINE_VAR}"
                continue
              fi         

              __LINE_VAR="*** DEBUG: Suspending single step until line ${__USERVALUE}"
              print -u 2 "${__DEBUG_MSG_COLOR}${__LINE_VAR}"
              __BREAKPOINT_LINE=${__USERVALUE}      
              break
              ;;

            "not" )
              if [ "${__USERVALUE}"x = ""x ] ; then
                __LINE_VAR="*** DEBUG: value missing"
                print -u 2 "${__DEBUG_MSG_COLOR}${__LINE_VAR}"
                continue
              fi

              isNumber ${__USERVALUE} 2>/dev/null
              if [ $? -ne 0 ] ; then
                __LINE_VAR="*** DEBUG: \"${__USERVALUE}\" is not a number"
                print -u 2 "${__DEBUG_MSG_COLOR}${__LINE_VAR}"
                continue
              fi         

              __LINE_VAR="*** DEBUG: Suspending single step for the next ${__USERVALUE} statements"
              print -u 2 "${__DEBUG_MSG_COLOR}${__LINE_VAR}"
              __STEP_COUNT=${__USERVALUE}      
              break
              ;;


            * )
              isNumber ${__USERPARMS} 2>/dev/null
              if [ $? -eq 0 ] ; then
                __TRACE_COUNT=${__USERPARMS}
                __LINE_VAR="*** DEBUG: Executing \"${__USERPARMS}\" lines"
                print -u 2 "${__DEBUG_MSG_COLOR}${__LINE_VAR}"
                break
              else
                __LINE_VAR="*** DEBUG: unknown trace option \"${__USERPARMS}\" "
                print -u 2 "${__DEBUG_MSG_COLOR}${__LINE_VAR}"    
              fi
              ;;
      
          esac
          ;;   

      "show" )      
           [ "${__USERPARMS}"x = ""x ] && __USERPARMS=${CUR_SRC_WIN_START}

           isNumber ${__USERPARMS} 2>/dev/null
           if [ $? -ne 0 ] ; then
             __LINE_VAR="*** DEBUG: \"${__USERPARMS}\" is not a number"
             print -u 2 "${__DEBUG_MSG_COLOR}${__LINE_VAR}"
             continue
           fi         

           if [ ${__USERPARMS} -lt 1 ] ; then
             __LINE_VAR="*** DEBUG: \"${__USERPARMS}\" is out of range"
             print -u 2 "${__DEBUG_MSG_COLOR}${__LINE_VAR}"
             continue
           fi         

           if [ "${__USERPARMS}" -gt ${__SCRIPT_ARRAY[0]} ] ; then
             __LINE_VAR="*** DEBUG: \"${__USERPARMS}\" is out of range (last line is ${__SCRIPT_ARRAY[0]})"
             print -u 2 "${__DEBUG_MSG_COLOR}${__LINE_VAR}"    
             continue
           fi

           i=${__USERPARMS}

           if [ "${__USERVALUE}"x != ""x ] ; then
             isNumber ${__USERVALUE} 2>/dev/null
             if [ $? -ne 0 ] ; then
               __LINE_VAR="*** DEBUG: \"${__USERVALUE}\" is not a number"
               print -u 2 "${__DEBUG_MSG_COLOR}${__LINE_VAR}"
               continue
             fi         
             j=$(( ${i}+ ${__USERVALUE} -1 )) 
           else
             j=$(( ${i}+9 ))   
           fi

           [ ${j} -gt ${__SCRIPT_ARRAY[0]} ] && j=${__SCRIPT_ARRAY[0]}

           while [ i -le j ] ; do
             NUM_VAR=$i
             if [ $i -eq ${__LINENO} ] ; then
               __SRCLINE_VAR=">>> ${__SCRIPT_ARRAY[$i]}"
               print -u 2 "${__CUR_LINE_COLOR}${NUM_VAR} ${__SRCLINE_VAR}"
             else
               __SRCLINE_VAR="    ${__SCRIPT_ARRAY[$i]}"
               print -u 2 "${__LINE_COLOR}${NUM_VAR} ${__SRCLINE_VAR}"
             fi 
             i=$(( i+1 ))
           done      
     
           ;;
   
      "exit" | "quit" )  :
           print "${__COLOR_OFF}"
           [ "${__USERPARMS}"x = ""x ] && die 500 "Program aborted by the user"
           die ${__USERPARMS} 
           ;;

      * ) executeCommand ${__USERINPUT} ${__USERPARMS} ${__USERVALUE} ${__USERVALUE2}
            ;;
    esac
  done
  print "${__COLOR_OFF}"

  return ${__LAST_RC}
}

## ---------------------------------------
## ShowShortUsage
##
## print the (short) usage help
##
## usage: ShowShortUsage
##
## returns: -
##
ShowShortUsage() {

cat <<EOT
  ${__SCRIPTNAME} ${__SCRIPT_VERSION} - ${__SHORT_DESC}

  Usage: ${__SCRIPTNAME} [-v] [-q] [-h] [-l logfile] [-y] [-n] [-D] 
                   [-a {y|n}] [-O {y|n}] [-H] [-V] [-R] 
                   [-f] [-b] [-t] [-e] [-d] [-N] [-s writerspeed,readerspeed]
                   [-m] [-r] [-w] [-x action] [parameter]  
EOT
}

## ---------------------------------------
## ShowUsage
##
## print the (long) usage help
##
## usage: ShowUsage
##
## returns: -
##
##
ShowUsage() {
  ShowShortUsage
cat <<EOT
    Parameter:

      -x - action, action can be:
               createconfig [configfile]
               install [configfile]
	       uninstall
               createISOimg sourcedir [isofile] [volid]
	       writecdrom|writecd sourcedir [volid]
	       writedvd sourcedir [volid]
               readcdrom|testcd isofile [srcdevice]
	       readdvd isofile [srcdevice] 
	       burncdrom|burncd isofile
	       burndvd isofile
               clonecdrom|clonecd [srcdevice]
	       clonedvd  [srcdevice]	       
               copycdrom|copycd [srcdevice]
	       copydvd  [srcdevice]	       
	       copyaudiocd [srcdevice] [useCDDB]
	       readaudiocd [targetdir] [sourcedevice] [useCDDB]
	       writeaudiocd [sourcedir] [targetdevice]
	       blankcdrom|blankcd [blanktype]
	       blankdvd [blanktype]
	       ejectcdrom|ejectcd [device]
	       ejectdvd	[device]       
	       loadcdrom|loadcd [device]
	       loaddvd [device]       
	       testcdrom|testcd [sourcedevice]
	       testdvd [sourcedevice]
               testiso isofile
	       listcdrom|listcd [sourcedevice]
	       listdvd [sourcedevice]
               listiso isofile
	       verifycdrom|verifycd [device]

      -f - switch the "write the CD/DVD on the fly" flag
           Current Status is $( ConvertToYesNo ${WRITE_ON_THE_FLY} )
      -b - switch the "blank the CD/DVD before burning" flag
           Current Status is $( ConvertToYesNo ${BLANK_THE_MEDIUM} )
      -t - switch the "test the CD/DVD after burning" flag
           Current Status is $( ConvertToYesNo ${TEST_THE_MEDIUM} )
      -V - switch the "verify the CD/DVD after burning" flag
           Current Status is $( ConvertToYesNo ${VERIFY_THE_MEDIUM} )
      -R - switch the "relaod the CD/DVD before doing anything" flag
           Current Status is $( ConvertToYesNo ${RELOAD_THE_MEDIUM} )
      -L - switch the "list the CD/DVD after burning" flag
           Current Status is $( ConvertToYesNo ${LIST_THE_MEDIUM} )
      -e - switch the "eject the CD/DVD after burning" flag
           Current Status is $( ConvertToYesNo ${EJECT_THE_MEDIUM} )
      -d - switch the "write the CD/DVD in dummy mode" flag
           Current Status is $( ConvertToYesNo ${DUMMY_MODE} )
      -N - switch the "do NOT check the directory size of the source dir" flag
           Current Status is $( ConvertToYesNo ${CHECK_DIR_SIZE} )
      -s - set the writer and/or reader speed 
           Default: ${DEFAULT_WRITER_SPEED},${DEFAULT_READER_SPEED}
      -m - process multi disks
           Current Status is $( ConvertToYesNo ${PROCESS_MANY_DISKS} )
      -r - switch the "remove the ISO image after burning" flag
           Current Status is $( ConvertToYesNo ${REMOVE_ISO_IMAGE} )
	   
      -w - switch the "wait for user pressing return before ending the script" flag
           Current Status is $( ConvertToYesNo ${WAIT_FOR_USER} )
	
      -v - turn verbose mode on
      -q - turn quiet mode on
      -h - show usage 
      -l - set the logfile
           Def.: ${__DEF_LOGFILE}
      -y - assume yes to all questions
      -n - assume no to all questions
      -D - run main in single step mode (and turn colors on) 
      -a - turn colors on (y) or off (n), Default: $( ConvertToYesNo "${__USE_COLORS}" )     
      -O - overwrite existing files (y) or not (n), Default: $( ConvertToYesNo "${__OVERWRITE_MODE}" )
      
      -H - write extended usage to STDERR

    Use the environment variables DVDRECORD_OPTIONS, CDRECORD_OPTIONS
    MKISOFS_OPTIONS, READCD_OPTIONS, and CDDA2WAV_OPTIONS for additional 
    parameter for dvdrecord, cdrecord, mkisofs, readcd, or cdda2wav.

    The file "${DVD_OPTION_FILE}" must contain the license key for
    dvdrecord/cdrecord.

    The config file "${__CONFIG_FILE}" is searched in the current 
    directory and in the HOME directory (in this order).

    Use "easycd.sh -x install" to create the symbolic links in the
    current directory; use "easycd.sh -x uninstall" to remove the
    symbolic links in the current directory.

EOT

  return 0      
}


## ---------------------------------------
## StartStopVolumeMgmt
##
## start or stop the volume management if neccessary
##
## usage: StartStopVolumeMgmt [init|start|stop]
##
## returns: -
##
StartStopVolumeMgmt() {
  if [ "$1"x = "init"x ] ; then
    VOLMGT_STOPPED=${__FALSE}
  fi  

  if [ "$1"x = "start"x ] ; then
    if [ ${VOLMGT_STOPPED} = ${__TRUE} ] ; then
      LogMsg "Starting the volume management ..."
      /etc/init.d/volmgt start
      VOLMGT_STOPPED=${__FALSE}
    fi
  fi
 
  if [ "$1"x = "stop"x ] ; then
    ps -ef | grep -v grep | grep /usr/sbin/vold >/dev/null
    if [ $? -eq 0 ] ; then
      LogMsg "Stopping the volume management ..."

      /etc/init.d/volmgt stop
      VOLMGT_STOPPED=${__TRUE}

      LogMsg "Waiting ${VOLD_WAIT_TIME} seconds for vold to stop"
      sleep ${VOLD_WAIT_TIME}
    fi  
  fi  

  return
}

## ---------------------------------------
## PreChecks
##
## check that the necessary binaries and directories exist
##
## usage: check [check_action] [...]
##
## returns: ${__TRUE} - ok
##          ${__FALSE) - error
##
##
PreChecks() {
  typeset THISRC=${__TRUE}
  typeset TEMPVAR1=
  typeset TEMPVAR2=
  
  for i in $* ; do
    case $i in

      "lofiadm" )
        shift 
	LogInfo "Checking if lofiadm is availalb ..."
	which lofiadm | read TEMPVAR1 TEMPVAR2
	[ "${TEMPVAR1}"x != "no"x ] && continue
	LogError "\"lofiadm\" not found or not executable"
	THISRC=${__FALSE}
        ;;	
	
      "cdrecord" )  
        shift 
	LogInfo "Checking the executable \"${RECORD_BINARY}\" ..."
        [ -x "${RECORD_BINARY}" ] && continue
	LogError "\"${RECORD_BINARY}\" not found or not executable"
	THISRC=${__FALSE}
	;;

      "mkisofs" )	
        shift 
	LogInfo "Checking the executable \"${MKISOFS_BINARY}\" ..."
        [ -x "${MKISOFS_BINARY}" ] &&  continue
	LogError "\"${MKISOFS_BINARY}\" not found or not executable"
	THISRC=${__FALSE}
	;;

      "readcd" )
        shift 
	LogInfo "Checking the executable \"${READCD_BINARY}\" ..."
        [ -x "${READCD_BINARY}" ] &&  continue
	LogError "\"${READCD_BINARY}\" not found or not executable"
	THISRC=${__FALSE}
	;;

      "cdda2wav" )
        shift 
	LogInfo "Checking the executable \"${CDDA2WAV_BINARY}\" ..."
        [ -x "${CDDA2WAV_BINARY}" ] &&  continue
	LogError "\"${CDDA2WAV_BINARY}\" not found or not executable"
	THISRC=${__FALSE}
	;;

      "sourcedir" )  
        shift 
	LogInfo "Checking the directory \"${IMG_SOURCE_BASE_DIR}\" ..."

        [ -d "${IMG_SOURCE_BASE_DIR}" ] &&  continue
	LogError "Directory \"${IMG_SOURCE_BASE_DIR}\" not found"
	THISRC=${__FALSE}
	;;

      "targetdir" )
        shift 
	LogInfo "Checking the directory \"${IMG_TARGET_DIR}\" ..."
        [ -d "${IMG_TARGET_DIR}" ] &&  continue
	LogError "Directory \"${IMG_TARGET_DIR}\" not found"
	THISRC=${__FALSE}
	;;

      "logdir" )
        shift 
	LogInfo "Checking the directory \"${LOG_DIR}\" ..."
        [ -d "${LOG_DIR}" ] &&  continue
	LogError "Directory \"${LOG_DIR}\" not found"
	THISRC=${__FALSE}
	;;

      * ) 
        shift 
        LogError "PreChecks: Don't know what to do with \"$i\" "
	THISRC=${__FALSE}
	;;
	
    esac

  done

  return ${THISRC} 
}


## ---------------------------------------
## ProcessAnother
##
## ask the user if she wants to process another disk
##
## usage: AskUser msg
##
## returns: ${__TRUE} - yes, process another
##          ${__FALSE) - no, do not process another
##
##
ProcessAnother() {
  typeset THISMSG="$*"
  typeset THISRC=${__FALSE}
  
  if [ ${PROCESS_MANY_DISKS} = ${__TRUE} ] ; then
    AskUser "### ${THISMSG} " 
    THISRC=$?
  fi
  return ${THISRC}
}

## ---------------------------------------
## InitOutputFile
##
## check if a file exist
##
## usage: InitOutputFile ISOFile
##
## returns: ${__TRUE} - ok, the file does not exist or overwrite mode is true
##          ${__FALSE} - error , the file exist and overwrite mode is false
##
## Note:  if the file exists and overwrite mode is true, the file will be DELETED!
##
InitOutputFile() {
  typeset THIS_FILE="$1"
  typeset THISRC=${__TRUE}

  if [ -f "${THIS_FILE}" ] ; then
    if [ ${__OVERWRITE_MODE} = ${__TRUE} ] ; then
      LogInfo "Deleting the existing file \"${THIS_FILE}\" ..."
      rm "${THIS_FILE}"
    else
      THISRC=${__FALSE}       
    fi
  fi    
  return ${THISRC}
}

## ---------------------------------------
## CheckSourceDevice
##
## check the source device parameter
##
## usage: CheckSourceDevice sourcedevice defaultdevice
##
## returns: ${__TRUE} - ok,
##            The variable ${THIS_DEV} contains device name for CDRECORD 
##            The variable ${MOUNT_DEV} contains the device to mount
##            The variable ${RAW_DEV} contains the raw device 
##          ${__FALSE) - error
##
##
CheckSourceDevice() {
  typeset THIS_SOURCEDEVICE="$1"
  typeset THISRC=${__FALSE}

  THIS_DEV=""
  MOUNT_DEV=""
  RAW_DEV=""
  
  [ "${THIS_SOURCEDEVICE}"x = ""x ] && THIS_SOURCEDEVICE="$2"

  case "${THIS_SOURCEDEVICE}" in

    "${SOURCE_DEVICE}" )     
      THIS_DEV="${READER_DEV}"
      MOUNT_DEV="${READER_DEVICE}"
      RAW_DEV="${READER_RAW_DEVICE}"
      THISRC=${__TRUE}

      StartStopVolumeMgmt stop   
      ;;

    "${TARGET_DEVICE}" ) 
      THIS_DEV="${WRITER_DEV}"
      MOUNT_DEV="${WRITER_DEVICE}"
      RAW_DEV="${WRITER_RAW_DEVICE}"
      THISRC=${__TRUE}
      ;;

    "${READER_DEV}" )     
      THIS_DEV="${READER_DEV}"
      MOUNT_DEV="${READER_DEVICE}"
      RAW_DEV="${READER_RAW_DEVICE}"
      THISRC=${__TRUE}

      StartStopVolumeMgmt stop   
      ;;

    "${WRITER_DEV}" ) 
      THIS_DEV="${WRITER_DEV}"
      MOUNT_DEV="${WRITER_DEVICE}"
      RAW_DEV="${WRITER_RAW_DEVICE}"
      THISRC=${__TRUE}
      ;;

    "writer" | "nec" ) 
      THIS_DEV="${WRITER_DEV}"
      MOUNT_DEV="${WRITER_DEVICE}"
      RAW_DEV="${WRITER_RAW_DEVICE}"
      THISRC=${__TRUE}
      ;;

    "reader" | "plextor" ) 
      THIS_DEV="${READER_DEV}"
      MOUNT_DEV="${READER_DEVICE}"
      RAW_DEV="${READER_RAW_DEVICE}"
      THISRC=${__TRUE}

      StartStopVolumeMgmt stop   

      ;;
    
    * ) THISRC=${__FALSE}
    
  esac

  LogInfo "CheckSourceDevice: The source device is \"${THIS_DEV}\" "
  LogInfo "CheckSourceDevice: The device to mount is \"${MOUNT_DEV}\" " 
  LogInfo "CheckSourceDevice: The raw device is \"${RAW_DEV}\" " 

  return ${THISRC}
}


## ---------------------------------------
## CalculateDirSize
##
## calculate the directory size using mkisofs
##
## usage: CalculateDirSize sourcedir
##
## returns: DIR_SIZE contains the size of the direcory in KByte 
##          TREE_SIZE contains the size of the directory in 2048K blocks
##
##
CalculateDirSize() {
  typeset SOURCEDIR="$1"
 
  TREE_SIZE=$( ${MKISOFS_BINARY} ${MKISOFS_PARM}  -R -q -print-size "${SOURCEDIR}" )
  (( DIR_SIZE=TREE_SIZE * 2 )) 

  LogInfo "CalculateDirSize: DIR_SIZE is ${DIR_SIZE}"
  LogInfo "CalculateDirSize: TREE_SIZE is ${TREE_SIZE}"
}

## ---------------------------------------
## CalculateFreespace
##
## calculate the free space in a directory 
##
## usage: CalculateFreespace sourcedir
##
## returns: The variable ${FREE_SPACE} contains the free space in KByte
##
CalculateFreespace() {
  typeset SOURCEDIR="$1"

  typeset THISRC=0

  set -- $( df -k "${SOURCEDIR}" | grep -v Filesystem )
  if [ $? -ne 0 ] ; then
    FREE_SPACE=-1
  else 
    FREE_SPACE=$4
  fi    

  LogInfo "CalculateFreespace: Freespace is ${THISRC}"

  return ${FREE_SPACE}
}


## ---------------------------------------
## CheckISOImageSize
##
## check the size of an ISO image
##
## usage: CheckISOImageSize ISOFile
##
## returns: ${__TRUE} - ok, the size fits on the current medium
##          ${__FALSE} - error , the image is to big for the current medium
##
CheckISOImageSize() {
  typeset ISO_IMAGE_FILE="$1"
  typeset THISRC=${__FALSE}
  
  IMG_SIZE=0  
  
  du -ks "${ISO_IMAGE_FILE}" | read IMG_SIZE d1
  
  LogInfo "CheckISOImageSize: The image size is ${IMG_SIZE} (current max size is ${MAX_IMG_SIZE})"

  [ ${IMG_SIZE} -lt ${MAX_IMG_SIZE} ] && THISRC=${__TRUE}
}

## ---------------------------------------
## CheckMediumSize
##
## check the size of an CD/DVD
##
## usage: CheckMediumSize thisdevice
##
## returns: ${__TRUE} - ok, the variable ${MEDIUM_SIZE} contains the size of the medium
##          ${__FALSE} - error  
##
##
CheckMediumSize() {
  typeset THIS_DEVICE="$1"
  typeset THISRC=${__TRUE}

  typeset d1=""
  typeset d2=""
  typeset d3=""
  
  MEDIUM_SIZE=0

  LogInfo "Mounting \"${THIS_DEVICE}\" to \"${TEMP_MOUNT_POINT}\" ..."
  mkdir -p "${TEMP_MOUNT_POINT}" || die 70 "Can not create the temporary mount point \"${TEMP_MOUNT_POINT}\" "
  mount -o ro -F hsfs "${THIS_DEVICE}" "${TEMP_MOUNT_POINT}" || die 75 "Can not mount the device \"${THIS_DEVICE}\" to \"${TEMP_MOUNT_POINT}\" "  

  df -k "${TEMP_MOUNT_POINT}" | grep -v Filesystem | read d1 d2 MEDIUM_SIZE d3
  umount "${TEMP_MOUNT_POINT}"

  LogInfo "CheckMediumSize: The medium size is ${MEDIUM_SIZE} "

  return ${THISRC}
}

## ---------------------------------------
## RemoveImageFile
##
## remove an ISO image file if it exists
##
## usage: RemoveImageFile
##
## returns: 0 - ok
##          else error
##
##
RemoveImageFile() {
  typeset ISO_IMAGE_FILE="$1"

  typeset THISRC=-1
  
  if [ -f "${ISO_IMAGE_FILE}" ] ; then
    LogMsg "Removing the file \"${ISO_IMAGE_FILE}\" ..."
    rm "${ISO_IMAGE_FILE}"
    THISRC=$?
  fi    

  return ${THISRC}
}

## ---------------------------------------
## ReadAudioCD
##
## read an audio CD
##
## usage: ReadAudioCD sourcedevice targetdir usecddb
##
## returns: 0 - ok
##          else error
##
ReadAudioCD() {

  typeset THIS_DEV="$1"
  typeset THIS_DIR="$2"
  typeset USE_CDDB="$3"
  
  typeset THISRC=0
  
  if [ "${USE_CDDB}"x = "y"x  -o "${USE_CDDB}"x = "Y"x ] ; then
    CDDA2WAV_PARM="${CDDA2WAV_PARM} cddb=0 "
  fi

  [ "${THIS_DIR}"x = ""x ] && THIS_DIR="audio.$$"
  
  typeset DIRNAME="${THIS_DIR##*/}"
  typeset DIRPATH="${THIS_DIR%/*}"
  [ "${DIRNAME}" = "${THIS_DIR}" ] && THIS_DIR="${IMG_TARGET_DIR}/${THIS_DIR}" 

  if [ -d "${THIS_DIR}" ] ; then
    [ -f ${THIS_DIR}/* ] && die 100 "The target directory \"${THIS_DIR}\" already exist"
  else	
    mkdir -p "${THIS_DIR}" || die 115 "Can not create the target directory \"${THIS_DIR}\" "
  fi

  LogMsgInvers "Reading the audio CD \"${THIS_DEV}\" and writing the output files to \"${THIS_DIR}\" ..."

  if [ ${CHECK_DIR_SIZE} = ${__TRUE} ] ; then
    CalculateFreespace $( dirname "${THIS_DIR}" ) 

    LogMsg "The freespace in the target directory is about ${FREE_SPACE} KByte"	
    if [ ${FREE_SPACE} -lt 700000 ] ; then
      AskUser "The free space in the target directory \"${THIS_DIR}\" is less than 700 MB -continue anyway? (y/N)"
      [ $? -eq ${__FALSE} ] && die 60 "Not enough free space to read the audio cd"
    fi
  fi

  oPWD=$( pwd )
  cd ${THIS_DIR}      
  traceon
  ${CDDA2WAV_BINARY} ${CDDA2WAV_PARM}  -D "${THIS_DEV}" -B 
  THISRC=$?
  traceoff
  cd ${oPWD}

  return ${THISRC}  
}

## ---------------------------------------
## WriteAudioCD
##
## write an audio CD
##
## usage: WriteAudioCD sourcedevice targetdir 
##
## returns: 0 - ok
##          else error
##
WriteAudioCD() {
  typeset THIS_DEV="$1"
  typeset THIS_DIR="$2"

  typeset DIRNAME="${THIS_DIR##*/}"
  typeset DIRPATH="${THIS_DIR%/*}"
  [ "${DIRNAME}" = "${THIS_DIR}" ] && THIS_DIR="${IMG_TARGET_DIR}/${THIS_DIR}"

  [ ! -d ${THIS_DIR} ] && die 100 "Invalid source directory entered: \"${THIS_DIR}\" "
  [ ! -f ${THIS_DIR}/*wav ] && die 120 "wav files missing in the directory \"${THIS_DIR}\" "
  [ ! -f ${THIS_DIR}/*inf ] && die 120 "inf files missing in the directory \"${THIS_DIR}\" "
      
  LogMsgInvers "Reading the audio files from \"${THIS_DIR}\" and writing the audio CD in \"${THIS_DEV}\"  ..."
  oPWD=$( pwd )
  cd "${THIS_DIR}"    
  traceon
  ${RECORD_BINARY} dev="${WRITER_DEV}" ${RECORD_PARM} -v -dao -useinfo *.wav
  THISRC=$?
  traceoff
  cd ${oPWD}

  return ${THISRC}  
}

## ---------------------------------------
## BurnISOImage
##
## burn an ISO image to CDROM
##
## usage: BurnISOImage ISOFile
##
## returns: 0 - ok
##          else error
##
BurnISOImage() {
  typeset ISO_IMAGE_FILE="$1"

  typeset THISRC=-1
  LogMsgInvers "Burning the ISO image \"${ISO_IMAGE_FILE}\"  ..."

  traceon    
  ${RECORD_BINARY} dev="${WRITER_DEV}" ${RECORD_PARM} "${ISO_IMAGE_FILE}"
  THISRC=$?
  traceoff
  
  return ${THISRC}  
}

## ---------------------------------------
## CopyDataToCDOnTheFly
##
## copy a directory tree to a CDROM on the fly
##
## usage: CopyDataToCDOnTheFly sourcedir volid
##
## returns: 0 - ok
##          else - error
##
CopyDataToCDOnTheFly() {
  typeset SOURCEDIR="$1"
  typeset VOLID="$2"
 
  typeset THISRC=-1

  LogMsgInvers "Writing the directory \"${SOURCEDIR}\" to the medium ..."
  traceon         
  ${MKISOFS_BINARY} ${MKISOFS_PARM} -volid "${VOLID}" -log-file ${__LOGFILE}.MKISOFS \
                    -v "${SOURCEDIR}" | ${RECORD_BINARY} -waiti dev="${WRITER_DEV}" ${RECORD_PARM} -
  THISRC=$?
  traceoff
      
  return ${THISRC}
}

## ---------------------------------------
## CopyDataToDVDOnTheFly
##
## copy a directory tree to a DVD on the fly
##
## usage: CopyDataToDVDOnTheFly sourcedir volid treesize
##
## returns: 0 - ok
##          else - error
##
##
CopyDataToDVDOnTheFly() {
   typeset SOURCEDIR="$1"
   typeset VOLID="$2"
   typeset TREESIZE="$3"
   
   typeset THISRC=-1

   LogMsgInvers "Writing the directory \"${SOURCEDIR}\" to the medium ..."
   AskUser "Burning DVDs on the fly may not always work. Do you want to continue?"

   traceon         
   ${MKISOFS_BINARY} ${MKISOFS_PARM} -volid "${VOLID}" -log-file ${__LOGFILE}.MKISOFS \
                    -v "${SOURCEDIR}" | ${RECORD_BINARY} -waiti dev="${WRITER_DEV}" ${RECORD_PARM} -fs8m -tsize=${TREESIZE} -
   THISRC=$?
   traceoff  
   return ${THISRC}
}

## ---------------------------------------
## DirToISOImage
##
## create an ISO image from a directory tree
##
## usage: DirToISOImage sourcedir targetISOFile [volid]
##
## returns: 0 - ok
##          else - error
##
DirToISOImage() {
  typeset SOURCEDIR="$1"
  typeset ISO_IMAGE_FILE="$2"
  typeset VOLID="$3"

  typeset THISRC=0
  
  IMG_NAME=${ISO_IMAGE_FILE%.*}
  [ "$VOLID}"x = ""x ] && VOLID="${IMG_NAME}"

  LogMsgInvers "Creating the ISO image file \"${ISO_IMAGE_FILE}\" from the directory tree \"${SOURCEDIR}\"..."

  traceon
  ${MKISOFS_BINARY} ${MKISOFS_PARM}  -volid "${VOLID}" -o ${ISO_IMAGE_FILE} \
                    -log-file ${__LOGFILE}.MKISOFS -v "${SOURCEDIR}" ${MKISOFS_ADD_PARMS}

  THISRC=$?
  traceoff
  
  return ${THISRC}
}

## ---------------------------------------
## CDToISOImage
##
## create an ISO image from a CD/DVD
##
## usage: CDToISOImage sourcedevice isoimagefile
##
## returns: 0 - ok
##          else - error
##          
##
CDToISOImage() {
  typeset SOURCE_DEVICE="$1"
  typeset ISO_IMAGE_FILE="$2"

  typeset THISRC=0

  LogMsgInvers "Creating the ISO image file \"${ISO_IMAGE_FILE}\" from the medium in the drive ${SOURCE_DEVICE}..."

  traceon
   dd if=${SOURCE_DEVICE} of="${ISO_IMAGE_FILE}" bs=2048
  THISRC=$?
  traceoff

  return ${THISRC}
}

## ---------------------------------------
## CDToRAWImage
##
## create a RAW image from a CD/DVD
##
## usage: CDToRAWImage sourcedevice rawimagefile
##
## returns: 0 - ok
##          else - error
##          
##
CDToRAWImage() {
  typeset SOURCE_DEVICE="$1"
  typeset RAW_IMAGE_FILE="$2"

  typeset THISRC=0
  
# reload the CD/DVD
  EjectMedium "${SOURCE_DEVICE}"
  sleep ${VOLD_WAIT_TIME}
  LoadMedium "${SOURCE_DEVICE}"

  LogMsgInvers "Creating the RAW image file \"${ISO_IMAGE_FILE}\" from the medium in the drive ${SOURCE_DEVICE}..."

  traceon
  ${READCD_BINARY} dev=${SOURCE_DEVICE} ${READCD_PARM} -f "${RAW_IMAGE_FILE}"
  THISRC=$?
  traceoff

  LogMsg "NOTE: If the disk contains many sectors that are unreadable by intention"
  LogMsg "      use \"export READCD_OPTIONS=-nocorr\" before calling ${__SCRIPTNAME} "

  return ${THISRC}
}

## ---------------------------------------
## BlankMedium
##
## blank the medium (CD/DVD)
##
## usage: BlankMedium targetdevice [blanktype]
##
## returns: 0 - ok
##          else - error
##
##
BlankMedium() {
  typeset TARGETDEVICE="$1"
  typeset BLANK_TYPE="$2"

  typeset THISRC=-1
  typeset ADD_PARM=""
  
  [ "${BLANK_TYPE}"x = ""x ] && BLANK_TYPE="${DEFAULT_BLANK_TYPE}"
  
  LogMsgInvers "Blanking the medium in the device \"${TARGETDEVICE}\" with \"BLANK=${BLANK_TYPE}\" ..."

  [ "${DUMMY_MODE}" = "${__TRUE}" ] && ADD_PARM="-dummy"

  traceon
  ${RECORD_BINARY} dev=${TARGETDEVICE} ${ADD_PARM} "gracetime=2" blank=${BLANK_TYPE}
  THISRC=$?
  traceoff
  return ${THISRC}
}

## ---------------------------------------
## ReloadMedium
##
## reload the medium (CD/DVD)
##
## usage: ReloadMedium targetdevice 
##
## returns: 0 - ok
##          else - error
##
ReloadMedium() {
  typeset TARGETDEVICE="$1"

  typeset THISRC=-1
  LogMsgInvers "Reloading the medium ..."
  
  EjectMedium ${TARGETDEVICE}
  sleep ${VOLD_WAIT_TIME} 
  LoadMedium ${TARGETDEVICE}
  THISRC=$?

  return ${THISRC}
}

  
## ---------------------------------------
## EjectMedium
##
## eject the medium (CD/DVD)
##
## usage: EjectMedium targetdevice 
##
## returns: 0 - ok
##          else - error
##
EjectMedium() {
  typeset TARGETDEVICE="$1"

  typeset THISRC=-1

  LogMsgInvers "Ejecting the medium in the device \"${TARGETDEVICE}\"..."

  traceon
  ${RECORD_BINARY} dev=${TARGETDEVICE} ${EJECT_PARM}
  THISRC=$?
  traceoff
  return ${THISRC}
}

## ---------------------------------------
## LoadMedium
##
## load the medium (CD/DVD)
##
## usage: LoadMedium targetdevice 
##
## returns: 0 - ok
##          else - error
##
LoadMedium() {
  typeset TARGETDEVICE="$1"

  typeset THISRC=-1

  LogMsgInvers "Loading the medium into the device \"${TARGETDEVICE}\" ..."

  traceon
  ${RECORD_BINARY} dev=${TARGETDEVICE} ${LOAD_PARM}
  THISRC=$?
  traceoff
  
  return ${THISRC}
}

## ---------------------------------------
## TestMedium
##
## check the zip and gz files on a CD/DVDROM or 
## list all files on the medium
##
## usage: TestMedium targetdevice [action]
##
## returns: 0 - ok
##          else - error
##
##
TestMedium() {
  typeset THIS_DEV="$1"
  typeset THISRC=0
  typeset THIS_ACTION=$2

  if [ "${DUMMY_MODE}" = "${__TRUE}" ] ; then
    LogWarning "Can not test the medium in dummy mode!"
    return ${__FALSE}
  fi
        
  if [ ${THIS_DEV} = ${WRITER_DEV} ] ; then
    THIS_DEV=${WRITER_DEVICE}
  else	
    THIS_DEV=${READER_DEVICE}
  fi	 

  LogMsgInvers "Checking the medium in the device \"${THIS_DEV}\" ..."  

  LogMsg "Mounting the medium to \"${TEMP_MOUNT_POINT}\" ..."
  mkdir -p "${TEMP_MOUNT_POINT}" || die 70 "Can not create the temporary mount point \"${TEMP_MOUNT_POINT}\" "
  mount -o ro -F hsfs ${THIS_DEV} "${TEMP_MOUNT_POINT}" || die 75 "Can not mount the device \"${THIS_DEV}\" to \"${TEMP_MOUNT_POINT}\""
   
  __USER_BREAK_ALLOWED=${__FALSE}

  if [ "${THIS_ACTION}"x = "list"x ] ; then
    LogMsg "List all files on the medium ..."
    ls -lR "${TEMP_MOUNT_POINT}" 
    THISRC=$?
  else
    LogMsg "Checking zip files ..."

#  find ${TEMP_MOUNT_POINT} -name "*zip" -o -name "*ZIP" -depth -exec unzip -t {} >/dev/null  \;
    find "${TEMP_MOUNT_POINT}" \( -name "*zip" -o -name "*ZIP" \) -exec unzip -t {} \;  -o -name "*gz" -exec gzip -t {} \; >/dev/null
    THISRC=$?
    LogMsg ""
  fi
    
  __USER_BREAK_ALLOWED=${__TRUE}

  umount "${TEMP_MOUNT_POINT}"

  return ${THISRC}   
}

## ---------------------------------------
## VerifyMedium
##
## verify the  CD using readcd
##
## usage: VerifyMedium targetdevice 
##
## returns: 0 - ok
##          else - error
##
##
VerifyMedium() {
  typeset THIS_DEV="$1"
  typeset THISRC=0

  if [ ${USE_DVD} != "c" ] ; then
    LogWarning "Can not verify DVDs!"
    return ${__FALSE}
  fi
  
  if [ "${DUMMY_MODE}" = "${__TRUE}" ] ; then
    LogWarning "Can not verify the medium in dummy mode!"
    return ${__FALSE}
  fi
        
  LogMsgInvers "Verifying the medium in the device \"${THIS_DEV}\" ..."  

  ${READCD_BINARY} dev=${THIS_DEV} ${READCD_PARM} -c2scan
  THISRC=$?

  return ${THISRC}   
}


## ---------------------------------------
## TestISOFile
##
## check the zip and gz files in an ISO image or list them
##
## usage: TestISOFile isoFile [action]
##
## returns: 0 - ok
##          else - error
##
##
TestISOFile() {
  typeset THIS_ISO="$1"
  typeset THISRC=0
  typeset THIS_ACTION=$2
  
  typeset TMP_DEV=""

  LogMsgInvers "Checking the ISO file \"${THIS_ISO}\" ..."  

  LogInfo "Calling lofiadm -a \"${THIS_ISO}\"..."
  TEMP_LOFI_DEVICE=$( lofiadm -a "${THIS_ISO}" ) || die 50 "Error calling \"lofiadm -a ${THIS_ISO}\"" 

  mkdir -p "${TEMP_MOUNT_POINT}" || die 70 "Can not create the temporary mount point \"${TEMP_MOUNT_POINT}\" "

  LogMsg "Mounting the ISO file to \"${TEMP_MOUNT_POINT}\" ..."
  mount -o ro -F hsfs ${TEMP_LOFI_DEVICE} "${TEMP_MOUNT_POINT}" || die 75 "Can not mount the device \"${TEMP_LOFI_DEVICE}\" to \"${TEMP_MOUNT_POINT}\""
   
  __USER_BREAK_ALLOWED=${__FALSE}

  if [ "${THIS_ACTION}"x = "list"x ] ; then
    LogMsg "List all files on the medium ..."
    ls -lR "${TEMP_MOUNT_POINT}" 
    THISRC=$?
  else
    LogMsg "Checking zip files ..."

#  find ${TEMP_MOUNT_POINT} -name "*zip" -o -name "*ZIP" -depth -exec unzip -t {} >/dev/null  \;
    find "${TEMP_MOUNT_POINT}" \( -name "*zip" -o -name "*ZIP" \) -exec unzip -t {} \;  -o -name "*gz" -exec gzip -t {} \; >/dev/null
    THISRC=$?
    LogMsg ""
  fi 

  LogInfo "Umounting \"${TEMP_MOUNT_POINT}\" ..."
  umount "${TEMP_MOUNT_POINT}"
  
  LogInfo "Calling lofiadm -d \"${THIS_ISO}\" ..."
  lofiadm -d "${THIS_ISO}"
  [ $? -eq 0 ] && TEMP_LOFI_DEVICE=""

  __USER_BREAK_ALLOWED=${__TRUE}

  return ${THISRC}   
}

## ---------------------------------------
## CloneMedium
##
## clone the medium (CD/DVD)
##
## usage: CloneMedium srcdevice tempdir [imgfile]
##
## returns: 0 - ok
##          else - error
##
##
CloneMedium() {
  typeset READER_DEV="$1"

  typeset TEMPDIR="$2"
  typeset IMG_FILE="$3"

  typeset THISRC=-1
  typeset OUTFILE=""
  
  typeset USERINPUT=""
  
  LogMsgInvers "Cloning the medium ..."

  if [ "${IMG_FILE}"x = ""x ] ; then
    OUTFILE="${TEMPDIR}/MEDIUM.$$.IMG"
  
    LogMsgInvers "Reading the medium to \"${OUTFILE}\" ..."
    traceon
    ${READCD_BINARY} dev=${READER_DEV} ${READCD_PARM} -clone f="${OUTFILE}"
    THISRC=$?
    traceoff
  else
    LogMsgInvers "Using the existing image file \"${IMG_FILE}\" "
    OUTFILE="${IMG_FILE}"
    THISRC=0
  fi
   
  if [ ${THISRC} -eq 0 ] ; then

    if [ ${WRITER_DEV} = ${READER_DEV} -a "${IMG_FILE}"x = ""x ] ; then
      EjectMedium ${WRITER_DEV}

      echo "### Remove the source disk and insert the target disk"
      echo "### Press enter when done"
      read USERINPUT

      LoadMedium ${WRITER_DEV}
    fi

    while [ 0 = 0 ] ; do

      PreProcessing "DONT_DIE" ${WRITER_DEV} "BLANK_MEDIUM"
      if [ $? -eq 0 ] ; then   
        LogMsg "Writing the medium from \"${OUTFILE}\"..."
        traceon
        ${RECORD_BINARY} dev=${WRITER_DEV} "gracetime=2" -v -clone -raw "${OUTFILE}"
        THISRC=$?
        traceoff

        [ ${THISRC} = 0 ] && PostProcessing "DONT_DIE" "${WRITER_DEV}" "RELOAD_MEDIUM" "TEST_MEDIUM" "LIST_MEDIUM" "VERIFY_MEDIUM"
      fi

      ProcessAnother "Write another medium?"
      [ $? -eq ${__FALSE} ] && break

      EjectMedium ${WRITER_DEV}

      echo "### Remove the disk and insert another target disk"
      echo "### Press enter when done"
      read USERINPUT
 
      LoadMedium ${WRITER_DEV}

    done  

    PostProcessing "${OUTFILE}" "REMOVE_IMG"
    PostProcessing "${WRITER_DEV}" "EJECT_MEDIUM"

  fi

  return ${THISRC}
}

## ---------------------------------------
## CloneMediumOnTheFly
##
## clone the medium (CD/DVD) on the fly
##
## usage: CloneMediumOnTheFly srcdevice 
##
## returns: 0 - ok
##          else - error
##
##
CloneMediumOnTheFly() {
  typeset READER_DEV="$1"

  typeset THISRC=-1
  
  typeset USERINPUT=""

  while [ 1 = 1 ] ; do

    PreProcessing "DONT_DIE" ${WRITER_DEV} "BLANK_MEDIUM"
    if [ $? -eq 0 ] ; then 
      LogMsgInvers "Cloning the medium on the fly  ..."

      traceon
      ${READCD_BINARY} dev=${READER_DEV} ${READCD_PARM} -q f=- | \
         ${RECORD_BINARY} dev=${WRITER_DEV} "-waiti" "gracetime=2" -
      THISRC=$?
      traceoff

      [ ${THISRC} = 0 ] && PostProcessing "DONT_DIE" ${WRITER_DEV} "RELOAD_MEDIUM" "TEST_MEDIUM" "LIST_MEDIUM" "VERIFY_MEDIUM"
    fi

    ProcessAnother "Write another medium?"
    [ $? -eq ${__FALSE} ] && break

    EjectMedium ${WRITER_DEV}

    echo "### Remove the disk and insert another target disk"
    echo "### Press enter when done"
    read USERINPUT
 
    LoadMedium ${WRITER_DEV}
  done  

  PostProcessing "${OUTFILE}" "REMOVE_IMG"
  PostProcessing "${WRITER_DEV}" "EJECT_MEDIUM"

  return ${THISRC}
}

## ---------------------------------------
## CopyMedium
##
## copy the medium (CD/DVD)
##
## usage: CopyMedium srcdevice tempdir [imgfile]
##
## returns: 0 - ok
##          else - error
##
##
CopyMedium() {
  typeset READER_DEV="$1"

  typeset TEMPDIR="$2"
  typeset IMG_FILE="$3"

  typeset THISRC=-1
  typeset OUTFILE=""
  
  typeset USERINPUT=""
  
  LogMsgInvers "Copying the medium ..."

  if [ "${IMG_FILE}"x = ""x ] ; then
    OUTFILE="${TEMPDIR}/MEDIUM.$$.IMG"
  
    LogMsgInvers "Reading the medium to \"${OUTFILE}\"..."
    traceon
    dd if=${READER_DEV} of="${OUTFILE}" bs=2048
    THISRC=$?
    traceoff
  else
    LogMsgInvers "Using the existing image file \"${IMG_FILE}\" "
    OUTFILE="${IMG_FILE}"
    THISRC=0
  fi
   
  if [ ${THISRC} -eq 0 ] ; then

    if [ ${WRITER_DEV} = ${READER_DEV} -a "${IMG_FILE}"x = ""x ] ; then
      EjectMedium ${WRITER_DEV}

      echo "### Remove the source disk and insert the target disk"
      echo "### Press enter when done"
      read USERINPUT

      LoadMedium ${WRITER_DEV}
    fi

    while [ 0 = 0 ] ; do

      PreProcessing "DONT_DIE" ${WRITER_DEV} "BLANK_MEDIUM"
      if [ $? -eq 0 ] ; then
        LogMsg "Writing the medium ..."
        traceon
        ${RECORD_BINARY} dev=${WRITER_DEV} "gracetime=2" -v -data "${OUTFILE}"
        THISRC=$?
        traceoff

        [ ${THISRC} = 0 ] && PostProcessing "DONT_DIE" ${WRITER_DEV} "RELOAD_MEDIUM" "TEST_MEDIUM" "LIST_MEDIUM" "VERIFY_MEDIUM"
      fi

      ProcessAnother "Write another medium?"
      [ $? -eq ${__FALSE} ] && break
      
      EjectMedium ${WRITER_DEV}

      echo "### Remove the disk and insert another target disk"
      echo "### Press enter when done"
      read USERINPUT
 
      LoadMedium ${WRITER_DEV}
    done  

    PostProcessing "${OUTFILE}" "REMOVE_IMG"
    PostProcessing "${WRITER_DEV}" "EJECT_MEDIUM"

  fi

  return ${THISRC}
}

## ---------------------------------------
## CopyMediumOnTheFly
##
## copy the medium (CD/DVD) on the fly
##
## usage: CopyMediumOnTheFly srcdevice 
##
## returns: 0 - ok
##          else - error
##
##
CopyMediumOnTheFly() {
  typeset READER_DEV="$1"

  typeset THISRC=-1
  
  typeset USERINPUT=""

  while [ 1 = 1 ] ; do

    PreProcessing "DONT_DIE" ${WRITER_DEV} "BLANK_MEDIUM"
    if [ $? -eq 0 ] ; then

      LogMsgInvers "Copying the medium on the fly  ..."
        traceon
      dd if=${READER_DEV} bs=2048 | \
         ${RECORD_BINARY} dev=${WRITER_DEV} -data "-waiti" -v "gracetime=2" -
      THISRC=$?
      traceoff

      [ ${THISRC} = 0 ] && PostProcessing "DONT_DIE" ${WRITER_DEV} "RELOAD_MEDIUM" "TEST_MEDIUM" "LIST_MEDIUM" "VERIFY_MEDIUM"
    fi
    
    ProcessAnother "Write another medium?"
    [ $? -eq ${__FALSE} ] && break

    EjectMedium ${WRITER_DEV}

    echo "### Remove the disk and insert another target disk"
    echo "### Press enter when done"
    read USERINPUT
 
    LoadMedium ${WRITER_DEV}

  done  

  PostProcessing "${WRITER_DEV}" "EJECT_MEDIUM"

  return ${THISRC}
}

## ---------------------------------------
## PreProcessing
##
## process the pre actions before doing the main task
##
## usage: PreProcessing {DONT_DIE} [writer_dev|isoimage] action [...]
##
## where: action - see below
##
## returns: 0 - ok
##          else - error
##
PreProcessing() {
  typeset TARGET=""
  typeset ACTION=""    
  typeset THISRC=0

  typeset DONT_DIE=${__FALSE}
  
  if [ "$1"x = "DONT_DIE"x ] ; then
    DONT_DIE=${__TRUE}
    shift
  fi
      
  TARGET=$1
  shift
  
  while [[ $# != 0 ]] ; do

    ACTION=$1
    shift
    
    case ${ACTION} in 

      RELOAD_MEDIUM )
       if [ ${RELOAD_THE_MEDIUM} = ${__TRUE} ] ; then
         ReloadMedium "${TARGET}"
	 THISRC=$?
       fi	 
	 ;;

      EJECT_MEDIUM )
        if [ ${EJECT_THE_MEDIUM} = ${__TRUE} ] ; then
          EjectMedium "${TARGET}"
	  THISRC=$?
        fi
        ;;
      
      BLANK_MEDIUM ) 
        if [ ${BLANK_THE_MEDIUM} = ${__TRUE} ] ; then
          BlankMedium ${TARGET} ${BLANK_PARM}
	  THISRC=$?
          if [ ${THISRC} -ne 0 ] ; then
	    if [ ${DONT_DIE} -eq ${__FALSE} ] ; then
	      die 20 "Error blanking the medium"
            else
	      LogError "Error blanking the medium"
	    fi
	  fi
        fi
        ;;

     * ) die 999 "PreProcessing: Unknown action \"${ACTION}\" found"
         ;;

    esac	
  done

  return ${THISRC}
}

## ---------------------------------------
## PostProcessing
##
## process the post actions after burning (testing, removing, ejecting)
##
## usage: PostProcessing {DONT_DIE} [writer_dev|isoimage] action [...]
##
## where: action - see below
##
## returns: 0 - ok
##          else - error
##
PostProcessing() {
  typeset DONT_DIE=${__FALSE}
  typeset TARGET=""
  typeset ACTION=""    
  typeset THISRC=0
  
  if [ "$1"x = "DONT_DIE"x ] ; then
    DONT_DIE=${__TRUE}
    shift
  fi

  TARGET=$1
  shift

  while [[ $# != 0 ]] ; do

    ACTION=$1
    shift
    
    case ${ACTION} in 

      RELOAD_MEDIUM )
         ReloadMedium "${TARGET}"
	 ;;
	 
      TEST_IMG ) 
        if [ ${TEST_THE_MEDIUM} = ${__TRUE} ] ; then
          TestISOFile "${TARGET}"
	  THISRC=$?
        fi
        ;;

      LIST_IMG )
        if [ ${LIST_THE_MEDIUM} = ${__TRUE} ] ; then
          TestISOFile "${TARGET}" "list"
	  THISRC=$?
        fi
        ;;

      REMOVE_IMG )	
        if [ ${REMOVE_ISO_IMAGE} = ${__TRUE} ] ; then
          RemoveImageFile "${TARGET}"
	  THISRC=$?
        fi 
        ;;

      EJECT_MEDIUM )
        if [ ${EJECT_THE_MEDIUM} = ${__TRUE} ] ; then
          EjectMedium "${TARGET}"
	  THISRC=$?
        fi
        ;;

      VERIFY_MEDIUM )
        if [ ${VERIFY_THE_MEDIUM} = ${__TRUE} ] ; then
          VerifyMedium "${TARGET}"
	  THISRC=$?
        fi
        ;;

      TEST_MEDIUM )
        if [ ${TEST_THE_MEDIUM} = ${__TRUE} ] ; then
          TestMedium "${TARGET}"
	  THISRC=$?
        fi
        ;;
   
      LIST_MEDIUM )
        if [ ${LIST_THE_MEDIUM} = ${__TRUE} ] ; then
          TestMedium "${TARGET}" "list"
	  THISRC=$?
        fi
        ;;

     * ) die 999 "PostProcessing: Unknown action \"${ACTION}\" found"
         ;;

    esac

  done    
  return ${THISRC}
}

## ---------------------------------------
## SetRecordingBinary
##
##  select the binarie to use according to the variable USE_DVD
##
## usage: SetRecordingBinary
##
## returns: -
##
SetRecordingBinary() {
# set the variables that depend on the recording program used
  case ${USE_DVD} in 

    "c" ) 
      RECORD_BINARY="${CDRECORD_BINARY}"
      RECORD_PARM="${RECORD_PARM} ${CDRECORD_PARM} ${CDRECORD_OPTIONS}"

      LogInfo "CDRECORD_OPTIONS are \"${CDRECORD_OPTIONS}\" "
      LogInfo "RECORD_PARM are \"${RECORD_PARM}\" "

      MAX_IMG_SIZE=660000 
      ;;

    "+" ) 
      RECORD_BINARY="${DVDRECORD_BINARY}"
      RECORD_PARM="${RECORD_PARM} ${DVDRECORD_PARM} ${DVDRECORD_OPTIONS} -driver=mmc_dvdplusrw -sao"

      LogInfo "DVDRECORD_OPTIONS are \"${DVDRECORD_OPTIONS}\" "
      LogInfo "RECORD_PARM are \"${RECORD_PARM}\" "

      MAX_IMG_SIZE=45000000
      ;;

    "-" ) 
      RECORD_BINARY="${DVDRECORD_BINARY}"
      RECORD_PARM="${RECORD_PARM} ${DVDRECORD_PARM} ${DVDRECORD_OPTIONS} -sao"

      LogInfo "DVDRECORD_OPTIONS are \"${DVDRECORD_OPTIONS}\" "
      LogInfo "RECORD_PARM are \"${RECORD_PARM}\" "

      MAX_IMG_SIZE=45000000
      ;;
     
  esac

  LogMsg "Using the recording binary \"${RECORD_BINARY}\" ..."

}

## ---------------------------------------
## CheckDirectory
##
## check the source directory
##
## usage: CheckDirectory resultvar sourcedir 
##
## returns: ${__TRUE} - ok, resultvar contains the fully qualified directory name
##          ${__FALSE) - error, sourcedir is NOT a directory
##
##
CheckDirectory() {
  typeset RESULTVAR=$1
  typeset SOURCEDIR="$2"

  typeset DIRNAME=""

  typeset THISRC=${__FALSE}

  if [ "${SOURCEDIR}"x != ""x ] ; then
    if [  -d "${SOURCEDIR}" ] ; then
      DIRNAME="${SOURCEDIR}"
      THISRC=${__TRUE}
    else 
      if [ -d "${IMG_SOURCE_BASE_DIR}/${SOURCEDIR}" ] ; then
        DIRNAME="${IMG_SOURCE_BASE_DIR}/${SOURCEDIR}"
        THISRC=${__TRUE}
      fi
    fi
  fi
  eval ${RESULTVAR}=\"${DIRNAME}\"

  return ${THISRC}      
}

## ---------------------------------------
## CheckOutputfile
##
## check the output file parameter
##
## usage: CheckOutputfile resultvar filename 
##
## returns: ${__TRUE} - ok, resultvar contains the fully qualified file name
##          ${__FALSE) - error, outputfile can not be created
##
##
CheckOutputfile() {
  typeset RESULTVAR=$1

  typeset THISRC=${__FALSE}

  typeset FILENAME="${2##*/}"
  typeset DIRNAME="${2%/*}"
   
  if [ "${DIRNAME}"x = "${FILENAME}"x ] ; then
    FILENAME="${IMG_TARGET_DIR}/${FILENAME}"
  elif [ -d "${DIRNAME}" ] ; then
    FILENAME="${DIRNAME}/${FILENAME}"
  fi  

  if [ ! -f "${FILENAME}" ] ; then
    touch "${FILENAME}"
    [ $? -eq 0 ] && THISRC=${__TRUE}
    rm "${FILENAME}"
  else      
    THISRC=${__TRUE}
  fi
   
  eval ${RESULTVAR}=\"${FILENAME}\"

  return ${THISRC}      
}

## ---------------------------------------
## CheckInputfile
##
## check the input file parameter
##
## usage: CheckInputfile resultvar filename
##
## returns: ${__TRUE} - ok, resultvar contains the fully qualified file name
##          ${__FALSE) - error, inputfile does not exist
##
##
CheckInputfile() {

  typeset RESULTVAR=$1

  typeset THISRC=${__FALSE}
  
  typeset FILENAME="$2"
  
  if [ "${FILENAME}"x != ""x ] ; then
    if [ -f "${FILENAME}" ] ; then
      [ -r "${FILENAME}" ] && THISRC=${__TRUE}
    elif [ -f "${IMG_TARGET_DIR}/${FILENAME}" ] ; then
      FILENAME="${IMG_TARGET_DIR}/${FILENAME}"
      [ -r "${FILENAME}" ] && THISRC=${__TRUE}
    fi
  fi
  eval ${RESULTVAR}=\"${FILENAME}\"

  return ${THISRC}      
}

## ---------------------------------------
## MyCleanup
##
## program specific cleanup at program end
##
## usage: called by the runtime system
##
## returns: -
##
MyCleanup()  {
  if [ "${TEMP_MOUNT_POINT}"x != ""x ] ; then
    mount | grep "^${TEMP_MOUNT_POINT} " >/dev/null
    [ $? -eq 0 ] && umount ${TEMP_MOUNT_POINT} 
    [ -d ${TEMP_MOUNT_POINT} ] && rmdir ${TEMP_MOUNT_POINT}
  fi    

  if [ "${TEMP_LOFI_DEVICE}"x != ""x ] ; then
    lofiadm | grep ${TEMP_LOFI_DEVICE} >/dev/null
    if [ $? -eq 0 ] ; then
      LogInfo "Calling \"lofiadm -d ${TEMP_LOFI_DEVICE}\" "
      lofiadm -d ${TEMP_LOFI_DEVICE}
      TEMP_LOFI_DEVICE=""
    fi      
  fi

# restart the volume management if necessary  
  StartStopVolumeMgmt "start"
}

# -----------------------------------------------------------------------------
# main:
#


# use a temporary log file until we know the real log file
  __TEMPFILE_CREATED=${__FALSE}
  __MAIN_LOGFILE=${__LOGFILE}
  
  __LOGFILE="${__LOGFILE}.$$.TEMP"
  echo >${__LOGFILE}

# temporary mount point for mounting the CD/DVDROM (for testing (-T) only)
  TEMP_MOUNT_POINT="/tmp/${__SCRIPTNAME}.$$"

# temporary lofi device to mount an ISO image
  TEMP_LOFI_DEVICE=""
 
# umount the CDROM/DVDROM an program end (-T only)
  __EXITROUTINES="${__EXITROUTINES} MyCleanup"

# init the local volume management
  StartStopVolumeMgmt "init"

# CONFIG_PARAMETER contains the variables, that are read from the config file
#
CONFIG_PARAMETER='

# default parameter for mkisofs, cdrecord, dvdrecord, and readcd
#
# Note: Use a config file to change these values
#

# default options for mkisofs
  DEFAULT_MKISOFS_PARM="-D -hide-rr-moved -hide-joliet-trans-tbl -v -v -J -R -l  -allow-leading-dots -d -N -U  -no-iso-translate -relaxed-filenames"
# 
  
# default options for cdrecord for burning CDs  
  DEFAULT_CDRECORD_PARM="driveropts=burnfree gracetime=2  "

# default options for cdrecord for burning DVDs  
  DEFAULT_DVDRECORD_PARM="driveropts=burnfree gracetime=2  "

# default blank mode for CDs and DVDs
  DEFAULT_BLANK_PARM="fast"

# default cdrecord parameter to eject a CD/DVD
  DEFAULT_EJECT_PARM="-eject gracetime=2"

# default cdrecord parameter to load a CD/DVD
  DEFAULT_LOAD_PARM="-load gracetime=2"

# default parameter for readcd to read CDs and/or DVDs
  DEFAULT_READCD_PARM=""

# default parameter for cdda2wav
  DEFAULT_CDDA2WAV_PARM="-vall -B -Owav"

# use the cddb (y) or not (no) for reading/copying audio cds
  DEFAULT_USE_CDDB="y"
  
# binaries used

# binary for burning DVDs
#  DVDRECORD_BINARY="/usr/bin/cdrecord-prodvd"
  DVDRECORD_BINARY="/opt/tools/bin/cdrecord-prodvd"
  
# binary for burning CDs
  CDRECORD_BINARY="/opt/sfw/bin/cdrecord"
#  CDRECORD_BINARY="/usr/bin/cdrecord"
    
# binary to create an ISO image
  MKISOFS_BINARY="/opt/sfw/bin/mkisofs"
#  MKISOFS_BINARY="/usr/bin/mkisofs"
  
# binary to read a data CD 
  READCD_BINARY="/opt/sfw/bin/readcd"
#  READCD_BINARY="/usr/bin/readcd"
  
# binary to read an audio CD
  CDDA2WAV_BINARY="/opt/sfw/bin/cdda2wav"
#  CDDA2WAV_BINARY="/usr/bin/cdda2wav"
  
# option file for dvdrecord/cdrecord with the license key
  DVD_OPTION_FILE="/opt/tools/scripts/dvdoptions"

# directories  

# default base directory for source directories
  IMG_SOURCE_BASE_DIR="/var/cdimg/dir"

# default base directory for ISO images and audio file directories
  IMG_TARGET_DIR="/var/cdimg/iso"

# default file for logfiles from mkisofs
  LOG_DIR="/var/cdimg/log"

# time in seconds to wait until vold finish after stopping
  VOLD_WAIT_TIME=5

# SCSI IDs for writer and reader devices
  __WRITER_SCSI_ID=1
  __READER_SCSI_ID=1

# cdrom write device parameter for cdrecord/dvdrecord
    WRITER_DEV="${__WRITER_SCSI_ID},0,0"

# cdrom reader device parameter for cdrecord/dvdrecord
    READER_DEV="${__READER_SCSI_ID},0,0"

# raw devices for the writer
   WRITER_RAW_DEVICE="/dev/rdsk/c${__WRITER_SCSI_ID}t0d0s0"

# raw devices for the reader
   READER_RAW_DEVICE="/dev/rdsk/c${__READER_SCSI_ID}t0d0s0"

# device for mounting the CD/DVD in the burner
   WRITER_DEVICE="/dev/dsk/c${__WRITER_SCSI_ID}t0d0s0"

# device for mounting the CD/DVD in the reader
   READER_DEVICE="/dev/dsk/c${__READER_SCSI_ID}t0d0s0"

# default reader device
  DEFAULT_SOURCE_DEVICE=${READER_DEVICE}
  
# default write device
  DEFAULT_TARGET_DEVICE=${WRITER_DEVICE}

# default write speed
  DEFAULT_WRITER_SPEED="16"

# default reader speed
  DEFAULT_READER_SPEED="48" 
    
# default action
  DEFAULT_ACTION="writecdrom"

# defaults for the modifier
  DEFAULT_WRITE_ON_THE_FLY=${__FALSE}
  DEFAULT_BLANK_THE_MEDIUM=${__FALSE}
  DEFAULT_TEST_THE_MEDIUM=${__FALSE}
  DEFAULT_VERIFY_THE_MEDIUM=${__FALSE}
  DEFAULT_LIST_THE_MEDIUM=${__FALSE}
  DEFAULT_EJECT_THE_MEDIUM=${__TRUE}
  DEFAULT_RELOAD_THE_MEDIUM=${__FALSE}
  DEFAULT_DUMMY_MODE=${__FALSE}
  DEFAULT_CHECK_DIR_SIZE=${__TRUE}
  DEFAULT_REMOVE_ISO_IMAGE=${__FALSE}
  DEFAULT_WAIT_FOR_USER=${__FALSE}
  DEFAULT_PROCESS_MANY_DISKS=${__FALSE}
  
# c = CDROM/CDRW, - = DVD/DVD-RW
  DEFAULT_USE_DVD="c" 
'
# DO NOT DELETE THE PREVIOUS LINE!!!!

# max image size for the current medium
  typeset -i MAX_IMG_SIZE=0

# init defaults
  eval "${CONFIG_PARAMETER}"
  
# end of config parameter

       
# possible symbolic links to this script with different default values    
  POSSIBLE_SCRIPT_NAMES=" 
easycd easydvd   
clonecd clonedvd
copycd copycdrom
copy_dir_to_iso_img copy_cd_to_iso_img copy_dvd_to_iso_img 
copyaudiocd readaudiocd writeaudiocd 
blankcd blankdvd ejectcd ejectdvd loadcd loaddvd 
testcd testdvd testiso 
verifycd 
cdrecord dvdrecord dvdrecord- 
                        "  


# set the default values depending on the name of this script 
  SYMBOLIC_LINK_USED=${__TRUE}
  
  case ${__SCRIPTNAME} in 
 
    "easycd" | "easycd.sh" ) 
		 LogMsg "Default action is create an ISO image and burn it to CD"
                 DEFAULT_USE_DVD="c" 
		 DEFAULT_ACTION="writecdrom"
                 ;;

    "easydvd" ) 
		 LogMsg "Default action is create an ISO image and burn it to DVD"
                 DEFAULT_USE_DVD="-"
		 DEFAULT_ACTION="writedvd"
		 ;;

    "clonecd" )   
		 LogMsg "Default action is clone a data CDROM "
                 DEFAULT_USE_DVD="c"
		 DEFAULT_REMOVE_ISO_IMAGE=${__TRUE}
		 DEFAULT_ACTION="clonecdrom"
		 ;;

    "clonedvd" )   
		 LogMsg "Default action is clone a data DVD "
                 DEFAULT_USE_DVD="-"
		 DEFAULT_REMOVE_ISO_IMAGE=${__TRUE}
		 DEFAULT_ACTION="clonedvd"	 
		 ;;

    "copycd" )   
		 LogMsg "Default action is copy a data CDROM "
                 DEFAULT_USE_DVD="c"
		 DEFAULT_REMOVE_ISO_IMAGE=${__TRUE}
		 DEFAULT_ACTION="copycdrom"
		 ;;

    "copydvd" )   
		 LogMsg "Default action is copy a data DVD "
                 DEFAULT_USE_DVD="-"
		 DEFAULT_REMOVE_ISO_IMAGE=${__TRUE}
		 DEFAULT_ACTION="copydvd"	 
		 ;;

    "copy_dir_to_iso_img" )
		 LogMsg "Default action is create an ISO image from a directory"
		 DEFAULT_ACTION="createISOimg"	 
		 ;;

    "copy_cd_to_iso_img" ) 
		 LogMsg "Default action is copy a CDROM to an ISO image "
                 DEFAULT_USE_DVD="c"
		 DEFAULT_ACTION="readcd"	 
		 ;;

    "copy_dvd_to_iso_img" ) 
		 LogMsg "Default action is copy a DVD to an ISO image "
                 DEFAULT_USE_DVD="-"
		 DEFAULT_ACTION="readdvd"	 
		 ;;

    "blankcd" )  
		 LogMsg "Default action is only blank the CDROM"
                 DEFAULT_USE_DVD="c"
		 DEFAULT_ACTION="blankcd"
                 ;;
    
    "blankdvd" ) 
		 LogMsg "Default action is only blank the DVD"
                 DEFAULT_USE_DVD="-"
		 DEFAULT_ACTION="blankdvd"
                 ;;

    "ejectcd" )  
		 LogMsg "Default action is only eject the CDROM"
                 DEFAULT_USE_DVD="c"
		 DEFAULT_ACTION="ejectcd"
                 ;;
    
    "ejectdvd" ) 
		 LogMsg "Default action is only eject the DVD"
                 DEFAULT_USE_DVD="-"
		 DEFAULT_ACTION="ejectdvd"
                 ;;

    "loadcd" )  
		 LogMsg "Default action is only eject the CDROM"
                 DEFAULT_USE_DVD="c"
		 DEFAULT_ACTION="loadcd"
                 ;;
    
    "loaddvd" ) 
		 LogMsg "Default action is only eject the DVD"
                 DEFAULT_USE_DVD="-"
		 DEFAULT_ACTION="loaddvd"
                 ;;

    "testcd"  )  
		 LogMsg "Default action is only test the CD"
                 DEFAULT_USE_DVD="c"
		 DEFAULT_ACTION="testcd"
                 ;;

    "testdvd"  )  
		 LogMsg "Default action is only test the DVD"
                 DEFAULT_USE_DVD="-"
		 DEFAULT_ACTION="testdvd"
                 ;;

    "verifycd"  )  
		 LogMsg "Default action is only verify the CD"
                 DEFAULT_USE_DVD="c"
		 DEFAULT_ACTION="verifycd"
                 ;;

    "testiso" )
                 LogMsg "Default action is test an ISO image"
		 DEFAULT_ACTION="testiso"
		 ;;
		 
    "cdrecord" ) 
		 LogMsg "Default action is burn an ISO image on CD"
                 DEFAULT_USE_DVD="c" 
		 DEFAULT_ACTION="burnCD"
		 ;;

    "dvdrecord-" | "dvdrecord" ) 
		 LogMsg "Default action is burn an ISO image on DVD"
                 DEFAULT_USE_DVD="-" 
		 DEFAULT_ACTION="burnCD"
		 ;;

    "copyaudiocd" )
		 LogMsg "Default action is burn an ISO image on DVD"
                 DEFAULT_USE_DVD="c"
		 DEFAULT_ACTION="copyaudiocd"
		 ;;

    "readaudiocd" )
		 LogMsg "Default action is burn an ISO image on DVD"
                 DEFAULT_USE_DVD="c"
		 DEFAULT_ACTION="readaudiocd"
		 ;;

    "writeaudiocd" )
		 LogMsg "Default action is burn an ISO image on DVD"
                 DEFAULT_USE_DVD="c"
		 DEFAULT_ACTION="writeaudiocd"
		 ;;

             * ) LogWarning "I don't know who I am \"${__SCRIPTNAME}\":  using the defaults for easycd.sh" 
		 LogMsg "Default action is create an ISO image and burn it to CD"
                 DEFAULT_USE_DVD="c" 
		 DEFAULT_ACTION="writecdrom"

                 SYMBOLIC_LINK_USED=${__FALSE}
	         ;;

  esac

  case ${DEFAULT_ACTION} in

   "loadcdrom" | "loadcd" | "loaddvd" )
     DEFAULT_EJECT_THE_MEDIUM=${__FALSE}
     ;;

   "readcdrom" | "readcd" | "readdvd" )
     DEFAULT_RELOAD_THE_MEDIUM=${__TRUE}
     ;;
     
    * ) : 
     ;;     

  esac

# read the config file if it exists
# The config file may overwrite the default values initialized above
#

# read the base config file
  ReadConfigFile ${__BASE_CONFIG_FILE}

# read the "custom" config file
  [ "${__BASE_CONFIG_FILE}" != "${__CONFIG_FILE}" ] && ReadConfigFile   

# variables

# default read device
  SOURCE_DEVICE=${DEFAULT_SOURCE_DEVICE}
  
# default write device
  TARGET_DEVICE=${DEFAULT_TARGET_DEVICE}

# default write speed
  WRITER_SPEED=${DEFAULT_WRITER_SPEED}

# default reader speed
  READER_SPEED=${DEFAULT_READER_SPEED}

# default action
  ACTION=${DEFAULT_ACTION}

# defaults for the modifier
  WRITE_ON_THE_FLY=${DEFAULT_WRITE_ON_THE_FLY}
  BLANK_THE_MEDIUM=${DEFAULT_BLANK_THE_MEDIUM}
  TEST_THE_MEDIUM=${DEFAULT_TEST_THE_MEDIUM}
  VERIFY_THE_MEDIUM=${DEFAULT_VERIFY_THE_MEDIUM}
  LIST_THE_MEDIUM=${DEFAULT_LIST_THE_MEDIUM}
  EJECT_THE_MEDIUM=${DEFAULT_EJECT_THE_MEDIUM}
  RELOAD_THE_MEDIUM=${DEFAULT_RELOAD_THE_MEDIUM}
  DUMMY_MODE=${DEFAULT_DUMMY_MODE}
  CHECK_DIR_SIZE=${DEFAULT_CHECK_DIR_SIZE}
  REMOVE_ISO_IMAGE=${DEFAULT_REMOVE_ISO_IMAGE}
  WAIT_FOR_USER=${DEFAULT_WAIT_FOR_USER}
  PROCESS_MANY_DISKS=${DEFAULT_PROCESS_MANY_DISKS}

  USE_DVD="${DEFAULT_USE_DVD}" 

# default parameter for cdda2wav, mkisofs, cdrecord, dvdrecord, and readcd

  CDDA2WAV_PARM="${DEFAULT_CDDA2WAV_PARM}"
  MKISOFS_PARM="${DEFAULT_MKISOFS_PARM}"
  CDRECORD_PARM="${DEFAULT_CDRECORD_PARM}"
  DVDRECORD_PARM="${DEFAULT_DVDRECORD_PARM}"
  BLANK_PARM="${DEFAULT_BLANK_PARM}"
  EJECT_PARM="${DEFAULT_EJECT_PARM}"
  LOAD_PARM="${DEFAULT_LOAD_PARM}"
  READCD_PARM="${DEFAULT_READCD_PARM}"
     

# install trap handler
  trap EXIT_SIGNAL_HANDLER exit 

  trap HUP_SIGNAL_HANDLER 1
  trap BREAK_SIGNAL_HANDLER 2
  trap QUIT_SIGNAL_HANDLER 3

  trap TERM_SIGNAL_HANDLER 15
  
# add additional exit routines
# __EXITROUTINES="${__EXITROUTINES} RebootIfNecessary"  

  LogMsg "${__SCRIPTNAME} started on $( date ) "
  
  THIS_PARAMETER=$*
  set -- $( getopt ynvqhHDl:a:O:x:fbtVLmedNRs:rw $* )
  if [ $? != 0 ] ; then
    LogError "Error evaluating the parameter \"${THIS_PARAMETER}\" "
    ShowShortUsage
    die 2
  fi

  PROCESSED_PARAMETER=$*
  [ "${PROCESSED_PARAMETER}"x = "--"x -a ${SYMBOLIC_LINK_USED} != ${__TRUE} ] && set -- -h

  
  
  for i in $* ; do

    case $i in 

      "-x" ) ACTION=$2; shift ; shift ;;

      "-f" ) SwitchOption WRITE_ON_THE_FLY ; shift ;;

      "-b" ) SwitchOption BLANK_THE_MEDIUM ; shift ;;

      "-t" ) SwitchOption TEST_THE_MEDIUM ; shift ;;

      "-V" ) SwitchOption VERIFY_THE_MEDIUM ; shift ;;

      "-L" ) SwitchOption LIST_THE_MEDIUM ; shift ;;
      
      "-e" ) SwitchOption EJECT_THE_MEDIUM ; shift ;;

      "-R" ) SwitchOption RELOAD_THE_MEDIUM ; shift ;;
      
      "-d" ) SwitchOption DUMMY_MODE ; shift ;;

      "-N" ) SwitchOption CHECK_DIR_SIZE ; shift ;;

      "-m" ) SwitchOption PROCESS_MANY_DISKS ; shift ;;

      "-s" ) 
             TESTVAR=$2
             WRITER_SPEED=${TESTVAR%,*}
	     [ "${WRITER_SPEED}" != "${TESTVAR}" ] && READER_SPEED=${TESTVAR#*,}
             shift ; shift  ;;

      "-r" ) SwitchOption  REMOVE_ISO_IMAGE ; shift ;;

      "-w" ) SwitchOption  WAIT_FOR_USER ; shift ;;

      "-D" )  __DEBUG_MODE=${__TRUE} ; __USE_COLORS=${__TRUE} ; shift ;;

      "-a" ) __USE_COLORS=$2; shift ; shift ;;

      "-O" ) __OVERWRITE_MODE=$2 ; shift ; shift ;;
           
      "-l" ) NEW_LOGFILE=$2; shift ; shift ;;
     
      "-h" ) if [ ${__VERBOSE_MODE} = ${__TRUE} ] ; then
               ShowUsage 
	       __VERBOSE_MODE=${__FALSE}
	     else
	       ShowShortUsage 
	       LogMsg "Use \"-v -h\" for a long help text"
	     fi
	     shift ; die 1 ;;

      "-u" ) ShowUsage ; shift ; die 1 ;;

      "-H" ) grep "^##" $0 | cut -c3-80 1>&2 ; shift ; die 0 ;;
                  
      "-v" ) __VERBOSE_MODE=${__TRUE} ; (( __VERBOSE_LEVEL=__VERBOSE_LEVEL+1 )) ; shift ;;

      "-q" ) __QUIET_MODE=${__TRUE} ; shift ;;

      "-y" ) __USER_RESPONSE_IS="y"; shift ;;

      "-n" ) __USER_RESPONSE_IS="n"; shift ;;
     
      "--" ) [ $# -ne 0 ] && shift; break ;;
              
    esac
  done

# check the parameter syntax
  INVALID_PARAMETER_FOUND=${__FALSE} 

  SOURCE_PARAMETER="$*"

  if [  "${WRITER_SPEED}"x != ""x  ] ; then
    isNumber ${WRITER_SPEED}
    if [ $? != ${__TRUE} ] ; then
      LogError "Invalid value for the parameter -s found: \"${WRITER_SPEED}\" "
      INVALID_PARAMETER_FOUND=${__TRUE}
    fi
  fi

  if [ "${READER_SPEED}"x != ""x  ] ; then
    isNumber ${READER_SPEED}
    if [ $? != ${__TRUE} ] ; then
      LogError "Invalid value for the parameter -s found: \"${READER_SPEED}\" "
      INVALID_PARAMETER_FOUND=${__TRUE}
    fi
  fi
  
  CheckYNParameter ${__USE_COLORS}
  THISRC=$?
  if [ ${THISRC} = 255 ] ; then
    LogError "Invalid value for the parameter -a found: \"${__USE_COLORS}\" "
    INVALID_PARAMETER_FOUND=${__TRUE}
  else
    __USE_COLORS=${THISRC}
  fi

  CheckYNParameter ${__OVERWRITE_MODE}
  THISRC=$?
  if [ ${THISRC} = 255 ] ; then
    LogError "Invalid value for the parameter -O found: \"${__OVERWRITE_MODE}\" "
    INVALID_PARAMETER_FOUND=${__TRUE}
  else
    __OVERWRITE_MODE=${THISRC}
  fi

  if [ "${NEW_LOGFILE}"x != ""x ] ; then
    substr "${NEW_LOGFILE}" 1 1 TEMPVAR
    if [ "${TEMPVAR}" = "-" ] ; then
      LogError "The logfile can not start with a hyphen \"-\" "
      INVALID_PARAMETER_FOUND=${__TRUE}
    fi
  fi
      
  if [ ${INVALID_PARAMETER_FOUND} -ne ${__FALSE} ] ; then
    LogError "One or more invalid parameter(s) found"
    ShowShortUsage
    die 2
  fi
  
  LogInfo "Parameter after the options are: " "\"$*\" "
  
# copy the temporary log file to the real log file

  LogInfo "Script template used is \"${__SCRIPT_TEMPLATE_VERSION}\" ."

  if [ "${NEW_LOGFILE}"x = "nul"x ] ; then
    LogMsg "Running without a log file"
    __MAIN_LOGFILE=""
# delete the temporary logfile   
    rm ${__LOGFILE} 2>/dev/null
    __LOGFILE=""
  else
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
  fi

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
  The lock file was created by the process with the PID ${__RUNNING_PID}.
  In the first case wait until the other instance ends; 
  in the second case delete the lock file 
  
      ${__LOCKFILE} 

  manually and restart the script.

EOF
   __CURPROC=$( ps -ef | grep -v grep | grep " ${__RUNNING_PID} " )
      if [ $? -eq 0 ] ; then
        LogMsg "Note: \"ps -ef | grep ${__RUNNING_PID}\" gives:"
	LogMsg ${__CURPROC}
      fi

      die 499
    fi

# remove the lock file at program end
    __EXITROUTINES="${__EXITROUTINES} RemoveLockFile"    
  fi

# __ABSOLUTE_SCRIPTDIR real absolute directory (no link)
  GetProgramDirectory $0 __ABSOLUTE_SCRIPTDIR
  
# create temporary files
  CreateTemporaryFiles

# remove temporary files at program end
  __EXITROUTINES="${__EXITROUTINES} DeleteTemporaryFiles"  

  if [ "${__DEBUG_MODE}" = ${__TRUE} ] ; then
    trap "__LAST_RC=\$?; __LAST_BG_RC=\$!; __LINENO=\$LINENO; DebugHandler"  DEBUG
:
    echo "INFO: Starting single step mode (works only for the main routine!)"
  fi

# read the environment variables necessary for cdrecord/dvdrecord

  [ ! -f ${DVD_OPTION_FILE} ] && die 10 "Can not find the file \"${DVD_OPTION_FILE}\" "
  LogMsg "Reading \"${DVD_OPTION_FILE}\" ..." 
   . "${DVD_OPTION_FILE}"
  
# set the general parameter for cdrecord/dvdrecord
  if [ "${DUMMY_MODE}" = "${__TRUE}" ] ; then
    [ "${USE_DVD}" = "+" ] && die 15 "Dummy mode is not supported for DVD+"

    LogMsg "Dummy mode activated - only simulating"
    RECORD_PARM="${RECORD_PARM} -dummy "
  fi
    
  [ "${WRITER_SPEED}"x != ""x ] && RECORD_PARM="${RECORD_PARM} speed=${WRITER_SPEED}"
  LogInfo "RECORD_PARM are \"${RECORD_PARM}\" "

  MKISOFS_PARM="${MKISOFS_PARM} ${MKISOFS_OPTIONS} "

  LogInfo "MKISOFS_OPTIONS are \"${MKISOFS_OPTIONS}\" "
  LogInfo "MKISOFS_PARM are \"${MKISOFS_PARM}\" "
  
  CDDA2WAV_PARM="${CDDA2WAV_PARM} ${CDDA2WAV_OPTIONS}"

  LogInfo "CDDA2WAV_OPTIONS are \"${CDDA2WAV_OPTIONS}\" "
  LogInfo "CDDA2WAV_PARM are \"${CDDA2WAV_PARM}\" "

  READCD_PARM="${READCD_PARM} ${READCD_OPTIONS}"
  [ "${READER_SPEED}"x != ""x ] && READCD_PARM="${READCD_PARM} speed=${READER_SPEED}"

  LogInfo "READCD_OPTIONS are \"${READCD_OPTIONS}\" "
  LogInfo "READCD_PARM are \"${READCD_PARM}\" "

  LogMsg "Action selected is \"${ACTION}\" "

# set the cdwriter program depending on the action

  [[ "${ACTION}" = *dvd* ]] && USE_DVD='-' || USE_DVD='c'
  SetRecordingBinary

  MKISOFS_ADD_PARMS=""
  
  case ${ACTION} in

# ---------------------------------------------------------------
    "createconfig" )                # create the config file

      echo ${SOURCE_PARAMETER} | read THIS_CONFIG THIS_DUMMY
      [ "${THIS_DUMMY}"x != ""x ] && die 19 "Too many parameter found!"

      InstallScript ${THIS_CONFIG}
      __THISRC=$?
      ;;

# ---------------------------------------------------------------
    "install" | "init" )            # create the symbolic links

      echo ${SOURCE_PARAMETER} | read THIS_CONFIG THIS_DUMMY
      [ "${THIS_DUMMY}"x != ""x ] && die 19 "Too many parameter found!"

      InstallScript ${THIS_CONFIG}
      __THISRC=$?
      ;;

# ---------------------------------------------------------------
    "uninstall" | "remove" )            # remove the symbolic links

      UnInstallScript
      __THISRC=$?
      ;;

# ---------------------------------------------------------------
    "blank" | "blankcdrom" | "blankcd" | "blankdvd"  )      # blankcdrom/blankdvd [blanktype]
      PreChecks cdrecord || die 17 "Something is missing"

      echo ${SOURCE_PARAMETER} | read THIS_BLANK_PARM THIS_DUMMY
      [ "${THIS_DUMMY}"x != ""x ] && die 19 "Too many parameter found!"

      [ "${THIS_BLANK_PARM}"x = ""x ] && THIS_BLANK_PARM=${BLANK_PARM}

      while [ 0 = 0 ] ;  do
        BlankMedium ${WRITER_DEV} ${THIS_BLANK_PARM}
        __THISRC=$?
        [ ${__THISRC} -ne 0 ] && LogError "Error blanking the medium"

        ProcessAnother "Blank another medium?"
        [ $? -eq ${__FALSE} ] && break

        EjectMedium ${WRITER_DEV}

        echo "### Remove the disk and insert another target disk"
        echo "### Press enter when done"
        read USERINPUT

        LoadMedium ${WRITER_DEV}

      done
     
      PostProcessing "${WRITER_DEV}" "EJECT_MEDIUM"      
      ;;

# ---------------------------------------------------------------
    "eject" | "ejectcdrom" | "ejectcd" | "ejectdvd" )      # ejectcdrom/ejectDVD device
      PreChecks cdrecord || die 17 "Something is missing"

      echo ${SOURCE_PARAMETER} | read THIS_DEVICE THIS_DUMMY
      [ "${THIS_DUMMY}"x != ""x ] && die 19 "Too many parameter found!"

      CheckSourceDevice "${THIS_DEVICE}" ${WRITER_DEV} 
      [ $? -ne 0 ] && die 18 "Invalid device entered: \"${THIS_DEVICE}\" "
# The variable ${THIS_DEV} contains device name for CDRECORD 
# The variable ${MOUNT_DEV} contains the device to mount
# The variable ${RAW_DEV} contains the raw device 

      EjectMedium ${THIS_DEV}

      __THISRC=$?

      ;;

# ---------------------------------------------------------------
    "load" | "loadcdrom" | "loadcd" | "loaddvd" )      # loadcdrom/loaddvd device
      PreChecks cdrecord || die 17 "Something is missing"

      echo ${SOURCE_PARAMETER} | read THIS_DEVICE THIS_DUMMY
      [ "${THIS_DUMMY}"x != ""x ] && die 19 "Too many parameter found!"

      CheckSourceDevice "${THIS_DEVICE}" ${WRITER_DEV} 
      [ $? -ne 0 ] && die 18 "Invalid device entered: \"${THIS_DEVICE}\" "
# The variable ${THIS_DEV} contains device name for CDRECORD 
# The variable ${MOUNT_DEV} contains the device to mount
# The variable ${RAW_DEV} contains the raw device 

      if [ ${RELOAD_THE_MEDIUM} = ${__TRUE} ] ; then
        EjectMedium "${THIS_DEV}"
      fi
      
      LoadMedium "${THIS_DEV}"
      __THISRC=$?

      [ ${__THISRC} = 0 ] && PostProcessing "${THIS_DEV}" "TEST_MEDIUM" "LIST_MEDIUM" "VERIFY_MEDIUM" 
      PostProcessing "${THIS_DEV}" "EJECT_MEDIUM"
      ;;

   
# ---------------------------------------------------------------
    "writecdrom" | "writecd" | "writedvd" )	# writecdrom/writedvd sourcedir [volid]
      PreChecks mkisofs cdrecord || die 17 "Something is missing"

      echo ${SOURCE_PARAMETER} | read THIS_SOURCEDIR THIS_VOLID MKISOFS_ADD_PARMS
#      [ "${THIS_DUMMY}"x != ""x ] && die 19 "Too many parameter found!"

      CheckDirectory IMG_SOURCE_DIR ${THIS_SOURCEDIR}
      [ $? -ne ${__TRUE} ] && die 14 "Source directory \"${THIS_SOURCEDIR}\" is not valid"

      [ "${THIS_VOLID}"x = ""x ] && VOLID="$( basename ${IMG_SOURCE_DIR} )" || VOLID=${THIS_VOLID}

      LogMsg "Burning a medium from the directory "
      LogMsg "    ${IMG_SOURCE_DIR}"
      LogMsg "The volume ID for the image is \"${VOLID}\"."

      LogMsg "Calculating the size of the source directory ..."
      CalculateDirSize ${IMG_SOURCE_DIR} 
# DIR_SIZE now contains the directory size in KByte
# TREE_SIZE now contains the TREESIZE for CDRECORD

      if [ ${CHECK_DIR_SIZE} = ${__TRUE} ] ; then
        LogMsg "The source directory uses about ${DIR_SIZE} KByte"
	[ ${DIR_SIZE} -gt ${MAX_IMG_SIZE} ] && die 90 "The directory \"${IMG_SOURCE_DIR}\" (about ${DIR_SIZE} KByte) does NOT fit on the medium"
      fi

      if [ ${WRITE_ON_THE_FLY} != ${__TRUE} ] ; then

        ISO_IMG_FILE="${IMG_TARGET_DIR}/$( basename ${IMG_SOURCE_DIR} ).iso"
        LogMsg "Using the temporay ISO file \"${ISO_IMG_FILE}\" ..."
        InitOutputFile ${ISO_IMG_FILE} || die 16 "The file \"${ISO_IMG_FILE}\" already exist (use -O y to overwrite)"
	
        if [ ${CHECK_DIR_SIZE} = ${__TRUE} ] ; then
	  LogMsg "Checking the free space in the target directory ..."
          CalculateFreespace ${IMG_TARGET_DIR}
    	  LogMsg "The freespace in the target directory \"${IMG_TARGET_DIR}\" is about ${FREE_SPACE} KByte"
          [ ${DIR_SIZE} -gt ${FREE_SPACE} ] && die 60 "Not enough free space to create the temporary ISO image \"${ISO_IMG_FILE}\""
	fi

        LogMsg "Creating an temporary ISO image in the file "
        LogMsg "    ${ISO_IMG_FILE}"
        LogMsg "from the directory " 
        LogMsg "    ${IMG_SOURCE_DIR}"
        LogMsg "The volume ID for the image is \"${VOLID}\"."

        DirToISOImage "${IMG_SOURCE_DIR}" "${ISO_IMG_FILE}" "${VOLID}"
        __THISRC=$?
        [ ${__THISRC} -ne 0 ] && die 80 "Error creating the temporary ISO image \"${ISO_IMG_FILE}\" from \"${IMG_SOURCE_DIR}\""
      fi

      PreProcessing ${WRITER_DEV} "BLANK_MEDIUM"
      
      if [ ${WRITE_ON_THE_FLY} = ${__TRUE} ] ; then
        LogMsg "Burning the medium on the fly ..."

        if [ "${ACTION}" = "writedvd" ] ; then
	  CopyDataToDVDOnTheFly ${IMG_SOURCE_DIR} ${VOLID} ${TREE_SIZE}
           __THISRC=$?
	else
	  CopyDataToCDOnTheFly ${IMG_SOURCE_DIR} ${VOLID}
	  __THISRC=$?
	fi
      else
        BurnISOImage "${ISO_IMG_FILE}"
        __THISRC=$?
      fi
      [ ${__THISRC} -ne 0 ] && die 25 "Error burning the medium"

      PostProcessing "${WRITER_DEV}" "RELOAD_MEDIUM" "TEST_MEDIUM" "LIST_MEDIUM" "VERIFY_MEDIUM" "EJECT_MEDIUM"
      PostProcessing "${ISO_IMG_FILE}" "REMOVE_IMG"
      
      ;;

# ---------------------------------------------------------------
    "readcdrom" | "readcd" | "readdvd" )	# readcdrom/readdvd isofile [sourcedevice]
      PreChecks readcd cdrecord || die 17 "Something is missing"

      echo ${SOURCE_PARAMETER} | read THIS_ISOFILE THIS_DEVICE THIS_DUMMY
      [ "${THIS_DUMMY}"x != ""x ] && die 19 "Too many parameter found!"

      [ "${THIS_ISOFILE}"x = ""x ] && die 17 "The ISO file name is missing"

      CheckSourceDevice "${THIS_DEVICE}" ${READER_DEV} 
      [ $? -ne 0 ] && die 18 "Invalid device entered: \"${THIS_DEVICE}\" "
# The variable ${THIS_DEV} contains device name for CDRECORD 
# The variable ${MOUNT_DEV} contains the device to mount
# The variable ${RAW_DEV} contains the raw device 
     
      CheckOutputfile ISO_IMG_FILE ${THIS_ISOFILE}
      [ $? -ne ${__TRUE} ] && die 65 "The name for the ISO file \"${THIS_ISOFILE}\" is invalid"

      InitOutputFile ${ISO_IMG_FILE} || die 16 "The file \"${ISO_IMG_FILE}\" already exist (use -O y to overwrite)"

      LogMsg "Creating an ISO image in the file "
      LogMsg "    ${ISO_IMG_FILE}"
      LogMsg "from medium in the drive" 
      LogMsg "    ${THIS_DEV}"

# reload the CD/DVD
      PreProcessing "${THIS_DEV}" "RELOAD_MEDIUM"
      [ $? -ne ${__TRUE} ] && die 30 "Error loading the medium"

      CDToISOImage ${RAW_DEV} ${ISO_IMG_FILE}
      __THISRC=$?
      [ ${__THISRC} -ne 0 ] && die 35 "Error creating the ISO image"

      PostProcessing "${THIS_DEV}" "EJECT_MEDIUM"
      PostProcessing "${ISO_IMG_FILE}"  "LIST_IMG" "TEST_IMG" "REMOVE_IMG"
      ;;            


# ---------------------------------------------------------------
    "createISOimg"   )	# createISOimg  sourcedir [isofile] [volid]
      PreChecks mkisofs || die 17 "Something is missing"    
      echo ${SOURCE_PARAMETER} | read THIS_SOURCEDIR THIS_ISOFILE THIS_VOLID THIS_DUMMY
      [ "${THIS_DUMMY}"x != ""x ] && die 19 "Too many parameter found!"

      CheckDirectory IMG_SOURCE_DIR ${THIS_SOURCEDIR}
      [ $? -ne ${__TRUE} ] && die 14 "Source directory \"${THIS_SOURCEDIR}\" not entered or not found"      

      [ "${THIS_ISOFILE}"x = ""x ] && THIS_ISOFILE="$( basename ${THIS_SOURCEDIR} ).iso"
      CheckOutputfile ISO_IMG_FILE ${THIS_ISOFILE}
      [ $? -ne ${__TRUE} ] && die 65 "The name for the ISO file \"${THIS_ISOFILE}\" is invalid"

      [ "${THIS_VOLID}"x = ""x ] && VOLID="$( basename ${THIS_SOURCEDIR} )" || VOLID=${THIS_VOLID}

      LogMsg "Creating an ISO image in the file "
      LogMsg "    ${ISO_IMG_FILE}"
      LogMsg "from the directory " 
      LogMsg "    ${IMG_SOURCE_DIR}"
      LogMsg "The volume ID for the image is \"${VOLID}\"."

      InitOutputFile ${ISO_IMG_FILE} || die 16 "The file \"${ISO_IMG_FILE}\" already exist (use -O y to overwrite)"

      if [ ${CHECK_DIR_SIZE} = ${__TRUE} ] ; then
        LogMsg "Checking the size of the source directory ..."
	CalculateDirSize ${IMG_SOURCE_DIR}
# DIR_SIZE now contains the directory size in KByte
# TREE_SIZE now contains the TREESIZE for CDRECORD

        LogMsg "The source directory uses about ${DIR_SIZE} KByte"
        CalculateFreespace $( dirname ${ISO_IMG_FILE} ) 

	LogMsg "The freespace in the target directory is about ${FREE_SPACE} KByte"	
	[ ${DIR_SIZE} -gt ${FREE_SPACE} ] && die 60 "Not enough free space to create the ISO image \"${ISO_IMG_FILE}\""
      fi

      DirToISOImage "${IMG_SOURCE_DIR}" "${ISO_IMG_FILE}" "${VOLID}"
      __THISRC=$?
      [ ${__THISRC} -ne 0 ] && die 80 "Error creating the temporary ISO image \"${ISO_IMG_FILE}\" from \"${IMG_SOURCE_DIR}\""

      PostProcessing "${ISO_IMG_FILE}"  "LIST_IMG" "TEST_IMG" "REMOVE_IMG"
      ;;
			

# ---------------------------------------------------------------
    "burncd" | "burndvd")	# burnCD/burnDVD isofile 
      PreChecks cdrecord || die 17 "Something is missing"

      echo ${SOURCE_PARAMETER} | read THIS_ISOFILE THIS_DUMMY
      [ "${THIS_DUMMY}"x != ""x ] && die 19 "Too many parameter found!"

      CheckInputfile ISO_IMG_FILE "${THIS_ISOFILE}"
      [ $? -ne ${__TRUE} ] && die 65 "The name for the ISO \"${THIS_ISOFILE}\" file is invalid or missing"

      LogMsg "Burning a medium from the ISO image "
      LogMsg "    ${ISO_IMG_FILE}"

      CheckISOImageSize ${ISO_IMG_FILE}
      __THISRC=$?
      if [ ${__THISRC} -ne 0 ] ; then
       if [ ${CHECK_DIR_SIZE} = ${__TRUE} ] ; then
         die 55 "The Image \"${ISO_IMG_FILE}\" is to big for the medium (${IMG_SIZE} KByte)"
       else
         LogWarning "The Image \"${ISO_IMG_FILE}\" is to big for the medium (${IMG_SIZE} KByte) - trying overburn"
	 RECORD_PARM="${RECORD_PARM} -overburn"
       fi
      fi
      
      while [ 0 = 0 ] ; do
        PreProcessing ${WRITER_DEV} "BLANK_MEDIUM"

        BurnISOImage "${ISO_IMG_FILE}"
        __THISRC=$?
        [ ${__THISRC} -ne 0 ] && LogError "Error burning the medium"

        PostProcessing "${WRITER_DEV}" "RELOAD_MEDIUM" "TEST_MEDIUM" "LIST_MEDIUM" "VERIFY_MEDIUM" 

        ProcessAnother "Write another medium?"
        [ $? -eq ${__FALSE} ] && break

        EjectMedium ${WRITER_DEV}

        echo "### Remove the disk and insert another target disk"
        echo "### Press enter when done"
        read USERINPUT

        LoadMedium ${WRITER_DEV}

      done

      PostProcessing "${WRITER_DEV}" "EJECT_MEDIUM"
      PostProcessing "${ISO_IMG_FILE}" "REMOVE_IMG" 
      ;;


# ---------------------------------------------------------------
    "test" | "testcd" | "testcdrom" | "testdvd" ) 	# testcdrom/testdvd [sourcedevice]
      PreChecks cdrecord || die 17 "Something is missing"

      echo ${SOURCE_PARAMETER} | read THIS_DEVICE THIS_DUMMY
      [ "${THIS_DUMMY}"x != ""x ] && die 19 "Too many parameter found!"

      CheckSourceDevice "${THIS_DEVICE}" ${WRITER_DEV} 
      [ $? -ne 0 ] && die 18 "Invalid device entered: \"${THIS_DEVICE}\" "
# The variable ${THIS_DEV} contains device name for CDRECORD 
# The variable ${MOUNT_DEV} contains the device to mount
# The variable ${RAW_DEV} contains the raw device 

      PreProcessing "${THIS_DEV}" "RELOAD_MEDIUM"

      while [ 0 = 0 ] ; do
        TestMedium ${THIS_DEV}
        __THISRC=$?

        ProcessAnother "Test another medium?"
        [ $? -eq ${__FALSE} ] && break

        EjectMedium ${THIS_DEV}

        echo "### Remove the disk and insert another disk"
        echo "### Press enter when done"
        read USERINPUT

        LoadMedium ${THIS_DEV}
      done
      
      PostProcessing "${THIS_DEV}" "EJECT_MEDIUM" 
      ;;

# ---------------------------------------------------------------
    "verify" | "verifycdrom"  ) 	# verifycdrom [sourcedevice]
      PreChecks readcd cdrecord || die 17 "Something is missing"

      echo ${SOURCE_PARAMETER} | read THIS_DEVICE THIS_DUMMY
      [ "${THIS_DUMMY}"x != ""x ] && die 19 "Too many parameter found!"

      CheckSourceDevice "${THIS_DEVICE}" ${WRITER_DEV} 
      [ $? -ne 0 ] && die 18 "Invalid device entered: \"${THIS_DEVICE}\" "
# The variable ${THIS_DEV} contains device name for CDRECORD 
# The variable ${MOUNT_DEV} contains the device to mount
# The variable ${RAW_DEV} contains the raw device 

      PreProcessing "${THIS_DEV}" "RELOAD_MEDIUM"

      while [ 0 = 0 ] ; do
        VerifyMedium ${THIS_DEV}
        __THISRC=$?
 
        ProcessAnother "Verify another medium?"
        [ $? -eq ${__FALSE} ] && break

        EjectMedium ${THIS_DEV}

        echo "### Remove the disk and insert another disk"
        echo "### Press enter when done"
        read USERINPUT

        LoadMedium ${THIS_DEV}
      done

      PostProcessing "${THIS_DEV}" "EJECT_MEDIUM" 

      ;;

# ---------------------------------------------------------------
    "list" | "listcd" | "listcdrom" | "listdvd" ) 	# listcdrom/listdvd [sourcedevice]

      echo ${SOURCE_PARAMETER} | read THIS_DEVICE THIS_DUMMY
      [ "${THIS_DUMMY}"x != ""x ] && die 19 "Too many parameter found!"

      CheckSourceDevice "${THIS_DEVICE}" ${WRITER_DEV} 
      [ $? -ne 0 ] && die 18 "Invalid device entered: \"${THIS_DEVICE}\" "
# The variable ${THIS_DEV} contains device name for CDRECORD 
# The variable ${MOUNT_DEV} contains the device to mount
# The variable ${RAW_DEV} contains the raw device 

      PreProcessing "${THIS_DEV}" "RELOAD_MEDIUM"

      while [ 0 = 0 ] ; do
        TestMedium ${THIS_DEV} "list"
        __THISRC=$?

        ProcessAnother "Test another medium?"
        [ $? -eq ${__FALSE} ] && break

        EjectMedium ${THIS_DEV}

        echo "### Remove the disk and insert another disk"
        echo "### Press enter when done"
        read USERINPUT

        LoadMedium ${THIS_DEV}
      done

      PostProcessing  "${THIS_DEV}" "EJECT_MEDIUM"
      ;;

# ---------------------------------------------------------------
    "testiso" )						# testiso [sourcedevice]
      PreChecks lofiadm
      echo ${SOURCE_PARAMETER} | read THIS_ISOFILE THIS_DUMMY
      [ "${THIS_DUMMY}"x != ""x ] && die 19 "Too many parameter found!"

      CheckInputfile ISO_IMG_FILE "${THIS_ISOFILE}"
      [ $? -ne ${__TRUE} ] && die 65 "The name for the ISO \"${THIS_ISOFILE}\" file is invalid or missing"

      TestISOFile ${ISO_IMG_FILE}
      __THISRC=$?
      ;;


# ---------------------------------------------------------------
    "listiso" )						# listiso [sourcedevice]
      PreChecks lofiadm
      echo ${SOURCE_PARAMETER} | read THIS_ISOFILE THIS_DUMMY
      [ "${THIS_DUMMY}"x != ""x ] && die 19 "Too many parameter found!"

      CheckInputfile ISO_IMG_FILE "${THIS_ISOFILE}"
      [ $? -ne ${__TRUE} ] && die 65 "The name for the ISO \"${THIS_ISOFILE}\" file is invalid or missing"

      TestISOFile ${ISO_IMG_FILE} "list"
      __THISRC=$?
      ;;


# ---------------------------------------------------------------
    "clonecdrom" | "clonecd" | "clonedvd" )	# clonecdrom sourcedevice [imagename]
      PreChecks readcd cdrecord || die 17 "Something is missing"     

      echo ${SOURCE_PARAMETER} | read THIS_DEVICE THIS_IMG THIS_DUMMY
      [ "${THIS_DUMMY}"x != ""x ] && die 19 "Too many parameter found!"

      CheckSourceDevice "${THIS_DEVICE}" ${READER_DEV} 
      [ $? -ne 0 ] && die 18 "Invalid device entered: \"${THIS_DEVICE}\" "
# The variable ${THIS_DEV} contains device name for CDRECORD 
# The variable ${MOUNT_DEV} contains the device to mount
# The variable ${RAW_DEV} contains the raw device 

      PreProcessing "${THIS_DEV}" "RELOAD_MEDIUM"

      if [ ${WRITE_ON_THE_FLY} = ${__TRUE} ] ; then
        [ "${THIS_DEV}" = "${WRITER_DEV}" ] && die 95 "Copying on the fly not possible if the read and write devices are the same"
        [ "${THIS_IMG}"x != ""x ] && die 19 "Too many parameter found!"

        CloneMediumOnTheFly "${THIS_DEV}"
        __THISRC=$?
        [ ${__THISRC} -ne 0 ] && die 25 "Error cloning the medium"
	
      else
        if [ "${THIS_IMG}"x != ""x ] ; then
          CheckInputfile THIS_RAW_IMG "${THIS_IMG}" 
          [ $? -ne ${__TRUE} ] && die 65 "The name for the img file \"${THIS_IMG}\" file is invalid or missing"
          [ ! -f "${THIS_RAW_IMG}.toc" ] && die 85 "The toc file is missing for the file \"${THIS_IMG}\" "
        else
          if [ ${CHECK_DIR_SIZE} = ${__TRUE} ] ; then
  	    LogMsg "Checking the free space in the target directory ..."
            CheckMediumSize ${MOUNT_DEV}
            LogMsg "The temporary ISO image needs about ${MEDIUM_SIZE} KByte."
            CalculateFreespace ${IMG_TARGET_DIR}
    	    LogMsg "The freespace in the target directory \"${IMG_TARGET_DIR}\" is about ${FREE_SPACE} KByte"
            [ ${MEDIUM_SIZE} -gt ${FREE_SPACE} ] && die 60 "Not enough free space to create the temporary ISO image"
	  fi
        fi
      
        CloneMedium ${THIS_DEV} ${IMG_TARGET_DIR} ${THIS_RAW_IMG}
        __THISRC=$?
        [ ${__THISRC} -ne 0 ] && die 25 "Error cloning the medium"
      fi	
      ;;

# ---------------------------------------------------------------
    "copycdrom" | "copycd" | "copydvd" )	# copycdrom/copydvd sourcedevice [imagename]
      PreChecks readcd cdrecord || die 17 "Something is missing"     

      echo ${SOURCE_PARAMETER} | read THIS_DEVICE THIS_IMG THIS_DUMMY
      [ "${THIS_DUMMY}"x != ""x ] && die 19 "Too many parameter found!"

      CheckSourceDevice "${THIS_DEVICE}" ${READER_DEV} 
      [ $? -ne 0 ] && die 18 "Invalid device entered: \"${THIS_DEVICE}\" "
# The variable ${THIS_DEV} contains device name for CDRECORD 
# The variable ${MOUNT_DEV} contains the device to mount
# The variable ${RAW_DEV} contains the raw device 

      PreProcessing "${THIS_DEV}" "RELOAD_MEDIUM"

      if [ ${WRITE_ON_THE_FLY} = ${__TRUE} ] ; then
        [ "${THIS_DEV}" = "${WRITER_DEV}" ] && die 95 "Copying on the fly not possible if the read and write devices are the same"
        [ "${THIS_IMG}"x != ""x ] && die 19 "Too many parameter found!"

        CopyMediumOnTheFly "${RAW_DEV}"
        __THISRC=$?
        [ ${__THISRC} -ne 0 ] && die 26 "Error copying the medium"
	
      else
        if [ "${THIS_IMG}"x != ""x ] ; then
          CheckInputfile THIS_ISO_IMG "${THIS_IMG}" 
          [ $? -ne ${__TRUE} ] && die 65 "The name for the img file \"${THIS_IMG}\" file is invalid or missing"
          [ ! -f "${THIS_ISO_IMG}.toc" ] && die 85 "The toc file is missing for the file \"${THIS_IMG}\" "
        else
          if [ ${CHECK_DIR_SIZE} = ${__TRUE} ] ; then
  	    LogMsg "Checking the free space in the target directory ..."
            CheckMediumSize ${MOUNT_DEV}
            LogMsg "The temporary ISO image needs about ${MEDIUM_SIZE} KByte."
            CalculateFreespace ${IMG_TARGET_DIR}
    	    LogMsg "The freespace in the target directory \"${IMG_TARGET_DIR}\" is about ${FREE_SPACE} KByte"
            [ ${MEDIUM_SIZE} -gt ${FREE_SPACE} ] && die 60 "Not enough free space to create the temporary ISO image"
	  fi
        fi
      
        CopyMedium ${RAW_DEV} ${IMG_TARGET_DIR} ${THIS_ISO_IMG}
        __THISRC=$?
        [ ${__THISRC} -ne 0 ] && die 26 "Error copying the medium"

      fi	
      ;;

                   
# ---------------------------------------------------------------
    "copyaudiocd" )	# copyaudiocd sourcedevice [useCDDB]   
      PreChecks cdda2wav cdrecord || die 17 "Something is missing"

      echo ${SOURCE_PARAMETER} | read THIS_DEVICE USE_CDDB THIS_DUMMY
      [ "${THIS_DUMMY}"x != ""x ] && die 19 "Too many parameter found!"

      if [ "${THIS_DEVICE}" = "y" -o "${THIS_DEVICE}" = "n" ] ; then
        THIS_DEVICE=""
	USE_CDDB="${THIS_DEVICE}"
      fi

      CheckSourceDevice "${THIS_DEVICE}" ${READER_DEV} 
      [ $? -ne 0 ] && die 18 "Invalid device entered: \"${THIS_DEVICE}\" "
# The variable ${THIS_DEV} contains device name for CDRECORD 
# The variable ${MOUNT_DEV} contains the device to mount
# The variable ${RAW_DEV} contains the raw device 

      PreProcessing "${THIS_DEV}" "RELOAD_MEDIUM"

      [ "${USE_CDDB}"x = ""x  ] && USE_CDDB=${DEFAULT_USE_CDDB}

      THIS_DIR="audiocd.$$"
      
      ReadAudioCD "${THIS_DEV}" "${THIS_DIR}" ${USE_CDDB}
      __THISRC=$?
      [ ${__THISRC} -ne 0 ]  && die 105 "Error reading the audio CD"

      if [ "${THIS_DEV}" = "${WRITER_DEV}" ] ; then
        EjectMedium ${WRITER_DEV}

        echo "### Remove the source disk and insert the target disk"
        echo "### Press enter when done"
        read USERINPUT

        LoadMedium ${WRITER_DEV}
      fi

      PreProcessing ${WRITER_DEV} "BLANK_MEDIUM"

      WriteAudioCD "${WRITER_DEV}" "${THIS_DIR}"
      __THISRC=$?

      if [ ${REMOVE_ISO_IMAGE} = ${__TRUE} ] ; then
        LogMsg "Removing the directory  \"${THIS_DIR}\" ..."
        rm -rf ${THIS_DIR}
        [ $? -ne 0 ] && LogWarning "Error removing the image files"
      fi 

      PostProcessing "EJECT" "${WRITER_DEV}"

      [ ${__THISRC} -ne 0 ]  && die 110 "Error writing the audio CD"
           
      ;;

# ---------------------------------------------------------------
    "readaudiocd" )	# readaudiocd targetdir [sourcedevice] [useCDDB]
      PreChecks cdda2wav || die 17 "Something is missing"

      echo ${SOURCE_PARAMETER} | read THIS_DIR THIS_DEVICE USE_CDDB THIS_DUMMY
      [ "${THIS_DUMMY}"x != ""x ] && die 19 "Too many parameter found!"

      if [ "${THIS_DEVICE}" = "y" -o "${THIS_DEVICE}" = "n" ] ; then
        THIS_DEVICE=""
	USE_CDDB="${THIS_DEVICE}"
      fi
      	
      CheckSourceDevice "${THIS_DEVICE}" ${READER_DEV} 
      [ $? -ne 0 ] && die 18 "Invalid device entered: \"${THIS_DEVICE}\" "
# The variable ${THIS_DEV} contains device name for CDRECORD 
# The variable ${MOUNT_DEV} contains the device to mount
# The variable ${RAW_DEV} contains the raw device 

      [ "${USE_CDDB}"x = ""x  ] && USE_CDDB=${DEFAULT_USE_CDDB}

      PreProcessing ${THIS_DEV} "BLANK_MEDIUM"

      ReadAudioCD "${THIS_DEV}" "${THIS_DIR}" ${USE_CDDB}
      __THISRC=$?

      PostProcessing "${THIS_DEV}" "EJECT_MEDIUM"

      [ ${__THISRC} -ne 0 ]  && die 105 "Error reading the audio CD"

      ;;

# ---------------------------------------------------------------
    "writeaudiocd" )	# writeaudiocd sourcedir [targetdevice]
      PreChecks cdrecord || die 17 "Something is missing"

      echo ${SOURCE_PARAMETER} | read THIS_DIR THIS_DEVICE THIS_DUMMY
      [ "${THIS_DUMMY}"x != ""x ] && die 19 "Too many parameter found!"

      CheckSourceDevice "${THIS_DEVICE}" ${WRITER_DEV} 
      [ $? -ne 0 ] && die 18 "Invalid device entered: \"${THIS_DEVICE}\" "
# The variable ${THIS_DEV} contains device name for CDRECORD 
# The variable ${MOUNT_DEV} contains the device to mount
# The variable ${RAW_DEV} contains the raw device 

      PreProcessing ${WRITER_DEV} "BLANK_MEDIUM"

      WriteAudioCD "${THIS_DEV}" "${THIS_DIR}"
      __THISRC=$?

      if [ ${REMOVE_ISO_IMAGE} = ${__TRUE} ] ; then
        LogMsg "Removing the directory \"${THIS_DIR}\" ..."
        rm -rf ${THIS_DIR}
        [ $? -ne 0 ] && LogWarning "Error removing the image files"
      fi 

      PostProcessing "${THIS_DEV}" "EJECT_MEDIUM"

      [ ${__THISRC} -ne 0 ]  && die 110 "Error writing the audio CD"

      ;;
          
# ---------------------------------------------------------------
     * )                
      die 496 "Unknown action \"${ACTION}\"  "
      ;;
      
# ---------------------------------------------------------------

  esac

  die ${__THISRC}
