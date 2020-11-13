#!/usr/bin/ksh
# 
# script to get the status of a network adapter
#
# Author: Bernd Schemmer
#         Bernd.Schemmer@gmx.de
#
# Version: 1.0.0 /bs 01/12/2004
#          1.0.1 /bs 10/01/2005
#          1.1.0 /bs 02/28/2005
#          1.2.0 /bs 12/15/2005 - added support for bge adapters
#          1.2.1 /bs 05/19/2006 - minor bug fixes
#          1.2.2 /bs 08/09/2006 - corrected code for bge adapters
#          1.2.3 /bs 11/02/2007 - added support for nxge adapters
#          1.2.4 /bs 12/21/2007 - added support for new GLDv3 driver
#          1.2.5 /bs 03/31/2008 - added support for e1000gx driver
#
# Usage: ksh get_network_adapter adapter [kstat|ndd]
#
# Where: adapter is the network adapter (e.g. hme0, ce0, etc)
#
#        kstat - use kstat
#        ndd - use ndd
#
#	Default: Use the approbiate method for the adapter
#
# This is a ksh script!
#
  SCRIPT_VERSION="v1.2.5"

  SCRIPT_NAME="${0##*/}"

  ADAPTER=$1
  [ "$2"x != ""x ] && METHOD_TO_USE=$2 || METHOD_TO_USE=""

  if [ "${ADAPTER}"x = ""x  -o "${ADAPTER}"x = "-h"x ] ; then
    echo "${SCRIPT_NAME} ${SCRIPT_VERSION} - get the status of a network adapter"
    echo ""
    echo "Usage: ${SCRIPT_NAME} adapter [kstat|ndd]"
    echo ""
    echo "kstat - use kstat, ndd - use ndd; default: use the approbiate"
    echo "method for the adapter."
    echo ""
    echo "Hint: The output of kstat maybe wrong if it is not supported by the driver!"
    echo ""
    exit 99
  fi

  if [ "$( id | sed 's/uid=\([0-9]*\)(.*/\1/' )" != 0 ] ; then     
    echo "ERROR: You must be root to execute this script!"
    exit 5
  fi

  if [ "${ADAPTER}"x != ""x ] ; then

#    ADAPTER_NAME=${ADAPTER%%[0-9]*}
#    ADAPTER_NUMBER=${ADAPTER##*[a-z]}

    ADAPTER_NAME=${ADAPTER%[0-9]*}
    ADAPTER_NUMBER=${ADAPTER##*[a-z]}

#  echo \"${ADAPTER_NAME}\"
#  echo \"${ADAPTER_NUMBER}\"
  
# echo ${ADAPTER_NAME} ${ADAPTER_NUMBER}

    INVALID_ADAPTER=1

    [ "${ADAPTER_NUMBER}"x = ""x ]         && INVALID_ADAPTER=0
    [ "${ADAPTER_NAME}"x = ""x ]           && INVALID_ADAPTER=0
    [ "${ADAPTER_NUMBER}"x = "${ADAPTER}"x ] && INVALID_ADAPTER=0
    [ "${ADAPTER_NAME}"x = "${ADAPTER}"x ]   && INVALID_ADAPTER=0

    if [ ${INVALID_ADAPTER} = 0 ] ; then
      echo "${SCRIPT_NAME}  - ERROR: Invalid adapter parameter: \"${ADAPTER}\" "
      exit 1
    fi

# some adapter support a different syntax for ndd 
#
    NEW_SYNTAX_FOR_NDD=1
    BGE_SYNTAX=1  

    case ${ADAPTER_NAME} in

      bge ) 
        ADAPTER_NAME_FOR_NDD="/dev/${ADAPTER_NAME}${ADAPTER_NUMBER}"

        DEFAULT_METHOD_TO_USE="ndd"
        NEW_SYNTAX_FOR_NDD=0
        BGE_SYNTAX=0
        ;;

      nxge ) 
        ADAPTER_NAME_FOR_NDD="/dev/${ADAPTER_NAME}${ADAPTER_NUMBER}"
        NEW_SYNTAX_FOR_NDD=0
        DEFAULT_METHOD_TO_USE="kstat"
        BGE_SYNTAX=0
        ;;
	
      ce ) 
        ADAPTER_NAME_FOR_NDD="/dev/${ADAPTER_NAME}"
        DEFAULT_METHOD_TO_USE="kstat"
        ;;


      * )
        ADAPTER_NAME_FOR_NDD="/dev/${ADAPTER_NAME}"

        DEFAULT_METHOD_TO_USE="ndd"
        NEW_SYNTAX_FOR_NDD=1
        ;;

    esac
    
    if [ ${NEW_SYNTAX_FOR_NDD} = 1 ] ; then
      ndd -set ${ADAPTER_NAME_FOR_NDD} instance ${ADAPTER_NUMBER}
      if [ $? -ne 0 ] ; then
        ndd -get ${ADAPTER_NAME_FOR_NDD}${ADAPTER_NUMBER} \? >/dev/null
	if [ $? -eq 0 ] ; then
	  echo "Note: This looks like a new GLDv3 driver is used for this adapter"
          ADAPTER_NAME_FOR_NDD="/dev/${ADAPTER_NAME}${ADAPTER_NUMBER}"
	  DEFAULT_METHOD_TO_USE="kstat"
          NEW_SYNTAX_FOR_NDD=0
          BGE_SYNTAX=0
	else  
          echo "${SCRIPT_NAME}  - ERROR: Adapter \"${ADAPTER}\" not found!"
          exit 2
	fi
      fi
    fi


    if [ "${METHOD_TO_USE}"x != ""x ] ; then
      if [ "${METHOD_TO_USE}"x != "kstat"x -a "${METHOD_TO_USE}"x != "ndd"x ] ; then
        echo "Invalid parameter found: \"$2\" "
        exit 4
      fi
    else
      METHOD_TO_USE=${DEFAULT_METHOD_TO_USE}
    fi

  
    echo "Retrieving the status for the adapter \"${ADAPTER}\" using the method \"${METHOD_TO_USE}\" ..."

    if [ "${METHOD_TO_USE}"x == "ndd"x ] ; then

      echo "The advertised capabilities of the interface are:"

      for i in `ndd -get ${ADAPTER_NAME_FOR_NDD} \? | grep "^adv_" | cut -f1 -d " "` ;
      do
        [ "$i" != "?" ] && echo "$i : " `ndd -get ${ADAPTER_NAME_FOR_NDD} $i`
      done

      echo "The capabilities of the link partner are:"
      echo "NOTE: THESE VALUES ARE ONLY VALID IF THE NETWORK CARD AND THE SWITCH ARE CONFIGURED FOR AUTONEG!"
      for i in `ndd -get ${ADAPTER_NAME_FOR_NDD} \? | grep "^lp" | cut -f1 -d " "` ; do
        echo "$i : " `ndd -get ${ADAPTER_NAME_FOR_NDD} $i`
      done

      if [ "${BGE_SYNTAX}" = "1" ] ; then
        link_status=`ndd -get ${ADAPTER_NAME_FOR_NDD} link_status`
        link_mode=`ndd -get ${ADAPTER_NAME_FOR_NDD} link_mode`
        link_speed=`ndd -get ${ADAPTER_NAME_FOR_NDD} link_speed`

        echo "The current mode of the interface is:"
        [ "$link_status" = "1" ] && echo "The link is up"
        [ "$link_status" = "0" ] && echo "The link is down"

        [ "$link_speed" = "1" ] && echo "The mode is 100 MBit"
        [ "$link_speed" = "0" ] && echo "The mode is 10 MBit"

        [ "$link_mode" = "1" ] && echo "The mode is Full Duplex"
        [ "$link_mode" = "0" ] && echo "The mode is Half Duplex"
      else
        link_status=`ndd -get ${ADAPTER_NAME_FOR_NDD} link_status`
        link_duplex=`ndd -get ${ADAPTER_NAME_FOR_NDD} link_duplex`
        link_speed=`ndd -get ${ADAPTER_NAME_FOR_NDD} link_speed`

        echo "The current mode of the interface is:"
        [ "$link_status" = "1" ] && echo "The link is up"
        [ "$link_status" = "0" ] && echo "The link is down"

        [ "$link_speed"x != ""x ] && echo "The mode is $link_speed MBit"

        [ "$link_duplex" = "2" ] && echo "The mode is Full Duplex"
        [ "$link_duplex" = "1" ] && echo "The mode is Half Duplex"
      fi
    else
      kstat -h 1>/dev/null 2>/dev/null
      if [ $? -ne 2 ] ; then
        echo "${SCRIPT_NAME}  - ERROR: kstat not found!"
        exit 7
      fi

      echo "The capabilities of the interface are:"
      kstat -p ${ADAPTER_NAME}:${ADAPTER_NUMBER}::"/^cap_/"        

      echo "The advertised capabilities of the interface are (retrieved with ndd):"
      for i in `ndd -get ${ADAPTER_NAME_FOR_NDD} \? | grep "adv_" | cut -f1 -d " "` ; do
        [ "$i" != "?" ] && echo "$i : " `ndd -get ${ADAPTER_NAME_FOR_NDD} $i`
      done

      echo "The link partner capabilities are:"
      echo "NOTE: THESE VALUES ARE ONLY VALID IF THE NETWORK CARD AND THE SWITCH ARE CONFIGURED FOR AUTONEG!"
      kstat -p ${ADAPTER_NAME}:${ADAPTER_NUMBER}::"/^lp_cap_/"


      echo "The current mode of the interface is:"
      echo "(Note: link_duplex: 0 = down, 1 = half, 2 = full "
      echo  "      link_speed in MBit/s, link_up: 1 = up, 0 = down)"
      kstat -p ${ADAPTER_NAME}:${ADAPTER_NUMBER}::"/^link_/"
   
    fi
  else
    echo "`${SCRIPT_NAME}  - ERROR: Parameter missing!"
    exit 4
  fi

  exit 0
 

