#!/bin/ksh
# Script to use a menu for common helpdesk items
# Des Warren, Paul Warren
# 15/02/00

### This is a menu designed for a helpdesk operative to 
### be able to select, create a user, change a users password, 
### expire a usesr password, local a user account and clear 
### a print queue, it calls sudo.
###
### Submitter Name: Des Warren
### Submitter Email: dwarren@symantec.com

# Define the functions

function clear_lp_queue
{
  clear
  echo
  echo
  echo
  echo
  echo "        Clearing a print Queue"
  echo
  echo
  echo "        Please enter the name of the printer to be cleared "
  echo
  read PRINTER
  echo "Removing Jobs, Please Wait"
  sudo cancel `lpstat $PRINTER | awk '{ print $1 }'`
  echo "      Please press Enter to continue "
  read null
}


function create_user_account
{
  clear
  echo
  echo
  echo
  echo
  echo "        Creating a user account "
  echo
  echo
  echo "        Please enter the User ID you would like created (Log in
Name)"
  echo
  read USERNAME
  echo
  echo
  echo "        Please enter the First name of the user "
  echo
  read FIRSTNAME
  echo
  echo
  echo "        Please enter the Last name of the user"
  echo
  read LASTNAME
  echo
  echo
  echo
  echo "        The user Log in Name is $USERNAME the username is
$FIRSTNAME $LA
STNAME"
  echo
  echo
  echo "                Is this Correct ? (Y/N)"
  read YN
  if [ "$YN" == "y" ]
  then
    sudo /usr/sbin/useradd -c  "$FIRSTNAME"_"$LAST -g users -d
/export/home/oralogin -s /bin/ksh  $USERNAME
NAME"
    echo
    echo
    echo "      Please press Enter to continue "
    read null
  fi
}


function password_change
{
  clear
  echo
  echo
  echo
  echo "        Change Password "
  echo
  echo
  echo
  echo "        Please enter the User ID "
  echo
  echo
  echo
  read USERNAME
  if [ "$USERNAME" != "" ]
  then
    /usr/local/bin/sudo /usr/bin/passwd $USERNAME
  fi
  echo
  echo "      Please press Enter to continue "
  read null

}

function password_expire
{
  clear
  echo
  echo
  echo
  echo "        Expire Password "
  echo
  echo
  echo
  echo "        Please enter the User ID "
  echo
  echo
  echo
  read USERNAME
  if [ "$USERNAME" != "" ]
  then
    /usr/local/bin/sudo /usr/bin/passwd -f $USERNAME
  fi
  echo
  echo "      Please press Enter to continue "
  read null
}

function password_lock
{
  clear
  echo
  echo
  echo
  echo "        Lock Account "
  echo
  echo
  echo
  echo "        Please enter the User ID "
  echo
  echo
  echo
  read USERNAME
  if [ "$USERNAME" != "" ]
  then
    /usr/local/bin/sudo /usr/bin/passwd -l $USERNAME
  fi
  echo
  echo "      Please press Enter to continue "
  read null
}



while [ 1 == 1 ]
do
clear
echo
echo
echo
echo "                  Welcome to the IT helpdesk Menu"
echo
echo "                      Please select an option below"
echo
echo
echo
echo
echo
echo "                     1) Create a new user account"
echo
echo "                     2) Change a users password"
echo
echo "                     3) Expire a users password (force change)"
echo
echo "                     4) Lock a users account"
echo
echo "                     5) Clear a print queue"
echo
echo "                     6) Quit this Menu"
echo
echo
echo
echo
echo
echo
echo
read OPTION

case "$OPTION" in
1) create_user_account
;;
2) password_change
;;
3) password_expire
;;
4) password_lock
;;
5) clear_lp_queue
;;
6) exit
;;
esac
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


