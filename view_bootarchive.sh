#!/usr/bin/ksh
#
# ****  Note: The main code starts after the line containing "# main:" ****
#             The main code for your script should start after "# main - your code"
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
# Copyright 2006-2011 Bernd Schemmer  All rights reserved.
# Use is subject to license terms.
#
# Notes:
# 
# - use "view_bootarchive.sh {-v} {-v} {-v} -h" to get the usage help
#
# - replace "scriptt.sh" with the name of your script
# - change the parts marked with "???" and "??" to your need
#
# - use "view_bootarchive.sh -H 2 >view_bootarchive.sh.doc" to get the documentation
#
# - use "view_bootarchive.sh -X 2 >view_bootarchive.sh.examples.doc" to get some usage examples
#
# - this is a Kornshell script - it may not function correctly in other shells
# - the script was written and tested with ksh88 but should also work in ksh93
#   The script should also work in bash -- but that is NOT completly tested
#
#
##EXAMPLE## 
##EXAMPLE##  
##EXAMPLE##  Mount the boot archive for the current platform
##EXAMPLE##  
##EXAMPLE##     ./view_bootarchive.sh
##EXAMPLE##  
##EXAMPLE##  Mount a specific boot archive
##EXAMPLE##  
##EXAMPLE##     ./view_bootarchive.sh mount /var/tmp/other_boot_archive
##EXAMPLE##  
##EXAMPLE##  Umount the boot archive for the current platform
##EXAMPLE##  
##EXAMPLE##     ./view_bootarchive.sh umount
##EXAMPLE##  
##EXAMPLE##  Umount a specific boot archive
##EXAMPLE##  
##EXAMPLE##     ./view_bootarchive.sh umount /var/tmp/other_boot_archive
##EXAMPLE##  
##EXAMPLE##  Mount a failsafe boot image
##EXAMPLE##  
##EXAMPLE##     /var/tmp/view_bootarchive.sh mount /platform/sun4v/failsafe
##EXAMPLE##  
# -----------------------------------------------------------------------------
####
#### view_bootarchive.sh - view the contents of a Solaris boot archive for SPARC or x86
####
#### Author: Bernd Schemmer (Bernd.Schemmer@gmx.de)
####
#### Version: see variable ${__SCRIPT_VERSION} below
####          (see variable ${__SCRIPT_TEMPLATE_VERSION} for the template 
####           version used)
####
#### Supported OS: Solaris and others
####
####
#### Description
#### -----------
#### 
#### view the contents of a Solaris boot archive for SPARC or x86
####
####   see http://wikis.sun.com/pages/viewpage.action?pageId=56569677 for some background information
##C#
##C# Configuration file
##C# ------------------
##C#
##C# This script supports a configuration file called <scriptname>.conf.
##C# The configuration file is searched in the working directory,
##C# the home directory of the user executing this script and in /etc
##C# (in this order).
##C#
##C# The configuration file is read before the parameter are processed.
##C#
##C# To override the default config file search set the variable
##C# CONFIG_FILE to the name of the config file to use.
##C#
##C# e.g. CONFIG_FILE=/var/myconfigfile ./view_bootarchive.sh
##C#
##C# See the variable __CONFIG_PARAMETER below for the possible entries in 
##C# the config file.
##C#
####
#### Predefined parameter
#### --------------------
####
#### see the subroutines ShowShortUsage and ShowUsage 
####
#### Note: The current version of the script template can be found here:
####
####       http://bnsmb.de/solaris/scriptt.html
####
####
##T# Troubleshooting support
##T# -----------------------
##T#
##T# Use 
##T#
##T#   __CREATE_DUMP=<anyvalue|directory> <yourscript>
##T#
##T# to create a dump of the environment variables on program exit.
##T#
##T# e.g
##T#
##T#  __CREATE_DUMP=1 ./view_bootarchive.sh
##T#
##T# will create a dump of the environment variables in the files
##T#
##T#   /tmp/view_bootarchive.sh.envvars.$$
##T#   /tmp/view_bootarchive.sh.exported_envvars.$$
##T#
##T# before the script ends
##T#
##T#  __CREATE_DUMP=/var/tmp/debug ./view_bootarchive.sh
##T#
##T# will create a dump of the environment variables in the files
##T#
##T#   /var/tmp/debug/view_bootarchive.sh.envvars.$$
##T#   /var/tmp/debug/view_bootarchive.sh.exported_envvars.$$
##T#
##T# before the script ends (the directory /var/tmp/debug must already exist).
##T#
##T# Note that the dump files will always be created in case of a syntax error. 
##T# To set the directory for these files use
##T#
##T#   export __DUMPDIR=/var/tmp/debug
##T#   ./view_bootarchive.sh
##T#
##T# To suppress creating the dump file in case of a syntax error use
##T#
##T# __DUMP_ALREADY_CREATED=${__TRUE}
##T#
##T#
##T# Use 
##T#
##T#    CreateDump <uniqdirectory> [filename_add]
##T#
##T# to manually create the dump files.
##T#
##T# e.g.
##T#
##T#   CreateDump /var/debug
##T#
##T# will create the files
##T#
##T#   /var/debug/view_bootarchive.sh.envvars.$$
##T#   /var/debug/view_bootarchive.sh.exported_envvars.$$
##T#
##T#   CreateDump /var/debug pass2.
##T#
##T# will create the files
##T#
##T#   /var/debug/view_bootarchive.sh.envvars.pass2.$$
##T#   /var/debug/view_bootarchive.sh.exported_envvars.pass2.$$
##T#
####  Note: 
####    The default action for the signal handler USR1 is "Create an env dump in /var/tmp"
####    The filenames for the dumps are 
####        
####      /var/tmp/<scriptname>.envvars.dump_no_<no>_<PID>
####      /var/tmp/<scriptname>.exported_envvars.dump_no_<no>_<PID>
####
####    where <no> is a sequential number,<PID> is the PID of the process with the script,
####    and <scriptname> is the name of the script without the path.
####
#### Credits
#### -------
####
####       wpollock (http://wikis.sun.com/display/~wpollock)
####         -- http://wikis.sun.com/display/BigAdmin/A+Script+Template+and+Useful+Techniques+for+ksh+Scripts?focusedCommentId=12517624#comment-12517624
####
####      Source for the function PrintWithTimeStamp:
####         Bernd Fingers blog:
####         http://blogs.sun.com/blogfinger/entry/prepend_command_output_lines_with
####
####
#### History:
#### --------
####   03.11.2008 /bs
####     inital release
####
####   03.12.2008/bs
####     added support for boot_archive files compressed by
####     gzip or bzip2
####     the script now always works on a copy of
####     the boot_archive (there's no need to umount the
####     boot_archive before rebooting the server or updating
####     he boot_archive manually anymore)
####
####   19.01.2010/bs
####     corrected a spelling error (sunv4 instead of sun4v)
####
####   12.10.2011 v1.0.0/bs
####     script rewritten using the template scriptt.sh
####     changed the name boot_archive to view_bootarchive.sh
####     the script now also works with the new Solaris 10 versions
####       without separate 32 Bit kernel
####     added the parameter -m to use any boot archive
####     did come code cleanup
####
####
#### script template History
#### -----------------------
####   1.22.0 08.06.2006 /bs  (BigAdmin Version 1)
####     public release; starting history for the script template
####
####   1.22.1 12.06.2006 /bs
####      added true/false to CheckYNParameter and ConvertToYesNo
#### 
####   1.22.2. 21.06.2006 /bs
####      added the parameter -V
####      added the use of environment variables
####      added the variable __NO_TIME_STAMPS
####      added the variable __NO_HEADERS
####      corrected a bug in the function executeCommandAndLogSTDERR
####      added missing return commands
####
####   1.22.3 24.06.2006 /bs
####      added the function StartStop_LogAll_to_logfile
####      added the variable __USE_TTY (used in AskUser)
####      corrected an spelling error (dev/nul instead of /dev/null)
####
####   1.22.4 06.07.2006 /bs
####      corrected a bug in the parameter error handling routine
####
####   1.22.5 27.07.2006 /bs
####      corrected some minor bugs
####
####   1.22.6 09.08.2006 /bs
####      corrected some minor bugs
####
####   1.22.7 17.08.2006 /bs
####      add the CheckParameterCount function
####      added the parameter -T 
####      added long parameter support (e.g --help)
####
####   1.22.8 07.09.2006 /bs
####      added code to save the env variable LANG and set it temporary to C
####
####   1.22.9 20.09.2006 /bs
####      corrected code to save the env variable LANG and set it temporary to C
####   
####   1.22.10 21.09.2006 /bs
####      cleanup comments
####      the number of temporary files created automatically is now variable 
####        (see the variable __NO_OF_TEMPFILES)
####      added code to install the trap handler in all functions
####
####   1.22.11 19.10.2006 /bs
####      corrected a minor bug in AskUser (/c was not interpreted by echo)
####      corrected a bug in the handling of the parameter -S (-S was ignored)
####
####   1.22.12 31.10.2006 /bs
####      added the variable __REQUIRED_ZONE
####
####   1.22.13 13.11.2006 /bs
####      the template now uses TMP or TEMP if set for the temporary files
####
####   1.22.14 14.11.2006 /bs
####      corrected a bug in the function AskUser (the default was y not n)
####
####   1.22.15 21.11.2006 /bs
####      added initial support for other Operating Systems
####
####   1.22.16 05.07.2007 /bs
####      enhanced initial support for other Operating Systems
####      Support for other OS is still not fully tested!
####
####   1.22.17 06.07.2007 /bs
####      added the global variable __TRAP_SIGNAL
####
####   1.22.18 01.08.2007 /bs
####      __OS_VERSION and __OS_RELEASE were not set - corrected
####
####   1.22.19 04.08.2007 /bs
####      wrong function used to print "__TRAP_SIGNAL is \"${__TRAP_SIGNAL}\"" - fixed
####
####   1.22.20 12.09.2007 /bs
####      the script now checks the ksh version if running on Solaris
####      made some changes for compatibility with ksh93
####
####   1.22.21 18.09.2007 /bs (BigAdmin Version 2)
####      added the variable __FINISHROUTINES
####      changed __REQUIRED_ZONE to __REQUIRED_ZONES
####      added the variable __KSH_VERSION
####      reworked the trap handling
####
####   1.22.22 23.09.2007 /bs 
####      added the signal handling for SIGUSR1 and SIGUSR2 (variables __SIGUSR1_FUNC and __SIGUSR2_FUNC)
####      added user defined function for the signals HUP, BREAK, TERM, QUIT, EXIT, USR1 and USR2
####      added the variables __WARNING_PREFIX, __ERROR_PREFIX,  __INFO_PREFIX, and __RUNTIME_INFO_PREFIX
####      the parameter -T or --tee can now be on any position in the parameters
####      the default output file if called with -T or --tee is now
####        /var/tmp/${0##*/}.$$.tee.log
####
####   1.22.23 25.09.2007 /bs 
####      added the environment variables __INFO_PREFIX, __WARNING_PREFIX,
####      __ERROR_PREFIX, and __RUNTIME_INFO_PREFIX
####      added the environment variable __DEBUG_HISTFILE
####      reworked the function to print the usage help :
####      use "-h -v" to view the extented usage help and use "-h -v -v" to 
####          view the environment variables used also
####
####   1.22.24 05.10.2007 /bs 
####      another minor fix for ksh93 compatibility
#### 
####   1.22.25 08.10.2007 /bs 
####      only spelling errors corrected
####
####   1.22.26 19.11.2007 /bs 
####      only spelling errors corrected
####
####   1.22.27 29.12.2007 /bs 
####      improved the code to create the lockfile (thanks to wpollock for the info; see credits above)
####      improved the code to create the temporary files (thanks to wpollock for the info; see credits above)
####      added the function rand (thanks to wpollock for the info; see credits above)
####      the script now uses the directory name saved in the variable $TMPDIR for temporary files 
####      if it's defined
####      now the umask used for creating temporary files can be changed (via variable __TEMPFILE_UMASK)
####
####   1.22.28 12.01.2008 /bs 
####      corrected a syntax error in the show usage routine
####      added the function PrintWithTimestamp (see credits above)
####
####   1.22.29 31.01.2008 /bs 
####      there was a bug in the new code to remove the lockfile which prevented
####      the script from removing the lockfile at program end
####      if the lockfile already exist the script printed not the correct error
####      message
####
####   1.22.30 28.02.2008 /bs 
####      Info update: executeCommandAndLog does NOT return the RC of the executed
####      command if a logfile is defined
####      added inital support for CYGWIN 
####      (tested with CYGWIN_NT-5.1 v..1.5.20(0.156/4/2)
####      Most of the internal functions are NOT tested yet in CYGWIN
####      GetCurrentUID now supports UIDs greater than 254; the function now prints the UID to STDOUT  
####      Corrected bug in GetUserName (only a workaround, not the solution)
####      now using printf in the AskUserRoutine
####
####   1.22.30 28.02.2008 /bs 
####    The lockfile is now also deleted if the script crashes because of a syntax error or something like this
####
####   1.22.31 18.03.2008 /bs 
####     added the version number to the start and end messages
####     an existing config file is now removed (and not read) if the script is called with -C to create a config file
####
####   1.22.32 04.04.2008 /bs 
####     minor changes for zone support
####
####   1.22.33 12.02.2009 /bs 
####     disabled the usage of prtdiag due to the fact that prtdiag on newer Sun machines needs a long time to run
####     (-> __MACHINE_SUBTYPE is now always empty for Solaris machines)
####     added the variable __CONFIG_FILE_FOUND; this variable contains the name of the config file
####     read if a config file was found
####     added the variable __CONFIG_FILE_VERSION 
####
####   1.22.34 28.02.2009 /bs 
####     added code to check for the max. line no for the debug handler 
####    (an array in ksh88 can only handle up to 4096 entries)
####    added the variable __PIDFILE
####
####  1.22.35 06.04.2009 /bs
####     added the variables 
####       __NO_CLEANUP
####       __NO_EXIT_ROUTINES
####       __NO_TEMPFILES_DELETE
####       __NO_TEMPMOUNTS_UMOUNT
####       __NO_TEMPDIR_DELETE
####       __NO_FINISH_ROUTINES
####       __CLEANUP_ON_ERROR
####       CONFIG_FILE
####
####  1.22.36 11.04.2009 /bs
####    corrected a cosmetic error in the messages (wrong: ${TEMPFILE#} correct: ${__TEMPFILE#})
####
####  1.22.37 08.07.2011
####    corrected a minor error with the QUIET parameter
####    added code to dump the environment (env var __CREATE_DUMP, function CreateDump )
####    implemented work around for missing function whence in bash
####    added the function LogIfNotVerbose
####
####  1.22.38 22.07.2011
####    added code to make the trap handling also work in bash
####    added a sample user defined trap handler (function USER_SIGNAL_HANDLER)
####    added the function SetHousekeeping to enabe or disable house keeping
####    scriptt.sh did not write all messages to the logfile if a relative filename was used - fixed
####    added more help text for "-v -v -v -h"
####    now user defined signal handler can have arguments
####    the RBAC feature (__USE_RBAC) did not work as expected - fixed
####    added new scriptt testsuite for testing the script template on other OS and/or shells
####    added the function SaveEnvironmentVariables
#### 
####  1.22.39 24.07.2011
####    __INIT_FUNCTION now enable for cygwin also
####    __SHELL did not work in all Unixes - fixed
####    __OS_FULLNAME is now also set in Solaris and Linux
####
####  1.22.40 25.07.2011
####    added some code for ksh93 (functions: substr)
####    Note: set __USE_ONLY_KSH88_FEATURES to ${__TRUE} to suppress using the ksh93 features
####    The default action for the signal handler USR1 is now "Create an env dump in /var/tmp"
####    The filenames for the dumps are 
####        
####      /var/tmp/<scriptname>.envvars.dump_no_<no>_<PID>
####      /var/tmp/<scriptname>.exported_envvars.dump_no_<no>_<PID>
####
####    where <no> is a sequential number, <PID> is the PID of the process with the script,
####    and <scriptname> is the name of the script without the path.
####
####  1.22.41 26.09.2011
####    added the parameter -X
####    disabled some ksh93 code because "ksh -x -n" using ksh88 does not like it
####
####  1.22.42 05.10.2011
####   added the function PrintDotToSTDOUT
####

#### ----------------                                         
#### Version variables
####
#### __SCRIPT_VERSION - the version of your script 
####
####
typeset  -r __SCRIPT_VERSION="v1.0.0"
####

#### __SCRIPT_TEMPLATE_VERSION - version of the script template
####
typeset -r __SCRIPT_TEMPLATE_VERSION="1.22.42 05.10.2011"
####

#### ----------------
####
##R# Predefined return codes:
##R# ------------------------
##R#
##R#    1 - show usage and exit
##R#    2 - invalid parameter found
##R#
##R#  210 - 235 reserved for the runtime system
##R#  236 - syntax error 
##R#  237 - script file has to many lines for the debug handler
##R#  238 - unsupported Operating system
##R#  239 - script runs in a not supported zone
##R#  240 - internal error
##R#  241 - a command ended with an error (set -e is necessary to activate this trap)
##R#  242 - the current user is not allowed to execute this script
##R#  243 - invalid machine architecture
##R#  244 - invalid processor type
##R#  245 - invalid machine platform
##R#  246 - error writing the config file
##R#  247 - include script not found
##R#  248 - unsupported OS version
##R#  249 - Script not executed by root
##R#  250 - Script is already running
##R#
##R#  251 - QUIT signal received
##R#  252 - User break
##R#  253 - TERM signal received
##R#  254 - unknown external signal received
##R#

#### ----------------
#### Used environment variables
####
#
# The variable __USED_ENVIRONMENT_VARIABLES is used in the function ShowUsage
#
__USED_ENVIRONMENT_VARIABLES="
#### __DEBUG_CODE
#### __RT_VERBOSE_LEVEL
#### __QUIET_MODE
#### __VERBOSE_MODE
#### __VERBOSE_LEVEL
#### __OVERWRITE_MODE
#### __USER_BREAK_ALLOWED
#### __NO_TIME_STAMPS
#### __NO_HEADERS
#### __USE_COLORS
#### __USE_RBAC
#### __RBAC_BINARY
#### __TEE_OUTPUT_FILE
#### __INFO_PREFIX
#### __WARNING_PREFIX
#### __ERROR_PREFIX
#### __RUNTIME_INFO_PREFIX
#### __DEBUG_HISTFILE
#### __NO_CLEANUP
#### __NO_EXIT_ROUTINES
#### __NO_TEMPFILES_DELETE
#### __NO_TEMPMOUNTS_UMOUNT
#### __NO_TEMPDIR_DELETE
#### __NO_FINISH_ROUTINES
#### __CLEANUP_ON_ERROR
#### __CREATE_DUMP
#### __DUMP_ALREADY_CREATED
#### __DUMPDIR
#### __USE_ONLY_KSH88_FEATURES
#### CONFIG_FILE
"
####

#
# binaries and scripts used in this script:
#
# basename cat cp cpio cut date dd dirname egrep expr find grep id ln ls nawk pwd 
# reboot rm sed sh tee touch tty umount uname who zonename
#
# ksh if running in a shell without builtin whence
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

#### ----------------
#### ##### general hints
####
#### Do not use variable names beginning with __ (these are reserved for
#### internal use)
####

# save the language setting and switch the language temporary to C
#
__SAVE_LANG="${LANG}"
LANG=C
export LANG

# -----------------------------------------------------------------------------
#### ##### constants
####
#### __TRUE - true (0)
#### __FALSE - false (1)
####
####
typeset -r __TRUE=0
typeset -r __FALSE=1

# -----------------------------------------------------------------------------
#### __KSH_VERSION - ksh version (either 88 or 93)
####  If the script is not executed by ksh the shell is compatible to 
###   ksh version $__KSH_VERSION
####
  __KSH_VERSION=88 ; f() { typeset __KSH_VERSION=93 ; } ; f ; 

# use ksh93 features?
#
if [ "${__KSH_VERSION}"x = "93"x ] ; then
  __USE_ONLY_KSH88_FEATURES=${__USE_ONLY_KSH88_FEATURES:=${__FALSE}}
else
  __USE_ONLY_KSH88_FEATURES=${__USE_ONLY_KSH88_FEATURES:=${__TRUE}}
fi

#### __OS - Operating system (e.g. SunOS)
####
__OS="$( uname -s )"


# -----------------------------------------------------------------------------
# specific settings for the various operating systems and shells
#

case ${__OS} in 
  CYGWIN* )  
    set +o noclobber
    __SHELL_FIELD=9
    ;;

  SunOS | AIX )
    __SHELL_FIELD=9  
    ;;
  
  * )
    __SHELL_FIELD=8
    ;;

esac


# -----------------------------------------------------------------------------
# specific settings for various shells
#

#### __SHELL - name of the current shell executing this script
####
__SHELL="$( ps -f -p $$ | grep -v PID | tr -s " " | cut -f${__SHELL_FIELD} -d " " )"
__SHELL=${__SHELL##*/}

: ${__SHELL:=ksh}

case "${__SHELL}" in

  "bash" )
# set shell options for alias expanding if running in bash
    shopt -s expand_aliases
    ;;

esac


# -----------------------------------------------------------------------------
# define whence if necessary
#
whence whence 2>/dev/null 1>/dev/null || function whence { ksh whence -p $* ; }

# -----------------------------------------------------------------------------

#### ----------------
#### internal variables
####
#### __TRAP_SIGNAL - current trap caught by the trap handler
####   This is a global variable that can be used in the exit routines
####
__TRAP_SIGNAL=""


# -----------------------------------------------------------------------------
#### __USE_RBAC - set this variable to ${__TRUE} to execute this script 
####   with RBAC
####   default is ${__FALSE}
####
####   Note: You can also set this environment variable before starting the script
####
: ${__USE_RBAC:=${__FALSE}}

# -----------------------------------------------------------------------------
#### __RBAC_BINARY - pfexec binary
####   
####   default is /usr/bin/pfexec
####
####   Note: You can also set this environment variable before starting the script
####
: ${__RBAC_BINARY:=/usr/bin/pfexec}

# -----------------------------------------------------------------------------
#
# user executing this script (works only if using a ssh session with specific
# ssh versions that export these variables!)
#
SCRIPT_USER="$(  echo $SSH_ORIGINAL_USER  | tr "=" " " | cut -f 5 -d " " )" 
SCRIPT_USER_MSG="${SCRIPT_USER}"

# -----------------------------------------------------------------------------
#### __TEE_OUTPUT_FILE - name of the output file if called with the parameter -T
####   default: /var/tmp/$( basename $0 ).$$.tee.log
####
####   Note: You can also set this environment variable before starting the script
####
: ${__TEE_OUTPUT_FILE:=/var/tmp/${0##*/}.$$.tee.log}

# -----------------------------------------------------------------------------
# process the parameter -q or --quiet
#
if [[ \ $*\  == *\ -q* || \ $*\  == *\ --quiet\ * ]] ; then
  __NO_HEADERS=${__TRUE}
  __QUIET_MODE=${__TRUE}
fi

# -----------------------------------------------------------------------------
# config file found or not
#
__CONFIG_FILE_FOUND=""
        
# -----------------------------------------------------------------------------
# use the parameter -T or --tee to automatically call the script and pipe 
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

: ${__PPID:=$PPID} ; export __PPID

# -----------------------------------------------------------------------------
#
# Set the variable ${__USE_RBAC} to ${__TRUE} to activate RBAC support
#
# Allow the use of RBAC to control who can access this script. Useful for
# administrators without root permissions
#
if [ "${__USE_RBAC}" = "${__TRUE}" ] ; then
  if [ "$_" != "${__RBAC_BINARY}" -a -x "${__RBAC_BINARY}" ]; then
    __USE_RBAC=${__FALSE} "${__RBAC_BINARY}" $0 $*
    exit $?
  else
    echo "${0%%*/} ERROR: \"${__RBAC_BINARY}\" not found or not executable!" >&2 
    exit 238 
  fi
fi

# -----------------------------------------------------------------------------
#### 
#### ##### defined variables that may be changed
####

#### __DEBUG_CODE - code executed at start of every sub routine
####   Note: Use always "__DEBUG_CODE="eval ..." if you want to use variables or aliases
####         Default debug code : none
####
#  __DEBUG_CODE=""

#### __FUNCTION_INIT - code executed at start of every sub routine
####   (see the hints for __DEBUG_CODE)
####         Default init code : install the trap handlers
####
#  __FUNCTION_INIT=" eval __settrap; echo  \"Now in function \${__FUNCTION}\" "
  __FUNCTION_INIT=" eval __settrap "
 
 ## variables for debugging
 ##
 ## __NO_CLEANUP - do not call the cleanup routine at all at script end if ${__TRUE}
 ##
 : ${__NO_CLEANUP:=${__FALSE}}
 
#### __NO_EXIT_ROUTINES  - do not execute the exit routines if ${__TRUE}
####
: ${__NO_EXIT_ROUTINES:=${__FALSE}}

#### __NO_TEMPFILES_DELETE - do not remove temporary files at script end if ${__TRUE}
####
: ${__NO_TEMPFILES_DELETE:=${__FALSE}}

#### __NO_TEMPMOUNTS_UMOUNT - do not umount temporary mount points at script end if ${__TRUE}
####
: ${__NO_TEMPMOUNTS_UMOUNT:=${__FALSE}}

#### __NO_TEMPDIR_DELETE - do not remove temporary directories at script end if ${__TRUE}
####
: ${__NO_TEMPDIR_DELETE:=${__FALSE}}

#### __NO_FINISH_ROUTINES - do not execute the finish routeins at script end if ${__TRUE}
####
: ${__NO_FINISH_ROUTINES:=${__FALSE}}

#### __CLEANUP_ON_ERROR - call cleanup if the script was aborted by a syntax error 
####
: ${__CLEANUP_ON_ERROR:=${__FALSE}}


####
#### sample debug code:
#### __DEBUG_CODE="  eval echo Entering the subroutine \${__FUNCTION} ...  "
####
#### Note: Use an include script for more complicate debug code, e.g.
#### __DEBUG_CODE=" eval . /var/tmp/mydebugcode"
####

#### __CONFIG_PARAMETER
####   The variable __CONFIG_PARAMETER contains the configuration variables
####
#### The defaults for these variables are defined here. You 
#### can use a config file to overwrite the defaults. 
####
#### Use the parameter -C to create a default configuration file
####
#### Note: The config file is read and interpreted via ". configfile"  
####       therefore you can also add some code her
####
__CONFIG_PARAMETER="__CONFIG_FILE_VERSION=\"${__SCRIPT_VERSION}\"
"'

# extension for backup files

  DEFAULT_BACKUP_EXTENSION=".$$.backup"

#### DEFAULT_MOUNT_POINT - default mount point to mount the temporary boot_archive
####
  DEFAULT_MOUNT_POINT_TEMPLATE="/tmp/boot_archive."
  DEFAULT_MOUNT_POINT="${DEFAULT_MOUNT_POINT_TEMPLATE}.$$"

# this script can run on x86 and SPARC
#

#### DEFAULT_BOOT_ARCHIVE - default boot archive to use
####
  case  ${__MACHINE_CLASS} in
    sun4u | sun4us | sun4v )
      DEFAULT_BOOT_ARCHIVE="/platform/${__MACHINE_CLASS}/boot_archive"
      ;;

    i86pc | i86xpv )
      BOOT_ARCHIVE_32="/platform/${__MACHINE_CLASS}/boot_archive"
      BOOT_ARCHIVE_64="/platform/${__MACHINE_CLASS}/amd64/boot_archive"

      if [ "$( isainfo -b  )"x = "32"x ] ; then
        DEFAULT_BOOT_ARCHIVE="${BOOT_ARCHIVE_32}"
      else
        [ -f "${BOOT_ARCHIVE_64}" ] && DEFAULT_BOOT_ARCHIVE="${BOOT_ARCHIVE_64}" || DEFAULT_BOOT_ARCHIVE="${BOOT_ARCHIVE_32}"
      fi
      ;;

# unknown machine architecture
    * )
      DEFAULT_BOOT_ARCHIVE=""
      ;;
  esac

#### __DUMP_ALREADY_CREATED - do not automatically create another dump if 
####   this variable is ${__TRUE}
####
#    __DUMP_ALREADY_CREATED=${__TRUE}


#### __CREATE_DUMP - create an environment dump if the scripts exits with
####   error
####   (replace <dumpdir> with either 0 or the directory for 
####   the dumps) to always create a dump at script end
####
#    __CREATE_DUMP=<dumpdir>

#### DEFAULT_DUMPDIR - default directory for environment dumps
####
  DEFAULT_DUMP_DIR="${TMPDIR:-${TMP:-${TEMP:-/tmp}}}"

# only change the following variables if you know what you are doing #


# no further internal variables defined yet
#
# Note you can redefine any variable that is initialized before calling
# ReadConfigFile here!
'
# end of config parameters

#### __SHORT_DESC - short description (for help texts, etc)
####   Change to your need
####
typeset -r __SHORT_DESC="view the contents of a Solaris boot archive for SPARC or x86"

#### __LONG_USAGE_HELP - Additional help if the script is called with 
####   the parameter "-v -h"
####
####   Note: To use variables in the help text use the variable name without
####         an escape character, eg. ${OS_VERSION}
####
__LONG_USAGE_HELP='
      -m mountpoint
         use this mount point to mount the boot archive

      mount
        mount a boot archive
      umount 
        umount a boot archive
      status 
        show the status (mounted/not mounted) of a boot archive

      boot_archive
        name of the boot archive to use
        This parameter is optional; the default is the boot archive for the current architecture

'

#### __SHORT_USAGE_HELP - Additional help if the script is called with the parameter "-h"
####
####   Note: To use variables in the help text use the variable name without an escape
####         character, eg. ${OS_VERSION}
####
__SHORT_USAGE_HELP='
                    [-m mountpoint] [mount|umount|status] {boot_archive}
'


#### __MUST_BE_ROOT - run script only by root (def.: false)
####   set to ${__TRUE} for scripts that must be executed by root only
####
__MUST_BE_ROOT=${__TRUE}

#### __REQUIRED_USERID - required userid to run this script (def.: none)
####   use blanks to separate multiple userids
####   e.g. "oracle dba sysdba"
####   "" = no special userid required
####
__REQUIRED_USERID=""

#### __REQUIRED_ZONES - required zones (either global, non-global or local 
####    or the names of the valid zones)
####   (def.: none) 
####   "" = no special zone required
####
__REQUIRED_ZONES="global"

#### __ONLY_ONCE - run script only once at a time (def.: false)
####   set to ${__TRUE} for scripts that can not run more than one instance at 
####   the same time
####
__ONLY_ONCE=${__FALSE}

#### __ REQUIRED_OS - required OS (uname -s) for the script (def.: none)
####    use blanks to separate the OS names if the script runs under multiple OS
####    e.g. "SunOS"
####
__REQUIRED_OS="SunOS"

#### __REQUIRED_OS_VERSION - required OS version for the script (def.: none)
####   minimum OS version necessary, e.g. 5.10
####   "" = no special version necessary
####
__REQUIRED_OS_VERSION="5.10"

#### __REQUIRED_MACHINE_PLATFORM - required machine platform for the script (def.: none)
####   required machine platform (uname -i) , e.g "i86pc"; use blanks to separate 
####   the multiple machine types, e.g "Sun Fire 3800 i86pc"
####   "" = no special machine type necessary
####
__REQUIRED_MACHINE_PLATFORM=""

#### __REQUIRED_MACHINE_CLASS - required machine class for the script (def.: none)
####   required machine class (uname -m) , e.g "i86pc" ; use blanks to separate  
####   the multiple machine classes, e.g "sun4u i86pc"
####   "" = no special machine class necessary
####
__REQUIRED_MACHINE_CLASS=""

#### __REQUIRED_MACHINE_ARC - required machine architecture for the script (def.: none)
####   required machine architecture (uname -p) , e.g "i386" ; use blanks to separate 
####   the machine architectures if more than one entry, e.g "sparc i386"
####   "" = no special machine architecture necessary
####
__REQUIRED_MACHINE_ARC=""

#### __VERBOSE_LEVEL - count of -v parameter (def.: 0)
####
####   Note: You can also set this environment variable before starting the script
####
typeset -i __VERBOSE_LEVEL=${__VERBOSE_LEVEL:=0}

#### __RT_VERBOSE_LEVEL - level of -v for runtime messages (def.: 1)
####
####   e.g. 1 = -v -v is necessary to print info messages of the runtime system
####        2 = -v -v -v is necessary to print info messages of the runtime system
####
####   Note: You can also set this environment variable before starting the script
####
typeset -i __RT_VERBOSE_LEVEL=${__RT_VERBOSE_LEVEL:=1}

#### __QUIET_MODE - do not print messages to STDOUT (def.: false)
####   use the parameter -q/+q to change this variable
####
####   Note: You can also set this environment variable before starting the script
####
: ${__QUIET_MODE:=${__FALSE}}

#### __VERBOSE_MODE - print verbose messages (def.: false)
####   use the parameter -v/+v to change this variable  
####
####   Note: You can also set this environment variable before starting the script
####
: ${__VERBOSE_MODE:=${__FALSE}}

#### __NO_TIME_STAMPS - Do not use time stamps in the messages (def.: false)
####
####   Note: You can also set this environment variable before starting the script
####
: ${__NO_TIME_STAMPS:=${__FALSE}}

#### __NO_HEADERS - Do not print headers and footers (def.: false)
####
####   Note: You can also set this environment variable before starting the script
####
: ${__NO_HEADERS:=${__FALSE}}

#### __FORCE - do the action anyway (def.: false)
####   If this variable is set to ${__TRUE} the function "die" will return 
####   if called with an RC not zero (instead of aborting the script)
####   use the parameter -f/+f to change this variable
####
__FORCE=${__FALSE}

#### __USE_COLORS - use colors (def.: false) 
####   use the parameter -a/+a to change this variable
####
####   Note: You can also set this environment variable before starting the script
####
: ${__USE_COLORS:=${__FALSE}}

#### __USER_BREAK_ALLOWED - CTRL-C aborts the script or not (def.: true)
####   (no parameter to change this variable)
####
####   Note: You can also set this environment variable before starting the script
####
: ${__USER_BREAK_ALLOWED:=${__TRUE}}

#### __NOECHO - turn echo off while reading input from the user
####   do not echo the user input in AskUser if __NOECHO is set to ${__TRUE}
####
__NOECHO=${__FALSE}

#### __USE_TTY - write prompts and read user input from /dev/tty (def.: false)
####   If __USE_TTY is ${__TRUE} the function AskUser writes the prompt to /dev/tty 
####   and the reads the user input from /dev/tty . This is useful if STDOUT is 
####   redirected to a file.
####
__USE_TTY=${__FALSE}

#### __OVERWRITE mode - overwrite existing files or not (def.: false)
####   use the parameter -O/+O to change this variable
####
####   Note: You can also set this environment variable before starting the script
####
: ${__OVERWRITE_MODE:=${__FALSE}}

#### __DEBUG_MODE - use single step mode for main (def.: false)
####   use the parameter -D/+D to change this variable
####
__DEBUG_MODE=${__FALSE}
__SCRIPT_ARRAY[0]=0

#### __TEMPDIR - directory for temporary files
####   The default is $TMPDIR (if defined), or $TMP (if defined), 
####   or $TEMP (if defined) or /tmp if none of the variables is
####   defined
####
__TEMPDIR="${TMPDIR:-${TMP:-${TEMP:-/tmp}}}"

#### __NO_OF_TEMPFILES
####   number of automatically created tempfiles that are deleted at program end
####   (def. 2)
####   Note: The variable names for the tempfiles are __TEMPFILE1, __TEMPFILE2, etc.
####
__NO_OF_TEMPFILES=2

#### __TEMPFILE_UMASK 
####   umask for creating temporary files (def.: 177)
####
__TEMPFILE_UMASK=177

#### __LIST_OF_TMP_MOUNTS - list of mounts that should be umounted at program end
####
__LIST_OF_TMP_MOUNTS=""

#### __LIST_OF_TMP_DIRS - list of directories that should be removed at program end
####
__LIST_OF_TMP_DIRS=""

#### __LIST_OF_TMP_FILES - list of files that should be removed at program end
####
__LIST_OF_TMP_FILES=""

#### __EXITROUTINES - list of routines that should be executed before the script ends
####   Note: These routines are called *before* temp files, temp directories, and temp 
####         mounts are removed
####
__EXITROUTINES=""

#### __FINISHROUTINES - list of routines that should be executed before the script ends
####   Note: These routines are called *after* temp files, temp directories, and temp
####         mounts are removed
####
__FINISHROUTINES=""

#### __SIGNAL_SIGUSR1_FUNCTION  - name of the function to execute if the signal SIGUSR1 is received
####   default signal handling: none
####
####   If a user defined function ends with a return code not equal zero the default 
####   action for the SIGUSR1 signal is not executed.
####
####   see USER_SIGNAL_HANDLER for an example user signal handler
####
 __SIGNAL_SIGUSR1_FUNCTION=""

#### __SIGNAL_SIGUSR2_FUNCTION  - name of the function to execute if the signal SIGUSR2 is received
####   default signal handling: none
####
####   If a user defined function ends with a return code not equal zero the default 
####   action for the SIGUSR2 signal is not executed.
####
####   see USER_SIGNAL_HANDLER for an example user signal handler
####
 __SIGNAL_SIGUSR2_FUNCTION=""

#### __SIGNAL_SIGHUP_FUNCTION  - name of the function to execute if the signal SIGHUP is received
####   default signal handling: switch the verbose mode on or off
####
####   If a user defined function ends with a return code not equal zero the default 
####   action for the SIGHUP signal is not executed.
####
####   see USER_SIGNAL_HANDLER for an example user signal handler
####
 __SIGNAL_SIGHUP_FUNCTION=""

#### __SIGNAL_SIGINT_FUNCTION  - name of the function to execute if the signal SIGINT is received
####   default signal handling: end the script if __USER_BREAK_ALLOWED is ${__TRUE} else ignore the signal
####
####   If a user defined function ends with a return code not equal zero the default 
####   action for the SIGINT signal is not executed.
####
####   see USER_SIGNAL_HANDLER for an example user signal handler
####
 __SIGNAL_SIGINT_FUNCTION=""

#### __SIGNAL_SIGQUIT_FUNCTION  - name of the function to execute if the signal SIGQUIT is received
####   default signal handling: end the script
####
####   If a user defined function ends with a return code not equal zero the default 
####   action for the SIGQUIT signal is not executed.
####
####   see USER_SIGNAL_HANDLER for an example user signal handler
####
 __SIGNAL_SIGQUIT_FUNCTION=""

#### __SIGNAL_SIGTERM_FUNCTION  - name of the function to execute if the signal SIGTERM is received
####   default signal handling: end the script
####
####   If a user defined function ends with a return code not equal zero the default 
####   action for the SIGTERM signal is not executed.
####
####   see USER_SIGNAL_HANDLER for an example user signal handler
####
 __SIGNAL_SIGTERM_FUNCTION=""

#### __REBOOT_REQUIRED - set to true to reboot automatically at 
####   script end (def.: false)
####
__REBOOT_REQUIRED=${__FALSE}

#### __REBOOT_PARAMETER - parameter for the reboot command (def.: none)
####
__REBOOT_PARAMETER=""

#### __INFO_PREFIX - prefix for INFO messages printed if __VERBOSE_MODE = ${__TRUE}
####   default: "INFO: "
####
: ${__INFO_PREFIX:=INFO: }

#### __WARNING_PREFIX - prefix for WARNING messages 
####   default: "WARNING: "
####
: ${__WARNING_PREFIX:=WARNING: }

#### __ERROR_PREFIX - prefix for ERROR messages 
####   default: "ERROR: "
####
: ${__ERROR_PREFIX:=ERROR: }

#### __RUNTIME_INFO_PREFIX - prefix for INFO messages of the runtime system
####   default: "RUNTIME INFO: "
####
: ${__RUNTIME_INFO_PREFIX:=RUNTIME INFO: }

#### __PRINT_LIST_OF_WARNINGS_MSGS - print the list of warning messages at program end (def.: false)
####
__PRINT_LIST_OF_WARNINGS_MSGS=${__FALSE}

#### __PRINT_LIST_OF_ERROR_MSGS - print the list of error messages at program end (def.: false)
####
__PRINT_LIST_OF_ERROR_MSGS=${__FALSE}

#### __PRINT_SUMMARIES - print error/warning msg summaries at script end
####
####   print error and/or warning message summaries at program end
####   known values:
####       0 = do not print summaries
####       1 = print error msgs
####       2 = print warning msgs
####       3 = print error and warning mgs
####   use the parameter -S to change this variable
####
__PRINT_SUMMARIES=0

#### __MAINRC - return code of the program 
####
__MAINRC=0

# -----------------------------------------------------------------------------
#

# -----------------------------------------------------------------------------
# init the global variables
#

#### ##### defined variables that should not be changed
####

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

: ${__DEBUG_HISTFILE:-/tmp/ksh.history.$$}

# delete the history file used in the debug routine at program end
__LIST_OF_TMP_FILES="${__LIST_OF_TMP_FILES} ${__DEBUG_HISTFILE}"

# variable used for input by the user
#
__USER_RESPONSE_IS=""

# __STTY_SETTINGS
#   saved stty settings before switching off echo in AskUser
#
__STTY_SETTINGS=""

#### __SCRIPTNAME - name of the script without the path
####
typeset -r __SCRIPTNAME="${0##*/}"

#### __SCRIPTDIR - path of the script (as entered by the user!)
####
__SCRIPTDIR="${0%/*}"

#### __REAL_SCRIPTDIR - path of the script (real path, maybe a link)
####
__REAL_SCRIPTDIR=$( cd -P -- "$(dirname -- "$(command -v -- "$0")")" && pwd -P )

#### __CONFIG_FILE - name of the default config file
####   (use ReadConfigFile to read the config file; 
####   use WriteConfigFile to write it)
####
__CONFIG_FILE="${__SCRIPTNAME%.*}.conf"

#### __PIDFILE - save the pid of the script in a file
####
#### example usage: __PIDFILE="/tmp/${__SCRIPTNAME%.*}.pid"
__PIDFILE=""

#### __HOSTNAME - hostname 
####
__HOSTNAME="$( uname -n )"

#### __NODENAME - nodename 
####
__NODENAME=${__HOSTNAME}
[ -f /etc/nodename ] && __NODENAME="$( cat /etc/nodename )"

#### __OS_FULLNAME - Operating system (e.g. CYGWIN_NT-5.1)
####   (only used for CYGWIN at this time)
####
__OS_FULLNAME=""

#### __ZONENAME - name of the current zone if running in Solaris 10 or newer
#### 

#### __OS_VERSION - Operating system version (e.g 5.8)
####

#### __OS_RELEASE - Operating system release (e.g. Generic_112233-08)
####

#### __MACHINE_CLASS - Machine class (e.g sun4u)
####

#### __MACHINE_PLATFORM - hardware platform (e.g. SUNW,Ultra-4)
####

#### __MACHINE_SUBTYPE - machine type (e.g  Sun Fire 3800)
####

#### __MACHINE_ARC - machine architecture (e.g. sparc)
####

#### __RUNLEVEL - current runlevel
####
# __RUNLEVEL="$( set -- $( who -r )  ; echo $7 )"

case ${__OS} in

    "SunOS" ) 
       [ -r /etc/release ] && __OS_FULLNAME="$( grep Solaris /etc/release | tr -s " " |  cut -f2- -d " " )"
       __ZONENAME="$( zonename 2>/dev/null )" 
       __OS_VERSION="$( uname -r )" 
       __OS_RELEASE="$( uname -v )"
       __MACHINE_CLASS="$( uname -m )"
       __MACHINE_PLATFORM="$( uname -i )"
       __MACHINE_SUBTYPE=""
#       if [ "${__ZONENAME}"x = ""x  -o  "${__ZONENAME}"x = "global"x ] ; then
#         [  -x /usr/platform/${__MACHINE_PLATFORM}/sbin/prtdiag ] &&   \
#           ( set -- $( /usr/platform/${__MACHINE_PLATFORM}/sbin/prtdiag | grep "System Configuration" ) ; shift 5; echo $* ) 2>/dev/null | read  __MACHINE_SUBTYPE
#        else
#         __MACHINE_SUBTYPE=""
#        fi
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
       [ -r /etc/lsb-release ] && eval __OS_FULLNAME="$( grep DISTRIB_DESCRIPTION= /etc/lsb-release | cut -f2- -d "=" )"
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

#### __START_DIR - working directory when starting the script
####
__START_DIR="$( pwd )"

#### __LOGFILE - fully qualified name of the logfile used
####   use the parameter -l to change the logfile
####
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

#### __NO_OF_WARNINGS - Number of warnings found
####
typeset -i __NO_OF_WARNINGS=0

#### __LIST_OF_WARNINGS - List of warning messages
####
__LIST_OF_WARNINGS=""

#### __NO_OF_ERRORS - Number of errors found
####
typeset -i __NO_OF_ERRORS=0

#### __LIST_OF_ERRORS - List of error messages
####
__LIST_OF_ERRORS=""

#### __LOGON_USERID - ID of the user opening the session  
####
__LOGIN_USERID="$( set -- $( who am i 2>/dev/null ) ; echo $1 )"
: ${__LOGIN_USERID:=${LOGNAME}}

#### __USERID - ID of the user executing this script (e.g. xtrnaw7)
####
__USERID="${__LOGIN_USERID}"
if [ "${__OS}"x = "SunOS"x ] ; then
  [ -x /usr/ucb/whoami ] && __USERID="$( /usr/ucb/whoami )"
else
  __USERID="$( whoami )"
fi

# -----------------------------------------------------------------------------
# color variables

#### Foreground Color variables:
#### __COLOR_FG_BLACK, __COLOR_FG_RED,     __COLOR_FG_GREEN, __COLOR_FG_YELLOW
#### __COLOR_FG_BLUE,  __COLOR_FG_MAGENTA, __COLOR_FG_CYAN,  __COLOR_FG_WHITE
####
#### Background Color variables:
#### __COLOR_BG_BLACK, __COLOR_BG_RED,     __COLOR_BG_GREEN, __COLOR_BG_YELLOW
#### __COLOR_BG_BLUE,  __COLOR_BG_MAGENTA, __COLOR_BG_CYAN,  __COLOR_BG_WHITE
####
if [ ${__USE_COLORS} = ${__TRUE} ] ; then
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

####
#### Colorattributes:
#### __COLOR_OFF, __COLOR_BOLD, __COLOR_NORMAL, - normal, __COLOR_UNDERLINE
#### __COLOR_BLINK, __COLOR_REVERSE, __COLOR_INVISIBLE
####

  __COLOR_BOLD="\033[1m"
  __COLOR_NORMAL="\033[2m"
  __COLOR_UNDERLINE="\033[4m"
  __COLOR_BLINK="\033[5m"
  __COLOR_REVERSE="\033[7m"
  __COLOR_INVISIBLE="\033[8m"
  __COLOR_OFF="\033[0;m"
fi

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

#### 
#### ##### defined sub routines
####

#### --------------------------------------
#### ReadConfigFile
####
#### read the config file
####
#### usage: ReadConfigFile [configfile]
####
#### where:   configfile - name of the config file
####          default: search ${__CONFIG_FILE} in the current directory,
####          in the home directory, and in /etc (in this order)
####
#### returns: ${__TRUE} - ok config read
####          ${__FALSE} - error config file not found or not readable
####
function ReadConfigFile {
  typeset __FUNCTION="ReadConfigFile"; ${__FUNCTION_INIT} ; ${__DEBUG_CODE}

  typeset THIS_CONFIG="$1"
  typeset THISRC=${__FALSE}
  
  if [ "${THIS_CONFIG}"x = ""x ] ; then
    THIS_CONFIG="$PWD/${__CONFIG_FILE}"
    [ ! -f "${THIS_CONFIG}" ] && THIS_CONFIG="${HOME}/${__CONFIG_FILE}"
    [ ! -f "${THIS_CONFIG}" ] && THIS_CONFIG="/etc/${__CONFIG_FILE}"
  fi

  if [ -f "${THIS_CONFIG}" ] ; then
    LogHeader "Reading the config file \"${THIS_CONFIG}\" ..." 

    includeScript "${THIS_CONFIG}"

    __CONFIG_FILE_FOUND="${THIS_CONFIG}"

    THISRC=${__TRUE}    
  else
    LogHeader "No config file (\"${__CONFIG_FILE}\") found (use -C to create a default config file)"
  fi

  return ${THISRC}
}

#### --------------------------------------
#### WriteConfigFile
####
#### write the variable ${__CONFIG_PARAMETER} to the config file
####
#### usage: WriteConfigFile [configfile]
####
#### where:  configfile - name of the config file
####         default: write ${__CONFIG_FILE} in the current directory
####
#### returns: ${__TRUE} - ok config file written
####          ${__FALSE} - error writing the config file
####
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

#### --------------------------------------
#### NoOfStackElements
####
#### return the no. of stack elements
####
#### usage: NoOfStackElements; var=$?
####
#### returns: no. of elements on the stack
####
#### Note: NoOfStackElements, FlushStack, push and pop use only one global stack!
####
function NoOfStackElements {
  typeset __FUNCTION="NoOfStackElements";  ${__FUNCTION_INIT} ; ${__DEBUG_CODE}

  return ${__STACK_POINTER}
}

#### --------------------------------------
#### FlushStack
####
#### flush the stack
####
#### usage: FlushStack
####
#### returns: no. of elements on the stack before flushing it
####
#### Note: NoOfStackElements, FlushStack, push and pop use only one global stack!
####
function FlushStack {
  typeset __FUNCTION="FlushStack";    ${__FUNCTION_INIT} ; ${__DEBUG_CODE}

  typeset THISRC=${__STACK_POINTER}
  __STACK_POINTER=0
  return ${THISRC}
}

#### --------------------------------------
#### push
####
#### push one or more values on the stack
####
#### usage: push value1 [...] [value#]
####
#### returns: 0
####
#### Note: NoOfStackElements, FlushStack, push and pop use only one global stack!
####
function push {
  typeset __FUNCTION="push";    ${__FUNCTION_INIT} ; ${__DEBUG_CODE}

   while [ $# -ne 0 ] ; do
    (( __STACK_POINTER=__STACK_POINTER+1 ))
    __STACK[${__STACK_POINTER}]="$1"
    shift
  done

  return 0
}

#### --------------------------------------
#### pop
####
#### pop one or more values from the stack
####
#### usage: pop variable1 [...] [variable#]
####
#### returns: 0
####
#### Note: NoOfStackElements, FlushStack, push and pop use only one global stack!
####
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

#### --------------------------------------
#### push_and_set
####
#### push a variable to the stack and set the variable to a new value
####
#### usage: push_and_set variable new_value
####
#### returns: 0
####
#### Note: NoOfStackElements, FlushStack, push and pop use only one global stack!
####
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

#### --------------------------------------
#### CheckYNParameter
####
#### check if a parameter is y, n, 0, or 1
####
#### usage: CheckYNParameter parameter
####
#### returns: ${__TRUE} - the parameter is equal to yes
####          ${__FALSE} - the parameter is equal to no
####
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

#### --------------------------------------
#### ConvertToYesNo
####
#### convert the value of a variable to y or n
####
#### usage: ConvertToYesNo parameter
####
#### returns: 0
####          prints y, n or ? to STDOUT
####
function ConvertToYesNo {
  typeset __FUNCTION="ConvertToYesNo";    ${__FUNCTION_INIT} ; ${__DEBUG_CODE}

  case $1 in
   "y" | "Y" | "yes" | "YES" | "true"  | "TRUE"  | 0 ) echo "y" ;;
   "n" | "N" | "no"  | "NO"  | "false" | "FALSE" | 1 ) echo "n" ;;
   * ) echo "?" ;;
  esac
  
  return 0
}

#### --------------------------------------
#### InvertSwitch
####
#### invert a switch from true to false or vice versa
####
#### usage: InvertSwitch variable
####
#### returns 0
####         switch the variable "variable" from ${__TRUE} to
####         ${__FALSE} or vice versa
####
function InvertSwitch {
  typeset __FUNCTION="InvertSwitch";    ${__FUNCTION_INIT} ; ${__DEBUG_CODE}

  eval "[ \$$1 -eq ${__TRUE} ] && $1=${__FALSE} || $1=${__TRUE} "
  
  return 0
}

#### --------------------------------------
#### CheckInputDevice
####
#### check if the input device is a terminal
####
#### usage: CheckInputDevice
####
#### returns: 0 - the input device is a terminal (interactive)
####          1 - the input device is NOT a terminal
####
function CheckInputDevice {
  typeset __FUNCTION="CheckInputDevice";    ${__FUNCTION_INIT} ; ${__DEBUG_CODE}

  tty -s
  return $?
}
  
#### --------------------------------------
#### GetProgramDirectory
####
#### get the directory where a program resides
####
#### usage: GetProgramDirectory [programpath/]programname [resultvar]
####
#### returns: 0
####          the variable PRGDIR contains the directory with the program
####          if the parameter resultvar is missing
####
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

#### --------------------------------------
#### substr
####
#### get a substring of a string
####
#### usage: variable=$( substr sourceStr pos length )
####     or substr sourceStr pos length resultStr
####
#### returns: 1 - parameter missing
####          0 - parameter okay
####
function substr {
  typeset __FUNCTION="substr";    ${__FUNCTION_INIT} ; ${__DEBUG_CODE}

  typeset resultstr=""
  typeset THISRC=1

  if [ "$1"x != ""x ] ; then 
    if [ "${__USE_ONLY_KSH88_FEATURES}"x = "${__TRUE}"x ] ; then
      LogRuntimeInfo "Using ksh88 syntax for substr"      
      
      typeset s="$1" p="$2" l="$3"
      : ${l:=${#s}}
      : ${p:=1}

      resultstr="$( echo $s | cut -c${p}-$((${p}+${l}-1)) )"
      THISRC=0
# ksh88 does not like this code (so ksh -x -n does not work with this code ) 26.09.2011/bs      
#    else
#      LogRuntimeInfo "Using ksh93 syntax for substr"  
#      
#      resultstr=${1:(( $2 -1 )):$3}
    fi
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

#### --------------------------------------
#### replacestr
####
#### replace a substring with another substring
####
#### usage: variable=$( replacestr sourceStr oldsubStr newsubStr )
####     or replacestr sourceStr oldsubStr newsubStr resultvariable
####
#### returns: 0 - substring replaced
####          1 - substring not found
####          3 - error, parameter missing
####
####          writes the substr to STDOUT if resultvariable is missing
####
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

#### --------------------------------------
#### pos
####
#### get the first position of a substring in a string
####
#### usage: pos searchstring sourcestring
####
#### returns: 0 - searchstring is not part of sourcestring
####          else the position of searchstring in sourcestring
####
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

#### --------------------------------------
#### lastpos
####
#### get the last position of a substring in a string
####
#### usage: lastpos searchstring sourcestring
####
#### returns: 0 - searchstring is not part of sourcestring
####          else the position of searchstring in sourcestring
####
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

#### --------------------------------------
#### isNumber
####
#### check if a value is an integer 
####
#### usage: isNumber testValue 
####
#### returns: ${__TRUE} - testValue is a number else not
####
function isNumber {
  typeset __FUNCTION="isNumber";    ${__FUNCTION_INIT} ; ${__DEBUG_CODE}

  typeset TESTVAR="$(echo "$1" | sed 's/[0-9]*//g' )"
  [ "${TESTVAR}"x = ""x ] && return ${__TRUE} || return ${__FALSE}
}

#### --------------------------------------
#### ConvertToHex
####
#### convert the value of a variable to a hex value
####
#### usage: ConvertToHex value
####
#### returns: 0
####          prints the value in hex to STDOUT
####
function ConvertToHex {
  typeset __FUNCTION="ConvertToHex";    ${__FUNCTION_INIT} ; ${__DEBUG_CODE}

  typeset -i16 HEXVAR
  HEXVAR="$1"
  echo ${HEXVAR##*#}
  
  return 0
}  

#### --------------------------------------
#### ConvertToOctal
####
#### convert the value of a variable to a octal value
####
#### usage: ConvertToOctal value
####
#### returns: 0
####          prints the value in octal to STDOUT
####
function ConvertToOctal {
  typeset __FUNCTION="ConvertToOctal";    ${__FUNCTION_INIT} ; ${__DEBUG_CODE}

  typeset -i8 OCTVAR
  OCTVAR="$1"
  echo ${OCTVAR##*#}
  
  return 0
}  

#### --------------------------------------
#### ConvertToBinary
####
#### convert the value of a variable to a binary value
####
#### usage: ConvertToBinary value
####
#### returns: 0
####          prints the value in binary to STDOUT
####
function ConvertToBinary {
  typeset __FUNCTION="ConvertToBinary";  ${__FUNCTION_INIT} ; ${__DEBUG_CODE}

  typeset -i2 BINVAR
  BINVAR="$1"
  echo ${BINVAR##*#}
  
  return 0
}  

#### --------------------------------------
#### toUppercase
####
#### convert a string to uppercase
####
#### usage: toUppercase sourceString | read resultString
####    or   targetString=$( toUppercase sourceString )
####    or   toUppercase sourceString resultString
####
#### returns: 0
####          writes the converted string to STDOUT if resultString is missing
####
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

#### --------------------------------------
#### toLowercase
####
#### convert a string to lowercase
####
#### usage: toLowercase sourceString | read resultString
####    or   targetString=$( toLowercase sourceString )
####    or   toLowercase sourceString resultString
####
#### returns: 0
####          writes the converted string to STDOUT if resultString is missing
####
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

#### --------------------------------------
#### StartStop_LogAll_to_logfile
####
#### redirect STDOUT and STDERR into a file
####
#### usage: StartStop_LogAll_to_logfile [start|stop] logfile
####
#### returns: 0 - okay, redirection started / stopped
####          1 - error, can not write to the logfile
####          2 - invalid usage (to much or not enough parameter)
####          3 - invalid parameter 
####
#### To explicitly write to STDOUT after calling this function with the 
#### parameter "start" use 
####   echo "This goes to STDOUT" >&3
####
#### To explicitly write to STDERR after calling this function with the 
#### parameter "start" use 
####   echo "This goes to STDERR" >&4
####
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

#### --------------------------------------
#### executeCommand
####
#### execute a command
####
#### usage: executeCommand command parameter
####
#### returns: the RC of the executed command
####
function executeCommand {
  typeset __FUNCTION="executeCommand";    ${__FUNCTION_INIT} ; ${__DEBUG_CODE}

  typeset THISRC=0

  set +e

  LogRuntimeInfo "Executing \"$@\" "  

  eval "$@"
  THISRC=$?
  
  return ${THISRC}
}

#### --------------------------------------
#### executeCommandAndLog
####
#### execute a command and write STDERR and STDOUT to the logfile
####
#### usage: executeCommandAndLog command parameter
####
#### returns: the RC of the executed command if no logfile is defined else 0
####
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

#### --------------------------------------
#### executeCommandAndLogSTDERR
####
#### execute a command and write STDERR to the logfile
####
#### usage: executeCommandAndLogSTDERR command parameter
####
#### returns: the RC of the executed command
####
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

#### --------------------------------------
#### UserIsRoot
####
#### validate the user id
####
#### usage: UserIsRoot
####
#### returns: ${__TRUE} - the user is root; else not
####
function UserIsRoot {
  typeset __FUNCTION="UserIsRoot";    ${__FUNCTION_INIT} ; ${__DEBUG_CODE}

  [ "$( id | sed 's/uid=\([0-9]*\)(.*/\1/' )" = 0 ] && return ${__TRUE} || return ${__FALSE}
}

#### --------------------------------------
#### UserIs
####
#### validate the user id
####
#### usage: UserIs USERID
####
#### where: USERID - userid (e.g oracle)
####
#### returns: 0 - the user is this user
####          1 - the user is NOT this user
####          2 - the user does not exist on this machine
####          3 - missing parameter
####
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

#### --------------------------------------
#### GetCurrentUID
####
#### get the UID of the current user
####
#### usage: GetCurrentUID
####
#### where: - 
####
#### returns: the function writes the UID to STDOUT
####
function GetCurrentUID {
  typeset __FUNCTION="GetCurrentUID";    ${__FUNCTION_INIT} ; ${__DEBUG_CODE}

  echo "$(id | sed 's/uid=\([0-9]*\)(.*/\1/')"
}

#### --------------------------------------
#### GetUserName
####
#### get the name of a user
####
#### usage: GetUserName UID
####
#### where: UID - userid (e.g 1686)
####
#### returns: 0
####          __USERNAME contains the user name or "" if
####           the userid does not exist on this machine
####
function GetUserName {
  typeset __FUNCTION="GetUserName";    ${__FUNCTION_INIT} ; ${__DEBUG_CODE}

  [ "$1"x != ""x ] &&  __USERNAME=$( grep ":x:$1:" /etc/passwd | cut -d: -f1 )  || __USERNAME=""
  
  return 0
}

#### --------------------------------------
#### GetUID
####
#### get the UID for a username
####
#### usage: GetUID username
####
#### where: username - user name (e.g nobody)
####
#### returns: 0
####          __USER_ID contains the UID or "" if
####          the username does not exist on this machine
####
function GetUID {
  typeset __FUNCTION="GetUID";    ${__FUNCTION_INIT} ; ${__DEBUG_CODE}

  [ "$1"x != ""x ] &&  __USER_ID=$( grep "^$1:" /etc/passwd | cut -d: -f3 ) || __USER_ID=""
  
  return 0
}

# ======================================
 
#### --------------------------------------
#### PrintWithTimestamp
####
#### print the output of a command to STDOUT with a timestamp
####
#### usage: PrintWithTimestamp command_to_execute [parameter]
####
#### returns: 0
####
#### Note: This function does not write to the log file!
####
#### Source: Bernd Fingers blog:
####         http://blogs.sun.com/blogfinger/entry/prepend_command_output_lines_with
####
function PrintWithTimestamp {
  typeset COMMAND="$*"
  LogInfo "Executing \"${COMMAND}\" ..."

  sh -c "${COMMAND} | nawk '{\"date \\\"+%m.%d.%Y %H:%M:%S\\\":\"|getline date;
  close(\"date \\\"+%m.%d.%Y %H:%M:%S\\\":\");
  printf (\"%s %s\n\", date, \$0)}'"   
}

 
#### --------------------------------------
#### LogMsg
####
#### print a message to STDOUT and write it also to the logfile
####
#### usage: LogMsg message
####
#### returns: 0
####
#### Notes: Use "- message" to suppress the date stamp
####        Use "-" to print a complete blank line
####
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

  [ "${__LOGFILE}"x != ""x ] && [ -f "${__LOGFILE}" ] &&  echo "${THISMSG}" >>"${__LOGFILE}" 


  return 0
}

#### --------------------------------------
#### LogOnly
####
#### write a message to the logfile
####
#### usage: LogOnly message
####
#### returns: 0
####
function LogOnly {
  typeset __FUNCTION="LogOnly";    ${__FUNCTION_INIT} ; ${__DEBUG_CODE}

  typeset THISMSG="[$(date +"%d.%m.%Y %H:%M:%S")] $*"

  [ "${__LOGFILE}"x != ""x ] && [ -f "${__LOGFILE}" ] &&  echo "${THISMSG}" >>${__LOGFILE} 

  return 0
}

#### --------------------------------------
#### LogIfNotVerbose
####
#### write a message to stdout and the logfile if we are not in verbose mode
####
#### usage: LogIfNotVerbose message
####
#### returns: 0
####
function LogIfNotVerbose {
  typeset __FUNCTION="LogIfNotVerbose";    ${__FUNCTION_INIT} ; ${__DEBUG_CODE}

  [ "${__VERBOSE_LEVEL}"x = "0"x ] && LogMsg "$*"

return 0
}

#### --------------------------------------
#### PrintDotToSTDOUT
####
#### write a message to stdout only if we are not in verbose mode
####
#### usage: PrintDotToSTDOUT [msg]
####
#### default for msg is "." without a LF; use "\n" to print a LF
####
#### returns: 0
####
function PrintDotToSTDOUT {
  typeset __FUNCTION="PrintDotToSTDOUT";    ${__FUNCTION_INIT} ; ${__DEBUG_CODE}
  
  typeset THISMSG=".\c"
  [ $# -ne 0 ] && THISMSG="$*"
  [ "${__VERBOSE_LEVEL}"x = "0"x ] && /usr/bin/echo "${THISMSG}"

return 0
}

#### --------------------------------------
#### LogInfo
####
#### print a message to STDOUT and write it also to the logfile 
#### only if in verbose mode
####
#### usage: LogInfo [loglevel] message
####
#### returns: 0
####
#### Notes: Output goes to STDERR, default loglevel is 0
####
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

#### --------------------------------------
#### LogWarning
####
#### print a warning to STDERR and write it also to the logfile
####
#### usage: LogWarning message
####
#### returns: 0
####
#### Notes: Output goes to STDERR
####
function LogWarning {
  typeset __FUNCTION="LogWarning";    ${__FUNCTION_INIT} ; ${__DEBUG_CODE}

  LogMsg "${__WARNING_PREFIX}$*" >&2
  (( __NO_OF_WARNINGS = __NO_OF_WARNINGS +1 ))
  __LIST_OF_WARNINGS="${__LIST_OF_WARNINGS}
${__WARNING_PREFIX}$*"  
  return 0
}

#### --------------------------------------
#### LogError
####
#### print an error message to STDERR and write it also to the logfile
####
#### usage: LogError message
####
#### returns: 0
####
#### Notes: Output goes to STDERR
####
function LogError {
  typeset __FUNCTION="LogError";    ${__FUNCTION_INIT} ; ${__DEBUG_CODE}

  LogMsg "${__ERROR_PREFIX}$*" >&2

  (( __NO_OF_ERRORS=__NO_OF_ERRORS + 1 ))  
  __LIST_OF_ERRORS="${__LIST_OF_ERRORS}
${__ERROR_PREFIX}$*"  
  return 0
}

#### ---------------------------------------
#### BackupFileIfNecessary
####
#### create a backup of a file if ${__OVERWRITE_MODE} is set to ${__FALSE}
####
#### usage: BackupFileIfNecessary [file1} ... {filen}
####
#### returns: 0 - done; else error
####
function BackupFileIfNecessary {
  typeset __FUNCTION="BackupFileIfNecessary";    ${__FUNCTION_INIT} ; ${__DEBUG_CODE}

 : ${BACKUP_EXTENSION:=".$$"}

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
 
#### ---------------------------------------
#### CopyDirectory
####
#### copy a directory 
####
#### usage: CopyDirectory sourcedir targetDir
####
#### returns:  0 - done; 
####           else error
####
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

#### --------------------------------------
#### AskUser
####
#### Ask the user (or use defaults depending on the parameter -n and -y)
####
#### Usage: AskUser "message" 
####        
#### returns: ${__TRUE} - user input is yes
####          ${__FALSE} - user input is no
####          USER_INPUT contains the user input
####
#### Notes: "all" is interpreted as yes for this and all other questions
####        "none" is interpreted as no for this and all other questions
####
#### If __NOECHO is ${__TRUE} the user input is not written to STDOUT
#### __NOECHO is set to ${__FALSE} again in this function
####
#### If __USE_TTY is ${__TRUE} the prompt is written to /dev/tty and the 
#### user input is read from /dev/tty . This is useful if STDOUT is redirected 
#### to a file.
####
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

#### --------------------------------------
#### GetKeystroke
####
#### read one key from STDIN
####
#### Usage: GetKeystroke "message" 
####        
#### returns: 0
####          USER_INPUT contains the user input
####          
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

#### --------------------------------------
#### RebootIfNecessary
####
#### Check if a reboot is necessary
####
#### Usage: RebootIfNecessary
####
#### Notes
####   The routine asks the user if neither the parameter -y nor the 
####   parameter -n is used
####   Before using this routine uncomment the reboot command!
####
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

#### ---------------------------------------
#### die
####
#### print a message and end the program
####
#### usage: die returncode {message}
####
#### returns: $1 (if it returns)
####
#### Notes: 
####
#### This routine 
####     - calls cleanup
####     - prints an error message if any (if returncode is not zero)
####       or the message if any (if returncode is zero)
####     - prints all warning messages again if ${__PRINT_LIST_OF_WARNING_MSGS} 
####       is ${__TRUE}
####     - prints all error messages again if ${__PRINT_LIST_OF_ERROR_MSGS} 
####       is ${__TRUE}
####     - prints a program end message and the program return code
#### and
####     - and ends the program
####
#### If the variable ${__FORCE} is ${__TRUE} and the return code is NOT zero
#### die() will only print the error message and return
####
function die {
  typeset __FUNCTION="die";    ${__FUNCTION_INIT} ; ${__DEBUG_CODE}

  [ "${__TRAP_SIGNAL}"x != ""x ] &&  LogRuntimeInfo "__TRAP_SIGNAL is \"${__TRAP_SIGNAL}\""
  
  typeset THISRC=$1
  [ $# -ne 0 ] && shift
  
  if [ "$*"x != ""x ] ; then
    [ ${THISRC} = 0 ] && LogMsg "$*" || LogError "$*"
  fi

  [ ${__FORCE} = ${__TRUE} -a ${THISRC} != 0 ] && return

  if [ "${__NO_CLEANUP}"x != ${__TRUE}x  ] ; then
    cleanup
  else
    LogInfo "__NO_CLEANUP set -- skipping the cleanup at script end at all"
  fi

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
#  __QUIET_MODE=${__FALSE}
  LogHeader "${__SCRIPTNAME} ${__SCRIPT_VERSION} ended on $( date )."
  LogHeader "The RC is ${THISRC}."
  
  __EXIT_VIA_DIE=${__TRUE} 

  StartStop_LogAll_to_logfile "stop" 

  RemoveLockFile
 
  RebootIfNecessary
  
  exit ${THISRC}
}

#### ---------------------------------------
#### includeScript
####
#### include a script via . [scriptname]
####
#### usage: includeScript [scriptname]
####
#### returns: 0
####
#### notes: 
####
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

#### --------------------------------------
#### rand
####
#### print a random number to STDOUT
####
#### usage: rand
####
#### returns: ${__TRUE} - random number printed to STDOUT
####          ${__FALSE} - can not create a random number
####
####
#### notes: 
####
#### This function prints the contents of the environment variable RANDOM
#### to STDOUT. If that variable is not defined, it uses nawk to create
#### a random number. If nawk is not available the function prints nothng to
#### STDOUT
####
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

#### 
#### ##### defined internal sub routines (do NOT use; these routines are called 
####       by the runtime system!)
####

# --------------------------------------
#### PrintLockFileErrorMsg
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
#### CreateLockFile
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
#### RemoveLockFile
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
#### CreateTemporaryFiles
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
      LogRuntimeInfo "Creating the temporary file \"${CURFILE}\"; the variable is \"\${__TEMPFILE${i}}" 

      echo >"${CURFILE}" || return $?    
    else    
# improved code from wpollock (see credits)
      set -C  # turn on noclobber shell option
            
      while : ; do
        eval __TEMPFILE${i}="${__TEMPDIR}/${__SCRIPTNAME}.$$.$( rand ).TEMP${i}"
        eval CURFILE="\$__TEMPFILE${i}"
        LogRuntimeInfo "Creating the temporary file \"${CURFILE}\"; the variable is \"\${__TEMPFILE${i}}" 
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

####
#### ---------------------------------------
#### cleanup
####
#### house keeping at program end
####
#### usage: [called by the runtime system]
####
#### returns: 0
####
#### notes: 
####  execution order is
####    - call exit routines from ${__EXITROUTINES}
####    - remove files from ${__LIST_OF_TMP_FILES}
####    - umount mount points ${__LIST_OF_TMP_MOUNTS}
####    - remove directories ${__LIST_OF_TMP_DIRS}
####    - call finish routines from ${__FINISHROUTINES}
####
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
   if [ "${__NO_EXIT_ROUTINES}"x != "${__TRUE}"x  ] ; then   

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
  else
    LogInfo "__NO_EXIT_ROUTINES is set -- skipping executing the exit routines"
  fi

# remove temporary files
   if [ "${__NO_TEMPFILES_DELETE}"x != "${__TRUE}"x ] ; then   
    LogRuntimeInfo "Removing temporary files ..."
    for CURENTRY in ${__LIST_OF_TMP_FILES} ; do
      LogRuntimeInfo "Removing the file \"${CURENTRY}\" ..."
      if [ -f "${CURENTRY}" ] ; then
        rm "${CURENTRY}" 
        [ $? -ne 0 ] && LogWarning "Error removing the file \"${CURENTRY}\" "
      fi
    done
  else
    LogInfo "__NO_TEMPFILES_DELETE is set -- skipping removing temporary files"
  fi
  

# remove temporary mounts
   if [ "${__NO_TEMPMOUNTS_UMOUNT}"x != "${__TRUE}"x ] ; then   
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
  else
    LogInfo "__NO_TEMPMOUNTS_UMOUNT is set -- skipping umounting temporary mounts"
  fi

# remove temporary directories
   if [ "${__NO_TEMPDIR_DELETE}"x != "${__TRUE}"x ] ; then   
    LogRuntimeInfo "Removing temporary directories ..."
    for CURENTRY in ${__LIST_OF_TMP_DIRS} ; do
      LogRuntimeInfo "Removing the directory \"${CURENTRY}\" ..."
      if [ -d "${CURENTRY}" ] ; then
        rm -r "${CURENTRY}" 2>/dev/null
        [ $? -ne 0 ] && LogWarning "Error removing the directory \"${CURENTRY}\" "
      fi
    done
  else
    LogInfo "__NO_TEMPDIR_DELETE is set -- skipping removing temporary directories"
  fi

# call the defined finish routines
   if [ "${__NO_FINISH_ROUTINES}"x != "${__TRUE}"x ] ; then   
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
  else
    LogInfo "__NO_FINISH_ROUTINES is set -- skipping executing the finish routines"
  fi

  [ -d "${OLDPWD}" ] && cd "${OLDPWD}"
  
  return 0
}


#### --------------------------------------
#### CreateDump
####
#### save the current environment of the script
####
#### usage: CreateDump [targetdir] [filename_add]
####
#### returns:  ${__TRUE} - ok, dump created (or dump was already created)
####           ${__FALSE} - error creating the dump
####
####  
function CreateDump {
  typeset __FUNCTION="CreateDump";   ${__FUNCTION_INIT} ;  
  ${__DEBUG_CODE}

#    typeset __FUNCTION="CreateDump";     ${__DEBUG_CODE}
   
# init the return code
  typeset THISRC=${__FALSE}
  typeset __DUMPDIR=""${__DUMPDIR:=DEFAULT_DUMP_DIR}""
  typeset TMPFILE=""
  typeset THISPARAM1="$1"
  typeset THISPARAM2="$2"
  
  if [ "${THISPARAM1}"x != ""x ] ; then
    __DUMPDIR="${THISPARAM1}"
    
  else  
    if [ "${__DUMP_ALREADY_CREATED}"x = "${__TRUE}"x ] ; then
      LogRuntimeInfo "Dump of the current script environment already created."
      return ${__TRUE}
    fi
    __DUMP_ALREADY_CREATED=${__TRUE}
    [ -d "${__CREATE_DUMP}" ] && __DUMPDIR="${__CREATE_DUMP}" || LogWarning "Dumpdir \"${__CREATE_DUMP}\" is no existing directory, using ${__DUMPDIR}"
  fi

  if [ "${__DUMPDIR}"x != ""x ] ; then
    
    LogMsg "Saving the current script environment to \"${__DUMPDIR}\" ..."
    LogMsg "The PID used for the filenames is $$"

    TMPFILE="${__DUMPDIR}/${__SCRIPTNAME}.envvars.${THISPARAM2}$$"
    LogMsg "Saving the current environment variables in the file \"${TMPFILE}\" ..."
    set >"${TMPFILE}"

    TMPFILE="${__DUMPDIR}/${__SCRIPTNAME}.exported_envvars.${THISPARAM2}$$"
    LogMsg "Saving the current exported environment variables in the file \"${TMPFILE}\" ..."
    env >"${TMPFILE}"

    THISRC=${__TRUE}
  fi


  return ${THISRC}
}

#### 
#### ##### defined trap handler (you may change them)
####

#### ---------------------------------------
#### GENERAL_SIGNAL_HANDLER
####
#### general trap handler 
####
#### usage: called automatically;
####        parameter: $1 = signal number
####                   $2 = LineNumber
####                   $3 = function name
####
#### returns: -
####
#### notes: see USER_SIGNAL_HANDLER for an example user signal handler
####
function GENERAL_SIGNAL_HANDLER {
  typeset __RC=$?
  
  __TRAP_SIGNAL=$1
   __LINENO=$2  
  INTERRUPTED_FUNCTION=$3
 
  LogRuntimeInfo "GENERAL_SIGNAL_HANDLER: TRAP \"${__TRAP_SIGNAL}\" occured in the function \"${INTERRUPTED_FUNCTION}\", Line No \"${__LINENO}\" "
  LogRuntimeInfo "__EXIT_VIA_DIE=\"${__EXIT_VIA_DIE}\" "
  LogRuntimeInfo "Parameter for the trap routine are: \"$*\"; the RC is $?"
  
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
    typeset fname
    typeset rest
    echo ${__USER_DEFINED_FUNCTION} | read fname rest
    typeset +f | grep "^${fname}" >/dev/null
    if [ $? -ne 0 ] ; then
      LogRuntimeInfo "Function \"${fname}\" is declared but not defined "
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

 
     "SIGUSR1" ) 
        [ "${__SIGUSR1_DUMP_NO}"x = ""x ] && __SIGUSR1_DUMP_NO=0 || (( __SIGUSR1_DUMP_NO = __SIGUSR1_DUMP_NO + 1 ))
        CreateDump  "/var/tmp" "dump_no_${__SIGUSR1_DUMP_NO}_"
        ;;
     
     "SIGUSR2" ) 
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
            if [ "${__CLEANUP_ON_ERROR}"x  = "${__TRUE}"x ] ; then
              LogMsg "__CLEANUP_ON_ERROR set -- calling the function die anyway"
              die 236 "You should use the function \"die\" to end the program"
            else
              LogWarning "You should use the function \"die\" to end the program"
            fi
            [ "${__CREATE_DUMP}"x = ""x ] && __CREATE_DUMP="${__DUMPDIR:=${DEFAULT_DUMP_DIR}}"
            CreateDump
          else
            [ "${__CREATE_DUMP}"x != ""x ] && CreateDump
          fi    
        ;;
       
      * ) 
          die 254 "Unknown signal caught: ${__TRAP_SIGNAL}"
        ;;

    esac
  fi
  
}

# ======================================

#### ---------------------------------------
#### DebugHandler
####
#### handler for single step mode
####
#### usage: called automatically
####
#### returns: the RC of the previous executed command
####
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


#### ---------------------------------------
#### InitScript
####
#### init the script runtime 
####
#### usage: [called by the runtime system]
####
#### returns: 0
####
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
    [ "${CONFIG_FILE}"x != ""x ] && LogInfo "User defined config file is \"${CONFIG_FILE}\" "
    ReadConfigFile ${CONFIG_FILE}
  fi
  
  return 0
}

#### ---------------------------------------
#### SetEnvironment
####
#### set and check the environment
####
#### usage: [called by the runtime system]
####
#### returns: 0
####
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
    __EXITROUTINES="${__EXITROUTINES}"    
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
    die 0 "Configfile \"${NEW_CONFIG_FILE}\" successfully written."    
  fi

}
 
#### 
#### ##### defined sub routines 
####

#### --------------------------------------
#### CheckParameterCount
####
#### check the number of parameters for a function 
####
#### usage: CheckParameterCount parametercount "$@"
####
#### returns:  ${__TRUE} - the no of parameter is ok
####           ${__FALSE} - the no of parameter is not ok
####          
####
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

#### ---------------------------------------
#### ShowShortUsage
####
#### print the (short) usage help
####
#### usage: ShowShortUsage
####
#### returns: 0
####
function ShowShortUsage {
  typeset __FUNCTION="ShowShortUsage";    ${__FUNCTION_INIT} ; ${__DEBUG_CODE}

  eval "__SHORT_USAGE_HELP=\"${__SHORT_USAGE_HELP}\""

cat <<EOT
  ${__SCRIPTNAME} ${__SCRIPT_VERSION} - ${__SHORT_DESC}

  Usage: ${__SCRIPTNAME} [-v|+v] [-q|+q] [-h] [-l logfile|+l] [-y|+y] [-n|+n] 
                    [-D|+D] [-a|+a] [-O|+O] [-f|+f] [-C] [-H] [-X] [-S n] [-V] [-T]
${__SHORT_USAGE_HELP}
  
EOT

  return 0
}

#### ---------------------------------------
#### ShowUsage
####
#### print the (long) usage help
####
#### usage: ShowUsage
####
#### returns: 0
####
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
      -X    - write usage examples to STDERR and exit
              Long format: --view_examples
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
Environment variables that are used if set (0 = TRUE, 1 = FALSE):

EOT

    for __CURVAR in ${ENVVARS} ; do
      echo "  ${__CURVAR} (Current value: \"$( eval echo \$${__CURVAR} )\")"
    done
  fi

  [ ${__VERBOSE_LEVEL} -gt 2 ] && egrep "^##[CRT]#" "$0" | cut -c5- 1>&2 


  return 0      
}

# -----------------------------------------------------------------------------


#### --------------------------------------
#### USER_SIGNAL_HANDLER
####
#### sample user defined trap handler
####
#### usage: __SIGNAL_<signal>_FUNCTION="USER_SIGNAL_HANDLER"
####
####        e.g. __SIGNAL_SIGUSR1_FUNCTION="USER_SIGNAL_HANDLER"
####
#### returns:  0 - execute the default action for this signal
####           else - do not execute the default action for this signal
####
####
function USER_SIGNAL_HANDLER {
  typeset THISRC=0
  
  LogMsg "***"
  LogMsg "User defined signal handler called"
  LogMsg ""
  LogMsg "Trap signal is \"${__TRAP_SIGNAL}\" "
  LogMsg "Interrupted function: \"${INTERRUPTED_FUNCTION}\", Line No: \"${__LINENO}\" "
  LogMsg "***"
  
  return ${THISRC}
}


#### --------------------------------------
#### SetHousekeeping
####
#### do or do not house keeping (remove tmp files/directories; execute exit routines/finish routines) at script end
####
#### usage: SetHousekeeping [${__TRUE}|${__FALSE}]
####
#### parameter: ${__TRUE} - do house keeping
####            ${__FALSE} - no house keeping
####
#### returns:  0 - okay
####           1 - invalid usage
####
####
function SetHousekeeping {
  typeset __FUNCTION="SetHousekeeping";    ${__FUNCTION_INIT} ; ${__DEBUG_CODE}
  typeset THISRC=0
  
  case ${1} in

    ${__TRUE} )
      LogRuntimeInfo "Switching cleanup at script end on"
      __NO_CLEANUP=${__FALSE}
      __NO_EXIT_ROUTINES=${__FALSE}
      __NO_TEMPFILES_DELETE=${__FALSE}
      __NO_TEMPMOUNTS_UMOUNT=${__FALSE}
      __NO_TEMPDIR_DELETE=${__FALSE}
      __NO_FINISH_ROUTINES=${__FALSE}
     ;;
      
    ${__FALSE} )
      LogRuntimeInfo "Switching cleanup at script end off"
      __NO_CLEANUP=${__TRUE}
      __NO_EXIT_ROUTINES=${__TRUE}
      __NO_TEMPFILES_DELETE=${__TRUE}
      __NO_TEMPMOUNTS_UMOUNT=${__TRUE}
      __NO_TEMPDIR_DELETE=${__TRUE}
      __NO_FINISH_ROUTINES=${__TRUE}
      ;;
      
    * )
      LogError "Internal Error: SetHousekeeping called with an invalid parameter: \"${1}\" "
      THISRC=1
        ;;
  esac
    
  return ${THISRC}
}

#### --------------------------------------
#### PrintRuntimeVariables
####
#### print the values of the runtime variables
####
#### usage: PrintRuntimeVariables
####
#### returns:  ${__TRUE} - ok
####           ${__FALSE} - error
####           else - invalid usage
####
####
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
  THISRC=255

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


####
#### other subroutines that can be used in your code



#### --------------------------------------
#### GetOtherDate
####
#### get the date for today +/- n ( 1 <= n <= 6)
####
#### usage: GetOtherDate [+|-]no_of_days [format]
####
#### where
####   +/-no_of_days - relative date (e.g -1, -2, etc)
####   format - format for the date (def.: %Y-%m-%d)
####
#### returns:  writes the date to STDOUT
####          
#### notes: 
####  - = date in the future
####  - = date in the past
####  max. date difference : +/- 6 days 
####
function GetOtherDate {
  typeset __FUNCTION="GetOtherDate";   ${__FUNCTION_INIT} ;  
  ${__DEBUG_CODE}
  
#    typeset __FUNCTION="GetOtherDate";     ${__DEBUG_CODE}
   
# init the return code
  typeset THISRC=${__FALSE}
  typeset FORMAT_STRING="%Y-%m-%d"

  if [ $# -ge 1 ] ; then
    [ "$2"x != ""x ] && FORMAT_STRING=$2
    (( TIME_DIFF= $1 * 24 ))
    TZ=$TZ${TIME_DIFF} date "+${FORMAT_STRING}"
    THISRC=${__TRUE}
  fi
  return ${THISRC}
}


#### --------------------------------------
#### SaveEnvironmentVariables
####
#### save selected environment variables to a file
####
#### usage: SaveEnvironmentVariables filename [[pattern1]...[pattern#]]
####
#### where: filename - name of the file for the environment variables
####        pattern# - egrep pattern to select the environment variables to save
####
#### returns:  ${__TRUE} - ok
####           ${__FALSE} - error
####          
#### Notes:
####   To reuse the file later use the function includeScript
####
function SaveEnvironmentVariables {
  typeset __FUNCTION="SaveEnvironmentVariables";   ${__FUNCTION_INIT} ;  
  ${__DEBUG_CODE}
  
#    typeset __FUNCTION="SaveEnvironmentVariables";     ${__DEBUG_CODE}
   
# init the return code
  THISRC=${__FALSE}

  if [ $# -ne 0 ] ; then
    typeset THIS_FILE="$1"
    LogRuntimeInfo "Writing the selected environment variables to \"${THIS_FILE}\" ..."
    shift
    
    touch "${THIS_FILE}" 2>/dev/null 
    if [ $? -ne 0 ] ; then
      LogError "SaveEnvironmentVariables: Error $? writing to the file \"${THIS_FILE}\" "
    else
      typeset OUTPUT=""
      typeset NEW_OUTPUT=""
      if [ $# -eq 0 ] ; then
        OUTPUT="$( set )"
      else
        for i in $* ; do
          CUR_PATTERN="$i"
          LogRuntimeInfo "Processing the pattern \"$i\" ..."
          NEW_OUTPUT="$( set | egrep "$i" )"
          LogRuntimeInfo "  The result of this pattern is: 
${NEW_OUTPUT}
"
        
          OUTPUT="${OUTPUT}
${NEW_OUTPUT}"
        done
      fi
      LogRuntimeInfo "Writing the file \"${THIS_FILE}\" ..."
      BackupFileIfNecessary "${THIS_FILE}"
      echo "${OUTPUT}" | sort | uniq  >"${THIS_FILE}"
      if [ $? -ne 0 ] ; then
        LogError "SaveEnvironmentVariables: Error $? writing to the file \"${THIS_FILE}\" "
      else
        THISRC=${__TRUE}
      fi
    fi
  fi    

  return ${THISRC}
}



#### template for a new user function
####

#### --------------------------------------
#### YourRoutine
####
#### template for a user defined function 
####
#### usage: YourRoutine
####
#### returns:  ${__TRUE} - ok
####           ${__FALSE} - error
####           255 - invalid usage
####          
####
function YourRoutine {
  typeset __FUNCTION="YourRoutine";   ${__FUNCTION_INIT} ;  
  ${__DEBUG_CODE}
  
#    typeset __FUNCTION="YourRoutine";     ${__DEBUG_CODE}
   
# init the return code
  THISRC=255

# check the parameter count
  CheckParameterCount 0 "$@" || die 240 "Internal error detected"
  
  if [ $# -eq 0 ] ; then
    THISRC=${__FALSE}

# add code here

  fi
  
#  echo ""
#  echo "LineNo: ${LINENO}; Function ${__FUNCTION} "; trap
#  read test

  return ${THISRC}
}


# -----------------------------------------------------------------------------
# main:
#
  
# trace main routine
#
# set -x
# PS4='LineNo: $LINENO (sec: $SECONDS): >> '
    
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

# ??? init variables with the defaults
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

# add functions that should be called automatically at program end 
# before removing temporary files, directories, and mounts
# to this variable
#
#   __EXITROUTINES="${__EXITROUTINES} "    

# add functions that should be called automatically at program end 
# after removing temporary files, directories, and mounts
# to this variable 
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

  __GETOPTS="+:ynvqhHDfl:aOS:CVTXm:"
  if [ "${__OS}"x = "SunOS"x -a "${__SHELL}"x = "ksh"x ] ; then
    if [ "${__OS_VERSION}"x  = "5.10"x -o  "${__OS_VERSION}"x  = "5.11"x ] ; then
      __GETOPTS="+:y(yes)n(no)v(verbose)q(quiet)h(help)H(doc)D(debug)f(force)l:(logfile)a(color)O(overwrite)S:(summaries)C(writeconfigfile)V(version)T(tee)X(view_examples)m:(mountpoint)"
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
#     __PRINT_ARGUMENTS=0 [scriptname]
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
       
       "l" ) 
             NEW_LOGFILE="${OPTARG:=nul}" 
             [ "$( substr ${NEW_LOGFILE} 1 1 )"x != "/"x ] && NEW_LOGFILE="$PWD/${NEW_LOGFILE}"
             ;;

      "+l" ) NEW_LOGFILE="nul" ;;

      "+h" ) __VERBOSE_MODE=${__TRUE}
             __PRINT_USAGE=${__TRUE} 
             ;;

       "h" ) __PRINT_USAGE=${__TRUE} ;;

       "T" ) : # parameter already processed 
             ;;
       
       "H" ) 

echo " -----------------------------------------------------------------------------------------------------" >&2
echo "                         ${__SCRIPTNAME} ${__SCRIPT_VERSION} ">&2
echo "                              Documentation" >&2
echo " -----------------------------------------------------------------------------------------------------" >&2

             grep "^##" "$0" | grep -v "##EXAMPLE##" | cut -c5- 1>&2 
             die 0 ;;

       "X" ) 

echo " -----------------------------------------------------------------------------------------------------" >&2
echo "                         ${__SCRIPTNAME} ${__SCRIPT_VERSION} ">&2
echo "                          Documentation" - Examples>&2
echo " -----------------------------------------------------------------------------------------------------" >&2

             grep "^##EXAMPLE##" "$0" | cut -c12- 1>&2 
             die 0 ;;

       "V" ) LogMsg "Script version: ${__SCRIPT_VERSION}"
             if [ ${__VERBOSE_MODE} = ${__TRUE} ] ; then
               LogMsg "Script template version: ${__SCRIPT_TEMPLATE_VERSION}"
               if [ "${__CONFIG_FILE_FOUND}"x != ""x ] ; then
                 LogMsg "Script config file: \"${__CONFIG_FILE_FOUND}\""
                 LogMsg "Script config file version : ${__CONFIG_FILE_VERSION}"
               fi
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

       "m" ) 
             MOUNT_POINT="${OPTARG}" 
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
      LogMsg "Use \"-v -h\", \"-v -v -h\", \"-v -v -v -h\" or \"+h\" for a long help text"
    fi
    die 1 ;   
  fi

  shift $(( OPTIND - 1 ))

  NOT_PROCESSED_PARAMETER="$*"

  LogRuntimeInfo "Not processed parameter: \"${NOT_PROCESSED_PARAMETER}\""
  

# ??? add parameter checking code here 
#
# set INVALID_PARAMETER_FOUND to ${__TRUE} if the script
# should abort due to an invalid parameter 
#
#  if [ "${NOT_PROCESSED_PARAMETER}"x != ""x ] ; then
#    LogError "Unknown parameter: \"${NOT_PROCESSED_PARAMETER}\" "
#    INVALID_PARAMETER_FOUND=${__TRUE}
#  fi


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

# create the PID file
#
  if [ "${__PIDFILE}"x != ""x ] ; then
    LogRuntimeInfo "Writing the PID $$ to the PID file \"${__PIDFILE}\" ..."
    echo $$>"${__PIDFILE}" && __LIST_OF_TMP_FILES="${__LIST_OF_TMP_FILES} ${__PIDFILE}" || \
      LogWarning "Can not write the pid to the PID file \"${__PIDFILE}\" "
  fi

# restore the language setting
#
  LANG=${__SAVE_LANG}
  export LANG

# -----------------------------------------------------------------------------
# test / debug code -- remove in your script


# print some of the runtime variables
#
#  PrintRuntimeVariables

  LogInfo "Config file version is: \"${__CONFIG_FILE_VERSION}\" "

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


# "


# -----------------------------------------------------------------------------
# print script environment

  if [ ${__VERBOSE_MODE} = ${__TRUE} ] ; then
    LogMsg "-"
    LogMsg "----------------------------------------------------------------------"
    LogMsg "Scriptname is \"${__SCRIPTNAME}\" "
    LogMsg "Scriptversion is \"${__SCRIPT_VERSION}\" "
    LogMsg "Script template version is \"${__SCRIPT_TEMPLATE_VERSION}\" "
    LogMsg " "
    LogMsg "OS is \"${__OS}\" (\"${__OS_FULLNAME}\") "
    LogMsg "OS Version is \"${__OS_VERSION}\" "
    LogMsg "OS Release is \"${__OS_RELEASE}\" "
    LogMsg "The current shell is \"${__SHELL}\"; this shell is compatible to ksh${__KSH_VERSION}"
    LogMsg ""
    LogMsg "The PID of this process is $$"
    LogMsg "----------------------------------------------------------------------"
    LogMsg ""
  fi

# -----------------------------------------------------------------------------
# ??? add your main code here

#  echo "Calling YourRoutine ..."
#   YourRoutine

# defined Log routines:
#
# LogMsg
# LogInfo
# LogWarning
# LogError
# LogOnly
# LogIfNotVerbose
# PrintDotToSTDOUT




# --------------------------------------------------------------------------------
# init the variables of the script
#

  echo ${NOT_PROCESSED_PARAMETER} | read ACTION BOOT_ARCHIVE_PARAMETER
  [ "${BOOT_ARCHIVE_PARAMETER}"x != ""x ] && BOOT_ARCHIVE="${BOOT_ARCHIVE_PARAMETER}"
  [ "${ACTION}"x = ""x ] && ACTION="mount"

  LogInfo "The current action is \"${ACTION}\""
  LogInfo "The boot archive name in the parameter is \"${BOOT_ARCHIVE_PARAMETER}\" "
  LogInfo "The boot archive to use is \"${BOOT_ARCHIVE}\" "

# check if we do have the name of a boot archive (either the default or a parameter)
#
  [ "${BOOT_ARCHIVE}"x = ""x ] && \
    die 3 "Unknown machine architecture \"${ARCH}\" and no boot archive specified in the parameter"

# exit if the boot_archive does not exist
#
  [ ! -r "${BOOT_ARCHIVE}" ]  && \
    die 5 "The boot archive \"${BOOT_ARCHIVE}\" does not exist or is not readable!"

# file used as temporary copy of the boot archive
#
  TMP_BOOT_ARCHIVE="/tmp/$( echo "${BOOT_ARCHIVE}" | tr "/" "_" ).uncompressed"

  LogInfo "The temporary copy of the boot_archive will be in the file \"${TMP_BOOT_ARCHIVE}\" "

# check if there is already a lofi device for the copy of the boot_archive
#
  LOFI_DEV="$( lofiadm "${TMP_BOOT_ARCHIVE}" 2>/dev/null )"
  [ "${LOFI_DEV}"x != ""x ] && USED_MOUNTPOINT="$( mount | grep " ${LOFI_DEV} " | cut -f1 -d " " )" || USED_MOUNTPOINT=""

  LogInfo "The lofi device found is \"${LOFI_DEV}\" "
  LogInfo "The used mount point is \"${USED_MOUNTPOINT}\" "

  case ${ACTION} in

    status )
      if [ "${LOFI_DEV}"x != ""x ] ; then
        if [ "${USED_MOUNTPOINT}"x != ""x ] ; then
          LogMsg "The boot archive \"${BOOT_ARCHIVE}\" is already mounted on \"${USED_MOUNTPOINT}\" "
          __MAINRC=0
        else
          LogMsg "The lofi device for the \"${BOOT_ARCHIVE}\" is \"${LOFI_DEV}\" already created but currently not mounted"
          __MAINRC=100
        fi
      else
        LogMsg "The boot archive \"${BOOT_ARCHIVE}\" is currently not in use by this script."
        __MAINRC=200
      fi
      ;;

    umount | unmount )
      LogMsg "Processing the boot archive \"${BOOT_ARCHIVE}\" ..."

      if [ "${USED_MOUNTPOINT}"x != ""x ] ; then
        LogInfo "Umounting the lofi device \"${LOFI_DEV}\" ..."
        umount "${LOFI_DEV}" 2>/dev/null || \
          die 11 "Error $? umounting the lofi device \"${LOFI_DEV}\" "
      else
        LogInfo "The boot archive is not mounted."
      fi
      
      if [ "${LOFI_DEV}"x != ""x ] ; then
        LogInfo "Removing the lofi device \"${LOFI_DEV}\" ..."
        lofiadm -d "${LOFI_DEV}" || \
          die 12 "Error $? removing the lofi device \"${LOFI_DEV}\""
      else
        LogInfo "There is no lofi device for the boot archive"
      fi

      if [[ "${USED_MOUNTPOINT}"x == ${DEFAULT_MOUNT_POINT_TEMPLATE}.[0-9]* ]] ; then
        if [ -d "${USED_MOUNTPOINT}" ] ; then
          LogInfo "Removing the temporary mount point \"${USED_MOUNTPOINT}\" "
          rmdir "${USED_MOUNTPOINT}" || \
            LogWarning "Error $? removing the mount point \"${USED_MOUNTPOINT}\" "
        else
          LogInfo "The used mount point \"${USED_MOUNTPOINT}\" does not exist anymore"
        fi
        LogInfo "The used mount point \"${USED_MOUNTPOINT}\" was probably not created by this script -- will not delete it"
      fi

      if [  -f "${TMP_BOOT_ARCHIVE}" ] ; then
        LogInfo "Deleting the temporary boot_archive \"${TMP_BOOT_ARCHIVE}\"..."
        rm "${TMP_BOOT_ARCHIVE}"  || \
          LogWarning "Error $? removing the temporary file \"${TMP_BOOT_ARCHIVE}\" "
      else
        LogInfo "The temporary boot archive \"${TMP_BOOT_ARCHIVE}\" does not exist anymore"
      fi
      
      LogMsg "Umounting the boot archive done."
      ;;


    mount )
      LogMsg "Using the boot archive \"${BOOT_ARCHIVE}\" ..."

# prepare the temporary copy of the boot_archive
      if [ "${LOFI_DEV}"x = ""x ] ; then
        if [ -f ${TMP_BOOT_ARCHIVE} ] ; then
          LogMsg "Using the existing boot_archive copy \"${TMP_BOOT_ARCHIVE}\" "
        else

# check the type of the boot_archive
#
          FILE_OUTPUT="$( file "${BOOT_ARCHIVE}" )" || \
            die 7 "Can not detect the type of the boot_archive file \"${BOOT_ARCHIVE}\" "

          FILE_TYPE="uncompressed"
          [[ ${FILE_OUTPUT} == *gzip* ]] && FILE_TYPE="gzip"
          [[ ${FILE_OUTPUT} == *bzip2* ]] && FILE_TYPE="bzip2"
          LogInfo "The type of the boot archive is \"${FILE_TYPE}\" "

          case "${FILE_TYPE}" in
          
            "uncompressed" )
              LogMsg "Copying \"${BOOT_ARCHIVE}\" to \"${TMP_BOOT_ARCHIVE}\" ... "
              cp "${BOOT_ARCHIVE}" "${TMP_BOOT_ARCHIVE}" || \
                die 13 "Error $? copying \"${BOOT_ARCHIVE}\" to \"${TMP_BOOT_ARCHIVE}\" "
              ;;

            "gzip" )
              LogMsg "Uncompressing \"${BOOT_ARCHIVE}\" to \"${TMP_BOOT_ARCHIVE}\" using gzip ... "
              gzip -cd "${BOOT_ARCHIVE}" >"${TMP_BOOT_ARCHIVE}" || \
                die 15 "Error $? uncompressing \"${BOOT_ARCHIVE}\" to \"${TMP_BOOT_ARCHIVE}\" "
              ;;

            "bzip2" )
              LogMsg "Uncompressing \"${BOOT_ARCHIVE}\" to \"${TMP_BOOT_ARCHIVE}\" using bzip2 ... "
              bzip2 -cd "${BOOT_ARCHIVE}" >"${TMP_BOOT_ARCHIVE}" || \
                die 17 "Error $? uncompressing \"${BOOT_ARCHIVE}\" to \"${TMP_BOOT_ARCHIVE}\" "
              ;;

          esac
        fi

# create the lofi device
        LOFI_DEV=$( lofiadm -a "${TMP_BOOT_ARCHIVE}" ) || \
          die 19 "Error $? creating the lofi device for the copy of the boot_archive"
        LogInfo "The lofi device for this boot archive is \"${LOFI_DEV}\" "
      fi

# mount the lofi device
      MOUNT_MSG="$( mount | grep " ${LOFI_DEV} "  )"
      if [ $? != 0 ] ; then

# lofi device not yet mounted 

# create the mount point if necessary
#
        if [ ! -d "${MOUNT_POINT}" ] ; then
          LogInfo "Creating the mount point \"${MOUNT_POINT}\" "
          mkdir -p "${MOUNT_POINT}" || \
           die 9 "Error $? creating the temporary mountpoint \"${MOUNT_POINT}\" "
        fi

        FSTYP=$( fstyp "${LOFI_DEV}" )
        [ "${FSTYP}"x = "hsfs"x ] && MSG="readonly (${FSTYP})]" ||  MSG="readwrite (${FSTYP})]"
        mount -F "${FSTYP}" "${LOFI_DEV}" "${MOUNT_POINT}" ||
          die 21 "Error $? mounting the lofi device"
        LogMsg "The boot_archive is mounted ${MSG}: "
        mount | grep "${MOUNT_POINT}"
      else
        LogMsg "The boot_archive is already mounted:"
        LogMsg "${MOUNT_MSG}"
      fi
      ;;

  esac

  die ${__MAINRC} 
 
exit
