#!/bin/ksh
#set -xv
#
# nic_check
# v1.0 - 01/12/2001 - David Cashion - initial script
# v1.1 - 11/06/2002 - David Cashion - added ability to look at all interfaces
#                                     or just the one specified
# v1.2 - 09/30/2004 - David Cashion - updated to work with ce, ge, bge, dmfe
#                   - Scott Kampen    and added autoneg link partner check
#
# Polls the interfaces specified (or all of them with exception of loX)
# for speed, link, duplex, autonegotiation of link partner, and what its
# highest speed/duplex setting is.

export PATH=/usr/sbin:/usr/bin:$PATH

WHOISTHIS=$(id | awk -F= '{print $2}' | awk -F\( '{print $1}')
if [ $WHOISTHIS -ne 0 ]; then 
        echo "Must be root to run $0." 
        exit 1
fi

#### Pick the interface given or run through all of them (except lo)
if [ $# -eq 1 ]; then
   if [ $1 == "-all" ]; then
        LISTOFNICS=$(ifconfig -a | awk -F: '/^[^l\t][^o]/ {print $1}' | sort -u)
   else
        LISTOFNICS=$1
   fi
else
   print "USAGE:"
   print "\t$0 INTERFACEinstance"
   print "\t$0 -all"
   print "\n\tExample: $0 hme0"
   exit 1
fi         


print "Interface\tLink\tSpeed\tDuplex\tLink Partner Autoneg\tLP Setting"
print "_________\t____\t_____\t______\t____________________\t__________"

for NIC in $LISTOFNICS
   do
   LPSETTING='N/A'
   # We now have "special" cases for each new interface, ick
   
   case $NIC in
      ce*)
        #### GigaSwift Ethernet
        INTERFACE=$(print ${NIC%?})
        INT_INST=$(print ${NIC#??})
        
        if [ $(kstat -p $INTERFACE:$INT_INST:$NIC:link_up | awk '{print $2}') -eq 0 ]; then
           STATUS=DOWN; SPEED='N/A'; DUPLEX='N/A'; AUTONEG='N/A       '; LPSETTING='N/A'
        else 
           STATUS=UP
           DUPLEX=$(kstat -p $INTERFACE:$INT_INST:$NIC:link_duplex | awk '{print $2}')
           case $DUPLEX in
                1) DUPLEX=HALF ;;
                2) DUPLEX=FULL ;;
                *) DUPLEX=DOWN ;;
           esac
           SPEED=$(kstat -p $INTERFACE:$INT_INST:$NIC:link_speed | awk '{print $2}')
           [ $(kstat -p $INTERFACE:$INT_INST:$NIC:lp_cap_autoneg | awk '{print $2}') -eq 0 ] && AUTONEG=DISABLED || AUTONEG="ENABLED "
        
           [ $(kstat -p $INTERFACE:$INT_INST:$NIC:lp_cap_10hdx | awk '{print $2}') -eq 1 ] && LPSETTING=10_HALF
           [ $(kstat -p $INTERFACE:$INT_INST:$NIC:lp_cap_10fdx | awk '{print $2}') -eq 1 ] && LPSETTING=10_FULL
           [ $(kstat -p $INTERFACE:$INT_INST:$NIC:lp_cap_100hdx | awk '{print $2}') -eq 1 ] && LPSETTING=100_HALF
           [ $(kstat -p $INTERFACE:$INT_INST:$NIC:lp_cap_100fdx | awk '{print $2}') -eq 1 ] && LPSETTING=100_FULL
           [ $(kstat -p $INTERFACE:$INT_INST:$NIC:lp_cap_1000hdx | awk '{print $2}') -eq 1 ] && LPSETTING=1000_HALF
           [ $(kstat -p $INTERFACE:$INT_INST:$NIC:lp_cap_1000fdx | awk '{print $2}') -eq 1 ] && LPSETTING=1000_FULL
        fi
        ;;
      
      ge*)
        #### Gigabit Ethernet - v880, fiber
        INTERFACE=$(print ${NIC%?})
        INT_INST=$(print ${NIC#??})
        ndd -set /dev/$INTERFACE instance $INT_INST
        if [ $? -ne 0 ]; then
           print "ERROR: Problems setting instance number for $NIC"
           break
        fi
        
        if [ $(ndd /dev/$INTERFACE link_status) -eq 0 ]; then
           STATUS=DOWN; SPEED='N/A'; DUPLEX='N/A'; AUTONEG='N/A       '; LPSETTING='N/A'
        else
           STATUS=UP
           [ $(ndd /dev/$INTERFACE link_mode) -eq 0 ] && DUPLEX=HALF || DUPLEX=FULL
           SPEED=$(ndd /dev/$INTERFACE link_speed | sed q)
           [ $(ndd /dev/$INTERFACE lp_1000autoneg_cap) -eq 0 ] && AUTONEG=DISABLED || AUTONEG="ENABLED "

           [ $(ndd /dev/$INTERFACE lp_1000hdx_cap) -eq 1 ] && LPSETTING=1000_HALF
           [ $(ndd /dev/$INTERFACE lp_1000fdx_cap) -eq 1 ] && LPSETTING=1000_FULL
        fi
        ;;
        
      bge*) 
        #### Gigabit Ethernet - quad onboard - v210 and v240
        if [ $(ndd /dev/$NIC link_status) -eq 0 ]; then 
           STATUS=DOWN; SPEED='N/A'; DUPLEX='N/A'; AUTONEG='N/A       '; LPSETTING='N/A'
        else
           STATUS=UP
           [ $(ndd /dev/$NIC link_duplex) -eq 0 ] && DUPLEX=HALF || DUPLEX=FULL
           SPEED=$(ndd /dev/$NIC link_speed)
           AUTONEG="UNKNOWN "
           LPSETTING="UNKNOWN "
        fi
        ;;
        
      dmfe*)
        #### Fast Ethernet - v100
        if [ $(ndd /dev/$NIC link_status) -eq 0 ]; then
           STATUS=DOWN; SPEED='N/A'; DUPLEX='N/A'; AUTONEG='N/A       '; LPSETTING='N/A'
        else 
           STATUS=UP
           [ $(ndd /dev/$NIC link_mode) -eq 0 ] && DUPLEX=HALF || DUPLEX=FULL
           SPEED=$(ndd /dev/$NIC link_speed)
           [ $(ndd /dev/$NIC lp_autoneg_cap) -eq 0 ] && AUTONEG=DISABLED || AUTONEG="ENABLED "
        
           [ $(ndd /dev/$NIC lp_10hdx_cap) -eq 1 ] && LPSETTING=10_HALF
           [ $(ndd /dev/$NIC lp_10fdx_cap) -eq 1 ] && LPSETTING=10_FULL
           [ $(ndd /dev/$NIC lp_100hdx_cap) -eq 1 ] && LPSETTING=100_HALF
           [ $(ndd /dev/$NIC lp_100fdx_cap) -eq 1 ] && LPSETTING=100_FULL
        fi
        ;;
        
      *)
        # Should catch everything else like hme, qfe, eri.
        INTERFACE=$(print ${NIC%?})
        INT_INST=$(print ${NIC#???})
        
        ndd -set /dev/$INTERFACE instance $INT_INST
        if [ $? -ne 0 ]; then
           print "ERROR: Problems setting instance number for $NIC"
           break
        fi
        
        if [ $(ndd /dev/$INTERFACE link_status) -eq 0 ]; then
           STATUS=DOWN; SPEED='N/A'; DUPLEX='N/A'; AUTONEG='N/A       '; LPSETTING='N/A'
        else
           STATUS=UP
           [ $(ndd /dev/$INTERFACE link_mode) -eq 0 ] && DUPLEX=HALF || DUPLEX=FULL
           [ $(ndd /dev/$INTERFACE link_speed) -eq 0 ] && SPEED=10 || SPEED=100
        
           #### Determine if the link partner (switch / router) has autonegotiation capability enabled or not
           case $NIC in
              hme*) [ $(ndd /dev/hme lp_autoneg_cap) -eq 0 ] && AUTONEG=DISABLED || AUTONEG="ENABLED " ;;
              qfe*) [ $(ndd /dev/qfe lp_autoneg_cap) -eq 0 ] && AUTONEG=DISABLED || AUTONEG="ENABLED " ;;
              eri*) [ $(ndd /dev/eri lp_autoneg_cap) -eq 0 ] && AUTONEG=DISABLED || AUTONEG="ENABLED " ;;
              *) AUTONEG="UNKNOWN " ;;
           esac
        
           [ $(ndd /dev/$INTERFACE lp_10hdx_cap) -eq 1 ] && LPSETTING=10_HALF
           [ $(ndd /dev/$INTERFACE lp_10fdx_cap) -eq 1 ] && LPSETTING=10_FULL
           [ $(ndd /dev/$INTERFACE lp_100hdx_cap) -eq 1 ] && LPSETTING=100_HALF
           [ $(ndd /dev/$INTERFACE lp_100fdx_cap) -eq 1 ] && LPSETTING=100_FULL
        fi
        ;;
   esac
   print "$NIC\t\t$STATUS\t$SPEED\t$DUPLEX\t$AUTONEG\t\t$LPSETTING"
done
