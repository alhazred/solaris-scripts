#!/usr/bin/ksh
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
# - use "check_fc_config.sh {-v} {-v} {-v} -h" to get the usage help
#
# - replace "scriptt.sh" with the name of your script
# - change the parts marked with "???" and "??" to your need
#
# - use "check_fc_config.sh -H 2>check_fc_config.sh.doc" to get the documentation
#
# - use "check_fc_config.sh -X 2>check_fc_config.sh.examples.doc" to get some usage examples
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
# Note: The escape character in the command below is only for the usage of check_fc_config.sh with the "-X" parameter!
#
##EXAMPLE## # use logger instead of echo to print the messages
##EXAMPLE##
##EXAMPLE##    LOGMSG_FUNCTION=\"logger -s -p user.info check_fc_config.sh\"  ./check_fc_config.sh
##EXAMPLE##

# -----------------------------------------------------------------------------
####
#### check_fc_config.sh - check the fiber channel configuration in Solaris
####
#### Author: Bernd Schemmer (Bernd.Schemmer@gmx.de)
####
#### Version: see variable ${__SCRIPT_VERSION} below
####          (see variable ${__SCRIPT_TEMPLATE_VERSION} for the template version used)
####
#### Supported OS: Solaris SPARC and Solaris x86
####
####
#### Description
#### -----------
####
#### This script retrieves the output of various commands to view the current
#### fiber channel configuration and generates a table with the most important
#### information regarding the fiber channel configuration
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
##C# e.g. CONFIG_FILE=/var/myconfigfile ./check_fc_config.sh
##C#
##C# To disable the use of a config file use
##C#
##C#     CONFIG_FILE=none ./check_fc_config.sh
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
##T#  __CREATE_DUMP=1 ./check_fc_config.sh
##T#
##T# will create a dump of the environment variables in the files
##T#
##T#   /tmp/check_fc_config.sh.envvars.$$
##T#   /tmp/check_fc_config.sh.exported_envvars.$$
##T#
##T# before the script ends
##T#
##T#  __CREATE_DUMP=/var/tmp/debug ./check_fc_config.sh
##T#
##T# will create a dump of the environment variables in the files
##T#
##T#   /var/tmp/debug/check_fc_config.sh.envvars.$$
##T#   /var/tmp/debug/check_fc_config.sh.exported_envvars.$$
##T#
##T# before the script ends (the target directory must already exist).
##T#
##T# Note that the dump files will always be created in case of a syntax
##T# error. To set the directory for these files use either
##T#
##T#   export __DUMPDIR=/var/tmp/debug
##T#   ./check_fc_config.sh
##T#
##T# or define __DUMPDIR in the script.
##T#
##T# To suppress creating the dump file in case of a syntax error add
##T# the statement
##T#
##T# __DUMP_ALREADY_CREATED=0
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
##T#   /var/debug/check_fc_config.sh.envvars.$$
##T#   /var/debug/check_fc_config.sh.exported_envvars.$$
##T#
##T#   CreateDump /var/debug pass2.
##T#
##T# will create the files
##T#
##T#   /var/debug/check_fc_config.sh.envvars.pass2.$$
##T#   /var/debug/check_fc_config.sh.exported_envvars.pass2.$$
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
####   29.04.2013 v1.0.0 /bs
####     initial release
####   06.08.2013 v1.1.0 /bs
####     script rewritten using scriptt.sh
####     added new information to the output
####   15.08.2013 v1.2.0 /bs
####     corrected the disk/lun/tape infos
####     added the parameter -L outputFile
####   18.08.2013 v1.2.1 /bs
####     added support for Guest LDoms
####   26.11.2013 v1.2.2 /bs
####     added code to get the PCI slots used on x86 machines
####     (Note: tested on an IBM xSeries and an Oracle Server only!)
####   03.09.2014 v2.0.0 /bs
####     script rewritten using the template scriptt.sh v2.0.0.7
####     changed the code for x86 machines some how
####     added some debug switches (use -D help to list the known debug switches)
####     added the parameter -s (show slot usage)
####   17.09.2014 v2.0.1 /bs
####     PCI Slot information in the output file for -L for x86 machines was still wrong -- corrected
####   03.10.2014 v2.1.0 /bs
####     the script now also prints the PCI Slot usage for SPARC Tx machines
####     added the parameter -P (show PCI slot usage only)
####   19.02.2015 v2.2.0 /bs
####     corrected a bug in the x86 slot retrieval routine
####     tested the script on a Oracle X4-2L, added partial support for the Oracle x4800
####   11.01.2019 v2.3.0 /bs
####     added support for Solaris 11 ; tested on  SPARC S7-2L
####     code for the trap handler rewritten (it did not work in the ksh from Solaris 11)
####
####
##V# script template History
##V# -----------------------
##V#   1.22.0 08.06.2006 /bs  (BigAdmin Version 1)
##V#      public release; starting history for the script template
##V#
##V#   1.22.1 12.06.2006 /bs
##V#      added true/false to CheckYNParameter and ConvertToYesNo
##V#
##V#   1.22.2. 21.06.2006 /bs
##V#      added the parameter -V
##V#      added the use of environment variables
##V#      added the variable __NO_TIME_STAMPS
##V#      added the variable __NO_HEADERS
##V#      corrected a bug in the function executeCommandAndLogSTDERR
##V#      added missing return commands
##V#
##V#   1.22.3 24.06.2006 /bs
##V#      added the function StartStop_LogAll_to_logfile
##V#      added the variable __USE_TTY (used in AskUser)
##V#      corrected an spelling error (dev/nul instead of /dev/null)
##V#
##V#   1.22.4 06.07.2006 /bs
##V#      corrected a bug in the parameter error handling routine
##V#
##V#   1.22.5 27.07.2006 /bs
##V#      corrected some minor bugs
##V#
##V#   1.22.6 09.08.2006 /bs
##V#      corrected some minor bugs
##V#
##V#   1.22.7 17.08.2006 /bs
##V#      add the CheckParameterCount function
##V#      added the parameter -T
##V#      added long parameter support (e.g --help)
##V#
##V#   1.22.8 07.09.2006 /bs
##V#      added code to save the env variable LANG and set it temporary to C
##V#
##V#   1.22.9 20.09.2006 /bs
##V#      corrected code to save the env variable LANG and set it temporary to C
##V#
##V#   1.22.10 21.09.2006 /bs
##V#      cleanup comments
##V#      the number of temporary files created automatically is now variable
##V#        (see the variable __NO_OF_TEMPFILES)
##V#      added code to install the trap handler in all functions
##V#
##V#   1.22.11 19.10.2006 /bs
##V#      corrected a minor bug in AskUser (/c was not interpreted by echo)
##V#      corrected a bug in the handling of the parameter -S (-S was ignored)
##V#
##V#   1.22.12 31.10.2006 /bs
##V#      added the variable __REQUIRED_ZONE
##V#
##V#   1.22.13 13.11.2006 /bs
##V#      the template now uses TMP or TEMP if set for the temporary files
##V#
##V#   1.22.14 14.11.2006 /bs
##V#      corrected a bug in the function AskUser (the default was y not n)
##V#
##V#   1.22.15 21.11.2006 /bs
##V#      added initial support for other Operating Systems
##V#
##V#   1.22.16 05.07.2007 /bs
##V#      enhanced initial support for other Operating Systems
##V#      Support for other OS is still not fully tested!
##V#
##V#   1.22.17 06.07.2007 /bs
##V#      added the global variable __TRAP_SIGNAL
##V#
##V#   1.22.18 01.08.2007 /bs
##V#      __OS_VERSION and __OS_RELEASE were not set - corrected
##V#
##V#   1.22.19 04.08.2007 /bs
##V#      wrong function used to print "__TRAP_SIGNAL is \"${__TRAP_SIGNAL}\"" - fixed
##V#
##V#   1.22.20 12.09.2007 /bs
##V#      the script now checks the ksh version if running on Solaris
##V#      made some changes for compatibility with ksh93
##V#
##V#   1.22.21 18.09.2007 /bs (BigAdmin Version 2)
##V#      added the variable __FINISHROUTINES
##V#      changed __REQUIRED_ZONE to __REQUIRED_ZONES
##V#      added the variable __KSH_VERSION
##V#      reworked the trap handling
##V#
##V#   1.22.22 23.09.2007 /bs
##V#      added the signal handling for SIGUSR1 and SIGUSR2 (variables __SIGUSR1_FUNC and __SIGUSR2_FUNC)
##V#      added user defined function for the signals HUP, BREAK, TERM, QUIT, EXIT, USR1 and USR2
##V#      added the variables __WARNING_PREFIX, __ERROR_PREFIX,  __INFO_PREFIX, and __RUNTIME_INFO_PREFIX
##V#      the parameter -T or --tee can now be on any position in the parameters
##V#      the default output file if called with -T or --tee is now
##V#        /var/tmp/${0##*/}.$$.tee.log
##V#
##V#   1.22.23 25.09.2007 /bs
##V#      added the environment variables __INFO_PREFIX, __WARNING_PREFIX,
##V#      __ERROR_PREFIX, and __RUNTIME_INFO_PREFIX
##V#      added the environment variable __DEBUG_HISTFILE
##V#      reworked the function to print the usage help :
##V#      use "-h -v" to view the extented usage help and use "-h -v -v" to
##V#          view the environment variables used also
##V#
##V#   1.22.24 05.10.2007 /bs
##V#      another minor fix for ksh93 compatibility
##V#
##V#   1.22.25 08.10.2007 /bs
##V#      only spelling errors corrected
##V#
##V#   1.22.26 19.11.2007 /bs
##V#      only spelling errors corrected
##V#
##V#   1.22.27 29.12.2007 /bs
##V#      improved the code to create the lockfile (thanks to wpollock for the info; see credits above)
##V#      improved the code to create the temporary files (thanks to wpollock for the info; see credits above)
##V#      added the function rand (thanks to wpollock for the info; see credits above)
##V#      the script now uses the directory name saved in the variable $TMPDIR for temporary files
##V#      if it's defined
##V#      now the umask used for creating temporary files can be changed (via variable __TEMPFILE_UMASK)
##V#
##V#   1.22.28 12.01.2008 /bs
##V#      corrected a syntax error in the show usage routine
##V#      added the function PrintWithTimestamp (see credits above)
##V#
##V#   1.22.29 31.01.2008 /bs
##V#      there was a bug in the new code to remove the lockfile which prevented
##V#      the script from removing the lockfile at program end
##V#      if the lockfile already exist the script printed not the correct error
##V#      message
##V#
##V#   1.22.30 28.02.2008 /bs
##V#      Info update: executeCommandAndLog does NOT return the RC of the executed
##V#      command if a logfile is defined
##V#      added inital support for CYGWIN
##V#      (tested with CYGWIN_NT-5.1 v..1.5.20(0.156/4/2)
##V#      Most of the internal functions are NOT tested yet in CYGWIN
##V#      GetCurrentUID now supports UIDs greater than 254; the function now prints the UID to STDOUT
##V#      Corrected bug in GetUserName (only a workaround, not the solution)
##V#      now using printf in the AskUserRoutine
##V#
##V#   1.22.30 28.02.2008 /bs
##V#     The lockfile is now also deleted if the script crashes because of a syntax error or something like this
##V#
##V#   1.22.31 18.03.2008 /bs
##V#     added the version number to the start and end messages
##V#     an existing config file is now removed (and not read) if the script is called with -C to create a config file
##V#
##V#   1.22.32 04.04.2008 /bs
##V#     minor changes for zone support
##V#
##V#   1.22.33 12.02.2009 /bs
##V#     disabled the usage of prtdiag due to the fact that prtdiag on newer Sun machines needs a long time to run
##V#     (-> __MACHINE_SUBTYPE is now always empty for Solaris machines)
##V#     added the variable __CONFIG_FILE_FOUND; this variable contains the name of the config file
##V#     read if a config file was found
##V#     added the variable __CONFIG_FILE_VERSION
##V#
##V#   1.22.34 28.02.2009 /bs
##V#     added code to check for the max. line no for the debug handler
##V#     (an array in ksh88 can only handle up to 4096 entries)
##V#     added the variable __PIDFILE
##V#
##V#  1.22.35 06.04.2009 /bs
##V#     added the variables
##V#       __NO_CLEANUP
##V#       __NO_EXIT_ROUTINES
##V#       __NO_TEMPFILES_DELETE
##V#       __NO_TEMPMOUNTS_UMOUNT
##V#       __NO_TEMPDIR_DELETE
##V#       __NO_FINISH_ROUTINES
##V#       __CLEANUP_ON_ERROR
##V#       CONFIG_FILE
##V#
##V#  1.22.36 11.04.2009 /bs
##V#     corrected a cosmetic error in the messages (wrong: ${TEMPFILE#} correct: ${__TEMPFILE#})
##V#
##V#  1.22.37 08.07.2011 /bs
##V#     corrected a minor error with the QUIET parameter
##V#     added code to dump the environment (env var __CREATE_DUMP, function CreateDump )
##V#     implemented work around for missing function whence in bash
##V#     added the function LogIfNotVerbose
##V#
##V#  1.22.38 22.07.2011 /bs
##V#     added code to make the trap handling also work in bash
##V#     added a sample user defined trap handler (function USER_SIGNAL_HANDLER)
##V#     added the function SetHousekeeping to enabe or disable house keeping
##V#     scriptt.sh did not write all messages to the logfile if a relative filename was used - fixed
##V#     added more help text for "-v -v -v -h"
##V#     now user defined signal handler can have arguments
##V#     the RBAC feature (__USE_RBAC) did not work as expected - fixed
##V#     added new scriptt testsuite for testing the script template on other OS and/or shells
##V#     added the function SaveEnvironmentVariables
##V#
##V#  1.22.39 24.07.2011 /bs
##V#     __INIT_FUNCTION now enabled for cygwin also
##V#     __SHELL did not work in all Unixes - fixed
##V#     __OS_FULLNAME is now also set in Solaris and Linux
##V#
##V#  1.22.40 25.07.2011 /bs
##V#     added some code for ksh93 (functions: substr)
##V#     Note: set __USE_ONLY_KSH88_FEATURES to ${__TRUE} to suppress using the ksh93 features
##V#     The default action for the signal handler USR1 is now "Create an env dump in /var/tmp"
##V#     The filenames for the dumps are
##V#
##V#      /var/tmp/<scriptname>.envvars.dump_no_<no>_<PID>
##V#      /var/tmp/<scriptname>.exported_envvars.dump_no_<no>_<PID>
##V#
##V#     where <no> is a sequential number, <PID> is the PID of the process with the script,
##V#     and <scriptname> is the name of the script without the path.
##V#
##V#  1.22.41 26.09.2011 /bs
##V#     added the parameter -X
##V#     disabled some ksh93 code because "ksh -x -n" using ksh88 does not like it
##V#
##V#  1.22.42 05.10.2011 /bs
##V#     added the function PrintDotToSTDOUT
##V#
##V#  1.22.43 15.10.2011 /bs
##V#     added support for disabling the config file feature with CONFIG_FILE=none ./scriptt.sh
##V#     corrected a minor bug in SaveEnvironmentVariables
##V#     corrected a bug in the function SaveEnvironmentVariables
##V#     corrected a bug in getting the value for the variable ${__ABSOLUTE_SCRIPTDIR}
##V#
##V#  1.22.44 22.04.2012 /bs
##V#     The script now uses nawk only if available (if not awk is used)
##V#     variables are now supported in the usage examples (prefixed with ##EXAMPLE##)
##V#     add a line with the current date and time to variable dumps, e.g.
##V#
##V#         ### /var/tmp/scriptt.sh.exported_envvars.dump_no_0_20074 - exported environment variable dump created on Sun Apr 22 11:35:38 CEST 2012
##V#
##V#         ### /var/tmp/scriptt.sh.envvars.dump_no_0_20074 - environment variable dump created on Sun Apr 22 11:35:38 CEST 2012
##V#
##V#     added experimental interactive mode to the signal handler for USR2
##V#     replaced /usr/bin/echo with printf
##V#     added the variable LOGMSG_FUNCTION
##V#
##V#  1.22.45 07.06.2012 /bs
##V#     added code to check if the symbolic link for the lockfile already exists before creating
##V#     the lock file
##V#
##V#  1.22.46 27.04.2013 /bs
##V#     executeCommandAndLog rewritten using coprocesses (see also credits)
##V#     Info update: executeCommandAndLog does now return the RC of the executed
##V#                  command even if a logfile is defined
##V#
##V# -------------------------------------------------------------------
##V#
##V#  2.0.0.0 17.05.2013 /bs
##V#     added the variable __GENERAL_SIGNAL_FUNCTION: This variable
##V#       contains the name of a function that is called for all SIGNALs
##V#       before the special SIGNAL handler is called
##V#     removed the Debug Handler for single step execution (due to the
##V#       length of the template it is not useful anymore; use the
##V#       version 1.x of scriptt.sh if you still need the Debug Handler)
##V#     function executeCommandAndLogSTDERR rewritten
##V#     removed the function CheckParameterCount
##V#     use lsb_release in Linux to retrieve OS infos if available
##V#     minor fixes for code and comments
##V#     replaced PrintWithTimeStamp with code that does not use awk
##V#     isNumber replaced with code that does not use sed
##V#
##V#  2.0.0.1 06.08.2013 /bs
##V#     added the variable __MACHINE_SUB_CLASS. Possible values
##V#     for sun4v machines: either "GuestLDom" or "PrimaryLDom"
##V#
##V#  2.0.0.2 01.09.2013 /bs
##V#     added the variables __SYSCMDS and __SYSCMDS_FILE
##V#
##V#  2.0.0.3 16.12.2013 /bs
##V#     now the Log-* functions return ${__TRUE} if a message is printed
##V#     and ${__FALSE} if not
##V#
##V#  2.0.0.4 01.01.2014 /bs
##V#     the alias __settrap is renamed to settraps (with leading s)
##V#     two new aliase are defined: __ignoretraps and __unsettraps
##V#     whence function for non-ksh compatible shells rewritten
##V#       without using ksh
##V#     the switch -D is now used to toggle debug switches
##V#       known debug switches:
##V#        help  -- print the usage help for -D
##V#         msg  -- log debug messages to /tmp/<scriptname>.<pid>.debug
##V#       trace  -- activate tracing to the file /tmp/<scriptname>.<pid>.trace
##V#     AskUser now accepts also "yes" and "no"
##V#     function IsFunctionDefined rewritten
##V#     now __LOGON_USERID and __USERID are equal to $LOGNAME until I
##V#     find a working solution (the code in the previous version
##V#       did not work if STDIN is not a tty)
##V#
##V#   2.0.0.5 08.01.2014 /bs
##V#     added the function executeFunctionIfDefined
##V#
##V#   2.0.0.6 27.01.2014 /bs
##V#     added the function PrintLine
##V#     added the functions GetSeconds, GetMinutes, ConvertMinutesToHours,
##V#       and GetTimeStamp
##V#     added the debug options fn_to_stderr, fn_to_tty, and fn_to_handle9
##V#     max. return value for a function is 255 and therefor the functions
##V#       for the stack and the functions pos and lastpos now abort the
##V#       script if a value greater than 255 should be returned
##V#     added the variables __SHEBANG, __SCRIPT_SHELL, and __SCRIPT_SHELL_OPTIONS
##V#     added the function DebugShell
##V#     AskUser now has a hidden shell; use "shell<return>" to call the DebugShell
##V#       set __DEBUG_SHELL_IN_ASKUSER to ${__FALSE} to disable the DebugShell
##V#       in AskUser
##V#     added the function ConvertDateToEpoc
##V#
##V#   2.0.0.7 27.04.2014 /bs
##V#     AskUser now save the last input in the variable LAST_USER_INPUT, to enter
##V#       this value again use "#last"
##V#     Version parameter (-V) usage enhanced:  use "-v -v  -V" to print also the version
##V#       history; use "-v -v -v -V" to also print the template version history.
##V#
#### ----------------
#### Version variables
####
#### __SCRIPT_VERSION - the version of your script
####
####
typeset  -r __SCRIPT_VERSION="v2.2.0"
####

#### __SCRIPT_TEMPLATE_VERSION - version of the script template
####
typeset -r __SCRIPT_TEMPLATE_VERSION="2.0.0.7 27.04.2014"
####


#### ----------------
####
##R# Predefined return codes:
##R# ------------------------
##R#
##R#    1 - show usage and exit
##R#    2 - invalid parameter found
##R#
##R#  210 - 232 reserved for the runtime system
##R#  233 - Can not write to handle 9
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
# awk basename cat cp cpio cut date dd dirname egrep expr find grep id
# ln ls nawk pwd perl
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


# -----------------------------------------------------------------------------

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
#### __SHEBANG - shebank of the script
#### __SCRIPT_SHELL - shell in the shebank of the script
#### __SCRIPT_SHELL_OPTIONS - shell options in the shebank of the script
####
####
__SHEBANG="$( head -1 $0 )"
__SCRIPT_SHELL="${__SHEBANG#*!}"
__SCRIPT_SHELL="${__SCRIPT_SHELL% *}"
__SCRIPT_SHELL_OPTIONS="${__SHEBANG#* }"
[ "${__SCRIPT_SHELL_OPTIONS}"x = "${__SHEBANG}"x ] && __SCRIPT_SHELL_OPTIONS=""

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
  typeset __FUNCTION="whence"; ${__FUNCTION_INIT} ; ${__DEBUG_CODE}
  typeset THISRC=1

  if typeset -f $1 1>/dev/null ; then
    echo $1 ; THISRC=0
  elif alias $1 2>/dev/null 1>/dev/null  ; then
    echo $1 ; THISRC=0
  else
    which $1 2>/dev/null ; THISRC=$?
  fi

  ${__FUNCTION_EXIT}
  return ${THISRC}
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
####
#### __DEBUG_SHELL_IN_ASKUSER - enable or disable the debug shell in AskUser
####
__DEBUG_SHELL_IN_ASKUSER=${__TRUE}

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
    exec  $0 $@ 2>&1 | tee -a "${__TEE_OUTPUT_FILE}"
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
__FUNCTION_INIT="${__FUNCTION_INIT:= eval __settraps }"

#### __FUNCTION_EXIT - code executed at end of every sub routine
####   (see the hints for __DEBUG_CODE)
####   Default exit code : ""
####
__FUNCTION_EXIT="${__FUNCTION_EXIT:= }"

#### variables for debugging
####
#### __NO_CLEANUP - do not call the cleanup routine at all at script end if ${__TRUE}
####
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

  DEFAULT_BACKUP_EXTENSION=".$$.backup"

#### DEFAULT_PRINT_DEBUG_MSGS - default for the debug switch
####
  DEFAULT_PRINT_DEBUG_MSGS=${__FALSE}

#### DEFAULT_SAN_DEVICE_ZONE_OUTPUTFILE -output file for the device zoning
####
  DEFAULT_SAN_DEVICE_ZONE_OUTPUTFILE=""


#### DEFAULT_USE_ALTERNATE_SLOT_NAMES - default for the parameter -D alternate_slot_names
####
  DEFAULT_USE_ALTERNATE_SLOT_NAMES=${__FALSE}

#### DEFAULT_PRINT_SLOT_LIST - default for the parameter -D print_slot_llist
####
  DEFAULT_PRINT_SLOT_LIST=${__FALSE}

#### DEFAULT_FCINFO_HBA_PORT_FILE - default for the parameter -D fcinfo=file
####
  DEFAULT_FCINFO_HBA_PORT_FILE=""

#### DEFAULT_PRTCONF_FILE - default for the parameter -D prtconf=file
####
  DEFAULT_PRT_CONF_FILE=""

#### DEFAULT_ETC_PATH_TO_INST_FILE - default for the parameter -D path_to_inst=file
####
  DEFAULT_ETC_PATH_TO_INST_FILE=""

#### DEFAULT_PRTDIAG_FILE - default for the parameter -d prtdiag=file
####
  DEFAULT_PRTDIAG_FILE=""

#### DEFAULT_LIST_ALL_SLOTS - default for the parameter -s
####
  DEFAULT_LIST_ALL_SLOTS=${__FALSE}

#### DEFAULT_ONLY_LIST_ALL_SLOTS - default for the parameter -P
####
  DEFAULT_ONLY_LIST_ALL_SLOTS=${__FALSE}


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
typeset -r __SHORT_DESC="check the fiber channel configuration in Solaris"

#### __LONG_USAGE_HELP - Additional help if the script is called with
####   the parameter "-v -h"
####
####   Note: To use variables in the help text use the variable name without
####         an escape character, eg. ${OS_VERSION}
####
__LONG_USAGE_HELP='
      -P    - only list all slots found; only supported for x86 and sun4v SPARC machines
              current value: $( ConvertToYesNo "${ONLY_LIST_ALL_SLOTS}" )
              Long format: --list_slots_only

      -s    - list all slots found; only supported for x86 and sun4v SPARC machines
              current value: $( ConvertToYesNo "${LIST_ALL_SLOTS}" )
              Long format: --list_all_slots

      -L outputfile
            - write the zoning for SAN devices to the file outputfile
              current value: ${SAN_DEVICE_ZONE_OUTPUTFILE}
              Long format: --logZoning

Legend:

PCI S/P          - PCI Slot / Port (sparc: prtdiag, x86: prtconf)
Device Path      - Solaris Device Path (/etc/path_to_inst)
Ctlr             - Solaris controller number (/dev/cfg/*)
State:           - state of the port (fcinfo)
Port WWN:        - port wwn (fcinfo)
Name:            - Solaris device name (/etc/path_to_inst)
# LUNs           - number of LUNs visible/uniq numer of LUNs visible (fcinfo)
# Disks          - number of disks visible (cfgadm)
# Tapes          - number of tapes visible (cfgadm)
# fabrics        - number of fabrics visible (cfgadm)
# misc           - number of devices visible that are neither tape nor disk (cfgadm)
SAN dev/w errors - SAN devices with errors (cfgadm)

Script tested on these kind of machines:

IBM x3650 M3, x3650 M4
Oracle X4-2L
Oracle x4800 (partial)
'

#### __SHORT_USAGE_HELP - Additional help if the script is called with the parameter "-h"
####
####   Note: To use variables in the help text use the variable name without an escape
####         character, eg. ${OS_VERSION}
####
__SHORT_USAGE_HELP='
                    -L outputfile [-s|+s] [-P|+P]

  Use the parameter \"-v -h [-v]\" to view the detailed online help; use the parameter \"-X\" to view some usage examples.

  see also http://bnsmb.de/solaris/scriptt.html

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
####   Note: Do not change this variable direct -- change __PRINT_SUMMARIES instead
####
__PRINT_LIST_OF_WARNINGS_MSGS=${__FALSE}

#### __PRINT_LIST_OF_ERROR_MSGS - print the list of error messages at program end (def.: false)
####   Note: Do not change this variable direct -- change __PRINT_SUMMARIES instead
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

  ${__FUNCTION_EXIT}
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

  ${__FUNCTION_EXIT}
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

  typeset THISRC=${__STACK_POINTER}

  ${__FUNCTION_EXIT}
  return ${THISRC}
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
####       In the current implementation the stack routines only support
####       up to 255 Stack elements
####
function FlushStack {
  typeset __FUNCTION="FlushStack";    ${__FUNCTION_INIT} ; ${__DEBUG_CODE}

  typeset THISRC=${__STACK_POINTER}
  __STACK_POINTER=0

  [ ${__STACK_POINTER} -gt 255 ] && die 234 "The return value is greater than 255 in function \"${__FUNCTION}\""

  ${__FUNCTION_EXIT}
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
####       In the current implementation the stack routines only support
####       up to 255 Stack elements
####
function push {
  typeset __FUNCTION="push";    ${__FUNCTION_INIT} ; ${__DEBUG_CODE}
  typeset THISRC=0

  while [ $# -ne 0 ] ; do
   (( __STACK_POINTER=__STACK_POINTER+1 ))
    __STACK[${__STACK_POINTER}]="$1"
    shift
  done

  ${__FUNCTION_EXIT}
  return ${THISRC}
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
####       In the current implementation the stack routines only support
####       up to 255 Stack elements
####
function pop {
  typeset __FUNCTION="pop";    ${__FUNCTION_INIT} ; ${__DEBUG_CODE}
  typeset THISRC=0

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

  ${__FUNCTION_EXIT}
  return ${THISRC}
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
####       In the current implementation the stack routines only support
####       up to 255 Stack elements
####
function push_and_set {
  typeset __FUNCTION="push_and_set";    ${__FUNCTION_INIT} ; ${__DEBUG_CODE}
  typeset THISRC=0

  if [ $# -ne 0 ] ; then
    typeset VARNAME="$1"
    eval push \$${VARNAME}

    shift
    eval ${VARNAME}="\"$*\""
  fi

  ${__FUNCTION_EXIT}
  return ${THISRC}
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

  ${__FUNCTION_EXIT}
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
  typeset THISRC=0

  case $1 in
   "y" | "Y" | "yes" | "YES" | "Yes" | "true" | "True"  | "TRUE"  | 0 ) echo "y" ;;
   "n" | "N" | "no"  | "NO"  | "No" | "false" | "False" | "FALSE" | 1 ) echo "n" ;;
   * ) echo "?" ;;
  esac

  ${__FUNCTION_EXIT}
  return ${THISRC}
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
  typeset THISRC=0

  eval "[ \$$1 -eq ${__TRUE} ] && $1=${__FALSE} || $1=${__TRUE} "

  ${__FUNCTION_EXIT}
  return ${THISRC}
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

  typeset THISRC=$?

  ${__FUNCTION_EXIT}
  return ${THISRC}
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
  typeset THISRC=0

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

  ${__FUNCTION_EXIT}
  return ${THISRC}
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

  ${__FUNCTION_EXIT}
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

  ${__FUNCTION_EXIT}
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

  ${__FUNCTION_EXIT}
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

  ${__FUNCTION_EXIT}
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

  typeset THISRC=${__FALSE}

# old code:
#  typeset TESTVAR="$(echo "$1" | sed 's/[0-9]*//g' )"
#  [ "${TESTVAR}"x = ""x ] && return ${__TRUE} || return ${__FALSE}

  [[ $1 == +([0-9]) ]] && THISRC=${__TRUE} || THISRC=${__FALSE}

  ${__FUNCTION_EXIT}
  return ${THISRC}
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
  typeset THISRC=0

  typeset -i16 HEXVAR
  HEXVAR="$1"
  echo ${HEXVAR##*#}

  ${__FUNCTION_EXIT}
  return ${THISRC}
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
  typeset THISRC=0

  typeset -i8 OCTVAR
  OCTVAR="$1"
  echo ${OCTVAR##*#}

  ${__FUNCTION_EXIT}
  return ${THISRC}
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
  typeset THISRC=0

  typeset -i2 BINVAR
  BINVAR="$1"
  echo ${BINVAR##*#}

  ${__FUNCTION_EXIT}
  return ${THISRC}
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
  typeset THISRC=0

  typeset -u testvar="$1"

  if [ "$2"x != ""x ] ; then
    eval $2=\"${testvar}\"
  else
    echo "${testvar}"
  fi

  ${__FUNCTION_EXIT}
  return ${THISRC}
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
  typeset THISRC=0

  typeset -l testvar="$1"

  if [ "$2"x != ""x ] ; then
    eval $2=\"${testvar}\"
  else
    echo "${testvar}"
  fi

  ${__FUNCTION_EXIT}
  return ${THISRC}
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

    THISRC=4
    return ${THISRC}
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

  ${__FUNCTION_EXIT}
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

  ${__FUNCTION_EXIT}
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
    THISRC=$( ( ( eval "$*" 2>&1; echo $? >&4 ) |tee "${__LOGFILE}" >&3 ) 4>&1 )

  else
    eval "$@"
    THISRC=$?
  fi

  __SYSCMDS="${__SYSCMDS}
# RC=${THISRC}"

  ${__FUNCTION_EXIT}
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

  ${__FUNCTION_EXIT}
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
  typeset THISRC=${__FALSE}

  [ "$( id | sed 's/uid=\([0-9]*\)(.*/\1/' )" = 0 ] && THISRC=${__TRUE} || THISRC=${__FALSE}

  ${__FUNCTION_EXIT}
  return ${THISRC}
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

  ${__FUNCTION_EXIT}
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
  typeset THISRC=0

  echo "$(id | sed 's/uid=\([0-9]*\)(.*/\1/')"

  ${__FUNCTION_EXIT}
  return ${THISRC}
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
  typeset THISRC=0

  [ "$1"x != ""x ] &&  __USERNAME=$( grep ":x:$1:" /etc/passwd | cut -d: -f1 )  || __USERNAME=""

  ${__FUNCTION_EXIT}
  return ${THISRC}
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
  typeset THISRC=0

  [ "$1"x != ""x ] &&  __USER_ID=$( grep "^$1:" /etc/passwd | cut -d: -f3 ) || __USER_ID=""

  ${__FUNCTION_EXIT}
  return ${THISRC}
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
  typeset __FUNCTION="PrintWithTimestamp";    ${__FUNCTION_INIT} ; ${__DEBUG_CODE}

  typeset COMMAND="$*"
  typeset THISRC=0

  LogInfo "Executing \"${COMMAND}\" ..."

  ${COMMAND} | while IFS= read -r line; do
    printf '[%s] %s\n' "$(date '+%Y-%m-%d %H:%M:%S')" "$line";
  done

  ${__FUNCTION_EXIT}
  return ${THISRC}
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

  ${__FUNCTION_EXIT}
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

  ${__FUNCTION_EXIT}
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

  ${__FUNCTION_EXIT}
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

  ${__FUNCTION_EXIT}
  return ${THISRC}
}

#### --------------------------------------
#### LogDebugMsg
####
#### print a debug message to STDERR and write it also to the logfile
####
#### usage: LogDebugMsg message
####
#### returns: ${__TRUE} - message printed
####          ${__FALSE} - message not printed
####
#### Notes: Use "- message" to suppress the date stamp
####        Use "-" to print a complete blank line
####
function LogDebugMsg {
  typeset __FUNCTION="LogDebugMsg";    ${__FUNCTION_INIT} ; ${__DEBUG_CODE}
  typeset THISRC=${__FALSE}
  LogMsg "[DEBUG] $*"

  ${__FUNCTION_EXIT}
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

  ${__FUNCTION_EXIT}
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
 
  typeset __OLD_INFO_PREFIX="${__INFO_PREFIX}"
 
  __INFO_PREFIX="${__RUNTIME_INFO_PREFIX}"
  LogInfo "${__RT_VERBOSE_LEVEL}" "$*"
  THISRC=$?
 
  __INFO_PREFIX="${__OLD_INFO_PREFIX}" 

  ${__FUNCTION_EXIT}
  return ${THISRC}
}

# internal sub routine for header messages
#
# returns: ${__TRUE} - message printed
#          ${__FALSE} - message not printed
#
function LogHeader {
  typeset __FUNCTION="LogHeader";    ${__FUNCTION_INIT} ; ${__DEBUG_CODE}
  typeset THISRC=${__FALSE}

  if [ "${__NO_HEADERS}"x != "${__TRUE}"x ] ; then
    LogMsg "$*"
    THISRC=${__TRUE}
  else
    [ "${__DEBUG_LOGFILE}"x != ""x ] && [ -f "${__DEBUG_LOGFILE}" ] && echo "$*" 2>/dev/null  >>"${__DEBUG_LOGFILE}"
  fi

  ${__FUNCTION_EXIT}
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

  ${__FUNCTION_EXIT}
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

  ${__FUNCTION_EXIT}
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

  ${__FUNCTION_EXIT}
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

  ${__FUNCTION_EXIT}
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
  "typeset" THISRC=${__TRUE}

  "typeset" USER_INPUT=""

  while "true" ; do
    "printf" "\n ------------------------------------------------------------------------------- \n"
    "printf" "${__SCRIPTNAME} - debug shell - enter a command to execute (\"exit\" to leave the shell)\n"
    "printf" ">> "
    "read" USER_INPUT

    case "${USER_INPUT}" in
      "exit" )
        "break";
        ;;

      "functions" | "func" | "funcs" )
        "typeset" -f | grep "\{$"
        ;;

      "" )
        :
        ;;

      * )
        "eval" ${USER_INPUT}
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
#### "shell" opens the DebugShell; set __DEBUG_SHELL_IN_ASKUSER to ${__FALSE}
#### to disable the DebugShell in AskUser
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

  ${__FUNCTION_EXIT}
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
  typeset THISRC=0

  trap "" 2 3
  [ $# -ne 0 ] && LogMsg "${THISMSG}"

  __STTY_SETTINGS="$( stty -g )"

  stty -echo raw
  USER_INPUT=$( dd count=1 2> /dev/null )

  stty ${__STTY_SETTINGS}
  __STTY_SETTINGS=""

  trap 2 3

  ${__FUNCTION_EXIT}
  return ${THISRC}
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
  typeset THISRC=0

  if [ ${__REBOOT_REQUIRED} -eq 0 ] ; then
    LogMsg "The changes made to the system require a reboot"

    AskUser "Do you want to reboot now (y/n, default is NO)?"
    if [ $? -eq ${__TRUE} ] ; then
      LogMsg "Rebooting now ..."
      echo "???" reboot ${__REBOOT_PARAMETER}
    fi
  fi

  ${__FUNCTION_EXIT}
  return ${THISRC}
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
#### If the variable ${__FORCE} is ${__TRUE} and the return code is NOT zero
#### die() will only print the error message and return
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

  [ ${__FORCE} = ${__TRUE} -a ${THISRC}x != 0x ] && return

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

  __END_TIME_IN_SECONDS="$( GetSeconds )"

  LogHeader "${__SCRIPTNAME} ${__SCRIPT_VERSION} started at ${__START_TIME} and ended at ${__END_TIME}."

  if [ "${__END_TIME_IN_SECONDS}"x != ""x -a  "${__START_TIME_IN_SECONDS}"x != ""x ] ; then
    (( __RUNTIME_IN_SECONDS = __END_TIME_IN_SECONDS - __START_TIME_IN_SECONDS ))
    (( __RUNTIME_IN_MINUTES = __RUNTIME_IN_SECONDS / 60 ))
    (( __RUNTIME_IN_SECONDS = __RUNTIME_IN_SECONDS % 60 ))

    LogHeader "The time used for the script is ${__RUNTIME_IN_MINUTES} minutes and ${__RUNTIME_IN_SECONDS} seconds."
  fi

  LogHeader "The RC is ${THISRC}."

  __EXIT_VIA_DIE=${__TRUE}

  if [ "${__GLOBAL_OUTPUT_REDIRECTION}"x != ""x ]  ; then
    StartStop_LogAll_to_logfile "stop"
  fi

  RemoveLockFile

  RebootIfNecessary

  ${__FUNCTION_EXIT}
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
  typeset THISRC=0

  if [ $# -ne 0 ] ; then

    LogRuntimeInfo "Including the script \"$*\" ..."

# set the variable for the TRAP handlers
    [ ! -f "$1" ] && die 247 "Include script \"$1\" not found"
    __INCLUDE_SCRIPT_RUNNING="$1"

# include the script
    . $*
    THISRC=$?

# reset the variable for the TRAP handlers
    __INCLUDE_SCRIPT_RUNNING=""

  fi

  ${__FUNCTION_EXIT}
  return ${THISRC}
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

  ${__FUNCTION_EXIT}
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
  typeset __FUNCTION="rand";    ${__FUNCTION_INIT} ; ${__DEBUG_CODE}

  typeset THISRC=${__FALSE}

  if [ "${RANDOM}"x != ""x ] ; then
    echo ${RANDOM}
    THISRC=${__TRUE}
  elif whence nawk >/dev/null ; then
    nawk 'BEGIN { srand(); printf "%d\n", (rand() * 10^8); }'
    THISRC=${__TRUE}
  fi

  ${__FUNCTION_EXIT}
  return ${THISRC}
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
  typeset __FUNCTION="PrintLockFileErrorMsg";    ${__FUNCTION_INIT} ; ${__DEBUG_CODE}
  typeset THISRC=250

  cat >&2  <<EOF

  ERROR:

  Either another instance of this script is already running
  or the last execution of this script crashes.
  In the first case wait until the other instance ends;
  in the second case delete the lock file

      ${__LOCKFILE}

  manually and restart the script.

EOF

  ${__FUNCTION_EXIT}
  return ${THISRC}
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
  typeset THISRC

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
    THISRC=0
  else
    THISRC=1
  fi

  ${__FUNCTION_EXIT}
  return ${THISRC}
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
  typeset THISRC=2

  if [ ! -L "${__LOCKFILE}" -a ! -f "${__LOCKFILE}" ] ; then
    THISRC=1
  elif [ ${__LOCKFILE_CREATED} -eq ${__TRUE} ] ; then
    LogRuntimeInfo "Removing the lock semaphore ..."

    rm "${__LOCKFILE}" 1>/dev/null 2>/dev/null
    [ $? -eq 0 ] && THISRC=0
  fi

  ${__FUNCTION_EXIT}
  return ${THISRC}
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
  typeset THISRC=0

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

  ${__FUNCTION_EXIT}
  return ${THISRC}
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
  typeset THISRC=0

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

  ${__FUNCTION_EXIT}
  return ${THISRC}
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

  ${__FUNCTION_EXIT}
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

  ${__FUNCTION_EXIT}
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
        "return"
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
            DebugShell
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

  ${__FUNCTION_EXIT}
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
  typeset THISRC=0


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

  ${__FUNCTION_EXIT}
  return ${THISRC}
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
  typeset THISRC=0

  eval "__SHORT_USAGE_HELP=\"${__SHORT_USAGE_HELP}\""

cat <<EOT
  ${__SCRIPTNAME} ${__SCRIPT_VERSION} - ${__SHORT_DESC}

  Usage: ${__SCRIPTNAME} [-v|+v] [-q|+q] [-h] [-l logfile|+l] [-y|+y] [-n|+n]
                    [-D debugswitch] [-a|+a] [-O|+O] [-f|+f] [-C] [-H] [-X] [-S n] [-V] [-T]
${__SHORT_USAGE_HELP}

EOT

  ${__FUNCTION_EXIT}
  return ${THISRC}
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
  typeset THISRC=0

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


  ${__FUNCTION_EXIT}
  return ${THISRC}
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

  ${__FUNCTION_EXIT}
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

  ${__FUNCTION_EXIT}
  return ${THISRC}
}


####
#### other subroutines that can be used in your code

# ??? add user defined subroutines here


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

# init the return code
  typeset THISRC=${__FALSE}
  typeset FORMAT_STRING="%Y-%m-%d"

  if [ $# -ge 1 ] ; then
    [ "$2"x != ""x ] && FORMAT_STRING=$2
    (( TIME_DIFF= $1 * 24 ))
    TZ=$TZ${TIME_DIFF} date "+${FORMAT_STRING}"
    THISRC=${__TRUE}
  fi
  ${__FUNCTION_EXIT}
  return ${THISRC}
}


#### --------------------------------------
#### ConvertDateToEpoc
####
#### convert a date into epoc time
####
#### usage: ConvertDateToEpoc [day month year hours minutes seconds] {diff}
####
#### returns:  ${__TRUE} - ok
####           ${__FALSE} - error
####
####           The epoc time is printed to STDOUT
####
function ConvertDateToEpoc {
  typeset __FUNCTION="GetTimeStamp";   ${__FUNCTION_INIT} ;
  ${__DEBUG_CODE}

# init the return code
  typeset THISRC=${__TRUE}

  typeset DIFF=${7:=0}
  typeset PERL_PROG="

$day=$1 ;
$month=$2 ;
$year=$3 ;
$hour=$4-$7 ;
$minute=$5 ;
$seconds=$6

  use Time::Local;
  print timelocal($second,$minute,$hour,$day,$month-1,$year);
"
  echo "${PERL_PROG}" | perl

  ${__FUNCTION_EXIT}

  return ${THISRC}
}


#### --------------------------------------
#### GetTimeStamp
####
#### get the current time stamp in the format dd:mm:yyyy hh:mm
####
#### usage: GetTimeStamp
####
#### returns:  ${__TRUE} - ok
####           ${__FALSE} - error
####
####           The timestamp is printed to STDOUT
####
function GetTimeStamp {
  typeset __FUNCTION="GetTimeStamp";   ${__FUNCTION_INIT} ;
  ${__DEBUG_CODE}

# init the return code
  typeset THISRC=${__TRUE}
  date +"%d.%m.%Y %H:%M"

  ${__FUNCTION_EXIT}
  return ${THISRC}
}

#### --------------------------------------
#### GetSeconds
####
#### get the seconds since 1970-01-01 00:00:00 UTC
####
#### usage: GetSeconds
####
#### returns:  ${__TRUE} - ok
####           ${__FALSE} - error
####
####           The seconds are printed to STDOUT
####
function GetSeconds {
  typeset __FUNCTION="GetSeconds";   ${__FUNCTION_INIT} ;
  ${__DEBUG_CODE}

# init the return code
  typeset THISRC=${__FALSE}

  perl -e 'print int(time)' 2>/dev/null
  THISRC=$?

  ${__FUNCTION_EXIT}
  return ${THISRC}
}

#### --------------------------------------
#### GetMinutes
####
#### get the minutes since 1970-01-01 00:00:00 UTC
####
#### usage: GetMinutes
####
#### returns:  ${__TRUE} - ok
####           ${__FALSE} - error
####
####           The minutes are printed to STDOUT
####
function GetMinutes {
  typeset __FUNCTION="GetMinutes";   ${__FUNCTION_INIT} ;
  ${__DEBUG_CODE}

# init the return code
  typeset THISRC=${__FALSE}

  typeset m1="$( GetSeconds  )"
  if [ $? -eq 0 ] ; then
    typeset m2
    (( m2 = m1 / 60  ))
    echo $m2
    THISRC=${__TRUE}
  fi

  ${__FUNCTION_EXIT}
  return ${THISRC}
}

#### --------------------------------------
#### ConvertMinutesToHours
####
#### convert a number of minutes in hh:mm
####
#### usage: ConvertMinutesToHours
####
#### returns:  ${__TRUE} - ok
####           ${__FALSE} - error
####
####           The result is printed to STDOUT
####
function ConvertMinutesToHours {
  typeset __FUNCTION="ConvertMinutesToHours";   ${__FUNCTION_INIT} ;
  ${__DEBUG_CODE}

# init the return code
  typeset THISRC=${__FALSE}

  if [ $# = 1 ] ; then
    isNumber $1
    if [ $? -eq ${__TRUE} ] ; then
      typeset -Z2 h
      typeset -Z2 m
      (( h = $1 / 60 ))
      (( m = $1 % 60 ))
      echo "$h:$m"
      THISRC=${__TRUE}
    fi
  fi

  ${__FUNCTION_EXIT}
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

  ${__FUNCTION_EXIT}
  return ${THISRC}
}


#### --------------------------------------
#### PrintLine
####
#### print a line with n times the character c
####
#### usage: PrintLine [n] {c} {msg}
####
#### returns:  ${__TRUE} - ok
####           ${__FALSE} - error
####
#### default for c is "-"
####
function PrintLine {
  typeset __FUNCTION="PrintLine";   ${__FUNCTION_INIT} ;
  ${__DEBUG_CODE}


# init the return code
  typeset THISRC=${__FALSE}
  typeset n
  typeset c
  typeset m

  if [ $# -ge 1 ] ; then
    n=$1
    c=${2:=-}
    m=$3
    eval printf \'%0.1s\' "$c"\{1..$n\}
    printf $m
    typeset THISRC=${__TRUE}
  fi

  ${__FUNCTION_EXIT}
  return ${THISRC}
}

# -----------------------------------------------------------------------------
# functions:
#

# ??? insert additional functions here


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
  echo "In YourRoutine -- "

  [ ${THISRC} -gt 255 ] && die 234 "The return value is greater than 255 in function \"${__FUNCTION}\""

  ${__FUNCTION_EXIT}
  return ${THISRC}
}

#### --------------------------------------
#### Getx86PCISlotUsage
####
#### get the PCI Slot Usage for x86
####
#### usage: Getx86PCISlotUsage
####
#### returns:  ${__TRUE} - ok
####           ${__FALSE} - error
####
####
function Getx86PCISlotUsage {
  typeset __FUNCTION="Getx86PCISlotUsage";   ${__FUNCTION_INIT} ;
  ${__DEBUG_CODE}

# init the return code
  typeset THISRC=${__TRUE}

  typeset PRTCONF_OUT=""
  typeset ETC_PATH_TO_INST=""
  typeset line=""

  [ "$1"x != ""x ] && PRTCONF_OUT="$( cat $1 )" || PRTCONF_OUT="$( prtconf -vpPD )"
  [ "$2"x != ""x ] && ETC_PATH_TO_INST="$( cat $2 )"  || ETC_PATH_TO_INST="$( cat /etc/path_to_inst )"

  typeset NO_OF_SLOTS=0
  typeset SLOT_FOUND=${__FALSE}
  typeset SLOT_MODEL[${NO_OF_SLOTS}]="initial"

  typeset CURLINE=0
  echo "${PRTCONF_OUT}" | while read line ; do
    (( CURLINE = CURLINE + 1 ))
    if [[ $line == *physical-slot#:* ]] ; then
      SLOT_FOUND="${__TRUE}"
      if [ "${SLOT_MODEL[${NO_OF_SLOTS}]}"x != ""x ] ; then
        (( NO_OF_SLOTS = NO_OF_SLOTS + 1 ))
      fi

      SLOT_NO[${NO_OF_SLOTS}]="$( set -- $line ; eval echo \$$# )"

      SLOT_MODEL[${NO_OF_SLOTS}]=""
      SLOT_ADDRESS[${NO_OF_SLOTS}]=""
      SLOT_ADAPTER[${NO_OF_SLOTS}]=""
      LogInfo "Slot No ${NO_OF_SLOTS} found (in line ${CURLINE}, Index is ${NO_OF_SLOTS} )"
    fi

    if [ "${SLOT_FOUND}" = "${__TRUE}" ] ; then
      if [[ $line == *name:* ]] ; then
        if [ "${SLOT_ADDRESS[${NO_OF_SLOTS}]}"x = ""x ] ; then
          SLOT_ADDRESS[${NO_OF_SLOTS}]="$( echo ${line}  |  cut -f2 -d "'" )"
#'
          LogInfo "SLOT ADDRESS is ${SLOT_ADDRESS[${NO_OF_SLOTS}]} (in line ${CURLINE}, Index is ${NO_OF_SLOTS} )"
        else
          SLOT_ADAPTER[${NO_OF_SLOTS}]="$( echo ${line}  |  cut -f2 -d "'" )"
#'
          LogInfo "SLOT ADAPTER is ${SLOT_ADAPTER[${NO_OF_SLOTS}]} (in line ${CURLINE}, Index is ${NO_OF_SLOTS} )"
          SLOT_FOUND="${__FALSE}"
        fi
      elif [[ $line == *model:* ]] ; then
        CUR_MODEL="$( echo ${line}  |  cut -f2 -d "'" )"
#'
        if [ "${CUR_MODEL}"x = "PCI-PCI bridge"x -o "${CUR_MODEL}"x = "PCIe-PCI bridge"x ] ; then
          SLOT_ADDRESS[${NO_OF_SLOTS}]=""
          SLOT_ADAPTER[${NO_OF_SLOTS}]=""
          SLOT_MODEL[${NO_OF_SLOTS}]=""
          LogInfo "SLOT MODEL ${CUR_MODEL} ignored (in line ${CURLINE}, Index is ${NO_OF_SLOTS} )"
        else
          SLOT_MODEL[${NO_OF_SLOTS}]="${CUR_MODEL}"
          LogInfo "SLOT MODEL is ${SLOT_MODEL[${NO_OF_SLOTS}]} (in line ${CURLINE}, Index is ${NO_OF_SLOTS} )"
        fi
      fi
    fi
  done
  LogInfo "${NO_OF_SLOTS} slot(s) found."

  if [ ${PRINT_SLOT_LIST} = ${__TRUE} ] ; then
    i=0
    while [ $i -lt ${NO_OF_SLOTS} ] ; do
      (( i = i + 1 ))

      SLOT_ADDRESS="${SLOT_ADDRESS[${i}]}"
      SLOT_MODEL="${SLOT_MODEL[${i}]}"
      SLOT_ADAPTER="${SLOT_ADAPTER[${i}]}"

      LogMsg "-"
      LogMsg "-" "Slot no $i: Adress: ${SLOT_ADDRESS}, Adapter: ${SLOT_ADAPTER}, Model: ${SLOT_MODEL}"
      LogMsg "-"
    done
  fi

  typeset -R10 P_SLOT_NO="Slot No."
  typeset -R40 P_SLOT_ADAPTER_CLASS="Adapter class"
  typeset -R40 P_SLOT_DEVICE_PATH="Device path"
  typeset -R60 P_SLOT_DEVICE_NAME="Device name"

  typeset Getx86PCISlotUsage_OUTPUT_TITLE="
${P_SLOT_NO}${P_SLOT_ADAPTER_CLASS}${P_SLOT_DEVICE_PATH}${P_SLOT_DEVICE_NAME}"

  typeset Getx86PCISlotUsage_OUTPUT_BODY=""

  typeset THIS_ADAPTER=""
  typeset i=0

  while [ $i -lt ${NO_OF_SLOTS} ] ; do
    (( i = i + 1 ))

    SLOT_ADDRESS="${SLOT_ADDRESS[${i}]}"
    SLOT_MODEL="${SLOT_MODEL[${i}]}"
    SLOT_ADAPTER="${SLOT_ADAPTER[${i}]}"

    (( SLOT_NO[${i}] = ${SLOT_NO[${i}]} + 0 ))
    P_SLOT_NO="${SLOT_NO[${i}]}"

    P_SLOT_ADAPTER_CLASS="${SLOT_MODEL}"
    P_SLOT_DEVICE_PATH="${SLOT_ADDRESS}/${SLOT_ADAPTER}"
    P_SLOT_DEVICE_NAME=""

    if [ ${USE_ALTERNATE_SLOT_NAMES} = ${__TRUE} ] ; then
# 02.09.2014/bs v1.2.3 : I do not know anymore why I used this code:
      THIS_ADAPTER="${SLOT_ADAPTER%,*}"
    else
      THIS_ADAPTER="${SLOT_ADAPTER}"
    fi

    echo "${ETC_PATH_TO_INST}" | grep "${SLOT_ADDRESS}@" | egrep "${THIS_ADAPTER}.*@"  | while read line ; do
      [[ ${line} == */${SLOT_ADDRESS}@*/${SLOT_ADAPTER}@*/* ]] && [ "${SLOT_MODEL[${i}]}"x != "PCI-PCI bridge"x ] && continue
      set -- $line
      eval DEVNAME=$3
      eval DEVNO=$2
      [[ ${DEVNAME} == pcieb* ]]  && continue
      P_SLOT_DEVICE_NAME="${P_SLOT_DEVICE_NAME} ${DEVNAME}${DEVNO}"

      if [ ${PRINT_DEBUG_MSGS} = ${__TRUE} ] ; then
        LogDebugMsg  "Setting \"ADAPTER_${DEVNAME}${DEVNO}\" to \"${SLOT_NO[${i}]}\""
      fi

#      eval ADAPTER_${DEVNAME}${DEVNO}=PCI\"${P_SLOT_NO}\"
      eval ADAPTER_${DEVNAME}${DEVNO}=PCI\"${SLOT_NO[${i}]}\"

    done

    Getx86PCISlotUsage_OUTPUT_BODY="${Getx86PCISlotUsage_OUTPUT_BODY}
${P_SLOT_NO}${P_SLOT_ADAPTER_CLASS}${P_SLOT_DEVICE_PATH}${P_SLOT_DEVICE_NAME}"

  done

  Getx86PCISlotUsage_OUTPUT="${Getx86PCISlotUsage_OUTPUT_TITLE}
$( echo "${Getx86PCISlotUsage_OUTPUT_BODY}" | grep -v "^$" | sort )
"

  return ${THISRC}
}

#### --------------------------------------
#### GetSPARCPCISlotUsage
####
#### get the PCI Slot Usage for SPARC 
####
#### usage: GetSPARCPCISlotUsage
####
#### returns:  ${__TRUE} - ok
####           ${__FALSE} - error
####
####
function GetSPARCPCISlotUsage {
  typeset __FUNCTION="GetSPARCPCISlotUsage";   ${__FUNCTION_INIT} ;
  ${__DEBUG_CODE}

# init the return code
  typeset THISRC=${__TRUE}

  typeset PRTDIAG_OUT=""
  typeset ETC_PATH_TO_INST=""

  typeset THIS_LINE=""
  typeset THIS_DEVICE=""
  typeset THIS_VAR=""
  typeset THIS_INDEX=""
  
  typeset NO_OF_SLOTS=0
  typeset CURLINE=0

  typeset SLOT_FOUND=${__FALSE}

  LogMsg "Retrieving the infos from \"prtdiag -v\" ..."
  [ "$1"x != ""x ] && PRTDIAG_OUT="$( cat $1 )" || PRTDIAG_OUT="$( prtdiag -v )"
  LogMsg "Retrieving the infos from \"cat /etc/path_to_inst\" ..."
  [ "$2"x != ""x ] && ETC_PATH_TO_INST="$( cat $2 )"  || ETC_PATH_TO_INST="$( cat /etc/path_to_inst )"

  
  if echo "${PRTDIAG_OUT}" | grep "sun4u" >/dev/null ; then
    LogWarning "This looks like an sun4u machine -- this machine type is not supported by this script!"
    LogMsg "-"
  elif ! echo "${PRTDIAG_OUT}" | grep "Firmware"  >/dev/null ; then
    LogWarning "This looks like an I/O domain -- the PCI slot usage shown by this script is most likely not valid!"
    LogMsg "-"
  fi
  
  IO_DEVICE_SECTION_FOUND=${__FALSE}
  
  echo "${PRTDIAG_OUT}" | while read THIS_LINE ; do

    (( CURLINE = CURLINE + 1 ))

    if [[ "${THIS_LINE}"x == *=\ IO\ \Devices\ =* ]] ; then
      IO_DEVICE_SECTION_FOUND=${__TRUE}
      continue        
    fi
    
    if [[ "${THIS_LINE}"x == *=\ Environmental\ Status\ =* ]] ; then
      IO_DEVICE_SECTION_FOUND=${__FALSE}
      break
    fi

    if [ ${IO_DEVICE_SECTION_FOUND} != ${__TRUE} ] ; then
      continue
    fi

    if [ "${SLOT_FOUND}" = "${__TRUE}" ] ; then
      [ "${SPARC_SLOT_ADDRESS[${CUR_SLOT}]}"x = ""x ] && SPARC_SLOT_ADDRESS[${CUR_SLOT}]="${THIS_LINE}"
      THIS_DEVICE="$( grep \"${THIS_LINE}\" /etc/path_to_inst | tr -d '"' | awk '{ print $3$2 };' )"
      SPARC_SLOT_DEVICE[${CUR_SLOT}]="${SPARC_SLOT_DEVICE[${CUR_SLOT}]} ${THIS_DEVICE}"

      SLOT_FOUND=${__FALSE}
      continue
    fi 

    if [[ ${THIS_LINE} == /SYS/* || ${THIS_LINE} == *PCIE* ]] ; then
      SLOT_FOUND="${__TRUE}"

      THIS_VAR="$(echo ${THIS_LINE} | cut -f1 -d " " )"
      THIS_VAR="${THIS_VAR##*/}"

      eval THIS_INDEX="\${${THIS_VAR}_INDEX}"
      if [ "${THIS_INDEX}"x = ""x ] ; then

        (( NO_OF_SLOTS = NO_OF_SLOTS + 1 ))
        CUR_SLOT=${NO_OF_SLOTS}
        eval ${THIS_VAR}_INDEX=${CUR_SLOT}

        SPARC_SLOT_NO[${CUR_SLOT}]="${THIS_VAR}"
        THIS_VAR="$( echo ${THIS_LINE}| awk '{ print $5 };' )"
        if [ "${THIS_VAR}"x = ""x ] ; then
          THIS_VAR="internal"
        else          
          THIS_VAR="$( echo ${THIS_LINE}| awk '{ print $4 };' )"      
          [ "${THIS_VAR}"x = ""x ] && THIS_VAR="internal"
        fi
        SPARC_SLOT_MODEL[${CUR_SLOT}]="${THIS_VAR}"

        SPARC_SLOT_ADDRESS[${CUR_SLOT}]=""
      else
        CUR_SLOT=${THIS_INDEX}
      fi
      continue      
    fi
   
  done

  LogInfo "${NO_OF_SLOTS} slot(s) found."

  if [ ${PRINT_SLOT_LIST} = ${__TRUE} ] ; then
    i=0
    while [ $i -lt ${NO_OF_SLOTS} ] ; do
      (( i = i + 1 ))

      SPARC_SLOT_NO="${SPARC_SLOT_NO[${i}]}"
      SPARC_SLOT_ADDRESS="${SPARC_SLOT_ADDRESS[${i}]}"
      SPARC_SLOT_MODEL="${SPARC_SLOT_MODEL[${i}]}"
      SPARC_SLOT_DEVICE="${SPARC_SLOT_DEVICE[${i}]}"

      LogMsg "-"
      LogMsg "-" "Slot no $i: Slot ${SPARC_SLOT_NO}, Adress: ${SPARC_SLOT_ADDRESS},  Model: ${SPARC_SLOT_MODEL}, Devices: ${SPARC_SLOT_DEVICE}"
      LogMsg "-"
    done
  fi

  typeset -R10 P_SLOT_NO="Slot No."
  typeset -R40 P_SLOT_MODEL="Adapter model"
  typeset -R60 P_SLOT_ADDRESS="Device path"
  typeset -R40 P_SLOT_DEVICE="Device name"

  typeset GetSPARCPCISlotUsage_OUTPUT_TITLE="
${P_SLOT_NO}${P_SLOT_MODEL}${P_SLOT_ADDRESS}${P_SLOT_DEVICE}"

  typeset GetSPARCPCISlotUsage_OUTPUT_BODY=""

  typeset THIS_ADAPTER=""
  typeset i=0
  while [ $i -lt ${NO_OF_SLOTS} ] ; do
    (( i = i + 1 ))

    P_SLOT_NO="${SPARC_SLOT_NO[${i}]}"
    P_SLOT_MODEL="${SPARC_SLOT_MODEL[${i}]}"
    P_SLOT_ADDRESS="${SPARC_SLOT_ADDRESS[${i}]}"
    P_SLOT_DEVICE="${SPARC_SLOT_DEVICE[${i}]}"


    GetSPARCPCISlotUsage_OUTPUT_BODY="${GetSPARCPCISlotUsage_OUTPUT_BODY}
${P_SLOT_NO}${P_SLOT_MODEL}${P_SLOT_ADDRESS}${P_SLOT_DEVICE}"

  done
  
  GetSPARCPCISlotUsage_OUTPUT="${GetSPARCPCISlotUsage_OUTPUT_TITLE}
$( echo "${GetSPARCPCISlotUsage_OUTPUT_BODY}" | grep -v "^$" | sort )
"

  return ${THISRC}
}


#### --------------------------------------
#### SaveConfigFileForLaterUse
####
#### save the config files used by this script
####
#### usage: SaveConfigFileForLaterUse {outputfile}
####
#### returns:  ${__TRUE} - ok
####           ${__FALSE} - error
####
####
function SaveConfigFileForLaterUse {
  typeset __FUNCTION="SaveConfigFileForLaterUse";   ${__FUNCTION_INIT} ;
  ${__DEBUG_CODE}

# init the return code
  typeset THISRC=${__TRUE}
  
  typeset SAVE_OS_CONFIG="$1"
  
  typeset TMPDIR=""
  typeset OUTFILE=""
  
  LogMsg "Saving the OS config files into the tar file \"${SAVE_OS_CONFIG}\" ..."

  touch "${SAVE_OS_CONFIG}" || die 17 "Can not write to the file \"${SAVE_OS_CONFIG}\" "

  TMPDIR="/tmp/$( basename ${SAVE_OS_CONFIG} ).$$.tmp"
  mkdir -p "${TMPDIR}" || die 19 "Can not create the temporary directory \"${TMPDIR}\" "
  __LIST_OF_TMP_DIRS="${__LIST_OF_TMP_DIRS} ${TMPDIR} "

  cd "${TMPDIR}" || die 19 "Can not change the current directory to the temporary directory \"${TMPDIR}\" "

  OUTFILE="prtconf.out"
  LogMsg "Creating the file \"${OUTFILE}\" using \"prtconf -vpPD\" ..."
  prtconf -vpPD >"${OUTFILE}" || LogWarning "Error creating the file \"${OUTFILE}\" "

  OUTFILE="prtdiag.out"
  LogMsg "Creating the file \"${OUTFILE}\" using \"prtdiag -v\" ..."
  prtdiag -v >"${OUTFILE}" || LogWarning "Error creating the file \"${OUTFILE}\" "

  OUTFILE="fcinfo.out"
  LogMsg "Creating the file \"${OUTFILE}\" using \"fcinfo hba-port\" ..."
  fcinfo hba-port >"${OUTFILE}" || LogWarning "Error creating the file \"${OUTFILE}\" "

  OUTFILE="path_to_inst.out"
  LogMsg "Creating the file \"${OUTFILE}\" using \"cat /etc/path_to_inst\" ..."
  cat /etc/path_to_inst >"${OUTFILE}" || LogWarning "Error creating the file \"${OUTFILE}\" "

  LogMsg "Creating the tar file \"${SAVE_OS_CONFIG}\" ..."
  tar -cvf "${SAVE_OS_CONFIG}" . || LogWarning "Error creating the tar file"

  LogMsg "-"
  LogMsg "-" "Unpack the tar file \"${SAVE_OS_CONFIG}\" and use the script with the parameter

$0 -D fcinfo=./fcinfo.out -D prtconf=./prtconf.out -D path_to_inst=./path_to_inst.out -D prtdiag=./prtdiag.out

to use these files.
"

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

  return ${THISRC}
}

# -----------------------------------------------------------------------------
# main:
#

#  __START_TIME_IN_SECONDS="$( GetSeconds )"

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

# add functions that should be called automatically at program end
# after removing temporary files, directories, and mounts
# to this variable
#
#  __FINISHROUTINES="${__FINISHROUTINES} "

# variables used by getopts:
#    OPTIND = index of the current argument
#    OPTARG = current function character
#
  THIS_PARAMETER="$*"

  INVALID_PARAMETER_FOUND=${__FALSE}

  __PRINT_USAGE=${__FALSE}
  CUR_SWITCH=""
  OPTARG=""

# ??? add additional switch characters here
#
  [ "${__OS}"x = "Linux" ] &&  GETOPT_COMPATIBLE="0"


  __GETOPTS="+:ynvqhHD:fl:aOS:CVTXL:sP"
  if [ "${__OS}"x = "SunOS"x -a "${__SHELL}"x = "ksh"x ] ; then
    if [ "${__OS_VERSION}"x  = "5.10"x -o  "${__OS_VERSION}"x  = "5.11"x ] ; then
      __GETOPTS="+:y(yes)n(no)v(verbose)q(quiet)h(help)H(doc)D:(debug)f(force)l:(logfile)\
a(color)O(overwrite)S:(summaries)C(writeconfigfile)V(version)T(tee)X(view_examples)L:(logZoning)s(list_all_slots)P(list_slots_only)"
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
               if [ ${__VERBOSE_LEVEL} -gt 1 ] ; then
                 LogMsg "-"
                 T=$( grep "^##v#" "$0" | cut -c4- )
                 eval T1="\"$T\""
                 echo "$T1"
               fi
               if [ ${__VERBOSE_LEVEL} -gt 2 ] ; then
                 LogMsg "-"
                 T=$( grep "^##V#" "$0" | cut -c4- )
#                eval T1="\"$T\""
                 echo "$T"
               fi
               __VERBOSE_LEVEL=0
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

      "+s" ) LIST_ALL_SLOTS=${__FALSE} ;;

       "s" ) LIST_ALL_SLOTS=${__TRUE} ;;

      "+P" ) ONLY_LIST_ALL_SLOTS=${__FALSE} ;;

       "P" ) ONLY_LIST_ALL_SLOTS=${__TRUE} ;;

       "L" )
             SAN_DEVICE_ZONE_OUTPUTFILE="${OPTARG}"
             if [ "${SAN_DEVICE_ZONE_OUTPUTFILE}"x != "console"x -a "${SAN_DEVICE_ZONE_OUTPUTFILE}"x != "STDOUT"x ] ; then
               [ "$( substr ${SAN_DEVICE_ZONE_OUTPUTFILE} 1 1 )"x != "/"x ] && SAN_DEVICE_ZONE_OUTPUTFILE="$PWD/${SAN_DEVICE_ZONE_OUTPUTFILE}"
             fi
             ;;

      "+L" ) SAN_DEVICE_ZONE_OUTPUTFILE=""
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


# -----------------------------------------------------------------------------
# process the debug switches

  SAVE_OS_CONFIG=""
  if [ "${__DEBUG_SWITCHES}"x != ""x ] ; then
     __DEBUG_SWITCHES=$( IFS=, ; printf "%s " ${__DEBUG_SWITCHES}  )

    for __CUR_DEBUG_SWITCH in ${__DEBUG_SWITCHES} ; do

      case ${__CUR_DEBUG_SWITCH} in

        "help" )
           cat <<EOT
Known debug switches (for -d / --debug):

  help          -- show this usage and exit
  msg           -- log debug messages to the file ${__DEBUG_LOGFILE}
  trace         -- activate tracing to the file ${__TRACE_LOGFILE}
  fn_to_stderr  -- print the function names to STDERR
  fn_to_tty     -- print the function names to /dev/tty
  fn_to_handle9 -- print the function names ot the file handle 9
  debug         -- print debug infos

  save_os_config=file
                -- save the OS config files that can be used as input files
                   for this script in the tar file "file" and exit
  alternate_slot_names=[yes|no]
                -- use alternate slot name syntax, try this switch if
                   the PCI slot usage shown by this script is not
                   correct
  print_slot_list
                -- print the list of slots found (x86 only)
  prtdiag=file  -- file with the output of "prtdiag -v" (used for sparc only)
  fcinfo=file   -- file with the output of "fcinfo hba-port"
  prtconf=file  -- file with the output of "prtconf -vpPD" (used for x86 only)
  path_to_inst=file
                -- copy of the file /etc/path_to_inst
EOT
            die 0
            ;;


        debug )
            PRINT_DEBUG_MSGS=${__TRUE}
            ;;

        nodebug )
            PRINT_DEBUG_MSGS=${__FALSE}
            ;;

    debugcode=* )
        DEBUG_PARAMETER_OKAY=${__TRUE}

        CUR_STATEMENT="${CUR_DEBUG_SWITCH#*=}"
        LogDebugMsg "Adding the debug code \"${CUR_STATEMENT}\" to all functions."
        __DEBUG_CODE="${CUR_STATEMENT}"
        ;;

    debugenv | debug=* )
        DEBUG_PARAMETER_OKAY=${__TRUE}
        CUR_STATEMENT="${CUR_DEBUG_SWITCH#*=}"
        if [ "${CUR_STATEMENT}"x != ""x  -a "${CUR_STATEMENT}"x != "debug"x ] ; then
          LogDebugMsg "Executing \"${CUR_STATEMENT}\" ..."
          ${CUR_STATEMENT}
        else
          LogDebugMsg "Starting debug environment ..."
          set +e
          while true ; do
            printf ">> "
            read USER_INPUT
            eval ${USER_INPUT}
            if [ "${USER_INPUT}"x = "quiet"x -o "${USER_INPUT}"x = "q"x  ] ; then
              break
            elif [ "${USER_INPUT}"x = "exit"x ] ; then
              die 255
            fi
          done
        fi
        ;;


        alternate_slot_names=* )
            [ "${__CUR_DEBUG_SWITCH#*=}"x = "yes"x ] && USE_ALTERNATE_SLOT_NAMES=${__TRUE} || USE_ALTERNATE_SLOT_NAMES=${__FALSE}
            ;;

        print_slot_list )
            PRINT_SLOT_LIST=${__TRUE}
            ;;

        prtdiag=* )
            [ "${__CUR_DEBUG_SWITCH#*=}"x != "none"x ] && PRTDIAG_FILE="${__CUR_DEBUG_SWITCH#*=}" || PRTDIAG_FIILE=""
            ;;

        fcinfo=* )
            [ "${__CUR_DEBUG_SWITCH#*=}"x != "none"x ] && FCINFO_HBA_PORT_FILE"${__CUR_DEBUG_SWITCH#*=}" || FCINFO_HBA_PORT_FILE=""
            ;;

        prtconf=* )
            [ "${__CUR_DEBUG_SWITCH#*=}"x != "none"x ] && PRTCONF_FILE="${__CUR_DEBUG_SWITCH#*=}" || PRTCONF_FILE=""
            ;;

        path_to_inst=* )
            [ "${__CUR_DEBUG_SWITCH#*=}"x != "none"x ] && ETC_PATH_TO_INST_FILE="${__CUR_DEBUG_SWITCH#*=}" || ETC_PATH_TO_INST_FILE=""
            ;;

        save_os_config | save_os_config=* )
            if [ "${__CUR_DEBUG_SWITCH#*=}"x != "none"x ] ; then
              SAVE_OS_CONFIG="${__CUR_DEBUG_SWITCH#*=}"
              if [ "${SAVE_OS_CONFIG}"x = ""x -o "${SAVE_OS_CONFIG}"x = "save_os_config"x  ] ; then
                SAVE_OS_CONFIG="/var/tmp/$( prtdiag | grep "System Configuration" | cut -f2- -d ":" | tr "()/: "  "_____" )_$( uname -n ).$$.tar"
              fi
            else
              SAVE_OS_CONFIG=""
            fi
            ;;

        "fn_to_stderr" )
            __FUNCTION_INIT=' eval __settraps; printf "Now in the function \"${__FUNCTION}\"; ; the parameter are \"$*\" (sec: $SECONDS): \n" >&2 '

            __FUNCTION_EXIT="eval echo \"Now leaving the function \"\${__FUNCTION}\"; THISRC is \"\${THISRC}\" (sec: \$SECONDS) \" >&2  "
            ;;

        "fn_to_tty" )
            __FUNCTION_INIT=' eval __settraps; printf "Now in the function \"${__FUNCTION}\"; ; the parameter are \"$*\" (sec: $SECONDS): \n" >/dev/tty '

            __FUNCTION_EXIT="eval echo \"Now leaving the function \"\${__FUNCTION}\"; THISRC is \"\${THISRC}\" (sec: \$SECONDS) \" >/dev/tty "
            ;;

        "fn_to_handle9" )
            echo 2>/dev/null >&9 || die 233 "Can not write to handle 9"
            __FUNCTION_INIT=' eval __settraps; printf "Now in the function \"${__FUNCTION}\"; ; the parameter are \"$*\" (sec: $SECONDS): \n" >&9 '

            __FUNCTION_EXIT="eval echo \"Now leaving the function \"\${__FUNCTION}\"; THISRC is \"\${THISRC}\" (sec: \$SECONDS) \" >&9 "
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

  if [ ${__LOG_DEBUG_MESSAGES} != ${__TRUE} ] ; then
    rm "${__DEBUG_LOGFILE}" 2>/dev/null 1>/dev/null
    __DEBUG_LOGFILE=""
  else
    echo 2>/dev/null >>"${__DEBUG_LOGFILE}" || \
      die 237 "Can not write to the debug log file \"${__DEBUG_LOGFILE}\" "
  fi

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
    LogMsg "The script Shebank is \"${__SHEBANG}\""
    LogMsg "The shell in the Shebank is \"${__SCRIPT_SHELL}\" "
    LogMsg "The shell options in the Shebank are \"${__SCRIPT_SHELL_OPTIONS}\" "
    LogMsg "----------------------------------------------------------------------"
    LogMsg ""
  fi

# -----------------------------------------------------------------------------
# add your main code here

  AWK=nawk
  ( $AWK '{}' ) < /dev/null 2>&0 || AWK=awk
  
# defined Log routines:
#
# LogMsg
# LogInfo
# LogWarning
# LogError
# LogOnly
# LogIfNotVerbose
# PrintDotToSTDOUT

  LogMsg "-"

  export PATH="${PATH}/usr/bin:/usr/sbin:"

#  ifconfig -a | grep vnet 2>/dev/null 1>/dev/null && die 3 "This script does not work in Guest LDoms."

# check parameter
#
  if [ "${SAVE_OS_CONFIG}"x != ""x ] ; then
    SaveConfigFileForLaterUse "${SAVE_OS_CONFIG}"

    die 0
  fi


  PARAMETER_OKAY=${__TRUE}

  if [ "${PRTCONF_FILE}"x != ""x ] ; then
    LogMsg "Using the output of \"prtconf -vpPD\" from the file \"${PRTCONF_FILE}\"."

    if [ ! -r "${PRTCONF_FILE}" ] ; then
      LogError "The file \"${PRTCONF_FILE}\" does not exist or is not readable"
      PARAMETER_OKAY=${__FALSE}
    fi
  fi

  if [ "${ETC_PATH_TO_INST_FILE}"x != ""x ] ; then
    LogMsg "Using the path_to_inst file \"${ETC_PATH_TO_INST_FILE}\"."

    if [ ! -r "${ETC_PATH_TO_INST_FILE}" ] ; then
      LogError "The file \"${ETC_PATH_TO_INST_FILE}\" does not exist or is not readable"
      PARAMETER_OKAY=${__FALSE}
    fi
  fi

  if [ "${FCINFO_HBA_PORT_FILE}"x != ""x ] ; then
    LogMsg "Using the output of \"fcinfo hba-port\" from the file \"${FCINFO_HBA_PORT_FILE}\"."

    if [ ! -r "${FCINFO_HBA_PORT_FILE}" ] ; then
      LogError "The file \"${FCINFO_HBA_PORT_FILE}\" does not exist or is not readable"
      PARAMETER_OKAY=${__FALSE}
    fi
  fi

  if [ "${PRTDIAG_FILE}"x != ""x ] ; then
    LogMsg "Using the output of \"prtdiag -v\" from the file \"${PRTDIAG_FILE}\"."

    if [ ! -r "${PRTDIAG_FILE}" ] ; then
      LogError "The file \"${PRTDIAG_FILE}\" does not exist or is not readable"
      PARAMETER_OKAY=${__FALSE}
    fi
  fi

  if [ ${PARAMETER_OKAY} != ${__TRUE} ] ; then
    die 15 "One or more errors found"
  fi

  if [ ${ONLY_LIST_ALL_SLOTS} != ${__TRUE} ] ; then
    UserIsRoot
    if [ $? -ne ${__TRUE} ] ; then
      LogWarning "You should execute this script with root rights to get all functionality"
    fi 
  fi
  

  if [ "${__MACHINE_CLASS}"x = "i86pc"x ] ; then
    LogMsg "Retrieving the infos from \"prtconf\" ..."
    Getx86PCISlotUsage "${PRTCONF_FILE}" "${ETC_PATH_TO_INST_FILE}" || LogWarning "Error retrieving the PCI slot information"
  else
    LogMsg "Retrieving the infos from \"prtdiag\" ..."
    GetSPARCPCISlotUsage "${PRTDIAG_FILE}" "${ETC_PATH_TO_INST_FILE}" || LogWarning "Error retrieving the PCI slot information"
  fi

  if [ ${ONLY_LIST_ALL_SLOTS} = ${__TRUE} ] ; then
    if [ "${__MACHINE_CLASS}"x = "i86pc"x ] ; then
      LogMsg "x86 Slot Usage"
      LogMsg "-" "${Getx86PCISlotUsage_OUTPUT}"
      LogMsg "-"
    else
      LogMsg "SPARC Slot Usage"
      LogMsg "-" "${GetSPARCPCISlotUsage_OUTPUT}"
      LogMsg "-"
    fi
    die 0
  fi
  

  FC_PORTS_FOUND=0

  LogMsg "Retrieving the infos from \"fcinfo hba-port\" ..."

  if [ "${FCINFO_HBA_PORT_FILE}"x != ""x ] ; then
    FCINFO_HBA_PORT="$( cat "${FCINFO_HBA_PORT_FILE}" )"
    THISRC=$?
  else
    FCINFO_HBA_PORT="$( fcinfo hba-port 2>&1 )"
    THISRC=$?
  fi

  if [ ${THISRC} -ne 0 ] ; then
    LogError  "Error ${THISRC} calling \"fcinfo hba-port\""
    LogMsg  "-" "${FCINFO_HBA_PORT}"
    die 5 "Errors found."
  fi

  [ "${FCINFO_HBA_PORT}"x = ""x -o  "${FCINFO_HBA_PORT}"x = "No Adapters Found."x ] && die 7 "\"fcinfo hba-port\" found no adapter"

  CUR_FC_PORT=${FC_PORTS_FOUND}
  ADAPTER_ONLINE=""
  ADAPTER_OFFLINE=""
  NO_OF_ONLINE_ADAPTER=0
  NO_OF_OFFLINE_ADAPTER=0

  echo "${FCINFO_HBA_PORT}" | while read LINE ; do
    LINE=$( echo ${LINE} )
    if [[ ${LINE} == HBA\ Port\ WWN:\ * ]] ; then
      (( CUR_FC_PORT = CUR_FC_PORT + 1 ))
      LogInfo "Adapter found: \"${LINE}\" "
    fi
    FIELD="${LINE%%:*}"
    FIELD="${FIELD#*:}"

    VALUE="${LINE#*:}"
    VALUE="${VALUE#* }"

    LogInfo "  Field found: \"${FIELD}\" "
    LogInfo "  Value found: \"${VALUE}\" "

    case ${FIELD} in

# HBA Port WWN: 21000024ff46d35a
      "HBA Port WWN" )
        HBA_PORT_WWN[${CUR_FC_PORT}]="${VALUE}"
        ;;

#        OS Device Name: /dev/cfg/c4
      "OS Device Name"  )
        HBA_PORT_OS_DEVICE_NAME[${CUR_FC_PORT}]="${VALUE}"
        ;;

#        Manufacturer: QLogic Corp.
      "Manufacturer" )
        HBA_PORT_MANUCATURER[${CUR_FC_PORT}]="${VALUE}"
        ;;

#        Model: 371-4325-02
      "Model" )
        HBA_PORT_MODEL[${CUR_FC_PORT}]="${VALUE}"
        ;;

#        Firmware Version: 05.06.00
      "Firmware Version" )
        HBA_PORT_FIRMWARE[${CUR_FC_PORT}]="${VALUE}"
        ;;

#        FCode/BIOS Version:  BIOS: 2.02; fcode: 2.03; EFI: 2.01;
      "FCode/BIOS Version" )
        HBA_PORT_BIOS[${CUR_FC_PORT}]="${VALUE}"
        ;;

#        Serial Number: 0402T00-1231076424
      "Serial Number" )
        HBA_PORT_SERIAL[${CUR_FC_PORT}]="${VALUE}"
        ;;

#        Driver Name: qlc
      "Driver Name" )
        HBA_PORT_DRIVER_NAME[${CUR_FC_PORT}]="${VALUE}"
        ;;

#        Driver Version: 20110825-3.06
      "Driver Version" )
        HBA_PORT_DRIVER_VERSION[${CUR_FC_PORT}]="${VALUE}"
        ;;

#        Type: N-port
      "Type" )
        HBA_PORT_TYPE[${CUR_FC_PORT}]="${VALUE}"
        ;;

#        State: online
      "State" )
        HBA_PORT_STATE[${CUR_FC_PORT}]="${VALUE}"
        if [ "${HBA_PORT_STATE[${CUR_FC_PORT}]}"x = "online"x ] ; then
          ADAPTER_ONLINE="${ADAPTER_ONLINE} ${CUR_FC_PORT}"
          (( NO_OF_ONLINE_ADAPTER = NO_OF_ONLINE_ADAPTER + 1 ))
        else
          ADAPTER_OFFLINE="${ADAPTER_OFFLINE} ${CUR_FC_PORT}"
          (( NO_OF_OFFLINE_ADAPTER = NO_OF_OFFLINE_ADAPTER + 1 ))
        fi
        ;;

#        Supported Speeds: 2Gb 4Gb 8Gb
      "Supported Speeds" )
        HBA_PORT_SUPPORTED_SPEEDS[${CUR_FC_PORT}]="${VALUE}"
        ;;

#        Current Speed: 8Gb
      "Current Speed" )
        HBA_PORT_CURRENT_SPEED[${CUR_FC_PORT}]="${VALUE}"
        ;;

#        Node WWN: 20000024ff46d35b
      "Node WWN" )
        HBA_PORT_NODE_WWN[${CUR_FC_PORT}]="${VALUE}"
        ;;

    esac

  done
  FC_PORTS_FOUND=${CUR_FC_PORT}

  LogMsg "Retrieving the infos from \"cfgadm -la\" ..."
  CFGADM_FAILED=${__FALSE}

  CFGADM_OUTPUT="$( cfgadm -la )"
  THISRC=$?
  if [ ${THISRC} -ne 0 ] ; then
    LogWarning "Error ${THISRC} calling \"cfgadm -la\": "
    LogMsg  "-" "${CFGADM_OUTPUT}"
    CFGADM_VERBOSE_OUTPUT=""
  else
    LogMsg "Retrieving the infos from \"cfgadm -la -o show_FCP_dev\" ..."
    CFGADM_VERBOSE_OUTPUT="$( cfgadm -la -o show_FCP_dev )"
    THISRC=$?
    if [ ${THISRC} -ne 0 ] ; then
      LogWarning "Error ${THISRC} calling \"cfgadm -la -o show_FCP_dev\": "
      LogMsg  "-" "${CFGADM_VERBOSE_OUTPUT}"
    fi
  fi

  [ "${CFGADM_VERBOSE_OUTPUT}"x = ""x -o "${CFGADM_OUTPUT}"x = ""x ] && CFGADM_FAILED=${__TRUE}

  LogMsg "Retrieving the infos from /dev/cfg/c* and /etc/path_to_inst ..."

  CUR_FC_PORT=0
  HBA_PORT_DEV_LINK_LENGTH=0

  while [ ${CUR_FC_PORT} -lt ${FC_PORTS_FOUND} ] ; do
    (( CUR_FC_PORT = CUR_FC_PORT + 1 ))
    CUR_HBA_PORT_OS_DEVICE_NAME="${HBA_PORT_OS_DEVICE_NAME[${CUR_FC_PORT}]}"
    LogInfo "  Retrieving the infos for the addapter \"${CUR_HBA_PORT_OS_DEVICE_NAME}\" ..."

    CUR_HBA_PORT_DEV_LINK="$( ls -l "${CUR_HBA_PORT_OS_DEVICE_NAME}" )"

    TESTVAR="${CUR_HBA_PORT_DEV_LINK#*devices}"
    TESTVAR="${TESTVAR%/fp*}"
    HBA_PORT_DEV_LINK[${CUR_FC_PORT}]="${TESTVAR}"
    [ ${#HBA_PORT_DEV_LINK[${CUR_FC_PORT}]} -gt ${HBA_PORT_DEV_LINK_LENGTH} ] && \
      HBA_PORT_DEV_LINK_LENGTH=${#HBA_PORT_DEV_LINK[${CUR_FC_PORT}]}

    case ${TESTVAR} in
      *,[0-9] )
        HBA_PORT_PCI_SLOT_PORT[${CUR_FC_PORT}]="${TESTVAR##*,}"
        ;;

      * )
        HBA_PORT_PCI_SLOT_PORT[${CUR_FC_PORT}]="0"
        ;;
    esac

    set -- $( grep "\"${TESTVAR}\"" /etc/path_to_inst )
    eval HBA_QLC_NAME[${CUR_FC_PORT}]="${3}$2"
    set --

    CUR_ADAPTER_NAME="${CUR_HBA_PORT_OS_DEVICE_NAME##*/}"
    if [ ${CFGADM_FAILED} = ${__FALSE} ] ; then
      HBA_CFGADM_CONNECTED_WWNS[${CUR_FC_PORT}]="$( echo "${CFGADM_OUTPUT}" | grep "^${CUR_ADAPTER_NAME}:" | cut -f1 -d " " | cut -f3 -d ":" )"
      HBA_CFGADM_WWNS_WITH_ERRORS[${CUR_FC_PORT}]="$( echo "${CFGADM_OUTPUT}" | grep ^${CUR_ADAPTER_NAME}: | egrep "unavailable|unusable"  | cut -f1 -d " " )"
      HBA_CFGADM_VISIBLE_DISKS[${CUR_FC_PORT}]="$( echo "${CFGADM_VERBOSE_OUTPUT}" | grep ^${CUR_ADAPTER_NAME}:: | grep disk | wc -l | tr -d " " )"
      HBA_CFGADM_VISIBLE_TAPES[${CUR_FC_PORT}]="$( echo "${CFGADM_VERBOSE_OUTPUT}" | grep ^${CUR_ADAPTER_NAME}:: | grep tape | wc -l  | tr -d " ")"
      HBA_CFGADM_VISIBLE_MISC[${CUR_FC_PORT}]="$( echo "${CFGADM_VERBOSE_OUTPUT}" | grep ^${CUR_ADAPTER_NAME}:: | egrep -v "tape|disk|unavailable" | wc -l | tr -d " " )"
      HBA_CFGADM_VISIBLE_FC_FABRIC[${CUR_FC_PORT}]="$( echo "${CFGADM_VERBOSE_OUTPUT}" | grep "^${CUR_ADAPTER_NAME} " | grep "fc-fabric" | wc -l  | tr -d " ")"
    else
      HBA_CFGADM_CONNECTED_WWNS[${CUR_FC_PORT}]="n/a"
      HBA_CFGADM_WWNS_WITH_ERRORS[${CUR_FC_PORT}]="n/a"
      HBA_CFGADM_VISIBLE_DISKS[${CUR_FC_PORT}]="n/a"
      HBA_CFGADM_VISIBLE_TAPES[${CUR_FC_PORT}]="n/a"
      HBA_CFGADM_VISIBLE_MISC[${CUR_FC_PORT}]="n/a"
      HBA_CFGADM_VISIBLE_FC_FABRIC[${CUR_FC_PORT}]="n/a"
    fi

    if [ ${PRINT_DEBUG_MSGS} = ${__TRUE} ] ; then
      LogDebugMsg
      LogDebugMsg "  Array element ${CUR_FC_PORT}:"
      LogDebugMsg "   HBA_PORT_DEV_LINK[${CUR_FC_PORT}]=\"${HBA_PORT_DEV_LINK[${CUR_FC_PORT}]}\" "
      LogDebugMsg "   HBA_PORT_PCI_SLOT_PORT[${CUR_FC_PORT}]=\"${HBA_PORT_PCI_SLOT_PORT[${CUR_FC_PORT}]}\" "
      LogDebugMsg "   HBA_QLC_NAME[${CUR_FC_PORT}]=\"${HBA_QLC_NAME[${CUR_FC_PORT}]}\" "

      LogDebugMsg "   HBA_CFGADM_CONNECTED_WWNS[${CUR_FC_PORT}]=\"${HBA_CFGADM_CONNECTED_WWNS[${CUR_FC_PORT}]}\" "
      LogDebugMsg "   HBA_CFGADM_WWNS_WITH_ERRORS[${CUR_FC_PORT}]=\"${HBA_CFGADM_WWNS_WITH_ERRORS[${CUR_FC_PORT}]}\" "
      LogDebugMsg "   HBA_CFGADM_VISIBLE_DISKS[${CUR_FC_PORT}]=\"${HBA_CFGADM_VISIBLE_DISKS[${CUR_FC_PORT}]}\" "
      LogDebugMsg "   HBA_CFGADM_VISIBLE_TAPES[${CUR_FC_PORT}]=\"${HBA_CFGADM_VISIBLE_TAPES[${CUR_FC_PORT}]}\" "
      LogDebugMsg "   HBA_CFGADM_VISIBLE_MISC[${CUR_FC_PORT}]=\"${HBA_CFGADM_VISIBLE_MISC[${CUR_FC_PORT}]}\" "
      LogDebugMsg "   HBA_CFGADM_VISIBLE_FC_FABRIC[${CUR_FC_PORT}]=\"${HBA_CFGADM_VISIBLE_FC_FABRIC[${CUR_FC_PORT}]}\" "
    fi
  done

  if [ "${SAN_DEVICE_ZONE_OUTPUTFILE}"x != ""x ] ; then
    GLOBAL_FCINFO_OUTPUTFILE="/tmp/fcinfo.$$.out"
    __LIST_OF_TMP_FILES="${__LIST_OF_TMP_FILES} ${GLOBAL_FCINFO_OUTPUTFILE} "
  fi

  CUR_FC_PORT=0

  while [ ${CUR_FC_PORT} -lt ${FC_PORTS_FOUND} ] ; do
    (( CUR_FC_PORT = CUR_FC_PORT + 1 ))
    CUR_HBA_PORT_WWN="${HBA_PORT_WWN[${CUR_FC_PORT}]}"

    LogMsg "Retrieving the infos from \"fcinfo remote-port -p ${CUR_HBA_PORT_WWN} -s\" ..."
    FCINFO_REMOTE_PORT_OUTPUT="$( fcinfo remote-port -p ${CUR_HBA_PORT_WWN} -s 2>&1 )"
    THISRC=$?

    if [ "${SAN_DEVICE_ZONE_OUTPUTFILE}"x != ""x -a ${THISRC} -eq 0 ] ; then
      CUR_OUTPUTFILE="/tmp/fcinfo_${CUR_FC_PORT}.$$.out"
      LogInfo "Creating the temporary file \"${CUR_OUTPUTFILE}\" ..."

      FCINFO_OUTPUT_FILE[${CUR_FC_PORT}]="${CUR_OUTPUTFILE}"
      echo "${FCINFO_REMOTE_PORT_OUTPUT}" >"${CUR_OUTPUTFILE}"
      __LIST_OF_TMP_FILES="${__LIST_OF_TMP_FILES} ${CUR_OUTPUTFILE} "

      echo "${FCINFO_REMOTE_PORT_OUTPUT}" >>"${GLOBAL_FCINFO_OUTPUTFILE}"
    fi

    if [ ${THISRC} -ne 0 ] ; then
      LogWarning "Error ${THISRC} calling \"fcinfo remote-port -p ${CUR_HBA_PORT_WWN} -s\": "
      LogMsg  "-" "${FCINFO_REMOTE_PORT_OUTPUT}"
      HBA_FCINFO_VISIBLE_LUNS[${CUR_FC_PORT}]="?"
    else
      HBA_FCINFO_VISIBLE_LUNS[${CUR_FC_PORT}]="$( echo "${FCINFO_REMOTE_PORT_OUTPUT}" | grep LUN | wc -l )"
      HBA_FCINFO_VISIBLE_LUNS_UNIQUE[${CUR_FC_PORT}]="$( echo "${FCINFO_REMOTE_PORT_OUTPUT}" | grep "OS Device Name:" | grep -v "Unknown" | sort | uniq | wc -l | tr -d " " )"
    fi

  done

  if [ "${__MACHINE_CLASS}"x = "sun4v"x -o "${__MACHINE_CLASS}"x = "sun4u"x  ] ; then
    LogMsg "Retrieving the infos from \"prtdiag -v\" ..."

    if [ "${PRTDIAG_FILE}"x != ""x ] ; then
      PRTDIAG_OUT="$( cat "${PRTDIAG_FILE}" )"
      THISRC=$?
    else
      PRTDIAG_OUT="$( prtdiag -v )"
      THISRC=$?
    fi

    if [ ${THISRC} -ne 0 ] ; then
      LogErrorMsg "Error ${THISRC} calling \"prtdiag -v\": "
      LogMsg  "${PRTDIAG_OUT}"
      die 5 "Errors found."
    fi

    LAST_LINE=""
    echo "${PRTDIAG_OUT}" | while read LINE ; do
      LINE=$( echo ${LINE} )
      if [[ ${LINE} == /pci@* ]] ; then

        LogInfo "prtdiag Line found: \"${LINE}\""

        CUR_FC_PORT=0
        while [ ${CUR_FC_PORT} -lt ${FC_PORTS_FOUND} ] ; do
          (( CUR_FC_PORT = CUR_FC_PORT + 1 ))
          CUR_HBA_PROT_DEV_LINK="${HBA_PORT_DEV_LINK[${CUR_FC_PORT}]}"

          LogInfo "HBA Dev Line: \"${CUR_HBA_PROT_DEV_LINK}\""

          if [ "${LINE}" = "${HBA_PORT_DEV_LINK[${CUR_FC_PORT}]}" ] ; then
            LogInfo "Line matches!"

            set -- ${LAST_LINE}
            case ${__MACHINE_CLASS} in
              sun4u )
                HBA_PORT_PCI_SLOT[${CUR_FC_PORT}]="${2}$3"
                HBA_PORT_PCI_SUNW_NAME[${CUR_FC_PORT}]="${14}"
                ;;
               sun4v )
                HBA_PORT_PCI_SLOT[${CUR_FC_PORT}]="${1##*/}"
                HBA_PORT_PCI_SUNW_NAME[${CUR_FC_PORT}]="${4}"
                ;;
            esac
            set --
            break
          fi
        done
      fi
      LAST_LINE="${LINE}"
    done
  else
    [ "${Getx86PCISlotUsage_OUTPUT}"x = ""x ] && \
      LogWarning "Can not get the PCI slot information on x86 machines"
  fi

  LogMsg "-"
  LogMsg "${CUR_FC_PORT} adapter port(s) found; ${NO_OF_ONLINE_ADAPTER} port(s) are online, ${NO_OF_OFFLINE_ADAPTER} port(s) are offline."
  LogMsg "-"

  (( HBA_PORT_DEV_LINK_LENGTH = HBA_PORT_DEV_LINK_LENGTH + 4 ))

  typeset -L15 P_HBA_PORT_PCI_SLOT_AND_PORT="PCI S/P"
  typeset -L${HBA_PORT_DEV_LINK_LENGTH} P_HBA_PORT_DEV_LINK="Device Path"
  typeset -L5  P_HBA_PORT_OS_DEVICE_NAME="Ctlr"
  typeset -L10 P_HBA_PORT_STATE="State"
  typeset -L24 P_HBA_PORT_WWN="Port WWN"
  typeset -L10  P_HBA_QLC_NAME="Name"
  #typeset -L10 P_HBA_PORT_PCI_SUNW_NAME="type"
  typeset -L11  P_HBA_FCINFO_VISIBLE_LUNS="# LUNs"
  typeset -L8  P_HBA_CFGADM_VISIBLE_DISKS="# Disks"
  typeset -L8  P_HBA_CFGADM_VISIBLE_TAPES="# Tapes"
  typeset -L10 P_HBA_CFGADM_VISIBLE_FABRICS="# fabrics"
  typeset -L8  P_HBA_CFGADM_VISIBLE_MISC="# misc"
  typeset      P_HBA_CFGADM_WWNS_WITH_ERRORS="SAN dev w/ errors"

  TITLE="${P_HBA_PORT_PCI_SLOT_AND_PORT}${P_HBA_PORT_DEV_LINK}${P_HBA_PORT_OS_DEVICE_NAME}${P_HBA_PORT_STATE}${P_HBA_PORT_WWN}${P_HBA_QLC_NAME}${P_HBA_FCINFO_VISIBLE_LUNS}${P_HBA_CFGADM_VISIBLE_DISKS}${P_HBA_CFGADM_VISIBLE_TAPES}${P_HBA_CFGADM_VISIBLE_FABRICS}${P_HBA_CFGADM_VISIBLE_MISC}${P_HBA_CFGADM_WWNS_WITH_ERRORS}"
  LogMsg "-" "${TITLE}"

  SLOT_USAGE_IS_WRONG=${__TRUE}
  PORTS_FOUND=""
  CUR_FC_PORT=0
  while [ ${CUR_FC_PORT} -lt ${FC_PORTS_FOUND} ] ; do
    (( CUR_FC_PORT = CUR_FC_PORT + 1 ))
#????    [[ " ${PORTS_FOUND} " == *\ ${THIS_ADAPTER}/${HBA_PORT_PCI_SLOT_PORT[${CUR_FC_PORT}]}\ * ]] && SLOT_USAGE_IS_WRONG=${__FALSE}
    PORTS_FOUND="${PORTS_FOUND} ${THIS_ADAPTER}/${HBA_PORT_PCI_SLOT_PORT[${CUR_FC_PORT}]}" 
  done

  CUR_FC_PORT=0
  while [ ${CUR_FC_PORT} -lt ${FC_PORTS_FOUND} ] ; do
    (( CUR_FC_PORT = CUR_FC_PORT + 1 ))

    eval X86_SLOT="\${ADAPTER_${HBA_QLC_NAME[${CUR_FC_PORT}]}}"
    if [ "${X86_SLOT}"x != ""x ] ; then
      THIS_ADAPTER="${X86_SLOT}"
    else
      THIS_ADAPTER="${HBA_PORT_PCI_SLOT[${CUR_FC_PORT}]}"
      [ "${THIS_ADAPTER}"x = ""x ] && THIS_ADAPTER="???"
    fi
    if [ ${SLOT_USAGE_IS_WRONG} = ${__FALSE} ] ; then
      P_HBA_PORT_PCI_SLOT_AND_PORT="???"
    else
      P_HBA_PORT_PCI_SLOT_AND_PORT="${THIS_ADAPTER}/${HBA_PORT_PCI_SLOT_PORT[${CUR_FC_PORT}]}"
    fi

    if [[ ${HBA_PORT_OS_DEVICE_NAME[${CUR_FC_PORT}]} = /devices/* ]] ; then
      P_HBA_PORT_OS_DEVICE_NAME="n/a"
    else
      P_HBA_PORT_OS_DEVICE_NAME="${HBA_PORT_OS_DEVICE_NAME[${CUR_FC_PORT}]##*/}"
    fi
    P_HBA_PORT_STATE="${HBA_PORT_STATE[${CUR_FC_PORT}]}"

#????    P_HBA_PORT_WWN="$( echo "${HBA_PORT_WWN[${CUR_FC_PORT}]}" |  sed -e :a -e 's/\(.*[0-9a-f]\)\([0-9a-f]\{2\}\)/\1:\2/;ta' )"
    P_HBA_PORT_WWN="${HBA_PORT_WWN[${CUR_FC_PORT}]}"

    P_HBA_QLC_NAME="${HBA_QLC_NAME[${CUR_FC_PORT}]}"
#    P_HBA_PORT_PCI_SUNW_NAME="${HBA_PORT_PCI_SUNW_NAME[${CUR_FC_PORT}]}"
    P_HBA_FCINFO_VISIBLE_LUNS="${HBA_FCINFO_VISIBLE_LUNS[${CUR_FC_PORT}]}/${HBA_FCINFO_VISIBLE_LUNS_UNIQUE[${CUR_FC_PORT}]}"
    P_HBA_CFGADM_VISIBLE_DISKS="${HBA_CFGADM_VISIBLE_DISKS[${CUR_FC_PORT}]}"
    P_HBA_CFGADM_VISIBLE_TAPES="${HBA_CFGADM_VISIBLE_TAPES[${CUR_FC_PORT}]}"
    P_HBA_CFGADM_VISIBLE_MISC="${HBA_CFGADM_VISIBLE_MISC[${CUR_FC_PORT}]}"
    P_HBA_CFGADM_VISIBLE_FABRICS="${HBA_CFGADM_VISIBLE_FC_FABRIC[${CUR_FC_PORT}]}"
    P_HBA_CFGADM_WWNS_WITH_ERRORS="${HBA_CFGADM_WWNS_WITH_ERRORS[${CUR_FC_PORT}]}"
    P_HBA_PORT_DEV_LINK="${HBA_PORT_DEV_LINK[${CUR_FC_PORT}]}"

    CUR_LINE="${P_HBA_PORT_PCI_SLOT_AND_PORT}${P_HBA_PORT_DEV_LINK}${P_HBA_PORT_OS_DEVICE_NAME}${P_HBA_PORT_STATE}${P_HBA_PORT_WWN}${P_HBA_QLC_NAME}${P_HBA_FCINFO_VISIBLE_LUNS}${P_HBA_CFGADM_VISIBLE_DISKS}${P_HBA_CFGADM_VISIBLE_TAPES}${P_HBA_CFGADM_VISIBLE_FABRICS}${P_HBA_CFGADM_VISIBLE_MISC}${P_HBA_CFGADM_WWNS_WITH_ERRORS}"
    LogMsg "-" "${CUR_LINE}"
  done

  if [ ${SLOT_USAGE_IS_WRONG} = ${__FALSE} ] ; then
    LogMsg "Note: Can not detect the slot / Solaris device relation on this kind of machine"
  fi

  if [ "${SAN_DEVICE_ZONE_OUTPUTFILE}"x != ""x ] ; then
    LogMsg "-"
    LogMsg "Writing the zoning for each SAN device to the file \"${SAN_DEVICE_ZONE_OUTPUTFILE}\" ..."

    if [ "${SAN_DEVICE_ZONE_OUTPUTFILE}"x != "console"x -a "${SAN_DEVICE_ZONE_OUTPUTFILE}"x != "STDOUT"x ] ; then
      touch "${SAN_DEVICE_ZONE_OUTPUTFILE}" || \
        die 44 "Can not write to the file \"${SAN_DEVICE_ZONE_OUTPUTFILE}\" "
    fi

    SAN_ZONING_OUTPUT=""

    DEVICE_LIST="$( grep "OS Device Name:" "${GLOBAL_FCINFO_OUTPUTFILE}" | awk '{ print $4 };' | sort | uniq )"

    typeset -L35 P_WWN="SAN Device"
    typeset -L10 P_DEV_TYPE="Type"
    typeset -L10 P_PORT=""
    CUR_TITLE="${P_WWN}${P_DEV_TYPE}"

    P_WWN="---"
    P_DEV_TYPE="---"
    CUR_TITLE2="${P_WWN}${P_DEV_TYPE}"

    CUR_FC_PORT=0
    while [ ${CUR_FC_PORT} -lt ${FC_PORTS_FOUND} ] ; do
      (( CUR_FC_PORT = CUR_FC_PORT + 1 ))

      eval X86_SLOT="\${ADAPTER_${HBA_QLC_NAME[${CUR_FC_PORT}]}"
      if [ "${X86_SLOT}"x != ""x ] ; then
        THIS_ADAPTER="${X86_SLOT}"
      else
        THIS_ADAPTER="${HBA_PORT_PCI_SLOT[${CUR_FC_PORT}]}"
      fi

      [ "${THIS_ADAPTER}"x = ""x ] && THIS_ADAPTER="???"
      P_PORT="${THIS_ADAPTER}/${HBA_PORT_PCI_SLOT_PORT[${CUR_FC_PORT}]}"
      CUR_TITLE="${CUR_TITLE}${P_PORT}"

      P_PORT="${HBA_QLC_NAME[${CUR_FC_PORT}]}"
      CUR_TITLE2="${CUR_TITLE2}${P_PORT}"
    done

    SAN_ZONING_OUTPUT="${SAN_ZONING_OUTPUT}
${CUR_TITLE}
${CUR_TITLE2}
"

    for CUR_OS_DEVICE in ${DEVICE_LIST} ; do

      CUR_WWN=""
      if [[ ${CUR_OS_DEVICE} == /dev/rdsk/* ]]  ;then
        CUR_WWN="${CUR_OS_DEVICE##*/c*t}"
        CUR_WWN="${CUR_WWN%d0s2}"
        P_DEV_TYPE="disk"
      elif [[ ${CUR_OS_DEVICE} == /devices/*/st@w* ]] ; then
        CUR_WWN="${CUR_OS_DEVICE#*st@w}"
        CUR_WWN="${CUR_WWN%,*}"
        P_DEV_TYPE="tape"
      else
        CUR_WWN="${CUR_OS_DEVICE}"
        P_DEV_TYPE="unknown"
      fi

      P_WWN="${CUR_WWN}"
      CUR_LINE="${P_WWN}${P_DEV_TYPE}"

      CUR_FC_PORT=0
      while [ ${CUR_FC_PORT} -lt ${FC_PORTS_FOUND} ] ; do
        (( CUR_FC_PORT = CUR_FC_PORT + 1 ))
        CUR_PCI_SLOT_AND_PORT="${THIS_ADAPTER}/${HBA_PORT_PCI_SLOT_PORT[${CUR_FC_PORT}]}"
        CUR_OUTPUTFILE="${FCINFO_OUTPUT_FILE[${CUR_FC_PORT}]}"
        P_PORT="$( grep ${CUR_WWN} ${CUR_OUTPUTFILE} | wc -l | tr -d " " )"
        CUR_LINE="${CUR_LINE}${P_PORT}"
      done

      SAN_ZONING_OUTPUT="${SAN_ZONING_OUTPUT}
${CUR_LINE}"

    done

    if [ "${SAN_DEVICE_ZONE_OUTPUTFILE}"x != "console"x -a "${SAN_DEVICE_ZONE_OUTPUTFILE}"x != "STDOUT"x ] ; then
      echo "${SAN_ZONING_OUTPUT}" >>"${SAN_DEVICE_ZONE_OUTPUTFILE}"
    else
      logMsg "-" "${SAN_ZONING_OUTPUT}"
    fi
  fi

  LogMsg "-"
  LDMD_STATE="$( svcs -o state -H svc:/ldoms/ldmd:default 2>/dev/null )"

  if [ "${LDMD_STATE}"x = "online"x ] ; then
    LDMD_DEVICE_LIST=""
    for i in $( ldm list | egrep -v "primary|^NAME" 2>/dev/null ) ; do
      for j in $( ldm list -o physio -p $i | egrep -v "^VERSION|^DOMAIN|^IO" | grep dev= | cut -f3 -d "|" | cut -f2 -d "=" ) ; do
      LDMD_DEVICE_LIST="${LDMD_DEVICE_LIST}
PCI Slot $j is assigned to the Guest LDom $i"
      done
    done

    if [ "${LDMD_DEVICE_LIST}"x != ""x ] ; then
      LogMsg "Some PCI Slots are assigned to Guest LDoms:"
      LogMsg "-"
      LogMsg "-" "${LDMD_DEVICE_LIST}"
      LogMsg "-"
      LogMsg "If the adapter in these slots are FiberChannel adapter please execute this script"
      LogMsg "in the Guest LDom to check the fiber channel connections."
      LogMsg "-"
    else
      LogMsg "All PCI Slots are assigned to the Primary LDom."
      LogMsg "-"
    fi
  fi

  if [ ${LIST_ALL_SLOTS} = ${__TRUE} ] ; then
    if [ "${GetSPARCPCISlotUsage_OUTPUT}"x != ""x ] ; then
      LogMsg "SPARC Slot Usage"
      LogMsg "-" "${GetSPARCPCISlotUsage_OUTPUT}"
      LogMsg "-"
    elif [ "${Getx86PCISlotUsage_OUTPUT}"x != ""x ] ; then
      LogMsg "x86 Slot Usage"
      LogMsg "-" "${Getx86PCISlotUsage_OUTPUT}"
      LogMsg "-"

      if [ ${SLOT_USAGE_IS_WRONG} = ${__FALSE} ] ; then
        LogMsg "Note: Can not detect the slot / Solaris device relation on this kind of machine"
        LogMsg "      The device asssignments in the table above are probably not correct!"
        LogMsg "-"
      fi

    else
      LogWarning "No slot information found."
    fi
  fi

  if [ ${__VERBOSE_MODE} = ${__TRUE} ] ; then
    if [ "${__LOGFILE}"x = ""x ] ; then
      LogWarning "Logging the environment requested but no logfile defined."
    else
      LogMsg "Writing the environment variables to the log file ..."
      echo "
#### environment variables at script end #### start #####

$( set )

#### environment variables at script end #### end #####
" >>"${__LOGFILE}"

#"
#"

    fi
  fi

# -----------------------------------------------------------------------------
#
  die ${__MAINRC}

# -----------------------------------------------------------------------------

exit 254

# -----------------------------------------------------------------------------
