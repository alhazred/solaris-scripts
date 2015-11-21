#!/bin/ksh

function symkill
{
for i in $(who -u | sort | awk '{print $1 ":" $6 ":" $7}')

do

	logged=$(echo $i | awk '{print $1}')

	#extracting the required username,idle time and PID

	p1=$(echo $logged | awk -F: '{print $1}')
	p2=$(echo $logged | awk -F: '{print $2}')
	p3=$(echo $logged | awk -F: '{print $3}')
	p4=$(echo $logged | awk -F: '{print $4}') 

	
	#Checking the if the idle time is more than 13min
	
	if [[($p2 -gt 0) || ($p3 -gt 13)]]

	then
		if [[($p1 = $1) || ($p1 = $2) || ($p1 = $3) || ($p1 = $4) || ($p1 = $5) || ($p1 = $6) || ($p1 = $7) || ($p1 = $8) || ($p1 = $9) || ($p1 = $10)|| ($p2 = '.')]]
		
		then
			echo $p1 "may be working"
		else
			echo "killed the login" $p1
			kill -9 $p4
		fi
	else
		echo $p1 "may be working"
	fi

done
}
##############################################################################
########Logic to Extract Login Exceptions in to an Array######################
#############################################################################
i=0
lines=$(wc -l logins.log | awk '{print $1}')
if [[($lines -lt 3)]]
	then
		echo "Noof Login Exceptions is less than 3.Cannot proceed."
		exit
	else
		{ while read line;do
	                     	names[i]=$line
			i=$i+1
		  done
		} < logins.log
fi

##############################################################################
###### Main Logic to clear unix Logins #######################################
##############################################################################

print ${names[*]}
print -n "There are the login Exceptions.....Do you like to continue(y/n)"
read ans

case "$ans" in
	
	y)
		symkill ${names[*]}
		 ;;
	n)	
		echo "Thanks...."
		exit
		;;
	*)
		echo "Not a Valid choice"
		exit
		;;
esac


*****************************MSLOGIN***********************************

#!/bin/ksh

##############################################################################
################ THIS SCRIPT IS USED TO ADD SYMIX LOGIN EXCEPTIONS ###########
##############################################################################

###############################################################################
#CHECK_NAME FUNCTION CHECKS THE VALIDITY OF THE USER NAME SUPPLIED ADDS THE 
#SAME TO LOGINS.LOG ###
###############################################################################

function check_name
{
				temp=$(logins -l $1)
				name=$(echo $temp | awk -F' ' '{print $1}')
				
				i=0	
				{ while read lines;do
					if [[("$lines" = "$1")]]
						then
							echo "Already Exists"
							exit
						else
							i=$1+1
					fi
				  done
				} < logins.log
				
				if [[("$name" = "$1")]]
					then
					echo $1 >> logins.log
					echo "Added" $1 "to the Logins file"
					exit
				else
					echo $1  " NOT THERE IN USER ACCOUNT DATABASE "
					exit
				fi
}

##############################################################################
# DELETE_NAME FUNCTIONS DELETES THE USER NAME FROM LOGINS.LOG#################
##############################################################################
	   
function delete_name
{
	touch logins.tmp
	{ while read line;do
		if [[("$line" = "$1")]]
			then
				echo "Deleted" $1 "From the Logins file" 
			else
				echo $line >> logins.tmp
		fi
	  done
	} < logins.log
	mv logins.tmp logins.log	
}


if [[($# -gt 2)]]
	then 
		echo "Usage : mslogins {-a | -d | -r} {username}"
		echo "You can only supply one user name at once"
		exit
	else
		case "$1" in 
	
			-a)
				lines=$(wc -l logins.log | awk '{print $1}')
				if [[("$2" != "") && ($lines -lt 11)]]
					then
						check_name $2
					else
						echo "you cannot have more than 10 login Exceptions."
						echo "If the noof login exceptions are less than 8 then retry the same command with proper username."
						exit
				fi
				;;
			-r)
				if [[("$2" != "")]]
					then
				        		delete_name $2
					else
						echo "Pls Supply User Name"
						exit
					fi
				 ;;
			-d)
				echo "Login Exceptions....\n"
				cat logins.log
				;;
			*)
				echo "Usage : mslogins {-a | -d | -r} {username}";exit ;;
		esac
fi
	




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


