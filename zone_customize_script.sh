# !!! This script will be executed by /bin/sh

# ------------------------------------------------------------------------- #
#
#   Pre Req:
#
#   The Perl and RCM package must be installed.
#
# ------------------------------------------------------------------------- #

# --------------------------- 
# constants
#
TRUE=0
FALSE=1

# --------------------------- global variables
#
# Solaris Version 
OS_VER=`uname -r`

# hostname 
NODENAME=`uname -n`

# hostid for RCM access
RCMHOSTID=`nslookup ${NODENAME} | grep Name: | cut -f2`
[ "${RCMHOSTID}"x = ""x ] && RCMHOSTID="${NODENAME}"


# ksh syntax!
#THISSCRIPT="${0##*/}"

# --------------------------- sub routines 
 LogMsg() {
	echo "${THISSCRIPT}: $*"
}

LogErrorMsg() {
	LogMsg "ERROR: $*" >&2
}

die () {
	typeset THISRC=$1
	if [ $# -gt 1 ] ; then
		shift
		[ ${THISRC} = 0 ] && LogMsg "$*" || LogErrorMsg "$*"
	fi
	exit ${THISRC}
}

# --------------------------- main function

# include the zone config file if it exists
#
# Note: 
#
# see create_zone.sh for the variables in the zone config file
#
ZONE_CONFIG_FILE="/etc/create_zone.cfg"

SMF_SERVICES_TO_DISABLE="sendmail 
svc:/application/cde-printinfo:default 
svc:/network/ssh:default
svc:/system/filesystem/autofs:default"

RCM_PACKAGES="IBMRcmc IBMPl588"


if [ -r "${ZONE_CONFIG_FILE}" ] ; then
	LogMsg "Reading the zone config file \"${ZONE_CONFIG_FILE}\" ..."
	ZONE_CUSTOMIZE_SCRIPT_TARGET=` grep "^ZONE_CUSTOMIZE_SCRIPT_TARGET=" "${ZONE_CONFIG_FILE}" | cut -f2 -d "=" | tr -d "'" `
#	'
else
	LogMsg "The zone config file \"${ZONE_CONFIG_FILE}\" does not exist or is not readable ..."
fi

if [ "${ZONE_CUSTOMIZE_SCRIPT_TARGET}"x != ""x ] ; then
	THISSCRIPT="${ZONE_CUSTOMIZE_SCRIPT_TARGET}"
else
	THISSCRIPT="` basename $0 `"
fi

LogMsg "Checking prerequisites ..."

# get the zonename
ZONENAME=` zonename` || die 10 "zonename not found or not executable -- zone support is not installed. Exiting"

LogMsg "Running in the zone \"${ZONENAME}\" ..."
[ "${ZONENAME}"x = "global"x ] && die 11 "This script is not intended for the global zone. Exiting"

# check if the necessary packages are installed
#
LogMsg "Checking required packages ..."

PKGS_MISSING=${FALSE}
for CUR_PACKAGE in ${RCM_PACKAGES} ; do
	pkginfo -l "${CUR_PACKAGE}" 
	if [ $? -ne 0 ] ; then
		LogErrorMsg "The package \"${CUR_PACKAGE}\" is NOT installed"
		PKGS_MISSING=${TRUE}
	fi
done
[ "${PKGS_MISSING}" = ${TRUE} ] && die 15 "One or more packages are missing"


LogMsg "Configuring the zone \"${ZONENAME}\" ...."

LogMsg "Disabling not used SMF services ..."

for CUR_SERVICE in ${SMF_SERVICES_TO_DISABLE} ; do
	echo "Disabling the SMF service \"${CUR_SERVICE}\" ..." 
	svcadm disable "${CUR_SERVICE}"
done

# Allow logins by root from anywhere !!!
#
grep "^CONSOLE" /etc/default/login >/dev/null
if [ $? -eq 0 ] ; then
	cp /etc/default/login /etc/default/login.org && \
		sed 's/^CONSOLE=\/dev\/console/#CONSOLE=\/dev\/console/' /etc/default/login.org >/etc/default/login
else
	LogMsg "/etc/default/login already corrected."
fi

grep "System user owned by SCM" /etc/passwd >/dev/null
if [ $? -ne 0 ] ; then
	LogMsg "Adding comments in /etc/passwd for standard users ..."
	cp /etc/passwd /etc/passwd.org

	awk -F\: '{
	printf("%s:%s:%s:%s:%s:%s:%s\\n"),$1, $2, $3, $4, $5="System user owned by SCM", $6, $7}' /etc/passwd.org > /tmp/passwdmod.$$
	if [ $? -eq 0 ]; then
		cp /tmp/passwdmod.$$ /etc/passwd
		rm /tmp/passwdmod.$$
	else
		rm /tmp/passwdmod.$$
	fi
else
	LogMsg "/etc/passwd already corrected."
fi

# new code ENDS here

# set default umask for all following directory and file creation
umask 022

grep hosts /etc/nsswitch.conf | grep dns >/dev/null
if [ $? -ne 0 ] ;then
	cp /etc/nsswitch.conf /etc/nsswitch.conf.org && \
		sed 's/^hosts:.*files/hosts:	files dns/' /etc/nsswitch.conf.org >/etc/nsswitch.conf
else
	LogMsg "/etc/nsswitch.conf already corrected."
fi


if [ -f /etc/auto_master ] ; then
	grep "^/home" /etc/auto_master >/dev/null
	if [ $? -ne 0 ] ; then
		cp /etc/auto_master /etc/auto_master.org && \
			sed 's/^\/home/#\/home/' /etc/auto_master.org >/etc/auto_master 
		svcadm disable autofs
	else
		LogMsg "/etc/auto_master already corrected."
	fi
fi

LogMsg "Configuring the nodename & hostname of the machine ..."

cat >/etc/nodename <<EOF
${NODENAME}
EOF

for CURFILE in /etc/net/ticlts/hosts /etc/net/ticots/hosts /etc/net/ticotsord/hosts ; do
	cat >${CURFILE} <<EOF
#ident "@(#)hosts      1.2     92/07/14 SMI"   /* SVr4.0 1.2   */
# RPC Hosts
${NODENAME} ${NODENAME}
EOF
done


ps -ef | grep -v grep | grep rcmd.pl >/dev/null
if [ $? -ne 0 ] ; then
	LogMsg "Configuring the machine for the RCM methods ..."
	/usr/db/RCM/scripts/make_rcm_c.pl

	mkdir -p /var/db/work
	mkdir -p /var/db/var
	cat >/var/db/var/hostid <<EOF
${RCMHOSTID}
EOF
else
	LogMsg "rcmd is already running, skipping rcm client make script execution."
fi

LogMsg "Creating the user for the zone ..."
/usr/db/RCM/Scripts/make_users.pl --user sshd


if [ ! -f /etc/ssh/ssh_host_dsa_key ] ; then
	LogMsg "Configuring sshd ...."
        SSH_SCRIPT_DIR="`ls -1trd /applications/ssh/*/scripts | tail -1`"
	if [ "${SSH_SCRIPT_DIR}"x = ""x ] ; then
		LogMsg "ssh not installed in this zone"
	else
		SSH_MAKE_SCRIPT1="${SSH_SCRIPT_DIR}/make_openssh_norcm.sh"
		if [ -x "${SSH_MAKE_SCRIPT1}" ] ;then
			${SSH_MAKE_SCRIPT1}
		else
			LogMsg "\"${SSH_MAKE_SCRIPT1}\" not found or not executable"
		fi

		SSH_MAKE_SCRIPT2="${SSH_SCRIPT_DIR}/make_openssh.pl"
		if [ -x "${SSH_MAKE_SCRIPT2}" ] ; then
			${SSH_MAKE_SCRIPT2}
		else
			LogMsg "\"${SSH_MAKE_SCRIPT2}\" not found or not executable"
		fi

		if [ -x /etc/init.d/sshd ] ; then
			LogMsg "Starting the sshd daemon ..."
                        /etc/init.d/sshd stop
                        /etc/init.d/sshd start

		else
			LogMsg "\"/etc/init.d/sshd\" not found - can not start the ssh daemon"
		fi
	fi
else
	LogMsg "ssh already configured."
fi
	
# added by /bs 09.10.2006 
# workaround for the NFS incompatiblity between Solaris 10 and AIX
#
grep "NFS_CLIENT_VERSMAX=3" /etc/default/nfs >/dev/null
if [ $? -ne 0 ] ; then
	LogMsg "Configuring workaround for NFS v4 compatibility between AIX and Solaris 10 (= use always NFS 3 or below)"
	if [ -f /etc/default/nfs ] ; then
		cp /etc/default/nfs /etc/default/nfs.org && \
			sed 's/^[#]NFS_CLIENT_VERSMAX=.*/NFS_CLIENT_VERSMAX=3/g' /etc/default/nfs.org >/etc/default/nfs
	else
		echo "NFS_CLIENT_VERSMAX=3" >/etc/default/nfs
	fi
else
	LogMsg "/etc/default/nfs already corrected."
fi

# This is too strong, does not apply root password
#rm /etc/.UNCONFIGURED
[ -f /etc/rc2.d/S30sysid.net ] && mv /etc/rc2.d/S30sysid.net /etc/rc2.d/DONOT.S30sysid.net

LogMsg "Creating profile files for the root user ..."

ROOT_HOME="` grep root /etc/passwd | cut -f 6 -d ":" `"
[ "${ROOT_HOME}"x = "/"x ] && ROOT_HOME=""

LogMsg "The home directory for root is \"${ROOT_HOME}\" "

LogMsg "Creating the profile files for the root user ..."

if [ ! -f ${ROOT_HOME}/.bashrc ] ; then
	cat >${ROOT_HOME}/.bashrc <<EOF
PS1="[\d \t \u@\h \w]\n# "
EOF
	[ -f ${ROOT_HOME}/.bashrc ] && chmod 755 ${ROOT_HOME}/.bashrc
else
	LogMsg "The file \"${ROOT_HOME}/.bashrc\" already exists."
fi

if [ ! -f ${ROOT_HOME}/.kshrc ] ; then
	cat <<EOT >${ROOT_HOME}/.kshrc
	# Old Prompt:
	#PS1="(ksh)/$LOGNAME@`uname -n` # "
	#
	PS1="(ksh):$LOGNAME@`uname -n|cut -d . -f1`\"':/\${PWD#*/} # '"
	EDITOR=vi
	FCEDIT=/usr/bin/vi
	export EDITOR FCEDIT
	HISTFILE=$HOME/.sh_history
	HISTSIZE=512
	export VISUAL=vi
	set -o emacs
	set -o monitor
	#
	# Aliases
	alias h=history
	alias smallps="PS1=\"(ksh):$LOGNAME@`uname -n|cut -d . -f1` # \""
	alias bigps="PS1=\"(ksh):$LOGNAME@`uname -n|cut -d . -f1`\"':/\${PWD#*/} # '"
	alias  cdb='cd /usr/db/bin'
	alias  cdi='cd /usr/sys/inst.images'
	alias  cdr="cd $/usr/db/RCM/Scripts"
	alias  vv='view'
	#
EOT
	[ -f ${ROOT_HOME}/.kshrc ] && chmod 755 ${ROOT_HOME}/.kshrc
else
	LogMsg "The file \"${ROOT_HOME}/.kshrc\" already exists."
fi

if [ ! -f ${ROOT_HOME}/.profile ] ; then
	cat <<EOT >${ROOT_HOME}/.profile
	MANPATH=$MANPATH:/usr/share/man:/usr/openwin/share/man:/usr/dt/man
	if [ -d /opt/VRTSvxvm ] ; then
		MANPATH=$MANPATH:/opt/VRTSvxvm/man
	fi
	PATH=$PATH:/usr/db/RCM/Scripts:/usr/db/RCM/scripts:/usr/db/RCM/Utility
	export PATH
	export MANPATH
	#
	EDITOR=/usr/bin/vi
	TERM=vt100
	export EDITOR TERM
	stty erase '^h'
	PS1="(sh):$LOGNAME@`uname -n|cut -d . -f1` # "
	test -x /usr/openwin/bin/resize && /usr/openwin/bin/resize
	ENV=$HOME/.kshrc
	export ENV
EOT
	[ -f ${ROOT_HOME}/.profile ] && chmod 755 ${ROOT_HOME}/.profile
else
	LogMsg "The file \"${ROOT_HOME}/.profile\" already exists."
fi

if [ "${ZONE_CUSTOMIZE_SCRIPT_TARGET}"x != ""x ] ; then
	LogMsg "Removing \"${ZONE_CUSTOMIZE_SCRIPT_TARGET}\" ..."
	rm "${ZONE_CUSTOMIZE_SCRIPT_TARGET}"
else
	LogMsg "Variable ZONE_CUSTOMIZE_SCRIPT_TARGET not set"
fi

exit 0
