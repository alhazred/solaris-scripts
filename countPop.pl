#!/usr/local/bin/perl -w

### 
### Counts the number of mails in a POP3 mailbox.
###

### Use the Net module
use Net::POP3;

### Define our POP server
$pop = Net::POP3->new("172.16.0.12") 
	or die "Cant Open connection to mail server\n";
defined ($pop->login("mailbox","password")) 
	or die "Cant get authenticated\n";

### Uncomment as necessary
#$messages = $pop->list or die "Cant list messages\n";
#@message_list=keys(%$messages);
#print "$message_list[-1]\n";
#foreach $i (@message_list){
#	print "$i \n";
#	}
@num_messages=$pop->popstat
	or die "can't find numner of last message\n";
print "$num_messages[0] \n";







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


