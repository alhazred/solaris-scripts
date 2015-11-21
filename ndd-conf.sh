#!/bin/sh
PATH=/usr/bin:/usr/sbin; export PATH

############ Komponents ########################
cards="le hme qfe ge ce eri bge dmfe"
# all network cards="le hme ba qe qfe ge nf idn ce eri bge dmfe"
servcard="le hme ba qe qfe ge ce nf idn vge eri bge dmfe"
# notify card: vge, dmfe  are only supported in services : servcard

service="ip tcp udp icmp arp"
INSTANCE="25"
MAXINSTANCE=`echo "$INSTANCE" | awk 'BEGIN{s="";}{ for(i=0;i<=$1;i++){s=s" "i;} }END{print s}'`

############ VARIABLES ########
CONFDIR="/opt/SUNWndd"
CONFDAT="$CONFDIR/ndd.conf"
DEBUG="0"
ERRHOSTS="1"
ERRNETSTAT="1"
ERRNFS="1"
ERRTRUNKING="1"
SYSLOG="1"
# SYSLOGFILE=/var/adm/network
SYSLOGFILE=/var/adm/messages

######### START OF VERSION INFORMATION ###############################
# v1.0    - start Option with basics interface
# v1.1    - modify run Options, BUG with lp_asmpause with module ge
# v1.3    - include netstat information in option service
#         - include Option check
# v1.4    - change Option check, now includes first networkcheck : netstat -k
#         - integrate first file sys loging in option check
# v1.5    - change Option check, now includes first networkcheck : netstat -pn
#         - add GigaSwift network card
# v1.5.1  - add eri network card
# v1.5.2  - make modify in module netstat -pn  look for more interfaces 
#         - change module syslog - now to ways for sysloging - over logger and over file
#         - insert in option check and read the driver information
# v1.6    - integrate a new diagnostic parameter in module ge (lp_pause_cap)
#         - change default network card to hme qfe ge ce eri, all other doesn't have ndd-parameteres
#         - change option service, now integrate the driver version in ndd.out
# v1.7    - change Output from ndd in option read and check  - add linkinfos and spezial settings, defaults.
# v1.7.1  - change MAXINSTANCE, increase it for SunFire machines eri interfaces
# v1.7.2  - change Option read - Bug in Part lp_pause_cap  - 
# v1.7.3  - integrate the SUN Alert : autonegosation  
# v1.7.4  - change option write : when can't read from remote, use local settings as default, optimize remote_check for module ce 
# v1.7.5  - make changes for solaris 9 
#	  - include dmfe interface in option service
#	  - select hw-path from /etc/path_to_inst and give out in option service and check
# v1.8	  - integrate rfe spezify a interface in all options
# 	  - integrate a install and uninstall option
#         - integrate a checkmodule for SUN trunking
# v1.8.1  - integrate in option service ba,nf interface, x25 config and hippi
# v1.8.2  - integrate pause_cap,asm_dir_cap for the ge module in option check and read
# v1.8.3  - change same outpute in read and check for card typs ge and ce
# v1.8.4  - add bge,dmfe interface in option service
# v2.0    - integrate a installation check and a link check mode in option check
#	  - change output in option service for better read
#	  - integate a full support for interfaces dmfe and bge
# v2.0.1  - integrate bug 1043 (-c not consitent to check)
#	  - integrate bug 1044 (kernelinfo in  module net only as root)
# v2.0.2  - integrate bug 1051 (wrong output in patchinfo and lp_ parameter for dmfe in option read)
#
######### END OF VERSION INFORMATION #################################

########### FIXES AND TEMPORAERES #######
TMPNDD=/tmp/ndd.new.$$
MODNDD=/tmp/ndd.mod.$$
HOSTNAME=`uname -n`
OS=`uname -r`
MINOROS=`echo $OS | awk 'BEGIN{FS="."}{print $NF}' `
MAJOROS=`echo $OS | awk 'BEGIN{FS="."}{print $1}' `
VERSION="2.0.1" 
DATE=`date | awk '{print $2" "$3" "$4}'`

#need space before and after
INFNET=" ce "
INFNDD=" le hme qfe ge eri "
INFETH=" bge dmfe "

######### funktionen #################
die()
{
    echo "$0: $*"
    exit 1
}

check_remote()
{
 touch /tmp/$$.out
 rm /tmp/$$.out
 if [ "$CARDTYP" -le 1 ]; then
 	ndd /dev/$mod \? | grep lp_ | while read parm rest; do 
   		ndd /dev/$mod $parm >> /tmp/$$.out 
 	done
  else
        ndd /dev/$mod$inst \? | grep lp_ | while read parm rest; do
                ndd /dev/$mod$inst $parm >> /tmp/$$.out
        done
 fi
 REMOTE=`grep "1" /tmp/$$.out 2>/dev/null | awk 'BEGIN{s=0}{s=1}END{print s}' `
 if [ $DEBUG = "1" ]; then echo $REMOTE ; fi
 rm /tmp/$$.out 2>/dev/null
}

check_remote1()
{
 REMOTE=`grep lp_ $NETCARD | awk 'BEGIN{t=0} { for(i=1;i<=NF;i++){ if($i=="1"){t=t+1} } } END{print t}' `
 if [ "$REMOTE" != "0" ]; then REMOTE="1" ; fi
 if [ $DEBUG = "1" ]; then echo $REMOTE ; fi
}

check_active()
{
 AKTIVCARD=""
 if [ "xx$RUN" != "xxSERVICE" ]; then SCARD="$cards"; 
  else SCARD="$servcard"; fi
 for mod in $SCARD; do
     if [ $DEBUG = "1" ]; then echo "test $mod" ; fi
     # ndd -set /dev/$mod instance 0 2>&1 | egrep -s -e "couldn't push"
     ndd -set /dev/$mod instance 0 >/dev/null 2>&1
     if [ "$?" != 1 ]; then
       AKTIVCARD=`echo $AKTIVCARD $mod`
       if [ $DEBUG = "1" ]; then echo "+$AKTIVCARD+"; fi
      else
	if [ `ls -l /dev/$mod* 2>/dev/null | awk 'BEGIN{s=0}{s++}END{print s}' ` -ge 2 ]; then
	   AKTIVCARD=`echo $AKTIVCARD $mod`
	   if [ $DEBUG = "1" ]; then echo "+$AKTIVCARD+"; fi
	fi
     fi
 done
 if [ $DEBUG = "1" ]; then echo $AKTIVCARD; fi
}

read_param()
{
  RUN="READ"; check_active
  if [ $DEBUG = "1" ]; then echo $AKTIVCARD; fi
  if [ "$AKTIVCARD" = "" ]; then 
        if [ "$TINF" = "" ]; then
                 die "no network-adapter work with the program ndd"; 
         else
                echo "ndd-info: no instance of $TINF found\n"
        fi
  fi
  for mod in $AKTIVCARD; do
      CARDTYP="0"
      TEST=` echo "$INFNET" | grep " $mod " | awk 'BEGIN{s=0}{s++}END{print s}'`
      if [ "$TEST" -ge 1 ]; then
                        # ce Interface
                        CARDTYP="2"
      fi
      TEST=` echo "$INFNDD" | grep " $mod " | awk 'BEGIN{s=0}{s++}END{print s}'`
      if [ "$TEST" -ge 1 ]; then
                        # standard ndd interface hme
                        CARDTYP="1"
      fi
      TEST=` echo "$INFETH" | grep " $mod " | awk 'BEGIN{s=0}{s++}END{print s}'`
      if [ "$TEST" -ge 1 ]; then
                        # interface bge dmfe
                        CARDTYP="3"
      fi

     echo " "
     echo "--------------------------------------------------------------------"
     echo "look for active card configuration for modules:  $mod "
     cardvers=`modinfo | grep " $mod" | awk '{print $6" "$7" "$8" "$9" " $10" "$11" "$12}' `
     if [ "$cardvers" = "" ]; then
      if [ -r /kernel/drv/$mod ]; then
     	cardvers=`strings /kernel/drv/$mod | grep -i "Ethernet" | grep -v [:,?,=] 2>/dev/null `
       else
	cardvers=`modinfo | grep -i ethernet | awk '{print $6" "$7" "$8" "$9" " $10" "$11" "$12}' | grep "^$mod" `
      fi
     fi
     if [ "xx$cardvers" != "xx" ]; then echo "device driver :\t $cardvers"; fi
     echo "(no more output - card does not work with ndd) "
     echo "--------------------------------------------------------------------"
     patchinfo


   case "$CARDTYP" in 
    '1' )
        if [ $DEBUG = "1" ]; then     echo "$mod - ndd" ; fi
        for inst in $MAXINSTANCE; do
         ndd -set /dev/$mod instance $inst 2>&1 | egrep -s -e "operation failed"
         if [ "$?" = 0 ]; then
            if [ $DEBUG = "1" ]; then echo "$mod$inst do not work" ; fi
            continue;
         fi
         echo " "
         check_remote 
         if [ $DEBUG = "1" ]; then echo $REMOTE; fi
         if [ $REMOTE = "1" ]; then 
           echo "\nconfiguration for : $mod$inst"
          else 
           echo "\nno remote configuration exist "
           echo "configuration for : $mod$inst"
         fi
          STAT=`ndd -get /dev/$mod link_status 2>/dev/null | awk '{if(NR==1){print $1} }' `
          SPEED=`ndd -get /dev/$mod link_speed 2>/dev/null | awk '{if(NR==1){print $1} }' `
          MODE=`ndd -get /dev/$mod link_mode   2>/dev/null | awk '{if(NR==1){print $1} }' `
          echo "\n\tLink status:\t$STAT, Link speed:\t$SPEED, Link mode:\t$MODE \n"

          echo "Linkoption   \t$mod$inst\tSwitch/HUB\tuse in $CONFDAT"
          echo "--------------------------------------------------------------------"
          ndd /dev/$mod \? | grep lp_ | awk '{print $1}' | while read parm rest; do
           if [ $DEBUG = "1" ]; then echo $parm ; fi
           if [ $parm != "lp_pause_cap" ]; then
            if [ $parm != "lp_asm_dir_cap" ]; then
             loc_str=`echo $parm | nawk '{print substr($1,4,length($1))}' `
             if [ DEBUG = "1" ]; then echo adv_$loc_str ; fi
             adv_str=`ndd /dev/$mod adv_$loc_str`
             rem_str=`ndd /dev/$mod  lp_$loc_str`
             if [ "$mod" = "ge" ] && [ "$loc_str" = "1000autoneg_cap" ]; then
                loc_str=`echo $loc_str | awk '{print substr($1,5,length($1))}' `
             fi 

             if [ $adv_str != $rem_str ]; then
                echo "$loc_str :\t$adv_str \t$rem_str\t\tcard;$mod;$inst;adv_$loc_str;$rem_str"
              else
                echo "$loc_str :\t$adv_str \t$rem_str"
             fi
             else
              rem_str=`ndd /dev/$mod $parm 2>/dev/null `
	      asm=`ndd /dev/$mod asm_dir_cap 2>/dev/null `
	      echo "asm_dir_cap :\t$asm \t$rem_str \t\t[ ONLY A DISPLAY INFORMATION ]"
            fi
           else
             # loc_str=`echo $parm | nawk '{print substr($1,4,length($1))}' `
             rem_str=`ndd /dev/$mod $parm 2>/dev/null `
             ts=`ndd /dev/$mod adv_pauseTX 2>/dev/null `
             tr=`ndd /dev/$mod adv_pauseRX 2>/dev/null `
	     pau=`ndd /dev/$mod pause_cap 2>/dev/null `
	     echo "pause_cap :\t$pau \t$rem_str \t\t[ ONLY A DISPLAY INFORMATION ]"
             echo "adv_pauseTX :\t$ts \t  \t\t[send pause - r/w parameter]"
             echo "adv_pauseRX :\t$tr \t  \t\t[receive pause - r/w parameter ]"
           fi
          done
     done
    ;;
   '2' ) 
     if [ $DEBUG = "1" ]; then echo "$mod -ce netstat-k"; fi
     TMPNK=/tmp/netstat-k
     netstat -k | grep -i "^$mod[0-9][0-9,:]" | awk '{ print substr($1,1,length($1)-1 ) }' \
                | while read card rest; do

       inst=`echo $card | awk '{ print substr($1,3,length($1) ) }' `
       ndd -set /dev/$mod instance $inst 
       echo " "
       NETCARD=/tmp/netstat-k-$card
        netstat -k $card > /tmp/$card
	cat /tmp/$card | awk '{ for(i=1;i<=NF;i++){ print $i" "$(i+1);i++; } }' > $NETCARD

	echo "\nconfiguration for : $mod$inst"

	  MODE=`grep -i link_duplex $NETCARD | awk ' {print $2}' `
	STATUS=`grep -i link_up     $NETCARD | awk ' {print $2}' `
	 SPEED=`grep -i link_speed  $NETCARD | awk ' {print $2}' `

	echo "\n\tLink status:\t$STATUS, Link speed:\t$SPEED, Link mode:\t$MODE \n";

        ceservice="lp_cap_autoneg lp_cap_100T4 lp_cap_1000fdx lp_cap_1000hdx lp_cap_100fdx lp_cap_100hdx lp_cap_10fdx lp_cap_10hdx lp_cap_asmpause lp_cap_pause"

          echo "Linkoption   \t$mod$inst\tSwitch/HUB\tuse in $CONFDAT"
          echo "--------------------------------------------------------------------"
          for parm in $ceservice; do

           if [ $DEBUG = "1" ]; then echo $parm ; fi

             loc_str=`echo $parm | nawk '{print substr($1,8,length($1))"_cap"}' `
             pause=`echo $parm | grep -v "pause" | wc -l | awk '{ print $1 }'  `
             if [ DEBUG = "1" ]; then echo adv_$loc_str ; fi
             adv_str=`ndd /dev/$mod adv_$loc_str`
             rem_str=`grep -i "^$parm "    $NETCARD | awk '{print $2}'`
             if [ $pause -ne 0 ]; then
              if [ $adv_str != $rem_str ]; then
                echo "$loc_str :\t$adv_str \t$rem_str\t\tcard;$mod;$inst;adv_$loc_str;$rem_str"
               else
                echo "$loc_str :\t$adv_str \t$rem_str"
              fi
             else echo "$loc_str :\t$adv_str \t$rem_str\t\t[ ONLY A DISPLAY INFORMATION ]"; fi
          done
     done
     ;;
     '3')  # echo "CARDTYP $CARDTYP "

	   for insti in $MAXINSTANCE; do
		[ "$insti" = "/dev/$mod" ] && continue 
		inst=`echo $insti | awk 'BEGIN{d=""}{s=length($1);for(i=1;i<=s;i++){t=substr($1,i,1);if(t !~ '/[a-z,/]/'){d=d t;} } } END{print d }' `
		SKIP=`echo $MAXINSTANCE $inst | awk 'BEGIN{s=1}{ for(i=i;i<=NF-1;i++){ if($i==$NF){s--;i=NF} } }END{print s}' `
		if [ $SKIP -le 0 ]; then
		   # echo "$insti  $mod $inst"
         		echo " "
         		check_remote
         		if [ $DEBUG = "1" ]; then echo $REMOTE; fi
         		if [ $REMOTE = "1" ]; then
           		 echo "\nconfiguration for : $mod$inst"
          		else
           		 echo "\nno remote configuration exist "
           		 echo "configuration for : $mod$inst"
         		fi
          	  STAT=`ndd -get /dev/$mod$inst link_status 2>/dev/null | awk '{if(NR==1){print $1} }' `
          	 SPEED=`ndd -get /dev/$mod$inst link_speed 2>/dev/null | awk '{if(NR==1){print $1} }' `
		  if [ "$mod" != "dmfe" ]; then
          	     MODE=`ndd -get /dev/$mod$inst link_duplex 2>/dev/null | awk '{if(NR==1){print $1} }'`
		   else
		     MODE=`ndd -get /dev/$mod$inst link_mode 2>/dev/null | awk '{if(NR==1){print $1} }'`
		  fi
          	  echo "\n\tLink status:\t$STAT, Link speed:\t$SPEED, Link mode:\t$MODE "

		   echo " "
		   echo "Linkoption   \t\t$mod$inst\tSwitch/HUB\tuse in $CONFDAT"
          	   echo "--------------------------------------------------------------------"
		   PLIST=`ndd /dev/$mod$inst \? | grep adv_ | awk 'BEGIN{S=""}{S=S" "$1}END{print S}' `
          	   for parm in $PLIST; do

           	   	if [ $DEBUG = "1" ]; then echo $parm ; fi

             		loc_str=`echo $parm | awk 'BEGIN{FS="_"}{s=""; for(i=2;i<=NF;i++){s=s"_"$i} }END{print substr(s,2,length(s))}' `
             		pause=`echo $parm | grep -v "pause" | awk 'BEGIN{s=0}{s++}END{ print s }'  `
             		adv_str=`ndd /dev/$mod$inst $parm `
			rem_str=`ndd /dev/$mod$inst lp_$loc_str 2>/dev/null | awk 'BEGIN{s="N/A"}{if($1=='0' || $1=='1'){s=$1}}END{print s}'`
			if [ "$REMOTE" -eq 1 ]; then
			   if [ "$rem_str" != "$adv_str" ]; then TINFO="card;$mod;$inst;$parm;$rem_str" ; else TINFO=""; fi
			  else TINFO="";
			fi
			LEN=`echo "$loc_str" | awk '{print length($1)}' `
			if [ $LEN -le 13 ]; then
                		echo "$loc_str :\t\t$adv_str \t$rem_str\t\t$TINFO"
			 else
				echo "$loc_str :\t$adv_str \t$rem_str\t\t$TINFO"
			fi
          	  done

		 else 
		   echo "\n\tERROR: instance $MAXINSTANCE of module $mod is not installed or configured yet"
		fi
	   done
     ;;
   esac 
  done
  ls -l /tmp/netstat-k-ce[0-9]* 2>&1 | grep -v "such" | awk '{ print $NF}' | while read pa rest; do rm -r $pa; done
  ls -l /tmp/ce[0-9]*           2>&1 | grep -v "such" | awk '{ print $NF}' | while read pa rest; do rm -r $pa; done

}

write_param()
{
 if [ $DEBUG = "1" ]; then echo "write parameter to $CONFDAT"; fi

 if [ -r $CONFDAT ]; then cp -p $CONFDAT /tmp/ndd.$ ; fi
 touch /tmp/ndd.$
 echo "# ndd.conf were updated : $DATE \tby Version : $VERSION" >> /tmp/ndd.$
 RUN="WRITE"; check_active
 if [ $DEBUG = "1" ]; then echo $AKTIVCARD; fi
 if [ "$AKTIVCARD" = "" ]; then 
        if [ "$TINF" = "" ]; then
                 die "no network-adapter work with the program ndd"; 
         else
                echo "ndd-info: no instance of $TINF found\n"
        fi
 fi

 for mod in $AKTIVCARD; do
      CARDTYP="0"
      TEST=` echo "$INFNET" | grep " $mod " | awk 'BEGIN{s=0}{s++}END{print s}'`
      if [ "$TEST" -ge 1 ]; then
                        # ce Interface
                        CARDTYP="2"
      fi
      TEST=` echo "$INFNDD" | grep " $mod " | awk 'BEGIN{s=0}{s++}END{print s}'`
      if [ "$TEST" -ge 1 ]; then
                        # standard ndd interface hme
                        CARDTYP="1"
      fi
      TEST=` echo "$INFETH" | grep " $mod " | awk 'BEGIN{s=0}{s++}END{print s}'`
      if [ "$TEST" -ge 1 ]; then
                        # interface bge dmfe
                        CARDTYP="3"
      fi
   case "$CARDTYP" in
     '1'|'2')
     for inst in $MAXINSTANCE; do
         ndd -set /dev/$mod instance $inst 2>&1 | egrep -s -e "operation failed"
         if [ "$?" = 0 ]; then
            continue;
         fi
         if [ "$mod" = "ce" ]; then
           card=`echo $mod$inst`
           NETCARD=/tmp/netstat-k-$card
           netstat -k $card > /tmp/$card
	   cat /tmp/$card | awk '{ for(i=1;i<=NF;i++){ print $i" "$(i+1);i++; } }' > $NETCARD
         fi
         echo " "
         echo "read configuration of : $mod$inst "
         echo "----------------------------------------------------------------------------"
         if [ "$mod" != "ce" ]; then check_remote; else check_remote1; fi
         if [ $DEBUG = "1" ]; then echo $REMOTE; fi
         if [ $REMOTE = "0" ]; then echo "no data from remote HUB/SWITCH (use local as default) !" ; fi
         echo "Option\t\t$mod$inst\t\tSwitch/HUB\tset in $CONFDAT"
         echo "----------------------------------------------------------------------------"
         if [ "$mod" != "ce" ]; then 
          ndd /dev/$mod \? | grep lp_ | awk '{print $1}' | while read parm rest; do
           if [ $DEBUG = "1" ]; then echo $parm ; fi
           if [ $parm != "lp_pause_cap" ] ; then
            if [ $parm != "lp_asm_dir_cap" ]; then
              loc_str=`echo $parm | awk '{print substr($1,4,length($1))}' `
              if [ DEBUG = "1" ]; then echo adv_$loc_str ; fi
              adv_str=`ndd /dev/$mod adv_$loc_str`
              rem_str=`ndd /dev/$mod  lp_$loc_str`
              if [ "$mod" = "ge" ] && [ "$loc_str" = "1000autoneg_cap" ]; then
                loc_str=`echo $loc_str | awk '{print substr($1,5,length($1))}' `
              fi 
	      if [ $REMOTE -ge 1 ]; then
                 echo "$loc_str\tlocal:$adv_str \tremote:$rem_str \tcard;$mod;$inst;adv_$loc_str;$rem_str"
                 echo "card;$mod;$inst;adv_$loc_str;$rem_str" 1>>$TMPNDD
	       else
                 echo "$loc_str\tlocal:$adv_str \tremote:$rem_str \tcard;$mod;$inst;adv_$loc_str;$adv_str \t (use current local value)"
                 echo "card;$mod;$inst;adv_$loc_str;$adv_str" 1>>$TMPNDD
	      fi
             else
              rem_str=`ndd /dev/$mod $parm 2>/dev/null `
              echo "$parm :\t   \t$rem_str \t\t[ ONLY A DISPLAY INFORMATION ]"
            fi
           else
             # loc_str=`echo $parm | awk '{print substr($1,4,length($1))}' `
             rem_str=`ndd /dev/$mod $parm 2>/dev/null `
             ts=`ndd /dev/$mod adv_pauseTX 2>/dev/null `
             tr=`ndd /dev/$mod adv_pauseRX 2>/dev/null `
             echo "$parm :\t   \t\t$rem_str \t\t[ ONLY A DISPLAY INFORMATION ]"
             echo "adv_pauseTX :\t$ts \t  \t\t\t[ send pause - r/w parameter]"
             echo "adv_pauseRX :\t$tr \t  \t\t\t[ receive pause - r/w parameter ]"
             
             echo "card;$mod;$inst;adv_pauseTX;$ts" 1>>$TMPNDD
             echo "card;$mod;$inst;adv_pauseRX;$tr" 1>>$TMPNDD
           fi

          done
         else 
          ceservice="lp_cap_autoneg lp_cap_100T4 lp_cap_1000fdx lp_cap_1000hdx lp_cap_100fdx lp_cap_100hdx lp_cap_10fdx lp_cap_10hdx lp_cap_asmpause lp_cap_pause"
          NETCARD=/tmp/netstat-k-$mod$inst
          for parm in $ceservice; do

           if [ $DEBUG = "1" ]; then echo $parm ; fi

             loc_str=`echo $parm | nawk '{print substr($1,8,length($1))"_cap"}' `
             pause=`echo $parm | grep -v "pause" | wc -l | awk '{ print $1 }'  `
             if [ DEBUG = "1" ]; then echo adv_$loc_str ; fi
             if [ $pause -ne 0 ]; then
              adv_str=`ndd /dev/$mod adv_$loc_str`
              rem_str=`grep -i "^$parm "    $NETCARD | awk '{print $2}'`
	      if [ $REMOTE -ge 1 ]; then
                 echo "$loc_str\tlocal:$adv_str \tremote:$rem_str \tcard;$mod;$inst;adv_$loc_str;$rem_str"
                 echo "card;$mod;$inst;adv_$loc_str;$rem_str" 1>>$TMPNDD
		else
                 echo "$loc_str\tlocal:$adv_str \tremote:$rem_str \tcard;$mod;$inst;adv_$loc_str;$adv_str \t (use current local value)"
                 echo "card;$mod;$inst;adv_$loc_str;$adv_str" 1>>$TMPNDD
	      fi
             fi
           done
          fi
     done
     ;;
    '3')
	for inst in $MAXINSTANCE; do
	   if [ ! -r /dev/$mod$inst ]; then continue; fi
           echo " "
           echo "read configuration of : $mod$inst "
           echo "----------------------------------------------------------------------------"
           check_remote
           if [ $DEBUG = "1" ]; then echo $REMOTE; fi
           if [ $REMOTE = "0" ]; then echo "no data from remote HUB/SWITCH (use local as default) !" ; fi
           echo "Option\t\t$mod$inst\t\tSwitch/HUB\tset in $CONFDAT"
           echo "----------------------------------------------------------------------------"
	   ndd -get /dev/$mod$inst \? | grep "adv_" | while read parm rest; do
	      loc_str=`echo "$parm" | awk 'BEGIN{FS="_"}{s=""; for(i=2;i<=NF;i++){s=s"_"$i} }END{print substr(s,2,length(s)) }' `
	      adv_str=`ndd -get /dev/$mod$inst $parm 2>/dev/null | awk '{if(NR=1){print $1} }' `
	      rem_str=`ndd -get /dev/$mod$inst lp_$loc_str 2>/dev/null | awk '{if(NF!=1){print "0"}else{print $1} }' `
              if [ $REMOTE -ge 1 ]; then
                 echo "$loc_str\tlocal:$adv_str \tremote:$rem_str \tcard;$mod;$inst;adv_$loc_str;$rem_str"
                 echo "card;$mod;$inst;adv_$loc_str;$rem_str" 1>>$TMPNDD
                else
                 echo "$loc_str\tlocal:$adv_str \tremote:$rem_str \tcard;$mod;$inst;adv_$loc_str;$adv_str \t (use current local value)"
                 echo "card;$mod;$inst;adv_$loc_str;$adv_str" 1>>$TMPNDD
              fi
           done

	done
    ;;
   esac
     echo " " ; echo " " >> $TMPNDD
 done

 if [ $DEBUG = "1" ]; then echo "new NDD-file!"; fi

 cat /tmp/ndd.$ | grep \# | grep -v "\# all" > $MODNDD
 echo "# all Services  " >> $MODNDD
 cat /tmp/ndd.$ | grep serv | grep -v \# >>$MODNDD
 
 echo "# all Cards  " >> $MODNDD
 RUN=`echo $cards | awk '{print NF}' `
 if [ $RUN -le 1 ]; then
  for mod in $servcard; do
     if [ "$mod" != "$cards" ]; then
        grep "^card;$mod;" /tmp/ndd.$ | grep -v autoneg >>$MODNDD
      else
        grep "^card;$mod;" /tmp/ndd.$ | grep -v autoneg | while read pa rest; do
             inst=`echo $pa | awk 'BEGIN{FS=";"}{print $3}' `
             found=0
             for in in $MAXINSTANCE; do
                 if [ "$in" = "$inst" ]; then found=1; fi
             done
             if [ $found -le 0 ]; then
                echo $pa >>$MODNDD
             fi
        done
     fi 
  done
 fi
 cat $TMPNDD | grep -v "autoneg" >> $MODNDD

 echo "# all Autonegosation as last - handle a Sun Alert " >> $MODNDD
 if [ $RUN -le 1 ]; then
  for mod in $servcard; do
     if [ "$mod" != "$cards" ]; then 
        grep "^card;$mod;" /tmp/ndd.$ | grep autoneg >>$MODNDD
      else
        grep "^card;$mod;" /tmp/ndd.$ | grep autoneg | while read pa rest; do
             inst=`echo $pa | awk 'BEGIN{FS=";"}{print $3}' `
             found=0
             for in in $MAXINSTANCE; do
                 if [ "$in" = "$inst" ]; then found=1; fi
             done
             if [ $found -le 0 ]; then
                echo $pa >>$MODNDD
             fi 
        done
     fi
  done
 fi
 cat $TMPNDD | grep "autoneg" >> $MODNDD

 if [ -f $CONFDAT ]; then cp $CONFDAT $CONFDAT.sav ; fi
 cp $MODNDD $CONFDAT 
 rm /tmp/ndd.$ $TMPNDD $MODNDD
 ls -l /tmp/netstat-k-ce[0-9]* 2>&1| grep -v "such" | awk '{ print $NF}' | while read pa rest; do rm -r $pa; done
 ls -l /tmp/ce[0-9]*    2>&1   | grep -v "such" | awk '{ print $NF}' | while read pa rest; do rm -r $pa; done

}

set_param()
{
 echo "Read $CONFDAT and set these value ... \c"
 if [ $DEBUG -ge 1 ]; then echo "now services" ; fi
 cat $CONFDAT | grep "^serv;" |  while read parm rest; do
    if [ $DEBUG = "1" ]; then echo "set Services"; echo "$parm"; fi
     inf=`echo $parm | awk 'BEGIN {FS=";"} {print $2}' `
    inst=`echo $parm | awk 'BEGIN {FS=";"} {print $3}' `
    para=`echo $parm | awk 'BEGIN {FS=";"} {print $4}' `
    wert=`echo $parm | awk 'BEGIN {FS=";"} {print $5}' `
   
    if [ ` echo "$inf $service" | awk 'BEGIN{s=0;}{t=$1;for(i=2;i<=NF;i++){ if(t==$i){s=1;}} }END{print s}' ` -le 0 ]; then
	ndd -set /dev/$inf instance $inst
    fi
    ndd -set /dev/$inf $para $wert

 done
 if [ $DEBUG -ge 1 ]; then echo "now cards ->$cards<- " ; fi
 cat $CONFDAT | grep "^card;" | while read parm rest; do
    if [ $DEBUG = "1" ]; then echo "set network configuration"; echo "$parm"; fi
     inf=`echo $parm | awk 'BEGIN {FS=";"} {print $2}' `
    inst=`echo $parm | awk 'BEGIN {FS=";"} {print $3}' `
    para=`echo $parm | awk 'BEGIN {FS=";"} {print $4}' `
    wert=`echo $parm | awk 'BEGIN {FS=";"} {print $5}' `
    found=0 
    if [ $DEBUG -ge 1 ]; then 
	echo "FOUND ->$found<- inf->$inf<- inst->$inst<- para->$para<- wert->$wert<-"  
    fi
    if [ "xx$TESTCARD" != "xx" ]; then
      if [ $DEBUG -ge 1 ]; then 
	echo "test $cards - $inf ->echo \"$cards\" | grep \"$inf\" | awk 'BEGIN{s=0}{s++}END{print s}' \c"; 
	echo "$cards" | grep "$inf" | awk 'BEGIN{s=0}{s++}END{print s}'
      fi
      if [ `echo "$cards" | grep "$inf" | awk 'BEGIN{s=0}{s++}END{print s}' ` -ge 1 ]; then
	if [ $DEBUG -ge 1 ]; then echo "found card - check instance" ; fi
	for int in $MAXINSTANCE; do
	    if [ $int -eq $inst ]; then found=1; fi
	done
      fi
     else
      found=1
    fi
    if [ $DEBUG = "1" ]; then echo "FOUND ->$found<- inf->$inf<- inst->$inst<- para->$para<- wert->$wert<-" ; fi
    if [ "$found" -eq 1 ]; then
	CARDTYP=0
	TEST=`echo "$INFNDD $INFNET $inf" | awk '{ s=0; for(i=1;i<=(NF-1);i++){ if($i==$NF){s++;i=NF} } }END{print s}' `
	if [ "$TEST" -eq 1 ]; then CARDTYP="$TEST"; 
	 else
	   TEST=`echo "$INFETH $inf" | awk '{ s=2; for(i=1;i<=(NF-1);i++){ if($i==$NF){s++;i=NF} } }END{print s}' `
	   if [ "$TEST" -eq 3 ]; then CARDTYP="$TEST";  fi
	fi
	if [ $DEBUG -ge 1 ]; then echo "\t cardtype ->$CARDTYP<-"; fi 
        if [ "$CARDTYP" -le 2 ]; then
	   if [ $DEBUG -ge 1 ]; then echo "\n\tset $para to /dev/$inf instance $inst with $wert (cardtyp $CARDTYP)"; fi
    	   ndd -set /dev/$inf instance $inst
    	   ndd -set /dev/$inf $para $wert
	 else
	   if [ $DEBUG -ge 1 ]; then echo "\n\tset $para to /dev/$inf$inst  with $wert (cardtyp $CARDTYP)"; fi
	   ndd -set /dev/$inf$inst $para $wert
	fi
    fi
 done
}

check_install()
{
  echo "__________________________________________________________________________"
  echo "--------------------------------------------------------------------------\n"
  echo "check installation of cards $cards"
  for mod in $cards; do
      TCARDS="$TCARDS $mods"
      ERRCONF=0
      echo "__________________________________________________________________________"
      echo "\n\n\ttest card installation of $mod"
      echo "\t=================================\n"
          # INFNET="ce"  -> 2 
          # INFNDD="hme qfe ge eri" 1 
          # INFETH="bge" 3
      CARDTYP="0"
      TEST=` echo "$INFNET" | grep " $mod " | awk 'BEGIN{s=0}{s++}END{print s}'`
      if [ "$TEST" -ge 1 ]; then
                # ce Interface
               CARDTYP="2"
      fi
      TEST=` echo "$INFNDD" | grep " $mod " | awk 'BEGIN{s=0}{s++}END{print s}'`
      if [ "$TEST" -ge 1 ]; then
                # standard ndd interface hme
                CARDTYP="1"
      fi
      TEST=` echo "$INFETH" | grep " $mod " | awk 'BEGIN{s=0}{s++}END{print s}'`
      if [ "$TEST" -ge 1 ]; then
                # interface bge dmfe
                CARDTYP="3"
      fi
      if [ "$CARDTYP" -le 0 ]; then
	 echo "ERROR: unknown card type for these function"
         return
      fi

    TEXIST=`echo "$TCARDS" | grep " $mod " | awk 'BEGIN{s=0}{s++}END{print s}' `
    if [ $TEXIST -le 0 ]; then
      TCARDS="$TCARDS $mod "
      ls -l /dev/$mod >/dev/null 2>&1
      if [ "$?" = "0" ]; then
	echo "\tOK\t- /dev/$mod exist"
	 else
	echo "\tERROR\t- /dev/$mod not exist"
	ERRCONF=1
      fi
      DEV=`ls -l /dev/$mod 2>/dev/null | awk '{print substr($NF,3,length($NF))}' `
      if [ "$DEV" != "" ]; then 
	 DEVI=`ls -l $DEV 2>/dev/null | awk '{c=substr($1,1,3);if(c=="crw"){erg=0;}else{erg=1;}if(erg==0 && $3!="root" && $4!="sys" ){erg=1} }END{print erg}' `
	 if [ "$DEVI" -le 0 ]; then
		echo "\tOK\t- $DEV exist"
	  else
	  	echo "\tERROR\t- with $DEV"
		ls -l $DEV 2>&1 | awk '{print "\t\t- "$0}'
	fi
      fi
      DEVPATH="/kernel/drv"
      DRVERR=0
      if [ "$CARDTYP"  -ne 3 ]; then 
      	 ls -l $DEVPATH/$mod >/dev/null 2>&1
      	 if [ "$?" = "0" ]; then
	 	echo "\tOK\t- /kernel/drv/$mod "
	  else
	 	ls -l /platform/`uname -m`/kernel/drv/$mod >/dev/null 2>&1
	 	if [ "$?" = "0" ]; then
	    		DEVPATH="/platform/`uname -m`/kernel/drv"	
	    		echo "\tOK\t- $DEVPATH/$mod "
	  	 else
	    	   	echo "\tERROR\t- missing $DEVPATH/$mod "
	    		DRVERR=1
	  	fi
      	fi
       else
	  	ls -l /platform/`uname -m`/kernel/drv/sparcv9/$mod >/dev/null 2>&1
                if [ "$?" = "0" ]; then
                        DEVPATH="/platform/`uname -m`/kernel/drv" 
		fi
      fi

      ls -l $DEVPATH/sparcv9/$mod >/dev/null 2>&1
      if [ "$?" = "0" ]; then
         echo "\tOK\t- $DEVPATH/sparcv9/$mod "
        else
	 if [ $DRVERR -le 0 ]; then
         	echo "\tINFO\t- no $DEVPATH/sparcv9/$mod "
	  else
		# echo "\tERROR\t- software for module $mod installed ?"
		ERRCONF=1
	 fi
      fi
      PACKET=`grep "/$mod " /var/sadm/install/contents 2>/dev/null | awk 'BEGIN{s=""}{s=s" "$NF;if(NR==1){s=s" "$NF"u"} }END{print s}' `
      if [ "$ERRCONF" -ge 1 ]; then
	 if [ "$PACKET" != "" ]; then
	    echo "\tOK\t- find /dev/$mod in /var/sadm/install/contents - check packets $PACKET now"
	    TPACKET=""
	    for pkg in $PACKET; do
	       TPK=`echo "$TPACKET" | grep "$pkg" | awk 'BEGIN{s=0}{s++}END{print s}' `
	       if [ "$TPK" -le 0 ]; then
		echo "\t\t\t-> pkgchk -v $pkg \t.. \c"
		pkgchk -v $pkg >/tmp/.pkgchk.$$ 2>&1
		if [ "$?" = "0" ]; then echo "\tOK"
                  else  
		  echo "\tFAILED" 
		  grep "ERROR:" /tmp/.pkgchk.$$ | awk '{ print "\t\t\t\t"$0 }' 
		  ERRCONF=1
                fi
		TPACKET="$TPACKET $pkg"
	       fi
	    done
	    rm -r /tmp/.pkgchk.$$ 2>/dev/null 
	  else
	    echo "\tERROR\t- software for module $mod is not installed "
	 fi
       else
	echo "\tOK\t- find /dev/$mod in /var/sadm/install/contents - check packets $PACKET now"
	TPACKET=""
	for pkg in $PACKET; do
	     TPK=`echo "$TPACKET" | grep "$pkg" | awk 'BEGIN{s=0}{s++}END{print s}' `
	     if [ "$TPK" -le 0 ]; then
		echo "\t\t\t-> pkgchk -v $pkg \t.. \c"
		pkgchk -v $pkg  >/tmp/.pkgchk.$$ 2>&1
		if [ "$?" = "0" ]; then echo "\tOK"
		  else 	
		  echo "\tFAILED"
		  grep "ERROR:" /tmp/.pkgchk.$$ | awk '{ print "\t\t\t\t"$0 }'
		  ERRCONF=1
		fi
		TPACKET="$TPACKET $pkg"
	     fi
	done
        rm -r /tmp/.pkgchk.$$ 2>/dev/null 

        ANZ=`modinfo | grep -i " $mod " | grep -i ETHERNET | awk 'BEGIN{s=0;}{s++;}END{print s}' `
        if [ "$ANZ"  -ge 1 ]; then 
	   inf=`modinfo | grep -i " $mod " | grep -i ETHERNET | awk '{s="";for(i=6;i<=NF;i++){s=s" "$i} }END{print s}'`
           echo "\tOK\t- module \"$inf \" loaded" 
	 else
	  ANZ=`modinfo | grep -i " $mod " | awk 'BEGIN{s=0;}{s++;}END{print s}' `
	  if [ "$ANZ"  -eq 1 ]; then
	     inf=`modinfo | grep -i " $mod " | awk '{s="";for(i=6;i<=NF;i++){s=s" "$i} }END{print s}'`
	     echo "\tOK\t- module \"$inf \" loaded"
	   else
          	echo "\tINFO\t- module $mod not loaded ; load now $DEVPATH/$mod" ; 
	  	modload $DEVPATH/$mod
	  	sleep 2
          	ANZ=`modinfo | grep -i " $mod " | grep -i ETHERNET | awk 'BEGIN{s=0;}{s++;}END{print s}' `
		if [ "$ANZ" -le 0 ]; then
		   ANZ=`modinfo | grep -i " $mod " | awk 'BEGIN{s=0;}{s++;}END{print s}' `
		fi
          	case "$ANZ" in
	    	'0' ) echo "\tERROR\t- can't load module $mod ?" ; ERRCONF=1 ;;
	    	'1' ) echo "\tOK\t- module loaded" ;;
            	*)    echo "\tINFO\t- can't found the real module" ; ERRCONF=1 ;;
          	esac
	    fi
	fi
      fi
      else
	echo "\n\t\tINFO: installation of $mod tested before in these run"
     fi ## END of TEXIST
      if [ $ERRCONF -ge 1 ] && [ $FORCE -le 0 ]; then
	 echo "\tFORCE - LINKCHECK for $mod$inst here "
	 ERRCONF=0
      fi
      if [ $ERRCONF -le 0 ]; then
	echo ""
	grep "\"$mod\"" /etc/path_to_inst  > /tmp/.instout
	for inst in $MAXINSTANCE; do
	    echo "\n\ttest now $mod$inst"
	    echo "\t------------------------------------------------------------------"
            INST=`awk '{print $2" "$1}' /tmp/.instout | grep "^$inst" | awk '{print $2}' `
	    if [ "$INST" = "" ]; then echo "\t\tERROR\t- instance not found in /etc/path_to_inst ";
		ERRCONF=1
	     else
               echo "\t\tOK \t- $mod$insts $INST in /etc/path_to_inst";
	       if [ "$CARDTYP" -le 2 ]; then
	       	  ndd -set /dev/$mod instance $inst 2>/dev/null
		  INFO="$?"
		else
		  ndd -get /dev/$mod$inst \? >/dev/null 2>&1
		  INFO="$?"
	       fi
	       if [ "$INFO" = "1" ]; then
		  echo "\t\tERROR\t- can't set instance for $mod$inst "
                  ERRCONF=1
		else
		  echo "\t\tOK\t- can set instane "
                  read_param_1
	       fi
	    fi
	    if [ "$ERRCONF" -ge 1 ]; then
		if [ $LINKCHECK -le 0 ]; then
		   echo "\n\t SKIPPING: linktestmode - please configure your system"
	        fi
		echo "\n\n\t\tis the card $mod$inst in the system ?"
		echo "\n\t\t\t- check /usr/sbin/prtconf -vp "
		echo "\t\t\t  ( device_type:  'network' "
		echo "\t\t\t    vendor-id:  0000108e    or"
		echo "\t\t\t    subsystem-vendor-id:  000014e4 \t)"
		echo "\n\t\t\t- check /usr/platform/`uname -m`/sbin/prtdiag "
		echo "\n\t\t\t- have you make a \"boot -r\" from the OPB"
	     else
	    	echo
	    fi
	done
       else
		echo "\nERROR:\tplease fix errors for module $mod ; than let run the script again"
      fi
  done

  rm -r /tmp/.instout 2>/dev/null
}

card_online()
{
   ONLINE="0"
   case  "$CARDTYP" in 
	'1' )	
   		LINK=`ndd -get /dev/$mod link_status 2>/dev/null | awk '{ if(NR==1){print $1} } ' `
   		MODE=`ndd -get /dev/$mod link_mode 2>/dev/null | awk '{ if(NR==1){print $1} } ' `
   		SPEED=`ndd -get /dev/$mod  link_speed 2>/dev/null | awk '{ if(NR==1){print $1} } ' `
		;;
	'2')    
		if [ -x /usr/bin/kstat ]; then
		   kstat -p | grep $mod$inst | awk 'BEGIN{FS="|"}{print $NF}' > $NETCARD
		 else
		   netstat -k $mod$inst | awk '{ t=0; for(i=1;i<=NF;i++){ if(substr($i,1,4)=="link" || t==0 ){s=$i;t=1}else{t=0;print s"\t"$i} } }'> $NETCARD
		fi
		LINK=`grep link_up $NETCARD | awk '{print $2}' `
		MODE=`grep link_duplex $NETCARD | awk '{print $2}' `
		SPEED=`grep link_speed $NETCARD | awk '{print $2}' `
		LINKPAU=`grep link_pause $NETCARD | awk '{print $2}' `
		LINKASM=`grep link_asmpause $NETCARD | awk '{print $2}' `
		;;
	'3')
                LINK=`ndd -get /dev/$mod$inst   link_status  2>/dev/null  | awk '{ if(NR==1){print $1} } ' `
                SPEED=`ndd -get /dev/$mod$inst  link_speed   2>/dev/null | awk '{ if(NR==1){print $1} } ' `
		if [ "$mod" != "dmfe" ]; then
			MODE=`ndd -get /dev/$mod$inst   link_duplex    2>/dev/null | awk '{ if(NR==1){print $1} } ' `
		 else
			MODE=`ndd -get /dev/$mod$inst   link_mode    2>/dev/null | awk '{ if(NR==1){print $1} } ' `
		fi
		;;
   esac
   INF="$mod$inst"
   INFUP=`ifconfig $INF 2>&1 | awk 'BEGIN{FS="<"}{if(NR=="1"){print substr($2,1,2) } else {print $0} }' | awk 'BEGIN{s=0}{if(s=="1"){b=$NF;s++}; if($1=="UP"){s++}; } END{if(s=="2"){print b}else {print s} }' `
   ERR=`ifconfig $INF | grep inet | awk '{s=0; if($2=="0.0.0.0"){s++} }END{print s}' `
   if [ $ERR -eq 0 ]; then
    if [ "$INFUP" = "0" ]; then
	ifconfig $INF up 2>/dev/null
     else
	if [ "$IHOSTS" != "" ]; then
	 for hostn in $IHOSTS; do
	    ping -i $INF -c 3 $hostn 10 >/dev/null 2>&1 &
	 done 
	fi
	ping -i $INF -c 20 $INFUP 10  >/dev/null 2>&1
	ONLINE=`netstat -f inet -pn | grep $INF | grep -v S | awk 'BEGIN{s=0}{s++}END{print s}' `
    fi
   fi
}

test_card_online()
{
  MAXSLEEP="180"
  S="8"
  T="1"
  ERR=`ifconfig $mod$inst | grep inet | awk '{s=0; if($2=="0.0.0.0"){s++} }END{print s}' `
  if [ $ERR -eq 0 ]; then
	echo "\n\tcleaning arp table .. \c"
	netstat -f inet -pn | grep "$mod$inst" | grep -v "S" | awk '{print $2}' | while read pa rest; do arp -d $pa >/dev/null 2>&1 ; done
	echo "done." 
        IHOSTS=`grep "^[1-9]" /etc/hosts | grep -v "lo[g,c]" | grep -v "$HOSTNAME" | awk 'BEGIN{s=""}{if(NR<=15){s=s" "$1} }END{print s}' ` 
  	echo "\n\tstart relief prozess .. \c"
  	snoop -o /tmp/.nsoop.out.$mod$inst -d $mod$inst -q -r -c 200  >/dev/null 2>&1 &
  	PID=`echo $!`
  	if [ "$PID" != "" ]; then  echo "started"; else echo ; fi
     echo "\twait for online (max $MAXSLEEP sec) : \c"
     IPADDR=`ifconfig $INF 2>/dev/null | awk '{if(NR==2){ip=$2;net=$4;br=$NF};if(NR==3){eth=$NF} }END{print ip }' `
     while( test "$T" != "0" ); do
    		card_online 
    	if [ "$ONLINE" -gt 0 ]; then 
		T="0"; 
		echo "\n\t\tsee $ONLINE stations in the network - mean the link is up on $mod$inst"	
     	else
		echo "$IPADDR" > /tmp/.nsoop.txt
		snoop -i /tmp/.nsoop.out.$mod$inst >> /tmp/.nsoop.txt
        	RECEIVE=`awk 'BEGIN{s=0}{if(NR==1){t=$1}else{ if($5==t){s++} } }END{print s}' /tmp/.nsoop.txt `
		if [ "$REVEICE" -le 0 ]; then
	   		RECEIVE=`grep "reply" /tmp/.nsoop.txt | awk 'BEGIN{s=0}{s++}END{print s}' `
		fi
		rm /tmp/.nsoop.txt
		if [ "$RECEIVE" -gt 0 ]; then 
			echo "\n\n\t\treceive $RECEIVE packets from the network - mean the link is up on $mod$inst"
			T="0"; 
		fi
    	fi
    	if [ "$T" != "0" ]; then
		T=`expr $T + $S + 2`
		if [ "$T" -eq 61 ] || [ "$T" -eq 111 ] || [ "$T" -eq 151 ]; then echo "\n\twait for online (max $MAXSLEEP sec) : \c"; fi
		echo "$T/$MAXSLEEP \c"
		sleep $S
    	fi
    	if [ "$T" -ge "$MAXSLEEP" ]; then T="0"; echo "fin waiting"; fi
     done
     echo "\tstop relief prozess .. \c"
     kill -9 $PID 2>/dev/null
     if [ "$?"  != "0" ]; then echo "Killed"; fi
     echo "$IPADDR" > /tmp/.nsoop.txt
     snoop -i /tmp/.nsoop.out.$mod$inst >> /tmp/.nsoop.txt
     RECEIVE=`awk 'BEGIN{s=0}{if(NR==1){t=$1}else{ if($5==t){s++} } }END{print s}' /tmp/.nsoop.txt `
     rm /tmp/.nsoop.out.$mod$inst /tmp/.nsoop.txt 2>/dev/null
     echo
     echo "\t\tLink state: $STATUS \tLink speed: $SPEED \tLink mode: $MODE"
     if [ "$LINKASM" != "" ]; then
   	echo "\t\t\tLink asm_pause: $LINKASM \tLink pause: $LINKPAU "
     fi
     echo
  else
	# SKIP IP 0.0.0.0
	echo "\n\t\tSKIPPING: WAIT FOR ONLINE - can't set UP the interface $INF - wrong IP ADDRESS 0.0.0.0 "
  fi
}


show_setting_ndd()
{

	ndd -set /dev/$mod instance $inst
          MODE=`ndd -get /dev/$mod link_mode 2>/dev/null | awk '{if(NR==1){s=$1}}END{print s}'`
        STATUS=`ndd -get /dev/$mod link_status 2>/dev/null | awk '{if(NR==1){s=$1}}END{print s}' `
         SPEED=`ndd -get /dev/$mod link_speed  2>/dev/null | awk '{if(NR==1){s=$1}}END{print s}' `

       echo "\n\n\t\tLink status:\t$STATUS, Link speed:\t$SPEED, Link mode:\t$MODE ";
       echo "\n"
       echo "\t\ttest settings are now"
       echo "\t\tLinkoption \t\t\t: $mod$inst (Default) \t Switch/HUB\t "
       echo "\t\t-------------------------------------------------------------------"
       POS=0

  ndd -get /dev/$mod \? 2>/dev/null | grep "lp_" | while read parm rest; do
                #       echo "PARM ->$parm<-"
                POS=`expr $POS + 1`
               rem_str=`ndd /dev/$mod $parm `
               param=`echo $parm | awk '{print substr($1,4,length($1))}' `
                # echo "PARAM ->$param<-"
               def_str=`ndd -get /dev/$mod $param 2>&1`
               if [ "$param" = "pause_cap" ] ||  [ "$param" = "asm_dir_cap" ]; then
                  adv_str="$def_str"
                 else
                   adv_str=`ndd /dev/$mod adv_$param`
               fi
                NSIZE=`echo $param | awk '{print length($1) }' `
                if [ "$L" != "0" ]; then
                        echo "\t\t$param \t\t\t: $adv_str ($def_str) \t\t $rem_str"
                 else
                     if [ $NSIZE -le 6 ]; then
                        echo "\t\t$POS\t$param \t\t\t: $adv_str ($def_str) \t\t $rem_str"
                      else
                        if  [ $NSIZE -ge 14 ]; then
                        echo "\t\t$POS\t$param \t: $adv_str ($def_str) \t\t $rem_str"
                        else
                        echo "\t\t$POS\t$param \t\t: $adv_str ($def_str) \t\t $rem_str"
                        fi
                     fi
                fi
  done
  if [  "$L" -eq "0" ]; then
                PARAMEXTRA=`ndd /dev/$mod \? | grep write | grep -v adv_ | grep -v instance | sort | awk 'BEGIN{s=""}{s=s" "$1} END{print s}' `
                LPOS=`ndd -get /dev/$mod \? 2>/dev/null | grep "lp_" | awk 'BEGIN{s=0}{s++}END{print s}' `
        	echo "\t\t-------------------------------------------------------------------"
                for parm in $PARAMEXTRA; do
                        get=`ndd -get /dev/$mod $parm 2>/dev/null | awk '{if(NR==1){print $1} }' `
                        LPOS=`expr $LPOS + 1 `
                        if [ "$get" != "" ]; then
                           NSIZE=`echo $parm | awk '{print length($1) }' `
                           if [ $NSIZE -le 6 ]; then
                                echo "\t\t$LPOS\t$parm \t\t\t: $get \t\t "
                            else
                                if  [ $NSIZE -ge 14 ]; then
                                echo "\t\t$LPOS\t$parm \t: $get \t\t "
                                 else
                                echo "\t\t$LPOS\t$parm \t\t: $get \t\t "
                                fi
                           fi
                        fi
                done
  fi


}

show_setting_net()
{
       GIGASWIFT=`prtconf -vp | grep -i GIGASWIFT | awk 'BEGIN{s=0}{s++}END{print s}' `
       if [ "$GIGASWIFT" -ge 1 ]; then
       		echo "\n\n\t\tINFO: found network card from typ GigaSwift - these card can max. 100 MBit/s"
       fi


       NETCARD=/tmp/netstat-k-$mod$inst
       if [ -x /usr/bin/kstat ]; then
           kstat -p $mod | grep $mod$inst | awk 'BEGIN{FS=":"}{print $NF}' > $NETCARD
        else
           netstat -k $mod$inst | awk '{ for(i=1;i<=NF;i++){ print $i" "$(i+1);i++; } }' > $NETCARD
       fi

          MODE=`grep -i link_duplex $NETCARD | awk ' {print $2}' `
        STATUS=`grep -i link_up     $NETCARD | awk ' {print $2}' `
         SPEED=`grep -i link_speed  $NETCARD | awk ' {print $2}' `
         LINK_ASM=`grep -i link_asmpause $NETCARD | awk ' {print $2}' `
         LINK_PAU=`grep -i link_pause $NETCARD | awk ' {print $2}' `

         echo "\n\n\t\tLink status:\t$STATUS, Link speed:\t$SPEED, Link mode:\t$MODE ";
         echo "\t\tLink asmpause:\t$LINK_ASM, Link pause:\t$LINK_PAU\n";

         if [ "$LINKCHECK" -le 0 ]; then
            LINKINFO="/tmp/.linkinfo.$mod$inst"
            TESTOPTION="/tmp/.testoption.$mod$inst"
            echo "link_up $STATUS" > $LINKINFO
            echo "link_duplex $MODE" >> $LINKINFO
            echo "link_speed $SPEED" >> $LINKINFO
            echo "link_asmpause $LINK_ASM" >> $LINKINFO
            echo "link_pause $LINK_PAU" >> $LINKINFO
            rm -r $TESTOPTION 2>/dev/null
         fi

       echo "\n"
       echo "\t\ttest settings are now"
       echo "\t\tLinkoption \t\t\t: $mod$inst (Default) \t Switch/HUB\t "
       echo "\t\t-------------------------------------------------------------------"
       POS=0


     grep "lp_" $NETCARD | while read parm rest; do
		POS=`expr $POS + 1 `
                rem_str=`grep "^$parm" $NETCARD | awk '{print $2}' `
                param=`echo $parm | awk '{print substr($1,4,length($1))}' `
                #echo $param
                def_str=`grep "^$param" $NETCARD | awk '{print $2}'`
                if [ "$param" = "pause_cap" ] ||  [ "$param" = "asm_dir_cap" ]; then
                   adv_str="$def_str"
                 else
                   adv_param=`echo $param | awk '{s=substr($1,5,length($1))}END{print "adv_"s"_cap"}' `
                   adv_str=`ndd /dev/$mod $adv_param`
                fi
                echo "\t\t$POS\t$param\t\t: $adv_str ($def_str) \t$rem_str"
     done
     if [  "$L" -eq "0" ]; then
        PARAMEXTRA=`ndd /dev/$mod \? | grep write | grep -v adv_ | grep -v instance | sort | awk 'BEGIN{s=""}{s=s" "$1} END{print s}' `
	LPOS=`grep "lp_" $NETCARD | awk 'BEGIN{s=0}{s++}END{print s}' `
	echo "\t\t-------------------------------------------------------------------"
        for parm in $PARAMEXTRA; do
            get=`ndd -get /dev/$mod $parm 2>/dev/null `
            LPOS=`expr $LPOS + 1 `
            if [ "$get" != "" ]; then
            	NSIZE=`echo $parm | awk '{print length($1) }' `
            	if [ $NSIZE -le 6 ]; then
                                echo "\t\t$LPOS\t$parm \t\t\t: $get \t\t "
                   else
                      if  [ $NSIZE -ge 15 ]; then
                                echo "\t\t$LPOS\t$parm \t: $get \t\t "
                       else
                                echo "\t\t$LPOS\t$parm \t\t: $get \t\t "
                      fi
                fi
            fi
        done
     fi


}

show_setting_eth()
{
  # 	echo "show_setting_eth"

        STATUS=`ndd -get /dev/$mod$inst link_status 2>/dev/null | awk '{if(NR==1){s=$1}}END{print s}' `
         SPEED=`ndd -get /dev/$mod$inst link_speed  2>/dev/null | awk '{if(NR==1){s=$1}}END{print s}' `
	 if [ "$mod" != "dmfe" ]; then
            MODE=`ndd -get /dev/$mod$inst link_duplex 2>/dev/null | awk '{if(NR==1){s=$1}}END{print s}' `
	  else
	    MODE=`ndd -get /dev/$mod$inst link_mode 2>/dev/null | awk '{if(NR==1){s=$1}}END{print s}' `
	fi

          echo "\n\n\t\tLink status:\t$STATUS, Link speed:\t$SPEED, Link mode:\t$MODE ";

          echo "\n"
          echo "\t\ttest settings are now"
          echo "\t\tLinkoption \t\t\t: $mod$inst (Default) \t Switch/HUB\t "
          echo "\t\t-------------------------------------------------------------------"
          POS=0
  	  ndd -get /dev/$mod$inst \? 2>/dev/null | grep "adv_" | while read parm rest; do
                #       echo "PARM ->$parm<-"
                POS=`expr $POS + 1`
                param=`echo $parm | awk '{print substr($1,5,length($1))}' `
	        adv_str=`ndd /dev/$mod$inst $parm`
		rem_str=`ndd /dev/$mod$inst lp_$param 2>/dev/null | awk 'BEGIN{s=0}{if(NF==1){s=$1} }END{print s}' `
		def_str=`ndd /dev/$mod$inst $param 2>/dev/null | awk 'BEGIN{s=0}{if(NF==1){s="("$1")" }else{s="(N/A)"} }END{print s}' `
                NSIZE=`echo $param | awk '{print length($1) }' `
                if [ "$L" != "0" ]; then
                        echo "\t\t$param \t\t\t: $adv_str $def_str \t\t\t $rem_str"
                 else
                     if [ $NSIZE -le 6 ]; then
                        echo "\t\t$POS\t$param \t\t\t: $adv_str $def_str \t\t\t $rem_str"
                      else
                        if  [ $NSIZE -ge 15 ]; then
                        echo "\t\t$POS\t$param \t: $adv_str $def_str \t\t\t $rem_str"
                        else
                        echo "\t\t$POS\t$param \t\t: $adv_str $def_str \t\t\t $rem_str"
                        fi
                     fi
                fi
  	  done
     	  if [  "$L" -eq "0" ]; then
          	PARAMEXTRA=`ndd /dev/$mod$inst \? | grep write | grep -v adv_ | sort | awk 'BEGIN{s=""}{s=s" "$1} END{print s}' `
          	LPOS=`echo "$PLIST" | awk 'BEGIN{s=0}{for(i=1;i<=NF;i++){if(substr($i,1,3)=="lp_"){s++} } }END{print s}' `
        	echo "\t\t-------------------------------------------------------------------"
        	for parm in $PARAMEXTRA; do
            	    get=`ndd -get /dev/$mod$inst $parm 2>/dev/null `
            	    LPOS=`expr $LPOS + 1 `
            	    if [ "$get" != "" ]; then
                	NSIZE=`echo $parm | awk '{print length($1) }' `
                	if [ $NSIZE -le 6 ]; then
                                echo "\t\t$LPOS\t$parm \t\t\t: $get \t\t "
                   	 else
                      	   if  [ $NSIZE -ge 15 ]; then
                                echo "\t\t$LPOS\t$parm \t: $get \t\t "
                            else
                                echo "\t\t$LPOS\t$parm \t\t: $get \t\t "
                      	   fi
               	 	fi
            	    fi
        	done
     	  fi




}

show_settings()
{

  patchinfo 

  # INFNET="ce" type 2 
  # INFNDD="hme qfe ge eri" 1 
  # INFETH="bge" 3

  case "$CARDTYP" in
	'2')	show_setting_net;;
	'1') 	show_setting_ndd;;
        '3')	show_setting_eth;;
  esac
}

change_inf_conf()
{
      case "$ANDI" in
	'i'|'I') echo "\t\t please enter a valid ip address [$IPADDR]: \c" ;;
	'm'|'M') echo "\t\t please enter a valid netmask address [$NETMASK]: \c";;
	'b'|'B') echo "\t\t please enter a valid broadcast address [$BROAD]: \c";;
        'e'|'E') echo "\t\t please enter a valid mac-address [$ETHER]: \c";;
	'p'|'P') echo "\t\t Do you like plumb the interface $INF (y/Y) : \c";;
	'u'|'U') echo "\t\t Do you like unplumb the interface $INF (y/Y) : \c";;
	*) echo "\t\t no valid option - press any key to continue \c";;
       esac
       read TIP
       if [ "$TIP" != "" ]; then
      	case "$ANDI" in
        	'i'|'I') TIPS=`getent hosts $TIP 2>/dev/null | awk  '{print $1}' `
			 if [ "$TIPS" != "" ]; then TIP=$TIPS
			  else echo "\t\t INFO: \tcan't resolve $TIP !"
			 fi
			 ifconfig $INF  $TIP  netmask + broadcast + >/dev/null 2>/dev/null ;;
        	'm'|'M') ifconfig $INF  netmask $TIP  >/dev/null 2>/dev/null   ;;
        	'b'|'B') ifconfig $INF  broadcast $TIP  >/dev/null 2>/dev/null ;;
        	'e'|'E') ifconfig $INF  ether $TIP  >/dev/null 2>/dev/null ;;
		'p'|'P') if [ "$TIP" = "y" ] || [ "$TIP" = "Y" ]; then
			    ifconfig $INF plumb
			 fi
			 ;;
		'u'|'U') if [ "$TIP" = "y" ] || [ "$TIP" = "Y" ]; then
                            ifconfig $INF unplumb
                         fi
                         ;; 
		*) echo "\t\t do nothing";;
        esac
       fi

}

configure_inf()
{
	INF="$mod$inst"
	ifconfig $INF >/dev/null 2>&1
	if [ "$?" != 0 ]; then
		plumb_inf;
	fi
        T=0
	echo "\n\t\t Is the IP configuration valid ?  - you can fix it now "
 	while( test "$T" != "1" ); do
     		CONFIG=`ifconfig $INF 2>/dev/null | awk '{if(NR==2){ip=$2;net=$4;br=$NF};if(NR==3){eth=$NF} }END{print ip" "net" "br" "eth }' `
     		IPADDR=`echo $CONFIG | awk '{print $1}' `
     		NETMASK=`echo $CONFIG | awk '{print $2}' `
     		BROAD=`echo $CONFIG | awk '{print $3}' `
     		ETHER=`echo $CONFIG | awk '{print $4}' `

		echo	
		echo "\t\t change IP-Address \t\t(i/I) \t[$IPADDR] "
		echo "\t\t change Netmask  \t\t(m/M) \t[$NETMASK] "
		echo "\t\t change Broadcast Address \t(b/B) \t[$BROAD] "
		echo "\t\t change Ethernet-Address \t(e/E) \t[$ETHER] "
		echo 
		echo "\t\t   plumb interface $INF \t(p/P) "
		echo "\t\t unplumb interface $INF \t(u/U) "
		echo 
		echo "\t\t configuration complete - quit \t(q/Q) "
		echo "\n\t\t \t\t \t your choice : \t\c"
   		read ANDI
		if [ "$ANDI" != "" ]; then
   		   T=`echo "$ANDI" | awk 'BEGIN{r=0}{s=substr($1,1,1);if(s=="Q" || s=="q" ){r++}}END{print r}' `
		   if [ $T -le 0 ]; then  change_inf_conf ;  fi
		fi
	done
}

plumb_inf()
{
  ERROR=0
  ifconfig $mod$inst plumb >/dev/null 2>&1
  if [ "$?" != "0" ]; then 
	echo "\t\tERROR: can't plumb interface $mod$inst"
	ERROR=1
  fi
}

check_device_down()
{
  INF="$mod$inst"
  ifconfig $INF down >/dev/null 2>/dev/null
  if [ "$?" != "0" ]; then
  	NODEV=0
  	ifconfig $INF >/dev/null 2>/dev/null
  	if [ "$?" != "0" ]; then plumb_inf;  fi

  	DOWN=`ifconfig $INF | grep $INF | grep UP | awk 'BEGIN{s=0}{s++}END{print s}' `
  	if [ "$DOWN" -ge 1 ]; then
		ifconfig $INF down
		echo "\t\tINFO:\t set interface $INF down"
  	fi

     	CONFIG=`ifconfig $INF | awk '{if(NR==2){ip=$2;net=$4;br=$NF};if(NR==3){eth=$NF} }END{print ip" "net" "br" "eth }' `
        IPOK=`echo $CONFIG | awk 'BEGIN{FS=".";s=0}{if(NF!="7"){s++};if($1=="0" && $2=="0" && $3=="0" && substr($4,1,1)=="0"){s++};}END{print s}' `

     	NODEV=`echo "$IPOK" | awk 'BEGIN{s=0}{for(i=1;i<=NF;i++){s=s+$i}}END{print s}' `
     	if [ "$NODEV" != "0" ]; then configure_inf; fi

  	ifconfig $INF >/dev/null 2>/dev/null
  	if [ "$?" != "0" ]; then 
    	   check_device_down
  	fi
   else
	echo "\t\tINFO:\t set interface $INF down"
  fi
}

check_device_up()
{
  ERR=`ifconfig $mod$inst 2>/dev/null | grep inet | awk '{s=0; if($2=="0.0.0.0"){s++} }END{print s}' `
  if [ $ERR -eq 0 ]; then
  	ifconfig $mod$inst up 2>/dev/null
  	if [ "$?" != "0" ]; then
		echo "\n\t\tERROR: can't set UP the interface $INF with ifconfig"
   	 else
		echo "\t\tINFO:\t set Interface $INF up"
  	fi
   else
	echo "\n\t\tERROR: can't set UP the interface $INF with ifconfig - wrong IP ADDRESS 0.0.0.0 "
  fi
}

test_remote_config()
{
 TESTINFO=1

 check_device_down

 echo "\t\tINFO:\t configure interface $mod$inst now - cardtyp $CARDTYP"
 case "$CARDTYP" in
   '1' )
	grep "lp_" $TESTOPTION | grep -v "autoneg" |awk '{print "adv_"substr($1,4,length($1))"."$2}'| while read pa rest; do
	   # echo "$pa" 
	   PARM=`echo "$pa" |awk 'BEGIN{FS="."}{print $1}' `
	    VAL=`echo "$pa" |awk 'BEGIN{FS="."}{print $2}' `
	    ndd -set /dev/$mod $PARM $VAL 2>/dev/null 
	done
	grep "lp_" $TESTOPTION | grep "autoneg" |awk '{print "adv_"substr($1,4,length($1))"."$2}'| while read pa rest; do
	   # echo "$pa"
           PARM=`echo "$pa" |awk 'BEGIN{FS="."}{print $1}' `
            VAL=`echo "$pa" |awk 'BEGIN{FS="."}{print $2}' `
            ndd -set /dev/$mod $PARM $VAL 2>/dev/null
        done
        ;;
   '2')
        grep "lp_" $TESTOPTION | grep -v "autoneg" |awk '{print "adv_"substr($1,8,length($1))"_cap."$2 }'| while read pa rest; do
           # echo "$pa"
           PARM=`echo "$pa" |awk 'BEGIN{FS="."}{print $1}' `
            VAL=`echo "$pa" |awk 'BEGIN{FS="."}{print $2}' `
            ndd -set /dev/$mod $PARM $VAL 2>/dev/null
        done
        grep "lp_" $TESTOPTION | grep "autoneg" |awk '{print "adv_"substr($1,8,length($1))"_cap."$2 }'| while read pa rest; do
           # echo "$pa"
           PARM=`echo "$pa" |awk 'BEGIN{FS="."}{print $1}' `
            VAL=`echo "$pa" |awk 'BEGIN{FS="."}{print $2}' `
            ndd -set /dev/$mod $PARM $VAL 2>/dev/null
        done
        ;;

   '3') 
        grep "lp_" $TESTOPTION | grep -v "autoneg" |awk '{print "adv_"substr($1,4,length($1))"."$2}'| while read pa rest; do
           # echo "$pa"
           PARM=`echo "$pa" |awk 'BEGIN{FS="."}{print $1}' `
            VAL=`echo "$pa" |awk 'BEGIN{FS="."}{print $2}' `
            ndd -set /dev/$mod$inst $PARM $VAL 2>/dev/null
        done
        grep "lp_" $TESTOPTION | grep "autoneg" |awk '{print "adv_"substr($1,4,length($1))"."$2}'| while read pa rest; do
           # echo "$pa"
           PARM=`echo "$pa" |awk 'BEGIN{FS="."}{print $1}' `
            VAL=`echo "$pa" |awk 'BEGIN{FS="."}{print $2}' `
            ndd -set /dev/$mod$inst $PARM $VAL 2>/dev/null
        done
	;;
 esac
 check_device_up
 show_settings
}

test_sun_default()
{
  TESTINFO=2
  TESTFILE="/tmp/.autoneg.$$"
  echo "\t\tINFO: set a autonegosation configuration on $mod$inst - cardtyp $CARDTYP"
  case "$CARDTYP" in
   '1')
     awk 'BEGIN{FS="_"}{if(NF<=2){if($1!="autoneg"){print "adv_"$1"_cap."substr($NF,length($NF),1)} } }'  $TESTOPTION | while read pa rest; do
           # echo "$pa"
           PARM=`echo "$pa" |awk 'BEGIN{FS="."}{print $1}' `
            VAL=`echo "$pa" |awk 'BEGIN{FS="."}{print $2}' `
            ndd -set /dev/$mod $PARM $VAL 2>/dev/null
     done
     awk 'BEGIN{FS="_"}{if(NF<=2){if($1=="autoneg"){print "adv_"$1"_cap."substr($NF,length($NF),1)} } }'  $TESTOPTION | while read pa rest; do
           # echo "$pa"
           PARM=`echo "$pa" |awk 'BEGIN{FS="."}{print $1}' `
            VAL=`echo "$pa" |awk 'BEGIN{FS="."}{print $2}' `
            ndd -set /dev/$mod $PARM $VAL 2>/dev/null
     done
     ;;
   '2')
        grep "lp_" $TESTOPTION | grep -v "autoneg" |awk '{print "adv_"substr($1,8,length($1))"_cap."$2 }'| while read pa rest; do
           # echo "$pa"
           PARM=`echo "$pa" |awk 'BEGIN{FS="."}{print $1}' `
            VAL=`echo "$pa" |awk 'BEGIN{FS="."}{print $2}' `
            echo ndd -set /dev/$mod $PARM $VAL 2>/dev/null
        done
        grep "lp_" $TESTOPTION | grep "autoneg" |awk '{print "adv_"substr($1,8,length($1))"_cap."$2 }'| while read pa rest; do
           # echo "$pa"
           PARM=`echo "$pa" |awk 'BEGIN{FS="."}{print $1}' `
            VAL=`echo "$pa" |awk 'BEGIN{FS="."}{print $2}' `
            echo "ndd -set /dev/$mod $PARM $VAL 2>/dev/null "
        done
        ;;

   '3')
     awk 'BEGIN{FS="_"}{if(NF<=2){if($1!="autoneg"){print "adv_"$1"_cap."substr($NF,length($NF),1)} } }'  $TESTOPTION | while read pa rest; do
           # echo "$pa"
           PARM=`echo "$pa" |awk 'BEGIN{FS="."}{print $1}' `
	   DEF=`echo "$PARM" |awk 'BEGIN{FS="_"}{s="";for(i=2;i<=NF;i++){s=s"_"$i};s=substr(s,2,length(s)) }END{print s}' `
	   ndd -get /dev/$mod$inst $DEF >/dev/null 2>&1
	   if [ "?" = 0 ]; then
              VAL=`echo "$pa" |awk 'BEGIN{FS="."}{print $2}' `
	    else
	      VAL=1
	   fi
           ndd -set /dev/$mod$inst $PARM $VAL 2>/dev/null
     done
     awk 'BEGIN{FS="_"}{if(NF<=2){if($1=="autoneg"){print "adv_"$1"_cap."substr($NF,length($NF),1)} } }'  $TESTOPTION | while read pa rest; do
           # echo "$pa"
           PARM=`echo "$pa" |awk 'BEGIN{FS="."}{print $1}' `
	    DEF=`echo "$PARM" |awk 'BEGIN{FS="_"}{s="";for(i=2;i<=NF;i++){s=s"_"$i};s=substr(s,2,length(s)) }END{print s}' `
	    ndd -get /dev/$mod$inst $DEF >/dev/null 2>&1
            if [ "?" = 0 ]; then
            	VAL=`echo "$pa" |awk 'BEGIN{FS="."}{print $2}' `
	     else
		VAL=1
	    fi
            ndd -set /dev/$mod$inst $PARM $VAL 2>/dev/null
     done

        ;;
    *)  echo "unsupported cardtyp $CARDTYP";;
  esac 
  check_device_up
  show_settings
}

test_force_duplex()
{
  TESTINFO=3
  TESTFILE="/tmp/.noautoneg.$$"

  awk 'BEGIN{FS="_"}{if(NF<=2){if($1!="autoneg"){print "adv_"$1"_cap."substr($NF,length($NF),1)} } }'  $TESTOPTION | while read pa rest; do
           # echo "$pa"
           PARM=`echo "$pa" |awk 'BEGIN{FS="."}{print $1}' `
            # VAL=`echo "$pa" |awk 'BEGIN{FS="."}{print $2}' `
	    VAL=`echo "$PARM" | awk 'BEGIN{FS="."}{l=length($1);s=substr($1,l-6,3); if(s=="fdx"){print "1" }else{ print "0"} }' `
	   if [ $CARDTYP -le 2 ]; then
            	ndd -set /dev/$mod $PARM $VAL 2>/dev/null
	    else
		ndd -set /dev/$mod$inst $PARM $VAL 2>/dev/null
	   fi
  done

  # force autoneg off 
  if [ $CARDTYP -le 2 ]; then
  	ndd -set /dev/$mod adv_autoneg_cap  0 2>/dev/null
   else
	ndd -set /dev/$mod$inst adv_autoneg_cap  0 2>/dev/null
  fi
  check_device_up
  show_settings
}

check4online()
{
     if [ $DEBUG -ge 4 ]; then echo "function check4online"; fi
     ONLINE="0"; RECEIVE="0"
     test_card_online
     card_online
     if [ "$ONLINE" -gt 0 ] || [ "$RECEIVE" -gt 0 ]; then
	echo
        echo "\t\t\tDo you won't write these configuration to $CONFDAT [Y/N] \c"
        read ANSWER
        WRITE=`echo "$ANSWER" | awk 'BEGIN{r=1}{s=substr($1,1,1);if(s=="Y" || s=="y" ){r--;}}END{print r}' `
        if [ "$WRITE" -le 0 ]; then
                if [ $DEBUG -ge 1 ]; then
                        echo "$0 write $mod$inst"
                fi
                echo "\t\t\trun optine write: $0 write $mod$inst"
                $0 write $mod$inst 2>&1 | awk '{print "\t\t\trun option write: "$0}'
        fi
      fi # end online
}

run_remotecheck()
{
 case "$CARDTYP" in
   '1'|'3' )
  	REMOTE=`grep "lp_" $TESTOPTION | awk 'BEGIN{s=0}{t=$2+1-1;if(t>=1){s++;} }END{print s}' `
  	if [ $REMOTE -ge 1 ]; then
     		echo "\n\n\t\tOK - receive information from remote - can use these settings"
     		test_remote_config
     		check4online
   	else
     		echo "\t\tSKIPPING: receive no information from remote"
  	fi
   	;;
   '2' )
        if [ ! -r $NETCARD ]; then
           if [ -x /usr/bin/kstat ]; then
              kstat -p | grep $mod$inst | awk 'BEGIN{FS="|"}{print $NF}' > $NETCARD
            else
              netstat -k $mod$inst | awk '{ t=0; for(i=1;i<=NF;i++){ if(substr($i,1,4)=="link" || t==0 ){s=$i;t=1}else{t=0;print s"\t"$i} } }'> $NETCARD
            fi
	fi
	REMOTE=`grep "lp_" $NETCARD | awk 'BEGIN{s=0}{t=$2+1-1;if(t>=1){s++;} }END{print s}' `
	awk 'BEGIN{FS=":"}{print $NF}'  $NETCARD > $TESTOPTION
	if [ $REMOTE -ge 1 ]; then
                echo "\n\n\t\tOK - receive information from remote - can use these settings"
                test_remote_config
                check4online
        else
                echo "\t\tSKIPPING: receive no information from remote"
        fi
	;;
  esac

}

run_defaultcheck()
{
     test_sun_default
     check4online
}

run_forcecheck()
{
     test_force_duplex
     check4online
}

run_selfconfig()
{
   if [ ! -r  $TESTOPTION ]; then
     case "$CARDTYP" in
	'1')
          ndd /dev/$mod \? | grep "lp_" | while read parm rest; do
                rem_str=`ndd /dev/$mod $parm`
                param=`echo $parm | awk '{print substr($1,4,length($1))}' `
                # echo $param
                def_str=`ndd /dev/$mod $param`
                if [ "$param" = "pause_cap" ] ||  [ "$param" = "asm_dir_cap" ]; then
                   adv_str="$def_str"
                 else
                   adv_str=`ndd /dev/$mod adv_$param`
                fi
                   echo "$parm $rem_str" >> $TESTOPTION
                   echo "$param $def_str" >> $TESTOPTION
                   echo "adv_$param $adv_str" >> $TESTOPTION
          done
        ;;
     	'2')
       	  NETCARD=/tmp/netstat-k-$mod$inst
       	  if [ -x /usr/bin/kstat ]; then
           	kstat -p $mod | grep $mod$inst | awk 'BEGIN{FS=":"}{print $NF}' > $NETCARD
            else
           	netstat -k $mod$inst | awk '{ for(i=1;i<=NF;i++){ print $i" "$(i+1);i++; } }' > $NETCARD
       	  fi

         grep "lp_" $NETCARD | while read parm rest; do
                rem_str=`grep "^$parm" $NETCARD | awk '{print $2}' `
                param=`echo $parm | awk '{print substr($1,4,length($1))}' `
                #echo $param
                def_str=`grep "^$param" $NETCARD | awk '{print $2}'`
                if [ "$param" = "pause_cap" ] ||  [ "$param" = "asm_dir_cap" ]; then
                   adv_str="$def_str"
                 else
                   adv_param=`echo $param | awk '{s=substr($1,5,length($1))}END{print "adv_"s"_cap"}' `
                   adv_str=`ndd /dev/$mod $adv_param`
                fi
                   echo "$parm $rem_str" >> $TESTOPTION
                   echo "$param $def_str" >> $TESTOPTION
                   echo "$adv_param $adv_str" >> $TESTOPTION
         done

       	;;
    	'3')  
          ndd /dev/$mod$mod \? | grep "adv_" | while read parm rest; do
		adv_str=`ndd /dev/$mod$inst $parm`
                param=`echo $parm | awk '{print substr($1,5,length($1))}' `
                # echo $param
                def_str=`ndd /dev/$mod$inst $param 2>/dev/null | awk 'BEGIN{s=0}{ if(NF==1){s=$1} }END{print s}' `
		rem_str=`ndd /dev/$mod$inst lp_$param 2>/dev/null | awk 'BEGIN{s=0}{ if(NF==1){s=$1} }END{print s}' `
                   echo "$parm $rem_str" >> $TESTOPTION
                   echo "$param $def_str" >> $TESTOPTION
                   echo "adv_$param $adv_str" >> $TESTOPTION
          done
	;;
     esac
   fi

   PLIST=`grep "adv_" $TESTOPTION | awk 'BEGIN{t=""}{t=t" "$1}END{print t}' `
   if [ $DEBUG -ge 1 ]; then echo "run_selfadapting PLIST ->$PLIST<-" ; fi
   L=0; CHANGED="0"
   while( test "$L" != "1" ); do
	ifconfig $mod$inst >/dev/null 2>&1
	if [ "$?" = 0 ]; then
	   CONFIG=`ifconfig $mod$inst | awk '{if(NR==2){ip=$2;net=$4;br=$NF};if(NR==3){eth=$NF} }END{print ip" "net" "br" "eth }' `
	   IPADDR=`echo "$CONFIG" | awk '{print $1}' `
	   if [ "$IPADDR" = "0.0.0.0" ]; then 
	      echo "\n\n\t\tERROR: wrong ip configuration on $mod$inst - please configure"
	    else
	      echo "\n\n\t\tIP configuration for $mod$inst : $CONFIG"
	   fi
	 else
	   echo "\n\tno device $mod$inst with command ifconfig defined"
	fi
	show_settings
	echo "\n\t\ttype u \tfor ifconfig $mod$inst up"
	echo "\t\ttype d \tfor ifconfig $mod$inst down"
	echo "\t\ttype c \tfor ifconfig $mod$inst configuration"
	echo "\t\ttype number (before Linkoption) to change these value"
	# echo "\n\t\ttype number (before Linkoption) or use q (quit) : \c"
	echo "\n\t\tor use q (quit) these option : \c"
	read ANSWER
	if [ "$ANSWER" != "" ]; then
	   case "$ANSWER" in 
	     'q'|'Q') 	L=1; 
			if [ "$CHANGED" -gt 0 ]; then  check4online ; fi
			;;
	     'd'|'D')   check_device_down ; CHANGED="1" ;;
	     'u'|'U')   check_device_up   ; CHANGED="1" ;;
	     'c'|'C')   configure_inf     ; CHANGED="1" ;;
	     * )
		
		   PLT=`echo "$PLIST $ANSWER" | awk  '{t=$NF+1-1;for(i=1;i<=(NF-1);i++){if(t==i){print $i}} }' `
		   if [ $DEBUG -ge 1 ]; then
			echo "PLIST ->$PLIST<-"
			echo "PLT ->$PLT<-"
		   fi
		   if [ "$PLT" != "" ]; then
		      if [ "$CARDTYP" -le 2 ]; then
			NPLT=`ndd -get /dev/$mod $PLT 2>/dev/null | awk '{if($1==1){print 0}else{print 1} }' `
			echo "\t\tchange for  $mod$inst  parameter $PLT to $NPLT"
			ndd -set /dev/$mod $PLT $NPLT  2>/dev/null
			if [ "$?" -eq 0 ]; then
			#   check4online
			    CHANGED="1"
			fi
		       else
                        NPLT=`ndd -get /dev/$mod$inst $PLT 2>/dev/null | awk '{if($1==1){print 0}else{print 1} }' `
			echo "\t\tchange for $mod$inst parameter $PLT to $NPLT"
                        ndd -set /dev/$mod$inst $PLT $NPLT  2>/dev/null
                        if [ "$?" -eq 0 ]; then
                        #   check4online
                            CHANGED="1"
                        fi
		      fi # END CARDTYP
		    else
		     PLT=`echo "$PLIST $PARAMEXTRA $ANSWER" | awk  '{t=$NF+1-1;for(i=1;i<=(NF-1);i++){if(t==i){print $i}} }' `
		     if [ "$PLT" != "" ]; then
			if [ "$CARDTYP" -le 2 ]; then
				NPLT=`ndd -get /dev/$mod $PLT `
			 else
				NPLT=`ndd -get /dev/$mod$inst $PLT `
			fi
			echo "\n\t\tparameter $PLT [$NPLT] - new value :\c"
			read VALE
			if [ "$VALE" != "" ]; then
			   echo "\t\tchange for $mod$inst parameter $PLT from $NPLT to $VALE"
			   if [ "$CARDTYP" -le 2 ]; then
			   	VT=`ndd -set /dev/$mod $PLT $VALE 2>&1 | awk 'BEGIN{s=0}{s++}END{print s}' `
			    else
				VT=`ndd -set /dev/$mod$inst $PLT $VALE 2>&1 | awk 'BEGIN{s=0}{s++}END{print s}' `
			   fi
			   if [ "$VT" != "0" ]; then
				echo "\n\t\tSKIPPING: \"$VALE\" is a wrong value for $PLT in module /dev/$mod"
			    else
				# check4online
				CHANGED="1"
			   fi
			fi
		      else
		     	echo "\t\tSKIPPING: \"$ANSWER\" is a wrong value"
		     fi
		   fi
		;;
	   esac 
	fi
   done
}

link_check()
{
  echo "\n\n\ttest the link now of network card $mod$inst"
  echo "\t------------------------------------------------------------------------------"
  echo "\t\tUse \"Quit\" when your work is finish or you don't like use these option"
	   S=0
	   while( test "$S" != "1" ); do
	        echo "\n\t\tREMOTE Configuration \t\t\t\t\t\t[r/R] "
		echo "\t\tDefault with Autonegosation \t\t\t\t\t[d/D] "
		echo "\t\tForce FDX-Link without Autonegosation \t\t\t\t[f/F] "
		echo "\n\t\tSelf-adapting Configuration \t\t\t\t\t[s/S] "
		echo "\n\t\tQuit these for $mod$inst \t\t\t\t\t\t[q/Q] "
		echo "\t\t\t \t\t\t \t\tyour choise : \c"
		read ANSWER 
		if [ "$ANSWER" != "" ]; then
		  if [ "$ANSWER" != "q" ] && [ "$ANSWER" != "Q" ]; then
			IFCONFIG=`ifconfig $mod$inst 2>&1 | grep "$mod$inst" `
        		IFCONFIGUP=`echo "$IFCONFIG" | grep UP | awk 'BEGIN{s=0}{s++;}END{print s}' `
        		if [ $STATUS -ge 1 ] || [ IFCONFIGUP -ge 1 ]; then
                		LINKSTATUS="0"
                		echo "\n\t\t Sorry the link is UP - you lose the link with these option."
                		echo "\n\t\t Say Yes (Y/y) when you will use these option [Y/N (Default)] \c"
                		read ANS
                		LINKSTATUS=`echo "$ANS" | awk 'BEGIN{r=0}{s=substr($1,1,1);if(s=="Y" || s=="y" ){r=1;}}END{print r}' `
        	        else
                		LINKSTATUS="1"
        		fi
			if [ $LINKSTATUS -ge 1 ]; then
				case "$ANSWER" in
				  'd'|'D' )	run_defaultcheck;;
				  'r'|'R' )     run_remotecheck;;
				  'f'|'F' )	run_forcecheck;;
				  's'|'S' )	run_selfconfig ;;
				  'q'|'Q' )	S="1";;
				  *)  echo "\t\t no valid option "
				esac
			fi
		  else  #  answer != q/Q else
		   S="1"
		 fi # answer != q/Q
		fi # anwer clean
	   done
}

patchinfo()
{
  PATCH=""
  # PATCH="5.5 5.6 5.7 5.8 5.9 5.10 5.11 5.12"
  case "$mod" in 
	'dmfe' )  PATCH="N N N 112168-02 114388-02 N N N " ;;
  esac
  if [ $DEBUG -ge 1 ]; then  echo "PATCHLIST for $mod ->$PATCH<-  OS $MAJOROS . $MINOROS" ; fi
  if [ "$PATCH" != "" ]; then
     if [ "$MAJOROS" -eq 5 ]; then
        PAT=`echo "$PATCH $MINOROS" | awk '{ s=$NF;s=s-4;p=$s }END{print p}' `
	
	if [ "$PAT" != "N" ]; then
	   MPAT=`echo $PAT | awk 'BEGIN{FS="-"}{print $1}' `
	   VPAT=`echo $PAT | awk 'BEGIN{FS="-"}{s=$2; s++;s--; print s}' `
	   RPAT=`ls -l /var/sadm/patch/ | grep "$MPAT" | awk '{s=substr($NF,length($NF)-1,length($NF) ); s++; s--}END{if(s!=""){print s}else{print 0} }' `
	   if [ "$VPAT" -gt "$RPAT" ]; then
		echo "\n\t\tINFO: Please install $PAT or later for full remote support"
	   fi
	fi
        if [ $DEBUG -ge 1 ]; then  echo "PATCH ->$PAT<-  ->$MPAT<- min ->$VPAT<- inst ->$RPAT<-"; fi
     fi 
  fi
}

read_param_1()
{

  echo "\n\n\tdisplay now the active configuration of $mod$inst"
  echo "\t---------------------------------------------------------------------"
  patchinfo
  case "$CARDTYP" in
    '1')
	  ndd -set /dev/$mod instance $inst
          STATUS=`ndd -get /dev/$mod link_status 2>/dev/null | awk '{if(NR==1){s=$1}}END{print s}' `
           SPEED=`ndd -get /dev/$mod link_speed  2>/dev/null | awk '{if(NR==1){s=$1}}END{print s}' `
            MODE=`ndd -get /dev/$mod link_mode   2>/dev/null | awk '{if(NR==1){s=$1}}END{print s}' `

          echo "\n\tLink state:\t$STATUS,\t Link speed: $SPEED,\t Link mode:\t$MODE \n"

         if [ "$LINKCHECK" -le 0 ]; then
            LINKINFO="/tmp/.linkinfo.$mod$inst"
            TESTOPTION="/tmp/.testoption.$mod$inst"
            echo "link_up $STATUS" > $LINKINFO
            echo "link_duplex $MODE" >> $LINKINFO
            echo "link_speed $SPEED" >> $LINKINFO
            echo "link_asmpause $LINK_ASM" >> $LINKINFO
            echo "link_pause $LINK_PAU" >> $LINKINFO
	    rm -r $TESTOPTION 2>/dev/null
         fi

          echo "\t\tLinkoption \t\t\t: $mod$inst (Default) \t Switch/HUB\t "
          echo "\t\t---------------------------------------------------------------------"
	  ndd /dev/$mod \? | grep "lp_" | while read parm rest; do
		rem_str=`ndd /dev/$mod $parm`
		param=`echo $parm | awk '{print substr($1,4,length($1))}' `
		# echo $param
		def_str=`ndd /dev/$mod $param`
		if [ "$param" = "pause_cap" ] ||  [ "$param" = "asm_dir_cap" ]; then
		   adv_str="$def_str"
	         else
		   adv_str=`ndd /dev/$mod adv_$param`
		fi
	        if [ "$LINKCHECK" -le 0 ]; then
		   echo "$parm $rem_str" >> $TESTOPTION
		   echo "$param $def_str" >> $TESTOPTION
		   echo "adv_$param $adv_str" >> $TESTOPTION
		fi
		NSIZE=`echo $param | awk '{ print length($1) }'`
		if [ "$NSIZE" -le 13 ]; then
			echo "\t\t$param \t\t\t: $adv_str ($def_str) \t\t $rem_str"
		 else
			echo "\t\t$param \t\t: $adv_str ($def_str) \t\t $rem_str"
		fi
	  done
	;;
  '2')
       NETCARD=/tmp/netstat-k-$mod$inst
       if [ -x /usr/bin/kstat ]; then
           kstat -p $mod | grep $mod$inst | awk 'BEGIN{FS=":"}{print $NF}' > $NETCARD
	else
           netstat -k $mod$inst | awk '{ for(i=1;i<=NF;i++){ print $i" "$(i+1);i++; } }' > $NETCARD
       fi
       
          MODE=`grep -i link_duplex $NETCARD | awk ' {print $2}' `
        STATUS=`grep -i link_up     $NETCARD | awk ' {print $2}' `
         SPEED=`grep -i link_speed  $NETCARD | awk ' {print $2}' `
         LINK_ASM=`grep -i link_asmpause $NETCARD | awk ' {print $2}' `
         LINK_PAU=`grep -i link_pause $NETCARD | awk ' {print $2}' `

         echo "\n\t\tLink status:\t$STATUS, Link speed:\t$SPEED, Link mode:\t$MODE ";
         echo "\t\tLink asmpause:\t$LINK_ASM, Link pause:\t$LINK_PAU\n";

	 if [ "$LINKCHECK" -le 0 ]; then
	    LINKINFO="/tmp/.linkinfo.$mod$inst"
	    TESTOPTION="/tmp/.testoption.$mod$inst"
	    echo "link_up $STATUS" > $LINKINFO
	    echo "link_duplex $MODE" >> $LINKINFO
	    echo "link_speed $SPEED" >> $LINKINFO
	    echo "link_asmpause $LINK_ASM" >> $LINKINFO
	    echo "link_pause $LINK_PAU" >> $LINKINFO
	    rm -r $TESTOPTION 2>/dev/null
	 fi


         echo "\t\tLinkoption \t\t\t: $mod$inst \t Switch/HUB"
         echo "\t\t-------------------------------------------------"

	 grep "lp_" $NETCARD | while read parm rest; do
                rem_str=`grep "^$parm" $NETCARD | awk '{print $2}' `
                param=`echo $parm | awk '{print substr($1,4,length($1))}' `
                #echo $param
                def_str=`grep "^$param" $NETCARD | awk '{print $2}'`
                if [ "$param" = "pause_cap" ] ||  [ "$param" = "asm_dir_cap" ]; then
                   adv_str="$def_str"
                 else
		   adv_param=`echo $param | awk '{s=substr($1,5,length($1))}END{print "adv_"s"_cap"}' ` 
                   adv_str=`ndd /dev/$mod $adv_param`
                fi
		if [ "$LINKCHECK" -le 0 ]; then
                   echo "$parm $rem_str" >> $TESTOPTION
                   echo "$param $def_str" >> $TESTOPTION
                   echo "$adv_param $adv_str" >> $TESTOPTION
                fi
                echo "\t\t$param\t\t\t: $adv_str ($def_str) \t$rem_str"
 	 done
       ;;
    '3')  
          STATUS=`ndd -get /dev/$mod$inst link_status 2>/dev/null | awk '{if(NR==1){s=$1}}END{print s}' `
           SPEED=`ndd -get /dev/$mod$inst link_speed  2>/dev/null | awk '{if(NR==1){s=$1}}END{print s}' `
	   if [ "$mod" != "dmfe" ]; then
             MODE=`ndd -get /dev/$mod$inst link_duplex   2>/dev/null | awk '{if(NR==1){s=$1}}END{print s}' `
	    else
	     MODE=`ndd -get /dev/$mod$inst link_mode   2>/dev/null | awk '{if(NR==1){s=$1}}END{print s}' `
	   fi

          echo "\n\t\tLink state:\t$STATUS,\t Link speed: $SPEED,\t Link mode:\t$MODE \n"

         if [ "$LINKCHECK" -le 0 ]; then
            LINKINFO="/tmp/.linkinfo.$mod$inst"
            TESTOPTION="/tmp/.testoption.$mod$inst"
            echo "link_up $STATUS" > $LINKINFO
            echo "link_duplex $MODE" >> $LINKINFO
            echo "link_speed $SPEED" >> $LINKINFO
            echo "link_asmpause $LINK_ASM" >> $LINKINFO
            echo "link_pause $LINK_PAU" >> $LINKINFO
            rm -r $TESTOPTION 2>/dev/null
         fi

          echo "\t\tLinkoption \t\t\t: $mod$inst (Default) \t Switch/HUB\t "
          echo "\t\t---------------------------------------------------------------------"
          ndd /dev/$mod$inst \? | grep "adv_" | while read parm rest; do
                adv_str=`ndd /dev/$mod$inst $parm`
                param=`echo $parm | awk '{print substr($1,5,length($1))}' `
                # echo $param
                # def_str=`ndd /dev/$mod$inst $param 2>/dev/null | awk 'BEGIN{s=0}{if(NF==1){s=$1} }END{print s}' `
		def_str=`ndd /dev/$mod$inst $param 2>/dev/null | awk 'BEGIN{s=0}{if(NF==1){s=$1 }else{s="N/A"} }END{print s}' `
                rem_str=`ndd /dev/$mod$inst lp_$param 2>/dev/null | awk 'BEGIN{s=0}{if(NF==1){s=$1}else{s="N/A"} }END{print s}'`
                if [ "$LINKCHECK" -le 0 ]; then
                   echo "$parm $adv_str" >> $TESTOPTION
		   if [ "$def_str" != "N/A" ]; then
                   	echo "$param $def_str" >> $TESTOPTION
		    else
		   	echo "$param 0 " >> $TESTOPTION
		   fi
		   if [ "$rem_str" != "N/A" ]; then
                      	echo "lp_$param $rem_str" >> $TESTOPTION
		    else
			echo "lp_$param 0" >> $TESTOPTION
		   fi
                fi
                NSIZE=`echo $param | awk '{ print length($1) }'`
                if [ "$NSIZE" -le 14 ]; then
                        echo "\t\t$param \t\t\t: $adv_str ($def_str) \t\t $rem_str"
                 else
                        echo "\t\t$param \t\t: $adv_str ($def_str) \t\t $rem_str"
                fi
          done
        ;;
  esac

  if [ "$LINKCHECK" -le 0 ]; then
	CONSOLE=`who am i | awk 'BEGIN{s="1"}{if(substr($NF,2,1)==":"){s--} }END{print s}' `

	if [ "$CONSOLE" -gt 0 ]; then
		echo "\n\tINFO: you are not on the console"
		SPLIST=`netstat -pn | grep SP | awk 'BEGIN{t=""}{ t=t" "$1":"$2 }END{print t}' `
		INFT=`netstat -pn | grep SP  | grep $mod$inst | awk 'BEGIN{t=""}{ t=t" "$1":"$2 }END{print t}' `
	
	        if [ "$SPLIST" != "$INFT" ]; then
		   echo "\tCHECK: NO OPEN SESSIONS [TELNET/RLOGIN/SSH] on interface $mod$inst ? .. \c"
		   NETT="0"
		   netstat -an | grep ESTABLISHED | grep -v "127.0.0.1" > /tmp/.netstat-an.out
		   for tinf in $INFT; do
			# echo "\t$tinf $mod$inst"
			IPADDR=`echo  $tinf | awk 'BEGIN{FS=":"}{print $NF}' `
			TPORT="23 513 22"
			for port in $TPORT; do
		       		TEST=`grep "$IPADDR.$port" /tmp/.netstat-an.out | awk 'BEGIN{s=0}{s++}END{print s}' `
				NETT=`expr $NETT + $TEST `
			done
		   done 
		   if [ "$NETT" -le 0 ]; then CONSOLE="0"; echo "OK" 
		    else echo "FAILED"; echo "\tfound $NETT open sessions over $mod$inst ports $TPORT" 
		   fi
		   rm /tmp/.netstat-an.out 2>/dev/null
		fi

	fi
        if [ "$FORCE" -le 0 ]; then  
		if [ "$CONSOLE" -ge 1 ]; then
			echo "\n\tWARNING: force linktest mode for $mod$inst - not on console or open sessions"
		fi
		CONSOLE=0; 
	fi
	if [ "$CONSOLE" -le 0 ]; then
		link_check
	 else
		echo "\n\n  SKIPPING: linktestmode - not on the console or not over diffrent interface"
	fi
  fi
  rm -r $LINKINFO $TESTOPTION  $NETCARD 2>/dev/null
}

check_param()
{
  ipforward=`ndd -get /dev/ip ip_forwarding `
  RUN="CHECK"; check_active
  if [ $DEBUG = "1" ]; then echo $AKTIVCARD; fi
  if [ "$AKTIVCARD" = "" ]; then 
	if [ "$TINF" = "" ]; then
		 die "no network-adapter work with the program ndd"; 
	 else
		echo "ndd-info: no instance of $TINF found\n"
	fi
  fi
  echo "__________________________________________________________________________"
  echo "--------------------------------------------------------------------------\n"

  if [ "$ipforward" -le 0 ]; then echo "IP forwarding is \tdisabled \ton all interfaces!"; else echo "IP forwarding is enabled !" ; fi
  echo "\n__________________________________________________________________________"
  echo "--------------------------------------------------------------------------"

  for mod in $AKTIVCARD; do

      CARDTYP="0"
      TEST=` echo "$INFNET" | grep " $mod " | awk 'BEGIN{s=0}{s++}END{print s}'`
      if [ "$TEST" -ge 1 ]; then
                        # ce Interface
                        CARDTYP="2"
      fi
      TEST=` echo "$INFNDD" | grep " $mod " | awk 'BEGIN{s=0}{s++}END{print s}'`
      if [ "$TEST" -ge 1 ]; then
                        # standard ndd interface hme
                        CARDTYP="1"
      fi
      TEST=` echo "$INFETH" | grep " $mod " | awk 'BEGIN{s=0}{s++}END{print s}'`
      if [ "$TEST" -ge 1 ]; then
                        # interface bge dmfe
                        CARDTYP="3"
      fi

     echo " "
     echo "--------------------------------------------------------------------"
     echo "look for active card configuration for modules:  $mod "
     cardvers=`modinfo | grep " $mod " | awk '{ s="";for(i=6;i<=NF;i++){s=s" "$i}}END{print s}'`
     if [ "$cardvers" = "" ]; then
     if [ -r /kernel/drv/$mod ]; then
     	  cardvers=`strings /kernel/drv/$mod | grep -i "Ethernet" | grep -v [:,?,=] 2>/dev/null `
	else 
	  cardvers=`modinfo | grep -i ethernet | awk '{print $6" "$7" "$8" "$9" " $10" "$11" "$12}' | grep "^$mod" `
       fi
     fi
     if [ "xx$cardvers" != "xx" ]; then echo "device driver :\t $cardvers"; fi
     echo "(no more output - card does not work with ndd or card not in use) "
     echo "--------------------------------------------------------------------"
     patchinfo

    grep "$mod" /etc/path_to_inst >/tmp/.nddhelp 2>/dev/null

    case "$CARDTYP" in
    '1')
     for inst in $MAXINSTANCE; do
         ndd -set /dev/$mod instance $inst 2>&1 | egrep -s -e "operation failed"
         if [ "$?" = 0 ]; then
            if [ $DEBUG = "1" ]; then echo "$mod$inst do not work" ; fi
            continue;
         fi
         if [ "$OS" = 5.8 ]; then ipforward_int=`ndd -get /dev/ip $mod$inst:ip_forwarding` ; fi
         echo " "
         check_remote

                     echo "$inst">/tmp/.nhelp2 2>/dev/null
                     cat /tmp/.nddhelp 2>/dev/null >> /tmp/.nhelp2 2>/dev/null
                     INFO=`awk '{ if(NF==1){T=$1}else{ if(T==$2){print $1} } }' /tmp/.nhelp2 2>/dev/null`
                     if [ "$INFO" = "" ]; then INFO="not found in /etc/path_to_inst"; fi


         if [ $DEBUG = "1" ]; then echo $REMOTE; fi
         if [ $REMOTE = "1" ]; then
           echo "\nconfiguration for : $mod$inst \c"
          else
           echo "\nno remote configuration exist "
           echo "configuration for : $mod$inst  \c"
         fi
         if [ "$OS" = "5.8" ] && [ "$ipforward" -ge 1 ]; then 
            ipforward_int=`ndd -get /dev/ip $mod$inst:ip_forwarding` 
            case "$ipforward_int" in 
             0)   echo "\t routing on these interface is : disabled" ;;
             1)   echo "\t routing on these interface is : enabled" ;;
             *)   echo "\t value $mod$inst:ip_forwarding not exist in /dev/ip";;
            esac 
         else echo " "; fi

	  STAT=`ndd -get /dev/$mod link_status 2>/dev/null `
	  SPEED=`ndd -get /dev/$mod link_speed 2>/dev/null `
	  MODE=`ndd -get /dev/$mod link_mode   2>/dev/null `
	  echo "\n\tLink status:\t$STAT, Link speed:\t$SPEED, Link mode:\t$MODE \n"

          echo "Linkoption\t$mod$inst\tSwitch/HUB\t in $CONFDAT"
          echo "--------------------------------------------------------------------"
          ndd /dev/$mod \? | grep lp_ | awk '{print $1}' | while read parm rest; do
           if [ $DEBUG = "1" ]; then echo $parm ; fi
           if [ $parm != "lp_asm_dir_cap" ] && [ $parm != "lp_pause_cap" ]; then
             loc_str=`echo $parm | awk '{print substr($1,4,length($1))}' `
             if [ $DEBUG = "1" ]; then echo adv_$loc_str ; fi
             adv_str=`ndd /dev/$mod adv_$loc_str`
             if [ $DEBUG = "1" ]; then echo "adv_str : $adv_str\#" ; fi
             rem_str=`ndd /dev/$mod  lp_$loc_str`
             if [ $DEBUG = "1" ]; then echo "rem_str : $rem_str\#" ; fi
	     def=`ndd /dev/$mod  $loc_str`
             if [ $DEBUG = "1" ]; then echo "default_str : $def\#" ; fi
             conf_str=`grep adv_$loc_str $CONFDAT 2>/dev/null | grep -v \# | grep \;$mod\;$inst\; | awk '{ print substr($1,length($1),length($1) ) } '`
             if [ $DEBUG = "1" ]; then echo "conf_str : $conf_str\#" ; fi
	     if [ "$mod" = "ge" ] && [ "$loc_str" = "1000autoneg_cap" ]; then
		loc_str=`echo $loc_str | awk '{print substr($1,5,length($1))}' `
	     fi
             if [ xx$adv_str != xx$rem_str ]; then
                if [ $DEBUG = "1" ]; then echo "settings remote and local are  not the same" ; fi
                if [ xx$adv_str != xx$conf_str ]; then
                   if [ $DEBUG = "1" ]; then echo "set config"; fi
                   echo "$loc_str :\t$adv_str ($def) \t$rem_str\t\t\t$conf_str \tset configuration "
                else  
		   if [ $DEBUG = "1" ]; then echo "error config"; fi    
                   echo "$loc_str :\t$adv_str ($def) \t$rem_str\t\t\t$conf_str \terror - change configuration"
                fi
              else
                if [ $DEBUG = "1" ]; then echo "settings remote and local are the same" ; fi
                if [ xx$adv_str != xx$conf_str ]; then
                  if [ $DEBUG = "1" ]; then echo "setting OK, no input in config"; fi
                  echo "$loc_str :\t$adv_str ($def) \t$rem_str \t\t\t$conf_str \tOK,check configfile"
                else
                  if [ $DEBUG = "1" ]; then echo "config OK"; fi
                  echo "$loc_str :\t$adv_str ($def) \t$rem_str \t\t\t$conf_str \tOK"
                fi
             fi
	    else
	    # else $parm != "lp_asm_dir_cap" &&  $parm != "lp_pause_cap" 
	      if [ "$parm" = "lp_asm_dir_cap" ]; then
		rem_str=`ndd /dev/$mod  lp_asm_dir_cap `
		adv_str=`ndd /dev/$mod  asm_dir_cap `
		echo "asm_dir_cap :\t$adv_str  \t$rem_str \t\t[ ONLY A DISPLAY INFORMATION ]"
	      fi
	      if [ "$parm" = "lp_pause_cap" ]; then
                rem_str=`ndd /dev/$mod  lp_pause_cap `
                adv_str=`ndd /dev/$mod  pause_cap `
                echo "pause_cap :\t$adv_str  \t$rem_str \t\t[ ONLY A DISPLAY INFORMATION ]"
	      fi
           fi
	  done
	  echo "\n\tspezial settings of interface $mod$inst \n\t-----------------------------------"
	  OTHER1="lance_mode ipg0 ipg1 ipg2 pace_size transceiver_inuse use_int_xcvr"
              MODE=`ndd -get /dev/$mod lance_mode  `
              echo "\tlance_mode \t\t: $MODE "
              MODE=`ndd -get /dev/$mod ipg0  `
              echo "\tipg0 \t\t\t: $MODE "
              MODE=`ndd -get /dev/$mod ipg1  `
              echo "\tipg1 \t\t\t: $MODE "
              MODE=`ndd -get /dev/$mod ipg2  `
              echo "\tipg2 \t\t\t: $MODE "
	    if [ $mod != "ge" ]; then
              MODE=`ndd -get /dev/$mod pace_size  `
              echo "\tpace_size \t\t: $MODE "
              MODE=`ndd -get /dev/$mod transceiver_inuse  `
              echo "\ttransceiver_inuse \t: $MODE "
              MODE=`ndd -get /dev/$mod use_int_xcvr  `
              echo "\tuse_int_xcvr \t\t: $MODE "
	     else
		# speccial for module ge
             	ts=`ndd /dev/$mod adv_pauseTX 2>/dev/null `
             	tr=`ndd /dev/$mod adv_pauseRX 2>/dev/null `
             	echo "\tadv_pauseTX \t\t: $ts   "
             	echo "\tadv_pauseRX \t\t: $tr  "
	    fi
	    echo "\n\thardware is located on\t: $INFO "
     done
	;;
   '2')
     TMPNK=/tmp/netstat-k
     netstat -k | grep -i "^$mod[0-9][0-9,:]" | awk '{ print substr($1,1,length($1)-1 ) }' \
                | while read card rest; do

       inst=`echo $card | awk '{ print substr($1,3,length($1) ) }' `
       ndd -set /dev/$mod instance $inst 
       echo " "
       NETCARD=/tmp/netstat-k-$card
        netstat -k $card > /tmp/$card
	cat /tmp/$card | awk '{ for(i=1;i<=NF;i++){ print $i" "$(i+1);i++; } }' > $NETCARD

        ceservice="lp_cap_autoneg lp_cap_100T4 lp_cap_1000fdx lp_cap_1000hdx lp_cap_100fdx lp_cap_100hdx lp_cap_10fdx lp_cap_10hdx lp_cap_asmpause lp_cap_pause"

                     echo "$inst">/tmp/.nhelp2 2>/dev/null
                     cat /tmp/.nddhelp 2>/dev/null >> /tmp/.nhelp2 2>/dev/null
                     INFO=`awk '{ if(NF==1){T=$1}else{ if(T==$2){print $1} } }' /tmp/.nhelp2 2>/dev/null`
                     if [ "$INFO" = "" ]; then INFO="not found in /etc/path_to_inst"; fi

        echo "\nconfiguration for : $mod$inst "

          MODE=`grep -i link_duplex $NETCARD | awk ' {print $2}' `
        STATUS=`grep -i link_up     $NETCARD | awk ' {print $2}' `
         SPEED=`grep -i link_speed  $NETCARD | awk ' {print $2}' `
         LINK_ASM=`grep -i link_asmpause $NETCARD | awk ' {print $2}' `
	 LINK_PAU=`grep -i link_pause $NETCARD | awk ' {print $2}' `

        echo "\n\tLink status:\t$STATUS, Link speed:\t$SPEED, Link mode:\t$MODE ";
        echo "\t\tLink asmpause:\t$LINK_ASM, Link pause:\t$LINK_PAU\n";


          echo "Option   \t$mod$inst\tSwitch/HUB\tuse in $CONFDAT"
          echo "--------------------------------------------------------------------"
          for parm in $ceservice; do

           if [ $DEBUG = "1" ]; then echo $parm ; fi

             loc_str=`echo $parm | nawk '{print substr($1,8,length($1))"_cap"}' `
             if [ DEBUG = "1" ]; then echo adv_$loc_str ; fi
             adv_str=`ndd /dev/$mod adv_$loc_str`
             rem_str=`grep -i "^$parm "    $NETCARD | awk '{print $2}'`
             conf_str=`grep adv_$loc_str $CONFDAT 2>/dev/null | grep -v \# | grep \;$mod\;$inst\; | awk '{ print substr($1,length($1),length($1) ) } '`
	     def=`echo $parm | nawk '{print substr($1,4,length($1))}' `
	     def=`grep -i "^$def "   $NETCARD | awk '{print $2}'`

             if [ $DEBUG = "1" ]; then echo "conf_str : $conf_str\#" ; fi
             pause=`echo $parm | grep -v "pause" | wc -l | awk '{ print $1 }'  `
             if [ $pause -ne 0 ]; then
              if [ xx$adv_str != xx$rem_str ]; then
                if [ $DEBUG = "1" ]; then echo "settings remote and local are  not the same" ; fi
                if [ xx$adv_str != xx$conf_str ]; then
                   if [ $DEBUG = "1" ]; then echo "set config"; fi
                   echo "$loc_str:\t$adv_str ($def) \t$rem_str\t\t\t$conf_str \tset configuration "
                else  
                   if [ $DEBUG = "1" ]; then echo "error config"; fi    
                   echo "$loc_str :\t$adv_str ($def) \t$rem_str\t\t\t$conf_str \terror - change configuration"
                fi
               else
                if [ $DEBUG = "1" ]; then echo "settings remote and local are the same" ; fi
                if [ xx$adv_str != xx$conf_str ]; then
                  if [ $DEBUG = "1" ]; then echo "setting OK, no input in config"; fi
                  echo "$loc_str :\t$adv_str ($def) \t$rem_str \t\t\t$conf_str \tOK,check configfile"
                 else
                  if [ $DEBUG = "1" ]; then echo "config OK"; fi
                  echo "$loc_str :\t$adv_str ($def) \t$rem_str \t\t\t$conf_str \tOK"
                fi
              fi
             else
               echo "$loc_str :\t$adv_str ($def) \t$rem_str \t\t[ ONLY A DISPLAY INFORMATION ]"
             fi
          done
          echo "\n\tspezial settings of interface $mod$inst \n\t-----------------------------------"
	  # (accept_jumbo -> not in v1.121 SunOS 5.9)
	  OTHER1="master_cfg_value master_cfg_enable ipg0 ipg1 ipg2 enable_ipg0 use_int_xcvr disable_64bit infinite_burst accept_jumbo rx_intr_pkts rx_intr_time red_dv4to6k red_dv6to8k red_dv8to10k red_dv10to12k tx_dma_weight rx_dma_weight"
	  for t in $OTHER1; do
		MODE=`ndd -get /dev/$mod $t 2>/dev/null `
	        echo "$t $MODE" | awk '{t="";l=length($1);for(i=2;i<=NF;i++){t=t" "$i;};if(l<=7){s="\t"$1"\t\t\t:"t}else{if(l<=14){s="\t"$1"\t\t:"t;}else{s="\t"$1"\t:"t;};} }END{print s}'	
	  done

	      echo "\n\thardware is located on\t: $INFO "
       done
	;;
   '3') 
	if [ $DEBUG -ge 1 ]; then echo "cardtype $CARDTYP not implemented yet - testing mode" ; fi
	for inst in $MAXINSTANCE; do
	    if [ ! -r /dev/$mod$inst ]; then  continue; fi
		INFO=`grep "$inst \"$mod\"" /etc/path_to_inst | awk '{ print $1 }' 2>/dev/null`
                if [ "$INFO" = "" ]; then INFO="not found in /etc/path_to_inst"; fi

         echo " "
         check_remote
         if [ $DEBUG = "1" ]; then echo $REMOTE; fi
         if [ $REMOTE = "1" ]; then
           echo "\nconfiguration for : $mod$inst \c"
          else
           echo "\nno remote configuration exist "
           echo "configuration for : $mod$inst  \c"
         fi
         if [ "$OS" = "5.8" ] && [ "$ipforward" -ge 1 ]; then
            ipforward_int=`ndd -get /dev/ip $mod$inst:ip_forwarding`
            case "$ipforward_int" in
             0)   echo "\t routing on these interface is : disabled" ;;
             1)   echo "\t routing on these interface is : enabled" ;;
             *)   echo "\t value $mod$inst:ip_forwarding not exist in /dev/ip";;
            esac
         else echo " "; fi

	    if [ "$mod" != "dmfe" ]; then 
	      MODE=`ndd -get /dev/$mod$inst link_duplex | awk '{ if(NR==1){print $1} }' `
	     else
	      MODE=`ndd -get /dev/$mod$inst link_mode | awk '{ if(NR==1){print $1} }' `
	    fi
	    STATUS=`ndd -get /dev/$mod$inst link_status | awk '{ if(NR==1){print $1} }' `
	     SPEED=`ndd -get /dev/$mod$inst link_speed  | awk '{ if(NR==1){print $1} }' `

	    echo "\n\tLink status:\t$STATUS, Link speed:\t$SPEED, Link mode:\t$MODE "; 
	    echo 
            echo "Linkoption   \t\t$mod$inst\tSwitch/HUB\tuse in $CONFDAT"
            echo "----------------------------------------------------------------------------"

	    ndd -get /dev/$mod$inst \? | grep "adv_" | while read param rest;  do
		# echo "$param"
		loc_str=`echo "$param" | awk 'BEGIN{FS="_"}{ s=""; for(i=2;i<=NF;i++){ s=s"_"$i;} } END{print substr(s,2,length(s))}' `
		adv_str=`ndd -get /dev/$mod$inst $param `
	   	rem_str=`ndd -get /dev/$mod$inst lp_$loc_str 2>/dev/null | awk '{ if(NF==1){print $1}else{print "N/A"} }' `	
		    def=`ndd -get /dev/$mod$inst    $loc_str 2>/dev/null | awk '{ if(NF==1){print "("$1")"} }' `
		if [ "$rem_str" = "" ]; then rem_str="N/A"; fi
                conf_str=`grep "$param" $CONFDAT 2>/dev/null | grep ";$mod;$inst;" | grep -v "#" | awk 'BEGIN{FS=";"}{print $NF}' `
		NSIZE=`echo "$loc_str" | awk '{print length($1) }' `
		if [ $NSIZE -le 13 ]; then
			START="$loc_str :\t\t"
		 else
			START="$loc_str :\t"
		fi
		INFO1=""
              	if [ "$adv_str" != "$rem_str" ] && [ "$rem_str"  != "N/A" ]; then
                	if [ $DEBUG = "1" ]; then echo "settings remote and local are  not the same" ; fi
                	if [ "$adv_str" != "$conf_str" ]; then
                   		if [ $DEBUG = "1" ]; then echo "set config"; fi
                   		INFO1="set configuration "
                	else
                   		if [ $DEBUG = "1" ]; then echo "error config"; fi
                   		INFO1="error - change configuration"
                	fi
                  else
                	if [ $DEBUG = "1" ]; then echo "settings remote and local are the same" ; fi
                	if [ "$adv_str" != "$conf_str" ]; then
                  		if [ $DEBUG = "1" ]; then echo "setting OK, no input in config"; fi
                  		INFO1="OK,check configfile"
                 	 else
                  		if [ $DEBUG = "1" ]; then echo "config OK"; fi
                  		INFO1="OK"
                	fi
              	fi
		echo "$START$adv_str $def \t$rem_str \t\t\t$conf_str \t$INFO1"
	    done
	    echo "\n\tspezial settings of interface $mod$inst \n\t-----------------------------------"
	    OTHER1=`ndd -get /dev/$mod$inst \? | grep -v "adv_" | grep -v link | grep -v "?" | awk 'BEGIN{s=""}{s=s" "$1}END{print s}'  `
	    for tinfo in $OTHER1; do
              MODE=`ndd -get /dev/$mod$inst $tinfo  `
              echo "\t$tinfo \t\t: $MODE "
	    done
            echo "\n\thardware is located on\t: $INFO "

	done
	;;
    *) echo "card $mod not implemented yet"
	;;
   esac
  done
  ls -l /tmp/netstat-k-ce[0-9]* 2>&1| grep -v "such" | awk '{ print $NF}' | while read pa rest; do rm -r $pa; done
  ls -l /tmp/ce[0-9]*   2>&1    | grep -v "such" | awk '{ print $NF}' | while read pa rest; do rm -r $pa; done

   rm -r /tmp/.nhelp2 /tmp/.nddhelp 2>/dev/null
}

check_netstat()
{
 if [ $DEBUG != "0" ]; then echo "check NETSTAT"; fi
 if [ ! -d /tmp/.ndd ]; then mkdir /tmp/.ndd; fi
  TMPPN=/tmp/.ndd/netstat-pn
  TMPNK=/tmp/.ndd/netstat-k
 TMPNKI=/tmp/.ndd/netstat-k-index
   TMPS=/tmp/.ndd/netstat-s
 IFCONF=/tmp/.ndd/ifconfig-a
 IFCONFM=/tmp/.ndd/ifconfig-a-modules

 if [ $DEBUG != "0" ]; then echo "check NETSTAT" ; fi
 /usr/bin/netstat -pn > $TMPPN 
 /usr/bin/netstat -k > $TMPNK
 /usr/bin/netstat -s > $TMPS
 /usr/sbin/ifconfig -a > $IFCONF
 grep -in ":" $TMPNK  | awk ' { print NR":"substr($1,1,length($1)-1) }' > $TMPNKI

 echo "Kernel...\c"
 cat $IFCONF | grep "RUNNING" | grep -v IPv6 | awk ' { print substr($1,1,length($1)-1) }' > $IFCONFM
 cat $IFCONFM | while read card rest; do
   co=`echo $card | grep -v ":" | wc -l | awk '{print $1}'`
   if [ "xx$co" != "xx0" ]; then
     if [ $DEBUG != "0" ]; then  echo "\n$card $co"; fi
     NETCARD=/tmp/.ndd/netstat-k-$card
     if [ -x /usr/bin/kstat ]; then
	 kstat -p | grep "$card" | awk 'BEGIN{FS=":"}{print $NF}' | awk '{print $1" "$2}' > $NETCARD
      else
     netstat -k $card > /tmp/.ndd/$card
     cat /tmp/.ndd/$card \
         | awk '/^[a-z]/{print $1" "$2} $3!=" "{print $3" "$4} $5!=" "{print $5" "$6} $7!=" "{print $7" "$8} $9!=" "{print $9" "$10} $11!=" "{print $11" "$12}' \
         | awk '/^[a-z]/ {print $1" "$2}' > $NETCARD 
     fi

      ierrors=`grep -i "^ierrors "  $NETCARD | awk 'BEGIN{s=0}{s=$2}END{print s}' `
     ipackets=`grep -i "^ipackets " $NETCARD | awk '{print $2}' `
      oerrors=`grep -i "^oerrors "  $NETCARD | awk 'BEGIN{s=0}{s=$2}END{print s}' `
     opackets=`grep -i "^opackets " $NETCARD | awk '{print $2}' `
     if [ $DEBUG -ge 1 ]; then
	echo "IPACKETS :$ipackets:  Err :$ierrors:"
	echo "0PACKETS :$opackets:  Err :$oerrors:"
     fi
     if [ "$ierrors" -ge 1 ] || [ "$oerrors" -ge 1 ]; then
        if [ $ipackets -ge 1 ]; then iproz=`expr $ierrors \* 100 / $ipackets`; else iproz="0"; fi
        if [ $opackets -ge 1 ]; then oproz=`expr $oerrors \* 100 / $opackets`; else oproz="0"; fi
	echo "$ierrors" >>/tmp/.netstat_comp
	echo "$oerrors" >>/tmp/.netstat_comp
        if [ $DEBUG != "0" ]; then echo "\n$card - IPack:$ipackets IErr:$ierrors ($iproz %) OPack:$opackets OErr:$oerrors ($oproz %)"; fi 
        if [ "$SYSLOG" = "1" ]; then 
           if [ $iproz -ge 1 ]; then LOGINFOTYP="$card netstat.info ] "; LOGINFO="receive packets/errors/errors in percent : $ipackets / $ierrors / $iproz % "; syslog;fi
           if [ $oproz -ge 1 ]; then LOGINFOTYP="$card netstat.info ] "; LOGINFO="send packets/errors/errors in percent : $opackets / $oerrors / $oproz % "; syslog;  fi
        fi
        # if [ $iproz -ge 1 ] || [ $oproz -ge 1 ]; then 
           if [ $DEBUG != "0" ]; then echo "\n$card - IPack:$ipackets IErr:$ierrors ($iproz %) OPack:$opackets OErr:$oerrors ($oproz %)"; fi
           echo "\n\n\t\t$card\t\t: Packets\tErrors\tPercent"           
           if [ "$ierrors" != "0" ]; then echo "\t\t\tInput\t: $ipackets\t$ierrors\t$iproz %" ;fi
           if [ "$oerrors" != "0" ]; then echo "\t\t\tOutput\t: $opackets\t$oerrors\t$oproz %" ;fi 

              echo "\n\t\t\tDescription\t\t\t: Count"
              echo "\t\t\t___________________________________________"

                     inetColl=`grep -i "^collisions"     $NETCARD | awk '{print $2}'   `
                     if [ "xx$inetColl"  = "xx" ]; then inetColl=`grep -i "^rx_collisions" $NETCARD | awk '{print $2}'   `  
                        else if [ "xx$inetColl"  = "0xx" ]; then inetColl=`grep -i "^rx_collisions" $NETCARD | awk '{print $2}'`; 
                               else inet=`grep -i "^rx_collisions" $NETCARD | awk '{print $2}'`
                                    if [ "xx$inet" != "xx" ]; then inetColl=`expr $inetColl + $inet `;fi; fi 
                     fi
		     inetExtColl=`grep -i "^ex_collisions"     $NETCARD | awk '{print $2}'   `
		     inetMulColl=`grep -i "^multi_collisions"     $NETCARD | awk '{print $2}'   `
                 if [  "xx$inetColl" != "xx" ] && [  "$inetColl" -ge 1 ]; then
                    if [ "$SYSLOG" = "1" ]; then 
                       s=`expr $inetColl \* 100 / \( $opackets + $ipackets \)   `
                       if [ "$s" -ge 10 ] ; then 
                         LOGINFOTYP="$card netstat.crit ] ";LOGINFO="high hollsions rate on network - count $inetColl";syslog; 
                        else 
                          if [ "$s" -ge 4 ]; then 
                             LOGINFOTYP="$card netstat.err ] ";LOGINFO="high collsions on network - count $inetColl / $s % of packets";syslog 
                           else 
                           if [ "$s" -ge 1 ]; then
                             LOGINFOTYP="$card netstat.warn ] ";LOGINFO="collsions on network - count $inetColl / $s % of packets";syslog
                           else LOGINFOTYP="$card netstat.info ] ";LOGINFO="collsions on network - count $inetColl / $s % of packets";syslog; fi
                          fi
                       fi
                    fi
                    echo "\t\t\tNetwork Collisions found\t: $inetColl" 
		    if [ "$inetExtColl" -ge 10 ]; then
			echo "\t\t\tNetwork Ext. Collisions found\t: $inetExtColl"
		    fi
		    if [ "$inetMulColl" -ge 10 ]; then
			echo "\t\t\tNetwork Multi-Collisions found\t: $inetMulColl"
		    fi
                 fi


                    inetFColl=`grep -i "^first_coll"    $NETCARD | awk '{print $2}'   `
                 if [  "xx$inetFColl" != "xx" ] && [  "$inetFColl" -ge 1 ]; then
                    if [ "$SYSLOG" = "1" ]; then LOGINFOTYP="$card netstat.warn ] "; LOGINFO="first collsions on network - count $inetFColl";syslog; fi
                    echo "\t\t\tNetwork First Collisions found\t: $inetFColl" 
                 fi

                  inetLatColl=`grep -i "^late_coll"     $NETCARD | awk '{print $2}'   `
                     if [ "xx$inetLatColl" = "xx" ]; then inetLatColl=`grep -i "^rx_late_coll" $NETCARD | awk '{print $2}'   ` 
                        else inet=`grep -i "^rx_late_coll" $NETCARD | awk '{print $2}'   `
                             if [ "xx$inet" != "xx" ]; then inetLatColl=`expr $inetLatColl + $inet`;fi ; fi
                     if [ "xx$inetLatColl" = "xx" ]; then inetLatColl=`grep -i "^tx_late_coll" $NETCARD | awk '{print $2}'   `
                        else inet=`grep -i "^tx_late_coll" $NETCARD | awk '{print $2}'   `
                             if [ "xx$inet" != "xx" ]; then inetLatColl=`expr $inetLatColl + $inet`;fi ; fi
                     if [ "xx$inetLatColl" = "xx" ]; then inetLatColl=`grep -i "^rlcol "       $NETCARD | awk '{print $2}'   `
                        else inet=`grep -i "^rlcol "       $NETCARD | awk '{print $2}'   `
                             if [ "xx$inet" != "xx" ]; then inetLatColl=`expr $inetLatColl + $inet`;fi ; fi
                     if [ "xx$inetLatColl" = "xx" ]; then inetLatColl=`grep -i "^tlcol "       $NETCARD | awk '{print $2}'   `
                        else inet=`grep -i "^tlcol "       $NETCARD | awk '{print $2}' `
                             if [ "xx$inet" != "xx" ]; then inetLatColl=`expr $inetLatColl + $inet`;fi ; fi
                 if [  "xx$inetLatColl" != "xx" ] && [  "$inetLatColl" -ge 1 ]; then
                    if [ "$SYSLOG" = "1" ]; then LOGINFOTYP="$card netstat.err ]"; LOGINFO="late collsions on network - count $inetLatColl";syslog; fi
                    echo "\t\t\tLate Network Collisions found\t: $inetLatColl" 
                 fi


                  inetFraming=`grep -i "^framing"       $NETCARD | awk '{print $2}'   ` 
                     if [ "xx$inetFraming" = "xx" ]; then inetFraming=`grep -i "^framming" $NETCARD | awk '{print $2}'   `
                        else inet=`grep -i "^framming" $NETCARD | awk '{print $2}'   `
                             if [ "xx$inet" != "xx" ]; then inetFraming=`expr $inetFraming + $inet`;fi ; fi
                     if [ "xx$inetFraming" = "xx" ]; then inetFraming=`grep -i "^fram"     $NETCARD | awk '{print $2}'   `
                        else inet=`grep -i "^fram"     $NETCARD | awk '{print $2}'   `
                             if [ "xx$inet" != "xx" ]; then inetFraming=`expr $inetFraming + $inet`;fi; fi
                 if [  "xx$inetFraming" != "xx" ] && [  "$inetFraming" -ge 1 ]; then
                    if [ "$SYSLOG" = "1" ]; then LOGINFOTYP="$card netstat.err ] "; LOGINFO="framing errors on interface - count $inetFraming";syslog; fi
                    echo "\t\t\tFraming Errors found\t\t: $inetFraming"
                 fi

                      inetCRC=`grep -i "^crc "          $NETCARD | awk '{print $2}'   ` 
                     if [ "xx$inetCRC" = "xx" ]; then inetCRC=`grep -i "^crc_err"          $NETCARD | awk '{print $2}'   `
                        else inet=`grep -i "^crc_err"          $NETCARD | awk '{print $2}'   `
                             if [ "xx$inet" != "xx" ]; then inetCRC=`expr $inetCRC + $inet`;fi ;fi
                     if [ "xx$inetCRC" = "xx" ]; then inetCRC=`grep -i "^rx_crc_err "      $NETCARD | awk '{print $2}'   `
                        else inet=`grep -i "^rx_crc_err "      $NETCARD | awk '{print $2}'   `
                             if [ "xx$inet" != "xx" ]; then inetCRC=`expr $inetCRC + $inet`;fi ;fi
                     if [ "xx$inetCRC" = "xx" ]; then inetCRC=`grep -i "^badcrc "          $NETCARD | awk '{print $2}'   `
                        else inet=`grep -i "^badcrc "          $NETCARD | awk '{print $2}'   `
                             if [ "xx$inet" != "xx" ]; then inetCRC=`expr $inetCRC + $inet`;fi ;fi
                     if [ "xx$inetCRC" = "xx" ]; then inetCRC=`grep -i "^fcs_errors "      $NETCARD | awk '{print $2}'   `
                        else inet=`grep -i "^fcs_errors "      $NETCARD | awk '{print $2}'   `
                             if [ "xx$inet" != "xx" ]; then inetCRC=`expr $inetCRC + $inet`;fi ;fi
                     if [ "xx$inetCRC" = "xx" ]; then inetCRC=`grep -i "^rx_corr "          $NETCARD | awk '{print $2}'   `
                        else inet=`grep -i "^rx_corr "          $NETCARD | awk '{print $2}'   `
                             if [ "xx$inet" != "xx" ]; then inetCRC=`expr $inetCRC + $inet`;fi ;fi
                     if [ "xx$inetCRC" = "xx" ]; then inetCRC=`grep -i "^mboxcrc"          $NETCARD | awk '{print $2}'   `
                        else inet=`grep -i "^mboxcrc"          $NETCARD | awk '{print $2}'   `
                             if [ "xx$inet" != "xx" ]; then inetCRC=`expr $inetCRC + $inet`;fi ;fi
                 if [  "xx$inetCRC" != "xx" ] && [  "$inetCRC" -ge 1 ]; then
                    if [ "$SYSLOG" = "1" ]; then LOGINFOTYP="$card netstat.err ] ";LOGINFO="crc errors on interface - count $inetCRC";syslog; fi
                    echo "\t\t\tCRC Errors found\t\t: $inetCRC" 
                 fi


                      inetSQE=`grep -i "^sqe "          $NETCARD | awk '{print $2}'   ` 
                     if [ "xx$inetSQE" = "xx" ]; then inetSQE=`grep -i "^sqe_error"         $NETCARD | awk '{print $2}'   `
                        else inet=`grep -i "^sqe_error"         $NETCARD | awk '{print $2}'   `
                             if [ "xx$inet" != "xx" ]; then inetSQE=`expr $inetSQE + $inet`;fi ;fi
                 if [  "xx$inetSQE" != "xx" ] && [  "$inetSQE" -ge 1 ]; then
                    if [ "$SYSLOG" = "1" ]; then LOGINFOTYP="$card netstat.err ] ";LOGINFO="sqe errors on interface - count $inetSQE";syslog; fi
                    echo "\t\t\tSQE Errors found\t\t: $inetSQE" 
                 fi


                   inetCodVio=`grep -i "^code_vio"      $NETCARD | awk '{print $2}'   ` 
                     if [ "xx$inetCodVio" = "xx" ]; then inetCodVio=`grep -i "^rx_code_viol_err" $NETCARD | awk '{print $2}'   `
                        else inet=`grep -i "^rx_code_viol_err" $NETCARD | awk '{print $2}'   `
                             if [ "xx$inet" != "xx" ]; then inetCodVio=`expr $inetCodVio + $inet`;fi ;fi
                 if [  "xx$inetCodVio" != "xx" ] && [  "$inetCodVio" -ge 1 ]; then
                    if [ "$SYSLOG" = "1" ]; then LOGINFOTYP="$card netstat.err ] ";LOGINFO="code violations on interface - count $inetCodVio";syslog; fi
                    echo "\t\t\tCode Violations found\t\t: $inetCodVio" 
                 fi


                   inetParity=`grep -i "^parity_error"       $NETCARD | awk '{print $2}'   `
                     if [ "xx$inetParity" = "xx" ]; then inetParity=`grep -i "^rx_parity_error"  $NETCARD | awk '{print $2}'   `
                        else inet=`grep -i "^rx_parity_error"  $NETCARD | awk '{print $2}'   `
                             if [ "xx$inet" != "xx" ]; then inetParity=`expr $inetParity + $inet`;fi ;fi
                     if [ "xx$inetParity" = "xx" ]; then inetParity=`grep -i "^tx_parity_error"  $NETCARD | awk '{print $2}'   `
                        else inet=`grep -i "^tx_parity_error"  $NETCARD | awk '{print $2}'   `
                             if [ "xx$inet" != "xx" ]; then inetParity=`expr $inetParity + $inet`;fi ;fi
                     if [ "xx$inetParity" = "xx" ]; then inetParity=`grep -i "^slv_parity_error" $NETCARD | awk '{print $2}'   `
                        else inet=`grep -i "^slv_parity_error" $NETCARD | awk '{print $2}'   `
                             if [ "xx$inet" != "xx" ]; then inetParity=`expr $inetParity + $inet`;fi ;fi
                 if [  "xx$inetParity" != "xx" ] && [  "$inetParity" -ge 1 ]; then
                    if [ "$SYSLOG" = "1" ]; then LOGINFOTYP="$card netstat.err ] ";LOGINFO="parity errors on interface - count $inetParity";syslog; fi
                    echo "\t\t\tParity Errors found\t\t: $inetParity" 
                 fi


                   inetLenErr=`grep -i "^len_errors"       $NETCARD | awk '{print $2}'   ` 
                     if [ "xx$inetLenErr" = "xx" ]; then inetLenErr=`grep -i "^lenght_err" $NETCARD | awk '{print $2}'   `
                        else inet=`grep -i "^lenght_err" $NETCARD | awk '{print $2}'   `
                             if [ "xx$inet" != "xx" ]; then inetLenErr=`expr $inetLenErr + $inet`;fi ;fi
                     if [ "xx$inetLenErr" = "xx" ]; then inetLenErr=`grep -i "^toolong_errors" $NETCARD | awk '{print $2}'   `
                        else inet=`grep -i "^toolong_errors" $NETCARD | awk '{print $2}'   `
                             if [ "xx$inet" != "xx" ]; then inetLenErr=`expr $inetLenErr + $inet`;fi ;fi
                     if [ "xx$inetLenErr" = "xx" ]; then inetLenErr=`grep -i "^rx_length_err" $NETCARD | awk '{print $2}'   `
                        else inet=`grep -i "^rx_length_err" $NETCARD | awk '{print $2}'   `
                             if [ "xx$inet" != "xx" ]; then inetLenErr=`expr $inetLenErr + $inet`;fi ;fi
                 if [  "xx$inetLenErr" != "xx" ] && [  "$inetLenErr" -ge 1 ]; then
                    if [ "$SYSLOG" = "1" ]; then LOGINFOTYP="$card netstat.err ] ";LOGINFO="len_errors on interface - count $inetLenErr";syslog; fi
                    echo "\t\t\tLen Errors found\t\t: $inetLenErr" 
                 fi


                 inetRetryErr=`grep -i "^retry_err"     $NETCARD | awk '{print $2}'   ` 
                     if [ "xx$inetRetryErr" = "xx" ]; then inetRetryErr=`grep -i "^xmtretry " $NETCARD | awk '{print $2}'   ` 
                        else inet=`grep -i "^xmtretry " $NETCARD | awk '{print $2}'   `
                             if [ "xx$inet" != "xx" ]; then inetRetryErr=`expr $inetRetryErr + $inet`;fi ;fi
                     if [ "xx$inetRetryErr" = "xx" ]; then inetRetryErr=`grep -i "^trtry " $NETCARD | awk '{print $2}'   `
                        else inet=`grep -i "^trtry " $NETCARD | awk '{print $2}'   `
                             if [ "xx$inet" != "xx" ]; then inetRetryErr=`expr $inetRetryErr + $inet`;fi ;fi
                 if [  "xx$inetRetryErr" != "xx" ] && [  "$inetRetryErr" -ge 1 ]; then
                    if [ "$SYSLOG" = "1" ]; then LOGINFOTYP="$card netstat.err ] ";LOGINFO="retry errors on network - count $inetRetryErr";syslog; fi
                    echo "\t\t\tRetry Errors found\t\t: $inetRetryErr" 
                 fi


                 inetNoCarrie=`grep -i "^nocarrier"     $NETCARD | awk '{print $2}'   ` 
                     if [ "xx$inetNoCarrie" = "xx" ]; then inetNoCarrie=`grep -i "^carrier_errors " $NETCARD | awk '{print $2}'   `
                        else inet=`grep -i "^carrier_errors " $NETCARD | awk '{print $2}'   `
                             if [ "xx$inet" != "xx" ]; then inetNoCarrie=`expr $inetNoCarrie + $inet`;fi ;fi
                     if [ "xx$inetNoCarrie" = "xx" ]; then inetNoCarrie=`grep -i "^tnocar "         $NETCARD | awk '{print $2}'   ` 
                        else inet=`grep -i "^tnocar "         $NETCARD | awk '{print $2}'   `
                             if [ "xx$inet" != "xx" ]; then inetNoCarrie=`expr $inetNoCarrie + $inet`;fi ;fi
                 if [  "xx$inetNoCarrie" != "xx" ] && [  "$inetNoCarrie" -ge 1 ]; then
                    if [ "$SYSLOG" = "1" ]; then LOGINFOTYP="$card netstat.err ] ";LOGINFO="lost carrier on interface - count $inetNoCarrie";syslog; fi
                    echo "\t\t\tCarrier Error (lost) found\t: $inetNoCarrie" 
                 fi


                    inetInits=`grep -i "^init"          $NETCARD | awk '{print $2}'   ` 
                     if [ "xx$inetInits" = "xx" ]; then inetInits=`grep -i "^reset    $NETCARD | awk '{print $2}'   `
                        else inet=`grep -i "^reset    $NETCARD | awk '{print $2}'   `
                             if [ "xx$inet" != "xx" ]; then inetInits=`expr $inetInits + $inet`;fi ;fi
                 if [  "xx$inetInits" != "xx" ] && [  "$inetInits" -ge 1 ]; then
                    if [ "$SYSLOG" = "1" ]; then LOGINFOTYP="$card netstat.err ] ";LOGINFO="reinitialize interface - count $inetColl";syslog; fi
                    echo "\t\t\tResets / Reinitialze found\t: $inetInits" 
                 fi


                 inetNoCanput=`grep -i "^nocanput"      $NETCARD | awk '{print $2}'   ` 
                    if [ "xx$inetNoCanput" = "xx" ]; then inetNoCanput=`grep -i "^no_canput"      $NETCARD | awk '{print $2}'   `
                        else inet=`grep -i "^no_canput"      $NETCARD | awk '{print $2}'   `
                             if [ "xx$inet" != "xx" ]; then inetNoCanput=`expr $inetNoCanput + $inet`;fi ;fi
                    if [ "xx$inetNoCanput" = "xx" ]; then inetNoCanput=`grep -i "^cannotput"      $NETCARD | awk '{print $2}'   `
                        else inet=`grep -i "^cannotput"      $NETCARD | awk '{print $2}'   `
                             if [ "xx$inet" != "xx" ]; then inetNoCanput=`expr $inetNoCanput + $inet`;fi ;fi
                    if [ "xx$inetNoCanput" = "xx" ]; then inetNoCanput=`grep -i "^rx_nocanput"    $NETCARD | awk '{print $2}'   `
                        else inet=`grep -i "^rx_nocanput"    $NETCARD | awk '{print $2}'   `
                             if [ "xx$inet" != "xx" ]; then inetNoCanput=`expr $inetNoCanput + $inet`;fi ;fi
                    if [ "xx$inetNoCanput" = "xx" ]; then inetNoCanput=`grep -i "^tx_nocanput"    $NETCARD | awk '{print $2}'   `
                        else inet=`grep -i "^tx_nocanput"    $NETCARD | awk '{print $2}'   `
                             if [ "xx$inet" != "xx" ]; then inetNoCanput=`expr $inetNoCanput + $inet`;fi ;fi
                 if [  "xx$inetNoCanput" != "xx" ] && [  "$inetNoCanput" -ge 1 ]; then
                    if [ "$SYSLOG" = "1" ]; then LOGINFOTYP="$card netstat.err ] ";LOGINFO="nocanputs - over max. sbus transactions - count $inetColl";syslog; fi
                    echo "\t\t\tNo Canputs (SBUS) found\t\t: $inetNoCanput" 
                 fi


                  inetLateErr=`grep -i "^late_error "     $NETCARD | awk '{print $2}'   ` 
                    if [ "xx$inetLateErr" = "xx" ]; then inetLateErr=`grep -i "^rx_late_error" $NETCARD | awk '{print $2}'   `
                        else inet=`grep -i "^rx_late_error" $NETCARD | awk '{print $2}'   `
                             if [ "xx$inet" != "xx" ]; then inetLateErr=`expr $inetLateErr + $inet`;fi ;fi
                    if [ "xx$inetLateErr" = "xx" ]; then inetLateErr=`grep -i "^tx_late_error" $NETCARD | awk '{print $2}'   `
                        else inet=`grep -i "^tx_late_error" $NETCARD | awk '{print $2}'   `
                             if [ "xx$inet" != "xx" ]; then inetLateErr=`expr $inetLateErr + $inet`;fi ;fi
                 if [  "xx$inetLateErr" != "xx" ] && [  "$inetLateErr" -ge 1 ]; then
                    if [ "$SYSLOG" = "1" ]; then LOGINFOTYP="$card netstat.err ] ";LOGINFO="late errors on network - count $inetLateErr";syslog; fi
                    echo "\t\t\tLate Errors on Network found\t: $inetLateErr" 
                 fi

                   inetMissed=`grep -i "^missed"        $NETCARD | awk '{print $2}'   `
                 if [  "xx$inetMissed" != "xx" ] && [  "$inetMissed" -ge 1 ]; then
                    if [ "$SYSLOG" = "1" ]; then LOGINFOTYP="$card netstat.err ] ";LOGINFO="receive missed packets from network - count $inetMissed";syslog; fi
                    echo "\t\t\tMissed Packets found\t\t: $inetMissed" 
                 fi


                 inetNoTXBuff=`grep -i "^no_tbufs"       $NETCARD | awk '{print $2}'   ` 
                    if [ "xx$inetNoTXBuff" = "xx" ]; then inetNoTXBuff=`grep -i "^notbufs "     $NETCARD | awk '{print $2}'   `
                        else inet=`grep -i "^notbufs "     $NETCARD | awk '{print $2}'   `
                             if [ "xx$inet" != "xx" ]; then inetNoTXBuff=`expr $inetNoTXBuff + $inet`;fi ;fi
                    if [ "xx$inetNoTXBuff" = "xx" ]; then inetNoTXBuff=`grep -i "^noxmtbuf "    $NETCARD | awk '{print $2}'   `
                        else inet=`grep -i "^noxmtbuf "    $NETCARD | awk '{print $2}'   `
                             if [ "xx$inet" != "xx" ]; then inetNoTXBuff=`expr $inetNoTXBuff + $inet`;fi ;fi
                    if [ "xx$inetNoTXBuff" = "xx" ]; then inetNoTXBuff=`grep -i "^outoftbuf "   $NETCARD | awk '{print $2}'   `
                        else inet=`grep -i "^outoftbuf "     $NETCARD | awk '{print $2}'   `
                             if [ "xx$inet" != "xx" ]; then inetNoTXBuff=`expr $inetNoTXBuff + $inet`;fi ;fi
                    if [ "xx$inetNoTXBuff" = "xx" ]; then inetNoTXBuff=`grep -i "^notxbufs "    $NETCARD | awk '{print $2}'   `
                        else inet=`grep -i "^notxbufs "     $NETCARD | awk '{print $2}'   `
                             if [ "xx$inet" != "xx" ]; then inetNoTXBuff=`expr $inetNoTXBuff + $inet`;fi ;fi
                    if [ "xx$inetNoTXBuff" = "xx" ]; then inetNoTXBuff=`grep -i "^fcips_noxmtbuf" $NETCARD | awk '{print $2}'   `
                        else inet=`grep -i "^fcips_noxmtbuf"     $NETCARD | awk '{print $2}'   `
                             if [ "xx$inet" != "xx" ]; then inetNoTXBuff=`expr $inetNoTXBuff + $inet`;fi ;fi
                 if [  "xx$inetNoTXBuff" != "xx" ] && [  "$inetNoTXBuff" -ge 1 ]; then
                    if [ "$SYSLOG" = "1" ]; then LOGINFOTYP="$card netstat.warn ] ";LOGINFO="no send buffer on interface - count $inetNoTXBuff";syslog; fi
                    echo "\t\t\tNo Send Buffer (XMT) found\t: $inetNoTXBuff" 
                 fi


                 inetNoRXBuff=`grep -i "^no_rbufs "     $NETCARD | awk '{print $2}'   ` 
                    if [ "xx$inetNoRXBuff" = "xx" ]; then inetNoRXBuff=`grep -i "^norbufs" $NETCARD | awk '{print $2}'   `
                        else inet=`grep -i "^norbufs"     $NETCARD | awk '{print $2}'   `
                             if [ "xx$inet" != "xx" ]; then inetNoRXBuff=`expr $inetNoRXBuff + $inet`;fi ;fi
                    if [ "xx$inetNoRXBuff" = "xx" ]; then inetNoRXBuff=`grep -i "^norxbufs " $NETCARD | awk '{print $2}'   `
                        else inet=`grep -i "^norxbufs "     $NETCARD | awk '{print $2}'   `
                             if [ "xx$inet" != "xx" ]; then inetNoRXBuff=`expr $inetNoRXBuff + $inet`;fi ;fi
                    if [ "xx$inetNoRXBuff" = "xx" ]; then inetNoRXBuff=`grep -i "^norcvbuf "  $NETCARD | awk '{print $2}'   `
                        else inet=`grep -i "^norcvbuf "     $NETCARD | awk '{print $2}'   `
                             if [ "xx$inet" != "xx" ]; then inetNoRXBuff=`expr $inetNoRXBuff + $inet`;fi ;fi
                    if [ "xx$inetNoRXBuff" = "xx" ]; then inetNoRXBuff=`grep -i "^rx_no_buf " $NETCARD | awk '{print $2}'   `
                        else inet=`grep -i "^rx_no_buf "     $NETCARD | awk '{print $2}'   `
                             if [ "xx$inet" != "xx" ]; then inetNoRXBuff=`expr $inetNoRXBuff + $inet`;fi ;fi
                    if [ "xx$inetNoRXBuff" = "xx" ]; then inetNoRXBuff=`grep -i "^fcips_norcvbuf " $NETCARD | awk '{print $2}'   `
                        else inet=`grep -i "^fcips_norcvbuf "     $NETCARD | awk '{print $2}'   `
                             if [ "xx$inet" != "xx" ]; then inetNoRXBuff=`expr $inetNoRXBuff + $inet`;fi ;fi
                    if [ "xx$inetNoRXBuff" = "xx" ]; then inetNoRXBuff=`grep -i "^outofrbuf " $NETCARD | awk '{print $2}'   `
                        else inet=`grep -i "^outofrbuf "     $NETCARD | awk '{print $2}'   `
                             if [ "xx$inet" != "xx" ]; then inetNoRXBuff=`expr $inetNoRXBuff + $inet`;fi ;fi
                 if [  "xx$inetNoRXBuff" != "xx" ] && [  "$inetNoRXBuff" -ge 1 ]; then
                    if [ "$SYSLOG" = "1" ]; then LOGINFOTYP="$card netstat.err ] ";LOGINFO="no receive buffer on interface - count $inetNoRXBuff";syslog; fi
                    echo "\t\t\tNo Receive Buffer (RCV) found \t: $inetNoRXBuff" 
                 fi

		 inetblocked=`grep -i "^blocked " $NETCARD | awk '{print $2}'   `
		 if [ "$inetblocked" -ge 1 ]; then
		    echo "\t\t\tBlocked\t\t\t\t: $inetblocked "
		 fi
		 inetunknowns=`grep -i "^unknowns " $NETCARD | awk '{print $2}'   `
		 if [ "$inetunknowns" -ge 1 ]; then
		    echo "\t\t\tUNKNOWNS\t\t\t: $inetunknowns "
		 fi

		 if [ "$UID" -eq 1 ]; then
		 	inetKERNsq=`echo "sq_max_size/X" | adb -k | awk '{ if(NF==2){s=$NF} }END{print s}' `
		 	echo "\n\t\t\tKernelparameter sq_max_size \t: $inetKERNsq hex"
		 fi

        # fi
     fi
   else if [ $DEBUG != "0" ]; then echo "logical card $card"; fi; fi
 done
  TERR=`awk 'BEGIN{s=0}{t=$1+1-1;s=s+t}END{print s}' /tmp/.netstat_comp 2>/dev/null`
  rm -r /tmp/.netstat_comp 2>/dev/null
  if  [  "$TERR" -le 0 ]; then
  	echo "ARP-Tables...\c"   
   else
	echo ""
	echo "checking netstat kernel complete"
	echo "check now kernel ARP-Tables...\c"
  fi
  cat $TMPPN | grep -i ":" | grep -v "IPv" | grep -v "224.0.0.0" | awk '{print $1"-"$2"-"$NF"-"$4}' | while read param rest; do

   INF=`echo $param | awk 'BEGIN{FS="-"}{print $1}' `
   IP=`echo $param | awk 'BEGIN{FS="-"}{print $2}' `
   NETMASK="NONE"
   BR="NONE"
   MAC=`echo $param | awk 'BEGIN{FS="-"}{print $3}' `
   FLAG=`echo $param | awk 'BEGIN{FS="-"}{print $4}' `
   if [ "$FLAG" = "$MAC" ]; then FLAG="0"; else if [ "$FLAG" = "SM" ]; then FLAG="1";fi;if [ "$FLAG" = "SP" ]; then FLAG="2";fi; fi
   byte1=`echo $IP | awk 'BEGIN{FS="."}{print $1}' `
   byte2=`echo $IP | awk 'BEGIN{FS="."}{print $2}' `
   byte3=`echo $IP | awk 'BEGIN{FS="."}{print $3}' `
   byte4=`echo $IP | awk 'BEGIN{FS="."}{print $4}' `
   if [ "$IP" = "$byte1" ]; then IPV6="1"; else IPV6="0"; fi
 
   if [ "$IPV6" -le 0 ]; then
   # Only IPv4
    if [ "$byte1" -le  127 ]; then 
      # echo "Klasse A"
      ASK="$byte1."
    else
      if [ "$byte1" -le  191 ]; then
       #  echo "Klase B"
       ASK="$byte1.$byte2."
      else
       #  echo "Klasse C"
       # grep -i "$byte1.$byte2.$byte3" $IFCONF
       ASK="$byte1.$byte2.$byte3."
      fi
    fi
    L1=`grep -in "$ASK" $IFCONF | awk 'BEGIN{FS=":"} $1 != prev { prev =$1" " prev } END { print prev } ' `
    FOUND="0"
    for LINE in $L1; do
     if [ $FOUND -ne 1 ]; then
     echo "NR == $LINE-1 { print substr(\$1,1,length(\$1)-1 ) } " > /tmp/.t1
     inf1=`awk -f /tmp/.t1  $IFCONF `
     echo "NR == $LINE { print } " > /tmp/.t1
     inf1_param=`awk -f /tmp/.t1  $IFCONF `
     
     inf1_ip=`echo $inf1_param | awk '{ print $2 }' `
     inf1_nt=`echo $inf1_param | awk '{ print substr($4,1,2)" "substr($4,3,2)" "substr($4,5,2)" "substr($4,7,2) }' `
     inf1_br=`echo $inf1_param | awk '{ print $6 }'  `
     # echo "$inf1 = $INF | $inf1_ip = $IP | $inf1_nt = $NETMASK | $inf1_br = $BR  | $L1 $LINE"
     # done
     m1="1 2 3 4";bt="" 
    for b in $m1; do
      case "$b" in
        '1')  byte="$byte1";;
        '2')  byte="$byte2";;
        '3')  byte="$byte3";;
        '4')  byte="$byte4";;
      esac
      echo "{ print \$$b }" > /tmp/.t1
      m=`echo $inf1_nt | awk -f /tmp/.t1 `
      case "$m" in 
        'ff')         if [ "$b" -ge 4 ]; then bt=`expr $bt$byte`; else  bt=`expr $bt$byte.`;fi ;;            
        'fe')         if [ "$b" -ge 4 ]; then bt=`echo $bt | awk '{ print $1 "254"}' `; else bt=`echo $bt | awk '{ print $1 "254."}' `;fi ;;
        'fc')         if [ "$b" -ge 4 ]; then bt=`echo $bt | awk '{ print $1 "253"}' `; else bt=`echo $bt | awk '{ print $1 "253."}' `;fi ;;
        'f8')         if [ "$b" -ge 4 ]; then bt=`echo $bt | awk '{ print $1 "251"}' `; else bt=`echo $bt | awk '{ print $1 "251."}' `;fi ;;
        'f0')         if [ "$b" -ge 4 ]; then bt=`echo $bt | awk '{ print $1 "247"}' `; else bt=`echo $bt | awk '{ print $1 "247."}' `;fi ;;
        'e0')         if [ "$b" -ge 4 ]; then bt=`echo $bt | awk '{ print $1 "239"}' `; else bt=`echo $bt | awk '{ print $1 "239."}' `;fi ;;
        'c0')         if [ "$b" -ge 4 ]; then bt=`echo $bt | awk '{ print $1 "223"}' `; else bt=`echo $bt | awk '{ print $1 "223."}' `;fi ;;
        '80')         if [ "$b" -ge 4 ]; then bt=`echo $bt | awk '{ print $1 "191"}' `; else bt=`echo $bt | awk '{ print $1 "191."}' `;fi ;;
        '00')         if [ "$b" -ge 4 ]; then bt=`echo $bt | awk '{ print $1 "255"}' `; else bt=`echo $bt | awk '{ print $1 "255."}' `;fi ;;
      esac     
     done
      if [ "xx$inf1_br" = "xx$bt" ]; then 
         if [ `echo $inf1 | awk 'BEGIN{FS=":"}{ print $1}'` = "$INF" ]; then
            FOUND="1"; BR=$bt; fi;fi
     fi
    done
      inf1=`echo $inf1 | awk 'BEGIN{FS=":"}{ print $1}'` 
      if [ "xx$inf1_br" = "xx$BR" ] && [ "xx$inf1" != "xx$INF" ]; then
         if [ "$SYSLOG" -ge 1 ]; then
            if [ "$DEBUG" = "1" ]; then echo "$inf1 = $INF | $inf1_ip = $IP | $inf1_nt = $NETMASK | $inf1_br = $BR | $maxmask | $minmask | $bt | $m" ; fi
            LOGINFOTYP="arp.err ] ";LOGINFO="found IP: $IP over interface $INF - but the true interface were $inf1 - network configuration error";syslog
           if [ -d /opt/SUNWcluster/bin ]; then
            LOGINFOTYP="CLUSTER.err ] ";LOGINFO="CLUSTERS doesn't work with that network configuration - change that network switches/hubs"; syslog
           fi
         fi
         echo "\tCRITICAL NETWORK CONFIGURATION ERROR : receive IP : $IP over interface $INF and not over $inf1"
         if [ -d /opt/SUNWcluster/bin ]; then
            echo "\t\t\t SYSTEM run's as cluster - cluster doesn't work with that network configuration - change network switches/hubs config!"
         fi
      fi

   else 
   # Only IPV6 
     if [ "$DEBUG" !=  "0" ]; then echo "IPv6"; fi
   fi

 done

 if [ "$DEBUG" != "0" ]; then 
   echo "\n $IFCONFM "
   cat $IFCONFM
 fi
 if [ -d /tmp/.ndd ]; then rm -r /tmp/.ndd; fi
 if [ -r /tmp/.t1  ]; then rm -r /tmp/.t1; fi
}

check_hosts()
{
	 if [ $DEBUG != "0" ]; then echo "check HOSTS"; fi
           ANZHOST=`cat /etc/hosts |wc -l | awk '{print $1}' `
	   echo "\ncheck /etc/hosts ... found $ANZHOST lines - begin ... \c"; ERROR=0

	   cat /etc/hosts | awk '/^[0-9]/ {print $1":"$2":"NR} ' | while read hosts rest; do
	    ip=`echo $hosts | awk 'BEGIN {FS=":"}{print $1}' `
            byte1=`echo $ip | awk 'BEGIN {FS="."}{print $1}' `
            byte2=`echo $ip | awk 'BEGIN {FS="."}{print $2}' `
            byte3=`echo $ip | awk 'BEGIN {FS="."}{print $3}' `
            byte4=`echo $ip | awk 'BEGIN {FS="."}{print $4}' `
	    ho=`echo $hosts | awk 'BEGIN {FS=":"}{print $2}' | awk ' /^[a-z,A-Z]/ {print $2} ! /^[a-z,A-Z]/{print "2"}' ` 
            li=`echo $hosts | awk 'BEGIN {FS=":"}{print $3}'`
	    if [  "$ho" = "2" ]; then 
              ho=`echo $hosts | awk 'BEGIN {FS=":"}{print $2}' `
              if [ "$SYSLOG" != "1" ]; then
	       ERROR="1"
	       echo "\tHost with IP:\t$ip\thas a wrong name \"$ho\" " 
              else 
               ERROR="1" 
               LOGINFOTYP="host.err ] ";LOGINFO="line $li with $ip in /etc/hosts has a wrong hostname \"$ho\" ";syslog
              fi
	    fi
            if [ $byte1 -ge 0 ] && [ $byte1 -le 255 ]; then
               if [ $byte2 -ge 0 ] && [ $byte2 -le 255 ]; then
                  if [ $byte3 -ge 0 ] && [  $byte3 -le 255 ]; then
                     if [ ! $byte4 -ge 0 ] && [ ! $byte4 -le 255 ]; then
                        ERROR="1"
                        if [ "$SYSLOG" != "1" ]; then echo "\tHost with name:\t$ho\thas a wrong IP-Address line [ $li ] "
                         else LOGINFOTYP="host.err ] ";LOGINFO="line $li in /etc/hosts has a wrong IP-Address byte4 in $ip";syslog; fi
                     fi
                  else  ERROR="1"
                        if [ "$SYSLOG" != "1" ]; then echo "\tHost with name:\t$ho\thas a wrong IP-Address line [ $li ] " 
                         else LOGINFOTYP="host.err ] ";LOGINFO="line $li in /etc/hosts has a wrong IP-Address byte3 in $ip";syslog; fi
                  fi
               else  ERROR="1"
                        if [ "$SYSLOG" != "1" ]; then echo "\tHost with name:\t$ho\thas a wrong IP-Address line [ $li ] " 
                         else LOGINFOTYP="host.err ] ";LOGINFO="line $li in /etc/hosts has a wrong IP-Address byte2 in $ip";syslog; fi
               fi
            else  ERROR="1"
                        if [ "$SYSLOG" != "1" ]; then echo "\tHost with name:\t$ho\thas a wrong IP-Address line [ $li ] " 
                          else LOGINFOTYP="host.err ] ";LOGINFO="line $li in /etc/hosts has a wrong IP-Address byte1 in $ip";syslog; fi
            fi
            s=`expr $li + 1`
            proz=`expr $s \* 100 / $ANZHOST`
            
            if [ $proz -ge 25 ] && [ "xx$TEST" = "xx"  ]; then TEST="1"; echo "25%  \c "; fi
            if [ $proz -ge 50 ] && [ "xx$TEST" = "xx1" ]; then TEST="2"; echo "50%  \c"; fi
            if [ $proz -ge 75 ] && [ "xx$TEST" = "xx2" ]; then TEST="3"; echo "75%  \c"; fi
            if [ $proz -ge 90 ] && [ "xx$TEST" = "xx3" ]; then TEST="4"; echo "90%  \c"; fi
            if [ "$ANZHOST" = "$s" ]; then 
               if [ "$ERROR" != "0" ]; then
                  echo "\nFound Erros in /etc/hosts \c"
                  if [ "$SYSLOG" = "1" ]; then echo "- check $SYSLOGFILE \c"; fi
               fi 
            fi 
   done
}

check_nfs()
{
 echo "check nfs status ... actually not in use .. \c"
}

service_param()
{
	  case $OS in
	   5.*)
	    if [ -f ./ndd.out ]; then rm ./ndd.out; fi
	    echo "####################################################################################" >> ndd.out 2>&1
	    echo " Output created by\t: $0" >> ndd.out 2>&1
	    echo " Date\t\t\t: $DATE"  >> ndd.out 2>&1
	    echo " Version\t\t: $VERSION" >> ndd.out 2>&1
	    echo " "  >> ndd.out 2>&1
	    echo " `/usr/bin/uname -a" >> ndd.out 2>&1
	    echo "####################################################################################" >> ndd.out 2>&1
	    echo " " >> ndd.out 2>&1
	    echo " ndd.out includes the following information"  >> ndd.out 2>&1
	    echo "\tSection Kernel\tsolaris tunable information" >> ndd.out 2>&1
	    echo "\tSection Tools\tkstat -p or netstat -k " >> ndd.out 2>&1
            echo "\tSection Tools\tnetstat -pn " >> ndd.out 2>&1
	    echo "\tSection Tools\tnetstat -an " >> ndd.out 2>&1
	    echo "\tSection Tools\tifconfig -a" >> ndd.out 2>&1
	    echo "\tSection Tools\tifconfig -a modlist" >> ndd.out 2>&1
	    echo "\tSection Tools\t/etc/nsswitch.conf">> ndd.out 2>&1
	    echo "\tSection Tools\tmodinfo">> ndd.out 2>&1
	    echo "\tSection Tools\tNFS">> ndd.out 2>&1
	    echo "\tSection Tools\tX25">> ndd.out 2>&1
	    echo " " >> ndd.out 2>&1
	    echo "\tSection Service includes all services :\t$service" >> ndd.out 2>&1
	    echo " " >> ndd.out 2>&1
	    echo "\tSection Cards include all networkcard :\t$servcard" >> ndd.out 2>&1
	    echo "\t\t(all instance are : $MAXINSTANCE)">> ndd.out 2>&1
	    echo " " >> ndd.out 2>&1
	    echo "\tSection spezial network interfaces (ba,hippi,dman,scman)" >> ndd.out 2>&1
	    echo " " >> ndd.out 2>&1
	    echo "\tSection SUN Trunking " >> ndd.out 2>&1
	    echo " " >> ndd.out 2>&1
	    echo "###################################################################################" >> ndd.out 2>&1
	    echo " " >> ndd.out 2>&1
	    if [ -x /usr/bin/adb ]; then
                 echo " " >> ndd.out 2>&1
                 echo " \tSECTION KERNEL -> solaris tunable information output" >> ndd.out 2>&1
                 echo " " >> ndd.out 2>&1
		 LISTE="physmem freemem avefree lotsfree desfree minfree throttlefree pageout_reserve cachefree dyncachefree pagesize maxpgio fastscan slowscan handspreadpages tune_t_fsflushr sd_max_throttle sd_io_time scsi_options ncsize ufs_ninode nrnode pt_cnt npty ngroups_max rstchown max_page_get maxusers max_nprocs maxuprc nproc sq_max_size "

		 echo "maxusers/D" | /usr/bin/adb -k >/dev/null 2>/dev/null
		 if [ "$?" != 0 ]; then
		    echo "sorry no output for solaris tunables - adb error " >> ndd.out 2>&1
		  else
		   ISA=`isainfo | awk '{print $1}' `
		   if [ "$ISA" = "sparcv9" ]; then
                    echo "kernel-infos: \toutput decimal  use /K" >> ndd.out 2>&1
                    for mod in $LISTE; do
                        echo "$mod/K" | /usr/bin/adb -k 2>&1 | awk '{ print "kernel-infos: \t" $0 }'>> ndd.out 2>&1
                    done
                    echo "kernel-infos: \toutput decimal use /K " >> ndd.out 2>&1
                    echo "" >> ndd.out 2>&1

		   else
		    echo "kernel-infos: \toutput decimal  use /D" >> ndd.out 2>&1
		    for mod in $LISTE; do
			echo "$mod/D" | /usr/bin/adb -k 2>&1 | awk '{ print "kernel-infos: \t" $0 }'>> ndd.out 2>&1
		    done
		    echo "kernel-infos: \toutput decimal use /D " >> ndd.out 2>&1
		    echo "" >> ndd.out 2>&1
		   fi
		    echo "$<msgbuf" | adb -k 2>&1 | awk '{ print "kernel-msgbuf: \t" $0 }'>> ndd.out 2>&1
		 fi
		 echo " " >> ndd.out 2>&1
	    fi
	    if [ -x /usr/bin/mpstat  ]; then
		/usr/bin/mpstat 5 5 2>&1  | awk '{ print "mpstat-5-5.out: \t" $0 }'>> ndd.out 2>&1
		echo " " >> ndd.out 2>&1
	    fi
	    if [ -x /usr/bin/vmstat  ]; then
		/usr/bin/vmstat 5 6 2>&1  | awk '{ print "vmstat-5-6.out: \t" $0 }'>> ndd.out 2>&1
		echo " " >> ndd.out 2>&1
	    fi
            if [ -x /usr/bin/iostat  ]; then
                /usr/bin/iostat -xtc 5 5 2>&1  | awk '{ print "iostat-xtc-5-5.out: \t" $0 }'>> ndd.out 2>&1
		echo " " >> ndd.out 2>&1
            fi 
	    if [ -x /usr/bin/netstat ] || [ -x /usr/bin/kstat  ]; then 
		 echo " " >> ndd.out 2>&1
		 echo " \tSECTION TOOLS -> netstat -k or kstat -p Output" >> ndd.out 2>&1
		 echo " " >> ndd.out 2>&1
		if [ ! -x /usr/bin/kstat  ]; then
		 /usr/bin/netstat -k 2>&1 | awk '{ print "netstat-k.out: " $0 }' >> ndd.out 2>&1
		else
		 /usr/bin/kstat -p 2>&1 | awk '{ print "kstat-p.out: " $0 }' >> ndd.out 2>&1
		fi
                 echo "______________________________________________________________" >> ndd.out 2>&1
                 echo " " >> ndd.out 2>&1
                 echo " \tSECTION TOOLS -> netstat -pn Output" >> ndd.out 2>&1
                 echo " " >> ndd.out 2>&1
                 /usr/bin/netstat -pn | awk '{ print "netstat-pn.out: " $0 }' >> ndd.out 2>&1
                 echo "______________________________________________________________" >> ndd.out 2>&1
                 echo " " >> ndd.out 2>&1
                 echo " \tSECTION TOOLS -> netstat -an Output" >> ndd.out 2>&1
                 echo " " >> ndd.out 2>&1
                 /usr/bin/netstat -an | awk '{ print "netstat-an.out: " $0 }' >> ndd.out 2>&1

	      else 
		echo  " No /usr/bin/netstat found -> No netstat - k -pn Output" >> ndd.out 2>&1
	    fi
	    echo "______________________________________________________________" >> ndd.out 2>&1
	    if [ -x /usr/sbin/ifconfig ]; then 
		 echo " " >> ndd.out 2>&1
		 echo " \tSECTION TOOLS -> ifconfig -a Output" >> ndd.out 2>&1
		 echo " " >> ndd.out 2>&1
		 /usr/sbin/ifconfig -a | awk '{ print "ifconfig-a.out: " $0 }' >> ndd.out 2>&1
		 /usr/sbin/ifconfig -a modlist 2>&1 | awk 'BEGIN{print "\n"}{ print "ifconfig-a_modlist.out: " $0 }' >> ndd.out 2>&1
	       else echo  " No /usr/sbin/ifconfig found -> No ifconfig -a Output" >> ndd.out 2>&1; fi
	    echo "______________________________________________________________" >> ndd.out 2>&1
	    if [ -r /etc/nsswitch.conf ]; then 
		 echo " " >> ndd.out 2>&1
		 echo " \tSECTION TOOLS -> /etc/nsswitch.conf Output" >> ndd.out 2>&1
		 echo " " >> ndd.out 2>&1
		 cat /etc/nsswitch.conf | awk '{ print "/etc/nsswitch.conf.out: " $0 }' >> ndd.out 2>&1
	       else 
		echo  " No /etc/nsswitch.conf found" >> ndd.out 2>&1
	     fi
	  echo "______________________________________________________________" >> ndd.out 2>&1
	  if [ -x /usr/sbin/modinfo ]; then
		echo " " >> ndd.out 2>&1
		echo " \tSECTION TOOLS -> /usr/sbin/modinfo Output" >> ndd.out 2>&1
		echo " " >> ndd.out 2>&1
		/usr/sbin/modinfo | awk '{ print "modinfo.out: " $0 }' >> ndd.out 2>&1
	  fi
	  echo "______________________________________________________________" >> ndd.out 2>&1
          if [ -x /usr/bin/nfsstat ]; then
           echo " \tSECTION TOOLS -> \tNFS \t\t   \n" >> ndd.out 2>&1
           ls -l /etc/net/*/hosts 2>/dev/null | awk '{print "NFS-hosts.out: " $0 }' >> ndd.out 
           more /etc/net/*/hosts 2>/dev/null | awk '{print "NFS-hosts.out: " $0 }END{print "\n"}' >> ndd.out
           nfsstat -a | awk '{print "NFS-nfsstat-a.out: "  $0 }END{print "\n"}' >> ndd.out
           rpcinfo | awk '{print "NFS-rpcinfo.out: "  $0 }END{print "\n"}' >> ndd.out
           rpcinfo -m | awk '{print "NFS-rpcinfo-m.out: "  $0 }END{print "\n"}' >> ndd.out
           grep -i nfs /var/adm/messages | awk '{print "NFS-messages.out: " $0 }' >> ndd.out
           grep -i rpc /var/adm/messages | awk '{print "NFS-messages.out: " $0 }END{print "\n"}'>> ndd.out
	   if [ -r /etc/auto_master ]; then
	      more /etc/auto_* 2>/dev/null | awk '{print "NFS-automount.out: " $0 }END{print "\n"}'>> ndd.out
	      if [ `awk 'BEGIN{s=0}{ for(i=1;i<=NF;i++){ if($i=="-xfn"){s++} } }END{print s}' /etc/auto_master ` -ge 1 ]; then
		 awk '{ print "/etc/fn/x500.conf: " $0 }' /etc/fn/x500.conf 2>/dev/null >> ndd.out
	      fi
	   fi
	   else
	    echo  "  \tSECTION TOOLS -> NFS : No /usr/bin/nfsstat found" >> ndd.out 2>&1
          fi
	  echo "______________________________________________________________" >> ndd.out
          if [ -d /etc/opt/SUNWconn/x25/config ]; then
	       echo "\nSECTION TOOLS -> X25 : X25 configuration\n" >>ndd.out 2>&1
	       ls -l /etc/opt/SUNWconn/x25/config | awk '{ print "x25_config_ls-l.out: " $0} END{print "\n\n" }' >> ndd.out 2>&1
	       more /etc/opt/SUNWconn/x25/config/* | awk '{ print "x25_config_files: " $0} END{ print "\n\n" }' >> ndd.out 2>&1       

	     else 
	  	 echo "\t\tSECTION TOOLS -> X25 : no X25 config found \n\n" >>ndd.out
          fi
	  echo "______________________________________________________________" >> ndd.out
	    echo "#################################################################" >> ndd.out 2>&1
	    echo "# \tSECTION SERVICES $service \t\t\t# ">> ndd.out 2>&1
	    echo "#################################################################" >> ndd.out 2>&1
	    echo " "  >> ndd.out 2>&1
	    for mod in $service; do
		echo "Configuration service: $mod" >> ndd.out 2>&1
		echo "-------------------------" >> ndd.out 2>&1
		ndd /dev/$mod \? 2>/dev/null | awk '{ print $1 }' | while read parm rest ; do
		    [ "$parm" = '?' ] && continue
		    rest=`echo $parm | awk ' { print substr($1,length($1)-4,length($1)) }' `
		    if [ "$rest" = "(read" ]; then parm=`echo $parm | awk '{ print substr($1,1,length($1)-5 ) }' ` ; fi
  	            TESTPA=` ndd /dev/$mod $parm 2>&1 | wc -l | awk '{ print $1 }' `
		    if [ "$TESTPA" = "1" ]; then
			echo "$parm = \c" >> ndd.out 2>&1
		        ndd /dev/$mod $parm  >> ndd.out 2>&1
		    else
                        echo "$parm = " >> ndd.out 2>&1
                        ndd /dev/$mod $parm 2>&1 | awk  '{ print "\t" $0 }'  >> ndd.out 2>&1
		    fi
		done
		if [ -r /kernel/drv/$mod.conf ]; then
	        	cat /kernel/drv/$mod.conf >> ndd.out 2>/dev/null
		fi
		echo >> ndd.out 2>&1; echo >> ndd.out 2>&1
	    done 
	    echo "#################################################################" >> ndd.out 2>&1
	    echo "# \tSECTION CARDS $servcard \t\t#" >> ndd.out 2>&1
	    echo "#################################################################" >> ndd.out 2>&1
	    RUN="SERVICE"; check_active
	    if [ $DEBUG -ge 1 ]; then echo "AKTIVECARDS ->$AKTIVCARD<-"; fi
	    for mod in $AKTIVCARD; do
                CARDTYP="0"
                TEST=` echo "$INFNET" | grep " $mod " | awk 'BEGIN{s=0}{s++}END{print s}'`
                if [ "$TEST" -ge 1 ]; then
                        # ce Interface
                        CARDTYP="2"
                fi
                TEST=` echo "$INFNDD" | grep " $mod " | awk 'BEGIN{s=0}{s++}END{print s}'`
                if [ "$TEST" -ge 1 ]; then
                        # standard ndd interface hme
                        CARDTYP="1"
                fi
                TEST=` echo "$INFETH" | grep " $mod " | awk 'BEGIN{s=0}{s++}END{print s}'`
                if [ "$TEST" -ge 1 ]; then
                        # interface bge dmfe
                        CARDTYP="3"
                fi

	     if [ $DEBUG -ge 1 ]; then echo "interface $mod ->> cardtyp ->$CARDTYP<-"; fi

	     grep $mod /etc/path_to_inst >/tmp/.nddhelp 2>/dev/null

             if [ "$CARDTYP" != "3" ]; then
	      # handle standard interfaces - cardtyp 1 and 2 ( lp_cap_XXX in kstat )
	      ndd -set /dev/$mod instance 0 2>&1 | egrep -s -e "couldn't push"
	      if [ "$?" = 0 ]; then 
		 continue;
	      fi 
	      for inst in $MAXINSTANCE; do
		     ndd -set /dev/$mod instance $inst 2>&1 | egrep -s -e "operation failed"
		     if [ "$?" = 0 ]; then
			continue;
		     fi

		     echo "$inst">/tmp/.nhelp2 2>/dev/null
		     cat /tmp/.nddhelp 2>/dev/null >> /tmp/.nhelp2 2>/dev/null
		     INFO=`awk '{ if(NF==1){T=$1}else{ if(T==$2){print $1} } }' /tmp/.nhelp2 2>/dev/null`
		     if [ "$INFO" = "" ]; then INFO="not found in /etc/path_to_inst"; fi

		     echo "\nCard Configuration: $mod instance : $inst \t($INFO)" >>ndd.out
		     if [ -r /kernel/drv/$mod ]; then
                        cardvers=`strings /kernel/drv/$mod | grep -i "Ethernet" | grep -v [:,?,=] 2>/dev/null `
		       else
			cardvers=`modinfo | grep -i ethernet | awk '{print $6" "$7" "$8" "$9" " $10" "$11" "$12}' | grep "^$mod" `
		     fi
                     if [ "xx$cardvers" != "xx" ]; then
                        echo "device driver for $mod:\t $cardvers" >>ndd.out
                     fi

		     echo "----------------------------------------------------------" >>ndd.out
		     echo "driver\t| instance\t| parameter = value " >>ndd.out
		     echo "----------------------------------------------------------" >>ndd.out
		     ndd /dev/$mod \? | awk '{print $1}' | while read parm rest ; do
		       [ "$parm" = '?' ] && continue
		       # echo "$mod\t| $mod$inst\t\t| $parm = \c" 1>>ndd.out
		       # ndd /dev/$mod $parm  1>>ndd.out 2>/dev/null 
		       echo "$mod\t| $mod$inst\t\t| $parm = `ndd /dev/$mod $parm 2>&1 | awk '{if(NR==1){print $1} }' ` " 1>>ndd.out
		       if [ $DEBUG = "1" ]; then echo "read network configuration of : $mod$inst $parm"; fi
		     done

		     echo 1>>ndd.out 2>&1 ;
		     if [ -r /kernel/drv/$mod.conf ]; then
		   	awk '{print "driver configfile :"$0}' /kernel/drv/$mod.conf >> ndd.out 2>&1
		      else
			echo "no configuration file $mod.conf found in /kernel/drv " 1>>ndd.out 2>&1 ;
		     fi

		     echo 1>>ndd.out 2>&1 ; echo 1>>ndd.out 2>&1
	       done
              else
		# handele  bge dmfe interface - cardtyp 3
	 	
		for inst in `ls -l /dev/$mod* 2>/dev/null | awk 'BEGIN{s=""}{s=s" "$9}END {print s}'`; do
		   # echo $inst	  
		   if [ "$inst" != "/dev/$mod" ]; then
			echo "$inst" | awk '{print substr($1,length($1),length($1)) }' >/tmp/.nhelp2 2>/dev/null
			cat /tmp/.nddhelp 2>/dev/null >> /tmp/.nhelp2 2>/dev/null
			INFO=`awk '{ if(NF==1){T=$1}else{ if(T==$2){print $1} } }' /tmp/.nhelp2 2>/dev/null `
			if [ "$INFO" = "" ]; then INFO="not found in /etc/path_to_inst"; fi

			echo "\nCard Configuration: $mod instance : $inst \t($INFO)" >>ndd.out
			cardvers=`modinfo | awk '{print $6" "$7" "$8" "$9" " $10" "$11" "$12}' | grep "^$mod" ` 
			if [ "xx$cardvers" != "xx" ]; then
                        	echo "device driver for $mod:\t $cardvers" >>ndd.out
                        fi

                    	echo "----------------------------------------------------------" >>ndd.out
                     	echo "driver\t| instance\t\t| parameter = value " >>ndd.out
                     	echo "----------------------------------------------------------" >>ndd.out
			ndd $inst \? | awk '{print $1}' | while read parm rest ; do
                       		[ "$parm" = '?' ] && continue
                       		# echo "$mod\t| $inst\t\t| $parm = \c" 1>>ndd.out
                       		# ndd $inst $parm  1>>ndd.out 2>/dev/null
				echo "$mod\t| $inst\t\t| $parm = `ndd $inst $parm 2>&1 ` " 1>>ndd.out
                       		if [ $DEBUG = "1" ]; then echo "read network configuration of : $mod$inst"; fi
                     	done
		   fi
		done
		echo 1>>ndd.out 2>&1 ;
		if [ -r /kernel/drv/$mod.conf ]; then
			cat /kernel/drv/$mod.conf >> ndd.out 2>&1
			echo 1>>ndd.out 2>&1 ; echo 1>>ndd.out 2>&1
		fi
	      fi
	    done 
	    rm -r /tmp/.nddhelp /tmp/.nhelp2 2>/dev/null

            echo "\n\n#################################################################" >> ndd.out  2>&1
            echo "# \tSection spezial network interfaces \t\t\t#" 1>>ndd.out 2>&1
            echo "#################################################################" >> ndd.out  2>&1
            if [ -x /etc/opt/SUNWconn/bin/atmstat ]; then
	       echo "===============================================================" >>ndd.out 2>&1
               grep "\"ba\"" /etc/path_to_inst >/tmp/.atmstat_inf 
	       awk '{print "from path_to_inst: " $0}' /tmp/.atmstat_inf >> ndd.out
	       INST=`awk 'BEGIN{s=""}{s=s" "$2}END{print s}' /tmp/.atmstat_inf `
               for int in $INST; do
		   if [ ! -x /usr/xpg4/bin/awk ]; then
                   /etc/opt/SUNWconn/bin/atmstat ba$int -dT | awk '{ print "atmstat-dT: " $0 } END { print "\n\n" }' >>ndd.out 2>&1
		    else
		     /etc/opt/SUNWconn/bin/atmstat ba$int -dT | /usr/xpg4/bin/awk -v t=$int  '{ print "atmstat_ba"t"-dT: " $0 } END { print "\n\n" }' >>ndd.out 2>&1
		   fi
		   if [ -x /etc/opt/SUNWconn/bin/aarstat ]; then
		    if [ ! -x /usr/xpg4/bin/awk ]; then
		      /etc/opt/SUNWconn/bin/aarstat ba$int  2>&1 | awk '{ print "aarstat.out: " $0} END { print "\n\n" }' >>ndd.out 2>&1
		     else
		      /etc/opt/SUNWconn/bin/aarstat ba$int 2>&1 | /usr/xpg4/bin/awk -v t=$int '{print "aarstat_ba"t".out: " $0 } END { print "\n\n" }' >>ndd.out 2>&1
		    fi
		   fi

		   if [ -x /etc/opt/SUNWconn/bin/qccstat ]; then
		    if [ ! -x /usr/xpg4/bin/awk ]; then
		      /etc/opt/SUNWconn/bin/qccstat ba$int 2>&1 | awk '{ print "qccstat.out: " $0} END { print "\n\n" }' >>ndd.out 2>&1
	    	     else
		      /etc/opt/SUNWconn/bin/qccstat ba$int 2>&1 | /usr/xpg4/bin/awk -v t=$int '{print "qccstat_ba"t".out: " $0 } END { print "\n\n" }' >>ndd.out 2>&1
		    fi
		   fi

               done
	       if [ -x /etc/opt/SUNWconn/bin/lanestat ]; then 
		  echo "===============================================================" >>ndd.out 2>&1
		  /etc/opt/SUNWconn/bin/lanestat -a 2>&1 |  awk 'BEGIN{print "lanestat-a.out"}{ print "lanestat-a.out: " $0} END{print "\n\n" }' >>ndd.out 2>&1
	       fi
               rm -r /tmp/.atmstat_inf 2>/dev/null
             else 
               echo "\n\t\tno spezial interface type ba found " >>ndd.out
            fi

	    echo "===============================================================" >>ndd.out
	    if [ -x /etc/opt/SUNWconn/bin/nf_stat ]; then
	       echo "\tCard Configuration nf " >> ndd.out ; echo "\n\n" >>ndd.out
	       grep "\"nf\"" /etc/path_to_inst >/tmp/.atmstat_inf
               awk '{print "from path_to_inst: " $0}' /tmp/.atmstat_inf >> ndd.out
	       echo "\n\n" >>ndd.out
               INST=`awk 'BEGIN{s=""}{s=s" "$2}END{print s}' /tmp/.atmstat_inf `
               for int in $INST; do
		   if [ -x /usr/xpg4/bin/awk ]; then
			/etc/opt/SUNWconn/bin/nf_stat nf$int | /usr/xpg4/bin/awk -v t=$int '{print "nfstat_nf"t".out" $0}' >>ndd.out
		        echo "\n\n" >> ndd.out
                        if [ -x /etc/opt/SUNWconn/bin/nf_macid ]; then
                           /etc/opt/SUNWconn/bin/nf_macid nf$int | /usr/xpg4/bin/awk  -v t=$int '{print "nf_macid_nf"t".out: " $0}' >> ndd.out
                           echo "\n\n" >> ndd.out
                        fi
		    else
			echo "nf_stat of interface nf$int" >> ndd.out
			/etc/opt/SUNWconn/bin/nf_stat nf$int | awk '{print "nfstat_nf.out: " $0}' >> ndd.out
			echo "\n\n" >> ndd.out
			if [ -x /etc/opt/SUNWconn/bin/nf_macid ]; then
			   echo "nf_macid of interface nf$int" >> ndd.out
			   /etc/opt/SUNWconn/bin/nf_macid nf$int | awk '{print "nf_macid_nf.out: " $0}' >> ndd.out
			   echo "\n\n" >> ndd.out
			fi
		   fi
	       done
               rm -r /tmp/.atmstat_inf 2>/dev/null	
	     else
               echo "\n\t\tno spezial interface type nf found " >>ndd.out
            fi

	    if [ -x /etc/opt/SUNWconn/bin/hippi ]; then
		echo "===============================================================" >>ndd.out
		echo "\tCard Configuration hippi : " >> ndd.out ; echo "\n\n" >>ndd.out
		grep "\"hip\"" /etc/path_to_inst | awk '{print "hippi-etc/path_to_inst.out: " $0}' >>ndd.out ; echo "\n\n" >>ndd.out
		/etc/opt/SUNWconn/bin/hippi status 2>&1 | awk '{print "hippi-status.out: " $0}' >>ndd.out ; echo "\n\n" >>ndd.out
		/etc/opt/SUNWconn/bin/hippi cards 2>&1 | awk '{print "hippi-cards.out: " $0}' >>ndd.out ; echo "\n\n" >>ndd.out
		/etc/opt/SUNWconn/bin/hippi version 2>&1 | awk '{print "hippi-version.out: " $0}' >>ndd.out ; echo "\n\n" >>ndd.out
		if [ -x /etc/opt/SUNWconn/bin/hippiarp ]; then
		   /etc/opt/SUNWconn/bin/hippiarp -a 2>&1 | awk '{print "hippiarp-a.out: " $0}' >>ndd.out  ; echo "\n\n" >>ndd.out
		fi
		if [ -x /etc/opt/SUNWconn/bin/hippistat ]; then
		   /etc/opt/SUNWconn/bin/hippistat 2>&1 | awk '{print "hippistat.out: " $0}' >>ndd.out
		fi
		echo "\n\n" >>ndd.out
	     else
		echo "===============================================================" >>ndd.out
		echo "\t\tno spezial interface type hippi found \n\n" >>ndd.out
	    fi

	    #systemcontroller devices  scman dman

	    if [ -x /etc/opt/SUNWconn/bin/nettr ]; then
               echo "#################################################################" >> ndd.out 2>&1
               echo "# \tSECTION SUN Trunking \t\t is installed  - run it  #" >> ndd.out 2>&1
               echo "#################################################################" >> ndd.out 2>&1
		echo 1>>ndd.out 2>&1 ; echo 1>>ndd.out 2>&1

	        /etc/opt/SUNWconn/bin/nettr -conf 2>&1 | awk '{ print "nettr-conf.out: " $0 }' >> ndd.out 2>&1
		echo 1>>ndd.out 2>&1 ; echo 1>>ndd.out 2>&1

		/etc/opt/SUNWconn/bin/nettr -debug 2>&1 | awk '{ print "nettr-debug.out: " $0 }' >> ndd.out 2>&1
		echo 1>>ndd.out 2>&1 ; echo 1>>ndd.out 2>&1

		for inst in 106531 106532 107743 ; do
	            SHOW=` /usr/bin/showrev -p | grep $inst 2>&1 `  
		    if [ "xx$SHOW" != "xx" ]; then
		      echo "Patch $inst is installed" 1>>ndd.out 2>&1
		      echo $SHOW | awk '{ print "showrev-p.out: " $0 } END { print "\n\n" }' >>ndd.out 2>&1 
	            fi
		done

		if [ -x /usr/sbin/eeprom ]; then
		   /usr/sbin/eeprom local-mac-address? 2>&1 |  awk '{ print "eeprom.out: " $0 } END { print "\n\n" }' >>ndd.out 2>&1	
	        fi

	    else 
               echo "#################################################################" >> ndd.out 2>&1
               echo "# \tSECTION SUN Trunking \t not runnable !!!!              #" >> ndd.out 2>&1
               echo "#################################################################" >> ndd.out 2>&1
		echo 1>>ndd.out 2>&1 ; echo 1>>ndd.out 2>&1
	    fi 

	    ;;
	  *)
	    for mod in $mods; do
		echo "Driver configuration: $mod"
		if [ -r /kernel/drv/$mod ]; then
                	cardvers=`strings /kernel/drv/$mod | grep -i "Ethernet" | grep -v [:,?,=] 2>/dev/null `
		 else
			cardvers=`modinfo | grep -i ethernet | awk '{print $6" "$7" "$8" "$9" " $10" "$11" "$12}' | grep "^$mod" `
		fi
                if [ "xx$cardvers" != "xx" ]; then 
                   echo "device driver :\t $cardvers"
                fi
		echo "-------------------------"
	   
		ndd /dev/$mod \? | awk '{print $1 }' | while read parm rest ; do
		    [ "$parm" = '?' ] && continue
		    echo "$parm = \c"
		    ndd /dev/$mod $parm 2>/dev/null
		done
		echo ; echo
	     done > ndd.out 2>&1
	     ;;
	  esac

  echo "Send the file ndd.out from: `pwd` to SUN!"
}

check4conf()
{
	if [ ! -f $CONFDAT ];then
	   die "error 1: File $CONFDAT does not exist!"
	fi
}

check4trunking()
{
 TEMPCONF='/tmp/.nettr-conf'
 TEMPDEBUG='/tmp/.nettr-debug'
 TEMPCONF_PRIM='/tmp/.nettr-conf-prim' 

 POLICY1="MAC hashing"
 POLICY2="Round Robin"
 POLICY3="IP Destination Address"
 POLICY4="IP Source & Destination Address"

 PATCHTRUNKING="106531-02 106532-02 107743-01"

 if [ -x /etc/opt/SUNWconn/bin/nettr ]; then
   /etc/opt/SUNWconn/bin/nettr -conf > $TEMPCONF 
   /etc/opt/SUNWconn/bin/nettr -debug > $TEMPDEBUG 
 else
  echo "\n\tSkipping : no binary /etc/opt/SUNWconn/bin/nettr found ";
  return 0;
 fi

 if [ ! -r $TEMPCONF ]; then  return 0; fi
 if [ ! -r $TEMPDEBUG ]; then return 0; fi
 
 # check eeprom variable 
 EEPROM=`eeprom local-mac-address? 2>&1 | awk 'BEGIN {FS="="} {print $NF }' `
 if [ "xx$EEPROM" != "xxtrue" ]; then 
    LOGINFO="critical ERROR: eeprom local-mac-address? not equal true"; LOGINFOTYP="trunking ]"
    echo "\n$LOGINFO"
    if [ "$SYSLOG" = "1" ]; then syslog; fi
 fi
 
 # check now qfe patch
 if [ "xx$OS" != "xx" ]; then
  OSMINOR=`echo $OS | awk 'BEGIN {FS="."} {print $2 }' `
  OSMAJOR=`echo $OS | awk 'BEGIN {FS="."} {print $1 }' `
 fi
 if [ "$debug" -gt "1" ]; then echo "OS :$OS: MAJOR :$OSMAJOR: MIN :$OSMINOR: "; fi
 
 case $OS in
   '5.8') echo " minimum patches OK ... \c "
         ;;
   '5.7') PATCH=`echo $PATCHTRUNKING | awk '{print $3}' ` ;;
   '5.6') PATCH=`echo $PATCHTRUNKING | awk '{print $2}' ` ;;
   '*'  ) 
         if [ "$OSMINOR" -gt 8 ]; then
          echo " minimum patches OK ... \c "
         else 
          PATCH=`echo $PATCHTRUNKING | awk '{print $1}' ` 
         fi
          ;;
 esac
 
 if [ "xx$PATCH" != "xx" ]; then

         PatchID=`echo $PATCH | awk 'BEGIN {FS="-"} {print $1} ' ` 
        PatchNum=`echo $PATCH | awk 'BEGIN {FS="-"} {print $2} ' `
        SHOW=`showrev -p | grep $PatchNum 2>&1 | awk '{print $2} ' | awk 'BEGIN {FS="-"} {print $2} ' `

        if [ "xx$SHOW" = "xx" ]; then 
           LOGINFO="ERROR: patch $PATCH is not installed"; LOGINFOTYP="trunking ]"
           echo "\n$LOGINFO"
           if [ "$SYSLOG" = "1" ]; then syslog; fi

        else
           if [ $SHOW -ge $PatchID ]; then
                echo "Patch OK .. \c "
           else
                LOGINFO="WARNING: patch $PATCH or higher is not installed"; LOGINFOTYP="trunking ]"
                echo "\n$LOGINFO"
                if [ "$SYSLOG" = "1" ]; then syslog; fi
           fi
        fi
 fi

 
 # check now the config from trunking
 BYTES=`ls -l $TEMPCONF | awk '{ print $5 }' `
 if [ "$BYTES" -le 0 ]; then 
	echo "\nSkipping : run not as root or no output from nettr -conf "; return 0;
 fi
 
 BYTES=`ls -l $TEMPDEBUG | awk '{ print $5 }' `
 if [ "$BYTES" -le 0 ]; then 
	echo "\nSkipping : run not as root or no output from nettr -debug "; return 0;
 fi

 # output exist now

 INF=`grep -v "non-trunk" $TEMPCONF | grep "^[q,g]"  | wc -l | awk '{ print $1}' `
 if [ "$INF" -gt 0 ]; then
   echo "$INF trunking interfaces found ..."
   cat $TEMPCONF | grep "^[q,g]" | awk 'NF==5 {print $1"."$2"."$3"."$4"."$5 }' > $TEMPCONF_PRIM
   cat $TEMPCONF_PRIM  | while read param rest; do

     if [ "$DEBUG" -gt 1 ]; then echo $param; fi
     inf=`echo $param | awk 'BEGIN {FS="."} {print $1} ' `
     head=`echo $param | awk 'BEGIN {FS="."} {print $2} ' `
     pol=`echo $param | awk 'BEGIN {FS="."} {print $3} ' `
     type=`echo $param | awk 'BEGIN {FS="."} {print $4} ' `
     mac=`echo $param | awk 'BEGIN {FS="."} {print $5} ' `
     if [ "$DEBUG" -gt 1 ]; then echo " $inf $head $pol $type $mac " ; fi
 
      echo "\n\tHead Trunking Interface : $inf \t with loaded policy : \c"
     case $pol in
        '1' )   echo "$POLICY1 [$pol]\n" ;;
        '2' )   echo "$POLICY2 [$pol]\n" ;;
        '3' )   echo "$POLICY3 [$pol]\n" ;;
        '4' )   echo "$POLICY4 [$pol]\n" ;;
        * )   echo "unknown policy [ policy = $pol ] " ;;
     esac

     cat $TEMPCONF | grep "$inf " | grep -v "^$inf " | awk '{print $1"."$2"."$3"."$4"."$5 }' | while read paar rest; do
       if [ "$DEBUG" -gt 1 ]; then echo $paar ; fi

     inf1=`echo $paar | awk 'BEGIN {FS="."} {print $1} ' `
     head1=`echo $paar | awk 'BEGIN {FS="."} {print $2} ' `
     pol1=`echo $paar | awk 'BEGIN {FS="."} {print $3} ' `
     type1=`echo $paar | awk 'BEGIN {FS="."} {print $4} ' `
     mac1=`echo $paar | awk 'BEGIN {FS="."} {print $5} ' `

       if [ "$DEBUG" -gt 1 ]; then echo " $inf1 $head1 $pol1 $type1 $mac1 " ; fi

        if [ "$mac" = "mac1" ]; then
              	LOGINFO="critical ERROR: mac-address on $inf and $inf1 are same $mac"; 
		LOGINFOTYP="trunking]"
              	echo "\n\t$LOGINFO"
                if [ "$SYSLOG" = "1" ]; then syslog; fi
        fi

     done


     cat $TEMPDEBUG | grep "$inf " | while read paar rest; do
       DEB=`grep "^$paar " $TEMPDEBUG  `
       lp=`echo $DEB | awk '{print $NF}' `
       hw=`echo $DEB | awk '{print $(NF-1)}' `
      adv=`echo $DEB | awk '{print $(NF-2)}' `
      Xcvr=`echo $DEB | awk '{print $(NF-6)}' `
      DUPLEX=`echo $DEB | awk '{print $(NF-7)}' `
      case $DUPLEX in
        'Full' )  DUPLEX="FULL-Duplex" ;;
        'Half' )  DUPLEX="HALF-Duplex" ;;
        *)   DUPLEX="unknown" ;;
      esac
       SPEED=`echo $DEB | awk '{print $(NF-8)}' `
          UP=`echo $DEB | awk '{print $(NF-9)}' `

       NDDERR="0"
       echo "\t$paar\tlink information : $SPEED $DUPLEX ($Xcvr) $UP \tndd: \c"

       if [ $lp -gt 0 ]; then
          if [ "$lp" != "$adv" ]; then
            NDDERR="1"
          fi
       fi

       case $NDDERR in
        '0' )   echo " ... OK" ;;

        '1' )   LOGINFO="ndd WARNING on $paar : $paar has diffrent ndd setting to remote HUB/SWITCH"; LOGINFOTYP="trunking ]"
		echo "\n\t\t$LOGINFO\n"
                if [ "$SYSLOG" = "1" ]; then syslog; fi
                ;;
         *)     LOGINFO="WARNING for $paar : unkown error $NDDERR"; LOGINFOTYP="trunking ]"
                echo "\n\t\t$LOGINFO\n"
                if [ "$SYSLOG" = "1" ]; then syslog; fi
                ;;
       esac

     done


   done
   echo " "
 else
   echo "No trunking interfaces found ... \c"
 fi
 
 # delete tempfiles
 rm -r /tmp/.nettr-* 2>/dev/null
}

displayversion()
{
 echo " "
 echo " Output created by\t: $0"
 echo " Version\t\t: $VERSION"
 echo " Date\t\t\t: $DATE"
 echo "\n on: `uname -a ` "
 echo " " ; echo " "
}

check4root()
{
CHECK="1"
UID=`id | awk '{print substr($1,5,length($1))}' | awk 'BEGIN{FS="("}{print $1}' `
if [ $UID -ne 0 ]; then
  if [ "$OPTI" != "CHECK" ]; then 
    die "You are not user ROOT !"
  else CHECK="0";fi
fi

}
syslog_check()
{
 if [ "$SYSLOG" = "1" ]; then 
  SYSLOGCHECK="0" 
  if [ "xx$SYSLOGFILE" != "xx" ]; then SYSLOGCHECK="2"; fi
  if [ "xx$SYSLOGFILE" = "xx/var/adm/messages" ]; then SYSLOGCHECK="1"; fi
 fi
}

syslog()
{ 
 if [ "$DEBUG" = "1" ]; then echo "MODULE SYSLOG:|$LOGINFOTYP|\n $LOGINFO "; fi
 if [ "$SYSLOG" = "1" ] && [ "xx$SYSLOGFILE" != "xx" ]; then 
  case "$SYSLOGCHECK" in
   '1')  
        LOGINFOTYP=`echo $LOGINFOTYP | awk '{ print $1 }' `
        if [ "$DEBUG" = "1" ]; then echo "MOD LOGINFOTYP: $LOGINFOTYP | $LOGINFO "; fi

        if [ `echo "$LOGINFOTYP xx" | grep ".crit"  | wc -l | awk '{print $1}' ` = "1" ]; then
            if [ "$DEBUG" = "1" ]; then echo "MODULE SYSLOG:$LOGINFOTYP:.crit"; fi
            logger -p daemon.crit -t ndd-conf.sh "$LOGINFOTYP $LOGINFO"
         else 
          if [ `echo "$LOGINFOTYP xx" | grep ".err" | wc -l | awk '{print $1}' ` = "1" ]; then
            if [ "$DEBUG" = "1" ]; then  echo "MODULE SYSLOG:$LOGINFOTYP:.err"; fi
            logger -p daemon.err  -t ndd-conf.sh "$LOGINFOTYP $LOGINFO"
           else
            if [ `echo "$LOGINFOTYP xx" | grep ".warn" | wc -l | awk '{print $1}' ` = "1" ]; then
              if [ "$DEBUG" = "1" ]; then echo "MODULE SYSLOG:$LOGINFOTYP:.warn"; fi
              logger -p daemon.warn -t ndd-conf.sh "$LOGINFOTYP $LOGINFO"
             else 
              if [ "$DEBUG" = "1" ]; then echo "MODULE SYSLOG:$LOGINFOTYP:.notice"; fi
              logger -p daemon.notice -t ndd-conf.sh "$LOGINFOTYP $LOGINFO"
            fi
          fi
         fi
         ;;
   '2')
 	  if [ "xx$LOGINFO" != "xx" ]; then
    		MESSAGES="[ ndd-conf.sh $LOGINFOTYP $LOGINFO" 
    		touch $SYSLOGFILE
    		DATE=`date | awk '{ print $2" "$3" "$4}'`
    		echo "$DATE\t$HOSTNAME\t$MESSAGES" >> $SYSLOGFILE
   	  fi
	  ;;
  esac
 fi
}

############ Programmstart ############

startup_config()
{
 if [ ! -d $CONFDIR ]; then
  if [ "$OPTI" = "install" ] || [ "$OPTI" = "INSTALL" ]; then
   echo "create now config directory"
  fi
  mkdir $CONFDIR 
  if [ "$?" != "0" ]; then
     die "Can't create the BASEDIR: $CONFDIR "
  fi
 fi

 if [ ! -f $CONFDAT ]; then
  if [ "$OPTI" = "install" ] || [ "$OPTI" = "INSTALL" ]; then
     echo "create now $CONFDAT"
  fi
  touch $CONFDAT
  echo "# Network-Configurationfile for NDD" >$CONFDAT
  echo "#  " >>$CONFDAT
  echo "# create by version $VERSION    on : $DATE " >>$CONFDAT
  echo "#" >>$CONFDAT
  echo "# type;drv;instance;Option;Value" >>$CONFDAT
  echo "# type         :         card, serv " >>$CONFDAT
  echo "# drv          :         serv - $services " >>$CONFDAT
  echo "#                        card - $cards " >>$CONFDAT
  echo "# instance     : [0-$INSTANCE] // for type serv  instance is not in use " >>$CONFDAT
  echo "# Option       : adv_autoneg_cap " >>$CONFDAT
  echo "# Value        : [n]  // sample 1 oder 0 " >>$CONFDAT
  echo "# " >>$CONFDAT
  echo "# examples:" >>$CONFDAT
  echo "#           for network card : card;hme;0;adv_100T4_cap;0 " >>$CONFDAT
  echo "#                       ndd -set /dev/hme instance 0                    " >>$CONFDAT
  echo "#                       ndd -set /dev/hme adv_100T4_cap 0               " >>$CONFDAT
  echo "# " >>$CONFDAT
  echo "#           for services     : serv;tcp;0;tcp_time_wait_interval;240000" >>$CONFDAT
  echo "#                       ndd -set /dev/tcp tcp_time_wait_interval 240000" >>$CONFDAT
  echo "# " >>$CONFDAT
  echo "#                   special  : serv;ce;0;cap_pause;1                   " >>$CONFDAT
  echo "#                       ndd -set /dev/ce instance 0                    " >>$CONFDAT
  echo "#                       ndd -set /dev/ce cap_pause 1                   " >>$CONFDAT
  echo "# " >>$CONFDAT
  echo "#           ( values from services were not updated during a new write ) " >>$CONFDAT
  echo "# " >>$CONFDAT
  echo "# " >>$CONFDAT
  else
  if [ "$OPTI" = "install" ] || [ "$OPTI" = "INSTALL" ]; then
     echo "$CONFDAT exist do nothing"
  fi
 fi
}

select_cards()
{
MAXINSTANCE=`echo "$INSTANCE" | awk 'BEGIN{s="";}{ for(i=0;i<=$1;i++){s=s" "i;} }END{print s}'`
cards="$SAVCARDS"

if [ "$TINF" != "" ]; then

   TCARD=`echo $TINF | awk 'BEGIN{d=""}{s=length($1);for(i=1;i<=s;i++){t=substr($1,i,1);if(t ~ '/[a-z]/'){d=d t;} } }END{print d}' `

  if [ "$TCARD" != "" ]; then
   found=0;
   for mod in $cards; do
     if [ $DEBUG -ge 1 ]; then
	echo "test now ->$mod<-"
     fi
     if [ "$mod" = "$TCARD" ]; then found=1; fi
   done
   if [ $found -ge 1 ]; then
	cards="$TCARD"
   fi
  fi

   TINST=`echo $TINF | awk 'BEGIN{d=""}{s=length($1);for(i=1;i<=s;i++){t=substr($1,i,1);if(t ~ '/[0-9]/'){d=d t;} } }END{print d}' `

   if [ "$TINST" != "" ]; then
	found=0;
   	for mod in $MAXINSTANCE; do
	    if [ "$mod" = "$TINST" ]; then found=1; fi
   	done
        if [ $found -ge 1 ]; then
		MAXINSTANCE="$TINST"
	fi
   fi
fi

   if [ $DEBUG -ge 1 ]; then
	echo "$TCARD ->$cards<- $TINST ->$MAXINSTANCE<-"
   fi

}

#### START MAIN-PROGRAMM
if [ ! -x /usr/bin/awk ]; then
   if [ ! -x /usr/sbin/awk ]; then echo "ERROR - Does not found awk!!"; exit 255; fi
fi

SAVCARDS="$cards"

INSTALLCHECK="1";
LINKCHECK="1";

POS="0" FORCE="1";
while [ "$1" != "" ]; do
        POS=`expr $POS + 1 `
        if [ $POS -le 1 ]; then
            OPTI="$1"
         else
	     case "$1" in
                '+')         ERRHOSTS="0"; ERRNETSTAT="0"; ERRNFS="0" ;
                             ERRTRUNKING="0";
                             if [ "$OS" = "5.10" ]; then
                                ERRNETSTAT="1";
                                echo "skipping check netstat SunOS $OS not support"
                             fi
                                ;;
                '-')         ERRHOSTS="1"; ERRNETSTAT="1"; ERRNFS="1" ;
                             ERRTRUNKING="1";
                                ;;
                'nfs'|'NFS') ERRNFS="0" ;;
                'net'|'NET'|'netstat'|'NETSTAT' ) ERRNETSTAT="0"
                                if [ "$OS" = "5.10" ]; then
                                        ERRNETSTAT="1";
                                        echo "skipping check netstat SunOS $OS not support"
                                fi
                                ;;

                'hosts'|'HOSTS' ) ERRHOSTS="0";;
                'trunking'|'TRUNKING'|'trunk') ERRTRUNKING="0";;
                'config' |'CONFIG' ) INSTALLCHECK="0";;
                'link' | 'LINK' )  LINKCHECK="0";INSTALLCHECK="0";;
		'-f' )		   FORCE="0";;
		'-c' )	RUNN="$RUNN check" ;;
		'-i' )  RUNN="$RUNN install";;
		'-s' )  RUNN="$RUNN set" ;;
		'-r' )  RUNN="$RUNN read";;
		'-w' )  RUNN="$RUNN write";;
		'-rw')  RUNN="$RUNN rewrite";;
		'-d' )  shift 2>/dev/null ; DEBUG="$1"  
			if [ "$DEBUG" = "" ]; then DEBUG="1"
			 else  
			   if [ "$DEBUG" = "-1" ]; then set -x; fi
			fi
			;;
		*) RUNN="$RUNN $1" ;;
            esac

        fi
        shift 2>/dev/null;
done

if [ $DEBUG -ge 1 ]; then
	echo "run Option"
        echo "\tOPTI ->$OPTI<- "
	echo "selected cards<-"
        echo "\tRUNN ->$RUNN<-"
        echo "selected option"
        echo "\tHOSTS ->$ERRHOSTS<- NET ->$ERRNETSTAT<- NFS ->$ERRNFS<- "
        echo "\tTRUNKING ->$ERRTRUNKING<-"
        echo "\tINSTALLCHECK ->$INSTALLCHECK<-"
	echo "\tLINKCHECK  ->$LINKCHECK<-"
fi

STARTUP="$OPTI"
syslog_check
if [ $DEBUG = "1" ]; then echo "SYSLOGCHECK :$SYSLOGCHECK" ; fi
if [ "$SYSLOG" = "1" ] && [ -w $SYSLOGFILE ]; then LOGINFOTYP="run ] "; LOGINFO="start with option: $STARTUP"; syslog
 else SYSLOG="0"; fi

if [ "$OPTI" != "service" ] && [ "$OPTI" != "SERVICE" ]; then
   if [ "$OPTI" != "start" ] && [ "$OPTI" != "START" ]; then
		displayversion
		START=1;
	else 
		START=0;
   fi
fi

if [ "$RUNN" != "" ] && [ $START -ge 1 ]; then
   for mod in $RUNN; do
       if [ $DEBUG -ge 1 ]; then echo "\tmod ->$mod<-"; fi
       modi=`echo $mod | awk 'BEGIN{d=""}{s=length($1);for(i=1;i<=s;i++){t=substr($1,i,1);if(t ~ '/[a-z]/'){d=d t;} } }END{print d}' `
	if [ $DEBUG -ge 1 ]; then echo "\t\tmodi->$modi<-"; fi

	if [ "$mod" = "+" ] || [ "$mod" = "-" ]; then
	   TEST=0
         else
	   TEST=`echo "$cards" | grep "$modi" 2>/dev/null | wc -l | awk '{print $1}' `
	fi
	if [ $DEBUG -ge 1 ]; then echo "\t\tmodi->$TEST<-"; fi
	if [ "$TEST" -ge 1 ]; then
	   TESTCARD="$TESTCARD $mod"
	fi
   done 
fi

case "$OPTI" in
 'start'|'START'|'set'|'SET'|'-s')
        if [ $DEBUG = "1" ]; then echo " start / set " ; fi
	OPTI="START"
        check4root
        check4conf
	if [ "$TESTCARD" != "" ]; then
	    for TINF in $TESTCARD; do
		select_cards
		set_param
	    done
	 else
        	set_param
	fi
        ;;

 'read'|'READ'|'-r')
        if [ $DEBUG = "1" ]; then echo "read" ; fi
	OPTI="READ"
        check4root
	if [ "$TESTCARD" != "" ]; then
          for TINF in $TESTCARD; do 
	   select_cards
           read_param
	  done
	 else
	   read_param
	fi
	echo
        ;;

 'write'|'WRITE'|'-w')
        if [ $DEBUG = "1" ]; then echo "write for ->$TESTCARD<- "; fi
	OPTI="WRITE"
        check4root
	if [ $DEBUG = "1" ]; then echo "check4root over ";fi
	startup_config
	if [ "$TESTCARD" != "" ]; then
		for TINF in $TESTCARD; do
			select_cards
			write_param
		done
	 else
		write_param
	fi
	echo
        ;;

 'rewrite'|'REWRITE'|'-rw')
        if [ $DEBUG = "1" ]; then echo "rewrite"; fi
	OPTI="REWRITE"
        check4root
	startup_config
	if [ "$TESTCARD" != "" ]; then
                for TINF in $TESTCARD; do
                        select_cards
			write_param
			check4conf
			set_param
		done
	 else
        	write_param
        	check4conf
        	set_param 
	fi
	echo
        ;;

 'check'|'CHECK'|'-c')
        if [ $DEBUG = "1" ]; then echo "check configuration"; fi
	OPTI="CHECK"
        check4root
        if [ "xx$CHECK" = "xx1" ]; then 
	   if [ $DEBUG = "1" ]; then echo "\tOK  - you are root ->$TESTCARD<- ->$INSTALLCHECK<-"; fi
	   if [ "$TESTCARD" != "" ]; then
		for TINF in $TESTCARD; do
			select_cards
			RUNI=0;
		        if [ "$INSTALLCHECK" -le 0 ] || [ "$LINKCHECK" -le 0 ] ; then 
			   RUNI=1
			   check_install; INSTCHECK="1"
			fi
			if [ $RUNI -le 0 ]; then
				check_param
			fi
		done
	    else
	       RUNI=0;
	       if [ "$LINKCHECK" -le 0 ]; then RUNI=1;
		  echo "\n__________________________________________________________________________"
                  echo "--------------------------------------------------------------------------\n"
		  echo "SKIPPING: the link testmode ist not allow for all interfaces"
		  LINKCHECK="1"
	       fi
	       if [ "$INSTALLCHECK" -le 0 ]; then RUNI=1; check_install; INSTCHECK="1"; fi
	       if [ $RUNI -le 0 ]; then
		check_param
	       fi
	   fi
           echo "\n__________________________________________________________________________"
           echo "--------------------------------------------------------------------------\n"
         else SYSLOG="0" 
	      if [ "$LINKCHECK" -le 0 ]; then 
		 echo "\n\tSKIPPING: need root access to let run the link test mode!"
		else
		 echo "can't check ndd parameters - run none root-user mode!!!";
		 echo "\nenable checking for netstat information";ERRNETSTAT="0"
	      fi
           echo "\n__________________________________________________________________________"
           echo "--------------------------------------------------------------------------\n"
        fi
        ;;

 'help'| 'HELP'|'-h')
	OPTI="HELP"
        echo "The options of ndd-conf.sh (version $VERSION)"
	echo "========================================================================"
        echo " "
        if [ "$RUNN" = "" ]; then RUNN="ALL"; fi
	if [ "$RUNN" = " start" ]; then RUNN=" set"; fi
	if [ "$RUNN" = " help" ]; then RUNN="ALL"; fi
	if [ "$RUNN" = "ALL" ] || [ "$RUNN" = " set" ]; then
        echo "start     - Read the values form $CONFDAT " 
        echo "          and set these value with the programm ndd"
        echo " "
        echo "set       - same as start"
        echo "          extend Options:"
        echo "\t\t<inf>\t\t set values from $CONFDAT"
        echo "\t\t\t\t only for the interface <inf>"
        echo "\t\t<driver>\t set values from $CONFDAT"
        echo "\t\t\t\t from all instances of the driver"
        echo " "
        echo "\t\tsample:"
        echo "\t\t# ./ndd-conf.sh  start "
        echo "\n\t\t these command let run the script with option start"
        echo "\t\t for   all   instance   of   all driver spezified"
	echo "\t\t in $CONFDAT."
        echo " "
        echo "\t\t# ./ndd-conf.sh  set eri qfe1"
        echo "\n\t\t these command let run the script with option set"
        echo "\t\t for all instance of eri ($INSTANCE) , for qfe instance 1"
	echo "\t\t (only when spezified in $CONFDAT )."
        echo " " 
	fi
	if [ "$RUNN" = "ALL" ] || [ "$RUNN" = " read" ]; then
        echo "read      - Read the parameters from the network adapters"
        echo "          and printed it out to the standard output"
        echo "          extend Options:"
        echo "                  <inf>     read ndd settings of <inf>"
        echo "                  <driver>  read ndd settings of all "
	echo "			    instances of the driver"
        echo " "
        echo "\t\tsample:"
        echo "\t\t# ./ndd-conf.sh  read eri qfe1"
        echo "\n\t\t these command let run the script with option read"
        echo "\t\t for all instance of eri ($INSTANCE) , for qfe instance 1."
	echo ""
	fi
        if [ "$RUNN" = "ALL" ] || [ "$RUNN" = " write" ]; then
        echo "write     - Read the ndd-parameters from the network-adapters."
        echo "          Use the remote values as default and write these to"
        echo "          the file $CONFDAT"
        echo "          extend Options:"
        echo "                  <inf>     write ndd settings of <inf> to "
	echo "				  the configfile"
        echo "                  <driver>  write ndd settings of all "
        echo "                            instances of the driver to "
	echo "                            the configfile"
        echo " "
	echo "\t\tsample:"
        echo "\t\t# ./ndd-conf.sh  write eri qfe1"
        echo "\n\t\t these command let run the script with option write"
        echo "\t\t for all instance of eri ($INSTANCE) , for qfe instance 1."
	echo "\t\t Only the the spezified driver/instances were modified, "
	echo "\t\t all other driver/instance in $CONFDAT  are fix"
        echo ""
	fi
        if [ "$RUNN" = "ALL" ] || [ "$RUNN" = " rewrite" ]; then
        echo "rewrite   - Run at first the write function and after that the"
        echo "          run the set function (same options)"
        echo " "
	echo "\tsee also option write and set "
	echo ""
	fi
        if [ "$RUNN" = "ALL" ] || [ "$RUNN" = " check" ]; then
        echo "check     - Verify the configuration in $CONFDAT"
        echo "          with the configuration from Switch/HUB and the "
        echo "          network adapters\n"
        echo "          extend Options:"
	echo "          <inf> \tcheck <inf>  for ndd settings "
	echo "          <driver>\tcheck all instance of the driver"
        echo "            + \t\twith complete network check"
        echo "            - \t\twithout network check - only ndd"
	echo "\t\t\t( default is - )\n"
	echo "          config\tcheck the installation of spezified driver/instance\n"
	echo "          link\t\tcheck the installation of spezified driver/instance"
	echo "\t\t\tafter a good installation check it will run a link testmode"
	echo "\t\t\t(only for a spezified driver/instance)\n"
	echo "          force\t\thas module \"config\" a error or you are not on the"
	echo "\t\t\tconsole of the system, than you can use these option to "
	echo "\t\t\tforce the the linktestmode\n"
	echo "          net \t\tcheck after ndd settings the statistics"
	echo "\t\t\tof the networkadapter\n"
	echo "          hosts \tcheck after ndd settings the /etc/hosts"
	echo "\t\t\tof wrong settings\n"
	echo "          trunking\tcheck after ndd settings the trunking "
	echo "\t\t\tsettings of wrong settings"
        echo " "
	echo "\t\tsample:"
	echo "\t\t# ./ndd-conf.sh  check hme qfe1 net"
	echo "\n\t\t these command let run the script with option check" 
	echo "\t\t for all instance of hme ($INSTANCE) , for qfe instance 1" 
	echo "\t\t and let run after thees the network statistics on the end"
	echo "\t\t of the script.\n"
        echo "\t\tsample:"
        echo "\t\t# ./ndd-conf.sh  check config"
        echo "\n\t\t these command let run the script with option check"
        echo "\t\t for all instance ($INSTANCE) of network cards"
        echo "\t\t ($cards)\n"
        echo "\t\tsample:"
        echo "\t\t# ./ndd-conf.sh  check link hme qfe1"
        echo "\n\t\t these command let run the script with option check"
        echo "\t\t for all instances of hme ($INSTANCE) and for qfe instance 1"
        echo "\t\t in the installation and is that complete it run a link "
        echo "\t\t testmode.\n"
	fi
        if [ "$RUNN" = "ALL" ] || [ "$RUNN" = " service" ]; then
        echo "service   - Read all parameters from the network-adapters and"
        echo "          from services out and write these values the file"
        echo "          ndd.out in the active directory"
        echo " "
	fi
        if [ "$RUNN" = "ALL" ] || [ "$RUNN" = " install" ]; then
	echo "install   - install these script in /etc/init.d and create a "
	echo "          link /etc/rc2.d/S60ndd-conf\n"
	echo "uninstall - remove these script from /etc/init.d and unlink "
	echo "\t  the link from /etc/rc2.d/S60ndd-conf\n"
	fi
	if [ "$RUNN" != "ALL" ]; then
	echo ""
	echo "INFO:\tYou can receive a complete listing of all options, when "
	echo "\tthe script run only with the option help."
	echo ""
	fi
        echo "Notify: Please check the state of the cards! The local system"
        echo "        and the remote system must have the same values!!!"
        echo " " 
	echo "        Have you any problems with the script, please send a email"
	echo "        to ndd-conf.service@sun.com .        Please insert a short "
	echo "        description that we can fix the problem."
	echo ""
        ;;

 'service' | 'SERVICE')
        if [ $DEBUG = "1" ]; then echo "service"; fi
        check4root
        service_param
        ;;

'install' | 'INSTALL')
	check4root
	if [ -r $0 ]; then
	   NEWVERS=`grep "^VERSION=\"" $0 |awk 'BEGIN{FS="="}{print substr($NF,2,length($NF)-3) }' `
	   if [ -w /etc/init.d ]; then
		startup_config
		check4conf
               if [ -r /etc/init.d/ndd-conf.sh ]; then
		  OLDVERS=`grep "^VERSION=\"" /etc/init.d/ndd-conf.sh | awk 'BEGIN{FS="="}{print substr($NF,2,length($NF)-3) }' `
		  echo "\nsave old ndd-conf.sh (version:$OLDVERS:) to $CONFDIR/ndd-conf.sh_$OLDVERS"
		  mv /etc/init.d/ndd-conf.sh $CONFDIR/ndd-conf.sh_$OLDVERS 
	       fi
	       echo "\ncopy new file of ndd-conf.sh (version:$NEWVERS:) to /etc/init.d"
	       cp $0 /etc/init.d/ndd-conf.sh
	       echo "\nchange permissions"
	       chmod 755 /etc/init.d/ndd-conf.sh
	       if [ ! -h /etc/rc2.d/S60ndd-conf ]; then
		  echo "\nlink doesn't exist - create"
	       	  ln -s /etc/init.d/ndd-conf.sh /etc/rc2.d/S60ndd-conf
		else
		  echo "\nlink /etc/rc2.d/S60ndd-conf exist do not create"
	       fi
	       echo "\nndd.conf exist now - please check configuration or configure now"
	       echo "\t( sample for configure # /etc/init.d/ndd-conf.sh write "
	       echo "\t  sample for check     # /etc/init.d/ndd-conf.sh check )"
	       echo "\ninstallation complete."
	    else
		echo "\nSkipping: can't write to /etc/init.d";
		exit 1
	   fi
	 else
	   echo "\nSkipping: can't read from $0";
	   exit 1
	fi
	;;

 'uninstall' | 'UNINSTALL')
	check4root
	startup_config
	echo "remove link /etc/rc2.d/S60ndd-conf "
	unlink /etc/rc2.d/S60ndd-conf 2>/dev/null
	echo "remove /etc/init.d/ndd-conf.sh"
	mv /etc/init.d/ndd-conf.sh $CONFDIR
	echo "ndd-conf.sh is not longer active"
	echo "all files are located in $CONFDIR"
	echo "uninstallation complete"
	;;

 *)
	echo "Usage from $0 \n"
        echo "\t\tndd-conf.sh set  [<inf>|<driver>] "
        echo "\t\tndd-conf.sh read [<inf>|<driver>] "
	echo "\t\tndd-conf.sh write [<inf>|<driver>] "
	echo "\t\tndd-conf.sh rewrite [<inf>|<driver>] "
	echo "\t\tndd-conf.sh check [<inf>|<driver>] [ +|-|module ] "
	echo "\t\tndd-conf.sh help [ set | read | write | rewrite | check | service | install ] "
	echo "\t\tndd-conf.sh [ start | service | install | uninstall ]"
	echo ""
        exit 1
        ;;
esac

if [ "$OPTI" = "check" ] || [ "$OPTI" = "CHECK" ] || [ "$OPTI" = "-c" ]; then
   # check Modules now
   if [ $DEBUG -ge 1 ]; then echo "check plus network card installation ->$INSTALLCHECK<- != 1 "; fi
   	if [ "$INSTALLCHECK" -le 0 ] && [ "$INSTCHECK" = "" ]; then check_install  ;
	   echo "\n__________________________________________________________________________"
           echo "--------------------------------------------------------------------------"
        fi
   if [ $DEBUG -ge 1 ]; then echo "check plus NETSTAT ->$ERRNETSTAT<- != 1 ?"; fi
        if [ -x /usr/bin/netstat ] && [ $ERRNETSTAT != 1 ]; then
           echo "\ncheck netstat information ... \c"; check_netstat;echo "complete."
           echo "\n__________________________________________________________________________"
           echo "--------------------------------------------------------------------------"
        fi
   if [ $DEBUG -ge 1 ]; then echo "check plus TRUNKING ->$ERRTRUNKING<- != 1 ? ROOT ->$CHECK<-" ; fi
 	if [ $ERRTRUNKING != 1 ]; then
            echo "\ncheck trunking information ... \c"; 
	    if [ "xx$CHECK" = "xx1" ]; then
		check4trunking
	      else
		echo "\n\tSkipping: script run not as root ";
	    fi
	    echo "complete."
            echo "\n__________________________________________________________________________"
            echo "--------------------------------------------------------------------------"
        fi
    if [ $DEBUG -ge 1 ]; then echo "check plus HOSTS ->$ERRHOSTS<- != 1 ?"; fi
        if [ -r /etc/hosts ] && [ $ERRHOSTS != 1 ]; then
           ERROR="0"
           check_hosts; echo "complete."
           echo "\n__________________________________________________________________________"
           echo "--------------------------------------------------------------------------"
        fi
        ERRNFS="1"
    if [ $DEBUG -ge 1 ]; then echo "check plus NFS ->$ERRNFS<- != 1 ?"; fi
        if [ "$ERRNFS" != "1" ]; then
           ERROR="0"
           check_nfs; echo "complete."
           echo "\n__________________________________________________________________________"
           echo "--------------------------------------------------------------------------"
        fi
fi

if [ "$SYSLOG" = "1" ] && [ -w $SYSLOGFILE ]; then LOGINFOTYP="fin ] "; LOGINFO="stop working option : $STARTUP"; syslog; fi

echo "script done."
exit 0



##############################################################################
### This script is submitted to BigAdmin by a user of the BigAdmin community.
### Sun Microsystems, Inc. is not responsible for the
### contents or the code enclosed. 
###
###
### Copyright 2007 Sun Microsystems, Inc. ALL RIGHTS RESERVED
### Use of this software is authorized pursuant to the
### terms of the license found at
### http://www.sun.com/bigadmin/common/berkeley_license.html
##############################################################################


