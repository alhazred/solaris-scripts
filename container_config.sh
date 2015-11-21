#!/bin/sh
#
# Script to generate a new container in Solaris 10
# No special configurations. Minimal working container config.
#
# Edmond Baroud: ebaroud@yahoo.com
# rev: 1.0
# date: 13/02/2006

ECHO="/usr/ucb/echo -n"

if [ `uname -r | cut -c3-5` -lt 10 ];
 then
    echo "Solaris 10 required."
    exit 2
fi

if [ "$#" -ge 1 ];
 then
        echo "Command line args are not supported yet"
        echo "Just run ./`basename $0`"
        exit 2
fi

ask_user()
{
        $ECHO $1 ; read ANS
        test ! "$ANS" && ANS=$2
}


check_exit()
{
        $ECHO "Exit new zone creation? (y/n) [n]: "
        read ANS
        case $ANS in
                [Yy])
                        exit 2
                ;;
                *)
                $FUNCTION
                ;;
        esac
}

enter_zone_name()
{
        FUNCTION=enter_zone_name
        echo "Please enter the name of your new zone"
        $ECHO "Name: " ; read ZONENAME
        if [ ! "$ZONENAME" ];
         then
                check_exit $FUNCTION
        fi
        check_zone_exist
}

check_zone_exist()
{
        zoneadm list -cv | awk '{print $2}' | grep -i \^$ZONENAME\$
        if [ $? = 0 ];
         then
                echo "Zone exist. " && ask_user "Would you like to view the info of the existing zone? [n]: " "n"
                case "$ANS" in
                        [yY])
                                zonecfg -z $ZONENAME info && enter_zone_name
                        ;;
                        *)
                                enter_zone_name
                        ;;
                esac
        else
                ARGS="create ; "
        fi
}

get_zone_path()
{
        echo "Please enter your zonepath in format /path/to/zone_dir"
        $ECHO "zonepath: [/export/zones/$ZONENAME]: " ; read ZONEPATH
        test ! "$ZONEPATH" && ZONEPATH=/export/zones/$ZONENAME
        if [ `zoneadm list -cv|awk '{print $4}'|grep $ZONEPATH|wc -l` -eq 1 ];
         then
                echo "$ZONEPATH is already in use by another zone! please chose another" && get_zone_path
        else
                ARGS="$ARGS set zonepath=$ZONEPATH ;"
        fi
}

get_IP()
{
        $ECHO "Please enter IP address: " ; read IP
        test ! "$IP" && echo "Error, cannot be left empty!" && get_IP
        ARGS="$ARGS set address=$IP ; end ;"
}

add_net()
{
        case $ANS in
                [nN])
                        echo "Okay.. No network interface will be configured for zone \"$ZONENAME\"!!"
                ;;
                [yY])
                        ARGS="$ARGS add net ; "
                        IF=`ifconfig -a | egrep -v -e "lo|inet|ether|zone" | awk '{print $1}'| cut -f1 -d:|head -1`
                        ask_user "using [$IF], (detected physical interface) pick another? (y/n) [n]: " "n"
                        test "$ANS" = "y" && $ECHO "IT IS RECOMMENDED TO USE WHAT I HAVE DETECTED, but anyhow.. you're a grown up! - Interface: " && read IF
                        ARGS="$ARGS set physical=$IF ; "
                        get_IP
                        ask_user "Configure additional network interface? (y/n) [n]: " "n"
                        test "$ANS" = "y" && add_net

                ;;
                *)
                        add_net
                ;;
        esac
}

autoboot()
{
        case $ANS in
                [yY])
                        ARGS="$ARGS set autoboot=true ;"
                ;;
                [nN])
                        ARGS="$ARGS set autoboot=false ;"
                ;;
                *)
                        ask_user "Not valid answer, please enter (y)for YES, and (n) for NO: " "y"
                ;;
        esac
}

enter_zone_name
get_zone_path
        ask_user "Would you like to configure a network interface? (y/n) [y]: " "y"
add_net
        ask_user "Autoboot zone? (y/n) [y]: " "y"
autoboot

# add zone
        ARGS="$ARGS ; exit"
zonecfg -z $ZONENAME $ARGS

# display the created zone info
echo "Here's your zone info:"
zonecfg -z $ZONENAME info
echo "All you need now is to install your zone and boot it."


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


