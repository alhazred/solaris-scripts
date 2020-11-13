#!/usr/bin/ksh
#
# list_pci_adapter.sh - simple script to list the PCI adapter of x86 machines running with Solaris x86
#
# History
#   27.11.2013/bs
#     initial release
#
# Usage:
#
#  list_pci_adapter.sh [prtconf_vpPD_output] [etc_path_to_inst]
#
# Both parameter are optional, if they are missing the script calls prtconf and reads /etc/path_to_inst
# to get the necsssary information
#
# Tested with
#   IBM System x3650 M3 -[794572G]
#   Oracle X4270 M3
#
#
__TRUE=0
__FALSE=1

#__VERBOSE=${__TRUE}
#__VERBOSE=${__FALSE}

LogInfo() {
  [ "${__VERBOSE}"x = "${__TRUE}"x ] && echo "INFO: $*"
}

TESTED_MACHINES="
IBM System x3650 M3 -[794572G]-
Oracle Corporation SUN FIRE X4270 M3 
"

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
  typeset THISRC=${__FALSE}

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
      SLOT_MODEL[${NO_OF_SLOTS}]=""
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

    P_SLOT_NO="${SLOT_NO[${i}]}"
    (( P_SLOT_NO = P_SLOT_NO + 0 ))
    P_SLOT_ADAPTER_CLASS="${SLOT_MODEL}"
    P_SLOT_DEVICE_PATH="${SLOT_ADDRESS}/${SLOT_ADAPTER}"
    P_SLOT_DEVICE_NAME=""

    THIS_ADAPTER="${SLOT_ADAPTER%,*}"
    echo "${ETC_PATH_TO_INST}" | grep "${SLOT_ADDRESS}@" | egrep "${THIS_ADAPTER}.*@"  | while read line ; do
      [[ ${line} == */${SLOT_ADDRESS}@*/${SLOT_ADAPTER}@*/* ]] && [ "${SLOT_MODEL[${i}]}"x != "PCI-PCI bridge"x ] && continue
      set -- $line 
      eval DEVNAME=$3
      eval DEVNO=$2
      [[ ${DEVNAME} == pcieb* ]]  && continue
      P_SLOT_DEVICE_NAME="${P_SLOT_DEVICE_NAME} ${DEVNAME}${DEVNO}"

      eval ADAPTER_${DEVNAME}${DEVNO}=PCI\"${P_SLOT_NO}\"
    done

    Getx86PCISlotUsage_OUTPUT_BODY="${Getx86PCISlotUsage_OUTPUT_BODY}
${P_SLOT_NO}${P_SLOT_ADAPTER_CLASS}${P_SLOT_DEVICE_PATH}${P_SLOT_DEVICE_NAME}"

  done

  Getx86PCISlotUsage_OUTPUT="${Getx86PCISlotUsage_OUTPUT_TITLE}
$( echo "${Getx86PCISlotUsage_OUTPUT_BODY}" | grep -v "^$" | sort )
"

  return ${THISRC}
}

# --------------------
# main
#

if [ "$1"x = "-h"x -o "$1"x = "--help"x ] ; then
  cat <<EOT

$0 [prtconf_vpPD_output] [etc_path_to_inst]

Both parameter are optional, if they are missing the script calls prtconf and reads /etc/path_to_inst
to get the necsssary information

The script was already tested on these machines

${TESTED_MACHINES}

EOT
  exit 1
fi

MACHINE_TYPE="$( uname -m )"
if [ "${MACHINE_TYPE}"x != "i86pc"x -a $# -ne 2 ] ; then
  echo "WARNING: This script is only tested on x86 machines!"
fi

if [ $# -ne 2 ] ; then
  CUR_MACHINE_TYPE="$( prtdiag | grep "System Configuration" | cut -f2- -d ":" )"

  MACHINE_KNOWN=${__FALSE}
  echo "${TESTED_MACHINES}" | while read line ; do
    [[ ${CUR_MACHINE_TYPE} == *${line}* ]] && MACHINE_KNOWN=${__TRUE}
  done
  if [ "${MACHINE_KNOWN}" != ${__TRUE} ] ; then
    echo "WARNING: This script was NOT tested yet for ${CUR_MACHINE_TYPE}"
  fi
fi


Getx86PCISlotUsage $1 $2

echo "${Getx86PCISlotUsage_OUTPUT}"

