#!/usr/bin/perl
# mail_attatch 1.0 By Steven Ho. 
# This program allows you to send email with attatchments 
# from a text window.  Similar to mailx, or BSD mail command.
# 
# The accepted file names are:
# 1. file with full path, such as /a/b/c/filename
# 2. files in the current directory, such as filename.
# 3. if mimencode exists it uses mimencode, otherwise, use uuencode

$ENV{'PATH'} = "/bin:/usr/sbin:/usr/local/bin:/usr/lib";

$UUENCODE = "uuencode";
$MIMENCODE = "mimencode";
$TESTFILE = "file";
$boundary = "simple boundary";
$WC = "wc";
$CP = "cp";
$UNLINK = "unlink";
$MV = "mv";
$TMP = "/tmp";
$TMPONLY = ".tmponly";
$ENCODED = ".encoded";
$ATTATCH = ".encoded_attatch";
$CONTENT = ".content";
$SENDMAIL = "sendmail";

$en_test = `which mimencode`;
chomp($en_test);
if($en_test !~ /^no mimencode/) {
	$encode_method = "mimencode";
}

if ($#ARGV != 0) {
       print "Usage: mail_attatch recipient\n";
       exit;
}

print "Subject: ";
$_ = <STDIN>;
chop;
$subject_line = $_;
print "Cc: ";
$_ = <STDIN>;
chop;
$Cc = $_;
print "Adding attatchments (input file name one at each line):\n";
print "An empty line means the end of attatchments.\n";
$i = 0;
while($i == 0) {
	print "file: ";
	$_ = <STDIN>;
	chomp;
	if($_ eq "") {
		$i++;
	}
	if(-e $_) {
		push(@ATCH_ARRY, $_);
	}
	else {
		if($_ ne "") {
			print "$_: file not found\n";
		}
	}
}

print "Start input of mail message:\n";
open(MESG, ">$TMP/$CONTENT");
do {
	$_ = <STDIN>;
	chop;
	print MESG $_, "\n" if $_ ne ".";
} until $_ eq ".";
print MESG "\n\n";
close(MESG);

print "Prepare for delivery ... This may take a while...\n";

# Prepare the header of the mail message

$output = `$WC $TMP/$CONTENT`;
($c_line, $c_words, $c_length, $c_name) = split(' ', $output);
open(CODED, ">$TMP/$ATTATCH") || die "can't open $TMP/$ATTATCH";
print CODED "Subject: $subject_line\n";
print CODED "Cc: $Cc\n";
print CODED "MIME-Version: 1.0\n";
print CODED "Content-Type: multipart/mixed; boundary=\"$boundary\"\n";
print CODED "Content-Length: $c_length\n";
print CODED "\n";
print CODED "--$boundary\n";
print CODED "Content-Type: text/plain; charset=ISO-8859-1\n";
# If you enable the following two lines, your message will show
# up as an attachment.
#print CODED "Content-Transfer-Encoding: 7bit\n";
#print CODED "Content-Description: \"Message Content\"\n";
print CODED "\n";

open(RFILE, "$TMP/$CONTENT") || die "can't open $TMP/$CONTENT";
	while(<RFILE>) {
	print CODED $_;
}
close(RFILE);
close (CODED);

# Create a encoded file (with attatchment header) for every
# attatchment.

for(@ATCH_ARRY) {
	if (/\//) { 
		($rv_f_name, @other) = reverse(split('/', $_));
		if (-e $rv_f_name) {
			system("$MV $rv_f_name $TMPONLY");
			system("$CP $_ .");
			$rename = 1;
		}
		else {
			system("$CP $_ .");
			$remove = 1;
		}
	}
	else {
		$rv_f_name = $_;
		$remove = 0;
	}
	if($encode_method eq "mimencode") {
		system("$MIMENCODE -o $TMP/$ENCODED $rv_f_name");
		$encoding = "base64";
	}
	else {
		system("$UUENCODE $rv_f_name $rv_f_name > $TMP/$ENCODED");
		$encoding = "uuencode";
	}
	$output = `$WC $TMP/$ENCODED`;
	($line, $words, $length, $name) = split(' ', $output);

	open(CODED, ">>$TMP/$ATTATCH") || die "can't open $TMP/$ATTATCH";
	open(OLD_CODED, "$TMP/$ENCODED") || die "can't open $TMP/$ENCODED";
	print CODED "--$boundary\n";
	print CODED "Content-Type: application/octet-stream; name=\"$rv_f_name\"\n";
	print CODED "Content-Transfer-Encoding: $encoding\n";
	print CODED "\n";
	while(<OLD_CODED>) {
		print CODED $_;
	}
	print CODED "\n";
	close(OLD_CODED);
	system("$UNLINK $rv_f_name") if $remove == 1;
	system("$MV $TMPONLY $rv_f_name") if $rename == 1;
	$rename = $remove = 0;
}
print CODED "--$boundary--\n";
close(CODED);

#system("$SENDMAIL -v $ARGV[0],$Cc < $TMP/$ATTATCH");
system("$SENDMAIL $ARGV[0],$Cc < $TMP/$ATTATCH");
system("$UNLINK $TMP/$ENCODED");
system("$UNLINK $TMP/$ATTATCH");
system("$UNLINK $TMP/$CONTENT");
print "Sent\n";




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


