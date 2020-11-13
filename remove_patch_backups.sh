#!/usr/bin/ksh
#
# Notes:
#
# -----------------------------------------------------------------------------
##
## remove_patch_backups.sh - remove backups of patches
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
## This script can be used to remove backups created by patch installations.
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
##  	wpollock (http://wikis.sun.com/display/~wpollock)
##	  -- http://wikis.sun.com/display/BigAdmin/A+Script+Template+and+Useful+Techniques+for+ksh+Scripts?focusedCommentId=12517624#comment-12517624
##
## 	Source for the function PrintWithTimeStamp:
##         Bernd Fingers blog:
##         http://blogs.sun.com/blogfinger/entry/prepend_command_output_lines_with
##
##
## History:
##   01.02.2008 v1.0.0 /bs
##     initial release
##   07.10.2008 v1.0.1 /bs
##     corrected a bug in the output of the action to do (dryrun or not dryrun)
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
## ----------------
## Version variables
##
## __SCRIPT_VERSION - the version of your script 
##
typeset -r __SCRIPT_VERSION="v1.0.0"
##

## __SCRIPT_TEMPLATE_VERSION - version of the script template
##
typeset -r __SCRIPT_TEMPLATE_VERSION="1.22.29 31.01.2008"
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
typeset -r __TRUE=0
typeset -r __FALSE=1


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
# __FUNCTION_INIT=""
 __FUNCTION_INIT=" eval __settrap"
 

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

  DEFAULT_NO_OF_BACKUPS_TO_KEEP=1
  DEFAULT_PATCH_BACKUP_DIR="/var/sadm/pkg"
  DEFAULT_PATCH_TYPE="all"
  DEFAULT_ACTION="dryrun"
  DEFAULT_OUTPUT_FILE=""
  DEFAULT_SUMMARIZE="${__FALSE}"
  
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
typeset -r __SHORT_DESC="remove backups of patches"

## __LONG_USAGE_HELP - Additional help if the script is called with 
##   the parameter "-v -h"
##
##   Note: To use variables in the help text use the variable name without
##         an escape character, eg. ${OS_VERSION}
##
__LONG_USAGE_HELP='
      -t patchtype
            - type of patches to consider; known values: all, obsolete
              Long format: --patchtype
              current value: ${PATCH_TYPE}
      -d patch_backup_directory 
            - Directory with the patch backups
              Long format --patchdir
              current value: ${PATCH_BACKUP_DIR}
      -N no_of_backups_to_keep
            - no. of backups to keep for each patch
              Long format: --keep_backups
              current value: ${NO_OF_BACKUPS_TO_KEEP}
      -x    - remove the backups; without this parameter the 
              script will only do a dryrun mode
              Long format: --doit
      -o outputfile 
            - write the commands to remove the backups to the file outputfile
              Long format: --outputfile
      -s    - calculate the diskspace used by the backups
              Long format: --summarize
'

## __SHORT_USAGE_HELP - Additional help if the script is called with the parameter "-h"
##
##   Note: To use variables in the help text use the variable name without an escape
##         character, eg. ${OS_VERSION}
##
__SHORT_USAGE_HELP='
                    -t patchtype -d patch_backup_directory 
                    -N no_of_backups_to_keep -o outputfile -s -x
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
__REQUIRED_ZONES=""

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
##
##   Note: You can also set this environment variable before starting the script
##
typeset -i __RT_VERBOSE_LEVEL=${__RT_VERBOSE_LEVEL:=1}

## __QUIET_MODE - do not print messages to STDOUT (def.: false)
##   use the parameter -q/+q to change this variable
##
##
##   Note: You can also set this environment variable before starting the script
##
__QUIET_MODE=${__QUIET_MODE:=${__FALSE}}

## __VERBOSE_MODE - print verbose messages (def.: false)
##   use the parameter -v/+v to change this variable  
##
##
##   Note: You can also set this environment variable before starting the script
##
__VERBOSE_MODE=${__VERBOSE_MODE:=${__FALSE}}

## __NO_TIME_STAMPS - Do not use time stamps in the messages (def.: false)
##
##
##   Note: You can also set this environment variable before starting the script
##
__NO_TIME_STAMPS=${__NO_TIME_STAMPS:=${__FALSE}}

## __NO_HEADERS - Do not print headers and footers (def.: false)
##
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
##
##   Note: You can also set this environment variable before starting the script
##
__USE_COLORS=${__USE_COLORS:=${__FALSE}}

## __USER_BREAK_ALLOWED - CTRL-C aborts the script or not (def.: true)
##   (no parameter to change this variable)
##
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
##    umask for creating temporary files (def.: 177)
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

##   __SIGNAL_SIGUSR1_FUNCTION  - name of the function to execute if the signal SIGUSR1 is received
##   default signal handling: none
##
 __SIGNAL_SIGUSR1_FUNCTION=""

##   __SIGNAL_SIGUSR2_FUNCTION  - name of the function to execute if the signal SIGUSR2 is received
##   default signal handling: none
##
 __SIGNAL_SIGUSR2_FUNCTION=""

##   __SIGNAL_SIGHUP_FUNCTION  - name of the function to execute if the signal SIGHUP is received
##   default signal handling: switch the verbose mode on or off
##   If a user defined function ends with a return code not equal zero the default 
##   action fro the SIGHUP signal is not executed.
##
 __SIGNAL_SIGHUP_FUNCTION=""

##   __SIGNAL_SIGINT_FUNCTION  - name of the function to execute if the signal SIGINT is received
##   default signal handling: end the script if __USER_BREAK_ALLOWED is ${__TRUE} else ignore the signal
##   If a user defined function ends with a return code not equal zero the default 
##   action for the SIGINT signal is not executed.
##
 __SIGNAL_SIGINT_FUNCTION=""

##   __SIGNAL_SIGQUIT_FUNCTION  - name of the function to execute if the signal SIGQUIT is received
##   default signal handling: end the script
##   If a user defined function ends with a return code not equal zero the default 
##   action for the SIGQUIT signal is not executed.
##
 __SIGNAL_SIGQUIT_FUNCTION=""

##   __SIGNAL_SIGTERM_FUNCTION  - name of the function to execute if the signal SIGTERM is received
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
typeset -r __SCRIPTNAME="${0##*/}"

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

## __OS - Operating system (e.g. SunOS)
##
__OS="$( uname -s )"

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
       [  -x /usr/platform/${__MACHINE_PLATFORM}/sbin/prtdiag ] &&   \
         ( set -- $( /usr/platform/${__MACHINE_PLATFORM}/sbin/prtdiag | grep "System Configuration" ) ; shift 5; echo $* ) 2>/dev/null | read  __MACHINE_SUBTYPE
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
# config file for $0
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
## returns: the RC of the executed command
##
function executeCommandAndLog {
  typeset __FUNCTION="executeCommandAndLog";    ${__FUNCTION_INIT} ; ${__DEBUG_CODE}

  set +e
  typeset THISRC=0

  LogRuntimeInfo "Executing \"$@\" "  

  if [ "${__LOGFILE}"x != ""x -a -f "${__LOGFILE}" ] ; then
    eval "$@" 2>&1 | tee -a "${__LOGFILE}"
    THISRC=$?
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
## returns: the UID (e.g. 100)
##
function GetCurrentUID {
  typeset __FUNCTION="GetCurrentUID";    ${__FUNCTION_INIT} ; ${__DEBUG_CODE}

  return "$(id | sed 's/uid=\([0-9]*\)(.*/\1/')"
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

  [ "$1"x != ""x ] &&  __USERNAME=$( grep ":$1:" /etc/passwd | cut -d: -f1 )  || __USERNAME=""
  
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
   
     * ) [ $# -ne 0 ] && eval LogMsg "-" "\"$* \c\"" ${mySTDOUT}
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
  LogHeader "${__SCRIPTNAME} ended on $( date )."
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
# Create the lock file (which is really a symbolic link) if possible
#
# usage: CreateLockFile
#
# returns: 0 - lock created
#          1 - lock already exist or error creating the lock
#
# Note: Use a symbolic link because this is always a atomic operation
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
# improved code from wpollock (see credits)
    __INSIDE_CREATE_LOCKFILE=${__TRUE}
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

  LogHeader "${__SCRIPTNAME} started on $( date ) "

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

       The long format of the parameter (--parameter/++parameter) is not supported 
       by all ksh implementations
       
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
      -T    - append STDOUT and STDERR to the file 
              "${__TEE_OUTPUT_FILE}"
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
  typeset __FUNCTION="YourRoutine";   ${__FUNCTION_INIT} ;  
  ${__DEBUG_CODE}
  
#    typeset __FUNCTION="YourRoutine";     ${__DEBUG_CODE}
   
# init the return code
  THISRC=${__INVALID_USAGE}

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

  [ "${__OS}"x = "Linux" ] &&  GETOPT_COMPATIBLE="0"

  __GETOPTS="+:ynvqhHDfl:aOS:CVTxN:d:t:o:s"
  if [ "${__OS}"x = "SunOS"x  ] ; then
    if [ "${__OS_VERSION}"x  = "5.10"x -o  "${__OS_VERSION}"x  = "5.11"x ] ; then
      __GETOPTS="+:y(yes)n(no)v(verbose)q(quiet)h(help)H(doc)D(debug)f(force)l:(logfile)a(color)O(overwrite)S:(summaries)C(writeconfigfile)V(version)T(tee)x(doit)N:(keep_backups)d:(patchdir)t:(patchtype)o:(outputfile)s(summarize)"
    fi
  fi

  while getopts ${__GETOPTS} CUR_SWITCH  ; do

# for debugging only
#
## -----------------------------------------------------------------------------
## Debug Hint
##
## Use
##
##     __PRINT_ARGUMENTS=0 ${__SCRIPTNAME}
##
## to debug the parameter handling
##
## -----------------------------------------------------------------------------
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

        "t" ) PATCH_TYPE="${OPTARG:=${DEFAULT_PATCH_TYPE}}" ;;

        "+t" ) PATCH_TYPE="${DEFAULT_PATCH_TYPE}" ;;

        "d" ) PATCH_BACKUP_DIR="${OPTARG:=${DEFAULT_PATCH_BACKUP_DIR}}" ;;

        "+d" ) PATCH_BACKUP_DIR="${DEFAULT_PATCH_BACKUP_DIR}" ;;

        "N" ) NO_OF_BACKUPS_TO_KEEP="${OPTARG:=${DEFAULT_NO_OF_BACKUPS_TO_KEEP}}" ;;

        "+N" ) NO_OF_BACKUPS_TO_KEEP="${DEFAULT_NO_OF_BACKUPS_TO_KEEP}" ;;

        "x" ) ACTION="doit" ;;

        "+x" ) ACTION="dryrun" ;;

        "o" ) OUTPUT_FILE="${OPTARG:=${DEFAULT_OUTPUT_FILE}}" ;;

        "+o" ) OUTPUT_FILE="" ;;

        "s" )  SUMMARIZE=${__TRUE} ;;

        "+s" )  SUMMARIZE=${__FALSE} ;;

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
  
   
# ??? add parameter checking code here 
#
# set INVALID_PARAMETER_FOUND to ${__TRUE} if the script
# should abort due to an invalid parameter 
#
  if [ "${NOT_PROCESSED_PARAMETER}"x != ""x ] ; then
    LogError "Unknown parameter: \"${NOT_PROCESSED_PARAMETER}\" "
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

# check the parameter
#
  isNumber "${NO_OF_BACKUPS_TO_KEEP}" || \
    die 10 "The value for the parameter -N (${NO_OF_BACKUPS_TO_KEEP}) is not numeric"

  [ -d "${PATCH_BACKUP_DIR}" ] || \
    die 15 "The directory \""${PATCH_BACKUP_DIR}"\" does not exist"

  if [ "${OUTPUT_FILE}"x != ""x ] ; then
    touch "${OUTPUT_FILE}" 2>/dev/null || \
      die 17 "Can not write to the file \"${OUTPUT_FILE}\" "

BackupFileIfNecessary "${OUTPUT_FILE}"
    cat <<EOT >"${OUTPUT_FILE}"
#!/usr/bin/ksh
# This script will delete the backups of selected patches
# This script was generated by ${__SCRIPTNAME} $( date )
# 
#
if [ \$# -ne 1 -o "\$1"x != "doit"x ] ; then
  echo "Usage: ${OUTPUT_FILE} {doit}"
  exit 5
fi
EOT
    [ $? -ne 0 ] &&  die 17 "Can not write to the file \"${OUTPUT_FILE}\" "
  fi
  
  case "${PATCH_TYPE}" in
  
    all | obsolete ) :
      ;;
      
    * ) 
      die 20 "The value for the parameter -t (${PATCH_TYPE}) is unknown."
      ;;
  esac


# read the list of existing patch backups
  LogMsg "Gathering information about the existing patch backups ..."

  LIST_OF_PATCH_BACKUPS=$( for i in $(  ls -1d ${PATCH_BACKUP_DIR}/*/save/[0-9]* ) ; do echo ${i##*/} ; done  | sort | uniq )
  [ "${LIST_OF_PATCH_BACKUPS}"x = ""x ] && die 25 "No patch backup directories found"
  
  PATCH_VARIABLES=""

  if [ "${PATCH_TYPE}" = "obsolete" ] ; then
    LogMsg "Processing only obsolete patches "
  else
    LogMsg "Processing all patches "
  fi
  LogMsg "Will preserve ${NO_OF_BACKUPS_TO_KEEP} backup(s) of the patches"
  case $ACTION in
    "doit" ) 
                LogMsg "Patch backup directories are deleted."
                ;;
                
    "dryrun" | * )
                LogMsg "dryrun - only list the directories to delete but do NOT delete them"
                ;;
 esac

  
  if [ "${OUTPUT_FILE}"x != ""x ] ; then
    LogMsg "The commands to delete the backups are written to the file "
    LogMsg "  \"${OUTPUT_FILE}\" "
  fi

  typeset -i SPACE_USED_BY_ALL_PATCH_BACKUPS=0
  typeset -i SPACE_USED_BY_THIS_PATCH_BACKUP=0
  
  for CUR_PATCH in ${LIST_OF_PATCH_BACKUPS} ; do
    ls ${PATCH_BACKUP_DIR}/*/save/${CUR_PATCH}/obsoleted_by >/dev/null 2>/dev/null
    [ $? -eq 0 ] && CUR_PATCHTYPE="obsolete" || CUR_PATCHTYPE="active"
    LogInfo "  Processing the patch \"${CUR_PATCH}\" (Type: \"${CUR_PATCHTYPE}\" ) ..."

    CUR_PATCHNO="${CUR_PATCH%%-*}"
    CUR_PATCHREV="${CUR_PATCH##*-}"
    VARNAME="PATCH_${CUR_PATCHNO}"
    if [[  ( "${PATCH_TYPE}" = "obsolete"  && ${CUR_PATCHTYPE} = "obsolete"  ) || "${PATCH_TYPE}" = "all"  ]] ; then
      LogInfo "    Saving the information about the patch backup "
      eval "${VARNAME}=\"\$${VARNAME} \${CUR_PATCHREV}\""
      pos "${VARNAME}" " ${PATCH_VARIABLES} "
      [ $? -eq 0 ] && PATCH_VARIABLES="${PATCH_VARIABLES} ${VARNAME}"
    else
      LogInfo "    Ignoring the patch because of the wrong type"
    fi
  done

  LogMsg "Processing the patch backups ..."
  for VARNAME in ${PATCH_VARIABLES} ; do
    CUR_PATCH="${VARNAME##*_}"
    LogMsg "  Processing the patch \"${CUR_PATCH}\" ..."
    
    CUR_REVISIONS=$( eval "echo \$${VARNAME}" )
    LogMsg "    Backup to delete for this patch: \"${CUR_REVISIONS}\" "
    set -- ${CUR_REVISIONS}

    while [ $# -gt ${NO_OF_BACKUPS_TO_KEEP} ] ; do
      CUR_PATCH_REV="${CUR_PATCH}-$1"
      THIS_REV=$1
      shift      
      PATCH_BACKUP_DIRS="$( ls -d ${PATCH_BACKUP_DIR}/*/save/${CUR_PATCH_REV} )"
      if [ $? -ne 0 -o "${PATCH_BACKUP_DIRS}"x = ""x ] ; then
        LogWarning "No backup directories found for the patch \"${CUR_PATCH_REV}\" "
        continue
      fi

      if [ "${OUTPUT_FILE}"x != ""x ] ; then
        echo "#### Patch ${CUR_PATCH_REV} " >>"${OUTPUT_FILE}"
      fi 

      if [ ${SUMMARIZE} = ${__TRUE} ] ; then
        SPACE_USED_BY_THIS_PATCH_BACKUP=0
        for CUR_BACKUP_DIR in ${PATCH_BACKUP_DIRS} ; do
          LogInfo "  Calculating the space for the directory \"${CUR_BACKUP_DIR}\" ... "
          i=$( du -ks ${CUR_BACKUP_DIR} | cut -f1 )
          (( SPACE_USED_BY_ALL_PATCH_BACKUPS = SPACE_USED_BY_ALL_PATCH_BACKUPS  + i ))
          (( SPACE_USED_BY_THIS_PATCH_BACKUP = SPACE_USED_BY_THIS_PATCH_BACKUP  + i ))
        done

        if [ "${OUTPUT_FILE}"x != ""x ] ; then
          echo "#### Diskspace used by the backup of the rev ${THIS_REV} of this patch: ${SPACE_USED_BY_THIS_PATCH_BACKUP}k" >>"${OUTPUT_FILE}"
        fi
      fi

      if [ "${OUTPUT_FILE}"x != ""x ] ; then
        echo "echo " Removing the backup of the patch ${CUR_PATCH_REV} ..." " >>"${OUTPUT_FILE}"

        for CUR_BACKUP_DIR in ${PATCH_BACKUP_DIRS} ; do
          echo "rm -r \"${CUR_BACKUP_DIR}\" " >> "${OUTPUT_FILE}"
        done
      fi
     
      case ${ACTION} in

        "doit" ) 
        
          LogInfo "Removing the directories for patch \"${CUR_PATCH_REV}\""
          for CUR_BACKUP_DIR in ${PATCH_BACKUP_DIRS} ; do
            LogInfo "    Removing the directory \"${CUR_BACKUP_DIR}\" ..."
            rm -r "${CUR_BACKUP_DIR}"
            THISRC=$?
            if [ ${THISRC} -ne 0 ] ; then 
              LogError "Error ${THISRC} removing the directory \"${CUR_BACKUP_DIR}\" "
            fi
          done
          ;;
          
        "dryrun" ) 
        
          LogInfo "Print the directories for patch \"${CUR_PATCH_REV}\""
          for CUR_BACKUP_DIR in ${PATCH_BACKUP_DIRS} ; do
            LogInfo "    Would remove the directory \"${CUR_BACKUP_DIR}\" ..."
          done
          ;;
          
      esac
      
      if [ ${SUMMARIZE} = ${__TRUE} ] ; then
        LogMsg "    Diskspace used by the backup of the rev ${THIS_REV} of this patch: ${SPACE_USED_BY_THIS_PATCH_BACKUP}k"
      fi

    done
    
  done

  LogMsg "-"

  case $ACTION in
    "doit" ) 
                LogMsg "Patch backup directories deleted."
                ;;
                
    "dryrun" | * )
                LogMsg "dryrun - no patch backups were deleted"
                ;;
 esac

  if [ ${SUMMARIZE} = ${__TRUE} ] ; then
      LogMsg "Diskspace used by all patch backups processed: ${SPACE_USED_BY_ALL_PATCH_BACKUPS}k"
  fi

  if [ "${OUTPUT_FILE}"x != ""x ] ; then
    LogMsg "The commands to delete the backups are written to the file \"${OUTPUT_FILE}\" "
    chmod 755 "${OUTPUT_FILE}"
  fi

  die ${__MAINRC} 
 
exit
