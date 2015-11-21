#!/bin/bash
# set -x
#
# Version 1.8.1
# Maintainer: Brad Diggs 
# Contributors: 
#    Alan Nichols, Anthony Waldron Christian Candia, John Clingan, Jeff Victor, 
#    and Patrick Woo
#
# The purpose of this script is to automate creating and managing Solaris 10 
# zones.
#
#   Copyright (C) 2006 Sun Microsystems, Inc. All rights reserved.
#   U.S. Government Rights - Commercial software. Government users are 
#   subject to the Sun Microsystems, Inc. standard license agreement and 
#   applicable provisions of the FAR and its supplements.
#
#   Use is subject to license terms. Sun, Sun Microsystems, the Sun logo 
#   and Solaris are trademarks or registered trademarks of Sun 
#   Microsystems, Inc. in the U.S. and other countries.
#
#  You can view the CDDL license by running this script with the
#  -l flag or http://www.sun.com/cddl
#  See the License for the specific language governing permissions
#  and limitations under the License.
# 
##############################################################################
### This script is submitted to BigAdmin by a user of the BigAdmin community.
### Sun Microsystems, Inc. is not responsible for the
### contents or the code enclosed.
###
###
### Copyright 2005 Sun Microsystems, Inc. ALL RIGHTS RESERVED
### Use of this software is authorized pursuant to the
### terms of the license found at
### http://www.sun.com/bigadmin/common/berkeley_license.html
##############################################################################
#
# Initialize variables
#
MYPATH="/usr/bin:/usr/sbin:/sbin:/usr/sfw/bin:/opt/sfw/bin:/usr/xpg4/bin:.:$PATH"
PATH="$MYPATH"
version='1.8.1'
zonetmpdir="$HOME/.zonemgr"
zonefile="$zonetmpdir/zone$$"
cswlog="$zonetmpdir/cswlog$$"
zcfg=''
zattrcfg=''
autoboot='true'
domains=''
domainname=''
zonetype='s'
zoneminimize=''
minimizationfile=''
rootHomeDir=''
ronum=0
rwnum=0
prefnum=0
postfnum=0
snum=0
rodirs[$ronum]=''
rwdirs[$rwnum]=''
pre_files[$prefnum]=''
post_files[$postfnum]=''
services[$snum]=''
pkgdefaults="/.pkgdefault"
forceaction='false'
n=0
zoneip[$n]=''
zoneif[$n]=''
zonenm[$n]=''
zonecidrnm[$n]=''
zoneipname[$n]=''
p=0
nfshost[$p]=''
nfsexport[$p]=''
nfsmount[$p]=''
nfsoptions[$p]=''
q=0
runcmd[$q]=''
brandname=''
brandsrcpath=''
brandsubset=''
r=0
pkglist[$r]=''
cnum=0
curProp[$cnum]=''
newProp[$cnum]=''
rcount=0
hardening_action='disable'
zone_privileges=''
newzonename=''
#
# Define pre-requisite packages
#
pkgreqs=( SUNWcar SUNWkvm SUNWcsr SUNWcsu SUNWcsl SUNWcsd SUNWzoner SUNWzoneu SUNWzfsr )

##############################################################################
#
# Define exit level error message routine
#
error_message() {
   errmsg=$1
   if [ -n "$errmsg" ]
   then 
      exec 1>&2
      echo -e "Error: $errmsg"
      echo "Use -h flag to see proper usage or -l flag to see the license."
      exec 1>&1
      exit 1
   fi
}

##############################################################################
#
# Define info level error message routine
#
info_error_message() {
   errmsg=$1
   if [ -n "$errmsg" ]
   then 
      echo -e "Error: $errmsg"
   fi
}

##############################################################################
#
# Check for the existence of requisite packages
#
ckpkgver() {
   mypkgs=( $@ )
   ck4err=''
   for (( i=0; i< ${#mypkgs[*]}; i++ ))
   do
      pkgvers=`pkginfo -l ${mypkgs[$i]} 2> /dev/null | awk '/VERSION/ { print $2 }'`
      if [ -n "$pkgvers" ]
      then
         mypkgs[$i]="${mypkgs[$i]}|$pkgvers"
      else
         info_error_message "Package ${mypkgs[$i]} is not installed."
         ck4err='true'
      fi
   done
   if [ -n "$ck4err" ]
   then
      exit 1
   fi
}

##############################################################################
#
# Find pager
#
findpager() {
   #
   # Set the page command
   #
   pgcmd='cat - '
   ck4less=`which less 2>&1 | grep -v "no less"`
   if [ -n "$ck4less" ]
   then
      pgcmd='less'
   else
      ck4more=`which more 2>&1 | grep -v "no more"`
      if [ -n "$ck4more" ]
      then
         pgcmd='more'
      fi
   fi
}

##############################################################################
#
# Define appropriate usage
#
usage() {
   errmsg=$1

   findpager

   usage_I='
         -I "<IP Address>|<Interface>|<Netmask>|<Host name>"
                            IP Address of the non-global zone 
                            plus the network interface for that 
                            IP address, the netmask in CIDR 
                            format, and the host name for that IP
                            address.
  
                            If not specified the default network 
                            interface is the first non-loopback 
                            interface listed by ifconfig.  The 
                            default netmask is the netmask that 
                            corresponds to the IP address that 
                            you specify. There is no default host
                            name.

                            Note that a zone can be created 
                            without a network address.
			    '
    usage_r='
         -r "<gdir>|<ldir>" Loopback mount global zone directory 
                            (gdir) on a non-global zone directory 
                            (ldir) in read only mode.
			    '

    usage_w='
         -w "<gdir>|<ldir>" Loopback mount global zone directory 
                            (gdir) on a non-global zone directory 
                            (ldir) in read write mode.
			    '
    usage_w_modify='
         -w "zfs|<dir>|zpool|zname"
                            Create a ZFS filesystem using legacy mode
                            and mount the ZFS filesystem within the 
                            zone.  Note that this filesystem is not
                            mounted in the global zone.  However, the
                            root user in the global zone can access
                            the contents of the mounted zfs 
                            filesystem because the root mount point of
                            the non-global zone is accessible as a 
                            directory in the global zone.
                            dir = The mount point inside the non-global
                                  zone
                            zpool = The ZFS pool name
                            zname = The ZFS filesystem name
			    '
        usage_c='
         -c "raw|<special>|<raw>|<type>|<ldir>|<options>"
                            Add a raw device to the zone configuration
                            special = character device /dev/dsk/XXX
                            raw = block device /dev/rdsk/XXX
                            type = file system type
                            ldir = mountpoint 
                            options = mount options
                            '
        usage_N='
         -N "<server>|<export_dir>|<mount_dir>|<options>"
                            Mount an NFS directory where <server>
                            is the NFS server host name or IP  
                            address, <export_dir> is the NFS 
                            exported directory, <mount_dir> is 
                            the mount point within the non-global
                            zone to mount the NFS filesystem, and
                            <options> are the NFS mount options.

                            Note that zones only supports 
                            mounting an NFS filesystem from a 
                            host on a separate physical server.
                            e.g. You cannot at the present time
                            mount an NFS filesystem from another
                            zone on this physical server.

        '

        usage_C='
         -C "<pre or post boot>|<source>|<destination>" 

         -C "<source>|<destination>"
                            File/Directory to recursively copy 
                            from the global zone into the non-
                            global zone.  The <pre or post boot>
                            option defines if you want the source
                            copied before the non-global zone is
                            booted (pre) or after (post) the zone
                            has completed its final boot.
                            The <destination> option is used to 
                            specify a different destination location 
                            in the non-global zone that presently 
                            exists in the global zone.
        '

        usage_p='
         -p "<resource>|<resource_arg>"
                            <resource> can be either cpu or ram.

                            <resource_arg> is either number of processors
                            or Mb of RAM depending on the resource specified.

                            Processor count enables you to specify the number
                            of processors that will be assigned to this zone.  

                            (Not yet available) RAM count enables you to 
                            specifiy the maximum amount of RAM in bytes that 
                            this zone can use.
        '

        usage_P_E='
         -P "<file or password>" 
                            Unencrypted password of the root user
                            of this new non-global zone.  The 
                            password can either be specified in
                            a file or as a quoted string.

            OR

         -E "<file or password>" 
                            This is an alternate way from 
                            -P <password> of specifying the non-
                            global root user's password via an 
                            encrypted format.  The encrypted 
                            password can either be specified in
                            a file or as a quoted string.  You 
                            can copy and paste the user's 
                            password from /etc/shadow).  

        '

        usage_z_Z='
         -z "<zonepath>"    Zonepath for this zone.
                            Zone / will be zonepath/zonename/root.
            
            OR

         -Z "<zonedir>"     Directory for zone root.
                            Zone / will be zonedir/root. 
        '

        usage_A='
         -A                 Disable autoboot (prevent zone from 
                            booting when the server reboots).
        '

        usage_s='
         -s "<method>|<method_arguments>"
                            This feature hardens the non-global
                            zone by disabling (or enabling)
                            un-necessary operating system 
                            services of the non-global zone
                            according to the method specified.
                            Hardening methods and corresponding
                            arguments are as follows:

                            Secure by default:
                              Method: netservices or sbd
                              Arguments: 
                                 limited - Eliminate un-necessary services
                                 open - Enable standard services

                            Service Management Facility Site 
                            Profile:
                              Method: smf
                              Argument: <fullpath>/<smf_xml_file>

                            JumpStart Architecture and Security 
                            Scripts (aka Solaris Security 
                            Toolkit):
                              Method: jass
                              Argument: <jass_driver_name> 

                            Basic service management:
                              Method: basic or enable or disable or lock or unlock
                              Argument: One of the following:
                                disable
                                lock
                                enable
                                unlock
                                disable|<service_list_file>
                                lock|<service_list_file>
                                enable|<service_list_file>
                                unlock|<service_list_file>
        '

        usage_M='
         -M [basic|<file>]  Minimize the non-global zone by 
                            either excluding or removing un-
                            necessary packages.  The optional
                            <file> is a file containing a list
                            of packages that you would like 
                            removed from the zone.  If no <file>
                            is specified, the following
                            categories will be removed with 
                            pkgrm -Y <category>:
                              JDS4 JDS3 JDS JDSosol GNOME2 CTL 
                              ALE APOC CTL EVO146 G11NTOLS GLOW 
                              JAI JAVAAPPS JDIC
        '

        usage_X='
         -X "<command> <args>"
                            Runs <command> inside the non-global
                            command once it is successfully 
                            created.  Note that you may need to 
                            include the full path to the command
                            as well. And you can pass <args>
                            (arguments) to the command if you 
                            include them in the quoted the 
                            command.
        '

        usage_G='
         -G <package>       Fully automates the installation of 
                            specified BlastWave package.  For a
                            full list of available BlastWave 
                            packages, visit the following URL:
                              http://blastwave.org/packages
        '



cat <<EOF | $pgcmd
Usage: $0 -a <action> -n <name>
System Administration Commands                        zonemgr(1M)

NAME
     zonemgr - set up and manage zones


SYNOPSIS
     Normal usage:
     zonemgr -a <action> [options]

     See proper usage:
     zonemgr -h

     Display the version:
     zonemgr -v

     Display the license:
     zonemgr -l 

DESCRIPTION
     The purpose of zonemgr is to simplify Solaris 10 zones 
     management.  There are many pre-defined actions that can be
     applied to one or more zones depending on the action. 


OPTIONS
     The following options are supported:

     -a <action>     Specify the action to be performed

     -n <zonename>   Specify the name of the zone

     -h              See this usage information

     -l              See the GPL v2 license

     -v              See the version number of this script


ACTIONS
     Actions which can result in destructive actions or loss
     of work have a -F flag to force the action. 

     The following actions are supported:

     info -n <zonename> 
         The "info" action displays configuration information 
         about a zone.


     add -n <zonename> -z <dir> [add_options]
         The "add" action adds a new zone.

         The following add_options are required:
$usage_P_E
$usage_z_Z
         The following add_options can be used as substitutes for
         the required options:


         The following optional add_options are supported:

         -t <w or s>        Type of zone where w=Whole Root and 
                            s=Sparse Root.  A sparse root zone
                            inherits the following directories
                            from the global zone: /lib, /usr, 
                            /sbin, and /platform. A whole root
                            zone does not inherit any directories
                            from the global zone. The default
                            value is sparse root (s).
$usage_I
         -D "<domain>"      DNS Domain Name.  If a domain is
                            specified, then dns name servers must
                            also be specified.  Note also that 
                            the fully qualified host name of the 
                            non-global zone must be resolvable by
                            the naming service. 


         -d "<ns1>,<ns2>,.."  
                            Ordered list of DNS Name Servers.  If
                            domain name servers are specified the
                            domain name must also be specified.
                            Note also that the fully qualified host 
                            name of the non-global zone must be 
                            resolvable by the naming service.
$usage_r
$usage_w
$usage_N
         -B "<name>|<subset>|<img>"
                            Make the zone into a Linux branded 
                            zone where <name> is the brand name, 
                            <subset>, is the brand subset, and 
                            <img> is the path and file name of 
                            the brand archive.  If a media drive
                            is being used, <img> is the path to
                            the mounted media.  e.g. 
                            /cdrom/cdrom0

         -R "<dir>|<shell>"
                            Custom home directory (<dir>) and 
                            a shell (<shell>) for the root user 
                            of the non-global zone.
$usage_C_add
$usage_C
$usage_s
         -S "<service>"     Restart specified service after 
                            adding zone.  A special case is 
                            'reboot' to restart all services in 
                            the zone.
$usage_M
$usage_X
$usage_G
         -L "<priv>[,<priv>,...]"
                            Specifies the limit set for privileges
                            allowed in this zone.  See manual page
                            privileges for more info and list of 
                            available privileges.


     del -n <zonename> [-F]
         The del action deletes an existing zone

         The "del" action supports the following optional option:

         -F                 Don't confirm an action; Just do it.

     modify -n <zonename> 
         The "modify" action enables you to add, modify and delete 
         select zone properties.  Zone properties that can be modified 
         include the following:

             Modify the zone name:
               -m "zonename:<value>"

             Modify the comment that describes the zone:
               -m "comment:<value>"

             Modify the autoboot value.  The autoboot property determines
             whether or not the zone will boot when the global zone is 
             booted.
               -m "autoboot:<true|false>"

             Modify the boot arguments of the zone:
               -m "bootargs:<value>"

             Modify an existing filesystem (fs) property:
               -m "fs:<dir>|<resource_type>:<value>"
                     Where net resource types include the following:
                        dir - Global zone directory
                        special - Non-global zone directory
                        options - Filesystem mount options

             Modify an existing network property:
               -m "net:<ipaddr/netmask>|<resource_type>:<value>"
                     Where net resource types include the following:
                        address - Network address and netmask in CIDR format
                        physical - The network interface

         Zone properties that can be deleted include the following:

             Modify an existing filesystem property:
               -m "del:fs:<dir_value>"

             Modify an existing network property:
               -m "del:net:<address/cidr_netmask>"

         In addition to modifying and deleting existing properties, 
         you can also add a few types of properties.  The arguments 
         used to add these properties are listed below.
$usage_I
$usage_r
$usage_w
$usage_w_modify
$usage_c
$usage_C
$usage_s
$usage_M
$usage_X
$usage_G
     list 
         The "list" action lists all current zones

     clone -n <zonename> -y <sourceZoneName> [clone_options]
         The "clone" action clones an existing zone into a
         new zone.  The new zone can be tailored via the
         optional arguments used when creating a new zone.

         The "clone" action supports the following required 
         options:

         The following clone_options are required:
$usage_P_E
$usage_z_Z
         The following optional clone_options are supported:

         -F                 Don't confirm an action; Just do it.

         -t <w or s>        Type of zone where w=Whole Root and 
                            s=Sparse [default: s]

         -d "<ns1>,<ns2>,.."  
                            Ordered list of DNS Name Servers

         -D "<domain>"      DNS Domain Name
$usage_A
$usage_w
$usage_N
$usage_p
     move -n <zonename> -Z <newzonepath> [-F]
         The "move" action moves an existing zone from its current
         directory to a new directory.

         The "move" action supports the following required 
         options:

         The following options are required:

         -Z "<dir>"         New directory for this zone.


     detach -n <zonename> [-F]
         The "detach" action detaches a zone so that it can be
         attached to a different server. 

         The "detach" action supports the following required 
         options:

         The following options are required:

         -F                 Don't confirm an action; Just do it.

     attach -n <zonename> [-F]
         The "attach" action attaches a detached zone.

         The "attach" action supports the following required 
         options:

         The following options are required:

         -F                 Don't confirm an action; Just do it.

     shutdown -n <zonename> [-F] 
         The "shutdown" action shuts down a zone.

         The "shutdown" action supports the following optional 
         option:

         -F                 Don't confirm an action; Just do it.

     boot -n <zonename>
         The "boot" action boots a zone.

         The "boot" action supports the following optional 
         option:

         -F                 Don't confirm an action; Just do it.

     reboot -n <zonename> [-F]
         The "reboot" action reboots a zone.

         The "reboot" action supports the following optional 
         option:

         -F                 Don't confirm an action; Just do it.

     halt -n <zonename> [-F]
         The "halt" action halts a zone.

         The "halt" action supports the following optional 
         option:

         -F                 Don't confirm an action; Just do it.

     only -n <zonename> [-F]
         The "only" action halts all non-global zones but those 
         specified by -n "<zonename> <zonename>" and boot any of 
         these specified zones that are not currently running.

         There are two zone name special cases.  
             bootall
                This zone name makes sure all non-global zones 
                are booted.

             haltall
                This zone name makes sure all zones are halted.

         The "only" action supports the following optional 
         option:

         -F                 Don't confirm an action; Just do it.

     runcmd -n <zonename> -X "<cmd_with_args>" [-F]
         The "runcmd" action runs commands specified with the
         -X "<cmd_with_args>" flags in all non-global zones 
         specified by -n "<zonename> <zonename>" flag.

         There is one zone name special case.  
             all
                This zone name runs the specified commands on
                all non-global zones.

         The following options are required:

         -n "<zone1> <zone2> ..."
                            Specify the name of the zones

         -X <command>       Runs <command> inside the non-global
                            command once it is successfully 
                            created.  Note that you may need to 
                            include the full path to the command
                            as well.

         The "runcmd" action supports the following optional 
         option:

         -F                 Don't confirm an action; Just do it.

     zcontainer -n <zonename> -p "<resource>|<resource_arg>"

         The "zcontainer" action transforms the zone into a container
         by applying resource controls to the zone.

         The following option is required:
$usage_p
         The "zcontainer" action supports the following optional 
         option:

         -F                 Don't confirm an action; Just do it.


EXAMPLES

     Example 1:  Create A Zone

     The following command will create a non-global zone named 
     m1.

         # zonemgr -a add -n m1 -z "/zones" -P "abc123" \\
             -I "192.168.0.10|hme0|24|myzonehost"


     Example 2:  Delete A Zone

     The following command will delete the non-global zone named
     m1 and it will not be prompted to continue because the 
     action is forced with the -F flag.

         # zonemgr -F -a del -n m1


     Example 3:  Create A Zone With Multiple IP Addresses

     The following command will create a non-global zone named 
     m1 with three IP addresses where each IP address is configured
     on its own network interface.

         # zonemgr -a add -n m1 -z "/zones" -P "abc123" \\
             -I "192.168.0.10|hme0|24|myzonehost1" \\
             -I "192.168.5.27|bge0|24|myzonehost2" \\
             -I "192.168.10.5|bge1|24|myzonehost3"


     Example 4: A Complex Example

     The following command will perform the details stated below.
         # zonemgr -a add -n m2 -t w -z "/zones" \\
             -P "abc123" -R /root \\
             -I "192.168.0.10|hme0|24|myzonehost" \\
             -r "/ds/build11/bits|/bits" \\
             -w "/zones/m2|/ds/m2" \\
             -s "basic|lock" -S ssh \\
             -C /etc/ssh/sshd_config -C /etc/resolv.conf \\
             -C /etc/nsswitch.conf \\
             -L "default,dtrace_proc,dtrace_user"

   1. Create a whole root zone named m2 in /zones/m2.
   2. Set the root password of that zone to abc123.
   3. Set the home directory of the root user of the non-global 
      zone to /root.
   4. Set the IP address of the zone to 192.168.0.10, the
      netmask to 255.255.255.0, assign it to interface hme0, and
      assign it a host name of myzonehost.
   5. Read only mount /ds/build11/bits from the global zone to 
      /bits in the non-global zone.
   6. Read write mount /zones/m2 from the global zone to /ds/m2 
      in the non-global zone.
   7. Disable all un-necessary services in the non-global zone
      and restart the ssh service once the lockdown is complete. 
   8. Copy the /etc/ssh/sshd_config, /etc/resolv.conf, and
      /etc/nsswitch.conf files from the global zone to the 
      non-global zone
   9. Add the dtrace_proc and dtrace_user privileges to the
      non-global zone


     Example 5:  List All Zones

     The following command will list all available zones.

         # zonemgr -a list


     Example 6:  Reboot A Zone

     The following command will reboot non-global zone m1.

         # zonemgr -a reboot -n m1


     Example 7: Disable Un-necessary Services

     The following command will disable all un-necessary services
     of non-global zone m1.

         # zonemgr -a modify -n m1 -s "basic|lock" 


     Example 8: Enable Un-necessary Services

     The following command will enable all un-necessary services
     of non-global zone m1.

         # zonemgr -a modify -n m1 -s "basic|unlock" 


     Example 9: Manage State Of Multiple Zones

     The following command will halt all non-global zones but 
     those specified by the -n parameter and will boot any of the
     specified zones that are not currently running.

         # zonemgr -a only -n "m1 m2"


     Example 10: Halt All Zones

     The following command will halt all non-global zones.

         # zonemgr -a only -n "haltall"


     Example 11: Boot All Zones

     The following command will boot all non-global zones.

         # zonemgr -a only -n "bootall"


     Example 12: Creating A BrandZ (e.g. Linux) Zone

     The following command will add a BrandZ zone
         # zonemgr -a add -n m1 -z "/zones" -P "abc123" \\
             -I "192.168.0.10|hme0|24|myzonehost" \\
             -B "SUNWlx|all|/data/brandz/centos_fs_image.tar" 

     The parameters passed to -B break down as follows:
         * SUNWlx: The zone brand (only lx is currently supported)

         * all: The brand subset to install. Valid values include 
           desktop, applications, server, development, system, 
           and all. I don't yet have an idea as to how this 
           option will impact other distributions that folks come
           up with. These options may or may not be valid. TBD.

         * /data/brandz/centos_fs_image.tar: The path to the 
           brand bits. I simply pointed them to the BrandZ 
           community's CentOS image.


     Example 13: Create A Zone AND Install MySQL5 From BlastWave

     The following command will add a zone named m1, download and
     install mysql5 and all requisite bits from Blastwave.org, 
     and install all those bits in the proper order in the m1 
     zone. 
         # zonemgr -a add -n m1 -z "/zones" -P "abc123" \\
             -I "192.168.0.10|hme0|24|myzonehost" -G "mysql5"

     Example 14: Add a ZFS filesystem to an existing zone

     The following command will create a legacy mode ZFS 
     filesystem from the myzfspool pool, set the ZFS mount 
     point to /zfsdata, and mount that filesystem exclusively
     within the m1 zone.
         # zonemgr -a modify -n m1 -w "zfs|/zfsdata|myzfspool"

     Example 15: Move a zone

     The following command will move a zone to a new directory.
         # zonemgr -a move -n m1 -Z /zones/newm1 

     Example 16: Detach and attach a zone

     The following two commands will detach a zone and then
     re-attach it.
         # zonemgr -a detach -n m1 -F
         # zonemgr -a attach -n m1 -F

     Example 17: Clone a zone

     The following command will move a zone to a new directory.
         # zonemgr -a clone -n m1 -y m1clone -Z /zones/m1clone \\
            -P "pw"

     Example 18: Apply CPU containment to a zone

     The following command will put a zone into a CPU processor 
     set that will limit all process of the zone to running on
     the specified number of CPUs.
         # zonemgr -a zcontainer -n m1 -p "cpu|1"

NOTES
     Note that most parameters are multivalued.  In other words,
     you can specify the same parameter multiple times.  For 
     example, to mount the /data1 and /data2 directories in read 
     only mode from the global zone to the non-global zone, add 
     the following to the add action:
       -r "/data1" -r "/data2"


EXIT STATUS
     The following exit values are returned:

     0        Successful completion.

     1        An error occurred.

     2        Invalid usage.


SEE ALSO
     svcs(1), zlogin(1), zonename(1), svcadm(1M),  svc.startd(1M)
     and  init(1M),  svc.startd(1M),  zoneadm(1M), zonecfg(1M), 
     attributes(5), smf(5), zones(5)

EOF

   if [ -n "$errmsg" ]; then echo "$errrmsg";fi

   exit 2
}

##############################################################################
#
# Show the GPL v2 license
#
showlicense() {
   findpager



cat <<EOF | $pgcmd
Copyright 2006 Sun Microsystems, Inc. All rights reserved.

U.S. Government Rights - Commercial software. Government users are subject 
to the Sun Microsystems, Inc. standard license agreement and applicable 
provisions of the FAR and its supplements.

Use is subject to license terms. Sun, Sun Microsystems, the Sun logo and 
Solaris are trademarks or registered trademarks of Sun Microsystems, Inc. 
in the U.S. and other countries.

The license used for this script is as follows.


		    GNU GENERAL PUBLIC LICENSE
		       Version 2, June 1991

 Copyright (C) 1989, 1991 Free Software Foundation, Inc.,
 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA
 Everyone is permitted to copy and distribute verbatim copies
 of this license document, but changing it is not allowed.

			    Preamble

  The licenses for most software are designed to take away your
freedom to share and change it.  By contrast, the GNU General Public
License is intended to guarantee your freedom to share and change free
software--to make sure the software is free for all its users.  This
General Public License applies to most of the Free Software
Foundation's software and to any other program whose authors commit to
using it.  (Some other Free Software Foundation software is covered by
the GNU Lesser General Public License instead.)  You can apply it to
your programs, too.

  When we speak of free software, we are referring to freedom, not
price.  Our General Public Licenses are designed to make sure that you
have the freedom to distribute copies of free software (and charge for
this service if you wish), that you receive source code or can get it
if you want it, that you can change the software or use pieces of it
in new free programs; and that you know you can do these things.

  To protect your rights, we need to make restrictions that forbid
anyone to deny you these rights or to ask you to surrender the rights.
These restrictions translate to certain responsibilities for you if you
distribute copies of the software, or if you modify it.

  For example, if you distribute copies of such a program, whether
gratis or for a fee, you must give the recipients all the rights that
you have.  You must make sure that they, too, receive or can get the
source code.  And you must show them these terms so they know their
rights.

  We protect your rights with two steps: (1) copyright the software, and
(2) offer you this license which gives you legal permission to copy,
distribute and/or modify the software.

  Also, for each author's protection and ours, we want to make certain
that everyone understands that there is no warranty for this free
software.  If the software is modified by someone else and passed on, we
want its recipients to know that what they have is not the original, so
that any problems introduced by others will not reflect on the original
authors' reputations.

  Finally, any free program is threatened constantly by software
patents.  We wish to avoid the danger that redistributors of a free
program will individually obtain patent licenses, in effect making the
program proprietary.  To prevent this, we have made it clear that any
patent must be licensed for everyone's free use or not licensed at all.

  The precise terms and conditions for copying, distribution and
modification follow.

		    GNU GENERAL PUBLIC LICENSE
   TERMS AND CONDITIONS FOR COPYING, DISTRIBUTION AND MODIFICATION

  0. This License applies to any program or other work which contains
a notice placed by the copyright holder saying it may be distributed
under the terms of this General Public License.  The "Program", below,
refers to any such program or work, and a "work based on the Program"
means either the Program or any derivative work under copyright law:
that is to say, a work containing the Program or a portion of it,
either verbatim or with modifications and/or translated into another
language.  (Hereinafter, translation is included without limitation in
the term "modification".)  Each licensee is addressed as "you".

Activities other than copying, distribution and modification are not
covered by this License; they are outside its scope.  The act of
running the Program is not restricted, and the output from the Program
is covered only if its contents constitute a work based on the
Program (independent of having been made by running the Program).
Whether that is true depends on what the Program does.

  1. You may copy and distribute verbatim copies of the Program's
source code as you receive it, in any medium, provided that you
conspicuously and appropriately publish on each copy an appropriate
copyright notice and disclaimer of warranty; keep intact all the
notices that refer to this License and to the absence of any warranty;
and give any other recipients of the Program a copy of this License
along with the Program.

You may charge a fee for the physical act of transferring a copy, and
you may at your option offer warranty protection in exchange for a fee.

  2. You may modify your copy or copies of the Program or any portion
of it, thus forming a work based on the Program, and copy and
distribute such modifications or work under the terms of Section 1
above, provided that you also meet all of these conditions:

    a) You must cause the modified files to carry prominent notices
    stating that you changed the files and the date of any change.

    b) You must cause any work that you distribute or publish, that in
    whole or in part contains or is derived from the Program or any
    part thereof, to be licensed as a whole at no charge to all third
    parties under the terms of this License.

    c) If the modified program normally reads commands interactively
    when run, you must cause it, when started running for such
    interactive use in the most ordinary way, to print or display an
    announcement including an appropriate copyright notice and a
    notice that there is no warranty (or else, saying that you provide
    a warranty) and that users may redistribute the program under
    these conditions, and telling the user how to view a copy of this
    License.  (Exception: if the Program itself is interactive but
    does not normally print such an announcement, your work based on
    the Program is not required to print an announcement.)

These requirements apply to the modified work as a whole.  If
identifiable sections of that work are not derived from the Program,
and can be reasonably considered independent and separate works in
themselves, then this License, and its terms, do not apply to those
sections when you distribute them as separate works.  But when you
distribute the same sections as part of a whole which is a work based
on the Program, the distribution of the whole must be on the terms of
this License, whose permissions for other licensees extend to the
entire whole, and thus to each and every part regardless of who wrote it.

Thus, it is not the intent of this section to claim rights or contest
your rights to work written entirely by you; rather, the intent is to
exercise the right to control the distribution of derivative or
collective works based on the Program.

In addition, mere aggregation of another work not based on the Program
with the Program (or with a work based on the Program) on a volume of
a storage or distribution medium does not bring the other work under
the scope of this License.

  3. You may copy and distribute the Program (or a work based on it,
under Section 2) in object code or executable form under the terms of
Sections 1 and 2 above provided that you also do one of the following:

    a) Accompany it with the complete corresponding machine-readable
    source code, which must be distributed under the terms of Sections
    1 and 2 above on a medium customarily used for software interchange; or,

    b) Accompany it with a written offer, valid for at least three
    years, to give any third party, for a charge no more than your
    cost of physically performing source distribution, a complete
    machine-readable copy of the corresponding source code, to be
    distributed under the terms of Sections 1 and 2 above on a medium
    customarily used for software interchange; or,

    c) Accompany it with the information you received as to the offer
    to distribute corresponding source code.  (This alternative is
    allowed only for noncommercial distribution and only if you
    received the program in object code or executable form with such
    an offer, in accord with Subsection b above.)

The source code for a work means the preferred form of the work for
making modifications to it.  For an executable work, complete source
code means all the source code for all modules it contains, plus any
associated interface definition files, plus the scripts used to
control compilation and installation of the executable.  However, as a
special exception, the source code distributed need not include
anything that is normally distributed (in either source or binary
form) with the major components (compiler, kernel, and so on) of the
operating system on which the executable runs, unless that component
itself accompanies the executable.

If distribution of executable or object code is made by offering
access to copy from a designated place, then offering equivalent
access to copy the source code from the same place counts as
distribution of the source code, even though third parties are not
compelled to copy the source along with the object code.

  4. You may not copy, modify, sublicense, or distribute the Program
except as expressly provided under this License.  Any attempt
otherwise to copy, modify, sublicense or distribute the Program is
void, and will automatically terminate your rights under this License.
However, parties who have received copies, or rights, from you under
this License will not have their licenses terminated so long as such
parties remain in full compliance.

  5. You are not required to accept this License, since you have not
signed it.  However, nothing else grants you permission to modify or
distribute the Program or its derivative works.  These actions are
prohibited by law if you do not accept this License.  Therefore, by
modifying or distributing the Program (or any work based on the
Program), you indicate your acceptance of this License to do so, and
all its terms and conditions for copying, distributing or modifying
the Program or works based on it.

  6. Each time you redistribute the Program (or any work based on the
Program), the recipient automatically receives a license from the
original licensor to copy, distribute or modify the Program subject to
these terms and conditions.  You may not impose any further
restrictions on the recipients' exercise of the rights granted herein.
You are not responsible for enforcing compliance by third parties to
this License.

  7. If, as a consequence of a court judgment or allegation of patent
infringement or for any other reason (not limited to patent issues),
conditions are imposed on you (whether by court order, agreement or
otherwise) that contradict the conditions of this License, they do not
excuse you from the conditions of this License.  If you cannot
distribute so as to satisfy simultaneously your obligations under this
License and any other pertinent obligations, then as a consequence you
may not distribute the Program at all.  For example, if a patent
license would not permit royalty-free redistribution of the Program by
all those who receive copies directly or indirectly through you, then
the only way you could satisfy both it and this License would be to
refrain entirely from distribution of the Program.

If any portion of this section is held invalid or unenforceable under
any particular circumstance, the balance of the section is intended to
apply and the section as a whole is intended to apply in other
circumstances.

It is not the purpose of this section to induce you to infringe any
patents or other property right claims or to contest validity of any
such claims; this section has the sole purpose of protecting the
integrity of the free software distribution system, which is
implemented by public license practices.  Many people have made
generous contributions to the wide range of software distributed
through that system in reliance on consistent application of that
system; it is up to the author/donor to decide if he or she is willing
to distribute software through any other system and a licensee cannot
impose that choice.

This section is intended to make thoroughly clear what is believed to
be a consequence of the rest of this License.

  8. If the distribution and/or use of the Program is restricted in
certain countries either by patents or by copyrighted interfaces, the
original copyright holder who places the Program under this License
may add an explicit geographical distribution limitation excluding
those countries, so that distribution is permitted only in or among
countries not thus excluded.  In such case, this License incorporates
the limitation as if written in the body of this License.

  9. The Free Software Foundation may publish revised and/or new versions
of the General Public License from time to time.  Such new versions will
be similar in spirit to the present version, but may differ in detail to
address new problems or concerns.

Each version is given a distinguishing version number.  If the Program
specifies a version number of this License which applies to it and "any
later version", you have the option of following the terms and conditions
either of that version or of any later version published by the Free
Software Foundation.  If the Program does not specify a version number of
this License, you may choose any version ever published by the Free Software
Foundation.

  10. If you wish to incorporate parts of the Program into other free
programs whose distribution conditions are different, write to the author
to ask for permission.  For software which is copyrighted by the Free
Software Foundation, write to the Free Software Foundation; we sometimes
make exceptions for this.  Our decision will be guided by the two goals
of preserving the free status of all derivatives of our free software and
of promoting the sharing and reuse of software generally.

			    NO WARRANTY

  11. BECAUSE THE PROGRAM IS LICENSED FREE OF CHARGE, THERE IS NO WARRANTY
FOR THE PROGRAM, TO THE EXTENT PERMITTED BY APPLICABLE LAW.  EXCEPT WHEN
OTHERWISE STATED IN WRITING THE COPYRIGHT HOLDERS AND/OR OTHER PARTIES
PROVIDE THE PROGRAM "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER EXPRESSED
OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF
MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE.  THE ENTIRE RISK AS
TO THE QUALITY AND PERFORMANCE OF THE PROGRAM IS WITH YOU.  SHOULD THE
PROGRAM PROVE DEFECTIVE, YOU ASSUME THE COST OF ALL NECESSARY SERVICING,
REPAIR OR CORRECTION.

  12. IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING
WILL ANY COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MAY MODIFY AND/OR
REDISTRIBUTE THE PROGRAM AS PERMITTED ABOVE, BE LIABLE TO YOU FOR DAMAGES,
INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL OR CONSEQUENTIAL DAMAGES ARISING
OUT OF THE USE OR INABILITY TO USE THE PROGRAM (INCLUDING BUT NOT LIMITED
TO LOSS OF DATA OR DATA BEING RENDERED INACCURATE OR LOSSES SUSTAINED BY
YOU OR THIRD PARTIES OR A FAILURE OF THE PROGRAM TO OPERATE WITH ANY OTHER
PROGRAMS), EVEN IF SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE
POSSIBILITY OF SUCH DAMAGES.

		     END OF TERMS AND CONDITIONS

	    How to Apply These Terms to Your New Programs

  If you develop a new program, and you want it to be of the greatest
possible use to the public, the best way to achieve this is to make it
free software which everyone can redistribute and change under these terms.

  To do so, attach the following notices to the program.  It is safest
to attach them to the start of each source file to most effectively
convey the exclusion of warranty; and each file should have at least
the "copyright" line and a pointer to where the full notice is found.

    <one line to give the program's name and a brief idea of what it does.>
    Copyright (C) <year>  <name of author>

    This program is free software; you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation; either version 2 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License along
    with this program; if not, write to the Free Software Foundation, Inc.,
    51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA.

Also add information on how to contact you by electronic and paper mail.

If the program is interactive, make it output a short notice like this
when it starts in an interactive mode:

    Gnomovision version 69, Copyright (C) year name of author
    Gnomovision comes with ABSOLUTELY NO WARRANTY; for details type 'show w'.
    This is free software, and you are welcome to redistribute it
    under certain conditions; type 'show c' for details.

The hypothetical commands 'show w' and 'show c' should show the appropriate
parts of the General Public License.  Of course, the commands you use may
be called something other than 'show w' and 'show c'; they could even be
mouse-clicks or menu items--whatever suits your program.

You should also get your employer (if you work as a programmer) or your
school, if any, to sign a "copyright disclaimer" for the program, if
necessary.  Here is a sample; alter the names:

  Yoyodyne, Inc., hereby disclaims all copyright interest in the program
  'nomovision' (which makes passes at compilers) written by James Hacker.

  <signature of Ty Coon>, 1 April 1989
  Ty Coon, President of Vice

This General Public License does not permit incorporating your program into
proprietary programs.  If your program is a subroutine library, you may
consider it more useful to permit linking proprietary applications with the
library.  If this is what you want to do, use the GNU Lesser General
Public License instead of this License.

EOF

   exit 0
}

##############################################################################
#
# Function to seek assurance
#
are_you_sure() {
   faction="$1"
   if [ "$forceaction" = 'false' ]
   then
      echo -e "Are you sure that you want to \"$faction\"? [no] \c"
      read ck4response
      ck4response=`echo $ck4response | sed -e "y/ABCDEFGHIJKLMNOPQRSTUVWXYZ/abcdefghijklmnopqrstuvwxyz/"`
      if [ "$ck4response" != 'yes' ]
      then
         error_message "You chose not to perform action \"$faction\"."
      fi
   else
      echo "The \"$faction\" action was forced on zone \"$zonename\" with the -F parameter."
   fi
}

##############################################################################
#
# Function to recursively copy specified files/directories from the global 
# zone into the non-global zone
#
copy_files() {
   myfiles=( $@ )

   if [ ${#myfiles[*]} -gt 0 ]
   then
   
      #
      # Handle the case when we are modifying a zone as opposed
      # to adding a new one.
      #
      if [ -z "$zonedir" ]
      then
         zonedir=`zonecfg -z "$zonename" info zonepath 2> /dev/null | awk '{ print $2 }'`
      fi

      i=0
      while [[ $i -lt ${#myfiles[*]} ]]
      do
         ck4destination=`echo ${myfiles[$i]} | tr -cd '|'`
         if [ -z "$ck4destination" ]
         then
            srccpdir="${myfiles[$i]}"
            dstcpdir="${myfiles[$i]}"
         elif [ "$ck4destination"  = '|' ]
         then
            srccpdir=`echo ${myfiles[$i]} | cut -d'|' -f1`
            dstcpdir=`echo ${myfiles[$i]} | cut -d'|' -f2`
         else 
            error_message "The proper format for the -C flag is -C \"<dir>\" or -C \"<source_dir>|<destination_dir>\""
         fi 

         echo "Copying ($srccpdir) from the global zone to ($dstcpdir) in the non-global zone."

         if [ -e "$srccpdir" ] || [ -h "$srccpdir" ]
         then
            dfile=`basename $dstcpdir`
            ddir=`dirname $dstcpdir`
            if [ -d "$zonedir/root/$ddir" ]
            then
               true
            else
               mkdir -p "$zonedir/root/$ddir"
            fi
            bfile=`basename $srccpdir`
            bdir=`dirname $srccpdir`
            cd "$bdir"
            tar cf - "$bfile" | (cd "$zonedir/root/$ddir"; tar xf -)
            if [ -n "$dfile" ] && [ "$bfile" != "$dfile" ]
            then
               cd $zonedir/root/$ddir
               mv "$bfile" "$dfile"
            fi
         else
            echo "File \"$srccpdir\" does not exist."
         fi
         i=$(($i+1))
      done
      echo "Copy completed."
   fi
}

##############################################################################
#
# Add a ro, rw, or zfs filesystem to the zone
#
add_fs() {
      #
      # Make sure the rodirs[$ronum] and rwdirs[$rwnum] exist and construct 
      # readonly directories to insert into the zone config
      #
      for (( i=0; i< ${#rodirs[*]}; i++ ))
      do
         if [ -n "${rodirs[$i]}" ]
         then
            globaldir=`echo ${rodirs[$i]} | cut -d'|' -f1`
            nonglobaldir=`echo ${rodirs[$i]} | cut -d'|' -f2`
            if [ -e "${globaldir}" ]
            then
               true
            else
               are_you_sure "create ($globaldir) in the global zone because it doesn not currently exist"
               mkdir -p "$globaldir" 
            fi

            # If no nonglobaldir specified, use the globaldir
            if [ -z "$nonglobaldir" ]
            then
               nonglobaldir="$globaldir"
            fi
            zcfg="$zcfg
add fs
set dir=$nonglobaldir
set special=$globaldir
set type=lofs
add options [ro,nodevices]
end"
         fi
      done

      #
      # Construct readwrite directories to insert into the zone config
      #
      for (( i=0; i< ${#rwdirs[*]}; i++ ))
      do
         if [ -n "${rwdirs[$i]}" ]
         then
            globaldir=`echo ${rwdirs[$i]} | cut -d'|' -f1`
            nonglobaldir=`echo ${rwdirs[$i]} | cut -d'|' -f2`
            #
            # Make sure the directory in the global zone exists.
            #
            if [ -e "$globaldir" ]
            then
               true
            else
               if [ "$globaldir" == 'zfs' ]
               then
                  true
               else
                  are_you_sure "create ($globaldir) in the global zone because it doesn not currently exist"
                  mkdir -p "$globaldir"
               fi
            fi

            # Check for zfs config 
            zfspool=`echo ${rwdirs[$i]} | cut -d'|' -f3`
            zfsname=`echo ${rwdirs[$i]} | cut -d'|' -f4`
            if [ -z "$zfsname" ]
            then
               zfsname=`basename $nonglobaldir`
            fi

            # If no nonglobaldir specified, use the globaldir
            if [ -z "$nonglobaldir" ]
            then
               nonglobaldir="$globaldir"
            fi

            #
            # Make sure zfs packages are installed
            #
            if [ "$globaldir" == 'zfs' ]
            then
               echo "Checking to make sure zfs is installed."
               ckpkgver SUNWzfsr SUNWzfsu SUNWzfskr
            fi

            if [ "$globaldir" == 'zfs' ] && [ "$action" == 'add' ]
            then
               info_error_message "This version of zones does not support adding a zfs filesystem during \nzone creation.  To add the requested zfs filesystem, run the following zonemgr \ncommand:\n  zonemgr -a modify -n $zonename -w \"zfs|$nonglobaldir|$zfspool\" -F\nThe bug number for this defect is 6449301."
            elif [ "$globaldir" == 'zfs' ]
            then
               if [ -n "$zfspool" ] 
               then
                  #
                  # Add test to make sure zfspool exists
                  #
                  ck4pool=`zpool list $zfspool > /dev/null 2>&1;echo $?`
                  if [ $ck4pool -eq 0 ]
                  then
                     zfs create $zfspool/$zfsname
                     zfs set mountpoint=legacy $zfspool/$zfsname
                     zfs set zoned=on $zfspool/$zfsname

                     zcfg="$zcfg
add fs
set dir=$nonglobaldir
set special=$zfspool/$zfsname
set type=zfs
end"

                  else
                     error_message "The zfs pool \"$zfspool\" does not exist."
                  fi
               else
                  error_message "You must specify a zfs pool."
               fi
            else
               zcfg="$zcfg
add fs
set dir=$nonglobaldir
set special=$globaldir
set type=lofs
add options [rw,nodevices]
end"
            fi
         fi
      done
}

##############################################################################
#
# Function for setting autoboot setting
#
set_autoboot() {
   if [ -n "$1" ]
   then
      aset="$1"
      zattrcfg="$zattrcfg
set autoboot=$aset"
   else
      error_message "Invalid value for autoboot. Valid options are true or false."
   fi
}

##############################################################################
#
# Function for setting zone privilege limits
#
limit_privs() {
   if [ -n "$zone_privileges" ]; then
     zattrcfg="$zattrcfg
set limitpriv=\"$zone_privileges\"";
   fi
}

##############################################################################
#
# If networking info has been specified, add it to the zone configuration
#
add_net_addr() {
   i=0
   while [ $i -lt $n ]
   do
      if [ -n "${zoneip[$i]}" ]
      then
         zcfg="$zcfg
add net
set address=${zoneip[$i]}/${zonecidrnm[$i]}
set physical=${zoneif[$i]}
end"
      fi
      i=$(($i+1))
   done
}

##############################################################################
#
# Commit the zone config changes to the zone config file
#
commit_zcfg() {
   if [ "$action" == 'add' ] || [ "$action" == 'clone' ]
   then
      zcfg="create $addminimize $addbrandcfg
set zonepath=$zonedir$zattrcfg
add attr
set name=comment
set type=string
set value=\"Zone $zonename\"
end$zcfg"
   elif [ "$action" == 'modify' ] 
   then
      if [ -n "$zattrcfg" ]
      then
         zcfg="$zattrcfg
$zcfg"
      elif [ -n "$zcfg" ]
      then
         true
      else
         error_message "No zone configuration specified."
      fi
   fi

   #
   # Specify end, verify and commit commands
   #
   zcfg="$zcfg
verify
commit
"
   echo "$zcfg" >> "$zonefile"
   zonecfg -z "$zonename" -f "$zonefile"
   if [ $? -ne 0 ] 
   then
      error_message "Error configuring $zonename, return value: $?"
   fi
}

##############################################################################
#
# Function for deleting a zone
#
delete_zone() {
   zonename="$1"
   # Validate assurance
   are_you_sure "Delete Zone $zonename"
   
   if [ -z "$zonename" ]
   then
      error_message "Must specify a zone name with the -n <name> flag"
   else
      #
      # Get necessary info to intelligently know what to clean up
      #
      zonepath=`zonecfg -z "$zonename" info zonepath 2> /dev/null | awk '{ print $2 }'`
      zonedirs=`zonecfg -z "$zonename" info fs 2> /dev/null | grep "special" | awk '{ print $2 }'`

      #
      # delete pool $zonename-pool 
      #
      ck4zpool=`poolcfg -dc info 2> /dev/null | grep "$zonename-pool"`
      if [ -n "$ck4zpool" ]
      then
         poolcfg -dc "destroy pool $zonename-pool" 2> /dev/null
      fi

      #
      # Delete processor set $zonename-pset 
      #
      ck4zpset=`poolcfg -dc info 2> /dev/null | grep "$zonename-pset"`
      if [ -n "$ck4zpset" ]
      then
         poolcfg -dc "destroy pset $zonename-pset" 2> /dev/null
      fi

      #
      # Make sure the active configuration has been saved
      #
      pooladm -s 2> /dev/null
     
      #
      # Instantiate (ie., activate) the configuration from /etc/pooladm.conf in to memory 
      #
      pooladm -c 2> /dev/null

      #
      # Make sure that the zone exists before trying to remove it.
      #
      ck4zone=`zoneadm -z "$zonename" list -v 2> /dev/null | grep "$zonename" | awk '{ print $3 }'`
      if [ -n "$ck4zone" ]
      then
         #
         # Ensure that the zone is shutdown
         #
         if [ "$ck4zone" = 'running' ]
         then
            zoneadm -z "$zonename" halt
         fi
         #
         # Uninstall and delete the zone
         #
         zoneadm -z $zonename uninstall -F
         zonecfg -z $zonename delete -F

         #
         # Try to remove the directories if they are empty
         #
         for dir in $zonedirs $zonepath
         do
            rmdir "$dir" > /dev/null 2>&1
         done

         #
         # Provide info on what may need to be cleaned up
         #
         echo "With the exception of the root users's home directory, this script does"
         echo "not remove any zone data.  There may be contents within the following"
         echo "directories that you may want to manually remove."
         echo "Zone path: $zonepath"
         echo "Globally mounted zone directories:"
         echo "$zonedirs"
      else
         echo "Error: Zone \"$zonename\" does not exist."
         exit 1
      fi
   fi
}

##############################################################################
#
# Function for adding a zone
#
add_zone() {
   zonename="$1"

   #
   # See if the zone already exists
   #
   ck4zone=`zoneadm -z "$zonename" list 2> /dev/null`
   if [ -n "$ck4zone" ] 
   then
      error_message "The specified zone name ($zonename) is already in use.";
   fi

   #
   # Make sure that the zone type specified is valid
   #
   if [ "$zonetype" != 's' ] && [ "$zonetype" != 'w' ]
   then
      error_message "Must specify a valid zone type [w=whole root or s=sparse root]";
   fi

   #
   # Verify that minimization is an option before attempting to create the zone
   #
   if [ "$zoneminimize" = 'yes' ]
   then
      if [ "$zonetype" != 'w' ]
      then 
         error_message "The zone type must be set to 'whole' in order to minimize the zone!";
      fi
   fi

   #
   # Set autoboot
   #
   set_autoboot "$autoboot"

   #
   # If networking info has been specified, add it to the zone configuration
   #
   add_net_addr

   #
   # Ensure that the root password is specified
   #
   if [ -z "$encrootpw" ];
   then 
      error_message "Must specify either encrypted (-E) or non-encrypted (-P) password and the password cannot be null (e.g. \"\")";
   fi

   #
   # Make sure there is a valid zonedir
   #
   if [ -n "$zonedir" ] && [  -n "$zonepath" ]
   then 
      bzonepath=`dirname $zonedir`
      if [ "$bzonepath"  != "$zonepath" ]
      then 
         error_message "If the zone path (-z <dir>) and the base of the zone directory (-Z <dir>) \nare specified, then the zone path:\n   $zonepath\nand the base directory of the zone directory:\n   $bzonepath\nmust match."
      fi 
   elif [ -z "$zonedir" ]
   then 
      if [ -z "$zonepath" ]
      then 
         error_message "Must provide either a zone directory with -Z <dir> or a zone path with -z <dir>."
      else 
         zonedir="$zonepath/$zonename"
      fi 
   else 
      if [ -z "$zonepath" ]
      then 
         zonepath=`dirname $zonedir`
      fi 
   fi 

   #
   # Make sure there is no trailing / at the end of the directory
   #
   zonedir=`echo $zonedir | sed -e "s/\/$//g"`
   zonepath=`echo $zonepath | sed -e "s/\/$//g"`

   if [ -n "$zonedir" ] 
   then
      #
      # Make sure the zone path exists
      #
      mkdir -p "$zonepath" 2> /dev/null

      #
      # Make sure that the zone path is valid
      #
      if [ -d "$zonedir/dev" ] || [ -d "$zonedir/root" ] || [ -f "$zonedir" ]
      then
         error_message "The zone directory ($zonedir) is already in use.  \nPlease select a zone directory that is not in use by another zone or remove the existing directory."
      elif [ -d "$zonedir" ] 
      then
         # Make sure that the permissions of the directory 
         # comply with zoneadm requirements
         chmod o-rwx,g-rwx "$zonedir"
         chown root "$zonedir"
      fi
   fi

   #
   # Ensure that zone name is specified
   #
   if [ -z "$zonename" ]
   then
      error_message "Must specify a zone name"
   else
      #
      # Create the zone config file
      #
      if [ "$zonetype" = 'w' ] && [ -z "$brandname" ] && [ "$zoneminimize" != 'yes' ];
      then
         zattrcfg="$zattrcfg
remove inherit-pkg-dir dir=/lib 
remove inherit-pkg-dir dir=/usr 
remove inherit-pkg-dir dir=/sbin 
remove inherit-pkg-dir dir=/platform"
      fi

      #
      # Add ro, rw, and zfs filesystems
      #
      add_fs

      #
      # Limit zone privileges
      #
      limit_privs

      #
      # If branding is specified set up the brand args for zone creation
      #
      addbrandcfg=''
      addbrandinstall=''
      if [ -n "$brandname" ];
      then 
         if [ "$zoneminimize" == 'yes' ] || [ -n "$nameservers" ] || [ -n "$domains" ] ||
            [ $snum != 0 ] || [ -n "$domainname" ] || [ -n "$hardening_mode" ]
         then
            error_message "Invalid option supplied with brand zone. Options -t, -M, -d, -D, and -s are not supported"
         fi
         addbrandcfg=" -t $brandname"
         addbrandinstall=" -d "$brandsrcpath" $brandsubset"
      fi

      #
      # If minimization is requested, enable it at zone creation
      #
      addminimize=''
      if [ "$zoneminimize" == 'yes' ];
      then 
         addminimize=" -b "
      fi

      #
      # Generate a sysidcfg file
      #
      adddomain=''
      nameservice='NONE'
      if [ -n "$domainname" ] || [ -n "$domains" ]
      then
         adddomain="domain_name=$domainname "
         if [ -n "$domains" ]
         then
            nameservice="DNS {$adddomain name_server=$domains}"
         else
            error_message "When specifying DNS information, must specify both a domain name and name server."
         fi
      fi

      # 
      # Validate that the zone will be able to communicate with the DNS server. 
      # 
      if [ "$nameservice" != 'NONE' ]
      then
         ns=`echo $domains | awk '{ print $1 }'`
         ckresolv=`nslookup ${zoneipname[0]}.$domainname $ns | grep Address | tail -1 | awk '{ print $2 }'`
         if [ "$ckresolv" !=  "${zoneip[0]}" ]
         then
            error_message "The specified domain name (${zoneipname[0]}.$domainname) does not resolve to the specified IP address (${zoneip[0]})."
         fi
      fi

      # 
      # Deal with possible DNS re-configure  
      # 
      rtr=`netstat -rn | grep default | awk '{ print $2 }' | cut -d'.' -f1-3`
      ipnet=`echo ${zoneip[0]} | cut -d'.' -f1-3`
      if [ -n "$domainname" ] && [ "$rtr" != "$ipnet" ] 
      then
         info_error_message "The default route doesn't match the subnet of the zone IP address.\nThis may cause the zone to hang on reboot if the zone cannot connect to the \nDNS server.  To resolve this you may need to login to the console with \n\"zlogin -C $zonename\" and complete the DNS configuration in the console."
      fi

      #
      # Commit the zone configuration 
      #
      commit_zcfg

      if [ "$action" == 'add' ]
      then
         zoneadm -z "$zonename" install $addbrandinstall
         if [ $? -ne 0 ] 
         then
            error_message "Zone installation failed, return value: $?"
         fi
      elif [ "$action" == 'clone' ]
      then
         #prevstate=`zoneadm -z "$srczonename" list -p | cut -d: -f3`
         if [ "$prevstate" == 'running' ]
         then
            zoneadm -z "$srczonename" halt
         fi
         sleep 2
         zoneadm -z "$zonename" clone "$srczonename"
         if [ $? -ne 0 ] 
         then
            error_message "Zone clone failed, return value: $?"
         fi
         if [ "$prevstate" == 'running' ]
         then
            zoneadm -z "$srczonename" boot
         fi
      fi

      echo "Creating the sysidcfg file for automated zone configuration."

      netif="NONE { hostname=$zonename }"
      if [ -n "${zoneip[0]}" ]
      then
         netif="PRIMARY { hostname=${zoneipname[0]} ip_address=${zoneip[0]} protocol_ipv6=no }"
      fi

      if [ -z "$TZ" ]
      then
         TZ="US/Central"
      fi

      if [ -n "$domainname" ]
      then
         nfs4domain="$domainname"
      else
         nfs4domain="domain"
      fi

      #
      # If a sysidcfg compatible hardening mode has been specified
      # implement that mode here.
      #
      svcprofile=''
      ck4netsvcs=`which netservices 2>&1 | grep -v "no less"`
      if [ "$hardening_mode" = 'netservices' ] && [ -n "$ck4netsvcs" ]
      then
         case $hardening_args in
           'limited') svcprofile="
service_profile = $hardening_args";;
                  'open') svcprofile="
service_profile = $hardening_args";;
         esac
      fi

      cat >> "$zonedir/root/etc/sysidcfg" <<EOF
system_locale=C
terminal=xterm
network_interface=$netif
security_policy=NONE
name_service=$nameservice
timezone=$TZ
root_password=$encrootpw
nfs4_domain=$nfs4domain$svcprofile
EOF

      cp "$zonedir/root/etc/sysidcfg" "$zonetmpdir/sysidcfg-$zonename"

      #
      # Generate a NFS install state file so as to avoid being
      # prompted for NFS on boot.
      #
      touch "$zonedir/root/etc/.NFS4inst_state.domain"

      #
      # Recursively copy specified files/directories from global into the 
      # non-global zone
      #
      if [ -n "${pre_files[0]}" ]
      then
         copy_files "${pre_files[@]}"
      fi

      #
      # Boot the zone for the first time
      #
      echo "Booting zone for the first time."
      zoneadm -z "$zonename" boot

      #
      # Wait for manifest-import [dsscfg] to complete before attempting
      # to disable services.  
      #
      echo "Waiting for first boot tasks to complete."
      ck4startd='sysidcfg'
      while [ -n "$ck4startd" ]
      do
         sleep 3
         ck4startd=`ps -fz "$zonename" | egrep "sysid|svccfg|manifest|reboot|ssh-keygen|inetd-upgrade" | grep -v grep`
      done
   
      #
      # Wait for automatic post-install reboot to complete
      #
      ck4syslogd=`ps -fz "$zonename" | egrep "syslogd" | grep -v grep`
      # Wait for first boot to complete
      while [ -z "$ck4syslogd" ]
      do
         sleep 1
         ck4syslogd=`ps -fz "$zonename" | egrep "syslogd" | grep -v grep`
      done

      #
      # Define the path to the etc directory
      #
      if [ -n "$brandname" ]
      then
         zone_hosts_path="$zonedir/root/etc"
      else
         zone_hosts_path="$zonedir/root/etc/inet"
      fi

      #
      # Update the /etc/netmasks file with the ip/netmask for each specified ip address
      #
      if [ -n "${zoneip[0]}" ] 
      then
         echo "Updating netmask information."
      fi
      i=0
      while [ $i -lt $n ]
      do
         if [ -n "${zoneip[$i]}" ] && [ -n "${zonecidrnm[$i]}" ]
         then
            ipnum=`dot2dword ${zoneip[$i]}`
            netmasknum=`dot2dword ${zonenm[$i]}`
            netmask=`dword2dot $netmasknum`
            maskedipnum=$(($ipnum & $netmasknum))
            maskedip=`dword2dot $maskedipnum`

            if [ -z "$brandname" ];
            then
               ck4thisnm=`grep "$maskedip" "$zone_hosts_path/netmasks" | grep $netmask`
               if [ -z "$ck4thisnm" ]
               then
                  echo "$maskedip $netmask" >> "$zone_hosts_path/netmasks"
               fi
            fi
         fi
         i=$(($i+1))
      done

      #
      # If BrandZ zone, update the /etc/sysconfig/network file
      # to reflect networking state

      if [ -n "$brandname" ];
      then
          if [ -n "$zoneipname[0]" ];
          then
             network_file="$zonedir/root/etc/sysconfig/network"
             echo "NETWORKING=yes\nHOSTNAME=$zoneipname[0]" > "$network_file"
             chmod 644 "$network_file"
          fi
      fi

      #
      # If nsswitch.conf was copied, re-copy it after firstboot
      #
      for (( e=0; e< ${#pre_files[*]}; e++ ))
      do
         ck4=$( echo ${pre_files[$e]} | grep nsswitch.conf )
         if [ -n "$ck4" ]
         then
            copy_files "${pre_files[$e]}"
            zoneadm -z "$zonename" reboot
         fi
      done
  
      #
      # Update the /etc/inet/hosts file in the new non-global zones
      #
      if [ -n "${zoneip[0]}" ] 
      then
         echo "Updating /etc/inet/hosts of the global zone with the $zonename IP information."
      fi
      i=0
      while [ $i -lt $n ]
      do
         myadddomainname=''
         if [ -n "$domainname" ]; then myadddomainname=" ${zoneipname[$i]}.$domainname"; fi
         if [ -n "${zoneip[$i]}" ] && [ -n "${zoneipname[$i]}" ]
         then
            #
            # Check the global hosts file
            #
            ck4name=`egrep "[ 	]${zoneipname[$i]}$|[ 	]${zoneipname[$i]}\.|[ 	]${zoneipname[$i]}[ 	]" "/etc/inet/hosts"`
            ck4ip=`egrep "^${zoneip[$i]}[ 	]" "/etc/inet/hosts"`
            if [ -z "$ck4name" ] && [ -z "$ck4ip" ]
            then
               echo "${zoneip[$i]} ${zoneipname[$i]} $myadddomainname" >> "/etc/inet/hosts"
            elif [ -z "$ck4name" ] && [ -n "$ck4ip" ]
            then
               ck4iptoname=`grep "^${zoneip[$i]}[ 	]" "/etc/inet/hosts" | grep -i "${zoneipname[$i]}"`
               if [ -z "$ck4ip2name" ] 
               then
                  grep -v "^${zoneip[$i]}[ 	]" "/etc/inet/hosts" > "/etc/inet/hosts.new"
                  grep "^${zoneip[$i]}[ 	]" "/etc/inet/hosts" | sed -e "s/$/ ${zoneipname[$i]}$myadddomainname/g" >> "/etc/inet/hosts.new"
                  mv "/etc/inet/hosts.new" "/etc/inet/hosts"
               fi
            fi
            #
            # Check the non-global hosts file
            #
            ck4name=`egrep "[ 	]${zoneipname[$i]}$|[    ]${zoneipname[$i]}\.|[    ]${zoneipname[$i]}[ 	]" "$zone_hosts_path/hosts"`
            ck4ip=`egrep "^${zoneip[$i]}[ 	]" "$zonedir/root/etc/inet/hosts"`
            if [ -z "$ck4name" ] && [ -z "$ck4ip" ]
            then
               echo "${zoneip[$i]} ${zoneipname[$i]} $myadddomainname" >> "$zone_hosts_path/hosts"
            elif [ -z "$ck4name" ] && [ -n "$ck4ip" ]
            then
               ck4iptoname=`grep "^${zoneip[$i]}[ 	]" "$zone_hosts_path/hosts" | grep -i "${zoneipname[$i]}"`
               if [ -z "$ck4ip2name" ] 
               then
                  grep -v "^${zoneip[$i]}[ 	]" "$zone_hosts_path/hosts" > "$zone_hosts_path/hosts.new"
                  grep "^${zoneip[$i]}[	]" "$zone_hosts_path/hosts" | sed -e "s/$/ ${zoneipname[$i]}$myadddomainname/g" >> "$zone_hosts_path/hosts.new"
                  mv "$zone_hosts_path/hosts.new" "$zone_hosts_path/hosts"
               fi
            fi
         fi
         i=$(($i+1))
      done

      #
      # Add NFS mount points
      #
      if [ -n "${nfshost[0]}" ] && [ -n "${nfsexport[0]}" ] 
      then
         echo "Updating /etc/inet/hosts of the global zone with the $zonename IP information."
      fi
      i=0
      while [ $i -lt $p ]
      do
         echo "${nfshost[$i]}:${nfsexport[$i]}	-	${nfsmount[$i]}	nfs	-	yes	${nfsoptions[$i]}" >> /etc/vfstab
      done

      #
      # If domainname is specified, create a /etc/defaultdomain
      #
      if [ -n "$domainname" ]
      then
         echo "$domainname" >> "$zonedir/root/etc/defaultdomain"
      fi

      #
      # Add branding customization
      #
      if [ -n "$brandname" ];
      then 
         echo "Enabling brandZ"
         #
         # Enable zone network interface
         #
            mkdir -p "$zonedir/root/etc/sysconfig" 2> /dev/null
            cat > "$zonedir/root/etc/sysconfig/network" <<EOF
NETWORKING=yes
HOSTNAME=$hostname
EOF

         #
         # Set the root password (hack)
         #
         tmpshadow="$zonetmpdir/shadow"
         export encrootpw

         cat "$zonedir/root/etc/shadow" | nawk 'BEGIN { FS=":"} ! /root/{ print $0 } /root/{ print $1 ":" ENVIRON["encrootpw"] ":" $3 ":" $4 ":" $5 ":" $6 ":" $7 ":" $8 ":" }' > $tmpshadow
         cat $tmpshadow > "$zonedir/root/etc/shadow"
         rm $tmpshadow
      fi
   fi

   #
   # Configure root user
   #
   cfg_root_user

   #
   # Perform appropriate management service action
   #
   if [ -n "$hardening_mode" ]
   then
      run_manage_services "$zonename" 'disable' "$hardening_mode" "$hardening_args"
   fi

   #
   # Minimize the non-global zone
   #
   if [ "$zoneminimize" == 'yes' ];
   then
      run_remove_packages 
   fi

   #
   # Install requested CSW packages
   #
   if [ -n "${pkglist[0]}" ]
   then
      addCSWpkgs;
   fi

   #
   # Run commands after zone creation
   #
   run_in_zones "$zonename"

   #
   # Let user know it is ready
   #
   echo "Zone $zonename is complete and ready to use."
}

##############################################################################
#
# Function for moving a zone
#
move_zone() {
   are_you_sure "move zone"
   ck4moving=`zoneadm 2>&1 | grep "move zonepath"`
   if [ -z "$ck4moving" ]
   then
      error_message "The move feature does not exist on this version of Solaris.";
   fi

   if [ -n "$zonedir" ] 
   then
      if [ -d "$zonedir/dev" ] || [ -d "$zonedir/root" ] || [ -f "$zonedir" ]
      then
         error_message "The destination directory ($zonedir) cannot contain an existing zone.";
      fi
   fi

   #prevstate=`zoneadm -z "$zonename" list -p | cut -d: -f3`
   if [ "$prevstate" == 'running' ]
   then
      zoneadm -z "$zonename" halt
   fi
   sleep 2
   zoneadm -z "$zonename" move "$zonedir"
   if [ $? -ne 0 ] 
   then
      error_message "Zone move failed, return value: $?"
   fi
   if [ "$prevstate" == 'running' ]
   then
      zoneadm -z "$zonename" boot
   fi
}

##############################################################################
#
# Function for detaching a zone
#
detach_zone() {
   are_you_sure "detach zone"
   ck4detach=`zoneadm 2>&1 | grep "detach"`
   if [ -z "$ck4detach" ]
   then
      error_message "The detach feature does not exist on this version of Solaris.";
   fi

   zoneadm -z "$zonename" halt
   sleep 2
   zoneadm -z "$zonename" detach
   if [ $? -ne 0 ] 
   then
      error_message "Zone detach failed, return value: $?"
   fi
}

##############################################################################
#
# Function for attaching a zone
#
attach_zone() {
   are_you_sure "attach zone"
   ck4attach=`zoneadm 2>&1 | grep "attach"`
   if [ -z "$ck4attach" ]
   then
      error_message "The attach feature does not exist on this version of Solaris.";
   fi

   zoneadm -z "$zonename" attach
   if [ $? -ne 0 ] 
   then
      error_message "Zone attach failed, return value: $?"
   fi
}

##############################################################################
#
# Function for disabling or enabling all un-necessary OS services
#
run_manage_services() {
   hardening_zone="$1"
   hardening_action="$2"
   hardening_mode="$3"
   hardening_args="$4"

   #
   # Test the zone name
   #
   if [ -n "$hardening_mode" ]
   then

      ck4zone=`zoneadm -z "$hardening_zone" list -p | cut -d: -f3`
      if [ -z "$ck4zone" ]
      then
         error_message "Must specify zone name when hardening a zone."
      fi

      #
      # Test the hardening action
      #
      case "$hardening_action" in
      'disable') hardening_action='disable'; averb='Disabling';;
         'lock') hardening_action='disable'; averb='Disabling';;
       'enable') hardening_action='enable';  averb='Enabling';;
       'unlock') hardening_action='enable';  averb='Enabling';;
              *) error_message "\"$hardening_action\" is not a valid hardening action";;
      esac
  
      #
      # Test the hardening mode
      #
      case "$hardening_mode" in
       'netservices') true;;
               'sbd') true;;
              'jass') true;;
               'smf') true;;
             'basic') true;;
            'enable') true;;
           'disable') true;;
              'lock') true;;
            'unlock') true;;
                   *) error_message "Invalid hardening mode.  Valid hardening modes include the following\n netservices - Secure by Default\n jass - \n smf - Service management facility (SMF) site profile\n basic - Select default or individual SMF and rc scripts to disable.";;
      esac

      #
      # Test hardening arguments
      #
      if [ -z "$hardening_args" ]
      then
         error_message "Must specify hardening arguments when hardening a zone."
      fi

      #
      # Test for force.
      #
      if [ "$action" != 'add' ];then are_you_sure "$hardening_action services"; fi

      #
      # Secure by Default
      #
      run_sbd() {
         echo "$averb un-necessary services via Secure by Default (netservices)"
         #
         # If netservices (Secure By Default) is available
         #   Note that this changes the default service settings
         #   to be secure by default.  Manual inetvention may be
         #   necessary as a post operation to enable services 
         #   that are made local only by sbd.
         #
         # Note: Only run netservices if a services file isn't
         # specified.
         #
         svcprofile=''
         ck4netsvcs=`which netservices 2>&1 | grep -v "no less"`
         if [ -n "$ck4netsvcs" ]
         then
            zlogin "$zonename" "netservices \"$hardening_args\" 2> /dev/null"
         else
            error_message "Secure by Default (netservices) isn't installed \non this system and therefore cannot be used."
         fi
      }

      #
      # JASS/SST
      #
      run_jass() {
         # Make sure jass is installed
         ckpkgver SUNWjass
         if [ -z "$hardening_args" ]
         then
            error_message "Must provide a JASS profile name."
         fi

         echo "$averb un-necessary services via JASS"
         if [ -f "$zonedir/root/opt/SUNWjass/bin/jass-execute" ]
         then
            undojass=''
            if [ "$hardening_action" == 'undo' ]
            then
                undojass=' -u '
            fi
            zlogin "$zonename" "env JASS_NOVICE_USER=0 /opt/SUNWjass/bin/jass-execute $undojass \"$hardening_args\""
            zoneadm -z "$zonename" reboot
         else
            error_message "JASS is not installed on this system and therefore cannot be used."
         fi
      }

      #
      # Service Management Facility site.xml profile
      #
      run_smf() {
         if [ -f "$hardening_args" ]
         then
            echo "$averb un-necessary services via SMF using the following site profile:\n$hardening_args"
            #
            # Add a sanity check of the xml file
            #
            isvalidfile=`grep 'DOCTYPE service_bundle SYSTEM' "$hardening_args"`
            ck4validxml=`xmllint "$hardening_args" > /dev/null 2>&1; echo $?`
            if [ -n "$isvalidfile" ] && [ $ck4validxml -eq 0 ]
            then
               cp "$hardening_args" /var/svc/profile/site.xml
               zoneadm -z "$zonename" reboot
            fi
         fi
      }

      #
      # Use basic services management
      #
      # or an input services file (in \"svcs -o FMRI\" format)."
      run_basic() {
         if [ "$action" == 'add' ]
         then
            hardening_action='disable'
         fi
         if [ -n "$hardening_args" ]
         then
            case "$hardening_args" in
                 'lock') hardening_action='disable'; averb='Disabling';;
               'unlock') hardening_action='enable';  averb='Enabling';;
              'disable') hardening_action='disable'; averb='Disabling';;
               'enable') hardening_action='enable';  averb='Enabling';;
                      *) hardening_action=`echo $hardening_args | cut -d'|' -f1`
                         svcs_file=`echo $hardening_args | cut -d'|' -f2`
                         if [ -f "$svcs_file" ]
                         then
                            true
                         else
                            error_message "Invalid hardening argument for basic method."
                         fi
                         ;;
            esac
         else
            case "$hardening_mode" in
              'enable') hardening_args='enable';hardening_action='enable'; averb='Enabling';;
             'disable') hardening_args='disable';hardening_action='disable'; averb='Disabling';;
                'lock') hardening_args='disable';hardening_action='disable'; averb='Disabling';;
              'unlock') hardening_args='enable';hardening_action='enable'; averb='Enabling';;
                     *) error_message "Invalid hardening mode."
            esac
         fi

         rzonepath=`zonecfg -z "$zonename" info zonepath 2> /dev/null | awk '{ print $2 }'`
         if [ -n "$svcs_file" ] && [ -f "$svcs_file" ]
         then
            echo "$averb un-necessary services via basic method using the ($svcs_file) input file."
            rcfiles=`grep "^lrc:" "$svcs_file" | cut -d: -f2- | sed -e "s/rc2_d/rc2.d/g" -e "s/rc3_d/rc3.d/g"`
            svcs=`grep "^svc:" "$svcs_file" | cut -d: -f2-`
         else
            echo "$averb un-necessary services via basic method for the default services."
            rc2="/etc/rc2.d"
            rc3="/etc/rc3.d"
            rcfiles="$rc3/S16boot.server $rc3/S50apache $rc3/S52imq $rc3/S76snmpdx $rc3/S77dmi $rc3/S81volmgt $rc3/S82initsma $rc3/S84appserv $rc3/S90samba $rc2/S70uucp $rc2/S72autoinstall $rc2/S73cachefs.daemon $rc2/S89PRESERVE $rc2/S90wbem $rc2/S90webconsole $rc2/S98deallocate $rc2/S99audit $rc2/S99dtlogin"

            svcs="svc:/network/smtp:sendmail svc:/system/filesystem/autofs:default svc:/network/nfs/status:default svc:/network/nfs/nlockmgr:default svc:/network/nfs/client:default svc:/network/nfs/rquota:default svc:/network/rpc/bind:default svc:/application/font/stfsloader:default svc:/application/x11/xfs:default svc:/network/finger:default svc:/network/ftp:default svc:/network/login:rlogin svc:/network/rpc/gss:default svc:/network/rpc/rstat:default svc:/network/rpc/rusers:default svc:/network/rpc/smserver:default svc:/network/security/ktkt_warn:default svc:/network/shell:default svc:/network/telnet:default svc:/network/rpc-100235_1/rpc_ticotsord:default svc:/network/rpc-100083_1/rpc_tcp:default svc:/network/rpc-100068_2-5/rpc_udp:default svc:/application/print/rfc1179 svc:/milestone/name-services:default svc:/system/name-service-cache:default"
         fi

         #
         # Disable unnecessary legacy (rc) services
         #
         for i in $rcfiles
         do
            j=`echo $i | sed -e "s/d\/S/d\/s/g"`
            if [ "$hardening_action" == 'disable' ]
            then
               if [ -e "$rzonepath/root/$i" ]
               then
                  zlogin "$zonename" "mv $i $j;$j stop > /dev/null 2>&1"
               fi
            elif [ "$hardening_action" == 'enable' ]
            then
               if [ -e "$rzonepath/root/$j" ]
               then
                  zlogin "$zonename" "mv $j $i;$i start > /dev/null 2>&1"
               fi
            fi
         done

         #
         # Disable/Enable unnecessary services
         #
         for svc in $svcs
         do
            zlogin $zonename "svcadm $hardening_action $svc 2> /dev/null"
         done
      }

      case "$hardening_mode" in
       'netservices') if [ "$action" != 'add' ];then run_sbd;fi;;
               'sbd') if [ "$action" != 'add' ];then run_sbd;fi;;
              'jass') run_jass;;
               'smf') run_smf;;
             'basic') run_basic;;
            'enable') run_basic;;
           'disable') run_basic;;
              'lock') run_basic;;
            'unlock') run_basic;;
      esac
   fi
}

##############################################################################
#
# Set the non-global root users home directory and/or shell
#
cfg_root_user() {
   if [ -z "$zonedir" ]
   then
      zonedir=`zonecfg -z "$zonename" info zonepath 2> /dev/null | awk '{ print $2 }'`
   fi
   if [ -n "$rootHomeDir" ] 
   then
      if [ -d "$zonedir/root/$rootHomeDir" ] 
      then
         true
      elif [ -f "$zonedir/root/$rootHomeDir" ] 
      then
         error_message "The root home directory ($rootHomeDir) does not appear to be a directory."
      else
         #
         # Create and set the permissions of the root home directory.
         #
         mkdir -p "$zonedir/root/$rootHomeDir"
         chmod 700 "$zonedir/root/$rootHomeDir"
      fi
      echo "Setting the root user's home directory to $rootHomeDir"
      #chroot "$zonedir/root" /usr/sbin/usermod -d "$rootHomeDir" root
      zlogin $zonename /usr/sbin/usermod -d "$rootHomeDir" root
   fi

   if [ -n "$rootShell" ]
   then
      if [ -x "$zonedir/root$rootShell" ]
      then
         if [ -f "$zonedir/root/etc/shells" ]
         then
            ck4shellinshells=`grep "$rootShell" "$zonedir/root/etc/shells"`
            if [ -z "$zonedir/root/etc/shells" ]
            then
               error_message "An /etc/shells file exists and your root shell ($rootShell) is \nnot in /etc/shells.  You must either choose a shell \nthat is in /etc/shells or make sure that your shell is in /etc/shells.\n"
            fi
         fi
         echo "Setting the root user's shell to $rootShell"
         #chroot "$zonedir/root" /usr/sbin/usermod -s "$rootShell" root
         zlogin $zonename /usr/sbin/usermod -s "$rootShell" root
      else
         error_message "The specified root shell ($rootShell) does not exist."
      fi
   fi
}

##############################################################################
# 
# Minimize the zone  
# 
run_remove_packages() {
   if [ "$zoneminimize" == 'yes' ];
   then
      if [ "$action" == 'add' ] || [ "$action" == 'modify' ] 
      then
         true
      else
         error_message "Zone minimization can only be applied when adding or modifying a zone."
      fi

      #
      # Make sure that there are no inherited directories
      #
      if [ "$zonetype" == 's' ] || [ "$zonetype" == 'w' ]
      then
         sparsezone=`zonecfg -z "$zonename" info inherit-pkg-dir 2> /dev/null`
         if [ -n "$sparsezone" ] 
         then
            error_message "The zone type must be set to 'whole' and there cannot be any inherited directories from the \nglobal zones in order to minimize the zone!";
         else
            zonetype='w'
         fi
      elif [ "$zonetype" != 'w' ]
      then 
         error_message "The zone type must be set to 'whole' in order to minimize the zone!";
      fi

      ck4zone=`zoneadm -z "$zonename" list -p | cut -d: -f3`
      if [ "$ck4zone" != 'running' ]
      then
         error_message "Zone must be running in order to minimize the zone!";
      fi

      # Validate assurance
      are_you_sure "Minimize Zone (e.g. Remove unnecessary packages)"

      zlogin "$zonename" "sed -e 's/ask/nocheck/' /var/sadm/install/admin/default > $pkgdefaults"

      if [ -n "$minimizationfile" ] && [ -f "$minimizationfile" ]
      then 
         pkg_cats=`cat "$minimizationfile"`
         pkgs=`cat "$minimizationfile"`
      else 
         pkg_cats="JDS4 JDS3 JDS JDSosol GNOME2 CTL ALE APOC CTL EVO146 G11NTOLS GLOW JAI JAVAAPPS JDIC"
         pkgs=''

         # Identify bundled Message Queue packages
         pkgstorm=`zlogin "$zonename" "pkginfo |grep SUNWiq|grep -i java|cut -c13-35"`
         pkgs="`echo $pkgstorm` $pkgs"

         # Identify bundled App Server
         pkgstorm=`zlogin "$zonename" "pkginfo |grep SUNWas|egrep -i '(java|pointbase)' |cut -c13-35"`
         pkgs="`echo $pkgstorm` $pkgs"
      fi

      #
      # Remove package categories
      #
      if [ -n "$pkg_cats" ]
      then
         echo "Constructing package list from package categories"
         for pkg_cat in $pkg_cats
         do
            cat_pkgs=`zlogin "$zonename" "pkginfo -c $pkg_cat 2> /dev/null" | awk '{ print $2 }'`
            if [ -n "$cat_pkgs" ]
            then
               pkgs="$pkgs $cat_pkgs"
            fi
         done
      fi

      #
      # Remove individual packages
      #
      if [ -n "$pkgs" ]
      then
         for pkg in $pkgs
         do
            ck4pkg=`zlogin "$zonename" "pkginfo $pkg 2>&1" | awk '{ print $2 }'`
            if [ "$ck4pkg" == "$pkg" ]
            then
               echo -e "Removing pkg $pkg...\c"
               zlogin "$zonename" "pkgrm -n -a $pkgdefaults $pkg"
            else
               echo "Package $pkg is not installed."
            fi
         done
      fi
   fi
}

##############################################################################
#
# Modify a zone's configuration
#
modify_zone() {
   are_you_sure "modify zone"
   #
   # Configure root user
   #
   cfg_root_user

   #
   # Make sure the zone file is empty
   #
   cp /dev/null "$zonefile"
 
   i=0
   while [[ $i -lt $cnum ]]
   do
      curProperty=`echo ${curProp[$i]} | cut -d':' -f1`
      case "$curProperty" in
             'del') prop1Type=`echo ${curProp[$i]} | cut -d':' -f2`
                    case "$prop1Type" in
                      'net') prop1Name='address';;
                       'fs') prop1Name='dir';;
                          *) error_message "\"$prop1Type\" is not a valid property for deletion.\nValid zoneconfiguration properties to delete include: net or fs";;
                    esac
                    prop1Value=`echo ${curProp[$i]} | cut -d':' -f3`
                    #
                    # Make sure the property to be modified exists
                    #
                    ck4prop=`zonecfg -z "$zonename" info $prop1Type $prop1Name=$prop1Value | grep 'No such fs resource.'`
                    if [ -n "$ck4prop" ]
                    then
                       error_message "Property $prop1Type $prop1Name=$prop1Value does not exist."
                    fi

                    zcfg="$zcfg
remove $prop1Type $prop1Name=$prop1Value"
                    ;;
        'zonename') prop1Value=`echo ${curProp[$i]} | cut -d':' -f2`
                    zattrcfg="$zattrcfg
set zonename=$prop1Value"
                    newzonename="$prop1Value"
                    ;;
        'autoboot') prop1Value=`echo ${curProp[$i]} | cut -d':' -f2`
                    if [ "$prop1Value" == 'true' ] || [ "$prop1Value" == 'false' ]
                    then
                       true
                    else
                       error_message "Invalid autoboot value.  Valid autoboot values are 'true' or 'false'."
                    fi
                    set_autoboot $prop1Value
                    ;;
        'bootargs') prop1Value=`echo ${curProp[$i]} | cut -d':' -f2`
                    zattrcfg="$zattrcfg
set bootargs=$prop1Value"
                    ;;
         'comment') prop1Value=`echo ${curProp[$i]} | cut -d':' -f2`
                    zattrcfg="$zattrcfg
select attr name=comment
set value=\"$prop1Value\"
end"
                    ;;
              'fs') prop1Value=`echo ${curProp[$i]} | cut -d':' -f2`
                    prop2Type=`echo ${newProp[$i]} | cut -d':' -f1`
                    case "$prop2Type" in
                      'dir') true;;
                      'special') true;;
                      'options') true;;
                      *) error_message "\"$prop2Type\" is not a valid property for modification.\nValid fs properties for modification include: dir, special, ";;
                    esac
                    prop2Value=`echo ${newProp[$i]} | cut -d':' -f2`

                    #
                    # Make sure the property to be modified exists
                    #
                    ck4prop=`zonecfg -z "$zonename" info fs dir=$prop1Value | grep 'No such fs resource.'`
                    if [ -n "$ck4prop" ]
                    then
                       error_message "Property fs dir=$prop1Value does not exist."
                    fi

                    #
                    # Make sure the new value doesn't already exist
                    #
                    ck4prop=`zonecfg -z "$zonename" info fs dir=$prop2Value | grep 'No such fs resource.'`
                    if [ -z "$ck4prop" ]
                    then
                       error_message "Property fs dir=$prop2Value already exists."
                    fi

                    zcfg="$zcfg
select fs dir=$prop1Value
set $prop2Type=$prop2Value
end
commit"
                    ;;
             'net') prop1Value=`echo ${curProp[$i]} | cut -d':' -f2`
                    prop2Type=`echo ${newProp[$i]} | cut -d':' -f1`
                    case "$prop2Type" in
                      'address') true;;
                      'physical') true;;
                      *) error_message "\"$prop2Type\" is not a valid property for modification.\nValid fs properties for modification include: address and physical";;
                    esac
                    prop2Value=`echo ${newProp[$i]} | cut -d':' -f2`

                    #
                    # Make sure the property to be modified exists
                    #
                    ck4prop=`zonecfg -z "$zonename" info net address=$prop1Value | grep 'No such'`
                    if [ -n "$ck4prop" ]
                    then
                       error_message "Property net address=$prop1Value does not exist."
                    fi

                    #
                    # Make sure the new property doesn't exist
                    #
                    ck4prop=`zonecfg -z "$zonename" info net address=$prop2Value | grep 'No such net resource.'`
                    if [ -z "$ck4prop" ]
                    then
                       error_message "Property net address=$prop2Value already exists."
                    fi

                    if [ "$prop2Type" == 'physical' ]
                    then
                       ck4if=`ifconfig $prop2Value > /dev/null 2>&1`
                       if [ $? -ne 0 ]
                       then
                          error_message "Network interface \"$prop2Value\" does not exist."
                       fi
                    fi

                    zcfg="$zcfg
select net address=$prop1Value
set $prop2Type=$prop2Value
end
commit"
                    ;;
                  *) error_message "Invalid property.  See the modify action in the help page for zonemgr.";;
      esac
      i=$(($i+1))
   done

   #
   # Add new IP addresses if specified
   #
   add_net_addr

   #
   # Limit zone privileges
   #
   limit_privs

   #
   # Add ro, rw, and zfs filesystems
   #
   add_fs

   #
   # Make sure the zone is halted, apply the change, and 
   # then restore it to its previous state.
   #
   if [ -n "$zcfg" ] || [ -n "$zattrcfg" ] || [ -n "${pre_files[0]}" ] 
   then
      #prevstate=`zoneadm -z "$zonename" list -p | cut -d: -f3`
      if [ "$prevstate" == 'running' ]
      then
         zlogin "$zonename" "shutdown -y -g 0 -i 5;wait"
         zoneadm -z "$zonename" halt
      fi

      #
      # Commit the zone configuration
      #
      commit_zcfg

      #
      # Copy files before booting the zone
      #
      if [ -n "${pre_files[0]}" ]
      then
         copy_files "${pre_files[@]}"
      fi

      if [ "$prevstate" == 'running' ]
      then
         if [ -n "$newzonename" ]
         then
            zoneadm -z "$newzonename" boot
         else
            zoneadm -z "$zonename" boot
         fi
      fi
   fi

   #
   # Perform appropriate management service action
   #
   if [ -n "$hardening_mode" ]
   then
      run_manage_services "$zonename" "$hardening_action" "$hardening_mode" "$hardening_args"
   fi

   #
   # Minimize the non-global zone
   #
   if [ "$zoneminimize" == 'yes' ];
   then
      run_remove_packages 
   fi

   #
   # Install requested CSW packages
   #
   if [ -n "${pkglist[0]}" ]
   then
      addCSWpkgs;
   fi

   #
   # Run commands after zone creation
   #
   run_in_zones "$zonename"
}
   
##############################################################################
#
# Functions for managing solaris trusted extensions
#
#labelCheck() {
#	hexlabel=`/bin/grep "^$zonename:" \
#	    /etc/security/tsol/tnzonecfg|cut -d ":" -f2`;
#	if [ $hexlabel ] ; then
#		label=
#		curlabel=`hextoalabel $hexlabel`
#	else
#		label="Select_Label..."
#		curlabel=...
#	fi
#}
#
#listLabels() {
#  echo "List Labels"
#}
#
#selectLabel() {
#	labelList=""
#	for p in `lslabels -h $maxlabel`; do
#		hexlabel=`/bin/grep :$p: /etc/security/tsol/tnzonecfg`
#		if [ $? != 0 ]; then
#			hextoalabel $p >> "$zonetmpdir/hexlabel$$"
#		fi
#	done
#	alabel=$(zenity --list \
#	    --title="$title" \
#	    --height=300 \
#	    --column="Available Sensitivity Labels" < "$zonetmpdir/hexlabel$$" ) 
#
#       rm -f "$zonetmpdir/hexlabel$$"
#
#	if [[ -n $alabel ]]; then
#		newlabel=`atohexlabel "$alabel"`
#		echo $zonename:$newlabel:0:: >> /etc/security/tsol/tnzonecfg
#	fi
#}


##############################################################################
# 
# Manage zones
# 
only_my_zones() {
   myzones="$*"
   if [ -z "$myzones" ] || [ "$action" != 'only' ]
   then
      echo -e "Error: you must specify one or more zones for this action.\nAvailable zones include the following"
      zoneadm list -cv
   else
      # Validate assurance
      if [ "$myzones" = 'bootall' ] 
      then
         are_you_sure "Boot All Zones"
         myzones=`zoneadm list -cp| cut -d: -f2 |grep -v global`
         for myzone in $myzones
         do
            ck4zone=`zoneadm -z "$myzone" list -p | cut -d: -f3`
            if [ "$ck4zone" != 'running' ]
            then
               echo "Zone $myzone is not currently running.  Starting up zone $myzone now."
               zoneadm -z "$myzone" boot
            fi
         done
         echo "All zones are now running."
      elif [ "$myzones" = 'haltall' ] 
      then
         are_you_sure "Halt All Zones"
         myzones=`zoneadm list -cp| cut -d: -f2 |grep -v global`
         for myzone in $myzones
         do
            ck4zone=`zoneadm -z "$myzone" list -p 2>&1 | cut -d: -f3`
            if [ "$ck4zone" != 'installed' ]
            then
               echo "Zone $myzone is currently running.  Halting zone $myzone now."
               zoneadm -z "$myzone" halt
            fi
         done
         echo "All zones are now halted."
      else
         are_you_sure "Make Only Selected Zones Online"
         #
         # Figure out which zones aren't in my list
         #
         zlist=`zoneadm list`
         for z in $zlist
         do
            inmylist='false'
            for myzone in $myzones
            do
               ck4zone=`zoneadm -z "$myzone" list -p 2>&1 | cut -d: -f3`
               if [ "$ck4zone" = ' No such zone configured' ]
               then
                  error_message "Zone \"$myzone\" does not exist.  Exiting"
               fi
               if [ "$z" = "$myzone" ] || [ "$z" = 'global' ]
               then
                  inmylist='true'
               fi
            done
            if [ "$inmylist" = 'false' ] 
            then
               notmyzones="$notmyzones $z"
            fi
         done

         #
         # Ensure my zones are booted
         #
         for myzone in $myzones
         do
            ck4zone=`zoneadm -z "$myzone" list -p | cut -d: -f3`
            if [ "$ck4zone" != 'running' ]
            then
               echo "Zone $myzone is not currently running.  Starting up zone $myzone now."
               zoneadm -z "$myzone" boot
            fi
         done

         #
         # Halt all other non-global zones
         #
         for z in $notmyzones
         do
            echo "Shutting down zone \"$z\""
            zoneadm -z "$z" halt
         done
      fi
      echo "Now only your zones are running."
   fi
}

##############################################################################
# 
# Delete all zones but those specified to keep
# 
del_all_but() {
   zones2keep="$*"

   #
   # Figure out which zones to delete
   #
   zlist=`zoneadm list`
   for z in $zlist
   do
      inmylist='false'
      for myzone in $zones2keep
      do
         ck4zone=`zoneadm -z "$myzone" list -p 2>&1 | cut -d: -f3`
         if [ "$ck4zone" = ' No such zone configured' ]
         then
            error_message "Zone \"$myzone\" does not exist.  Exiting"
         fi
         if [ "$z" = "$myzone" ] || [ "$z" = 'global' ]
         then
            inmylist='true'
         fi
      done
      if [ "$inmylist" = 'false' ] 
      then
         zones2delete="$zones2delete $z"
      fi
   done


   if [ -n "$zones2keep" ] && [ "$action" == 'keep' ]
   then
      are_you_sure "Delete The Following Zones: $zones2delete"
      #
      # Delete zones
      #
      for z in $zones2delete
      do
         delete_zone "$z"
      done

      echo "Now only zones $zones2keep are remaining."
   else
      echo -e "Error: you must specify one or more zones to keep for this action.\nAvailable zones include the following"
      zoneadm list -cv
      exit 0
   fi
}

##############################################################################
# 
# Run a command in specified zones
# 
run_in_zones() {
   myzones="$*"
   if [ -n "${runcmd[0]}" ]
   then
       if [ -z "$myzones" ] 
       then
          echo -e "Error: you must specify one or more zones for this action.\nAvailable zones include the following"
          zoneadm list -cv
       else
          # Validate assurance
          if [ "$myzones" = 'all' ] 
          then
             are_you_sure "Run command in zones $myzones"
             myzones=`zoneadm list -cp| cut -d: -f2 |grep -v global`
          fi
          for myzone in $myzones
          do
             ck4zone=`zoneadm -z "$myzone" list -p | cut -d: -f3`
             if [ "$ck4zone" == 'running' ]
             then
                i=0
                while [ $i -lt $q ]
                do
                   echo "Running \"${runcmd[$i]}\" in zone $myzone..."
                   zlogin -S "$myzone" "${runcmd[$i]}"
                   i=$(($i+1))
                done
             else
                echo -e "Error: Couldn't run commands in $myzone zone\nbecause the zone wasn't in the running state."
             fi
          done
       fi
   fi
}

##############################################################################
#
# Function for setting up a resource pool
#
make_resource_pool() {
      #
      # Make sure poold is enabled
      #
      ck4poold=`ps -ef | grep poold | grep -v grep`
      if [ -z "$ck4poold" ]
      then
         pooladm -e
      fi

      #
      # Create a new pool called $zonename-pool
      #
      ck4pool=`poolcfg -dc "info pool $zonename-pool" > /dev/null 2>&1; echo $?`
      if [ $ck4pool -ne 0 ]
      then
         poolcfg -dc "create pool $zonename-pool"
      fi
}

##############################################################################
#
# Function for activating a resource pool
#
activate_resource_pool() {
      #
      # Make sure the active configuration has been saved
      #
      pooladm -s

      #
      # Instantiate (ie., activate) the configuration from /etc/pooladm.conf in to memory 
      #
      pooladm -c

      #
      # Set the zcontainer name for zone creation
      #
      zattrcfg="$zattrcfg
set pool=$zonename-pool"
}

##############################################################################
#
# Function for setting up a processor set and configuring it
#
make_cpu_limit() {
   myrcount=$1
   ck4pset=`poolcfg -dc "info pset $zonename-pset" > /dev/null 2>&1; echo $?`
   if [ $ck4pset -ne 0 ]
   then
      if [ -n "$myrcount" ] && [ $myrcount -ge 1 ]
      then
         #
         # Make sure the resource pool exists
         #
         make_resource_pool
   
         maxavailcpus=`poolcfg -dc 'info pset pset_default' | grep cpu.sys_id | awk '{ print $3 }' | sort -nr | uniq | wc -l`
         # The number of cpus must be decremented by 1 because the global needs a minimum of
         # one processor.  The remainder is what is available to non-global zones.
         maxavailcpus=`echo $(($maxavailcpus - 1))`
   
         if [ $myrcount -gt 1 ] 
         then
            nprocs="processors"
         else
            nprocs="processor"
         fi

         if [ $maxavailcpus -gt 1 ] || [ $maxavailcpus -le 0 ] 
         then
            aprocs="are only $maxavailcpus processors"
         else
            aprocs="is only $maxavailcpus processor"
         fi

         if [ $(($maxavailcpus - $myrcount)) -lt 0 ] 
         then
            poolcfg -dc "destroy pool $zonename-pool" 2> /dev/null
            poolcfg -dc "destroy pset $zonename-pset" 2> /dev/null
            error_message "You cannot assign $myrcount $nprocs to zone $zonename because there $aprocs available."
         fi
  
         if [ $myrcount -le 0 ] || [ $myrcount -gt $maxavailcpus ] 
         then
            error_message "The number of processors cannot be greater than the number of processors in the system."
         fi

         #
         # Create a processor set
         #
         poolcfg -dc "create pset $zonename-pset  ( uint pset.min = 1; uint pset.max = $myrcount )"

         #
         # Associate the processor set $zonename-pset with pool $zonename-pool
         #
         poolcfg -dc "associate pool $zonename-pool ( pset $zonename-pset )"

         #
         # Activate the resource pool
         #
         activate_resource_pool
      else
         info_error_message "A valid processor count must be provided with the cpu resource type of the -p flag."
      fi
   fi
}

##############################################################################
#
# THIS FEATURE IS NOT YET AVAILABLE OR ENABLED!!!!!
#
# Function for setting up a memory limit   (THIS FEATURE IS NOT YET AVAILABLE)
#  * This is just a place holder for this feature as soon as it becomes 
#    available in Solaris.
#
make_memory_limit() {
   # myrcount is the number of bytes of RAM
   myrcount=`echo $1 | cut -d'|' -f2`
   if [ -n "$myrcount" ] && [ $myrcount -ge 1 ]
   then
      #
      # Make sure the resource pool exists
      #
      make_resource_pool

      #
      # Add memory capping for a zone
      #

      #
      # Activate the resource pool
      #
      activate_resource_pool
   else
      info_error_message "A valid memory count must be provided with the ram resource type of the -p flag."
   fi
}

##############################################################################
#
# Convert the netmask from dot notation to CIDR format
#
nm2cidr() {
   nm=$1
   oct=("`echo $nm | cut -d. -f1`" "`echo $nm | cut -d. -f2`" "`echo $nm | cut -d. -f3`" "`echo $nm | cut -d. -f4`")

   validnm='true'
   for (( o=0; o< ${#oct[*]}; o++ ))
   do
      if [ -z "${oct[$o]}" ] || [ $((${oct[$o]} + 0)) -lt 0 ] || [ $((${oct[$o]} + 0)) -gt 255 ]
      then
         validnm='false'
      fi
   done
     
   if [ "$validnm" == 'false' ]
   then
      error_message "When using dotted notation netmask, the octet values cannot be greater than 255 or less than 0."
   fi

   # Convert the netmask to CIDR format (thanks James Carlson!)
   cidr=`perl -e 'use Socket; print unpack("%32b*",inet_aton($ARGV[0])), "\n";' $nm`
   echo $cidr
}

##############################################################################
#
# Convert the netmask from CIDR format to dot notation 
#
cidr2dot() {
   cidr=$1
   if [ -n "$cidr" ] && [ $cidr -ge 0 ] && [ $cidr -le 32 ]
   then
      # Convert the CIDR netmask to dotted notation format 
      # (thanks James Carlson!)
      perl -e 'use Socket;
            ($c1,$c2,$c3,$c4) = unpack("C4",pack("N",~((1<<(32-$ARGV[0]))-1)));
            print "$c1.$c2.$c3.$c4\n";' $cidr
   else
      error_message "When using the CIDR netmask format, the value cannot be greater than 32 or less than 0"
   fi
}

##############################################################################
#
# Convert an IP address from decimal format to dot notation
#
dword2dot() {
   dword=$1
   byte0=$((($dword & 0xff000000)/256/256/256))
   byte1=$((($dword & 0x00ff0000)/256/256))
   byte2=$((($dword & 0x0000ff00)/256))
   byte3=$(($dword & 0x000000ff))
   echo "$byte0.$byte1.$byte2.$byte3"
}

##############################################################################
#
# Convert an IP address from dot notation to decimal format
#
dot2dword() {
   dot=$1
   oct1=`echo $dot | cut -d. -f1`
   oct2=`echo $dot | cut -d. -f2`
   oct3=`echo $dot | cut -d. -f3`
   oct4=`echo $dot | cut -d. -f4`
   echo $(($oct1*256*256*256+$oct2*256*256+$oct3*256+$oct4))
}

##############################################################################
#
# Download and install requested CSW packages
#
addCSWpkgs() {
   #
   # Wait for about 10 seconds to make sure that the zone is
   # ready to download packages from the Internet.
   #
   sleep 10;

   echo -e "Making sure Blastwave's pkg-get progam is installed."
   echo -e "The installation log for blastwave packages is stored in\n$cswlog"
   #
   # Make sure that the CSWpkgget is installed and at version 3.5 or above
   #
   cswdata=`zlogin "$zonename" "pkginfo -l CSWpkgget 2>&1" | grep VERSION | awk '{ print $2 }'`;
   cswversion=`echo $cswdata | cut -d. -f1`
   cswrelease=`echo $cswdata | cut -d. -f2`
   if [ -n "$cswdata" ] 
   then 
      if [ "$cswversion" -lt 3 ] || [ "$cswrelease" -lt 5 ]
      then 
         error_message "CSWpkgget version must be 3.5 or greater."
      fi 
   else
      #
      # If CSWpkgget isn't installed, then download it
      # from Blastwave and install it.
      #
      ck4wget=`zlogin "$zonename" "env \"PATH=$MYPATH\" which wget 2>/dev/null | grep -v \"^no wget\""`
      if [ -z "$ck4wget" ]
      then
         error_message "The wget command is required to download and install the BlastWave pkg_get.pkg package."
      else
         zlogin "$zonename" "env \"PATH=$MYPATH\" wget -q http://www.blastwave.org/pkg_get.pkg 2>&1" >> "$cswlog" 
         if [ "$?" -eq 0 ]; 
         then 
            zlogin "$zonename" "yes | pkgadd -d pkg_get.pkg all 2>&1" >> "$cswlog";
         else 
            zlogin "$zonename" "ping -I 1 www.blastwave.org 56 3 > /dev/null 2>&1"
            if [ $? -ne 0 ]
            then
               error_message "The wget command could not connect to www.blastwave.org.\nCheck networking and name resolution."; 
            else
               error_message "The wget command did not run properly.  See the CSW log: $cswlog"; 
            fi
         fi
      fi
   fi

   echo -e "Install md5 package in zone $zonename in order \nto properly verify Blastwave packages..."
   #
   # Install the gnupg and md5 tools to verify Blastwave packages
   #
   zlogin "$zonename" "yes | env \"PATH=$MYPATH\" /opt/csw/bin/pkg-get -i gnupg textutils 2>&1" >> "$cswlog" 
   #
   # Install the Blastwave pgp.key
   #
   zlogin "$zonename" "mkdir -p \"$zonetmpdir\"; env \"PATH=$MYPATH\" wget -q --output-document=\"$zonetmpdir/pgp.key\" http://www.blastwave.org/mirrors.html 2>&1; /opt/csw/bin/gpg --import \"$zonetmpdir/pgp.key\" 2>&1" >> "$cswlog"

   i=0
   while [ $i -lt $r ]
   do
      echo "Installing package \"${pkglist[$i]}\" in zone $zonename..."
      #
      # Install the requested Blastwave packages
      #
      zlogin "$zonename" "yes | env \"PATH=$MYPATH\" /opt/csw/bin/pkg-get -i ${pkglist[$i]} 2>&1" >> "$cswlog"
      i=$(($i+1))
   done
}

##############################################################################
#
# If any parameters were passed evaluate their usage...
#
while getopts a:m:n:y:z:Z:P:E:I:N:B:t:r:w:R:G:d:D:C:s:S:AM:X:Fp:hlL:v OPT
do
   case $OPT in
   a|+a) if [ -z "$OPTARG" ];then error_message "Must provide a valid action with the -a flag";fi
         action="$OPTARG"
         ;;
   m|+m) if [ -z "$OPTARG" ];then error_message "";fi
         ck4arg=`echo $OPTARG | grep "\|"`
         if [ -n "$OPTARG" ] && [ -n "$ck4arg" ]
         then
            curProp[$cnum]=`echo $OPTARG | cut -d'|' -f1`
            newProp[$cnum]=`echo $OPTARG | cut -d'|' -f2`
         else
            curProp[$cnum]=`echo $OPTARG | cut -d'|' -f1`
         fi
         cnum=$(($cnum+1))
         ;;
   n|+n) if [ -z "$OPTARG" ];then error_message "Must provide a zone name with the -n flag";fi
         zonename="$OPTARG"
         prevstate=`zoneadm -z "$zonename" list -p 2> /dev/null | cut -d: -f3`
         ;;
   y|+y) if [ -z "$OPTARG" ];then error_message "Must provide a source zone name with the -y flag";fi
         ck4cloning=`zoneadm 2>&1 | grep clone`
         if [ -z "$ck4cloning" ]
         then
            error_message "The clone feature does not exist on this version of Solaris.";
         fi
         srczonename="$OPTARG"
         ;;
   Z|+Z) if [ -z "$OPTARG" ];then error_message "Must provide a zone directory with the -Z flag";fi
         zonedir="$OPTARG"
         ;;
   z|+z) if [ -z "$OPTARG" ];then error_message "Must provide a base zone directory with the -z flag";fi
         zonepath="$OPTARG"
         ;;
   P|+P) if [ -z "$OPTARG" ];then error_message "Must provide an unencrypted password with the -P flag and the password cannot be null (e.g. \"\")";fi
         rootpw="$OPTARG"
         if [ -f "$rootpw" ]
         then
            rootpw=`cat "$rootpw"`
         fi
         # Encrypt the password
         encrootpw=`/usr/bin/perl -e "print crypt(\"$rootpw\", (('a'..'z', 'A'..'Z', '0'..'9', '.', '/')[int(rand(64))].('a'..'z', 'A'..'Z', '0'..'9', '.', '/')[int(rand(64))]));"`
         ;;
   E|+E) if [ -z "$OPTARG" ];then error_message "Must provide an encrypted password with the -E flag";fi
         encrootpw="$OPTARG"
         if [ -f "$encrootpw" ]
         then
            encrootpw=`cat "$encrootpw"`
         fi
         ;;
   I|+I) if [ -z "$OPTARG" ];then error_message "Must provide a valid IP address, interface, netmask, and host name with the -I flag";fi
         zoneip[$n]=`echo $OPTARG | cut -d'|' -f1`
         zoneif[$n]=`echo $OPTARG | cut -d'|' -f2`
         zonenm[$n]=`echo $OPTARG | cut -d'|' -f3`
         zoneipname[$n]=`echo $OPTARG | cut -d'|' -f4`

         #
         # Do basic sanity check
         #
         if [ -z "${zoneip[$n]}" ] || [ -z "${zoneif[$n]}" ]|| [ -z "${zonenm[$n]}" ]|| [ -z "${zoneipname[$n]}" ]
         then
            error_message "Must specify all four values (\"IP Address|Interface||NetMask|HostName\")\nwhen specifying an IP address for the non-global zone."
         fi

         #
         # Make sure we get a cidr formatted and non-cidr formatted netmask
         #
         ck4noncidr=`echo ${zonenm[$n]} | tr -cd '\.' | wc -c`
         if [ $ck4noncidr -ge 1 ] && [ $ck4noncidr -le 3 ]
         then 
            zonecidrnm[$n]=`nm2cidr ${zonenm[$n]} 2>&1`
         else
            zonecidrnm[$n]="${zonenm[$n]}"
            zonenm[$n]=`cidr2dot ${zonecidrnm[$n]} 2>&1`
         fi

         ck4err=`echo ${zonecidrnm[$n]} | grep Error`
         if [ -n "$ck4err" ]
         then 
            echo "$ck4err" 1>&2
            exit 1
         fi 

         #
         # Validate the specified IP address
         #
         echo -e "Checking to see if the zone IP address (${zoneip[$n]}) is already in use...\c"
         if [ -z "${zoneip[$n]}" ]; then error_message "Must specify a valid IP address with the -I flag."; fi
         ping -I 1 ${zoneip[$n]} 56 3 > /dev/null 2>&1
         if [ $? -eq 0 ]
         then
            echo 
            error_message "The specified zone ip address (${zoneip[$n]}) is already in use.  Please specify an unused IP address."
         else
            echo "IP is available."
         fi

         #
         # Validate the specified network interface
         #
         if [ -z "${zoneif[$n]}" ]; then error_message "Must specify a valid network interface with the -I flag."; fi


         ck4zoneif=`ifconfig ${zoneif[$n]} 2>&1 | grep "no such interface"`
         if [ $? -ne 0 -o -n "$ck4zoneif" ]
         then
            dladm show-link ${zoneif[$n]} &> /dev/null
            if [ $? -eq 0 ]
            then
               if [ -n "$ck4zoneif" ]
               then 
                  info_error_message "Network interface specified (${zoneif[$n]}) does not exist.\nAttempting to plumb that interface."
                  ifconfig ${zoneif[$n]} plumb &> /dev/null
                  if [ $? -eq 0 ]
                  then
                     echo "Plumbed interface for existing link ${zoneif[$n]}"
                  fi
               fi
            else
               #
               # Try to determine if we are using VLAN tagging
               #
               iftype=`echo ${zoneif[$n]} | sed -e "s/e1000g/eONEKg/g" | tr -d "[:digit:]" | sed -e "s/eONEKg/e1000g/g"`
               ifPPA=`echo ${zoneif[$n]} | sed -e "s/e1000g/eONEKg/g" | tr -d "[:alpha:]"`
               if [ $ifPPA -gt 999 ]
               then
                  # interface is VLAN id * 1000 + PPA
                  # this assumes no interface can be numbered higher than 999
                  i=`echo $ifPPA | awk '{print substr($1,length($1) - 2) + 0}'`
                  echo -e "Ridiculously large point of attachment might be a VLAN tagged interface..."
                  echo -e "probably $iftype$i"
                  ck4zoneif=''
                  ck4zoneif=`dladm show-dev $iftype$i 2> /dev/null`
                  if [ $? -ne 0 -o -z "$ck4zoneif" ]
                  then
                     #
                     # plumb the original interface
                     #
                     ifconfig ${zoneif[$n]} plumb 2> /dev/null
                     if [ $? -ne 0 ]
                     then
                        error_message "Could not plumb VLAN tagged interface ${zoneif[$n]} on $iftype$i"
                     else
                        echo "Plumbed VLAN tagged interface ${zoneif[$n]} on $iftype$i"
                     fi
                  else
                     error_message "Derived Physical Device '$iftype$i' does not exist"
                  fi
               else
                  error_message "Interface (${zoneif[$n]}) does not exist"
               fi
            fi
         fi
         #if [ $? -ne 0 ] || [ -z "$ck4zoneif" ];then error_message "Network interface specified (${zoneif[$n]}) does not exist";fi

         #
         # Validate the specified netmask
         #
         if [ -z "${zonenm[$n]}" ]; then error_message "Must specify a valid netmask with the -I flag."; fi
         if [ ${zonecidrnm[$n]} -gt 32  ] || [ ${zonecidrnm[$n]} -lt 0 ]
         then 
            error_message "If using the CIDR netmask format, the value cannot be greater than 32 or less than 0"
         fi 

         #
         # Validate the specified host name
         #
         if [ -z "${zoneipname[$n]}" ]; then error_message "Must specify a valid host name with the -I flag."; fi
         ck4ip=`/usr/bin/getent hosts "${zoneipname[$n]}"| awk '{ print $1 }'`
         if [ -n "$ck4ip" ] && [ "${zoneip[$n]}" != "$ck4ip" ]
         then 
            error_message "The specified host name resolves to an IP address ($ck4ip) that does not match the specified IP address (${zoneip[$n]})."
         fi 
         n=$(($n+1))
         ;;
   N|+N) if [ -z "$OPTARG" ];then error_message "Must provide a valid NFS server name or IP, export directory, and mount directory with the -N flag";fi
         nfshost[$p]=`echo $OPTARG | cut -d'|' -f1`
         nfsexport[$p]=`echo $OPTARG | cut -d'|' -f2`
         nfsmount[$p]=`echo $OPTARG | cut -d'|' -f3`
         nfsoptions[$p]=`echo $OPTARG | cut -d'|' -f4`
         localhost=`hostname`
         if [ "${nfsexport[$p]}" = "$localhost" ]; then error_message "The NFS host cannot be the global-zone.  NFS mounting from the global zone to a non-global zone is not supported.";fi
         p=$(($p+1))
         ;;
   B|+B) if [ -z "$OPTARG" ];then error_message "Must provide valid branding info with the -B flag";fi
         # Make sure that the packages are installed before validating input parameters
         echo -e "Checking to make sure Brandz is installed prior to attempting to create a BrandZ zone.\nIf not installed, see the Brandz site for installation details:\n  http://www.opensolaris.org/os/community/brandz/install"
         ckpkgver SUNWlxr SUNWlxu

         brandname=`echo $OPTARG | cut -d'|' -f1`
         brandsubset=`echo $OPTARG | cut -d'|' -f2`
         brandsrcpath=`echo $OPTARG | cut -d'|' -f3`
         if [ "$brandname" != 'SUNWlx' ]; then error_message "At this time, 'lx' is the only supported brand name."; fi
         case "$brandsubset" in
                 'desktop') true;;
            'applications') true;;
                  'server') true;;
             'development') true;;
                  'system') true;;
                     'all') true;;
                         *) error_message "Valid brand subsets include: desktop, applications, server, development, system, and all";;
         esac
         if [ -r "${brandsrcpath[$r]}" ]; then true; else  error_message "Must specify a valid brand source path to the brand archive/CD."; fi
         ;;
   G|+G) if [ -z "$OPTARG" ];then error_message "Must provide a valid package name with the -G flag";fi
         pkglist[$r]="$OPTARG"
         r=$(($r+1))
         ;;
   t|+t) if [ -z "$OPTARG" ];then error_message "Must specify a valid zone type (w or s) with the -t flag";fi
         zonetype="$OPTARG"
         ;;
   r|+r) if [ -z "$OPTARG" ];then error_message "";fi
         rodirs[$ronum]="$OPTARG"
         ronum=$(($ronum+1))
         ;;
   w|+w) if [ -z "$OPTARG" ];then error_message "";fi
         rwdirs[$rwnum]="$OPTARG"
         rwnum=$(($rwnum+1))
         ;;
   R|+R) if [ -z "$OPTARG" ];then error_message "";fi
         ck4arg=`echo $OPTARG | grep "\|"`
         if [ -n "$OPTARG" ] && [ -n "$ck4arg" ]
         then
            rootHomeDir=`echo $OPTARG | cut -d'|' -f1`
            rootShell=`echo $OPTARG | cut -d'|' -f2`
         else
            rootHomeDir="$OPTARG"
         fi
         ;;
   d|+d) if [ -z "$OPTARG" ];then error_message "";fi
         if [ -n "$domains" ]
         then 
            domains="$domains,$OPTARG"
         else 
            domains="$OPTARG"
         fi
         if [ "$domains" = "local" ]
         then
            if [ -f /etc/resolv.conf ]
            then
               nameservers=`grep nameserver /etc/resolv.conf|sed -e 's/nameserver//' -e 's/ //g'`
               domains=""
               for ns in `echo $nameservers`
               do
                   if [ -z "$domains" ]
                   then
                      domains=$ns
                   else
                      domains="$domains,$ns"
                   fi
               done
               domainname=`grep domain /etc/resolv.conf|sed -e 's/domain//' -e 's/ //g'`
            else 
               error_message "DNS is not configured on global zone."
            fi
         fi
         ;;
   D|+D) if [ -z "$OPTARG" ];then error_message "";fi
         domainname="$OPTARG"
         ;;
   C|+C) if [ -z "$OPTARG" ];then error_message "";fi
         if [ -n "$OPTARG" ] 
         then
            ck4args=`echo "$OPTARG" | tr -cd '|'`
            if [ -n "$ck4args" ] 
            then
               bootstage=`echo $OPTARG | cut -d'|' -f1`
               case "$bootstage" in
                   'pre') pre_files[$prefnum]=`echo $OPTARG | cut -d'|' -f2-`; prefnum=$(($prefnum+1));;
                  'post') post_files[$postfnum]=`echo $OPTARG | cut -d'|' -f2-`; postfnum=$(($postfnum+1));;
                       *) pre_files[$prefnum]=`echo $OPTARG | cut -d'|' -f1-`; prefnum=$(($prefnum+1));;
               esac
                       #*) error_message "Valid arguments for pre/post boot file/directory copies include: pre or post.";;
            else
               pre_files[$prefnum]="$OPTARG"
               prefnum=$(($prefnum+1))
            fi
         fi
         ;;
   s|+s) if [ -z "$OPTARG" ];then error_message "Must provide hardening mode and corresponding hardening mode arguments with the -s flag";fi
         if [ -n "$OPTARG" ] 
         then
            ck4args=`echo "$OPTARG" | grep -v "\|"`
            if [ -n "$ck4args" ] 
            then
               case "$OPTARG" in
                    'enable') hardening_mode='enable'; hardening_args='enable';;
                   'disable') hardening_mode='disable'; hardening_args='disable';;
                    'unlock') hardening_mode='enable'; hardening_args='enable';;
                      'lock') hardening_mode='disable'; hardening_args='disable';;
                           *) error_message "Must provide hardening mode and corresponding hardening mode arguments with the -s flag";;
               esac
            else
               hardening_mode=`echo $OPTARG | cut -d'|' -f1`
               hardening_args=`echo $OPTARG | cut -d'|' -f2-`
            fi
         fi
         ;;
   S|+S) if [ -z "$OPTARG" ];then error_message "Must provide a service name with the -S <service> flag";fi
         ck4arg=`echo $OPTARG | grep "^-"`
         if [ -n "$OPTARG" ] && [ -z "$ck4arg" ]
         then
            services[$snum]="$OPTARG"
            snum=$(($snum+1))
         elif [ -n "$OPTARG" ] && [ -n "$ck4arg" ]
         then
            error_message "Must provide a service name with the -S <service> flag"
         fi
         ;;
   A|+A) autoboot="false";;
   M|+M) zoneminimize="yes"
         if [ "$OPTARG" == 'basic' ] 
         then 
            minimizationfile=''
         elif [ -f "$OPTARG" ] 
         then 
            minimizationfile="$OPTARG"
         else
            error_message "Minimization file $OPTARG does not exist."
         fi
         ;;
   X|+X) if [ -z "$OPTARG" ];then error_message "Must provide a command with the -X \"<cmd> <cmd args>\" flag";fi
         runcmd[$q]="$OPTARG"; 
         q=$(($q+1))
         ;;
   F|+F) forceaction='true';;
   p|+p) if [ -z "$OPTARG" ];then error_message "Must provide valid container resource type and count with the -p flag";fi
         ck4resource=`echo "$OPTARG" | grep "\|"`
         if [ -z "$ck4resource" ]
         then
            error_message "Invalid resource type."
         else
            rtype=`echo $OPTARG | cut -d'|' -f1`
            rcount=`echo $OPTARG | cut -d'|' -f2`
            if [ -n "$rcount" ] && [ $rcount -ge 1 ]
            then
               case $rtype in
                 [cC][pP][uU]) make_cpu_limit $rcount;;
                 [rR][aA][mM]) #make_memory_limit $rcount;;
                               info_error_message "Memory capping is not yet available.";;
                            *) error_message "Invalid resource type.";;
               esac
            else
               error_message "Invalid resource count value."
            fi
         fi
         ;;
   h|+h) usage;;
   l|+l) showlicense;;
   L|+L) if [ -z "$OPTARG" ]; then error_message "Must provide a list of privileges with the -L flag.";fi
         # Check if zone privileges are supported
         ckpkgver SUNWtoo
         strings /usr/sbin/zonecfg | grep limitpriv > /dev/null 2>&1
         if [ $? -ne 0 ];
         then
            error_message "Zone privileges require Nevada build 37 or greater or Solaris 10 11/06 or greater"
         fi
         ck4args=`echo $OPTARG | tr '|' ','`
	 zone_privileges="$ck4args"
         ;;
   v|+v) echo "The Zone Manager (zonemgr) version $version"; exit 0;;
      *) usage;;
   esac
done
shift `expr $OPTIND - 1`


#
# Test the hardening mode
#
if [ -n "$hardening_mode" ] 
then
   case "$hardening_mode" in
    'netservices') true;;
            'sbd') true;;
           'jass') true;;
            'smf') true;;
          'basic') true;;
         'enable') true;;
        'disable') true;;
           'lock') true;;
         'unlock') true;;
                *) error_message "Invalid hardening mode.  Valid hardening modes include the following\n netservices - Secure by Default\n jass - \n smf - Service management facility (SMF) site profile\n basic - Select default or individual SMF and rc scripts to disable.";;
   esac
   if [ -z "$hardening_args" ]
   then
      error_message "Hardening args must be provided with -s flag."
   fi
fi

if [ -d "$zonetmpdir" ]
then
   true
else
   mkdir "$zonetmpdir"
   chmod 700 "$zonetmpdir"
fi

if [ -z "$zonename" ]
then 
   if [ "$action" != 'list' ]
   then 
      error_message "Must provide the zone name"
   fi
fi

#
# Set the hostname of the first IP address
#
if [ -z "${zoneipname[0]}" ]
then
   zoneipname[0]="$zonename"
fi

#
# Verify for supported operating system version
#
osver=`uname -sr`
if [ "$osver" != 'SunOS 5.10' ] && [ "$osver" != 'SunOS 5.11' ] 
then
   error_message "This script will only work on Solaris 10 and later."
fi

#
# Verify that the all core requisite packages are installed
#
ckpkgver ${pkgreqs[*]}

#
# Verify dependencies exist
#
ck4perl=`which perl 2> /dev/null| grep -v "^no perl"`
if [ -z "$ck4perl" ]
then
   error_message "Perl must be installed."
fi

case "$action" in
   'info') zonecfg -z "$zonename" info;;
   'add') add_zone "$zonename";;
   'clone') if [ -z "$srczonename" ]; 
          then 
             error_message "A source zone name must be specified with the -y <zonename> \nwhen cloning a zone."; 
          fi  
          are_you_sure "clone zone $srczonename"
          add_zone "$zonename"
          ;;
   'move') move_zone "$zonename";;
   'detach') detach_zone "$zonename";;
   'attach') attach_zone "$zonename";;
   'del') delete_zone "$zonename"
          fnum=0
          rootHomeDir=''
          ;;
   'list') zoneadm list -cv; files=''; rootHomeDir='';;
   'lock') error_message "The lock action has been moved to the modify action via the \n  -s \"<method>|<method_arguments>\" option";;
   'unlock') error_message "The unlock action has been moved to the modify action via the \n  -s \"<method>|<method_arguments>\" option";;
   'enable') error_message "The enable action has been moved to the modify action via the \n  -s \"<method>|<method_arguments>\" option";;
   'disable') error_message "The enable action has been moved to the modify action via the \n  -s \"<method>|<method_arguments>\" option";;
   'shutdown') 
          # Validate assurance
          are_you_sure "Shutdown Zone"
          zlogin "$zonename" "shutdown -y -g 0 -i 5"; files=''; rootHomeDir=''
          ;;
   'minimize') error_message "The minimize action has been moved to the modify action via the \n  -M \"basic|<file>\" option";;
   'halt') 
          # Validate assurance
          are_you_sure "Halt Zone"
          zoneadm -z "$zonename" halt; files=''; rootHomeDir=''
          ;;
   'boot') zoneadm -z "$zonename" boot; files=''; rootHomeDir='';;
   'reboot') 
          # Validate assurance
          are_you_sure "Reboot Zone"
          zoneadm -z "$zonename" reboot; files=''; rootHomeDir=''
          ;;
   'only') only_my_zones "$zonename";;
   'keep') del_all_but "$zonename";;
   'runcmd') run_in_zones "$zonename";;
   'modify') modify_zone;;
   *) error_message "\"$action\" is not a valid action";;
esac

##############################################################################
#
# Clean up
#
if [ -e "$zonefile" ]
then 
   rm -f "$zonefile" "$zonedir/root$pkgdefaults" "$zonetmpdir/sysidcfg-$zonename" 
fi

##############################################################################
#
# Restart requested services (so that any changes made to will take 
# effect)
#
if [ "$action" == 'add' ]
then
   i=0
   while [[ $i -lt $snum ]]
   do
      if [ "${services[$i]}" = 'reboot' ]
      then
         zoneadm -z "$zonename" reboot
      else
         #
         # Determine if the service is online
         #
         ck4svc=`zlogin "$zonename" "svcs -H \"${services[$i]}\"" | awk '{ print $1 }'`
         if [ "$ck4svc" = 'online' ]
         then
            zlogin "$zonename" "svcadm restart ${services[$i]}"
         else
            echo "Error: Service \"${services[$i]}\" does not exist."
         fi
      fi
      i=$(($i+1))
   done
fi

#
# Recursively copy specified files/directories from global into the 
# non-global zone
#
if [ "$action" == 'add' ] || [ "$action" == 'modify' ]
then
   if [ -n "${post_files[0]}" ]
   then
      copy_files "${post_files[@]}"
   fi
fi

#
# Enable root login via ssh (Proceed with caution!)
#
#sshcfgfile="$zonedir/root/etc/ssh/sshd_config"
#ck4root=`grep -i PermitRootLogin "$sshcfgfile" | awk '{ print $2 }'`
#if [ "$ck4root" != 'yes' ]
#then
#   sed -e "s/PermitRootLogin.*/PermitRootLogin yes/g" "$sshcfgfile" > "$sshcfgfile."
#   mv "$sshcfgfile." "$sshcfgfile"
#   zlogin "$zonename" "svcadm restart svc:/network/ssh"
#fi

#
# Set the end state according to autoboot
#
if [ "$action" == 'add' ] && [ "$autoboot" == 'false' ]
then
   zoneadm -z "$zonename" halt
elif [ "$action" == 'modify' ] && [ "$prevstate" != 'running' ]
then
   if [ -n "$newzonename" ]
   then
      zoneadm -z "$newzonename" halt
   else
      zoneadm -z "$zonename" halt
   fi
fi
