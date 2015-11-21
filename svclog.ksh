#! /usr/bin/ksh
###############
# svclog
#
# SYNTAX : svclog [options] FMRI
#          See usage function for possible options
#
# PURPOSE : Display log file content of service (FMRI)
#
# CDDL HEADER START
#
# The contents of this file are subject to the terms of the
# Common Development and Distribution License, Version 1.0 only
# (the "License").  You may not use this file except in compliance
# with the License.
#
# You can obtain a copy of the license at usr/src/OPENSOLARIS.LICENSE
# or http://www.opensolaris.org/os/licensing.
# See the License for the specific language governing permissions
# and limitations under the License.
#
# When distributing Covered Code, include this CDDL HEADER in each
# file and include the License file at usr/src/OPENSOLARIS.LICENSE.
# If applicable, add the following below this CDDL HEADER, with the
# fields enclosed by brackets "[]" replaced with your own identifying
# information: Portions Copyright [yyyy] [name of copyright owner]
#
# CDDL HEADER END
#
# Copyright 2007 Peter A. van Gemert
#
# Current Version : 1.4 
#
# Change Log
# 01-03-2007 -  Version 1.5
#               Changed
#               Changed from GPL to CDDL copyright statement.
# 01-06-2006 -  Version 1.4
#               Added
#               -f : show log file of first maintenance service
#               This is now also the default behaviour for
#               svclog.
# 31-05-2006 -  Version 1.3
#               Added 
#               GPL copyleft statement.
# 11-05-2006 -  Version 1.2
#               Added
#               -h : print help message
#               -t : see -l
#               -x : show log file of failed dependency
#               -X : show log file of all failed dependecies
# 08-05-2006 -  Version 1.1
#               Added
#               -c : Use cat as pager
# 02-05-2006 -  Version 1.0
#               Published svclog


#################
### Set variables
###
AWK="/usr/bin/awk"
CAT="/usr/bin/cat"
GREP="/usr/bin/grep"
HEAD="/usr/bin/head"
PAGER="${PAGER:-/usr/bin/more}"
SVCS="/usr/bin/svcs"
SVCS_X="${SVCS} -x"
SVCPROP="/usr/bin/svcprop"
SVCPROP_P="${SVCPROP} -p restarter/logfile"
TAIL="/usr/bin/tail"



#############
### Functions
###
function usage {
	{ # Output redirection
		print "Error: $(basename $0) [-chnxX] [-l count] [-t count] FMRI"
		print "          -c  - Use cat as pager"
		print "          -f  - Print contents of log file of first"
		print "                service found in maintenance. (Default)"
		print "          -h  - Print this message"
		print "          -l  - Print only last count lines of log file"
		print "          -n  - Only print log file name"
		print "          -t  - see -l"
                print "          -x  - Print contents of log file of first"
                print "                failed dependency service (according"
                print "                to svcs -x)"
		print "          -X  - Print contents of log files of"
		print "                all failed dependency services"
	} >&2
	exit 2
}



function exit_nologdefinition {
	{ # Output redirection
		print "Could not find LOGFILE definition for ${FMRI}"
	} >&2
	exit 3
}



function exit_nomaintenanceservice {
	{ # Output redirection
		print "No service in maintenance found"
	} >&2
	exit 4
}



###################
### Process options
###
DEBUG=0
LINECOUNT=0
PRINTNAME=0
while getopts :cfhl:nt:xX option ; do
	case $option in
		c)	PAGER="/usr/bin/cat"
			;;
		f)	DEBUG=3
			;;
		h)	usage
			;;
		l)	LINECOUNT=${OPTARG}
			;;
		n)	PRINTNAME=1
			;;
		t)	LINECOUNT=${OPTARG}
			;;
		x)	DEBUG=1
			;;
		X)	DEBUG=2
			;;
	esac
done
shift ${OPTIND}-1



############
### Check $1
###
if [[ $# -eq 0 ]] ; then
	DEBUG=3
elif [[ $# -eq 1 ]] ; then
	FMRI=$1
else
	usage
fi



##############################
### Get log file of service(s)
###
if [[ ${DEBUG} -eq 3 ]] ; then
	FMRI=$(${SVCS} | 
		${GREP} "^maintenance" | 
		${HEAD} -1 | 
		$AWK '{print $3}' )

	[[ -z ${FMRI} ]] && exit_nomaintenanceservice

	LOGFILES=$( ${SVCPROP_P} ${FMRI} 2>/dev/null )
	[[ $? -ne 0 ]] && exit_nologdefinition

elif [[ ${DEBUG} -eq 0 ]] ; then
	LOGFILES=$( ${SVCPROP_P} ${FMRI} 2>/dev/null )
	[[ $? -ne 0 ]] && exit_nologdefinition

else
	dependencies=$( ${SVCS_X} ${FMRI} | ${AWK} '
		/^Reason:/ {print $3}' )

	LOGFILES=""
	for fmri in ${dependencies} ; do
		logfile="$( ${SVCPROP_P} ${fmri} 2>/dev/null )"
		[[ ! -r $logfile ]] && continue

		# If logfile is readable add it to logfiles list
		LOGFILES="${LOGFILES} ${logfile}"

		# IF -x then we are only interested in the first
		# service log file found. With -X we want to see
		# ALL service log files.
		[[ ${DEBUG} -eq 1 ]] && break
	done
fi



################################################
### Display log file content when log file found
###
[[ -z ${LOGFILES} ]] && exit_nologdefinition

### Generate output for -n option
if [[ ${PRINTNAME} -eq 1 ]] ; then
	for logfile in ${LOGFILES} ; do
		print ${logfile}
	done
	exit 0
fi


### Display content with pager
if [[ ${LINECOUNT} -eq 0 ]] ; then
	${PAGER} ${LOGFILES}

else
	for logfile in $LOGFILES ; do
		print -- "-->${logfile}"
		${TAIL} -${LINECOUNT} ${logfile}
		print
	done
fi

# eos





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


