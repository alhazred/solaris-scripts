#!/bin/ksh
#
#H# Description
#H#   wrapper script for scp and ssh
#H#
#H# Author:
#H#   Bernd Schemmer, Bernd.Schemmer@de.ibm.com
#H#
#H# History
#H#   06.08.2015 v1.0.0 /bs
#H#    initial release
#H#   09.11.2015 v1.1.0 /bs
#H#    added support for Deuba hostnames starting with fra
#H#   19.11.2015 v1.1.1 /bs
#H#    the script did not support the default user for scp -- fixed now
#H#   21.12.2015 v1.1.2 /bs
#H#    the script now supports blanks in names for local files and dirs
#H#    the ssh wraper for SLS is now also used for unknown hosts and IP 
#H#    addresses
#H#    the script now supports also hostnames in uppercase 
#H#   05.01.2016 v1.1.3 /bs
#H#    in version 1.1.2 the script also converted filenames to lowercase -- fixed now
#H#   02.03.2016 v1.1.4 /bs
#H#    added support for the new ticket requirement for Deuba ssh access
#H#   07.03.2016 v1.1.5 /bs
#H#    addeded the parameter --noticket
#H#   08.03.2016 v1.1.6 /bs
#H#    fixed a minor bug for the parameter --noticket
#H#   17.06.2016 v1.1.7 /bs
#H#    the wrapper script failed to upload a file with a name like a known hostname - fixed
#H#      "scp dbkreccscxt01 support@dbkreccscxt01:."  now works
#H#    the wrapper script now supports uploads of multiple files to a host
#H#      "scp test11 test12 support@dbkreccscxt01:."  now works
#H#    the usage of a ticket is now again the default for ssh/scp to/from Deuba machines
#H#   12.07.2016 v1.1.8 /bs
#H#    the script did no use ticket numbers for hostnames found in the host file - fixed 
#H#   25.09.2016 v1.1.9 /bs
#H#    added code to add the host ssh key to the known_hosts
#H#   18.11.2016 v1.2.0 /bs
#H#    added code to support switches (like -p) for scp
#H#   31.01.2017 v1.3.0 /bs
#H#    added support for scp/ssh from RHEL 7.x
#H#
#H#
#
SCRIPT_VERSION="1.3.0"

__TRUE=0
__FALSE=1

__SHEBANG="$( head -1 $0 )"
__SCRIPT_SHELL="${__SHEBANG#*!}"
__SCRIPT_SHELL="${__SCRIPT_SHELL% *}"
__SCRIPT_SHELL_OPTIONS="${__SHEBANG#* }"
[ "${__SCRIPT_SHELL_OPTIONS}"x = "${__SHEBANG}"x ] && __SCRIPT_SHELL_OPTIONS=""


# config file (  set to "" to not use a config file )
#
# to use another config file call the script with
#   CONFIG_FILE=<your_config_file> ssh
# or
#   CONFIG_FILE=<your_config_file> ssh
#
if [ "${CONFIG_FILE}"x != ""x ] ; then
  NEW_CONFIG_FILE_USED=${__TRUE}
else
  NEW_CONFIG_FILE_USED=${__FALSE}
  CONFIG_FILE=~/ssh_and_scp_wrapper.config
fi

# default ssh options (added to all ssh commands)
#
DEFAULT_SSH_OPTIONS=""

# default scp options (added to all scp commands)
#
DEFAULT_SCP_OPTIONS=""

# default user for ssh (set to "" to not use a default user)
# (see below to use different ssh default users for different customers)
#
DEFAULT_SSH_USER="support"

# default user for scp (set to "" to not use a default user)
# (see below to use different scp default users for different customers)
#
DEFAULT_SCP_USER="support"


# default ticket string and ticket variables
#
DEFAULT_TICKET_STRING="ticket_id=9999"
TICKET_STRING=""
USE_TICKET=${__FALSE}
TICKET_STRING_FOUND=${__FALSE}
DO_NOT_USE_TICKETS=${__FALSE}

# default user for scp for the customer Deuba
#
DEFAULT_SCP_USER_dbk="support"

# default user for ssh for the customer Deuba
#
DEFAULT_SSH_USER_fra="support"

# default user for scp for the customer Deuba
#
DEFAULT_SCP_USER_fra="support"

# default user for ssh for the customer Deuba
#
DEFAULT_SSH_USER_dbk="support"


# default user for scp for the customer HSH
#
DEFAULT_SCP_USER_hsh="support"

# default user for ssh for the customer HSH
#
DEFAULT_SSH_USER_hsh="support"


# default user for scp for the customer FMS
#
DEFAULT_SCP_USER_fms="support"

# default user for ssh for the customer FMS
#
DEFAULT_SSH_USER_fms="support"


# default user for scp for the customer Haspa
#
DEFAULT_SCP_USER_hh="support"

# default user for ssh for the customer Haspa
#
DEFAULT_SSH_USER_hh="support"


# default user for scp for the customer Henkel US
#
DEFAULT_SCP_USER_ushen="root"

# default user for ssh for the customer Henkel US
#
DEFAULT_SSH_USER_ushen="root"


# default binary used for ssh
#
SSH_BINARY="/usr/bin/ssh"

# default binary used for scp
#
SCP_BINARY="/usr/bin/scp"

HOST_LIST_FILE=~/ssh_and_scp_wrapper_hostlist

HOST_LIST="
#
# format of the entries in this list:
#
#  short_hostname : customer : domain : interface
#

hshpt5phys0001cl0:hsh:net01.extern01:a1
hshpt5phys0001cl1:hsh:net01.extern01:a1

hshpt5phys0002cl0:hsh:net01.extern01:a1
hshpt5phys0002cl1:hsh:net01.extern01:a1

hshpt5phys0003cl0:hsh:net01.extern01:a1
hshpt5phys0003cl1:hsh:net01.extern01:a1

hshpt5phys0004cl0:hsh:net01.extern01:a1
hshpt5phys0004cl1:hsh:net01.extern01:a1
"

# tmporary ssh wrapper for scp to activate the Forward Agent
#
SSH_WRAPPER="/tmp/ssh_wrapper_for_scp"

# known_hosts file
#
SRCFILE="${HOME}/.ssh/known_hosts"

# backup file for the known_hosts file
# (will be deleted at script end)
#
BKPFILE="/tmp/known_hosts.$$"

# additional parameter for the real ssh or scp
#
ADD_PARAMETER=""

# -- functions ---
#

LogInfo() {
  [ "${QUIET}"x = ""x ] && echo "*** INFO: $*" >&2
}

LogError() {
  echo "*** ERROR: $*" >&2
}

LogVerbose() {
  [ "${DEBUG}"x != ""x ] && echo "*** DEBUG: $*" >&2
}

ProcessCustomer() { 
  typeset THIS_DOMAIN="$1"

  [ ${DO_NOT_USE_TICKETS} = ${__TRUE} ] && USE_TICKET=${__FALSE}

  if [ ${USE_TICKET} = ${__FALSE} ] ; then
    if [ ${TICKET_STRING_FOUND} =  ${__TRUE} ] ; then
      LogInfo "Ticket string found in the parameter \"${TICKET_STRING}\" but ticket strings are disabled for the current customer"
    fi
    TICKET_STRING=""   
  else
    [ "${TICKET_STRING}"x = ""x ] && TICKET_STRING="${DEFAULT_TICKET_STRING}@"
#    [ "${TICKET_STRING}"x != ""x ] && TICKET_STRING="${TICKET_STRING}@"
  fi
  
  if [ "${THIS_DOMAIN}"x != "rze.de.db.com"x ] ; then
    HOSTNAME="${HOSTNAME}${HOST_INTERFACE}"

    LogVerbose "   HOSTNAME is now: \"${HOSTNAME}\" "

    [ "${DOMAIN}"x = ""x ] && DOMAIN="${THIS_DOMAIN}"
    LogVerbose "   DOMAIN is now:   \"${DOMAIN}\" "

    [ "${CUR_HOSTNAME#*@}"x != "${HOSTNAME}.${DOMAIN}" ] && LogInfo "Hostname \"${CUR_HOSTNAME}\" replaced with \"${HOSTNAME}.${DOMAIN}\" "

    if [ "${ACTION}"x = "scp"x ] ; then
      [ "${USERNAME}"x != ""x ] && PARAMETER="${PARAMETER} ${TICKET_STRING}${USERNAME}@${HOSTNAME}.${DOMAIN}:'${FILENAME}'" || PARAMETER="${PARAMETER} ${TICKET_STRING}${HOSTNAME}.${DOMAIN}:'${FILENAME}'"
      ADD_PARAMETER="-S ${SSH_WRAPPER} "
    else
      [ "${USERNAME}"x != ""x ] && PARAMETER="${PARAMETER} ${TICKET_STRING}${USERNAME}@${HOSTNAME}.${DOMAIN}" || PARAMETER="${PARAMETER} ${TICKET_STRING}${HOSTNAME}.${DOMAIN}"
    fi
    HOSTNAME_FOUND=${__TRUE}
  else

    [ "${DOMAIN}"x = ""x ] && DOMAIN="${THIS_DOMAIN}"

    HOSTNAME="${HOSTNAME}${HOST_INTERFACE}"
    LogVerbose "   HOSTNAME is now: \"${HOSTNAME}\" "

    LogVerbose "   DOMAIN is now:   \"${DOMAIN}\" "

    [ "${CUR_HOSTNAME#*@}"x != "${HOSTNAME}.${DOMAIN}"x ] && LogInfo "Hostname \"${CUR_HOSTNAME#*@}\" replaced with \"${HOSTNAME}.${DOMAIN}\" "

    cp "${SRCFILE}" "${BKPFILE}" && grep -v "^${HOSTNAME}.${DOMAIN}" "${BKPFILE}" > "${SRCFILE}" \
      && diff "${SRCFILE}" "${BKPFILE}" >/dev/null || LogInfo "Hostname \"${HOSTNAME}.${DOMAIN}\" removed from the known_hosts file"
    [ -f "${BKPFILE}" ] && rm "${BKPFILE}"

    LogInfo "Adding the host key for ${HOSTNAME}.${DOMAIN} to the known_hosts"
    ssh-keyscan "${HOSTNAME}.${DOMAIN}" >>$HOME/.ssh/known_hosts

    if [ "${ACTION}"x = "scp"x ] ; then
      [ "${USERNAME}"x != ""x ] && PARAMETER="${PARAMETER} ${TICKET_STRING}${USERNAME}@${HOSTNAME}.${DOMAIN}:'${FILENAME}'" || PARAMETER="${PARAMETER} ${HOSTNAME}.${DOMAIN}:'${FILENAME}'"
      ADD_PARAMETER="-S ${SSH_WRAPPER} "
    else
      [ "${USERNAME}"x != ""x ] && PARAMETER="${PARAMETER} ${TICKET_STRING}${USERNAME}@${HOSTNAME}.${DOMAIN}" || PARAMETER="${PARAMETER} ${HOSTNAME}.${DOMAIN}"
    fi
    HOSTNAME_FOUND=${__TRUE}
  fi
}

# --- main code ---
#

# check for invalid link/script name
#
if [[ $0 == *ssh* && $0 == *scp* ]] ; then
  if [[ $0 != *wrapper* ]] ; then
#### invalid link name
    echo "
Invalid script/link name: $0  -- do NOT use a link with \"ssh\" and \"scp\" in the name!
"
    exit  6
  fi
fi

# check for a config file
#
if [ "${CONFIG_FILE}"x != ""x ] ; then
  [ ${NEW_CONFIG_FILE_USED} = ${__TRUE} ] && \
    LogInfo "The config file used is \"${CONFIG_FILE}\"." ||
    LogVerbose "The config file used is \"${CONFIG_FILE}\"."

  if [ -r "${CONFIG_FILE}" ] ; then
    [ ${NEW_CONFIG_FILE_USED} = ${__TRUE} ] && \
      LogInfo "Reading the config file \"${CONFIG_FILE}\" ..." ||
      LogVerbose "Reading the config file \"${CONFIG_FILE}\" ..."
# check the config file
    ${__SCRIPT_SHELL} -x -n "${CONFIG_FILE}"
    if [ $? -ne 0 ] ; then
      LogError "There is an error in the config file \"${CONFIG_FILE}\""
      exit 101
    fi
    . "${CONFIG_FILE}"
  else
    [ ${NEW_CONFIG_FILE_USED} = ${__TRUE} ] && \
      LogInfo "The config file \"${CONFIG_FILE}\" does not exist or is not readable." ||
      LogVerbose "The config file \"${CONFIG_FILE}\" does not exist or is not readable."
  fi
else
  LogInfo "No config file configured."
fi

# --- variables that can not be overwritten by a config file ---
#

# hostname already found in the parameter?
#
HOSTNAME_FOUND=${__FALSE}

USERNAME_FOUND=${__FALSE}

# converted parameter for ssh or scp
#
PARAMETER=""


# check for the parameter --version
#
if [[ "$1"x == "--version"x || "$1"x == "-V"x ]] ; then
  echo "# $( basename $0 ) ${SCRIPT_VERSION}
#
$( grep "^#H#" $0 | cut -c3- )
"
  exit 2
#
fi

# check for the parameter --hostlist
#
if [[ "$1"x == "--hostlist"x  ]] ; then
  echo ""
  echo "### The internal hostlist is "
  echo "${HOST_LIST}"
  echo ""
  if [ -f ${HOST_LIST_FILE} ] ; then
    echo "### The contents of the host list file \"${HOST_LIST_FILE}\" are:"
    echo ""
    cat ${HOST_LIST_FILE}
    echo ""
  else
    echo "### The host list file \"${HOST_LIST_FILE}\" does not exist or is not readable."
  fi
  exit 0
fi

# check for the parameter --help
#
if [[ "$1"x == "--help"x || "$1"x == "-h"x ]] ; then

  if [[ $0 == *wrapper* ]] ; then
#### wrapper script -- no link created
####
    echo "

To use this script create symbolic links with \"ssh\" or \"scp\" in the name (and WITHOUT \"wrapper\" in the name), e.g

  ln -s $0 ./ssh
  ln -s $0 ./scp

or

  ln -s $0 ./my_ssh
  ln -s $0 ./myscp


Notes:

The config file used for both symbolic links is \"${CONFIG_FILE}\".

The file with the exceptions for hostnames used for both symbolic links is \"${HOST_LIST_FILE}\"
"
  elif [[ $0 == *scp* ]] ; then
#### scp wrapper
####
    echo "
Usage $0 <parameter_for_scp>

This script is a wrapper for scp to support the various customers (Deuba, Haspa, FMS, HSH).
You should copy it to a directory in the path before /usr/bin.

The real scp binary used by this script is \"${SCP_BINARY}\".
The default user for scp is \"${DEFAULT_SCP_USER}\".

The scripts supports these customers:

  Deuba:
    Deuba hostnames start with dbk
    The script adds the default Deuba domain \"rze.de.db.com\" to the hostname if necessary
    The script removes the hostname from the known_hosts file if necessary
    The script enables Forward Authentification for scp

  Deuba:
    These deuba hostnames start with fra
    The script adds the default Deuba domain \"de.db.com\" to the hostname if necessary
    The script removes the hostname from the known_hosts file if necessary
    The script enables Forward Authentification for scp

  Haspa:
    Haspa hostnames start with hh
    The script adds the default Haspa Admin domain \"hsp.de.sni.ibm.com\" to the hostname if necessary
    The script adds the standard admin interface \"a1\" to the hostname if neccessary

  HSH:
    HSH hostnames start with hsh
    The script adds the default HSH Admin domain \"hsh.de.sni.ibm.com\" to the hostname if necessary
    The script adds the standard admin interface \"a1\" to the hostname if neccessary

  FMS:
    FMS hostnames start with fms
    The script adds the default FMS domain \"dcrm.fms-sg.de\" to the hostname if necessary
    The script adds the standard admin interface \"a1\" to the hostname if neccessary

  Use \"PREFIX=echo $0 <scp_parameter>\" to only print the scp command without executing it
    (the message is written to STDOUT)

  Use \"QUIET=0 $0 <scp_parameter>\" to suppress the messages of the script
    (the messages are written to STDERR)

  Use \"DEBUG=0 $0 <scp_parameter>\" to get some debug messages
    (the messages are written to STDERR)


  The config file used is \"${CONFIG_FILE}\".
  Use \"CONFIG_FILE=<your_configfile> $0 <scp_parameter>\" to use a different config file.

  The file with the exceptions for hostnames is \"${HOST_LIST_FILE}\"
  Use the parameter \"--hostlist\" to view the host lists used; use
  the parameter \"--version\" to view the version and history for the script.

  Use the parameter --noticket to disable the use of the ticket parameter.
"

  elif [[ $0 == *ssh* ]] ; then
#### ssh wrapper
####
    echo "
Usage $0 <parameter_for_ssh>

This script is a wrapper for ssh to support the various customers (Deuba, Haspa, FMS, HSH).
You should copy it to a directory in the path before /usr/bin.

The script does nothing for parameter for SLS connections.

The real ssh binary used by this script is \"${SSH_BINARY}\".
The default user for ssh is \"${DEFAULT_SSH_USER}\".

The scripts supports these customers:

  Deuba:
    Deuba hostnames start with dbk
    The script adds the default Deuba domain \"rze.de.db.com\" to the hostname if necessary
    The script removes the hostname from the known_hosts file if necessary

  Haspa:
    Haspa hostnames start with hh
    The script adds the default Haspa Admin domain \"hsp.de.sni.ibm.com\" to the hostname if necessary
    The script adds the standard admin interface \"a1\" to the hostname if neccessary

  HSH:
    HSH hostnames start with hsh
    The script adds the default HSH Admin domain \"hsh.de.sni.ibm.com\" to the hostname if necessary
    The script adds the standard admin interface \"a1\" to the hostname if neccessary

  FMS:
    FMS hostnames start with fms
    The script adds the default FMS domain \"dcrm.fms-sg.de\" to the hostname if necessary
    The script adds the standard admin interface \"a1\" to the hostname if neccessary

  Use \"PREFIX=echo $0 <ssh_parameter>\" to only print the ssh command without executing it
    (the message is written to STDOUT)

  Use \"QUIET=0 $0 <ssh_parameter>\" to suppress the messages of the script
    (the messages are written to STDERR)

  Use \"DEBUG=0 $0 <ssh_parameter>\" to get some debug messages
    (the messages are written to STDERR)

  The config file used is \"${CONFIG_FILE}\".
  Use \"CONFIG_FILE=<your_configfile> $0 <ssh_parameter>\" to use a different config file.

  The file with the exceptions for hostnames is \"${HOST_LIST_FILE}\"
  Use the parameter \"--hostlist\" to view the host lists used; use
  the parameter \"--version\" to view the version and history for the script.

  Use the parameter --noticket to disable the use of the ticket parameter.
 "
  else
#### unknown script name
####
    echo "Unknown script name found: $0"
  fi

  exit 1
fi

if [[ $0 == *wrapper* ]] ; then
#### wrapper script called directly
###
  echo "
Do NOT call the wrapper script directly!
"
  exit  6
fi


case $0 in

  *ssh* )
     REAL_BINARY="${SSH_BINARY}"
     DEFAULT_USER="${DEFAULT_SSH_USER}"
     DEFAULT_OPTIONS="${DEFAULT_SSH_OPTIONS}"
     ACTION="ssh"
     ;;

  *scp* )
     REAL_BINARY="${SCP_BINARY}"
     DEFAULT_USER="${DEFAULT_SCP_USER}"
     DEFAULT_OPTIONS="${DEFAULT_SSH_OPTIONS}"
     ACTION="scp"

     if [ ! -x "${SSH_WRAPPER}" ] ; then
       LogVerbose "Creating the ssh wrapper for scp \"${SSH_WRAPPER}\" ..."
       grep "7\." /etc/redhat-release >/dev/null
       if  [ $? -eq 0 ] ; then
         echo "#!/usr/bin/perl
exec '/usr/bin/ssh', map {\$_ eq '-oForwardAgent=no' ? (  ) : \$_} @ARGV;
">"${SSH_WRAPPER}" && chmod 755 "${SSH_WRAPPER}"
         THISRC=$?
       else
         echo "#!/usr/bin/perl
exec '/usr/bin/ssh', map {\$_ eq '-oForwardAgent no' ? (  ) : \$_} @ARGV;
">"${SSH_WRAPPER}" && chmod 755 "${SSH_WRAPPER}"
         THISRC=$?
       fi
       
       if  [ ${THISRC} -ne 0 ] ; then
         echo "ERROR: Can NOT create the necessary ssh wrapper script \"${SSH_WRAPPER}\" "
         exit 255
       fi
     else
       LogVerbose "The ssh wrapper for scp \"${SSH_WRAPPER}\" already exists."
       LogVerbose "$( ls -l ${SSH_WRAPPER}) "
     fi
     ;;

  * )
    LogError "Invalid script name: \"$0\"."
    ACTION="unknown"
    exit 100
    ;;

esac


LogVerbose "Current action: ${ACTION}; real binary used is ${REAL_BINARY}"
LogVerbose "  Default user for ${ACTION} is \"${DEFAULT_USER}\" . "

typeset -l CUR_HOSTNAME

# check for sls and ssh
#
echo "$*" | grep sls >/dev/null
if [ $? -eq 0 -a "${ACTION}"x = "ssh"x ] ; then
# sls used do nothing - just call ssh
  LogVerbose "sls found - doing nothing with the parameter"
  PARAMETER="$*"
else
# no sls used -- process every parameter to find the hostname
#
  USER_PARAMETER=${__FALSE}

  while [ $# -ne 0 ] ; do

    CUR_PARAMETER="$1"
    LogVerbose "Processing the parameter \"${CUR_PARAMETER}\" ..."

    if [ "$1"x = "--noticket"x ] ; then
      DO_NOT_USE_TICKETS=${__TRUE}
      shift
      continue
    fi
    
    PARAMETER_IN_LOWERCASE="$( echo "${CUR_PARAMETER}"  | tr "A-Z" "a-z" )"
       
# check for the ssh parameter for the ssh user
    if [ "$1"x = "-l"x ] ; then
      USERNAME="$2"
      USERNAME_FOUND=${__TRUE}
      USER_PARAMETER=${__TRUE}
    fi

    LogVerbose "Current parameter is: \"$1\" "
    if [ "${ACTION}"x = "scp"x -a -r "${CUR_PARAMETER}" ] ; then
      LogVerbose "${CUR_PARAMETER} is an existing file"      
      PARAMETER="${PARAMETER} \"$1\" "
    elif [ ${HOSTNAME_FOUND} = ${__FALSE} ] ; then
# hostname not yet found in the parameter

      HOSTNAME="${CUR_PARAMETER}"

      if [ "${ACTION}"x = "scp"x ] ; then
# split the parameter into filename and hostname
#
        FILENAME="${HOSTNAME#*:}"
        HOSTNAME="${HOSTNAME%%:*}"
        [ "${FILENAME}"x == "${HOSTNAME}"x ] && FILENAME=""
        LogVerbose "FILENAME is \"${FILENAME}\" "
      fi


# split the hostname into username and hostname
#
      THIS_USERNAME="${HOSTNAME%@*}"
      if [ "${THIS_USERNAME}"x = "${HOSTNAME}x" ] ; then
        THIS_USERNAME="" 
      else
        THIS_USERNAME_FOUND=${__TRUE}
        HOSTNAME="${HOSTNAME##*@}"
        TICKET_STRING="${THIS_USERNAME%@*}"
        if [ "${THIS_USERNAME}"x = "${TICKET_STRING}x" ] ; then
          if [[ ${THIS_USERNAME} == *=* ]] ; then
            THIS_USERNAME=""
            THIS_USERNAME_FOUND=${__FALSE}
            TICKET_STRING="${TICKET_STRING}@"
            TICKET_STRING_FOUND=${__TRUE}
          else
            TICKET_STRING="${DEFAULT_TICKET_STRING}@"
            USERNAME_FOUND=${__TRUE}
          fi
        else
          TICKET_STRING="${TICKET_STRING}@"
          THIS_USERNAME="${THIS_USERNAME##*@}"
          TICKET_STRING_FOUND=${__TRUE}
          USERNAME_FOUND=${__TRUE}
        fi
      fi

      if [ ${USER_PARAMETER} = ${__FALSE} ] ; then
        USERNAME="${THIS_USERNAME}"
      fi

# split the hostname into hostname and DNS domain
#
      HOSTNAME="${HOSTNAME#*@}"
      DOMAIN="${HOSTNAME#*.}"
      HOSTNAME="${HOSTNAME%%.*}"
      [ "${DOMAIN}"x = "${HOSTNAME}"x ] && DOMAIN=""

      
      HOSTNAME="$( echo "${HOSTNAME}" | tr "A-Z" "a-z" )"
      DOMAIN="$( echo ${DOMAIN} | tr "A-Z" "a-z" )"
      CUR_HOSTNAME="${HOSTNAME}"
      
      LogVerbose " USERNAME is: \"${USERNAME}\" "
      LogVerbose " HOSTNAME is: \"${HOSTNAME}\" "
      LogVerbose " DOMAIN is:   \"${DOMAIN}\" "
      LogVerbose " TICKET_STRING is \"${TICKET_STRING}\" "
      
      [ "${ACTION}"x = "scp"x ] && LogVerbose " FILENAME is: \"${FILENAME}\" "

# check if the admin adapter has to be added to the hostname
#
      case ${HOSTNAME} in

         *a | *a1 | *a2 | *sc0 | *sc | *xscf* )
           HOST_INTERFACE=""
           ;;

         * )
           HOST_INTERFACE="a1"
           ;;
      esac

      if [ -r "${HOST_LIST_FILE}" ] ; then
        LogVerbose "Host list file \"${HOST_LIST_FILE}\" found."
        HOST_LIST="$( cat "${HOST_LIST_FILE}" )
${HOST_LIST}
"
      fi

      CUR_LINE="$( echo "${HOST_LIST}" | egrep -v "^#|^$" | grep -- "^${HOSTNAME}:" | head -1 )"
      if [ "${CUR_LINE}"x != ""x ] ; then
        LogVerbose "Host \"${HOSTNAME}\" found in the host list."
        LogVerbose "  ${CUR_LINE}"
        CUR_HOSTNAME="${CUR_LINE%%:*}"
        [[ ${CUR_HOSTNAME} = dbk* ]] && USE_TICKET=${__TRUE}

        CUR_LINE="${CUR_LINE#*:}"

        CUR_CUSTOMER="${CUR_LINE%%:*}"
        CUR_LINE="${CUR_LINE#*:}"

        CUR_DOMAIN="${CUR_LINE%%:*}"
        CUR_LINE="${CUR_LINE#*:}"

        CUR_HOST_INTERFACE="${CUR_LINE%%:*}"
        CUR_LINE="${CUR_LINE#*:}"        
        
        HOST_INTERFACE="${CUR_HOST_INTERFACE}"
        ProcessCustomer "${CUR_DOMAIN}"


# now process the various customer environments
#
      elif [[ ${PARAMETER_IN_LOWERCASE} == *@hh* ||  ${PARAMETER_IN_LOWERCASE} == hh* ]] ; then
        [ "${ACTION}"x = "scp"x -a "${DEFAULT_SCP_USER_hh}"x != ""x ] && DEFAULT_USER="${DEFAULT_SCP_USER_hh}"
        [ "${ACTION}"x = "ssh"x -a "${DEFAULT_SSH_USER_hh}"x != ""x ] && DEFAULT_USER="${DEFAULT_SSH_USER_hh}"
        [ ${USERNAME_FOUND} = ${__FALSE} -a "${DEFAULT_USER}"x != ""x  ] && USERNAME="${DEFAULT_USER}"
        USE_TICKET=${__FALSE}
        ProcessCustomer "hsp.de.sni.ibm.com"

      elif [[ ${PARAMETER_IN_LOWERCASE} == *@ushen* ||  ${PARAMETER_IN_LOWERCASE} == ushen* ]] ; then
        [ "${ACTION}"x = "scp"x -a "${DEFAULT_SCP_USER_ushen}"x != ""x ] && DEFAULT_USER="${DEFAULT_SCP_USER_ushen}"
        [ "${ACTION}"x = "ssh"x -a "${DEFAULT_SSH_USER_ushen}"x != ""x ] && DEFAULT_USER="${DEFAULT_SSH_USER_ushen}"
        [ ${USERNAME_FOUND} = ${__FALSE} -a "${DEFAULT_USER}"x != ""x  ] && USERNAME="${DEFAULT_USER}"
        USE_TICKET=${__FALSE}
        ProcessCustomer "us.hen.de.sni.ibm.com"

      elif [[ ${PARAMETER_IN_LOWERCASE} == *@hsh* || ${PARAMETER_IN_LOWERCASE} == hsh* ]] ; then
        [ "${ACTION}"x = "scp"x -a "${DEFAULT_SCP_USER_hsh}"x != ""x ] && DEFAULT_USER="${DEFAULT_SCP_USER_hsh}"
        [ "${ACTION}"x = "ssh"x -a "${DEFAULT_SSH_USER_hsh}"x != ""x ] && DEFAULT_USER="${DEFAULT_SSH_USER_hsh}"
        [ ${USERNAME_FOUND} = ${__FALSE} -a "${DEFAULT_USER}"x != ""x  ] && USERNAME="${DEFAULT_USER}"
        USE_TICKET=${__FALSE}
        ProcessCustomer "hsh.de.sni.ibm.com"

      elif [[ ${PARAMETER_IN_LOWERCASE} == *@fms* || ${PARAMETER_IN_LOWERCASE} == fms* ]] ; then
        [ "${ACTION}"x = "scp"x -a "${DEFAULT_SCP_USER_fms}"x != ""x ] && DEFAULT_USER="${DEFAULT_SCP_USER_fms}"
        [ "${ACTION}"x = "ssh"x -a "${DEFAULT_SSH_USER_fms}"x != ""x ] && DEFAULT_USER="${DEFAULT_SSH_USER_fms}"
        [ ${USERNAME_FOUND} = ${__FALSE} -a "${DEFAULT_USER}"x != ""x  ] && USERNAME="${DEFAULT_USER}"
        USE_TICKET=${__FALSE}
        ProcessCustomer "dcrm.fms-sg.de"

      elif [[ ${PARAMETER_IN_LOWERCASE} == dbk* || ${PARAMETER_IN_LOWERCASE} == *@dbk* ]] ; then
        HOST_INTERFACE=""
        [ "${ACTION}"x = "scp"x -a "${DEFAULT_SCP_USER_dbk}"x != ""x ] && DEFAULT_USER="${DEFAULT_SCP_USER_dbk}"
        [ "${ACTION}"x = "ssh"x -a "${DEFAULT_SSH_USER_dbk}"x != ""x ] && DEFAULT_USER="${DEFAULT_SSH_USER_dbk}"
        [ ${USERNAME_FOUND} = ${__FALSE} -a "${DEFAULT_USER}"x != ""x  ] && USERNAME="${DEFAULT_USER}"
        USE_TICKET=${__TRUE}
        ProcessCustomer "rze.de.db.com"

      elif [[ ${PARAMETER_IN_LOWERCASE} == fra* || ${PARAMETER_IN_LOWERCASE} == *@fra* ]] ; then
        HOST_INTERFACE=""
        [ "${ACTION}"x = "scp"x -a "${DEFAULT_SCP_USER_fra}"x != ""x ] && DEFAULT_USER="${DEFAULT_SCP_USER_fra}"
        [ "${ACTION}"x = "ssh"x -a "${DEFAULT_SSH_USER_fra}"x != ""x ] && DEFAULT_USER="${DEFAULT_SSH_USER_fra}"
        [ ${USERNAME_FOUND} = ${__FALSE} -a "${DEFAULT_USER}"x != ""x  ] && USERNAME="${DEFAULT_USER}"
        #USE_TICKET=${__TRUE}
        ProcessCustomer "de.db.com"
      else
        LogVerbose "  This is NOT a hostname parameter."
        [ "${ACTION}"x = "scp"x ] && ADD_PARAMETER="-S ${SSH_WRAPPER} "
        PARAMETER="${PARAMETER} \"$1\" "
      fi
      
    else
# hostname already found in the parameter
      LogVerbose "   Hostname already found in the parameter, nothing to do with this parameter"
      PARAMETER="${PARAMETER} \"$1\" "
    fi

    LogVerbose "  SSH PARAMETER are now: \"${DEFAULT_OPTIONS} ${ADD_PARAMETER} ${PARAMETER}\" "

    shift
  done
fi

LogInfo "Executing now : ${PREFIX} ${REAL_BINARY} ${ADD_PARAMETER} ${PARAMETER}"
${PREFIX} eval ${REAL_BINARY} ${DEFAULT_OPTIONS} ${ADD_PARAMETER} ${PARAMETER}
# ${PREFIX} ${REAL_BINARY} ${DEFAULT_OPTIONS} ${ADD_PARAMETER} ${PARAMETER}

