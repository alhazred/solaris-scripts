#!/usr/bin/perl
use strict;

### Create or Delete a zone under Solaris 10
### Put entry for new zone in global:/etc/hosts before running this script.
### This script will add an entry to your hosts file if you don't have one
###
### Usage: ./zonetool -c    (to create a zone)
###	   ./zonetool -d    (to delete a zone)
###        ./zonetool       (will ask you what you want to do...)
###
#
#   Things to customize:
#   1) zonepath (make sure you have enough space on this device)
my $ZONEPATH="/export/zones";

#   3) Change autoboot if desired
#   4) Add any special directories to mount(lofs) below
#   5) Make any site specific changes to the sysidcfg array below
#   6) Make sparse if you want
#  
###  
### M. Kiefer 1/2006
### Revision: 1.3
###  
### 7/2006: Changed to "use strict" and changed first interface
###	    found to list of interfaces for user to choose from.
###	   
### 7/2006: 1.1 Changed split on /:/ to /: / to allow for aliased interfaces. 
### 7/2006: 1.2 Moved count++ in delete section.
### 8/2006: 1.3 fixed bug in DELETE section (Setting opt to yes to exit while loop)


# This array holds the config file for the zone
my @ZONEDEF=("create -b",
	"set zonepath=${ZONEPATH}/ZONENAME",
	"set autoboot=false",
	### Uncomment this section of the zone config
	### file to configure a lofs mount
#	"add fs",
#	"set dir=/jes",
#	"set special=/export/jes",
#	"set type=lofs",
#	"add options rw",
#	"add options nodevices",
#	"end",
	"add net",
	"set address=ZONEIPADDR/ZONENETMASK",
	"set physical=NETINT",
	"end" );

my $line="";		# Used for file enum
my @SHADOW=();		# Elements of the root shadow entry
my $opt=shift;		# Argument 1 supplied to this script
my $ACT="";		# Action to take (create|delete)
my $pid=$$;		# Processid (used for uniq tmp files)
my $ans="";		# Your Answer

# Grab the encrypted passwd for use in the new zone
open(shad,"/etc/shadow");
while($line=<shad>){
	if ($line =~ /^root:/){
		@SHADOW=split(/:/,$line);
		last;
	}
}
close(shad);

# This array holds the new sysidcfg file 
my @SYSCFG=(
	"system_locale=C",
	"terminal=vt100",
	"network_interface=primary {",
	"\thostname=ZONENAME\n}",
	"security_policy=NONE",
	"name_service=NONE",
	"timezone=US/Eastern",
	"root_password=$SHADOW[1]",
);


# Determine if we are creating or deleting a zone
##############################################################################
if ( "$opt" eq "-c" || "$opt" eq "-d" ){
    $ACT=$opt;
    $ACT=~s/-//;
} else {
    while ("${ACT}" eq "" ){
	print "Do you want to CREATE a zone or DELETE one? [c,d]: ";
	$ans=<STDIN>;
	chomp($ans);
	
	if ("$ans" eq "c" || "$ans" eq "C" ){
		$ACT="c";
	}
	if ("$ans" eq "d" || "$ans" eq "D" ){
		$ACT="d";
	}
    }
}

###############################################################################
###	CREATE 
###############################################################################
my $zname="";		# zonename
my $hent="";		# Used in host file enum
my @host=();		# Elements of a host entry
my $zip="";		# Zone IP

if ($ACT eq "c"){
	print "Enter a name for the new zone: ";
	$zname=<STDIN>;
	chomp($zname);

	# Grab the IP for that zone from /etc/hosts if it is there
	##################################################
	open(HOSTS,"/etc/hosts");
	while ($hent = <HOSTS>){
		next if ($hent =~ /^#/);
		if ($hent =~ /$zname$/ || $hent =~ /$zname./){
			@host=split(/\s+/,"$hent");
			$zip=$host[0];	
			last;
		}
	}
	close(HOSTS);

	# Figure out which interface to use
	##################################################
	my %INTLIST=();		# Interface list
	my $count=0;		# Number of interfaces found
	my $NETINT="";		# Interface to use
	my $JUNK="";		# Junk
	my $zipaddr="";		# Zone IP Address
	my $znetmask="";	# Zone Netmask
	my $key="";		# Used for hash enum

	### populate a hash with interface names
	open(GETINT,"/usr/sbin/ifconfig -a |");
		while($line=<GETINT>){
			if ($line =~ /RUNNING/ && $line !~ /^lo0:/){
	 			($NETINT,$JUNK)=split(/: /,$line);
				$count++;
				$INTLIST{$count}=$NETINT;
			}
		}
	close(GETINT);

	### Choose interface if more than one is plumbed
	if ($count > 1 ){
		$ans=0;
		while ($ans < 1 || $ans > $count ){
			print "Select the interface to use for this zone:\n";

			foreach $key ( sort( keys(%INTLIST))){
				print "  $key:\t$INTLIST{$key}\n";
			}

			print "Enter the number of the interface to use [(1)-$count]:";
			$ans=<STDIN>;
			chomp($ans);
		    	$ans=1 if ( "x$ans" eq "x" );
		}
		$NETINT=$INTLIST{$ans};
	}

	### Get the zones IP address
	print "Enter an IP address for the new zone [$zip]: ";
	$zipaddr=<STDIN>;
	chomp($zipaddr);
	$zipaddr=$zip if ("$zipaddr" eq "");

	### Get the zones netmask
	print "Enter a netmask for the new zone [24]: ";
	$znetmask=<STDIN>;
	chomp($znetmask);
	$znetmask=24 if ("$znetmask" eq "");
	
	# Create the zone config file
	##################################################
	open(A,">/var/tmp/${zname}.cfg");
	foreach $line (@ZONEDEF){
		if ($line =~ /ZONENAME/ ){
			$line =~ s/ZONENAME/$zname/
		}
		if ($line =~ /ZONEIPADDR/){
			$line =~ s/ZONEIPADDR/$zipaddr/
		}
		if ($line =~ /ZONENETMASK/){
			$line =~ s/ZONENETMASK/$znetmask/
		}
		if ($line =~ /NETINT/){
			$line =~ s/NETINT/$NETINT/
		}
		print A "$line\n";
	}
	close(A);

	# Create the sysidcfg 
	##################################################
	open(C,">/tmp/${zname}.sysidcfg");
	foreach $line (@SYSCFG){
		if ($line =~ /ZONENAME/ ){
			$line =~ s/ZONENAME/$zname/
		}
		print C "$line\n";
	}
	close(C);

	open(B,">/tmp/zcrea.$pid");

		if ( "x$host[0]" eq "x" ){
			print B "echo \"$zname\t$zipaddr\" >> /etc/hosts\n";
		}
		print B "echo \"(/usr/sbin/zonecfg -z $zname -f /var/tmp/${zname}.cfg)\"\n";
		print B "/usr/sbin/zonecfg -z $zname -f /var/tmp/${zname}.cfg\n";

		print B "echo \"(/usr/sbin/zoneadm -z $zname install)\"\n";
		print B "/usr/sbin/zoneadm -z $zname install\n";

		print B "cp /tmp/${zname}.sysidcfg ${ZONEPATH}/${zname}/root/etc/sysidcfg\n";
		print B "cp /.bash_profile ${ZONEPATH}/${zname}/root/.bash_profile\n";
		print B "touch ${ZONEPATH}/${zname}/root/etc/.NFS4inst_state.domain\n";

		print B "echo \"(/usr/sbin/zoneadm -z $zname boot)\"\n";
		print B "/usr/sbin/zoneadm -z $zname boot\n";

		print B "rm /tmp/${zname}.sysidcfg\n";
		print B "rm /tmp/zcrea.$pid\n";

	close(B);

	system("sh /tmp/zcrea.$pid");

	
}

###############################################################################
###	DELETE
###############################################################################

if ($ACT eq "d"){

	my $count=0;	# Count of configured zones
	my $idx="";	# zone index number
	my $zname="";	# Zone name
	my $zstate="";	# Zone state
	my $zpath="";	# Zone path
	my $zone="";	# Used to enum @ZONES
	my @ZONES=();	# Array of configured zones
	my @zelem=();	# Elements of a configured zone

	open(ZONES,"/usr/sbin/zoneadm list -cpi |");
		while($line=<ZONES>){
			next if ($line =~ /:global:/ );
			chomp($line);
			$count++;
			($idx,$zname,$zstate,$zpath)=split(/:/,$line);
			push(@ZONES,"$count:$zname:$zstate:$zpath");
		}
	close(ZONES);

	$opt="no";

	if ($count > 0){
		while ($opt eq "no" ){

			print "Which zone do you want to delete?\n";
			foreach $zone (@ZONES){
				(@zelem)=split(/:/,$zone);
				print "\t$zelem[0]) $zelem[1]\n";
			} # End Foreach

			print "Enter a number: ";
			$ans=<STDIN>;
			chomp($ans);

			if ($ans > 0 && $ans <= $count ){
				$opt="yes";
			} # End if
      		} # End While

		foreach $zone (@ZONES){
			($idx,$zname,$zstate,$zpath)=split(/:/,$zone);

			next if ($ans != $idx );

			print "Deleting $zname...\n";
			open(A,">/tmp/zdel.$pid");

	    		if ($zstate eq "running" ){
				print A "/usr/sbin/zoneadm -z $zname halt\n";
	    		}

	    		print A "echo \"(/usr/sbin/zonecfg -z $zname export -f ${zpath}.cfg)\"\n";
	    		print A "/usr/sbin/zonecfg -z $zname export -f ${zpath}.cfg\n";

	    		print A "echo \"(/usr/sbin/zoneadm -z $zname uninstall)\"\n";
	    		print A "/usr/sbin/zoneadm -z $zname uninstall\n";

	    		print A "echo \"(/usr/sbin/zonecfg -z $zname delete -F)\"\n";
	    		print A "/usr/sbin/zonecfg -z $zname delete -F\n";

	    		print A "/bin/rm /tmp/zdel.$pid\n";
			close(A);

			system("sh /tmp/zdel.$pid");

		} # End Foreach
	} else {
		print "No zones to delete...\n";
	} # End if (count)
} # End if (ACT)

exit 0


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


