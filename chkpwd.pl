#!/usr/local/bin/perl
# Password hacking check script
# Written 4/1/99 by Robert G. Ferrell
# Revised 4/30/99  RGF

$pwd_live = qq(/etc/passwd);
$pwd_cached = qq(usr/users/sysadmin/sa/passwd);
$shd_live = qq(/etc/shadow);
$shd_cached = qq(/usr/users/sysadmin/sa/shadow);
$log_file = qq(/usr/users/sysadmin/sa/chkpwd.log);
$pwd_diff = qx(diff $pwd_live $pwd_cached);
$shd_diff = qx(diff $shd_live $shd_cached);
chomp($date = qx(/bin/date));

if ($pwd_diff ne "") {
        qx(mailx -s "Change in /etc/passwd detected" sysadmin\@myhost.com);
	&log_results;
        }

if ($shd_diff ne "") {
        qx(mailx -s "Change in /etc/shadow detected" sysadmin\@myhost.com);
	&log_results;
        }

sub log_results {
	open(LOG, ">>$log_file") || die "can't open $log_file";
	print LOG "$date\|$pwd_diff\|$shd_diff\n";
	close(LOG);
}

