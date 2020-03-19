#!/bin/ksh -p

# $Id: dtwin,v 1.13 2003/05/06 18:31:11 wl9802 Exp $
##################################################################################
#
# Copyright Info
# --------------
#
# Copyright (c) 1998-2000 William Large (william.large@sun.com)
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA
# 02111-1307, USA.
##################################################################################
#
#
# william.large@sun.com, March 28, 2002
#
# Script - dtwin - Originally designed to allow you to bring up a terminal
#                  window based on just entering the color name at your prompt.
#
#                  Current support is for TERM to be set to dtterm.
#
#                  Currently configured to always utilize a ($BG) black
#                  background with whatever color you choose based on the
#                  current settings of the $COLOR variable.
#
#                  Alternative colors maybe utilized by using command "color"
#
#                   ie:           color blue
#
#                   Will initiate a blue foreground dtterm with a black background
#
#                  There are more options that have been introduced that can
#                  be seen by reading the following.
#
#                  For now if you wish to install.  I would recommend placing
#                  dtwin in say your $HOME/bin directory and then let it install
#                  by simply entering :
#
#  To Install  :       /home/william/bin/dtwin
#
#                  Then you'll be all set to go. by entering a list of colors
#                  and or alternate commands listed by :   dtcolors
#
#  N o t e     :   If you wish to install it somewhere else then please note
#                  you will have to update the variable link_dir setting.
#
##################################################################################
#
# dtwin  - Sets up all initial colors provided by the $COLORS variable.
#          Initiall you'll simply run :  dtwin   in your bin directory.
#
##################################################################################
#
# This script provides a quick alternative to calling up colored
# dtterm windows.
#
# When dtwin is initially executed on setup the following such links
# will be setup automatically for you.
#
# <color>     -> dtwin
#  (ie:)
#  yellow     -> dtwin
#  cyan       -> dtwin
#  green      -> dtwin
#  white      -> dtwin
#  lawngreen  -> dtwin
#
#
# color   : This option allows you to specify colors without usage of the
#           symlinks - The symlinks were only examples of an older styling idea
#           that I had.  The only link you would really need is the following:
#
# color  -> dtwin #  color blue
#                 #  color "light slate gray"  - Notice the doubld quotes
#                 #  color "119 136 153"       - utilizing valid color triplets.  
#                                                ie : light slate gray
#
#
# cedit   : Select a full range of color choices given by the rgb.txt file.
#           This is done through an interactive vi session, and you leaving
#           one line of the color of choice.
#
# selcolor <color> : Selection Color allows you to specify the filter on
#                    the color name.  ie blue could give you 26 color variations
#                    of blue to select from including such names as :
#                         navy blue
#                         cornflower blue
#                         dark slate blue
#                         slate blue
#                         medium slate blue
#                         light slate blue
#                         medium blue
#                    Note:  Any such colors that contain white space should be
#                           enclosed within double quotes.
#
# dtwin-deinstall : uninstalls all dtwin links, but leaves dtwin alone.
#
# dtcolors : List all color options available, including alternate command list.
# dtlist   : Same as dtcolors.
#
##################################################################################

# Security
export PATH="/usr/sbin:/usr/bin:/usr/ucb$PATH"
umask 077

# For banner
PROG=`basename $0`
VER=`echo $Revision: 1.13 $ | sed 's/[^\.0-9]//g'`
AUTHOR='William Large'
EMAIL='william.large@sun.com'
SUPPORT='william.large@sun.com'
YEAR=`date +%Y` # for Y2k
USER=`whoami`
DOMAIN=`domainname`

# Managable settings
COLORS="yellow cyan green red orange blue white gold snow LightBlue dodgerblue lawngreen"
ALTNAMES="cedit selcolor color dtwin-deinstall dtcolors dtlist"

# TERM : Terminal support thus far is DTTERM (/usr/dt/bin/dtterm)
TERM="/usr/dt/bin/dtterm"
DEF_COLOR="dodgerblue"
BG="black"
GTERM="/opt/gnome-1.4/bin/gnome-terminal"
COLOR=`basename $0`
PROG="dtwin"

# Recommendation:
# -------------- 
# Place dtwin in a directory such as your bin directory ($HOME/bin)
# but be explicit by using something like /home/wl9802/bin
#
link_dir="$HOME/bin"

# Useful funcs
warn () {
   echo "$*" >&2
}

die () {
   warn "$*"
   exit 1
}

verbose () {
   [ "$quiet" ] || echo "$*" 
}

usage () {
   cat <<EOF >&2
   
Usage: $0 [options]

Ex:    $PROG 
       $PROG -l         list all $COLORS and $ALTNAMES possible.  Same as the command dtcolors
       $PROG -h         Help list.

Options:

    <color_name>        Generally a link to dtwin.

    cedit               Select a full range of color choices given by the rgb.txt file.
                          This is done through an interactive vi session, and you leaving
                          one line of the color of choice.

    selcolor <color>    Selection Color allows you to specify the filter on
                          the color name.  ie blue could give you 26 color variations
                          of blue to select from including such names as :
                               navy blue
                               cornflower blue
                               .
                               .
                               . etc

    dtcolors            lists all $COLORS and $ALTNAMES possible.

    dtlist              Same as dtcolors.

    dtwin               Initially installs all required symlinks.

    dtwin-deinstall     Removes all links setup by dtwin

    -h                  This help message

EOF
   exit 2

}


# Warning/Info/Confirm
support () {
   cat <<EOF1 >&2


    -- $PROG v$VER by $AUTHOR ($EMAIL) --

This script will install the necessary links based on 

\$COLOR :
 
EOF1

for color in $COLORS
do
   echo "                   $color"
done

echo " "
echo "and \$ALTNAMES :"
echo " "
for altnames in $ALTNAMES
do
   if [ $altnames == "selcolor" ]; then
       echo "                   $altnames <color>"
   else 
       echo "                   $altnames"
   fi
done


cat <<EOF2 >&2

that are managed within this script.

Please contact $SUPPORT if you have any problems.
EOF2
}


while getopts qnl OPT
do       
   case $OPT in 
   h)    
     usage
     ;;
   l) 
     echo ""
     echo "Colors available         : $COLORS"
     echo ""
     echo "Alternate cmds available : " $ALTNAMES
     echo ""
     die
     ;;
   n) 
      test=1
      verbose "Notice: Running in test mode, no changes will be applied..."
      ;;
   q)
      quiet=1
      ;;
   *)
      # usage
      # echo " "
      # support
      ;;
   esac
done


if [ ! -d "$link_dir" ]; then
  echo "Creating.... $link_dir"
  echo ""
  `mkdir -p $link_dir`
fi

for links in $COLORS $ALTNAMES
do
   if [ ! -a "$link_dir/$links" ]; then
      echo "cd $link_dir ; /usr/bin/ln -s $PROG $links"
      `cd $link_dir ; /usr/bin/ln -s $PROG $links`
   fi
done

#COLORS="yellow cyan green red orange blue white gold snow LightBlue dodgerblue lawngreen"
case `basename $0` in
'yellow')
   $TERM -bg $BG -fg $COLOR &
   ;;
'cyan')
   $TERM -bg $BG -fg $COLOR &
   ;;
'green')
   $TERM -bg $BG -fg $COLOR &
   ;;
'red')
   $TERM -bg $BG -fg $COLOR &
   ;;
'orange')
   $TERM -bg $BG -fg $COLOR &
   ;;
'blue')
   $TERM -bg $BG -fg $COLOR &
   ;;
'white')
   $TERM -bg $BG -fg $COLOR &
   ;;
'gold')
   $TERM -bg $BG -fg $COLOR &
   ;;
'snow')
   $TERM -bg $BG -fg $COLOR &
   ;;
'LightBlue')
   $TERM -bg $BG -fg $COLOR &
   ;;
'dodgerblue')
   $TERM -bg $BG -fg $COLOR &
   ;;
'lawngreen')
   $TERM -bg $BG -fg $COLOR &
   ;;
'color')
   $TERM -bg $BG -fg "$@" &
   ;;
'dtwin')
   echo " "
   echo " "
   support
   echo " "

   echo "Do you wish to be advised updates to $PROG : (y|n) :\c"
   read answer

   case $answer in
         y|Y|yes|YES )
           if [ -f $link_dir/dtwin ]; then
               mailx -s "dtwin - $VER setup for $USER@$DOMAIN" william.large@sun.com < /dev/null
           fi
         ;;
     * ) echo ""
         echo ""
         ;;
   esac

   die
   ;;
'dtcolors'|'dtlist')
   support
   die
   ;;
'dtwin-deinstall')
   echo "Thank You for trying dtwin."
   echo "De-installing all links pointing to dtwin"
   echo " "
   echo " "
   echo " "
   echo "----    For updates/support please contact      ----- "
   echo " "
   echo "          -- $PROG v$VER by $AUTHOR ($EMAIL) --"
   echo " "
   echo " "
   for links in $COLORS $ALTNAMES
   do
      if [ -f "$link_dir/$links" ]; then
         verbose "cd $link_dir ; /usr/bin/rm -f $links"
         `cd $link_dir ; /usr/bin/rm -f $links`
      fi
   done
   die
   ;;
'selcolor')
   RGB="/usr/openwin/lib/rgb.txt"
   touch /tmp/ccolors.$$
   `cat /dev/null > /tmp/ccolors.$$`
   cat $RGB | cut -c14-50 |
   while read line 
   do
         echo "$line" >> /tmp/ccolors.$$
   done
   
   `grep "$@" /tmp/ccolors.$$ > /tmp/ccolor.$$`

   vi /tmp/ccolor.$$

   if [ -s /tmp/ccolor.$$ ]; then
       line_cntr=`wc -l /tmp/ccolor.$$ | awk '{ print $1}"'`
       if [ $line_cntr == 1 ]; then
          color=`cat /tmp/ccolor.$$`
          echo "$TERM -bg black -fg \"$color\" &"
          $TERM -bg black -fg "$color" &
       else
          echo ""
          echo ""
          echo "Error:  more then one color specified - using default color ..."
          $TERM -bg black -fg $DEF_COLOR &
          echo ""
          echo ""
       fi
   else
       echo ""
       echo ""
       echo "Error: File was left empty. using default color ..."
       $TERM -bg black -fg $DEF_COLOR &
       echo ""
       echo ""
       die
   fi

   ;;
'cedit')
   RGB="/usr/openwin/lib/rgb.txt"
   cat /dev/null > /tmp/ceditt.$$
   cat $RGB | cut -c14-50 |
   while read line
   do
         echo "$line" >> /tmp/ceditt.$$
   done
   
   echo "#" > /tmp/cedit.$$
   echo "# Now utilizing vi please delete all but one line of your color choice" >> /tmp/cedit.$$
   echo "# remove these comments - Thanks william.large@sun.com"
   echo "#" >> /tmp/cedit.$$
   grep -v rgb.txt /tmp/ceditt.$$ >> /tmp/cedit.$$

   vi /tmp/cedit.$$

   if [ -s /tmp/cedit.$$ ]; then
       line_cntr=`wc -l /tmp/cedit.$$ | awk '{ print $1}"'`
       if [ $line_cntr == 1 ]; then
          color=`cat /tmp/cedit.$$`
          echo "$TERM -bg black -fg \"$color\" &"
          $TERM -bg black -fg "$color" &
       else 
          echo ""
          echo ""
          echo "Error:  more then one color specified - using default color ..."
          $TERM -bg black -fg $DEF_COLOR &
          echo ""
          echo ""
       fi
   else
       echo "Error: File was left empty."
   fi            
 
   ;;
*)
   # Default
   echo " "
   # usage
   echo " "
   echo " "
   # support
   echo " "
   echo " "
   $TERM -bg black -fg $DEF_COLOR &
   ;;
esac


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


