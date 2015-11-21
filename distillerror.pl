#!/usr/bin/perl
#
# distillerror	- strace/truss error distiller. Runs either truss or strace
#  to troubleshoot a command, then prints a filtered report of the possible
#  problems. 
#
# USAGE: distillerror command
# eg,
#        distillerror ls -l /tmp/blah
#        distillerror some_broken_command
#
# 20-Oct-2003, ver 0.7a beta	(check for newer versions)
#
# Note: This is a first release, there could be bugs. This has been tested
#  on Solaris 9 and Red Hat 7.1.
#
# Warranty: This is freeware, use at your own risk.
#
# 20-Oct-2003	Brendan Gregg	Created this.


$COMPRESS = 1;		# This will compress duplicated lines in the output
			# with a "repeated X times" message.

$command = "@ARGV";	# Pull in the command to run

if ($command =~ /^$|^-h$|^--help$/ ) { &usage(); }



#######################
# --- RUN COMMAND ---
#

#
# --- Linux, strace ---
#
if ($^O eq "linux") {
	#
	#  Run the command, output to $tmpfile
	#
	$tmpfile = "/tmp/.distillerror.$$";
	system("strace -f -ttt -o $tmpfile $command");

	#
	#  Read then delete the file
	#
	open(TMP,"$tmpfile") || die "ERROR: Can't open $tmpfile: $!\n";
	@Lines = <TMP>;
	close TMP;
	unlink("$tmpfile");

	#
	#  Process output
	#
	&strace_Analyse();
	&linux_Prune();
}


#
# --- Solaris, truss ---
#
if ($^O eq "solaris") {
	### Fetch error codes
	&solaris_Codes();

	#
	#  Run the command, output to $tmpfile
	#
	$tmpfile = "/tmp/.distillerror.$$";
	system("truss -fdo $tmpfile $command");

	#
	#  Read then delete the file
	#
	open(TMP,"$tmpfile") || die "ERROR: Can't open $tmpfile: $!\n";
	@Lines = <TMP>;
	close TMP;
	unlink("$tmpfile");

	#
	#  Process output
	#
	&truss_Analyse();
	&solaris_Prune();
}



########################
# --- PRINT OUTPUT ---
#

#
#  Build file error output @Out
#
@Out = ();
print "\nFile Errors\n-----------\n";
foreach $time (sort {$a <=> $b} keys(%Error_file)) {

	### Fetch fields
	$file = $Error_file{$time};
	$type = $Error_file_type{$time};
	$err = $Error_file_err{$time};

	### Add to array @Out
	$line = sprintf "%s %-7s %-49s %s\n",$time,$type,$file,$err;
	push(@Out,$line);
}

#
#  Compress duplicate lines in file error output @Out, and Print
#
$line = ""; $same = 0;
while (1) {
	$old = $line;			# remember previous line
	last if @Out == 0;		# end point, exit if no more
	$line = shift(@Out);		# get next line

	### If no line compression
	if ($COMPRESS == 0) { print $line; next; }

	### Check for line compression
	($line_time,$line_text) = split(' ',$line,2);
	($old_time,$old_text) = split(' ',$old,2);
	if ($old_text ne $line_text) {
		if ($same > 0) {
			print "$old_time   \"      \"   repeated $same times\n";
			$same = 0;
		}
		print $line;
		next;
	}
	$same++;			# count duplicated lines
}

#
#  Print event error output immediately (no compression)
#
print "\nMisc Errors\n-----------\n";
foreach $time (sort {$a <=> $b} keys(%Error_event)) {

	### Fetch values and print
	$call = $Error_event{$time};
	$err = $Error_event_err{$time};
	printf "%s %-57s %s\n",$time,$call,$err;
}

#
#  Print error code messages
#
print "\nError Codes\n-----------\n";
foreach $code (keys(%Codes)) {

	### Fetch values and print
	$message = $Codes{$code};
	next if $message eq "";
	printf "%-7s %s\n",$code,$message;
}

#
#  Print out last 8 lines
#
if (@All < 8) { 
	@Print = @All; 
} else {
	@Print = @All[-8..-1];
}
print "\nLast 8 Lines\n------------\n";
print @Print;



# ---------------------------------------------------------------------------

###############################
# --- ANALYSE SUBROUTINES ---
#

#  These process the @Lines in memory and populate error event hashs with the
#  details, such as %Error_file and %Error_error
#

# strace_Analyse - analyse strace output in memory, build hashs of errors
#
sub strace_Analyse {
   my ($line,$time,$rest,$call,$result,$code,$file,$filename,$type);
   my ($result_full,$start_time);
   my $line_num = 0;

   foreach $line (@Lines) {
	$line_num++;
	chomp($line);

	### Remove PID and whitespace
	$line =~ s/^\s*\d*\s*//;
	
	### Fetch time, remember the first time seen
	($time,$rest) = split(' ',$line,2);
	if ($line_num == 1) { $start_time = $time; }

	### Convert time into time since command invocation
	$time = $time - $start_time;
	$time = sprintf("%.4f",$time);

	### Get system call and result text
	($call,$result) = $rest =~ /^(\w*\(.*?\))\s*(.*)$/;
	$result_full = $result;
	$result =~ s/\s*\(.*\)$//;	# chop off "(...)" message

	### Format line neatly
	push(@All,sprintf("%s %-57s %s\n",$time,$call,$result));

	if ($result =~ /^= -/) {
		#
		#  Process error line
		#

		### Remember this error code was seen
		($code,$message) = $result_full =~ /(\w*)\s*\((.*)\)/;
		$Codes{$code} = $message;

		if ($call =~ /^open|^access|^stat|^fstat|^lstat/) {
			#
			#  Remember that this file failed
			#
			($filename) = $call =~ /[^\"]*\"(.*)\"/;
			($type) = $call =~ /^([^(]*)/;
			$file = $filename;
			$file =~ s:^.*/::;
			$Error_file{$time} = $filename;
			$Error_file_err{$time} = $result;
			$Error_file_type{$time} = $type;
			$Error_file_trys{$file}{$time} = 1;
		} else {
			$Error_event{$time} = $call;
			$Error_event_err{$time} = $result;
		}
	} else {
		#
		#  Process success line
		#
		if ($call =~ /^open|^access|^stat|^fstat|^lstat/) {
			#
			#  Forget if this file previously failed
			#
			($filename) = $call =~ /[^\/]*(\/.*)\"/;
			($type) = $call =~ /^([^(]*)/;
			$file = $filename;
			$file =~ s:^.*/::;
			foreach $try (keys(%{$Error_file_trys{$file}})) {
				delete $Error_file{$try};
				delete $Error_file_err{$try};
				delete $Error_file_type{$try};
				delete $Error_file_trys{$file}{$try};
			}
		}
	}

   }
}



# truss_Analyse - analyse truss output in memory, build hashs of errors
#
sub truss_Analyse {
   my ($line,$time,$rest,$call,$result,$code,$file,$filename,$type);

   foreach $line (@Lines) {
	chomp($line);

	### Remove PID and whitespace
	$line =~ s/^\s*\d*:\s*//;

	### Fetch time, system call, and result text
	($time,$rest) = split(' ',$line,2);
	($call,$result) = $rest =~ /^(\w*\(.*?\))\s*(.*)$/;

	### Format line neatly
	push(@All,sprintf("%s %-57s %s\n",$time,$call,$result));

	if ($result =~ /^Err/) {
		#
		#  Process error line
		#

		### Remember this error code was seen
		($code) = $result =~ /(\w*)$/;
		$Codes{$code} = $CodesAll{$code} || "";
	
		if ($call =~ /^open|^access|^stat|^fstat|^lstat/) {
			#
			#  Remember that this file failed
			#
			($filename) = $call =~ /[^\"]*\"(.*)\"/;
			($type) = $call =~ /^([^(]*)/;
			$file = $filename;
			$file =~ s:^.*/::;
			$Error_file{$time} = $filename;
			$Error_file_err{$time} = $result;
			$Error_file_type{$time} = $type;
			$Error_file_trys{$file}{$time} = 1;
		} else {
			$Error_event{$time} = $call;
			$Error_event_err{$time} = $result;
		}
	} else {
		#
		#  Process success line
		#
		if ($call =~ /^open|^access|^stat|^fstat|^lstat/) {
			#
			#  Forget if this file previously failed
			#
			($filename) = $call =~ /[^\/]*(\/.*)\"/;
			($type) = $call =~ /^([^(]*)/;
			$file = $filename;
			$file =~ s:^.*/::;
			foreach $try (keys(%{$Error_file_trys{$file}})) {
				delete $Error_file{$try};
				delete $Error_file_err{$try};
				delete $Error_file_type{$try};
				delete $Error_file_trys{$file}{$try};
			}
		}
	}

   }
}



#############################
# --- PRUNE SUBROUTINES ---
#

#  These prune through the error event hashs in memory, removing unimportant
#  events. These subroutines can be "tuned" to your liking.
#

# solaris_Prune - Prune errors in memory
#
sub solaris_Prune {
   my ($time,$call,$text);

   foreach $time (keys(%Error_event)) {

	$call = $Error_event{$time};
	$text = $Error_event_err{$time};
	
	### Throw out IOCTL TTY GETA's
	if ($text =~ /ENOTTY$/ && $call =~ /^ioctl.*TCGETA,/) {
		delete $Error_event{$time};
		delete $Error_event_err{$time};
	}
   }

}


# linux_Prune - Prune errors in memory
#
sub linux_Prune {
   my ($time,$call,$text);

   foreach $time (keys(%Error_event)) {

	$call = $Error_event{$time};
	$text = $Error_event_err{$time};
	
	### Throw out IOCTL TTY GETS's
	if ($text =~ /ENOTTY$/ && $call =~ /^ioctl.*TCGETS,/) {
		delete $Error_event{$time};
		delete $Error_event_err{$time};
	}
   }

}



################
# --- MISC ---
#

# solaris_Codes - loads Solaris error codes into a lookup hash
#
sub solaris_Codes {
	my ($line,$code,$message);

	### At least have this
	$CodesAll{"ENOENT"} = "No such file or directory";

	### Reading this file is optional
	open(HFILE,"/usr/include/sys/errno.h") || return;
	
	#
	#  Create a lookup hash %CodesAll for error codes
	#
	while ($line = <HFILE>) {

		next if $line !~ /^#define/;
		
		$code = $message = "";
		($code,$message) = $line =~ 
		 /^#define\s*(\S*)\s*\w*\s*\/\*\s*(.*?)\s*\*\//;
		$CodesAll{$code} = $message if defined $message;
	}

	close HFILE;
}


# usage - Print command usage
#
sub usage {

	print "Version 0.7a beta, 20-Oct-2003
USAGE: distillerror command
eg,
       distillerror ls -l /tmp/blah
       distillerror some_broken_command\n\n";
	exit(0);
}


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


