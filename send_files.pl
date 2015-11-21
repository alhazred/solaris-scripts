#!/usr/local/bin/perl -w

=head1 NAME

send_files.pl - Transfer files to another server

=cut

use vars qw/$CVS/;

$CVS = q$Id: send_files.pl,v 1.1 2001/08/10 12:24:31 tachien Exp $;

=head1 SYNOPSIS

This script is a command line script that is meant to either be run from
a cronjob or run at user command.

=head1 DESCRIPTION

The script send files to another server from local machine ( same location with this script ) . 
The original intent is bring the Apache web log ( 1 day old ) into different server 
and use Analog software to analyz the web traffic since Analog is CPU and memory intense.

=cut

use Net::FTP;

my $logdir  = '/your/log/directory';
my @filename=`find /your/log/directory -mtime -1 | perl -p -e 's#.*/##'`;
my $ftpfiles=join ( "" , @filename);
my $server='foo.com';
my ($username, $password)= ("your_username", "your_password");
$ftp = Net::FTP->new($server);
$ftp->login("$username","$password");
$ftp->binary;
$ftp->lcd ("$logdir");
$ftp->cd ("$logdir");
$ftp->put("$ftpfiles");
$ftp->quit;

=pod

=head1 SEE ALSO

Net::FTP

=head1 NOTES

This script can run under any users but since you have to put username & password in the clear
text, you may want to setup another operator account for the security concern.

=head1 AUTHOR

=head2 Original Author

Ta Chien <tachien@yahoo.com>

=head2 Contributor

=cut
