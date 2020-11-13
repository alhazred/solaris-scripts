#!/usr/bin/ksh
#
# use "create_zone.sh {-v} -h" to get the usage help
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
# Copyright 2006 - 2013 Bernd Schemmer  All rights reserved.
# Use is subject to license terms.
#
# Notes:
#
# - use "create_zone.sh {-v} {-v} -h" to get the usage help
#
# - use "create_zone.sh -H 2>create_zone.doc" to get the documentation
#
# - this is a Kornshell script - it may not function correctly in other shells
# - the script was written and tested with ksh88 but should also work in ksh93
#
# The documentation for create_zone.sh and the newest version can be found here:
#
#   http://bnsmb.de/solaris/create_zone.html
#
##
# -----------------------------------------------------------------------------
##
## create_zone.sh - script to create zones unattended
##
## Author: Bernd Schemmer (Bernd.Schemmer@gmx.de)
##
## Version: see variable ${__SCRIPT_VERSION} below
##          (see variable ${__SCRIPT_TEMPLATE_VERSION} for the template 
##           version used)
##
## Supported OS: Solaris 10 and newer
##
##
## Description
## 
## This script can be used to create and configure a zone without user interaction.
## 
## The script supports a finish script for the zone, a customization script for the zone, 
## and a SMF profile. Various settings for the zone can be done via parameter and a
## configuration file.
##
## Configuration file
##
## This script supports a configuration file called create_zone.conf.
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
##       Nicolas Dorfsman for the idea for the parameter -N (cloning) and -t (template) 
##
##
## History:
##   12.06.2006 /bs 
##     initial release
##   12.03.2008 v1.1.0 /bs
##     added support for IP instances
##     use a newer version of the script template
##   15.03.2008 v1.1.1 /bs
##     added the config options zone_memory_limit, zone_swap_limit, zone_cpu_count, and zone_cpu_shares
##   17.03.2008 v1.1.2 /bs
##     added the option -e (edit)
##     added the config option zone_inherited_dir and the option -d
##     added the syntax xx.xx.xx.xx/yy for the IP address (use /yy to specify the netmask)
##   18.03.2008 v1.1.3 /bs
##     added the config option zone_writable_dir  and the option -w (writabledir)
##     improved the error handling
##   15.05.2008 v1.1.4 /bs
##     added workaround for the "GLDv3 support" for the ce adapter
##         see: http://sunsolve.sun.com/search/document.do?assetkey=1-61-234401-1
##     added the config options zone_gldv3_check
##   08.02.2009 v1.1.5 /bs
##     added support for the defrouter configuration for zones in Solaris U6 and newer
##     The list of file that are copied to a zone with exclusive IP stack can now be 
##     configured in the config file; see the variable EXCLUSIVE_IP_STACK_CONFIG_FILES
##   15.02.2009 v1.1.6 /bs
##     added support for ZFS datasets (parameter -Z)
##     added support for cloning a zone (parameter -N)
##   18.02.2009 v1.1.7 /bs
##     added support for other global config entries
##     added suport for devices for the zone
##   25.02.2009 v1.1.8 /bs
##     added support for new dladm options 
##     added the parameter -t (--templatedir) to specify template directories
##     added the config options zone_netmask for zones with exclusive IP stack
##     create_zone.sh did not create a complete sysidcfg for zones with exclusive IP. Fixed.
##     remove the call of prtdiag; __MACHINE_SUBTYPE is now always empty
##   28.02.2009 v1.1.9 /bs
##     the default for the zone template directories (parameter -t) is now
##     "${DEFAULT_ZONE_PATH}/template_dir" 
##     if that directory exist
##     create_zones.sh now creates a correct sysidcfg file if USE_EXISTING_NAMESERVER_CONFIG
##     is set to y
##   29.03.2009 v1.1.10 /bs
##     added the parameter -R (--readonlydir) to configure add. read-only directories for the 
##     zone
##   31.08.2009 v1.1.11 /bs
##     corrected a bug in the format of the created sysidcfg file
##     added code to set the timezone in the file /etc/TIMEZONE in the zone to avoid one reboot
##     added
##        svcadm disable svc:/application/cde-printinfo:default
##     to the builtin customize script for the zones
##     The default run level for the customize script is now rcS.d:
##        DEFAULT_ZONE_CUSTOMIZE_SCRIPT_TARGET="/etc/rcS.d/S99customize_script"
##     The script noew creates a config file inside the zone with the zone configuration
##     variables called 
##         /etc/create_zone.cfg 
##     (this are all variables used in this script with a name beginning with ZONE_)
##   03.09.2009 v1.1.12 /bs
##     the script did not handle timezones with a slash "/" correct. Fixed.
##     the script now removes the entries for localhost from the /etc/hosts file before
##     copying it to the zone
##   09.09.2009 v1.1.13 /bs
##     the script did not handle incomplete resolv.conf files correct. Fixed
##   17.09.2009 v1.1.14 /bs
##     not released
##  
##   17.09.2009 v1.1.15 /bs
##     added code to copy files from the global zone to the non-global zone
##     (parameter -c)
##     the home directory for root is now configured as in the global zone
##   29.09.2010 v1.1.16/bs
##     added a workaround for a bug in the zoneadm commands
##   22.03.2011 v1.1.17 /bs
##     added a check for additional directories for the zone
##     removed the restriction to run only once at a time
##     added the keyword zone_add_network_interface to define additional network
##       interfaces for the zone
##     added the parameter -B (zone_config_only)
##     some cosmetic changes
##   25.10.2012 v1.1.18 /bs
##     changed the code to cleanup existing zone directories -- now it only deletes the
##     files and directories in the zone directory and not the zone directory
##   01.11.2012 v1.1.19 /bs
##     corrected a bug in the TIMEZONE handling
##   07.11.2012 v1.1.20 /bs
##     added the parameter -P <zone_path_absolute>
##     ZFS filesystems are now supported for the global directories to be used by 
##       the zone (parameter -w and -R)
##     added support for flash image installations (-x zone_flashimage)
##     -x zone_netmask= is now also used for shared IP stack configurations
##     code cleanup${THIS_MOUNTPOOINT
##     added more parameter checks
##   17.12.2012 v1.1.21 /bs
##     added code to workaround a "bug" in the zfs list command
##     (zfs list <dirname> returns always 0)
##   18.12.2012 v1.1.22 /bs
##     disabled all not necessary checks if configure only mode is used
##     added the parameter -F to disable all zone configuration checks
##     code cleanup
##   10.01.2013 v1.1.23/bs
##     added the parameter -x zone_hostid=<hostid>
##     create_zone.sh will now NOT stop or delete a zone if -O and -B are used
##     added the keyword zone_set_global_option for -x
##
##   13.02.2013 v1.1.24/bs
##     corrected invalid options for ZFS filesystems for the zone (ro instead rw)
##
##   26.03.2013 v1.1.25/bs
##     corrected some bugs for configure only tasks
##     use "cp -p" instead of "cp " to copy files
##
##   19.07.2013 v1.1.26/bs
##     added support for capped-cpu (parameter -x zone_capped_cpu_count)
##     added initial support for branded zones (parameter -x brand)
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
##   1.22.10 21.09.2006 /bs content/sunsolve/archives/082007.html
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
##      view the environment variables used also
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

## ----------------
## Version variables
##
## __SCRIPT_VERSION - the version of your script 
##
#  Note: CYGWIN ksh does not like typeset -r
##
typeset  __SCRIPT_VERSION="v1.1.26"
##

## __SCRIPT_TEMPLATE_VERSION - version of the script template
##
typeset  __SCRIPT_TEMPLATE_VERSION="1.22.30 28.02.2008"
##

## ----------------
##
## Predefined return codes:
##
##    1 - show usage and exit
##    2 - invalid parameter found
##
##  210 - 236 reserved for the runtime system
##  237 - script file has to many lines for the debug handler
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
##    3 "Use either the parameter ZONE_PATH or ZONE_PATH_ABSOLUTE -- not both"
##    4 "ZONE_PATH_ABSOLUTE can not be the root directory"
##    5 "The parameter for the name of the zone is missing"
##    8 "The parameter for the IP address of the zone is missing"
##   11 "The directory for the zone \"${ZONE_PATH}\" does not exist"
##   12 "You must specifiy a network interface (-A) if creating a zone with exclusive IP stack (-I)"
##   15 "Can not detect the interface for the zone (use -A to specify the interface)"
##   14 "Script aborted by the user"
##   17 "Error reading the customize script for the zone \"${ZONE_CUSTOMIZE_SCRIPT_SOURCE}\" " 
##   20 "Zone configuration is not okay"
##   23 "Error calling zonecfg -z ${ZONE_NAME} delete -F"   
##   26 "Can not cleanup the existing zone directory \"${THIS_ZONE_PATH}\""
##   27 "Can not create the directory \"${WRITABLE_GLOBAL_DIR}\" "
##   28 
##   29 "Error configuring the zone \"${ZONE_NAME}\""
##   32 "Error installing the zone \"${ZONE_NAME}\""
##   35 "Error preparing the zone \"${ZONE_NAME}\""
##   36 "Use either dedicated CPUs or CPU shares for the zone -- but not both"
##   37 "Use either a flashimage or a source zone for the installation -- but not both"
##   38 "A flashimage or a zone to be cloned can not be used if zone_config_only is true"
##

##  100 - error creating the sysidcfg file of the zone
##  102 - error creating one of the files for the nameserver configuration
##  105 - error creating the directory for the customize script for the zone
##  106 - error creating the customize script for the zone
##  107 - error creating the SMF profile for the zone
##  108 - the finish script for the zone returned an error
##  109 - error booting the zone
##
## ----------------
## Used environment variables
##
#
# Note: The variable __USED_ENVIRONMENT_VARIABLES is used in the function ShowUsage
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
#  __DEBUG_CODE=""

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

## EXCLUSIVE_IP_STACK_CONFIG_FILES
##   network configuration files that will be copied from the global zone
##   to the non-global zone if an exclusive IP stack is used
##   Note: Add only fully qualified filenames here!
##
  EXCLUSIVE_IP_STACK_CONFIG_FILES="
/etc/netmasks
/etc/networks
/etc/defaultrouter
/etc/hosts
"

## NAME_SERVER_CONFIG_FILES 
##   name server configuration files
##   Note: Add only fully qualified filenames here!
##
  NAME_SERVER_CONFIG_FILES="
/etc/resolv.conf
/etc/nsswitch.conf
"

## DEFAULT_FREE_SPACE_FOR_THE_ZONE
##   free space neccessary for the zone in KB
##   (the default depends on the type of the zone)
##
  DEFAULT_FREE_SPACE_FOR_THE_ZONE=""

## DEFAULT_FREE_SPACE_FOR_A_BIG_ZONE
##   default free space needed for a big zone in KB
##
  DEFAULT_FREE_SPACE_FOR_A_BIG_ZONE=3500000

## DEFAULT_FREE_SPACE_FOR_A_SMALL_ZONE
##   default free space needed for a small zone in KB
##
  DEFAULT_FREE_SPACE_FOR_A_SMALL_ZONE=200000

## DEFAULT_ZONE_CONFIG_ONLY
##   if true the zone will only be configured but not installed
##   default: configure and install the zone
##
  DEFAULT_ZONE_CONFIG_ONLY=${__FALSE}

## DEFAULT_NO_ZONE_CONFIG_CHECKS
##   if true the script will not check the zone configuration
##   default: check the zone configuration before creating the zone
##
  DEFAULT_NO_ZONE_CONFIG_CHECKS=${__FALSE}

## DEFAULT_ZONE_MODE
##   default type of the new zone; 
##   possible values: small (= sparse zone) or big (= whole root zone)
##
  DEFAULT_ZONE_MODE="small"

## DEFAULT_ZONE_CLONE_SOURCE
##   source zone for cloning
##
  DEFAULT_ZONE_CLONE_SOURCE=""
  
## DEFAULT_ZONE_PATH
##   base directory for zones (can be a symbolic link; 
##   this will be resolved by the script)
##   Use either ZONE_PATH or ZONE_PATH_ABSOLUTE -- not both
##   (see comments for ZONE_PATH_ABSOLUTE)
## 
  DEFAULT_ZONE_PATH="/zones"

## DEFAULT_ZONE_PATH_ABSOLUTE
##   absolute directory for the zone (can be a symbolic link; 
##   this will be resolved by the script)
##
##   e.g.
##   ZONE_NAME=myzone
##   ZONE_PATH=/zones/myzone
##    -> The zone will be created in the directory /zones/myzone/myzone
##
##   ZONE_NAME=myzone
##   ZONE_PATH_ABSOLUTE=/zones/myzone
##    -> The zone will be created in the directory /zones/myzone
##
##   Notes: 
##   Use either ZONE_PATH or ZONE_PATH_ABSOLUTE -- not both
##    
  DEFAULT_ZONE_PATH_ABSOLUTE=""

## DEFAULT_ZONE_FLASHIMAGE
##   flash image for the installation of the zone
##   default: none
##
  DEFAULT_ZONE_FLASHIMAGE=""
   
## DEFAULT_ZONE_ROOT_PASSWORD
##   default for the root password is the password
##   of the existing root user
##  
  DEFAULT_ZONE_ROOT_PASSWORD="$( grep root /etc/shadow 2>/dev/null | cut -f2 -d ":" )"

## DEFAULT_ZONE_TZ
##   the default timezone is the timezone of the machine
##
  DEFAULT_ZONE_TZ="$( grep "^TZ=" /etc/TIMEZONE 2>/dev/null | cut -f2 -d"=" )"
  [ "${DEFAULT_ZONE_TZ}"x = ""x ] && DEFAULT_ZONE_TZ="${TZ}"

## DEFAULT_ZONE_LOCALE
##   default locale is the current locale
##
  DEFAULT_ZONE_LOCALE="${LANG}"
  [ "${DEFAULT_ZONE_LOCAL}"x = ""x ] && DEFAULT_ZONE_LOCALE="C"

## DEFAULT_ZONE_TERMINAL  
##   default terminal type for the zone
##
  DEFAULT_ZONE_TERMINAL="${TERM:-vt100}"

## DEFAULT_ZONE_TIMESERVER
##   default timeserver for the zones
##
  DEFAULT_ZONE_TIMESERVER="localhost"

## DEFAULT_ZONE_CUSTOMIZE_SCRIPT_SOURCE  
##   default customize script for the zone
##   Possible values for this variabe are:
##       "builtin", "none", or the name of an existing script
##   The customize script runs inside the new zone
##   while first rebooting the zone
##
  DEFAULT_ZONE_CUSTOMIZE_SCRIPT_SOURCE="builtin"

## DEFAULT_ZONE_CUSTOMIZE_SCRIPT_TARGET
##   fully qualified name of the customize script inside the zone
##
##   Note: The runlevel in which the script runs depends on the path of the 
##         customize scripts
##         The default is rcS.d = single-user-mode
##       
  DEFAULT_ZONE_CUSTOMIZE_SCRIPT_TARGET="/etc/rcS.d/S99customize_script"

## DEFAULT_ZONE_SMF_PROFILE
##   SMF site profile for the zone; default: none
##
  DEFAULT_ZONE_SMF_PROFILE=""

## DEFAULT_ZONE_IP_ADDRESS  
##   there is no default IP address for the zone
##
  DEFAULT_ZONE_IP_ADDRESS=""

## DEFAULT_ZONE_IP_STACK
##   this can be either SHARED or EXCLUSIVE; the default is SHARED
##
  DEFAULT_ZONE_IP_STACK="SHARED"

## DEFAULT_ZONE_NETMASK
##  netmask for the zone 
##
  DEFAULT_ZONE_NETMASK=""
  
## DEFAULT_ZONE_DEFAULT_ROUTER
##  default router for the zones 
##  Note: A default router for a zone can only be configured for zones in Solaris 10 Update 6 and newer
##
  DEFAULT_ZONE_DEFAULT_ROUTER=""
#  $(  netstat -rn | grep "^default" | tr -s " " | cut -f2 -d " " | head -1 )"
  
## ZONE_GLDV3_CHECK
##   Do check the GLDv3 capabiltiy (yes, default) of the network adapter or not (no)
##
  DEFAULT_ZONE_GLDV3_CHECK="yes"

## DEFAULT_ZONE_NAME
##   there is no default name for the zone
##
  DEFAULT_ZONE_NAME=""

## DEFAULT_ZONE_GLOBAL_OPTIONS
##   additional global options for the zone
##   that use the syntax "option=value" or "option"
##   You can NOT use blanks in the parameter 
##   for this option!
##   Please note that the script DOES not check the syntax or semantic for these entries!
##
  DEFAULT_ZONE_GLOBAL_OPTIONS=""

## DEFAULT_ZONE_BRAND
##   brand for the zone, e.g. SUNWsolaris8
##   Default is : use the installed Solaris version
##
  DEFAULT_ZONE_BRAND=""
  
## DEFAULT_ZONE_SET_GLOBAL_OPTIONS
##   additional global options for the zone 
##   that use the syntax "set option=value"
##   Please note that the script DOES not check the syntax or semantic for these entries!
##
  DEFAULT_ZONE_SET_GLOBAL_OPTIONS=""
   
## DEFAULT_ZONE_HOSTID   
##   hostid for the zone
##
  DEFAULT_ZONE_HOSTID=""
   
## DEFAULT_USE_EXISTING_NAMESERVER_CONFIG
##   default nameserver configuration is: 
##     use the existing nameserver configuration
##
  DEFAULT_USE_EXISTING_NAMESERVER_CONFIG=${__TRUE}

## DEFAULT_ZONE_AUTOBOOT
##   enable zone autoboot?; default is false
##
  DEFAULT_ZONE_AUTOBOOT=${__FALSE}

## DEFAULT_ZONE_NETWORK_INTERFACE
##   the default network interface for the zone
##   The default is the network interface which hosts the
##   network with the IP address for the zone
##
  DEFAULT_ZONE_NETWORK_INTERFACE=""

## DEFAULT_ZONE_ADD_NETWORK_INTERFACE
##   additional network interfaces for the zones
##
  DEFAULT_ZONE_ADD_NETWORK_INTERFACE=""

## DEFAULT_BOOT_THE_ZONE_NOW
##   boot the zone after installation?
##
  DEFAULT_BOOT_THE_ZONE_NOW=${__FALSE}

## DEFAULT_ZONE_MEMORY_LIMIT
##   the memory limit for the zone
##   There is no default for this keyword
##   Note that this configuration is only supported in 
##   Solaris 10 8/07 and newer!
##  
  DEFAULT_ZONE_MEMORY_LIMIT=""

## DEFAULT_ZONE_SWAP_LIMIT
##   the swap limit for the zone
##   There is no default for this keyword
##   Note that this configuration is only supported in 
##   Solaris 10 8/07 and newer!
##
  DEFAULT_ZONE_SWAP_LIMIT=""

## DEFAULT_ZONE_CAPPED_CPU_COUNT
##   the max. number of CPUs for the zone
##   There is no default for this keyword
##
  DEFAULT_ZONE_CAPPED_CPU_COUNT=""

## DEFAULT_ZONE_CPU_COUNT
##   the number of CPUs for the zone
##   There is no default for this keyword
##   Note that this configuration is only supported in 
##   Solaris 10 8/07 and newer!
##
  DEFAULT_ZONE_CPU_COUNT=""

## DEFAULT_ZONE_CPU_SHARES
##   the number of CPU shares for the zone
##   There is no default for this keyword
##   Note that this configuration is only supported in 
##   Solaris 10 8/07 and newer!
##
  DEFAULT_ZONE_CPU_SHARES=""

## DEFAULT_ZONE_INHERITED_DIRS
##   add. directories that should be inherited by the zone
##   Note: Directories with space or tabs in the name are NOT supported!
##
  DEFAULT_ZONE_INHERITED_DIRS=""

## DEFAULT_ZONE_WRITABLE_DIRS
##   directories that should be mounted r/w in the zone
##   Format of the entries:
##      zone_dir:global_dir
##   Note: Directories with space or tabs in the name are NOT supported!
##         global_dir can be either a directory or ZFS filesystem.
##
  DEFAULT_ZONE_WRITABLE_DIRS=""

## DEFAULT_ZONE_READONLY_DIRS
##   directories that should be mounted r/o in the zone
##   Format of the entries:
##      zone_dir:global_dir
##   Note: Directories with space or tabs in the name are NOT supported!
##         global_dir can be either a directory or ZFS filesystem.
##
  DEFAULT_ZONE_READONLY_DIRS=""

## DEFAULT_ZONE_DATASETS
##   ZFS datasets for the zone
##
  DEFAULT_ZONE_DATASETS=""

## DEFAULT_ZONE_DEVICES
##
  DEFAULT_ZONE_DEVICES=""
  
## DEFAULT_EDIT_ZONE_CONFIG
##   edit the zone configuration before creating the zone 
##   after exiting the editor the user can choose to continue
##   or to abort the zone installation
##
##   Note: The editor used is ${EDITOR}
##
  DEFAULT_EDIT_ZONE_CONFIG=${__FALSE}

## DEFAULT_ZONE_TEMPLATE_DIRS
##   Template directories for the zone; all files and directories in the
##   directories listed in this variable are copied to the root dir of the
##   zone
  if [ -d "${DEFAULT_ZONE_PATH}/template_dir" ] ; then
    ZONE_TEMPLATE_DIRS="${DEFAULT_ZONE_PATH}/template_dir"
  else
    ZONE_TEMPLATE_DIRS=""
  fi

## DEFAULT_ZONE_FILES_TO_COPY
##   File which should be copied from the global zone to the non-global zone
##   The file(s) are copied to the same location in the non-global zone 
##
  DEFAULT_ZONE_FILES_TO_COPY=""

## DEFAULT_ZONE_FINISH_SCRIPT
##
##   finish script for creating the zone
##   This script is called in the global zone after the new 
##   zone is created and configured but before the zone is booted
##   The parameters for the script are
##     - the fully qualified name of the directory for the zone
##
##   Note: Please write your finish scripts so that they handle multiple parameter correct
##         because there may be additional parameter in a future version of this script!
##
##   The finish script must return 0 if everything is okay; everthing else
##   is interpreted as error and the script stops.
##
##   Note that you can change the configuration of the zone from within the finish script 
##   with a few exceptions (e.g. you can NOT add directories to inherit here)
##
##   All environment variables beginning with ZONE_ are exported and can be used by the
##   finish script. The exported variables are:
##
##     ZONE_CONFIG_ONLY
##     ZONE_AUTOBOOT
##     ZONE_CLONE_SOURCE
##     ZONE_CUSTOMIZE_SCRIPT_CONTENTS
##     ZONE_CUSTOMIZE_SCRIPT_SOURCE
##     ZONE_CUSTOMIZE_SCRIPT_TARGET
##     ZONE_FINISH_SCRIPT
##     ZONE_IP_ADDRESS
##     ZONE_LOCALE
##     ZONE_MODE
##     ZONE_NAME
##     ZONE_NETWORK_INTERFACE
##     ZONE_ADD_NETWORK_INTERFACE
##     ZONE_PATH
##     ZONE_PATH_ABSOLUTE
##     ZONE_FLASHIMAGE
##     ZONE_ROOT_PASSWORD
##     ZONE_SMF_PROFILE
##     ZONE_TERMINAL
##     ZONE_TIMESERVER
##     ZONE_TZ
##     ZONE_IP_STACK
##     ZONE_NETMASK
##     ZONE_DEFAULT_ROUTER
##     ZONE_MEMORY_LIMIT
##     ZONE_SWAP_LIMIT
##     ZONE_CPU_COUNT
##     ZONE_CAPPED_CPU_COUNT
##     ZONE_BRAND
##     ZONE_CPU_SHARES
##     ZONE_INHERITED_DIRS
##     ZONE_WRITABLE_DIRS
##     ZONE_READONLY_DIRS
##     ZONE_DATASETS
##     ZONE_GLDV3_CHECK
##     ZONE_GLOBAL_OPTIONS
##     ZONE_SET_GLOBAL_OPTIONS
##     ZONE_HOSTID
##     ZONE_DEVICES
##     ZONE_TEMPLATE_DIRS
##     ZONE_FILES_TO_COPY
##
##
  DEFAULT_ZONE_FINISH_SCRIPT=""

## DEFAULT_ZONE_CUSTOMIZE_SCRIPT_CONTENTS
##   builtin customize script for the zones
##   The customize script runs inside the new zone while first
##   booting the zone
##   You must remove the script itself in the script if the
##   script should only run once (see below)!
##
  DEFAULT_ZONE_CUSTOMIZE_SCRIPT_CONTENTS="
  echo \"Customization of the zone is running ...\"

  echo \"Disabling sendmail ...\"
  svcadm disable sendmail
  svcadm disable svc:/application/cde-printinfo:default

  echo \" ... customization done. Removing the customize script\"
  rm \$0
"
  
# only change the following variables if you know what you are doing 
#
  ZONE_CONFIG_FILE="/etc/create_zone.cfg"

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
typeset  __SHORT_DESC="create Solaris zones unattended"

## __LONG_USAGE_HELP - Additional help if the script is called with 
##   the parameter "-v -h"
##
##   Note: To use variables in the help text use the variable name without
##         an escape character, eg. ${OS_VERSION}
##
__LONG_USAGE_HELP='
      -F/+F - do not check the zone configuration if set (-F)
              Current value: $( ConvertToYesNo ${NO_ZONE_CONFIG_CHECKS} )
              Long format: --no_zone_config_checks
      -B/+B - configure the zone but do NOT install the zone if set (-B)
              Current value: $( ConvertToYesNo ${ZONE_CONFIG_ONLY} )
              Long format: --only_configure_zone			  
      -z    - zone name, mandatory, no default
              Current value: ${ZONE_NAME}
              Long format: --zone_name
      -i    - zone ip address, mandatory, no default
              Current value: ${ZONE_IP_ADDRESS}      
              use xx.xx.xx.xx/yy to specifiy a netmask
              Long format: --zone_ip_address
      -r      default router for the zone; 
              current value ${ZONE_DEFAULT_ROUTER}
              use "none" to unset the default router
              Long format: --zone_default_router
      -I/+I - use an exclusive IP stack (-I) or a shared IP stack (+I); 
              current value ${ZONE_IP_STACK}
              Long format: --zone_ip_stack / ++zone_ip_stack
      -p    - zone path; 
              current value: ${ZONE_PATH}
              Long format: --zone_path
              Note: The zone will be created in the directory 
                    <zone_path>/<zone_name>
                    Use either -p or -P 
      -P    - absolute zone path; 
              current value: ${ZONE_PATH_ABSOLUTE}
              Long format: --zone_path_absolute              
              Note: The zone will be created in the directory 
                    <zone_path_absolute>
                    Use either -p or -P 
      -N    - create the zone by cloning another zone
              Current value: ${ZONE_CLONE_SOURCE}
              Long format: --clone 
      +N    - create the zone by installing it from the global zone
              Long format: ++clone 
      -A    - zone network adapter
              Current value: ${ZONE_NETOWRK_INTERFACE}
              Long format: --zone_network_interface
      -b    - create a big zone (= whole root zone)
              Current value: ${ZONE_MODE}
              Long format: --big
      +b    - create a small zone (= sparse zone)
              Long format:  ++big
      -s    - freespace in KB necessary for the zone
              Current value: ${FREE_SPACE_FOR_THE_ZONE}
              Use 0 to suppress the free space check
              Long format: --free_space
      -e|+e - edit the zone configuration before creating the zone
              current value: $( ConvertToYesNo ${EDIT_ZONE_CONFIG} )
              If this parameter is found, the script calls the standard 
              editor (environment variable EDITOR or vi if not set) for 
              the zone configuration before creating the zone
              Long format: --edit
      -d    - directory to inherit by the zone (*)
              Current Value: ${ZONE_INHERITED_DIRS}
              Directory names with spaces or tabs are NOT supported
              Long format: --inherit
      +d    - remove all additional inherited directories and add the 
              new directory to the list of directories to inherit
              (use "none" to delete the complete list)
              This parameter will undo all previous found -d parameter
              and also delete the default values from the config file
              Long format: ++inherit
      -R    - directory to mount readonly in the zone (*)
              Current value: ${ZONE_READONLY_DIRS}
              Format of the entry: zone_dir:global_dir
              Directory names with spaces or tabs are NOT supported
              If the directory global_dir does not exist it will be
              created.
              global_dir can also be a ZFS filesystem
              Long format: --readonlydir
      +R    - reset the list of readonly directories and add the new 
              directory to the list of readonly directories 
              (use "none" to delete the complete list)              
              Format of the entry: zone_dir:global_dir
              If the directory global_dir does not exist it will be
              created.
              global_dir can also be a ZFS filesystem
              This parameter will undo all previous found -R parameter
              and also delete the default values from the config file
              Long format: ++readonlydir
      -w    - directory to mount writable in the zone (*)
              Current value: ${ZONE_WRITABLE_DIRS}
              Format of the entry: zone_dir:global_dir
              Directory names with spaces or tabs are NOT supported
              If the directory global_dir does not exist it will be
              created.
              global_dir can also be a ZFS filesystem
              Long format: --writabledir
      +w    - reset the list of writable directories and add the new 
              directory to the list of writable directories 
              (use "none" to delete the complete list)              
              Format of the entry: zone_dir:global_dir
              If the directory global_dir does not exist it will be
              created.
              global_dir can also be a ZFS filesystem
              This parameter will undo all previous found -w parameter
              and also delete the default values from the config file
              Long format: ++writabledir
      -t    - template directory for the zone (*)
              Current value: ${ZONE_TEMPLATE_DIRS}
              All files and directories in this directory will be
              copied to the root filesystem of the zone after the zone
              is created.
              Directory names with spaces or tabs are NOT supported
              Long format: --templatedir
      +t    - reset the list of template dirs and add a new directory
              directory to the list of template directories 
              (use "none" to delete the complete list)              
              This parameter will undo all previous found -t parameter
              and also delete the default values from the config file
              Long format: ++templatedir
      -c    - copy a file from the global zone to the non-global zone (*)
              Long format: ++copyfile
      +c    - reset the list of files to copy to the zone and add a new 
              file to the list of files to copy
              (use "none" to delete the complete list)              
              This parameter will undo all previous found -c parameter
              and also delete the default values from the config file
              Long format: ++copyfile
      -Z    - ZFS dataset for the zone (*)
              Current Value: ${ZONE_DATASETS}
              Long format: --dataset
      +Z    - reset the list of ZFS datasets for the zone and add the 
              new ZFS dataset to the zone
              (use "none" to delete the complete list)              
              This parameter will undo all previous found -Z parameter
              and also delete the default values from the config file
              Long format: ++dataset
      -x key=value (*)
            - define various config parameter for the zone (see below)
              Long format: --config

    The parameter marked with (*) can be used multiple times.


    Known key/value pairs for the parameter -x are
    (keys marked with (*) can be used more than once):

      no_zone_config_checks=yes|no
        Do not check the zone configuration
        current value: $( ConvertToYesNo ${NO_ZONE_CONFIG_CHECKS} ) 
        default: check the zone configuration
        shortcut: -F
        
      zone_config_only=yes|no
        Only configure the zone but do not install the zone
        current value: $( ConvertToYesNo ${ZONE_CONFIG_ONLY} )
        default: configure and install the zone
        shortcut: -B
		
      zone_name=name_of_the_zone
        current value: ${ZONE_NAME}
        no default
        shortcut: -z

      zone_brand=brand_of_the_zone
        example: SUNWsolaris8
        current value: ${ZONE_BRAND}
        no default 
   
      zone_clone_source=name_of_the_zone_to_clone
        Create the zone by cloning an existing zone
        current value: ${ZONE_CLONE_SOURCE}
        no default
        shortcut: -N

      zone_memory_limit=memory_limit
        current value: ${ZONE_MEMORY_LIMIT}
        memory limit for the zone; no default

      zone_swap_limit=swap_limit
        current value: ${ZONE_SWAP_LIMIT}
        no default
        swap limit for the zone

      zone_cpu_shares=no_of_cpu_shares
        current value: ${ZONE_CPU_SHARES}
        no default
        no of CPU shares for the zone

      zone_capped_cpu_count=no_of_cpus
        current value: ${ZONE_CAPPED_CPU_COUNT}
        no default
        max no. of cpus for the zone
       
      zone_cpu_count=no_of_cpus
        current value: ${ZONE_CPU_COUNT}
        no default
        no. of cpus for the zone

      address=ip_address_for_the_zone
    or
      zone_ip_address=ip_address_for_the_zone
        current value: ${ZONE_IP_ADDRESS}
        speficy the IP address for the zone; use xx.xx.xx.xx/yy to 
        specify a netmask also 
        no default
        shortcut: -i

      zone_network_interface=network_interface_for_the_zone
    or
      physical=network_interface_for_the_zone
        current value: ${ZONE_NETWORK_INTERFACE}
        the default depends on the IP address choosen for the zone
        When configuring a zone with exclusive IP stack (-I) there is no 
        default for this parameter and therefore this parameter is 
        mandatory
        shortcut: -A

      zone_default_router=ip_address_of_the_default_router
        current value: ${ZONE_DEFAULT_ROUTER}
        The default router for the zone; 
        no default
        use none to unset the default router

      zone_netmask=netmask_for_the_zone
        current value: ${ZONE_NETMASK}
        This is the netmask for zones with exclusive IP stack
        no default

      zone_add_network_interface=interface:address:defrouter  (*)
	    current value: ${ZONE_ADD_NETWORK_INTERFACE}
		Additional network interfaces for the zone
		no default

      zone_ip_stack={shared|exclusive}
        current value: ${ZONE_IP_STACK}
        this is the type of the IP stack for the zone
        default: shared IP stack
        shortcut: -I

      zone_gldv3_check={yes|no}
        current value: ${ZONE_GLDV3_CHECK}
        if this key is set to no, the script will not check if the 
        network adapter for the zone uses a GLDv3 driver 
        default: do not check

      zone_mode=[small|big] 
        current value: ${ZONE_MODE}
        shortcut: -b|+b
        default: small (= sparse zone)

      zonepath=path_for_the_zone 
    or
      zone_path=path_for_the_zone
        current value: ${ZONE_PATH}
        shortcut: -p
        The zone will be created in the directory [zone_path]/[zone_name]
        no default
        Use either zone_path or zone_path_absolute -- not both
        
      zone_path_absolute=absolute_path_for_the_zone
        current value: ${ZONE_PATH_ABSOLUTE}
        shortcut: -P
        The zone will be created in the directory [absolute_zonepath]
        no default
        Use either zone_path or zone_path_absolute -- not both

      zone_flashimage=flashimage_for_the_zone
        current value: ${ZONE_FLASHIMAGE}
        flashimage to be used to install the zone
        no default
              
      zone_root_password=encrypted_password_for_root
        current value: ${ZONE_ROOT_PASSWORD}
        The default is the passwort from the root user in the global zone
        Use none for no root user password
        
      zone_tz=timezone_for_the_zone
        current value: ${ZONE_TZ}
        The default is the current TIMEZONE of the global zone

      zone_locale=locale_for_the_zone
        current value: ${ZONE_LOCALE}
        The default is the current locale

      zone_terminal=terminal_type_for_the_zone
        current value: ${ZONE_TERMINAL}
        The default is the value of the variable TERM
        or vt100 if the variable TERM is not set

      zone_timeserver=timeserver_for_the_zone
        current value: ${ZONE_TIMESERVER}
        no default

      zone_finish_script=finish_script_for_the_zone
        current value: ${ZONE_FINISH_SCRIPT}
        The finish script runs in the global zone after the zone is 
        created and configured but before it is booted. The parameter
        for the finish_script is the directory used for the zone
        Use "none" for no finish script
        no default
        
      zone_customize_script_source=customize_script_for_the_zone
        current value: ${ZONE_CUSTOMIZE_SCRIPT_SOURCE}
        The customization script runs inside the new zone 
        while first booting the zone.

        Use "builtin" for the builtin customize script; use "none" for 
        no customize script
        
        The builtin customize script is:

        # --- built in script starts
${ZONE_CUSTOMIZE_SCRIPT_CONTENTS}
        # --- built in script ends

        (defined in the variable DEFAULT_ZONE_CUSTOMIZE_SCRIPT_CONTENTS 
          in the config file)

      zone_customize_script_target=fqn_of_the_customize_script
        FQN of the customize script inside the zone
        current value: ${ZONE_CUSTOMIZE_SCRIPT_TARGET}

      zone_profile=smf_profile_for_the_zone
        current value: ${ZONE_SMF_PROFILE}

      use_existing_nameserver_config=[yes|no]
        current value: $( ConvertToYesNo ${USE_EXISTING_NAMESERVER_CONFIG} )
        If this variable is true the files

${NAME_SERVER_CONFIG_FILES}

        from the global zone are copied to the new zone
        (the list of files is defined in the variable NAME_SERVER_CONFIG_FILES 
         in the config file)
         
      zone_autoboot=[yes|no] 
    or
      autoboot=[yes|no] 
        current value: $( ConvertToYesNo ${ZONE_AUTOBOOT} )
      
      boot_the_zone_now=[yes|no] 
        current value: $( ConvertToYesNo ${BOOT_THE_ZONE_NOW} )
        if yes, the zone will be booted automatically if configured and
        created without errors.

      free_space_for_the_zone=freespace_necessary_in_kb
        The defaults are 
          for big zones: ${DEFAULT_FREE_SPACE_FOR_A_BIG_ZONE} kb
          for small zones: ${DEFAULT_FREE_SPACE_FOR_A_SMALL_ZONE} kb
        Use 0 to suppress the free space check
        shortcut: -s

      zone_inherited_dir=dir_name  (*)
        current value: ${ZONE_INHERITED_DIRS}
        Directory which should be inherited by the zone. 
        The default is only to inherit the default directories 
        Directories with space or tabs in the name are NOT supported!
        shortcut: -d

      zone_readonly_dir=zone_dir:global_dir  (*)
        current value: ${ZONE_READONLY_DIRS}
        Directory which should be mounted readonly in the zone. 
        Directories with space or tabs in the name are NOT supported!
        If the directory in the global zone does not exist it will 
        be created.
        global_dir can be either a directory or a ZFS filesystem;
        ZFS filesystems must already exist
        shortcut: -R

      zone_writable_dir=zone_dir:global_dir  (*)
        current value: ${ZONE_WRITABLE_DIRS}
        Directory which should be mounted writable in the zone. 
        Directories with space or tabs in the name are NOT supported!
        If the directory in the global zone does not exist it will 
        be created.
        global_dir can be either a directory or a ZFS filesystem;
        ZFS filesystems must already exist        
        shortcut: -w

      zone_template_dir=dir_name  (*)
        current value: ${ZONE_TEMPLATE_DIRS}
        All files and directories in this directory wil be copied to the
        root filesystem of the zone
        Directories with space or tabs in the name are NOT supported
        shortcut: -t

      zone_copy_file=source_file (*)
        current value: ${ZONE_FILES_TO_COPY}
        copy a file from the global zone to the non-global zone 
        filenames with space or tabs in the name are NOT supported
        shortcut: -c
        
      zone_dataset=zpool (*)
        current value: ${ZONE_DATASETS}
        ZFS dataset for the zone
        shortcut: -Z

      zone_device=device (*)
        current value: ${ZONE_DEVICES}
        device for the zone 

      zone_global_option=option (*)
        current value: ${ZONE_GLOBAL_OPTIONS}
        Add. global options that use the syntax \"option=value\" or
        \"option\" can be defined using this keyword. 
        These entries are NOT checked by the script!

      zone_set_global_option=option (*)
        current value: ${ZONE_SET_GLOBAL_OPTIONS}
        Add. global options set use the syntax \"set options=value\" or
        \"set option\" can be defined using this keyword. 
        These entries are NOT checked by the script!

      zone_hostid=hostid
        current value: ${ZONE_HOSTID}
        
Please note that you need Solaris 10 8/07 or newer for the configuration 
options 

  zone_memory_limit, zone_swap_limit, zone_cpu_count, and zone_cpu_shares

Please note that you need Solaris 10 6/08 or newer for the configuration 
options

  zone_default_router (shortcut -r)
  
'

## __SHORT_USAGE_HELP - Additional help if the script is called with the parameter "-h"
##
##   Note: To use variables in the help text use the variable name without an escape
##         character, eg. ${OS_VERSION}
##
__SHORT_USAGE_HELP='
                        -z zone_name -i zone_ip_address 
                        [-p zone_path|-P zone_path_absolute] [-r zone_def_router] 
                        [-A zone_network_adapter] [-b|+b] [-s freespace] [-x key=value] [-t templatedir]
                        [-e] [-d dir_to_inherit] [-w zonedir:globaldir] [-R zonedir:globaldir] [-Z dataset] 
                        [-N sourcezone] [-c sourcefile] [-I|+I] [-B|+B] [-F|+F]

  Known keys for the parameter -x :
    zone_name zone_ip_address zone_network_interface zone_mode zone_ip_stack zone_netmask zone_default_router
    zone_root_password zone_tz zone_locale zone_terminal zone_timeserver zone_gldv3_check zone_path 
    zone_path_absolute zone_customize_script_source zone_customize_script_target zone_finish_script 
    zone_autboot boot_the_zone_now free_space_for_the_zone zone_profile zone_hostid
    use_existing_nameserver_config zone_add_network_interface
    zone_memory_limit zone_swap_limit zone_cpu_count zone_cpu_shares zone_capped_cpu_count
    zone_inherited_dir zone_writabledir zone_readonly_dir zone_dataset     
    zone_clone_source zone_device zone_global_option zone_set_global_option zone_brand
    zone_template_dir zones_copy_file zone_config_only zone_flashimage no_zone_config_checks

  The parameter -d, -R, -w, -t, -c, -Z, and -x can be used multiple times.
'

__USAGE_EXAMPLES='
  # Example using only the mandatory parameter
  #
  create_zone.sh -z rtdev02zone005 -i 10.225.111.158/24

  # Example using some more parameter
  #
  create_zone.sh -z rtdev02zone005 -i 10.225.111.158/24 \
	-A vnet1 -r 10.225.111.254 \
	-x zone_add_network_interface=vnet4:10.225.247.157/24 \
	-x zonepath=/zones/rtdev02zone005 \
	-w /applications:/zones/rtdev02zone005/data/applications \
	-w /usr/sys/inst.images/SunOS:/zones/rtdev02zone005/data/usr/sys/inst.images/SunOS
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
__ONLY_ONCE=${__FALSE}

## __ REQUIRED_OS - required OS (uname -s) for the script (def.: none)
##    use blanks to separate the OS names if the script runs under multiple OS
##    e.g. "SunOS"
##
__REQUIRED_OS="SunOS"

## __REQUIRED_OS_VERSION - required OS version for the script (def.: none)
##   minimum OS version necessary, e.g. 5.10
##   "" = no special version necessary
##
__REQUIRED_OS_VERSION="5.10"

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
__REQUIRED_MACHINE_CLASS=""

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

       __MACHINE_SUBTYPE=""
#       [  -x /usr/platform/${__MACHINE_PLATFORM}/sbin/prtdiag ] &&   \
#         ( set -- $( /usr/platform/${__MACHINE_PLATFORM}/sbin/prtdiag | grep "System Configuration" ) ; shift 5; echo $* ) 2>/dev/null | read  __MACHINE_SUBTYPE

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
__LOGIN_USERID="$( set -- $( who am i ) ; echo $1 )"
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
##          2 - invalid usage (usage (to much or not enough parameter)
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
     cp -p "${CURFILE}" "${CUR_BKP_FILE}"
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
  typeset __FUNCTION="rand";    ${__FUNCTION_INIT} ; ${__DEBUG_CODE}
	
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
# Create the lock file if possible
#
# usage: CreateLockFile
#
# returns: 0 - lock created
#          1 - lock already exist or error creating the lock
#
# Note: The old code uses a symbolic link because this is always a atomic operation
#
function CreateLockFile {
  typeset __FUNCTION="CreateLockFile";    ${__FUNCTION_INIT} ; ${__DEBUG_CODE}
 
# for compatibilty reasons the old code can still be activated if necessary
  typeset __USE_OLD_CODE=${__FALSE}
  
  typeset LN_RC=""

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
  (( COLUMNS = COLUMNS - 1 ))
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

# no of lines in the file (max array elements in ksh88 = 4096)
#
     MAX_ARRAY_INDEX="$( wc -l ./create_zone.sh | tr -s " "  | cut -f2 -d " " )"
     
    typeset oIFS=$IFS
    IFS="\n"

    i=1

    while read -r __SCRIPT_ARRAY[$i] ; do
      i=$(( i+1 ))
    done <$0

    __SCRIPT_ARRAY[0]=$i

    IFS=$oIFS
    
   [  "${_SCRIPT_ARRAY[0]}"x != "${MAX_ARRAY_INDEX}"x ] && \
     die 237 "Script file has to many lines for the debug handler"

    
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

  LogRuntimeInfo "Script template used is \"${__SCRIPT_TEMPLATE_VERSION}\" ."

  __WRITE_CONFIG_AND_EXIT=${__FALSE} 
  
# init the variables
  eval "${__CONFIG_PARAMETER}"

# read the config file
  ReadConfigFile

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

${__USAGE_EXAMPLES}  
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

${__USAGE_EXAMPLES}  
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
# sub routines:
#

## --------------------------------------
## YourRoutine
##
## template for a user defined function 
##
## usage: YourRoutine
##
## returns:  ${__TRUE} - ok
##           ${__FALSE} - error
##           ${__INVALID_USAGE} - invalid usage
##          
##
function YourRoutine {
  typeset __FUNCTION="YourRoutine";   ${__FUNCTION_INIT} ;  ${__DEBUG_CODE}
  
#    typeset __FUNCTION="YourRoutine";     ${__DEBUG_CODE}
   
# init the return code
  THISRC=${__INVALID_USAGE}

# check the parameter count
  CheckParameterCount 0 "$@" || die 240 "Internal error detected"
  
  if [ $# -eq 0 ] ; then

# add code here
:

  fi
  
#  echo ""
#  echo "LineNo: ${LINENO}; Function ${__FUNCTION} "; trap
#  read test

  return ${THISRC}
}

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

## --------------------------------------
## check_ip_address
##
## check if an IP address already exists
##
## usage: check_ip_address ip_address zonename
##
## returns:  ${__TRUE} - ok, IP address is unused
##           ${__FALSE} - error, IP address is in use
##          
##
function check_ip_address {
  typeset __FUNCTION="check_ip_address";   ${__FUNCTION_INIT} ;    ${__DEBUG_CODE}
  
  typeset ZONE_IP_ADDRESS="$1"
  typeset ZONE_NAME="$2"
  
  typeset IP_ADDRESS_OK=${__TRUE}

  ping "${ZONE_IP_ADDRESS}" 1 1 >/dev/null 2 >/dev/null
  if [ $? -eq 0 ] ; then
    if [ ${ZONE_EXISTS} = ${__TRUE} -a ${__OVERWRITE_MODE} = ${__TRUE} ] ; then
# the zone already exists and should be overwritten -> check if the IP address is the IP address of the existing zone
      grep  "${ZONE_IP_ADDRESS}"  2>/dev/null 1>/dev/null <<EOT
$( zonecfg -z "${ZONE_NAME}" info | grep address | cut -f2 -d ":" )
EOT
      [ $? -ne 0 ] && IP_ADDRESS_OK=${__FALSE}
    else
      IP_ADDRESS_OK=${__FALSE}
    fi
  fi	
  return ${IP_ADDRESS_OK}
}

## --------------------------------------
## get_network_adapter_type
##
## get the type of a network adapter
##
## usage: get_network_adapter_type network_adapter
##
## returns:  ${__TRUE} - the name of the network adapter is written to STDOUT
##           ${__FALSE} - network adapter not defined; an empty string is written to STDOUT
##          
##
function get_network_adapter_type {
  typeset __FUNCTION="get_network_adapter_type";   ${__FUNCTION_INIT} ;    ${__DEBUG_CODE}
  
  typeset ZONE_NETWORK_INTERFACE="$1"
  typeset NETWORK_ADAPTER_TYPE=""
  
# init the return code
  typeset THISRC=${__FALSE}
  
  if [ $# = 1 ] ; then
	NETWORK_ADAPTER_TYPE="$( dladm show-link -p "${ZONE_NETWORK_INTERFACE}" 2>/dev/null | cut -f 2 -d " ")"
	[ "${NETWORK_ADAPTER_TYPE}"x = ""x ] && \
      NETWORK_ADAPTER_TYPE="$( dladm show-link -p -o CLASS "${ZONE_NETWORK_INTERFACE}" 2>/dev/null )"
  fi
  
  [ "${NETWORK_ADAPTER_TYPE}"x != ""x ] && THISRC=${__TRUE}
  echo "${NETWORK_ADAPTER_TYPE}"
  
  return ${THISRC}
}


## --------------------------------------
## ProcessParameter
##
## description  Process the parameter -x keyword=keyvalue
##
## usage: ProcessParameter
##
## returns: 0 - parameter okay
##          1 - parameter invalid
##
ProcessParameter(){
  typeset __FUNCTION="ProcessParameter";   ${__FUNCTION_INIT} ;    ${__DEBUG_CODE}
  
  typeset THISRC=0

  typeset THIS_PARM="$*"
  typeset KEYVALUE="${THIS_PARM#*=}"
  typeset KEYNAME="${THIS_PARM%%=*}"

  case ${KEYNAME} in

    "no_zone_config_checks" )
      CheckYNParameter "${KEYVALUE}"
      THATRC=$?
      if [ ${THATRC} -ne 255 ] ; then
        NO_ZONE_CONFIG_CHECKS=${THATRC}
      else
        LogError "Invalid value for \"${KEYNAME}\" found: \"${KEYVALUE}\""
        THISRC=5
      fi    
	  ;;
     
    "zone_config_only" | "only_configure_zone" )
      CheckYNParameter "${KEYVALUE}"
      THATRC=$?
      if [ ${THATRC} -ne 255 ] ; then
        ZONE_CONFIG_ONLY=${THATRC}
      else
        LogError "Invalid value for \"${KEYNAME}\" found: \"${KEYVALUE}\""
        THISRC=5
      fi    
	  ;;
	  
    "zone_device" )
      ZONE_DEVICES="${ZONE_DEVICES} 
${KEYVALUE}"
      ;;

    "zone_set_global_option" )
        ZONE_SET_GLOBAL_OPTIONS="${ZONE_SET_GLOBAL_OPTIONS}
${KEYVALUE}"
        ;;
  
    "zone_global_option" )
        ZONE_GLOBAL_OPTIONS="${ZONE_GLOBAL_OPTIONS}
${KEYVALUE}"
        ;;

    "zone_hostid" )
        ZONE_HOSTID="${KEYVALUE}"
        ;;

    "zone_dataset" )
        ZONE_DATASETS="${ZONE_DATASETS} ${KEYVALUE}"
        ;;

    "zone_default_router" )
        ZONE_DEFAULT_ROUTER=${KEYVALUE}
        ;;
  
    "zone_gldv3_check" )
       ZONE_GLDV3_CHECK=${KEYVALUE}
       [ "${ZONE_GLDV3_CHECK}"x != "no"x ]  && ZONE_GLDV3_CHECK="yes"
       ;;
       
    "zone_memory_limit" )
       ZONE_MEMORY_LIMIT=${KEYVALUE} 
       ;;
       
    "zone_swap_limit" )
       ZONE_SWAP_LIMIT=${KEYVALUE} 
       ;;
    
    "zone_cpu_count" )
       ZONE_CPU_COUNT=${KEYVALUE} 
       ;;

    "zone_capped_cpu_count" )
       ZONE_CAPPED_CPU_COUNT=${KEYVALUE} 
       ;;

    "zone_brand" )
       [ "${KEYVALUE}"x = "none"x -o "${KEYVALUE}"x = "default"x ] && ZONE_BRAND="" || ZONE_BRAND=${KEYVALUE}
       ;;
           
    "zone_cpu_shares" )
       ZONE_CPU_SHARES=${KEYVALUE}
       ;;
       
    "zone_mode" )
      ZONE_MODE="${KEYVALUE:-${DEFAULT_ZONE_MODE}}"
      case ${ZONE_MODE} in
        small | sparse | SPARSE | default ) 
          ZONE_MODE="small" ;;
  
        big | whole_root | WHOLE_ROOT | whole | WHOLE ) 
        ZONE_MODE="big" ;;

        * )
          LogError "Invalid value for zone_mode found: \"${KEYVALUE}\" "
          THISRC=5
          ;;
      esac
      ;;

    "zone_path" | "zonepath" )
      ZONE_PATH="${KEYVALUE:-${DEFAULT_ZONE_PATH}}"
      ;;

    "zone_path_absolute" | "absolute_zonepath" )
      ZONE_PATH_ABSOLUTE="${KEYVALUE:-${DEFAULT_ZONE_PATH_ABSOLUTE}}"
      ;;

    "zone_flashimage" )
      ZONE_FLASHIMAGE="${KEYVALUE:-${DEFAULT_ZONE_FLASHIMAGE}}"
      ;;
      
    "zone_name" | "zonename" )
      ZONE_NAME="${KEYVALUE:-${ZONE_NAME}}"
      ;;

    "zone_ip_address" | "address" )
      ZONE_IP_ADDRESS="${KEYVALUE:-${DEFAULT_ZONE_IP_ADDRESS}}"
      ;;

    "zone_ip_stack" )
      case ${KEYVALUE} in
             
        shared | SHARED | default | share ) 
          ZONE_IP_STACK="SHARED" 
          ;;
          
        exclusive | EXCLUSIVE | excl ) 
          ZONE_IP_STACK="EXCLUSIVE" 
          ;;
          
        * )  
          LogError "Invalid value for zone_ip_stack found: \"${KEYVALUE}\" "
          THISRC=5
          ;;
      esac
      ;;
      
    "zone_network_interface" | "physical" )
      ZONE_NETWORK_INTERFACE="${KEYVALUE:-${DEFAULT_ZONE_NETWORK_INTERFACE}}"
      ;;

    "zone_add_network_interface" )
      ZONE_ADD_NETWORK_INTERFACE="${ZONE_ADD_NETWORK_INTERFACE} ${KEYVALUE}"
	  ;;
	  
    "zone_root_password" )
      if [ "${KEYVALUE}"x = "none"x ] ; then
        ZONE_ROOT_PASSWORD=""
      else
        ZONE_ROOT_PASSWORD="${KEYVALUE:-${DEFAULT_ZONE_ROOT_PASSWORD}}"
      fi
      ;;
      
    "zone_tz" | "zone_timezone" )
      ZONE_TZ="${KEYVALUE:-${DEFAULT_ZONE_TZ}}"
      ;;
      
    "zone_locale" )
      ZONE_LOCALE="${KEYVALUE:-${DEFAULT_ZONE_LOCALE}}"
      ;;

    "zone_terminal" ) 
      ZONE_TERMINAL="${KEYVALUE:-${DEFAULT_ZONE_TERMINAL}}"
      ;;

    "zone_timeserver" ) 
      ZONE_TIMESERVER="${KEYVALUE:-${DEFAULT_ZONE_TIMESERVER}}"
      ;;
      
    "zone_finish_script" )
      ZONE_FINISH_SCRIPT="${KEYVALUE:-${DEFAULT_ZONE_FINISH_SCRIPT}}"
      ;;

    "zone_customize_script_source" )
      ZONE_CUSTOMIZE_SCRIPT_SOURCE="${KEYVALUE:-${DEFAULT_ZONE_CUSTOMIZE_SCRIPT_SOURCE}}"
      ;;
      
    "zone_customize_script_target" )
      ZONE_CUSTOMIZE_SCRIPT_TARGET="${KEYVALUE:-${DEFAULT_ZONE_CUSTOMIZE_SCRIPT_TARGET}}"
      ;;

    "free_space_for_the_zone" | "freespace" )
      FREE_SPACE_FOR_THE_ZONE="${KEYVALUE:-${DEFAULT_FREE_SPACE_FOR_THE_ZONE}}"
      ;;
      
    "zone_autoboot" | "autoboot" )
      CheckYNParameter "${KEYVALUE}"
      THATRC=$?
      if [ ${THATRC} -ne 255 ] ; then
        ZONE_AUTOBOOT=${THATRC}
      else
        LogError "Invalid value for \"${KEYNAME}\" found: \"${KEYVALUE}\""
        THISRC=5
      fi
      ;;
      
    "boot_the_zone_now" )
      CheckYNParameter "${KEYVALUE}"
      THATRC=$?
      if [ ${THATRC} -ne 255 ] ; then
        BOOT_THE_ZONE_NOW=${THATRC}
      else
        LogError "Invalid value for \"${KEYNAME}\" found: \"${KEYVALUE}\""
        THISRC=5
      fi
      ;;

    "use_existing_nameserver_config" )
      CheckYNParameter "${KEYVALUE}"
      THATRC=$?
      if [ ${THATRC} -ne 255 ] ; then
        USE_EXISTING_NAMESERVER_CONFIG=${THATRC}
      else
        LogError "Invalid value for \"${KEYNAME}\" found: \"${KEYVALUE}\""
        THISRC=5
      fi
      ;;

    "zone_profile" )
       ZONE_SMF_PROFILE="${KEYVALUE:-${DEFAULT_ZONE_SMF_PROFILE}}"      
       ;;
      
    "zone_readonly_dir" | "readonly_dir" )
      ZONE_READONLY_DIRS="${ZONE_READONLY_DIRS} ${KEYVALUE}"
      ;;

    "zone_copy_file" | "copy_file" )
      ZONE_FILES_TO_COPY="${ZONE_FILES_TO_COPY} ${KEYVALUE}"
      ;;

    "zone_inherited_dir" | "inherited_dir" )
      ZONE_INHERITED_DIRS="${ZONE_INHERITED_DIRS} ${KEYVALUE}"
      ;;
      
    "zone_writable_dir" | "writable_dir" )
      ZONE_WRITABLE_DIRS="${ZONE_WRITABLE_DIRS} ${KEYVALUE}"
      ;;

    "zone_clone_source" )
      ZONE_CLONE_SOURCE="${KEYVALUE}"
      ;;

    "zone_template_dir" )
      ZONE_TEMPLATE_DIRS="${ZONE_TEMPLATE_DIRS} ${KEYVALUE}"
      ;;

    "zone_netmask" )
      ZONE_NETMASK="${KEYVALUE}"
       ;;
       
    * )
      LogError "Invalid Parameter found: \"${THIS_PARM}\" "
      THISRC=5
      ;;

  esac

  return ${THISRC}
}

## --------------------------------------
## calc_netmask_size
##
## description  calculate the network size from the netmask
##
## usage: calc_netmask_size netmask
##
## returns: the size of the network
##
calc_netmask_size() {
  typeset __FUNCTION="calc_netmask_size";   ${__FUNCTION_INIT} ;    ${__DEBUG_CODE}
  
  typeset NETMASK="$1"
  typeset -i2 BINVAR=0
  typeset LOCALVAR=""
  typeset THISRC=0
  typeset i=0

  set -- $( echo ${NETMASK} | tr "." " " )
  i=0
  while [ $# -ne 0 ] ; do
    BINVAR="$1"
    LOCALVAR="${LOCALVAR}${BINVAR##*#}"
    shift
  done
  LOCALVAR=$( echo ${LOCALVAR} | tr -d "0" )
  THISRC=${#LOCALVAR}

  return ${THISRC}
}

## --------------------------------------
## zone_config_error
##
## description  handle an error in the zone configuration
##
## usage: zone_config_error return_code message
##
## returns: returns only if ${NO_ZONE_CONFIG_CHECKS} is ${__TRUE} 
##          if not the script is aborted
##
zone_config_error() {
  typeset __FUNCTION="zone_config_error";   ${__FUNCTION_INIT} ;    ${__DEBUG_CODE}
  
  typeset THISRC=$1
  shift
  typeset THISMSG="$*"
  
  if [ ${NO_ZONE_CONFIG_CHECKS} = ${__TRUE} ] ; then
    LogError "${THISMSG}"
  else
    die ${THISRC} "${THISMSG}"
  fi
  
  return 0
}	

## --------------------------------------
## is_zfs_file_system 
##
## description  check if a directory is mounted on a ZFS filesystem
##
## usage: is_zfs_file_system directory
##
## returns: ${__TRUE} - the directory is mounted on a ZFS filesystem
##          ${__FALSE} - the directory is NOT mounted on a ZFS filesystem
##
is_zfs_file_system() {
  typeset __FUNCTION="is_zfs_file_system";   ${__FUNCTION_INIT} ;   ${__DEBUG_CODE}
  
  typeset THISRC=${__FALSE}
  typeset THIS_DIR="$1"
  if [ "${THIS_DIR}"x != ""x ] ; then
    [ "$( echo "${THIS_DIR}" | cut -c1 )"x != "/"x ] && THISRC=${__TRUE}

# this only works if the ZPOOL is imported
#    zfs list | egrep  " ${THIS_DIR}\$"  2>/dev/null >/dev/nul && THISRC=${__TRUE}

  fi
   
  return ${THISRC}
}  

# -----------------------------------------------------------------------------
# main:
#
  
# trace main routine (for debugging only!)
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

  InitScript

# make sure the PATH is okay
#
  export PATH="$PATH:/usr/bin:/usr/sbin"

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

# add additional switch characters here
#
  [ "${__OS}"x = "Linux" ] &&  GETOPT_COMPATIBLE="0"
  __GETOPTS="+:ynvqhHDfl:aOS:CVTbp:i:z:A:x:s:Ied:w:Z:N:t:R:c:BPF"
  if [ "${__OS}"x = "SunOS"x  ] ; then
    if [ "${__OS_VERSION}"x  = "5.10"x -o  "${__OS_VERSION}"x  = "5.11"x ] ; then
      __GETOPTS="+:y(yes)n(no)v(verbose)q(quiet)h(help)H(doc)D(debug)f(force)l:(logfile)a(color)O(overwrite)S:(summaries)C(writeconfigfile)V(version)T(tee)b(big)p:(zone_path)i:(zone_ip_address)z:(zone_name)A:(zone_network_interface)x:(config)s:(free_space)I(zone_ip_stack)e(edit)d:(inherit)w:(writabledir)r:(zone_default_router)Z:(dataset)N:(clone)t:(templatedir)R:(readonlydir)c:(copyfile)B(only_configure_zone)P:(zone_path_absolute)F(no_zone_config_checks)"
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
#     __PRINT_ARGUMENTS=${__TRUE}
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
#            [ ${OPTIND} != 1 ] && LogWarning "The parameter -T must be the first parameter if used"
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

       "B" ) 
	         ZONE_CONFIG_ONLY=${__TRUE}
	         ;;

      "+B" ) 
	         ZONE_CONFIG_ONLY=${__FALSE}
             ;;

       "F" ) 
	         NO_ZONE_CONFIG_CHECKS=${__TRUE}
	         ;;

      "+F" ) 
	         NO_ZONE_CONFIG_CHECKS=${__FALSE}
             ;;
			 
       "b" )
             ZONE_MODE="big"
             ;;

      "+b" )
             ZONE_MODE="small"
             ;;

       "N" )
             ZONE_CLONE_SOURCE="${OPTARG}"
             ;;

      "+N" ) 
             ZONE_CLONE_SOURCE=""
             ;;

       "i" ) 
             ZONE_IP_ADDRESS="${OPTARG}"
             ;;

       "r" )
             ZONE_DEFAULT_ROUTER="${OPTARG}"
             ;;

      "+r" )
             ZONE_DEFAULT_ROUTER=""
             ;;

       "I" ) 
             ZONE_IP_STACK="EXCLUSIVE"
             ;;

      "+I" ) 
             ZONE_IP_STACK="SHARED"
             ;;

       "z" )
             ZONE_NAME="${OPTARG}"
             ;;

       "A" ) 
             ZONE_NETWORK_INTERFACE="${OPTARG}"
             ;;

       "s" )
             FREE_SPACE_FOR_THE_ZONE="${OPTARG}"
             ;;

       "p" )
             ZONE_PATH="${OPTARG}"
             ZONE_PATH_ABSOLUTE=""
             ;;

       "P" )
             ZONE_PATH_ABSOLUTE="${OPTARG}"
             ZONE_PATH=""
             ;;

       "x" )
             ProcessParameter "${OPTARG}"
             [ $? -ne 0 ] && INVALID_PARAMETER_FOUND=${__TRUE}
             ;;


       "e" ) 
             EDIT_ZONE_CONFIG=${__TRUE}
             ;;

      "+e" ) 
             EDIT_ZONE_CONFIG=${__FALSE}
             ;;

       "d" )
             ZONE_INHERITED_DIRS="${ZONE_INHERITED_DIRS} ${OPTARG}"
             ;;

      "+d" )
             [ "${OPTARG}"x = "none"x ] && ZONE_INHERITED_DIRS="" || ZONE_INHERITED_DIRS="${OPTARG}"
             ;;

       "t" )
             ZONE_TEMPLATE_DIRS="${ZONE_TEMPLATE_DIRS} ${OPTARG}"
             ;;

      "+t" )
             [ "${OPTARG}"x = "none"x ] && ZONE_TEMPLATE_DIRS="" || ZONE_TEMPLATE_DIRS="${OPTARG}"
             ;;

       "Z" )
             ZONE_DATASETS="${ZONE_DATASETS} ${OPTARG}"
             ;;

      "+Z" )
             [ "${OPTARG}"x = "none"x ] && ZONE_DATASETS="" || ZONE_DATASETS="${OPTARG}"
             ;;

       "R" )
             ZONE_READONLY_DIRS="${ZONE_READONLY_DIRS} ${OPTARG}"
             ;;

      "+R" )
             [ "${OPTARG}"x = "none"x ] && ZONE_READONLY_DIRS="" || ZONE_READONLY_DIRS="${OPTARG}"
             ;;


       "w" )
             ZONE_WRITABLE_DIRS="${ZONE_WRITABLE_DIRS} ${OPTARG}"
             ;;

      "+w" )
             [ "${OPTARG}"x = "none"x ] && ZONE_WRITABLE_DIRS="" || ZONE_WRITABLE_DIRS="${OPTARG}"
             ;;

       "c" ) 
             ZONE_FILES_TO_COPY="${ZONE_FILES_TO_COPY} ${OPTARG}"
             ;;
            
       "+c" )
             [ "${OPTARG}"x = "none"x ] && ZONE_FILES_TO_COPY="" || ZONE_FILES_TO_COPY="${OPTARG}"
             ;;

       \? )  LogError "Unknown parameter found: \"${OPTARG}\" "
             INVALID_PARAMETER_FOUND=${__TRUE}
             break
             ;;

        * )  LogError "Unknown parameter found: \"${CUR_SWITCH}\""
             INVALID_PARAMETER_FOUND=${__TRUE}
             break 
            ;;

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

  if [ "${NOT_PROCESSED_PARAMETER}"x != ""x ] ; then
    for CUR_PARM in ${NOT_PROCESSED_PARAMETER} ; do
      ProcessParameter "${CUR_PARM}"
      [ $? -ne 0 ] && INVALID_PARAMETER_FOUND=${__TRUE}
    done
  fi

  LogRuntimeInfo "Not processed parameter: \"${NOT_PROCESSED_PARAMETER}\""
  
#
# set INVALID_PARAMETER_FOUND to ${__TRUE} if the script
# should abort due to an invalid parameter 
#
  if [ "${NOT_PROCESSED_PARAMETER}"x != ""x ] ; then
    LogError "Unknown parameter found: \"${NOT_PROCESSED_PARAMETER}\" "
    INVALID_PARAMETER_FOUND=${__TRUE}
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

# set the variable EDITOR if not already set
#
  [ "${EDITOR}"x = ""x ] && EDITOR=vi  
  
# -----------------------------------------------------------------------------
# check the mandatory parameter
#
  LogInfo "Checking for the mandatory zone parameter ..."
    
  [ "${ZONE_NAME}"x = ""x ] && die 5 "The parameter for the name of the zone is missing"
  [ "${ZONE_IP_ADDRESS}"x = ""x ] && die 8 "The parameter for the IP address of the zone is missing"

# -----------------------------------------------------------------------------
#
  LogInfo "Checking some optional parameter ..."
   
  [ "${ZONE_CPU_COUNT}"x != ""x -a "${ZONE_CPU_SHARES}"x != ""x ] && \
    zone_config_error 36 "Use either dedicated CPUs or CPU shares for the zone -- but not both"
 
  [ "${ZONE_FLASHIMAGE}"x != ""x -a "${ZONE_CLONE_SOURCE}"x != ""x ] && \
    zone_config_error 37 "Use either a flashimage or a source zone for the installation -- but not both"

  LogInfo "ZONE_PATH is \"${ZONE_PATH}\" "
  LogInfo "ZONE_PATH_ABSOLUTE is \"${ZONE_PATH_ABSOLUTE}\" "
  
  [ "${ZONE_PATH_ABSOLUTE}"x != ""x -a "${ZONE_PATH}"x != ""x  ] && die 3 "Use either the parameter ZONE_PATH or ZONE_PATH_ABSOLUTE -- but not both" 
  [ "${ZONE_PATH_ABSOLUTE}"x = "/"x ] && die 4 "ZONE_PATH_ABSOLUTE can not be the root directory"

  if [ "${ZONE_PATH_ABSOLUTE}"x != ""x ] ; then 
      ZONE_PATH="$( dirname ${ZONE_PATH_ABSOLUTE} )"
    ZONE_SUBDIR="$( basename ${ZONE_PATH_ABSOLUTE} )"
  else    
    [ ! -d "${ZONE_PATH}" -a ${ZONE_CONFIG_ONLY} != ${__TRUE} ] && die 11 "The directory for the zone \"${ZONE_PATH}\" does not exist"
    ZONE_SUBDIR="${ZONE_NAME}"
    ZONE_PATH_ABSOLUTE="${ZONE_PATH}/${ZONE_SUBDIR}"
  fi

  LogInfo "ZONE_PATH is \"${ZONE_PATH}\" "
  LogInfo "ZONE_SUBDIR is \"${ZONE_SUBDIR}\" "
  LogInfo "ZONE_PATH_ABSOLUTE is \"${ZONE_PATH_ABSOLUTE}\" "
  if [ "${ZONE_BRAND}"x != ""x ] ; then
    if [ ! -f "/etc/zones/${ZONE_BRAND}.xml" ] ; then    
      LogWarning "No XML found in /etc/zones for this brand: \"${ZONE_BRAND}\""
    fi      
  fi
  
# -----------------------------------------------------------------------------
# resolv symbolic links for the ZONE_PATH
#
  if [ ${ZONE_CONFIG_ONLY} != ${__TRUE} ] ; then  
    if [ -d "${ZONE_PATH_ABSOLUTE}" ] ; then
      LogInfo "Converting the zone path \"${ZONE_PATH_ABSOLUTE}\" to an absolute name ..."  

      cd "${ZONE_PATH_ABSOLUTE}" 
      THIS_ZONE_PATH="$( pwd -P )"
      cd - >/dev/null
      LogInfo "  ... the zone path is now \"${ZONE_PATH_ABSOLUTE}\" "
    else 
      LogInfo "The target path for the zone \"${ZONE_PATH_ABSOLUTE}\" does not exist"
      THIS_ZONE_PATH="${ZONE_PATH_ABSOLUTE}"
    fi
  else
    THIS_ZONE_PATH="${ZONE_PATH_ABSOLUTE}"      
  fi

# -----------------------------------------------------------------------------
# set defaults for the missing values
#
  LogInfo "Setting the missing optional zone parameter using default values ..."
  if [ "${FREE_SPACE_FOR_THE_ZONE}"x = ""x ] ; then
    if [ "${ZONE_MODE}"x = "small"x ] ; then
      FREE_SPACE_FOR_THE_ZONE="${DEFAULT_FREE_SPACE_FOR_A_SMALL_ZONE}"
    else
      FREE_SPACE_FOR_THE_ZONE="${DEFAULT_FREE_SPACE_FOR_A_BIG_ZONE}"
    fi   
    LogInfo "Setting the free space needed for the zone to ${FREE_SPACE_FOR_THE_ZONE}."
  fi

  LogInfo "Getting the netmask for the zone ..."
  ZONE_IP_NETMASK="${ZONE_IP_ADDRESS#*/}"
  ZONE_IP_ADDRESS="${ZONE_IP_ADDRESS%/*}" 
  if [ "${ZONE_IP_NETMASK}"x != ""x ] ; then
    if  [ "${ZONE_IP_NETMASK}"x != "${ZONE_IP_ADDRESS}"x ] ; then
      ZONE_IP_NETMASK="/${ZONE_IP_NETMASK}"  
    else
      if [ "${ZONE_NETMASK}"x != ""x ] ; then
        calc_netmask_size "${ZONE_NETMASK}"
        ZONE_IP_NETMASK=/$?
      else
        ZONE_IP_NETMASK=""
      fi
    fi
  fi
  LogInfo "   ... the netmask for the zone is \"${ZONE_IP_NETMASK}\". "
  
  LogInfo "Setting the network interface for the zone ..."
  if [ "${ZONE_NETWORK_INTERFACE}"x = ""x ] ; then
    if [ "${ZONE_IP_STACK}"x = "EXCLUSIVE"x ] ; then
      zone_config_error 12 "You must specifiy a network interface (-A) if creating a zone with exclusive IP stack (-I)"
    else
      typeset ZONE_NETWORK_INTERFACE="$(route -n get ${ZONE_IP_ADDRESS} | grep interface | tr -d " " | cut -f2 -d ":" )"
      [ "${ZONE_NETWORK_INTERFACE}"x = ""x ] && \
        zone_config_error 15 "Can not detect the interface for the zone (use -A to specify the interface)"
    fi
	LogInfo "  ... the network interface for the zone is \"${ZONE_NETWORK_INTERFACE}\". "
  fi
   
  LogInfo "Retrieving the status of the new zone ..."  
  CUR_ZONE_STATUS="$( zoneadm -z ${ZONE_NAME} list -p 2>/dev/null | cut -f3 -d":"  )"
  
# -----------------------------------------------------------------------------
# print the configuration for the zone
#
  LogMsg "-"
  LogMsg "Creating the zone \"${ZONE_NAME}\""

  if [ "${ZONE_BRAND}"x != ""x ] ; then
    LogMsg "The brand for the zone is \"${ZONE_BRAND}\""
  fi

  [ "${ZONE_CLONE_SOURCE}"x != ""x ] && \
     LogMsg "The zone will be created by cloning the zone \"${ZONE_CLONE_SOURCE}\" "   

  [ "${ZONE_FLASHIMAGE}"x != ""x ] && \
    LogMsg "The zone will be installed using the flash image \"${ZONE_FLASHIMAGE}\" "

  LogMsg "The path for the zone is \"${THIS_ZONE_PATH}\" "
  LogMsg "The mode for the zone is \"${ZONE_MODE}\" "
	 
  [ "${ZONE_MEMORY_LIMIT}"x != ""x ] && \
    LogMsg "The memory limit for the zone is \"${ZONE_MEMORY_LIMIT}\" " || \
    LogMsg "No memory limit configured for the zone"
  [ "${ZONE_SWAP_LIMIT}"x != ""x ] && \
    LogMsg "The swap limit for the zone is \"${ZONE_SWAP_LIMIT}\" "  || \
    LogMsg "No swap limit configured for the zone"
  [ "${ZONE_CPU_COUNT}"x != ""x ] && \
    LogMsg "The number of CPUs for the zone is \"${ZONE_CPU_COUNT}\" "  || \
    LogMsg "No dedicated cpus configured for the zone"
  [ "${ZONE_CAPPED_CPU_COUNT}"x != ""x ] && \
    LogMsg "The max. number of CPUs for the zone is \"${ZONE_CAPPED_CPU_COUNT}\" "  || \
    LogMsg "No maximum cpus configured for the zone"    
  [ "${ZONE_CPU_SHARES}"x != ""x ] && \
    LogMsg "The number of CPU shares for the zone is \"${ZONE_CPU_SHARES}\" "  || \
    LogMsg "No CPU shares configured for the zone"
 
  if [ "${ZONE_INHERITED_DIRS}"x != ""x ] ; then
    LogMsg "Additional directories inherited by the zone are:"
    for CURDIR in ${ZONE_INHERITED_DIRS} ; do
      LogMsg "    ${CURDIR}"
    done
  else
    LogMsg "No additional directories to be inherited by the zone"
  fi
  
  if [ "${ZONE_READONLY_DIRS}"x != ""x ] ; then
    LogMsg "Readonly directories in the zone are:"
    for CUR_ENTRY in ${ZONE_READONLY_DIRS} ; do
      READONLY_GLOBAL_DIR="${CUR_ENTRY#*:}" 
      READONLY_ZONE_DIR="${CUR_ENTRY%:*}"
      LogMsg "    (zone) ${READONLY_ZONE_DIR} = (global) ${READONLY_GLOBAL_DIR}"
    done
  fi

  if [ "${ZONE_WRITABLE_DIRS}"x != ""x ] ; then
    LogMsg "Writable directories in the zone are:"
    for CUR_ENTRY in ${ZONE_WRITABLE_DIRS} ; do
      WRITABLE_GLOBAL_DIR="${CUR_ENTRY#*:}" 
      WRITABLE_ZONE_DIR="${CUR_ENTRY%:*}"
      LogMsg "    (zone) ${WRITABLE_ZONE_DIR} = (global) ${WRITABLE_GLOBAL_DIR}"
    done
  fi

  if [ "${ZONE_DATASETS}"x != ""x ] ; then
    LogMsg "ZFS datasets for the zone are:"
    for CUR_ENTRY in ${ZONE_DATASETS} ; do
      LogMsg "    ${CUR_ENTRY}"
    done
  fi

  LogMsg "Check the GLDv3 driver: \"${ZONE_GLDV3_CHECK}\" "
  LogMsg "The zone uses the network interface \"${ZONE_NETWORK_INTERFACE}\""
  LogMsg "The zone uses the \"${ZONE_IP_STACK}\" IP stack"
  LogMsg "The IP address of the zone is \"${ZONE_IP_ADDRESS}${ZONE_IP_NETMASK}\""
  
  if [ "${ZONE_IP_STACK}"x = "EXCLUSIVE"x ] ; then
    if [ "${ZONE_NETMASK}"x != ""x ] ; then
      LogMsg "The netmask for the zone is \"${ZONE_NETMASK}\""
    else
      LogMsg "WARNING: The netmask for the zone is NOT set (use -x zone_netmask=netmask)!"
    fi
  fi

  if [ "${ZONE_DEFAULT_ROUTER}"x != ""x -a "${ZONE_DEFAULT_ROUTER}"x != "none"x ] ; then
    LogMsg "The default router for the zone is \"${ZONE_DEFAULT_ROUTER}\" "
  else
    LogMsg "No default router configured for the zone."
  fi
  
  if [ "${ZONE_ADD_NETWORK_INTERFACE}"x != ""x ] ; then
    LogMsg "Additional network interfaces for the zone: "
	for CURENTRY in ${ZONE_ADD_NETWORK_INTERFACE} ; do
	  CUR_IF="${CURENTRY%%:*}"
	  CUR_ROUTER="${CURENTRY##*:}"
	  DUMMY=${CURENTRY%:*} ; CUR_IP="${DUMMY#*:}"

#	  CUR_IF="$( echo ${CURENTRY} | cut -f1 -d ":" )"
#	  CUR_IP="$( echo ${CURENTRY} | cut -f2 -d ":" )"
#	  CUR_ROUTER="$( echo ${CURENTRY} | cut -f3 -d ":" )"

	  LogMsg "  Interface: ${CUR_IF}, IP: ${CUR_IP}, DefRouter: ${CUR_ROUTER}"
	done
  fi
  
  LogMsg "The locale for the zone is \"${ZONE_LOCALE}\" "
  LogMsg "The timezone for the zone is \"${ZONE_TZ}\" "
  LogMsg "The encrypted root password for the zone is \"${ZONE_ROOT_PASSWORD}\""
  LogMsg "The terminal type for the zone is \"${ZONE_TERMINAL}\""
  LogMsg "The timeserver for the zone is \"${ZONE_TIMESERVER}\""
  LogMsg "The finish script for the zone is \"${ZONE_FINISH_SCRIPT}\""
  LogMsg "The customize script for the zone is \"${ZONE_CUSTOMIZE_SCRIPT_SOURCE}\" "
  LogMsg "The customize script inside the zone is \"${ZONE_CUSTOMIZE_SCRIPT_TARGET}\""
  LogMsg "The SMF profile for the zone is \"${ZONE_SMF_PROFILE}\""
  
  if [ "${ZONE_TEMPLATE_DIRS}"x != ""x ] ; then
    LogMsg "The zone template directories are:"
    for CUR_ENTRY in ${ZONE_TEMPLATE_DIRS} ; do
      LogMsg  "    ${CUR_ENTRY}"
    done
  fi

  if [ "${ZONE_FILES_TO_COPY}"x != ""x ] ; then
    LogMsg "The files to copy to the zone are:"
    for CUR_ENTRY in ${ZONE_FILES_TO_COPY} ; do
      LogMsg  "    ${CUR_ENTRY}"
    done
  fi

  LogMsg "Use the existing name server configuration: $( ConvertToYesNo ${USE_EXISTING_NAMESERVER_CONFIG} )"
  LogMsg "Set autoboot to enable for the zone: $( ConvertToYesNo ${ZONE_AUTOBOOT} )"
  LogMsg "Boot the zone after installation: $( ConvertToYesNo ${BOOT_THE_ZONE_NOW} )"
  LogMsg "Free space in KB necessary for creating the zone is: ${FREE_SPACE_FOR_THE_ZONE}"

  if [ "${ZONE_DEVICES}"x != ""x ] ; then
    LogMsg "Devices for the zone:"
    LogMsg "-" "${ZONE_DEVICES}"
  fi

  if [ "${ZONE_GLOBAL_OPTIONS}"x != ""x ] ; then
    LogMsg "The add. global options for the zone are:"
    LogMsg "-" "${ZONE_GLOBAL_OPTIONS}"
  fi

  if [ "${ZONE_SET_GLOBAL_OPTIONS}"x != ""x ] ; then
    LogMsg "The add. global set options for the zone are:"
    LogMsg "-" "${ZONE_SET_GLOBAL_OPTIONS}"
  fi

  if [ "${ZONE_HOSTID}"x != ""x ] ; then
    LogMsg "The hostid for the zone is: ${ZONE_HOSTID}"
  fi

  if [ ${ZONE_CONFIG_ONLY} = ${__TRUE} ] ; then
    LogMsg ""
    LogMsg "The zone will only be configured but NOT installed."
  fi
    
  LogMsg ""
  LogMsg "Edit the zone config before creating the zone: $( ConvertToYesNo ${EDIT_ZONE_CONFIG} )"
  if [ ${EDIT_ZONE_CONFIG} = ${__TRUE} ] ; then
    LogMsg "  The editor to use is \"${EDITOR}\" "
  fi
  
  LogMsg "-"
  if  [ "${CUR_ZONE_STATUS}"x != ""x ] ; then
    LogWarning "The zone \"${ZONE_NAME}\" already exists; the status is \"${CUR_ZONE_STATUS}\" "
    LogMsg "-"
    USER_PROMPT="Recreate the zone (y/N)? "  
  else
    USER_PROMPT="Create the zone (y/N)? "    
  fi

  AskUser "${USER_PROMPT}"  
  [ $? -ne ${__TRUE} ] && die 14 "Script aborted by the user"

# -----------------------------------------------------------------------------
# check the zone configuraton
#
  LogMsg "Checking the zone configuration ..."

  ZONE_EXISTS=${__FALSE}
  ZONE_PATH_EXISTS=${__FALSE}

  ZONE_CONFIGURATION_OK=${__TRUE}  

# check if the zone is configured
#
  if [ "${CUR_ZONE_STATUS}"x !=  ""x ] ; then
    ZONE_EXISTS=${__TRUE}
    if [ ${__OVERWRITE_MODE} = ${__FALSE} ] ; then
      LogError "The zone \"${ZONE_NAME}\" already exists (use the parameter -O to delete and recreate the zone)"
      ZONE_CONFIGURATION_OK=${__FALSE}
    fi
  fi

# ----------------------------------------------------------------------------- 
# check if the zone is running
#
  if [ "${CUR_ZONE_STATUS}"x = "running"x -a ${ZONE_CONFIG_ONLY} != ${__TRUE} ] ; then
    ZONE_EXISTS=${__TRUE}
    LogError "The zone \"${ZONE_NAME}\" is running - please stop the zone manually before calling this script"
    LogError "and either delete the zone manually or use the parameter -O to delete and recreate the zone."
    ZONE_CONFIGURATION_OK=${__FALSE}
  fi

# ----------------------------------------------------------------------------- 
# check if the zone to clone exists and is not running
#
  if [ "${ZONE_CLONE_SOURCE}"x != ""x -a ${ZONE_CONFIG_ONLY} != ${__TRUE} ] ; then
    LogInfo "Checking the source zone for cloning ..."
    CLONE_SOURCE_STATUS="$( zoneadm -z ${ZONE_CLONE_SOURCE} list -p  | cut -f3 -d ":" )"
    if [ "${CLONE_SOURCE_STATUS}"x = ""x ] ; then
      LogError "The zone to clone \"${ZONE_CLONE_SOURCE}\" does not exist"
      ZONE_CONFIGURATION_OK=${__FALSE}
    fi
    if [ "${CLONE_SOURCE_STATUS}"x != "installed"x ] ; then
      LogError "The zone to clone \"${ZONE_CLONE_SOURCE}\" is in the wrong status (\"${CLONE_SOURCE_STATUS}\")"
      LogError "The zone to clone must have the status \"installed\"."
      ZONE_CONFIGURATION_OK=${__FALSE}
    fi
  fi

# -----------------------------------------------------------------------------
# check the flash image for the zone
#
  if [ "${ZONE_FLASHIMAGE}"x != ""x -a ${ZONE_CONFIG_ONLY} != ${__TRUE} ] ; then
    LogInfo "Checking the flash image for the zone ..."
    if [ ! -r "${ZONE_FLASHIMAGE}" ] ; then
      LogError "The flash image \"${ZONE_FLASHIMAGE}\" does not exist."
      ZONE_CONFIGURATION_OK=${__FALSE}
    fi
  fi
  
# -----------------------------------------------------------------------------
# check if the directory for the zone already exists
#    
  if [ ${ZONE_CONFIG_ONLY} != ${__TRUE} ] ; then 
    LogInfo "Checking the zone path ..."
    if [ -d "${THIS_ZONE_PATH}" ] ; then
      ZONE_PATH_EXISTS=${__TRUE}
    
      if [ ${__OVERWRITE_MODE} = ${__FALSE} -a "$( ls "${THIS_ZONE_PATH}" )"x != ""x ] ; then
        LogError "The directory \"${THIS_ZONE_PATH}\" already exists and is not empty (use the parameter -O to delete and recreate the directory)"
        ZONE_CONFIGURATION_OK=${__FALSE}
      else
        DIR_MODE="$( ls -ld "${THIS_ZONE_PATH}" | cut -f1 -d " ")"
        if [ "${DIR_MODE}"x != "drwx------"x ] ; then
          LogMsg "The mode of the directory \"${THIS_ZONE_PATH}\" is \"${DIR_MODE}\" -- changing it to 700 now..."
          chmod 700 "${THIS_ZONE_PATH}"
          if [ $? -ne 0 ] ; then
            LogError "Can not change the mode of the directory \"${THIS_ZONE_PATH}\" to 700"
            ZONE_CONFIGURATION_OK=${__FALSE}
          fi
        fi
        DIR_MODE="$( ls -ld "${THIS_ZONE_PATH}" | cut -f1 -d " ")"
        if [ "${DIR_MODE}"x != "drwx------"x ] ; then
          LogError "The mode of the directory \"${THIS_ZONE_PATH}\" (${DIR_MODE}) is not valid for zones (the mode should be 700)"
          ZONE_CONFIGURATION_OK=${__FALSE}
        fi
      fi
    fi
  fi

# ----------------------------------------------------------------------------- 
# check if the additional directories to inherit exist
#
  if [ ${ZONE_CONFIG_ONLY} != ${__TRUE} ] ; then
    LogInfo "Checking the directories to inherit to the zone ..."
    for CURDIR in ${ZONE_INHERITED_DIRS} ; do
      if [ ! -d "${CURDIR}" ] ; then
        LogError "The directory to inherit \"${CURDIR}\" does not exist"
        ZONE_CONFIGURATION_OK=${__FALSE}
      fi
    done
  fi
  
# ----------------------------------------------------------------------------- 
 # check if the directory names are all valid
 #
  if [ ${ZONE_CONFIG_ONLY} != ${__TRUE} ] ; then
    LogInfo "Checking the directory names ..."
    for CURDIR in ${ZONE_INHERITED_DIRS} ; do
      if [ "$( echo "${CURDIR}" | cut -c1 )"x != "/"x ] ; then
        LogError "The directory to inherit \"${CURDIR}\" is NOT an absolute path"
        ZONE_CONFIGURATION_OK=${__FALSE}
      fi
    done
    
    for CUR_ENTRY in ${ZONE_READONLY_DIRS} ${ZONE_WRITABLE_DIRS} ; do
      THIS_ZONE_DIR="${CUR_ENTRY%:*}" 
      THIS_GLOBAL_DIR="${CUR_ENTRY#*:}"
	
      if [ "$( echo "${THIS_GLOBAL_DIR}"x | cut -c1 )"x != "/x" ] ; then
        LogInfo "\"${THIS_GLOBAL_DIR}\" is not an absolute path - checking if it's a ZFS filesystem ..."
        is_zfs_file_system "${THIS_GLOBAL_DIR}"
        if [ $? -ne ${__TRUE} ] ; then
          LogError "The global directory \"${THIS_GLOBAL_DIR}\" is NOT an absolute path nor a ZFS filesystem"
          ZONE_CONFIGURATION_OK=${__FALSE}
        else
          LogInfo "\"${THIS_GLOBAL_DIR}\" is a ZFS filesystem."
          ZFS_FS_MOUNTPOINT="$( zfs get -o value  -H mountpoint "${THIS_GLOBAL_DIR}" )"
          if [ "${ZFS_FS_MOUNTPOINT}"x != "legacy"x ] ; then
            LogError "The mountpoint for the ZFS filesystem \"${THIS_GLOBAL_DIR}\" is not legacy"
            ZONE_CONFIGURATION_OK=${__FALSE}
          else
            THIS_MOUNTPOOINT="$( df -h | grep "^${THIS_GLOBAL_DIR} | awk '{ print $6 }'" 2>/dev/null >/dev/null )"
            if [ "${THIS_MOUNTPOOINT}"x != ""x ] ; then
              LogError "The ZFS filesystem \"${THIS_GLOBAL_DIR}\" is already mounted to \"${THIS_MOUNTPOOINT}\""
              ZONE_CONFIGURATION_OK=${__FALSE}          
            fi
          fi        
        fi
      fi
        
      if [ "$( echo "${THIS_ZONE_DIR}" | cut -c1 )"x != "/x" ] ; then
        LogError "The zone directory \"${THIS_ZONE_DIR}\" is NOT an absolute path"
        ZONE_CONFIGURATION_OK=${__FALSE}
      fi
    done
  fi
  
# ----------------------------------------------------------------------------- 
# check if the site profile for the zone exists 
#
  if [ "${ZONE_SMF_PROFILE}"x != ""x -a "${ZONE_SMF_PROFILE}"x != "none"x -a ${ZONE_CONFIG_ONLY} != ${__TRUE} ] ; then
    LogInfo "Checking the SMF profile ..."
    if [ ! -f "${ZONE_SMF_PROFILE}" ] ; then
      LogError "The profile \"${ZONE_SMF_PROFILE}\" does not exist"
      ZONE_CONFIGURATION_OK=${__FALSE}
    fi
  fi

# ----------------------------------------------------------------------------- 
# check if the finish script for the zone exists (if any)
#
  if [ ${ZONE_CONFIG_ONLY} != ${__TRUE} -a ${ZONE_CONFIG_ONLY} != ${__TRUE} ] ; then
    LogInfo "Checking the finish script for the zone ..."
    if [ "${ZONE_FINISH_SCRIPT}"x != ""x -a "${ZONE_FINISH_SCRIPT}"x != "none"x ] ; then
      if [ ! -x "${ZONE_FINISH_SCRIPT}" ] ; then
        LogError "The finish script \"${ZONE_FINISH_SCRIPT}\" does not exist or is not executable"
        ZONE_CONFIGURATION_OK=${__FALSE}
      fi
    fi
  fi

# ----------------------------------------------------------------------------- 
# check if the customize script for the zone exists (if any)
#
  if [ ${ZONE_CONFIG_ONLY} != ${__TRUE} -a ${ZONE_CONFIG_ONLY} != ${__TRUE} ] ; then
    LogInfo "Checking the customization script for the zone ..."
    if [ "${ZONE_CUSTOMIZE_SCRIPT_SOURCE}"x != ""x -a  \
         "${ZONE_CUSTOMIZE_SCRIPT_SOURCE}"x != "builtin"x -a \
         "${ZONE_CUSTOMIZE_SCRIPT_SOURCE}"x != "none"x ] ; then
      if [ ! -f "${ZONE_CUSTOMIZE_SCRIPT_SOURCE}" ] ; then
        LogError "The customize script \"${ZONE_CUSTOMIZE_SCRIPT_SOURCE}\" does not exist"
        ZONE_CONFIGURATION_OK=${__FALSE}
      else
        ZONE_CUSTOMIZE_SCRIPT_CONTENTS="$( cat "${ZONE_CUSTOMIZE_SCRIPT_SOURCE}" )"
        [ $? -ne 0 ] && die 17 "Error reading the customize script for the zone \"${ZONE_CUSTOMIZE_SCRIPT_SOURCE}\" " 
      fi
    fi
  fi

# ----------------------------------------------------------------------------- 
# check the network configuration for the zone
#
  LogInfo "Checking the network configuration for the zone ..."
  if [ "${ZONE_IP_STACK}"x = "EXCLUSIVE"x ] ; then

# ----------------------------------------------------------------------------- 
# EXCLUSIVE IP STACK used

# ----------------------------------------------------------------------------- 
# check the status and the type of the network adapter (using old and new dladm syntax)
#
    NETWORK_ADAPTER_TYPE="$( get_network_adapter_type "${ZONE_NETWORK_INTERFACE}" )"
    if [ "${NETWORK_ADAPTER_TYPE}"x = ""x ] ; then
      LogError "Network interface \"${ZONE_NETWORK_INTERFACE}\" not found"
      ZONE_CONFIGURATION_OK=${__FALSE}
    elif [ "${NETWORK_ADAPTER_TYPE}"x = "type=legacy"x  -a  "${ZONE_GLDV3_CHECK}"x != "no"x  ] ; then
      if [ "${ZONE_NETWORK_INTERFACE%%[0-9]*}"x = "ce"x ] ; then

# check for special patches for the ce adapter
#
        CE_PATCHES_INSTALLED=${__TRUE}
   
        case ${__MACHINE_ARC} in 

          "sparc" )
            rev="$( showrev -p | grep "Patch: 137042" | cut -f 2 -d " " | cut -f2 -d "-" | tail -1 )"
            [ 0${rev} -lt 01  ] &&  CE_PATCHES_INSTALLED=${__FALSE}

            rev="$( showrev -p | grep "Patch: 118777" | cut -f 2 -d " " | cut -f2 -d "-" | tail -1 )"
            [ 0${rev} -lt 12  ] &&  CE_PATCHES_INSTALLED=${__FALSE}
            ;;

          "i386" )
            rev="$( showrev -p | grep "Patch: 137043" | cut -f 2 -d " " | cut -f2 -d "-" )"
            [ 0${rev} -lt 01  ] &&  CE_PATCHES_INSTALLED=${__FALSE}

            rev="$( showrev -p | grep "Patch: 118778" | cut -f 2 -d " " | cut -f2 -d "-" )"
            [ 0${rev} -lt 11  ] &&  CE_PATCHES_INSTALLED=${__FALSE}
            ;;

          * )
            CE_PATCHES_INSTALLED=${__FALSE}
            ;;
        esac
      else
        CE_PATCHES_INSTALLED=${__FALSE}
      fi
          
      if [ ${CE_PATCHES_INSTALLED} = ${__FALSE} ] ;then
        LogError "The network interface \"${ZONE_NETWORK_INTERFACE}\" does not support zones with an exclusive IP stack"
        ZONE_CONFIGURATION_OK=${__FALSE}       
      fi
    fi
    
    ifconfig "${ZONE_NETWORK_INTERFACE}" 1>/dev/null 2>/dev/null
    if [ $? -eq 0 ] ; then
      LogError "The network interface \"${ZONE_NETWORK_INTERFACE}\" is used in the global zone"
      ZONE_CONFIGURATION_OK=${__FALSE}
    fi
  else

# ----------------------------------------------------------------------------- 
# SHARED IP STACK used

# check if the network interface for the zone exists
#  
    ifconfig "${ZONE_NETWORK_INTERFACE}" 1>/dev/null 2>/dev/null
    if [ $? -ne 0 ] ; then
      LogError "The network interface \"${ZONE_NETWORK_INTERFACE}\" does not exist or is not plumbed"
      ZONE_CONFIGURATION_OK=${__FALSE}
    fi
  fi
  
# ----------------------------------------------------------------------------- 
# check if the IP address already exists
#
  if [ ${ZONE_CONFIG_ONLY} != ${__TRUE} ] ; then
    check_ip_address "${ZONE_IP_ADDRESS}" "${ZONE_NAME}"
    IP_ADDRESS_OK=$?

    if [ ${IP_ADDRESS_OK} != ${__TRUE} ] ; then
      LogError "The IP address \"${ZONE_IP_ADDRESS}\" is already in use"
      ZONE_CONFIGURATION_OK=${__FALSE}
    fi
  fi

# ----------------------------------------------------------------------------- 
# check the configuration for additional network interfaces
#
  if [ "${ZONE_ADD_NETWORK_INTERFACE}"x != ""x ] ; then
    for CURENTRY in ${ZONE_ADD_NETWORK_INTERFACE} ; do
#      CUR_IF="$( echo ${CURENTRY} | cut -f1 -d ":" )"
#      CUR_IP="$( echo ${CURENTRY} | cut -f2 -d ":" )"
#      CUR_ROUTER="$( echo ${CURENTRY} | cut -f3 -d ":" )"

	  CUR_IF="${CURENTRY%%:*}"
	  CUR_ROUTER="${CURENTRY##*:}"
	  DUMMY=${CURENTRY%:*} ; CUR_IP="${DUMMY#*:}"

      if [ ${ZONE_CONFIG_ONLY} != ${__TRUE} ] ; then
        check_ip_address "${CUR_IP%/*}" "${ZONE_NAME}" 
        if [ $? -ne 0 ] ; then
          LogError "The IP \"${CUR_IP}\" is already active!"
          ZONE_CONFIGURATION_OK=${__FALSE}
        fi
	  fi
	  
      CUR_ADAPTER_TYPE="$( get_network_adapter_type "${CUR_IF}" )"
      if [ "${CUR_ADAPTER_TYPE}"x = ""x ] ; then
        LogError "The network adapter \"${CUR_IF}\" does not exist!"
        ZONE_CONFIGURATION_OK=${__FALSE}
      fi
	  
      if [ "${ZONE_IP_STACK}"x = "EXCLUSIVE"x ] ; then
        ifconfig "${CUR_IF}" 1>/dev/null 2>/dev/null
        if [ $? -eq 0 ] ; then
          LogError "The network interface \"${CUR_IF}\" is used in the global zone"
          ZONE_CONFIGURATION_OK=${__FALSE}
        fi
      fi
    done
  fi

# ----------------------------------------------------------------------------- 
# check the mode for the zone
#
  LogInfo "Checking the mode for the zone ..."
  [ "${ZONE_MODE}"x = "sparse"x ] && ZONE_MODE="small"
  [ "${ZONE_MODE}"x = "whole"x -o "${ZONE_MODE}"x = "wholeroot"x -o "${ZONE_MODE}"x = "whole_root"x ] && ZONE_MODE="big"  
  
  if [ "${ZONE_MODE}" != "small" -a "${ZONE_MODE}" != "big" ] ; then
    LogError "Invalid zone mode found: \"${ZONE_MODE}\""
    ZONE_CONFIGURATION_OK=${__FALSE}
  fi

# ----------------------------------------------------------------------------- 
# check the ZFS datasets
#
  if [ ${ZONE_CONFIG_ONLY} != ${__TRUE} ] ; then
    LogInfo "Checking the ZFS datasets for the zone ..."
    for CUR_ENTRY in ${ZONE_DATASETS} ; do
      zfs list ${CUR_ENTRY} 2>/dev/null 1>/dev/null
      if [ $? -ne 0 ] ; then
        LogError "The ZFS dataset \"${CUR_ENTRY}\" does not exist"
        ZONE_CONFIGURATION_OK=${__FALSE}
      fi
      grep  "<dataset name="${CUR_ENTRY}"/>" /etc/zones/*.xml | grep -v "/etc/zones/${ZONE_NAME}.xml"
      if [ $? -eq 0 ] ; then
        LogWarning "Looks like the ZFS dataset \"${CUR_ENTRY}\" is already configured for another zone"
        if [ ${ZONE_CONFIGURATION_OK} != ${__FALSE} ] ; then
          AskUser "Do you want to continue?" 
          [ $? -ne ${__TRUE} ] && die 14 "Script aborted by the user"
        fi
      fi
    done
  fi
  
# ----------------------------------------------------------------------------- 
# Check the Zone template directories
#
  if [ ${ZONE_CONFIG_ONLY} != ${__TRUE} ] ; then
    LogInfo "Checking the template directories for the zone ..."
    for CUR_ENTRY in ${ZONE_TEMPLATE_DIRS} ; do
      if [ ! -d "${CUR_ENTRY}"  ] ; then
        LogError "The zone template directory \"${CUR_ENTRY}\" does not exist"
        ZONE_CONFIGURATION_OK=${__FALSE}
      fi
    done
  fi
  
# ----------------------------------------------------------------------------- 
# check the free space in the target directory 
#
  if [ ${ZONE_CONFIG_ONLY} != ${__TRUE} ] ; then
    LogInfo "Checking the free space for the zone ..."
    if [ "${FREE_SPACE_FOR_THE_ZONE}" != "0" ] ; then
      FREE_SPACE=$( df -k "${ZONE_PATH}"  | grep -v "Filesystem" | tr -s " " | cut -f4 -d" "  )
      if [[ ${FREE_SPACE} -lt ${FREE_SPACE_FOR_THE_ZONE} ]] ; then
        LogError "Not enough free space in \"${ZONE_PATH}\" to create the zone; free are ${FREE_SPACE} kb; necessary are ${FREE_SPACE_FOR_THE_ZONE} kb"
        ZONE_CONFIGURATION_OK=${__FALSE}
      fi
    fi
  fi
  
  if [ ${ZONE_CONFIGURATION_OK} != ${__TRUE} ] ; then
    zone_config_error 20 "Zone configuration is not okay"
  else
    LogMsg "The zone configuration seems to be okay "
  fi
  
# ----------------------------------------------------------------------------- 
# delete the zone if it already exists
#
  if [ ${ZONE_EXISTS} = ${__TRUE} ] ; then
    LogMsg "Deleting the existing zone \"${ZONE_NAME}\" ..."
#    [ ${__FORCE} = ${__TRUE} ] && ADD_PARM="-F"  || ADD_PARM=""
  

    if [ ${ZONE_CONFIG_ONLY} != ${__TRUE}  ] ; then 
      LogMsg "Stopping the zone .."
      executeCommandAndLog zoneadm -z "${ZONE_NAME}" halt 
      ZONE_STATUS="$( zoneadm -z "${ZONE_NAME}" list -p  | cut -f3 -d ":" )"
      [ "${ZONE_STATUS}"x != "installed"x ] && LogWarning "Error calling \"zoneadm -z ${ZONE_NAME} halt\""
    else
      LogMsg "NOT stopping the zone because we only configure the zone "
    fi

    if [ ${ZONE_CONFIG_ONLY} != ${__TRUE}  ] ; then
      LogMsg "Uninstalling the zone .."
      executeCommandAndLog zoneadm -z "${ZONE_NAME}" uninstall -F 
      ZONE_STATUS="$( zoneadm -z "${ZONE_NAME}" list -p  | cut -f3 -d ":" )"
      [ "${ZONE_STATUS}"x != "configured"x ] && LogWarning "Error calling \"zoneadm -z ${ZONE_NAME} uninstall -F\""
   else
     LogMsg "NOT uninstalling the zone because we only configure the zone."
   fi

    LogMsg "Deleting the zone .."
    executeCommandAndLog zonecfg -z "${ZONE_NAME}" delete -F || \
    ZONE_STATUS="$( zoneadm -z "${ZONE_NAME}" list -p  | cut -f3 -d ":" )"
    [ "${ZONE_STATUS}"x != "configured"x ] && die 23 "Error calling \"zonecfg -z ${ZONE_NAME} delete -F\""   
  fi

  if [ ${ZONE_PATH_EXISTS} = ${__TRUE} -a -d "${THIS_ZONE_PATH}" -a ${ZONE_CONFIG_ONLY} != ${__TRUE} ] ; then
    LogMsg "Removing the existing files in the zone directory \"${THIS_ZONE_PATH}\" ..."
    rm -rf "${THIS_ZONE_PATH}/"* 
    [ -r "${THIS_ZONE_PATH}"/* ] && die 26 "Can not cleanup the existing zone directory \"${THIS_ZONE_PATH}\" "

    chmod 700 "${THIS_ZONE_PATH}"  ||  LogWarning "Error $? changing the mode of  \"${THIS_ZONE_PATH}\" to 700"
  fi

# ----------------------------------------------------------------------------- 
# create the temp. zone configuration file
#
  LogMsg "Configuring the zone \"${ZONE_NAME}\" ..."
  [ ${ZONE_AUTOBOOT} = ${__TRUE} ] && AUTOBOOT="true" || AUTOBOOT="false"
  if [ "${ZONE_BRAND}"x != ""x ] ; then
    CREATE="create -t ${ZONE_BRAND}"
  elif [ "${ZONE_MODE}"x = "big"x ] ; then
    CREATE="create -b" 
  else
    CREATE="create"
  fi
  
  ZONE_GLOBAL_CONFIG="${ZONE_GLOBAL_OPTIONS}"

  if [ "${ZONE_SET_GLOBAL_OPTIONS}"x != ""x ] ; then
     for CUR_OPTION in ${ZONE_SET_GLOBAL_OPTIONS} ; do
       ZONE_GLOBAL_CONFIG="${ZONE_GLOBAL_CONFIG}
set ${CUR_OPTION}
"
     done
  fi
              
  if [ "${ZONE_HOSTID}"x != ""x ] ; then
    ZONE_GLOBAL_CONFIG="${ZONE_GLOBAL_CONFIG}
set hostid=${ZONE_HOSTID}
"
  fi

  ADD_ZONE_CONFIG=""

# add the ZFS datasets
  for CUR_DATASET in ${ZONE_DATASETS} ; do
    ADD_ZONE_CONFIG="${ADD_ZONE_CONFIG}
	
add dataset
set name=${CUR_DATASET}
end"    
  done

# add devices for the zone

# temporary disable file name generation
set -f

  for CUR_DEVICE in ${ZONE_DEVICES} ; do
    ADD_ZONE_CONFIG="${ADD_ZONE_CONFIG}

add device
set match=\"${CUR_DEVICE}\"
end"    
  done

# enable file name generation again
set +f

# add inherited dirs to the zone configuration
#
  for CURDIR in ${ZONE_INHERITED_DIRS} ; do
    CUR_INHERITED_DIR="$( echo ${CURDIR} | sed "s#/\$##g" )"
    ADD_ZONE_CONFIG="${ADD_ZONE_CONFIG}
	
add inherit-pkg-dir
set dir=${CUR_INHERITED_DIR}
end"    
  done

# add readonly dirs to the zone configuration
#
  for CUR_ENTRY in ${ZONE_READONLY_DIRS} ; do
    READONLY_ZONE_DIR="$( echo ${CUR_ENTRY%:*} | sed "s#/\$##g" )" 
    READONLY_GLOBAL_DIR="$( echo ${CUR_ENTRY#*:} | sed "s#/\$##g"  )"  

    is_zfs_file_system "${READONLY_GLOBAL_DIR}"
    if [ $? -eq ${__TRUE} ] ; then
      ADD_ZONE_CONFIG="${ADD_ZONE_CONFIG}
	
add fs
set dir=${READONLY_ZONE_DIR}
set special=${READONLY_GLOBAL_DIR}
set type=zfs
add options ro
end"     

    else    
      if [ ! -d "${READONLY_GLOBAL_DIR}" ] ; then
        LogWarning "Creating the directory \"${READONLY_GLOBAL_DIR}\" "
        mkdir -p "${READONLY_GLOBAL_DIR}" || \
          die 27 "Can not create the directory \"${READONLY_GLOBAL_DIR}\" "
      fi
      ADD_ZONE_CONFIG="${ADD_ZONE_CONFIG}
	
add fs
set dir=${READONLY_ZONE_DIR}
set special=${READONLY_GLOBAL_DIR}
set type=lofs
add options ro
end" 
    fi
  done


# add writable dirs to the zone configuration
#
  for CUR_ENTRY in ${ZONE_WRITABLE_DIRS} ; do
    WRITABLE_ZONE_DIR="$( echo ${CUR_ENTRY%:*} | sed "s#/\$##g" )"
    WRITABLE_GLOBAL_DIR="$( echo ${CUR_ENTRY#*:} | sed "s#/\$##g"  )"

    is_zfs_file_system "${WRITABLE_GLOBAL_DIR}"
    if [ $? -eq ${__TRUE} ] ; then
      ADD_ZONE_CONFIG="${ADD_ZONE_CONFIG}
	
add fs
set dir=${WRITABLE_ZONE_DIR}
set special=${WRITABLE_GLOBAL_DIR}
set type=zfs
add options rw
end"     
    else        
      if [ ! -d "${WRITABLE_GLOBAL_DIR}" ] ; then
        LogWarning "Creating the directory \"${WRITABLE_GLOBAL_DIR}\" "
        mkdir -p "${WRITABLE_GLOBAL_DIR}" || \
          die 27 "Can not create the directory \"${WRITABLE_GLOBAL_DIR}\" "
      fi
        
      ADD_ZONE_CONFIG="${ADD_ZONE_CONFIG}
	
add fs
set dir=${WRITABLE_ZONE_DIR}
set special=${WRITABLE_GLOBAL_DIR}
set type=lofs
add options rw
end"
    fi 
  done

# add add. network interfaces to the zone configuration
#
  if [ "${ZONE_ADD_NETWORK_INTERFACE}"x != ""x ] ; then
	for CURENTRY in ${ZONE_ADD_NETWORK_INTERFACE} ; do
#	  CUR_IF="$( echo ${CURENTRY} | cut -f1 -d ":" )"
#	  CUR_IP="$( echo ${CURENTRY} | cut -f2 -d ":" )"
#	  CUR_ROUTER="$( echo ${CURENTRY} | cut -f3 -d ":" )"

	  CUR_IF="${CURENTRY%%:*}"
	  CUR_ROUTER="${CURENTRY##*:}"
	  DUMMY=${CURENTRY%:*} ; CUR_IP="${DUMMY#*:}"

	  [ "${CUR_ROUTER}"x != ""x ] && T="set defrouter=${CUR_ROUTER}" || T=""
      if [ "${ZONE_IP_STACK}"x = "SHARED"x ] ; then	  
        ADD_ZONE_CONFIG="${ADD_ZONE_CONFIG}
		
add net
set address=${CUR_IP}
set physical=${CUR_IF}
${T}
end
"	  
      else
        ADD_ZONE_CONFIG="${ADD_ZONE_CONFIG}
		
add net
set physical=${CUR_IF}
end
"	  
      fi
	done
  fi

# add memory and cpu resources to the zone configuration
#
  if [ "${ZONE_MEMORY_LIMIT}"x != ""x -o "${ZONE_SWAP_LIMIT}"x != ""x ] ; then
    ADD_ZONE_CONFIG="${ADD_ZONE_CONFIG}
	
add capped-memory"

    [ "${ZONE_MEMORY_LIMIT}"x != ""x ] && ADD_ZONE_CONFIG="${ADD_ZONE_CONFIG}	  
set physical=${ZONE_MEMORY_LIMIT}"

    [ "${ZONE_SWAP_LIMIT}"x != ""x  ] && ADD_ZONE_CONFIG="${ADD_ZONE_CONFIG} 
set swap=${ZONE_SWAP_LIMIT}"

    ADD_ZONE_CONFIG="${ADD_ZONE_CONFIG}
end"
  fi

  if [ "${ZONE_CAPPED_CPU_COUNT}"x != ""x ] ; then
    ADD_ZONE_CONFIG="${ADD_ZONE_CONFIG}
	
add capped-cpu
set ncpus=${ZONE_CAPPED_CPU_COUNT}
end"
  fi
    
  if [ "${ZONE_CPU_COUNT}"x != ""x ] ; then
    ADD_ZONE_CONFIG="${ADD_ZONE_CONFIG}
	
add dedicated-cpu
set ncpus=${ZONE_CPU_COUNT}
end"
  fi

  if [ "${ZONE_CPU_SHARES}"x != ""x ] ; then
    ADD_ZONE_CONFIG="${ADD_ZONE_CONFIG}
	
set cpu-shares=${ZONE_CPU_SHARES}
set scheduling-class=FSS"
  fi

# add the IP configuration to the zone configuration
#
  if [ "${ZONE_DEFAULT_ROUTER}"x != ""x -a "${ZONE_DEFAULT_ROUTER}"x != "none"x ] ; then
    ROUTER_CONFIG="set defrouter=${ZONE_DEFAULT_ROUTER}"
  else
    ROUTER_CONFIG=""
  fi

  if [ "${ZONE_IP_STACK}"x = "SHARED"x ] ; then
    ZONE_IP_CONFIG_CMDS="
add net
set address=${ZONE_IP_ADDRESS}${ZONE_IP_NETMASK}  
set physical=${ZONE_NETWORK_INTERFACE}
${ROUTER_CONFIG}
end"      
  else
    ZONE_IP_CONFIG_CMDS="
set ip-type=exclusive
add net
set physical=${ZONE_NETWORK_INTERFACE}
end"      
  fi

  ZONE_CONFIG="
${CREATE}
set autoboot=${AUTOBOOT}
set zonepath=${THIS_ZONE_PATH}
${ZONE_GLOBAL_CONFIG}
${ZONE_IP_CONFIG_CMDS}
${ADD_ZONE_CONFIG}
commit
exit
"

  echo "${ZONE_CONFIG}" >"${__TEMPFILE1}"
  if [ ${EDIT_ZONE_CONFIG} = ${__TRUE} ] ; then
    LogMsg "Calling the editor \"${EDITOR}\" to edit the zone configuration file \"${__TEMPFILE1}\"..."
    ${EDITOR} "${__TEMPFILE1}"
    AskUser "Continue creating the zone (y/N)? "
    [ $? -ne ${__TRUE} ] && die 14 "Script aborted by the user"
  fi

# ----------------------------------------------------------------------------- 
# configure the zone
#    
  zonecfg -z "${ZONE_NAME}" -f  "${__TEMPFILE1}"
  if [ $? -ne 0 ] ; then
    LogError "zonecfg ended with an error."
    LogMsg "The commands to create the zone are: "
    
    LogMsg "-" "${ZONE_CONFIG}"
    
	TMP_ZONE_CONFIG_FILE="/var/tmp/"${ZONE_NAME}".$$"
	LogMsg "-" ""
	cp -p "${__TEMPFILE1}" "${TMP_ZONE_CONFIG_FILE}" && \
	  LogMsg "The temporary zone config is saved in the file \"${TMP_ZONE_CONFIG_FILE}\" "
	
    die 29 "Error configuring the zone \"${ZONE_NAME}\""
  fi

  if [ ${ZONE_CONFIG_ONLY} = ${__TRUE} ] ; then
     LogMsg "Only configuring the zone requested. Ending now. "
	 die 0
  fi	 

# ----------------------------------------------------------------------------- 
# install the zone
#  

  if [ "${ZONE_CLONE_SOURCE}"x != ""x ] ; then
    LogMsg "Installing the zone \"${ZONE_NAME}\" by cloning the zone \"${ZONE_CLONE_SOURCE}\"..."
    executeCommandAndLog  zoneadm -z "${ZONE_NAME}" clone ${ZONE_CLONE_SOURCE}
  elif [ "${ZONE_FLASHIMAGE}"x != ""x ] ; then
    LogMsg "Installing the zone \"${ZONE_NAME}\" using the flashimage \"${ZONE_FLASHIMAGE}\" ... "
    executeCommandAndLog zoneadm -z "${ZONE_NAME}" install -a "${ZONE_FLASHIMAGE}" -u
  else  
    LogMsg "Installing the zone \"${ZONE_NAME}\" ..."
    executeCommandAndLog zoneadm -z "${ZONE_NAME}" install 
  fi

# wait until the zone is down
  CUR_TIMEOUT=180
  CUR_INTERVALL=10
  
  LogMsg "Waiting up to ${CUR_TIMEOUT} seconds for the zone to shutdown .."
  i=0
  while [ 0 = 0 ] ; do
    printf "."
    ZONE_STATUS="$( zoneadm -z "${ZONE_NAME}" list -p | cut -f3 -d ":" )"
    [ "${ZONE_STATUS}"x = "shutting_down"x ] && sleep ${CUR_INTERVALL}
    (( i = i + CUR_INTERVALL ))
    [ $i -gt ${CUR_TIMEOUT} ] && break
  done
  printf "\n"  
  
  ZONE_STATUS="$( zoneadm -z "${ZONE_NAME}" list -p | cut -f3 -d ":" )"
  [ "${ZONE_STATUS}"x != "installed"x ] && die 32 "Error installing the zone \"${ZONE_NAME}\" (The zone status is \"${ZONE_STATUS}\")"

# ----------------------------------------------------------------------------- 
# prepare the zone ready
#

#   29.09.2010 v1.1.16/bs
# workaround for a bug in the zone creation 
#
  LogInfo "Executing the workaround for a bug in zone create: 'pkgadm sync -R \"${THIS_ZONE_PATH}/root\"  -q' "
  pkgadm sync -R "${THIS_ZONE_PATH}/root"  -q
 
  LogMsg "Preparing the zone \"${ZONE_NAME}\" for running applications ..."
  executeCommandAndLog  zoneadm  -z "${ZONE_NAME}" ready
  ZONE_STATUS="$( zoneadm -z "${ZONE_NAME}" list -p | cut -f3 -d ":" )"
  [ "${ZONE_STATUS}"x != "ready"x ] && die 35 "Error preparing the zone \"${ZONE_NAME}\""

# ----------------------------------------------------------------------------- 
# do the zone post config
#
  LogMsg "Post configuring the zone \"${ZONE_NAME}\"  ..."

  LogMsg "Copying additional files to the zone ..."  

  for CUR_DIR in ${ZONE_TEMPLATE_DIRS} ; do
    if [ -d "${CUR_DIR}" ] ; then
      LogMsg "Copying files from the template directory \"${CUR_DIR}\" ..."
      cd "${CUR_DIR}" && find . | cpio -pdum "${THIS_ZONE_PATH}/root" || \
	    LogWarning "Error copying the files from the directory \"${CUR_DIR}\" to the zone"
    else
      LogWarning "The zone template directory \"${CUR_DIR}\" does not exist anymore. Ignoring this entry."
    fi
  done

  for CUR_FILE in ${ZONE_FILES_TO_COPY} ; do
    if [ -f "${CUR_FILE}" ] ; then
      CUR_TARGET_FILE="${THIS_ZONE_PATH}/root/${CUR_FILE}"
      LogMsg "Copying file \"${CUR_FILE}\" to the non-global zone ..."
      mkdir -p "$( dirname "${CUR_TARGET_FILE}" )" && \
      cp -p "${CUR_FILE}" "${CUR_TARGET_FILE}" ||\
        LogWarning "Error copying the file \"${CUR_FILE}\" to \"${CUR_TARGET_FILE}\" "
    else
      LogWarning "The file \"${CUR_FILE}\" does not exist in the global zone. Ignoring this entry."
    fi
  done

  if [ "${ZONE_IP_STACK}"x = "SHARED"x ] ; then
    SYSID_NETWORK_CONFIG="network_interface=NONE
{hostname=${ZONE_NAME}}"   
  else
    if [ "${ZONE_DEFAULT_ROUTER}"x != ""x ] ; then
      TMP_DEF_ROUTER="${ZONE_DEFAULT_ROUTER}"
    else
      TMP_DEF_ROUTER="$(  netstat -rn | grep default  | head -1 | tr -s " " | cut -f2 -d " " )"
    fi
    if [ "${ZONE_NETMASK}"x != ""x ] ; then
      TMPVAR1="netmask=${ZONE_NETMASK}"
    else
      TMPVAR1=""
    fi     
    SYSID_NETWORK_CONFIG="network_interface=${ZONE_NETWORK_INTERFACE}{hostname=${ZONE_NAME} ip_address=${ZONE_IP_ADDRESS} ${TMPVAR1} protocol_ipv6=no default_route=${TMP_DEF_ROUTER}}"
  fi
 
  if  [ ${USE_EXISTING_NAMESERVER_CONFIG} = ${__TRUE} ] ; then
    DNS_NAMESERVER="$( grep nameserver /etc/resolv.conf | cut -f2 -d " " )"
    DNS_NAMESERVER="$( echo ${DNS_NAMESERVER} | tr " " "," )"
    DNS_SEARCHPATH="$( grep search /etc/resolv.conf | cut -f2- -d " " | tr " " "," )"
    DNS_DOMAIN="$( grep domain /etc/resolv.conf | cut -f2 -d " " | tail -1 )"

    SYSID_NAMESERVER_CONFIG="name_service=DNS {"
    [ "${DNS_NAMESERVER}"x != ""x ] && SYSID_NAMESERVER_CONFIG="${SYSID_NAMESERVER_CONFIG} name_server=${DNS_NAMESERVER}"
    [ "${DNS_SEARCHPATH}"x != ""x ] && SYSID_NAMESERVER_CONFIG="${SYSID_NAMESERVER_CONFIG} search=${DNS_SEARCHPATH} "
    [ "${DNS_DOMAIN}"x != ""x ] && SYSID_NAMESERVER_CONFIG="${SYSID_NAMESERVER_CONFIG} domain_name=${DNS_DOMAIN} "
    SYSID_NAMESERVER_CONFIG="${SYSID_NAMESERVER_CONFIG} }"

  else
    SYSID_NAMESERVER_CONFIG="name_service=NONE"
  fi

  ZONE_SYSIDCFG_FILE="${THIS_ZONE_PATH}/root/etc/sysidcfg"
  cat <<EOT >> "${ZONE_SYSIDCFG_FILE}"
${SYSID_NAMESERVER_CONFIG}
root_password=${ZONE_ROOT_PASSWORD}
system_locale=${ZONE_LOCALE}
${SYSID_NETWORK_CONFIG}
timezone=${ZONE_TZ}
security_policy=NONE
timeserver=${ZONE_TIMESERVER}
terminal=${ZONE_TERMINAL}
nfs4_domain=default
EOT
  if [ $? -ne 0 ] ; then
    LogError "Error creating the file \"${ZONE_SYSIDCFG_FILE}\" "
    __MAINRC=100
  fi

# change the TIMEZONE file in the zone to avoid the initial zone reboot
#
   TZ_FILE="${THIS_ZONE_PATH}/root/etc/TIMEZONE"
   if [ -f "${TZ_FILE}" ] ; then
    LogInfo "Changing the file \"${TZ_FILE}\" ..."
    cp -p "${TZ_FILE}" "${TZ_FILE}".org
    TMPVAR="$( sed "s#^TZ=.*#TZ=${ZONE_TZ}#g"  "${TZ_FILE}" )"
    echo "${TMPVAR}" >"${TZ_FILE}"
  else
    LogInfo "Creating the file \"${TZ_FILE}\" ..."
    cat <<EOT >"${TZ_FILE}"
TZ=${ZONE_TZ}
CMASK=022
EOT
  fi

# correct the home directory for root in the zone
  CUR_ROOT_HOME="$(grep root /etc/passwd  | cut -f 6 -d ":" )"
  mkdir -p "${THIS_ZONE_PATH}/root/${CUR_ROOT_HOME}"
  cp -p "${THIS_ZONE_PATH}/root/etc/passwd" "${THIS_ZONE_PATH}/root/etc/passwd.org"
  TMPLINE="$( grep "^root" "${THIS_ZONE_PATH}/root/etc/passwd.org" | sed "s#:/:#:${CUR_ROOT_HOME}:#" )"
  echo "${TMPLINE}
$( grep -v "^root" ${THIS_ZONE_PATH}/root/etc/passwd.org )" >"${THIS_ZONE_PATH}/root/etc/passwd"  

  if [ ${USE_EXISTING_NAMESERVER_CONFIG} = ${__TRUE} ] ; then
    LogMsg "Changing the nameserver configuration of the zone \"${ZONE_NAME}\" ..."

    for CURFILE in ${NAME_SERVER_CONFIG_FILES} ; do
      LogMsg "Processing the file \"${CURFILE}\" ..."
      if [ -f ${CURFILE} ] ; then
         cp -p ${CURFILE} "${THIS_ZONE_PATH}/root/${CURFILE}"
#        /usr/sfw/bin/gtar  -cf - ${CURFILE} | ( cd "${THIS_ZONE_PATH}/root" ; /usr/sfw/bin/gtar -xvf -  )
        if [ $? -ne 0 ] ; then
          LogError "Error creating \"${THIS_ZONE_PATH}/root/${CURFILE}\" " 
          __MAINRC=102
        fi
      else
        LogWarning "\"${CURFILE}\" not found in the global zone"
      fi
    done
  fi

# check loghost entry in /etc/hosts
  grep loghost "${THIS_ZONE_PATH}/root/etc/hosts" >/dev/null
  if [ $? -ne 0 ] ; then
    LogInfo "Adding a loghost entry to the /etc/hosts files ..."
    TMPVAR="$( sed "s/localhost/localhost loghost/g" "${THIS_ZONE_PATH}/root/etc/hosts" )"
    cp -p "${THIS_ZONE_PATH}/root/etc/hosts" "${THIS_ZONE_PATH}/root/etc/hosts.org"
    echo "${TMPVAR}" >"${THIS_ZONE_PATH}/root/etc/hosts"
 fi
 
  if [ "${ZONE_IP_STACK}x" = "EXCLUSIVE"x ] ; then
    LogMsg "Creating initial network adapter configuration for the zone ..."
	OUTFILE="${THIS_ZONE_PATH}/root/etc/hostname.${ZONE_NETWORK_INTERFACE}"
    echo "${ZONE_IP_ADDRESS}" >"${OUTFILE}" && LogMsg "File \"${OUTFILE}\" created." || \
	  LogWarning "Error creating the file \"${OUTFILE}\" "	  
	  
    for CURFILE in ${EXCLUSIVE_IP_STACK_CONFIG_FILES} ; do
	  LogInfo "Copying the file \"${CURFILE}\" to the zone ..."
      if [ ! -f "${CURFILE}" ] ; then
        LogWarning "File \"${CURFILE}\" not found in the global zone"
      else
        cp -p "${CURFILE}" "${THIS_ZONE_PATH}/root/${CURFILE}" || LogWarning "Error copying \"${CURFILE}\" to the zone"
      fi
    done

# remove localhost entries from /etc/hosts
    TMPVAR="$( egrep -v "^::1 |^127.0.0.1 " ${THIS_ZONE_PATH}/root/etc/hosts)"
    echo "${TMPVAR}" >"${THIS_ZONE_PATH}/root/etc/hosts)"

    if [ "${ZONE_ADD_NETWORK_INTERFACE}"x != ""x ] ; then
      LogMsg "Creating additional initial network adapter configurations for the zone ... "
	  for CURENTRY in ${ZONE_ADD_NETWORK_INTERFACE} ; do
	    CUR_IF="$( echo ${CURENTRY} | cut -f1 -d ":" )"
	    CUR_IP="$( echo ${CURENTRY} | cut -f2 -d ":" )"
		OUTFILE="${THIS_ZONE_PATH}/root/etc/hostname.${CUR_IF}"
        echo "${CUR_IP}" > "${OUTFILE}" && LogMsg "File \"${OUTFILE}\" created." || \
          LogWarning "Error creating the file \"${OUTFILE}\" "	  
      done
	fi	
  fi
  
  touch "${THIS_ZONE_PATH}/root/etc/.NFS4inst_state.domain" || \
    LogWarning "Error creating \"${THIS_ZONE_PATH}/root/etc/.NFS4inst_state.domain\" "

  if [ "${ZONE_CUSTOMIZE_SCRIPT_SOURCE}"x != ""x -a  \
       "${ZONE_CUSTOMIZE_SCRIPT_SOURCE}"x != "none"x ] ; then

    LogMsg "Installing the customize script \"${ZONE_CUSTOMIZE_SCRIPT_TARGET}\" in the zone \"${ZONE_NAME}\" ..."
    CUSTOMIZE_SCRIPT_INSIDE_THE_ZONE="${THIS_ZONE_PATH}/root${ZONE_CUSTOMIZE_SCRIPT_TARGET}"
    CREATE_CUSTOMIZE_SCRIPT=${__TRUE}

    TARGET_DIR="$( dirname ${CUSTOMIZE_SCRIPT_INSIDE_THE_ZONE} )"  
    if [ ! -d "${TARGET_DIR}" ] ; then
      LogWarning "The target directory \"${TARGET_DIR}\" does not exist - now creating it..."
      mkdir -p "${TARGET_DIR}" 
      if [ $? -ne 0 ] ; then
        LogError "Can not create the target dir \"${TARGET_DIR}\" - customize script not created" 
        CREATE_CUSTOMIZE_SCRIPT=${__FALSE}
        __MAINRC=105
      fi
    fi

# creating the config file with the zone variables inside the zone
#
    ZONE_CONFIG_FILE="${THIS_ZONE_PATH}/root${ZONE_CONFIG_FILE}"
    LogMsg "Creating the zone creation config file \"${ZONE_CONFIG_FILE}\" ..." 

CONFIG_FILE_CONTENTS="
#
# zone created by ${__SCRIPTNAME} ${__SCRIPT_VERSION} at $( date )
#
"    
    for i in $( set | grep "^ZONE_"  | cut -f 1 -d "=" ) ; do
      CUR_VAR="${i%%=*}" 
      CUR_VALUE="${i#*=}"
      CONFIG_FILE_CONTENTS="${CONFIG_FILE_CONTENTS}
${CUR_VAR}='$( eval echo \"\$${CUR_VAR}\" )'"
    done

    echo "${CONFIG_FILE_CONTENTS}" >"${ZONE_CONFIG_FILE}"
    if [ $? -ne 0 ] ; then
      LogError "Error creating the file \"${ZONE_CONFIG_FILE}\" "
      __MAINRC=110
    fi

    if [ ${CREATE_CUSTOMIZE_SCRIPT} = ${__TRUE} ] ; then
      echo "${ZONE_CUSTOMIZE_SCRIPT_CONTENTS}" >"${CUSTOMIZE_SCRIPT_INSIDE_THE_ZONE}"
      if [ $? -ne 0 ] ; then
        LogError "Error creating the file \"${CUSTOMIZE_SCRIPT_INSIDE_THE_ZONE}\" "
        __MAINRC=106
      fi
      chmod 755 "${CUSTOMIZE_SCRIPT_INSIDE_THE_ZONE}" || \
      LogWarning "Error changing the mode of \"${CUSTOMIZE_SCRIPT_INSIDE_THE_ZONE}\" "
    fi
  fi

  if [ "${ZONE_SMF_PROFILE}"x != ""x -a "${ZONE_SMF_PROFILE}"x != "none"x ] ; then
    LogMsg "Installing the profile for the zone ..."
    PROFILE_INSIDE_THE_ZONE="${THIS_ZONE_PATH}/root/var/svc/profile/site.xml"
    cp -p "${ZONE_SMF_PROFILE}"  "${PROFILE_INSIDE_THE_ZONE}"
    if [ $? -ne 0 ] ; then
      LogError "Can not create the profile for the zone \"${PROFILE_INSIDE_THE_ZONE}\" " 
      __MAINRC=107
    fi
  fi

  if [ "${ZONE_FINISH_SCRIPT}"x != ""x -a "${ZONE_FINISH_SCRIPT}"x != "none"x ] ; then
    LogMsg "Calling the finish script for the zone ..."

# export all variables beginning with ZONE_
#
    for i in $( set | grep "^ZONE_"  | cut -f 1 -d "=" ) ; do
      CUR_VAR="${i%%=*}" ; export ${CUR_VAR}
    done
    
    "${ZONE_FINISH_SCRIPT}" "${THIS_ZONE_PATH}" 
    if [ $? -ne 0 ] ; then
      LogError "The finish script for the zone returned an error " 
      __MAINRC=108
    fi
  fi
  
  LogMsg " ... done. zone \"${ZONE_NAME}\" installed and configured"

# ----------------------------------------------------------------------------- 
# boot the zone if requested
#
  if [ ${BOOT_THE_ZONE_NOW} = ${__TRUE} ] ; then
    if [ ${__MAINRC} != 0  -a ${__FORCE} != ${__TRUE} ] ; then
      LogWarning "autobooting the zone is true but due to the errors while creating the zone we will not boot the zone now"
      LogWarning "Note: Use -f to force the boot of the zone anyway and suppress this check the next time"
      BOOT_THE_ZONE_NOW=${__FALSE}
    fi

    if [ ${BOOT_THE_ZONE_NOW} = ${__TRUE} ] ; then
      LogMsg "Now booting the new created zone \"${ZONE_NAME}\" ..."
      executeCommandAndLog  zoneadm -z "${ZONE_NAME}" boot
      ZONE_STATUS="$( zoneadm -z "${ZONE_NAME}" list -p | cut -f3 -d ":" )"
      if [ "${ZONE_STATUS}"x = "running"x ] ; then
        LogMsg "The zone \"${ZONE_NAME}\" is now running"
      else
        LogError "Error booting the zone \"${ZONE_NAME}\" "
        __MAINRC=109
      fi
    fi
  fi

# ----------------------------------------------------------------------------- 
# end the script
#

  die ${__MAINRC} 

# this "exit" command should never be executed ...
#

exit ${__MAINRC} 

# ----------------------------------------------------------------------------- 

