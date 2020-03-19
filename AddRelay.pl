#!/usr/bin/perl
#
#
# This Iplanet script adds a client to be relayed. You would typically find this 
# in an ISP invironment where the service provider has to add a client ( a range of Ip's)
# to be added for relaying. 
# The foll needs to be changed 1) The installation directory of Iplanet
#			       2) The Uid of the mail deamon
# any quiries can be forwarded to carlyle@wipro.co.in or carbritto@yahoo.com
#
#
#
#$DIR="/iplanet/ims5p3/msg-smtp1/imta/config" ;
$DIR="/export/isp/bin/test" ;
#$Uid=101 ;
$Uid=1003 ;
$DEFAULTMASK=32 ; 
#
#
#
#
#
$RED="\033[31;1m" ;
$BLUE="\033[34;1m" ;
$BOLD="\033[30;1m" ;
$NORMAL="\033[0m" ;
#$RED="\033[01;31m\c" ;
#$BLUE="\033[01;34m\c"  ;
#$BOLD="\033[01;30m\c" ;
#$NORMAL="\033[0m\c" ;
$Already_done_it=0;
$FORCE=0 ;
$ADDONLY=1 ;
$MASK=$DEFAULTMASK ;
$MAPPINGS="$DIR/mappings" ;
$OMAP="$DIR/OldMappings/" ;
$|=1  ; #Auto flush on 
#
#

sub Ipformat 
{
	$IPFORMAT=0 ;
	if ( $IPADDRESS !~ /^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$/ )
		{ 
		 $IPFORMAT=1 ;
		}
}

sub Maskformat 
{
	$MASKFORMAT=0 ;
	if ( $MASK !~ /^[1-3][0-9]$/ )
		{
		$MASKFORMAT=1 ;
		}
}

sub DuplicateIP
{
	$DUPLICATE=0 ; 
	open(FH , "<$MAPPINGS") || die "Cannot open $MAPPINGS for reading \n" ;
		while (<FH>)
		{
         		if ( index($_ , "$IPADDRESS\/" ) != -1 )	
			{ $DUPLICATE=1 ; break ; } 
		}
	close(FH) ;
}

sub GetConf 
{
$done=0 ;
while ( ! $done )
{
system("/usr/bin/clear") ;



$ipdone=0 ; 
while ( ! $ipdone ) 
{

if ( $IPADDRESS )    { print "IpAddress of the client [$IPADDRESS] :" ; } 
	       	  else 
		     { print "IpAddress of the client : " ; }
chop($TMP=<STDIN>); if ( $TMP )  
		     { $IPADDRESS=$TMP ; }

Ipformat() ;    
if ($IPFORMAT)  { print "$RED The Ipaddress is not of the right format$NORMAL \n" ; $ipdone=0; next ; } 

DuplicateIP() ; 
if ($DUPLICATE) { print "$RED This IP already seems to be used. $BOLD Use it any way [n]:$NORMAL " ; chop($YN=<STDIN>) ;
		  if ( $YN =~ /[Y,y][e,E]{0,1}[S,s]{0,1}/ ) 
		     {$FORCE=1 ; $ipdone=1 ; }else{ $ipdone=0; }
		}
		else
		{ $ipdone=1; }
}



$maskdone=0 ;
while ( ! $maskdone )
{
print "Network mask of the client [$MASK] : " ; 
chop($TMP=<STDIN>); if ( $TMP )
                     { $MASK=$TMP ; }
Maskformat();
if ($MASKFORMAT)  { print "The mask is not of the right format\/value\n" ; }
		  else
		  { $maskdone=1; }

}

if ( $ORIGCOMM ) { print "The name of the client [$ORIGCOMM]: " ; } else { print "The name of the client : " ; }
chop($TMP=<STDIN>); if ( $TMP )
                     { $ORIGCOMM=$TMP ; }
$ADDONLY=1 ; 
print "Do you want to restart the server [n]" ;
chop($YN=<STDIN>) ;
	if ( $YN =~ /[Y,y][e,E]{0,1}[S,s]{0,1}/ )
		{ print "A restart of the server is $BOLD NOT $NORMAL required. The entry will become active even without a restart
Now do you really want to restart [n]: " ;
		chop($YN=<STDIN>) ;
		if ( $YN =~ /[Y,y][e,E]{0,1}[S,s]{0,1}/ ) { $ADDONLY=0 ; $FORRE=$RED ; }else { $FORRE=$NORMAL ; }
		}
		else { $FORRE=$NORMAL ; }

print "Let's see what we have here ...." ; 
sleep(2) ;
system("/usr/bin/clear") ;
if ( ! $ADDONLY ) { $RESTART=YES ; } else { $RESTART=NO ; } 
print " ______________________________________________
$BOLD o The CLients Name 		:$NORMAL $ORIGCOMM
$BOLD o The Clients IP Address	:$NORMAL $IPADDRESS
$BOLD o The Network Mask 		:$NORMAL $MASK
$BOLD o Restart the server		:$FORRE $RESTART
$NORMAL ______________________________________________
$BLUE IS THIS INFORMATION CORRECT [n]:$NORMAL " ; 

chop($YN=<STDIN>) ;
if ( $YN =~ /[Y,y][e,E]{0,1}[S,s]{0,1}/ )
    { $done=1 ;}

}

$COMMENT="$ORIGCOMM Added on $d/$m/$y at $h:$mn" ;
$Already_done_it=1 ;
}
########### Starts from here ###############

if ( $> != $Uid && $> != 0 ) { $name=getpwuid($Uid); print "Hey !!! you are not ROOT or $name \n" ; exit (1) ; }


@ARGU=@ARGV ;
use File::Basename  ;
$THISSCRIPT=basename("$0") ;
$USAGE1="
Usage $THISSCRIPT [ -f ] [ -h ] [ -r ] -I Ipaddress [ -m Subnet Mask ] [ -c \"Clients Name\" ]  
      $THISSCRIPT  -i  [ [ -f ] [ -r ] [ -I Ipaddress] [ -m Subnet Mask ] [ -c \"Clients Name\" ] ] 
where 	Ipaddress	:is the IP Address alloted to the client
	Subnet Mask	:[optional] is the Subnet Mask ( If not mentioned will default to $DEFAULTMASK )
	Clients Name	:[optional] is any comments to be added to the mappings file
	-f		:[optional] Will forcefully add the entry. ie will not check for duplicates
	-r		:[optional] Will restart the server (A cnbuild and refresh will happen irrespective) 
	-h		:[optional] Will show you this usage
	-i		:Will run this script interractively. When used with this 
			 option the other arguments will be considered but are optional.
";

if ( ! -d "$OMAP" ) 
{ 
	if ( system("/usr/bin/mkdir $OMAP 2> /dev/null ") ) 
		{ print "ERROR: Cannot create $OMAP \n"; exit;}  
}

( $m, $d , $y , $h , $mn ) = (localtime)[4,3,5,2,1] ; ++$m ; $y=( $y + 1900 ) ;
use Getopt::Std ;
my %options;
getopts('m:frh:c:I:i', \%options) || die "$USAGE1";
if ($options{m}) { $MASK=$options{m} ; } 
if ($options{f}) { $FORCE=1 ; }
if ($options{r}) { $ADDONLY=0 ; }
if ($options{h}) { print "$USAGE1"; exit;  }
if ($options{c}) {  $ORIGCOMM=$options{c} ; $COMMENT="$options{c} Added on $d/$m/$y at $h:$mn" ;} else { $COMMENT="Added on $d/$m/$y at $h:$mn" ;}
if ($options{I}) { $IPADDRESS=$options{I} ; if ($options{i}) { GetConf(); } }
		 else
		 {
		  if ($options{i}) { GetConf(); } else { print "$USAGE1"; exit; }
		 }

if ( ! $Already_done_it )
{

Ipformat() ;
	if ($IPFORMAT)
		{ 
			print "Error : The IpAddress $IPADDRESS does not seem to be in the right format \n" ;
			exit ;
		}

Maskformat() ;
	if ($MASKFORMAT)
		{
        		print "Error : The Subnet mask  $MASK does not seem to be in the right format \n" ;
        		exit ;
		}

open(FH , "<$MAPPINGS") || die "Cannot open $MAPPINGS for reading \n" ;
if ( ! $FORCE )
{
	while (<FH>)
	{
         		if ( index($_ , "$IPADDRESS\/" ) != -1 )	
				{ 
			print "The IpAdddress $IPADDRESS already exists in the mappings file \nTo forcefully make an entry use\n \t $THISSCRIPT -f @ARGU \n" ;		
			
			#	if (  ! $ORIGCOMM  )
			#		{ print "The IpAdddress $IPADDRESS already exists in the mappings file \nTo forcefully make an entry use\n \t $THISSCRIPT -f -i $IPADDRESS -m $MASK  \n" ; }
			#		else
			#		{ print "The IpAdddress $IPADDRESS already exists in the mappings file \nTo forcefully make an entry use\n \t $THISSCRIPT -f -i $IPADDRESS -m $MASK -c  \"$ORIGCOMM\"  \n" ; }
				close(FH) ;
				exit ; 
				}

	}
}
close(FH) ;

}

if ( system( "/usr/bin/cp $MAPPINGS $OMAP/mappings-\[$d:$m:$y\_$h.$mn\] 2> /dev/null" ) )
{
print "ERROR : Cannot backup $MAPPINGS \n" ;
exit ;
}
open(OFH , ">$MAPPINGS") || die "Cannot open $MAPPINGS for writing \n" ;
open(IFH ,"<$OMAP/mappings-\[$d:$m:$y\_$h.$mn\]") || die "Cannot open $OMAP/mappings-$d:$m:$y\_$h.$mn Wierd this cannot not happen !!!!!!!\n";
while (<IFH>)
{
	if ( $_ =~ /^[ ,\t]*\*[ ,\t]*\$N/ )
		{ print OFH "  \$\($IPADDRESS\/$MASK\)  \$Y \# $COMMENT \n" ;
		}
	
	print OFH "$_" ;		

}
close(OFH) ;
close(IFH) ;


print "Building the configuration .........." ;
if (system("$DIR/../../imsimta cnbuild >/dev/null 2>&1 "))  { print "ERROR: The server could not do a \"cnbuild\" \nRun $DIR/../../imsimta cnbuild manually.... and then refresh the server\n" ; exit(1) ; } else { print "done\n" }

print "Refreshing the server ..............." ;
if (system("$DIR/../../imsimta refresh >/dev/null 2>&1 "))  { print "ERROR: The server could not do a \"refresh\" \nRun $DIR/../../imsimta refresh manually\n";  exit(1) ; } else { print "done\n" }

if ( ! $ADDONLY )
{
print "Stopping the Server.................." ;
if (system("$DIR/../../imsimta stop >/dev/null 2>&1 "))  { print "ERROR: The server could stop  \nRun $DIR/../../imsimta stop manually.... and then restart the server\n"; exit(1) ; } else { print "done\n" ; }
print "Wait for a the server to settle down a bit " ;
for ( $i=0 ; $i<10 ; ++$i ) { print ".."; sleep(1) ; }
print "\nStarting the Server.................." ;
if (system("$DIR/../../imsimta start >/dev/null 2>&1 "))  { print "ERROR: The server could start  \nRun $DIR/../../imsimta start manually to start the server \n" ; exit(1) ;} else { print "done\n" }

}
print "Your backup file is $OMAP/mappings-\[$d:$m:$y\_$h.$mn\] \n" ;
exit ;

