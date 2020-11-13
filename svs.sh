#!/usr/bin/ksh
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
# shell script to start a secure VNC server using ssh 
#
# Author: Bernd Schemmer (Bernd.Schemmer@gmx.de)
#
# History
#
# 13.12.2004 /bs	initial release
# 15.12.2004 /bs	extend the script
# 17.12.2004 /bs 	extended the script
# 21.12.2004 /bs	extended the script
# 13.01.2005 /bs	added the parameter startUser
#

# ----------------------------------------------------------
# sub routines

# --------------------------------------
# isNumber
#
# check if a value is an integer 
#
# usage: isNumber testValue 2>/dev/null
#
# returns: 0 - testValue is a number else not
#
isNumber() {
  [ "$( echo $1 | sed 's/[0-9]*//' )"x = ""x ] && return 0 || return 1
}


# --------------------------------------
# die
#
# print an error message and end the script
#
# usage: die returncode errormessage
#
die() {
  typeset THISRC=$1

  shift
  echo "ERROR: $*"
  exit ${THISRC}
}



# --------------------------------------
# PrintUsge
#
# print the usage
#
# usage: PrintUsage
#
PrintUsage() {
  echo "Usage: $( basename $0 ) {start|startmed|startbig|startuser geometry|startsmall|stop|status|statusall} [displaynumber]"
}


# --------------------------------------
# CheckVNCStatus
#
# usage: CheckVNCStatus display_number incoming_port vnc_port
#
# returns: the variables 
#            VNC_ALREADY_RUNNING 
#            SSH_ALREADY_RUNNING 
#            VNC_PID
#            SSH_PID
#            VNC_USER
#            SSH_USER 
#            VNC_GEOMETRY 
# are set
#
CheckVNCStatus() {
  typeset DISPLAY_NUMBER=$1
  typeset INCOMING_PORT=$2
  typeset VNC_PORT=$3

  VNC_GEOMETRY=""  
#  ps -ef | grep -v grep | grep "Xvnc :${DISPLAY_NUMBER}"  | read VNC_USER VNC_PID d2 
  set -- $(ps -ef | grep -v grep | grep "Xvnc :${DISPLAY_NUMBER}" )
  VNC_USER=$1
  VNC_PID=$2
  if [ "${VNC_PID}"x != ""x ] ; then
    VNC_ALREADY_RUNNING=${__TRUE}
    while [ "$1"x != ""x ] ; do
      [ "$1"x = "-geometry"x ] && VNC_GEOMETRY=$2
      shift
    done      
  else
    VNC_ALREADY_RUNNING=${__FALSE}
  fi

  ps -ef | grep -v grep | grep "ssh ${SSH_OPTIONS} ${INCOMING_PORT}:localhost:${VNC_PORT}" | read SSH_USER SSH_PID d2
  if [ $? -eq 0 ] ; then
    SSH_ALREADY_RUNNING=${__TRUE}
  else 
    SSH_ALREADY_RUNNING=${__FALSE}
  fi
}

# --------------------------------------
# main: start

  __TRUE=0
  __FALSE=1

 __USERID=""
 [ -x /usr/ucb/whoami ] && /usr/ucb/whoami | read __USERID __REST

  GEOMETRY="1280x960"
  
  DISPLAY_NUMBER=""

  ACTION=$1
  [ "${ACTION}"x = ""x ] && ACTION="start"

  if [ "${ACTION}"x = "startUser"x ] ; then
    ACTION="start"
    [ "$2"x = ""x ] && die 3 "Missing parameter for startUser!"
    GEOMETRY="$2"  
    shift
  fi
      
  if [ "$2"x != ""x ] ; then
    if [ "$2"x = "all"x ] ; then
      ACTION="statusall"
    else
      isNumber $2
      if [ $? -ne 0 ] ; then 
        die 3 "Invalid parameter found: $2"
      else	
        DISPLAY_NUMBER=$2
      fi
    fi      
  fi
  
  [ "${DISPLAY_NUMBER}"x = ""x ] && DISPLAY_NUMBER=1

  PATH=$PATH:/usr/openwin/bin
  export PATH

  THISHOST=$( hostname )

  SSH_OPTIONS="-t -N -f -C -c blowfish -L"

  (( VNC_PORT=5900 + ${DISPLAY_NUMBER} ))

  (( INCOMING_PORT = 7900 + ${DISPLAY_NUMBER} ))

  case ${ACTION} in

   "statusall" ) : "Retrieving the status of all running secure VNC servers ..."
              ;;
	       
    "startbig" ) ACTION="start"
                 GEOMETRY="1600x1200"
              ;;

    "startmed" ) ACTION="start"
                 GEOMETRY="1280x960"
              ;;

    "startsmall" ) ACTION="start"
                   GEOMETRY="1026x768"
              ;;


    "start" ) : echo "Starting the secure VNC server with ${GEOMETRY} ..." 
              ;;

    "stop"  ) : echo "Stopping the secure VNC server ..." 
              ;;

   "status" ) : echo "Retrieving the status of the secure VNC server ..." 
              ;;

   
   "-h" | "help" )
              PrintUsage
              exit 1
              ;;

          * ) echo "ERROR: Invalid parameter found ($*)"
              PrintUsage
              exit 255
              ;;

  esac


# usage: CheckVNCStatus display_number incoming_port vnc_port

  CheckVNCStatus ${DISPLAY_NUMBER} ${INCOMING_PORT} ${VNC_PORT}


  case ${ACTION} in

    "start" ) if [ ${VNC_ALREADY_RUNNING} = ${__TRUE} ] ; then
                echo "The VNC server for display ${DISPLAY_NUMBER} is already running; the user id is ${VNC_USER} (Geometry: ${VNC_GEOMETRY})."
              else
                echo "Starting the secure VNC server for display ${DISPLAY_NUMBER} with ${GEOMETRY}..." ;
# -IdleTimeout=360000
                vncserver :${DISPLAY_NUMBER} -name ${THISHOST}_${DISPLAY_NUMBER} -geometry ${GEOMETRY} -depth 16 -localhost
		[ $? -ne 0 ] && echo "EERROR: Can not start the vnc server!"
              fi

              if [ ${SSH_ALREADY_RUNNING} = ${__TRUE} ] ; then
                echo "the ssh for display ${DISPLAY_NUMBER} is already running; the user id is ${SSH_USER}"
              else
                echo "Starting ssh ..."   
                ssh ${SSH_OPTIONS} ${INCOMING_PORT}:localhost:${VNC_PORT} ${THISHOST}
		[ $? -ne 0 ] && echo "EERROR: Can not start ssh!"
              fi
              ;;

    "stop"  ) if [ ${VNC_ALREADY_RUNNING} = ${__FALSE} ] ; then
                echo "The VNC server for display ${DISPLAY_NUMBER} is not running."
              else
	        if  [ "${__USERID}"x != "${VNC_USER}"x ] ; then
		  echo "ERROR: The VNC server for display ${DISPLAY_NUMBER} is owned by ${VNC_USER} (You are ${__USERID})"
		  echo "       Can NOT stop that VNC server."
                else
                  echo "Stopping the VNC server for display ${DISPLAY_NUMBER} ..." ;
                  vncserver -kill :${DISPLAY_NUMBER} 
		fi
              fi

              if [ ${SSH_ALREADY_RUNNING} = ${__FALSE} ] ; then
                echo "the ssh process for display ${DISPLAY_NUMBER} is not running."       
              else
	        if  [ "${__USERID}"x != "${SSH_USER}"x ] ; then
		  echo "ERROR: The ssh for display ${DISPLAY_NUMBER} is owned by ${SSH_USER} (You are ${__USERID})."
		  echo "       Can NOT stop that ssh."
                else
                  echo "Stopping ssh ..."   
                  kill -15 ${SSH_PID}
                fi
              fi
              ;;
 

   "status" ) if [ ${VNC_ALREADY_RUNNING} = ${__TRUE} ] ; then
                echo "The VNC server for display ${DISPLAY_NUMBER} is running; the PID is ${VNC_PID}; user id is ${VNC_USER} (Geometry: ${VNC_GEOMETRY})."
              else
                echo "The VNC server for display ${DISPLAY_NUMBER} is not running."
              fi

              if [ ${SSH_ALREADY_RUNNING} = ${__TRUE} ] ; then
                echo "ssh for display ${DISPLAY_NUMBER} is already running; the PID is ${SSH_PID}; user id is ${SSH_USER}."
              else
                echo "ssh for display ${DISPLAY_NUMBER} is not running."       
              fi
              ;;

   "statusall" ) 
              echo "Retrieving the status of all running secure VNC servers ..."
              for DISPLAY_NUMBER in 1 2 3 4 5 6 7 8 9 ; do
                (( VNC_PORT=5900 + ${DISPLAY_NUMBER} ))         
                (( INCOMING_PORT = 7900 + ${DISPLAY_NUMBER} ))
                CheckVNCStatus ${DISPLAY_NUMBER} ${INCOMING_PORT} ${VNC_PORT}

                if [ ${VNC_ALREADY_RUNNING} = ${__TRUE} ] ; then              
  	          echo "The VNC server for display ${DISPLAY_NUMBER} is running; the PID is ${VNC_PID}; user id is ${VNC_USER} (Geometry: ${VNC_GEOMETRY})."
                else
                  echo "The VNC server for display ${DISPLAY_NUMBER} is not running."
                fi

                if [ ${SSH_ALREADY_RUNNING} = ${__TRUE} ] ; then
                  echo "ssh for display ${DISPLAY_NUMBER} is already running; the PID is ${SSH_PID}; user id is ${SSH_USER}."
                else
                  echo "ssh for display ${DISPLAY_NUMBER} is not running."       
                fi
		   
               done
              ;;
	      

          * ) echo "ERROR: Invalid parameter found: \"${ACTION}\" "
              PrintUsage
              exit 1
              ;;


  esac
