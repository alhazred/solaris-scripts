#!/usr/bin/ksh
#set -xv
#@(#) dio version 2.1
#@(#)
#@(#)
#@(#) COPYRIGHT
#@(#)   Copyright (C) 2004 Mark A. Lane.
#@(#)   All rights reserved.
#@(#)
#@(#)
#@(#) LICENSING GENERAL
#@(#)   The Copywrite Owner hereby grants you unlimited permision to use/copy/modify
#@(#)   this software.
#@(#)
#@(#)
#@(#) WARRANTY
#@(#)   This software is provided as is without any express or implied warranty.
#@(#)
#@(#)
#@(#) AUTHOR
#@(#)   Mark A. Lane
#@(#)
#@(#)
#@(#) DATE WRITTEN
#@(#)   2006.
#@(#)
#@(#) REQUIREMENTS
#@(#)	None.
#@(#)
#@(#) DESCRIPTION
#@(#)	dio sorts the output from iostat as per user requirements.
#@(#)
#@(#)

Options=-xXnmpDC 
Order=9
umask 077
stty sane
Tmp=/tmp/$$
Type=default
Interval=5
PATH=/bin:/usr/sbin
Logname=`logname`
Id=`id | awk '{FS=")"}{print $1}' | awk '{FS="("}{print $2}'`

if [ ! "$Id" = "$Logname" ]; then
	echo "
Error:	`basename $0` must be run as ${Logname} not ${Id}
"
	exit
fi
[ ! -d $Tmp ] && mkdir $Tmp >/dev/null 2>&1
cd $Tmp >/dev/null 2>&1
rm * >/dev/null 2>&1
InputKey=$Tmp/InputKey
Update(){ case $Key in
	c|C|h|H) clear
	kill -9 `cat Display.PID` >/dev/null 2>&1
	kill -9 `cat Iostat.PID` >/dev/null 2>&1
	unset Udisplay
	tput cup 0 0
	echo "
  		Configuration and Help Menu

[C] Configure 			( Configure menu - This )
[H] Help 			( Help menu - This )
[R] Return 			( Return to display )
[R] Refresh Display		( Refresh display )
[S] Sort Field			( Sort Field )
[O] iostat Options		( iostat Options )
[I] iostat Interval		( iostat Interval )
[Q] Quit 			( Quit )
"
	printf "%s" "-> "
	stty raw
	dd if=$Tty count=1 bs=1 of=$InputKey >/dev/null 2>&1
	stty -raw
	printf "%s\n"
	export Key=`head -1 $InputKey`
	Update $Key
	;;
	r|R) kill -9 `cat Display.PID` >/dev/null 2>&1
	kill -9 `cat Iostat.PID` >/dev/null 2>&1
	unset Udisplay
	tput cup 0 0
	;;
	s|S) kill -9 `cat Display.PID` >/dev/null 2>&1
	kill -9 `cat Iostat.PID` >/dev/null 2>&1
	unset Udisplay
	tput cup 0 0
	printf "%s\015%s" "                                                      " "enter Field to sort on -> "
        read Order
	case $Order in 
		[0-9]) clear
		;;
		*) printf "\015%s" "Invalid entry"
               	sleep 2
		;;
	esac
        ;;
	o|O) kill -9 `cat Display.PID` >/dev/null 2>&1
	kill -9 `cat Iostat.PID` >/dev/null 2>&1
	unset Udisplay
	clear
	echo "

Default Options -xXnmpDC 

Usage: iostat [-cCdDeEiImMnpPrstxXYz]  [-l n] [-T d|u] [disk ...] [interval [count]]
                -c:     report percentage of time system has spent
                        in user/system/wait/idle mode
                -C:     report disk statistics by controller
                -d:     display disk Kb/sec, transfers/sec, avg. 
                        service time in milliseconds  
                -D:     display disk reads/sec, writes/sec, 
                        percentage disk utilization 
                -e:     report device error summary statistics
                -E:     report extended device error statistics
                -i:     show device IDs for -E output
                -I:     report the counts in each interval,
                        instead of rates, where applicable
                -l n:   Limit the number of disks to n
                -m:     Display mount points (most useful with -p)
                -M:     Display data throughput in MB/sec instead of Kb/sec
                -n:     convert device names to cXdYtZ format
                -p:     report per-partition disk statistics
                -P:     report per-partition disk statistics only,
                        no per-device disk statistics
                -r:     Display data in comma separated format
                -s:     Suppress state change messages
                -T d|u  Display a timestamp in date (d) or unix time_t (u)
                -t:     display chars read/written to terminals
                -x:     display extended disk statistics
                -X:     display I/O path statistics
                -Y:     display I/O path (I/T/L) statistics
                -z:     Suppress entries with all zero values
 "
	tput cup 0 0
	printf "%s\015%s" "                                                      " "Enter Iostat Options -> "
        read Options
        ;;
	i|I) kill -9 `cat Display.PID` >/dev/null 2>&1
	kill -9 `cat Iostat.PID` >/dev/null 2>&1
	unset Udisplay
	tput cup 0 0
	printf "%s\015%s" "                                                      " "Enter Iostat Interval -> "
        read Interval
        ;;
        q|Q) cd /tmp
        rm -fr $Tmp
	jobs -p | while read PID
	do
		kill -9 $PID >/dev/null 2>&1
	done
	exit
        ;;
esac
}
Display_iostat(){ 

( iostat $Options $Interval > /$Tmp/$$ 2>&1 ) &
jobs -l %% 2>/dev/null | awk '{print $3}' > Iostat.PID 2>/dev/null

( Tmp=/tmp/$1
cd $Tmp
clear
Lines=`tput lines`
Cols=`tput cols`
Clines=$(( $Lines - 10 ))
iostat $Options  | head -2 > /$Tmp/$$.head
while :
do
       	tput cup 0 0 
	printf "%+28s\n\r%+40s\n\r\n\r%s\n\r\n\r" "`hostname`"  "`date`" "iostat $Options $Interval"
	cat /$Tmp/$$.head | while read Display_Line
	do
		printf "\r%s\n\r%s\n" "$Display_Line"
	done
	L=`iostat $Options | sed 1,2d | wc -l | awk '{print $1}'`
	tail -$L /$Tmp/$$ | sort +${Order} -nr | head -${Clines} | while read Display_Line
	do
		DCols=`echo $Display_Line | wc -c | awk '{print $1}'`
		printf "%s" "$Display_Line"
		Max_Cols=`expr $Cols - 2`
		until [ "$DCols" -gt "$Max_Cols" ]
		do
			printf "%s" "                         "
			DCols=$(( $DCols +25 ))
		done
		printf "\r%s" ""
	done
	sleep $Interval
done ) &
jobs -l %% 2>/dev/null | awk '{print $3}' > Display.PID 2>/dev/null
}
#
# Main
#
unset Udisplay
Tty=`tty`
echo $Tty > TTY
while :
do
	if [ -z $Udisplay ]; then
		Display_iostat $$
		Udisplay=yes
	fi
	stty raw
	dd if=$Tty count=1 bs=1 of=$InputKey >/dev/null 2>&1
	stty -raw
	export Key=`head -1 $InputKey`
	Update $Key
done


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


