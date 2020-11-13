#!/bin/ksh 
#
# script to set the speed of a network adapter
#
# Author: Bernd Schemmer
#         Bernd.Schemmer@gmx.de
#
# History: 
#
#           1.0.9 31.03.2008
#           - added support for e1000gx driver
#
#           1.0.8 04.01.2008 
#           - added support for new GLDv3 driver
#           - added parameter createcmds
#
#           1.0.7 06.11.2007
#           - added workaround for bug 6548250 for nxge driver
# 
#           1.0.6 02.11.2007
#           - added support for nxge adapters
#
#           1.0.5 15.12.2005
#           - added suport for bge adapters
#
#          1.0.4 28.02.2005
#           - change order of ndd commands
#           - make code more flexible
#
#          1.0.3 10.02.2005
#           - added check for executing user
#
#          1.0.2 17.11.2004
#           - added support for adapters no 10 to 99
#
#          1.0.1  27.06.2004
#          - minor bug changes
#
#          1.0.0, 01/10/2004
#          - initial version
#
# Usage: ksh configure_network_adapter adapter adapter_speed
#
# Where: Adapter is the network adapter (e.g. hme0, ce0, etc)
#
#        Adapter speed is the adapter speed:
#
#          100HD 100FD 1000HD 1000FD 10FD 10HD AUTO 10000 10G
#
# This is a ksh script!
#

NDD_KEYS=""

my_echo() {
  
  if [ "${COMMAND}"x = "createcmds"x ] ; then
    typeset THISMSG="# $*"
      
    if [ "${OUTPUTFILE}"x != ""x ] ; then
      echo "${THISMSG}" >>"${OUTPUTFILE}"
    else
      echo "${THISMSG}" 
    fi
  else
    echo "${THISMSG}" 
  fi     

}

my_echo1() {
  if [ "${COMMAND}"x = "createcmds"x ] ; then
    typeset THISMSG="$*"

    if [ "${OUTPUTFILE}"x != ""x ] ; then
      echo "${THISMSG}" >>"${OUTPUTFILE}"
    else
      echo "${THISMSG}"
    fi
  fi
}

my_ndd() {
  typeset THIS_CMD=$1
  typeset THIS_ADAPTER=$2
  typeset THIS_KEY=$3
  typeset THIS_VAL=$4

# workaround for bug 6548250 for nxge driver
#
  if [ "${NDD_KEYS}"x = ""x ] ; then
    for i in $( ndd -get ${THIS_ADAPTER} \? | grep "read and write" | cut -f1 -d " " ) ; do
      NDD_KEYS="${NDD_KEYS} ${i} "
    done
  fi

  if [[ ${NDD_KEYS} == *\ ${THIS_KEY}\ *  ]] ; then  
    if [ "${COMMAND}"x != "createcmds"x ] ; then
      echo "Setting \"${THIS_KEY}\" \"${THIS_VAL}\" ..."
      ndd -set ${THIS_ADAPTER} ${THIS_KEY} ${THIS_VAL}
    else      
      if [ "${OUTPUTFILE}"x != ""x ] ; then
        echo ndd -set ${THIS_ADAPTER} ${THIS_KEY} ${THIS_VAL}  >>"${OUTPUTFILE}"
      else
        echo ndd -set ${THIS_ADAPTER} ${THIS_KEY} ${THIS_VAL}
      fi
      
    fi      
  fi

  return $?
}


#
# usage:  set_all_except_one [adv_xx] {0|1}
#
set_all_except_one() {

  typeset NEW_MODE="$1"
  typeset NEW_VALUE="$2"
  [ "${NEW_VALUE}"x = ""x ] && NEW_VALUE=0
  
  typeset CUR_KEY=""
  for CUR_KEY in adv_10gfdx_cap adv_10gfdx_cap \
                 adv_100hdx_cap adv_100fdx_cap adv_100T4_cap \
		 adv_1000fdx_cap adv_1000hdx_cap \
                 adv_10fdx_cap adv_10hdx_cap 
		 do
    if [ "${NEW_MODE}"x != "${CUR_KEY}"x ] ; then		 
      my_ndd -set ${ADAPTER_NAME_FOR_NDD} ${CUR_KEY} ${NEW_VALUE}
    fi
  done   
}

toggle_autoneg() {

  if [ $1 = 0 ] ; then
# toggle the adv_autoneg_cap and set it to 0
    my_ndd -set ${ADAPTER_NAME_FOR_NDD} adv_autoneg_cap 0
    my_ndd -set ${ADAPTER_NAME_FOR_NDD} adv_autoneg_cap 1
    my_ndd -set ${ADAPTER_NAME_FOR_NDD} adv_autoneg_cap 0
  else
# toggle the adv_autoneg_cap and set it to 1
    my_ndd -set ${ADAPTER_NAME_FOR_NDD} adv_autoneg_cap 1
    my_ndd -set ${ADAPTER_NAME_FOR_NDD} adv_autoneg_cap 0
    my_ndd -set ${ADAPTER_NAME_FOR_NDD} adv_autoneg_cap 1
  fi      
}


  SCRIPT_VERSION="v1.0.9"

  ADAPTER=$1
  ADAPTER_SPEED=$2
  COMMAND="$3"
  OUTPUTFILE="$4"

  SCRIPT_NAME="${0##*/}"

  case "${COMMAND}" in

    "createcmds" )
      : known command
      ;;

    "" )
      : no command
      ;;

    * )
      : invalid command
      echo "${SCRIPT_NAME} - ERROR: Invalid command found \"${COMMAND}\" "
      SHOW_USAGE=0
      ;;
  esac

  if [ "${ADAPTER}"x = ""x  -o "${ADAPTER}"x = "-h"x -o "${SHOW_USAGE}"x = "0"x ] ; then
    echo "${SCRIPT_NAME} ${SCRIPT_VERSION} - configure a network adapter"
    echo ""
    echo "Usage: ${SCRIPT_NAME} adapter adapter_speed [createcmds [outputfile]]"
    echo ""
    echo "Possible values for adapter_speed:"
    echo ""
    echo "Value                                   means"
    echo "-----------------------------------------------------------------"
    echo "100fd, 100FD,    100FullDuplex        - 100 Mbit FullDuplex"
    echo "100hd, 100HD,    100HalfDuplex        - 100 Mbit HalfDuplex"
    echo "1000fd, 10000FD, 1000FullDuplex       - 1000 Mbit FullDuplex"
    echo "1000hd, 1000HD,  1000HalfDuplex       - 1000 Mbit HalfDuplex"
    echo "10fd,   10FD,    10HFullDuplex        - 10 Mbit FullDuplex"
    echo "10hd,   10HD,    10HalfDuplex         - 10 Mbit HalfDuplex"
    echo "10000, 10G                            - 10 Gigabit"
    echo "auto,  AUTO                           - use Autonegotiation"
    echo ""
    echo "createcmds : Save the commands in the file \"outpufile\" - do not change "
    echo "             the adapter configuration; default output file is STDOUT."
    exit 99
  fi

  if [ "$( id | sed 's/uid=\([0-9]*\)(.*/\1/' )" != 0 ] ; then     
    echo "${SCRIPT_NAME} - ERROR: You must be root to execute this script!"
    exit 5
  fi

  if [ "${ADAPTER}"x != ""x -a "${ADAPTER_SPEED}"x != ""x ] ; then

#    ADAPTER_NAME=${ADAPTER%%[0-9]*}
#    ADAPTER_NUMBER=${ADAPTER##*[a-z]}

    ADAPTER_NAME=${ADAPTER%[0-9]*}
    ADAPTER_NUMBER=${ADAPTER##*[a-z]}

#  echo  \"${ADAPTER_NAME}\"
#  echo \"${ADAPTER_NUMBER}\"
  
# echo "${ADAPTER_NAME} ${ADAPTER_NUMBER}"

    INVALID_ADAPTER=1

    [ "${ADAPTER_NUMBER}"x = ""x ]           && INVALID_ADAPTER=0
    [ "${ADAPTER_NAME}"x = ""x ]             && INVALID_ADAPTER=0
    [ "${ADAPTER_NUMBER}"x = "${ADAPTER}"x ] && INVALID_ADAPTER=0
    [ "${ADAPTER_NAME}"x = "${ADAPTER}"x ]   && INVALID_ADAPTER=0

    if [ ${INVALID_ADAPTER} = 0 ] ; then
      echo "${SCRIPT_NAME} - ERROR: Invalid adapter parameter: \"${ADAPTER}\" "
      exit 1
    fi

# some adapter support a different syntax for ndd 
#
    case ${ADAPTER_NAME} in

      bge ) 
        ADAPTER_NAME_FOR_NDD="/dev/${ADAPTER_NAME}${ADAPTER_NUMBER}"
        NEW_SYNTAX_FOR_NDD=0
        ;;

      nxge ) 
        ADAPTER_NAME_FOR_NDD="/dev/${ADAPTER_NAME}${ADAPTER_NUMBER}"
        NEW_SYNTAX_FOR_NDD=0
        ;;


      * )
        ADAPTER_NAME_FOR_NDD="/dev/${ADAPTER_NAME}"
        NEW_SYNTAX_FOR_NDD=1
        ;;
    esac

    if [ ${NEW_SYNTAX_FOR_NDD} = 1 ] ; then
      ndd -set ${ADAPTER_NAME_FOR_NDD} instance ${ADAPTER_NUMBER} 2>/dev/null 1>/dev/null
      if [ $? -ne 0 ] ; then
        NND_SELECT_CMD=""
        ndd -get ${ADAPTER_NAME_FOR_NDD}${ADAPTER_NUMBER} \? >/dev/null 2>/dev/null
	if [ $? -eq 0 ] ; then
	  my_echo "Note: This looks like a new GLDv3 driver is used for this adapter"
          ADAPTER_NAME_FOR_NDD="/dev/${ADAPTER_NAME}${ADAPTER_NUMBER}"
          NEW_SYNTAX_FOR_NDD=0
          BGE_SYNTAX=0
	else  
          echo "${SCRIPT_NAME} - ERROR: Adapter \"${ADAPTER}\" not found!"
          exit 2
	fi
      else
        NDD_SELECT_CMD="ndd -set ${ADAPTER_NAME_FOR_NDD} instance ${ADAPTER_NUMBER}"
      fi
    fi

    case ${ADAPTER_SPEED} in

      "10000" | "10G" | "10g" )
        my_echo "Setting the adapter \"${ADAPTER}\" to 10g"
        my_echo1 "${NDD_SELECT_CMD}"
	
        ndd -get ${ADAPTER_NAME_FOR_NDD} adv_10gfdx_cap 1>/dev/null 2>/dev/null
        if [ $? -ne 0 ] ; then
          echo "${SCRIPT_NAME} - ERROR: This mode is NOT supported by the adapter!"
          exit 6
        fi
        my_ndd -set ${ADAPTER_NAME_FOR_NDD} adv_10gfdx_cap 1
        set_all_except_one adv_10gfdx_cap 0
        toggle_autoneg 0
        ;;

	 
      "100HD" | "100hd" | "100Hd" | "100HalfDuplex" ) 
        my_echo "Setting the adapter \"${ADAPTER}\" to 100 Mbit/s HalfDuplex"
        my_echo1 "${NDD_SELECT_CMD}"
	
        ndd -get ${ADAPTER_NAME_FOR_NDD} adv_100hdx_cap 1>/dev/null 2>/dev/null
        if [ $? -ne 0 ] ; then
          echo "${SCRIPT_NAME} - ERROR: This mode is NOT supported by the adapter!"
          exit 6
        fi

        my_ndd -set ${ADAPTER_NAME_FOR_NDD} adv_100hdx_cap 1
        set_all_except_one adv_100hdx_cap 0
        toggle_autoneg 0
        ;;

      "100FD" | "100fd" | "100Fd" | "100FullDuplex" ) 
        my_echo "Setting the adapter \"${ADAPTER}\" to 100 Mbit/s FullDuplex" 
        my_echo1 "${NDD_SELECT_CMD}"
	
        ndd -get ${ADAPTER_NAME_FOR_NDD} adv_100fdx_cap 1>/dev/null 2>/dev/null
        if [ $? -ne 0 ] ; then
          echo "${SCRIPT_NAME} - ERROR: This mode is NOT supported by the adapter!" 
          exit 6
        fi 

        my_ndd -set ${ADAPTER_NAME_FOR_NDD} adv_100fdx_cap 1
        set_all_except_one adv_100fdx_cap 0
        toggle_autoneg 0
        ;;

      "1000FD" | "1000fd" | "1000Fd" | "1000FullDuplex" ) 
        my_echo "Setting the adapter \"${ADAPTER}\" to 1000 Mbit/s FullDuplex"
        my_echo1 "${NDD_SELECT_CMD}"
	
        ndd -get ${ADAPTER_NAME_FOR_NDD} adv_1000fdx_cap 1>/dev/null 2>/dev/null
        if [ $? -ne 0 ] ; then
          echo "${SCRIPT_NAME} - ERROR: This mode is NOT supported by the adapter!" 
          exit 6
        fi

        my_ndd -set ${ADAPTER_NAME_FOR_NDD} adv_1000fdx_cap 1
        set_all_except_one adv_10000fdx_cap 0
        toggle_autoneg 0
        ;;

      "1000HD" | "1000hd" | "1000Hd" | "1000HalfDuplex" ) 
        my_echo "Setting the adapter \"${ADAPTER}\" to 1000 Mbit/s HalfDuplex"
        my_echo1 "${NDD_SELECT_CMD}"
	
        ndd -get ${ADAPTER_NAME_FOR_NDD} adv_1000hdx_cap 1>/dev/null 2>/dev/null
        if [ $? -ne 0 ] ; then
          echo "${SCRIPT_NAME} - ERROR: This mode is NOT supported by the adapter!"
          exit 6
        fi

        my_ndd -set ${ADAPTER_NAME_FOR_NDD} adv_1000hdx_cap 1 
        set_all_except_one adv_1000hdx_cap 0
        toggle_autoneg 0
        ;;

      "10FD" | "10fd" | "10Fd" | "10FullDuplex" )
        my_echo "Setting the adapter \"${ADAPTER}\" to 10 Mbit/s FullDuplex" 
        my_echo1 "${NDD_SELECT_CMD}"

        ndd -get ${ADAPTER_NAME_FOR_NDD} adv_10fdx_cap 1>/dev/null 2>/dev/null
        if [ $? -ne 0 ] ; then
          echo "${SCRIPT_NAME} - ERROR: This mode is NOT supported by the adapter!" 
          exit 6
        fi

        my_ndd -set ${ADAPTER_NAME_FOR_NDD} adv_10fdx_cap 1
        set_all_except_one adv_10fdx_cap 0
        toggle_autoneg 0
        ;;

      "10HD" | "10hd" | "10Hd" | "10HalfDuplex" )
        my_echo "Setting the adapter \"${ADAPTER}\" to 10 Mbit/s HalfDuplex"
        my_echo1 "${NDD_SELECT_CMD}"
	
        ndd -get ${ADAPTER_NAME_FOR_NDD} adv_10hdx_cap 1>/dev/null 2>/dev/null
        if [ $? -ne 0 ] ; then
          echo "${SCRIPT_NAME} - ERROR: This mode is NOT supported by the adapter!"
          exit 6
        fi

        my_ndd -set ${ADAPTER_NAME_FOR_NDD} adv_10hdx_cap 1
        set_all_except_one adv_10ghdx_cap 0
        toggle_autoneg 0
        ;;

      "auto" | "AUTO" | "Auto" )
        my_echo "Setting the adapter \"${ADAPTER}\" to AutoNegotiation"
        my_echo1 "${NDD_SELECT_CMD}"
	
        ndd -get ${ADAPTER_NAME_FOR_NDD} adv_autoneg_cap 1>/dev/null 2>/dev/null
        if [ $? -ne 0 ] ; then
          echo "${SCRIPT_NAME} - ERROR: This mode is NOT supported by the adapter!"
          exit 6
        fi

        my_ndd -set ${ADAPTER_NAME_FOR_NDD} adv_100T4_cap 0
        set_all_except_one adv_100T4_cap 1
        toggle_autoneg 1
        ;;

      * )
        echo "${SCRIPT_NAME} - ERROR: Invalid speed parameter: \"${ADAPTER_SPEED}\" "
        exit 3
        ;;

    esac
  else
    echo "${SCRIPT_NAME} - ERROR: Parameter missing!"
    exit 4
  fi

  if [ "${COMMAND}"x = "createcmds"x -a "${OUTPUTFILE}"x != ""x ] ; then
    echo "Outputfile \"${OUTPUTFILE}\" created."
  fi

  exit 0
 

