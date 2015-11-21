#!/usr/bin/sh
#
# This utility is used to list all of the open ports on a Solaris UNIX 
# based machine. It relies heavily on tools that are used to read through
# the /proc directory so it needs to be run as root or as a root equivalent.
#
# The pathname for all executables should reside in root's path statement
# for ldd to work correctly with this script
#
# Originally posted at: http://www.ilkda.com/op.htm
# Submitter: Alan Pae
# 
# nmap is a great tool that will show you what is listening on each port
# of a given machine.
# 
# nmap tries to give you some information about each port that it finds.
# It does not assume that any service is listening on any port number and
# it will tell you what is listening on the port if it is told to do so
# and it is able to do so.
# 
# However, I felt that the information that was given to me via nmap still
# left a lot of research to do on each port so I threw a script together
# to tell you what process is listening on each port and to give you some
# more information about the process so you can tell at a glance what is
# happening on the system that you are responsible for.
# 
# Enjoy the script.
# 
#
# Sample output:
#
#    -----------------------------------------------------
#    Process ID #: 154
#
#    Ports used: 
#     	sockname: AF_INET 0.0.0.0  port: 68
#    	sockname: AF_INET6 ::  port: 546
#    	sockname: AF_INET 127.0.0.1  port: 4999
#    	sockname: AF_INET 127.0.0.1  port: 4999
#    	sockname: AF_INET 10.0.0.64  port: 68
#
#    COMMAND                    
#    /sbin/dhcpagent                    
#
#    Command Line #2: /sbin/dhcpagent 
#
#    Environment Variables: 154:	/sbin/dhcpagent
#    envp[0]: LANG=C
#    envp[1]: LD_LIBRARY_PATH=/lib
#    envp[2]: PATH=/usr/sbin:/usr/bin
#    envp[3]: SMF_FMRI=svc:/network/physical:default
#    envp[4]: SMF_METHOD=start
#    envp[5]: SMF_RESTARTER=svc:/system/svc/restarter:default
#    envp[6]: SMF_ZONENAME=global
#    envp[7]: SUNW_NO_MPATHD=
#    envp[8]: TZ=US/Pacific
#    envp[9]: _INIT_NET_STRATEGY=none
#
#    Libraries used: /sbin/dhcpagent 
#     	libxnet.so.1 =>	 /lib/libxnet.so.1
#    	libnvpair.so.1 =>	 /lib/libnvpair.so.1
#    	libdhcpagent.so.1 =>	 /lib/libdhcpagent.so.1
#    	libdhcputil.so.1 =>	 /lib/libdhcputil.so.1
#    	libinetutil.so.1 =>	 /lib/libinetutil.so.1
#    	libdevinfo.so.1 =>	 /lib/libdevinfo.so.1
#    	libdlpi.so.1 =>	 /lib/libdlpi.so.1
#    	libc.so.1 =>	 /lib/libc.so.1
#    	libnsl.so.1 =>	 /lib/libnsl.so.1
#    	libsocket.so.1 =>	 /lib/libsocket.so.1
#    	libuuid.so.1 =>	 /lib/libuuid.so.1
#    	libgen.so.1 =>	 /lib/libgen.so.1
#    	libsec.so.1 =>	 /lib/libsec.so.1
#    	libdladm.so.1 =>	 /lib/libdladm.so.1
#    	libmp.so.2 =>	 /lib/libmp.so.2
#    	libmd.so.1 =>	 /lib/libmd.so.1
#    	libscf.so.1 =>	 /lib/libscf.so.1
#    	libavl.so.1 =>	 /lib/libavl.so.1
#    	librcm.so.1 =>	 /lib/librcm.so.1
#    	libkstat.so.1 =>	 /lib/libkstat.so.1
#    	libuutil.so.1 =>	 /lib/libuutil.so.1
#    	libm.so.2 =>	 /lib/libm.so.2
#
#   Maximum number of file descriptors = unlimited file descriptors
#
#    Effective	 Real	 Effective	 Real
#    User		 User	 Group		 Group
#
#    root 		 root 	 root 		 root
#
#    Current Working Directory: /
#
#    elfsign: verification of /sbin/dhcpagent passed.
#
#    -----------------------------------------------------
#
#
for i in `ls /proc`
do
openport=`pfiles $i 2> /dev/null |grep "port:"`
if [ ! -z "$openport" ]; then
echo "Process ID #: $i"
echo ""
echo "Ports used: \n $openport"
echo ""
commandline=`/usr/ucb/ps awwx $i | awk '{print $5,$6,$7,$8,$9,$10,$11,$12,$13,$14,$15,$16,$17,$18,$19,$20,$21,$22,$23,$24,$25}'`
echo "$commandline"
echo ""
commandline2=`pargs -l $i`
echo "Command Line #2: $commandline2" 
echo ""
eco=`pargs -e $i`
echo "Environment Variables: $eco"
echo ""
deps=`ps -ef | awk '{print $2,$8}' | grep $i`
deps2=`echo $deps | awk '{print $2}'`
deps3=`which $deps2`
deps4=`ldd $deps3`
echo "Libraries used: $deps3 \n $deps4"
echo ""
filedescriptors=`pfiles $i | grep rlimit | awk '{print $3,$4,$5}'`
echo "Maximum number of file descriptors = $filedescriptors"
echo ""
eu=`ps -o user -p $i`
ru=`ps -o ruser -p $i`
eg=`ps -o group -p $i`
rg=`ps -o rgroup -p $i`
effectiveuser=`echo $eu | awk '{print $2}'`
realuser=`echo $ru | awk '{print $2}'`
effectivegroup=`echo $eg | awk '{print $2}'`
realgroup=`echo $rg | awk '{print $2}'`
echo "Effective	 Real	 Effective	 Real"
echo "User		 User	 Group		 Group"
echo ""
echo "$effectiveuser \t\t $realuser \t $effectivegroup \t\t $realgroup"
echo ""
current=`pwdx $i | awk '{print $2}'`
echo "Current Working Directory: $current"
echo ""
elfsign verify -e $deps3
echo ""
echo "-----------------------------------------------------"
fi
done




##############################################################################
### This script is submitted to BigAdmin by a user of the BigAdmin community.
### Sun Microsystems, Inc. is not responsible for the
### contents or the code enclosed. 
###
###
### Copyright 2008 Sun Microsystems, Inc. ALL RIGHTS RESERVED
### Use of this software is authorized pursuant to the
### terms of the license found at
### http://www.sun.com/bigadmin/common/berkeley_license.html
##############################################################################


