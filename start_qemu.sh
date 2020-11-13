#!/usr/bin/ksh
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
# Copyright 2006 Bernd Schemmer  All rights reserved.
# Use is subject to license terms.

##
# -----------------------------------------------------------------------------
##
## start_qemu.sh - start qemu images
##
## Author: Bernd Schemmer (Bernd.Schemmer@gmx.de)
##
## Version: see variable ${__SCRIPT_VERSION} below
##          (see variable ${__SCRIPT_TEMPLATE_VERSION} for the template 
##           version used)
##
## Supported OS: Solaris 
##
##
## Description
## 
## Configuration file
##
## This script supports a configuration file called <scriptname>.conf.
## The configuration file is searched in the working directory,
## the home directory of the user execting this script and /etc
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
##
## History:
##   30.09.2006 v1.0.0 /bs
##     initial release
##
## scriptt History
## ---------------
##   1.22.0 08.06.2006 /bs
##     public release; starting history for scriptt.sh
##
##   1.22.1 12.06.2006 /bs
##      added true/false to CheckYNParameter and ConverToYesNo
## 
##   1.22.2. 21.06.2006 /bs
##      added the parameter -V
##      added the use of environemnt variables
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
##   1.22.10 21.09.2006 /bs
##      cleanup comments
##      the number of temporary files created automatically is now variable 
##        (see the variable __NO_OF_TEMPFILES)
##      added code to install the trap handler in all functions
##
##   
## __SCRIPT_VERSION - the version of your script 
##
typeset -r __SCRIPT_VERSION="v1.0.0.0"
##

## __SCRIPT_TEMPLATE_VERSION - version of the script template
##
typeset -r __SCRIPT_TEMPLATE_VERSION="1.22.10 20.09.2006"
##

## ----------------
##
## Predefined return codes:
##
##    1 - show usage and exit
##    2 - invalid parameter found
##
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
"

#
# binaries and scripts used in this script:
#
# basename cat cp cpio cut dd dirname expr find grep id ln ls prtdiag pwd rebboot rm sed tee touch tty umount uname who zonename
#
# /usr/bin/pfexec
# /usr/ucb/whoami
# /usr/openwin/bin/resize
#

# -----------------------------------------------------------------------------

# variables for the trap handler

__FUNCTION="main"

# alias to install the trap handler
#
alias __settrap='
  trap "GENERAL_SIGNAL_HANDLER  1    \$LINENO"  1
  trap "GENERAL_SIGNAL_HANDLER  2    \$LINENO"  2
  trap "GENERAL_SIGNAL_HANDLER  3    \$LINENO"  3
  trap "GENERAL_SIGNAL_HANDLER 15    \$LINENO" 15
#  trap "GENERAL_SIGNAL_HANDLER exit  \$LINENO" EXIT
'


## ##### general hints
##
## Do not use variable names beginning with __ (these are reserved for
## internal use)
##


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


# -----------------------------------------------------------------------------
# use --tee to automatically call the script and pipe all output to tee
#
__TEE_OUTPUT_FILE="/var/log/$( basename $0 ).tee.log"

if [ "$1"x = "-T"x -o "$1"x = "--tee"x ] ; then

# Note: If you need the parent PID save it here
#
   __PPID=$PPID ; export __PPID

  echo "Saving STDOUT and STDERR to \"${__TEE_OUTPUT_FILE}\" ..."
  shift
  exec $0 $@ 2>&1 | tee -a "${__TEE_OUTPUT_FILE}"
  exit $?
fi

[ "${__PPID}"x = ""x ] && __PPID=$PPID ; export __PPID

# -----------------------------------------------------------------------------
#
# change [ 0 = 1 ] to [ 0 = 0 ] if you want the script running with RBAC control
# (Solaris 10 and newer only!)
#
# Allow the use of RBAC to control who can access this script. Useful for
# administrators without root permissions
#

if [ 0 = 1 ] ; then
  if [ "$_" != "/usr/bin/pfexec" -a -x /usr/bin/pfexec ]; then
    /usr/bin/pfexec $0 $*
    exit $?
  fi
fi

# -----------------------------------------------------------------------------
## 
## ##### defined variables that may be changed
##

## __DEBUG_CODE - code executed at start of every sub routine
##   Note: Use always "__DEBUG_CODE="eval ..." if you want to use variables or aliase
##         Default debug code : install the trap handlers
##
  __DEBUG_CODE="eval __settrap"

##
## sample debug code:
## __DEBUG_CODE="  eval echo Entering the subroutine \$__FUNCTION ...  "
##
## Note: Use an include script for more complicate debug code, e.g.
## __DEBUG_CODE=" eval . /var/tmp/mydebugcode"
##

## __CONFIG_PARAMETER
##   The variable __CONFIG_PARAMETER contains the configuraton variables
##
## The defaults for these variables are defined here. You 
## can use a config file to overwrite the defaults. 
##
## Use the parameter -C to create a default configuration file
##
## Note: The config file is read and interpreted via ". configfile"  
##       therefor you can add also some code her
##
__CONFIG_PARAMETER='


# extension for backup files

DEFAULT_BACKUP_EXTENSION=".$$.backup"
  
## sample debug code:
## __DEBUG_CODE="  eval echo Entering the subroutine \$__FUNCTION ...  "

## Note: Use an include script for more complicate debug code, e.g.
## __DEBUG_CODE=" eval . /var/tmp/mydebugcode"
##

  DEFAULT_QEMU_VERSION="SUNWqemu_v02"
  
  TMP_DEFAULT_QEMU_LIBRARY_PATH_32BIT=""
  TMP_DEFAULT_QEMU_LIBRARY_PATH_64BIT=""
  TMP_DEFAULT_BIOS_DIR=""
  TMP_DEFAULT_KQEMU_KERNEL_MODE=${__FALSE}
  TMP_DEFAULT_KQEMU_USER_MODE=${__FALSE}
  
  case ${DEFAULT_QEMU_VERSION} in
  
    072 )
      TMP_DEFAULT_QEMU_BINARY_32BIT="/opt/csw/bin/qemu"
      TMP_DEFAULT_QEMU_BINARY_64BIT="/opt/csw/bin/qemu"
      TMP_DEFAULT_LIBRARY_PATH_32BIT="/opt/csw/lib:/opt/sfw/lib"
      TMP_DEFAULT_LIBRARY_PATH_64BIT="/opt/csw/lib:/opt/sfw/lib"
      ;;

    081 )      
      TMP_DEFAULT_QEMU_BINARY_32BIT="/opt/tools/qemu/0.8.1/bin/qemu"
      TMP_DEFAULT_QEMU_BINARY_64BIT="/opt/tools/qemu/0.8.1/bin/qemu-system-x86_64"
      ;;
      
    082 )
      TMP_DEFAULT_QEMU_BINARY_32BIT="/opt/tools/qemu/0.8.2/qemu"
      TMP_DEFAULT_QEMU_BINARY_64BIT="/opt/tools/qemu/0.8.2/qemu-system-x86_64"
      ;;
      
    SUNWqemu_v01 )
      TMP_DEFAULT_QEMU_BINARY_32BIT="/opt/tools/qemu/SUNWqemu/32/bin/qemu"
      TMP_DEFAULT_QEMU_BINARY_64BIT="/opt/tools/qemu/SUNWqemu/64/bin/qemu-system-x86_64"
      TMP_DEFAULT_QEMU_LIBRARY_PATH_32BIT="/opt/tools/qemu/SUNWqemu/32/lib"
      TMP_DEFAULT_QEMU_LIBRARY_PATH_64BIT="/opt/tools/qemu/SUNWqemu/64/lib"
      TMP_DEFAULT_KQEMU_KERNEL_MODE=${__TRUE}
      TMP_DEFAULT_KQEMU_USER_MODE=${__TRUE}
      ;;
      
    SUNWqemu_v02 )
      TMP_DEFAULT_QEMU_BINARY_32BIT="/opt/SUNWqemu/bin/qemu"    
      TMP_DEFAULT_QEMU_BINARY_64BIT="/opt/SUNWqemu/bin/qemu-system-x86_64"   
      TMP_DEFAULT_KQEMU_KERNEL_MODE=${__TRUE}
      TMP_DEFAULT_KQEMU_USER_MODE=${__TRUE}
      ;;
      
    * ) die 230 "No qemu binary choosen"
        ;;
  esac
  	   
  if [ $( isainfo -b ) = 64 ] ; then
    DEFAULT_QEMU_BINARY="${TMP_DEFAULT_QEMU_BINARY_64BIT}"

## add. directory for LD_LIBRARY_PATH ; parameter -L
    DEFAULT_QEMU_LIBRARY_PATH="${TMP_DEFAULT_QEMU_LIBRARY_PATH_64BIT}"
  else
    DEFAULT_QEMU_BINARY="${TMP_DEFAULT_QEMU_BINARY_32BIT}"

## add. directory for LD_LIBRARY_PATH ; parameter -L
    DEFAULT_QEMU_LIBRARY_PATH="${TMP_DEFAULT_QEMU_LIBRARY_PATH_32BIT}"
  fi  

## use kqemu use kqemu for user code?
  DEFAULT_KQEMU_USER_MODE=${TMP_DEFAULT_KQEMU_USER_MODE}

## use kqemu use kqemu for kernel code?
  DEFAULT_KQEMU_KERNEL_MODE=${TMP_DEFAULT_KQEMU_KERNEL_MODE}
     
## directory with the bios images and keymaps ; parameter -B
  DEFAULT_QEMU_BIOS_DIR="${TMP_DEFAULT_BIOS_DIR}"

## monitor to stdio true/false; parameter -m
  DEFAULT_MONITOR_TO_STDIO=${__FALSE}
 
## basedirectory for harddisk images    
  HD_BASEDIR="/export/qemu/hdimg/"
  
## basedirectory for cdrom images
  CD_BASEDIR="/export/qemu/cdrom"
  
## basedirectory for VM images  
  VM_BASEDIR="/export/qemu/qemu_vm"
  
## parameter for qemu 
  DEFAULT_QEMU_PARAMETER=""

## default image
  DEFAULT_PC_IMAGE=""
  
## definitions for the various images


##   "start_belenix.sh")
##
  BELENIX_TITLE="Belenix ISO image"
  BELENIX_HDA_IMAGE="${HD_BASEDIR}/tempdata.hdd"
  BELENIX_HDB_IMAGE=""
  BELENIX_HDC_IMAGE=""
  BELENIX_HDD_IMAGE=""
  BELENIX_FDA_IMAGE=""
  BELENIX_FDB_IMAGE=""
  BELENIX_CDROM_IMAGE="${CD_BASEDIR}/belenix.iso"
#  BELENIX_CDROM_IMAGE="${CD_BASEDIR}/belenix0.4.4.iso"

  BELENIX_QEMU_BINARY="${QEMU_BINARY_072}"
  BELENIX_LIBRARY_PATH=""
  BELENIX_BIOS_DIR=""
  BELENIX_KQEMU_USER_MODE=""
  BELENIX_KQEMU_KERNEL_MODE=""
  
  BELENIX_LODAVM_IMAGE="${VM_BASEDIR}/belenix.vm"
  BELENIX_QEMU_PARAMETER="-boot d  -m 512"
  BELENIX_ADD_CMD=""
  export BELENIX_TITLE


##   "start_nexenta.sh")
##
  NEXENTA_TITLE="Nexenta ISO image"
  NEXENTA_HDA_IMAGE="${HD_BASEDIR}/nexenta.hdd"
  NEXENTA_HDB_IMAGE=""
  NEXENTA_HDC_IMAGE=""
  NEXENTA_HDD_IMAGE=""
  NEXENTA_FDA_IMAGE=""
  NEXENTA_FDB_IMAGE=""
  NEXENTA_CDROM_IMAGE="${CD_BASEDIR}/nexenta_install.iso"

#  NEXENTA_QEMU_BINARY="${QEMU_BINARY_082}"
#  NEXENTA_LIBRARY_PATH=""
#  NEXENTA_BIOS_DIR=""
#  NEXENTA_KQEMU_USER_MODE=""
#  NEXENTA_KQEMU_KERNEL_MODE=""

  NEXENTA_LODAVM_IMAGE="${VM_BASEDIR}/nexenta.vm"
  NEXENTA_QEMU_PARAMETER="-boot c  -m 512"
  NEXENTA_ADD_CMD=""
  export NEXENTA_TITLE


##   "start_nexenta_live.sh")
##
  NEXENTA_LIVE_TITLE="Nexenta Live CD"
  NEXENTA_LIVE_HDA_IMAGE="${HD_BASEDIR}/tempdata.hdd"
  NEXENTA_LIVE_HDB_IMAGE=""
  NEXENTA_LIVE_HDC_IMAGE=""
  NEXENTA_LIVE_HDD_IMAGE=""
  NEXENTA_LIVE_FDA_IMAGE=""
  NEXENTA_LIVE_FDB_IMAGE=""
  NEXENTA_LIVE_CDROM_IMAGE="${CD_BASEDIR}/nexenta_livecd.iso"

#  NEXENTA_LIVE_QEMU_BINARY="${QEMU_BINARY_082}"
#  NEXENTA_LIVE_LIBRARY_PATH=""
#  NEXENTA_LIVE_BIOS_DIR=""
#  NEXENTA_LIVE_KQEMU_USER_MODE=""
#  NEXENTA_LIVE_KQEMU_KERNEL_MODE=""

  NEXENTA_LIVE_LODAVM_IMAGE="${VM_BASEDIR}/nexenta.vm"
  NEXENTA_LIVE_QEMU_PARAMETER="-boot d  -m 512"
  NEXENTA_LIVE_ADD_CMD=""
  export NEXENTA_LIVE_TITLE
     
##   "start_schillix.sh" )
##
  SCHILLIX_TITLE="Schillix ISO image"
  SCHILLIX_HDA_IMAGE="${HD_BASEDIR}/tempdata.hdd"
  SCHILLIX_CDROM_IMAGE="${CD_BASEDIR}/schillix.iso"
  SCHILLIX_LODAVM_IMAGE="${VM_BASEDIR}/schillix.vm"
  SCHILLIX_QEMU_PARAMETER="-boot d  -m 256"
  SCHILLIX_ADD_CMD=""

#  SCHILLIX_QEMU_BINARY="${QEMU_BINARY_082}"
#  SCHILLIX_LIBRARY_PATH=""
#  SCHILLIX_BIOS_DIR=""
#  SCHILLIX_KQEMU_USER_MODE=""
#  SCHILLIX_KQEMU_KERNEL_MODE=""


  export SCHILLIX_TITLE

##   "start_dsl.sh" )
##
  DSL_TITLE="DSL ISO image"
  DSL_HDA_IMAGE="${HD_BASEDIR}/dsl.hdd"
  DSL_CDROM_IMAGE="${CD_BASEDIR}/dsl.iso"
  DSL_LODAVM_IMAGE="${VM_BASEDIR}/dsl.vm"
  DSL_QEMU_PARAMETER="-boot d  -m 256"
  DSL_ADD_CMD=""

  DSL_QEMU_BINARY="${QEMU_BINARY_082}"
#  DSL_LIBRARY_PATH=""
#  DSL_BIOS_DIR=""
#  DSL_KQEMU_USER_MODE=""
#  DSL_KQEMU_KERNEL_MODE=""

  export DSL_TITLE

##  "start_zaurusdev.sh" )
##
  ZAURUSDEV_TITLE="Zaurus Development"
  ZAURUSDEV_HDA_IMAGE="${HD_BASEDIR}/sharp_zsdk_dsl_disk.img"
#  ZAURUSDEV_CDROM_IMAGE="${CD_BASEDIR}/knoppix.iso"
  ZAURUSDEV_QEMU_PARAMETER="-boot c  -m 256"
  ZAURUSDEV_LODAVM_IMAGE="${VM_BASEDIR}/zaurusdev.vm"
  ZAURUSDEV_ADD_CMD="firefox  http://kopsisengineering.com/kopsis/SharpZaurusSdkDsl"

#  ZAURUSDEV_QEMU_BINARY="${QEMU_BINARY_082}"
#  ZAURUSDEV_LIBRARY_PATH=""
#  ZAURUSDEV_BIOS_DIR=""
#  ZAURUSDEV_KQEMU_USER_MODE=""
#  ZAURUSDEV_KQEMU_KERNEL_MODE=""
  
  export ZAURUSDEV_TITLE

##  "start_knoppix.sh" )
##
  KNOPPIX_TITLE="Knoppix ISO image"
  KNOPPIX_HDA_IMAGE="${HD_BASEDIR}/knoppix.hdd"
  KNOPPIX_CDROM_IMAGE="${CD_BASEDIR}/knoppix.iso"
  KNOPPIX_QEMU_PARAMETER="-boot d  -m 256"
  KNOPPIX_LODAVM_IMAGE="${VM_BASEDIR}/knoppix.vm"
  KNOPPIX_ADD_CMD=""

#  KNOPPIX_QEMU_BINARY="${QEMU_BINARY_082}"
#  KNOPPIX_LIBRARY_PATH=""
#  KNOPPIX_BIOS_DIR=""
#  KNOPPIX_KQEMU_USER_MODE=""
#  KNOPPIX_KQEMU_KERNEL_MODE=""
  
  export KNOPPIX_TITLE

##  "start_knoppix40.sh" )
##
  KNOPPIX40_TITLE="Knoppix ISO image"
#  KNOPPIX40_HDA_IMAGE="${HD_BASEDIR}/knoppix.hdd"
  KNOPPIX40_CDROM_IMAGE="${CD_BASEDIR}/knoppix40.iso"
  KNOPPIX40_QEMU_PARAMETER="-boot d -m 256"
  KNOPPIX40_LODAVM_IMAGE="${VM_BASEDIR}/knoppix40.vm"
  KNOPPIX40_ADD_CMD=""

#  KNOPPIX40_QEMU_BINARY="${QEMU_BINARY_082}"
#  KNOPPIX40_LIBRARY_PATH=""
#  KNOPPIX40_BIOS_DIR=""
#  KNOPPIX40_KQEMU_USER_MODE=""
#  KNOPPIX40_KQEMU_KERNEL_MODE=""
  
  export KNOPPIX40_TITLE

##  "start_ubuntu_live.sh" )
##
  UBUNTU_LIVE_TITLE="Ubuntu ISO image"
  UBUNTU_LIVE_HDA_IMAGE="${HD_BASEDIR}/ubuntu.hdd"
  UBUNTU_LIVE_CDROM_IMAGE="${CD_BASEDIR}/ubuntu_live.iso"
  UBUNTU_LIVE_QEMU_PARAMETER="-boot d -m 1024"
  UBUNTU_LIVE_LODAVM_IMAGE="${VM_BASEDIR}/ubuntu_live.vm"
  UBUNTU_LIVE_ADD_CMD=""

#  UBUNTU_LIVE_QEMU_BINARY="${QEMU_BINARY_082}"
#  UBUNTU_LIVE_LIBRARY_PATH=""
#  UBUNTU_LIVE_BIOS_DIR=""
#  UBUNTU_LIVE_KQEMU_USER_MODE=""
#  UBUNTU_LIVE_KQEMU_KERNEL_MODE=""

  export UBUNTU_LIVE_TITLE
       
##  "start_ubuntu.sh" )
##
  UBUNTU_TITLE="Ubuntu harddisk image"
  UBUNTU_HDA_IMAGE="${HD_BASEDIR}/Ubuntu.vmdk"
#  UBUNTU_CDROM_IMAGE="${CD_BASEDIR}/ubuntu.iso"
  UBUNTU_QEMU_PARAMETER="-boot c  -m 256"
  UBUNTU_LODAVM_IMAGE="${VM_BASEDIR}/ubuntu.vm"
  UBUNTU_ADD_CMD=""

#  UBUNTU_QEMU_BINARY="${QEMU_BINARY_082}"
#  UBUNTU_LIBRARY_PATH=""
#  UBUNTU_BIOS_DIR=""
#  UBUNTU_KQEMU_USER_MODE=""
#  UBUNTU_KQEMU_KERNEL_MODE=""

  export UBUNTU_TITLE

##  "start_win2k.sh" )
##
  WIN2K_TITLE="Windows 2000 harddisk image"
  WIN2K_HDA_IMAGE="${HD_BASEDIR}/win2k_sp4_qemu7ok.hdd"
  WIN2K_CDROM_IMAGE="${CD_BASEDIR}/ForSolx86.iso"
  WIN2K_QEMU_PARAMETER="-snapshot  -m 512 -boot c"
  WIN2K_LODAVM_IMAGE="${VM_BASEDIR}/win2k.vm"
  WIN2K_ADD_CMD=""

#  WIN2K_QEMU_BINARY="${QEMU_BINARY_082}"
#  WIN2K_LIBRARY_PATH=""
#  WIN2K_BIOS_DIR=""
#  WIN2K_KQEMU_USER_MODE=""
#  WIN2K_KQEMU_KERNEL_MODE=""

  export WIN2K_TITLE

##  "start_win2k_office.sh")
##
  WIN2K_OFFICE_TITLE="Windows 2000 & Office harddisk image"
  WIN2K_OFFICE_HDA_IMAGE="${HD_BASEDIR}/win2k_sp4_qemu7_office.hdd"
  WIN2K_OFFICE_CDROM_IMAGE="${CD_BASEDIR}/ForSolx86.iso"
  WIN2K_OFFICE_QEMU_PARAMETER="-snapshot  -m 512 -boot c "
  WIN2K_OFFICE_LODAVM_IMAGE="${VM_BASEDIR}/win2koffice.vm"
  WIN2K_ADD_CMD=""

#  WIN2K_OFFICE_QEMU_BINARY="${QEMU_BINARY_082}"
#  WIN2K_OFFICE_LIBRARY_PATH=""
#  WIN2K_OFFICE_BIOS_DIR=""
#  WIN2K_OFFICE_KQEMU_USER_MODE=""
#  WIN2K_OFFICE_KQEMU_KERNEL_MODE=""

  export WIN2K_OFFICE_TITLE


##  "start_winnt.sh" )
##
  WINNT_TITLE="Windows NT harddisk image"
  WINNT_HDA_IMAGE="${HD_BASEDIR}/winNT_sp6.hdd"
  WINNT_CDROM_IMAGE="${CD_BASEDIR}/ForSolx86.iso"
  WINNT_QEMU_PARAMETER="-snapshot  -m 256 -boot c "
  WINNT_LODAVM_IMAGE="${VM_BASEDIR}/winnt.vm"
  WINNT_ADD_CMD=""

#  WINNT_QEMU_BINARY="${QEMU_BINARY_082}"
#  WINNT_LIBRARY_PATH=""
#  WINNT_BIOS_DIR=""
#  WINNT_KQEMU_USER_MODE=""
#  WINNT_KQEMU_KERNEL_MODE=""

  export WINNT_TITLE

# only change the following variables if you know what you are doing #

# no further internal variables defined yet
'
# end of config parameters


## __SHORT_DESC - short description (for help texts, etc)
##   Change to your need
##
typeset -r __SHORT_DESC="script to start qemu virtual machine"

## __LONG_USAGE_HELP - Additional help if the script is called with 
##   the parameter "-v -h"
##
##   Note: To use variables in the help text use the variable name without
##         an escape character, eg. ${OS_VERSION}
##
__LONG_USAGE_HELP='
      -B    - set the directory for bios images and keymaps; current value: ${QEMU_BIOS_DIR}
              long format: --biosdir
      -L    - add path for LD_LIBRARY_PATH; current value: ${QEMU_LIBRARY_PATH}
              long format: --librarypath
      -x    - set the qemu binary to use; current value: ${QEMU_BINARY}
              long format: --qemubinary
      -m|+m - monitor to STDOUT or not; current value: $( ConvertToYesNo "${MONITOR_TO_STDIO}")
              long format: --monitorSTDOUT / ++monitorSTDOUT
      -k|+k - user kqemu in kernel mode or not; current value $( ConvertToYesNo "${KQEMU_KERNEL_MODE}" )
              long format: --kernel-kqemu / ++kernel-kqemu
      -u|+u - user kqemu in user mode or not; current value $( ConvertToYesNo "${KQEMU_USER_MODE}" )
              long format: --kqemu / ++kqemu
      -i    - PC image to start; current value: ${PC_IMAGE}
              long format: --pcimage

      parameter_for_qemu - additional parameter for qemu; current value: "${QEMU_ADD_PARAMETER}"
 
'

## __SHORT_USAGE_HELP - Additional help if the script is called with the parameter "-h"
##
##   Note: To use variables in the help text use the variable name without an escape
##         character, eg. ${OS_VERSION}
##
__SHORT_USAGE_HELP='
		    [-B qemu_bios_directory] [-x qemu_binary] [-m|+m] [-k|+k] [-u|+u] [-i pc_image]
		    [-L librarypath] [-- parameter_for_qemu]
'


## __MUST_BE_ROOT - run script only by root (def.: false)
##   set to ${__TRUE} for scripts that must be executed by root only
##
__MUST_BE_ROOT=${__FALSE}

## __REQUIRED_USERID - required userid to run this script (def.: none)
##   use blanks to separate multiple userids
##   e.g. "oracle dba sysdba"
##   "" = no special userid required
##
__REQUIRED_USERID=""

## __ONLY_ONCE - run script only once at a time (def.: false)
##   set to ${__TRUE} for scripts that can not run more than one instance at 
##   the same time
##
__ONLY_ONCE=${__FALSE}

## __REQUIRED_OS_VERSION - required OS version for the script (def.: none)
##   minimum OS version necessary, e.g. 5.10
##   "" = no special version necessary
##
__REQUIRED_OS_VERSION=""

## __REQUIRED_MACHINE_PLATFORM - required machine platform for the script (def.: none)
##   required machine platform (uname -i) , e.g "i86pc"; use blanks to separate 
##   the machine types if more than one entry, e.g "Sun Fire 3800 i86pc"
##   "" = no special machine type necessary
##
__REQUIRED_MACHINE_PLATFORM=""

## __REQUIRED_MACHINE_CLASS - required machine class for the script (def.: none)
##   required machine class (uname -m) , e.g "i86pc" ; use blanks to separate  
##   the machine classes if more than one entry, e.g "sun4u i86pc"
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
typeset -i __VERBOSE_LEVEL=${__VERBOSE_LEVEL:=0}

## __RT_VERBOSE_LEVEL - level of -v for runtime messages (def.: 1)
##
##   e.g. 1 = -v -v is necessary to print info messages of the runtime system
##        2 = -v -v -v is necessary to print info messages of the runtime system
##
typeset -i __RT_VERBOSE_LEVEL=${__RT_VERBOSE_LEVEL:=1}

## __QUIET_MODE - do not print messages to STDOUT (def.: false)
##   use the parameter -q/+q to change this variable
##
__QUIET_MODE=${__QUIET_MODE:=${__FALSE}}

## __VERBOSE_MODE - print verbose messages (def.: false)
##   use the parameter -v/+v to change this variable  
##
__VERBOSE_MODE=${__VERBOSE_MODE:=${__FALSE}}

## __NO_TIME_STAMPS - Do not use time stamps in the messages (def.: false)
##
__NO_TIME_STAMPS=${__NO_TIME_STAMPS:=${__FALSE}}

## __NO_HEADERS - Do not print headers and footers (def.: false)
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
__USE_COLORS=${__USE_COLORS:=${__FALSE}}

## __USER_BREAK_ALLOWED - CTRL-C aborts the script or not (def.: true)
##   (no parameter to change this variable)
##
__USER_BREAK_ALLOWED=${__USER_BREAK_ALLOWED:=${__TRUE}}

## __NOECHO - turn echo on while reading input from the user
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
__OVERWRITE_MODE=${__OVERWRITE_MODE:=${__FALSE}}

## __DEBUG_MODE - use single step mode for main (def.: false)
##   use the parameter -D/+D to change this variable
##
__DEBUG_MODE=${__FALSE}
__SCRIPT_ARRAY[0]=0


## __NO_OF_TEMPFILES
##   number of automatically created tempfiles that are deleted at program end
##   (def. 2)
##   Note: The variable names for the tempfiles are __TEMPFILE1, __TEMPFILE2, etc.
##
__NO_OF_TEMPFILES=2


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
##
__EXITROUTINES=""

## __REBOOT_REQUIRED - set to true to reboot automatically at 
##   script end (def.: false)
##
__REBOOT_REQUIRED=${__FALSE}

## __REBOOT_PARAMETER - parameter for the reboot command (def.: none)
##
__REBOOT_PARAMETER=""

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
##       0 no summarys, 
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
__DEBUG_HISTFILE="/tmp/ksh.history.$$"

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

## __OS_VERSION - Operating system version (e.g 5.8)
##
__OS_VERSION="$( uname -r )"

## __ZONENAME - name of the current zone if running in Solaris 10 or newer
## 
__ZONENAME="$( zonename 2>/dev/null )"

## __OS_RELEASE - Operating system release (e.g. Generic_112233-08)
##
__OS_RELEASE="$( uname -v )"

## __MACHINE_CLASS - Machine class (e.g sun4u)
##
__MACHINE_CLASS="$( uname -m )"

## __MACHINE_PLATFORM - machine platform (e.g. SUNW,Ultra-4)
##
__MACHINE_PLATFORM="$( uname -i )"

## __MACHINE_SUBTYPE - machine type (e.g  Sun Fire 3800)
##
__MACHINE_SUBTYPE=""
if [ -x /usr/platform/${__MACHINE_PLATFORM}/sbin/prtdiag ] ; then
  ( set -- $( /usr/platform/${__MACHINE_PLATFORM}/sbin/prtdiag | grep "System Configuration" ) ; shift 5; echo $* ) | read  __MACHINE_SUBTYPE
fi

## __MACHINE_ARC - machine architecture (e.g. sparc)
##
__MACHINE_ARC="$( uname -p )"

## __START_DIR - working directory when starting the script
##
__START_DIR="$( pwd )"

## __LOGFILE - fully qualified name of the logfile used
##   use the parameter -l to change the logfile
##
if [ -d /var/log ] ; then
  __DEF_LOGFILE="/var/tmp/${__SCRIPTNAME%.*}.LOG"
else
  __DEF_LOGFILE="/tmp/${__SCRIPTNAME%.*}.LOG"
fi

__LOGFILE="${__DEF_LOGFILE}"

## __GLOBAL_OUTPUT_REDIRECTION
##   status variable used by StartStop_LogAll_to_logfile
##
__GLOBAL_OUTPUT_REDIRECTION=""

     
# lock file (used if ${__ONLY_ONCE} is ${__TRUE})
# Note: This is only a symbolic link
#
__LOCKFILE="/tmp/${__SCRIPTNAME}.lock"
__LOCKFILE_CREATED=${__FALSE}

## __NO_OF_WARNINGS - No of warnings found
##
typeset -i __NO_OF_WARNINGS=0

## __LIST_OF_WARNINGS - List of warning messages
##
__LIST_OF_WARNINGS=""

## __NO_OF_ERRORS - No of errors found
##
typeset -i __NO_OF_ERRORS=0

## __LIST_OF_ERRORS - List of error messages
##
__LIST_OF_ERRORS=""

## __LOGON_USERID - ID of the user opening the session  
##
__LOGIN_USERID=$( set -- $( who am i ) ; echo $1 )
[ "${__LOGIN_USERID}" = "" ] && __LOGIN_USERID=${LOGNAME}

## __USERID - ID of the user executing this script (e.g. xtrnaw7)
##
__USERID=${__LOGIN_USERID}
[ -x /usr/ucb/whoami ] && __USERID=$( /usr/ucb/whoami )

## __RUNLEVEL - current runlevel
##
# __RUNLEVEL=$( set -- $( who -r )  ; echo $7 )
__RUNLEVEL=$( who -r  2>/dev/null | tr -s " " | cut -f8 -d " " )

# -----------------------------------------------------------------------------
# color variables

##
## Colorattributes:
## __COLOR_OFF, __COLOR_BOLD, __COLOR_NORMAL, - normal, __COLOR_UNDERLINE
## __COLOR_BLINK, __COLOR_REVERSE, __COLOR_INVISIBLE
##

__COLOR_OFF="\033[0;m"
__COLOR_BOLD="\033[1m"
__COLOR_NORMAL="\033[2m"
__COLOR_UNDERLINE="\033[4m"
__COLOR_BLINK="\033[5m"
__COLOR_REVERSE="\033[7m"
__COLOR_INVISIBLE="\033[8m"

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
ReadConfigFile() {
  typeset __FUNCTION="ReadConfigFile"; ${__DEBUG_CODE}

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
WriteConfigFile() {
  typeset __FUNCTION="WriteConfigFile" ; ${__DEBUG_CODE} 

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
NoOfStackElements() {
  typeset __FUNCTION="NoOfStackElements";  ${__DEBUG_CODE}

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
FlushStack() {
  typeset __FUNCTION="FlushStack";    ${__DEBUG_CODE}

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
push() {
  typeset __FUNCTION="push";    ${__DEBUG_CODE}

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
pop() {
  typeset __FUNCTION="pop";    ${__DEBUG_CODE}

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
push_and_set() {
  typeset __FUNCTION="push_and_set";    ${__DEBUG_CODE}

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
CheckYNParameter(){
  typeset __FUNCTION="CheckYNParameter";    ${__DEBUG_CODE}

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
ConvertToYesNo(){
  typeset __FUNCTION="ConvertToYesNo";    ${__DEBUG_CODE}

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
InvertSwitch(){
  typeset __FUNCTION="InvertSwitch";    ${__DEBUG_CODE}

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
CheckInputDevice(){
  typeset __FUNCTION="CheckInputDevice";    ${__DEBUG_CODE}

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
GetProgramDirectory() {
  typeset __FUNCTION="GetProgramDirectory";    ${__DEBUG_CODE}

  typeset PRG=""
  typeset RESULTVAR=$2
    
  if [ ! -L $1 ] ; then
    PRG=$( cd -P -- "$(dirname -- "$(command -v -- "$1")")" && pwd -P )
  else  
# resolve links - $1 may be a softlink
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
substr() {
  typeset __FUNCTION="substr";    ${__DEBUG_CODE}

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
replacestr() {
  typeset __FUNCTION="replacestr";    ${__DEBUG_CODE}

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
pos() {
  typeset __FUNCTION="pos";    ${__DEBUG_CODE}

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
lastpos() {
  typeset __FUNCTION="lastpos";    ${__DEBUG_CODE}

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
isNumber() {
  typeset __FUNCTION="isNumber";    ${__DEBUG_CODE}

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
ConvertToHex(){
  typeset __FUNCTION="ConvertToHex";    ${__DEBUG_CODE}

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
ConvertToOctal(){
  typeset __FUNCTION="ConvertToOctal";    ${__DEBUG_CODE}

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
ConvertToBinary(){
  typeset __FUNCTION="ConverToBinary";  ${__DEBUG_CODE}

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
toUppercase() {
  typeset __FUNCTION="toUppercase";    ${__DEBUG_CODE}

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
toLowercase() {
  typeset __FUNCTION="toLowercase";    ${__DEBUG_CODE}

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
StartStop_LogAll_to_logfile() {
  typeset __FUNCTION="StartStop_LogAll_to_logfile";    ${__DEBUG_CODE}

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
executeCommand() {
  typeset __FUNCTION="executeCommand";    ${__DEBUG_CODE}

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
executeCommandAndLog() {
  typeset __FUNCTION="executeCommandAndLog";    ${__DEBUG_CODE}

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
executeCommandAndLogSTDERR() {
  typeset __FUNCTION="executeCommandAndLogSTDERR";    ${__DEBUG_CODE}

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
UserIsRoot() {
  typeset __FUNCTION="UserIsRoot";    ${__DEBUG_CODE}

  [ $( id | sed 's/uid=\([0-9]*\)(.*/\1/' ) = 0 ] && return ${__TRUE} || return ${__FALSE}
#) dummy comment for the syntax highlighting to work correct
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
  typeset __FUNCTION="UserIs";    ${__DEBUG_CODE}

  typeset THISRC=3
  typeset USERID=""
  
  if [ "$1"x != ""x ] ; then
    THISRC=2
    USERID=$( grep "^$1:" /etc/passwd | cut -d: -f3 )
    if [ "${USERID}"x != ""x ] ; then
      UID=`id | sed 's/uid=\([0-9]*\)(.*/\1/'`
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
GetCurrentUID() {
  typeset __FUNCTION="GetCurrentUID";    ${__DEBUG_CODE}

  return  `id | sed 's/uid=\([0-9]*\)(.*/\1/'`
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
GetUserName() {
  typeset __FUNCTION="GetUserName";    ${__DEBUG_CODE}

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
GetUID() {
  typeset __FUNCTION="GetUID";    ${__DEBUG_CODE}

  [ "$1"x != ""x ] &&  __USER_ID=$( grep "^$1:" /etc/passwd | cut -d: -f3 ) || __USER_ID=""
  
  return 0
}


# ======================================
 
## --------------------------------------
## LogMsg
##
## print a message to STDOUT and write it also to the logfile
##
## usage: LogMsg message
##
## returns: 0
##
## Notes: Use - your message to suppress the date stamp
##        Use "-" to print a complete blank line
##
LogMsg() {
  typeset __FUNCTION="LogMsg";    ${__DEBUG_CODE}

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
LogOnly() {
  typeset __FUNCTION="LogOnly";    ${__DEBUG_CODE}

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
LogInfo() {
  typeset __FUNCTION="LogInfo";    ${__DEBUG_CODE}

#  [ ${__VERBOSE_MODE} -eq ${__TRUE} ] && LogMsg "INFO: $*"

  typeset THISLEVEL=0
  
  if [ ${__VERBOSE_MODE} -eq ${__TRUE} ] ; then
    if [ $# -gt 1 ] ; then
      isNumber $1 
      if [ $? -eq ${__TRUE} ] ; then
        THISLEVEL=$1
        shift
      fi
    fi      
    [ ${__VERBOSE_LEVEL} -gt ${THISLEVEL} ]  && LogMsg "INFO: $*" >&2
  fi  
  return 0
  }

# internal sub routine for info messages
#
#
LogRuntimeInfo() {
  typeset __FUNCTION="LogRuntimeInfo";    ${__DEBUG_CODE}
  LogInfo "${__RT_VERBOSE_LEVEL}" "$*"
  return 0
}

# internal sub routine for header messages
#
#
LogHeader() {
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
LogWarning() {
  typeset __FUNCTION="LogWarning";    ${__DEBUG_CODE}

  LogMsg "WARNING: $*" >&2
  (( __NO_OF_WARNINGS = __NO_OF_WARNINGS +1 ))
  __LIST_OF_WARNINGS="${__LIST_OF_WARNINGS}
WARNING: $*"  
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
LogError() {
  typeset __FUNCTION="LogError";    ${__DEBUG_CODE}

  LogMsg "ERROR: $*" >&2

  (( __NO_OF_ERRORS=__NO_OF_ERRORS + 1 ))  
  __LIST_OF_ERRORS="${__LIST_OF_ERRORS}
ERROR: $*"  
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
BackupFileIfNecessary() {
  typeset __FUNCTION="BackupFileIfNecessary";    ${__DEBUG_CODE}

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
CopyDirectory() {
  typeset __FUNCTION="CopyDirectory";    ${__DEBUG_CODE}

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
AskUser() {
  typeset __FUNCTION="AskUser";    ${__DEBUG_CODE}

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

           "*" )  THISRC=${__FALSE} ;;

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
GetKeystroke () {
  typeset __FUNCTION="GetKeystroke";    ${__DEBUG_CODE}

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
RebootIfNecessary() {
  typeset __FUNCTION="RebootIfNecessary";    ${__DEBUG_CODE}

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
die() {
  typeset __FUNCTION="die";    ${__DEBUG_CODE}

  typeset THISRC=$1
  shift
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
includeScript() {
  typeset __FUNCTION="includeScript";    ${__DEBUG_CODE}

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

# ======================================

## 
## ##### defined internal sub routines (do NOT use; these routines are called 
##       by the runtime system!)
##

# --------------------------------------
## CreateLockFile
#
# Create the lock file (which is really a symbolic link) if possible
#
# usage: CreateLockFile
#
# returns: 0 - lock created
#          1 - lock already exist or erro creating the lock
#
# Note: Use a symbolic link because this is always a atomic operation
#
CreateLockFile() {
  typeset __FUNCTION="CreateLockFile";    ${__DEBUG_CODE}

  typeset LN_RC=""

  ln -s  "$0" "${__LOCKFILE}" 2>/dev/null
  LN_RC=$?
      
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
RemoveLockFile() {
  typeset __FUNCTION="RemoveLockFile";    ${__DEBUG_CODE}

  [ ! -L "${__LOCKFILE}" ] && return 1
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
CreateTemporaryFiles() {
  typeset __FUNCTION="CreateTemporaryFiles";    ${__DEBUG_CODE}

  typeset CURFILE=
  typeset i=1

  __TEMPFILE_CREATED=${__TRUE}

  LogRuntimeInfo "Creating the temporary files  ..."

  while [ ${i} -le ${__NO_OF_TEMPFILES} ]  ; do   
    eval __TEMPFILE${i}="/tmp/${__SCRIPTNAME}.$$.TEMP${i}"
    eval CURFILE="\$__TEMPFILE${i}"

    LogRuntimeInfo "Creating the temporary file \"${CURFILE}\"; the variable is \"\${TEMPFILE${i}}" 

    echo >"${CURFILE}" || return $?
    
    eval __LIST_OF_TMP_FILES=\"${__LIST_OF_TMP_FILES} \${__TEMPFILE${i}}\"
    (( i = i +1 ))
  done

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
##
cleanup() {
  typeset __FUNCTION="cleanup";    ${__DEBUG_CODE}

  typeset EXIT_ROUTINE=
  typeset OLDPWD="$( pwd )"

  cd /tmp

# reset tty settings if necessary
  if [ "${__STTY_SETTINGS}"x != ""x ] ; then
   stty ${__STTY_SETTINGS}
   __STTY_SETTINGS=""
  fi
  
# call the defined exit routines
  if [ "${__EXITROUTINES}"x !=  ""x ] ; then
    LogRuntimeInfo "Executing the exit routines \"${__EXITROUTINES}\" ..."
    for EXIT_ROUTINE in ${__EXITROUTINES} ; do
      LogRuntimeInfo "Now calling the exit routine \"${EXIT_ROUTINE}\" ..."
      eval ${EXIT_ROUTINE}
    done
  fi

# remove temporary files
  for CURENTRY in ${__LIST_OF_TMP_FILES} ; do
    LogRuntimeInfo "Removing the file \"${CURENTRY}\" ..."
    if [ -f "${CURENTRY}" ] ; then
      rm "${CURENTRY}" 
      [ $? -ne 0 ] && LogWarning "Error removing the file \"${CURENTRY}\" "
    fi
  done
 
# remove temporary mounts
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
  for CURENTRY in ${__LIST_OF_TMP_DIRS} ; do
    LogRuntimeInfo "Removing the directory \"${CURENTRY}\" ..."
    if [ -d "${CURENTRY}" ] ; then
      rm -r "${CURENTRY}" 2>/dev/null
      [ $? -ne 0 ] && LogWarning "Error removing the directory \"${CURENTRY}\" "
    fi
  done

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
## usage: called automatically (parameter $1 is the signal number)
##
## returns: -
##
GENERAL_SIGNAL_HANDLER() {
  typeset INTERRUPTED_FUNCTION="${__FUNCTION}"
  typeset __FUNCTION="GENERAL_SIGNAL_HANDLER";    ${__DEBUG_CODE}
  typeset __LINENO=$2

  LogMsg "Current function is: ${INTERRUPTED_FUNCTION}"
       
  [ "${__INCLUDE_SCRIPT_RUNNING}"x != ""x ] && LogMsg "Trap occured inside of the include script \"${__INCLUDE_SCRIPT_RUNNING}\" "
  
  LogRuntimeInfo "Signal $1 received: Line: ${__LINENO} in function: ${INTERRUPTED_FUNCTION}"
  
  case $1 in 

    1 )
        LogWarning "HUP signal received"

        InvertSwitch __VERBOSE_MODE
        LogMsg "Switching verbose mode to $( ConvertToYesNo ${__VERBOSE_MODE} )"
        ;;

    2 )
        if [ ${__USER_BREAK_ALLOWED} -eq ${__TRUE} ] ; then
          die 252 "Script aborted by the user via signal BREAK (CTRL-C)" 
        else
          LogRuntimeInfo "Break signal (CTRL-C) received and ignored (Break is disabled)"
        fi
        ;;

    3 )
        die 251 "QUIT signal received" 
        ;;

   15 )
        die 253 "Script aborted by the external signal TERM" 
        ;;

   "ERR" )
        LogMsg "A command ended with an error"
        ;;

   "exit" | 0 )
        if [ "${__EXIT_VIA_DIE}"x != "${__TRUE}"x ] ; then
          LogError "exit signal received."
          LogWarning "You should use the function \"die\" to end the program"
        fi    
        return
        ;;
       
    * ) die 254 "Unknown signal catched: $1"
        ;;

  esac
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
  typeset __FUNCTION="DebugHandler";    ${__DEBUG_CODE}

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
  [ -x /usr/openwin/bin/resize ] && eval $( /usr/openwin/bin/resize ) 
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
#  eval "typeset -L${j} __SRCLINE_VAR"  
  eval "typeset -L${COLUMNS} __SRCLINE_VAR"
  
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
  print "${__COLOR_OFF}"
  
# read the user input
#
  __LINE_VAR="*** DEBUG: \$\$ is ${__THIS_PID}; \$? is ${__LAST_RC}; \$! is ${__LAST_BG_RC}"
  print -u 2 "${__DEBUG_MSG_COLOR}${__LINE_VAR}"
  __LINE_VAR="*** DEBUG: Enter a command to execute or <enter> to execute the next command:"
  print -u 2 "${__DEBUG_MSG_COLOR}${__LINE_VAR}"

  while [ 1 = 1 ] ; do
    print -u 2 -n  "${__DEBUG_MSG_COLOR}DEBUG>>> "
    read -s __USERINPUT __USERPARMS __USERVALUE __USERVALUE2
  
    case ${__USERINPUT} in 

      "help" | "?" ) __LINE_VAR="*** DEBUG:Known commands"
           print -u 2 "${__DEBUG_MSG_COLOR}${__LINE_VAR}"
cat 1>&2 <<EOT

  help                         - print this text
  trace count               - execute count lines
  trace off                   - turn single mode off
  trace at lineNo           - suspend single step until line linNo
  trace not lineNumber   - suspend single step for lineNumber statements
  show lineNo [count]    - show count (def.: 10) lines after line lineNo
  exit [returncode]        - exit the program with RC returnCode (def.: 1)
  <return>                   - execute next statement (single step)
  everything else          - execute the command 

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

              isNumber "${__USERVALUE}" 2>/dev/null
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

              isNumber "${__USERVALUE}" 2>/dev/null
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
              isNumber "${__USERPARMS}" 2>/dev/null
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

           isNumber "${__USERPARMS}" 2>/dev/null
           if [ $? -ne 0 ] ; then
             __LINE_VAR="*** DEBUG: \"${__USERPARMS}\" is not a number"
             print -u 2 "${__DEBUG_MSG_COLOR}${__LINE_VAR}"
             continue
           fi         

           if [ "${__USERPARMS}" -lt 1 ] ; then
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
             isNumber "${__USERVALUE}" 2>/dev/null
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
InitScript() {    
  typeset __FUNCTION="InitScript";    ${__DEBUG_CODE}

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
SetEnvironment() {
  typeset __FUNCTION="SetEnvironment";    ${__DEBUG_CODE}
 
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

  LogRuntimeInfo "Parameter before getopt processing are: \"${THIS_PARAMETER}\" "
  LogRuntimeInfo "Not processed parameter after getopt processing are: \"${NOT_PROCESSED_PARAMETER}\" "

  if [ "${__REQUIRED_OS_VERSION}"x != ""x ] ; then

    LogRuntimeInfo "Curent OS version is \"${__OS_VERSION}\"; required OS version is \"${__REQUIRED_OS_VERSION}\""
    
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
      die 245 "This script can not run on this platform; necessary platforms are \"${__REQUIRED_MACHINE_PLATFORM}\""
  fi

  if [ "${__REQUIRED_MACHINE_CLASS}"x != ""x ] ; then
    pos " ${__MACHINE_CLASS} " " ${__REQUIRED_MACHINE_CLASS} " && \
      die 244 "This script can not run on this machine class; necessary machine classes are \"${__REQUIRED_MACHINE_CLASS}\""
  fi

  if [ "${__REQUIRED_MACHINE_ARC}"x != ""x ] ; then
    pos " ${__MACHINE_ARC} " " ${__REQUIRED_MACHINE_ARC} " && \
      die 243 "This script can not run on this machine architecture; necessary machine classes are \"${__REQUIRED_MACHINE_ARC}\""
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
      cat >&2  <<EOF

  ERROR:

  Either another instance of this script is already running 
  or the last execution of this script crashes.
  In the first case wait until the other instance ends; 
  in the second case delete the lock file 
  
      ${__LOCKFILE} 

  manually and restart the script.

EOF

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
CheckParameterCount(){
  typeset __CALLED_BY="${__FUNCTION}"
   
  typeset __FUNCTION="CheckParameterCount";    ${__DEBUG_CODE}

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
ShowShortUsage() {
  typeset __FUNCTION="ShowShortUsage";    ${__DEBUG_CODE}

  eval "__SHORT_USAGE_HELP=\"${__SHORT_USAGE_HELP}\""

cat <<EOT
  ${__SCRIPTNAME} ${__SCRIPT_VERSION} - ${__SHORT_DESC}

  Usage: ${__SCRIPTNAME} [-T] [-v|+v] [-q|+q] [-h] [-l logfile|+l] [-y|+y] [-n|+n] 
                    [-D|+D] [-a|+a] [-O|+O] [-f|+f] [-C] [-H] [-S n] [-V] 
${__SHORT_USAGE_HELP}
  
EOT


  while read CURLINE ; do
     echo "    ${CURLINE##*TITLE=} (${CURLINE%%_TITLE=*})"  
  done <<EOT
$( env | grep "TITLE=" )
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
ShowUsage() {
  typeset __FUNCTION="ShowUsage";    ${__DEBUG_CODE}

  eval "__LONG_USAGE_HELP=\"${__LONG_USAGE_HELP}\""

  ShowShortUsage
cat <<EOT

 Note: Use -{switch} or --{longswitch} to turn an option on; 
       use +{switch} or ++{longswitch} to turn an option off

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
              Long format: --no / ++no
      -D|+D - run main in single step mode (and turn colors on) 
              Long format: --debug / ++debug
      -a|+a - turn colors on/off; current value: $( ConvertToYesNo "${__USE_COLORS}" )
              Long format: --color / ++color
      -O|+O - overwrite existing files or not; current value: $( ConvertToYesNo "${__OVERWRITE_MODE}" )
              Long format: --overwrite / ++overwrite
      -f|+f - force; do it anyway
              Long format: --force / ++force 
       -C   - write a default config file in the current directory and exit
              Long format: --writeconfigfile
      -S n  - print error/warning summaries: 
              n = 0 no summarys, 1 = print error msgs,
              2 = print warning msgs, 3 = print error and warning mgs
              Current value: ${__PRINT_SUMMARIES}
              Long format: --summaries
      -H    - write extended usage to STDERR and exit
              Long format: --doc
      -V    - write version number to STDOUT and exit
              Long format: --version
      -T    - append STDOUT and STDERR to the file "${__TEE_OUTPUT_FILE}"
              Note: This parameter must be the FIRST parameter if used!
              Long format: --tee
${__LONG_USAGE_HELP}

Used environment variables:
$( echo "${__USED_ENVIRONMENT_VARIABLES}" | tr "#" " " )

EOT

  return 0      
}

# -----------------------------------------------------------------------------


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
YourRoutine(){
  typeset __FUNCTION="YourRoutine";    ${__DEBUG_CODE}

# init the return code
  THISRC=${__INVALID_USAGE}

# check the parameter count
  CheckParameterCount 0 "$@" || die 240 "Internal error detected"
  
  if [ $# -eq 0 ] ; then
    THISRC=${__FALSE}

# add code here

  fi

  die 0 "test exit"
  
  return ${THISRC}
}

## --------------------------------------
## SetImageVariables
##
## set the variables for an image
##
## usage: SetImageVariables 
##
## returns:  ${__TRUE} - ok
##           ${__FALSE} - error
##          
##
SetImageVariables(){
  typeset __FUNCTION="SetImageVariables";    ${__DEBUG_CODE}
     
  THISRC=${__TRUE}
       
  if [ "${PC_IMAGE}"x = ""x ] ; then
    TEMPVAR="${__SCRIPTNAME#start_*}"
    PC_IMAGE="${TEMPVAR%%.sh}"
    [  "${PC_IMAGE}"x = ""x ] && die 10 "I don't know which PC image to start"
  fi

  grep "${PC_IMAGE}_TITLE="  $0 >/dev/null
  [ $? -ne 0 ] && die 10 "The PC image \"${PC_IMAGE}\" is not known by this script"

  eval PC_IMAGE_TITLE="\${${PC_IMAGE}_TITLE}"
  [  "${PC_IMAGE_TITLE}"x = ""x ] && die 10 "The PC image \"${PC_IMAGE}\" is not known by this script"
   
  eval HDA_IMAGE="\${${PC_IMAGE}_HDA_IMAGE}"
  eval HDB_IMAGE="\${${PC_IMAGE}_HDB_IMAGE}"
  eval HDC_IMAGE="\${${PC_IMAGE}_HDC_IMAGE}"
  eval HDD_IMAGE="\${${PC_IMAGE}_HDD_IMAGE}"

  eval FDA_IMAGE="\${${PC_IMAGE}_FDA_IMAGE}"
  eval FDB_IMAGE="\${${PC_IMAGE}_FDB_IMAGE}"

  eval CDROM_IMAGE="\${${PC_IMAGE}_CDROM_IMAGE}"
  eval QEMU_PARAMETER="\${${PC_IMAGE}_QEMU_PARAMETER}"

  eval LODAVM_IMAGE="\${${PC_IMAGE}_LOADVM_IMAGE}"
  eval ADD_CMD="\${${PC_IMAGE}_ADD_CMD}"

  eval THIS_QEMU_BINARY="\${${PC_IMAGE}_QEMU_BINARY}"

  if [ "${THIS_QEMU_BINARY}"x != ""x -a "${QEMU_BINARY_PARAMETER_FOUND}"x != "${__TRUE}"x ] ; then
    QEMU_BINARY="${THIS_QEMU_BINARY}"
  fi

  eval THIS_QEMU_BIOS_DIR="\${${PC_IMAGE}_QEMU_BIOS_DIR}"

  if [ "${THIS_QEMU_BIOS_DIR}"x != ""x -a "${QEMU_BIOS_DIR_PARAMETER_FOUND}"x != "${__TRUE}"x ] ; then
    QEMU_BIOS_DIR="${THIS_QEMU_BIOS_DIR}"
  fi

  eval THIS_QEMU_LIBRARY_PATH="\${${PC_IMAGE}_QEMU_LIBRARY_PATH}"

  if [ "${THIS_QEMU_LIBRARY_PATH}"x != ""x -a "${QEMU_LIBRARY_PATH_PARAMETER_FOUND}"x != "${__TRUE}"x ] ; then
    QEMU_LIBRARY_PATH="${THIS_QEMU_LIBRARY_PATH}"
  fi

  eval THIS_KQEMU_KERNEL_MODE="\${${PC_IMAGE}_KQEMU_KERNEL_MODE}"

  if [ "${THIS_KQEMU_KERNEL_MODE}"x != ""x -a "${KQEMU_KERNEL_MODE_PARAMETER_FOUND}"x != "${__TRUE}"x ] ; then
    KQEMU_KERNEL_MODE="${THIS_KQEMU_KERNEL_MODE}"
  fi

  eval THIS_KQEMU_USER_MODE="\${${PC_IMAGE}_KQEMU_USER_MODE}"

  if [ "${THIS_KQEMU_USER_MODE}"x != ""x -a "${KQEMU_USER_MODE_PARAMETER_FOUND}"x != "${__TRUE}"x ] ; then
    KQEMU_USER_MODE="${THIS_KQEMU_USER_MODE}"
  fi
   
  return ${THISRC}
}

# -----------------------------------------------------------------------------
# main:
#
 
# install trap handler
  __settrap

  InitScript


# init variables with the defaults
#
# format var=${DEFAULT_var}
#
  typeset -u  PC_IMAGE=""

# to process all variables beginning with DEFAULT_ use 

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
#
#  __EXITROUTINES="${__EXITROUTINES} "    


# variables used by getops:
#    OPTIND = index of the current argument
#    OPTARG = current function character
#

  INVALID_PARAMETER_FOUND=${__FALSE}

  __PRINT_USAGE=${__FALSE}
  CUR_SWITCH=""
  OPTARG=""
  
#
  while getopts ":y(yes)n(no)v(verbose)q(quiet)h(help)H(doc)D(debug)f(force)l:(logfile)a(color)O(overwrite)S:(summaries)C(writeconfigfile)V(version)T(tee)L:(librarypath)B:(biosdir)x:(qemubinary)m:(monitorSTDOOUT)i:(pcimage)k(kernel-kqemu)u(kqemu)" CUR_SWITCH  ; do
   
# for debugging only
    if [ 0 = 1 ] ; then 
      echo "CUR_SWITCH is $CUR_SWITCH"
      echo "OPTIND = $OPTIND"
      echo "OPTARG = $OPTARG"
      echo "\$* is \"$*\" "
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

       "T" ) : # parameter already processed 
             ;;
       
       "H" ) 

echo " -----------------------------------------------------------------------------------------------------" >&2
echo "                         ${__SCRIPTNAME} ${__SCRIPT_TEMPLATE_VERSION} ">&2
echo "                                Documentation" >&2
echo " -----------------------------------------------------------------------------------------------------" >&2

             grep "^##" "$0" | cut -c3-100 1>&2 ; die 0 ;;
                  

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

                * )  LogError "Unknown value for -S found found: \"${OPTARG}\""
                      INVALID_PARAMETER_FOUND=${__TRUE}
                      ;;
              esac
              ;;


# add additional parameter here


        "B" ) QEMU_BIOS_DIR="${OPTARG:=${DEFAULT_QEMU_BIOS_DIR}}" 
	      QEMU_BIOS_DIR_PARAMETER_FOUND=${__TRUE}
	      ;;

        "L" ) QEMU_LIBRARY_PATH="${OPTARG:=${DEFAULT_QEMU_LIBRARY_PATH}}" 
	      QEMU_QEMU_LIBRARY_PATH_PARAMETER_FOUND=${__TRUE}
	      ;;

	"x" ) QEMU_BINARY="${OPTARG:=${DEFAULT_QEMU_BINARY}}"
	      QEMU_BINARY_PARAMETER_FOUND=${__TRUE}
	      ;;

        "i" ) PC_IMAGE="${OPTARG:=${DEFAULT_PC_IMAGE}}" 
	      PARAMETER_I_FOUND=${__TRUE}
	      ;;

        "k" ) KQEMU_KERNEL_MODE=${__TRUE} 
	      KQEMU_KERNEL_MODE_PARAMETER_FOUND=${__TRUE}
	      ;;
	
       "+k" ) KQEMU_KERNEL_MODE=${__FALSE}
	      KQEMU_KERNEL_MODE_PARAMETER_FOUND=${__TRUE}
	      ;;

        "u" ) KQEMU_USER_MODE=${__TRUE} 
	      KQEMU_USER_MODE_PARAMETER_FOUND=${__TRUE}
	      ;;
	
       "+u" ) KQEMU_USER_MODE=${__FALSE} 
	      KQEMU_USER_MODE_PARAMETER_FOUND=${__TRUE}
	      ;;
       
        "m" ) MONITOR_TO_STDIO=${__TRUE} ;;

       "+m" ) MONITOR_TO_STDIO=${__FALSE} ;;

     
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
      SetImageVariables
      ShowUsage 
      __VERBOSE_MODE=${__FALSE}
    else
      ShowShortUsage 
      LogMsg "Use \"-v -h\" or \"+h\" for a long help text"
    fi
    die 1 ;   
  fi

  shift $(( OPTIND - 1 ))

  NOT_PROCESSED_PARAMETER="$*"
  [ $# -ne 0 ] && QEMU_ADD_PARAMETER="$*"

  LogRuntimeInfo "Not processed parameter: \"${NOT_PROCESSED_PARAMETER}\""
  
   
#
# set INVALID_PARAMETER_FOUND to ${__TRUE} if the script
# should abort due to an invalid parameter 
#
# [ "${NOT_PROCESSED_PARAMETER}"x != ""x ] && INVALID_PARAMETER_FOUND=${__TRUE}
# 
#  if [ "${NOT_PROCESSED_PARAMETER}"x != ""x ] ; then
#    LogError "Unknown parameter: \"${NOT_PROCESSED_PARAMETER}\" "
#    INVALID_PARAMETER_FOUND=${__TRUE}
#  fi
#
#

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

    trap "__LAST_RC=\$?; __LAST_BG_RC=\$!; __LINENO=\$LINENO; DebugHandler"  DEBUG
:
    echo "INFO: Starting single step mode - works only for the main routine!"
  fi
 
# restore the language setting
  LANG=${__SAVE_LANG}
  export LANG

  SetImageVariables "${PC_IMAGE}" ${__TRUE}

  LogMsg "Starting the PC image \"${PC_IMAGE_TITLE}\" ..."
 
  LogMsg "Using the qemu binary \"${QEMU_BINARY}\" "
  [ ! -x "${QEMU_BINARY}" ] && die 5 "qemu binary \"${QEMU_BINARY}\" not found or not executable"
 
  QEMU_VERSION_STRING="$( ${QEMU_BINARY} -h | grep version )"
  LogMsg "${QEMU_VERSION_STRING}"

  if [ "${QEMU_BIOS_DIR}"x = ""x ] ; then
    TESTDIR="$( dirname ${QEMU_BINARY} )/bios"
    if [ -d "${TESTDIR}" ] ; then
      QEMU_BIOS_DIR="${TESTDIR}"
    else      
      TESTDIR="$( dirname ${QEMU_BINARY} )/../share/qemu"
      if [ -d "${TESTDIR}" ] ; then
        QEMU_BIOS_DIR="${TESTDIR}"
      else      
        die 4 "BIOS image directory \"${TESTDIR}\" not found"
      fi
    fi    
  fi
  	
  echo "${QEMU_VERSION_STRING}" | grep 0.7 >/dev/null
  if [ $? -eq 0 ] ; then
    QEMU_BASE_PARAMETER="${QEMU_BASE_PARAMETER} -k de -user-net"
  else
    QEMU_BASE_PARAMETER="${QEMU_BASE_PARAMETER} -net user -net nic"
  fi

  if [ "${QEMU_LIBRARY_PATH}"x != ""x ] ; then
    LogMsg "Adding \"${QEMU_LIBRARY_PATH}\" to the LD_LIBRARY_PATH ..."
    export LD_LIBRARY_PATH=${QEMU_LIBRARY_PATH}:${LD_LIBRARY_PATH}
  fi
  LogMsg "LD_LIBRARY_PATH is now \"${LD_LIBRARY_PATH}\""
  
  QEMU_BASE_PARAMETER="-L ${QEMU_BIOS_DIR}"
  
  QEMU_PARAMETER="${QEMU_BASE_PARAMETER} ${QEMU_PARAMETER}"
         
  LogInfo "hda image used is : ${HDA_IMAGE} "
  LogInfo "hdb image used is : ${HDB_IMAGE} "
  LogInfo "hdc image used is : ${HDC_IMAGE} "
  LogInfo "hdd image used is : ${HDD_IMAGE} "

  LogInfo "fda image used is : ${FDA_IMAGE} "
  LogInfo "fdb image used is : ${FDB_IMAGE} "

  LogInfo "cdrom image used is : ${CDROM} "
  LogInfo "qemu parameter are : ${QEMU_PARAMETER}"
  LogInfo "VM Image used is : ${LOADVM}"
  LogInfo "Add. commmand is \"${ADD_CMD}\" "  
  
  QEMU_PARAMETER="${QEMU_PARAMETER} ${QEMU_ADD_PARAMETER}"

  if [ ${MONITOR_TO_STDIO} = ${__TRUE} ] ; then
    QEMU_PARAMETER="${QEMU_PARAMETER} -monitor stdio "
  fi

  for IMAGE_FILE_DESC in hda hdb hdc hdd fda fdb cdrom loadvm ; do
     
    eval IMAGE_FILE_NAME=\"\$$( toUppercase ${IMAGE_FILE_DESC} )_IMAGE\"
    if [ "${IMAGE_FILE_NAME}"x != ""x ] ; then
      if [ ! -f "${IMAGE_FILE_NAME}" ] ; then
        die 6 "Image file  \"${IMAGE_FILE_NAME}\" (${IMAGE_FILE_DESC}) not found"
      else
        IMAGE_USERS="$( fuser "${IMAGE_FILE_NAME}" 2>/dev/null )"
        if [ "${IMAGE_USERS}"x != ""x ] ; then
          LogWarning "The image file \"${IMAGE_FILE_NAME}\" (${IMAGE_FILE_DESC}) is already in use by the process(es): "
          for PID in ${IMAGE_USERS} ; do
	    LogMsg "-" "$( ps -p ${PID} -o pid= -o args= )"
          done	    
          AskUser "Continue execution?" || die 200 "Script aborted by the user"
        fi 
        QEMU_PARAMETER="${QEMU_PARAMETER} -${IMAGE_FILE_DESC} ${IMAGE_FILE_NAME}" 
      fi
    fi
  done
  
   
  if [ ${KQEMU_USER_MODE} = ${__FALSE} -a ${KQEMU_KERNEL_MODE} != ${__TRUE} ] ; then
    QEMU_PARAMETER="-no-kqemu ${QEMU_PARAMETER}"
  fi

  if [ ${KQEMU_KERNEL_MODE} = ${__TRUE} ] ; then
    QEMU_PARAMETER="-kernel-kqemu ${QEMU_PARAMETER}"
  fi

  if  [ "${ADD_CMD}"x != ""x ] ; then
    LogMsg "Executing \"${ADD_CMD}\" ..."     
    ${ADD_CMD}
  fi
  
  CMD="${QEMU_BINARY} ${QEMU_PARAMETER} "

  if [ "${DISPLAY}"x = ""x ] ; then
    export DISPLAY=:0.0
    XHOST_BINARY="/usr/openwin/bin/xhost"
    if [ -x "${XHOST_BINARY}" ] ; then
       "${XHOST_BINARY}" || die 2 "Can not use the display \"${DISPLAY}\""
    else
      LogWarning "Can not find or execute the binary \"${XHOST_BINARY}\""
    fi
  fi
  
  LogMsg "Executing \"${CMD}\" ..."

  if [ ${MONITOR_TO_STDIO} = ${__TRUE} ] ; then
# start qemu in the foreground to get access to the control console!
    set -x
    ${CMD} 
    __MAINRC=$?
    set +x
  else
    set -x
    ${CMD} &
    __MAINRC=0
    set +x
  fi
  
  die ${__MAINRC} 
 
exit
