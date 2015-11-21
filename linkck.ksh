#!/bin/ksh
#
# $Id: linkck,v 2.8 2004/04/18 04:53:29 marnold Exp $
#
# Solaris Ethernet Link Checker
#     Prints the configuration of the interface instance and the
#     status of the link.
#
AUTHOR="Mike Arnold <mike at razorsedge dot org>"
VERSION=200404150502
# http://www.razorsedge.org/~mike/software/linkck/
#
# Tested with bge, ce, dmfe, eri, ge, hme, le, and qfe.
#
# ce inspiration from James Council's improvements to Paul Bates' nicstatus.txt
#
if [ $DEBUG ]; then set -x; fi
PATH=/usr/xpg4/bin:/usr/bin:/usr/sbin:/sbin:$PATH

## Check for root priv's
#if [[ `/usr/xpg4/bin/id -u` -ne 0 ]]; then
#  echo " You must have root priviledges to run this program."
#  exit 2
#fi

# Check for root priv's
if [[ `/usr/bin/id | awk -F= '{print $2}' | awk -F"(" '{print $1}' 2>/dev/null` -ne 0 ]]; then
  echo " You must have root priviledges to run this program."
  exit 2
fi

# Function to query the device driver or stats and pretty-print the results.
query_print () {
  local TYPE="$1"
  local DRIVER_VAR="$2"
  local LINEPRE="$3"
  local VARM="$4";  local LINEM="$5"
  local VARJ="$6";  local LINEJ="$7"
  local VARA="$8";  local LINEA="$9"
  if [[ $TYPE = ndd ]]; then
    local RESULT=`ndd /dev/$DEV $DRIVER_VAR`
  elif [[ $TYPE = netstat ]]; then
    local RESULT=`echo "$NETSTAT" | awk '{for (i=1; i<=NF; ++i) {if ($i == "'$DRIVER_VAR'") {print $(i+1)}}}'`
  fi
  if [[ $RESULT -eq $VARM ]]; then
    echo "${LINEPRE}${LINEM}"
    return 0
  elif [[ $RESULT -eq $VARJ ]]; then
    echo "${LINEPRE}${LINEJ}"
    return 1
  elif [[ $RESULT -eq $VARA ]]; then
    echo "${LINEPRE}${LINEA}"
    return 2
  fi
}

# Function to compare a version string and return =(0), >(1), or <(2).
version_chk () {
  CURRENT=$1
  BASELINE=$2
  IFSTMP="$IFS"; IFS="."
  set $CURRENT
  # Think SCCS
  C_RELEASE=${1:-0}; C_LEVEL=${2:-0}; C_BRANCH=${3:-0}; C_SEQUENCE=${4:-0}
  set $BASELINE
  # Think SCCS
  B_RELEASE=${1:-0}; B_LEVEL=${2:-0}; B_BRANCH=${3:-0}; B_SEQUENCE=${4:-0}
  IFS="$IFSTMP"
  # return =(0), >(1), or <(2).
  if [[ "$C_RELEASE" -eq "$B_RELEASE" && \
        "$C_LEVEL" -eq "$B_LEVEL" && \
        "$C_BRANCH" -eq "$B_BRANCH" && \
        "$C_SEQUENCE" -eq "$B_SEQUENCE" ]]; then return 0
  fi
  if   [[ "$C_RELEASE" -gt "$B_RELEASE" ]]; then return 1
  elif [[ "$C_LEVEL" -gt "$B_LEVEL" ]]; then return 1
  elif [[ "$C_BRANCH" -gt "$B_BRANCH" ]]; then return 1
  elif [[ "$C_SEQUENCE" -gt "$B_SEQUENCE" ]]; then return 1
  fi
  if   [[ "$C_RELEASE" -lt "$B_RELEASE" ]]; then return 2
  elif [[ "$C_LEVEL" -lt "$B_LEVEL" ]]; then return 2
  elif [[ "$C_BRANCH" -lt "$B_BRANCH" ]]; then return 2
  elif [[ "$C_SEQUENCE" -lt "$B_SEQUENCE" ]]; then return 2
  fi
  return 5
}

# Function that returns the interface instance.
which_inst () {
  case $1 in
    bge*)  echo $1 | sed 's/bge//';;
    ce*)   echo $1 | sed 's/ce//';;
    dmfe*) echo $1 | sed 's/dmfe//';;
    eri*)  echo $1 | sed 's/eri//';;
    ge*)   echo $1 | sed 's/ge//';;
    hme*)  echo $1 | sed 's/hme//';;
    le*)   echo $1 | sed 's/le//';;
    qfe*)  echo $1 | sed 's/qfe//';;
  esac
}

# Function to test the output of which_inst and make sure it is correct.
sanity_chk () {
  echo "$INST" | grep -v "[^0-9]" > /dev/null 2>&1
  # If value returned is not a numeral, exit.
  if [[ $? -eq 1 ]]; then
    echo "Invalid argument: Device instance is not numeric."
    exit 3
  fi
  # If value returned is null, exit.
  if [[ -z "$INST" ]]; then
    echo "Invalid argument: Device instance is null."
    exit 4
  fi
  case $DEV in
    bge*|dmfe*)
      ndd /dev/$DEV link_status 2>&1 | grep ^[01] > /dev/null 2>&1
      # If not a 0 or 1 output from ndd, exit.
      if [[ $? -ne 0 ]]; then
        echo "Invalid interface instance: Do you have one of those?"
        exit 5
      fi
      ;;
    le)
      ifconfig -a | grep "^$DEV" > /dev/null 2>&1
      # If interface is not present, exit.
      if [[ $? -ne 0 ]]; then
        echo "Invalid interface instance: Do you have one of those?"
        exit 5
      fi
      ;;
    *)
      ndd -set /dev/$DEV instance $INST 2>&1 | grep . > /dev/null 2>&1
      # If any output from ndd, exit.
      if [[ $? -eq 0 ]]; then
        echo "Invalid interface instance: Do you have one of those?"
        exit 5
      fi
      ;;
  esac
}

# Function to consolidate the repetitions in the drivers.
print_head () {
  echo "Checking ${DEV}${INST}: "
  case $DEV in
    ge) query_print ndd adv_1000autoneg_cap " Autonegotiation capability is " 0 off 1 on;;
     *) query_print ndd adv_autoneg_cap " Autonegotiation capability is " 0 off 1 on;;
  esac
}

# Function to consolidate the repetitions in the gig ethernet drivers.
print_gigeth () {
  query_print ndd adv_1000fdx_cap " 1000 Mbps Full Duplex capability is " 0 off 1 on
  query_print ndd adv_1000hdx_cap " 1000 Mbps Half Duplex capability is " 0 off 1 on
}

# Function to consolidate the repetitions in the fast ethernet drivers.
print_fasteth () {
  query_print ndd adv_100fdx_cap " 100 Mbps Full Duplex capability is " 0 off 1 on
  query_print ndd adv_100hdx_cap " 100 Mbps Half Duplex capability is " 0 off 1 on
  query_print ndd adv_10fdx_cap " 10 Mbps Full Duplex capability is " 0 off 1 on
  query_print ndd adv_10hdx_cap " 10 Mbps Half Duplex capability is " 0 off 1 on
}

# Function to consolidate the repetitions in the gig ethernet drivers.
print_gigpause () {
  case $DEV in
    bge*|ce)
      if [[ $DEV = bge* ]]; then
        ASMPAUSE=`ndd /dev/$DEV adv_asym_pause_cap`
        PAUSE=`ndd /dev/$DEV adv_pause_cap`
      elif [[ $DEV = ce ]]; then
        ASMPAUSE=`ndd /dev/$DEV adv_asmpause_cap`
        PAUSE=`ndd /dev/$DEV adv_pause_cap`
      fi
      # http://docs.sun.com/db/doc/816-2351-10/6m8n54s3b?a=view
      if [[ $ASMPAUSE -eq 0 && $PAUSE -eq 0 ]]; then
        echo " Pause TX capability is negotiated on"
        echo " Pause RX capability is negotiated on"
      elif [[ $ASMPAUSE -eq 0 && $PAUSE -eq 1 ]]; then
        echo " Pause TX capability is forced on"
        echo " Pause RX capability is forced on"
      elif [[ $ASMPAUSE -eq 1 && $PAUSE -eq 0 ]]; then
        echo " Pause TX capability is forced on"
        echo " Pause RX capability is forced off"
      elif [[ $ASMPAUSE -eq 1 && $PAUSE -eq 1 ]]; then
        echo " Pause TX capability is forced off"
        echo " Pause RX capability is forced on"
      fi
      if [[ $DEV = ce ]]; then
        # http://sunsolve.sun.com/pub-cgi/retrieve.pl?doc=finfodoc/41665
        version_chk `modinfo | awk '/CE Ethernet Driver/{print $NF}' | sed -e 's/v//' -e 's/)//'` 1.118
        # if the result is less than(2) or equal to(0)
        if [[ $? -eq 2 || $? -eq 0 ]]; then
          query_print ndd link_master " Link master is " 0 off 1 on
        elif [[ $? -eq 1 ]]; then
          #query_print ndd master_cfg_enable " Link master config is " 0 disabled 1 enabled
          query_print ndd master_cfg_value " Link master is " 0 off 1 on
        fi
      # This does not seem to be supported...
      #elif [[ $DEV = bge* ]]; then
        #query_print ndd master_cfg_enable " Link master config is " 0 disabled 1 enabled
        #query_print ndd master_cfg_value " Link master is " 0 off 1 on
      fi
      ;;
    ge)
      query_print ndd adv_pauseTX " Pause TX capability is " 0 off 1 on
      query_print ndd adv_pauseRX " Pause RX capability is " 0 off 1 on
      ;;
  esac
}

# Function to print link information of the interface.
print_link () {
  case $DEV in
    bge*)
      # Don't bother to print link speed or mode if the status is "down".
      if query_print ndd link_status " Link Status is " 0 down 1 up; then return; fi
      query_print ndd link_speed " Link Speed is " 10 "10 Mbps" 100 "100 Mbps" 1000 "1000 Mbps"
      # See Sun Info Doc 70401 and Bug ID 4982182
      #mja /usr/bin/kstat -p bge:0::duplex   /actual duplex setting, full or half/
      query_print ndd link_duplex " Link Mode is " 0 "Half Duplex" 1 "Full Duplex" 2 "Full Duplex "
      ;;
    ce)
      NETSTAT=`netstat -k ${DEV}${INST}`
      query_print netstat link_T4 " 100BASE-T4 capability is " 0 off 1 on
      # Don't bother to print link speed or mode if the status is "down".
      if query_print netstat link_up " Link Status is " 0 down 1 up; then return; fi
      query_print netstat link_speed " Link Speed is " 10 "10 Mbps" 100 "100 Mbps" 1000 "1000 Mbps"
      query_print netstat link_duplex " Link Mode is " 1 "Half Duplex" 2 "Full Duplex"
      ;;
    *)
      # Don't bother to print link speed or mode if the status is "down".
      if query_print ndd link_status " Link Status is " 0 down 1 up; then return; fi
      case $DEV in
        ge) query_print ndd link_speed " Link Speed is " 0 "0 Mbps" 1000 "1000 Mbps";;
        dmfe*) query_print ndd link_speed " Link Speed is " 10 "10 Mbps" 100 "100 Mbps";;
        *)  query_print ndd link_speed " Link Speed is " 0 "10 Mbps" 1 "100 Mbps";;
      esac
      query_print ndd link_mode " Link Mode is " 0 "Half Duplex" 1 "Full Duplex"
      ;;
  esac
}

# Function to print the help screen.
print_help () {
  echo "Usage: `basename $0` <interface>"
  echo "       `basename $0` [-h|--help]"
  echo "       `basename $0` [-v|--version]"
  echo "   ex. `basename $0` hme1"
  echo "   Only bge, ce, dmfe, eri, ge, hme, le, and qfe are supported."
  exit 1
}

# If the variable DEBUG is set, then turn on tracing.
# http://www.research.att.com/lists/ast-users/2003/05/msg00009.html
if [ $DEBUG ]; then
  # This will turn on the ksh xtrace option for mainline code
  set -x

  # This will turn on the ksh xtrace option for all functions
  typeset +f |
  while read F junk
  do
    typeset -ft $F
  done
  unset F junk
fi

# Figure out what we have been fed and act.
case $1 in
  bge*) # SunFire v210, v240, v250, Blade 1500, Blade 2500
    DEV=$1
    INST=`which_inst $1`
    sanity_chk
    unset INST
    print_head
    print_gigeth
    print_fasteth
    print_gigpause
    print_link
    ;;
  ce*) # SunFire v440, v480, v1280
    DEV=ce
    INST=`which_inst $1`
    sanity_chk
    print_head
    print_gigeth
    print_fasteth
    print_gigpause
    print_link
    ;;
  dmfe*) # SunFire v100
    DEV=$1
    INST=`which_inst $1`
    sanity_chk
    unset INST
    print_head
    print_fasteth
    print_link
    ;;
  eri*) # SunBlade 100, 150, SunFire v120, 280R, v880
    DEV=eri
    INST=`which_inst $1`
    sanity_chk
    print_head
    print_fasteth
    print_link
    ;;
  ge*) # Add-in sBus, PCI, and cPCI cards, SunFire v880
    DEV=ge
    INST=`which_inst $1`
    sanity_chk
    print_head
    print_gigeth
    print_gigpause
    print_link
    ;;
  hme*) # Most Ultra and Ultra Enterprise
    DEV=hme
    INST=`which_inst $1`
    sanity_chk
    print_head
    print_fasteth
    query_print ndd adv_100T4_cap " 100BASE-T4 capability is " 0 off 1 on
    query_print ndd use_int_xcvr " Force Internal Transceiver option is " 0 off 1 on
    query_print ndd transceiver_inuse "" 0 " Internal Transceiver is in use" 1 " External Transceiver is in use"
    print_link
    ;;
  le*) # Ultra 1
    DEV=le
    INST=`which_inst $1`
    sanity_chk
    # The le driver is 10 Mbps, Half Duplex only.
    echo "Checking ${DEV}${INST}: "
    echo "Link Status is unknown (check the LED)"
    echo "Link Speed is 10 Mbps"
    echo "Link Mode is Half Duplex"
    ;;
  qfe*) # Add-in sBus, PCI, and cPCI card
    DEV=qfe
    INST=`which_inst $1`
    sanity_chk
    print_head
    print_fasteth
    print_link
    ;;
  -h|--help)
    print_help
    ;;
  -v|--version)
    echo "\tSolaris Ethernet Link Checker"
    echo "\tVersion: $VERSION"
    echo "\tWritten by: $AUTHOR"
    echo "\thttp://www.razorsedge.org/~mike/software/linkck/"
    exit 0
    ;;
  *)
    print_help
    ;;
esac
exit 0
