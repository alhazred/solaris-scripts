#!/usr/bin/ksh
#
# Note: use "/usr/bin/ksh -i" if the signal handler do not work
#
# ****  Note: The main code starts after the line containing "# main:" ****
#             The main code for your script should start after "# main - your code"
#             Function statt after the line containing "# functions: "
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
# Copyright 2006-2014 Bernd Schemmer  All rights reserved.
# Use is subject to license terms.
#
# Notes:
#
# - use "execute_scripts.sh {-v} {-v} {-v} -h" to get the usage help
#
# - use "execute_scripts.sh -H 2>execute_scripts.sh.doc" to get the documentation
#
# - use "execute_scripts.sh -X 2>execute_scripts.sh.examples.doc" to get some usage examples
#
# - this is a Kornshell script - it may not function correctly in other shells
# - the script was written and tested with ksh88 but should also work in ksh93
#   The script should also work in bash -- but that is NOT completly tested
#
# ??? Add usage examples here; the lines should start with ##EXAMPLE##
#
##EXAMPLE##
##EXAMPLE##
##EXAMPLE## # create the documentation for the script
##EXAMPLE##
##EXAMPLE##   ./${__SCRIPTNAME} -H 2>./${__SCRIPTNAME}.doc
##EXAMPLE##
##EXAMPLE## # get the verbose usage for the script
##EXAMPLE##
##EXAMPLE##   ./${__SCRIPTNAME} -v -v -h
##EXAMPLE##
##EXAMPLE## # write a config file for the script
##EXAMPLE##
##EXAMPLE##   ./${__SCRIPTNAME} -C
##EXAMPLE##
##EXAMPLE##
##EXAMPLE## # use another config file
##EXAMPLE##
##EXAMPLE##   CONFIG_FILE=myconfig.conf ./${__SCRIPTNAME}
##EXAMPLE##
##EXAMPLE## # use no config file at all
##EXAMPLE##
##EXAMPLE##   CONFIG_FILE=none ./${__SCRIPTNAME}
##EXAMPLE##
##EXAMPLE##
##EXAMPLE## # write all output (STDOUT and STDERR) to the file
##EXAMPLE## #   /var/tmp/mylog.txt
##EXAMPLE##
##EXAMPLE##    __TEE_OUTPUT_FILE=/var/tmp/mylog.txt ./${__SCRIPTNAME} -T
##EXAMPLE##
##EXAMPLE##
##EXAMPLE## # create a dump of the environment variables in the files
##EXAMPLE## #   /tmp/${__SCRIPTNAME}.envvars.\$\$
##EXAMPLE## #   /tmp/${__SCRIPTNAME}.exported_envvars.\$\$
##EXAMPLE## # (\$\$ is the PID of the process running the script)
##EXAMPLE##
##EXAMPLE##    __CREATE_DUMP=1 ./${__SCRIPTNAME}
##EXAMPLE##
##EXAMPLE## # create a dump of the environment variables in the files
##EXAMPLE## #   /var/tmp/debug/${__SCRIPTNAME}.envvars.\$\$
##EXAMPLE## #   /var/tmp/debug/${__SCRIPTNAME}.exported_envvars.\##EXAMPLE## # (\$\$ is the PID of the process running the script)
##EXAMPLE## # (\$\$ is the PID of the process running the script)
##EXAMPLE##
##EXAMPLE##    __CREATE_DUMP=/var/tmp/debug ./${__SCRIPTNAME}
##EXAMPLE##
#
# Note: The escape character in the command below is only for the usage of execute_scripts.sh with the "-X" parameter!
#
##EXAMPLE## # use logger instead of echo to print the messages
##EXAMPLE##
##EXAMPLE##    LOGMSG_FUNCTION=\"logger -s -p user.info execute_scripts.sh\"  ./execute_scripts.sh
##EXAMPLE##

# -----------------------------------------------------------------------------
####
#### execute_scripts.sh - execute scripts parallel or sequentiell
####../../../../
#### Author: Bernd Schemmer (Bernd.Schemmer@gmx.de)
####
#### Version: see variable ${__SCRIPT_VERSION} below
####          (see variable ${__SCRIPT_TEMPLATE_VERSION} for the template version used)
####
#### Supported OS: Solaris and others
####
####
#### Description
#### -----------
####
#### execute scripts either parallel or sequentiell
##C#
##C# Configuration file
##C# ------------------
##C#
##C# This script supports a configuration file called <scriptname>.conf.
##C# The configuration file is searched in the working directory,
##C# the home directory of the user executing this script and in /etc
##C# (in this order).
##C#../../../../
##C# The configuration file is read before the parameter are processed.
##C#
##C# To override the default config file search set the variable
##C# CONFIG_FILE to the name of the config file to use.
##C#
##C# e.g. CONFIG_FILE=/var/myconfigfile ./execute_scripts.sh
##C#
##C# To disable the use of a config file use
##C#
##C#     CONFIG_FILE=none ./execute_scripts.sh
##C#
##C# See the variable __CONFIG_PARAMETER below for the possible entries
##C# in the config file.
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
##T#  __CREATE_DUMP=1 ./execute_scripts.sh
##T#
##T# will create a dump of the environment variables in the files
##T#
##T#   /tmp/execute_scripts.sh.envvars.$$
##T#   /tmp/execute_scripts.sh.exported_envvars.$$
##T#
##T# before the script ends
##T#
##T#  __CREATE_DUMP=/var/tmp/debug ./execute_scripts.sh
##T#
##T# will create a dump of the environment variables in the files
##T#
##T#   /var/tmp/debug/execute_scripts.sh.envvars.$$
##T#   /var/tmp/debug/execute_scripts.sh.exported_envvars.$$
##T#
##T# before the script ends (the target directory must already exist).
##T#
##T# Note that the dump files will always be created in case of a syntax
##T# error. To set the directory for these files use either
##T#
##T#   export __DUMPDIR=/var/tmp/debug
##T#   ./execute_scripts.sh
##T#
##T# or define __DUMPDIR in the script.
##T#
##T# To suppress creating the dump file in case of a syntax error add
##T# the statement
##T#
##T# __DUMP_ALREADY_CREATED=0../../../../
##T#
##T# to your script
##T#
##T# Use
##T#
##T#    CreateDump <uniqdirectory> [filename_add]
##T#
##T# to manually create the dump files from within the script.
##T#
##T# e.g.
##T#
##T#   CreateDump /var/debug
##T#
##T# will create the files
##T#
##T#   /var/debug/execute_scripts.sh.envvars.$$
##T#   /var/debug/execute_scripts.sh.exported_envvars.$$
##T#
##T#   CreateDump /var/debug pass2.
##T#
##T# will create the files
##T#
##T#   /var/debug/execute_scripts.sh.envvars.pass2.$$
##T#   /var/debug/execute_scripts.sh.exported_envvars.pass2.$$
##T#
####  Note:
####    The default action for the signal handler USR1 is
####    "Create an environment dump in /var/tmp"
####    The filenames for the dumps are
####
####      /var/tmp/<scriptname>.envvars.dump_no_<no>_<PID>
####      /var/tmp/<scriptname>.exported_envvars.dump_no_<no>_<PID>
####
####    where <no> is a sequential number, <PID> is the PID of the
####    process with the script, and <scriptname> is the name of the
####    script without the path.
####
####
#### User defined signal handler
#### ---------------------------
####
#### You can define various SIGNAL handlers to process signals received
#### by the script.
####
#### All SIGNAL handlers can use these variables:
####
#### __TRAP_SIGNAL -- the catched trap signal
#### INTERRUPTED_FUNCTION -- the function interrupted by the signal
####
####
#### To define one signal handler for all signals do:
####
####   __GENERAL_SIGNAL_FUNCTION=<signalhandler_name>
####
#### To define unique signal handler for the various signals do:
####
####   __SIGNAL_SIGUSR1_FUNCTION=<signalhandler_name>
####   __SIGNAL_SIGUSR2_FUNCTION=<signalhandler_name>
####   __SIGNAL_SIGHUP_FUNCTION=<signalhandler_name>
####   __SIGNAL_SIGINT_FUNCTION=<signalhandler_name>
####   __SIGNAL_SIGQUIT_FUNCTION=<signalhandler_name>
####   __SIGNAL_SIGTERM_FUNCTION=<signalhandler_name>
####
#### If both type of signal handler are defined the script first
#### executes the general signal handler.
#### If this handler returns 0 the handler for the catched signal will
#### also be executed (else not).
#### If the unique handler for the signal ends with 0 the default signal
#### handler for this signal will also be executed (else not)
####
####
#### Credits
#### -------
####
####   Hints regarding the code to create the lockfile
####     wpollock (http://wikis.sun.com/display/~wpollock)
####
####   Source for the function PrintWithTimeStamp (in version 2.x and newer):
####     http://unix.stackexchange.com/questions/26728/prepending-a-timestamp-to-each-line-of-output-from-a-command
####
####   Andreas Obermaier for a security issue in the lockfile routine
####     (see history section 1.22.45 07.06.2012)
####
####   The code used in executeCommandAndLog is from
####     http://www.unix.com/unix-dummies-questions-answers/13018-exit-status-command-pipe-line.html#post47559
####
####
#### History:
#### --------
####   1.0.0 07.06.2014 /bs
####     initial release
####
####   1.0.1 09.01.2016 /bs
####     die will now end the script even if the parameter -f is used
####
####   1.0.2 01.01.2017 /bs
####     replaced "set -o noglob" with "set -f" and "set -o glob" with "set +f"  to be compatible with shells
####     like mirksh that to not support the glob/noglob syntax
####
####   1.0.3 11.01.2019 /bs
####     __ingoretraps does not work on all ksh versions -- deleted
####     __unsettraps rewritten to work on more ksh versions
####     die now calls __unsettraps
####    LogRuntimeInfo rewritten to work on more ksh versions
####    code using LINENO corrected
####
####
#### script template History
#### -----------------------
####   1.22.0 08.06.2006 /bs  (BigAdmin Version 1)
####      public release; starting history for the script template
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
####.
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
####     The lockfile is now also deleted if the script crashes because of a syntax error or something like this
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
####     (an array in ksh88 can only handle up to 4096 entries)
####     added the variable __PIDFILE
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
####     corrected a cosmetic error in the messages (wrong: ${TEMPFILE#} correct: ${__TEMPFILE#})
####
####  1.22.37 08.07.2011 /bs
####     corrected a minor error with the QUIET parameter
####     added code to dump the environment (env var __CREATE_DUMP, function CreateDump )
####     implemented work around for missing function whence in bash
####     added the function LogIfNotVerbose
####
####  1.22.38 22.07.2011 /bs
####     added code to make the trap handling also work in bash
####     added a sample user defined trap handler (function USER_SIGNAL_HANDLER)
####     added the function SetHousekeeping to enabe or disable house keeping
####     scriptt.sh did not write all messages to the logfile if a relative filename was used - fixed
####     added more help text for "-v -v -v -h"
####     now user defined signal handler can have arguments
####     the RBAC feature (__USE_RBAC) did not work as expected - fixed
####     added new scriptt testsuite for testing the script template on other OS and/or shells
####     added the function SaveEnvironmentVariables
####
####  1.22.39 24.07.2011 /bs
####     __INIT_FUNCTION now enabled for cygwin also
####     __SHELL did not work in all Unixes - fixed
####     __OS_FULLNAME is now also set in Solaris and Linux
####
####  1.22.40 25.07.2011 /bs
####     added some code for ksh93 (functions: substr)
####     Note: set __USE_ONLY_KSH88_FEATURES to ${__TRUE} to suppress using the ksh93 features
####     The default action for the signal handler USR1 is now "Create an env dump in /var/tmp"
####     The filenames for the dumps are
####
####      /var/tmp/<scriptname>.envvars.dump_no_<no>_<PID>
####      /var/tmp/<scriptname>.exported_envvars.dump_no_<no>_<PID>
####
####     where <no> is a sequential number, <PID> is the PID of the process with the script,
####     and <scriptname> is the name of the script without the path.
####
####  1.22.41 26.09.2011 /bs
####     added the parameter -X
####     disabled some ksh93 code because "ksh -x -n" using ksh88 does not like it
####
####  1.22.42 05.10.2011 /bs
####     added the function PrintDotToSTDOUT
####
####  1.22.43 15.10.2011 /bs
####     added support for disabling the config file feature with CONFIG_FILE=none ./scriptt.sh
####     corrected a minor bug in SaveEnvironmentVariables
####     corrected a bug in the function SaveEnvironmentVariables
####     corrected a bug in getting the value for the variable ${__ABSOLUTE_SCRIPTDIR}
####
####  1.22.44 22.04.2012 /bs
####     The script now uses nawk only if available (if not awk is used)
####     variables are now supported in the usage examples (prefixed with ##EXAMPLE##)
####     add a line with the current date and time to variable dumps, e.g.
####
####         ### /var/tmp/scriptt.sh.exported_envvars.dump_no_0_20074 - exported environment variable dump created on Sun Apr 22 11:35:38 CEST 2012
####
####         ### /var/tmp/scriptt.sh.envvars.dump_no_0_20074 - environment variable dump created on Sun Apr 22 11:35:38 CEST 2012
####
####     added experimental interactive mode to the signal handler for USR2
####     replaced /usr/bin/echo with printf
####     added the variable LOGMSG_FUNCTION
####
####  1.22.45 07.06.2012 /bs
####     added code to check if the symbolic link for the lockfile already exists before creating
####     the lock file
####
####  1.22.46 27.04.2013 /bs
####     executeCommandAndLog rewritten using coprocesses (see also credits)
####     Info update: executeCommandAndLog does now return the RC of the executed
####                  command even if a logfile is defined
####
#### -------------------------------------------------------------------
####
####  2.0.0.0 17.05.2013 /bs
####     added the variable __GENERAL_SIGNAL_FUNCTION: This variable
####       contains the name of a function that is called for all SIGNALs
####       before the special SIGNAL handler is called
####     removed the Debug Handler for single step execution (due to the
####       length of the template it is not useful anymore; use the
####       version 1.x of scriptt.sh if you still need the Debug Handler)
####     function executeCommandAndLogSTDERR rewritten
####     removed the function CheckParameterCount
####     use lsb_release in Linux to retrieve OS infos if available
####     minor fixes for code and comments
####     replaced PrintWithTimeStamp with code that does not use awk
####     isNumber replaced with code that does not use sed
####
####  2.0.0.1 06.08.2013 /bs
####     added the variable __MACHINE_SUB_CLASS. Possible values
####     for sun4v machines: either "GuestLDom" or "PrimaryLDom"
####
####  2.0.0.2 01.09.2013 /bs
####     added the variables __SYSCMDS and __SYSCMDS_FILE
####
####  2.0.0.3 16.12.2013 /bs
####     now the Log-* functions return ${__TRUE} if a message is printed
####     and ${__FALSE} if not
####
####  2.0.0.4 01.01.2014 /bs
####     the alias __settrap is renamed to settraps (with leading s)
####     two new aliase are defined: __ingoretraps and __unsettraps
####     whence function for non-ksh compatible shells rewritten
####       without using ksh
####     the switch -D is now used to toggle debug switches
####       known debug switches:
####        help  -- print the usage help for -D
####         msg  -- log debug messages to /tmp/<scriptname>.<pid>.debug
####       trace  -- activate tracing to the file /tmp/<scriptname>.<pid>.trace
####     AskUser now accepts also "yes" and "no"
####     function IsFunctionDefined rewritten
####     now __LOGON_USERID and __USERID are equal to $LOGNAME until I
####     find a working solution
####       (the code in the previous version did not work if STDIN is not a tty)
####
####   2.0.0.5 08.01.2014 /bs
####      added the function executeFunctionIfDefined
####
####   2.0.0.6 17.01.2014 /bs
####      added the function PrintLine
####      added the debug options fn_to_stderr and fn_to_tty
####      max. return value for a function is 255 and therefor
####        the function for the stack and the functions pos and lastpo
####        now abort the script if a value greater than 255 should be returned
####      added the variables __HASHTAG, __SCRIPT_SHELL, and __SCRIPT_SHELL_OPTIONS
####

#### ----------------
#### Version variables
####
#### __SCRIPT_VERSION - the version of your script
####
####
typeset  -r __SCRIPT_VERSION="v1.0.3"

####

#### __SCRIPT_TEMPLATE_VERSION - version of the script template
####
typeset -r __SCRIPT_TEMPLATE_VERSION="2.0.0.6 17.01.2014"
####

#### ----------------
####
##R# Predefined return codes:
##R# ------------------------
##R#
##R#    1 - show usage and exit
##R#    2 - invalid parameter found
##R#
##R#  210 - 233 reserved for the runtime system
##R#  234 - The return value is greater than 255 in function x
##R#  235 - Invalid debug switch found
##R#  236 - syntax error
##R#  237 - Can not write to the debug log file
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
# awk basename cat cp cpio cut date dd dirname egrep expr find grep id ln ls nawk pwd
# reboot rm sed sh tee touch tty umount uname who zonename
#
# /usr/bin/pfexec
# /usr/ucb/whoami or $( whence whoami )
# /usr/openwin/bin/resize or $( whence resize )
#
# AIX: oslevel
#
# Linux: lsb_release
#
# -----------------------------------------------------------------------------
# variables for the trap handler

__FUNCTION="main"

#
# Note: The usage of the variable LINENO is different in the various ksh versions
#

# alias to install the trap handler
#
alias __settraps="
  trap 'GENERAL_SIGNAL_HANDLER SIGHUP    \${LINENO} \${__FUNCTION}' 1
  trap 'GENERAL_SIGNAL_HANDLER SIGINT    \${LINENO} \${__FUNCTION}' 2
  trap 'GENERAL_SIGNAL_HANDLER SIGQUIT   \${LINENO} \${__FUNCTION}' 3
  trap 'GENERAL_SIGNAL_HANDLER SIGTERM   \${LINENO} \${__FUNCTION}' 15
  trap 'GENERAL_SIGNAL_HANDLER SIGUSR1   \${LINENO} \${__FUNCTION}' USR1
  trap 'GENERAL_SIGNAL_HANDLER SIGUSR2   \${LINENO} \${__FUNCTION}' USR2
"

# alias to reset all traps to the defaults
#
alias __unsettraps="
  trap - 1
  trap - 2
  trap - 3
  trap - 15
  trap - USR1
  trap - USR2
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
####   If the script is not executed by ksh the shell is compatible to
###    ksh version $__KSH_VERSION
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


# ----------------------------------------------------------------------
# read the hash tag of the script
#
#### __HASHTAG - hash tag of the script
#### __SCRIPT_SHELL - shell in the hash tag of the script
#### __SCRIPT_SHELL_OPTIONS - shell options in the hash tag of the script
####
####
  __HASHTAG="$( head -1 $0 )"
  __SCRIPT_SHELL="${__HASHTAG#*!}"
  __SCRIPT_SHELL="${__SCRIPT_SHELL% *}"
  __SCRIPT_SHELL_OPTIONS="${__HASHTAG#* }"
  [ "${__SCRIPT_SHELL_OPTIONS}"x = "${__HASHTAG}"x ] && __SCRIPT_SHELL_OPTIONS=""

# -----------------------------------------------------------------------------
# specific settings for the various operating systems and shells
#
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

# old definition for whence:
#
# whence whence 2>/dev/null 1>/dev/null || function whence { ksh whence -p $* ; }

# new definition for whence:
#
whence whence 2>/dev/null 1>/dev/null || function whence {
  if typeset -f $1 1>/dev/null ; then
    echo $1
  elif alias $1 2>/dev/null 1>/dev/null  ; then
    echo $1
  else
    which $1 2>/dev/null
  fi
}


#### --------------------------------------------------------------------------
#### internal variables


# -----------------------------------------------------------------------------
####
#### __LOG_DEBUG_MESSAGES - log debug messages if set to true
####   This can be activated with the parameter -D msg
####
  __LOG_DEBUG_MESSAGES=${__FALSE}

# -----------------------------------------------------------------------------
#### __ACTIVATE_TRACE - log trace messages (set -x) if set to true
####   This can be activated with the parameter -D trace
###
  __ACTIVATE_TRACE=${__FALSE}

# -----------------------------------------------------------------------------
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
####   sample debug code:
####   __DEBUG_CODE="  eval echo Entering the subroutine \${__FUNCTION} ...  "
####
####   Note: Use an include script for more complicated debug code, e.g.
####   __DEBUG_CODE=" eval . /var/tmp/mydebugcode"
####
  __DEBUG_CODE=""

#### __FUNCTION_INIT - code executed at start of every sub routine
####   (see the hints for __DEBUG_CODE)
####   Default init code : install the trap handlers
####
#  __FUNCTION_INIT=" eval __settraps; echo  \"Now in function \${__FUNCTION}\" "
  __FUNCTION_INIT=" eval __settraps "

### variables for debugging
###
### __NO_CLEANUP - do not call the cleanup routine at all at script end if ${__TRUE}
###
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


# default log file for debug messages
#
# This filename is already defined here to catch all debug log messages
# The file will be deleted if the debug switch for writing this log
# is missing.
# To use this file enter the parameter "-D msg"
#
  __DEBUG_LOGFILE="/tmp/${0##*/}.$$.debug"

# default log file for trace output
# To use this file enter the parameter "-D trace"
#
  __TRACE_LOGFILE="/tmp/${0##*/}.$$.trace"

#### __CONFIG_PARAMETER
####   The variable __CONFIG_PARAMETER contains the configuration variables
####
#### The defaults for these variables are defined here. You
#### can use a config file to overwrite the defaults.
####
#### Use the parameter -C to create a default configuration file
####
#### Note: The config file is read and interpreted via ". configfile"
####       therefore you can also add some code here
####
__CONFIG_PARAMETER="__CONFIG_FILE_VERSION=\"${__SCRIPT_VERSION}\"
"'

# extension for backup files
#
  DEFAULT_BACKUP_EXTENSION=".$$.backup"

# allow the debug shell in AskUser
#
  __DEBUG_SHELL_IN_ASKUSER=${__TRUE}

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

# variables that can be changed via parameter
#

# default for the parameter -o
  DEFAULT_WORKDIR="/var/tmp/${__SCRIPTNAME##*/}.$$.work"

# execute the command in parallel? -- default for the parameter -d
  DEFAULT_EXECUTE_PARALLEL=${__FALSE}

# wait time in seconds for the background processes
#   -- 1st default for the parameter -W
  DEFAULT_MAX_RUN_WAIT_TIME=1h

# wait intervall in seconds for the background processes
#   -- 2nd default for the parameter -W
  DEFAULT_RUN_WAIT_INTERVALL=2s

# maximum number of background processes
#   -- 1st default for the parameter -w
  DEFAULT_MAX_NO_OF_BACKGROUND_PROCESSES=-1

# wait intervall for starting the background processes
#   -- 2nd default for the parameter -w
  DEFAULT_START_PROC_WAIT_INTERVALL=5s

# timeout value for the start of the parallel background processes
#  -- 3rd default for the parameter -w
  DEFAULT_START_PROC_TIMEOUT=5m


# scripts to execute  -- default for the parameter -i / -I
#
  DEFAULT_SCRIPTLIST=""

# scripts NOT to execute -- default for the parameter -x
#
  DEFAULT_SCRIPTEXCLUDE_LIST=""

# shell to use for script execution -- default for the parameter -c
#
  DEFAULT_SHELL_TO_USE="${__SCRIPT_SHELL}"

# add comments to the logfiles? -- default for the parameter -k
#
  DEFAULT_ADD_COMMENTS=${__TRUE}

# remove duplicate entries from the list of executables  -- default for the parameter -r
#
  DEFAULT_REMOVE_DUPLICATES=${__FALSE}

# start script -- default for the parameter -s
#
  DEFAULT_STARTSCRIPT=""

# start script -- default for the parameter -z
#
  DEFAULT_STOPSCRIPT=""

# stop after a script returns non-zero? -- default for the parameter -B
#
  DEFAULT_STOP_AFTER_ERROR=${__FALSE}

# no of lines of the logfile to list in case of an error -- defuaulf for the parameter -D no_of_error_loglines=n
#
  DEFAULT_NO_OF_ERROR_LOGLINES=10

 # no of lines of the logfile to list in case of no error -- defuaulf for the parameter -D no_of_ok_loglines=n
#
  DEFAULT_NO_OF_OK_LOGLINES=5

# no of lines of the logfile to list for parallel tasks -- defuaulf for the parameter -D no_of_logfile_lines=n
#
  DEFAULT_NO_OF_LOGFILE_LINES=10

# variables that can NOT be changed with parameter

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
typeset -r __SHORT_DESC="execute multiple excecutables either parallel or sequentiell"

#### __LONG_USAGE_HELP - Additional help if the script is called with
####   the parameter "-v -h"
####
####   Note: To use variables in the help text use the variable name without
####         an escape character, eg. ${OS_VERSION}
####
__LONG_USAGE_HELP='
      -I [listfile|directory|regex]
              The value for the parameter -I is either a file with a list
              of executables to execute, a directory, or a regular expression for files.

              If the value is a directory all executable files in in the
              directory will be executed.

              If the value is a regular expression all executables that
              match this regular expression will be executed.

              In both cases the script sorts the list of executables before
              adding them to the list of executables to execute

              A listfile is a file with a list of executables to execute
              The format of the file is:
                one executable per line, empty lines and lines beginning
                with a hash \"#\" are ignored.
              Parameter for the executables are NOT allowed.

              Use a comma \",\" to separate multiple listfiles or directories.
              or use the parameter \"-I\" more than one time.

              Missing listfiles or directories or regex that do not expand to
              a file are not treated as error.
              Current list of executables is: \"${SCRIPTLIST}\"
              Long format: --list

      -i executable
              \"executable\" is an executable to execute.
              Use a comma \",\" to separate multiple executables
              or use the parameter \"-i\" more than one time.
              Current list of executables is: \"${SCRIPTLIST}\"
              Long format: --exec

      -x executable
              exclude the executable \"executable\" from the execution
              Use a comma \",\" to separate multiple executables
              or use the parameter \"-i\" more than one time.
              Regular expressions for \"executable\" are allowed.
              Use \"-x none\" to clear the list of executables to exclude.
              Current value: \"${SCRIPTEXCLUDE_LIST}\"
              Long format: --exclude

      -s startscript
              The executable \"startscript\" is executed before
              all other executables. And it is always executed in the foreground
              Current value: \"${START_SCRIPT}\"
              Long format: --startscript

      -z stopscript
              The executable \"stopscript\" is executed after all other
              executables finished. And it is always executed in the foreground
              Current value: \"${STOP_SCRIPT}\"
              Long format: --stopscript

      -o working directory
              This is the directory used for temporary files and
              the log files of the executables.
              Current value: ${WORKDIR}
              Long format: --workdir

      -c shell_to_use
              \"shell_to_use\" is the shell to execute scripts
              use \"default\" to use the shell from this script and use
              \"none\" to use no explicit shell
              Current value \"${SHELL_TO_USE}\"
              Long format: --shell

       -r|+r remove duplicates from the list of executables
              Current value \"${REMOVE_DUPLICATES}\"
              Long format: --remove_duplicates

      -d|+d execute the commands in parallel
              Current value: $( ConvertToYesNo "${EXECUTE_PARALLEL}" )
              Long format: --parallel

      -k|+k add comments to the output file
              Current value: $( ConvertToYesNo "${ADD_COMMENTS}" )
              Long format: --nocomments

      -B|+B stop after an executable returns a non-zero return code
              (only if the executables are executed in sequentiell order)
              Current value: $( ConvertToYesNo "${STOP_AFTER_ERROR}" )
              Long format: --stop_after_error

      -W timeout[/intervall]
              \"timeout\" is the timeout for background processes and
              \"intervall\" is the wait intervall for background processes.
              Use \"-1\" or \"none\" for the timeout value to disable the
              timeout.
              Current values:
                Timeout: ${MAX_RUN_WAIT_TIME} (= $( CalculateSeconds ${MAX_RUN_WAIT_TIME} ) second(s) )
                Intervall: ${RUN_WAIT_INTERVALL} (= $( CalculateSeconds ${RUN_WAIT_INTERVALL} ) second(s) )
              Use a trailing \"m\" for times in minutes or a trailing \"h\"
              for times in hours; \"s\" is for seconds which is the default
              if neither \"m\" nor \"h\" is used.
              Use \"default\" for any value to use the default value.
              Use \" -W /intervall\" to only change the intervall.
              You can also use \",\" to separate the values.
              This parameter is only used if the commands are executed
              in parallel (parameter \"-d\")
              Long format: --timeout

      -w noOfBackgroundprocesses[/startIntervall[/maxStartTime]]
              \"noOfBackgroundprocesses\" is the max. number of background
              processes running at the same time, \"startIntervall\" is the
              wait intervall and \"maxStartTime\" is the timeout for starting
              the background processes.
              Use \"-1\" or \"none\" for an unlimited number of parallel
              background processes.
              Use \"-1\" or \"none\" for the timeout value to disable
              the timeout.
              Current values:
                Max. number of parallel running background processes: ${MAX_NO_OF_BACKGROUND_PROCESSES}
                Wait intervall: ${START_PROC_WAIT_INTERVALL} (= $( CalculateSeconds ${START_PROC_WAIT_INTERVALL} ) second(s) )
                Timeout value: ${START_PROC_TIMEOUT} (= $( CalculateSeconds ${START_PROC_TIMEOUT} ) second(s) )
              Use a trailing \"m\" for times in minutes or a trailing \"h\"
              for times in hours; \"s\" is for seconds which is the default
              if neither \"m\" nor \"h\" is used.
              Use \"default\" for any value to use the default value.
              Use \" -w /startIntervall\" to only change the start intervall.
              Use \" -w //maxStartTime\" to only change the timeout
              You can also use \",\" to separate the values.
              This parameter is only used if the commands are executed
              in parallel (parameter \"-d\")
              Long format: --noOfbackgroundProcesses
'

#### __SHORT_USAGE_HELP - Additional help if the script is called with the parameter "-h"
####
####   Note: To use variables in the help text use the variable name without an escape
####         character, eg. ${OS_VERSION}
####
__SHORT_USAGE_HELP='                           [-d|+d] [-W [timeout[/intervall]] [-w NoOfBackgroundProcs[/intervall[/timeout]]]] [-c shell] [-k|+k] [-r|+r] [-B|+B]
                           -I [listfile|directory|regex] [-i executable] [-x executable] [-o workdir] [-s startscript] [-z stopscript]

  The parameters -I or -i are mandatory.

  Use the parameter \"-v -h [-v]\" to view the detailed online help; use the parameter \"-X\" to view some usage examples.

  see also http://bnsmb.de/solaris/execute_scripts.html
'

#### __MUST_BE_ROOT - run script only by root (def.: false)
####   set to ${__TRUE} for scripts that must be executed by root only
####
__MUST_BE_ROOT=${__FALSE}

#### __REQUIRED_USERID - required userid to run this script (def.: none)
####   use blanks to separate multiple userids
####   e.g. "oracle dba sysdba"
####   "" = no special userid required (see also the variable __MUST_BE_ROOT)
####
__REQUIRED_USERID=""

#### __REQUIRED_ZONES - required zones (either global, non-global or local
####    or the names of the valid zones)
####   This is a Solaris only feature!
####   (def.: none)
####   "" = no special zone required
####
__REQUIRED_ZONES=""

#### __ONLY_ONCE - run script only once at a time (def.: false)
####   set to ${__TRUE} for scripts that can not run more than one instance at
####   the same time
####
__ONLY_ONCE=${__FALSE}

#### __ REQUIRED_OS - required OS (uname -s) for the script (def.: none)
####    use blanks to separate the OS names if the script runs under multiple OS
####    e.g. "SunOS"
####
__REQUIRED_OS=""

#### __REQUIRED_OS_VERSION - required OS version for the script (def.: none)
####   minimum OS version necessary, e.g. 5.10
####   "" = no special version necessary
####
__REQUIRED_OS_VERSION=""

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

#### __SYSCMDS - list of commands execute via one of the execute... functions
###
__SYSCMDS=""

#### __SYSCMDS_FILE - write the list of executed commands via the execute function to
####   this file at program end
####
__SYSCMDS_FILE=""

#### __EXITROUTINES - list of routines that should be executed before the script ends
####   Note: These routines are called *before* temporary files, temporary
####         directories, and temporary mounts are removed
####
__EXITROUTINES=""

#### __FINISHROUTINES - list of routines that should be executed before the script ends
####   Note: These routines are called *after* temporary files, temporary
####         directories, and temporary mounts are removed
####
__FINISHROUTINES=""

#### __GENERAL_SIGNAL_FUNCTION  - name of the function to execute if a signal is received
####   default signal handling: none
####
####   This variable can be used to define a general user defined signal handler for
####   all signals catched. If this signal handler is defined it will be called first
####   for every signal. If the handler returns 0 the user defined signal handler for
####   the signal will be called (if defined). If the handler returns a value other
####   than 0 no other signal handler is called.
####
####   see USER_SIGNAL_HANDLER for an example user signal handler
####
__GENERAL_SIGNAL_FUNCTION=""


#### __SIGNAL_SIGUSR1_FUNCTION  - name of the function to execute if the signal SIGUSR1 is received
####   default signal handling: create variable dump
####
####   If a user defined function ends with a return code not equal zero the default
####   action for the SIGUSR1 signal is not executed.
####
####   see USER_SIGNAL_HANDLER for an example user signal handler
####
 __SIGNAL_SIGUSR1_FUNCTION=""

#### __SIGNAL_SIGUSR2_FUNCTION  - name of the function to execute if the signal SIGUSR2 is received
####   default signal handling: call an interactive shell (experimental!)
####
####   If a user defined function ends with a return code not equal zero the default
####   action for the SIGUSR2 signal is not executed.
####
####   see USER_SIGNAL_HANDLER for an example user signal handler
####
 __SIGNAL_SIGUSR2_FUNCTION=""

#### __SIGNAL_SIGHUP_FUNCTION  - name of the function to execute if the signal SIGHUP is received
####   default signal handling: switch verbose mode on or off
####
####   If a user defined function ends with a return code not equal zero the default
####   action for the SIGHUP signal is not executed.
####
####   see USER_SIGNAL_HANDLER for an example user signal handler
####
 __SIGNAL_SIGHUP_FUNCTION=""

#### __SIGNAL_SIGINT_FUNCTION  - name of the function to execute if the signal SIGINT is received
####   default signal handling: end the script if ${__USER_BREAK_ALLOWED} is ${__TRUE} else ignore the signal
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
####   Note:
####   To use this feature it must be enabled in the function RebootIfNecessary!
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
####   use none to disable the config file feature
####
__CONFIG_FILE="${__SCRIPTNAME%.*}.conf"

#### __PIDFILE - save the pid of the script in a file
####
#### example usage: __PIDFILE="/tmp/${__SCRIPTNAME%.*}.pid"
####
__PIDFILE=""

#### __HOSTNAME - hostname
####
__HOSTNAME="$( uname -n )"

#### __NODENAME - nodename
####
__NODENAME=${__HOSTNAME}
[ -f /etc/nodename ] && __NODENAME="$( cat /etc/nodename )"

#### __OS_FULLNAME - Operating system (e.g. CYGWIN_NT-5.1)
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

#### __MACHINE_SUB_CLASS - Machine sub class
####   either GuestLDom or PrimaryLDom for sun4v LDoms
####
__MACHINE_SUB_CLASS=""

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
       if [ "${__MACHINE_CLASS}"x = "sun4v"x -a "${__ZONENAME}"x = "global"x ] ; then
         [ ! -d  /dev/usb ] && __MACHINE_SUB_CLASS="GuestLDom" || __MACHINE_SUB_CLASS="PrimaryLDom"
       fi
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
       __OS_FULLNAME="$( lsb_release -d -s 2>/dev/null )"
       [  "${__OS_FULLNAME}"x = ""x -a -r /etc/lsb-release ] && eval __OS_FULLNAME="$( grep DISTRIB_DESCRIPTION= /etc/lsb-release | cut -f2- -d "=" )"
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

#### LOGMSG_FUNCTION - function to write log messages
####   default: use "echo " to write in log functions
####
: ${LOGMSG_FUNCTION:=echo}


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
: ${__LOGIN_USERID:=${LOGNAME}}

#### __USERID - ID of the user executing this script (e.g. xtrnaw7)
####
: ${__USERID:=${LOGNAME}}


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

  if [ "${THIS_CONFIG}"x = "none"x ] ; then
    LogInfo "The use of a config file is disabled."
  else
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

  if [ "${THIS_CONFIG}"x = "none"x ] ; then
    LogInfo "The use of a config file is disabled."
  else
    [ "${THIS_CONFIG_FILE}"x = ""x ] && THIS_CONFIG_FILE="./${__CONFIG_FILE}"

    [ -f "${THIS_CONFIG_FILE}" ] &&  BackupFileIfNecessary "${THIS_CONFIG_FILE}"
    LogMsg "Writing the config file \"${THIS_CONFIG_FILE}\" ..."

    cat <<EOT >"${THIS_CONFIG_FILE}"
# config file for ${__SCRIPTNAME} ${__SCRIPT_VERSION}, created $( date )

${__CONFIG_PARAMETER}
EOT
    THISRC=$?
  fi

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

  [ ${__STACK_POINTER} -gt 255 ] && die 234 "The return value is greater than 255 in function \"${__FUNCTION}\""

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

  [ ${__STACK_POINTER} -gt 255 ] && die 234 "The return value is greater than 255 in function \"${__FUNCTION}\""

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
   "y" | "Y" | "yes" | "YES" | "Yes" | "true" | "True"  | "TRUE"  | 0 ) echo "y" ;;
   "n" | "N" | "no"  | "NO"  | "No" | "false" | "False" | "FALSE" | 1 ) echo "n" ;;
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
####     or substr sourceStr pos length resultVariable
####
#### returns: 1 - parameter missing
####          0 - parameter okay
####
function substr {
  typeset __FUNCTION="substr";    ${__FUNCTION_INIT} ; ${__DEBUG_CODE}

  typeset resultstr=""
  typeset THISRC=1

  if [ "$1"x != ""x ] ; then
    typeset s="$1" p="$2" l="$3"
    : ${l:=${#s}}
    : ${p:=1}

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

#### --------------------------------------
#### replacestr
####
#### replace a substring with another substring
####
#### usage: variable=$( replacestr sourceStr oldsubStr newsubStr )
####     or replacestr sourceStr oldsubStr newsubStr resultVariable
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
  typeset THISRC=0

  if [[ "${sourcestring}" == *${searchstring}* ]] ; then
    typeset f="${sourcestring%%${searchstring}*}"
    THISRC=$((  ${#f}+1 ))
  fi

  [ ${THISRC} -gt 255 ] && die 234 "The return value is greater than 255 in function \"${__FUNCTION}\""
  return ${THISRC}

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
  typeset THISRC=0

  if [[ "${sourcestring}" == *${searchstring}* ]] ; then
    typeset f="${sourcestring%${searchstring}*}"
    THISRC=$((  ${#f}+1 ))
  fi

  [ ${THISRC} -gt 255 ] && die 234 "The return value is greater than 255 in function \"${__FUNCTION}\""
  return ${THISRC}
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

# old code:
#  typeset TESTVAR="$(echo "$1" | sed 's/[0-9]*//g' )"
#  [ "${TESTVAR}"x = ""x ] && return ${__TRUE} || return ${__FALSE}

  [[ $1 == +([0-9]) ]] && return ${__TRUE} || return ${__FALSE}
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
#### usage: toUppercase sourceString | read resultVariable
####    or   targetString=$( toUppercase sourceString )
####    or   toUppercase sourceString resultVariable
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
#### usage: toLowercase sourceString | read resultVariable
####    or   targetString=$( toLowercase sourceString )
####    or   toLowercase sourceString resultVariable
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
####          4 - tracing is enabled
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

  if [ ${__ACTIVATE_TRACE} = ${__TRUE} ] ; then
    LogError "StartStop_LogAll_to_logfile can NOT be used if tracing is enabled (\"-D trace\")".
    return 4
  fi

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
          __GLOBAL_OUTPUT_REDIRECTION=""
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

  __SYSCMDS="${__SYSCMDS}
$@"

  set +e

  LogRuntimeInfo "Executing \"$@\" "

  eval "$@"
  THISRC=$?

  __SYSCMDS="${__SYSCMDS}
# RC=${THISRC}"

  return ${THISRC}
}

#### --------------------------------------
#### executeCommandAndLog
####
#### execute a command and write STDERR and STDOUT also to the logfile
####
#### usage: executeCommandAndLog command parameter
####
#### returns: the RC of the executed command (even if a logfile is used!)
####
function executeCommandAndLog {
  typeset __FUNCTION="executeCommandAndLog";    ${__FUNCTION_INIT} ; ${__DEBUG_CODE}

  set +e
  typeset THISRC=0

  __SYSCMDS="${__SYSCMDS}
$@"

  LogRuntimeInfo "Executing \"$@\" "

  if [ "${__LOGFILE}"x != ""x -a -f "${__LOGFILE}" ] ; then
    # LogMsg "# "$* 1>&2

    # The following trick is from
    # http://www.unix.com/unix-dummies-questions-answers/13018-exit-status-command-pipe-line.html#post47559
    exec 5>&1
    tee -a "${__LOGFILE}" >&5 |&
    exec >&p
    eval "$*" 2>&1
    THISRC=$?
    exec >&- >&5
    wait

# alternative:
#
#    THISRC=$( ( ( eval "$*" 2>&1; echo $? >&4 ) |tee "${__LOGFILE}" >&3 ) 4>&1 )

  else
    eval "$@"
    THISRC=$?
  fi

  __SYSCMDS="${__SYSCMDS}
# RC=${THISRC}"

  return ${THISRC}
}

#### --------------------------------------
#### executeCommandAndLogSTDERR
####
#### execute a command and write STDERR also to the logfile
####
#### usage: executeCommandAndLogSTDERR command parameter
####
#### returns: the RC of the executed command
####
function executeCommandAndLogSTDERR {
  typeset __FUNCTION="executeCommandAndLogSTDERR";    ${__FUNCTION_INIT} ; ${__DEBUG_CODE}

  set +e
  typeset THISRC=0

  __SYSCMDS="${__SYSCMDS}
$@"

  LogRuntimeInfo "Executing \"$@\" "

  if [ "${__LOGFILE}"x != ""x -a -f "${__LOGFILE}" ] ; then
    # The following trick is from
    # http://www.unix.com/unix-dummies-questions-answers/13018-exit-status-command-pipe-line.html#post47559
    exec 5>&2
    tee -a "${__LOGFILE}" >&5 |&
    exec 2>&p
    eval "$*"
    THISRC=$?
    exec  2>&5
    wait
  else
    eval "$@"
    THISRC=$?
  fi

  __SYSCMDS="${__SYSCMDS}
# RC=${THISRC}"

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
#### Source:  in v2.x and newer
####          http://unix.stackexchange.com/questions/26728/prepending-a-timestamp-to-each-line-of-output-from-a-command
####
function PrintWithTimestamp {
  typeset COMMAND="$*"
  LogInfo "Executing \"${COMMAND}\" ..."

  ${COMMAND} | while IFS= read -r line; do
    printf '[%s] %s\n' "$(date '+%Y-%m-%d %H:%M:%S')" "$line";
  done
}

#### --------------------------------------
#### LogMsg
####
#### print a message to STDOUT and write it also to the logfile
####
#### usage: LogMsg message
####
#### returns: ${__TRUE} - message printed
####          ${__FALSE} - message not printed
####
#### Notes: Use "- message" to suppress the date stamp
####        Use "-" to print a complete blank line
####
function LogMsg {
  typeset __FUNCTION="LogMsg";    ${__FUNCTION_INIT} ; ${__DEBUG_CODE}
  typeset THISRC=${__FALSE}

  if [ "$1"x = "-"x ] ; then
    shift
    typeset THISMSG="$*"
  elif [ "${__NO_TIME_STAMPS}"x = "${__TRUE}"x ] ; then
    typeset THISMSG="$*"
  else
    typeset THISMSG="[$(date +"%d.%m.%Y %H:%M:%S")] $*"
  fi

  if [  ${__QUIET_MODE} -ne ${__TRUE} ] ; then
    ${LOGMSG_FUNCTION} "${THISMSG} "
    THISRC=${__TRUE}
  fi

  [ "${__LOGFILE}"x != ""x ] && [ -f "${__LOGFILE}" ] &&  echo "${THISMSG}" >>"${__LOGFILE}"

  [ "${__DEBUG_LOGFILE}"x != ""x ] && [ -f "${__DEBUG_LOGFILE}" ] && echo "${THISMSG}" 2>/dev/null >>"${__DEBUG_LOGFILE}"

  return ${THISRC}
}

#### --------------------------------------
#### LogOnly
####
#### write a message to the logfile
####
#### usage: LogOnly message
####
#### returns: ${__TRUE} - message printed
####          ${__FALSE} - message not printed
####
function LogOnly {
  typeset __FUNCTION="LogOnly";    ${__FUNCTION_INIT} ; ${__DEBUG_CODE}
  typeset THISRC=${__FALSE}

  typeset THISMSG="[$(date +"%d.%m.%Y %H:%M:%S")] $*"

  if [ "${__LOGFILE}"x != ""x ] ; then
    if [ -f "${__LOGFILE}" ] ; then
      echo "${THISMSG}" >>"${__LOGFILE}"
      THISRC=${__TRUE}
    fi
  fi

  [ "${__DEBUG_LOGFILE}"x != ""x ] && [ -f "${__DEBUG_LOGFILE}" ] && echo "${THISMSG}" 2>/dev/null  >>"${__DEBUG_LOGFILE}"

  return ${THISRC}
}

#### --------------------------------------
#### LogIfNotVerbose
####
#### write a message to stdout and the logfile if we are not in verbose mode
####
#### usage: LogIfNotVerbose message
####
#### returns: ${__TRUE} - message printed
####          ${__FALSE} - message not printed
####
function LogIfNotVerbose {
  typeset __FUNCTION="LogIfNotVerbose";    ${__FUNCTION_INIT} ; ${__DEBUG_CODE}
  typeset THISRC=${__FALSE}

  if [ "${__VERBOSE_LEVEL}"x = "0"x ] ; then
    LogMsg "$*"
    THISRC=$?
  fi

  return ${THISRC}
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
#### returns: ${__TRUE} - message printed
####          ${__FALSE} - message not printed
####
function PrintDotToSTDOUT {
  typeset __FUNCTION="PrintDotToSTDOUT";    ${__FUNCTION_INIT} ; ${__DEBUG_CODE}

  typeset THISRC=$?
  typeset THISMSG=".\c"
  [ $# -ne 0 ] && THISMSG="$*"
  if [ "${__VERBOSE_LEVEL}"x = "0"x ] ; then
    printf "${THISMSG}"
    THISRC=${__TRUE}
  fi

  return ${THISRC}
}

#### --------------------------------------
#### LogInfo
####
#### print a message to STDOUT and write it also to the logfile
#### only if in verbose mode
####
#### usage: LogInfo [loglevel] message
####
#### returns: ${__TRUE} - message printed
####          ${__FALSE} - message not printed
####
#### Notes: Output goes to STDERR, default loglevel is 0
####
function LogInfo {
  typeset __FUNCTION="LogInfo";    ${__FUNCTION_INIT} ; ${__DEBUG_CODE}

#  [ ${__VERBOSE_MODE} -eq ${__TRUE} ] && LogMsg "INFO: $*"

  typeset THIS_TIMESTAMP="[$(date +"%d.%m.%Y %H:%M:%S")] "

  typeset THISLEVEL=0
  typeset THISRC=1


  if [ $# -gt 1 ] ; then
    isNumber $1
    if [ $? -eq ${__TRUE} ] ; then
      THISLEVEL=$1
      shift
    fi
  fi

  if [ "${__VERBOSE_MODE}" = "${__TRUE}" ] ; then
    if [ ${__VERBOSE_LEVEL} -gt ${THISLEVEL} ] ; then
      LogMsg "${__INFO_PREFIX}$*" >&2
      THISRC=$?
    fi
  fi

  [ ${THISRC} = 1 -a "${__DEBUG_LOGFILE}"x != ""x  ] && echo "${THIS_TIMESTAMP}${__INFO_PREFIX}$*" 2>/dev/null  >>"${__DEBUG_LOGFILE}"

  return ${THISRC}
}

# internal sub routine for info messages from the runtime system
#
# returns: ${__TRUE} - message printed
#          ${__FALSE} - message not printed
#
function LogRuntimeInfo {
  typeset __FUNCTION="LogRuntimeInfo";    ${__FUNCTION_INIT} ; ${__DEBUG_CODE}
  typeset THISRC=${__FALSE}
  
  typeset ORG__INFO_PREFIX="${__INFO_PREFIX}"
  
  __INFO_PREFIX="${__RUNTIME_INFO_PREFIX}"
  
  LogInfo "${__RT_VERBOSE_LEVEL}" "$*"
  THISRC=$?

  __INFO_PREFIX="${ORG__INFO_PREFIX}"
	  
  return ${THISRC}
}

# internal sub routine for header messages
#
# returns: ${__TRUE} - message printed
#          ${__FALSE} - message not printed
#
function LogHeader {
  typeset THISRC=${__FALSE}

  if [ "${__NO_HEADERS}"x != "${__TRUE}"x ] ; then
    LogMsg "$*"
    THISRC=${__TRUE}
  else
    [ "${__DEBUG_LOGFILE}"x != ""x ] && [ -f "${__DEBUG_LOGFILE}" ] && echo "$*" 2>/dev/null  >>"${__DEBUG_LOGFILE}"
  fi

  return ${THISRC}
}

#### --------------------------------------
#### LogWarning
####
#### print a warning to STDERR and write it also to the logfile
####
#### usage: LogWarning message
####
#### returns: ${__TRUE} - message printed
####          ${__FALSE} - message not printed
####
#### Notes: Output goes to STDERR
####
function LogWarning {
  typeset __FUNCTION="LogWarning";    ${__FUNCTION_INIT} ; ${__DEBUG_CODE}
  typeset THISRC=${__FALSE}

  LogMsg "${__WARNING_PREFIX}$*" >&2
  THISRC=$?
  (( __NO_OF_WARNINGS = __NO_OF_WARNINGS +1 ))
  __LIST_OF_WARNINGS="${__LIST_OF_WARNINGS}
${__WARNING_PREFIX}$*"
  return ${THISRC}
}

#### --------------------------------------
#### LogError
####
#### print an error message to STDERR and write it also to the logfile
####
#### usage: LogError message
####
#### returns: ${__TRUE} - message printed
####          ${__FALSE} - message not printed
####
#### Notes: Output goes to STDERR
####
function LogError {
  typeset __FUNCTION="LogError";    ${__FUNCTION_INIT} ; ${__DEBUG_CODE}
  typeset THISRC=$?

  if [ ${__ACTIVATE_TRACE} = ${__TRUE} ] ; then
    LogMsg "${__ERROR_PREFIX}$*" >&3
    THISRC=$?
  else
    LogMsg "${__ERROR_PREFIX}$*" >&2
    THISRC=$?
  fi

  (( __NO_OF_ERRORS=__NO_OF_ERRORS + 1 ))
  __LIST_OF_ERRORS="${__LIST_OF_ERRORS}
${__ERROR_PREFIX}$*"

  return ${THISRC}
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
        cd "$1" && find . -depth -print | cpio -pdumv "$2"
        THISRC=$?
        cd "${OLDPWD}"
     fi
  fi

  return ${THISRC}
}

#### --------------------------------------
#### DebugShell
####
#### Open a simple debug shell
####
#### Usage: DebugShell
####
#### returns: ${__TRUE}
####
#### Input is always read from /dev/tty; output always goes to /dev/tty
####
function DebugShell {
  typeset THISRC=${__TRUE}

  typeset USER_INPUT=""

  while true ; do
    printf "\n ------------------------------------------------------------------------------- \n"
    printf "${__SCRIPTNAME} - debug shell - enter a command to execute (\"exit\" to leave the shell)\n"
    printf ">> "
    read USER_INPUT

    case "${USER_INPUT}" in
      "exit" )
        break;
        ;;

      "functions" | "func" | "funcs" )
        typeset -f | grep "\{$"
        ;;

      "" )
        :
        ;;

      * )
        eval ${USER_INPUT}
        ;;
    esac

  done </dev/tty >/dev/tty

  "return" ${THISRC}
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

     * ) while true ; do
           [ $# -ne 0 ] && eval printf "\"$* \"" ${mySTDOUT}
           if [ ${__NOECHO} = ${__TRUE} ] ; then
             __STTY_SETTINGS="$( stty -g )"
             stty -echo
           fi

           eval read USER_INPUT ${mySTDIN}
           if [ "${USER_INPUT}"x = "shell"x -a ${__DEBUG_SHELL_IN_ASKUSER} = ${__TRUE} ] ; then
             DebugShell
           else
             [ "${USER_INPUT}"x = "#last"x ] && USER_INPUT="${LAST_USER_INPUT}"
             break
           fi
         done

         if [ ${__NOECHO} = ${__TRUE} ] ; then
           stty ${__STTY_SETTINGS}
           __STTY_SETTINGS=""
         fi

         case ${USER_INPUT} in

           "y" | "Y" | "yes" | "Yes") THISRC=${__TRUE}  ;;

           "n" | "N" | "no" | "No" ) THISRC=${__FALSE} ;;

           "all" ) __USER_RESPONSE_IS="y"  ; THISRC=${__TRUE}  ;;

           "none" )  __USER_RESPONSE_IS="n" ;  THISRC=${__FALSE} ;;

           * )  THISRC=${__FALSE} ;;

        esac
        ;;
  esac

  [ "${USER_INPUT}"x != ""x ] && LAST_USER_INPUT="${USER_INPUT}"

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
####     - and ends the program or reboots the machine if requested
####
####
function die {
  typeset __FUNCTION="die";    ${__FUNCTION_INIT} ; ${__DEBUG_CODE}

  [ "${__TRAP_SIGNAL}"x != ""x ] &&  LogRuntimeInfo "__TRAP_SIGNAL is \"${__TRAP_SIGNAL}\""

  __unsettraps

  typeset THISRC=$1
  [ $# -ne 0 ] && shift

  if [ "$*"x != ""x ] ; then
    [ ${THISRC} = 0 ] && LogMsg "$*" || LogError "$*"
  fi

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
  [[ ${__LOG_DEBUG_MESSAGES} = ${__TRUE} ]] && LogHeader "The debug messages are logged to \"${__DEBUG_LOGFILE}\" "
  [[ ${__ACTIVATE_TRACE} = ${__TRUE} ]] && LogHeader "The trace messages are logged to \"${__TRACE_LOGFILE}\" "

#  __QUIET_MODE=${__FALSE}
  __END_TIME="$( date )"

  LogHeader "${__SCRIPTNAME} ${__SCRIPT_VERSION} started at ${__START_TIME} and ended at ${__END_TIME}."
  LogHeader "The RC is ${THISRC}."

  __EXIT_VIA_DIE=${__TRUE}

  if [ "${__GLOBAL_OUTPUT_REDIRECTION}"x != ""x ]  ; then
    StartStop_LogAll_to_logfile "stop"
  fi

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

#### ---------------------------------------
#### executeFunctionIfDefined
####
#### execute a function if it's defined
####
#### usage: executeFunctionIfDefined [function_name] {function_parameter}
####
#### returns: the RC of the function [function_name] or 255 if the function
####          is not defined
####
#### notes:
####
function executeFunctionIfDefined {
  typeset __FUNCTION="executeFunctionIfDefined";    ${__FUNCTION_INIT} ; ${__DEBUG_CODE}

  typeset THISRC=255

  if [ $# -ne 0 ] ; then
    typeset THIS_FUNCTION="$1"
    shift

    LogRuntimeInfo "Searching the function \"${THIS_FUNCTION}\" ..."

    IsFunctionDefined "${THIS_FUNCTION}"
    if [ $? -eq ${__TRUE} ] ; then
      LogRuntimeInfo "The function \"${THIS_FUNCTION}\" is defined; now calling wit \"${THIS_FUNCTION} $@\" ..."
      ${THIS_FUNCTION} "$@"
      THISRC=$?
    fi

  fi
  return ${THISRC}
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

  LogRuntimeInfo "Trying to create the lock semaphore \"${__LOCKFILE}\" ..."
  if [ ${__USE_OLD_CODE} = ${__TRUE} ] ; then
# old code using ln
    ln -s  "$0" "${__LOCKFILE}" 2>/dev/null
    LN_RC=$?
  else
    __INSIDE_CREATE_LOCKFILE=${__TRUE}

# improved code from wpollock (see credits)
    if [ -L "${__LOCKFILE}" ] ; then
      LN_RC=1
    else
      set -C  # or: set -o noclobber
      : > "${__LOCKFILE}" 2>/dev/null
      LN_RC=$?
    fi
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
####    - write executed commands to ${__SYSCMDS_FILE} if requested
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

# write __SYSCMDS
  if [ "${__SYSCMDS_FILE}"x != ""x -a "${__SYSCMDS}"x != ""x ] ; then
    LogRuntimeInfo "Writing the list of executed commands to the file \"${__SYSCMDS_FILE}\" ..."
    echo "${__SYSCMDS}" >>"${__SYSCMDS_FILE}"
  fi

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
  typeset __DUMPDIR=""${__DUMPDIR:=${DEFAULT_DUMP_DIR}}""
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
    echo "### ${TMPFILE} - environment variable dump created on $( date)" >"${TMPFILE}"
    set >>"${TMPFILE}"

    TMPFILE="${__DUMPDIR}/${__SCRIPTNAME}.exported_envvars.${THISPARAM2}$$"
    LogMsg "Saving the current exported environment variables in the file \"${TMPFILE}\" ..."
    echo "### ${TMPFILE} - exported environment variable dump created on $( date)" >"${TMPFILE}"
    env >>"${TMPFILE}"

    THISRC=${__TRUE}
  fi


  return ${THISRC}
}

####
#### ##### defined trap handler (you may change them)
####

#### ---------------------------------------
#### IsFunctiondefined
####
#### check if a function is defined in this script
####
#### usage: IsFunctionDefined name_of_the_function
####
#### returns:  ${__TRUE} - the function is defined
####           ${__FALSE} - the function is not defined
####
####
function IsFunctionDefined {
  typeset __FUNCTION="IsFunctionDefined";   ${__FUNCTION_INIT} ;
  ${__DEBUG_CODE}

  typeset THISRC=${__FALSE}

  [ $# -eq 1 ] && typeset -f $1 >/dev/null && THISRC=${__TRUE}

  return ${THISRC}
}


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

  if [ "${__GENERAL_SIGNAL_FUNCTION}"x != ""x ] ; then
    LogRuntimeInfo "General user defined signal handler is declared: \"${__GENERAL_SIGNAL_FUNCTION}\" "
    IsFunctionDefined "${__GENERAL_SIGNAL_FUNCTION}"
    if [ $? -ne ${__TRUE} ] ; then
      LogRuntimeInfo "The general user defined signal handler is declared but not defined"
    else
      LogRuntimeInfo "Calling the general user defined signal handler now ..."
      ${__GENERAL_SIGNAL_FUNCTION}
      if [ $? -ne 0 ] ; then
        LogRuntimeInfo "General user defined signal handler \"${__GENERAL_SIGNAL_FUNCTION}\" ended with RC=$? -> not executing the other signal handler"
        return
      else
        LogRuntimeInfo "General user defined signal handler \"${__GENERAL_SIGNAL_FUNCTION}\" ended with RC=$? -> executing the other signal handler now"
      fi
    fi
  else
    LogRuntimeInfo "No general user defined signal handler defined."
  fi

  typeset __DEFAULT_ACTION_OK=${__TRUE}
  if [ "${__USER_DEFINED_FUNCTION}"x = ""x  ] ; then
    LogRuntimeInfo "No user defined function for signal \"${__TRAP_SIGNAL}\" declared"
  else
    LogRuntimeInfo "The user defined function for signal \"${__TRAP_SIGNAL}\" is \"${__USER_DEFINED_FUNCTION}\""
    IsFunctionDefined "${__USER_DEFINED_FUNCTION}"
    if [ $? -ne ${__TRUE} ] ; then
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
            LogMsg "-"
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
           (( __SIGUSR1_DUMP_NO = ${__SIGUSR1_DUMP_NO:=-1} +1 ))
          CreateDump  "/var/tmp" "dump_no_${__SIGUSR1_DUMP_NO}_"
        ;;

     "SIGUSR2" )
          CheckInputDevice
        if [ $? -eq 0 ] ; then
            printf "*** Entering interactive mode ***\n"
          while [ 0 = 0 ] ; do
            printf "Enter command to execute (exit to leave interactive mode): "
            printf "\n"
            read __USERINPUT
            [ "${__USERINPUT}"x = "exit"x ] && break
            eval ${__USERINPUT}
          done
          printf "*** Leaving interactive mode ***\n"
        else
          LogWarning "SIGUSR2: Input device is not a terminal"
        fi
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
          kill -9 $$ 2>/dev/null
        ;;

      * )
          die 254 "Unknown signal caught: ${__TRAP_SIGNAL}"
        ;;

    esac
  fi

}

# ======================================


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

  if [ "${__DEBUG_LOGFILE}"x != ""x ] ; then
    echo 2>/dev/null >"${__DEBUG_LOGFILE}"
  fi

  __START_TIME="$( date )"
  LogHeader "${__SCRIPTNAME} ${__SCRIPT_VERSION} started at ${__START_TIME}."

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

  if [ "${__NEW_LOGFILE}"x = "nul"x ] ; then
    LogHeader "Running without a log file"
    __MAIN_LOGFILE=""
# delete the temporary logfile
    rm "${__LOGFILE}" 2>/dev/null
    __LOGFILE=""
  else
    [ "${__NEW_LOGFILE}"x != ""x ] && __MAIN_LOGFILE="${__NEW_LOGFILE}"
    LogRuntimeInfo "Initializing the log file\"${__MAIN_LOGFILE}\" "

    touch "${__MAIN_LOGFILE}" 2>/dev/null
    cat "${__LOGFILE}" >>"${__MAIN_LOGFILE}" 2>/dev/null
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
#
  GetProgramDirectory "${__SCRIPTDIR}/${__SCRIPTNAME}" __ABSOLUTE_SCRIPTDIR

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
                           [-D debugswitch] [-a|+a] [-O|+O] [-f|+f] [-C] [-H] [-X] [-S n] [-V] [-T]
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
              current value: ${__NEW_LOGFILE:=${__DEF_LOGFILE}}
              Long format: --logfile
      +l    - do not write a logfile
              Long format: ++logfile
      -y|+y - assume yes to all questions or not
              Long format: --yes / ++yes
      -n|+n - assume no to all questions or not
              Long format: --no /++no
      -D|+D - debug switch
              current value: ${__DEBUG_SWITCHES}
              use "-D help" to list the known debug switches
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
    typeset __ENVVARS=$( IFS="#" ; printf "%s " ${__USED_ENVIRONMENT_VARIABLES}  )
    cat <<EOT
Environment variables that are used if set (0 = TRUE, 1 = FALSE):

EOT

    for __CURVAR in ${__ENVVARS} ; do
      echo "  ${__CURVAR} (Current value: \"$( eval echo \$${__CURVAR} )\")"
    done
  fi

  [ ${__VERBOSE_LEVEL} -gt 2 ] && egrep "^##[CRT]#" "$0" | cut -c5- 1>&2


  return 0
}

# -----------------------------------------------------------------------------


#### --------------------------------------
#### SetHousekeeping
####
#### do or do not house keeping (remove tmp files/directories; execute exit routines/finish routines) at script end
####
#### usage: SetHousekeeping [${__TRUE}|${__FALSE}]
####
#### parameter: ${__TRUE} | all - do house keeping
####            ${__FALSE} | none - no house keeping
####            nodelete - do all house keeping except removing temporary files and directories
####
#### returns:  0 - okay
####           1 - invalid usage
####
####
function SetHousekeeping {
  typeset __FUNCTION="SetHousekeeping";    ${__FUNCTION_INIT} ; ${__DEBUG_CODE}
  typeset THISRC=0

  case ${1} in

    ${__TRUE} | "all" )
      LogRuntimeInfo "Switching cleanup at script end on"
      __NO_CLEANUP=${__FALSE}
      __NO_EXIT_ROUTINES=${__FALSE}
      __NO_TEMPFILES_DELETE=${__FALSE}
      __NO_TEMPMOUNTS_UMOUNT=${__FALSE}
      __NO_TEMPDIR_DELETE=${__FALSE}
      __NO_FINISH_ROUTINES=${__FALSE}
     ;;

    ${__FALSE} | "none" )
      LogRuntimeInfo "Switching cleanup at script end off"
      __NO_CLEANUP=${__TRUE}
      __NO_EXIT_ROUTINES=${__TRUE}
      __NO_TEMPFILES_DELETE=${__TRUE}
      __NO_TEMPMOUNTS_UMOUNT=${__TRUE}
      __NO_TEMPDIR_DELETE=${__TRUE}
      __NO_FINISH_ROUTINES=${__TRUE}
      ;;

    "nodelete" )
      LogRuntimeInfo "Switching cleanup at script end to do-not-delete-files"
      __NO_CLEANUP=${__FALSE}
      __NO_EXIT_ROUTINES=${__FALSE}
      __NO_TEMPFILES_DELETE=${__TRUE}
      __NO_TEMPMOUNTS_UMOUNT=${__FALSE}
      __NO_TEMPDIR_DELETE=${__TRUE}
      __NO_FINISH_ROUTINES=${__FALSE}
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
__MACHINE_SUB_CLASS
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
####  + = date in the past
####  max. date difference : +/- 6 days
####
#### This function was only tested successfull in Solaris!
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
    LogMsg "Writing the selected environment variables to \"${THIS_FILE}\" ..."
    shift

    BackupFileIfNecessary "${THIS_FILE}"
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

      echo "${OUTPUT}" | sort | uniq | grep -v "^$" >"${THIS_FILE}"
      if [ $? -ne 0 ] ; then
        LogError "SaveEnvironmentVariables: Error $? writing to the file \"${THIS_FILE}\" "
      else
        THISRC=${__TRUE}
      fi
    fi
  fi

  return ${THISRC}
}


#### --------------------------------------
#### PrintLine
####
#### print a line with n times the character c
####
#### usage: PrintLine [n] {c}
####
#### returns:  ${__TRUE} - ok
####           ${__FALSE} - error
####
####
function PrintLine {
  typeset __FUNCTION="PrintLine";   ${__FUNCTION_INIT} ;
  ${__DEBUG_CODE}

# init the return code
  typeset THISRC=${__FALSE}

  if [ $# -ge 1 ] ; then
    typeset n=$1
    typeset c=$2
    typeset c=${c:=-}
    eval printf \'%0.1s\' "$c"\{1..$n\}
    typeset THISRC=${__TRUE}
  fi

  return ${THISRC}
}

# -----------------------------------------------------------------------------
# functions:
#

#### --------------------------------------
#### CalculateSeconds
####
#### convert a string like nnX where
####  X is s for seconds, m for minutes, and h for hours
####  to the approbiate number of seconds
####
#### usage: CalculateSeconds timeValue [resultVar]
####
#### returns:  ${__TRUE} - ok, if the parameter resultVar is found
####           resultVar contains the number of seconds else the
####           number of seconds is written to STDOUT.
####           ${__FALSE} - error, invalid format
####
####
function CalculateSeconds {
  typeset __FUNCTION="CalculateSeconds";   ${__FUNCTION_INIT} ;
  ${__DEBUG_CODE}

# init the return code
  typeset THISRC=${__TRUE}

  typeset TIME_VALUE="$1"
  typeset RESULT_VAR="$2"

  typeset TIME_CHAR="$( echo ${TIME_VALUE} | cut -c${#TIME_VALUE} )"

  typeset TIME_IN_SECONDS=""

  case ${TIME_CHAR} in
    "h" | "H" )
      (( TIME_IN_SECONDS = ${TIME_VALUE%${TIME_CHAR}} * 60 * 60 ))
      ;;

    "m" | "M" )
      (( TIME_IN_SECONDS = ${TIME_VALUE%${TIME_CHAR}} * 60 ))
      ;;

    "s" | "S")
      (( TIME_IN_SECONDS = ${TIME_VALUE%${TIME_CHAR}} ))
      ;;

    "1" | "2"| "3"| "4"| "5"| "6"| "7"| "8"| "9"| "0" )
      TIME_IN_SECONDS=${TIME_VALUE}
      ;;

    * )
      TIME_IN_SECONDS=""
      THISRC=${__FALSE}
      ;;

  esac

  if [ ${THISRC} = ${__TRUE} ] ; then
    if [ "${RESULT_VAR}"x != ""x ] ; then
      eval ${RESULT_VAR}="${TIME_IN_SECONDS}"
    else
      echo "${TIME_IN_SECONDS}"
    fi
  fi

  return ${THISRC}
}


#### --------------------------------------
#### check_SSH_agent_status
####
#### check if the ssh agent is running
####
#### usage: check_SSH_agent_statuscheck_SSH_agent_status
####
#### returns:  ${__TRUE} - ssh agent is running, SSH_AGENT_RUNNING is ${__TRUE}
####           ${__FALSE} - ssh agent is not running, SSH_AGENT_RUNNING is ${__FALSE}
####
####
function check_SSH_agent_status {
  typeset __FUNCTION="check_SSH_agent_status";   ${__FUNCTION_INIT} ;
  ${__DEBUG_CODE}

  SSH_AGENT_RUNNING=${__FALSE}
  if [ "${SSH_AUTH_SOCK}"x != ""x ] ; then
    [ -S "${SSH_AUTH_SOCK}" ] && SSH_AGENT_RUNNING=${__TRUE}
  fi

  return ${SSH_AGENT_RUNNING}
}

#### --------------------------------------
#### GetNumberOfRunningProcesses
####
#### get the number of still running processes
####
#### usage: GetNumberOfRunningProcesses {list_of_pids}
####
#### returns:  writes the number of still running processes to STDOUT
####
####
function GetNumberOfRunningProcesses {
  typeset __FUNCTION="GetNumberOfRunningProcesses";   ${__FUNCTION_INIT} ;
  ${__DEBUG_CODE}

# init the return code
  typeset THISRC=${__FALSE}

  typeset BACKGROUND_PIDS=$*
  typeset NO_OF_RUNNING_PIDS=0

  if [ "${BACKGROUND_PIDS}"x != ""x ] ; then

    if [[ "${__OS}"x == CYGWIN*  ]] ; then
      typeset i
      NO_OF_RUNNING_PIDS=0
      for i in ${BACKGROUND_PIDS} ; do
        ps -p $i >/dev/null && (( NO_OF_RUNNING_PIDS = NO_OF_RUNNING_PIDS + 1 ))
      done
    else
      set -- $( ps -o pid= -p "${BACKGROUND_PIDS}" )
      NO_OF_RUNNING_PIDS=$#
    fi
    THISRC=${__TRUE}
  fi
  echo ${NO_OF_RUNNING_PIDS}

  return ${THISRC}
}



#### --------------------------------------
#### mycleanup
####
#### Housekeeping:
####   write the summaries
####   cleanup the temporary
####   kill still running background processes
####
#### usage: mycleanup
####
#### returns:  nothing
####
function mycleanup {
  typeset __FUNCTION="mycleanup";   ${__FUNCTION_INIT} ;
  ${__DEBUG_CODE}

  if [ "${PROCESSING_STARTED}"x = "${__TRUE}"x ] ; then

    typeset STILL_RUNNING_PIDS=""
    typeset KEEP_LOGFILES=${__FALSE}
    typeset CLEANUP_OUTPUT=""
    typeset CUR_PID

    LogMsg ""

    if [ ${NO_OF_SCRIPTS_EXECUTED} != 0 ] ; then
      LogMsg "-"
      LogMsg "${NO_OF_SCRIPTS_EXECUTED} executable(s) executed:"
      LogMsg "-" "${SCRIPTS_EXECUTED}"
    else
      LogWarning "No executables executed"
    fi

    if [ ${NO_OF_SCRIPTS_NOT_EXECUTED} != 0 ]  ; then
      LogMsg "-"
      LogMsg "${NO_OF_SCRIPTS_NOT_EXECUTED} executable(s) not executed due to an error."
      LogMsg "-" "${SCRIPTS_NOT_EXECUTED}"
    fi

    if [ ${NO_OF_SCRIPTS_EXCLUDED} != 0 ] ; then
      LogMsg "-"
      LogMsg "${NO_OF_SCRIPTS_EXCLUDED} executable(s) not executed because they are on the exclude list:"
      LogMsg "-" "${SCRIPTS_EXCLUDED}"
    fi

    LogMsg "-"
    LogMsg "The working directory was \"${WORKDIR}\"."
    LogMsg "-"

# kill still running background processes
    for CUR_PID in ${BACKGROUND_PIDS} ; do
      CUR_OUTPUT="$( ps -fp ${CUR_PID} )"
      if [ $? -eq 0 ] ; then
        LogMsg "Process ${CUR_PID} is still running: "
        LogMsg "${CUR_OUTPUT}"
        LogMsg "Killing the process ${CUR_PID} now  ..."
        kill ${CUR_PID}
     fi
    done

    for CUR_PID in ${BACKGROUND_PIDS} ; do
      CUR_OUTPUT="$( ps -fp ${CUR_PID} )"
      if [ $? -eq 0 ]  ; then
        LogMsg "Process ${CUR_PID} is still running: "
        LogMsg "${CUR_OUTPUT}"
        LogMsg "Killing the process ${CUR_PID} now with -9  ..."
        kill ${CUR_PID}
      fi
    done

    for CUR_PID in ${BACKGROUND_PIDS} ; do
      ps -p ${CUR_PID} >/dev/null && STILL_RUNNING_PIDS="${STILL_RUNNING_PIDS} ${CUR_PID}"
    done

    if [ "${STILL_RUNNING_PIDS}"x != ""x ] ; then
      LogError "There are still running background processes (kill -9 did not work): ${STILL_RUNNING_PIDS}"
      ps -p ${STILL_RUNNING_PIDS}

      KEEP_LOGFILES=${__TRUE}
    fi

  fi
}

#### --------------------------------------
#### USER_SIGNAL_HANDLER
####
#### template for a user defined trap handler
####
#### usage:
####   to define one signal handler for all signals do:
####
####     __GENERAL_SIGNAL_FUNCTION=USER_SIGNAL_HANDLER
####
####   to define unique signal handler for the various signals do:
####
####     __SIGNAL_<signal>_FUNCTION="USER_SIGNAL_HANDLER"
####
####   e.g.:
####
####     __SIGNAL_SIGUSR1_FUNCTION=USER_SIGNAL_HANDLER
####     __SIGNAL_SIGUSR2_FUNCTION=USER_SIGNAL_HANDLER
####     __SIGNAL_SIGHUP_FUNCTION=USER_SIGNAL_HANDLER
####     __SIGNAL_SIGINT_FUNCTION=USER_SIGNAL_HANDLER
####     __SIGNAL_SIGQUIT_FUNCTION=USER_SIGNAL_HANDLER
####     __SIGNAL_SIGTERM_FUNCTION=USER_SIGNAL_HANDLER
####
#### returns:  0 - execute the next action for this signal
####           else - do not execute the next action for this signal
####
#### Notes:
####    Depending on the return code of the signal handler the other
####    signal handler are called (RC=0) or not (RC<>0)
####
####    The call order is
####       - general user defined signal handler (if defined)
####       - signal specific user defined signal handler (if defined)
####       - default specific signal handler
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
#### host_on_the_exclude_list
####
#### check if a host is on the host exclude list
####
#### usage: YourRoutine
####
#### returns:  ${__TRUE} -  yes
####           ${__FALSE} - no
####
####
function host_on_the_exclude_list {
  typeset __FUNCTION="host_on_the_exclude_list";   ${__FUNCTION_INIT} ;
  ${__DEBUG_CODE}

# parameter
  typeset CUR_HOST="$1"

# local variables
#
  typeset HOST_EXCLUDE_MASK=""

# init the return code
  typeset THISRC=${__FALSE}

  if [ "$1"x != ""x ] ; then
    for HOST_EXCLUDE_MASK in ${EXCLUDE_HOSTS} ; do
      if [[ ${CUR_HOST} == ${HOST_EXCLUDE_MASK} ]] ; then
        HOSTS_EXCLUDED="${HOSTS_EXCLUDED} ${CUR_HOST}"
        THISRC=${__TRUE}
        break
      fi
    done
  fi

  return ${THISRC}
}


#### --------------------------------------
#### CheckExecutable
####
#### check if a directory entry is an executable file
####
#### usage: CheckExecutable filename
####
#### returns:  ${__TRUE} - yes
####           ${__FALSE} - no
####
####
function CheckExecutable {
  typeset __FUNCTION="CheckExecutable";   ${__FUNCTION_INIT} ;
  ${__DEBUG_CODE}

# init the return code
  typeset THISRC=${__FALSE}

  if [ $# -eq 1 ] ; then
    typeset CUR_FILE="$1"
    [ -f "${CUR_FILE}" -a -x "${CUR_FILE}" ] && THISRC=${__TRUE}
  fi

  return ${THISRC}
}

#### --------------------------------------
#### ProcessParameterI
####
#### Process the value of the parameter -I
#### (either a directory or file)
####
#### usage: ProcessParameterI [file|directory]
####
#### The function prints the list of found executables to STDOUT
####
#### returns:  ${__TRUE} - ok
####           ${__FALSE} - error
####
####
function ProcessParameterI {
  typeset __FUNCTION="ProcessParameterI";   ${__FUNCTION_INIT} ;
  ${__DEBUG_CODE}

# init the return code
  typeset THISRC=${__FALSE}
  typeset THIS_ARGS="$*"
  typeset CUR_ARG=""
  typeset CUR_FILE=""
  typeset SCRIPTLIST=""

  typeset -i i=0
  typeset -i j=0

  for CUR_ARG in ${THIS_ARGS} ; do
    LogInfo "Processing \"${CUR_ARG}\" ..."

    set -f
    [[ ${CUR_ARG} == *\** ]] && i=1
    [[ ${CUR_ARG} == *\?* ]] && j=1
    set +f

    if [ $j -ne 0 -o $i -ne 0 ] ; then
      LogInfo "Searching for executables matching the regular expression \"${CUR_ARG}\" ..."

      i=0 ; j=0

      for CUR_FILE in ${CUR_ARG} ; do

        substr "${CUR_FILE}" 1 1 FIRST_CHAR
        [ "${FIRST_CHAR}"x != "/"x ] && CUR_FILE="${PWD}/${CUR_FILE}"

        if [ -x "${CUR_FILE}" -a -f "${CUR_FILE}" ] ; then
          LogInfo "  ... found the executable \"${CUR_FILE}\" ..."
          SCRIPTLIST="${SCRIPTLIST} ${CUR_FILE}"
          (( i = i + 1 ))
        else
          LogInfo "  ... ignoring the non-executable \"${CUR_FILE}\" ..."
         (( j = j + 1 ))
        fi
      done
      LogInfo "... found $i executable(s) and $j non-executable(s)."
      [ $i = 0 ] && LogWarning "No executables found for the regular expression \"${CUR_ARG}\""

      echo "${SCRIPTLIST}" | sort

    elif [ -d "${CUR_ARG}" ] ; then
      LogInfo "Searching for executables in the directory \"${CUR_ARG}\" ..."
      cd "${CUR_ARG}"
      if [ $? -ne 0 ] ; then
        LogWarning "Can NOT read the directory contents of \"${CUR_ARG}\" "
        continue
      fi

      i=0 ; j=0
      set -f
      for CUR_FILE in * ; do
        if [ -x "${CUR_FILE}" -a -f "${CUR_FILE}" ] ; then
          LogInfo "  ... found the executable \"${CUR_FILE}\" ..."
          SCRIPTLIST="${SCRIPTLIST} ${PWD}/${CUR_FILE}"
          (( i = i + 1 ))
        else
          LogInfo "  ... ignoring the non-executable \"${CUR_FILE}\" ..."
         (( j = j + 1 ))
        fi
      done
      LogInfo "... found $i executable(s) and $j non-executable(s)."

      [ $i = 0 ] && LogWarning "No executables found in the directory \"${CUR_ARG}\""

      echo "${SCRIPTLIST}" | sort

    elif [ -f "${CUR_ARG}" ] ; then
      LogInfo "Checking the list of executables in the file \"${OPTARG}\" ..."

      i=0 ; j=0
      for CUR_FILE in $( egrep -v "^#|^$"  "${CUR_ARG}" ) ; do

        substr "${CUR_FILE}" 1 1 FIRST_CHAR
        [ "${FIRST_CHAR}"x != "/"x ] && CUR_FILE="${PWD}/${CUR_FILE}"

        if [ -x "${CUR_FILE}" -a -f "${CUR_FILE}" ] ; then
          LogInfo "  ... found the executable \"${CUR_FILE}\" ..."
          SCRIPTLIST="${SCRIPTLIST} ${CUR_FILE}"
          (( i = i + 1 ))
        else
          LogInfo "  ...  \"${CUR_FILE}\" not found or not executable."
          (( j = j + 1 ))
        fi
      done
      LogInfo "... found $i executable(s) and $j non-executable(s)."

      [ $i = 0 ] && LogWarning "No executables found from the list in the file \"${CUR_ARG}\""

      echo "${SCRIPTLIST}"
    else
      LogWarning "File/Directory \"${OPTARG}\" NOT found."
    fi
  done

  [ "${SCRIPTLIST}"x != ""x ] && THISRC=${__TRUE}

  return ${THISRC}
}

#### --------------------------------------
#### script_on_the_exclude_list
####
#### check if an executable is on the exclude list
####
#### usage: script_on_the_exclude_list executablename
####
#### returns:  ${__TRUE} - ok
####           ${__FALSE} - error
####
####
function script_on_the_exclude_list  {
  typeset __FUNCTION="script_on_the_exclude_list ";   ${__FUNCTION_INIT} ;
  ${__DEBUG_CODE}

# init the return code
  typeset THISRC=${__FALSE}

  typeset CUR_SCRIPT="$1"
  typeset CUR_REGEX=""

  set -f
  if [ $# -eq 1 ] ; then
    for CUR_REGEX in ${SCRIPTEXCLUDE_LIST} ; do
      if [[ ${CUR_SCRIPT} == ${CUR_REGEX} ]] ; then
        LogInfo "${CUR_SCRIPT} matches the exclude regex \"${CUR_REGEX}\" "
        THISRC=${__TRUE}
        break
      fi
    done
  fi

  return ${THISRC}
}

#### --------------------------------------
#### ViewLogfile
####
#### print all or parts of the logfile
####
#### usage: ViewLogfile logfile no_of_Lines
####
#### returns:  ${__TRUE} - ok
####           ${__FALSE} - error
####
####
function ViewLogfile {
  typeset __FUNCTION="ViewLogfile";   ${__FUNCTION_INIT} ;
  ${__DEBUG_CODE}

# init the return code
  typeset THISRC=${__FALSE}

  typeset THIS_LOGFILE="$1"
  typeset NO_OF_LINES="$2"

  case ${NO_OF_LINES} in

    0 ) :
      ;;

   -1 )
      LogMsg "The contents of the logfile \"${THIS_LOGFILE}\" are:"
      LogMsg "-"
      LogMsg "-------------------------------------"
      echo ${__COLOR_BG_YELLOW}
      cat "${THIS_LOGFILE}"
      echo ${__COLOR_NORMAL}
      LogMsg "-------------------------------------"
      LogMsg "-"

      THISRC=${__TRUE}
      ;;

    * )
      LogMsg "The last ${NO_OF_LINES} line(s) of the logfile \"${THIS_LOGFILE}\" are:"
      LogMsg "-"
      LogMsg "-------------------------------------"
      echo ${__COLOR_BG_YELLOW}
      tail -${NO_OF_LINES}  "${THIS_LOGFILE}"
      echo ${__COLOR_NORMAL}

      LogMsg "-------------------------------------"
      LogMsg "-"

      THISRC=${__TRUE}
      ;;
  esac

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
####
####
function YourRoutine {
  typeset __FUNCTION="YourRoutine";   ${__FUNCTION_INIT} ;
  ${__DEBUG_CODE}

# init the return code
  typeset THISRC=${__FALSE}

# add code here

  [ ${THISRC} -gt 255 ] && die 234 "The return value is greater than 255 in function \"${__FUNCTION}\""

  return ${THISRC}
}

# -----------------------------------------------------------------------------
# main:
#

# trace main routine
#
if [ 1 = 0 ] ; then
  set -x
  PS4='LineNo: $LINENO (sec: $SECONDS): >> '
fi

# install trap handler
  __settraps

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

# for debugging (no parameter are processed until now)
#
    if [ 1 = 0 ] ; then
      push_and_set __VERBOSE_MODE ${__TRUE}
      push_and_set __VERBOSE_LEVEL ${__RT_VERBOSE_LEVEL}
      LogInfo 0 "Setting variable $P2 to \"$( eval "echo \"\$$P1\"")\" "
      pop __VERBOSE_MODE
      pop __VERBOSE_LEVEL
    fi

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
#  __EXITROUTINES="${__EXITROUTINES} "

  SCRIPTS_EXCLUDED=""
  SCRIPTS_NOT_EXECUTED=""
  SCRIPTS_EXECUTED=""

  typeset -i NO_OF_SCRIPTS_EXCLUDED=0
  typeset -i NO_OF_SCRIPTS_NOT_EXECUTED=0
  typeset -i NO_OF_SCRIPTS_EXECUTED=0

  BACKGROUND_PIDS=""
  __EXITROUTINES="${__EXITROUTINES} mycleanup"

# add functions that should be called automatically at program end
# after removing temporary files, directories, and mounts
# to this variable
#
#  __FINISHROUTINES="${__FINISHROUTINES} "

  check_SSH_agent_status && SSH_AGENT_STATUS="running" || SSH_AGENT_STATUS="not running"

# variables used by getopts:
#    OPTIND = index of the current argument
#    OPTARG = current function character
#
  THIS_PARAMETER="$*"

  INVALID_PARAMETER_FOUND=${__FALSE}

  __PRINT_USAGE=${__FALSE}
  CUR_SWITCH=""
  OPTARG=""

  set -f

#
  [ "${__OS}"x = "Linux" ] &&  GETOPT_COMPATIBLE="0"


   __GETOPTS=":+:ynvqhHD:fl:aOS:CVTXI:i:x:o:dW:w:lc:s:z:rBk"
  if [ "${__OS}"x = "SunOS"x -a "${__SHELL}"x = "ksh"x ] ; then
    if [ "${__OS_VERSION}"x  = "5.10"x -o  "${__OS_VERSION}"x  = "5.11"x ] ; then
      __GETOPTS="+:y(yes)n(no)v(verbose)q(quiet)h(help)H(doc)D:(debug)f(force)l:(logfile)\
a(color)O(overwrite)S:(summaries)C(writeconfigfile)V(version)T(tee)X(view_examples)\
I:(list)i:(exec)x:(exlcude)o:(workdir)k(nocomments)c:(shell)s:(startscript)z:(stopscript)r(remove_duplicates)\
d(parallel)W:(timeout)w:(noOfbackgroundProcesses)x:(excludehost)A:(includehost)B(stop_after_error)"
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

       "D" ) __DEBUG_SWITCHES="${__DEBUG_SWITCHES} ${OPTARG}" ;;

      "+D" ) [ "${OPTARG}"x != "none"x ] && DEBUG_SWITCHES="${OPTARG}" || DEBUG_SWITCHES="" ;;

      "+v" ) __VERBOSE_MODE=${__FALSE}  ;;

       "v" ) __VERBOSE_MODE=${__TRUE} ; (( __VERBOSE_LEVEL=__VERBOSE_LEVEL+1 )) ;;

      "+q" ) __QUIET_MODE=${__FALSE} ;;

       "q" ) __QUIET_MODE=${__TRUE} ;;

      "+a" ) __USE_COLORS=${__FALSE} ;;

       "a" ) __USE_COLORS=${__TRUE} ;;

      "+O" ) __OVERWRITE_MODE=${__FALSE} ;;

       "O" ) __OVERWRITE_MODE=${__TRUE} ;;

       "f" ) __FORCE=${__TRUE} ;;

      "+f" ) __FORCE=${__FALSE} ;;

       "l" )
             __NEW_LOGFILE="${OPTARG:=nul}"
             [ "$( substr ${__NEW_LOGFILE} 1 1 )"x != "/"x ] && __NEW_LOGFILE="$PWD/${__NEW_LOGFILE}"
             ;;

      "+l" ) __NEW_LOGFILE="nul" ;;

      "+h" ) __VERBOSE_MODE=${__TRUE}
             __PRINT_USAGE=${__TRUE}
             ;;

       "h" ) __PRINT_USAGE=${__TRUE} ;;

       "T" ) : # parameter already processed
             ;;

       "H" )

echo " -----------------------------------------------------------------------------------------------------" >&2
echo " ${__SCRIPTNAME} ${__SCRIPT_VERSION} (Scripttemplate: ${__SCRIPT_TEMPLATE_VERSION})  ">&2
echo " Documentation" >&2
echo " -----------------------------------------------------------------------------------------------------" >&2

             grep "^##" "$0" | grep -v "##EXAMPLE##" | cut -c5- 1>&2
             die 0 ;;

       "X" )

echo " -----------------------------------------------------------------------------------------------------" >&2
echo " ${__SCRIPTNAME} ${__SCRIPT_VERSION} ">&2
echo " Documentation" - Examples>&2
echo " -----------------------------------------------------------------------------------------------------" >&2

             T=$( grep "^##EXAMPLE##" "$0" | cut -c12- )
       eval T1="\"$T\""
       echo "$T1" 1>&2
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



       "I" ) set -f
             if [ "${OPTARG}"x = "none"x ] ; then
               SCRIPTLIST=""
             else
               SCRIPTLIST="${SCRIPTLIST} $( ProcessParameterI $( echo "${OPTARG}" | tr "," " " ) )"
             fi
             ;;

      "+I" ) SCRIPTLIST="$( ProcessParameterI $( echo "${OPTARG}" | tr "," " " ) )"
              ;;

       "i" ) for CUR_FILE in  $( echo "${OPTARG}" | tr "," " " ) ; do

                substr "${CUR_FILE}" 1 1 FIRST_CHAR
                [ "${FIRST_CHAR}"x != "/"x ] && CUR_FILE="${PWD}/${CUR_FILE}"

                CheckExecutable "${CUR_FILE}"
                if [ $? -eq 0 ] ; then
                  SCRIPTLIST="${SCRIPTLIST} ${CUR_FILE}"
                else
                  LogWarning "Executable \"${CUR_FILE}\" does not exist or is not executable."
                fi
             done
             ;;

       "x" ) set -f 
             SCRIPTEXCLUDE_LIST="${SCRIPTEXCLUDE_LIST} $( echo "${OPTARG}" | tr "," " " )"
             set +f
             ;;

       "o" ) WORKDIR="${OPTARG}"
             ;;

       "s" ) if [ "${OPTARG}"x = "none"x ] ; then
               START_SCRIPT=""
             else
               START_SCRIPT="${OPTARG}"
             fi
             ;;

       "z" ) if [ "${OPTARG}"x = "none"x ] ; then
               STOP_SCRIPT=""
             else
               STOP_SCRIPT="${OPTARG}"
             fi
             ;;

       "d" ) EXECUTE_PARALLEL=${__TRUE} ;;

      "+d" ) EXECUTE_PARALLEL=${__FALSE} ;;

       "r" ) REMOVE_DUPLICATES=${__TRUE} ;;

      "+r" ) REMOVE_DUPLICATES=${__FALSE} ;;

       "B" ) STOP_AFTER_ERROR=${__TRUE} ;;

      "+B" ) STOP_AFTER_ERROR=${__FALSE} ;;

       "c" ) case ${OPTARG} in
              "default" | "DEFAULT" )
                 SHELL_TO_USE="${DEFAULT_SHELL_TO_USE}"
                 ;;
               "none " )
                 SHELL_TO_USE=""
                 ;;
               *)
                 SHELL_TO_USE="${OPTARG}"
                 ;;
             esac
             ;;

       "k" ) ADD_COMMENTS=${__FALSE} ;;

      "+k" ) ADD_COMMENTS=${__TRUE} ;;

       "W" ) TIMEOUT_PARAMETER="${OPTARG}" ;;

       "w" ) START_TIMEOUT_PARAMETER="${OPTARG}" ;;

        \? ) [ "${OPTARG}"x = ""x ] && eval OPTARG=\$"$(( $OPTIND -1 ))"
             LogError "Unknown parameter found: \"${OPTARG}\" "
             INVALID_PARAMETER_FOUND=${__TRUE}
             break
          ;;

         * ) LogError "Not expected parameter found: \"${CUR_SWITCH}\""
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


# -----------------------------------------------------------------------------
# process the debug switches


  if [ "${__DEBUG_SWITCHES}"x != ""x ] ; then
     __DEBUG_SWITCHES=$( IFS=, ; printf "%s " ${__DEBUG_SWITCHES}  )

    for __CUR_DEBUG_SWITCH in ${__DEBUG_SWITCHES} ; do
      case ${__CUR_DEBUG_SWITCH} in

        "help" )
           cat <<EOT
Known debug switches (for -d / --debugmode):

  help         -- show this usage and exit
  msg          -- log debug messages to the file ${__DEBUG_LOGFILE}
  trace        -- activate tracing to the file ${__TRACE_LOGFILE}
  fn_to_stderr -- print the function names to STDERR
  fn_to_tty    -- print the function names to /dev/tty
  no_of_error_loglines=n
               -- no. of lines of the logfile to print in case of an rc not equal zero (for sequentiell tasks only)
                  (use 0 for none or -1 for all)
  no_of_ok_loglines=n
               -- no of lines of the logfile to print in case of an rc equal zero (for sequentiell tasks only)
                  (use 0 for none or -1 for all)
  no_of_logfile_lines=n
               -- no of lines of the logfile to print for parallel tasks
                  (use 0 for none or -1 for all)
EOT
            die 0
            ;;

     no_of_error_loglines=* )
           NO_OF_ERROR_LOGLINES="${__CUR_DEBUG_SWITCH#*=}"
           ;;

     no_of_ok_loglines=* )
           NO_OF_OK_LOGLINES="${__CUR_DEBUG_SWITCH#*=}"
           ;;

      no_of_logfile_lines=* )
           NO_OF_LOGFILE_LINES="${__CUR_DEBUG_SWITCH#*=}"
           ;;

     "fn_to_stderr" )
            __FUNCTION_INIT=' eval __settraps; echo  "Now in function ${__FUNCTION} ; the parameter are \"$*\" (sec: $SECONDS): " >&2 '
            ;;

     "fn_to_tty" )
            __FUNCTION_INIT=' eval __settraps; echo  "Now in function ${__FUNCTION} ; the parameter are \"$*\" " >/dev/tty '
            ;;

        "msg" )
            LogMsg "Debug messages enabled; the output goes into the file \"${__DEBUG_LOGFILE}\"."
            __LOG_DEBUG_MESSAGES=${__TRUE}
            ;;

        "trace" )
            __ACTIVATE_TRACE=${__TRUE}
            exec 3>&2
            exec 2>"${__TRACE_LOGFILE}"
            typeset -ft $( typeset +f )
            set -x
            PS4='LineNo: $LINENO (sec: $SECONDS): >> '
            LogMsg "Tracing enabled; the output goes to the file \"${__TRACE_LOGFILE}\". "
            LogMsg "WARNING: All output to STDERR now goes into the file \"${__TRACE_LOGFILE}\"; use \">&3\" to print to real STDERR."
            ;;

        * )
            die 235 "Invalid debug switch found: \"${__CUR_DEBUG_SWITCH}\" -- use \"-d help\" to list the known debug switches"
            ;;
      esac
    done

  fi

  isNumber ${NO_OF_ERROR_LOGLINES}
  if [ $? -ne ${__TRUE} -a ${NO_OF_ERROR_LOGLINES} -ne -1 ] ; then
     LogError "The value for the parameter \"-D no_of_error_loglines\" \"${NO_OF_ERROR_LOGLINES}\" is not valid"
     INVALID_PARAMTER_FOUND=${__TRUE}
  fi

  isNumber ${NO_OF_OK_LOGLINES}
  if [ $? -ne ${__TRUE} -a ${NO_OF_OK_LOGLINES} -ne -1 ] ; then
     LogError "The value for the parameter \"-D no_of_ok_loglines\" \"${NO_OF_OK_LOGLINES}\" is not valid"
     INVALID_PARAMTER_FOUND=${__TRUE}
  fi

  isNumber ${NO_OF_LOGFILE_LINES}
  if [ $? -ne ${__TRUE} -a ${NO_OF_LOGFILE_LINES} -ne -1 ] ; then
     LogError "The value for the parameter \"-D no_of_ok_logfile_lines\" \"${NO_OF_LOGFILE_LINES}\" is not valid"
     INVALID_PARAMTER_FOUND=${__TRUE}
  fi

  if [ ${__LOG_DEBUG_MESSAGES} != ${__TRUE} ] ; then
    rm "${__DEBUG_LOGFILE}" 2>/dev/null 1>/dev/null
    __DEBUG_LOGFILE=""
  else
    echo 2>/dev/null >>"${__DEBUG_LOGFILE}" || \
      die 237 "Can not write to the debug log file \"${__DEBUG_LOGFILE}\" "
  fi

#
# set INVALID_PARAMETER_FOUND to ${__TRUE} if the script
# should abort due to an invalid parameter
#
  if [ "${NOT_PROCESSED_PARAMETER}"x != ""x ] ; then
    LogError "Unknown parameter: \"${NOT_PROCESSED_PARAMETER}\" "
    INVALID_PARAMETER_FOUND=${__TRUE}
  fi

  if [ "${START_TIMEOUT_PARAMETER}"x != ""x ] ; then

    oIFS="${IFS}" ; IFS="," ; set -- $( echo "${START_TIMEOUT_PARAMETER}" | tr "/" "," )  ; V1="$1" ; V2="$2"; V3="$3"; IFS="${oIFS}"
    MAX_NO_OF_BACKGROUND_PROCESSES=${V1:=${MAX_NO_OF_BACKGROUND_PROCESSES}}
    START_PROC_WAIT_INTERVALL=${V2:=${START_PROC_WAIT_INTERVALL}}
    START_PROC_TIMEOUT=${V3:=${START_PROC_TIMEOUT}}

    [ "${MAX_NO_OF_BACKGROUND_PROCESSES}"x = "default"x ] && MAX_NO_OF_BACKGROUND_PROCESSES="${DEFAULT_MAX_NO_OF_BACKGROUND_PROCESSES}"
    [ "${START_PROC_WAIT_INTERVALL}"x = "default"x      ] && START_PROC_WAIT_INTERVALL="${DEFAULT_START_PROC_WAIT_INTERVALL}"
    [ "${START_PROC_TIMEOUT}"x = "default"x             ] && START_PROC_TIMEOUT="${DEFAULT_START_PROC_TIMEOUT}"

    [ "${MAX_NO_OF_BACKGROUND_PROCESSES}"x = "none"x ] && MAX_NO_OF_BACKGROUND_PROCESSES="-1"
    [ "${START_PROC_TIMEOUT}"x = "none"x             ] && START_PROC_TIMEOUT="-1"

    if [ "${MAX_NO_OF_BACKGROUND_PROCESSES}"x != "-1"x  ] ; then
      isNumber "${MAX_NO_OF_BACKGROUND_PROCESSES}"
      if [ $? -ne 0 ] ; then
        LogError "Invalid parameter found: The value for the number of parallel background processes (${MAX_NO_OF_BACKGROUND_PROCESSES}) is not a number"
        LogError "This is the 1st value for the parameter -w"
        INVALID_PARAMETER_FOUND=${__TRUE}
      fi
    fi

    CalculateSeconds "${START_PROC_WAIT_INTERVALL}" START_PROC_WAIT_INTERVALL_IN_SEC
    if [ $? -ne 0 ] ; then
      LogError "Invalid parameter found: The value for wait intervall (${START_PROC_WAIT_INTERVALL}) for starting the background processes is not a number"
      LogError "This is the 2nd value for the parameter -w"
      INVALID_PARAMETER_FOUND=${__TRUE}
    fi

    if [ "${START_PROC_TIMEOUT}"x != "-1"x  ] ; then
      CalculateSeconds "${START_PROC_TIMEOUT}" START_PROC_TIMEOUT_IN_SEC
      if [ $? -ne 0 ] ; then
        LogError "Invalid parameter found: The value for the timeout for starting the parallel background processes (${START_PROC_TIMEOUT}) is not a number"
        LogError "This is the 3rd value for the parameter -w"
        INVALID_PARAMETER_FOUND=${__TRUE}
      fi
    fi

  fi


  if [ "${TIMEOUT_PARAMETER}"x != ""x ] ; then

    oIFS="${IFS}" ; IFS="," ; set -- $( echo "${TIMEOUT_PARAMETER}" | tr "/" "," )  ; V1="$1" ; V2="$2"; IFS="${oIFS}"
    MAX_RUN_WAIT_TIME=${V1:=${MAX_RUN_WAIT_TIME}}
    RUN_WAIT_INTERVALL=${V2:=${RUN_WAIT_INTERVALL}}

    [ "${MAX_RUN_WAIT_TIME}"x = "default"x  ] && MAX_RUN_WAIT_TIME="${DEFAULT_MAX_RUN_WAIT_TIME}"
    [ "${RUN_WAIT_INTERVALL}"x = "default"x ] && RUN_WAIT_INTERVALL="${DEFAULT_RUN_WAIT_INTERVALL}"

    [ "${MAX_RUN_WAIT_TIME}"x = "none"x ] && MAX_RUN_WAIT_TIME="-1"

    if [ "${MAX_RUN_WAIT_TIME}"x != "-1"x  ] ; then
      CalculateSeconds "${MAX_RUN_WAIT_TIME}" MAX_RUN_WAIT_TIME_IN_SEC
      if [ $? -ne 0 ] ; then
        LogError "Invalid parameter found: The value for timeout (${MAX_RUN_WAIT_TIME}) is not a number"
        LogError "This is the 1st value for the parameter -W"
        INVALID_PARAMETER_FOUND=${__TRUE}
      fi
    fi

    CalculateSeconds "${RUN_WAIT_INTERVALL}" RUN_WAIT_INTERVALL_IN_SEC
    if [ $? -ne 0 ] ; then
      LogError "Invalid parameter found: The value for timeout (${RUN_WAIT_INTERVALL}) is not a number"
      LogError "This is the 2nd value for the parameter -W"
      INVALID_PARAMETER_FOUND=${__TRUE}
    fi
  fi

# use defaults if necessary
  [ "${START_PROC_WAIT_INTERVALL_IN_SEC}"x = ""x ] && CalculateSeconds ${START_PROC_WAIT_INTERVALL} START_PROC_WAIT_INTERVALL_IN_SEC
  [ "${START_PROC_TIMEOUT_IN_SEC}"x = ""x ] && CalculateSeconds ${START_PROC_TIMEOUT} START_PROC_TIMEOUT_IN_SEC
  [ "${MAX_RUN_WAIT_TIME_IN_SEC}"x = ""x ] && CalculateSeconds ${MAX_RUN_WAIT_TIME} MAX_RUN_WAIT_TIME_IN_SEC
  [ "${RUN_WAIT_INTERVALL_IN_SEC}"x = ""x ] && CalculateSeconds ${RUN_WAIT_INTERVALL} RUN_WAIT_INTERVALL_IN_SEC


  if [ "${SHELL_TO_USE}"x = ""x ] ; then
    LogWarning "The shell to use for scripts is not set."
    INVALID_PARAMETER_FOUND=${__TRUE}
  elif [ ! -x "${SHELL_TO_USE}" ]  ; then
    LogError "The shell to use \"${SHELL_TO_USE}\" for scripts does not exist or is not executable"
    INVALID_PARAMETER_FOUND=${__TRUE}
  fi

  if [ "${START_SCRIPT}"x != ""x ] ; then

    substr "${START_SCRIPT}" 1 1 FIRST_CHAR
    [ "${FIRST_CHAR}"x != "/"x ] && START_SCRIPT="${PWD}/${START_SCRIPT}"

    if [ ! -f "${START_SCRIPT}" -o ! -x  "${START_SCRIPT}" ] ; then
      LogError "Start script \"${START_SCRIPT}\" not found or not executable"
      INVALID_PARAMETER_FOUND=${__TRUE}
    fi
  fi

  if [ "${STOP_SCRIPT}"x != ""x ] ; then

    substr "${STOP_SCRIPT}" 1 1 FIRST_CHAR
    [ "${FIRST_CHAR}"x != "/"x ] && STOP_SCRIPT="${PWD}/${STOP_SCRIPT}"

    if [ ! -f "${STOP_SCRIPT}" -o ! -x  "${STOP_SCRIPT}" ] ; then
      LogError "Stop script \"${STOP_SCRIPT}\" not found or not executable"
      INVALID_PARAMETER_FOUND=${__TRUE}
    fi
  fi

# exit the program if there are one or more invalid parameter
#
  if [ ${INVALID_PARAMETER_FOUND} -eq ${__TRUE} ] ; then
    LogError "One or more invalid parameters found"
    ShowShortUsage
    die 2
  fi

  SetEnvironment

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
  if [ 1 = 0 ] ; then
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
    LogMsg "OS is \"${__OS}\" (Fullname: \"${__OS_FULLNAME}\") "
    LogMsg "OS Version is \"${__OS_VERSION}\" "
    LogMsg "OS Release is \"${__OS_RELEASE}\" "
    LogMsg "The current shell is \"${__SHELL}\"; this shell is compatible to ksh${__KSH_VERSION}"
    LogMsg "The userid running this script is \"${__USERID}\""
    LogMsg ""
    LogMsg "The PID of this process is $$"
    LogMsg ""
    LogMsg "The script hashtag is \"${__HASHTAG}\""
    LogMsg "The shell in the hashtag is \"${__SCRIPT_SHELL}\" "
    LogMsg "The shell options in the hashtag are \"${__SCRIPT_SHELL_OPTIONS}\" "
    LogMsg "----------------------------------------------------------------------"
    LogMsg ""
  fi

# -----------------------------------------------------------------------------

# defined Log routines:
#
# LogMsg
# LogInfo
# LogWarning
# LogError
# LogOnly
# LogIfNotVerbose
# PrintDotToSTDOUT

  PARAMETER_OKAY=${__TRUE}


 # create the working directory if necessary
 #
  mkdir -p "${WORKDIR}" || die 5 "Can not create the working directory \"${WORKDIR}\" "
  export WORKDIR

# remove duplicate entries from the list executables to execute
#
  if [ ${REMOVE_DUPLICATES} = ${__TRUE} ] ; then
    LogInfo "Removing duplicate entries from the list of executables to execute ..."

    NEW_SCRIPTLIST=" "

    NO_OF_REMOVED_ENTRIES=0
    REMOVED_ENTRIES=""

    for CUR_SCRIPT in ${SCRIPTLIST} ; do
      if [[ ${NEW_SCRIPTLIST} == *\ ${CUR_SCRIPT}\ * ]] ; then
        (( NO_OF_REMOVED_ENTRIES = NO_OF_REMOVED_ENTRIES +1 ))
        REMOVED_ENTRIES="${REMOVED_ENTRIES} ${CUR_SCRIPT}"
        LogInfo "Removing the entry \"${CUR_SCRIPT}\" from the list of executables to execute."
      else
        NEW_SCRIPTLIST="${NEW_SCRIPTLIST} ${CUR_SCRIPT}"
      fi
    done
    if [ ${NO_OF_REMOVED_ENTRIES} = 0 ] ; then
      LogInfo "No duplicate entries on the list found."
    else
      LogMsg "Removed ${NO_OF_REMOVED_ENTRIES} duplicate(s) from the list of executables to execute (Parameter -r)"
      SCRIPTLIST="${NEW_SCRIPTLIST}"
    fi
  fi

# calculate the number of scripts to execute
#
  set -- ${SCRIPTLIST}
  NO_OF_SCRIPTS_TO_EXECUTE=$#
   [ "${NO_OF_SCRIPTS_TO_EXECUTE}"x = "0"x ] && die 4 "No executables found."

  LogMsg ""


  LogMsg "Will process ${NO_OF_SCRIPTS_TO_EXECUTE} executable(s). (Parameter -I and/or -i)"

  if [ "${SCRIPTEXCLUDE_LIST}"x != ""x ] ; then
    LogMsg "  The regular expression(s) for executables that should not be executed are (Parameter -x):"
    LogMsg "    ${SCRIPTEXCLUDE_LIST}"
  fi

  if [ ${REMOVE_DUPLICATES} = ${__FALSE} ] ; then
    LogMsg "  Duplicates are NOT removed from the list of executables (Parameter -r to change)"
  else
    LogMsg "  Duplicates are removed from the list of executables (Parameter -r)"
  fi

  if [ "${START_SCRIPT}"x != ""x ] ; then
    LogMsg "Using the start script \"${START_SCRIPT}\" (Parameter -s) "
  fi

  if [ "${STOP_SCRIPT}"x != ""x ] ; then
    LogMsg "Using the stop script \"${STOP_SCRIPT}\"  (Parameter -z) "
  fi

  LogMsg "The working directory is \"${WORKDIR}\". (Parameter -o)"

  if [ ${ADD_COMMENTS} = ${__TRUE} ] ; then
    LogMsg "Start and stop comment lines will be added to the logfiles (Parameter -k to change)"
  else
    LogMsg "No start and stop comment lines will be added to the logfiles (Parameter -k)"
  fi

  if [ ${EXECUTE_PARALLEL} = ${__TRUE} ] ; then
    LogMsg ""
    LogMsg "The executables will run parallel in the background (Parameter -d)"
    LogMsg ""
    LogMsg "The maximum number of parallel background processes is ${MAX_NO_OF_BACKGROUND_PROCESSES} (Parameter -w ${MAX_NO_OF_BACKGROUND_PROCESSES},x,x -1 = not limited)."
    LogMsg "  The wait intervall for starting the background processes is ${START_PROC_WAIT_INTERVALL_IN_SEC} second(s) (Parameter -w x,${START_PROC_WAIT_INTERVALL},x); "
    LogMsg "  the timeout for starting the background processes is ${START_PROC_TIMEOUT_IN_SEC} second(s) (Parameter -w x,x,${START_PROC_TIMEOUT} -1 = not limited)."
    LogMsg ""
    LogMsg "Waiting up to ${MAX_RUN_WAIT_TIME_IN_SEC} second(s) for the background processes to finish (Parameter -W ${MAX_RUN_WAIT_TIME},x, -1 = not limited)."
    LogMsg "  The wait intervall for waiting for the background processes to finish is ${RUN_WAIT_INTERVALL_IN_SEC} second(s) (Parameter -W x,${RUN_WAIT_INTERVALL} )"
    LogMsg ""

    if [ "${NO_OF_LOGFILE_LINES}" = "-1" ] ; then
      LogMsg "The logfiles of the executables will be printed after the executable finished (Parameter -D no_of_logfile_lines=${NO_OF_LOGFILE_LINES})"
    elif [ "${NO_OF_LOGFILE_LINES}" = "0" ] ; then
      LogMsg "The logfiles of the executables will not be printed after the executable finished (Parameter -D no_of_logfile_lines=${NO_OF_LOGFILE_LINES})"
    else
      LogMsg "The last ${NO_OF_LOGFILE_LINES} lines of the logfiles of the executables will be printed after the executable finished (Parameter -D no_of_logfile_lines=${NO_OF_LOGFILE_LINES})"
    fi

  else
    LogMsg ""
    LogMsg "The executables will run sequential one after the other (Parameter -d to change)."
    LogMsg ""
    if [ ${STOP_AFTER_ERROR} = ${__TRUE} ]  ; then
      LogMsg "The execution stops after an executable ends with a non-zero reuturn code (Parameter -B)"
    else
      LogMsg "The return code of the executables will be ignored (Parameter -B to change)"
    fi

    if [ "${NO_OF_ERROR_LOGLINES}" = "-1" ] ; then
      LogMsg "The logfiles of the executables will be printed after the executable finished with RC not equal zero (Parameter -D no_of_logfile_lines=${NO_OF_ERROR_LOGLINES})"
    elif [ "${NO_OF_ERROR_LOGLINES}" = "0" ] ; then
      LogMsg "The logfiles of the executables will not be printed after the executable finished with RC not equal zero (Parameter -D no_of_logfile_lines=${NO_OF_ERROR_LOGLINES})"
    else
      LogMsg "The last ${NO_OF_ERROR_LOGLINES} lines of the logfiles of the executables will be printed after the executable finished with RC not equal zero (Parameter -D no_of_logfile_lines=${NO_OF_ERROR_LOGLINES})"
    fi

     if [ "${NO_OF_OK_LOGLINES}" = "-1" ] ; then
      LogMsg "The logfiles of the executables will be printed after the executable finished with RC nequal zero (Parameter -D no_of_logfile_lines=${NO_OF_OK_LOGLINES})"
    elif [ "${NO_OF_OK_LOGLINES}" = "0" ] ; then
      LogMsg "The logfiles of the executables will not be printed after the executable finished with RC equal zero (Parameter -D no_of_logfile_lines=${NO_OF_OK_LOGLINES})"
    else
      LogMsg "The last ${NO_OF_OK_LOGLINES} lines of the logfiles of the executables will be printed after the executable finished with RC nequal zero (Parameter -D no_of_logfile_lines=${NO_OF_OK_LOGLINES})"
    fi

  fi

# do not use the AskUser builtin shell!
  __DEBUG_SHELL_IN_ASKUSER=${__FALSE}

  while true ; do

# check for the parameter "-y"
#
    [ "${__USER_RESPONSE_IS}"x = "y"x ] && break
    LogMsg "-"

    [ "${USER_INPUT}"x = ""x ] && LogMsg "-" "*** Enter <l><return> to list the executables to execute, <x> to list the regex for executables not to execute, <p> to view the script parameter"
    AskUser "*** <y><return> to start or <n><return> to abort. Default is <n>: "
    THISRC=$?

    case ${USER_INPUT} in

      "shell" )
         while true ; do
           printf "\n------------------------------------------------------------------------------------------\n"
           printf "${__SCRIPTNAME} - debug shell - enter a command to execute (\"exit\" to leave the shell)\n"
           printf ">> "
           read USERINPUT
           [ "${USERINPUT}"x = "exit"x ] && break
           eval ${USERINPUT}
         done
        USER_INPUT=""
         ;;

      "l" | list )
        LogMsg "Executables to execute (in this order) are:"
        LogMsg "-" "$( echo "${SCRIPTLIST}" | tr -s " " |  sed "s/ /\n/g" )"
        ;;

      "x" )
        LogMsg "Regex for executables NOt to execute are:"
        LogMsg "-" "$( echo "${SCRIPTEXCLUDE_LIST}" | tr -s " " | sed "s/ /\n/g" )"
        ;;

      "h" )
         ShowShortUsage
         ;;

      "H" )
         ShowUsage
         ;;

      "p" )
         LogMsg "The parameter for this script execution are: "
         LogMsg "-" "${THIS_PARAMETER}"
         USER_INPUT=""
        ;;

      "v" | "verbose" )
        if [ ${__VERBOSE_MODE} = ${__TRUE} ] ; then
          LogMsg "Verbose mode is now off"
          __VERBOSE_MODE=${__FALSE}
        else
          LogMsg "Verbose mode is now on"
          __VERBOSE_MODE=${__TRUE}
        fi
        USER_INPUT=""
        ;;

       "q" | "quit" | "exit" | "n" )
          die 100 "Script aborted by the user."
          ;;

       * )
        if [ ${THISRC} -ne ${__TRUE} ] ; then
          AskUser "Really abort the script (y/N)? "
          [ $? -eq ${__TRUE} ] && die 100 "Script aborted by the user."
          USER_INPUT=""
          continue
        fi
        break
        ;;
    esac
    USER_INPUT=""
  done
  __USER_RESPONSE_IS=""

  __DEBUG_SHELL_IN_ASKUSER=${__TRUE}


  PROCESSING_STARTED=${__TRUE}

  typeset -i COUNT=0

  LogMsg "Starting processing ..."

  if [ "${START_SCRIPT}"x != ""x ] ; then
    LogMsg "Executing the start script \"${START_SCRIPT}\" ... "
    file "${START_SCRIPT}" | egrep " LSB | MSB " >/dev/null
    if [ $? -eq 0 ] ; then
      ${START_SCRIPT}
    else
      ${SHELL_TO_USE} -e ${START_SCRIPT}
    fi
  fi


  if [ ${EXECUTE_PARALLEL} = ${__TRUE} ] ; then

# --------- execute the scripts in parallel
    STOP_STARTING=${__FALSE}

    PROCS=""
    BACKGROUND_PIDS=""
    typeset -i NO_OF_PROCS_STARTED=0
    typeset -i OVERALL_START_TIME=0

    typeset -i MINUTES
    typeset -i SECONDS
    typeset -i HOURS


    for CUR_SCRIPT in ${SCRIPTLIST} ; do

      script_on_the_exclude_list "${CUR_SCRIPT}"
      if [ $? -eq ${__TRUE} ] ; then
        LogMsg "++++ The executable \"${CUR_SCRIPT}\" is on the exclude list. Ignoring this executable."

        SCRIPTS_EXCLUDED="${SCRIPTS_EXCLUDED} ${CUR_SCRIPT}"
        (( NO_OF_SCRIPTS_EXCLUDED = NO_OF_SCRIPTS_EXCLUDED + 1 ))

        continue
      fi

      NO_OF_RUNNING_PIDS=$( GetNumberOfRunningProcesses ${BACKGROUND_PIDS} )

      LogMsg "  Number of running processes are: ${NO_OF_RUNNING_PIDS}"

      if [ "${MAX_NO_OF_BACKGROUND_PROCESSES}"x != "-1"x ] ; then
        typeset -i START_WAIT_TIME=0
        while [ ${NO_OF_RUNNING_PIDS} -ge ${MAX_NO_OF_BACKGROUND_PROCESSES} ] ; do
          if [ "${START_PROC_TIMEOUT_IN_SEC}"x != "-1"x ] ; then
            if [ ${START_WAIT_TIME} -gt ${START_PROC_TIMEOUT_IN_SEC} ] ; then
              LogWarning "Maximum startup time (${START_PROC_TIMEOUT_IN_SEC} seconds) reached - will NOT start the processes for the other hosts!"
              INVALID_HOSTS_LIST="${INVALID_HOSTS_LIST} ${LIST_OF_HOSTS_TO_PROCESS#*${CUR_HOST}}"
              STOP_STARTING=${__TRUE}
              break
            fi
          fi
          LogMsg "  Maximum number of background processes (${MAX_NO_OF_BACKGROUND_PROCESSES}) reached."

          if [ "${START_PROC_TIMEOUT_IN_SEC}"x != "-1"x ] ; then
            (( REMAINING_WAIT_TIME = ${START_PROC_TIMEOUT_IN_SEC} - ${START_WAIT_TIME} ))
            LogMsg "Waiting for ${START_PROC_WAIT_INTERVALL_IN_SEC} second(s) now (total wait time until now: ${START_WAIT_TIME} seconds; max. timeout is ${START_PROC_TIMEOUT_IN_SEC} seconds ; remaining wait time is ${REMAINING_WAIT_TIME} seconds) ..."
          else
            LogMsg "Waiting for ${START_PROC_WAIT_INTERVALL_IN_SEC} second(s) now (total wait time until now: ${START_WAIT_TIME} seconds)"
          fi

          sleep ${START_PROC_WAIT_INTERVALL_IN_SEC}
          (( START_WAIT_TIME = START_WAIT_TIME +  START_PROC_WAIT_INTERVALL_IN_SEC ))
          (( OVERALL_START_TIME = OVERALL_START_TIME + START_PROC_WAIT_INTERVALL_IN_SEC ))

          LogMsg "  Resuming starting further processes ..."
          NO_OF_RUNNING_PIDS=$( GetNumberOfRunningProcesses ${BACKGROUND_PIDS} )

        done
        [ ${STOP_STARTING} = ${__TRUE} ] && break
      fi

      (( COUNT = COUNT + 1 ))
      LogMsg  "  ---- Processing the executable \"${CUR_SCRIPT}\" ... ( ${COUNT} from ${NO_OF_SCRIPTS_TO_EXECUTE}; ${NO_OF_PROCS_STARTED} already started) "

      CUR_OUTPUT_FILE="${WORKDIR}/$( basename ${CUR_SCRIPT} ).$$.log"
      touch "${CUR_OUTPUT_FILE}"
      if [ $? -ne 0 ] ; then
        LogError "Can not write to the log file \"${CUR_OUTPUT_FILE}\"  -- skipping this executable."

        SCRIPTS_NOT_EXECUTED="${SCRIPTS_NOT_EXECUTED} ${CUR_SCRIPT}"
        (( NO_OF_SCRIPTS_NOT_EXECUTED = NO_OF_SCRIPTS_NOT_EXECUTED + 1 ))
        continue
      fi

      FS_TYPE=$( file "${CUR_SCRIPT}" | egrep " LSB | MSB " ) && THIS_SHELL="" || THIS_SHELL="${SHELL_TO_USE}"
      LogInfo "The type of \"${CUR_SCRIPT}\" is \"${FS_TYPE}\" "

      ( [ ${ADD_COMMENTS} = ${__TRUE} ] && echo "# ### ---- Log of the executable \"${CUR_SCRIPT}\" executed at $( date )--- start ---"  ; \
         eval ${THIS_SHELL} "${CUR_SCRIPT}" \
        [ ${ADD_COMMENTS} = ${__TRUE} ] && echo "# ### ---- Log of the executable \"${CUR_SCRIPT}\" executed at $( date ) --- end ---"  ) >>"${CUR_OUTPUT_FILE}" 2>&1 &

      LogMsg "    The log file is \"${CUR_OUTPUT_FILE}\" "

      SCRIPTS_EXECUTED="${SCRIPTS_EXECUTED} ${CUR_SCRIPT}"
      (( NO_OF_SCRIPTS_EXECUTED = NO_OF_SCRIPTS_EXECUTED + 1 ))

      (( NO_OF_PROCS_STARTED = NO_OF_PROCS_STARTED + 1 ))

      [ "${PROCS}"x = ""x ] && PROCS="${CUR_SCRIPT}#${!}#${CUR_OUTPUT_FILE}" || PROCS="${CUR_SCRIPT}#${!}#${CUR_OUTPUT_FILE};${PROCS}"
      LogInfo "  command \"${THIS_SHELL} ${CUR_SCRIPT}\" started; the process PID=$! started at $( date )"
      [ "${BACKGROUND_PIDS}"x = ""x ] && BACKGROUND_PIDS="$!" || BACKGROUND_PIDS="${BACKGROUND_PIDS} $!"

    done

    (( SECONDS = OVERALL_START_TIME % 60 ))
    (( MINUTES = OVERALL_START_TIME / 60 ))
    if [ ${MINUTES} -gt 59 ] ; then
      (( HOURS = MINUTES / 60 ))
      (( MINUTES = MINUTES % 60 ))
    else
      HOURS=0
    fi

    LogMsg "The loop to start the ${NO_OF_PROCS_STARTED} background processes ended at $( date ), the runtime is $( printf "%d:%.2d:%.2d" ${HOURS} ${MINUTES} ${SECONDS} )."

    LogInfo "Starting the wait loop with PROCS=\"$PROCS\" "

# now wait for the ssh processes to finish
#
    LogMsg ""
    LogMsg "Starting the loop to wait for the background processes at $( date ) ..."
    LogMsg "  Waiting up to ${MAX_RUN_WAIT_TIME_IN_SEC} seconds for the background processes to finish ..."

    typeset -i RUN_WAIT_TIME=0
    typeset PROC_LOG_FILES=""

    while true ; do

      if [ "${MAX_RUN_WAIT_TIME_IN_SEC}"x != "-1"x ] ; then
        [ ${RUN_WAIT_TIME} -ge ${MAX_RUN_WAIT_TIME_IN_SEC} ] && break
      fi

      [ "${PROCS}"x = ""x ] && break

      LogInfo "  PROCS loop starts here ..."
      STILL_RUNNING_PROCS=""
      NO_OF_STILL_RUNNING_PROCS=0

      NO_OF_RUNNING_PIDS=$( GetNumberOfRunningProcesses ${BACKGROUND_PIDS} )

      case ${NO_OF_RUNNING_PIDS} in
        0 ) LogInfo "All processes finished at loop start." ;;
        1 ) LogInfo "There is still ${NO_OF_RUNNING_PIDS} process running at loop start:" ;;
        * ) LogInfo "There are still ${NO_OF_RUNNING_PIDS} processes running at loop start:" ;;
      esac

      while [ "${PROCS}"x != ""x ]; do
        CUR_PROC_LINE="${PROCS%%;*}"
        PROCS="${PROCS#*;}"
        [ "${PROCS}"x = "${CUR_PROC_LINE}"x  -o "${PROCS}"x = ";"x ] && PROCS=""

        CUR_SCRIPT="${CUR_PROC_LINE%%#*}"
        CUR_OUTPUT_FILE="${CUR_PROC_LINE##*#}"
        CUR_PID=${CUR_PROC_LINE#*#} ; CUR_PID=${CUR_PID%%#*}

        LogInfo "    PROCS: \"${PROCS}\" "
        LogInfo "    CUR_PROC_LINE: \"${CUR_PROC_LINE}\" "
        LogInfo "    CUR_OUTPUT_FILE: \"${CUR_OUTPUT_FILE}\" "
        LogInfo "    CUR_SCRIPT: \"${CUR_SCRIPT}\" "
        LogInfo "    CUR_PID: \"${CUR_PID}\" "

        PS_P_OUTPUT="$( ps -p ${CUR_PID} 2>&1 )"
        if [ $? -eq 0 ] ; then
          [ "${STILL_RUNNING_PROCS}"x = ""x ] && STILL_RUNNING_PROCS="${CUR_PROC_LINE}" || STILL_RUNNING_PROCS="${STILL_RUNNING_PROCS};${CUR_PROC_LINE}"
          LogMsg "    Process \"${CUR_PID}\" for ${CUR_SCRIPT} is still running"
          LogMsg "      The log file is \"${CUR_OUTPUT_FILE}\" "

          (( NO_OF_STILL_RUNNING_PROCS = NO_OF_STILL_RUNNING_PROCS + 1 ))
          continue
        else
          LogMsg "    Process \"${CUR_PID}\" for ${CUR_SCRIPT} finished"
          LogMsg "      The log file is \"${CUR_OUTPUT_FILE}\" "
          ViewLogfile "${CUR_OUTPUT_FILE}" ${NO_OF_LOGFILE_LINES}
          PROC_LOG_FILES="${PROC_LOG_FILES} ${CUR_OUTPUT_FILE}"
        fi

      done

      PROCS="${STILL_RUNNING_PROCS}"
      if [ "${PROCS}"x != ""x ] ; then
        [ ${NO_OF_STILL_RUNNING_PROCS} = 1 ] && \
          LogMsg "  ${NO_OF_STILL_RUNNING_PROCS} background process (from ${NO_OF_PROCS_STARTED}) is still running" || \
          LogMsg "  ${NO_OF_STILL_RUNNING_PROCS} background processes (from ${NO_OF_PROCS_STARTED}) are still running"
        if [ "${MAX_RUN_WAIT_TIME_IN_SEC}x" != "-1"x ] ; then
          (( REMAINING_WAIT_TIME = ${MAX_RUN_WAIT_TIME_IN_SEC} - ${RUN_WAIT_TIME} ))

          LogMsg "  Waiting for ${RUN_WAIT_INTERVALL_IN_SEC} second(s) now (total wait time until now: ${RUN_WAIT_TIME} seconds; max. timeout is ${MAX_RUN_WAIT_TIME_IN_SEC} seconds ; remaining wait time is ${REMAINING_WAIT_TIME} seconds) ..."
        else
          LogMsg "  Waiting for ${RUN_WAIT_INTERVALL_IN_SEC} second(s) now (total wait time until now: ${RUN_WAIT_TIME} seconds)"
        fi

        sleep ${RUN_WAIT_INTERVALL_IN_SEC}
        (( RUN_WAIT_TIME = RUN_WAIT_TIME + RUN_WAIT_INTERVALL_IN_SEC ))
      fi
    done

    (( SECONDS = RUN_WAIT_TIME % 60 ))
    (( MINUTES = RUN_WAIT_TIME / 60 ))
    if [ ${MINUTES} -gt 59 ] ; then
      (( HOURS = MINUTES / 60 ))
      (( MINUTES = MINUTES % 60 ))
    else
      HOURS=0
    fi

    LogMsg "The loop to wait for the background processes ended at $( date ), the runtime is $( printf "%d:%.2d:%.2d" ${HOURS} ${MINUTES} ${SECONDS} )."
    LogMsg ""

  else
# --------- execute the script sequential

    typeset -i COUNT=0

    for CUR_SCRIPT in ${SCRIPTLIST} ; do

      script_on_the_exclude_list "${CUR_SCRIPT}"
      if [ $? -eq ${__TRUE} ] ; then
        LogMsg "++++ The executable \"${CUR_SCRIPT}\" is on the exclude list. Ignoring this executable."

        SCRIPTS_EXCLUDED="${SCRIPTS_EXCLUDED} ${CUR_SCRIPT}"
        (( NO_OF_SCRIPTS_EXCLUDED = NO_OF_SCRIPTS_EXCLUDED + 1 ))

        continue
      fi

      (( COUNT = COUNT + 1 ))
      LogMsg "-"
      LogMsg  "---- Processing \"${CUR_SCRIPT}\" ... ( ${COUNT} from ${NO_OF_SCRIPTS_TO_EXECUTE}) "

      CUR_OUTPUT_FILE="${WORKDIR}/$( basename ${CUR_SCRIPT} ).$$.log"
      echo > "${CUR_OUTPUT_FILE}"
      if [ $? -ne 0 ] ; then
        LogError "Can not write to the log file \"${CUR_OUTPUT_FILE}\"  -- skipping this executable."

        SCRIPTS_NOT_EXECUTED="${SCRIPTS_NOT_EXECUTED} ${CUR_SCRIPT}"
        (( NO_OF_SCRIPTS_NOT_EXECUTED = NO_OF_SCRIPTS_NOT_EXECUTED + 1 ))
        continue
      fi

      file "${CUR_SCRIPT}" | egrep " LSB | MSB " >/dev/null && THIS_SHELL="" || THIS_SHELL="${SHELL_TO_USE}"

      [ ${ADD_COMMENTS} = ${__TRUE} ] && echo "# ### ---- Log of the executable \"${CUR_SCRIPT}\" executed  at $( date )--- start ---" >>"${CUR_OUTPUT_FILE}"
      ${THIS_SHELL} "${CUR_SCRIPT}" >>"${CUR_OUTPUT_FILE}" 2>&1
      THISRC=$?
      [ ${ADD_COMMENTS} = ${__TRUE} ] && echo "# ### ---- Log of the executable \"${CUR_SCRIPT}\" executed at $( date ) --- end ---"    >>"${CUR_OUTPUT_FILE}"
      LogMsg "  The RC is ${THISRC}; the log file is \"${CUR_OUTPUT_FILE}\""

      SCRIPTS_EXECUTED="${SCRIPTS_EXECUTED} ${CUR_SCRIPT}"
      (( NO_OF_SCRIPTS_EXECUTED = NO_OF_SCRIPTS_EXECUTED + 1 ))

      if [ ${THISRC} != 0 ] ; then
        ViewLogfile "${CUR_OUTPUT_FILE}" ${NO_OF_ERROR_LOGLINES}
      else
        ViewLogfile "${CUR_OUTPUT_FILE}" ${NO_OF_OK_LOGLINES}
      fi

      [ ${THISRC} -ne 0 -a ${STOP_AFTER_ERROR} = ${__TRUE} ] && die 15 "The executable \"${CUR_SCRIPT}\" ends with RC=${THISRC}"

    done
  fi


  if [ "${STOP_SCRIPT}"x != ""x ] ; then
    LogMsg "Executing the stop script \"${STOP_SCRIPT}\" ... "
    file "${STOP_SCRIPT}" | egrep " LSB | MSB " >/dev/null
    if [ $? -eq 0 ] ; then
      ${STOP_SCRIPT}
    else
      ${SHELL_TO_USE} -e ${STOP_SCRIPT}
    fi
  fi


  LogMsg ""
  LogMsg "All done (${NO_OF_SCRIPTS_EXECUTED} executable(s) )."
  LogMsg ""

  die ${__MAINRC}

exit

# -----------------------------------------------------------------------------

