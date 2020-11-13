#!/usr/bin/ksh
#
# ****  Note: The main code starts after the line containing "main:" ****
#
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
#
# Copyright 2006, 2007 Bernd Schemmer  All rights reserved.
# Use is subject to license terms.

# Notes:
#
# - use "ldm_config.sh {-v} {-v} -h" to get the usage help
#
# - replace "scriptt.sh" with the name of your script
# - change the parts marked with "???" and "??" to your need
#
# - use "ldm_config.sh -H 2 >scriptt.sh.doc" to get the documentation
#
# - this is a Kornshell script - it may not function correctly in other shells
# - the script was written and tested with ksh88 but should also work in ksh93
#
##
# -----------------------------------------------------------------------------
##
## ldm_config.sh - config scripts for LDoms
##
## Author: Bernd Schemmer (Bernd.Schemmer@gmx.de)
##
## Version: see variable ${__SCRIPT_VERSION} below
##          (see variable ${__SCRIPT_TEMPLATE_VERSION} for the template 
##           version used)
##
## Supported OS: Solaris and others
##
##
## Description
## 
## This script provides some additional configuration tasks for LDoms
##
## Configuration file
##
## This script supports a configuration file called <scriptname>.conf.
## The configuration file is searched in the working directory,
## the home directory of the user executing this script and /etc
## (in this order).
##
## The configuration file is read before the parameter are read.
##
## See the variable __CONFIG_PARAMETER below for the possible entries in 
## the config file.
## 
## Predefined parameter
##
## see the subroutines ShowShortUsage and ShowUsage 
##
## Note: The current version of the script template can be found here:
##
##       http://bnsmb.de/solaris/scriptt.html
##
##
## Credits
##       wpollock (http://wikis.sun.com/display/~wpollock)
##         -- http://wikis.sun.com/display/BigAdmin/A+Script+Template+and+Useful+Techniques+for+ksh+Scripts?focusedCommentId=12517624#comment-12517624
##
##      Source for the function PrintWithTimeStamp:
##         Bernd Fingers blog:
##         http://blogs.sun.com/blogfinger/entry/prepend_command_output_lines_with
##
##
## History:
##   01.09.2008 v0.0.0.1 /bs
##     initial release
##   03.09.2008 v0.0.0.2 /bs
##     added the actions
##      list_ldoms
##      stop_domain
##      start_domain
##      restart_domain
##   05.09.2008 v0.0.3 /bs
##     added the actions
##       create_primary_ldom / configure_primary_ldom
##       save_initial_config
##       post_config_ldom
##       check_mac_addresses
##       start_ldom_consoleservice
##    05.10.2008 v0.0.4 /bs
##     added the actions
##       configure_install_network
##
## script template History
## -----------------------
##   1.22.0 08.06.2006 /bs  (BigAdmin Version 1)
##     public release; starting history for the script template
##
##   1.22.1 12.06.2006 /bs
##      added true/false to CheckYNParameter and ConvertToYesNo
## 
##   1.22.2. 21.06.2006 /bs
##      added the parameter -V
##      added the use of environment variables
##      added the variable __NO_TIME_STAMPS
##      added the variable __NO_HEADERS
##      corrected a bug in the function executeCommandAndLogSTDERR
##      added missing return commands
##
##   1.22.3 24.06.2006 /bs
##      added the function StartStop_LogAll_to_logfile
##      added the variable __USE_TTY (used in AskUser)
##      corrected an spelling error (dev/nul instead of /dev/null)
##
##   1.22.4 06.07.2006 /bs
##      corrected a bug in the parameter error handling routine
##
##   1.22.5 27.07.2006 /bs
##      corrected some minor bugs
##
##   1.22.6 09.08.2006 /bs
##      corrected some minor bugs
##
##   1.22.7 17.08.2006 /bs
##      add the CheckParameterCount function
##      added the parameter -T 
##      added long parameter support (e.g --help)
##
##   1.22.8 07.09.2006 /bs
##      added code to save the env variable LANG and set it temporary to C
##
##   1.22.9 20.09.2006 /bs
##      corrected code to save the env variable LANG and set it temporary to C
##   
##   1.22.10 21.09.2006 /bscontent/sunsolve/archives/082007.html
##      cleanup comments
##      the number of temporary files created automatically is now variable 
##        (see the variable __NO_OF_TEMPFILES)
##      added code to install the trap handler in all functions
##
##   1.22.11 19.10.2006 /bs
##      corrected a minor bug in AskUser (/c was not interpreted by echo)
##      corrected a bug in the handling of the parameter -S (-S was ignored)
##
##   1.22.12 31.10.2006 /bs
##      added the variable __REQUIRED_ZONE
##
##   1.22.13 13.11.2006 /bs
##      the template now uses TMP or TEMP if set for the temporary files
##
##   1.22.14 14.11.2006 /bs
##      corrected a bug in the function AskUser (the default was y not n)
##
##   1.22.15 21.11.2006 /bs
##      added initial support for other Operating Systems
##
##   1.22.16 05.07.2007 /bs
##      enhanced initial support for other Operating Systems
##      Support for other OS is still not fully tested!
##
##   1.22.17 06.07.2007 /bs
##      added the global variable __TRAP_SIGNAL
##
##   1.22.18 01.08.2007 /bs
##      __OS_VERSION and __OS_RELEASE were not set - corrected
##
##   1.22.19 04.08.2007 /bs
##      wrong function used to print "__TRAP_SIGNAL is \"${__TRAP_SIGNAL}\"" - fixed
##
##   1.22.20 12.09.2007 /bs
##      the script now checks the ksh version if running on Solaris
##      made some changes for compatibility with ksh93
##
##   1.22.21 18.09.2007 /bs (BigAdmin Version 2)
##      added the variable __FINISHROUTINES
##      changed __REQUIRED_ZONE to __REQUIRED_ZONES
##      added the variable __KSH_VERSION
##      reworked the trap handling
##
##   1.22.22 23.09.2007 /bs 
##      added the signal handling for SIGUSR1 and SIGUSR2 (variables __SIGUSR1_FUNC and __SIGUSR2_FUNC)
##      added user defined function for the signals HUP, BREAK, TERM, QUIT, EXIT, USR1 and USR2
##      added the variables __WARNING_PREFIX, __ERROR_PREFIX,  __INFO_PREFIX, and __RUNTIME_INFO_PREFIX
##      the parameter -T or --tee can now be on any position in the parameters
##      the default output file if called with -T or --tee is now
##        /var/tmp/${0##*/}.$$.tee.log
##
##   1.22.23 25.09.2007 /bs 
##      added the environment variables __INFO_PREFIX, __WARNING_PREFIX,
##      __ERROR_PREFIX, and __RUNTIME_INFO_PREFIX
##      added the environment variable __DEBUG_HISTFILE
##      reworked the function to print the usage help :
##      use "-h -v" to view the extented usage help and use "-h -v -v" to 
##          view the environment variables used also
##
##   1.22.24 05.10.2007 /bs 
##      another minor fix for ksh93 compatibility
## 
##   1.22.25 08.10.2007 /bs 
##      only spelling errors corrected
##
##   1.22.26 19.11.2007 /bs 
##      only spelling errors corrected
##
##   1.22.27 29.12.2007 /bs 
##      improved the code to create the lockfile (thanks to wpollock for the info; see credits above)
##      improved the code to create the temporary files (thanks to wpollock for the info; see credits above)
##      added the function rand (thanks to wpollock for the info; see credits above)
##      the script now uses the directory name saved in the variable $TMPDIR for temporary files 
##      if it's defined
##      now the umask used for creating temporary files can be changed (via variable __TEMPFILE_UMASK)
##
##   1.22.28 12.01.2008 /bs 
##      corrected a syntax error in the show usage routine
##      added the function PrintWithTimestamp (see credits above)
##
##   1.22.29 31.01.2008 /bs 
##      there was a bug in the new code to remove the lockfile which prevented
##      the script from removing the lockfile at program end
##      if the lockfile already exist the script printed not the correct error
##      message
##
##
##   1.22.30 28.02.2008 /bs 
##      Info update: executeCommandAndLog does NOT return the RC of the executed
##      command if a logfile is defined
##      added inital support for CYGWIN 
##      (tested with CYGWIN_NT-5.1 v..1.5.20(0.156/4/2)
##      Most of the internal functions are NOT tested yet in CYGWIN
##      GetCurrentUID now supports UIDs greater than 254; the function now prints the UID to STDOUT  
##      Corrected bug in GetUserName (only a workaround, not the solution)
##      now using printf in the AskUserRoutine
##
##   1.22.30 28.02.2008 /bs 
##      The lockfile is now also deleted if the script crashes because of a syntax error or something like this
##
##   1.22.31 18.03.2008 /bs 
##     added the version number to the start and end messages
##     an existing config file is now removed (and not read) if the script is called with -C to create a config file
##
##   1.22.32 04.04.2008 /bs 
##     minor changes for zone support
##
## ----------------
## Version variables
##
## __SCRIPT_VERSION - the version of your script 
##
#  Note: CYGWIN ksh does not like typeset -r
##
typeset  __SCRIPT_VERSION="v0.0.0.4"
##

## __SCRIPT_TEMPLATE_VERSION - version of the script template
##
typeset  __SCRIPT_TEMPLATE_VERSION="1.22.31 18.03.2008"
##

## ----------------
##
## Predefined return codes:
##
##    1 - show usage and exit
##    2 - invalid parameter found
##
##  210 - 237 reserved for the runtime system
##  238 - unsupported Operating system
##  239 - script runs in a not supported zone
##  240 - internal error
##  241 - a command ended with an error (set -e is necessary to activate this trap)
##  242 - the current user is not allowed to execute this script
##  243 - invalid machine architecture
##  244 - invalid processor type
##  245 - invalid machine platform
##  246 - error writing the config file
##  247 - include script not found
##  248 - unsupported OS version
##  249 - Script not executed by root
##  250 - Script is already running
##
##  251 - QUIT signal received
##  252 - User break
##  253 - TERM signal received
##  254 - unknown external signal received
##

## ----------------
## Used environment variables
##
#
# The variable __USED_ENVIRONMENT_VARIABLES is used in the function ShowUsage
#
__USED_ENVIRONMENT_VARIABLES="
## __DEBUG_CODE
## __RT_VERBOSE_LEVEL
## __QUIET_MODE
## __VERBOSE_MODE
## __VERBOSE_LEVEL
## __OVERWRITE_MODE
## __USER_BREAK_ALLOWED
## __NO_TIME_STAMPS
## __NO_HEADERS
## __USE_COLORS
## __USE_RBAC
## __TEE_OUTPUT_FILE
## __INFO_PREFIX
## __WARNING_PREFIX
## __ERROR_PREFIX
## __RUNTIME_INFO_PREFIX
## __DEBUG_HISTFILE
"

#
# binaries and scripts used in this script:
#
# basename cat cp cpio cut date dd dirname expr find grep id ln ls nawk prtdiag pwd 
# reboot rm sed sh tee touch tty umount uname who zonename
#
# /usr/bin/pfexec
# /usr/ucb/whoami or $( whence whoami )
# /usr/openwin/bin/resize or $( whence resize )
#
# AIX: oslevel
#

# -----------------------------------------------------------------------------

# variables for the trap handler

__FUNCTION="main"

# alias to install the trap handler
#
# Note: The statement LINENO=${LINENO} is necessary to use the variable LINENO in the trap command
#
alias __settrap="  
  LINENO=\${LINENO}
  trap 'GENERAL_SIGNAL_HANDLER SIGHUP    \${LINENO} \${__FUNCTION}' 1
  trap 'GENERAL_SIGNAL_HANDLER SIGINT    \${LINENO} \${__FUNCTION}' 2
  trap 'GENERAL_SIGNAL_HANDLER SIGQUIT   \${LINENO} \${__FUNCTION}' 3
  trap 'GENERAL_SIGNAL_HANDLER SIGTERM   \${LINENO} \${__FUNCTION}' 15
  trap 'GENERAL_SIGNAL_HANDLER SIGUSR1   \${LINENO} \${__FUNCTION}' USR1
  trap 'GENERAL_SIGNAL_HANDLER SIGUSR2   \${LINENO} \${__FUNCTION}' USR2
"



##
## ----------------
## ##### general hints
##
## Do not use variable names beginning with __ (these are reserved for
## internal use)
##


# -----------------------------------------------------------------------------
## __KSH_VERSION - ksh version (either 88 or 93)
##
  __KSH_VERSION=88 ; f() { typeset __KSH_VERSION=93 ; } ; f ; 

# save the language setting and switch the language temporary to C
#
__SAVE_LANG="${LANG}"
LANG=C
export LANG

# -----------------------------------------------------------------------------
## ##### constants
##
## __TRUE - true (0)
## __FALSE - false (1)
##
#  Note: CYGWIN ksh does not like typeset -r
##
typeset  __TRUE=0
typeset  __FALSE=1


## ----------------
## __OS - Operating system (e.g. SunOS)
##
__OS="$( uname -s )"

case ${__OS} in 
  CYGWIN* )  set +o noclobber
     ;;

  * )
     :
     ;;

esac

## ----------------
## internal variables
##
## __TRAP_SIGNAL - current trap caught by the trap handler
##   This is a global variable that can be used in the exit routines
##
__TRAP_SIGNAL=""


# -----------------------------------------------------------------------------
## __USE_RBAC - set this variable to ${__TRUE} to execute this script 
##   with RBAC
##   default is ${__FALSE}
##
##   Note: You can also set this environment variable before starting the script
##
__USE_RBAC=${__USE_RBAC:=${__FALSE}}


# -----------------------------------------------------------------------------
## __TEE_OUTPUT_FILE - name of the output file if called with the parameter -T
##   default: var/tmp/$( basename $0 ).$$.tee.log
##
##   Note: You can also set this environment variable before starting the script
##
__TEE_OUTPUT_FILE="${__TEE_OUTPUT_FILE:=/var/tmp/${0##*/}.$$.tee.log}"

# -----------------------------------------------------------------------------
# use the parameter --tee to automatically call the script and pipe 
# all output to tee

if [ "${__PPID}"x = ""x ] ; then
  __PPID=$PPID ; export __PPID
  if [[ \ $*\  == *\ -T* || \ $*\  == *\ --tee\ * ]] ; then
    echo "Saving STDOUT and STDERR to \"${__TEE_OUTPUT_FILE}\" ..."
    exec $0 $@ 2>&1 | tee -a "${__TEE_OUTPUT_FILE}"
    __MAINRC=$?
    echo "STDOUT and STDERR saved in \"${__TEE_OUTPUT_FILE}\"."
    exit ${__MAINRC}    
  fi
fi

[ "${__PPID}"x = ""x ] && __PPID=$PPID ; export __PPID

# -----------------------------------------------------------------------------
#
# Set the variable ${__USE_RBAC} to ${__TRUE} to activate RBAC support
#
# Allow the use of RBAC to control who can access this script. Useful for
# administrators without root permissions
#
if [ "${__USE_RBAC}" = "${__TRUE}" ] ; then
  if [ "$_" != "/usr/bin/pfexec" -a -x /usr/bin/pfexec ]; then
    /usr/bin/pfexec $0 $*
    exit $?
  else
    echo "${0%%*/} ERROR: /usr/bin/pfexec not found or not executable!" >&2 
    exit 238 
  fi
fi

# -----------------------------------------------------------------------------
## 
## ##### defined variables that may be changed
##


## __DEBUG_CODE - code executed at start of every sub routine
##   Note: Use always "__DEBUG_CODE="eval ..." if you want to use variables or aliases
##         Default debug code : none
##
#  __DEBUG_CODE='eval echo $__FUNCTION'

## __FUNCTION_INIT - code executed at start of every sub routine
##   (see the hints for __DEBUG_CODE)
##         Default init code : install the trap handlers
##

if [[ ${__OS} == CYGWIN* ]] ; then
  __FUNCTION_INIT=""
else   
  __FUNCTION_INIT=" eval __settrap"
fi
 

##
## sample debug code:
## __DEBUG_CODE="  eval echo Entering the subroutine \${__FUNCTION} ...  "
##
## Note: Use an include script for more complicate debug code, e.g.
## __DEBUG_CODE=" eval . /var/tmp/mydebugcode"
##

## __CONFIG_PARAMETER
##   The variable __CONFIG_PARAMETER contains the configuration variables
##
## The defaults for these variables are defined here. You 
## can use a config file to overwrite the defaults. 
##
## Use the parameter -C to create a default configuration file
##
## Note: The config file is read and interpreted via ". configfile"  
##       therefore you can also add some code her
##
__CONFIG_PARAMETER='

# extension for backup files
  DEFAULT_BACKUP_EXTENSION=".$$.backup"

# default values for the parameter

# parameter -d
  DEFAULT_LDOMS_TO_PROCESS="primary"

# parameter -x
  DEFAULT_LDOM_TASKS=""

# parameter -o
  DEFAULT_LDOM_OUTPUT_FILE=""

# parameter -s
  DEFAULT_LDOM_SCRIPT_FILE=""

# parameter -c
  DEFAULT_CURRENT_COMMENT=""

# parameter -a
  DEFAULT_PROCESS_ALL_GUEST_LDOMS=${__FALSE}

# no parameter defined for the following variables:

  DEFAULT_LDM_SAVE_DIR="${LDM_SAVE_DIR:=/var/db/ldom}"

  DEFAULT_LDM_CONFIG_NAME="${LDM_CONFIG_NAME:=production}"

# only change the following variables if you know what you are doing #

# no further internal variables defined yet
#
# Note you can redefine any variable that is initialized before calling
# ReadConfigFile here!
'
# end of config parameters


## __SHORT_DESC - short description (for help texts, etc)
##   Change to your need
##
#  Note: CYGWIN ksh does not like typeset -r
##
typeset  __SHORT_DESC="LDom configuration script"

## __LONG_USAGE_HELP - Additional help if the script is called with 
##   the parameter "-v -h"
##
##   Note: To use variables in the help text use the variable name without
##         an escape character, eg. ${OS_VERSION}
##
__LONG_USAGE_HELP='

      -d ldom_name
         Define the LDom to process
         Long format: --ldom
         Current value: ${LDOMS_TO_PROCESS}

      -c comment
         Define a comment for the script file 
         (only used for tasks that change the configuration!)
         Long format: --comment
         Current value: ${CUR_COMMENT}

      -x task 
         Define the tasks to execute for the current LDom
         Long format: --task
         Current value: ${LDOM_TASKS}
         
         Known tasks to view the configuration:
          list_ldoms
            list the status of one or more ldoms
          list_vdisks
          list_vdisks_verbose
            list all vdisks defined for a LDom
          list_vdiskserverdevices_verbose
            list all vdiskserverdevices defined for a LDom
          list_vnets
          list_vnets_verbose
          list_vnets_table
            list all vnets defined for a LDom
          list_vswitches
          list_vswitches_verbose
            list all vswitches defined for a LDom
          list_vnets_mac
            list the mac addressees for the vnets defined for a LDom
           check_mac_addresses
            check the mac addresses of the virtual switches
            
         Known tasks to change the configuration:
          configure_primary_ldom
            configure the primary LDom with the recommended configuration

          set_vswitches_mac_address
            configure the mac addresses of the vswitches to be equal with
            the mac addresses of the attached network adapters
            
          configure_vswitches
            create the /etc/hostname.vsw* files for the vswitches and remove the
            files /etc/hostname.<adaptername> for the attached network adapter
            
          activate_vswitches
            plumb and configure the vswitches for which a /etc/hostname.vsw* exists
            and unplumb the attached physical network adapters
            
          configure_network_adapters
            create the file /etc/hostname.<adaptername> for the network adapters which
            are attached to a vswitch and remove the existing configuration files
            for the vswitches (/etc/hostname.vsw*)

          activate_network_adapters
            plumb and configure the network adapters for which a /etc/hostname.<adaptername>
            exists and unplumb the vswitches to which these adapters are attached 

          reconfigure_vnets
            remove the vnets from te LDom and reattach them

          reattach_vdisks
            not implemented yet!

          start_ldom_consoleservice
            start the console service for Guest LDoms

          list_ldoms
            view the status of a LDom
            
          stop_domain
            stop a LDom
            
          start_domain
            start a LDom
            
          restart_domain
            stop and start a LDom
            
          save_config
            save the current LDom configuration to XML files and to the nvram
            Notes: 
              Set the environment variable LDM_SAVE_DIR before calling
              the script to change the directory for the ldom configuration 
              The current value is: "${LDM_SAVE_DIR}"
              Set the environment variable LDM_CONFIG_NAME before calling
              the script to change the name of the ldom configuration 
              The current value is: "${LDM_CONFIG_NAME}"
            The parameter -s is NOT supported for this task!
            
          save_initial_config
            saves the initial LDom configuration with the name "initial"
            The parameter -s is NOT supported for this task!

          post_config_ldom
            execute post configuration tasks for Guest LDoms
            Note: This task needs root access via ssh to the Guest LDom!

          configure_install_network
            configure the installation network adapter with the values from the
            nvarmrc variable network-boot-argumnets

          configure_primary_network 
            this is an alias for the tasks
              set_vswitches_mac_address configure_vswitches activate_vswitches

      -o outputfile
         Define the output file for the command output for tasks that only 
         list the configuration

      -s scriptfile
         Write the commands to execute into the file scriptfile instead of
         executing them.
         The tasks to change the configuration will only write the commands
         to the script file if -s is used!

         Long format: --scriptfile
         Current value: ${LDOM_SCRIPT_FILE}

      -A process all guest ldoms
         Long format: --all_guestldoms
         Current value: $( ConvertToYesNo ${PROCESS_ALL_GUEST_LDOMS} )

'

## __SHORT_USAGE_HELP - Additional help if the script is called with the parameter "-h"
##
##   Note: To use variables in the help text use the variable name without an escape
##         character, eg. ${OS_VERSION}
##
__SHORT_USAGE_HELP='
                    [-d ldom] -x task [...] [-s scriptfile] [-o outputfile] [-A|+A] [-c comment]

Known tasks:

list_vdisks list_vdisks_verbose list_vdiskserverdevices_verbose
list_vnets list_vnets_verbose list_vnets_table list_vswitches list_vswitches_verbose 
list_vnets_mac check_mac_addresses

set_vswitches_mac_address reconfigure_vnets
configure_vswitches configure_network_adapters activate_vswitches activate_network_adapters

save_config save_initial_config

list_ldoms stop_domain start_domain restart_domain 
post_config_ldom  start_ldom_consoleservice

configure_primary_network 
configure_install_network
'

## __MUST_BE_ROOT - run script only by root (def.: false)
##   set to ${__TRUE} for scripts that must be executed by root only
##
__MUST_BE_ROOT=${__TRUE}

## __REQUIRED_USERID - required userid to run this script (def.: none)
##   use blanks to separate multiple userids
##   e.g. "oracle dba sysdba"
##   "" = no special userid required
##
__REQUIRED_USERID=""

## __REQUIRED_ZONES - required zones (either global, non-global or local 
##    or the names of the valid zones)
##   (def.: none) 
##   "" = no special zone required
##
__REQUIRED_ZONES="global"

## __ONLY_ONCE - run script only once at a time (def.: false)
##   set to ${__TRUE} for scripts that can not run more than one instance at 
##   the same time
##
__ONLY_ONCE=${__TRUE}

## __ REQUIRED_OS - required OS (uname -s) for the script (def.: none)
##    use blanks to separate the OS names if the script runs under multiple OS
##    e.g. "SunOS"
##
__REQUIRED_OS="SunOS"


## __REQUIRED_OS_VERSION - required OS version for the script (def.: none)
##   minimum OS version necessary, e.g. 5.10
##   "" = no special version necessary
##
__REQUIRED_OS_VERSION=""

## __REQUIRED_MACHINE_PLATFORM - required machine platform for the script (def.: none)
##   required machine platform (uname -i) , e.g "i86pc"; use blanks to separate 
##   the multiple machine types, e.g "Sun Fire 3800 i86pc"
##   "" = no special machine type necessary
##
__REQUIRED_MACHINE_PLATFORM=""

## __REQUIRED_MACHINE_CLASS - required machine class for the script (def.: none)
##   required machine class (uname -m) , e.g "i86pc" ; use blanks to separate  
##   the multiple machine classes, e.g "sun4u i86pc"
##   "" = no special machine class necessary
##
__REQUIRED_MACHINE_CLASS="sun4v"

## __REQUIRED_MACHINE_ARC - required machine architecture for the script (def.: none)
##   required machine architecture (uname -p) , e.g "i386" ; use blanks to separate 
##   the machine architectures if more than one entry, e.g "sparc i386"
##   "" = no special machine architecture necessary
##
__REQUIRED_MACHINE_ARC=""

## __VERBOSE_LEVEL - count of -v parameter (def.: 0)
##
##   Note: You can also set this environment variable before starting the script
##
typeset -i __VERBOSE_LEVEL=${__VERBOSE_LEVEL:=0}

## __RT_VERBOSE_LEVEL - level of -v for runtime messages (def.: 1)
##
##   e.g. 1 = -v -v is necessary to print info messages of the runtime system
##        2 = -v -v -v is necessary to print info messages of the runtime system
##
##   Note: You can also set this environment variable before starting the script
##
typeset -i __RT_VERBOSE_LEVEL=${__RT_VERBOSE_LEVEL:=1}

## __QUIET_MODE - do not print messages to STDOUT (def.: false)
##   use the parameter -q/+q to change this variable
##
##   Note: You can also set this environment variable before starting the script
##
__QUIET_MODE=${__QUIET_MODE:=${__FALSE}}

## __VERBOSE_MODE - print verbose messages (def.: false)
##   use the parameter -v/+v to change this variable  
##
##   Note: You can also set this environment variable before starting the script
##
__VERBOSE_MODE=${__VERBOSE_MODE:=${__FALSE}}

## __NO_TIME_STAMPS - Do not use time stamps in the messages (def.: false)
##
##   Note: You can also set this environment variable before starting the script
##
__NO_TIME_STAMPS=${__NO_TIME_STAMPS:=${__FALSE}}

## __NO_HEADERS - Do not print headers and footers (def.: false)
##
##   Note: You can also set this environment variable before starting the script
##
__NO_HEADERS=${__NO_HEADERS:=${__FALSE}}

## __FORCE - do the action anyway (def.: false)
##   If this variable is set to ${__TRUE} the function "die" will return 
##   if called with an RC not zero (instead of aborting the script)
##   use the parameter -f/+f to change this variable
##
__FORCE=${__FALSE}

## __USE_COLORS - use colors (def.: false) 
##   use the parameter -a/+a to change this variable
##
##   Note: You can also set this environment variable before starting the script
##
__USE_COLORS=${__USE_COLORS:=${__FALSE}}

## __USER_BREAK_ALLOWED - CTRL-C aborts the script or not (def.: true)
##   (no parameter to change this variable)
##
##   Note: You can also set this environment variable before starting the script
##
__USER_BREAK_ALLOWED=${__USER_BREAK_ALLOWED:=${__TRUE}}

## __NOECHO - turn echo off while reading input from the user
##   do not echo the user input in AskUser if __NOECHO is set to ${__TRUE}
##
__NOECHO=${__FALSE}

## __USE_TTY - write prompts and read user input from /dev/tty (def.: false)
##   If __USE_TTY is ${__TRUE} the function AskUser writes the prompt to /dev/tty 
##   and the reads the user input from /dev/tty . This is useful if STDOUT is 
##   redirected to a file.
##
__USE_TTY=${__FALSE}

## __OVERWRITE mode - overwrite existing files or not (def.: false)
##   use the parameter -O/+O to change this variable
##
##   Note: You can also set this environment variable before starting the script
##
__OVERWRITE_MODE=${__OVERWRITE_MODE:=${__FALSE}}

## __DEBUG_MODE - use single step mode for main (def.: false)
##   use the parameter -D/+D to change this variable
##
__DEBUG_MODE=${__FALSE}
__SCRIPT_ARRAY[0]=0

## __TEMPDIR - directory for temporary files
##   The default is $TMPDIR (if defined), or $TMP (if defined), 
##   or $TEMP (if defined) or /tmp if none of the variables is
##   defined
##
__TEMPDIR="${TMPDIR:-${TMP:-${TEMP:-/tmp}}}"

## __NO_OF_TEMPFILES
##   number of automatically created tempfiles that are deleted at program end
##   (def. 2)
##   Note: The variable names for the tempfiles are __TEMPFILE1, __TEMPFILE2, etc.
##
__NO_OF_TEMPFILES=2

## __TEMPFILE_UMASK 
##   umask for creating temporary files (def.: 177)
##
__TEMPFILE_UMASK=177

## __LIST_OF_TMP_MOUNTS - list of mounts that should be umounted at program end
##
__LIST_OF_TMP_MOUNTS=""

## __LIST_OF_TMP_DIRS - list of directories that should be removed at program end
##
__LIST_OF_TMP_DIRS=""

## __LIST_OF_TMP_FILES - list of files that should be removed at program end
##
__LIST_OF_TMP_FILES=""

## __EXITROUTINES - list of routines that should be executed before the script ends
##   Note: These routines are called *before* temp files, temp directories, and temp 
##         mounts are removed
##
__EXITROUTINES=""

## __FINISHROUTINES - list of routines that should be executed before the script ends
##   Note: These routines are called *after* temp files, temp directories, and temp
##         mounts are removed
##
__FINISHROUTINES=""

## __SIGNAL_SIGUSR1_FUNCTION  - name of the function to execute if the signal SIGUSR1 is received
##   default signal handling: none
##
 __SIGNAL_SIGUSR1_FUNCTION=""

## __SIGNAL_SIGUSR2_FUNCTION  - name of the function to execute if the signal SIGUSR2 is received
##   default signal handling: none
##
 __SIGNAL_SIGUSR2_FUNCTION=""

## __SIGNAL_SIGHUP_FUNCTION  - name of the function to execute if the signal SIGHUP is received
##   default signal handling: switch the verbose mode on or off
##   If a user defined function ends with a return code not equal zero the default 
##   action fro the SIGHUP signal is not executed.
##
 __SIGNAL_SIGHUP_FUNCTION=""

## __SIGNAL_SIGINT_FUNCTION  - name of the function to execute if the signal SIGINT is received
##   default signal handling: end the script if __USER_BREAK_ALLOWED is ${__TRUE} else ignore the signal
##   If a user defined function ends with a return code not equal zero the default 
##   action for the SIGINT signal is not executed.
##
 __SIGNAL_SIGINT_FUNCTION=""

## __SIGNAL_SIGQUIT_FUNCTION  - name of the function to execute if the signal SIGQUIT is received
##   default signal handling: end the script
##   If a user defined function ends with a return code not equal zero the default 
##   action for the SIGQUIT signal is not executed.
##
 __SIGNAL_SIGQUIT_FUNCTION=""

## __SIGNAL_SIGTERM_FUNCTION  - name of the function to execute if the signal SIGTERM is received
##   default signal handling: end the script
##   If a user defined function ends with a return code not equal zero the default 
##   action for the SIGTERM signal is not executed.
##
 __SIGNAL_SIGTERM_FUNCTION=""

## __REBOOT_REQUIRED - set to true to reboot automatically at 
##   script end (def.: false)
##
__REBOOT_REQUIRED=${__FALSE}

## __REBOOT_PARAMETER - parameter for the reboot command (def.: none)
##
__REBOOT_PARAMETER=""

## __INFO_PREFIX - prefix for INFO messages printed if __VERBOSE_MODE = ${__TRUE}
##   default: "INFO: "
##
__INFO_PREFIX="${__INFO_PREFIX:-INFO: }"

## __WARNING_PREFIX - prefix for WARNING messages 
##   default: "WARNING: "
##
__WARNING_PREFIX="${__WARNING_PREFIX:-WARNING: }"

## __ERROR_PREFIX - prefix for ERROR messages 
##   default: "ERROR: "
##
__ERROR_PREFIX="${__ERROR_PREFIX:-ERROR: }"

## __RUNTIME_INFO_PREFIX - prefix for INFO messages of the runtime system
##   default: "RUNTIME INFO: "
##
__RUNTIME_INFO_PREFIX="${__RUNTIME_INFO_PREFIX:-RUNTIME INFO: }"

## __PRINT_LIST_OF_WARNINGS_MSGS - print the list of warning messages at program end (def.: false)
##
__PRINT_LIST_OF_WARNINGS_MSGS=${__FALSE}

## __PRINT_LIST_OF_ERROR_MSGS - print the list of error messages at program end (def.: false)
##
__PRINT_LIST_OF_ERROR_MSGS=${__FALSE}

## __PRINT_SUMMARIES - print error/warning msg summaries at script end
##
##   print error and/or warning message summaries at program end
##   known values:
##       0 = do not print summaries
##       1 = print error msgs,
##       2 = print warning msgs
##       3 = print error and warning mgs
##   use the parameter -S to change this variable
##
__PRINT_SUMMARIES=0

## __MAINRC - return code of the program 
##
__MAINRC=0


# -----------------------------------------------------------------------------
#

# -----------------------------------------------------------------------------
# init the global variables
#

## ##### defined variables that should not be changed
##

# init the variable for the TRAP handlers  
#   __INCLUDE_SCRIPT_RUNNING contains the name of the included script if 
#   a sourced-in script is currently running
#
__INCLUDE_SCRIPT_RUNNING=""

# 
# internal variables for push/pop
#
typeset -i __STACK_POINTER=0
__STACK[0]=${__STACK_POINTER}

#
# internal variables for the single-step routine
#
typeset -i __BREAKPOINT_LINE=0 
typeset -i __STEP_COUNT=0
typeset -i __TRACE_COUNT=0

__DEBUG_HISTFILE="${__DEBUG_HISTFILE:-/tmp/ksh.history.$$}"

# delete the history file used in the debug routine at program end
__LIST_OF_TMP_FILES="${__LIST_OF_TMP_FILES} ${__DEBUG_HISTFILE}"

# variable used for input by the user
#
__USER_RESPONSE_IS=""

# __STTY_SETTINGS
#   saved stty settings before switching off echo in AskUser
#
__STTY_SETTINGS=""

## __SCRIPTNAME - name of the script without the path
##
#  Note: CYGWIN ksh does not like typeset -r
##
typeset  __SCRIPTNAME="${0##*/}"

## __SCRIPTDIR - path of the script (as entered by the user!)
##
__SCRIPTDIR="${0%/*}"

## __REAL_SCRIPTDIR - path of the script (real path, maybe a link)
##
__REAL_SCRIPTDIR=$( cd -P -- "$(dirname -- "$(command -v -- "$0")")" && pwd -P )

## __CONFIG_FILE - name of the config file
##   (use ReadConfigFile to read the config file; 
##   use WriteConfigFile to write it)
##
__CONFIG_FILE="${__SCRIPTNAME%.*}.conf"

## __HOSTNAME - hostname 
##
__HOSTNAME="$( uname -n )"

## __NODENAME - nodename 
##
__NODENAME=${__HOSTNAME}
[ -f /etc/nodename ] && __NODENAME="$( cat /etc/nodename )"



## __OS_FULLNAME - Operating system (e.g. CYGWIN_NT-5.1)
##   (only used for CYGWIN at this time)
##
__OS_FULLNAME=""

## __ZONENAME - name of the current zone if running in Solaris 10 or newer
## 

## __OS_VERSION - Operating system version (e.g 5.8)
##

## __OS_RELEASE - Operating system release (e.g. Generic_112233-08)
##

## __MACHINE_CLASS - Machine class (e.g sun4u)
##

## __MACHINE_PLATFORM - hardware platform (e.g. SUNW,Ultra-4)
##

## __MACHINE_SUBTYPE - machine type (e.g  Sun Fire 3800)
##

## __MACHINE_ARC - machine architecture (e.g. sparc)
##

## __RUNLEVEL - current runlevel
##
# __RUNLEVEL="$( set -- $( who -r )  ; echo $7 )"

case ${__OS} in

    "SunOS" ) 
       __ZONENAME="$( zonename 2>/dev/null )" 
       __OS_VERSION="$( uname -r )" 
       __OS_RELEASE="$( uname -v )"
       __MACHINE_CLASS="$( uname -m )"
       __MACHINE_PLATFORM="$( uname -i )"
       if [ "${__ZONENAME}"x = ""x  -o  "${__ZONENAME}"x = "global"x  -a "${__MACHINE_CLASS}"x  != "sun4v"x  ] ; then
         [  -x /usr/platform/${__MACHINE_PLATFORM}/sbin/prtdiag ] &&   \
           ( set -- $( /usr/platform/${__MACHINE_PLATFORM}/sbin/prtdiag | grep "System Configuration" ) ; shift 5; echo $* ) 2>/dev/null | read  __MACHINE_SUBTYPE
        else
          __MACHINE_SUBTYPE=""
        fi
         __MACHINE_ARC="$( uname -p )"
       __RUNLEVEL=$( who -r  2>/dev/null | tr -s " " | cut -f8 -d " " ) 
       ;;
     
    "AIX" ) 
       __ZONENAME=""
       __MACHINE_PLATFORM="$( oslevel )" 
       __OS_VERSION="$( oslevel -r )"
       __OS_RELEASE="$( uname -v )"
       __MACHINE_CLASS="$( uname -m )"
       __MACHINE_PLATFORM="$( uname -M )"
       __MACHINE_SUBTYPE=""
       __MACHINE_ARC="$( uname -p )"
       __RUNLEVEL=$( who -r  2>/dev/null | tr -s " " | cut -f8 -d " " ) 
       ;;

      
    "Linux" ) 
       __ZONENAME=""
       __OS_VERSION="$( uname -r )"
       __OS_RELEASE="$( uname -v )" 
       __MACHINE_CLASS="$( uname -m )"
       __MACHINE_PLATFORM="$( uname -i )"
       __MACHINE_SUBTYPE=""
       __MACHINE_ARC="$( uname -p )"
       __RUNLEVEL=$( who -r  2>/dev/null | tr -s " " | cut -f3 -d " " ) 
       ;;

     CYGWIN* )
       __OS_FULLNAME="$__OS"
       __OS="CYGWIN"
       __ZONENAME=""
       __OS_VERSION="$( uname -r )"
       __OS_RELEASE="$( uname -v )" 
       __MACHINE_CLASS="$( uname -m )"
       __MACHINE_PLATFORM="$( uname -i )"
       __MACHINE_SUBTYPE=""
       __MACHINE_ARC="$( uname -p )"
       __RUNLEVEL=$( who -r  2>/dev/null )
       ;;

     
    * ) 
       __ZONENAME=""
       __MACHINE_PLATFORM=""
       __MACHINE_CLASS="" 
       __MACHINE_PLATFORM=""
       __MACHINE_SUBTYPE=""
       __MACHINE_ARC=""
       __RUNLEVEL="?"
       ;;
     
esac


## __START_DIR - working directory when starting the script
##
__START_DIR="$( pwd )"

## __LOGFILE - fully qualified name of the logfile used
##   use the parameter -l to change the logfile
##
if [ -d /var/tmp ] ; then
  __DEF_LOGFILE="/var/tmp/${__SCRIPTNAME%.*}.LOG"
else
  __DEF_LOGFILE="/tmp/${__SCRIPTNAME%.*}.LOG"
fi

__LOGFILE="${__DEF_LOGFILE}"

# __GLOBAL_OUTPUT_REDIRECTION
#   status variable used by StartStop_LogAll_to_logfile
#
__GLOBAL_OUTPUT_REDIRECTION=""

     
# lock file (used if ${__ONLY_ONCE} is ${__TRUE})
# Note: This is only a symbolic link
#
__LOCKFILE="/tmp/${__SCRIPTNAME}.lock"
__LOCKFILE_CREATED=${__FALSE}

## __NO_OF_WARNINGS - Number of warnings found
##
typeset -i __NO_OF_WARNINGS=0

## __LIST_OF_WARNINGS - List of warning messages
##
__LIST_OF_WARNINGS=""

## __NO_OF_ERRORS - Number of errors found
##
typeset -i __NO_OF_ERRORS=0

## __LIST_OF_ERRORS - List of error messages
##
__LIST_OF_ERRORS=""

## __LOGON_USERID - ID of the user opening the session  
##
__LOGIN_USERID="$( set -- $( who am i 2>/dev/null ) ; echo $1 )"
[ "${__LOGIN_USERID}"x = ""x ] && __LOGIN_USERID="${LOGNAME}"

## __USERID - ID of the user executing this script (e.g. xtrnaw7)
##
__USERID="${__LOGIN_USERID}"
if [ "${__OS}"x = "SunOS"x ] ; then
  [ -x /usr/ucb/whoami ] && __USERID="$( /usr/ucb/whoami )"
else
  __USERID="$( whoami )"
fi


# -----------------------------------------------------------------------------
# color variables

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

##
## Colorattributes:
## __COLOR_OFF, __COLOR_BOLD, __COLOR_NORMAL, - normal, __COLOR_UNDERLINE
## __COLOR_BLINK, __COLOR_REVERSE, __COLOR_INVISIBLE
##

__COLOR_BOLD="\033[1m"
__COLOR_NORMAL="\033[2m"
__COLOR_UNDERLINE="\033[4m"
__COLOR_BLINK="\033[5m"
__COLOR_REVERSE="\033[7m"
__COLOR_INVISIBLE="\033[8m"
__COLOR_OFF="\033[0;m"


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
## ##### defined sub routines
##

## --------------------------------------
## ReadConfigFile
##
## read the config file
##
## usage: ReadConfigFile [configfile]
##
## where:   configfile - name of the config file
##          default: search ${__CONFIG_FILE} in the current directory,
##          in the home directory, and in /etc (in this order)
##
## returns: ${__TRUE} - ok config read
##          ${__FALSE} - error config file not found or not readable
##
function ReadConfigFile {
  typeset __FUNCTION="ReadConfigFile"; ${__FUNCTION_INIT} ; ${__DEBUG_CODE}

  typeset THIS_CONFIG="$1"
  typeset THISRC=${__FALSE}
  
  if [ "${THIS_CONFIG}"x = ""x ] ; then
    THIS_CONFIG="./${__CONFIG_FILE}"
    [ ! -f "${THIS_CONFIG}" ] && THIS_CONFIG="${HOME}/${__CONFIG_FILE}"
    [ ! -f "${THIS_CONFIG}" ] && THIS_CONFIG="/etc/${__CONFIG_FILE}"
  fi

  if [ -f "${THIS_CONFIG}" ] ; then
    LogHeader "Reading the config file \"${THIS_CONFIG}\" ..." 

    includeScript "${THIS_CONFIG}"

    THISRC=${__TRUE}    
  else
    LogHeader "No config file (\"${__CONFIG_FILE}\") found (use -C to create a default config file)"
  fi

  return ${THISRC}
}

## --------------------------------------
## WriteConfigFile
##
## write the variable ${__CONFIG_PARAMETER} to the config file
##
## usage: WriteConfigFile [configfile]
##
## where:  configfile - name of the config file
##         default: write ${__CONFIG_FILE} in the current directory
##
## returns: ${__TRUE} - ok config file written
##          ${__FALSE} - error writing the config file
##
function WriteConfigFile {
  typeset __FUNCTION="WriteConfigFile" ; ${__FUNCTION_INIT} ; ${__DEBUG_CODE} 

  typeset THIS_CONFIG_FILE="$1"
  typeset THISRC=${__FALSE}
  
  [ "${THIS_CONFIG_FILE}"x = ""x ] && THIS_CONFIG_FILE="./${__CONFIG_FILE}"

  [ -f "${THIS_CONFIG_FILE}" ] &&  BackupFileIfNecessary "${THIS_CONFIG_FILE}"
  LogMsg "Writing the config file \"${THIS_CONFIG_FILE}\" ..." 
   
cat <<EOT >"${THIS_CONFIG_FILE}"
# config file for ${__SCRIPTNAME} ${__SCRIPT_VERSION}, created $( date )

${__CONFIG_PARAMETER}
EOT
  THISRC=$?
  
  return ${THISRC}
}

## --------------------------------------
## NoOfStackElements
##
## return the no. of stack elements
##
## usage: NoOfStackElements; var=$?
##
## returns: no. of elements on the stack
##
## Note: NoOfStackElements, FlushStack, push and pop use only one global stack!
##
function NoOfStackElements {
  typeset __FUNCTION="NoOfStackElements";  ${__FUNCTION_INIT} ; ${__DEBUG_CODE}

  return ${__STACK_POINTER}
}

## --------------------------------------
## FlushStack
##
## flush the stack
##
## usage: FlushStack
##
## returns: no. of elements on the stack before flushing it
##
## Note: NoOfStackElements, FlushStack, push and pop use only one global stack!
##
function FlushStack {
  typeset __FUNCTION="FlushStack";    ${__FUNCTION_INIT} ; ${__DEBUG_CODE}

  typeset THISRC=${__STACK_POINTER}
  __STACK_POINTER=0
  return ${THISRC}
}

## --------------------------------------
## push
##
## push one or more values on the stack
##
## usage: push value1 [...] [value#]
##
## returns: 0
##
## Note: NoOfStackElements, FlushStack, push and pop use only one global stack!
##
function push {
  typeset __FUNCTION="push";    ${__FUNCTION_INIT} ; ${__DEBUG_CODE}

   while [ $# -ne 0 ] ; do
    (( __STACK_POINTER=__STACK_POINTER+1 ))
    __STACK[${__STACK_POINTER}]="$1"
    shift
  done

  return 0
}

## --------------------------------------
## pop
##
## pop one or more values from the stack
##
## usage: pop variable1 [...] [variable#]
##
## returns: 0
##
## Note: NoOfStackElements, FlushStack, push and pop use only one global stack!
##
function pop {
  typeset __FUNCTION="pop";    ${__FUNCTION_INIT} ; ${__DEBUG_CODE}

  typeset NEWALUE=""

  while [ $# -ne 0 ] ; do
    if [ ${__STACK_POINTER} -eq 0 ] ; then
      NEWVALUE=""
    else
      NEWVALUE="${__STACK[${__STACK_POINTER}]}"
      (( __STACK_POINTER=__STACK_POINTER-1 ))
    fi
    eval $1="\"${NEWVALUE}\""
    shift
  done

  return 0
}

## --------------------------------------
## push_and_set
##
## push a variable to the stack and set the variable to a new value
##
## usage: push_and_set variable new_value
##
## returns: 0
##
## Note: NoOfStackElements, FlushStack, push and pop use only one global stack!
##
function push_and_set {
  typeset __FUNCTION="push_and_set";    ${__FUNCTION_INIT} ; ${__DEBUG_CODE}

  if [ $# -ne 0 ] ; then
    typeset VARNAME="$1"
    eval push \$${VARNAME}
     
    shift
    eval ${VARNAME}="\"$*\""
  fi
  
  return 0
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
##
function CheckYNParameter {
  typeset __FUNCTION="CheckYNParameter";    ${__FUNCTION_INIT} ; ${__DEBUG_CODE}

  typeset THISRC=255
  
  case $1 in
   "y" | "Y" | "yes" | "YES" | "true"  | "TRUE"  | 0 ) THISRC=${__TRUE} ;;
   "n" | "N" | "no"  | "NO"  | "false" | "FALSE" | 1 ) THISRC=${__FALSE} ;;
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
## returns: 0
##          prints y, n or ? to STDOUT
##
function ConvertToYesNo {
  typeset __FUNCTION="ConvertToYesNo";    ${__FUNCTION_INIT} ; ${__DEBUG_CODE}

  case $1 in
   "y" | "Y" | "yes" | "YES" | "true"  | "TRUE"  | 0 ) echo "y" ;;
   "n" | "N" | "no"  | "NO"  | "false" | "FALSE" | 1 ) echo "n" ;;
   * ) echo "?" ;;
  esac
  
  return 0
}

## --------------------------------------
## InvertSwitch
##
## invert a switch from true to false or vice versa
##
## usage: InvertSwitch variable
##
## returns 0
##         switch the variable "variable" from ${__TRUE} to
##         ${__FALSE} or vice versa
##
function InvertSwitch {
  typeset __FUNCTION="InvertSwitch";    ${__FUNCTION_INIT} ; ${__DEBUG_CODE}

  eval "[ \$$1 -eq ${__TRUE} ] && $1=${__FALSE} || $1=${__TRUE} "
  
  return 0
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
function CheckInputDevice {
  typeset __FUNCTION="CheckInputDevice";    ${__FUNCTION_INIT} ; ${__DEBUG_CODE}

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
## returns: 0
##          the variable PRGDIR contains the directory with the program
##          if the parameter resultvar is missing
##
function GetProgramDirectory {
  typeset __FUNCTION="GetProgramDirectory";    ${__FUNCTION_INIT} ; ${__DEBUG_CODE}

  typeset PRG=""
  typeset RESULTVAR=$2
    
  if [ ! -L $1 ] ; then
    PRG=$( cd -P -- "$(dirname -- "$(command -v -- "$1")")" && pwd -P )
  else  
# resolve links - $1 may be a softlink
    PRG="$1"
   
    while [ -h "$PRG" ] ; do
      ls=$(ls -ld "$PRG")
      link=$( expr "$ls" : '.*-> \(.*\)$' )
      if expr "$link" : '.*/.*' > /dev/null; then
        PRG="$link"
      else
        PRG=$(dirname "$PRG")/"$link"
      fi
    done
    PRG="$(dirname ${PRG})"
  fi

  if [ "${RESULTVAR}"x != ""x ] ; then
     eval ${RESULTVAR}=\"${PRG}\"
  else 
    PRGDIR="${PRG}"
  fi
  
  return 0
}

## --------------------------------------
## substr
##
## get a substring of a string
##
## usage: variable=$( substr sourceStr pos length )
##     or substr sourceStr pos length resultStr
##
## returns: 1 - parameter missing
##          0 - parameter okay
##
function substr {
  typeset __FUNCTION="substr";    ${__FUNCTION_INIT} ; ${__DEBUG_CODE}

  typeset resultstr=""
  typeset THISRC=1

  if [ "$1"x != ""x ] ; then 
    typeset s="$1"
    typeset p="$2"
    typeset l="$3"
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
    echo "${resultstr}"
  fi

  return ${THISRC}
}

## --------------------------------------
## replacestr
##
## replace a substring with another substring
##
## usage: variable=$( replacestr sourceStr oldsubStr newsubStr )
##     or replacestr sourceStr oldsubStr newsubStr resultvariable
##
## returns: 0 - substring replaced
##          1 - substring not found
##          3 - error, parameter missing
##
##          writes the substr to STDOUT if resultvariable is missing
##
function replacestr {
  typeset __FUNCTION="replacestr";    ${__FUNCTION_INIT} ; ${__DEBUG_CODE}

  typeset THISRC=3
   
  typeset sourcestring="$1"
  typeset oldsubStr="$2"
  typeset newsubStr="$3"

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
    echo "${sourcestring}"
  fi

  return ${THISRC}
}

## --------------------------------------
## pos
##
## get the first position of a substring in a string
##
## usage: pos searchstring sourcestring
##
## returns: 0 - searchstring is not part of sourcestring
##          else the position of searchstring in sourcestring
##
function pos {
  typeset __FUNCTION="pos";    ${__FUNCTION_INIT} ; ${__DEBUG_CODE}

  typeset searchstring="$1"
  typeset sourcestring="$2"
 
  if [[ "${sourcestring}" == *${searchstring}* ]] ; then
    typeset f="${sourcestring%%${searchstring}*}"
    return $((  ${#f}+1 ))
  else
    return 0
  fi
}

## --------------------------------------
## lastpos
##
## get the last position of a substring in a string
##
## usage: lastpos searchstring sourcestring
##
## returns: 0 - searchstring is not part of sourcestring
##          else the position of searchstring in sourcestring
##
function lastpos {
  typeset __FUNCTION="lastpos";    ${__FUNCTION_INIT} ; ${__DEBUG_CODE}

  typeset searchstring="$1"
  typeset sourcestring="$2"

  if [[ "${sourcestring}" == *${searchstring}* ]] ; then
    typeset f="${sourcestring%${searchstring}*}"
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
## returns: ${__TRUE} - testValue is a number else not
##
function isNumber {
  typeset __FUNCTION="isNumber";    ${__FUNCTION_INIT} ; ${__DEBUG_CODE}

  typeset TESTVAR="$(echo "$1" | sed 's/[0-9]*//g' )"
  [ "${TESTVAR}"x = ""x ] && return ${__TRUE} || return ${__FALSE}
}

## --------------------------------------
## ConvertToHex
##
## convert the value of a variable to a hex value
##
## usage: ConvertToHex value
##
## returns: 0
##          prints the value in hex to STDOUT
##
function ConvertToHex {
  typeset __FUNCTION="ConvertToHex";    ${__FUNCTION_INIT} ; ${__DEBUG_CODE}

  typeset -i16 HEXVAR
  HEXVAR="$1"
  echo ${HEXVAR##*#}
  
  return 0
}  

## --------------------------------------
## ConvertToOctal
##
## convert the value of a variable to a octal value
##
## usage: ConvertToOctal value
##
## returns: 0
##          prints the value in octal to STDOUT
##
function ConvertToOctal {
  typeset __FUNCTION="ConvertToOctal";    ${__FUNCTION_INIT} ; ${__DEBUG_CODE}

  typeset -i8 OCTVAR
  OCTVAR="$1"
  echo ${OCTVAR##*#}
  
  return 0
}  

## --------------------------------------
## ConvertToBinary
##
## convert the value of a variable to a binary value
##
## usage: ConvertToBinary value
##
## returns: 0
##          prints the value in binary to STDOUT
##
function ConvertToBinary {
  typeset __FUNCTION="ConvertToBinary";  ${__FUNCTION_INIT} ; ${__DEBUG_CODE}

  typeset -i2 BINVAR
  BINVAR="$1"
  echo ${BINVAR##*#}
  
  return 0
}  


## --------------------------------------
## toUppercase
##
## convert a string to uppercase
##
## usage: toUppercase sourceString | read resultString
##    or   targetString=$( toUppercase sourceString )
##    or   toUppercase sourceString resultString
##
## returns: 0
##          writes the converted string to STDOUT if resultString is missing
##
function toUppercase {
  typeset __FUNCTION="toUppercase";    ${__FUNCTION_INIT} ; ${__DEBUG_CODE}

  typeset -u testvar="$1"

  if [ "$2"x != ""x ] ; then
    eval $2=\"${testvar}\" 
  else
    echo "${testvar}"
  fi
  
  return 0
}

## --------------------------------------
## toLowercase
##
## convert a string to lowercase
##
## usage: toLowercase sourceString | read resultString
##    or   targetString=$( toLowercase sourceString )
##    or   toLowercase sourceString resultString
##
## returns: 0
##          writes the converted string to STDOUT if resultString is missing
##
function toLowercase {
  typeset __FUNCTION="toLowercase";    ${__FUNCTION_INIT} ; ${__DEBUG_CODE}

  typeset -l testvar="$1"

  if [ "$2"x != ""x ] ; then
    eval $2=\"${testvar}\" 
  else
    echo "${testvar}"
  fi
  
  return 0
}


## --------------------------------------
## StartStop_LogAll_to_logfile
##
## redirect STDOUT and STDERR into a file
##
## usage: StartStop_LogAll_to_logfile [start|stop] logfile
##
## returns: 0 - okay, redirection started / stopped
##          1 - error, can not write to the logfile
##          2 - invalid usage (to much or not enough parameter)
##          3 - invalid parameter 
##
## To explicitly write to STDOUT after calling this function with the 
## parameter "start" use 
##   echo "This goes to STDOUT" >&3
##
## To explicitly write to STDERR after calling this function with the 
## parameter "start" use 
##   echo "This goes to STDERR" >&4
##
function StartStop_LogAll_to_logfile {
  typeset __FUNCTION="StartStop_LogAll_to_logfile";    ${__FUNCTION_INIT} ; ${__DEBUG_CODE}

  typeset THISRC=0
  
  if [ $# -ne 0 ] ; then
    case $1 in

     'start' ) 
        if [ $# -gt 1 ] ; then
          touch "$2" 2>/dev/null
          if [ $? -eq 0 ] ; then
            LogInfo "Logging STDOUT and STDERR to \"$2\" ... "
            exec 3>&1
            exec 4>&2
            if [ "${__OVERWRITE_MODE}" = "${__TRUE}" ] ; then
              exec 1>$2 2>&1
            else
              exec 1>>$2 2>&1
            fi
            __GLOBAL_OUTPUT_REDIRECTION="$2"
          else
            THISRC=1
          fi
        else
          THISRC=2
        fi
        ;;

      'stop' )
        if [ "${__GLOBAL_OUTPUT_REDIRECTION}"x != ""x ] ; then
          exec 2>&4
          exec 1>&3
          LogInfo "Stopping logging of STDOUT and STDERR to \"${__GLOBAL_OUTPUT_REDIRECTION}\""
          __GLOBAL_OUTPUT_REDIRECTION=
        fi   
        ;;

      * ) 
        THISRC=3
        ;;
    esac
  else
    THISRC=2
  fi

  return ${THISRC}
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
function executeCommand {
  typeset __FUNCTION="executeCommand";    ${__FUNCTION_INIT} ; ${__DEBUG_CODE}

  typeset THISRC=0

  set +e

  LogRuntimeInfo "Executing \"$@\" "  

  eval "$@"
  THISRC=$?
  
  return ${THISRC}
}

## --------------------------------------
## executeCommandAndLog
##
## execute a command and write STDERR and STDOUT to the logfile
##
## usage: executeCommandAndLog command parameter
##
## returns: the RC of the executed command if no logfile is defined else 0
##
function executeCommandAndLog {
  typeset __FUNCTION="executeCommandAndLog";    ${__FUNCTION_INIT} ; ${__DEBUG_CODE}

  set +e
  typeset THISRC=0

  LogRuntimeInfo "Executing \"$@\" "  

  if [ "${__LOGFILE}"x != ""x -a -f "${__LOGFILE}" ] ; then
    eval "$@"  2>&1 | tee -a "${__LOGFILE}"
    THISRC=0
  else    
    eval "$@"
    THISRC=$?
  fi

  return ${THISRC}
}

## --------------------------------------
## executeCommandAndLogSTDERR
##
## execute a command and write STDERR to the logfile
##
## usage: executeCommandAndLogSTDERR command parameter
##
## returns: the RC of the executed command
##
function executeCommandAndLogSTDERR {
  typeset __FUNCTION="executeCommandAndLogSTDERR";    ${__FUNCTION_INIT} ; ${__DEBUG_CODE}

  set +e
  typeset THISRC=0

  LogRuntimeInfo "Executing \"$@\" "  >&2

  if [ "${__LOGFILE}"x != ""x -a -f" ${__LOGFILE}" ] ; then
    eval "$@" 2>>${__LOGFILE}
    THISRC=$?
  else    
    eval "$@"
    THISRC=$?
  fi

  return ${THISRC}
}

## --------------------------------------
## UserIsRoot
##
## validate the user id
##
## usage: UserIsRoot
##
## returns: ${__TRUE} - the user is root; else not
##
function UserIsRoot {
  typeset __FUNCTION="UserIsRoot";    ${__FUNCTION_INIT} ; ${__DEBUG_CODE}

  [ "$( id | sed 's/uid=\([0-9]*\)(.*/\1/' )" = 0 ] && return ${__TRUE} || return ${__FALSE}
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
function UserIs {
  typeset __FUNCTION="UserIs";    ${__FUNCTION_INIT} ; ${__DEBUG_CODE}

  typeset THISRC=3
  typeset USERID=""
  
  if [ "$1"x != ""x ] ; then
    THISRC=2
    USERID=$( grep "^$1:" /etc/passwd | cut -d: -f3 )
    if [ "${USERID}"x != ""x ] ; then
      UID="$( id | sed 's/uid=\([0-9]*\)(.*/\1/' )"      
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
## returns: the function writes the UID to STDOUT
##
function GetCurrentUID {
  typeset __FUNCTION="GetCurrentUID";    ${__FUNCTION_INIT} ; ${__DEBUG_CODE}

  echo "$(id | sed 's/uid=\([0-9]*\)(.*/\1/')"
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
## returns: 0
##          __USERNAME contains the user name or "" if
##           the userid does not exist on this machine
##
function GetUserName {
  typeset __FUNCTION="GetUserName";    ${__FUNCTION_INIT} ; ${__DEBUG_CODE}

  [ "$1"x != ""x ] &&  __USERNAME=$( grep ":x:$1:" /etc/passwd | cut -d: -f1 )  || __USERNAME=""
  
  return 0
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
## returns: 0
##          __USER_ID contains the UID or "" if
##          the username does not exist on this machine
##
function GetUID {
  typeset __FUNCTION="GetUID";    ${__FUNCTION_INIT} ; ${__DEBUG_CODE}

  [ "$1"x != ""x ] &&  __USER_ID=$( grep "^$1:" /etc/passwd | cut -d: -f3 ) || __USER_ID=""
  
  return 0
}


# ======================================
 
 
## --------------------------------------
## PrintWithTimestamp
##
## print the output of a command to STDOUT with a timestamp
##
## usage: PrintWithTimestamp command_to_execute [parameter]
##
## returns: 0
##
## Note: This function does not write to the log file!
##
## Source: Bernd Fingers blog:
##         http://blogs.sun.com/blogfinger/entry/prepend_command_output_lines_with
##
function PrintWithTimestamp {
  typeset COMMAND="$*"
  LogInfo "Executing \"${COMMAND}\" ..."

  sh -c "${COMMAND} | nawk '{\"date \\\"+%m.%d.%Y %H:%M:%S\\\":\"|getline date;
  close(\"date \\\"+%m.%d.%Y %H:%M:%S\\\":\");
  printf (\"%s %s\n\", date, \$0)}'"   
}

 
## --------------------------------------
## LogMsg
##
## print a message to STDOUT and write it also to the logfile
##
## usage: LogMsg message
##
## returns: 0
##
## Notes: Use "- message" to suppress the date stamp
##        Use "-" to print a complete blank line
##
function LogMsg {
  typeset __FUNCTION="LogMsg";    ${__FUNCTION_INIT} ; ${__DEBUG_CODE}

  if [ "$1"x = "-"x ] ; then
    shift
    typeset THISMSG="$*"
  elif [ "${__NO_TIME_STAMPS}"x = "${__TRUE}"x ] ; then
    typeset THISMSG="$*"
  else
    typeset THISMSG="[$(date +"%d.%m.%Y %H:%M:%S")] $*"
  fi
  
  [  ${__QUIET_MODE} -ne ${__TRUE} ] && echo "${THISMSG} "
  [ "${__LOGFILE}"x != ""x ] && [ -f "${__LOGFILE}" ] &&  echo "${THISMSG}" >>${__LOGFILE} 
  
  return 0
}


## --------------------------------------
## LogOnly
##
## write a message to the logfile
##
## usage: LogOnly message
##
## returns: 0
##
function LogOnly {
  typeset __FUNCTION="LogOnly";    ${__FUNCTION_INIT} ; ${__DEBUG_CODE}

  typeset THISMSG="[$(date +"%d.%m.%Y %H:%M:%S")] $*"

  [ "${__LOGFILE}"x != ""x ] && [ -f "${__LOGFILE}" ] &&  echo "${THISMSG}" >>${__LOGFILE} 
  
  return 0
}

## --------------------------------------
## LogInfo
##
## print a message to STDOUT and write it also to the logfile 
## only if in verbose mode
##
## usage: LogInfo [loglevel] message
##
## returns: 0
##
## Notes: Output goes to STDERR, default loglevel is 0
##
function LogInfo {
  typeset __FUNCTION="LogInfo";    ${__FUNCTION_INIT} ; ${__DEBUG_CODE}

#  [ ${__VERBOSE_MODE} -eq ${__TRUE} ] && LogMsg "INFO: $*"

  typeset THISLEVEL=0
  
  if [ "${__VERBOSE_MODE}" = "${__TRUE}" ] ; then
    if [ $# -gt 1 ] ; then
      isNumber $1 
      if [ $? -eq ${__TRUE} ] ; then
        THISLEVEL=$1
        shift
      fi
    fi      
    [ ${__VERBOSE_LEVEL} -gt ${THISLEVEL} ]  && LogMsg "${__INFO_PREFIX}$*" >&2
  fi  
  
  return 0
  }

# internal sub routine for info messages from the runtime system
#
#
function LogRuntimeInfo {
  typeset __FUNCTION="LogRuntimeInfo";    ${__FUNCTION_INIT} ; ${__DEBUG_CODE}
  (
    __INFO_PREFIX="${__RUNTIME_INFO_PREFIX}"  
    LogInfo "${__RT_VERBOSE_LEVEL}" "$*"  
  )
  return 0
}

# internal sub routine for header messages
#
#
function LogHeader {
  [ "${__NO_HEADERS}"x != "${__TRUE}"x ] && LogMsg "$*"
  return 0
}

## --------------------------------------
## LogWarning
##
## print a warning to STDERR and write it also to the logfile
##
## usage: LogWarning message
##
## returns: 0
##
## Notes: Output goes to STDERR
##
function LogWarning {
  typeset __FUNCTION="LogWarning";    ${__FUNCTION_INIT} ; ${__DEBUG_CODE}

  LogMsg "${__WARNING_PREFIX}$*" >&2
  (( __NO_OF_WARNINGS = __NO_OF_WARNINGS +1 ))
  __LIST_OF_WARNINGS="${__LIST_OF_WARNINGS}
${__WARNING_PREFIX}$*"  
  return 0
}

## --------------------------------------
## LogError
##
## print an error message to STDERR and write it also to the logfile
##
## usage: LogError message
##
## returns: 0
##
## Notes: Output goes to STDERR
##
function LogError {
  typeset __FUNCTION="LogError";    ${__FUNCTION_INIT} ; ${__DEBUG_CODE}

  LogMsg "${__ERROR_PREFIX}$*" >&2

  (( __NO_OF_ERRORS=__NO_OF_ERRORS + 1 ))  
  __LIST_OF_ERRORS="${__LIST_OF_ERRORS}
${__ERROR_PREFIX}$*"  
  return 0
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
function BackupFileIfNecessary {
  typeset __FUNCTION="BackupFileIfNecessary";    ${__FUNCTION_INIT} ; ${__DEBUG_CODE}

 [ "${BACKUP_EXTENSION}"x = ""x ] && BACKUP_EXTENSION=".$$"
 
 typeset FILES_TO_BACKUP="$*"
 typeset CURFILE=""
 typeset CUR_BKP_FILE=""
 typeset THISRC=0
  
 if [ ${__OVERWRITE_MODE} -eq ${__FALSE} ] ; then
   for CURFILE in ${FILES_TO_BACKUP} ; do         
     [ ! -f "${CURFILE}" ] && continue

     CUR_BKP_FILE="${CURFILE}${BACKUP_EXTENSION}"
     LogMsg "Creating a backup of \"${CURFILE}\" in \"${CUR_BKP_FILE}\" ..."
     cp "${CURFILE}" "${CUR_BKP_FILE}"
     THISRC=$?
     if [ ${THISRC} -ne 0 ] ; then
       LogError "Error creating the backup of the file \"${CURFILE}\""
       break
     fi
   done
 fi
 
 return ${THISRC}
}  
 
## ---------------------------------------
## CopyDirectory
##
## copy a directory 
##
## usage: CopyDirectory sourcedir targetDir
##
## returns:  0 - done; 
##           else error
##
function CopyDirectory {
  typeset __FUNCTION="CopyDirectory";    ${__FUNCTION_INIT} ; ${__DEBUG_CODE}

  typeset THISRC=1
  if [ "$1"x != ""x -a "$2"x != ""x  ] ; then
     if [ -d "$1" -a -d "$2" ] ; then
        LogMsg "Copying all files from \"$1\" to \"$2\" ..."
        cd "$1"
        find . -depth -print | cpio -pdumv "$2"
        THISRC=$?
        cd "${OLDPWD}"
     fi
  fi

  return ${THISRC}
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
## Notes: "all" is interpreted as yes for this and all other questions
##        "none" is interpreted as no for this and all other questions
##
## If __NOECHO is ${__TRUE} the user input is not written to STDOUT
## __NOECHO is set to ${__FALSE} again in this function
##
## If __USE_TTY is ${__TRUE} the prompt is written to /dev/tty and the 
## user input is read from /dev/tty . This is useful if STDOUT is redirected 
## to a file.
##
function AskUser {
  typeset __FUNCTION="AskUser";    ${__FUNCTION_INIT} ; ${__DEBUG_CODE}

  typeset THISRC=""

  if [ "${__USE_TTY}"x = "${__TRUE}"x ] ; then
    typeset mySTDIN="</dev/tty"
    typeset mySTDOUT=">/dev/tty"
  else
    typeset mySTDIN=""
    typeset mySTDOUT=""
  fi
  
  case ${__USER_RESPONSE_IS} in 
     
   "y" ) USER_INPUT="y" ; THISRC=${__TRUE} 
         ;;

   "n" ) USER_INPUT="n" ; THISRC=${__FALSE} 
         ;;
   
     * ) [ $# -ne 0 ] && eval printf "\"$* \"" ${mySTDOUT}
          if [ ${__NOECHO} = ${__TRUE} ] ; then
            __STTY_SETTINGS="$( stty -g )"
            stty -echo
          fi
          eval read USER_INPUT ${mySTDIN}
          if [ ${__NOECHO} = ${__TRUE} ] ; then
            stty ${__STTY_SETTINGS}
            __STTY_SETTINGS=""
          fi

         case ${USER_INPUT} in

           "y" | "Y" ) THISRC=${__TRUE}  ;;

           "n" | "N" ) THISRC=${__FALSE} ;;

           "all" ) __USER_RESPONSE_IS="y"  ; THISRC=${__TRUE}  ;;

           "none" )  __USER_RESPONSE_IS="n" ;  THISRC=${__FALSE} ;;

           * )  THISRC=${__FALSE} ;;

        esac
        ;;
  esac  

  __NOECHO=${__FALSE}
  return ${THISRC}
}

## --------------------------------------
## GetKeystroke
##
## read one key from STDIN
##
## Usage: GetKeystroke "message" 
##        
## returns: 0
##          USER_INPUT contains the user input
##          
function GetKeystroke {
  typeset __FUNCTION="GetKeystroke";    ${__FUNCTION_INIT} ; ${__DEBUG_CODE}

  trap "" 2 3
  [ $# -ne 0 ] && LogMsg "${THISMSG}"

  __STTY_SETTINGS="$( stty -g )"

  stty -echo raw
  USER_INPUT=$( dd count=1 2> /dev/null )

  stty ${__STTY_SETTINGS}
  __STTY_SETTINGS=""

  trap 2 3
  
  return 0
} 

## --------------------------------------
## RebootIfNecessary
##
## Check if a reboot is necessary
##
## Usage: RebootIfNecessary
##
## Notes
##   The routine asks the user if neither the parameter -y nor the 
##   parameter -n is used
##   Before using this routine uncomment the reboot command!
##
function RebootIfNecessary {
  typeset __FUNCTION="RebootIfNecessary";    ${__FUNCTION_INIT} ; ${__DEBUG_CODE}

  if [ ${__REBOOT_REQUIRED} -eq 0 ] ; then
    LogMsg "The changes made to the system require a reboot"

    AskUser "Do you want to reboot now (y/n, default is NO)?"
    if [ $? -eq ${__TRUE} ] ; then
      LogMsg "Rebooting now ..."
      echo "???" reboot ${__REBOOT_PARAMETER}
    fi
  fi
  
  return 0
}

## ---------------------------------------
## die
##
## print a message and end the program
##
## usage: die returncode {message}
##
## returns: $1 (if it returns)
##
## Notes: 
##
## This routine 
##     - calls cleanup
##     - prints an error message if any (if returncode is not zero)
##       or the message if any (if returncode is zero)
##     - prints all warning messages again if ${__PRINT_LIST_OF_WARNING_MSGS} 
##       is ${__TRUE}
##     - prints all error messages again if ${__PRINT_LIST_OF_ERROR_MSGS} 
##       is ${__TRUE}
##     - prints a program end message and the program return code
## and
##     - and ends the program
##
## If the variable ${__FORCE} is ${__TRUE} and the return code is NOT zero
## die() will only print the error message and return
##
function die {
  typeset __FUNCTION="die";    ${__FUNCTION_INIT} ; ${__DEBUG_CODE}

  [ "${__TRAP_SIGNAL}"x != ""x ] &&  LogRuntimeInfo "__TRAP_SIGNAL is \"${__TRAP_SIGNAL}\""
  
  typeset THISRC=$1
  [ $# -ne 0 ] && shift
  
  if [ "$*"x != ""x ] ; then
    [ ${THISRC} = 0 ] && LogMsg "$*" || LogError "$*"
  fi

  [ ${__FORCE} = ${__TRUE} -a ${THISRC} != 0 ] && return

  cleanup
  
  if [ "${__NO_OF_WARNINGS}" != "0" -a ${__PRINT_LIST_OF_WARNINGS_MSGS} -eq ${__TRUE} ] ; then
    LogMsg "*** CAUTION: One or more WARNINGS found ***"
    LogMsg "*** please check the logfile ***"
    
    LogMsg "Summary of warnings:
${__LIST_OF_WARNINGS}
"
  fi    

  if [ "${__NO_OF_ERRORS}" != "0" -a ${__PRINT_LIST_OF_ERROR_MSGS} -eq ${__TRUE} ] ; then
    LogMsg "*** CAUTION: One or more ERRORS found ***"
    LogMsg "*** please check the logfile ***"

    LogMsg "Summary of error messages
${__LIST_OF_ERRORS}
"
  fi    

  [[ -n "${__LOGFILE}" ]] && LogHeader "The log file used was \"${__LOGFILE}\" "
  __QUIET_MODE=${__FALSE}
  LogHeader "${__SCRIPTNAME} ${__SCRIPT_VERSION} ended on $( date )."
  LogHeader "The RC is ${THISRC}."
  
  __EXIT_VIA_DIE=${__TRUE} 

  StartStop_LogAll_to_logfile "stop" 

  RebootIfNecessary
  
  exit ${THISRC}
}


## ---------------------------------------
## includeScript
##
## include a script via . [scriptname]
##
## usage: includeScript [scriptname]
##
## returns: 0
##
## notes: 
##
function includeScript {
  typeset __FUNCTION="includeScript";    ${__FUNCTION_INIT} ; ${__DEBUG_CODE}

  if [ $# -ne 0 ] ; then
   
    LogRuntimeInfo "Including the script \"$*\" ..."

# set the variable for the TRAP handlers
    [ ! -f "$1" ] && die 247 "Include script \"$1\" not found"
    __INCLUDE_SCRIPT_RUNNING="$1"
  
# include the script
    . $*

# reset the variable for the TRAP handlers  
    __INCLUDE_SCRIPT_RUNNING=""

  fi
}


## --------------------------------------
## rand
##
## print a random number to STDOUT
##
## usage: rand
##
## returns: ${__TRUE} - random number printed to STDOUT
##          ${__FALSE} - can not create a random number
##
##
## notes: 
##
## This function prints the contents of the environment variable RANDOM
## to STDOUT. If that variable is not defined, it uses nawk to create
## a random number. If nawk is not available the function prints nothng to
## STDOUT
##
function rand {
  typeset __THISRC=${__FALSE}
  
  if [ "${RANDOM}"x != ""x ] ; then
    echo ${RANDOM}
    __THISRC=${__TRUE}
  elif whence nawk >/dev/null ; then
    nawk 'BEGIN { srand(); printf "%d\n", (rand() * 10^8); }'
    __THISRC=${__TRUE}
  fi
  
  return ${__THISRC}
}

# ======================================

## 
## ##### defined internal sub routines (do NOT use; these routines are called 
##       by the runtime system!)
##

# --------------------------------------
## PrintLockFileErrorMsg
#
# Print the lockfile already exist error message to STDERR
#
# usage: PrintLockFileErrorMsg
#
# returns: 250
#
function PrintLockFileErrorMsg { 
  cat >&2  <<EOF

  ERROR:

  Either another instance of this script is already running 
  or the last execution of this script crashes.
  In the first case wait until the other instance ends; 
  in the second case delete the lock file 
  
      ${__LOCKFILE} 

  manually and restart the script.

EOF
  return 250
}

# --------------------------------------
## CreateLockFile
#
# Create the lock file (which is really a symbolic link if using the "old method") if possible
#
# usage: CreateLockFile
#
# returns: 0 - lock created
#          1 - lock already exist or error creating the lock
#
# Note: The old method uses a symbolic link because this is should always be a atomic operation
#
function CreateLockFile {
  typeset __FUNCTION="CreateLockFile";    ${__FUNCTION_INIT} ; ${__DEBUG_CODE}
 
# for compatibilty reasons the old code can still be activated if necessary
  typeset __USE_OLD_CODE=${__FALSE}
  
  typeset LN_RC=""

  LogRuntimeInfo "Trying to create the lock semaphore ..."
  if [ ${__USE_OLD_CODE} = ${__TRUE} ] ; then    
# old code using ln  
    ln -s  "$0" "${__LOCKFILE}" 2>/dev/null
    LN_RC=$?
  else    
    __INSIDE_CREATE_LOCKFILE=${__TRUE}
    
# improved code from wpollock (see credits)
    set -C  # or: set -o noclobber
    : > "${__LOCKFILE}" 2>/dev/null
    LN_RC=$?
    __INSIDE_CREATE_LOCKFILE=${__FALSE}
  fi
  
  if [ ${LN_RC} = 0 ] ; then
    __LOCKFILE_CREATED=${__TRUE}
    return 0 
  else
    return 1
  fi
  
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
function RemoveLockFile {
  typeset __FUNCTION="RemoveLockFile";    ${__FUNCTION_INIT} ; ${__DEBUG_CODE}

  [ ! -L "${__LOCKFILE}" -a ! -f "${__LOCKFILE}" ] && return 1
  if [ ${__LOCKFILE_CREATED} -eq ${__TRUE} ] ; then
    LogRuntimeInfo "Removing the lock semaphore ..."
  
    rm "${__LOCKFILE}" 1>/dev/null 2>/dev/null
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
# returns: 0
#
# notes: 
#  The variables with the tempfiles are called
#  __TEMPFILE1, __TEMPFILE2, ..., __TEMPFILE#
#
function CreateTemporaryFiles {
  typeset __FUNCTION="CreateTemporaryFiles";    ${__FUNCTION_INIT} ; ${__DEBUG_CODE}

  typeset CURFILE=
  
  typeset i=1

# for compatibilty reasons the old code can still be activated if necessary
  typeset __USE_OLD_CODE=${__FALSE}
 
  __TEMPFILE_CREATED=${__TRUE}

# save the current umask and set the temporary umask
  __ORIGINAL_UMASK=$( umask )
  
  umask ${__TEMPFILE_UMASK}

  LogRuntimeInfo "Creating the temporary files  ..."
 
  while [ ${i} -le ${__NO_OF_TEMPFILES} ]  ; do   
    if [  ${__USE_OLD_CODE} = ${__TRUE} ] ; then       
      eval __TEMPFILE${i}="${__TEMPDIR}/${__SCRIPTNAME}.$$.TEMP${i}"
      eval CURFILE="\$__TEMPFILE${i}"
      LogRuntimeInfo "Creating the temporary file \"${CURFILE}\"; the variable is \"\${TEMPFILE${i}}" 

      echo >"${CURFILE}" || return $?    
    else    
# improved code from wpollock (see credits)
      set -C  # turn on noclobber shell option
            
      while : ; do
        eval __TEMPFILE${i}="${__TEMPDIR}/${__SCRIPTNAME}.$$.$( rand ).TEMP${i}"
        eval CURFILE="\$__TEMPFILE${i}"
        LogRuntimeInfo "Creating the temporary file \"${CURFILE}\"; the variable is \"\${TEMPFILE${i}}" 
        : > ${CURFILE}  && break
      done
    fi
    eval __LIST_OF_TMP_FILES=\"${__LIST_OF_TMP_FILES} \${__TEMPFILE${i}}\"
   
    (( i = i +1 ))
  done

# restore the umask  
  umask ${__ORIGINAL_UMASK}
  __ORIGINAL_UMASK=""
  
  return 0
}

# ======================================


# ======================================

##
## ---------------------------------------
## cleanup
##
## house keeping at program end
##
## usage: [called by the runtime system]
##
## returns: 0
##
## notes: 
##  execution order is
##    - call exit routines from ${__EXITROUTINES}
##    - remove files from ${__LIST_OF_TMP_FILES}
##    - umount mount points ${__LIST_OF_TMP_MOUNTS}
##    - remove directories ${__LIST_OF_TMP_DIRS}
##    - call finish routines from ${__FINISHROUTINES}
##
function cleanup {
  typeset __FUNCTION="cleanup";    ${__FUNCTION_INIT} ; ${__DEBUG_CODE}

  typeset EXIT_ROUTINE=
  typeset OLDPWD="$( pwd )"

  cd /tmp

# restore the umask if necessary
  if [ "${__ORIGINAL_UMASK}"x != ""x ] ; then
    umask ${__ORIGINAL_UMASK}
    __ORIGINAL_UMASK=""
  fi
  
# reset tty settings if necessary
  if [ "${__STTY_SETTINGS}"x != ""x ] ; then
    stty ${__STTY_SETTINGS}
    __STTY_SETTINGS=""
  fi
  
# call the defined exit routines
  LogRuntimeInfo "Executing the exit routines \"${__EXITROUTINES}\" ..."
  if [ "${__EXITROUTINES}"x !=  ""x ] ; then
    for EXIT_ROUTINE in ${__EXITROUTINES} ; do
      typeset +f | grep "^${EXIT_ROUTINE}" >/dev/null
      if [ $? -eq 0 ] ; then
        LogRuntimeInfo "Now calling the exit routine \"${EXIT_ROUTINE}\" ..."
        eval ${EXIT_ROUTINE}
      else
        LogError "Exit routine \"${EXIT_ROUTINE}\" is NOT defined!"
      fi
    done
  fi

# remove temporary files
  LogRuntimeInfo "Removing temporary files ..."
  for CURENTRY in ${__LIST_OF_TMP_FILES} ; do
    LogRuntimeInfo "Removing the file \"${CURENTRY}\" ..."
    if [ -f "${CURENTRY}" ] ; then
      rm "${CURENTRY}" 
      [ $? -ne 0 ] && LogWarning "Error removing the file \"${CURENTRY}\" "
    fi
  done
 
# remove temporary mounts
  LogRuntimeInfo "Removing temporary mounts ..."
  typeset CURENTRY
  for CURENTRY in ${__LIST_OF_TMP_MOUNTS} ; do
    mount | grep "^${CURENTRY} " 1>/dev/null 2>/dev/null
    if [ $? -eq 0 ] ; then
      LogRuntimeInfo "Umounting \"${CURENTRY}\" ..."
      umount "${CURENTRY}" 
      [ $? -ne 0 ] && LogWarning "Error umounting \"${CURENTRY}\" "
    fi
  done

# remove temporary directories
  LogRuntimeInfo "Removing temporary directories ..."
  for CURENTRY in ${__LIST_OF_TMP_DIRS} ; do
    LogRuntimeInfo "Removing the directory \"${CURENTRY}\" ..."
    if [ -d "${CURENTRY}" ] ; then
      rm -r "${CURENTRY}" 2>/dev/null
      [ $? -ne 0 ] && LogWarning "Error removing the directory \"${CURENTRY}\" "
    fi
  done

# call the defined finish routines
  LogRuntimeInfo "Executing the finish routines \"${__FINISHROUTINES}\" ..."
  if [ "${__FINISHROUTINES}"x !=  ""x ] ; then
    for FINISH_ROUTINE in ${__FINISHROUTINES} ; do
      typeset +f | grep "^${FINISH_ROUTINE}" >/dev/null
      if [ $? -eq 0 ] ; then
        LogRuntimeInfo "Now calling the finish routine \"${FINISH_ROUTINE}\" ..."
        eval ${FINISH_ROUTINE}
      else
        LogError "Finish routine \"${FINISH_ROUTINE}\" is NOT defined!"
      fi
    done
  fi

  [ -d "${OLDPWD}" ] && cd "${OLDPWD}"
  
  return 0
}



## 
## ##### defined trap handler (you may change them)
##

## ---------------------------------------
## GENERAL_SIGNAL_HANDLER
##
## general trap handler 
##
## usage: called automatically;
##        parameter: $1 = signal number
##                   $2 = LineNumber
##                   $3 = function name
##
## returns: -
##
function GENERAL_SIGNAL_HANDLER {
  typeset __RC=$?
       
  __TRAP_SIGNAL=$1
  typeset __LINENO=$2  
  typeset INTERRUPTED_FUNCTION=$3
  
  typeset __FUNCTION="GENERAL_SIGNAL_HANDLER";    ${__DEBUG_CODE}

# get the name of a user defined trap routine
  typeset __USER_DEFINED_FUNCTION=""
  eval __USER_DEFINED_FUNCTION="\$__SIGNAL_${__TRAP_SIGNAL}_FUNCTION"
  
  if [ "${__EXIT_VIA_DIE}"x != "${__TRUE}"x -a ${__TRAP_SIGNAL} != "exit" ] ; then
    LogRuntimeInfo "Trap \"${__TRAP_SIGNAL}\" caught"
      
    [ "${__INCLUDE_SCRIPT_RUNNING}"x != ""x ] && LogMsg "Trap occurred inside of the include script \"${__INCLUDE_SCRIPT_RUNNING}\" "
  
    LogRuntimeInfo "Signal ${__TRAP_SIGNAL} received: Line: ${__LINENO} in function: ${INTERRUPTED_FUNCTION}"
  fi

  case ${__TRAP_SIGNAL} in 
    0 ) __TRAP_SIGNAL="EXIT" ;;
    1 ) __TRAP_SIGNAL="SIGHUP" ;;
    2 ) __TRAP_SIGNAL="SIGINT" ;;
    3 ) __TRAP_SIGNAL="SIGQUIT" ;;
   15 ) __TRAP_SIGNAL="SIGTERM"
  esac
             
  typeset __DEFAULT_ACTION_OK=${__TRUE}
  if [ "${__USER_DEFINED_FUNCTION}"x = ""x  ] ; then
    LogRuntimeInfo "No user defined function for signal \"${__TRAP_SIGNAL}\" declared"
  else
    typeset +f | grep "^${__USER_DEFINED_FUNCTION}" >/dev/null
    if [ $? -ne 0 ] ; then
      LogRuntimeInfo "Function \"${__USER_DEFINED_FUNCTION}\" is declared but not defined "
      __USER_DEFINED_FUNCTION=""
    else
      LogRuntimeInfo "Executing the user defined function for signal \"${__TRAP_SIGNAL}\"  \"${__USER_DEFINED_FUNCTION}\" ..."
      ${__USER_DEFINED_FUNCTION} 
      __USER_DEFINED_FUNCTION_RC=$?
      LogRuntimeInfo "The return code of the user defined signal function is ${__USER_DEFINED_FUNCTION_RC}"
      
      if [ ${__USER_DEFINED_FUNCTION_RC} -ne 0 ]  ; then
        LogRuntimeInfo "  -->> Will not execute the default action for this signal"
      __DEFAULT_ACTION_OK=${__FALSE}
      fi
    fi
  fi

      
  if [ ${__DEFAULT_ACTION_OK} = ${__TRUE} ] ; then
  
    case ${__TRAP_SIGNAL} in 

      1 | "SIGHUP" )
          LogWarning "SIGHUP signal received"

          InvertSwitch __VERBOSE_MODE
          LogMsg "Switching verbose mode to $( ConvertToYesNo ${__VERBOSE_MODE} )"
        ;;


      2 | "SIGINT" )

        if [ ${__USER_BREAK_ALLOWED} -eq ${__TRUE} ] ; then
            die 252 "Script aborted by the user via signal BREAK (CTRL-C)" 
          else
            LogRuntimeInfo "Break signal (CTRL-C) received and ignored (Break is disabled)"
          fi
        ;;

      3 | "SIGQUIT" )

          die 251 "QUIT signal received" 
        ;;

     15 | "SIGTERM" )
          die 253 "Script aborted by the external signal SIGTERM" 
        ;;

     "SIGUSR1" | "SIGUSR2" ) 
          :
        ;;
   
     "ERR" )
          LogMsg "A command ended with an error; the RC is ${__RC}"
        ;;

   "exit" | "EXIT" | 0 )
          if [ "${__INSIDE_CREATE_LOCKFILE}"x = "${__TRUE}"x ]; then
            PrintLockFileErrorMsg
          elif [ "${__EXIT_VIA_DIE}"x != "${__TRUE}"x ] ; then
            LogError "EXIT signal received; the RC is ${__RC}"
            [ "${__INCLUDE_SCRIPT_RUNNING}"x != ""x ] && LogMsg "exit occurred inside of the include script \"${__INCLUDE_SCRIPT_RUNNING}\" "
            RemoveLockFile
            LogWarning "You should use the function \"die\" to end the program"
          fi    
        ;;
       
      * ) 
          die 254 "Unknown signal caught: ${__TRAP_SIGNAL}"
        ;;

    esac
  fi
  
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
function DebugHandler {
  typeset __FUNCTION="DebugHandler";    ${__FUNCTION_INIT} ; ${__DEBUG_CODE}

  [ "${__DEBUG_MODE}" -ne ${__TRUE} ] && return ${__LAST_RC}

  __STTY_SETTINGS="$( stty -g )"
#  stty erase 
  
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
  typeset RESIZE_BINARY="$( whence resize )"
  [ "${RESIZE_BINARY}"x = ""x ] && RESIZE_BINARY="/usr/openwin/bin/resize"
  [ -x "${RESIZE_BINARY}" ] && eval $( ${RESIZE_BINARY} ) 
  (( COLUMNS = $COLUMNS - 1 ))
  eval "typeset -L${COLUMNS} LINE_VAR"
  
#  typeset  -L80 __LINE_VAR=""
  typeset __USERINPUT=""

  set -o emacs
  
  alias __A=$(print "\020")    # up arrow    -> Ctrl-P (previous cmd)
  alias __B=$(print "\016")    # down arrow  -> Ctrl-N (next cmd)
  alias __C=$(print "\006")    # right arrow -> Ctrl-F (move forward 1 char)
  alias __D=$(print "\002")    # left arrow  -> Ctrl-B (move backward 1 char)
  alias __H=$(print "\001")    # home        -> Ctrl-A (go to beginning of line)
  alias __P=$(print "\004")    # delete      -> Ctrl-D (delete char under cursor)
  alias __@=" "
  alias __Q=$(print "\005")    # end         -> Ctrl-E (go to end of line)
  alias __Z=$(print "\017")    # end         -> Ctrl-O (operate)

  export HISTFILE="${__DEBUG_HISTFILE}"
  
# check for the break points
  if [ "${__BREAKPOINT_LINE}"x != "0"x ] ; then
    if [ "${__BREAKPOINT_LINE}" -ge "${__LINENO}" ] ; then
      __LINE_VAR="*** DEBUG: Break point at line ${__LINENO} found"
      print -u2 "${__DEBUG_MSG_COLOR}${__LINE_VAR}"
      __BREAKPOINT_LINE=0
    else
      return ${__LAST_RC}
    fi
  fi

  if [ "${__STEP_COUNT}"x != "0"x ] ; then
    __STEP_COUNT=$(( __STEP_COUNT - 1 ))
    if [  "${__STEP_COUNT}"x = "0"x  ] ; then
      __LINE_VAR="*** DEBUG: Break point at line ${__LINENO} found"
      print -u2 "${__DEBUG_MSG_COLOR}${__LINE_VAR}"
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
#  eval "typeset -L${j} __SRCLINE_VAR"  
  eval "typeset -L${COLUMNS} __SRCLINE_VAR"
  
  if [ "${__TRACE_COUNT}"x != "0"x ] ; then
    __SRCLINE_VAR="${NUM_VAR}>>> ${__SCRIPT_ARRAY[${__LINENO}]}"
    print -u2 "${__CUR_LINE_COLOR}${__SRCLINE_VAR}"
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
  print -u2 "${__DEBUG_MSG_COLOR}${__LINE_VAR}"

  __LINE_VAR="*** DEBUG: Executed line: ${__LINENO}"
  print -u2 "${__DEBUG_MSG_COLOR}${__LINE_VAR}"
  __LINE_VAR="*** DEBUG: Line Context:"
  print -u2 "${__DEBUG_MSG_COLOR}${__LINE_VAR}"

  [ ${__LINENO} -gt 5 ] && i=$(( ${__LINENO}-5 )) || i=1
  typeset CUR_SRC_WIN_START=$i
  j=$(( ${__LINENO}+5 ))
  [ ${j} -gt ${__SCRIPT_ARRAY[0]} ] && j=${__SCRIPT_ARRAY[0]}

# write the context of the line just executed   
  while [ i -lt j ] ; do
    NUM_VAR=$i
    if [ $i -eq ${__LINENO} ] ; then
      __SRCLINE_VAR="${NUM_VAR}>>> ${__SCRIPT_ARRAY[$i]}"
      print -u2 "${__CUR_LINE_COLOR}${__SRCLINE_VAR}${__COLOR_OFF} "
    else
      __SRCLINE_VAR="${NUM_VAR}    ${__SCRIPT_ARRAY[$i]}"
      print -u2 "${__LINE_COLOR}${__SRCLINE_VAR}${__COLOR_OFF} "
    fi
      i=$(( i+1 ))
  done   
  print "${__COLOR_OFF}"
  
# read the user input
#
  __LINE_VAR="*** DEBUG: \$\$ is ${__THIS_PID}; \$? is ${__LAST_RC}; \$! is ${__LAST_BG_RC}"
  print -u2 "${__DEBUG_MSG_COLOR}${__LINE_VAR}"
  __LINE_VAR="*** DEBUG: Enter a command to execute or <enter> to execute the next command:"
  print -u2 "${__DEBUG_MSG_COLOR}${__LINE_VAR}"

  while [ 1 = 1 ] ; do
    echo $COLUMNS
    echo $LINE
    print -u2 -n  "${__DEBUG_MSG_COLOR}DEBUG>>> "
    read -s __USERINPUT __USERPARMS __USERVALUE __USERVALUE2
  
    case ${__USERINPUT} in 

      "help" | "?" ) __LINE_VAR="*** DEBUG:Known commands"
           print -u2 "${__DEBUG_MSG_COLOR}${__LINE_VAR}"
cat 1>&2 <<EOT

  help                      - print this text
  trace count               - execute count lines
  trace off                 - turn single mode off
  trace at lineNo           - suspend single step until line lineNo
  trace not lineNumber      - suspend single step for lineNumber statements
  show lineNo [count]       - show count (def.: 10) lines after line lineNo
  exit [returncode]         - exit the program with RC returnCode (def.: 1)
  <return>                  - execute next statement (single step)
  everything else           - execute the command 

EOT
           ;; 
   
   
      "" ) break 
           ;;
           
      "trace"  ) :
          case ${__USERPARMS}  in 

            "off" )
              __LINE_VAR="*** DEBUG: Turning single step mode off"
              print -u2 "${__DEBUG_MSG_COLOR}${__LINE_VAR}"
              __DEBUG_MODE=${__FALSE} 
              break
              ;;
      
            "at" )
              if [ "${__USERVALUE}"x = ""x ] ; then
                __LINE_VAR="*** DEBUG: value missing"
                print -u2 "${__DEBUG_MSG_COLOR}${__LINE_VAR}"
                continue
              fi

              isNumber "${__USERVALUE}" 2>/dev/null
              if [ $? -ne 0 ] ; then
                __LINE_VAR="*** DEBUG: \"${__USERVALUE}\" is not a number"
                print -u2 "${__DEBUG_MSG_COLOR}${__LINE_VAR}"
                continue
              fi         

              __LINE_VAR="*** DEBUG: Suspending single step until line ${__USERVALUE}"
              print -u2 "${__DEBUG_MSG_COLOR}${__LINE_VAR}"
              __BREAKPOINT_LINE=${__USERVALUE}      
              break
              ;;

            "not" )
              if [ "${__USERVALUE}"x = ""x ] ; then
                __LINE_VAR="*** DEBUG: value missing"
                print -u2 "${__DEBUG_MSG_COLOR}${__LINE_VAR}"
                continue
              fi

              isNumber "${__USERVALUE}" 2>/dev/null
              if [ $? -ne 0 ] ; then
                __LINE_VAR="*** DEBUG: \"${__USERVALUE}\" is not a number"
                print -u2 "${__DEBUG_MSG_COLOR}${__LINE_VAR}"
                continue
              fi         

              __LINE_VAR="*** DEBUG: Suspending single step for the next ${__USERVALUE} statements"
              print -u2 "${__DEBUG_MSG_COLOR}${__LINE_VAR}"
              __STEP_COUNT=${__USERVALUE}      
              break
              ;;


            * )
              isNumber "${__USERPARMS}" 2>/dev/null
              if [ $? -eq 0 ] ; then
                __TRACE_COUNT=${__USERPARMS}
                __LINE_VAR="*** DEBUG: Executing \"${__USERPARMS}\" lines"
                print -u2 "${__DEBUG_MSG_COLOR}${__LINE_VAR}"
                break
              else
                __LINE_VAR="*** DEBUG: unknown trace option \"${__USERPARMS}\" "
                print -u2 "${__DEBUG_MSG_COLOR}${__LINE_VAR}"    
              fi
              ;;
      
          esac
          ;;   

      "show" )      
           [ "${__USERPARMS}"x = ""x ] && __USERPARMS=${CUR_SRC_WIN_START}

           isNumber "${__USERPARMS}" 2>/dev/null
           if [ $? -ne 0 ] ; then
             __LINE_VAR="*** DEBUG: \"${__USERPARMS}\" is not a number"
             print -u2 "${__DEBUG_MSG_COLOR}${__LINE_VAR}"
             continue
           fi         

           if [ "${__USERPARMS}" -lt 1 ] ; then
             __LINE_VAR="*** DEBUG: \"${__USERPARMS}\" is out of range"
             print -u2 "${__DEBUG_MSG_COLOR}${__LINE_VAR}"
             continue
           fi         

           if [ "${__USERPARMS}" -gt ${__SCRIPT_ARRAY[0]} ] ; then
             __LINE_VAR="*** DEBUG: \"${__USERPARMS}\" is out of range (last line is ${__SCRIPT_ARRAY[0]})"
             print -u2 "${__DEBUG_MSG_COLOR}${__LINE_VAR}"    
             continue
           fi

           i=${__USERPARMS}

           if [ "${__USERVALUE}"x != ""x ] ; then
             isNumber "${__USERVALUE}" 2>/dev/null
             if [ $? -ne 0 ] ; then
               __LINE_VAR="*** DEBUG: \"${__USERVALUE}\" is not a number"
               print -u2 "${__DEBUG_MSG_COLOR}${__LINE_VAR}"
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
               print -u2 "${__CUR_LINE_COLOR}${NUM_VAR} ${__SRCLINE_VAR}"
             else
               __SRCLINE_VAR="    ${__SCRIPT_ARRAY[$i]}"
               print -u2 "${__LINE_COLOR}${NUM_VAR} ${__SRCLINE_VAR}"
             fi 
             i=$(( i+1 ))
           done      
     
           ;;
   
      "exit" | "quit" )  :
           print "${__COLOR_OFF}"
           [ "${__USERPARMS}"x = ""x ] && die 252 "Program aborted by the user"
           die ${__USERPARMS} 
           ;;

      * ) executeCommand "${__USERINPUT}" "${__USERPARMS}" "${__USERVALUE}" "${__USERVALUE2}"
            ;;
    esac
  done
  print "${__COLOR_OFF}"

  return ${__LAST_RC}
}



## ---------------------------------------
## InitScript
##
## init the script runtime 
##
## usage: [called by the runtime system]
##
## returns: 0
##
function InitScript {    
  typeset __FUNCTION="InitScript";    ${__FUNCTION_INIT} ; ${__DEBUG_CODE}

# use a temporary log file until we know the real log file
  __TEMPFILE_CREATED=${__FALSE}
  __MAIN_LOGFILE=${__LOGFILE}
  
  __LOGFILE="/tmp/${__SCRIPTNAME}.$$.TEMP"
  echo >${__LOGFILE}

  LogHeader "${__SCRIPTNAME} ${__SCRIPT_VERSION} started on $( date ) "

  LogInfo "Script template used is \"${__SCRIPT_TEMPLATE_VERSION}\" ."

  __WRITE_CONFIG_AND_EXIT=${__FALSE} 
  
# init the variables
  eval "${__CONFIG_PARAMETER}"

  if [[ ! \ $*\  == *\ -C* ]]  ; then
# read the config file
    ReadConfigFile
  fi

  return 0
}


## ---------------------------------------
## SetEnvironment
##
## set and check the environment
##
## usage: [called by the runtime system]
##
## returns: 0
##
function SetEnvironment {
  typeset __FUNCTION="SetEnvironment";    ${__FUNCTION_INIT} ; ${__DEBUG_CODE}
 
# copy the temporary log file to the real log file

  if [ "${NEW_LOGFILE}"x = "nul"x ] ; then
    LogHeader "Running without a log file"
    __MAIN_LOGFILE=""
# delete the temporary logfile   
    rm "${__LOGFILE}" 2>/dev/null
    __LOGFILE=""
  else
    [ "${NEW_LOGFILE}"x != ""x ] && __MAIN_LOGFILE="${NEW_LOGFILE}"
    LogRuntimeInfo "Initializing the log file\"${__MAIN_LOGFILE}\" "

    touch "${__MAIN_LOGFILE}" 2>/dev/null
    cat "${__LOGFILE}" >>${__MAIN_LOGFILE} 2>/dev/null
    if [ $? -ne 0 ]   ; then
      LogWarning "Error writing to the logfile \"${__MAIN_LOGFILE}\"."
      LogWarning "Using the log file \"${__LOGFILE}\" "
    else
      rm "${__LOGFILE}" 2>/dev/null
      __LOGFILE="${__MAIN_LOGFILE}"
    fi
    LogHeader "Using the log file \"${__LOGFILE}\" "
  fi

  if [ "${__REQUIRED_OS}"x != ""x ] ; then
    pos " ${__OS} " " ${__REQUIRED_OS} " && \
      die 238 "This script can not run on this operating system (${__OS}); known Operating systems are \"${__REQUIRED_OS}\""
  fi

  if [ "${__REQUIRED_OS_VERSION}"x != ""x ] ; then

    LogRuntimeInfo "Current OS version is \"${__OS_VERSION}\"; required OS version is \"${__REQUIRED_OS_VERSION}\""
    
    __OS_VERSION_OKAY=${__TRUE}
    
    __CUR_MAJOR_VER="${__OS_VERSION%.*}"
    __CUR_MINOR_VER="${__OS_VERSION#*.}"
  
    __REQ_MAJOR_VER="${__REQUIRED_OS_VERSION%.*}"
    __REQ_MINOR_VER="${__REQUIRED_OS_VERSION#*.}"

    [ "${__CUR_MAJOR_VER}" -lt "${__REQ_MAJOR_VER}" ] && __OS_VERSION_OKAY=${__FALSE}
    [ "${__CUR_MAJOR_VER}" -eq "${__REQ_MAJOR_VER}"  -a "${__CUR_MINOR_VER}" -lt "${__REQ_MINOR_VER}" ] && __OS_VERSION_OKAY=${__FALSE}
    
     [ ${__OS_VERSION_OKAY} = ${__FALSE} ] && die 248 "Unsupported OS Version: ${__OS_VERSION}; necessary OS version is ${__REQUIRED_OS_VERSION}"
      
  fi

  if [ "${__REQUIRED_MACHINE_PLATFORM}"x != ""x ] ; then
    pos " ${__MACHINE_PLATFORM} " " ${__REQUIRED_MACHINE_PLATFORM} " && \
      die 245 "This script can not run on this platform (${__MACHINE_PLATFORM}); necessary platforms are \"${__REQUIRED_MACHINE_PLATFORM}\""
  fi

  if [ "${__REQUIRED_MACHINE_CLASS}"x != ""x ] ; then
    pos " ${__MACHINE_CLASS} " " ${__REQUIRED_MACHINE_CLASS} " && \
      die 244 "This script can not run on this machine class (${__MACHINE_CLASS}); necessary machine classes are \"${__REQUIRED_MACHINE_CLASS}\""
  fi

  if [ "${__REQUIRED_MACHINE_ARC}"x != ""x ] ; then
    pos " ${__MACHINE_ARC} " " ${__REQUIRED_MACHINE_ARC} " && \
      die 243 "This script can not run on this machine architecture (${__MACHINE_ARC}); necessary machine architectures are \"${__REQUIRED_MACHINE_ARC}\""
  fi

  if  [ "${__ZONENAME}"x != ""x -a "${__OS}"x = "SunOS"x ] ; then
    case "${__REQUIRED_ZONES}" in 

     "global" ) 
       [ "${__ZONENAME}"x != "global"x ] && \
         die 239 "This script must run in the global zone; the current zone is \"${__ZONENAME}\""
       ;;

     "non-global" | "local" ) 
       [ "${__ZONENAME}"x = "global"x ] && \
         die 239 "This script can not run in the global zone"
       ;;

     "" ) :
       ;;
   
     * ) 
       pos " ${__ZONENAME} " " ${__REQUIRED_ZONES} " && \
         die 239 "This script must run in one of the zones \"${__REQUIRED_ZONES}\"; the current zone is \"${__ZONENAME}\" "
       ;;
       
    esac

  fi
    
  if [ ${__MUST_BE_ROOT} -eq ${__TRUE} ] ; then  
    UserIsRoot || die 249 "You must be root to execute this script" 
  fi

  if [ "${__REQUIRED_USERID}"x != ""x ] ; then
    pos " ${__USERID} "  " ${__REQUIRED_USERID} " && \
      die 242 "This script can only be executed by one of the users: ${__REQUIRED_USERID}"
  fi
        
  if [ ${__ONLY_ONCE} -eq ${__TRUE} ] ; then
    CreateLockFile
    if [ $? -ne 0 ] ; then
      PrintLockFileErrorMsg
      die 250
    fi

# remove the lock file at program end
    __EXITROUTINES="${__EXITROUTINES} RemoveLockFile"    
  fi

# __ABSOLUTE_SCRIPTDIR real absolute directory (no link)
  GetProgramDirectory "$0" __ABSOLUTE_SCRIPTDIR
  
# create temporary files
  CreateTemporaryFiles

# check for the parameter -C 
  if [   "${__WRITE_CONFIG_AND_EXIT}" = ${__TRUE} ] ; then
    NEW_CONFIG_FILE="${__CONFIG_FILE}"
     LogMsg "Creating the config file \"${NEW_CONFIG_FILE}\" ..."    
    WriteConfigFile "${NEW_CONFIG_FILE}"
    [ $? -ne 0 ] && die 246 "Error writing the config file \"${NEW_CONFIG_FILE}\""
    die 0 "Configfile \"${NEW_CONFIG_FILE}\" written successfully."    
  fi

}

 
## 
## ##### defined sub routines 
##

## --------------------------------------
## CheckParameterCount
##
## check the number of parameters for a function 
##
## usage: CheckParameterCount parametercount "$@"
##
## returns:  ${__TRUE} - the no of parameter is ok
##           ${__FALSE} - the no of parameter is not ok
##          
##
function CheckParameterCount {
  typeset __CALLED_BY="${__FUNCTION}"
   
  typeset __FUNCTION="CheckParameterCount";    ${__FUNCTION_INIT} ; ${__DEBUG_CODE}

  typeset THISRC=${__FALSE}

  typeset __PARAMETER_COUNT=$1
  shift
  
  if [ $# -eq ${__PARAMETER_COUNT} ] ; then
    THISRC=${__TRUE}
  else
    LogError "CheckParameterCount - Function \"${__CALLED_BY}\" called with $# parameters but the function expects ${__PARAMETER_COUNT} parameter"
    if [ $# -ne 0 ] ; then
      LogError "The parameter are:"
      typeset i=1
      while [ $# -ne 0 ] ; do
        LogError "\$$i : \"$1\" "
        (( i = i + 1 ))
        shift
      done
    fi
  fi

  return ${THISRC}
}


## ---------------------------------------
## ShowShortUsage
##
## print the (short) usage help
##
## usage: ShowShortUsage
##
## returns: 0
##
function ShowShortUsage {
  typeset __FUNCTION="ShowShortUsage";    ${__FUNCTION_INIT} ; ${__DEBUG_CODE}

  eval "__SHORT_USAGE_HELP=\"${__SHORT_USAGE_HELP}\""

cat <<EOT
  ${__SCRIPTNAME} ${__SCRIPT_VERSION} - ${__SHORT_DESC}

  Usage: ${__SCRIPTNAME} [-v|+v] [-q|+q] [-h] [-l logfile|+l] [-y|+y] [-n|+n] 
                    [-D|+D] [-a|+a] [-O|+O] [-f|+f] [-C] [-H] [-S n] [-V] [-T]
${__SHORT_USAGE_HELP}
  
EOT

  return 0
}


## ---------------------------------------
## ShowUsage
##
## print the (long) usage help
##
## usage: ShowUsage
##
## returns: 0
##
function ShowUsage {
  typeset __FUNCTION="ShowUsage";    ${__FUNCTION_INIT} ; ${__DEBUG_CODE}

  eval "__LONG_USAGE_HELP=\"${__LONG_USAGE_HELP}\""

  ShowShortUsage
cat <<EOT

 Note: Use -{switch} or --{longswitch} to turn an option on; 
       use +{switch} or ++{longswitch} to turn an option off

       The long format of the parameter (--parameter/++parameter) is not supported by all ksh implementations
       
       
    Parameter:

      -v|+v - turn verbose mode on/off; current value: $( ConvertToYesNo "${__VERBOSE_MODE}" )
              Long format: --verbose / ++verbose
      -q|+q - turn quiet mode on/off; current value: $( ConvertToYesNo "${__QUIET_MODE}" )
              Long format: --quiet / ++quiet
      -h    - show usage 
              Long format: --help
      -l    - set the logfile 
              current value: ${NEW_LOGFILE:=${__DEF_LOGFILE}}
              Long format: --logfile      
      +l    - do not write a logfile
              Long format: ++logfile
      -y|+y - assume yes to all questions or not
              Long format: --yes / ++yes 
      -n|+n - assume no to all questions or not
              Long format: --no /++no
      -D|+D - run main in single step mode (and turn colors on); current value: $( ConvertToYesNo "${__DEBUG_MODE}" )
              Long format: --debug / ++debug
      -a|+a - turn colors on/off; current value: $( ConvertToYesNo "${__USE_COLORS}" )
              Long format: --color / ++color
      -O|+O - overwrite existing files or not; current value: $( ConvertToYesNo "${__OVERWRITE_MODE}" )
              Long format: --overwrite / ++overwrite
      -f|+f - force; do it anyway; current value: $( ConvertToYesNo "${__FORCE}" )
              Long format: --force / ++force
      -C    - write a default config file in the current directory and exit
              Long format: --writeconfigfile
      -H    - write extended usage to STDERR and exit
              Long format: --doc
      -S n  - print error/warning summaries: 
              n = 0 no summariess, 1 = print error msgs,
              2 = print warning msgs, 3 = print error and warning mgs
              Current value: ${__PRINT_SUMMARIES}
              Long format: --summaries
      -V    - write version number to STDOUT and exit
              Long format: --version
      -T    - append STDOUT and STDERR to the file "${__TEE_OUTPUT_FILE}"
              Long format: --tee
${__LONG_USAGE_HELP}
EOT

  if [ ${__VERBOSE_LEVEL} -gt 1 ] ; then

    typeset ENVVARS="$( echo "${__USED_ENVIRONMENT_VARIABLES}" | tr "#" " " )"
    cat <<EOT
Environment variables that are used if set:

EOT

    for __CURVAR in ${ENVVARS} ; do
      echo "  ${__CURVAR} (Current value: \"$( eval echo \$${__CURVAR} )\")"
    done
  fi
      
  return 0      
}

# -----------------------------------------------------------------------------

## --------------------------------------
## PrintRuntimeVariables
##
## print the values of the runtime variables
##
## usage: PrintRuntimeVariables
##
## returns:  ${__TRUE} - ok
##           ${__FALSE} - error
##           ${__INVALID_USAGE} - invalid usage
##
##
function PrintRuntimeVariables {
  typeset __FUNCTION="PrintRuntimeVariables";    ${__FUNCTION_INIT} ; ${__DEBUG_CODE}

  typeset CURVAR CURVALUE

  typeset __RUNTIME_VARIABLES="
__KSH_VERSION
__SAVE_LANG
__SCRIPTNAME
__REAL_SCRIPTDIR
__CONFIG_FILE
__HOSTNAME
__NODENAME
__OS
__OS_VERSION
__ZONENAME
__OS_RELEASE
__MACHINE_CLASS
__START_DIR
__MACHINE_PLATFORM
__MACHINE_SUBTYPE
__MACHINE_ARC
__LOGFILE
__LOGIN_USERID
__USERID
__RUNLEVEL
"

# init the return code
  THISRC=${__INVALID_USAGE}

# check the parameter count
  CheckParameterCount 0 "$@" || die 240 "Internal error detected"

  if [ $# -eq 0 ] ; then
    THISRC=${_TRUE}

    for CURVAR in ${__RUNTIME_VARIABLES} ; do
      eval CURVALUE="\$${CURVAR}"
      LogMsg "Variable \"${CURVAR}\" is \"${CURVALUE}\" "
    done
  fi

  return ${THISRC}
}


# ??? add user defined subroutines here

## --------------------------------------
## ldom_defined
##
## check if a ldom defined
##
## usage: ldom_defined ldom
##
## returns:  ${__TRUE} - ok, ldom is defined
##           ${__FALSE} - ldom is not defined
##          
##
function ldom_defined {
  typeset __FUNCTION="ldom_defined";   ${__FUNCTION_INIT} ;  
  ${__DEBUG_CODE}

  typeset THISRC=${__FALSE}
  if [ $# -eq 1 ] ; then
    typeset THIS_LDOM="$1"
    echo "${LIST_OF_LDOMS}" | grep "^${THIS_LDOM}$" >/dev/null && \
      THISRC=${__TRUE}
  fi
  return ${THISRC}
}

## --------------------------------------
## ldom_status
##
## retrieve the ldom status
##
## usage: ldom_status ldom {print}
##
## returns:  ${__TRUE} - ok
##           ${__FALSE} - invalid usage     
##          
##
function ldom_status {
  typeset __FUNCTION="ldom_status";   ${__FUNCTION_INIT} ;  
  ${__DEBUG_CODE}

  typeset TEST
  typeset name=""
  typeset state=""
  typeset flags=""
  typeset cons=""
  typeset ncpu=""
  typeset mem=""
  typeset util=""
  typeset uptime=""
  
  typeset LDOM_STATUS=""
  
  typeset THISRC=${__FALSE}
  
  if [ "$1"x != ""x ] ; then
    THISRC=${__TRUE}
    typeset THIS_LDOM="$1"
    typeset THIS_ACTION="$2"
    
    eval TEST=$( ldm list -p ${THIS_LDOM}| grep DOMAIN | tr "|" ";" )    

    LDOM_NAME="$name"
    LDOM_STATE="$state"
    LDOM_FLAGS="$flags"
    LDOM_CONS="$cons"
    LDOM_NCPU="$ncpu"
    LDOM_MEM="$mem"
    LDOM_UTIL="$util"
    LDOM_UPTIME="$uptime"

    if [ "${THIS_ACTION}"x = "print"x ] ; then
      toUppercase "${THIS_LDOM}" THIS_LDOM1
      LDOM_STATUS="      
# status of the LDom  \"${THIS_DLOM}\": 
  ${THIS_LDOM1}_NAME=\"${LDOM_NAME}\"
  ${THIS_LDOM1}_STATE=\"${LDOM_STATE}\"
  ${THIS_LDOM1}_FLAGS=\"${LDOM_FLAGS}\"
  ${THIS_LDOM1}_CONS=\"${LDOM_CONS}\"
  ${THIS_LDOM1}_NCPU=\"${LDOM_NCPU}\"
  ${THIS_LDOM1}_MEM=\"${LDOM_MEM}\"
  ${THIS_LDOM1}_UTIL=\"${LDOM_UTIL}\"
  ${THIS_LDOM1}_UPTIME=\"${LDOM_UPTIME}\"
"
        print_ldm_output "${LDOM_STATUS}"
    fi

  fi
  return ${THISRC}
}


## --------------------------------------
## print_ldm_output
##
## print ldm output to the screen and the output file
##
## usage: print_ldm_output output 
##
## returns:  n/a
##
function print_ldm_output {
  typeset __FUNCTION="print_ldm_output";   ${__FUNCTION_INIT} ;  
  ${__DEBUG_CODE}

  typeset THISRC=${__FALSE}
  if [ $# -ne 0 ] ; then
    typeset THIS_MSG="$*"
    [ "${LDOM_OUTPUT_FILE}"x != ""x ] && echo "${THIS_MSG}" >>"${LDOM_OUTPUT_FILE}"
    echo "${THIS_MSG}"
    typeset THISRC=${__TRUE}
  fi

  return ${THISRC}
}


## --------------------------------------
## write_to_scriptfile
##
## write the commands to the screen and to the scriptfile
##
## usage: write_to_scriptfile output 
##
## returns:  n/a
##
function write_to_scriptfile {
  typeset __FUNCTION="write_to_scriptfile";   ${__FUNCTION_INIT} ;  
  ${__DEBUG_CODE}

  typeset THISRC=${__FALSE}
  if [ $# -ne 0 ] ; then
    typeset THIS_MSG="$*"
    [ "${LDOM_SCRIPT_FILE}"x != ""x ] && echo "${THIS_MSG}" >>"${LDOM_SCRIPT_FILE}"
    [ "${__QUIET_MODE}" = ${__FALSE} ] && echo "${THIS_MSG}"
    typeset THISRC=${__TRUE}
  fi

  return ${THISRC}
}

## --------------------------------------
## list_all_ldoms
##
## create the list of the defined LDoms
##
## usage: list_all_ldoms
##
## returns:  prints the list of LDoms to STDOUT
##
function list_all_ldoms {
  typeset __FUNCTION="list_all_ldoms";   ${__FUNCTION_INIT} ;  
  ${__DEBUG_CODE}

  typeset THISRC=${__TRUE}
  
  ${LDM_BINARY} list  | egrep -v "NAME" | tr -s " " | cut -f 1 -d " "
  
  return ${THISRC}
}

## --------------------------------------
## list_guest_ldoms
##
## create the list of the defined guest LDoms
##
## usage: list_guest_ldoms
##
## returns:  prints the list of Guest LDoms to STDOUT
##
function list_guest_ldoms {
  typeset __FUNCTION="list_guest_ldoms";   ${__FUNCTION_INIT} ;  
  ${__DEBUG_CODE}

  typeset THISRC=${__TRUE}
  
  ${LDM_BINARY} list  | egrep -v "NAME|primary" | tr -s " " | cut -f 1 -d " "
  
  return ${THISRC}
}


## --------------------------------------
## save_ldm_config
##
## save the ldm configuration to files and to the nvram
##
## usage: save_ldm_config {configname}
##
## parameter: configname - name of the ldm configuration, 
##                 default: production
##
## returns:  ${__TRUE} - okay, configuration saved
##              in case of an error the function aborts the script
##
##
function save_ldm_config {
  typeset __FUNCTION="save_ldm_config";   ${__FUNCTION_INIT} ;  
  ${__DEBUG_CODE}

  if [ "$1"x != ""x ] ; then
    typeset THIS_LDM_CONFIG_NAME="$1"
  else
    typeset THIS_LDM_CONFIG_NAME=${LDM_CONFIG_NAME}
  fi
  
  typeset THISRC=${__FALSE}

  typeset LDOM_SHORT_LIST="ldoms_short.list"
  typeset LDOM_LIST="ldoms.list"

  LogMsg "Saving the LDom configuration to \"${THIS_LDM_CONFIG_NAME}\" ..."
  
  [ "${LDM_SAVE_DIR}"x = ""x ] && die 55 "The variable LDM_SAVE_DIR not set"
  
  typeset THIS_LDM_SAVE_DIR="${LDM_SAVE_DIR}/${THIS_LDM_CONFIG_NAME}"
  
  if [ ! -d "${THIS_LDM_SAVE_DIR}" ] ; then
    LogInfo "Creating the directory \"${THIS_LDM_SAVE_DIR}\" ... "
    mkdir -p "${THIS_LDM_SAVE_DIR}" || \
      die 60 "Error $? creating the directory \"${THIS_LDM_SAVE_DIR}\" "
  fi
    
  cd "${THIS_LDM_SAVE_DIR}" || \
    die 65 "Error $? changing the working directory to \"${THIS_LDM_SAVE_DIR}\" "

  LogInfo "Creating \"${LDOM_SHORT_LIST}\" ...."
  ${LDM_BINARY} list >./"${LDOM_SHORT_LIST}" || \
   LogWarning "Error executing \"ldm list\" to create the file ${LDOM_SHORT_LIST}"

  LogInfo "Creating \"${LDOM_LIST}\" ...."
  ${LDM_BINARY} list -l >./"${LDOM_LIST}" || \
   LogWarning "Error executing \"ldm list -l\" to create the file ${LDOM_LIST}"
  
  LogInfo "Backing up  \"${LDM_CONFIG_DB}\" ..."
  cp "${LDM_CONFIG_DB}"  . || \
    LogWarning "Error copying \"${LDM_CONFIG_DB}\" to $( pwd )"
  
  for i in ${LIST_OF_LDOMS} ; do
    ${LDM_BINARY} list-constraints -x $i >"$i.xml" || \
      LogWarning "Error executing \"ldm list-constraints -x $i\" to create the file \"$i.xml\" "
   done

## save the configuration in the nvram
#
  ${LDM_BINARY} list-spconfig | egrep "^${THIS_LDM_CONFIG_NAME}$|^${THIS_LDM_CONFIG_NAME} \[next\]$|^${THIS_LDM_CONFIG_NAME} \[current\]$"  && ${LDM_BINARY} remove-spconfig "${THIS_LDM_CONFIG_NAME}"

  ${LDM_BINARY} add-spconfig "${THIS_LDM_CONFIG_NAME}" || \
    die 65 "Error $? executing \"ldm add-spconfig ${THIS_LDM_CONFIG_NAME}\" "

  LogMsg "LDom configuration saved."

}

## --------------------------------------
## list_ldom_vdisks
##
## create the list of vdisks of a LDom
##
## usage: list_ldom_vdisks ldom
##
## returns:  prints the list of vdisks to STDOUT
##
function list_ldom_vdisks {
  typeset __FUNCTION="list_ldom_vdisks";   ${__FUNCTION_INIT} ;  
  ${__DEBUG_CODE}

  typeset THISRC=${__FALSE}

  typeset THIS_LDOM="$1"

  typeset TEST=""
  typeset LINE=""
  LIST_OF_VDISKS=""
  name=""

  if [ "${THIS_LDOM}"x != ""x ] ; then
    ${LDM_BINARY} list -l -p "${THIS_LDOM}" | grep "^VDISK|" | while read LINE ; do
      eval "TEST=$( echo $LINE | tr "|" ";" )" 
      LIST_OF_VDISKS="${LIST_OF_VDISKS} $name"
    done

#    typeset LIST_OF_VDISKS="$( ${LDM_BINARY} list -l "${THIS_LDOM}" | grep " disk@" | tr -s " " | cut -f2 -d " " )"
   
    LogInfo "Defined vdisks for the LDom \"${THIS_LDOM}\": "
    LogInfo "${LIST_OF_VDISKS}"
   
    echo "${LIST_OF_VDISKS}"

    THISRC=${__TRUE}
  fi
  
  return ${THISRC}
}


## --------------------------------------
## retrieve_ldom_vdisksserverdevice
##
## print the configuration of a vdiskserverdevice
##
## usage: retrieve_ldom_vdiskserverdevice ldom vdiskserverdevice {print}
##
## returns:  prints the vdiskserverdevice configuration to STDOUT
##
function retrieve_ldom_vdiskserverdevice {
  typeset __FUNCTION="retrieve_ldom_vdiskserverdevice";   ${__FUNCTION_INIT} ;  
  ${__DEBUG_CODE}

  typeset THISRC=${__FALSE}

  typeset THIS_LDOM="$1"
  typeset THIS_VDISKSERVER_DEVICE="$2"
  typeset THIS_ACTION="$3"

  typeset TEST=""
  
  VDISKSERVER_DEVICE_VOLUME=""
  VDISKSERVER_DEVICE_BACKEND=""
  VDISKSERVER_DEVICE_OPTS=""
  VDISK_SERVER_DEVICE_STATUS=""

  vol=""
  dev=""
  opts=""

  if [ "${THIS_LDOM}"x != ""x -a "${THIS_VDISKSERVER_DEVICE}"x != ""x ] ; then

    eval TEST=$( ${LDM_BINARY} list -l -p "${THIS_LDOM}" | grep "${THIS_VDISKSERVER_DEVICE}|" | tr "|" ";" )

    if [ "${vol}"x != ""x ] ; then

      VDISKSERVER_DEVICE_VOLUME="$vol"
      VDISKSERVER_DEVICE_BACKEND="$dev"
      VDISKSERVER_DEVICE_OPTS="$opts"

      if [ -b "${VDISKSERVER_DEVICE_BACKEND}" -o -c "${VDISKSERVER_DEVICE_BACKEND}" ] ; then
        VDISK_SERVER_DEVICE_STATUS="$( ls -l ${VDISKSERVER_DEVICE_BACKEND} )"
      elif  [ -L "${VDISKSERVER_DEVICE_BACKEND}" ] ; then
        VDISK_SERVER_DEVICE_STATUS="$( echo;  ls -l ${VDISKSERVER_DEVICE_BACKEND} ; ls -lL ${VDISKSERVER_DEVICE_BACKEND} )"
      elif [ -f "${VDISKSERVER_DEVICE_BACKEND}" ] ; then
        VDISK_SERVER_DEVICE_STATUS="$( echo ;  ls -l ${VDISKSERVER_DEVICE_BACKEND}; df -k $( dirname ${VDISKSERVER_DEVICE_BACKEND}) )"
      else
        VDISK_SERVER_DEVICE_STATUS="$( echo \"File ${VDISKSERVER_DEVICE_BACKEND} not found or type not known: \" ; ls -l ${VDISKSERVER_DEVICE_BACKEND} ) "
      fi
    fi

    if [ "${THIS_ACTION}"x = "print"x ] ; then
      toUppercase "${THIS_VDISKSERVER_DEVICE}" THIS_VDISKSERVER_DEVICE1
      VDISKSERVERDEVICE_CONFIGURATION="
# configuration for the vdisk server device \"${THIS_VDISKSERVER_DEVICE}\" in the LDom \"${LDOM}\": 
  ${THIS_VDISKSERVER_DEVICE}_VDISKSERVER_DEVICE_VOLUME=\"${VDISKSERVER_DEVICE_VOLUME}\"
  ${THIS_VDISKSERVER_DEVICE}_VDISK_SERVER_DEVICE_BACKEND=\"${VDISKSERVER_DEVICE_BACKEND}\"
  ${THIS_VDISKSERVER_DEVICE}_VDISK_SERVER_DEVICE_STATUS=\"${VDISK_SERVER_DEVICE_STATUS}\"
"
        print_ldm_output "${VDISKSERVERDEVICE_CONFIGURATION}"

    fi
  fi

}

## --------------------------------------
## retrieve_ldom_vdisk_verbose
##
## print the vdisk configuration
##
## usage: retrieve_ldom_vdisk_verbose ldom vdisk {print}
##
## returns:  prints the configuration of the vdisk to STDOUT
##
function retrieve_ldom_vdisk_verbose {
  typeset __FUNCTION="retrieve_ldom_vdisk_verbose";   ${__FUNCTION_INIT} ;  
  ${__DEBUG_CODE}

  typeset THISRC=${__FALSE}

  typeset THIS_LDOM="$1"
  typeset THIS_VDISK="$2"
  typeset THIS_ACTION="$3"

  typeset TEST=""

  VDISK_NAME=""
  VDISK_VOLUME=""
  VDISK_DEVICE=""
  VDISK_SERVER=""
    
  VDISK_DISKSERVER=""
  VDISK_DISKSERVERDEVICE=""

  name=""
  vol=""
  dev=""
  server=""
  
  if [ "${THIS_LDOM}"x != ""x -a "${THIS_VDISK}"x != ""x ] ; then

    eval TEST=$( ${LDM_BINARY} list -l -p  "${THIS_LDOM}" | grep "name=${THIS_VDISK}" | tr "|" ";" )
    if [ "${name}"x != ""x ]  ; then

      VDISK_NAME="$name"
      VDISK_VOLUME="$vol"
      VDISK_DEVICE="$dev"
      VDISK_SERVER="$server"

      VDISK_DISKSERVER="${VDISK_VOLUME#*@}"
      VDISK_DISKSERVERDEVICE="${VDISK_VOLUME%@*}"

      retrieve_ldom_vdiskserverdevice "primary"  "${VDISK_DISKSERVERDEVICE}"
    fi
    
    if [ "${THIS_ACTION}"x = "print"x ] ; then
      toUppercase "${THIS_VDISK}" THIS_VDISK1
      VDISK_CONFIGURATION="
# configuraton for the vdisk \"${THIS_VDISK}\" in the LDom \"${THIS_LDOM}\"      
  ${THIS_VDISK1}_VDISK_NAME=\"${VDISK_NAME}\"
  ${THIS_VDISK1}_VDISK_VOLUME=\"${VDISK_VOLUME}\"
  ${THIS_VDISK1}_VDISK_DEVICE=\"${VDISK_DEVICE}\"
  ${THIS_VDISK1}_VDISK_SERVER=\"${VDISK_SERVER}\"
# configuration for the vdisk server device \"${VDISK_DISKSERVERDEVICE}\" in the LDom \"${VDISK_DISKSERVER}\": 
  ${THIS_VDISK1}_VDISKSERVER_DEVICE_VOLUME=\"${VDISKSERVER_DEVICE_VOLUME}\"
  ${THIS_VDISK1}_VDISK_SERVER_DEVICE_BACKEND=\"${VDISKSERVER_DEVICE_BACKEND}\"
  ${THIS_VDISK1}_VDISK_SERVER_DEVICE_STATUS=\"${VDISK_SERVER_DEVICE_STATUS}\"
"      
      print_ldm_output "${VDISK_CONFIGURATION}"

    fi
  fi
  
  return ${THISRC}
}

## --------------------------------------
## list_ldom_vdiskserverdevices
##
## create the list of vdiskserverdevices of a LDom
##
## usage: list_ldom_vdiskserverdevices ldom {print}
##
## returns:  prints the list of vdisks to STDOUT
##
function list_ldom_vdiskserverdevices {
  typeset __FUNCTION="list_ldom_vdiskserverdevices";   ${__FUNCTION_INIT} ;  
  ${__DEBUG_CODE}

  typeset THISRC=${__FALSE}

  typeset THIS_LDOM="$1"
  typeset THIS_ACTION="$2"
  typeset VDISKSERVER_DEVICE_FOUND=${__FALSE}
  
  typeset TEST=""
  typeset LINE=""
  vol=""
  
  if [ "${THIS_LDOM}"x != ""x ] ; then
    ${LDM_BINARY} list -l -p "${THIS_LDOM}"   | grep "vol=" | while read line ; do
      VDISKSERVER_DEVICE_FOUND=${__TRUE}
      eval TEST=$( echo $line | tr "|" ";" )

      retrieve_ldom_vdisk_verbose "${THIS_LDOM}" "${vol}" "${THIS_ACTION}"
    done
    
    [ ${VDISKSERVER_DEVICE_FOUND} = ${__FALSE} -a "${THIS_ACTION}"x = "print"x ]  && \
      LogMsg  "No vdiskserverdevices found for the LDom \"${THIS_LDOM}\" "
  fi

  return ${THISRC}
}


## --------------------------------------
## list_ldom_vnets
##
## create the list of vnets of a LDom
##
## usage: list_ldom_vnets ldom
##
## returns:  prints the list of vnets to STDOUT
##
function list_ldom_vnets {
  typeset __FUNCTION="list_ldom_vnets";   ${__FUNCTION_INIT} ;  
  ${__DEBUG_CODE}

  typeset THISRC=${__FALSE}
  typeset THIS_LDOM="$1"
  
#  typeset LIST_OF_VNETS="$( ${LDM_BINARY} list -l "${THIS_LDOM}" | grep network@ | tr -s " " | cut -f2 -d " " )"
   
  typeset TEST=""
  typeset LINE=""
  LIST_OF_VNETS=""
  name=""

  if [ "${THIS_LDOM}"x != ""x ] ; then
    ${LDM_BINARY} list -l -p "${THIS_LDOM}" | grep "^VNET|" | while read LINE ; do
      eval "$( echo $LINE | cut -f2 -d "|" | tr "|" ";" )" 
      LIST_OF_VNETS="${LIST_OF_VNETS} $name"
    done
  fi


  LogInfo "Defined vnets for the LDom \"${THIS_LDOM}\": "
  LogInfo ${LIST_OF_VNETS}

  echo "${LIST_OF_VNETS}"
}

## --------------------------------------
## list_ldom_vswitches
##
## create the list of vwitches of a LDom
##
## usage: list_ldom_vswitches ldom
##
## returns:  prints the list of vswitches to STDOUT
##
function list_ldom_vswitches {
  typeset __FUNCTION="list_ldom_vswitches";   ${__FUNCTION_INIT} ;  
  ${__DEBUG_CODE}

  typeset THISRC=${__FALSE}
  typeset THIS_LDOM="$1"
  
#   typeset LIST_OF_VSWITCHES="$( ${LDM_BINARY} list -l "${THIS_LDOM}" | grep switch@ | tr -s " " | cut -f2 -d " " )"

  typeset TEST=""
  typeset LINE=""
  LIST_OF_VSWITCHES=""
  name=""

  if [ "${THIS_LDOM}"x != ""x ] ; then
    ${LDM_BINARY} list -l -p "${THIS_LDOM}" | grep "^VSW|" | while read LINE ; do
      eval "$( echo $LINE | cut -f2 -d "|" | tr "|" ";" )" 
      LIST_OF_VSWITCHES="${LIST_OF_VSWITCHES} $name"
    done
  fi

  LogInfo "Defined vswitches for the LDom \"${THIS_LDOM}\": "
  LogInfo "${LIST_OF_VSWITCHES}"
   
   echo "${LIST_OF_VSWITCHES}"
}


## --------------------------------------
## retrieve_vnet_config 
##
## retrieve and print the vnet configuration
##
## usage: retrieve_vnet_config ldom vnet {print}
##
## returns:  n/a
##
function retrieve_vnet_config {
  typeset __FUNCTION="retrieve_vnet_config";   ${__FUNCTION_INIT} ;  
  ${__DEBUG_CODE}

  typeset THISRC=${__FALSE}

  typeset THIS_LDOM="$1"
  typeset THIS_VNET="$2"
  typeset THIS_ACTION="$3"

  typeset TEST=""

  VNET_NAME=""
  VNET_SERVICE=""
  VNET_DEVICE=""
  VNET_MAC=""
  
  SERVICE_NAME=""
  SERVICE_MAC=""
  SERVICE_NETDEV=""
  SERVICE_DEVICE=""
  SERVICE_MODE=""

  VNET_DEVICE_IN_LDOM=""

  NETDEV_MAC=""

  name=""
  service=""
  dev=""
  mac_addr=""
  
  if [ "${THIS_LDOM}"x != ""x -a "${THIS_VNET}"x != ""x ] ; then
    LogInfo "Retrieving the configuration for the vnet \"${THIS_VNET}\" from the LDom \"${THIS_LDOM}\" ..."

    eval TEST="$( ${LDM_BINARY} list -p -l "${THIS_LDOM}" | grep "name=${THIS_VNET}" | sed "s/mac-addr/mac_addr/g" | tr "|" ";" )"
    
#    ${LDM_BINARY} list -l "${THIS_LDOM}"  | grep " ${THIS_VNET} "  | tr -s " " | read VNET_NAME VNET_SERVICE VNET_DEVICE VNET_MAC
#    if [ "${VNET_NAME}"x != ""x ] ; then

    if [ "${name}"x != ""x ] ; then
      VNET_NAME="$name"
      VNET_SERVICE="$service"
      VNET_DEVICE="$dev"
      VNET_MAC="${mac_addr}"
      
      SERVICE_LDOM="${VNET_SERVICE#*@}"
      SERVICE_SWITCH="${VNET_SERVICE%@*}"
      retrieve_vswitch_config  "${SERVICE_LDOM}" "${SERVICE_SWITCH}" 
    fi

    [ "${VNET_DEVICE}"x != ""x ] && VNET_DEVICE_IN_LDOM="vnet${VNET_DEVICE#*@}"
    
    if [ "${THIS_ACTION}"x = "print"x ] ; then
      toUppercase "${THIS_VNET}" THIS_VNET1
      VNET_CONFIGURATION="
# configuration for \"${THIS_VNET}\" in the LDom \"${LDOM}\": 
  ${THIS_VNET1}_VNET_NAME=\"${VNET_NAME}\"
  ${THIS_VNET1}_VNET_SERVICE=\"${VNET_SERVICE}\"
  ${THIS_VNET1}_VNET_DEVICE_IN_LDOM=\"${VNET_DEVICE_IN_LDOM}\"
  ${THIS_VNET1}_VNET_MAC=\"${VNET_MAC}\"
# switch configuration in the LDom \"${SERVICE_LDOM}\":
  ${THIS_VNET1}_SERVICE_NAME=\"${SERVICE_NAME}\"
  ${THIS_VNET1}_SERVICE_MAC=\"${SERVICE_MAC}\"
  ${THIS_VNET1}_SERVICE_NETDEV=\"${SERVICE_NETDEV}\"
  ${THIS_VNET1}_SERVICE_DEVICE=\"${SERVICE_DEVICE}\"
  ${THIS_VNET1}_SERVICE_SWITCH_DEVICE=\"${SERVICE_SWITCH_DEVICE}\"
  ${THIS_VNET1}_SERVICE_SWITCH=\"${SERVICE_SWITCH}\"
${THIS_VNET1}_SERVICE_MODE=\"${SERVICE_MODE}\"
# Virtual Switch configuration for the switch \"${VSWITCH_NAME}\" 
  ${THIS_VNET1}_VSWITCH_MAC=\"${VSWITCH_MAC}\"
# Network adapter configuration for \"${SERVICE_NETDEV}\":
  ${THIS_VNET1}_NETDEV_MAC=\"${NETDEV_MAC}\"
"

        print_ldm_output "${VNET_CONFIGURATION}"

    fi
  fi
  return 0
}


## --------------------------------------
## retrieve_vswitch_config 
##
## retrieve and print the vswitch configuration
##
## usage: retrieve_vswitch_config  ldom vswitch {print}
##
## returns:  n/a
##
function retrieve_vswitch_config {
  typeset __FUNCTION="retrieve_vswitch_config";   ${__FUNCTION_INIT} ;  
  ${__DEBUG_CODE}

  typeset THISRC=${__FALSE}

  typeset THIS_LDOM="$1"
  typeset THIS_VSWITCH="$2"
  typeset THIS_ACTION="$3"
  
  typeset TEST=""
  
  SERVICE_NAME=""
  SERVICE_MAC=""
  SERVICE_NETDEV=""
  SERVICE_DEVICE=""
  SERVICE_MODE=""

  NETDEV_MAC=""

  name=""
  mac_addr=""
  net_dev=""
  mode=""
  
  if [ "${THIS_LDOM}"x != ""x -a "${THIS_VSWITCH}"x != ""x ] ; then

#      SERVICE_LDOM="${THIS_LDOM}"
#      VSERVICE_SWITCH="${THIS_VSWITCH}"
#      ${LDM_BINARY} list -l "${SERVICE_LDOM}" | grep "${SERVICE_VSWITCH}" | read SERVICE_NAME SERVICE_MAC SERVICE_NETDEV SERVICE_DEVICE SERVICE_MODE

    eval TEST="$( ${LDM_BINARY} list -p -l "${THIS_LDOM}" | grep "name=${THIS_VSWITCH}|" | \
       sed -e "s/mac-addr/mac_addr/g" -e "s/net-dev/net_dev/g" | tr "|" ";" )"

    SERVICE_NAME="$name"
    SERVICE_MAC="$mac_addr"
    SERVICE_NETDEV="$net_dev"
    SERVICE_NETDEV_STATUS=""
    SERVICE_DEVICE="$dev"
    SERVICE_MODE="$mode"
    SERVICE_SWITCH_DEVICE=""

    if [ "${SERVICE_NETDEV}"x != ""x ] ; then

      NETDEV_MAC="$( ifconfig "${SERVICE_NETDEV}" 2>/dev/null | grep ether | cut -f2 -d " " )"

      if [ "${NETDEV_MAC}"x = ""x ] ; then
        ifconfig "${SERVICE_NETDEV}" plumb  2>/dev/null
        NETDEV_MAC="$( ifconfig "${SERVICE_NETDEV}" 2>/dev/null | grep ether | cut -f2 -d " " )"
        ifconfig "${SERVICE_NETDEV}" unplumb 2>/dev/null
      fi

      if [ "${SERVICE_DEVICE}"x != ""x ] ; then
        VSWITCH_NUMBER="${SERVICE_DEVICE#*@}"
        VSWITCH_NAME="vsw${VSWITCH_NUMBER}"
        VSWITCH_MAC="$( ifconfig "${VSWITCH_NAME}"  2>/dev/null | grep ether | cut -f2 -d " " )"
        if [ "${VSWITCH_MAC}"x = ""x ] ; then
          ifconfig "${VSWITCH_NAME}" plumb 2>/dev/null
          VSWITCH_MAC="$( ifconfig "${VSWITCH_NAME}" 2>/dev/null | grep ether | cut -f2 -d " " )"
          ifconfig "${VSWITCH_NAME}" unplumb 2>/dev/null
        fi
      fi

    fi

    [ "${SERVICE_NETDEV}"x != ""x ] && SERVICE_NETDEV_STATUS="$( dladm show-dev ${SERVICE_NETDEV} )"
    [ "${SERVICE_DEVICE}"x != ""x ] && SERVICE_SWITCH_DEVICE="vsw${SERVICE_DEVICE#*@}"

    if [ "${THIS_ACTION}"x = "print"x ] ; then
      THIS_VSWITCH1="$( toUppercase "${THIS_VSWITCH}"  | tr "-" "_" )"
      VSWITCH_CONFIGURATION="
# configuration of the switch \"${SERVICE_NAME}\" in the LDom \"${THIS_LDOM}\":
  ${THIS_VSWITCH1}_SERVICE_NAME=\"${SERVICE_NAME}\"
  ${THIS_VSWITCH1}_SERVICE_MAC=\"${SERVICE_MAC}\"
  ${THIS_VSWITCH1}_SERVICE_NETDEV=\"${SERVICE_NETDEV}\"
  ${THIS_VSWITCH1}_SERVICE_NETDEV_STATUS=\"${SERVICE_NETDEV_STATUS}\"
  ${THIS_VSWITCH1}_SERVICE_DEVICE=\"${SERVICE_DEVICE}\"
  ${THIS_VSWITCH1}_SERVICE_SWITCH_DEVICE=\"${SERVICE_SWITCH_DEVICE}\"
  ${THIS_VSWITCH1}_SERVICE_MODE=\"${SERVICE_MODE}\"
# Virtual Switch configuration for the switch \"${VSWITCH_NAME}\" 
  ${THIS_VSWITCH1}_VSWITCH_MAC=\"${VSWITCH_MAC}\"
# Network adapter configuration for \"${SERVICE_NETDEV}\":
  ${THIS_VSWITCH1}_NETDEV_MAC=\"${NETDEV_MAC}\"
"
        print_ldm_output "${VSWITCH_CONFIGURATION}"

    fi
  fi
  return 0
}

# -----------------------------------------------------------------------------


## --------------------------------------
## execute_commands
##
## execute config commands or write them to the script file
##
## 
## usage: COMMANDS_TO_EXECUTE=<commands> 
##          execute_commands  [message]
##
## returns:  n/a
##
function execute_commands {
  typeset __FUNCTION="execute_commands";   ${__FUNCTION_INIT} ;  
  ${__DEBUG_CODE}

  typeset THISRC=${__TRUE}
  typeset THIS_MESSAGE="$*"

  if [ "${LDOM_SCRIPT_FILE}"x != ""x ] ; then       
    write_to_scriptfile "${COMMANDS_TO_EXECUTE}"
  else
    typeset THISRC=${__FALSE}
    [ "${THIS_MESSAGE}"x != ""x ] && LogMsg "${THIS_MESSAGE}"
    eval "( set -x -v ; ${COMMANDS_TO_EXECUTE} )"
  fi

  return ${THISRC}
}

# -----------------------------------------------------------------------------
# main:
#
  
# trace main routine
#
# set -x

# Note: This statement seems to be necessary to use ${LINENO} in the trap statement
#
  LINENO=${LINENO}

# install trap handler
   __settrap

  trap 'GENERAL_SIGNAL_HANDLER EXIT  ${LINENO} ${__FUNCTION}' exit
  

# trace also all function defined before this line (!)
#
# typeset -ft $( typeset +f )

  InitScript $*


# init variables with the defaults
#
# format var=${DEFAULT_var}
#

# to process all variables beginning with DEFAULT_ use 
#
  for CURVAR in $( set | grep "^DEFAULT_"  | cut -f1 -d"=" ) ; do
    P1="${CURVAR%%=*}"
    P2="${P1#DEFAULT_*}"

# for debugging
#    push_and_set __VERBOSE_MODE ${__TRUE}
#    push_and_set __VERBOSE_LEVEL ${__RT_VERBOSE_LEVEL}
#    LogInfo 0 "Setting variable $P2= \"$( eval "echo \"\$$P1\"")\" "
#    pop __VERBOSE_MODE
#    pop __VERBOSE_LEVEL
        
    eval "$P2="\"\$$P1\"""
   
  done

    
# --- variables for the cleanup routine:
#
# add mounts that should be automatically be unmounted at script end to this variable
#
#  __LIST_OF_TMP_MOUNTS="${__LIST_OF_TMP_MOUNTS} "

# add directories that should be automatically removed at script end to this variable
#
#  __LIST_OF_TMP_DIRS="${__LIST_OF_TMP_DIRS} "

# add files that should be automatically removed at script end to this variable
#  __LIST_OF_TMP_FILES="${__LIST_OF_TMP_FILES} "

# add functions that should be called automatically at program end to this variable
# before removing temporary files, directories, and mounts
#
#  __EXITROUTINES="${__EXITROUTINES} "    

# add functions that should be called automatically at program end to this variable 
# after removing temporary files, directories, and mounts
#
# __FINISHROUTINES="${__FINISHROUTINES}"

# variables used by getopts:
#    OPTIND = index of the current argument
#    OPTARG = current function character
#
  THIS_PARAMETER="$*"
  
  LogRuntimeInfo "Parameter before getopts processing are: \"${THIS_PARAMETER}\" "

  INVALID_PARAMETER_FOUND=${__FALSE}

  __PRINT_USAGE=${__FALSE}
  CUR_SWITCH=""
  OPTARG=""

# ??? add additional switch characters here
#
  [ "${__OS}"x = "Linux" ] &&  GETOPT_COMPATIBLE="0"

  __GETOPTS="+:ynvqhHDfl:aOS:CVTx:o:d:Ac:s:"
  if [ "${__OS}"x = "SunOS"x  ] ; then
    if [ "${__OS_VERSION}"x  = "5.10"x -o  "${__OS_VERSION}"x  = "5.11"x ] ; then
      __GETOPTS="+:y(yes)n(no)v(verbose)q(quiet)h(help)H(doc)D(debug)f(force)l:(logfile)a(color)O(overwrite)S:(summaries)C(writeconfigfile)V(version)T(tee)x:(task)d:(ldom)o:(outputfile)A(all_guestldoms)c:(comment)s:(scriptfile)"
    fi
  fi

  while getopts ${__GETOPTS} CUR_SWITCH  ; do

# for debugging only
#
# -----------------------------------------------------------------------------
# Debug Hint
#
# Use
#
#     __PRINT_ARGUMENTS=0 
#
# to debug the parameter handling
#
# -----------------------------------------------------------------------------
    if [  "${__PRINT_ARGUMENTS}" = "${__TRUE}" ] ; then 
      LogMsg "CUR_SWITCH is $CUR_SWITCH"
      LogMsg "OPTIND = $OPTIND"
      LogMsg "OPTARG = $OPTARG"
      LogMsg "\$* is \"$*\" "
    fi
    
    if [ "${CUR_SWITCH}" = ":" ] ; then
      CUR_SWITCH=${OPTARG}
      OPTARG=""
    fi

    LogInfo "Processing the parameter switch \"${CUR_SWITCH}\" with the argument \"${OPTARG}\" "
    
    case ${CUR_SWITCH} in 
    
       "C" ) __WRITE_CONFIG_AND_EXIT=${__TRUE} ;;

      "+D" ) __DEBUG_MODE=${__FALSE}  ;;
      
       "D" ) __DEBUG_MODE=${__TRUE} ; __USE_COLORS=${__TRUE} ;;

      "+v" ) __VERBOSE_MODE=${__FALSE}  ;;

       "v" ) __VERBOSE_MODE=${__TRUE} ; (( __VERBOSE_LEVEL=__VERBOSE_LEVEL+1 )) ;;

      "+q" ) __QUIET_MODE=${__FALSE} ;;

       "q" ) __QUIET_MODE=${__TRUE} ;;

      "+a" ) __USE_COLORS=${__FALSE} ;;

      "a"  ) __USE_COLORS=${__TRUE} ;;

      "+O" ) __OVERWRITE_MODE=${__FALSE} ;;

       "O" ) __OVERWRITE_MODE=${__TRUE} ;;

       "f" ) __FORCE=${__TRUE} ;;

      "+f" ) __FORCE=${__FALSE} ;;
       
       "l" ) NEW_LOGFILE="${OPTARG:=nul}" ;;

      "+l" ) NEW_LOGFILE="nul" ;;

      "+h" ) __VERBOSE_MODE=${__TRUE}
             __PRINT_USAGE=${__TRUE} 
             ;;

       "h" ) __PRINT_USAGE=${__TRUE} ;;

       "T" ) : # parameter already processed but only as first parameter
#                [ ${OPTIND} != 1 ] && LogWarning "The parameter -T must be the first parameter if used"
             ;;
       
       "H" ) 

echo " -----------------------------------------------------------------------------------------------------" >&2
echo "                         ${__SCRIPTNAME} ${__SCRIPT_TEMPLATE_VERSION} ">&2
echo "                                Documentation" >&2
echo " -----------------------------------------------------------------------------------------------------" >&2

             grep "^##" "$0" | cut -c3- 1>&2 ; die 0 ;;
                  

       "V" ) LogMsg "Script version: ${__SCRIPT_VERSION}"
             if [ ${__VERBOSE_MODE} = ${__TRUE} ] ; then
               LogMsg "Script template version: ${__SCRIPT_TEMPLATE_VERSION}"
             fi
             die 0 ;;
                

      "+y" ) __USER_RESPONSE_IS="" ;;

       "y" ) __USER_RESPONSE_IS="y" ;;

      "+n" ) __USER_RESPONSE_IS="" ;;

       "n" ) __USER_RESPONSE_IS="n" ;;

       "S" ) case ${OPTARG} in

                0 | 1 | 2 | 3 ) __PRINT_SUMMARIES=${OPTARG}
                                    ;;

                * )  LogError "Unknown value for -S found: \"${OPTARG}\""
                      INVALID_PARAMETER_FOUND=${__TRUE}
                      ;;
                esac
                ;;


# ??? add additional parameter here
     
        "A" ) PROCESS_ALL_GUEST_LDOMS=${__TRUE} 
                ;;
        
       "+A" ) PROCESS_ALL_GUEST_LDOMS=${__FALSE} 
                ;;

        "x" ) case ${OPTARG} in
                configure_primary_network )
                  LDOM_TASKS="${LDOM_TASKS} set_vswitches_mac_address configure_vswitches activate_vswitches"
                  ;;
                  
                * )
                  LDOM_TASKS="${LDOM_TASKS} $( echo ${OPTARG} | tr "," " " ) "
                  ;;
              esac
                ;;

         "o" ) LDOM_OUTPUT_FILE="${OPTARG}"
                ;;

         "s" ) LDOM_SCRIPT_FILE="${OPTARG}"
                ;;

         "d" ) LDOM_TASKS="${LDOM_TASKS} SWITCH_LDOM:${OPTARG}"
                 ;;

         "c" )  NEW_COMMENT="$( echo ${OPTARG} | tr " " "^" )"
                  LDOM_TASKS="${LDOM_TASKS} SWITCH_COMMENT:${NEW_COMMENT}"
                 ;;

        \? ) LogError "Unknown parameter found: \"${OPTARG}\" "
             INVALID_PARAMETER_FOUND=${__TRUE}
             break
          ;;

         * ) LogError "Unknown parameter found: \"${CUR_SWITCH}\""
             INVALID_PARAMETER_FOUND=${__TRUE}
             break ;;             

    esac
  done

  case ${__PRINT_SUMMARIES} in 
     0 )  __PRINT_LIST_OF_WARNINGS_MSGS=${__FALSE} 
          __PRINT_LIST_OF_ERROR_MSGS=${__FALSE}
          ;;

    1 )   __PRINT_LIST_OF_WARNINGS_MSGS=${__FALSE} 
          __PRINT_LIST_OF_ERROR_MSGS=${__TRUE}
          ;;

    2 )   __PRINT_LIST_OF_WARNINGS_MSGS=${__TRUE} 
          __PRINT_LIST_OF_ERROR_MSGS=${__FALSE}
          ;;

    3 )   __PRINT_LIST_OF_WARNINGS_MSGS=${__TRUE} 
          __PRINT_LIST_OF_ERROR_MSGS=${__TRUE}
          ;;

    * ) : this should never happen but who knows ...
          __PRINT_LIST_OF_WARNINGS_MSGS=${__FALSE} 
          __PRINT_LIST_OF_ERROR_MSGS=${__FALSE}
  esac
    
  LogRuntimeInfo "Parameter after processing the default parameter are: " "\"$*\" "

  if [ ${__PRINT_USAGE} = ${__TRUE} ] ; then
    if [ ${__VERBOSE_MODE} -eq ${__TRUE} ] ; then
      ShowUsage 
      __VERBOSE_MODE=${__FALSE}
    else
      ShowShortUsage 
      LogMsg "Use \"-v -h\", \"-v -v -h\" or \"+h\" for a long help text"
    fi
    die 1 ;   
  fi

  shift $(( OPTIND - 1 ))

  NOT_PROCESSED_PARAMETER="$*"

  LogRuntimeInfo "Not processed parameter: \"${NOT_PROCESSED_PARAMETER}\""

  if [ "${NOT_PROCESSED_PARAMETER}"x = "configure_primary_network"x ] ; then
    LDOM_TASKS="${LDOM_TASKS} set_vswitches_mac_address configure_vswitches activate_vswitches"
    NOT_PROCESSED_PARAMETER=""
  fi

# ??? add parameter checking code here 
#
# set INVALID_PARAMETER_FOUND to ${__TRUE} if the script
# should abort due to an invalid parameter 
#
  if [ "${NOT_PROCESSED_PARAMETER}"x != ""x ] ; then
    LDOM_TASKS="${LDOM_TASKS} ${NOT_PROCESSED_PARAMETER}"

#    LogError "Unknown parameter: \"${NOT_PROCESSED_PARAMETER}\" "
#    INVALID_PARAMETER_FOUND=${__TRUE}
  fi

  if [ "${LDOM_TASKS}"x = ""x  ] ; then
     ShowShortUsage 
    die 1
  fi

# exit the program if there are one or more invalid parameter
#
  if [ ${INVALID_PARAMETER_FOUND} -eq ${__TRUE} ] ; then
    LogError "One or more invalid parameters found"
    ShowShortUsage
    die 2
  fi

  SetEnvironment
   
  if [ "${__DEBUG_MODE}" -eq ${__TRUE} ] ; then
     __LIST_OF_TMP_FILES="${__LIST_OF_TMP_FILES} ${__DEBUG_HISTFILE}"

    trap "__LAST_RC=\$?; __LAST_BG_RC=\$!; __LINENO=\${LINENO}; DebugHandler"  DEBUG
:
    echo "INFO: Starting single step mode - works only for the main routine!"
  fi
 
# restore the language setting
#
  LANG=${__SAVE_LANG}
  export LANG
  
# execute test suite if available
#
# [ -f "./scriptt_test.sh" ] && includeScript "./scriptt_test.sh"

# print some of the runtime variables
#
#  PrintRuntimeVariables

# print all internal variables
#
  if [ 0 = 1 ] ; then
    for i in $( set | grep "^__" | cut -f1 -d"=" ) ; do
     if [[ $i != __COLOR* ]] ; then
        echo "$i : \"$( eval echo \"\$$i\" )\" "
      else
         echo "$i is set "
      fi
    done
  fi

# ldm config db
#
  LDM_CONFIG_DB="/var/opt/SUNWldm/ldom-db.xml"

# check  if ldm is necessary for the current tasks
#
  LDM_NECESSARY=${__FALSE}
  
  for i in ${LDOM_TASKS} ; do
    case ${i} in
      configure_install_network | test_guest ) 
        :
        ;;
        
      * )
        LDM_NECESSARY=${__TRUE}
        ;;
    esac
  done

  if [ "${LDM_NECESSARY}" = ${__TRUE} ] ; then
    LDM_BINARY="$( whence ldm )" || \
      [ -f /opt/SUNWldm/bin/ldm ] && LDM_BINARY="/opt/SUNWldm/bin/ldm" || \
        die  9 "ldm binary not found!"

    ${LDM_BINARY} list 2>/dev/null >/dev/null  || \
      die 10 "This script must run in the primary LDom"

    LogInfo "The ldm binary used is \"{${LDM_BINARY}\" "

# list of defined LDoms
#
    LIST_OF_LDOMS="$( list_all_ldoms )"

  else
    LIST_OF_LDOMS=""
    DEFAULT_LDOMS_TO_PROCESS="current_running_ldom"
  fi

  if [ "${LDOM_OUTPUT_FILE}"x != ""x ] ; then
    BackupFileIfNecessary "${LDOM_OUTPUT_FILE}"
    [ ${__OVERWRITE_MODE} = ${__TRUE} ] && rm "${LDOM_OUTPUT_FILE}" 2>/dev/null 1>/dev/null

    if [ -f  "${LDOM_OUTPUT_FILE}" ] ; then
      LogMsg "The output of the commands will be appended to the file \"${LDOM_OUTPUT_FILE}\" "
    else
      LogMsg "The output of the commands will be written to the file \"${LDOM_OUTPUT_FILE}\" "
    fi

    touch "${LDOM_OUTPUT_FILE}" || \
      die 15 "Can not write to the output file \"${LDOM_OUTPUT_FILE}\" "

  else
    LogInfo "No output file for the ldm output defined."
  fi


  if [ "${LDOM_SCRIPT_FILE}"x != ""x ] ; then
    BackupFileIfNecessary "${LDOM_SCRIPT_FILE}"
    [ ${__OVERWRITE_MODE} = ${__TRUE} ] && rm "${LDOM_SCRIPT_FILE}" 2>/dev/null 1>/dev/null

    if [ -f  "${LDOM_SCRIPT_FILE}" ] ; then
      LogMsg "The commands will be appended to the file \"${LDOM_SCRIPT_FILE}\" "
    else
      echo "#!/usr/bin/ksh" >"${LDOM_SCRIPT_FILE}" 2>/dev/null
      LogMsg "The commands will be written to the file \"${LDOM_SCRIPT_FILE}\" "
    fi
    
    touch "${LDOM_SCRIPT_FILE}" || \
      die 15 "Can not write to the script file \"${LDOM_SCRIPT_FILE}\" "

    chmod 755 "${LDOM_SCRIPT_FILE}"
  else
    LogInfo "No script file for the ldm commands defined."
  fi

  if [ ${PROCESS_ALL_GUEST_LDOMS} = ${__TRUE} ] ; then
    if [ "${LDM_NECESSARY}" = ${__TRUE} ] ; then
      LDOMS_TO_PROCESS=$( list_guest_ldoms )
      LogInfo "-A found -- processing all Guest LDoms: \"${LDOMS_TO_PROCESS}\" "
    else
       die 16  "Parameter -A not supported for the current actions"
    fi
  else
    LDOMS_TO_PROCESS="${DEFAULT_LDOMS_TO_PROCESS}"
    LogInfo "Processing the Guest LDoms \"${LDOMS_TO_PROCESS}\" "
  fi

  LogInfo "LDoms defined are:"
  for i in ${LIST_OF_LDOMS} ; do
    LogInfo "  $i "
  done

  LogInfo "LDoms to process are:"
  for i in ${LDOMS_TO_PROCESS} ; do
    LogInfo "  $i "
  done

  LogInfo "Tasks defined are:"
  for i in ${LDOM_TASKS} ; do
    LogInfo "  $i "
  done

  CHECK_ACTION=${__TRUE}
  INVALID_TASKS_FOUND=${__FALSE}

# the DRY_RUN task is only to check the parameter!
#
  for LDOM in DRY_RUN ${LDOMS_TO_PROCESS} ; do
    for CUR_LDOM_TASK in ${LDOM_TASKS} ; do
      if [ "${LDOM}"x != "DRY_RUN"x ] ; then
        LogMsg "Processing the task \"${CUR_LDOM_TASK}\" ..."
        LogMsg "The current LDom is \"${LDOM}\" ..."
      else
        LogInfo "Checking the action \"${CUR_LDOM_TASK}\" (DRY_RUN) ..."
      fi

      case "${CUR_LDOM_TASK}" in

# -------------------------- actions to view the status

        list_ldoms )
          [ "${CHECK_ACTION}" = "${__TRUE}" ] && continue
          ldom_status "${LDOM}" "print"
          ;;
          
# -------------------------- actions to view the configuration

        list_vdisks )
          [ "${CHECK_ACTION}" = "${__TRUE}" ] && continue
          
          [ "${LDOM}"x = "primary"x ] && \
            LogWarning "vdisk are normally not configured in the primary LDom"

          CUR_LIST_OF_VDISKS="$( ${LDM_BINARY} list -p -l "${LDOM}" | grep "^VDISK|" )"
          if [ "${CUR_LIST_OF_VDISKS}"x = ""x ]  ; then
            LogMsg "No vdisks defined for the LDom \"${LDOM}\" "
          else
            print_ldm_output "${CUR_LIST_OF_VDISKS}"
          fi
          ;;

# -------------------------- 

        list_vdisks_verbose )
          [ "${CHECK_ACTION}" = "${__TRUE}" ] && continue
          
          [ "${LDOM}"x = "primary"x ] && \
            LogWarning "vnets are normally not configured in the primary LDom"

          CUR_LIST_OF_VDISKS="$( list_ldom_vdisks "${LDOM}" )"
          if [ "${CUR_LIST_OF_VDISKS}"x = ""x ]  ; then
            LogMsg "No vdisks defined for the LDom \"${LDOM}\" "
          else
            for CUR_DISK in ${CUR_LIST_OF_VDISKS} ; do
              retrieve_ldom_vdisk_verbose  "${LDOM}" "${CUR_DISK}" "print"
            done
          fi
          ;;

# -------------------------- 

        list_vdiskserverdevices_verbose )
          [ "${CHECK_ACTION}" = "${__TRUE}" ] && continue

          [ "${LDOM}"x != "primary"x ] && \
            LogWarning "vdiskserverdevices are normally only configured in the primary LDom"

          list_ldom_vdiskserverdevices "${LDOM}" "print"
          ;;

# -------------------------- 

        list_vnets )
          [ "${CHECK_ACTION}" = "${__TRUE}" ] && continue
          
          [ "${LDOM}"x = "primary"x ] && \
            LogWarning "vnets are normally not configured in the primary LDom"

          CUR_LIST_OF_VNETS="$( ${LDM_BINARY} list -l ${LDOM} | grep network@ )"

          if [ "${CUR_LIST_OF_VNETS}"x = ""x ]  ; then
            LogMsg "No vnets defined for the LDom \"${LDOM}\" "
          else
            print_ldm_output "${CUR_LIST_OF_VNETS}"
          fi
          ;;

# -------------------------- 

        list_vswitches )
          [ "${CHECK_ACTION}" = "${__TRUE}" ] && continue
        
          [ "${LDOM}"x != "primary"x ] && \
            LogWarning "vswitches are normally not configured in the guest LDom"
            
          CUR_LIST_OF_VSWITCHES="$( ${LDM_BINARY} list -l ${LDOM} | grep switch@ )"
          if [ "${CUR_LIST_OF_VSWITCHES}"x = ""x ]  ; then
            LogMsg "No vswitches defined for the LDom \"${LDOM}\" "
          else
            print_ldm_output "${CUR_LIST_OF_VSWITCHES}"
          fi
          ;;

# -------------------------- 

        list_vnets_verbose )
          [ "${CHECK_ACTION}" = "${__TRUE}" ] && continue
        
          [ "${LDOM}"x = "primary"x ] && \
            LogWarning "vnets are normally not configured in the primary LDom"
          CUR_LIST_OF_VNETS="$( list_ldom_vnets "${LDOM}" )"
          if [ "${CUR_LIST_OF_VNETS}"x = ""x ]  ; then
            LogMsg "No vnets defined for the LDom \"${LDOM}\" "
          else

            OUTPUT="
  CUR_LIST_OF_VNETS=\"${CUR_LIST_OF_VNETS}\""
            print_ldm_output  "${OUTPUT}"

            for CUR_VNET in ${CUR_LIST_OF_VNETS} ; do
              retrieve_vnet_config  "${LDOM}" "${CUR_VNET}" "print"
            done
          fi
          ;;
          
# -------------------------- 

        list_vnets_table )
          [ "${CHECK_ACTION}" = "${__TRUE}" ] && continue
        
          [ "${LDOM}"x = "primary"x ] && \
            LogWarning "vnets are normally not configured in the primary LDom"
            
          CUR_LIST_OF_VNETS="$( list_ldom_vnets "${LDOM}" )"
          if [ "${CUR_LIST_OF_VNETS}"x = ""x ]  ; then
            LogMsg "No vnets defined for the LDom \"${LDOM}\" "
          else

            typeset -L15 PRINT_LDOM="#LDom"
            typeset -L15 PRINT_VNET_NAME="vnet"
            typeset -L25 PRINT_SWITCH_NAME="vswitch"
            typeset -L10 PRINT_NET_DEV="NetDev"
            typeset -L12  PRINT_SWITCH_DEVICE="SwitchDev"
            typeset -L20 PRINT_VNET_IN_LDOM="net dev in LDom"
            
            OUTPUT="
${OUTPUT}${PRINT_LDOM}${PRINT_VNET_NAME}${PRINT_SWITCH_NAME}${PRINT_NET_DEV}${PRINT_SWITCH_DEVICE}${PRINT_VNET_IN_LDOM}
#-------------------------------------------------------------------------------------------
"
            for CUR_VNET in ${CUR_LIST_OF_VNETS} ; do
              retrieve_vnet_config  "${LDOM}" "${CUR_VNET}" 
              
              PRINT_LDOM="${LDOM:=-}"
              PRINT_VNET_NAME="${VNET_NAME:=-}"
              PRINT_SWITCH_NAME="${SERVICE_SWITCH:=-}"
              PRINT_NET_DEV="${SERVICE_NETDEV:=-}"
              PRINT_SWITCH_DEVICE="${SERVICE_SWITCH_DEVICE:=-}"
              PRINT_VNET_IN_LDOM="${VNET_DEVICE_IN_LDOM:=-}"
              
OUTPUT="${OUTPUT}${PRINT_LDOM}${PRINT_VNET_NAME}${PRINT_SWITCH_NAME}${PRINT_NET_DEV}${PRINT_SWITCH_DEVICE}${PRINT_VNET_IN_LDOM}
"
            done
            print_ldm_output "${OUTPUT}"
          fi
          ;;

# -------------------------- 

        list_vnets_mac )
          [ "${CHECK_ACTION}" = "${__TRUE}" ] && continue

          [ "${LDOM}"x = "primary"x ] && \
            LogWarning "vnets are normally not configured in the primary LDom"

          CUR_LIST_OF_VNETS="$( list_ldom_vnets "${LDOM}" )"
          if [ "${CUR_LIST_OF_VNETS}"x = ""x ]  ; then
            LogMsg "No vnets defined for the LDom \"${LDOM}\" "
          else
            for CUR_VNET in ${CUR_LIST_OF_VNETS} ; do
              retrieve_vnet_config  "${LDOM}" "${CUR_VNET}" 
              OUTPUT="${CUR_VNET}: VSWITCH_MAC=${VSWITCH_MAC}; NETDEV_MAC=${NETDEV_MAC}; VNET_MAC=${VNET_MAC} "
              print_ldm_output "${OUTPUT}"
            done
          fi
          ;;

# -------------------------- 

        list_vswitches_verbose )
          [ "${CHECK_ACTION}" = "${__TRUE}" ] && continue
        
          [ "${LDOM}"x != "primary"x ] &&
            LogWarning "vswitches are normally configured in the primary LDom"

          CUR_LIST_OF_VSWITCHES="$( list_ldom_vswitches "${LDOM}" )"
          if [ "${CUR_LIST_OF_VSWITCHES}"x = ""x ]  ; then
            LogMsg "No vswitches defined for the LDom \"${LDOM}\" "
          else

            OUTPUT="
  CUR_LIST_OF_VSWITCHES=\"${CUR_LIST_OF_VSWITCHES}\""
            print_ldm_output  "${OUTPUT}"

            for CUR_VSWITCH in ${CUR_LIST_OF_VSWITCHES} ; do
              retrieve_vswitch_config  "${LDOM}" "${CUR_VSWITCH}" "print"
            done
          fi
          ;;

# -------------------------- 

        list_vswitches_table )
          [ "${CHECK_ACTION}" = "${__TRUE}" ] && continue
        
          [ "${LDOM}"x != "primary"x ] &&
            LogWarning "vswitches are normally configured in the primary LDom"

          CUR_LIST_OF_VSWITCHES="$( list_ldom_vswitches "${LDOM}" )"
          if [ "${CUR_LIST_OF_VSWITCHES}"x = ""x ]  ; then
            LogMsg "No vswitches defined for the LDom \"${LDOM}\" "
          else

            OUTPUT=""

            typeset -L15 PRINT_LDOM="#LDom"
            typeset -L25 PRINT_SWITCH_NAME="vswitch"
            typeset -L10 PRINT_NET_DEV="NetDev"
            typeset -L15 PRINT_SWITCH_DEVICE="SwitchDev"
            
OUTPUT="
${OUTPUT}${PRINT_LDOM}${PRINT_SWITCH_NAME}${PRINT_NET_DEV}${PRINT_SWITCH_DEVICE}
#-----------------------------------------------------------
"
            for CUR_VSWITCH in ${CUR_LIST_OF_VSWITCHES} ; do
              retrieve_vswitch_config  "${LDOM}" "${CUR_VSWITCH}" 
              
              PRINT_LDOM="${LDOM:=-}"
              PRINT_SWITCH_NAME="${SERVICE_NAME:=-}"
              PRINT_NET_DEV="${SERVICE_NETDEV:=-}"
              PRINT_SWITCH_DEVICE="${SERVICE_SWITCH_DEVICE:=-}"
              
OUTPUT="${OUTPUT}${PRINT_LDOM}${PRINT_SWITCH_NAME}${PRINT_NET_DEV}${PRINT_SWITCH_DEVICE}
"
            done
            print_ldm_output "${OUTPUT}"
          fi
          ;;

# -------------------------- 

        check_mac_addresses )
          [ "${CHECK_ACTION}" = "${__TRUE}" ] && continue

          [ "${LDOM}"x != "primary"x ] && \
            LogWarning "vswitches are normally only configured in the primary LDom"

          typeset -L25 PRINT_SWITCH_NAME="Switch"
          typeset -L10  PRINT_SWITCH_DEV="SwitchDev"
          typeset -L10 PRINT_SWITCH_NETDEV="NetDev"
          typeset -L20 PRINT_SWITCH_MAC_ADDR="MAC/Switch"
          typeset -L20 PRINT_NETDEV_MAC_ADDR="MAC/NetDev"
          typeset -L10 PRINT_STATUS="Status"

          OUTPUT="${PRINT_SWITCH_NAME}${PRINT_SWITCH_DEV}${PRINT_SWITCH_NETDEV}${PRINT_SWITCH_MAC_ADDR}${PRINT_NETDEV_MAC_ADDR}${PRINT_STATUS}
"

          CUR_LIST_OF_VSWITCHES="$( list_ldom_vswitches "${LDOM}" )"
          if [ "${CUR_LIST_OF_VSWITCHES}"x = ""x ]  ; then
            LogMsg "No vswitches defined for the LDom \"${LDOM}\" "
          else
            for CUR_VSWITCH in ${CUR_LIST_OF_VSWITCHES} ; do
              LogMsg "Processing the switch \"${CUR_VSWITCH}\" ..."
              retrieve_vswitch_config  "${LDOM}" "${CUR_VSWITCH}" 
              
              PRINT_SWITCH_NAME="${SERVICE_NAME:=-}"
              PRINT_SWITCH_DEV="${SERVICE_SWITCH_DEVICE:=-}"
              PRINT_SWITCH_NETDEV="${SERVICE_NETDEV:=-}"
              PRINT_SWITCH_MAC_ADDR="${VSWITCH_MAC:=-}"
              PRINT_NETDEV_MAC_ADDR="${NETDEV_MAC:=-}"

              PRINT_STATUS="okay"
              if [ "${SERVICE_NETDEV}"x != ""x -a "${SERVICE_NETDEV}"x != "-"x ] ; then
                if [ "${VSWITCH_MAC}"x != "${NETDEV_MAC}"x ] ; then
                  PRINT_STATUS="not okay"
                fi
              fi

              OUTPUT="${OUTPUT}
${PRINT_SWITCH_NAME}${PRINT_SWITCH_DEV}${PRINT_SWITCH_NETDEV}${PRINT_SWITCH_MAC_ADDR}${PRINT_NETDEV_MAC_ADDR}${PRINT_STATUS}
"
             done
           fi
            print_ldm_output "${OUTPUT}"
            ;;

# -------------------------- actions to change the configuration 

        set_vswitches_mac_address )
          [ "${CHECK_ACTION}" = "${__TRUE}" ] && continue
        
          [ "${LDOM}"x != "primary"x ] && \
            LogWarning "vswitches are normally only configured in the primary LDom"

          COMMANDS_TO_EXECUTE="${CURRENT_COMMENT}
"
          CUR_LIST_OF_VSWITCHES="$( list_ldom_vswitches "${LDOM}" )"
          if [ "${CUR_LIST_OF_VSWITCHES}"x = ""x ]  ; then
            LogMsg "No vswitches defined for the LDom \"${LDOM}\" "
          else
            for CUR_VSWITCH in ${CUR_LIST_OF_VSWITCHES} ; do
              LogMsg "Processing the switch \"${CUR_VSWITCH}\" ..."
              retrieve_vswitch_config  "${LDOM}" "${CUR_VSWITCH}" 
              if [ "${NETDEV_MAC}"x != ""x ] ; then
                COMMANDS_TO_EXECUTE="${COMMANDS_TO_EXECUTE} 
${LDM_BINARY} set-vswitch mac-addr=${NETDEV_MAC} ${SERVICE_NAME} ; "
              else
                COMMANDS_TO_EXECUTE="${COMMANDS_TO_EXECUTE} 
# No network device defined for the switch \"${SERVICE_NAME}\"  "
              fi
            done
            COMMANDS_TO_EXECUTE="${COMMANDS_TO_EXECUTE} 
"          
            execute_commands "Changing the configuration"
          fi
          ;;

# -------------------------- 

        configure_vswitches )
          [ "${CHECK_ACTION}" = "${__TRUE}" ] && continue
        
          [ "${LDOM}"x != "primary"x ] && \
            LogWarning "vswitches are normally only configured in the primary LDom"

          COMMANDS_TO_EXECUTE="${CURRENT_COMMENT}
"
          CUR_LIST_OF_VSWITCHES="$( list_ldom_vswitches "${LDOM}" )"
          if [ "${CUR_LIST_OF_VSWITCHES}"x = ""x ]  ; then
            LogMsg "No vswitches defined for the LDom \"${LDOM}\" "
          else
            for CUR_VSWITCH in ${CUR_LIST_OF_VSWITCHES} ; do
              LogMsg "Processing the switch \"${CUR_VSWITCH}\" ..."
              retrieve_vswitch_config  "${LDOM}" "${CUR_VSWITCH}" 
              if [ "${SERVICE_NETDEV}"x != ""x ] ; then
                NETDEV_CONFIG_FILE="/etc/hostname.${SERVICE_NETDEV}"
                SWITCH_CONFIG_FILE="/etc/hostname.vsw${SERVICE_DEVICE#*@}"

                COMMANDS_TO_EXECUTE="${COMMANDS_TO_EXECUTE} 
[ -f \"${NETDEV_CONFIG_FILE}\" ] && mv \"${NETDEV_CONFIG_FILE}\" \"${SWITCH_CONFIG_FILE}\" "
              else
                COMMANDS_TO_EXECUTE="${COMMANDS_TO_EXECUTE} 
# No network device defined for the switch \"${SERVICE_NAME}\"  "
              fi
            done
            COMMANDS_TO_EXECUTE="${COMMANDS_TO_EXECUTE} 
"          
            execute_commands "Changing the configuration"
          fi
          ;;

# -------------------------- 

        configure_network_adapters )
          [ "${CHECK_ACTION}" = "${__TRUE}" ] && continue

          [ "${LDOM}"x != "primary"x ] && \
            LogWarning "vswitches are normally only configured in the primary LDom"

          COMMANDS_TO_EXECUTE="${CURRENT_COMMENT}
"
          CUR_LIST_OF_VSWITCHES="$( list_ldom_vswitches "${LDOM}" )"
          if [ "${CUR_LIST_OF_VSWITCHES}"x = ""x ]  ; then
            LogMsg "No vswitches defined for the LDom \"${LDOM}\" "
          else
            for CUR_VSWITCH in ${CUR_LIST_OF_VSWITCHES} ; do
              LogMsg "Processing the switch \"${CUR_VSWITCH}\" ..."
              retrieve_vswitch_config  "${LDOM}" "${CUR_VSWITCH}" 
              if [ "${SERVICE_NETDEV}"x != ""x ] ; then
                NETDEV_CONFIG_FILE="/etc/hostname.${SERVICE_NETDEV}"
                SWITCH_CONFIG_FILE="/etc/hostname.vsw${SERVICE_DEVICE#*@}"

                COMMANDS_TO_EXECUTE="${COMMANDS_TO_EXECUTE} 
[ -f \"${SWITCH_CONFIG_FILE}\" ] && mv \"${SWITCH_CONFIG_FILE}\" \"${NETDEV_CONFIG_FILE}\" "
              else
                COMMANDS_TO_EXECUTE="${COMMANDS_TO_EXECUTE} 
# No network device defined for the switch \"${SERVICE_NAME}\"  "
              fi
            done
            COMMANDS_TO_EXECUTE="${COMMANDS_TO_EXECUTE} 
"          
            execute_commands "Changing the configuration"
          fi
          ;;

# -------------------------- 

        activate_vswitches )
          [ "${CHECK_ACTION}" = "${__TRUE}" ] && continue
        
          [ "${LDOM}"x != "primary"x ] && \
            LogWarning "vswitches are normally only configured in the primary LDom"

          COMMANDS_TO_EXECUTE="${CURRENT_COMMENT}
"
          CUR_LIST_OF_VSWITCHES="$( list_ldom_vswitches "${LDOM}" )"
          if [ "${CUR_LIST_OF_VSWITCHES}"x = ""x ]  ; then
            LogMsg "No vswitches defined for the LDom \"${LDOM}\" "
          else
            for CUR_VSWITCH in ${CUR_LIST_OF_VSWITCHES} ; do
              LogMsg "Processing the switch \"${CUR_VSWITCH}\" ..."
              retrieve_vswitch_config  "${LDOM}" "${CUR_VSWITCH}" 
              if [ "${SERVICE_NETDEV}"x != ""x ] ; then
                NETDEV_CONFIG_FILE="/etc/hostname.${SERVICE_NETDEV}"
                SWITCH_NAME="vsw${SERVICE_DEVICE#*@}"
                SWITCH_CONFIG_FILE="/etc/hostname.${SWITCH_NAME}"
                COMMANDS_TO_EXECUTE="${COMMANDS_TO_EXECUTE} 
if [ -f \"${SWITCH_CONFIG_FILE}\" ] ; then
  ifconfig \"${SERVICE_NETDEV}\" 2>/dev/null >/dev/null && ifconfig \"${SERVICE_NETDEV}\" unplumb
  ifconfig \"${SWITCH_NAME}\" 2>/dev/null >/dev/null && ifconfig \"${SWITCH_NAME}\" unplumb
  ifconfig \"${SWITCH_NAME}\" plumb \$( cat \"${SWITCH_CONFIG_FILE}\" )
fi
" 
              fi
            done
            COMMANDS_TO_EXECUTE="${COMMANDS_TO_EXECUTE} 
"          
            execute_commands "Changing the configuration"
          fi
          ;;

# -------------------------- 

        activate_network_adapters )
          [ "${CHECK_ACTION}" = "${__TRUE}" ] && continue
        
          [ "${LDOM}"x != "primary"x ] && \
            LogWarning "vswitches are normally only configured in the primary LDom"

          COMMANDS_TO_EXECUTE="${CURRENT_COMMENT}
"
          CUR_LIST_OF_VSWITCHES="$( list_ldom_vswitches "${LDOM}" )"
          if [ "${CUR_LIST_OF_VSWITCHES}"x = ""x ]  ; then
            LogMsg "No vswitches defined for the LDom \"${LDOM}\" "
          else
            for CUR_VSWITCH in ${CUR_LIST_OF_VSWITCHES} ; do
              LogMsg "Processing the switch \"${CUR_VSWITCH}\" ..."
              retrieve_vswitch_config  "${LDOM}" "${CUR_VSWITCH}" 
              if [ "${SERVICE_NETDEV}"x != ""x ] ; then
                NETDEV_CONFIG_FILE="/etc/hostname.${SERVICE_NETDEV}"
                SWITCH_NAME="vsw${SERVICE_DEVICE#*@}"
                SWITCH_CONFIG_FILE="/etc/hostname.${SWITCH_NAME}"
                COMMANDS_TO_EXECUTE="${COMMANDS_TO_EXECUTE} 
if [ -f \"${NETDEV_CONFIG_FILE}\" ] ; then
  ifconfig \"${SERVICE_NETDEV}\" 2>/dev/null >/dev/null && ifconfig \"${SERVICE_NETDEV}\" unplumb
  ifconfig \"${SWITCH_NAME}\" 2>/dev/null >/dev/null && ifconfig \"${SWITCH_NAME}\" unplumb
  ifconfig \"${SERVICE_NETDEV}\" plumb \$( cat \"${NETDEV_CONFIG_FILE}\" )
fi
"
              fi
            done
            COMMANDS_TO_EXECUTE="${COMMANDS_TO_EXECUTE} 
"
            execute_commands "Changing the configuration"
          fi
          ;;

# -------------------------- 

        reconfigure_vnets )
          [ "${CHECK_ACTION}" = "${__TRUE}" ] && continue

          [ "${LDOM}"x = "primary"x ] && \
            LogWarning "vnets are normally not configured in the primary LDom"

          CUR_LIST_OF_VNETS="$( list_ldom_vnets "${LDOM}" )"
          COMMANDS_TO_EXECUTE="${CURRENT_COMMENT}
"
          COMMANDS_TO_EXECUTE1=""
          
          if [ "${CUR_LIST_OF_VNETS}"x = ""x ]  ; then
            LogMsg "No vnets defined for the LDom \"${LDOM}\" "
          else
          
            for CUR_VNET in ${CUR_LIST_OF_VNETS} ; do
              retrieve_vnet_config  "${LDOM}" "${CUR_VNET}" 
             COMMANDS_TO_EXECUTE="${COMMANDS_TO_EXECUTE} 
${LDM_BINARY} remove-vnet \"${VNET_NAME}\" \"${LDOM}\" "              

             COMMANDS_TO_EXECUTE1="${COMMANDS_TO_EXECUTE1} 
${LDM_BINARY} add-vnet \"${VNET_NAME}\" \"${VNET_SERVICE%@*}\" \"${LDOM}\" "

            done

            COMMANDS_TO_EXECUTE="${COMMANDS_TO_EXECUTE}
${COMMANDS_TO_EXECUTE1} 
"
            execute_commands "Changing the configuration"
          fi

          ;;

# -------------------------- 

        reattach_vdisk | reattach_vdisks )
          [ "${CHECK_ACTION}" = "${__TRUE}" ] && continue

          [ "${LDOM}"x = "primary"x ] && \
            LogWarning "vdisks are normally not configured in the primary LDom"
          ;;

# -------------------------- actions to start/stop the domains

        stop_domain | stop_ldom )
          [ "${CHECK_ACTION}" = "${__TRUE}" ] && continue

          if [ "${LDOM}"x = "primary"x ] ; then
            LogWarning "\"${CUR_LDOM_TASK}\" is not possible for the primary LDom - ignoring the task"
            continue
          fi

          COMMANDS_TO_EXECUTE="${CURRENT_COMMENT}
"

          for CUR_LDOM in ${LDOM} ; do
            ldom_status "${CUR_LDOM}"
            case "${LDOM_STATE}" in 

              "active" )
            COMMANDS_TO_EXECUTE="${COMMANDS_TO_EXECUTE} 
echo \"Stopping the LDom ${CUR_LDOM} ...\" ;
${LDM_BINARY} stop \"${CUR_LDOM}\"
"
                ;;

              "inactive" )
                LogWarning "LDom \"${CUR_LDOM}\" is not bound"
                ;;

              "bound" )
                LogWarning "LDom \"${CUR_LDOM}\" is not running"
                ;;

              * )
                LogWarning "LDom \"${CUR_LDOM}\" is in an unknown state: \"${LDOM_STATE}\""
                ;;
            esac
          done

          execute_commands "Stopping the LDoms now"
          ;;

# -------------------------- 

        start_domain | start_ldom )
          [ "${CHECK_ACTION}" = "${__TRUE}" ] && continue

          if [ "${LDOM}"x = "primary"x ] ; then
            LogWarning "\"${CUR_LDOM_TASK}\" is not possible for the primary LDom - ignoring the task"
            continue
          fi

COMMANDS_TO_EXECUTE="${CURRENT_COMMENT}
"
          for CUR_LDOM in ${LDOM} ; do
            ldom_status "${CUR_LDOM}"
            case "${LDOM_STATE}" in 
              "active" )
                LogWarning "LDom \"${CUR_LDOM}\" is already running"
                ;;

              "inactive" )
                LogWarning "LDom \"${CUR_LDOM}\" is not bound"
                ;;

              "bound" )
            COMMANDS_TO_EXECUTE="${COMMANDS_TO_EXECUTE} 
echo \"Starting the LDom ${CUR_LDOM} ...\" ;
${LDM_BINARY} start \"${CUR_LDOM}\"
"
                ;;

              * )
                LogWarning "LDom \"${CUR_LDOM}\" is in an unknown state: \"${LDOM_STATE}\""
                ;;
            esac
          done

            execute_commands "Starting the LDoms now"
          ;;

# -------------------------- 

        restart_domain | restart_ldom )
          [ "${CHECK_ACTION}" = "${__TRUE}" ] && continue

          if [ "${LDOM}"x = "primary"x ] ; then
            LogWarning "\"${CUR_LDOM_TASK}\" is not possible for the primary LDom - ignoring the task"
            continue
          fi

          COMMANDS_TO_EXECUTE="${CURRENT_COMMENT}
"

          for CUR_LDOM in ${LDOM} ; do
            ldom_status "${CUR_LDOM}"
            case "${LDOM_STATE}" in 

              "active" )
            COMMANDS_TO_EXECUTE="${COMMANDS_TO_EXECUTE} 
echo \"Stopping the LDom ${CUR_LDOM} ...\" ;
${LDM_BINARY} stop \"${CUR_LDOM}\"
echo \"Starting the LDom ${CUR_LDOM} ...\" ;
${LDM_BINARY} start \"${CUR_LDOM}\"
"
                ;;
                
              "inactive" )
                LogWarning "LDom \"${CUR_LDOM}\" is not bound"
                ;;

              "bound" )
                LogWarning "LDom \"${CUR_LDOM}\" is not running"
                ;;

              * )
                LogWarning "LDom \"${CUR_LDOM}\" is in an unknown state: \"${LDOM_STATE}\""
                ;;
            esac
          done
          
          execute_commands "Restarting the LDoms now"
          ;;

# -------------------------- 

       post_config_ldom )
          [ "${CHECK_ACTION}" = "${__TRUE}" ] && continue

          if [ "${LDOM}"x = "primary"x ] ; then
            LogWarning "\"${CUR_LDOM_TASK}\" is not possible for the primary LDom - ignoring the task"
            continue
          fi
          COMMANDS_TO_EXECUTE="${CURRENT_COMMENT}
"
          SSH_BINARY="$( whence ssh )" || \
            SSH_BINARY="/applications/ssh/CURRENT/bin/ssh"
            
          for CUR_LDOM in ${LDOM} ; do
            LogMsg "Processing the LDom \"${CUR_LDOM}\" ..."
            COMMANDS_TO_EXECUTE="${COMMANDS_TO_EXECUTE} 
ldm set-variable auto-boot\?=true \"${CUR_LDOM}\"
${SSH_BINARY} -l root \"${CUR_LDOM}\" eeprom auto-boot\?=true
"
          done

          execute_commands "Changing the configuration"
          ;;


# -------------------------- 

        configure_primary_ldom | create_primary_ldom )
          [ "${CHECK_ACTION}" = "${__TRUE}" ] && continue

          if [ "${LDOM}"x != "primary"x ] ; then
            LogWarning "Task ${CUR_LDOM_TASK} only supported for the primary LDom; The current LDom is \"${LDOM}\" "
            continue
          fi

          MACHINE_TYPE="$( uname -a | cut -f 7 -d " " )"
          case ${MACHINE_TYPE} in
            "SUNW,SPARC-Enterprise-T5220" )
              THREADS_PER_CORE=8
              ;;
            "SUNW,SPARC-Enterprise-T5210" )
              THREADS_PER_CORE=8
              ;;
            * )
              THREADS_PER_CORE=4
              ;;
          esac

          COMMANDS_TO_EXECUTE="${CURRENT_COMMENT}
   echo \"\"
   echo \"### Creating the primary LDom ....\"

    ${LDM_BINARY} add-vdiskserver primary-vds0 primary
    ${LDM_BINARY} add-vdiskserver san-dco primary
    ${LDM_BINARY} add-vdiskserver san-dcs primary
    ${LDM_BINARY} add-vdiskserver san-mirrored-devices primary

    ${LDM_BINARY} add-vconscon port-range=5000-5100 primary-vcc0 primary
    ${LDM_BINARY} add-vswitch net-dev=e1000g0 primary-e1000g0 primary
    ${LDM_BINARY} add-vswitch net-dev=e1000g1 primary-e1000g1 primary
    ${LDM_BINARY} add-vswitch net-dev=e1000g2 primary-e1000g2 primary
    ${LDM_BINARY} add-vswitch net-dev=e1000g3 primary-e1000g3 primary
    ${LDM_BINARY} add-vswitch primary-local primary

    ${LDM_BINARY} add-vswitch net-dev=nxge0  primary-nxge0 primary
    ${LDM_BINARY} add-vswitch net-dev=nxge1  primary-nxge1 primary
    ${LDM_BINARY} add-vswitch net-dev=nxge2  primary-nxge2 primary
    ${LDM_BINARY} add-vswitch net-dev=nxge3  primary-nxge3 primary

    ${LDM_BINARY} add-vswitch net-dev=nxge4  primary-nxge4 primary
    ${LDM_BINARY} add-vswitch net-dev=nxge5  primary-nxge5 primary
    ${LDM_BINARY} add-vswitch net-dev=nxge6  primary-nxge6 primary
    ${LDM_BINARY} add-vswitch net-dev=nxge7  primary-nxge7 primary

    ${LDM_BINARY} set-vcpu ${THREADS_PER_CORE} primary
#    ${LDM_BINARY} set-crypto 1 primary
    ${LDM_BINARY} set-memory 3968M  primary

    ${LDM_BINARY} add-spconfig initial001
    ${LDM_BINARY} list-spconfig
"

          execute_commands "Configuring the primary LDom now"
          ;;

# --------------------------
        start_ldom_consoleservice )
          [ "${CHECK_ACTION}" = "${__TRUE}" ] && continue

          if [ "${LDOM}"x != "primary"x ] ; then
            LogWarning "Task ${CUR_LDOM_TASK} only supported for the primary LDom; The current LDom is \"${LDOM}\" "
            continue
          fi

          COMMANDS_TO_EXECUTE="${CURRENT_COMMENT}
# view current status
svcs  svc:/ldoms/vntsd:default
# start the service
svcadm enable -s svc:/ldoms/vntsd:default
# view new status
svcs  svc:/ldoms/vntsd:default
"

          execute_commands "Starting the Guest LDom Console Service now"
          ;;

# -------------------------- configure install network interface
        configure_install_network )
          [ "${CHECK_ACTION}" = "${__TRUE}" ] && continue

          CONTINUE=${__TRUE}
          NETWORK_BOOT_ARGUMENTS="$( eeprom network-boot-arguments | cut -f2- -d "=" )"
          if [ "${NETWORK_BOOT_ARGUMENTS}"x = ""x ] ; then
            LogError "nvramrc variable \"network-boot-arguments\" not set"      
            CONTINUE=${__FALSE}
          fi
          
          if [ ${CONTINUE} = ${__TRUE} ] ; then
            LogInfo "nvramrc variable \"network-boot-arguments\" is"
            LogInfo "${NETWORK_BOOT_ARGUMENTS}"

            eval $( eeprom network-boot-arguments | cut -f2- -d "=" | tr ",-" ";_" )

            LogInfo "host_ip = \"${host_ip}\" "
            LogInfo "router_ip = \"${router_ip}\" "
            LogInfo "subnet_mask = \"${subnet_mask}\" "
            LogInfo "hostname = \"${hostname}\" "
            LogInfo "file = \"${file}\" "
            LogInfo "client_id = \"${client_id}\" "

            if [ "${INSTALL_NETDEV}"x = ""x ] ; then
              NET_DEV=$( prtconf -vp | grep "net:" | cut -f2 -d "'" )
              if [ "${NET_DEV}"x = "" x ] ; then
                LogError "nvramrc net not set; use INSTALL_NETDEV=adapter ${__SCRIPTNAME} configure_install_network"
              CONTINUE=${__FALSE}
              fi
         
              if [ ${CONTINUE} = ${__TRUE} ] ; then
                LogInfo "net device is \"${NET_DEV}\" "
                set -- $( grep "\"${NET_DEV}\"" /etc/path_to_inst )
                if [ $# -eq 0 ] ; then
                  LogError "\"\" not found in /etc/path_to_inst; use INSTALL_NETDEV=adapter ${__SCRIPTNAME} configure_install_network"
                  CONTINUE=${__FALSE}
                else
                  eval INSTALL_NETDEV=$3$2
                fi
              fi
            fi
          fi
          
          if [ ${CONTINUE} = ${__TRUE} ] ; then

            LogInfo "Using the IP interface \"${INSTALL_NETDEV}\" "
            COMMANDS_TO_EXECUTE="
ifconfig ${INSTALL_NETDEV} >/dev/null 2>/dev/null || ifconfig ${INSTALL_NETDEV} plumb  ;
ifconfig ${INSTALL_NETDEV} ${host_ip} netmask ${subnet_mask} broadcast + up ;
route add default ${router_ip}
"

            execute_commands "Configuring the installation network adapter"

          fi
          ;;
        
# -------------------------- actions to save/restore the configuration

        save_config | save_initial_config )
          if [ "${CHECK_ACTION}" = "${__TRUE}" ] ; then
            if [ "${LDOM_SCRIPT_FILE}"x != ""x ] ; then
              LogError "The parameter -s is not supported for the action \"${CUR_LDOM_TASK}\" "
              INVALID_TASKS_FOUND=${__TRUE}
              continue
            fi
            continue
          fi

          if [ "${LDOM}"x != "primary"x ] ; then
            LogWarning "Task ${CUR_LDOM_TASK} only supported for the primary LDom; The current LDom is \"${LDOM}\" "
            continue
          fi

          if [ "${CUR_LDOM_TASK}"x = "save_initial_config"x ] ; then
              THIS_CONFIG_NAME="initial"
          else
              THIS_CONFIG_NAME=""
          fi

          save_ldm_config "${THIS_CONFIG_NAME}"
          ;;


# -------------------------- internal actions
# parameter -c is handled here:

        SWITCH_COMMENT:* )
          [ "${CHECK_ACTION}" = "${__TRUE}" ] && continue
        
          NEW_COMMENT="$( echo ${CUR_LDOM_TASK#*:} | tr "^" " " )"
          if [ "${NEW_COMMENT}"x != ""x ] ; then
            CURRENT_COMMENT="# ${NEW_COMMENT}"
          else
            CURRENT_COMMENT=""
          fi
          
          LogInfo "Setting the comment string to \"${CURRENT_COMMENT}\" ..."
          ;;

# -------------------------- 
# parameter -d is handled here:

        SWITCH_LDOM:* )
          if [ "${CHECK_ACTION}" = "${__TRUE}" ] ; then
            if [ ${PROCESS_ALL_GUEST_LDOMS} = ${__TRUE} ] ; then
              LogError "Either use the switch -A or -d -- but not both at the same time"
              INVALID_TASKS_FOUND=${__TRUE}
            fi
            continue
          fi

          NEW_LDOM="${CUR_LDOM_TASK#*:}"
          LogInfo "Setting the ldom to \"${NEW_LDOM}\" ..."

          ldom_defined "${NEW_LDOM}" 
          [ $? = ${__FALSE} ] && \
            die 20 "The LDom \"${NEW_LDOM}\" is NOT defined."
          LDOM="${NEW_LDOM}"
          ;;

# -------------------------- 

# for debugging only:

        test )
          [ "${CHECK_ACTION}" = "${__TRUE}" ] && continue

          while true ; do
            echo "Enter command to execute: "
            read USERINPUT
            [ "${USERINPUT}"x = "exit"x ] && break
            eval $USERINPUT
          done
          ;;

       test_guest )
          [ "${CHECK_ACTION}" = "${__TRUE}" ] && continue

          while true ; do
            echo "Enter command to execute: "
            read USERINPUT
            [ "${USERINPUT}"x = "exit"x ] && break
            eval $USERINPUT
          done
          ;;

#
# -------------------------- 

        * ) LogError "Unknown task \"${CUR_LDOM_TASK}\" found."
            INVALID_TASKS_FOUND=${__TRUE}
          ;;

      esac
    done

    if [ ${INVALID_TASKS_FOUND} = ${__TRUE} ] ; then
      die 45 "Invalid tasks found in the parameter"
    fi

    CHECK_ACTION=${__FALSE}

  done

  if [ "${LDOM_OUTPUT_FILE}"x != ""x ] ; then
    LogMsg "The output file for the ldm output is \"${LDOM_OUTPUT_FILE}\" "
  fi

  if [ "${LDOM_SCRIPT_FILE}"x != ""x ] ; then
    LogMsg "The script file for the ldm commands is \"${LDOM_SCRIPT_FILE}\" "
  fi

  die ${__MAINRC} 
 
exit
