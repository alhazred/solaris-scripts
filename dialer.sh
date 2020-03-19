#!/usr/dt/bin/dtksh

APPNAME="Dtksh Dialer 0.4"

# Copyright (C) 1999 David Everly <deckrider@yahoo.com>.
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA 02111-1307, USA

#-------------------------------------------------------------------------------
# Modify the DIALER_PATH to specify where you put the dialer
#-------------------------------------------------------------------------------

DIALER_PATH=/opt/dialer

. $DIALER_PATH/xutil.sh

#-------------------------------------------------------------------------------
# selectISP (change only this to work with your ISP and related files
#-------------------------------------------------------------------------------

function selectISP {
	ISP.SUFFIX="pcisys"	# the one you want as the
				# default when nothing was
				# selected (should match first
				# ISP.SUFFIX value below)

	XUaddbuttons $PULL \
		ISP.DISPLAYNAME "PCI Systems"  "ISP.SUFFIX=pcisys" \
		ISP.DISPLAYNAME "MCI WorldCom" "ISP.SUFFIX=wcom"
	return
}

#-------------------------------------------------------------------------------
# log Timer
#-------------------------------------------------------------------------------

function logTimer {
	NEWLINE=`/usr/bin/sed -n $LINECOUNT$"p" /var/adm/log/asppp.log`

	while [[ $NEWLINE ]]
	do
		if print $NEWLINE | /usr/bin/fgrep "IP up"
			then
				connectButtons
				XUset $STATUS labelString:"Connected"
		elif print $NEWLINE | /usr/bin/fgrep -f $DIALER_PATH/stop.list
			then disconnectButtons
		fi
		XUtextdisable $TEXT
		XUtextappend $TEXT $'\n\n'"$NEWLINE"
		XUtextgetlast last $TEXT
		XUtextshow $TEXT $last
		XUset $TEXT cursorPosition:$last
		XUtextenable $TEXT
		LINECOUNT=$LINECOUNT+1
		NEWLINE=`/usr/bin/sed -n $LINECOUNT$"p" /var/adm/log/asppp.log`
	done

	XUaddtimeout LOGTIMER 1000 logTimer
	return
}

#-------------------------------------------------------------------------------
# clock Timer
#-------------------------------------------------------------------------------

function clockTimer {
	typeset -Z2 HH MM SS # -Z2 pads with leading 0

	SS=$((SECONDS%60))
	MM=$(( ((SECONDS-SS)/60)%60 ))
	HH=$(( ((SECONDS-(SS+(MM*60)))/3600)%24 ))

	XUset $TIME labelString:"$HH:$MM:$SS"

	XUaddtimeout CLOCKTIMER 1000 clockTimer

	return
}

#-------------------------------------------------------------------------------
# Disconnect
#-------------------------------------------------------------------------------

function disconnectDefer {
	/etc/init.d/asppp stop
	if [[ -f /etc/resolv.conf ]]
	then
		/usr/bin/rm /etc/resolv.conf
	fi
	/usr/bin/cp /etc/asppp.cf.original /etc/asppp.cf
	/usr/bin/cp /etc/nsswitch.files /etc/nsswitch.conf
	/usr/sbin/route -f
	return
}

function disconnectButtons {
	XUinsensitive $BUTTON2
	XUsensitive $ISP
	XUsensitive $BUTTON1
	XUremovetimeout $CLOCKTIMER
	XUset $STATUS labelString:"Disconnected"
	return
}

function disconnect {
	disconnectButtons
	XUbusy $TOPLEVEL
	XUdefer disconnectDefer
	return
}

#-------------------------------------------------------------------------------
# Connect
#-------------------------------------------------------------------------------

function connectDefer {
	disconnectDefer
	/usr/bin/cat /dev/null > /var/adm/log/asppp.log
	LINECOUNT=1
	/usr/bin/cp /etc/asppp.cf.${ISP.SUFFIX} /etc/asppp.cf
	/etc/init.d/asppp start
	/usr/sbin/ping 2.2.2.2 &
	/usr/bin/cp /etc/resolv.conf.${ISP.SUFFIX} /etc/resolv.conf
	/usr/bin/cp /etc/nsswitch.dns /etc/nsswitch.conf
	return
}

function connectButtons {
	XUinsensitive $BUTTON1
	XUinsensitive $ISP
	XUsensitive $BUTTON2
}

function connect {
	connectButtons
	XUbusy $TOPLEVEL
	XUset $STATUS labelString:"Connecting . . ."
	SECONDS=0
	XUaddtimeout CLOCKTIMER 1000 clockTimer
	XUdefer connectDefer
	return
}

#-------------------------------------------------------------------------------
# Exit
#-------------------------------------------------------------------------------

function dialerExit {
	XUbusy $TOPLEVEL
	disconnectDefer
	if [[ -f $DIALER_PATH/is.running ]]
	then
		/usr/bin/rm $DIALER_PATH/is.running
	fi
	exit 0
}

#-------------------------------------------------------------------------------
# Main Body
#-------------------------------------------------------------------------------

XUinitialize TOPLEVEL "$APPNAME" \
	-title "$APPNAME" "$@"

XUform FORM $TOPLEVEL

XUlabel TIMELABEL $FORM labelString:"Connect time:  " \
	$(XUattach left 10 top 16 )

XUlabel TIME $FORM labelString:"00:00:00" \
	$(XUattach rightof $TIMELABEL 0 top 16)

XUpulldownmenu -u PULL $FORM

XUoptionmenu -u ISP "$FORM" \
	labelString:"ISP:  " \
	subMenuId:"$PULL" \
	$(XUattach right 10 top 10 )

selectISP
XUmanage $ISP

XUcolumn COLUMN $FORM \
	$(XUattach left 10 under $ISP 10 )

XUaddbuttons $COLUMN \
	BUTTON1 "Connect"	"connect"  \
	BUTTON2 "Disconnect"	"disconnect" \
	BUTTON3 "Exit"		"dialerExit"

XUtext TEXT $FORM \
	editMode:MULTI_LINE_EDIT \
	columns:40 \
	rows:8 \
	wordWrap:True \
	editable:False \
	$(XUattach rightof $COLUMN 10 under $ISP 10 right 10 bottom 32)

XUseparator SEP $FORM \
	$(XUattach left 0 right 0 under $TEXT 10)

XUlabel STATUS $FORM labelString:"" \
	$(XUattach left 10 bottom 1 under $SEP 0)

if [[ -f /etc/resolv.conf ]]
then
	XUinsensitive $BUTTON1
	XUaddtimeout CLOCKTIMER 1000 clockTimer
else
	XUinsensitive $BUTTON2
fi

typeset -i LINECOUNT=0
XUaddtimeout LOGTIMER 1000 logTimer

XUrealize $TOPLEVEL

if [[ -f $DIALER_PATH/is.running ]]
then
	XUset $STATUS labelString:"Unknown"
	XUwarning -m "$APPNAME" \
		"The dialer may already
		be running.  Continue?" \
		"XUregisterwindowclose dialerExit; LINECOUNT=1" \
		"exit 1"
else
	/usr/bin/touch $DIALER_PATH/is.running
	XUregisterwindowclose dialerExit
fi

XUmainloop
