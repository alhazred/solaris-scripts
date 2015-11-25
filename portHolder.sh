#!/bin/sh

# author Jakub Podlesak (japod at sun dot com)

# common functions

print_usage(){
cat << EOF
Usage: $0 [-v] [-a] [-u uid] -p portnum
Options:
  -v ... verbose mode
  -p ... portnum which the owner should be detected for
  -a ... print arguments for the processes found as well 
  -u ... search just processes for given uid or login name
EOF
}

print_msg(){
    if test ! -z "$VERBOSE_MODE" ;then
        echo $1
    fi
}

# MAIN

# parse the command line options

args=`getopt vl:ap: $*`
if test $? -ne 0 ;then
    print_usage
    exit 1
fi

LIMIT_UID=""

set -- $args

for a in $* ;do
    case "$a" in
        -v)
            VERBOSE_MODE="VERBOSE"
            shift;;
        -a)
            PRINT_ARGS="TRUE"
            shift;;
        -p)
            PORTNUM="$2"; shift;
            shift;;
        -u)
            LIMIT_UID="-u $2"; shift;
            shift;;
        --)
            shift;
            break;;
    esac
done
    

if test -z "$PORTNUM" ;then
    print_usage
    exit 1
fi

PIDS=`ps -ef $LIMIT_UID| awk '{ print $2 }' | sed 1d` 
for p in $PIDS ;do
    pfiles $p 2> /dev/null | grep "port: $PORTNUM" > /dev/null 2>&1
      if test 0 -eq $? ;then
        if test -z "$PRINT_ARGS" ;then
          ps -p $p | sed 1d
        else
          pargs -l $p
        fi	  
      fi
  done

print_msg "Done:o)"

