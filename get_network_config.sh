#!/usr/bin/ksh

#########################################################################
# ToDO         : Network Configuration Output in "./ntwk.conf"
# Version      : 2.0
# Author       : Aleksander Pavic <nsecret@gmx.de>
# OS           : Sparc@Solaris 8
# Scriptname   : get_network_config
# Licence      : GPL
#########################################################################



function filestart
{
 echo "############# Begin of Network Configuration #################" >&3
}




function separator
{
 echo "" >&3
 echo "##############################################################" >&3
 echo "" >&3
}


function help
{
 echo
 echo " Network Configuration is printed to './ntwk.conf'"
 echo "  Format: <Attribute>=<value-in_one_line>"
 echo
 echo " GENERAL OPTIONS:"
 echo "  -c <interface_dev> - generate output for this interface"
 echo "  -l <instance>      - interface instance between 0 - 1023 (default=0)"
 echo "  -V                 - version"
 echo "  -h                 - this screen"
 echo "  -p                 - print generated output file"
 echo 
 echo " OUTPUT MODIFIERS:"
 echo "  -a                 - all O.M. without '-v'"
 echo "  -i                 - ip output"
 echo "  -t                 - tcp output"
 echo "  -u                 - udp output"
 echo "  -r                 - arp output"
 echo "  -e                 - icmp output"
 echo "  -v                 - verbose mode (write 'long line' Attributes)"
 echo
 echo " Example: $0 -c /dev/hme -l 2 -tuvi"
 echo "  Everything is optional, customize your output!"
 echo
}



function get_ip
{
 ip_container=`ndd -get /dev/ip \? | sed '1d' | nawk -F"(" '{print $1}'`
 printf "\n\nBegin IP Config:\n\n" >&3

   for i in $ip_container
   do
   ip_val=`ndd -get /dev/ip $i | sed -n -e '1p' -e '2,$p'`
   var_ip=`echo $ip_val | wc -m`

     if (( var_ip < "9" ))
     then
     print $i"="$ip_val >&3
     elif (( var_ip >= "9" )) && (( verbose == "0" ))
     then
     continue
     elif (( var_ip >= "9" )) && (( verbose == "1" ))
     then
     print $i"="$ip_val >&3
     else
     echo "error - aborting..."
     exit 4
     fi

   done

 printf "\n\nEnd IP Config\n" >&3
}




function get_tcp
{

 tcp_container=`ndd -get /dev/tcp \? | sed '1d' | nawk -F"(" '{print $1}'`
 printf "\n\nBegin TCP Config:\n\n" >&3

   for t in $tcp_container
   do
   tcp_val=`ndd -get /dev/tcp $t | sed -n -e '1p' -e '2,$p'`
   var_tcp=`echo $tcp_val | wc -m`

     if (( var_tcp < "9" ))
     then
     print $t"="$tcp_val >&3 
     elif (( var_tcp >= "9" )) && (( verbose == "0" ))
     then
     continue
     elif (( var_tcp >= "9" )) && (( verbose == "1" ))
     then
     print $t"="$tcp_val >&3 
     else
     echo "error - aborting..."
     exit 6
     fi

   done


 printf "\n\nEnd TCP Config\n" >&3

}




function get_udp
{
 udp_container=`ndd -get /dev/udp \? | sed '1d' | nawk -F"(" '{print $1}'`
 printf "\n\nBegin UDP Config:\n\n" >&3

   for u in $udp_container
   do
   udp_val=`ndd -get /dev/udp $u | sed -n -e '1p' -e '2,$p'`
   var_udp=`echo $udp_val | wc -m`

     if (( var_udp < "9" ))
     then
     print $u"="$udp_val >&3 
     elif (( var_udp >= "9" )) && (( verbose == "0" ))
     then
     continue
     elif (( var_udp >= "9" )) && (( verbose == "1" ))
     then
     print $u"="$udp_val >&3 
     else
     echo "error - aborting..."
     exit 7
     fi

   done

 printf "\n\nEnd UDP Config\n" >&3

}




function get_arp
{
 arp_container=`ndd -get /dev/arp \? | sed '1d' | nawk -F"(" '{print $1}'`
 printf "\n\nBegin ARP Config:\n\n" >&3

   for a in $arp_container
   do
   arp_val=`ndd -get /dev/arp $a | sed -n -e '1p' -e '2,$p'`
   var_arp=`echo $arp_val | wc -m`

     if (( var_arp < "9" ))
     then
     print $a"="$arp_val >&3 
     elif (( var_arp >= "9" )) && (( verbose == "0" ))
     then
     continue
     elif (( var_arp >= "9" )) && (( verbose == "1" ))
     then
     print $a"="$arp_val >&3 
     else
     echo "error - aborting..."
     exit 8
     fi

   done

 printf "\n\nEnd ARP Config\n" >&3

}




function get_icmp
{
 icmp_container=`ndd -get /dev/icmp \? | sed '1d' | nawk -F"(" '{print $1}'`
 printf "\n\nBegin ICMP Config:\n\n" >&3
 

   for ic in $icmp_container
   do
   icmp_val=`ndd -get /dev/icmp $ic | sed -n -e '1p' -e '2,$p'`
   var_icmp=`echo $icmp_val | wc -m`

     if (( var_icmp < "9" ))
     then
     print $ic"="$icmp_val >&3 
     elif (( var_icmp >= "9" )) && (( verbose == "0" ))
     then
     continue
     elif (( var_icmp >= "9" )) && (( verbose == "1" ))
     then
     print $a"="$icmp_val >&3 
     else
     echo "error - aborting..."
     exit 11
     fi

   done

 printf "\n\nEnd ICMP Config\n" >&3

}




function get_int
{
 int_container=`ndd -get "$int_val" \? | sed '1d' | nawk -F"(" '{print $1}'` 
 printf "\n\nBegin Interface Config:\n\n" >&3

   for int in $int_container
   do
   int_temp=`ndd -get $int_val $int | sed -n -e '1p' -e '2,$p'`
   var_int=`echo $int_temp | wc -m`

     if (( var_int < "9" ))
     then
     print $int"="$int_temp >&3 
     elif (( var_int >= "9" )) && (( verbose == "0" ))
     then
     continue
     elif (( var_int >= "9" )) && (( verbose == "1" ))
     then
     print $int"="$int_temp >&3 
     else
     echo "error - aborting..."
     exit 12
     fi

   done

 printf "\n\nEnd Interface Config\n" >&3

}





################# Action #################





if (( $# == "0" )) || [[ $1 == "--help" ]]
then
help
exit 0
fi


if (( $# > "12" ))
then
echo "Syntax Error - Too much arguments"
echo
echo
help
exit 13
fi

export PATH=/usr/bin:/usr/sbin

verbose="0"
with_int="0"
int_val="0"
instance_id="0"
instwasset="0"
option_counter="255"
print="0"

want_ip="0"
want_tcp="0"
want_udp="0"
want_arp="0"
want_icmp="0"
want_justint="0"
version="2.0"





while getopts :c:l:aituerhvVp option
do
  case $option in
  h)
    help
    exit 0
  ;;


  V)
    echo "Version=$version"
    exit 0
  ;;

  c)
    if [[ -c $OPTARG ]]
    then
    with_int="1"
    int_val="$OPTARG"
    else
    echo "specified file cannot be an interface (no character file)"
    exit 1
    fi
  ;;

  l)
    instance_id_container=`echo $OPTARG | nawk '{if ($0 < 1024) print $0}'`

    if [[ -n $instance_id_container ]]
    then
    instance_id=$OPTARG
    instwasset=1
    else
    echo "invalid argument for 'l'"
    exit 2
    fi
  ;;
 
  a)
    option_counter="0"
  ;;
 
  i)
    want_ip="1"
    option_counter="1"
  ;; 

  t)
    want_tcp="1"
    option_counter="2"
  ;;

  u)
    want_udp="1"
    option_counter="3"
  ;;

  r)
    want_arp="1"
    option_counter="4"
  ;;

  e)
    want_icmp="1"
    option_counter="5"
  ;;

  v)
    verbose="1"
  ;;

  p)
    print="1"
  ;;

  :)
    echo "no argument for $OPTARG"
    exit 9
  ;;

  \?)
     echo "Invalid Option given (${OPTARG})"
     exit 10
  ;;

  
  esac

 done






# catch user errors

if (( with_int == "0" )) &&  (( "$instwasset" != "0" ))
then
echo "You cannot specify an instance without interface"
exit 2
elif (( with_int != "0" ))
then
ndd_error=`ndd -set "$int_val" instance "$instance_id"`

# Cause ndd give a text message instead of an non zero exit code

  if [[ -n "$ndd_error" ]] 
  then
  echo "incorrect instance or interface"
  exit 3
  fi


fi





# the decision process
 
exec 3> ./ntwk.conf

 
filestart

if (( want_ip == "1" || option_counter == "0" ))
then
get_ip
separator
fi


if (( want_tcp == "1" || option_counter == "0" ))
then
get_tcp
separator
fi


if (( want_udp == "1" || option_counter == "0" ))
then
get_udp
separator
fi


if (( want_arp == "1" || option_counter == "0" ))
then
get_arp
separator
fi


if (( want_icmp == "1" || option_counter == "0" ))
then
get_icmp
separator
fi

if (( with_int != "0" ))
then
get_int
fi


outsize=`wc -l ntwk.conf | nawk '{print $1}'`

if (( $outsize == 1 ))
then
echo 'sorry, you don`t generate any usefull output'
exit 15
else 
printf "\nOutput is successfully written in ./ntwk.conf\n"
fi


if (( print == 1 ))
then

  if type more > /dev/null 2>&1
  then
  exec 3<&-
  more ntwk.conf
  exit 0
  else
  echo "sorry, cannot find the 'more' binary"
  exec 3<&-
  exit 16

  fi

else
exec 3<&-
exit 0

fi


##############################################################################
### This script is submitted to BigAdmin by a user of the BigAdmin community.
### Sun Microsystems, Inc. is not responsible for the
### contents or the code enclosed. 
###
###
### Copyright 2008 Sun Microsystems, Inc. ALL RIGHTS RESERVED
### Use of this software is authorized pursuant to the
### terms of the license found at
### http://www.sun.com/bigadmin/common/berkeley_license.html
##############################################################################


