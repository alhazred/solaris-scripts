#!/bin/sh
#
# Nagios plugin to check Solaris CPU usage.
#
# $Id: check_solaris_cpu_usage.sh,v 1.3 2008/09/09 06:39:22 kivimaki Exp $
#
# Copyright (C) 2007-2008  Hannu Kivimäki / CSC - Scientific Computing Ltd.
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
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
#

# External commands
CMD_AWK="/usr/bin/awk"
CMD_MPSTAT="/usr/bin/mpstat"
CMD_TAIL="/usr/bin/tail"

# Nagios plugin return values
STATE_OK=0
STATE_WARNING=1
STATE_CRITICAL=2
STATE_UNKNOWN=3
STATE_TEXT=""

# Default values
CPU_USAGE=0
CPU_WARN_MIN=-1
CPU_WARN_MAX=101
CPU_CRIT_MIN=-1
CPU_CRIT_MAX=101
WARN_TRIGGER=0
CRIT_TRIGGER=0
VERBOSE=0

# ------------------------------ FUNCTIONS -------------------------------------

printInfo() {
    echo "Nagios plugin to check Solaris CPU usage."
    echo "Copyright (C) 2007-2008  Hannu Kivimäki / CSC - Scientific Computing Ltd."
}

printHelp() {
    echo
    echo "Usage: `basename $0` [-w <range>] [-c <range>]"
    echo
    echo "  -w  CPU usage% warning safe range ([min]:[max]) as integers"
    echo "  -c  CPU usage% critical safe range ([min]:[max]) as integers"
    echo "  -h  this help screen"
    echo "  -l  license info"
    echo "  -v  verbose output (for debugging)"
    echo "  -V  version info"
    echo
    echo "Note about safe ranges: You can give the minimum (min:) or maximum (:max)"
    echo "CPU usage percentage or both (min:max). Values must be integers between"
    echo "0-100 and mins must be less than maxes."
    echo
    echo "Example: `basename $0` -w :60 -c :75"
    echo "This will return CRITICAL if CPU usage is above 75%, WARNING if"
    echo "CPU usage is above 60% and OK otherwise. In case of errors"
    echo "plugin returns UNKNOWN."
    echo
}

printLicense() {
    echo
    echo "This program is free software; you can redistribute it and/or"
    echo "modify it under the terms of the GNU General Public License"
    echo "as published by the Free Software Foundation; either version 2"
    echo "of the License, or (at your option) any later version."
    echo
    echo "This program is distributed in the hope that it will be useful,"
    echo "but WITHOUT ANY WARRANTY; without even the implied warranty of"
    echo "MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the"
    echo "GNU General Public License for more details."
    echo
    echo "You should have received a copy of the GNU General Public License"
    echo "along with this program; if not, write to the Free Software"
    echo "Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA."
    echo
}

printVersion() {
    echo
    echo "\$Id: check_solaris_cpu_usage.sh,v 1.3 2008/09/09 06:39:22 kivimaki Exp $"
    echo
}

# Checks command line options (pass $@ as parameter).
checkOptions() {
    if [ $# -eq 0 ]; then
        printInfo
        printHelp
        exit $STATE_UNKNOWN
    fi

    while getopts w:c:lhvV OPT $@; do
            case $OPT in
                w) # warning range
                   opt_warn_min=`echo $OPTARG | $CMD_AWK 'BEGIN{FS=":"}{print \$1}'`
                   opt_warn_max=`echo $OPTARG | $CMD_AWK 'BEGIN{FS=":"}{print \$2}'`
                   WARN_TRIGGER=1
                   ;;
                c) # critical range
                   opt_crit_min=`echo $OPTARG | $CMD_AWK 'BEGIN{FS=":"}{print \$1}'`
                   opt_crit_max=`echo $OPTARG | $CMD_AWK 'BEGIN{FS=":"}{print \$2}'`
                   CRIT_TRIGGER=1
                   ;;
                l) printInfo
                   printLicense
                   exit $STATE_UNKNOWN
                   ;;
                h) printInfo
                   printHelp
                   exit $STATE_UNKNOWN
                   ;;
                v) VERBOSE=1
                   ;;
                V) printInfo
                   printVersion
                   exit $STATE_UNKNOWN
                   ;;
                ?) printInfo
                   printHelp
                   exit $STATE_UNKNOWN
                   ;;
            esac
    done

    range_error=0
    if [ $WARN_TRIGGER -eq 1 ]; then
        if [ "$opt_warn_min" != "" ]; then
            if [ "`echo $opt_warn_min | grep '^[0-9]*\$'`" = "" ]; then
                range_error=1
            elif [ $opt_warn_min -lt 0 ] || [ $opt_warn_min -gt 100 ]; then
                range_error=1
            fi
            CPU_WARN_MIN=$opt_warn_min
        fi
        if [ "$opt_warn_max" != "" ]; then
            if [ "`echo $opt_warn_max | grep '^[0-9]*\$'`" = "" ]; then
                range_error=1
            elif [ $opt_warn_max -lt 0 ] || [ $opt_warn_max -gt 100 ]; then
                range_error=1
            fi
            CPU_WARN_MAX=$opt_warn_max
        fi
        if [ $CPU_WARN_MIN -ge $CPU_WARN_MAX ]; then
            range_error=1
        fi
    fi
    if [ $CRIT_TRIGGER -eq 1 ]; then
        if [ "$opt_crit_min" != "" ]; then
            if [ "`echo $opt_crit_min | grep '^[0-9]*\$'`" = "" ]; then
                range_error=1
            elif [ $opt_crit_min -lt 0 ] || [ $opt_crit_min -gt 100 ]; then
                range_error=1
            fi
            CPU_CRIT_MIN=$opt_crit_min
        fi
        if [ "$opt_crit_max" != "" ]; then
            if [ "`echo $opt_crit_max | grep '^[0-9]*\$'`" = "" ]; then
                range_error=1
            elif [ $opt_crit_max -lt 0 ] || [ $opt_crit_max -gt 100 ]; then
                range_error=1
            fi
            CPU_CRIT_MAX=$opt_crit_max
        fi
        if [ $CPU_CRIT_MIN -ge $CPU_CRIT_MAX ]; then
            range_error=1
        fi
    fi
    if [ $range_error -eq 1 ]; then
        echo "Error: Invalid safe range values."
        printInfo
        printHelp
        exit $STATE_UNKNOWN
    fi
}

# ----------------------------- MAIN PROGRAM -----------------------------------

checkOptions $@

if [ $VERBOSE -eq 1 ]; then
    echo "Executing $CMD_MPSTAT -a 3 2 | $CMD_TAIL -1 | $CMD_AWK '{printf(\"usr=%d sys=%d idle=%d\"), \$13, \$14, \$16}'..."
fi
CPU_USR_SYS_IDLE_3SEC_AVG=`$CMD_MPSTAT -a 3 2 | $CMD_TAIL -1 | $CMD_AWK '{printf("usr=%d sys=%d idle=%d"), $13, $14, $16}'`
CPU_USAGE=`echo $CPU_USR_SYS_IDLE_3SEC_AVG | $CMD_AWK -F= '{print 100-\$NF}'`

STATE_TEXT="- $CPU_USAGE% ($CPU_USR_SYS_IDLE_3SEC_AVG)|usage=$CPU_USAGE $CPU_USR_SYS_IDLE_3SEC_AVG"

if [ $CRIT_TRIGGER -eq 1 ]; then
    if [ $CPU_USAGE -lt $CPU_CRIT_MIN ] || [ $CPU_USAGE -gt $CPU_CRIT_MAX ]; then
        echo "CPU USAGE CRITICAL $STATE_TEXT"
        exit $STATE_CRITICAL
    fi
fi
if [ $WARN_TRIGGER -eq 1 ]; then
    if [ $CPU_USAGE -lt $CPU_WARN_MIN ] || [ $CPU_USAGE -gt $CPU_WARN_MAX ]; then
        echo "CPU USAGE WARNING $STATE_TEXT"
        exit $STATE_WARNING
    fi
fi

echo "CPU USAGE OK $STATE_TEXT"
exit $STATE_OK
