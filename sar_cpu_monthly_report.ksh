#!/bin/ksh

#%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
#%% A common task to the new SysAdmin is create monthly reports using Sar's data.
#%% This script will make this job easy. It gets monthly CPU usage average,
#%% and you only need put script's output in a spreadsheet to plot data.
#%% Author: Valdemir Jose dos Santos
#%% Grupo Ultra - Informatica Corporativa
#%% Sao Paulo - Brazil
#%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

###
### For script to run correctly, sar must have been setup to run on a daily basis 
### to get the files in /var/adm/sa correctly.
###

clear
echo
LA="01 02 03 04 05 06 07 08 09 10 11 12 13 14 15 16 17 18 19 20 21 22 23 24 25 26 27 28 29 30 31"

echo "Enter Saturdays, Sundays and Holidays to exclude from the average. "
echo "  2-digit (Example:  03 04 10 11 17 18 25 26): "; read weekend_days
lav=`/usr/xpg4/bin/grep -vf <(echo $weekend_days | tr ' ' '\n') <(echo $LA |tr ' ' '\n')`

echo
echo "Enter pathname to the sar binary files (/var/adm/sa): " ; read endereco

if [[ -z $endereco ]]
then
  endereco="/var/adm/sa"
fi

dias=`echo $lav | awk '{ print NF }'`
first_day=`echo $lav | awk '{ print $1 }'`

linecounter=1
integer num
integer avg

echo $$$ > /tmp/sar_cpu99
rm /tmp/sar_cpu??

for I in `echo $lav`
do
  if [[ ${#I} -eq 1 ]]
  then
    I="0$I"
  fi
  
  # If the file exists - process it - else touch it
  if [[ -e $endereco/sa$I ]]
  then
    sar -u -f $endereco/sa$I > /tmp/sar_cpu$I
  else
    touch /tmp/sar_cpu$I
  fi
done

while read dados
do
set -A num 0 0 0 0 0  

for dia in `echo $lav`
do
  if [[ ${#dia} -eq 1 ]]
  then
    dia="0$dia"
  fi
  
  linha=$(head -n $linecounter /tmp/sar_cpu$dia | tail -1)
  	
   set -A linha `echo $linha`
   case "${linha[1]}" in 
     [0-9]*)
          num[1]=$((num[1]+linha[1]))
          num[2]=$((num[2]+linha[2]))
          num[3]=$((num[3]+linha[3]))
          num[4]=$((num[4]+linha[4]))
        ;;
       *)
         echo "" > /dev/null
         ;;
    esac
done

  case "${linha[1]}" in 
    [0-9]*)
        avg[1]=$((num[1]/$dias))
        avg[2]=$((num[2]/$dias))
        avg[3]=$((num[3]/$dias))
        avg[4]=$((num[4]/$dias))
        echo "${linha[0]}  ${avg[1]} ${avg[2]} ${avg[3]} ${avg[4]}" \
        | nawk '{ gsub(/[0-9]$/, "0", $1); print }' | awk '{ print $1 ," " ,$2, "  ", $3, "  ", $4, "  ", $5 }'
        ;;
    *)
        echo "${linha[*]}"
         ;;
  esac
  linecounter=$((linecounter+1))
 
done < /tmp/sar_cpu$first_day

exit 0



##############################################################################
### This script is submitted to BigAdmin by a user of the BigAdmin community.
### Sun Microsystems, Inc. is not responsible for the
### contents or the code enclosed. 
###
###
###  Copyright Sun Microsystems, Inc. ALL RIGHTS RESERVED
### Use of this software is authorized pursuant to the
### terms of the license found at
### http://www.sun.com/bigadmin/common/berkeley_license.jsp
##############################################################################
