#!/usr/bin/ksh
#
# Checks the speed and settings of Sun HME and QFE interfaces. 
#
# Olivier S. Masse
# omasse@iname.com
#
# Originally posted some time in spring 2001.
#
# Updated on 2003/06/24:
# Corrections sent simultaneously by Mark Leber and Ubaid Khan, probably 
# after someone posted this script on BigAdmin: Auto negociation report 
# was reversed, it is corrected now.
#
#
for i in `ifconfig -a | egrep "^hme|^qfe" | awk '/^[a-z]*[0-9]*: / {print $1}' | sed s/://`
do
        device=`echo $i | sed s/[0-9]*$//`
        instance=`echo $i | sed s/^[a-z]*//`
        ndd -set /dev/$device instance $instance
        duplex=`ndd -get /dev/$device link_mode`
        speed=`ndd -get /dev/$device link_speed`
        autoneg=`ndd -get /dev/$device adv_autoneg_cap`
        case "$speed" in
                "0") echo "$i is at 10 mbit \c";;
                "1") echo "$i is at 100 mbit \c";;
                *) echo "$i is at ??? mbit \c";;
        esac
        case "$duplex" in
                "0") echo "half duplex \c";;
                "1") echo "full duplex \c";;
                *) echo "??? duplex \c";;
        esac
        case "$autoneg" in
                "0") echo "without auto negotiation";;
                "1") echo "with auto negotiation";;
                *) echo "??? auto negotiation";;
        esac
done


