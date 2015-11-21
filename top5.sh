#!/bin/sh
#
# ==============================================================================
# Filename : top5
#  Function:
#  This script is a handy version of "top" command. But this shows only the top
#  5 processes (can be change). 
#  The script also gives the following functionality :-
# 	   Function			Key
#             List Specific User process 	 u  
#	      All User processes		 a    
#             Kill Process 			 k  
#             Send Signal 			 s    
#             List Signal Name 			 f
#	      Quit        			 q 
#             Refresh     			 l
# ==============================================================================
# Author : A P Singh 
# Submitter : arjun.singh@hpsglobal.com
# ==============================================================================#
# Tested on AIX 4.3. Some adjustments may be needed for your flavor of Unix.
#
 
ShowMenu() {
face1="_(._.)_"
face2="	     	\|||/"
face3="	         @ @"
face4="----oOOo--(_)--oOOo----------"

echo "\t\t\t\t\t\t\t\t${face2}"
echo "\t\t\t\t\t\t\t\t${face3}"
echo "-----------------------------------------------------------------------${face4}"
echo "${bold}Specific User${norm} : u\t${bold}All User   ${norm} : a\t${bold}Quit${norm}             : q\t${bold}Refresh${norm} : l"
echo "${bold}Kill Process ${norm} : k\t${bold}Send Signal${norm} : s\t${bold}List Signal Name${norm} : f"
echo "----------------------------------------------------------------------------------------------------"
}


GetKeystroke () {
trap "" 2 3

#stty -g : Writes option settings to standard output in a form usable by 
#another stty command.
oldSttySettings=`stty -g`

#-echo : Does not echo characters.
#dd count=inputblocks : Copies only the number of input blocks specified 
stty -echo raw
echo "`dd count=1 2> /dev/null`"
stty $oldSttySettings
trap 2 3
}
 
 
#----------------------------------------------#
# Here's the main program. Hit "q" to exit.    #
#----------------------------------------------#
 
bold=`tput smso` 
norm=`tput rmso` 

keyStroke=""
while [ "$keyStroke" != "q" ]
do
   if [ "$keyStroke" = "u" ]
   then
      	echo "${bold}User:${norm} \c"
	read user
	clear
	ps gu|head -n 1;ps gau|egrep -v "CPU|kproc"|grep "${user}"|grep -v grep|sort +2b -3 -n -r|head -n5;uptime
	ShowMenu
	keyStroke=`GetKeystroke`
	while [ "$keyStroke" = "l" ]
	do
		clear
		ps gu|head -n 1;ps gau|egrep -v "CPU|kproc"|grep "${user}"|grep -v grep|sort +2b -3 -n -r|head -n5;uptime
		ShowMenu
		keyStroke=`GetKeystroke`
	done
   elif [ "$keyStroke" = "a" ]
   then
	clear
	ps gu|head -n 1;ps gau|egrep -v "CPU|kproc"|sort +2b -3 -n -r|head -n 5;uptime
	ShowMenu
	keyStroke=`GetKeystroke`
   elif [ "$keyStroke" = "f" ]
   then
	kill -l
	keyStroke=`GetKeystroke`
   elif [ "$keyStroke" = "k" ]
   then
   	echo "${bold}Process ID:${norm} \c"
	read pid
	kill -9 ${pid} && echo "Killed!!!"
	keyStroke=`GetKeystroke`
   elif [ "$keyStroke" = "s" ]
   then
	echo "${bold}Signal ID:${norm} \c"
	read sigid
	echo "${bold}Process ID:${norm} \c"
	read pid
	kill -${sigid} ${pid} && echo "Signal Sended!!!"
	keyStroke=`GetKeystroke`
   else
	clear
	ps gu|head -n 1;ps gau|egrep -v "CPU|kproc"|sort +2b -3 -n -r|head -n 5;uptime
	ShowMenu
	keyStroke=`GetKeystroke`
   fi
done


##############################################################################
### This script is submitted to BigAdmin by a user of the BigAdmin community.
### Sun Microsystems, Inc. is not responsible for the
### contents or the code enclosed. 
###
###
### Copyright 2006 Sun Microsystems, Inc. ALL RIGHTS RESERVED
### Use of this software is authorized pursuant to the
### terms of the license found at
### http://www.sun.com/bigadmin/common/berkeley_license.html
##############################################################################


