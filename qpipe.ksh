#!/bin/ksh
# Script to demonstrate using pipe in unix. 
# 'mknod' unix command used to create a FIFO pipe(named pipe)
# This sample script shows how to use pipe with 
# other Unix command or utility.
#
# submitted by : arjun.singh@hpsglobal.com
#

# Create pipe file. 
# If already exists quit from program else execute.
PIPE_FILE=mypipe
COMPRESS_FILE=/tmp/dbexport.Z

[ -p ${PIPE_FILE} ] && echo "pipe ${PIPE_FILE} already exists.Quiting...!" && exit 1
mknod ${PIPE_FILE} p

if [ $? -ne 0 ]
then
      echo "${PIPE_FILE} creation failed!!!."
  exit 1
fi

# Copy file and compress it. 
# Modified the command argument or parameterised it as per the need.
# Here the script uses the sample names for example only.

# Run in background, otherwise the foreground process is 
# blocked until something reads the pipe
cat ${PIPE_FILE}|compress - > ${COMPRESS_FILE} &

# Copy file through pipe
cp user_export.dmp ${PIPE_FILE}




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


