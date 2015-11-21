#!/arch/unix/bin/perl
#
# Subnet Calculator
#
# Created by Kirk Vogelsang, Interliant Systems and Security Group
# Thu Mar 29 11:00:34 EST 2001
#
# This was written using Activestate's perl:
#
# This is perl, v5.6.0 built for MSWin32-x86-multi-thread
# (with 1 registered patch, see perl -V for more detail)
#
# and their tk module, along with the Net::Netmask module from CPAN
#

use Tk;
use Tk::DialogBox;
use Net::Netmask;
use strict;

#
# No buffering, bad bad buffering
#
$| = 1;

#
# The MainWindow that everything is contained within
#
my $MW = MainWindow->new;
$MW->title('Kirk\'s Subnet Calculator');

#
# Entries that are modified in &calculate, thus need to have global action
#
my ($ipaddr_ent,$ipaddrhex_ent,$netmask_ent,$netmaskhex_ent,$hostmask_ent,$hostmaskhex_ent,$netmaskbits_ent,$subnetbits_ent,$broadcast_ent,$broadcasthex_ent,$numhosts_ent,$numnets_ent,$firstip_ent,$firstiphex_ent,$ip_list);

#
# Forward decl of subs
#
sub initialize;
sub calculate;
sub about;
sub help;
sub main;

#
# This does all of the GUI initializing.
#
sub initialize {
    my $menu_frame = $MW->Frame(qw/-relief raised 
				-borderwidth 2/)->grid(qw/-sticky ew 
						       -columnspan 2/);
    
    $menu_frame->gridColumnconfigure(qw/1 -weight 1/);
    
    my $mb_File = $menu_frame->Menubutton(qw/-text File 
					  -width 5 
					  -underline 0
					  -tearoff 0/)->grid(qw/-row 0 
							     -column 0/);
    
    my $mb_About = $menu_frame->Menubutton(qw/-text About
					   -anchor e
					   -underline 0/)->grid(qw/-row 0
								-column 2
								-sticky e/);
    $mb_About->command(-label => 'Subnetcalc', -command => sub{about()});
    $mb_About->command(-label => 'Help', -command => sub{helpme()});
    
    $mb_File->command(-label => 'Quit', -command => \&exit);
    
    my $body_frame = $MW->Frame()->grid(qw/-sticky ew/);

    my $classA_text = $body_frame->Label(-text => 'Class A: 1.0.0.0 - 127.255.255.255',
					 -padx => 2,
					 -pady => 5,
					 -relief => 'sunken',
					 )->grid(qw/-row 1
						 -column 1/);
    
    my $classB_text = $body_frame->Label(-text => "Class B: 128.0.0.0 - 191.255.255.255",
					 -padx => 2,
					 -pady => 5,
					 -relief => 'sunken'
					 )->grid(qw/-row 1
						 -column 2/);
    
    my $classC_text = $body_frame->Label(-text => "Class C: 192.0.0.0 - 239.255.255.255",
					 -padx => 2,
					 -pady => 5,
					 -relief => 'sunken'
					 )->grid(qw/-row 1
						 -column 3/);
    


    my $ipaddr_text = $body_frame->Label(-text => "IP Address",
					 -relief => 'raised',
					 -bg => 'darkgrey',
					 -pady => 2,
					 -padx => 5
					 )->grid(-row => 2,
						 -column => 1,
						 -pady => 2,
						 -sticky => 'ew');
    $ipaddr_ent = $body_frame->Entry()->grid(qw/-row 2
					     -column 2
					     -ipadx 25
					     -padx 5/);
    
    $ipaddrhex_ent = $body_frame->Entry()->grid(qw/-row 2
						-column 3
						-ipadx 25
						-padx 5/);
    $ipaddrhex_ent->bindtags([]);
    $ipaddr_ent ->insert('end', '0.0.0.0');
    
    my $netmask_text = $body_frame->Label(-text => "Netmask",
					  -relief => 'raised',
					  -bg => 'darkgrey',
					  -pady => 2,
					  -padx => 5
					  )->grid(-row => 3,
						  -column => 1,
						  -pady => 2,
						  -sticky => 'ew');
    $netmask_ent = $body_frame->Entry()->grid(qw/-row 3
					      -column 2
					      -ipadx 25
					      -padx 5/);
    $netmask_ent->bind('<Return>' => sub{calculate("netmask",$ipaddr_ent->get(),$netmask_ent->get())});
    $netmask_ent->insert('end','255.255.255.255');

    $netmaskhex_ent = $body_frame->Entry()->grid(qw/-row 3
						 -column 3
						 -ipadx 25
						 -padx 5/);
    $netmaskhex_ent->bindtags([]);
    
    my $hostmask_text = $body_frame->Label(-text => "Hostmask",
					   -relief => 'raised',
					   -bg => 'darkgrey',
					   -pady => 2,
					   -padx => 5
					  )->grid(-row => 4,
						  -column => 1,
						  -pady => 2,
						  -sticky => 'ew');
    $hostmask_ent = $body_frame->Entry()->grid(qw/-row 4
						  -column 2
						  -ipadx 25
						  -padx 5/);
    $hostmask_ent->bindtags([]);

    $hostmaskhex_ent = $body_frame->Entry()->grid(qw/-row 4
						-column 3
						-ipadx 25
						-padx 5/);
    $hostmaskhex_ent->bindtags([]);
    
    my $netmaskbits_text = $body_frame->Label(-text => "Netmask Bits",
					      -relief => 'raised',
					      -bg => 'darkgrey',
					      -pady => 2,
					      -padx => 5
					     )->grid(-row => 5,
						     -column => 1,
						     -pady => 2,
						     -sticky => 'ew');
    $netmaskbits_ent = $body_frame->Entry()->grid(qw/-row 5
						     -column 2
						     -ipadx 25
						     -padx 5/);
    $netmaskbits_ent->bind('<Return>' => sub{calculate("netbits",$ipaddr_ent->get(),$netmaskbits_ent->get())});    
    $netmaskbits_ent->insert('end','32');

    my $subnetbits_text = $body_frame->Label(-text => "Subnet Bits",
					     -relief => 'raised',
					     -bg => 'darkgrey',
					     -pady => 2,
					     -padx => 5
					    )->grid(-row => 6,
						    -column => 1,
						    -pady => 2,
						    -sticky => 'ew');
    $subnetbits_ent = $body_frame->Entry()->grid(qw/-row 6
						    -column 2
						    -ipadx 25
						    -padx 5/);
    $subnetbits_ent->bindtags([]);
    
    my $broadcast_text = $body_frame->Label(-text => "Broadcast",
					    -relief => 'raised',
					    -bg => 'darkgrey',
					    -pady => 2,
					    -padx => 5
					   )->grid(-row => 7,
						   -column => 1,
						   -pady => 2,
						   -sticky => 'ew');
    $broadcast_ent = $body_frame->Entry()->grid(qw/-row 7
						   -column 2
						   -ipadx 25
						   -padx 5/);
    $broadcast_ent->bindtags([]);
    
    $broadcasthex_ent = $body_frame->Entry()->grid(qw/-row 7
						-column 3
						-ipadx 25
						-padx 5/);
    $broadcasthex_ent->bindtags([]);
    
    my $numhosts_text = $body_frame->Label(-text => "Number of Hosts",
					   -relief => 'raised',
					   -bg => 'darkgrey',
					   -pady => 2,
					   -padx => 5
					   )->grid(-row => 8,
						   -column => 1,
						   -pady => 2,
						   -sticky => 'ew');
    $numhosts_ent = $body_frame->Entry()->grid(qw/-row 8
					       -column 2
					       -ipadx 25
					       -padx 5/);
    $numhosts_ent->bindtags([]);
    
    my $numnets_text = $body_frame->Label(-text => "Number of Nets",
					  -relief => 'raised',
					  -bg => 'darkgrey',
					  -pady => 2,
					  -padx => 5
					 )->grid(-row => 9,
						 -column => 1,
						 -pady => 2,
						 -sticky => 'ew');
    
    $numnets_ent = $body_frame->Entry()->grid(qw/-row 9
						 -column 2
						 -ipadx 25
						 -padx 50/);
    $numnets_ent->bindtags([]);
    
    my $firstip_text = $body_frame->Label(-text => "Next Avail Address",
					  -relief => 'raised',
					  -bg => 'darkgrey',
					  -pady => 2,
					  -padx => 5
					  )->grid(-row => 10,
						  -column => 1,
						  -pady => 2,
						  -sticky => 'ew');
    
    $firstip_ent = $body_frame->Entry()->grid(qw/-row 10
					      -column 2
					      -ipadx 25
					      -padx 50/);
    $firstip_ent->bindtags([]);
    
    $firstiphex_ent = $body_frame->Entry()->grid(qw/-row 10
						 -column 3
						 -ipadx 25
						 -padx 5/);
    $firstiphex_ent->bindtags([]);
 
    my $cal_button = $MW->Button(-text => 'Calculate',
				 -bg => 'red',
				 -command => sub{calculate("dunno",$ipaddr_ent->get(),$netmask_ent->get(),$netmaskbits_ent->get())}
				 )->grid(qw/-sticky ew
					 -row 11
					 -column 0/);
    
    my $ip_frame = $MW->Frame()->grid(qw/-sticky ew/);
    $ip_list = $ip_frame->Scrolled(qw/Listbox -setgrid true -width 100 -height 10 -scrollbars e/);
    $ip_list->pack(qw/-expand yes -fill both/);
}

#
# Do all the necassary calc's
#
sub calculate {
  my ($switch,$ipaddr,$value1,$value2) = @_;

  my ($nmoct1,$nmoct2,$nmoct3,$nmoct4);
  my ($numnets,$subnetbits,$block,$err);

  if ($switch eq 'dunno') {
      if ($value1 eq '255.255.255.255') {
	  $switch = "netbits";
	  $value1 = $value2;
      } else {
	  $switch = "netmask";
      }
  }

  if ($switch eq 'netmask') {
      $block = new Net::Netmask($ipaddr,$value1);
      ($nmoct1,$nmoct2,$nmoct3,$nmoct4) = split /\./,$value1;
  } elsif ($switch eq 'netbits') {
      $block = new Net::Netmask("$ipaddr/$value1");
      ($nmoct1,$nmoct2,$nmoct3,$nmoct4) = split /\./,$block->mask();
  }

  
#
# I'm sure some swift base2 could do this in a line or two, but I'm not
# that smart
#
  if (($nmoct2==255)&&($nmoct3==0)){$numnets=254;$subnetbits=8}
  elsif (($nmoct3==255)&&($nmoct4==0)){$numnets=254;$subnetbits=8}
  elsif ($nmoct2 != 255) {
    if ($nmoct2==192){$numnets=2;$subnetbits=2;print "here\n";}
    elsif ($nmoct2==224){$numnets=6;$subnetbits=3}
    elsif ($nmoct2==240){$numnets=14;$subnetbits=4}
    elsif ($nmoct2==248){$numnets=30;$subnetbits=5}
    elsif ($nmoct2==252){$numnets=62;$subnetbits=6}
    else {$numnets="INVALID NETMASK FOR CLASS A";$err=1}
  } elsif ($nmoct3!=255) {
    if ($nmoct3==192){$numnets=2;$subnetbits=2}
    elsif ($nmoct3==224){$numnets=6;$subnetbits=3}
    elsif ($nmoct3==240){$numnets=14;$subnetbits=4}
    elsif ($nmoct3==248){$numnets=30;$subnetbits=5}
    elsif ($nmoct3==252){$numnets=62;$subnetbits=6}
    else {$numnets="INVALID NETMASK FOR CLASS B";$err=1}
  } elsif ($nmoct4!=255) {
    if ($nmoct4==192){$numnets=2;$subnetbits=2}
    elsif ($nmoct4==224){$numnets=6;$subnetbits=3}
    elsif ($nmoct4==240){$numnets=14;$subnetbits=4}
    elsif ($nmoct4==248){$numnets=30;$subnetbits=5}
    elsif ($nmoct4==252){$numnets=62;$subnetbits=6}
    else {$numnets="INVALID NETMASK FOR CLASS C";$err=1}
  } else {$numnets="INVALID NETMASK";}

#
# Check for errors in $block before trying to snorkle data from it.
# Otherwise, netmask.pm will lay the smack down on your roody-poo
# candy bum(tm)
#
  if ($err == 1) { 
      $numnets_ent->delete(0,'end');
      $numnets_ent->insert('end',$numnets);
      return;
  }

  $numnets_ent->delete(0,'end');
  $numnets_ent->insert('end',$numnets);

  $subnetbits_ent->delete(0,'end');
  $subnetbits_ent->insert('end',$subnetbits);

  $ipaddrhex_ent->delete(0,'end');
  $ipaddrhex_ent->insert('end',sprintf "%x.%x.%x.%x", split /\./,$ipaddr);

  $netmaskhex_ent->delete(0,'end');
  $netmaskhex_ent->insert('end',sprintf "%x.%x.%x.%x", $nmoct1,$nmoct2,$nmoct3,$nmoct4);

  $hostmask_ent->delete(0,'end');
  $hostmask_ent->insert('end',$block->hostmask());

  $hostmaskhex_ent->delete(0,'end');
  $hostmaskhex_ent->insert('end',sprintf "%x.%x.%x.%x",split /\./,$block->hostmask());

  if ($switch eq "netmask") {
      $netmaskbits_ent->delete(0,'end');
      $netmaskbits_ent->insert('end',$block->bits());
  }

  if ($switch eq "netbits") {
      $netmask_ent->delete(0,'end');
      $netmask_ent->insert('end',$block->mask());
  }

  $broadcast_ent->delete(0,'end');
  my $broadcast = $block->broadcast();
  $broadcast_ent->insert('end',$broadcast);

  $broadcasthex_ent->delete(0,'end');
  $broadcasthex_ent->insert('end',sprintf "%x.%x.%x.%x", split /\./,$broadcast);

  $numhosts_ent->delete(0,'end');
  $numhosts_ent->insert('end',$block->size());

  $firstip_ent->delete(0,'end');
  my $firstip = $block->next();
  $firstip_ent->insert('end',$firstip);

  $firstiphex_ent->delete(0,'end');
  $firstiphex_ent->insert('end',sprintf "%x.%x.%x.%x", split /\./,$firstip);

  my @ips = $block->enumerate();

  $ip_list->delete(0,'end');
  $ip_list->insert('end',@ips);
}

#
# A little About dialog action
#
sub about {
    my $about_dialog = $MW->DialogBox(-title => 'About Subnetcalc', -buttons => ['Dismiss']);
    
    my $about_message = "Subnetcalc was written by Kirk Vogelsang, ";
    $about_message .= "Interliant Systems and Security Group,\n";
    $about_message .= "on Thu Mar 29 11:00:34 EST 2001 ";
    $about_message .= "because he is was bored one day.\n\n";
    $about_message .= "kirk\@interliant.com";
    $about_dialog->add('Label')->grid;
    $about_dialog->Subwidget('label')->Label(-justify => 'left', -text => "$about_message")->grid;
    $about_dialog->Show;
}

#
# A little Help puppy
#
sub helpme {
  my $help_dialog = $MW->DialogBox(-title => 'Using Subnetcalc', -buttons => ['Dismiss']);
    
    my $help_message = 'Kirk\'s Innovative Help System: (patent pending)';
    $help_message .= "\n\n\t1\) Open this script with your favorite text editor\n";
    $help_message .= "\t2\) Snarf through the code\n";
    $help_dialog->add('Label')->grid;
    $help_dialog->Subwidget('label')->Label(-justify => 'left', -text => "$help_message")->grid;
    $help_dialog->Show;
}

#
# Nuff said
#
sub main {
  &initialize;
  MainLoop;
}

#
# Do the above
#
&main;


