#!/usr/bin/perl 

use strict;

##################################################
###
###    Filename:   haora
###
###    Description:  A simple perl script to replicate
###      within reason the original "haoracle" tool present
###      in Sun Cluster 2.x and missing from SC 3.x
###
###      "Within Reason" means that the previous information
###      from SC 2.x was not all that valuable to us.  This
###      'enhanced' output format is more useful to us.
###
###    EXAMPLE:
###
###     gremlin:ent14> whoami
###     oracle
###     
###     gremlin:ent14> which haoracle
###     no haoracle in /oracle/app/oracle/product/8.1.7.4/bin /usr/bin /etc 
###     /usr/sbin /opt/bin /usr/ccs/bin /sbin /bin /usr/ucb /usr/local/bin 
###     /usr/local/bin /opt/SUNWcluster/bin /dna/bin
###     
###     gremlin:ent14> alias | grep haoracle
###     haoracle='/usr/local/bin/sudo /dna/bin/haoracle'
###     
###     gremlin:ent14> ls -l /dna/bin/haoracle
###     -rwx------   1 root     other    1277380 Nov 17 15:17 /dna/bin/haoracle
###     
###     gremlin:ent14> haoracle list
###     class14db-rg:ONLINE:Failover:FALSE:class14db-srvr-rs:On:class14db-lsnr-rs:On
###     class17db-rg:ONLINE:Failover:FALSE:class17db-srvr-rs:Off:class17db-lsnr-rs:Off
###     
###     gremlin:ent14> haoracle stop class14db-rg
###     Stoping class14db-srvr-rs . . .     Stopped
###     Stoping class14db-lsnr-rs . . .     Stopped
###     class14db-rg:ONLINE:Failover:FALSE:class14db-srvr-rs:Off:class14db-lsnr-rs:Off
###     
###     gremlin:ent14> haoracle start class14db-rg
###     Starting class14db-srvr-rs . . .     Started
###     Starting class14db-lsnr-rs . . .     Started
###     class14db-rg:ONLINE:Failover:FALSE:class14db-srvr-rs:On:class14db-lsnr-rs:On
###     
###     gremlin:ent14>
###     
###
###    Author:  Robert Petty
###             SR. Programmer / Administrator
###             Denver Newspaper Agency
###             rpetty (@) denver newspaper agency dot com
###
###    Changelog:
###
###        11-17-03   RP Original File
###
###        01-30-04   RP Added more verbosity in a "help" operation:
###
###    root@gremlin # perl haora help
###    
###    haora_utility help:
###    usage: 
###      haora_utility help
###      haora_utility list
###      haora_utility start [RG name]
###      haora_utility stop  [RG name]
###      RG name:  name of resource group
###    
###    Fields when using "list" operation:
###            1       rg_name
###            2       rg_state
###            3       rg_mode
###            4       rg_auto_fail_back
###            5       server_rs_name
###            6       server_rs_state
###            7       listener_rs_name
###            8       listener_rs_state
###            ** "rg" refers to a Sun Cluster "Resource Group"
###            ** "rs" refers to a Sun Cluster "Resource" within a Resource Group
###    
###    Example line of "list" operation output:
###    ______1_____:__2___:___3____:__4__:________5________:_6_:________7________:_8_
###    class17db-rg:ONLINE:Failover:FALSE:class17db-srvr-rs:Off:class17db-lsnr-rs:Off
###    
###    root@gremlin #
###
###
##################################################

#  We need to initialize some variables:

# We need to figure out if we were passed an operation and a 
# Resource Group name
my $operation=shift;
my $rgname=shift;

my $message="";
my $ORACLE_SERVER=0;
my $ORACLE_LISTENER=1;

my @rg_names;
my %res_properties;
my %res_states=(
    "ONLINE" => "On" ,
    "OFFLINE" => "Offline",
    "START_FAILED" => "Offline,Start-Failed",
    "STOP_FAILED" => "Online,Stop-Failed",
    "MONITOR_FAILED" => "Monitor-Failed",
    "ONLINE_NOT_MONITORED" => "Off"
   );


if (! ( $operation eq "help" || $operation eq "list" || $operation eq "start" || $operation eq "stop")) {
  $message="--> Missing Operation <--";
  &doUsage;
  exit 1;
} elsif ( $operation eq "help" ) {
  &help;
  exit 0;
} else { 
  if (! ($operation eq "list")) {
    if (! length($rgname) ) {
      $message="--> Missing RG Name <--";
      &doUsage;
      exit 1;
    }
  }
}


#   Get a hash of the resource group params
getHashForSCstat();


# Now do some work...
#  We seem to be OK at this point.  

if ($operation eq "list") {
  &list;
} elsif ( $operation eq "start" ) {
  &start;
} elsif ( $operation eq "stop" ) {
  &stop;
}



exit 0;


###############################################################
#####
#####
#####        Some functions?
#####
#####
###############################################################


##################################################
###
###  subroutine execFetch()
###  Expects:   executable filename (in path or fully qualified)
###  Returns:   Array buffer of output from executed command
###
##################################################
sub execFetch {
  my $exefilename=shift;
  # Hmm, lets allow the passing of parameters, but get the actual
  # filename first and make sure it's executable...
  my $actualfilename=(split(/ /,$exefilename))[0];
  my @buffer=();
  if ( -x $exefilename || -x $actualfilename ) {
    # RUN the file here, cache the output to a tmp file...
    open (IFH, " $exefilename | ") or die(" --> execFetch <--\n"
         ."Unable to open input filename $exefilename for reading\n$!\n");
    while (<IFH>) {
      $buffer[++$#buffer]=$_;
    }
    close(IFH);
    return @buffer;
  } else {
    die " --> fetchfile <--\n$exefilename is not an executable file, operation failed\n";
    return "";
  }
}


##################################################
###
###  subroutine doUsage()
###  Expects:   $message may be given a value prior to call
###  Returns:   Nothing
###
##################################################
sub doUsage {
  print "usage: 
  haora_utility help
  haora_utility list
  haora_utility start [RG name]
  haora_utility stop  [RG name]
  RG name:  name of resource group\n\n";
}


##################################################
###
###  subroutine getHashForSCstat()
###  Expects:   optional $rgname from cmdline
###  Returns:   Nothing Assigns values to $res_properties and @rg_names
###
##################################################
sub getHashForSCstat {

  if (defined($rgname)) { 
    @rg_names=($rgname);
  } else {
    open (SCHA_CLUSTER_GET, "/usr/cluster/bin/scha_cluster_get -O ALL_RESOURCEGROUPS |") or die "Cannot talk to the cluster software.\n";
    while (<SCHA_CLUSTER_GET>) {
      chomp;
      push @rg_names, $_;
    } 
    close (SCHA_CLUSTER_GET);
  }

  if ($#rg_names< 0) { die "No resource group names found.\n"; }
  for (my $index=0;$index<=$#rg_names;$index++) {
    my $in_for_rgname=$rg_names[$index];
    chomp ( $res_properties{$in_for_rgname}{RG}{RG_STATE}= `/usr/cluster/bin/scha_resourcegroup_get -G $in_for_rgname -O RG_STATE`);
    chomp ( $res_properties{$in_for_rgname}{RG}{RG_MODE}= `/usr/cluster/bin/scha_resourcegroup_get -G $in_for_rgname -O RG_MODE`);
    chomp ( $res_properties{$in_for_rgname}{RG}{FAILBACK}= `/usr/cluster/bin/scha_resourcegroup_get -G $in_for_rgname -O FAILBACK`);
    open (SCHA_RESOURCEGROUP_GET, "/usr/cluster/bin/scha_resourcegroup_get -O RESOURCE_LIST -G $in_for_rgname |") 
           or die "Cannot query cluster.\n"; 
    while (<SCHA_RESOURCEGROUP_GET>) {
      # We have the resources spewing now, for each resource, lets get it's properties...
      chomp;
      my $resname=$_;
      my $restype="";
      my $resstate="";
      # We captured the _name_ of the resource, now get it's states and properties
      chomp($restype=`/usr/cluster/bin/scha_resource_get -O TYPE -R $resname`);
      chomp($resstate=`/usr/cluster/bin/scha_resource_get -O RESOURCE_STATE -R $resname`);
      if ($restype =~ m/oracle_server/ ) {
        $res_properties{$in_for_rgname}{$ORACLE_SERVER}{NAME}=$resname;
        $res_properties{$in_for_rgname}{$ORACLE_SERVER}{STATE}=$resstate;
      }
      if ($restype =~ m/oracle_listener/) {
        $res_properties{$in_for_rgname}{$ORACLE_LISTENER}{NAME}=$resname;
        $res_properties{$in_for_rgname}{$ORACLE_LISTENER}{STATE}=$resstate;
      }
    }
    close (SCHA_RESOURCEGROUP_GET);
  }
}



##################################################
###
###  subroutine start_resource()
###  Expects:   Resource Name passed as a parameter
###  Returns:   nothing, Outputs to STDOUT
###
##################################################
sub start_resource {
  my $resource_name=shift;
  print "Starting $resource_name . . .     ";
  my $retvalue=system("/usr/cluster/bin/scswitch -e -M -j $resource_name");
  if ($retvalue != 0) {
    print "FAILED\n";
    alert("Start method failed for $resource_name");
  } else {
    print "Started\n";
  }
}


##################################################
###
###  subroutine stop_resource()
###  Expects:   Resource Name passed as a parameter
###  Returns:   nothing, Outputs to STDOUT
###
##################################################
sub stop_resource {
  my $resource_name=shift;
  print "Stoping $resource_name . . .     ";
  my $retvalue=system("/usr/cluster/bin/scswitch -n -M -j $resource_name");
  if ($retvalue != 0) {
    print "FAILED\n";
    alert("Start method failed for $resource_name");
  } else {
    print "Stopped\n";
  }
}


##################################################
###
###  subroutine alert()
###  Expects:   message string passed as a parameter
###  Returns:   nothing, Outputs message to STDERR
###
##################################################
sub alert {
  my $message=shift;
  print STDERR "ALERT: ".$message."\n";
}


##################################################
###
###  subroutine list()
###  Expects:   getHashForSCstat must be run first
###  Returns:   nothing, prints to STDOUT
###
##################################################
sub list {
  for (my $i=0;$i<=$#rg_names;$i++) {
    my $name=$rg_names[$i];
    my $rgstate=$res_properties{$name}{RG}{RG_STATE};
    my $rgmode=$res_properties{$name}{RG}{RG_MODE};
    my $rgfailback=$res_properties{$name}{RG}{FAILBACK};
    my $servername=$res_properties{$name}{$ORACLE_SERVER}{NAME};
    my $serverstate=$res_states{$res_properties{$name}{$ORACLE_SERVER}{STATE}};
    my $listenername=$res_properties{$name}{$ORACLE_LISTENER}{NAME};
    my $listenerstate=$res_states{$res_properties{$name}{$ORACLE_LISTENER}{STATE}};
    if (length($serverstate) && length($listenerstate)) {
      print
        $name .":". $rgstate .":".
        $rgmode .":". $rgfailback .":".
        $servername .":" . $serverstate .":".
        $listenername .":" . $listenerstate ."\n";
    }
  }
}


##################################################
###
###  subroutine start()
###  Expects:   getHashForSCstat must be run first
###  Returns:   nothing, prints to STDOUT
###
##################################################
sub start {
  #  OK, we can only start a stopped resource so lets look at the states and make sure
  #  we can move forward...
  my $name=$rgname;
  my $rgstate=$res_properties{$name}{RG}{RG_STATE};
  my $rgmode=$res_properties{$name}{RG}{RG_MODE};
  my $rgfailback=$res_properties{$name}{RG}{FAILBACK};
  my $servername=$res_properties{$name}{$ORACLE_SERVER}{NAME};
  my $serverstate=$res_properties{$name}{$ORACLE_SERVER}{STATE};
  my $listenername=$res_properties{$name}{$ORACLE_LISTENER}{NAME};
  my $listenerstate=$res_properties{$name}{$ORACLE_LISTENER}{STATE};

  # Well, probably wrong about this, but I am presuming I can start each
  # resource monitor independantly of the other so we'll do the server
  # first... Then the listener.

  if ($rgstate eq "ONLINE") {
    for ($serverstate) {
      SWITCH: {
        /^OFFLINE$|^START_FAILED$|^ONLINE_NOT_MONITORED$/ && do { start_resource($servername); last SWITCH; };
        /^MONITOR_FAILED$/ && do { alert("Cannot change state of $servername, resource is in $_ state. Notify SA as soon a
s possible!"); };
        print "Cannot start server $servername because $res_states{$_} is not a startable state\n";
      }
    }

    for ($listenerstate) {
      SWITCH: {
        /^OFFLINE$|^START_FAILED$|^ONLINE_NOT_MONITORED$/ && do { start_resource($listenername); last SWITCH; };
        /^MONITOR_FAILED$/ && do { alert("Cannot change state of $servername, resource is in $_ state. Notify SA as soon a
s possible!"); };
        print "Cannot start listener $listenername because $res_states{$_} is not a startable state\n";
      }
    }
    &getHashForSCstat;
    &list;
  } else { alert("Resource Group state is $rgstate, cannot manage!"); }
}


##################################################
###
###  subroutine stop()
###  Expects:   getHashForSCstat must be run first
###  Returns:   nothing, prints to STDOUT
###
##################################################
sub stop {
  #  OK, we can only stop a started resource so lets look at the states and make sure
  #  we can move forward...
  my $name=$rgname;
  my $rgstate=$res_properties{$name}{RG}{RG_STATE};
  my $rgmode=$res_properties{$name}{RG}{RG_MODE};
  my $rgfailback=$res_properties{$name}{RG}{FAILBACK};
  my $servername=$res_properties{$name}{$ORACLE_SERVER}{NAME};
  my $serverstate=$res_properties{$name}{$ORACLE_SERVER}{STATE};
  my $listenername=$res_properties{$name}{$ORACLE_LISTENER}{NAME};
  my $listenerstate=$res_properties{$name}{$ORACLE_LISTENER}{STATE};

  if ($rgstate eq "ONLINE") {
    for ($serverstate) {
      SWITCH: {
        /^ONLINE$|^STOP_FAILED$/ && do { stop_resource($servername); last SWITCH; };
        /^MONITOR_FAILED$/ && do { alert("Cannot change state of $servername, resource is in $_ state. Notify SA as soon a
s possible!"); };
        print "Cannot stop server $servername because $res_states{$_} is not a stopable state\n";
      }
    }

    for ($listenerstate) {
      SWITCH: {
        /^ONLINE$|^STOP_FAILED$/ && do { stop_resource($listenername); last SWITCH; };
        /^MONITOR_FAILED$/ && do { alert("Cannot change state of $servername, resource is in $_ state. Notify SA as soon a
s possible!"); };
        print "Cannot stop listener $listenername because $res_states{$_} is not a stopable state\n";
      }
    }
    &getHashForSCstat;
    &list;
  } else { alert("Resource Group state is $rgstate, cannot manage!"); }
}


##################################################
###
###  subroutine help()
###  Expects:   nothing
###  Returns:   nothing, prints to STDOUT
###
##################################################
sub help {
  print "\n";
  print "haora_utility help:\n";
  &doUsage;
  print "Fields when using \"list\" operation:\n";
  #print "name : rgstate : rgmode : rgfailback : server_rs_name : ";
  #print "server_rs_state : listener_rs_name : listener_rs_state\n";
  print "\t1\trg_name\n";
  print "\t2\trg_state\n";
  print "\t3\trg_mode\n";
  print "\t4\trg_auto_fail_back\n";
  print "\t5\tserver_rs_name\n";
  print "\t6\tserver_rs_state\n";
  print "\t7\tlistener_rs_name\n";
  print "\t8\tlistener_rs_state\n";
  print "\t** \"rg\" refers to a Sun Cluster \"Resource Group\"\n";
  print "\t** \"rs\" refers to a Sun Cluster \"Resource\" within a Resource Group\n";
  print "\n";
  print "Example line of \"list\" operation output:\n";
  print "______1_____:__2___:___3____:__4__:________5________:_6_:________7________:_8_\n";
  print "class17db-rg:ONLINE:Failover:FALSE:class17db-srvr-rs:Off:class17db-lsnr-rs:Off\n\n";
}



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


