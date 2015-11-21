#!/bin/ksh

#
# ps
#
# Version 1.0
#
# Author: Bitt Faulk <bitt@beaglebros.com>
#
#
# A wrapper for two different ps binaries, so that both BSD and SysV
# features can be used seamlessly.
#
# Based slightly on the Linux procps ps command, which acts similarly
# to this script and the two related binaries.
#

SYSVPS=/usr/bin/ps
BSDPS=/usr/ucb/ps

DEFAULTPS=$SYSVPS

if [ -n "$1" ]; then
        typeset -L1 SV=$1
        if [ "$SV" = "-" ]; then
                exec $SYSVPS $@
        else
                exec $BSDPS $@
        fi
else
        exec $DEFAULTPS $@
fi
