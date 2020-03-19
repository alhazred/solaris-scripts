#!/usr/bin/env perl
#
# @(#) memconf - Identify sizes of SIMM/DIMM memory modules installed on a
# @(#)           Sun SPARC or HP-UX workstation or server.
# @(#) Micron Technology, Inc. - Tom Schmidt 13-Feb-2006 V1.65
#
# Maintained by Tom Schmidt (tschmidt@micron.com)
#
#   If memconf does not recognize a system, then please E-mail the output of
#   'memconf -v', '/usr/sbin/prtconf -pv' (or '/usr/etc/devinfo -pv' on Solaris
#   1.X) and '/usr/platform/`uname -i`/sbin/prtdiag -v' if available to
#   tschmidt@micron.com so that memconf can be enhanced to recognize it.
#   If the unrecognized system is a Sun clone, please also send any hardware
#   documentation on the memory layout that you may have. Check my website
#   at http://www.4schmidts.com/unix.html to get the latest version of memconf.
#
# Usage: memconf [ -v | -D | -h ] [explorer_dir]
#                  -v            verbose mode
#                  -D            E-mail results to memconf maintainer
#                  -h            print help
#                  explorer_dir  Sun Explorer output directory
#
# memconf reports the size of each SIMM/DIMM memory module installed in a
# system. It also reports the system type and any empty memory sockets.
# In verbose mode, it also reports:
#  - banner name, model and CPU/system frequencies
#  - address range and bank numbers for each module
#
# memconf is Y2K compliant. There are no date calls in the program. Your
# Operating System or Perl version may not be Y2K compliant.
#
# memconf is free software; you can redistribute it and/or modify it under
# the terms of the GNU General Public License as published by the Free
# Software Foundation; either version 2 of the License, or (at your option)
# any later version.
#
# Original version based on SunManagers SUMMARY by Howard Modell
# (h.modell@ieee.org) on 29-Jan-1997.
#
# Tested to work on:
# - sun4c Sun SS1, SS2, IPC, IPX, ELC with Open Boot PROM V2.X
# - sun4m Sun 4/6x0, SS4, SS5, SS10, SS20, LX/ZX, Classic, Voyager, JavaEngine1
# - sun4d Sun SPARCserver-1000, 1000E, SPARCcenter-2000, 2000E
# - sun4u Sun Ultra 1, 2, 5, 10, 30, 60, 450
# - sun4u Sun Ultra Enterprise 220R, 250, 450
# - sun4u Sun Ultra Enterprise 3000, 3500, 4000/5000, 4500/5500, 6000, 6500
# - sun4u1 Sun Ultra Enterprise 10000
# - sun4u Sun SPARCengine Ultra AX, AXi, AXmp, AXmp+, AXe
# - sun4u Sun SPARCengine CP 1400, CP 1500
# - sun4u Sun Netra t1 100/105, t1120/1125, ft1800, X1, T1 200, AX1105-500, 120
# - sun4u Sun Netra 20 (Netra T4)
# - sun4u Sun Netra ct400, ct800
# - sun4u Sun Blade 100, 150, 1000, 1500, 2000 and 2500
# - sun4u Sun Fire 280R
# - sun4u Sun Fire 3800, 4800, 4810, and 6800
# - sun4u Sun Fire V100, V120, V210, V240, V250, Netra 240, V440, and Netra 440
# - sun4u Sun Fire V480, V490, V880 and V890
# - sun4u Sun Fire 12000, 15000
# - sun4u Sun Fire V1280 and Netra 1280 (Netra T12)
# - sun4u Sun Fire E2900
# - sun4u Sun Fire B100s Blade Server
# - sun4v Sun Fire T2000
# - sun4m Tatung COMPstation 5, 10, 20AL, 20S and 20SL clones
# - sun4m transtec SPARCstation 20I clone
# - sun4m Rave Axil-255 SPARCstation 5 clone
# - sun4m Rave Axil-245, 311 and 320 clones (no verbose output)
# - sun4u AXUS Ultra 250
# - sun4u Tatung COMPstation U2, U60 and U80D clones
# - Force Computers SPARC clones (no verbose output)
# - Tadpole SPARCbook 3 and RDI PowerLite-170 (no verbose output)
# - Tadpole VoyagerIIi
# - Tadpole (Cycle) 3200 CycleQUAD Ultra 2 upgrade motherboard
# - Tadpole (Cycle) UP-520-IIi SPARCstation 5/20 upgrade motherboard
# - Tadpole SPARCle
# - Auspex 7000/650 (no verbose output)
# - Fujitsu S-4/10H, S-4/20L and S-4/20H clones (no verbose output)
# - Fujitsu GP7000 and GP7000F
# - Fujitsu Siemens PrimePower 200, 400, 600, 800, 1000 and 2000
# - Fujitsu Siemens PrimePower 250, 450, 650, and 850
# - Fujitsu Siemens PrimePower 900, 1500, 2500 and HPC2500
# - Twinhead TWINstation 5G and 20G
# - Detects VSIMMs for SX graphics on SS10SX/SS20 (1st VSIMM only)
# - Detects Prestoserve NVSIMMs on SS10/SS20/SS1000/SC2000
#
# Untested systems that should work:
# - sun4c Sun SS1+ with Open Boot PROM V2.X
# - sun4m Tatung COMPstation 20A clone
# - sun4u Sun Fire E4900, E6900, E20K, E25K
# - sun4v Sun Fire T1000
# - May not work properly on Sun clones
#
# Won't work on:
# - sun4u Sun Ultra 80, Ultra Enterprise 420R, and Netra t1400/1405.
#   Not enough information is provided about the memory in the prtconf and
#   prtdiag outputs by the Open Boot PROM.
# - Systems without /dev/openprom
# - sun4c Sun SS1, SS1+, SLC, IPC with Open Boot PROM V1.X (no 'memory' lines
#   in devinfo/prtconf output)
# - sun4 kernel architecture, and sun3 and older systems
# - i86pc Solaris on Intel-based (x86) machines only show total memory
# - Perl 5.001 is known to have problems with hex number conversions
# - Does not detect unused VSIMMs (another FB installed) or second VSIMM
#
# To Do list and Revision History can be found on the maintainers web site at
# http://www.4schmidts.com/unix.html

# Uncomment for debugging (perl 5 only)
#use diagnostics;

$version="V1.65";
$version_date="13-Feb-2006";
$URL="http://www.4schmidts.com/unix.html";
$ENV{PATH}="/usr/sbin:/bin:/usr/bin:/usr/ucb:/usr/local/bin:/var/local/bin:$ENV{PATH}";
$_=$];
$^W=1; # Enables -w warning switch, put here for SunOS4 compatibility.
($PERL_VERSION_MAJOR)=/(\d).*/;
if ($PERL_VERSION_MAJOR < 5) {
	($PERL_VERS)=/(\d\.\d)/;
	($PERL_PATCH)=/(\d*)$/;
	$PERL_PATCH="0$PERL_PATCH" if ($PERL_PATCH < 10);
	$PERL_VERSION="$PERL_VERS$PERL_PATCH";
} else {
	($PERL_VERSION)=/(\d\.\d{3}).*/;
}

$uname="/usr/bin/uname";
$uname="/bin/uname" if (-x '/bin/uname');
if (-x $uname) {
	$hostname=&mychomp(`$uname -n`);
	$machine=&mychomp(`$uname -m`);
	$operating_system=&mychomp(`$uname`);
	$osrel=&mychomp(`$uname -r`);
	$platform=$machine;
} else {
	$hostname="";
	$machine="";
	$operating_system="this unsupported";
	$osrel="";
}
$prtdiag_cmd="";
$prtdiag_exec="";
$have_prtdiag_data=0;
$prtfru_cmd="";
$have_prtfru_data=0;
$prtpicl_cmd="";
$have_prtpicl_data=0;
if (-d '/usr/platform') {
	$platform=&mychomp(`$uname -i`);
	if (-x "/usr/platform/$platform/sbin/prtdiag") {
		$prtdiag_cmd="/usr/platform/$platform/sbin/prtdiag";
	} elsif (-x "/usr/platform/$machine/sbin/prtdiag") {
		$prtdiag_cmd="/usr/platform/$machine/sbin/prtdiag";
	}
} elsif (-x '/usr/kvm/prtdiag') {
	$platform=$machine;
	$prtdiag_cmd='/usr/kvm/prtdiag';
}
if ($prtdiag_cmd ne "") {
	if (-x $prtdiag_cmd) {
		# Force C locale so that prtdiag output is in English
		$prtdiag_exec="/bin/sh -c 'LC_ALL=C $prtdiag_cmd'";
	}
}
$buffer="";
$filename="";
$memory_size="";
$installed_memory=0;
$failed_memory=0;
$spare_memory=0;
$failing_memory=0;
$ultra=0;
$simmbanks=0;
$simmspergroup=1;
$bankcnt=0;
$slot0=0;
$smallestsimm=16777216;
$largestsimm=0;
$found8mb=0;
$found16mb=0;
$found32mb=0;
$found10bit=0;
$found11bit=0;
$foundbank1or3=0;
$sxmem=0;
$nvmem=0;
$nvmem1=0;
$nvmem2=0;
$memtype="SIMM";
$sockettype="socket";
$verbose=0;
$recognized=1;
$untested=1;
$untested_type="";
$perlhexbug=0;
$exitstatus=0;
$meg=1048576;
@socketstr=("");
@orderstr=("");
@groupstr=("");
@bankstr=("");
@banksstr=("");
$bankname="banks";
@bytestr=("");
@slotstr=("");
$simmrangex=0;
$simmrange=1;
$start1x="";
$stop1x="";
@simmsizes=(0,16777216);
@simmsizesfound=();
@memorylines=("");
$socket="";
$order="";
$group="";
$slotnum="";
$bank="";
$dualbank=0;
$byte="";
$gotmemory="";
$gotmodule="";
$gotmodulenames="";
$gotcpunames="";
$gotcpuboards="";
$slotname0="";
@boards_cpu="";
@boards_mem="";
$empty_banks="";
$banks_used="";
$nvsimm_banks="";
$boardslot_cpu=" ";
$boardslot_cpus=" ";
@boardslot_cpus=();
$boardslot_mem=" ";
$boardslot_mems=" ";
@boardslot_mems=();
$boardfound_cpu=0;
$boardfound_mem=0;
$prtdiag_has_mem=0;
$prtdiag_banktable_has_dimms=0;
$prtdiag_failed=0;
$prtconf_warn="";
$flag_cpu=0;
$flag_mem=0;
$format_cpu=0;
$format_mem=0;
$foundname=0;
$sockets_used="";
$sockets_empty="";
$sortslots=1;
$devtype="";
$interleave=0;
$stacked=0;
$freq=0;
$sysfreq=0;
$cpufreq=0;
$cputype="";
@cpucnt=();
$ncpu=0;	# remains 0 if using prtdiag output only
$multithread=0;
$header_shown=0;
$romver="";
$romvernum="";
$SUNWexplo=0;
$banner="";
$bannermore="";
$cpubanner="";
$diagbanner="";
$model="";
$modelmore="";
$BSD=1; # Initially assume SunOS 4.X
$config_cmd="/usr/etc/devinfo -pv";
$config_command="devinfo";
$config_permission=0;
$permission_error="";
$HPUX=0;
$devname="";	# Sun internal development code name
$clone=0;
$totmem=0;

#
# Parse options
#
if ($#ARGV >= 0) {
	foreach $name (@ARGV) {
		if ($name eq "-v") {
			# verbose mode
			$verbose=1;
		} elsif ($name eq "-d") {
			# more verbose debug mode
			$verbose=2;
		} elsif ($name eq "-D") {
			# E-mail information of system to maintainer
			$verbose=3;
			open(MAILFILE, ">/tmp/memconf.output") || die "can't open /tmp/memconf.output: $!";
			print MAILFILE "Output from 'memconf -d' on $hostname\n";
			print MAILFILE "----------------------------------------------------\n";
			close(MAILFILE);
			open(STDOUT, "| tee -a /tmp/memconf.output") || die "can't open /tmp/memconf.output: $!";
			print "Gathering memconf data to E-mail to maintainer. Please wait...\n";
		} elsif (-f "$name/sysconfig/prtconf-vp.out") {
			# Sun Explorer output
			$SUNWexplo=1;
			open(FILE, "<$name/sysconfig/prtconf-vp.out");
			@config=<FILE>;
			close(FILE);
			if (-f "$name/sysconfig/prtdiag-v.out") {
				open(FILE, "<$name/sysconfig/prtdiag-v.out");
				@prtdiag=<FILE>;
				$have_prtdiag_data=1;
				close(FILE);
			}
			if (-f "$name/fru/prtfru_-x.out") {
				open(FILE, "<$name/fru/prtfru_-x.out");
				@prtfru=<FILE>;
				$have_prtfru_data=1;
				close(FILE);
			}
			if (-f "$name/sysconfig/prtpicl-v.out") {
				open(FILE, "<$name/sysconfig/prtpicl-v.out");
				@prtpicl=<FILE>;
				$have_prtpicl_data=1;
				close(FILE);
			}
			if (-f "$name/sysconfig/uname-a.out") {
				open(FILE, "<$name/sysconfig/uname-a.out");
				$uname=&mychomp(<FILE>);
				close(FILE);
				@unamearr=split(/\s/, $uname);
				$hostname=$unamearr[1];
				$machine=$unamearr[4];
				$osrel=$unamearr[2];
				$platform=$unamearr[6];
				$prtdiag_cmd="/usr/platform/$platform/sbin/prtdiag";
			} else {
				if ($config[0] =~ /System Configuration:/) {
					@machinearr=split(/\s+/, $config[0]);
					$machine=$machinearr[4];
				}
				$osrel="";
				$hostname="";
			}
			if (-f "$name/sysconfig/prtconf-V.out") {
				open(FILE, "<$name/sysconfig/prtconf-V.out");
				$romver=&mychomp(<FILE>);
				close(FILE);
			}
			$filename="$name";
		} elsif (-f $name) {
			# Test file with prtconf/devinfo output
			open(FILE, "<$name");
			@config=<FILE>;
			close(FILE);
			# Test file may also have prtdiag and other output
			@prtdiag=@config;
			@prtfru=@config;
			@prtpicl=@config;
			$hostname="";
			if ($config[0] =~ /System Configuration:/) {
				@machinearr=split(/\s+/, $config[0]);
				$machine=$machinearr[4];
			}
			$osrel="";
			# Special case for testing LinuxSPARC files
			$operating_system="Linux" if ($name =~ /prtconf.Linux/);
			$filename="$name";
		} else {
			&show_help;
		}
	}
}
if ($filename eq "") {
	if ("$operating_system" eq "HP-UX") {
		$HPUX=1;
		if (-x '/usr/sbin/cstm') {
			&hpux_cstm;
		} else {
			&show_supported;
		}
	} elsif ("$operating_system" eq "Linux") {
		&show_supported if (-e '/dev/openprom');
	} elsif ("$operating_system" ne "SunOS") {
		&show_supported;
	}
	if (-f '/vmunix') {
		# SunOS 4.X (Solaris 1.X)
		$BSD=1;
		if (! -x '/usr/etc/devinfo') {
			print "ERROR: no 'devinfo' command. Aborting.\n";
			exit 1;
		}
		$config_cmd="/usr/etc/devinfo -pv";
		$config_command="devinfo";
	} else {
		# Solaris 2.X or later
		$BSD=0;
		if (! -x '/usr/sbin/prtconf') {
			print "ERROR: no 'prtconf' command. Aborting.\n";
			exit 1;
		}
		$config_cmd="/usr/sbin/prtconf -pv";
		$config_command="prtconf";
	}
}
$kernbit="";
$hasprtconfV=0;
$solaris="";
if ($osrel eq "4.1.1") { $solaris="1.0"; }
if ($osrel eq "4.1.2") { $solaris="1.0.1"; }
if ($osrel =~ /4.1.3/) { $solaris="1.1"; }
if ($osrel eq "4.1.3_U1") { $solaris="1.1.1"; }
if ($osrel eq "4.1.4") { $solaris="1.1.2"; }
if ($osrel =~ /5./) {
	$osminor=$osrel;
	$osminor=~s/5.//;
	$release="";
	if ($SUNWexplo == 1) {
		if (-f "$filename/etc/release") {
			open(FILE, "<$filename/etc/release");
			$release=<FILE>;
			close(FILE);
		}
	} else {
		if (-f '/etc/release') {
			open(FILE, "</etc/release");
			$release=<FILE>;
			close(FILE);
		}
	}
	if ($release =~ "Solaris") {
		$release=~s/\s+//;
		$release=&mychomp($release);
		$solaris="$release";
	}
	if ($osminor =~ /[7-9]|1[0-9]/) {
		$hasprtconfV=1;
		$solaris=$osminor if ($solaris eq "");
		$kernbit=32;
		$cpuarch="";
		if ($SUNWexplo == 1) {
			if (-f "$filename/sysconfig/isainfo.out") {
				open(FILE, "<$filename/sysconfig/isainfo.out");
				$cpuarch=<FILE>;
				close(FILE);
			} elsif (-f "$filename/sysconfig/isainfo-kv.out") {
				open(FILE, "<$filename/sysconfig/isainfo-kv.out");
				$cpuarch=<FILE>;
				close(FILE);
			}
		} elsif (-x '/bin/isainfo') {
			$cpuarch=`/bin/isainfo -k`;
		}
		if ($cpuarch =~ /sparcv9/) {
			$kernbit=64;
		}
	} elsif ($osminor =~ /[4-6]/) {
		$hasprtconfV=1;
		$solaris="2.$osminor" if ($solaris eq "");
	} else {
		$solaris="2.$osminor";
	}
	if ("$machine" eq "i86pc" & $osminor =~ /[0-5]/) {
		# x86 Solaris 2.5.1 and earlier has different syntax than SPARC
		$hasprtconfV=0;
		$config_cmd="/usr/sbin/prtconf -v";
	}
}
if ($filename eq "") {
	@config=`$config_cmd 2>&1`;
	if ($hasprtconfV) {
		# Solaris 2.4 or later
		$romver=&mychomp(`/usr/sbin/prtconf -V 2>/dev/null`);
		@romverarr=split(/\s/, $romver);
		$romvernum=$romverarr[1];
	} else {
		# Solaris 2.3 or older
		# Try to use sysinfo if installed to determine the OBP version.
		# sysinfo is available from http://www.MagniComp.com/sysinfo/
		close(STDERR);
		$romver=`sysinfo -show romver 2>/dev/null | tail -1`;
		open(STDERR);
		if ($romver eq "") {
			# Assume it is old
			$romver="2.X" if ($machine =~ /sun4/);
		} else {
			$romver=&mychomp($romver);
			@romverarr=split(/\s/, $romver);
			$romver=$romverarr[$#romverarr];
		}
		$romvernum=$romver;
	}
}

sub show_help {
	if ("$operating_system" eq "HP-UX") {
		$config_cmd="echo 'selclass qualifier memory;info;wait;infolog'|/usr/sbin/cstm";
	} elsif (-x '/usr/sbin/prtconf') {
		# Solaris 2.X or later
		$config_cmd="/usr/sbin/prtconf -pv";
		$prtfru_cmd='/usr/sbin/prtfru' if (-x '/usr/sbin/prtfru');
		$prtpicl_cmd='/usr/sbin/prtpicl' if (-x '/usr/sbin/prtpicl');
	}
	print "Usage: memconf [ -v | -D | -h ] [explorer_dir]\n";
	print "                 -v            verbose mode\n";
	print "                 -D            E-mail results to memconf maintainer\n";
	print "                 -h            print help\n";
	print "                 explorer_dir  Sun Explorer output directory\n";
	print "\nThis is memconf, $version $version_date\n\nCheck my website ";
	print "at $URL to get the latest\nversion of memconf.\n\n";
	if ("$operating_system" ne "HP-UX" & "$operating_system" ne "SunOS") {
		&show_supported;
	}
	print "Please send bug reports and enhancement requests along with ";
	print "the output of the\nfollowing commands to tschmidt\@micron.com ";
	print "as E-mail attachments so that memconf\ncan be enhanced. ";
	print "You can do this using the 'memconf -D' command if this system\n";
	print "can E-mail to the Internet.\n";
	print "    $config_cmd\n";
	print "    $prtdiag_cmd -v\n" if ($prtdiag_exec ne "");
	print "    $prtfru_cmd -x\n" if ($prtfru_cmd ne "");
	print "    $prtpicl_cmd -v\n" if ($prtpicl_cmd ne "");
	exit;
}

sub show_header {
	if ($header_shown == 1) {
		return;
	}
	$header_shown=1;
	undef %saw;
	@saw{@simmsizesfound}=();
	@simmsizesfound=sort numerically keys %saw;
	print "memconf:  $version $version_date $URL\n" if ($verbose);
	print "hostname: $hostname\n" if ($hostname);
	if ($filename) {
		if ($SUNWexplo == 1) {
			print "Sun Explorer directory: $filename\n";
		} else {
			print "filename: $filename\n";
		}
	}
	if ($banner) {
		# See if banner includes CPU information
		if ($banner !~ /\(.*SPARC/ & $banner !~ /MHz/) {
			@cputypecnt=keys(%cpucnt);
			$x=0;
			while (($cf,$cnt) = each(%cpucnt)) {
				$x++;
				$cf=~/^(.*) (.*)$/;
				$ctype=$1;
				$cfreq=$2;
				$cpubanner .= "$cnt X " if ($cnt > 1);
				if ($ctype =~ /390Z5/) {
					if ($cfreq > 70) {
						$cpubanner .= "SuperSPARC-II";
					} else {
						$cpubanner .= "SuperSPARC";
					}
				} elsif ($ctype =~ /MB86907/) {
					$cpubanner .= "TurboSPARC-II";
				} elsif ($ctype =~ /MB86904/ | $ctype =~ /390S10/) {
					if ($cfreq > 70) {
						$cpubanner .= "microSPARC-II";
					} else {
						$cpubanner .= "microSPARC";
					}
				} elsif ($ctype =~ /L2A0925/) {
					$cpubanner .= "microSPARC-IIep";
				} elsif ($ctype =~ /,RT62[56]/) {
					$cpubanner .= "hyperSPARC";
				} else {
					$cpubanner .= "$ctype";
				}
				$cpubanner .= " ${cfreq}MHz" if ($cfreq);
				$cpubanner .= ", " if ($x < scalar(@cputypecnt));
			}
		} elsif ($banner =~ /\(/ & $banner !~ /MHz/) {
			# CPU listed without speed
			while (($cf,$cnt) = each(%cpucnt)) {
				$cf=~/^(.*) (.*)$/;
				$cfreq=$2;
				$banner=~s/\)/ ${cfreq}MHz\)/g if ($cfreq);
			}
		}
	}
	if ($verbose) {
		if ($banner) {
			print "banner:   $banner";
			print " $bannermore" if ($bannermore);
			print " ($cpubanner)" if ($cpubanner);
			print "\n";
		}
		if ($model) {
			print "model:    ";
			print "$manufacturer " if ($manufacturer);
			print "$model";
			print " $modelmore" if ($modelmore);
			print " $realmodel" if ($realmodel);
			print "\n";
		}
		if ($devname ne "" & ! $clone) {
			print "Sun development name: $devname\n";
		}
		if ($filename eq "" | $SUNWexplo == 1) {
			if ($solaris) {
				print "Solaris " if ($solaris !~ /Solaris/);
				print "${solaris}, ";
			}
			print "${kernbit}-bit kernel, " if ($kernbit);
			print "${operating_system} ${osrel}\n";
		} elsif ($HPUX) {
			print "HP-UX\n";
		} elsif ("$operating_system" eq "Linux") {
			print "Linux SPARC\n" if (-e '/dev/openprom');
		} elsif ($BSD) {
			print "Solaris 1.X, SunOS 4.X\n";
		} else {
			print "Solaris 2.X, SunOS 5.X\n";
		}
		if ($ncpu > 0) {
			@cputypecnt=keys(%cpucnt);
			$x=0;
			while (($cf,$cnt) = each(%cpucnt)) {
				$x++;
				$cf=~/^(.*) (.*)$/;
				$ctype=$1;
				$cfreq=$2;
				print "$cnt $ctype";
				print " ${cfreq}MHz" if ($cfreq > 0);
				print " cpu";
				print "s" if ($cnt > 1);
				print ", " if ($x < scalar(@cputypecnt));
			}
			if ($sysfreq) {
				print ", ";
			} else {
				print "\n";
			}
		}
		print "system freq: ${sysfreq}MHz\n" if ($sysfreq);
	} else {
		if ($manufacturer) {
			if ($manufacturer ne "" & $banner !~ /^$manufacturer/) {
				print "$manufacturer ";
			}
		}
		if ($cpubanner ne "" & $bannermore ne "") {
			print "$banner $bannermore ($cpubanner)";
		} elsif ($cpubanner ne "" & $modelmore ne "") {
			print "$model $modelmore ($cpubanner)";
		} elsif ($cpubanner) {
			print "$banner ($cpubanner)";
		} elsif ($bannermore) {
			print "$banner $bannermore";
		} elsif ($modelmore) {
			print "$model $modelmore";
		} elsif ($banner) {
			print "$banner";
		} elsif ($diagbanner) {
			print "$diagbanner";
		} elsif ($model) {
			print "$model";
		}
		print " $realmodel" if ($realmodel);
		print "\n";
	}
	# debug output
	if ($verbose > 1) {
		print "manufacturer = $manufacturer\n" if ($manufacturer);
		if ($banner) {
			print "banner = $banner\n";
		} else {
			print "diagbanner = $diagbanner\n" if ($diagbanner);
		}
		print "cpubanner = $cpubanner\n" if ($cpubanner);
		print "bannermore = $bannermore\n" if ($bannermore);
		print "model = $model\n" if ($model);
		print "modelmore = $modelmore\n" if ($modelmore);
		print "machine = $machine\n" if ($machine);
		print "platform = $platform\n" if ($platform);
		print "ultra = $ultra\n" if ($ultra);
		if ($ultra eq "AXi") {
			print "found10bit = $found10bit\n";
			print "found11bit = $found11bit\n";
		}
		print "motherboard = $motherboard\n" if ($motherboard);
		print "romver = $romver\n" if ($romver);
		print "perl version: $]\n";
		print "memory line: $gotmemory\n" if ($gotmemory);
		print "module info: $gotmodule\n" if ($gotmodule);

		# Fujitsu GP7000F and PrimePower systems
		print "cpu name info: $gotcpunames\n" if ($gotcpunames);
		print "cpu board info: $gotcpuboards\n" if ($gotcpuboards);
		print "module name info: $gotmodulenames\n" if ($gotmodulenames);

		print "simmsizes = @simmsizes\n" if ($simmsizes[0] > 0);
		print "simmsizesfound = @simmsizesfound\n" if ($simmsizesfound[0]);
	}
	if ($verbose >= 1 & $boardfound_cpu == 1) {
		if ($format_cpu == 1) {
			if ($model =~ /-Enterprise/ | $ultra eq "e") {
				print "CPU Units: Frequency Cache-Size Version\n";
			}
		} else {
			print "CPU Units:\n";
		}
		if ($model ne "SPARCserver-1000" & $model ne "SPARCcenter-2000") {
			print @boards_cpu;
			print "Memory Units:\n";
		}
	}
	if ($interleave) {
		print "Memory Interleave Factor = " . $interleave . "-way\n";
	}
}

sub show_unrecognized {
	if ($perlhexbug) {
		print "       This is most likely because Perl V$PERL_VERSION";
		print " is buggy in hex number\n       conversions. Please";
		print " upgrade your perl release to Perl V5.002 or later\n";
		print "       for best results.\n";
	} else {
		print "       This is most likely because memconf $version";
		print " does not completely\n";
		print "       recognize this $operating_system $osrel $platform system.\n";
		&show_request if ($untested == 0);
	}
}

sub show_untested {
	if ($untested_type eq "OS") {
		print "WARNING: This is an untested $operating_system $osrel operating";
	} elsif ($untested_type eq "OBP") {
		print "ERROR: This is an untested $operating_system $osrel OBP $romvernum";
	} elsif ($untested_type eq "CPU") {
		print "ERROR: This is an untested CPU type on this $operating_system $osrel";
	} else {
		print "ERROR: This is an untested $operating_system $osrel";
	}
	print " system by memconf $version\n";
	print "       Please let the author know how it works.\n";
	$exitstatus=1;
	&show_request;
}

sub show_request {
	print "       Check my website at $URL\n";
	print "       for a newer version of memconf that may recognize this ";
	print "system better.\n";
	print "       Please run 'memconf -D' if this system can E-mail to ";
	print "the Internet\n       or send the output of the following ";
	print "commands manually to Tom Schmidt\n       (tschmidt\@micron.com)";
	print " so that memconf $version can be enhanced to\n       properly ";
	print "recognize this system:\n";
	print "            memconf -d\n            $config_cmd\n";
	print "            $prtdiag_cmd -v\n" if ($prtdiag_exec ne "");
	print "            $prtfru_cmd -x\n" if ($prtfru_cmd ne "");
	print "            $prtpicl_cmd -v\n" if ($prtpicl_cmd ne "");
	if ($untested) {
		print "       If this system is a Sun clone, ";
		print "please also send any hardware\n       documentation ";
		print "on the memory layout that you may have.\n";
	}
}

sub show_supported {
	print "memconf:  $version $version_date $URL\n";
	print "ERROR: memconf $version is not supported on $operating_system";
	print" $machine systems.\n       memconf is supported on:\n";
	print "           SunOS 4.X or 5.X (Solaris) on SPARC\n";
	print "           Linux on SPARC with sparc-utils and /dev/openprom\n";
	print "           most HP-UX systems with Support Tools Manager (cstm)\n";
	print "       memconf may be able to process Sun Explorer data on this";
	print " machine.\n";
	print "       Check my website at $URL\n";
	print "       for a newer version of memconf that may recognize this ";
	print "system better.\n";
	exit 1;
}

sub check_model {
	if ($filename ne "") {
		$platform=$model;
		$platform="SUNW,Ultra-5_10" if ($diagbanner =~ /Sun Ultra 5\/10/);
		$platform="SUNW,Sun-Fire" if ($diagbanner =~ /Sun Fire [346]8[01]0\b/ | $diagbanner =~ /Sun Fire E[246]900\b/);
		$platform="SUNW,Sun-Fire-15000" if ($diagbanner =~ /Sun Fire E2[05]K\b/);
		$platform=~s/-S$//g if ($model =~ /Sun-Blade-[12]500-S\b/);
		$prtdiag_cmd="/usr/platform/$platform/sbin/prtdiag" if ($prtdiag_cmd =~ /platform/);
	}
	$model=~s/SUNW,//g;
	$model=~s/TWS,//g;
	$model=~s/CYCLE,//g;
	$model=~s/Tadpole_//g;
	$model=~s/ASPX,//g;
	$model=~s/PFU,//g;
	$model=~s/FJSV,//g;
	$model=~s/CompuAdd //g;
	$model=~s/RDI,//g;
	if ($ultra eq 0) {
		$ultra="ultra" if ($model =~ /Ultra/ | $model =~ /Blade/ | $model =~ /Fire/);
	}
	$ultra="sparc64" if ($model =~ /SPARC64/);
	$ultra="e" if ($model =~ /-Enterprise/);
	$ultra=1 if ($model =~ /Ultra-1\b/);
	$ultra=2 if ($model =~ /Ultra-2\b/);
	$ultra=5 if ($model =~ /Ultra-5\b/);
	$ultra="5_10" if ($model =~ /Ultra-5_10\b/);
	$ultra=30 if ($model =~ /Ultra-30\b/);
	$ultra=60 if ($model =~ /Ultra-60\b/);
	$ultra=80 if ($model =~ /Ultra-80[\b\/]/);
	$ultra=250 if ($model =~ /Ultra-250\b/);
	$ultra=450 if ($model =~ /Ultra-4\b/);
	$ultra="Netra t1" if ($banner =~ /Netra t1\b/);
	if ($model =~ /Ultra-4FT\b/) {
		$ultra="Netra ft1800";
		$bannermore="(Netra ft1800)";
		$modelmore="(Netra ft1800)";
	}
	$ultra="Sun Blade 1000" if ($model =~ /Ultra-100\b/); # prototype
	$ultra="Sun Blade 1000" if ($model =~ /Sun-Blade-1000\b/);
	$ultra="Sun Blade 2000" if ($model =~ /Sun-Blade-2000\b/);
	$ultra="Netra 20" if ($model =~ /Netra-20\b/);
	$ultra="Netra 20" if ($model =~ /Netra-T4\b/);
	# E2900/E4900 also use Netra-T12
	$ultra="Netra T12" if ($model =~ /Netra-T12\b/ & $ultra !~ /Sun Fire/);
	$ultra="Sun Blade 100" if ($model =~ /Grover\b/); # prototype
	$ultra="Sun Blade 100" if ($model =~ /Sun-Blade-100\b/);
	$ultra="Sun Fire 280R" if ($model =~ /Enterprise-820R\b/); # prototype
	$ultra="Sun Fire 280R" if ($model =~ /Sun-Fire-280R\b/);
	$ultra="Sun Fire" if ($model =~ /Serengeti\b/); # prototype
	$ultra="Sun Fire" if ($model eq "Sun-Fire" | $model =~ /Sun-Fire-[346]8[01]0\b/);
	$ultra="Sun Fire V480" if ($model =~ /Sun-Fire-480R\b/);
	$ultra="Sun Fire V490" if ($model =~ /Sun-Fire-V490\b/);
	$ultra="Sun Fire V880" if ($model =~ /Sun-Fire-880\b/);
	$ultra="Sun Fire V890" if ($model =~ /Sun-Fire-V890\b/);
	# Sun Fire 12K system identifies itself as Sun Fire 15K
	$ultra="Sun Fire 15K" if ($model =~ /Sun-Fire-15000\b/);
	$ultra="Sun Fire 12K" if ($model =~ /Sun-Fire-12000\b/);
	$ultra="Serverblade1" if ($model =~ /Serverblade1\b/);
	# UltraSPARC-IIIi (Jalapeno) systems
	$ultra="Enchilada" if ($model =~ /Enchilada\b/); # prototype
	$ultra="Enchilada" if ($model =~ /Sun-Fire-V210\b/);
	$ultra="Enchilada" if ($model =~ /Sun-Fire-V240\b/);
	$ultra="Enchilada" if ($model =~ /Netra-240\b/);
	$ultra="Sun Fire V440" if ($model =~ /Sun-Fire-V440\b/);
	$ultra="Netra 440" if ($model =~ /Netra-440\b/);
	$ultra="Sun Fire V250" if ($model =~ /Sun-Fire-V250\b/);
	$ultra="Sun Blade 1500" if ($model =~ /Sun-Blade-1500\b/);
	$ultra="Sun Blade 2500" if ($model =~ /Sun-Blade-2500\b/);
	if ($model =~ /Sun-Blade-[12]500-S\b/) {
		$model=~s/-S$//g;
		$modelmore="(Silver)" if ($banner !~ /\(Silver\)/);
	}
	# UltraSPARC-IV or UltraSPARC-IV+ (Panther) systems
	$ultra="Sun Fire E2900" if ($model =~ /Sun-Fire-E2900\b/);
	$ultra="Sun Fire E4900" if ($model =~ /Sun-Fire-E4900\b/);
	$ultra="Sun Fire E6900" if ($model =~ /Sun-Fire-E6900\b/);
	$ultra="Sun Fire E20K" if ($model =~ /Sun-Fire-E20K\b/);
	$ultra="Sun Fire E25K" if ($model =~ /Sun-Fire-E25K\b/);
	# UltraSPARC-T1 (Niagara) systems
	if ($model =~ /Sun-Fire-T200\b/) {
		$ultra="Sun Fire T2000";
		$modelmore="($ultra)";
	}
	$ultra="Sun Fire T1000" if ($model =~ /Sun-Fire-T1000\b/);
	# Older SPARCstations
	$modelmore="SPARCstation SLC" if ($model eq "Sun 4/20");
	$modelmore="SPARCstation ELC" if ($model eq "Sun 4/25");
	$modelmore="SPARCstation IPC" if ($model eq "Sun 4/40");
	$modelmore="SPARCstation IPX" if ($model eq "Sun 4/50");
	$modelmore="SPARCstation 1" if ($model eq "Sun 4/60");
	$modelmore="SPARCstation 1+" if ($model eq "Sun 4/65");
	$modelmore="SPARCstation 2" if ($model eq "Sun 4/75");
	$modelmore="(SPARCsystem 600)" if ($model =~ /Sun.4.600/ & $banner !~ /SPARCsystem/);
	$modelmore="Sun 4/30" if ($model =~ /SPARCstation-LX/);
	$modelmore="Sun 4/15" if ($model =~ /SPARCclassic/);
	$modelmore="Sun 4/10" if ($model =~ /SPARCclassic-X/);
	$modelmore="(SPARCstation 10SX)" if ($model =~ /Premier-24/);
	if ($model eq "S240") {
		$manufacturer="Sun";
		$modelmore="SPARCstation Voyager";
	}
	# x86
	if ($model eq "i86pc") {
		$modelmore="(Solaris on Intel-based (x86) machine)";
		$cputype="x86";
		if ($filename eq "") {
			if (-x '/usr/sbin/psrinfo') {
				$ncpu=`/usr/sbin/psrinfo | wc -l`;
				$ncpu=~s/\s+//;
				$ncpu=&mychomp($ncpu);
				@psrinfo=`/usr/sbin/psrinfo -v`;
				if ($psrinfo[2] =~ /MHz/) {
					$cpufreq=$psrinfo[2];
					$cpufreq=~s/.+ operates at //;
					$cpufreq=~s/ MHz.+//;
					$cpufreq=&mychomp($cpufreq);
				}
			}
		}
		$ncpu++;
		$cpucnt{"$cputype $cpufreq"}++;
	}
	# Clones
	if ($banner =~ /\bMP-250[(\b]/) {
		$ultra="axus250";
		$bannermore="Ultra-250";
		$modelmore="(Ultra-250)";
	}
	$manufacturer="AXUS" if ($ultra =~ /axus/);
	if ($model =~ /SPARC CP/) {
		$manufacturer="Force Computers";
	}
	if ($model eq "S3GX") {
		$bannermore="(SPARCbook 3GX)";
		$modelmore="(SPARCbook 3GX)";
	}
	if ($model eq "S3XP") {
		$bannermore="(SPARCbook 3XP)";
		$modelmore="(SPARCbook 3XP)";
	}
	$manufacturer="Sun" if ($model =~ /^SPARCstation/ |
		$model =~ /^SPARCsystem/ | $model =~ /^SPARCclassic/ |
		$model =~ /^SPARCserver/ | $model =~ /^SPARCcenter/ |
		$model =~ /Enterprise/ | $model =~ /Premier 24/);
	if ($model =~ /Auspex/) {
		$manufacturer="Auspex";
		$model=~s/Auspex //g;
		$bannermore="Netserver";
		$modelmore="Netserver";
	}
	if ($model =~ /S-4/ | $model eq "GP" | $model =~ /^GPUS/) {
		$manufacturer="Fujitsu" if ($manufacturer eq "");
		$model=~s,_,/,g;
	}
	if ($model =~ /PowerLite-/) {
		$bannermore=$model;
		$bannermore=~s/PowerLite-//g;
	}
}

sub check_banner {
	if ($ultra eq 0) {
		$ultra="ultra" if ($banner =~ /Ultra/ | $banner =~ /Blade/ | $banner =~ /Fire/);
	}
	$ultra="sparc64" if ($banner =~ /SPARC64/);
	$ultra=5 if ($banner =~ /Ultra 5\b/);
	$ultra="5_10" if ($banner =~ /Ultra 5\/10\b/);
	$ultra=10 if ($banner =~ /Ultra 10\b/);
	$ultra="220R" if ($banner =~ /Enterprise 220R\b/);
	# E410 is prototype name of E420R, but may still be in the
	# banner as "Sun Ultra 80/Enterprise 410 UPA/PCI"
	$ultra="420R" if ($banner =~ /Enterprise 410\b/);
	$ultra="420R" if ($banner =~ /Enterprise 420R\b/);
	$ultra="Netra t140x" if ($banner =~ /Netra t 1400\/1405\b/);
	$ultra="cp1400" if ($banner =~ /Ultra CP 1400\b/);
	$ultra="cp1500" if ($banner =~ /Ultra CP 1500\b/);
	$ultra="Sun Blade 1000" if ($banner =~ /Sun Excalibur\b/); # prototype
	$ultra="Sun Blade 2000" if ($banner =~ /Sun Blade 2000\b/);
	$ultra="Netra ct400" if ($banner =~ /Netra ct400\b/);
	$ultra="Netra ct800" if ($banner =~ /Netra ct800\b/);
	$ultra="Sun Blade 150" if ($banner =~ /Sun Blade 150\b/);
	# Sun Fire 12K system identifies itself as Sun Fire 15K
	$ultra="Sun Fire 12K" if ($banner =~ /Sun Fire 12000\b/ | $banner =~ /Sun Fire 12K\b/);
	if ($banner =~ /Ultra 4FT\b/) {
		$ultra="Netra ft1800";
		$bannermore="(Netra ft1800)";
		$modelmore="(Netra ft1800)";
	}
	# UltraSPARC-IV or UltraSPARC-IV+ (Panther) systems
	$ultra="Sun Fire E2900" if ($banner =~ /Sun Fire E2900\b/);
	$ultra="Sun Fire E4900" if ($banner =~ /Sun Fire E4900\b/);
	$ultra="Sun Fire E6900" if ($banner =~ /Sun Fire E6900\b/);
	$ultra="Sun Fire E20K" if ($banner =~ /Sun Fire E20K\b/);
	$ultra="Sun Fire E25K" if ($banner =~ /Sun Fire E25K\b/);
	# Clones
	if ($banner =~ /\bMP-250[(\b]/) {
		$ultra="axus250";
		$bannermore="Ultra-250";
		$modelmore="(Ultra-250)";
	}
	$manufacturer="AXUS" if ($ultra =~ /\baxus\b/);
	$manufacturer="Rave" if ($banner =~ /Axil/);
	$manufacturer="Tadpole/Cycle" if ($banner =~ /Cycle/ | $banner =~ /\bUP-20\b/ | $banner =~ /\b520IIi\b/);
	$manufacturer="Tadpole" if ($banner =~ /Tadpole/ | $banner =~ /\bRDI\b/ | $banner =~ /\bVoyagerIIi\b/ | $banner =~ /\bSPARCLE\b/);
	$manufacturer="Tatung" if ($banner =~ /COMPstation/);
	$manufacturer="Twinhead" if ($banner =~ /TWINstation/);
	$manufacturer="Fujitsu" if ($banner =~ /Fujitsu/);
	$manufacturer="Fujitsu Siemens" if ($banner =~ /Fujitsu Siemens/);
	# Only add "Sun" to those that don't already have it
	$manufacturer="Sun" if ($banner =~ /^SPARCstation/ |
		$banner =~ /^SPARCsystem/ | $banner =~ /^SPARCclassic/ |
		$banner =~ /^SPARCserver/ | $banner =~ /^SPARCcenter/ |
		$banner =~ /Enterprise/ | $banner =~ /Premier 24/);
}

sub check_for_prtdiag {
	return if ("$prtdiag_exec" eq "" & $filename eq "");
	return if ($have_prtdiag_data == 1);
	@prtdiag=`$prtdiag_exec 2>&1` if ($filename eq "");
	$have_prtdiag_data=1;
	foreach $line (@prtdiag) {
		$line=~s/\015//g;	# Remove any DOS carriage returns
		if ($line =~ /^System Configuration: +Sun Microsystems +sun\w+ +/) {
			$diagbanner=&mychomp($line);
			$diagbanner=~s/System Configuration: +Sun Microsystems +sun\w+ //g;
		}
		$prtdiag_failed=1 if ($line =~ /[Pp]rtdiag [Ff]ailed/);
		$prtdiag_failed=2 if ($line =~ /prtdiag can only be run in the global zone/);
	}
	if ($filename eq "" & $verbose == 3) {
		# Only run prtfru and prtpicl if E-mailing maintainer since
		# this data is not used yet by memconf
		if (-x '/usr/sbin/prtfru') {
			$prtfru_cmd='/usr/sbin/prtfru';
			if ($have_prtfru_data == 0) {
				@prtfru=`$prtfru_cmd -x 2>&1`;
				$have_prtfru_data=1;
			}
		}
		if (-x '/usr/sbin/prtpicl') {
			$prtpicl_cmd='/usr/sbin/prtpicl';
			if ($have_prtpicl_data == 0) {
				@prtpicl=`$prtpicl_cmd -v 2>&1`;
				$have_prtpicl_data=1;
			}
		}
	}
}

sub check_prtdiag {
	return if ("$prtdiag_exec" eq "" & $filename eq "");
	&check_for_prtdiag;
	foreach $line (@prtdiag) {
		$line=~s/\015//g;	# Remove any DOS carriage returns
		if ($line =~ /=====/) {
			$flag_cpu=0;	# End of CPU section
			$flag_mem=0;	# End of memory section
		}
		if ($line =~ /Memory Units: Group Size/) {
			# Start of CPU and memory section on SS1000/SC2000
			$flag_cpu=1;
			$flag_mem=1;
		}
		$line="Memory $line" if ($line =~ /^Segment Table:/);
#		if ($flag_mem >= 1 & $line ne "\n" & $line ne "\n") {
		if ($flag_mem >= 1 & $line ne "\n") {
			$boardfound_mem=1;
			$boardfound_mem=0 if ($line =~ /Cannot find/);
			@linearr=split(' ', $line);
			if ($linearr[0] =~ /^0x/ & $ultra =~ /Sun Blade 1[05]0\b/ & ($linearr[$#linearr] eq "chassis/system-board" | $linearr[$#linearr] eq "-")) {
				# Sometimes socket is unlabeled on prtdiag
				# output on Sun Blade 100/150
				$socket=$socketstr[0] if ($linearr[0] =~ /^0x0/);
				if ($simmrangex eq "00000400") {
					$socket=$socketstr[1] if ($linearr[0] =~ /^0x4/);
					$socket=$socketstr[2] if ($linearr[0] =~ /^0x8/);
					$socket=$socketstr[3] if ($linearr[0] =~ /^0xc/);
				} else {
					$socket=$socketstr[1] if ($linearr[0] =~ /^0x2/);
					$socket=$socketstr[2] if ($linearr[0] =~ /^0x4/);
					$socket=$socketstr[3] if ($linearr[0] =~ /^0x6/);
				}
				if ($linearr[$#linearr] eq "-") {
					$line=~s/-$/$socket/g;
					$linearr[$#linearr]=$socket;
				} else {
					$line=~s/-board/-board\/$socket/g;
					$linearr[$#linearr]="chassis/system-board/$socket";
				}
			}
			push(@boards_mem, "$line");
			if ($#linearr >= 2) {
				if ($linearr[2] =~ /\bU\d\d\d\d\b/) {
					# Sun Ultra-250 format
					$sockets_used .= " $linearr[2]";
				} elsif ($linearr[2] =~ /\b\d\d\d\d\b/) {
					# Sun Ultra-4 format
					$sockets_used .= " U$linearr[2]";
				}
			}
			if ($#linearr >= 3) {
				if ($linearr[3] ne "BankIDs" & $linearr[3] ne "GroupID" & $line !~ /^0x\d[\d ]+\d.+ +\d +-$/) {
					if ($linearr[1] =~ /\b\d+MB\b/) {
						# Sun Blade 100/1000 format
						$simmsize=$linearr[1];
						$simmsize=~s/MB//g;
						push(@simmsizesfound, "$simmsize");
					} elsif ($linearr[1] =~ /\b\d+GB\b/) {
						# Sun Blade 1000 format
						$simmsize=$linearr[1];
						$simmsize=~s/GB//g;
						$simmsize=$simmsize * 1024;
						push(@simmsizesfound, "$simmsize");
					}
				}
				if ($model eq "Ultra-250" | $ultra eq 250 | $model eq "Ultra-4" | $ultra eq 450 | $model eq "Ultra-4FT" | $ultra eq "Netra ft1800") {
					if ($linearr[3] =~ /\b\d+\b/) {
						$simmsize=$linearr[3];
						push(@simmsizesfound, "$simmsize");
					}
				}
			}
			if ($linearr[$#linearr] =~ /\bDIMM\d/ | $linearr[$#linearr] =~ /\b[UJ]\d\d\d\d[\b,]/ | $linearr[$#linearr] =~ /MB\/P[01]\/B[01]\/D[01]/ | $linearr[$#linearr] =~ /C[0-3]\/P[01]\/B[01]\/D[01]/ | ($linearr[$#linearr - 1] eq "Label" & $linearr[$#linearr] eq "-")) {
				$sockets_used .= " $linearr[$#linearr]";
				# May be multiple sockets separated by ","
				$sockets_used=~s/,/ /g;
			}
			if ($linearr[0] !~ /^0x/ & ($linearr[$#linearr] eq "-" | $linearr[$#linearr] =~ /^-,/)) {
				# unlabeled sockets
				$sockets_used .= " $linearr[$#linearr]";
				# May be multiple sockets separated by ","
				$sockets_used=~s/,/ /g;
			}
			if ($linearr[$#linearr] =~ /\/J\d\d\d\d$/) {
				$linearr[$#linearr]=~s/.+\///g;
				$sockets_used .= " $linearr[$#linearr]";
			}
			if ($ultra eq "Sun Fire 280R") {
				if ($line =~ / CA +0 +[0-3] .+4-way/) {
					$sockets_used="J0100 J0202 J0304 J0406 J0101 J0203 J0305 J0407";
				} elsif ($line =~ / CA +0 +[02] /) {
					$sockets_used .= " J0100 J0202 J0304 J0406" if ($sockets_used !~ / J0100 /);
				} elsif ($line =~ / CA +[01] +[13] /) {
					$sockets_used .= " J0101 J0203 J0305 J0407" if ($sockets_used !~ / J0101 /);
				}
			}
			# Memory on Sun Fire systems
			if ($line =~ /^\/N\d\/SB\d\/P\d\/B\d\b/) {
				$boardslot_mem=substr($line,0,13);
				push(@boardslot_mems, "$boardslot_mem");
				$boardslot_mems .= $boardslot_mem . " ";
			} elsif ($line =~ /^\/N\d\/SB\d\d\/P\d\/B\d\b/) {
				$boardslot_mem=substr($line,0,14);
				push(@boardslot_mems, "$boardslot_mem");
				$boardslot_mems .= $boardslot_mem . " ";
			} elsif ($line =~ /^\/SB\d\d\/P\d\/B\d\b/) {
				$boardslot_mem=substr($line,0,11);
				push(@boardslot_mems, "$boardslot_mem");
				$boardslot_mems .= $boardslot_mem . " ";
			} elsif ($line =~ /SB\d\/P\d\/B\d\/D\d/) {
				$boardslot_mem=substr($line,25,52);
				push(@boardslot_mems, "$boardslot_mem");
				$boardslot_mems .= $boardslot_mem . " ";
			}
			if ($ultra =~ /Sun Fire/ & $#linearr >= 5) {
				if ($linearr[5] =~ /\d+MB/) {
					$simmsize=$linearr[5];
					$simmsize=~s/MB//g;
					push(@simmsizesfound, "$simmsize");
				}
			}
			if ($ultra =~ /Sun Fire V[48][89]0\b/) {
				# Fire V480, V490, V880, V890
				$bankname="groups";
				$banks_used="A0 B0" if ($line =~ /^  ?[AB] .+ 4-way /);
				$banks_used="A0 A1 B0 B1" if ($line =~ /^  ?[AB] .+ 8-way /);
			}
		}
		if ($line =~ /CPU Units:/) {
			$flag_cpu=1;	# Start of CPU section
			$flag_mem=0;	# End of memory section
			$format_cpu=1;
		}
		if ($line =~ /===== CPU/) {
			$flag_cpu=1;	# Start of CPU section
			$flag_mem=0;	# End of memory section
			$format_cpu=2;
		}
		if ($line =~ /Memory Units:/ | $line =~ /===== Memory / | $line =~ /Used Memory:/) {
			$flag_cpu=0;	# End of CPU section
			$flag_mem=1;	# Start of memory section
		}
		if ($line =~ /CPU Units:/ & $line =~ /Memory Units:/) {
			$flag_cpu=1;	# Start of CPU section
			$flag_mem=1;	# Start of memory section
		}
		if ($flag_cpu >= 1 & $line ne "\n") {
			if ($model eq "Ultra-5_10" | $ultra eq "5_10" | $ultra eq 5 | $ultra eq 10) {
				$newline=$line;
				$newline=~s/^       //g if ($line !~ /Run   Ecache   CPU    CPU/);
				push(@boards_cpu, "$newline");
			} else {
				push(@boards_cpu, "$line");
			}
			$boardfound_cpu=1;
			# CPUs on Sun Fire systems
			if ($line =~ /^\/N\d\/SB\d\/P\d\b/) {
				$boardslot_cpu=substr($line,0,10);
				push(@boardslot_cpus, "$boardslot_cpu");
				$boardslot_cpus .= $boardslot_cpu . " ";
			} elsif ($line =~ /^\/N\d\/SB\d\d\/P\d\b/) {
				$boardslot_cpu=substr($line,0,11);
				push(@boardslot_cpus, "$boardslot_cpu");
				$boardslot_cpus .= $boardslot_cpu . " ";
			} elsif ($line =~ /^\/SB\d\d\/P\d\b/) {
				$boardslot_cpu=substr($line,0,8);
				push(@boardslot_cpus, "$boardslot_cpu");
				$boardslot_cpus .= $boardslot_cpu . " ";
			} elsif ($line =~ /^    SB\d\/P\d\b/) {
				$boardslot_cpu=substr($line,4,6);
				push(@boardslot_cpus, "$boardslot_cpu");
				$boardslot_cpus .= $boardslot_cpu . " ";
			}
		}
		if ($flag_cpu == 1 & $line =~ /------/) {
			# Next lines are the CPUs on each system board
			$flag_cpu=2;
		}
		if ($flag_mem == 1 & $line =~ /------/) {
			# Next lines are the memory on each system board
			$flag_mem=2;
		}
	}

	# Rewrite prtdiag output to include DIMM information on SB1X00, SB2X00,
	# Enchilada and Chalupa (Sun Fire V440) systems
	@new_boards_mem="";
	$grpcnt=0;
	if ($ultra =~ /Sun Blade [12][05]00\b/ | $ultra eq "Sun Fire 280R" | $ultra eq "Netra 20" | $ultra eq "Sun Fire V250") {
		foreach $line (@boards_mem) {
			$line=&mychomp($line);
			$newline=$line;
			if ($line eq "-----------------------------------------------------------" & $prtdiag_banktable_has_dimms == 0) {
				$newline=$line . "------";
			} elsif ($line eq "--------------------------------------------------") {
				$newline=$line . "-----------";
			} elsif ($line =~ /ControllerID  GroupID   Size/ & $prtdiag_banktable_has_dimms == 0) {
				$newline="ID       ControllerID  GroupID   Size    DIMMs    Interleave Way";
			} elsif ($line =~ /ControllerID   GroupID  Labels         Status/) {
				$newline=$line . "       DIMMs";
			} elsif ($line =~ /ControllerID   GroupID  Labels/) {
				$newline=$line . "                      DIMMs";
			} elsif ($line =~ /ControllerID   GroupID  Size       Labels/) {
				$newline=$line . "          DIMMs";
			} elsif ($line =~ /^\d[\d ]       \d             \d /) {
				# prtdiag Bank Table
				$simmsize=substr($line,33,5);
				if ($simmsize =~ /\dGB/) {
					$simmsize=~s/GB//g;
					$simmsize=$simmsize * 1024;
				} else {
					$simmsize=~s/MB//g;
				}
				if ($prtdiag_banktable_has_dimms == 0 | $line =~ /  0$/) {
					# Interleave Way = 0
					$simmsize=$simmsize / 2;
				}
				push(@simmsizesfound, "$simmsize");
				if ($simmsize >= 1024) {
					$simmsize=$simmsize / 1024;
					$simmsize="${simmsize}GB  ";
				} else {
					$simmsize="${simmsize}MB  ";
				}
				$grpsize{substr($line,9,1),substr($line,23,1)}=$simmsize;
				if ($prtdiag_banktable_has_dimms == 0) {
					$newline=substr($line,0,38) . "   2x" . substr($simmsize,0,5);
					$memlength=length($line);
					if ($memlength > 38) {
						$newline .= substr($line,42,20);
					}
				}
			} elsif ($line =~ /^0x\d[\d ]+\d.+ +\d +-$/ | $line =~ /  GroupID \d[\d ]$/) {
				# prtdiag Memory Segment Table
				if ($line =~ /\dGB/) {
					$simmsize=substr($line,19,1) * 512;
				} else {
					$simmsize=substr($line,19,3) / 2;
				}
				$grp=substr($line,-2,2);
				$grp=~s/ //g;
				if ($grp eq "-") {
					$grp=$grpcnt;
					$grpcnt++;
				}
				push(@simmsizesfound, "$simmsize");
				if ($simmsize >= 1024) {
					$simmsize=$simmsize / 1024;
					$simmsize="${simmsize}GB  ";
				} else {
					$simmsize="${simmsize}MB  ";
				}
				$grpsize{0,$grp}=$simmsize;
			} elsif ($line =~ /J0100,/) {
				$sz=$grpsize{0,0};
				$sz=~s/ //g;
				$newline=$line . "     4x$sz" if defined($sz);
			} elsif ($line =~ /J0101,/) {
				$sz=$grpsize{0,1};
				$sz=~s/ //g;
				$newline=$line . "     4x$sz" if defined($sz);
			} elsif ($line =~ /\/J0[1-4]0[0246]\b/) {
				$sz=$grpsize{0,0};
				$sz=~s/ //g;
				$newline=$line . "  $sz" if defined($sz);
			} elsif ($line =~ /\/J0[1-4]0[1357]\b/) {
				$sz=$grpsize{0,1};
				$sz=~s/ //g;
				$newline=$line . "  $sz" if defined($sz);
			} elsif ($line =~ / MB\/DIMM\d,/) {
				$sz=$grpsize{0,substr($line,15,1)};
				$newline=$line . "           2x$sz" if defined($sz);
			} elsif ($line =~ /DIMM\d,DIMM\d/) {
				@linearr=split(' ', $line);
				if ($linearr[2] =~ /\d+[MG]B/) {
					$sz=$linearr[2];
					if ($sz =~ /\dGB/) {
						$sz=~s/GB//g;
						$sz=$sz * 512;
					} else {
						$sz=~s/MB//g;
						$sz=$sz / 2;
					}
					if ($sz >= 1024) {
						$sz=$sz / 1024;
						$sz="${sz}GB  ";
					} else {
						$sz="${sz}MB  ";
					}
				}
				$newline=$line . "     2x$sz" if defined($sz);
				if ($line =~ /DIMM[13],DIMM[24]/ & $ultra eq "Sun Blade 1500") {
					# prototype has sockets DIMM1-DIMM4
					@socketstr=("DIMM1".."DIMM4");
				}
				if ($line =~ /DIMM[1357],DIMM[2468]/ & $ultra eq "Sun Blade 2500") {
					# prototype has sockets DIMM1-DIMM8
					if ($line =~ /DIMM[13],DIMM[24]/) {
						@socketstr=("");
						push(@socketstr, "DIMM1".."DIMM4");
					} elsif ($line =~ /DIMM[57],DIMM[68]/) {
						push(@socketstr, "DIMM5".."DIMM8");
					}
				}
			}
			push(@new_boards_mem, "$newline\n") if ($newline ne "");
		}
		@boards_mem=@new_boards_mem;
	} elsif ($ultra eq "Enchilada" | $ultra eq "Sun Fire V440" | $ultra eq "Netra 440") {
		foreach $line (@boards_mem) {
			$line=&mychomp($line);
			$newline=$line;
			if ($line eq "-----------------------------------------------------------" & $prtdiag_banktable_has_dimms == 0) {
				$newline=$line . "------";
			} elsif ($line eq "--------------------------------------------------") {
				$newline=$line . "-----------";
			} elsif ($line =~ /ControllerID  GroupID   Size/ & $prtdiag_banktable_has_dimms == 0) {
				$newline="ID       ControllerID  GroupID   Size    DIMMs    Interleave Way";
			} elsif ($line =~ /ControllerID   GroupID  Labels         Status/) {
				$newline=$line . "           DIMMs";
			} elsif ($line =~ /ControllerID   GroupID  Labels/) {
				$newline=$line . "                      DIMMs";
			} elsif ($line =~ /^\d[\d ]       \d             \d /) {
				# prtdiag Bank Table
				$simmsize=substr($line,33,5);
				if ($simmsize =~ /\dGB/) {
					$simmsize=~s/GB//g;
					$simmsize=$simmsize * 1024;
				} else {
					$simmsize=~s/MB//g;
				}
				if ($line =~ /  0$/) {
					# Interleave Way = 0
					$simmsize=$simmsize / 2;
				}
				push(@simmsizesfound, "$simmsize");
				if ($simmsize >= 1024) {
					$simmsize=$simmsize / 1024;
					$simmsize="${simmsize}GB  ";
				} else {
					$simmsize="${simmsize}MB  ";
				}
				$a=substr($line,9,1);
				$b=substr($line,23,1);
				$grpsize{$a,$b}=$simmsize;
				$memlength=length($line);
				if ($memlength > 49) {
					if (substr($line,49,40) ne "") {
						$grpinterleave{$a,$b}=substr($line,49,40);
					}
				}
				if ($prtdiag_banktable_has_dimms == 0) {
					$newline=substr($line,0,38) . "   2x" . substr($simmsize,0,5);
					if ($memlength > 38) {
						$newline .= substr($line,42,20);
					}
				}
			} elsif ($line =~ /^0x\d[\d ]+\d.+ +\d +-$/ | $line =~ /  GroupID \d[\d ]$/) {
				# prtdiag Memory Segment Table
				if ($line =~ /\dGB/) {
					$simmsize=substr($line,19,1) * 512;
				} else {
					$simmsize=substr($line,19,3) / 2;
				}
				$grp=substr($line,-2,2);
				$grp=~s/ //g;
				if ($grp eq "-") {
					$grp=$grpcnt;
					$grpcnt++;
				}
				push(@simmsizesfound, "$simmsize");
				if ($simmsize >= 1024) {
					$simmsize=$simmsize / 1024;
					$simmsize="${simmsize}GB  ";
				} else {
					$simmsize="${simmsize}MB  ";
				}
				$grpsize{0,$grp}=$simmsize;
			} elsif ($line =~ / MB\/P[01]\/B[01]\/D[01],/ | $line =~ /C[0-3]\/P[01]\/B[01]\/D[01],/) {
				$sz=$grpsize{substr($line,0,1),substr($line,15,1)};
				$sz=$grpsize{0,substr($line,15,1)} if !defined($sz);
				if (defined($sz)) {
					$newline=$line . "     2x$sz";
				} else {
					$failing_memory=1;
				}
			} elsif ($line =~ / MB\/P[01]\/B[01]\/D[01]\b/ | $line =~ /C[0-3]\/P[01]\/B[01]\/D[01]\b/) {
				$sz=$grpsize{substr($line,28,1),substr($line,31,1)};
				$sz=~s/ //g;
				# If interleave factor is 16, then print 4x$sz
				if ($grpinterleave{substr($line,28,1),0} eq "0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15") {
					$newline=$line . "               4x$sz" if defined($sz);
				} else {
					$newline=$line . "                 $sz" if defined($sz);
				}
			}
			push(@new_boards_mem, "$newline\n") if ($newline ne "");
		}
		@boards_mem=@new_boards_mem;
	}
	# Rewrite prtdiag output to exclude redundant labels
	@new_boards_mem="";
	$flag_group=0;
	foreach $line (@boards_mem) {
		$line=&mychomp($line);
		$newline=$line;
		$flag_group++ if ($line =~ /Memory Module Groups:/);
		if ($flag_group ge 2) {
			$newline="" if ($line =~ /Memory Module Groups:/ | $line =~ "--------------------------------------------------" | $line =~ /ControllerID   GroupID/);
		}
		if ($ultra eq "Netra T12") {
			@linearr=split(' ', $line);
			if ($#linearr >= 4) {
				if ($linearr[3] =~ /\d+MB/) {
					$simmsize=$linearr[3];
					if ($simmsize =~ /\dGB/) {
						$simmsize=~s/GB//g;
						$simmsize=$simmsize * 1024;
					} else {
						$simmsize=~s/MB//g;
					}
					push(@simmsizesfound, "$simmsize");
				}
			}
		}
		push(@new_boards_mem, "$newline\n") if ($newline ne "");
	}
	@boards_mem=@new_boards_mem;
}

sub found_empty_bank {
	$empty_banks .= "," if ($empty_banks ne "");
	$boardslot_mem=~s/[: ]//g;
	$empty_banks .= " Board $boardslot_mem @_";
}

sub found_nvsimm_bank {
	$nvsimm_banks .= ", Board $boardslot_mem @_";
}

sub recommend_prtdiag_patch {
	# Sun BugID 4664349
	print "         This may be corrected by installing ";
	if ($osrel eq "5.9") {
		print "Sun patch 113221-03 or 118558-06 or later.\n";
	} elsif ($osrel eq "5.8") {
		print "Sun patch 109873-26 or 111792-11 or later.\n";
	} else {
		print "a Sun patch on this system.\n";
	}
}

sub numerically {
	$a <=> $b;
}

sub convert_freq {
	($freqx)=@_;
	if ($model eq "i86pc") {
		$freq=int(hex("0x$freqx") / 10000 + 0.5);
	} else {
		if ($freqx =~ /'/) {
			$freqpack=$freqx;
			$freqpack=~s/'//g;
			@frequnpack=unpack("C*",$freqpack);
			$freqx="";
			foreach $field (@frequnpack) {
				$freqx.=sprintf("%02lx", $field);
			}
			if ($#frequnpack < 3) {
				$freqx.="00";
			}
		}
		$freq=int(hex("0x$freqx") / 1000000 + 0.5);
	}
	return $freq;
}

sub mychomp {
	# Used instead of chop or chomp for compatibility with Perl4 and Perl5
	($a)=@_;
	$a=~s,$/$,,g;
	return $a;
}

$motherboard="";
$realmodel="";
$manufacturer="";
$i=0;
# May not have had permission to run prtconf, so see if prtdiag works
&check_for_prtdiag;
if ($diagbanner) {
	if ($filename eq "" | $SUNWexplo == 1) {
		$model=$platform;
		$model=~s/SUNW,//g;
	} else {
		$model=$diagbanner;
		$model=~s/ /-/g;
		# define $model for systems with $diagbanner != $model
		$model="Ultra-4" if ($diagbanner =~ /Sun.Enterprise.450\b/);
		$model="Sun-Blade-1000" if ($diagbanner =~ /Sun.Blade.1000\b/);
		$model="Sun-Fire-280R" if ($diagbanner =~ /Sun.Fire.280R\b/);
		$model="Netra t1" if ($diagbanner =~ /Netra.t1\b/);
		$model="Netra-T4" if ($diagbanner =~ /Netra.T4\b/);
		$model="Sun-Blade-100" if ($diagbanner =~ /Sun.Blade.1[05]0\b/);
		$model="Netra-T12" if ($diagbanner =~ /Sun.Fire.V1280\b/);
		$model="Serverblade1" if ($diagbanner =~ /Serverblade1\b/);
		$model="Ultra-Enterprise" if ($diagbanner =~ /Enterprise.E?[3-6][05]00\b/ | $diagbanner =~ /Enterprise.10000\b/);
	}
	&check_model;
	&check_banner;
}
foreach $line (@config) {
	$line=~s/\015//g;	# Remove any DOS carriage returns
	if ($line =~ /Node /) {
		$config_permission=1;
	}
	if ($line =~ /Permission denied/) {
		$permission_error="ERROR: $line" if ($diagbanner eq "" | ! $prtdiag_has_mem);
	}
	if ($line =~ /selclass qualifier memory;info;wait;infolog/) {
		&hpux_cstm;
	}
	if ($line =~ /banner-name:/ & $banner eq "") {
		$banner=$line;
		$banner=~s/\s+banner-name:\s+//;
		$banner=~s/'//g;
		$banner=~s/SUNW,//g;
		$banner=~s/TWS,//g;
		$banner=~s/CYCLE,//g;
		$banner=&mychomp($banner);
		&check_banner;
	}
	if ($line =~ /model:.*AXUS/) {
		# AXUS clones with their name on OBP
		$manufacturer="AXUS";
	}
	if ($line =~ /SUNW,Ultra-/ | $line =~ /SUNW,SPARC/ | $line =~ /Sun.4/ |
	    $line =~ /SUNW,S240/ | $line =~ /SUNW,JavaEngine1/ |
	    $line =~ /SUNW,Ultra.*Engine/ | $line =~ /SUNW,Ultra.*Netra*/ |
	    $line =~ /SUNW,Premier-24/ | $line =~ /SUNW,UltraAX-/ |
	    $line =~ /SUNW,Netra/ | $line =~ /\s+name:.*SUNW,Sun-/ |
	    $line =~ /SUNW,Grover/ | $line =~ /SUNW,Enchilada/ |
	    $line =~ /SUNW,Serverblade1/ | $line =~ /SUNW,Enterprise/ |
	    $line =~ /\s+name:.*'i86pc'/ | $line =~ /^i86pc/ |
	    $line =~ /model:\s+'SPARC CPU-/ | $line =~ /model:\s+'SPARC CPCI-/ |
	    $line =~ /SUNW,Axil-/ | $line =~ /\s+name:.*COMPstation/ |
	    $line =~ /\s+name:.*Tadpole/ | $line =~ /\s+name:.*Auspex/ |
	    $line =~ /\s+name:.*S-4/ | $line =~ /\s+name:.*FJSV,GP/ |
	    $line =~ /\s+name:.*CompuAdd/ | $line =~ /\s+name:.*RDI,/) {
		$model=$line;
		$model=~s/\s+name:\s+//;
		$model=~s/\s+model:\s+//;
		$model=~s/'//g;
		$model=&mychomp($model);
		&check_model;
		if ($line =~ /CompuAdd/) {
			$manufacturer="CompuAdd";
			if ($model eq "SS-2") {
				$banner=$model if ($banner eq "");
				$bannermore="SPARCstation 2";
				$modelmore="SPARCstation 2";
			}
		}
	}
	$foundname=1 if ($line =~ /\s+name:\s+/);
	if ($line =~ /\s+model:\s+'.+,/ & $foundname == 0) {
		# Ultra 5/10 motherboard is 375-xxxx part number
		# SS10/SS20 motherboard is Sxx,501-xxxx part number
		if ($line =~ /,375-/ | $line =~ /,500-/ | $line =~ /,501-/) {
			$motherboard=$line;
			$motherboard=~s/\s+model:\s+//;
			$motherboard=~s/'//g;
			$motherboard=&mychomp($motherboard);
		}
	}
	if ($line =~ /\sname:\s+'memory'/) {
		$j=$i - 2;
		if ($config[$j] =~ /\sreg:\s/) {
			$gotmemory=&mychomp($config[$j]);
		} elsif ($config[$j - 1] =~ /\sreg:\s/) {
			$gotmemory=&mychomp($config[$j - 1]);
		} elsif ($config[$j + 1] =~ /\sreg:\s/) {
			$gotmemory=&mychomp($config[$j + 1]);
		}
	}
	if ($line =~ /\sdevice_type:\s+'memory-bank'/) {
		$j=$i - 3;
		if ($config[$j] =~ /\sreg:\s/ & $config[$j] !~ /.00000000$/) {
			$config[$j]=~s/\s+reg:\s+//;
			if ($gotmemory) {
				$gotmemory .= ".$config[$j]";
			} else {
				$gotmemory=$config[$j];
			}
			$gotmemory=&mychomp($gotmemory);
		}
	}
	# The following is not used yet
	#if ($line =~ /\sdevice_type:\s+'memory-module'/) {
	#	if ($config[$i - 2] =~ /\sreg:\s/) {
	#		$config[$i - 3]=~s/\s+socket-name:\s+//;
	#		if ($gotmodule) {
	#			$gotmodule .= ".$config[$i - 3]";
	#		} else {
	#			$gotmodule=$config[$i - 3];
	#		}
	#		$gotmodule=&mychomp($gotmodule);
	#		$config[$i - 2]=~s/\s+reg:\s+//;
	#		@module=split(/\./, $config[$i - 2]);
	#		$gotmodule .= ".$module[3]";
	#		$gotmodule=&mychomp($gotmodule);
	#		$config[$i + 1]=~s/\s+name:\s+//;
	#		$config[$i + 1] =~ y/[a-z]/[A-Z]/;
	#		$gotmodule .= ".$config[$i + 1]";
	#		$gotmodule=&mychomp($gotmodule);
	#		$gotmodule=~s/'//g;
	#	}
	#}
	if ($line =~ /\ssimm-use:\s+/) {
		# DIMM usage on Fujitsu GP7000
		$gotmodule=$config[$i];
		$gotmodule=~s/\s+simm-use:\s+//;
		$gotmodule=&mychomp($gotmodule);
		$slotname0="SLOT0" if ($banner =~ /GP7000\b/);
	}
	if ($line =~ /\scomponent-name:\s+'.*CPU.*'/) {
		# CPUs on Fujitsu GP7000F and PrimePower systems
		$slotname=$line;
		$slotname=~s/\s+component-name:\s+//;
		$slotname=~s/'//g;
		$slotname=&mychomp($slotname);
		if ($gotcpunames) {
			$gotcpunames .= " $slotname";
		} else {
			$gotcpunames=$slotname;
		}
		$boardname=$slotname;
		$boardname=~s/-.*//g;
		if ($boardname ne $slotname) {
			if ($gotcpuboards) {
				$gotcpuboards .= " $boardname" if ($gotcpuboards !~ /\b$boardname\b/);
			} else {
				$gotcpuboards=$boardname;
			}
		}
	}
	if ($line =~ /\sdevice_type:\s+'memory-module'/) {
		# DIMM usage on Fujitsu GP7000F and PrimePower systems
		$slotname="";
		if ($config[$i - 3] =~ /\scomponent-name:\s/) {
			$slotname=$config[$i - 3];
		}
		if ($config[$i - 4] =~ /\scomponent-name:\s/) {
			$slotname=$config[$i - 4];
		}
		if ($slotname ne "") {
			$slotname=~s/\s+component-name:\s+//;
			$slotname=~s/'//g;
			$slotname=&mychomp($slotname);
			if ($gotmodulenames) {
				$gotmodulenames .= ".$slotname";
			} else {
				$gotmodulenames=$slotname;
			}
			$slotname0=$slotname if (! $slotname0);
			$config[$i - 1]=~s/\s+reg:\s+//;
			@module=split(/\./, $config[$i - 1]);
			$gotmodulenames .= ".$module[1]";
			$gotmodulenames=&mychomp($gotmodulenames);
		}
	}
	if ($line =~ /\sname:\s+'cgfourteen'/) {
		# Determine size of VSIMM
		# Currently assumes only one VSIMM is installed
		if ($config[$i - 2] =~ /\sreg:\s/) {
			$sx_line=&mychomp($config[$i - 2]);
		} elsif ($config[$i - 3] =~ /\sreg:\s/) {
			$sx_line=&mychomp($config[$i - 3]);
		}
		@sxline=split(/\./, $sx_line);
		$sxmem=hex("0x$sxline[5]") / $meg;
	}
	if ($line =~ /501-2197/) {
		# 1MB Prestoserve NVSIMMs (SS1000/SC2000)
		if ($config[$i + 1] =~ /\sreg:\s/) {
			$nv_line=&mychomp($config[$i + 1]);
		} elsif ($config[$i + 2] =~ /\sreg:\s/) {
			$nv_line=&mychomp($config[$i + 2]);
		}
		@nvline=split(/\./, $nv_line);
		$nvmem += hex("0x$nvline[2]") / $meg;
	}
	if ($line =~ /501-2001/) {
		# 2MB Prestoserve NVSIMMs (SS10/SS20)
		if ($config[$i + 1] =~ /\sreg:\s/) {
			$nv_line=&mychomp($config[$i + 1]);
		} elsif ($config[$i + 2] =~ /\sreg:\s/) {
			$nv_line=&mychomp($config[$i + 2]);
		}
		@nvline=split(/\./, $nv_line);
		$nvmem += hex("0x$nvline[2]") / $meg;
		$nvmem1=1 if ($nvline[1] eq "10000000");
		$nvmem2=1 if ($nvline[1] eq "14000000" | $nvline[1] eq "1c000000");
	}
	if ($line =~ /Memory size:\s/ & $installed_memory == 0) {
		$memory_size=&mychomp($line);
		@memory=split(/\s+/, $memory_size);
		$installed_memory=$memory[2];
		if ($installed_memory =~ /GB/) {
			$installed_memory=~s/GB//g;
			$installed_memory=$installed_memory * 1024;
		} else {
			$installed_memory=~s/M[Bb]//g;
		}
		# prtconf sometimes reports incorrect total memory
		# 32MB is minimum for sun4u machines
		if ($installed_memory < 32 & $machine eq "sun4u") {
			$prtconf_warn="Incorrect total installed memory ($installed_memory MB) was reported by prtconf.";
			$installed_memory=0;
		}
		$BSD=0;	# prtconf and prtdiag only have this output
		$config_cmd="/usr/sbin/prtconf -pv" if ($config_cmd !~ /prtconf/);
		$config_command="prtconf";
	}
	if ($sysfreq == 0 & $freq > 0) {
		$sysfreq=$freq;
		$freq=0;
	}
	if ($devtype eq "cpu") {
		$cpufreq=$freq;
		$cpuline=$line;
		$j=$i - 3;
		while ($cpuline !~ /^$/) {
			if ($cpuline =~ /clock-frequency:/) {
				@freq_line=split(' ', $cpuline);
				$cpufreq=&convert_freq($freq_line[1]);
				$sysfreq=$freq if ($sysfreq == 0 & $freq > 0);
			} elsif (($cpuline =~ /\sname:\s/ | $cpuline =~ /\scompatible:\s/) & $cpuline !~ /Sun 4/ & $cpuline !~ /SPARCstation/ & $cpuline !~ /CompuAdd/ & $cpuline !~ /'cpu/) {
				$cputype=$cpuline;
				$cputype=~s/\s+name:\s+//;
				$cputype=~s/\s+compatible:\s+//;
				$cputype=~s/'//g;
				$cputype=~s/SUNW,//g;
				$cputype=~s/ .*//g;
				$cputype=&mychomp($cputype);
			}
			$j++;
			if ($config[$j]) {
				$cpuline=$config[$j];
			} else {
				$cpuline="";
			}
		}
		$freq=0;
		$devtype="";
		$cpufreq=$sysfreq if ($sysfreq >= $cpufreq);
		if ($cputype eq "") {
			$cputype=$machine;
			$cputype="SPARC" if ($cputype =~ /^sun4/);
			@bannerarr=split(/\s/, $banner);
			foreach $field (@bannerarr) {
				if ($field =~ /SPARC/ & $field !~ /SPARCstation/) {
					$cputype=$field;
				} elsif ($field =~ /390Z5/) {
					$field="TI,TMS$field" if ($field =~ /^390Z5/);
					if ($cpufreq > 70) {
						$cputype="SuperSPARC-II $field";
					} else {
						$cputype="SuperSPARC $field";
					}
				} elsif ($field =~ /RT62[56]/) {
					$cputype="hyperSPARC $field";
					$machine="sun4m";
				}
			}
			$cputype=~s/[()]//g;
		} elsif ($cputype =~ /MB86907/) {
			$cputype="TurboSPARC-II $cputype";
		} elsif ($cputype =~ /MB86904/ | $cputype =~ /390S10/) {
			if ($cpufreq > 70) {
				$cputype="microSPARC-II $cputype";
			} else {
				$cputype="microSPARC $cputype";
			}
		} elsif ($cputype =~ /,RT62[56]/) {
			$cputype="hyperSPARC $cputype";
			$machine="sun4m";
		} elsif ($cputype =~ /UltraSPARC-IV/) {
			# Count dual-thread (dual-core) US-IV & US-IV+ as 1 CPU
			$cputype="dual-thread $cputype";
			$machine="sun4u";
			$multithread++;
			$multithread=0 if ($multithread == 2);
		} elsif ($cputype =~ /UltraSPARC-T1/) {
			# Count 4-thread (4, 6, or 8 core) Niagara CPUs as 1 CPU
			$machine="sun4v";
			$multithread++;
			# Number of cores & CPUs counted outside this loop below
		}
		if ($multithread == 0) {
			$ncpu++;
			$cpucnt{"$cputype $cpufreq"}++;
		}
	}
	if ($line =~ /device_type:/) {
		@dev_line=split(/\'/, $line);
		$devtype=$dev_line[1];
	}
	if ($line =~ /clock-frequency:/) {
		@freq_line=split(' ', $line);
		$freq=&convert_freq($freq_line[1]);
	}
	if ($line =~ /\sversion:\s+'OBP/ & $romver eq "") {
		$romver=$line;
		$romver=~s/\s+version:\s+//;
		$romver=~s/'//g;
		$romver=&mychomp($romver);
		@romverarr=split(/\s/, $romver);
		$romvernum=$romverarr[1];
	}
	if ($line =~ /compatible:\s+'sun4.'/ & $osrel eq "") {
		@compatible_line=split(/\'/, $line);
		$machine=$compatible_line[1];
	}
	$i++;
}
if ($cputype =~ /UltraSPARC-T1/) {
	# Count 4-thread (4, 6, or 8 core) Niagara CPUs as 1 CPU
	if ($multithread > 32) {
		# Assume each CPU has 8 cores (32 threads)
		$ncpu=$multithread / 32 + 1;
	} else {
		$ncpu=1;
	}
	$corecnt=$multithread / 4 / $ncpu;
	$cputype="${corecnt}-core quad-thread $cputype";
	$cpucnt{"$cputype $cpufreq"}=$ncpu;
}
if ($osrel eq "") {
	if ($BSD) {
		$osrel="4.X";
		$config_cmd="/usr/etc/devinfo -pv";
		$config_command="devinfo";
	} else {
		$osrel="5.X";
		$solaris="2.X";
		$config_cmd="/usr/sbin/prtconf -pv";
		$config_command="prtconf";
	}
}
#$sysfreq=$freq if ($sysfreq == 0 & $freq > 0);
#$cpufreq=$sysfreq if ($sysfreq > $cpufreq & $ncpu > 0);

@romverarr=split(/\./, $romvernum) if ($romver);
$romvermajor=($romverarr[0]) ? $romverarr[0] : 2;
$romverminor=($romverarr[1]) ? $romverarr[1] : 0;
$romverminor=0 if ($romverminor eq "" | $romverminor eq "X");
if ($banner =~ /^ \(/) {
	# banner-name does not include the eeprom banner name. This happens
	# sometimes when OBP 3.23 is installed on Ultra-60/E220R and
	# Ultra-80/E420R systems.
	$bannermore="Ultra 60 or Enterprise 220R" if ($model eq "Ultra-60");
	$bannermore="Ultra 80, Enterprise 420R or Netra t 1400/1405" if ($model eq "Ultra-80");
}
#
# SPARCengine systems
#
$ultra="AX" if ($motherboard =~ /501-3043/);
$ultra="AX-300" if ($motherboard =~ /501-5037/);
$ultra="AXi" if ($motherboard =~ /501-4559/);
$ultra="AXmp" if ($banner =~ /UltraAX-MP/ | $model =~ /UltraAX-MP/ | $motherboard =~ /501-5296/ | $motherboard =~ /501-5487/ | $motherboard =~ /501-5670/);
$ultra="AXmp+" if ($banner =~ /UltraAX-MP\+/ | $model =~ /UltraAX-MP\+/ | $motherboard =~ /501-4324/);
$ultra="AXe" if ($banner =~ /UltraAXe\b/ | $model =~ /UltraAX-e\b/ | $motherboard =~ /375-0088/);
$ultra="AX-e2" if ($banner =~ /Netra AX1105-500\b/ | $model =~ /UltraAX-e2\b/ | $motherboard =~ /375-0128/);
$ultra="Netra X1" if ($banner =~ /Netra X1\b/ | $motherboard =~ /375-3015/);
$ultra="Netra T1 200" if ($banner =~ /Netra T1 200\b/ | $motherboard =~ /375-0132/);
$ultra="Sun Fire V100" if ($banner =~ /Sun Fire V100\b/);
# Sun Fire V120/Netra 120 can use motherboard 375-0132 like Netra T1 200 above
$ultra="Sun Fire V120" if ($banner =~ /Sun Fire V120\b/);
$ultra="Netra 120" if ($banner =~ /Netra 120\b/);
if ($ultra =~ /AX/) {
	if ($banner !~ /SPARCengine.*Ultra/) {
		if ($bannermore) {
			$bannermore="(SPARCengine Ultra $ultra) $bannermore";
		} else {
			$bannermore="(SPARCengine Ultra $ultra)";
		}
	}
}
if ($model =~ /Ultra-5_10\b/) {
	if ($banner =~ /\bVoyagerIIi\b/) {
		# Tadpole Voyager IIi has 8 DIMM slots, but prtconf reports
		# it as an Ultra 5/10
		$model="VoyagerIIi";
		$ultra="VoyagerIIi";
	}
}
$ultra="Sun Blade 150" if ($banner =~ /Sun Blade 150\b/ | $diagbanner =~ /Sun Blade 150\b/);
$ultra="UP-20" if ($banner =~ /\bUP-20\b/); # untested ???
$ultra="UP-520IIi" if ($motherboard =~ /501-4559/ & $banner =~ /\b520IIi\b/);

$need_obp2=0;
if ($model eq "Sun 4/20" | $model eq "Sun 4/25" | $model eq "Sun 4/40" | $model eq "Sun 4/50" | $model eq "Sun 4/60" | $model eq "Sun 4/65" | $model eq "Sun 4/75" | $model eq "SS-2") {
	$machine="sun4c";
	if ($model eq "Sun 4/40" | $model eq "Sun 4/60" | $model eq "Sun 4/65") {
		$need_obp2=1;
	}
}

if ($gotmemory eq "" & $ultra eq 0 & $machine ne "sun4d") {
	&check_prtdiag;
	&show_header;
	print "total memory = ${installed_memory}MB\n" if ($installed_memory);
	print "$permission_error" if ($permission_error);
	print "ERROR: no 'memory' line in \"$config_cmd\" output.\n";
	if (! $config_permission & $machine =~ /sun4/) {
		print "       This user ";
		if ($permission_error) {
			print "does";
		} else {
			print "may";
		}
		print " not have permission to run $config_command.\n";
		print "       Try running memconf as a privileged user like root.\n";
	} elsif ($need_obp2) {
		print "       Upgrading from Open Boot PROM V1.X to V2.X will ";
		print "allow memconf to\n       detect the memory installed.\n";
	} else {
		print "       This is an unsupported system by memconf.\n";
	}
	if ($machine !~ /sun4/) {
		print "       Currently it is only supported on SPARC and HP-UX systems, not on\n";
		print "       $machine systems.\n";
	}
	$exitstatus=1;
	&mailmaintainer if ($verbose == 3);
	exit $exitstatus;
}

$gotmemory=~s/\s+reg:\s+//;
$gotmemory=~s/'//g;
@slots=split(/\./, $gotmemory);
$slot=1;
#$start1x=0;
$manufacturer="" if (($banner =~ /^Sun\b/ | $model =~ /^Sun\b/) & $manufacturer eq "Sun");
if ($manufacturer ne "" & $manufacturer ne "Sun") {
	if ($manufacturer ne "Force Computers") {
		$bannermore=($bannermore) ? "$bannermore clone" : "clone";
	}
	$modelmore=($modelmore) ? "$modelmore clone" : "clone";
	$clone=1;
}
# DIMMs are installed in pairs on Ultra 1, 5 and 10; quads on
# Ultra 2, 60, 80, 220R, 420R, 450; 8's in Ultra Enterprise
#
# On 64-bit systems, prtconf format is AAAAAAAA.AAAAAAAA.SSSSSSSS.SSSSSSSS
# and on 32-bit systems, prtconf format is AAAAAAAA.AAAAAAAA.SSSSSSSS
# where A is for Address, S is for Size.
# Minimum module size is 1MB (0x00100000), so strip off last 5 hex digits of LSB
# and prepend last 5 digits of MSB, which allows recognizing up to 4500TB!
#
if ($ultra) {
	$val0=3;	# simmsize is in 3rd and 4th fields
	$valaddr=2;	# address is 2 fields before simmsize
	$valinc=4;	# fields per simm
	$memtype="DIMM";
} else {
	$val0=2;	# simmsize is in 3rd field
	$valaddr=1;	# address is 1 field before simmsize
	$valinc=3;	# fields per simm
}

#
# Define memory layout for specific systems
#
if ($model eq "Sun 4/20") {
	# SLC accepts 4MB SIMMs on motherboard
	#   501-1676 (4MB 100ns), 501-1698 (4MB 80ns)
	#   33-bit 72-pin Fast Page Mode (36-bit work also)
	# Does not support Open Boot PROM V2.X, so devinfo/prtconf output will
	# not have memory lines.
	$devname="OffCampus";
	$untested=1;
	$simmrangex="00000010";
	$simmbanks=4;
	$simmsperbank=1;
	@simmsizes=(4);
	@socketstr=("U0502","U0501","U0602","U0601");
}
if ($model eq "Sun 4/25") {
	# ELC accepts 4MB or 16MB SIMMs on motherboard
	#   501-1698 or 501-1812 (4MB 80ns), 501-1822 (16MB 80ns)
	#   33-bit 72-pin Fast Page Mode (36-bit work also)
	$devname="NodeWarrior";
	$untested=0;
	$simmrangex="00000010";
	$simmbanks=4;
	$simmsperbank=1;
	@simmsizes=(4,16);
	@socketstr=("U0407".."U0410");
	@bankstr=("MEM1".."MEM4");
}
if ($model eq "Sun 4/40") {
	# IPC accepts 1MB or 4MB SIMMs on motherboard
	#   501-1697 (1MB 80ns), 501-1625 (4MB 100ns), 501-1739 (4MB 80ns)
	# Does not show memory with Open Boot PROM V1.X, but does with OBP V2.X
	$devname="Phoenix";
	$untested=0;
	$simmrangex="00000010";
	$simmbanks=3;
	$simmsperbank=4;
	@simmsizes=(1,4);
	@socketstr=("U0588","U0587","U0586","U0585","U0584","U0591","U0590","U0589","U0678","U0676","U0683","U0677");
	@bankstr=(0,0,0,0,1,1,1,1,2,2,2,2);
	@bytestr=(0..3,0..3,0..3);
}
if ($model eq "Sun 4/50") {
	# IPX accepts 4MB or 16MB SIMMs on motherboard
	#   501-1812 (4MB 80ns), 501-1915 or 501-1822 (16MB 80ns)
	#   33-bit 72-pin Fast Page Mode (36-bit work also)
	$devname="Hobbes";
	$untested=0;
	$simmrangex="00000010";
	$simmbanks=4;
	$simmsperbank=1;
	@simmsizes=(4,16);
	@socketstr=("U0310","U0309","U0308","U0307");
	@bankstr=(0..3);
}
if ($model eq "Sun 4/60" | $model eq "Sun 4/65") {
	# SS1 and SS1+ accepts 1MB or 4MB SIMMs on motherboard
	#   501-1408 (1MB 100ns), 501-1697 (SS1+ only) (1MB 80ns),
	#   501-1625 (4MB 100ns), 501-1739 (4MB 80ns)
	# Does not show memory with Open Boot PROM V1.X, but does with OBP V2.X
	if ($model eq "Sun 4/60") {
		$devname="Campus";
		$untested=0;
	} else {
		$devname="CampusB";
		$untested=1;
	}
	$simmrangex="00000010";
	$simmbanks=4;
	$simmsperbank=4;
	@simmsizes=(1,4);
	@socketstr=("U0588","U0587","U0586","U0585","U0584","U0591","U0590","U0589","U0678","U0676","U0683","U0677","U0682","U0681","U0680","U0679");
	@bankstr=(0,0,0,0,1,1,1,1,2,2,2,2,3,3,3,3);
	@bytestr=(0..3,0..3,0..3,0..3);
}
if ($model eq "Sun 4/75" | $model eq "SS-2") {
	# SS2 accepts 4MB SIMMs on motherboard and 32MB or 64MB SBus expansion
	# card (501-1823 Primary and 501-1824 Secondary)
	#   501-1739 (4MB 80ns)
	$devname="Calvin";
	$untested=0;
	$simmrangex="00000010";
	$simmbanks=4;
	$simmsperbank=4;
	@simmsizes=(4);
	@socketstr=("U0311","U0309","U0307","U0322","U0312","U0310","U0308","U0321","U0313","U0314","U0315","U0320","U0319","U0318","U0317","U0316");
	@bankstr=(0,0,0,0,1,1,1,1,2,2,2,2,3,3,3,3);
	@bytestr=(0..3,0..3,0..3,0..3);
}
if ($model =~ /SPARCclassic/ | $model =~ /SPARCstation-LX/) {
	# Classic-X (4/10) accepts 1MB, 2MB, 4MB and 16MB SIMMs on motherboard
	# Classic (4/15) and LX (4/30) accepts 4MB and 16MB SIMMs on motherboard
	# Can accept 32MB SIMMs in bank 1, allowing 128MB total (2x32, 4x16)
	# Possibly accepts 8MB SIMMs in bank 1
	#   501-2289 (1MB), 501-2433 (2MB) on Classic-X only
	#   501-1991 (4MB), 501-2059 (16MB)
	#   36-bit 72-pin 60ns Fast Page Mode
	$devname="Sunergy";
	if ($model =~ /SPARCclassic-X/) {
		$untested=1;
		@simmsizes=(1,2,4,8,16,32);
	} else {
		$untested=0;
		@simmsizes=(4,8,16,32);
	}
	$simmrangex="00000020";
	$simmbanks=3;
	$simmsperbank=2;
	@socketstr=("U0304","U0303","U0301","U0302","U0402","U0401");
	@bankstr=(1,1,2,2,3,3);
}
if ($model eq "S240") {
	# Voyager has 16MB on motherboard, plus accepts one or two 16MB or 32MB
	# Memory cards (501-2327 32MB, 501-2366 16MB)
	# Motherboard, address 0x00000000-0x007fffff, 0x01000000-0x017fffff
	# Lower slot=Mem 1, address 0x02000000-0x07ffffff
	# Upper slot=Mem 2, address 0x0a000000-0x0fffffff
	$devname="Gypsy";
	$untested=0;
	$memtype="memory card";
	$sockettype="slot";
	$simmrangex="00000020";
	$simmbanks=8;	# Count the skipped address range
	$simmsperbank=1;
	@simmsizes=(16,32);
	@socketstr=("motherboard","Mem 1","Mem 1","Mem 1","?","Mem 2","Mem 2","Mem 2");
	@orderstr=("","lower slot","lower slot","lower slot","?","upper slot","upper slot","upper slot");
}
if ($model eq "JavaEngine1") {
	# Accepts 8MB, 16MB and 32MB EDO DIMMs
	$devname="Bali";
	$untested=0;
	$memtype="DIMM";
	$simmrangex="00000020";
	$simmbanks=2;
	$simmsperbank=1;
	@simmsizes=(8,16,32);
	@socketstr=("J0501","J0502");
	@bankstr=(0,1);
}
if ($model eq "SPARCstation-4") {
	# Accepts 8MB and 32MB SIMMs on motherboard
	#   501-2470 (8MB), 501-2471 (32MB)
	#   168-pin 60ns Fast Page Mode
	$devname="Perigee";
	$untested=0;
	$simmrangex="00000020";
	$simmbanks=5;
	$simmsperbank=1;
	@simmsizes=(8,32);
	@socketstr=("J0301".."J0305");
	@bankstr=(0..4);
}
if ($model eq "SPARCstation-5" | $model eq "micro COMPstation 5" | $model =~ /Axil-255/ | $banner =~ /TWINstation 5G\b/) {
	# Accepts 8MB and 32MB SIMMs on motherboard
	#   501-2470 (8MB), 501-2471 (32MB)
	#   168-pin 60ns Fast Page Mode
	$devname="Aurora" if ($model eq "SPARCstation-5");
	$untested=0;
	$simmrangex="00000020";
	$simmbanks=8;
	$simmsperbank=1;
	@simmsizes=(8,32);
	@socketstr=("J0300".."J0303","J0400".."J0403");
	@bankstr=(0..7);
	if ($banner =~ /TWINstation 5G\b/) {
		$simmbanks=6;
		@socketstr=(0..5);
	}
	if ($model ne "SPARCstation-5") {
		$bannermore="SPARCstation 5 clone";
		$modelmore="SPARCstation 5 clone";
	}
}
if ($model =~ /SPARCstation-10/ | $model eq "Premier-24" | $motherboard eq "SUNW,S10,501-2365") {
	# Accepts 16MB and 64MB SIMMs on motherboard
	#   501-1785 or 501-2273 (16MB 80ns), 501-2479 (16MB 60ns),
	#   501-2622 (32MB 60ns), 501-1930 (64MB 80ns), 501-2480 (64MB 60ns)
	#   200-pin 60ns or 80ns Fast Page Mode ECC
	# 32MB SIMMs not supported according to Sun, but appears to work fine
	# depending on the OBP revision. OBP 2.12 and older detects the 32MB
	# SIMM as 16MB, OBP 2.19 and later properly detects the 32MB SIMM.
	$devname="Campus2" if ($model =~ /SPARCstation-10/);
	$untested=0;
	$simmrangex="00000040";
	$simmbanks=8;
	$simmsperbank=1;
	$romvernum="2.X" if ($romvernum eq "");
	$romverminor=0 if ($romverminor eq "" | $romverminor eq "X");
	if ($romvermajor eq 2 & $romverminor >= 19) {
		@simmsizes=(16,32,64);
	} else {
		@simmsizes=(16,64);
	}
	@socketstr=("J0201","J0203","J0302","J0304","J0202","J0301","J0303","J0305");
	@orderstr=("1st","3rd","4th","2nd","8th","6th","5th","7th");
	@bankstr=(0..7);
}
if ($model =~ /SPARCstation-20/ | $model =~ /COMPstation-20S/ | $banner =~ /TWINstation 20G\b/) {
	# Accepts 16MB, 32MB and 64MB SIMMs on motherboard
	#   501-2479 (16MB), 501-2622 (32MB), 501-2480 (64MB)
	#   200-pin 60ns Fast Page Mode ECC
	$devname="Kodiak" if ($model eq "SPARCstation-20");
	$untested=0;
	$simmrangex="00000040";
	$simmbanks=8;
	$simmsperbank=1;
	@simmsizes=(16,32,64);
	@socketstr=("J0201","J0303","J0202","J0301","J0305","J0203","J0302","J0304");
	@orderstr=("1st","2nd","3rd","4th","5th","6th","7th","8th");
	@bankstr=(0..7);
	if ($model !~ /SPARCstation-20/) {
		$bannermore="SPARCstation 20 clone";
		$modelmore="SPARCstation 20 clone";
	}
	if ($model eq "SPARCstation-20I") {
		$bannermore="(SPARCstation-20I) clone";
		$modelmore="clone";
	}
	if ($banner =~ /TWINstation 20G\b/) {
#		@socketstr=("J0201","J0303","J0202","J0301","J0305","J0203","J0302","J0304");
#		@orderstr=("1st","6th","2nd","4th","8th","3rd","5th","7th");
		@socketstr=(0..7);
		@orderstr=("");
	}
}
if ($model eq "SPARCsystem-600" | $model =~ /Sun.4.600/) {
	# Accepts 4MB or 16MB SIMMs on motherboard
	# Accepts 1MB, 4MB or 16MB SIMMs on VME expansion cards
	# A memory bank is 16 SIMMs of the same size and speed
	# Minimum memory configuration is 16 SIMMs in Bank 0 on the motherboard
	# Motherboard Bank 1 must be populated before adding expansion cards
	# Up to two VME memory expansion cards can be added
	# Use 4MB SIMM 501-1739-01 or 501-2460-01
	# Use 16MB SIMM 501-2060-01
	$devname="Galaxy";
	$untested=0;
	$simmrangex="00000100";
	$simmbanks=2; # 2 banks on CPU board, 4 banks on each expansion cards
	$simmsperbank=16;
	@simmsizes=(4,16);
	# Sockets, banks and bytes on motherboard
	@socketstr=("U1107","U1307","U1105","U1305","U1103","U1303","U1101","U1301","U1207","U1407","U1205","U1405","U1203","U1403","U1201","U1401","U1108","U1308","U1106","U1306","U1104","U1304","U1102","U1302","U1208","U1408","U1206","U1406","U1204","U1404","U1202","U1402");
	@bankstr=(0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1);
	@banksstr=("Motherboard bank 0","Motherboard bank 1");
	@bytestr=("0L0","0L1","1L0","1L1","2L0","2L1","3L0","3L1","4L0","4L1","5L0","5L1","6L0","6L1","7L0","7L1","0H0","0H1","1H0","1H1","2H0","2H1","3H0","3H1","4H0","4H1","5H0","5H1","6H0","6H1","7H0","7H1");
	# Sockets, banks and bytes on VME expansion cards
	@socketstr_exp=("U1501","U1503","U1505","U1507","U1601","U1603","U1605","U1607","U1701","U1703","U1705","U1707","U1801","U1803","U1805","U1807","U1502","U1504","U1506","U1508","U1602","U1604","U1606","U1608","U1702","U1704","U1706","U1708","U1802","U1804","U1806","U1808","U1901","U1903","U1905","U1907","U2001","U2003","U2005","U2007","U2101","U2103","U2105","U2107","U2201","U2203","U2205","U2207","U1902","U1904","U1906","U1908","U2002","U2004","U2006","U2008","U2102","U2104","U2106","U2108","U2202","U2204","U2206","U2208");
	@bankstr_exp=("B0","B0","B0","B0","B0","B0","B0","B0","B0","B0","B0","B0","B0","B0","B0","B0","B1","B1","B1","B1","B1","B1","B1","B1","B1","B1","B1","B1","B1","B1","B1","B1","B2","B2","B2","B2","B2","B2","B2","B2","B2","B2","B2","B2","B2","B2","B2","B2","B3","B3","B3","B3","B3","B3","B3","B3","B3","B3","B3","B3","B3","B3","B3","B3");
	@bytestr_exp=("0L0","0L1","1L0","1L1","2L0","2L1","3L0","3L1","4L0","4L1","5L0","5L1","6L0","6L1","7L0","7L1","0H0","0H1","1H0","1H1","2H0","2H1","3H0","3H1","4H0","4H1","5H0","5H1","6H0","6H1","7H0","7H1","8L0","8L1","9L0","9L1","aL0","aL1","bL0","bL1","cL0","cL1","dL0","dL1","eL0","eL1","fL0","fL1","8H0","8H1","9H0","9H1","aH0","aH1","bH0","bH1","cH0","cH1","dH0","dH1","eH0","eH1","fH0","fH1");
}
if ($model eq "Ultra-1" | $ultra eq 1) {
	# Accepts 16MB, 32MB, 64MB or 128MB DIMMs on motherboard
	#   501-2479 (16MB), 501-2622 (32MB), 501-2480 or 501-5691 (64MB),
	#   501-3136 (128MB)
	#   200-pin 60ns Fast Page Mode ECC
	$devname="Neutron (Ultra 1), Electron (Ultra 1E), Dublin (Ultra 150)";
	$untested=0;
	$simmrangex="00000100";
	$simmbanks=4;
	$simmsperbank=2;
	@simmsizes=(16,32,64,128);
	@socketstr=("U0701","U0601","U0702","U0602","U0703","U0603","U0704","U0604");
	@bankstr=("0L","0H","1L","1H","2L","2H","3L","3H");
	@bytestr=("00-15","16-31","00-15","16-31","00-15","16-31","00-15","16-31");
}
if ($model eq "Ultra-2" | $ultra eq 2) {
	# Accepts 16MB, 32MB, 64MB or 128MB DIMMs on motherboard
	$devname="Pulsar";
	$untested=0;
	$simmrangex="00000200";
	$simmbanks=4;
	$simmsperbank=4;
	@simmsizes=(16,32,64,128);
	@socketstr=("U0501","U0401","U0701","U0601","U0502","U0402","U0702","U0602","U0503","U0403","U0703","U0603","U0504","U0404","U0704","U0604");
	@groupstr=(0,0,0,0,1,1,1,1,2,2,2,2,3,3,3,3);
	@bankstr=("0L","0H","1L","1H","0L","0H","1L","1H","0L","0H","1L","1H","0L","0H","1L","1H");
	@bytestr=("00-15","16-31","32-47","48-63","00-15","16-31","32-47","48-63","00-15","16-31","32-47","48-63","00-15","16-31","32-47","48-63");
}
if ($model eq "Ultra-30" | $ultra eq 30) {
	# Accepts 16MB, 32MB, 64MB or 128MB DIMMs on motherboard
	#   501-2479 (16MB), 501-2622 (32MB), 501-2480 or 501-5691 (64MB),
	#   501-3136 (128MB)
	#   200-pin 60ns Fast Page Mode ECC
	# Two DIMMs form a pair, two pairs of DIMMs form a quad.
	# Minumum requirements is two DIMMs in any adjacent pair.
	# DIMMs can be installed in any order of pairs.
	# Interleaving requires a fully populated quad.
	# Each quad addresses 512MB of memory.
	$devname="Quark";
	$untested=0;
	# simmrangex, simmbanks, and simmsperbank set later after determining
	# if interleaving banks using quads rather than pairs
	@simmsizes=(16,32,64,128);
	@socketstr=("U0701","U0801","U0901","U1001","U0702","U0802","U0902","U1002","U0703","U0803","U0903","U1003","U0704","U0804","U0904","U1004");
	@bankstr=("Quad 0 Pair 0","Quad 0 Pair 0","Quad 0 Pair 1","Quad 0 Pair 1","Quad 1 Pair 0","Quad 1 Pair 0","Quad 1 Pair 1","Quad 1 Pair 1","Quad 2 Pair 0","Quad 2 Pair 0","Quad 2 Pair 1","Quad 2 Pair 1","Quad 3 Pair 0","Quad 3 Pair 0","Quad 3 Pair 1","Quad 3 Pair 1");
}
if ($model eq "Ultra-5_10" | $ultra eq "5_10" | $ultra eq 5 | $ultra eq 10) {
	# Accepts 16MB, 32MB, 64MB, 128MB or 256MB DIMMs on motherboard
	# 16MB DIMM uses 10-bit column addressing and was not sold
	# 32, 64, 128 and 256MB DIMMs use 11-bit column addressing
	# Do not mix 16MB DIMMs with other sizes
	# 256MB DIMM not supported in Ultra 5 according to Sun documentation,
	# but they do work as long as you use low-profile DIMMs or take out the
	# floppy drive.
	# Memory speed is 60ns if 50ns and 60ns DIMMs are mixed
	# 2-way interleaving supported with four identical sized DIMMs
	# 50ns DIMMs supported on 375-0066 & 375-0079 motherboards
	# Bank 0 DIMM1/DIMM2 0x00000000-0x0fffffff, 0x20000000-0x2fffffff
	# Bank 1 DIMM3/DIMM4 0x10000000-0x1fffffff, 0x30000000-0x3fffffff
	$devname="Darwin/Otter (Ultra 5), Darwin/SeaLion (Ultra 10)";
	$untested=0;
	$simmrangex="00000100";
	$simmbanks=2;
	$simmsperbank=2;
	@simmsizes=(16,32,64,128,256);
	@socketstr=("DIMM1".."DIMM4");
	@bankstr=("0L","0H","1L","1H");
	$sortslots=0;
}
if ($model eq "Ultra-60" | $ultra eq 60 | $ultra eq "220R") {
	# Also Netra t1120/1125
	# Accepts 16MB, 32MB, 64MB or 128MB DIMMs on motherboard
	#   501-2479 (16MB), 501-2622 (32MB), 501-2480 or 501-5691 (64MB),
	#   501-3136 (128MB)
	#   200-pin 60ns Fast Page Mode ECC
	# U1001-U1004 bank 3 address 0xa0000000-0xbfffffff
	# U0901-U0904 bank 2 address 0x80000000-0x9fffffff
	# U0801-U0804 bank 1 address 0x20000000-0x3fffffff
	# U0701-U0704 bank 0 address 0x00000000-0x1fffffff
	$devname="Deuterium" if ($model eq "Ultra-60" | $ultra eq 60);
	$devname="Razor" if ($ultra eq "220R");
	$untested=0;
	$simmrangex="00000200";
	$simmbanks=6;	# Count the skipped address range
	$simmsperbank=4;
	@simmsizes=(16,32,64,128);
	@socketstr=("U0701".."U0704","U0801".."U0804","?","?","?","?","?","?","?","?","U0901".."U0904","U1001".."U1004");
	@bankstr=(0,0,0,0,1,1,1,1,"?","?","?","?","?","?","?","?",2,2,2,2,3,3,3,3);
}

#
# SPARCengine systems
#
if ($banner =~ /Netra t1\b/ | $ultra eq "Netra t1" | $model eq "Netra t1" | $banner =~ /Ultra CP 1500\b/ | $ultra eq "cp1500" | $ultra eq "Netra ct400" | $ultra eq "Netra ct800") {
	# Netra t1 100/105, Netra ct400/800, SPARCengine CP1500
	#  Accepts 1 or 2 64MB, 128MB, 256MB or 512MB mezzanine memory cards
	# Also used in Sun Fire 12K & Sun Fire 15K
	# Install the highest capacity memory board first
	# The 370-4155 was sold for use in the Netra t1 100/105
	# Up to four 370-4155 256MB memory boards can be installed
	# Only one 370-4155 can be mixed with any other memory boards
	# Cannot distinguish between 4 370-4155 256MB and 2 512MB memory boards
	# Maximum memory: 768MB for 270MHz/33MHz, 1GB for 360MHz/440MHz systems
	#
	#   Top slot ->  64MB    64MB   128MB   128MB   256MB   256MB   512MB
	# Bottom slot   SSF SS  DSF SS  SSF SS  DSF SS  DSF DS  DSF SS  DSF DS
	#       |
	#       v       ------  ------  ------  ------  ------  ------  ------
	#  64MB SSF SS  Y       N       Y       N       N       Y       N
	#  64MB DSF SS  Y       Y       Y       Y       Y       Y       Y
	# 128MB SSF SS  Y       N       Y       N       N       Y       N
	# 128MB DSF SS  Y       Y       Y       Y       Y       Y       Y
	# 256MB DSF SS  Y       Y       Y       Y       Y       Y       Y
	# 512MB DSF DS  Y/N *   Y/N *   Y/N *   Y/N *   Y/N *   Y/N *   Y/N *
	#
	# SSF=single-sided fab, DSF=double-sided fab
	# SS=stuffed on one side, DS=stuffed on both sides
	# * 512MB DSF DS board is supported on 360MHz and 440MHz systems,
	#   512MB DSF DS board is not supported on 270MHz and 333MHz systems
	# Lower board, address 0x00000000-0x0fffffff, 0x20000000-0x2fffffff
	# upper board, address 0x10000000-0x1fffffff, 0x30000000-0x3fffffff
	$devname="Flyweight (Model 100), Flapjack (Model 105)" if ($banner =~ /Netra t1\b/ | $ultra eq "Netra t1" | $model eq "Netra t1");
	$devname="Tonga, Monte Carlo" if ($ultra =~ /Netra ct[48]00\b/);
	$untested=0;
	$untested=1 if ($ultra eq "Netra ct400");
	$memtype="memory card";
	$sockettype="";
	$simmrangex="00000100";
	$simmbanks=2;
	$simmsperbank=1;
	@simmsizes=(64,128,256,512);
	@socketstr=("base mezzanine board","additional mezzanine board");
	@orderstr=("lower board","upper board");
	$sortslots=0;
}
if ($banner =~ /Ultra CP 1400\b/ | $ultra eq "cp1400") {
	# Accepts 1 or 2 64MB, 128MB, 256MB or 512MB mezzanine memory cards
	# Has 64MB on-board memory on motherboard
	# Maximum memory: 832MB (64MB motherboard, 512MB bottom, 256MB top)
	#
	#   Top slot ->  64MB    64MB   128MB   128MB   256MB   512MB
	# Bottom slot   SSF SS  DSF SS  SSF SS  DSF SS  DSF SS  DSF DS
	#       |
	#       v       ------  ------  ------  ------  ------  ------
	#  64MB SSF SS  Y       N       Y       N       Y       N
	#  64MB DSF SS  Y       Y       Y       Y       Y       N
	# 128MB SSF SS  Y       N       Y       N       Y       N
	# 128MB DSF SS  Y       Y       Y       Y       Y       N
	# 256MB DSF SS  Y       Y       Y       Y       Y       N
	# 512MB DSF DS  Y       Y       Y       Y       Y       N
	#
	# SSF=single-sided fab, DSF=double-sided fab
	# SS=stuffed on one side, DS=stuffed on both sides
	# 512MB DSF DS board is only supported in bottom slot
	#
	# Motherboard, address 0x00000000-0x03ffffff
	# Upper board, address 0x08000000-0xffffffff, 0x28000000-0x2fffffff
	# Lower board, address 0x10000000-0x17ffffff, 0x30000000-0x37ffffff
	$untested=0;
	$memtype="memory card";
	$sockettype="";
	$simmrangex="00000080";
	$simmbanks=3;
	$simmsperbank=1;
	@simmsizes=(64,128,256,512);
	@socketstr=("motherboard","additional mezzanine board","base mezzanine board");
	@orderstr=("","upper board","lower board");
	$sortslots=0;
}
if ($ultra eq "AX" | $ultra eq "AX-300") {
	# SPARCengine Ultra AX and AX-300
	# Accepts 8MB, 16MB, 32MB or 64MB DIMMs on motherboard
	# AX-300 also accepts 128MB DIMMs on motherboard
	$untested=0;		# unsure if socket order is correct
	$simmrangex="00000200";
	$simmbanks=2;
	$simmsperbank=4;
	@simmsizes=(8,16,32,64,128);
	@socketstr=("U0301".."U0304","U0401".."U0404");
	@bankstr=(0,0,0,0,1,1,1,1);
}
if ($ultra eq "AXi") {
	# SPARCengine Ultra AXi
	# Accepts 8MB, 16MB, 32MB, 64MB or 128MB single or dual bank 10-bit
	#  column address type DIMMs on motherboard in all socket pairs
	# Accepts 8MB, 16MB, 32MB, 64MB, 128MB or 256MB dual bank 11-bit
	#  column address type DIMMs on motherboard in Pairs 0 & 2
	#  (leave Pairs 1 & 3 empty)
	# DIMMs should be chosen as all 10-bit or all 11-bit column address type
	# Use 60ns DIMMs only
	$untested=0;
	$simmrangex="00000100";
	$simmbanks=4;
	$simmsperbank=2;
	@simmsizes=(8,16,32,64,128,256);
	@socketstr=("U0404","U0403","U0304","U0303","U0402","U0401","U0302","U0301");
	@bankstr=(0,0,2,2,1,1,3,3);
	$sortslots=0;
}
if ($ultra eq "AXmp" | $ultra eq "AXmp+") {
	# SPARCengine Ultra AXmp
	#  Accepts 8MB, 16MB, 32MB, 64MB or 128MB DIMMs on motherboard
	#  Accepts 256MB dual-bank DIMMs in bank 0 or 1 (not both)
	#  Can't distinguish dual-bank DIMMs from two banks of single bank DIMMs
	# SPARCengine Ultra AXmp+
	#  Accepts 8MB, 16MB, 32MB, 64MB, 128MB or 256MB DIMMs on motherboard
	#  Accepts dual-bank DIMMs in both bank 0 and 1
	#  Can't distinguish dual-bank DIMMs from two banks of single bank DIMMs
	$untested=0;
	$simmbanks=2;
	$simmsperbank=8;
	if ($ultra eq "AXmp+") {
		$simmrangex="00000400";
		@simmsizes=(8,16,32,64,128,256);
	} else {
		$simmrangex="00000800";
		@simmsizes=(8,16,32,64,128);
	}
	@socketstr=("U0701".."U0704","U0801".."U0804","U0901".."U0904","U1001".."U1004");
	@bankstr=(0,0,0,0,0,0,0,0,1,1,1,1,1,1,1,1);
	$sortslots=0;
}
if ($ultra eq "AXe") {
	# SPARCengine Ultra AXe
	# Accepts 32MB, 64MB, 128MB or 256MB single or dual bank DIMMs
	# DIMMs should be chosen as all 10-bit or all 11-bit column address type
	$untested=0;
	$simmrangex="00000100";
	$simmbanks=2;
	$simmsperbank=2;
	@simmsizes=(32,64,128,256);
	@socketstr=("DIMM3","DIMM4","DIMM1","DIMM2");
	@bankstr=(0,0,1,1);
	# Assume stacked DIMMs like AXi since only 128MB DIMMs have been tested
	$sortslots=0;
}
if ($ultra eq "AX-e2") {
	# Netra AX1105-500
	# Accepts up to 4 64MB, 128MB, 256MB or 512MB registered SDRAM PC133
	# DIMMs; 128MB Minimum, 2GB Maximum
	# DIMM0 & DIMM1 form Bank 0, DIMM2 & DIMM3 form Bank 1
	# DIMMs don't have to be installed as pairs
	$untested=0;
	$simmrangex="00000200";
	$simmbanks=4;
	$simmsperbank=1;
	@simmsizes=(64,128,256,512);
	@socketstr=("DIMM0".."DIMM3");
	@bankstr=(0,0,1,1);
}
if ($ultra eq "Netra X1" | $ultra eq "Sun Fire V100") {
	# Netra X1, Sun Fire V100, UltraAX-i2
	# Accepts up to 4 128MB or 256MB PC133 DIMMs for 1GB maximum
	# 500MHz model also accepts up to 4 512MB PC133 DIMMs for 2GB maximum
	# Have seen slower models also work with 512MB DIMMs for 2GB maximum
	# Sun Fire V100 is 500MHz only
	# The memory installation sequence is Slot 3, 2, 1, and 0.
	# Each DIMM slot addresses 512MB with 400MHz UltraSPARC IIe
	# Each DIMM slot addresses 1GB with >= 550MHz UltraSPARC IIe
	# Memory is SDRAM PC133 CL=3 ECC registered
	# When equal size DIMMs are installed, the lowest slot number is
	#  mapped to the lowest address range.
	# When mixed size DIMMs are installed, the slot number with the largest
	#  size DIMM is mapped to the lowest address range.
	$devname="Flapjack-lite" if ($ultra eq "Netra X1");
	$devname="Flapjack-liteCD500" if ($ultra eq "Sun Fire V100");
	$untested=0;
	$simmrangex=($cpufreq > 520) ? "00000400" : "00000200";
	$simmbanks=4;
	$simmsperbank=1;
	@simmsizes=(128,256,512);
	@socketstr=("DIMM0".."DIMM3");
}
if ($ultra eq "Netra T1 200" | $ultra eq "Sun Fire V120" | $ultra eq "Netra 120") {
	# Netra T1 200, Sun Fire V120, Netra 120, UltraAX-i2
	# Accepts up to 4 256MB, 512MB or 1GB PC133 DIMMs for 4GB maximum
	# Sun Fire V120 is 550MHz or 650MHz
	# Netra 120 is same platform as Sun Fire V120, but is 650MHz only
	# Memory is SDRAM PC133 CL=3 ECC registered
	# The minimum memory requirement is one DIMM in Slot 0
	# The memory installation sequence is Slot 0, 1, 2, 3
	# Each DIMM slot addresses 512MB of memory with 500MHz UltraSPARC IIe
	# Each DIMM slot addresses 1GB of memory with >= 550MHz UltraSPARC IIe
	# When equal size DIMMs are installed, the lowest slot number is
	#  mapped to the lowest address range.
	# When mixed size DIMMs are installed, the slot number with the largest
	#  size DIMM is mapped to the lowest address range.
	$devname="Flapjack2" if ($ultra eq "Netra T1 200");
	$devname="Flapjack2 plus" if ($ultra eq "Sun Fire V120" | $ultra eq "Netra 120");
	$untested=0;
	$simmrangex=($cpufreq > 520) ? "00000400" : "00000200";
	$simmbanks=4;
	$simmsperbank=1;
	@simmsizes=(256,512,1024);
	@socketstr=("DIMM0".."DIMM3");
}

#
# Clones: most do not have verbose output since I don't have any socket data
# on them
#
if ($ultra eq "axus250" | $modelmore =~ /Ultra-250/) {
	# AXUS Microsystems, Inc. http://www.axus.com.tw
	# AXUS 250 clone
	# accepts up to 128MB DIMMs on motherboard
	$untested=0;
	$simmrangex="00000200";
	$simmbanks=4;
	$simmsperbank=4;
	@simmsizes=(8,16,32,64,128);
	@socketstr=("U0501","U0601","U0701","U0801","U0502","U0602","U0702","U0802","U0503","U0603","U0703","U0803","U0504","U0604","U0704","U0804");
	@bankstr=(0,0,0,0,1,1,1,1,2,2,2,2,3,3,3,3);
}
if ($model =~ /SPARC CPU-/ | $model =~ /SPARC CPCI-/) {
	# Force Computers, http://www.forcecomputers.com
	# model format: "SPARC CPU-5V/64-110-X" for 64MB w/ 110MHz CPU
	$untested=1;
	$untested=0 if ($model =~ /SPARC CPU-/);
	if ( $model =~ /\/${installed_memory}-/ ) {
		$totmem=$installed_memory;
		push(@simmsizesfound, "$totmem");
		$buffer="motherboard contains ${totmem}MB on-board memory\n";
		&finish;
	}
}
if ($model =~ /Axil/) {
	# RAVE Computer Association, http://rave.com
	$untested=1;
	$untested=0 if ($model =~ /Axil-245/);
	$untested=0 if ($model =~ /Axil-255/);
	$untested=0 if ($model =~ /Axil-311/);
	$untested=0 if ($model =~ /Axil-320/);
}
if ($manufacturer =~ /Tadpole/) {
	# Tadpole RDI, http://www.tadpole.com
	$untested=1;
	$untested=0 if ($banner =~ /Tadpole S3/);
	$untested=0 if ($model =~ /PowerLite-170/);
	$untested=0 if ($banner =~ /\bVoyagerIIi\b/);
	$untested=0 if ($banner =~ /\bCycleQUAD\b/);
	if ($ultra eq "UP-20") {
		# Cycle UP-20 to upgrade SPARCstation 5/20 motherboards
		# Accepts 16MB, 32MB and 64MB SIMMs from SPARCstation 20
		# Install SIMMs in pairs to form each bank
		$untested=1;
		$simmrangex="00000040";
		$simmbanks=4;
		$simmsperbank=2;
		@simmsizes=(16,32,64);
		@bankstr=(0,0,1,1,2,2,3,3);
	}
	if ($ultra eq "UP-520IIi") {
		# Cycle UP-520-IIi to upgrade SPARCstation 5/20 motherboards
		# Accepts 8MB, 16MB, 32MB, 64MB, 128MB and 256MB DIMMs
		$untested=0;
		$simmrangex="00000200";
		$simmbanks=4;
		$simmsperbank=2;
		@simmsizes=(8,16,32,64,128,256);
		@socketstr=("J301".."J304");
		@bankstr=(0,0,1,1);
	}
	if ($banner =~ /\bSPARCLE\b/) {
		# UltraSPARC-IIe at 440MHz, 500MHz, or 650MHz
		# 256MB - 2GB ECC SDRAM, two slots, PC-133, 144-pin SO-DIMMs
		$untested=0;
		$simmbanks=2;
		$simmsperbank=1;
		@simmsizes=(128,256,512,1024);
		@socketstr=("DIMM0","DIMM1");
		$memtype="SO-DIMM";
	}
}
if ($manufacturer eq "Auspex") {
	# Auspex Netserver, http://www.auspex.com
	$memtype="Memory Module";
	$untested=1;
	$untested=0 if ($model eq "SPARC Processor");
	if ($osrel =~ /^5./) {
		$untested=1;	# Untested with Solaris 2.X
		$untested_type="OS";
	}
}
if ($manufacturer =~ /Fujitsu/) {
	# Hal Computer Systems, a Fujitsu Company, http://www.hal.com
	# Fujitsu Siemens, http://www.fujitsu-siemens.com
	$untested=1;
	$untested=0 if ($model =~ /S-4\/10H/ | $model =~ /S-4\/20[ABLH]/);
	if ($banner =~ /GP7000\b/ | $banner =~ /GP7000F\b/) {
		$untested=0;
		if ($slotname0 =~ /SLOT[0-9]/) {
			# M200
			# Up to 4GB of memory
			# System board has 16 DIMM slots, #00 - #15
			# Banks - 0,0,1,1,2,2,2,2,3,3,3,3,4,4,4,4
			# First Modules installed in Bank 0, slots 0-1
			# Second Modules Installed in Bank 1, slots 2-3
			# Modules in Bank 0 and 1 must be same size
			# Subsequent memory expansion installed in sets of four
			#   modules in Bank 2 - 4 (Slots 4-7, 8-11, 12-15)
			@socketstr=("SLOT0".."SLOT9","SLOT10".."SLOT15");
		}
		if ($slotname0 =~ /SLOT[AB][0-9]/) {
			# M400 and M600
			# Up to 4GB of memory
			# System board has 32 DIMM slots, #00 - #15 Group A & B
			# Banks - 0,0,1,1,2,2,2,2,3,3,3,3,4,4,4,4
			# First Modules installed in Bank 0 Group A, slots 0-1
			# Second Modules installed in Bank 0 Group B, slots 0-1
			# Modules in Group A and B must be same size
			# Next memory expansion installs in Bank 1 Group A & B,
			#   slots 2-3 using modules of same size as Bank 0
			# Subsequent memory expansion installed in sets of eight
			#   modules in Bank 2 - 4 (Slots 4-7, 8-11, 12-15) in
			#   both Group A and B
			@socketstr=("SLOTA0".."SLOTA9","SLOTA10".."SLOTA15","SLOTB0".."SLOTB9","SLOTB10".."SLOTB15");
		}
	}
	if ($banner =~ /PRIMEPOWER *100N?\b/) {
		# PRIMEPOWER100N, 1U rack mount
		# Up to 2GB of memory
		# 4 memory module slots
		# 100MHz SDRAM ECC
		# Mount memory modules in order from memory module slot 0
		$untested=1;
	}
	if ($banner =~ /PRIMEPOWER *[246]00\b/) {
		# Up to 8GB of memory
		# Each system board has 16 DIMM slots, #00 - #15
		# Four banks of 4 (0-3,4-7,8-11,12-15)
		# PrimePower 200 and 400 use 1 system board
		# PrimePower 600 uses 2 system boards (00, 01)
		$untested=0;
		foreach $brd ("00","01") {
			if ($gotcpuboards =~ /\b${brd}\b/) {
				if ($gotmodulenames =~ /${brd}-SLOT[0-9]/) {
					foreach $i (0..15) {
						push(@socketstr, ("${brd}-SLOT$i"));
					}
				}
			}
		}
	}
	if ($banner =~ /PRIMEPOWER *800\b/ | $banner =~ /PRIMEPOWER *1000\b/ | $banner =~ /PRIMEPOWER *2000\b/) {
		# 1-4 SPARC64 GP CPUs / system board
		# PrimePower 800 can have 4 system boards per system
		# PrimePower 1000 can have 8 system boards per system
		# PrimePower 2000 can have 32 system boards per system
		# Minimum Memory: 1GB / system board, 2GB / system
		# Maximum Memory: 8GB / system board, 32GB / system
		# 32 or 16 memory modules per system board, installed in quads
		$untested=0;
		@simmsizes=(128,256,512);
		foreach $brd ("00".."77") {
			if ($gotcpuboards =~ /\b${brd}\b/) {
				if ($gotmodulenames =~ /${brd}-SLOT#[AB][0-9]/) {
					foreach $j ("A","B") {
						foreach $i ("00".."03","10".."13","20".."23","30".."33") {
							push(@socketstr, ("${brd}-SLOT#$j$i"));
						}
					}
				}
			}
		}
	}
	if ($banner =~ /PRIMEPOWER *250\b/) {
		# Pedestal, 2U or 4U rack mount
		# 1-2 SPARC64 V processors at 1.1GHz, 1.32GHz, 1.87GHz
		# 1GB-16GB DDR-SDRAM memory with ECC, 2-way, 8 DIMM slots
		$untested=0;
		@simmsizes=(256,512,1024,2048);
		foreach $i ("00".."07") {
			push(@socketstr, ("SLOT#$i"));
		}
	}
	if ($banner =~ /PRIMEPOWER *450\b/) {
		# Pedestal, 4U or 7U rack mount
		# 1-4 SPARC64 V processors at 1.1GHz, 1.32GHz, 1.87GHz
		# 1GB-32GB DDR-SDRAM memory with ECC, 4-way, 16 DIMM slots
		$untested=0;
		@simmsizes=(256,512,1024,2048);
		foreach $i ("00".."15") {
			push(@socketstr, ("SLOT#$i"));
		}
	}
	if ($banner =~ /PRIMEPOWER *[68]50\b/) {
		# PrimePower 650: 2-8 SPARC64 V processors at 1.1GHz or faster
		#   2GB-64GB memory, 8-way, 1 system board, 8U rack mount
		# PrimePower 850: 4-16 SPARC64 V processors at 1.1GHz or faster
		#   2GB-128GB memory, 16-way, 2 system boards, 16U rack mount
		# Uses DDR SDRAM ECC memory in 256MB, 512MB and 1GB sizes
		# Each system board has 32 memory module slots, layed out
		# with 4 DIMM modules on 8 DIMM riser cards.
		$untested=0;
		@simmsizes=(256,512,1024,2048);
		foreach $brd ("C0S00","C0S01") {
			if ($gotcpuboards =~ /\b${brd}\b/) {
				if ($gotmodulenames =~ /${brd}-SLOT#[A-D][0-9]/) {
					foreach $j ("A".."D") {
						foreach $i ("00".."07") {
							push(@socketstr, ("${brd}-SLOT#$j$i"));
						}
					}
				}
			}
		}
	}
	if ($banner =~ /PRIMEPOWER *HPC2500\b/ | $banner =~ /PRIMEPOWER *900\b/ | $banner =~ /PRIMEPOWER *[12]500\b/) {
		# SPARC64 V CPUs at 1.3GHz or 1.89GHz
		# PRIMEPOWER HPC2500 / 2500
		#   2-8 CPUs / system board, 64-128 / system
		#   Up to 16 8-way system boards / system
		#   Up to 1024GB DDR-SDRAM memory with ECC, 128-way
		#   Minimum Memory: 4GB / system board, 4GB / system
		#   Maximum Memory: 64GB / system board, 1024GB / system
		# PRIMEPOWER 900
		#   17U rack mount
		#   1-8 CPUs / system board, 1-16 / system
		#   Up to 2 8-way system boards / system
		#   Up to 128GB DDR-SDRAM memory with ECC, 8-way
		#   Minimum Memory: 2GB / system board, 2GB / system
		#   Maximum Memory: 64GB / system board, 128GB / system
		# PRIMEPOWER 1500
		#   1-8 CPUs / system board, 1-32 / system
		#   Up to 4 8-way system boards / system
		#   Up to 256GB DDR-SDRAM memory with ECC, 8-way
		#   Minimum Memory: 2GB / system board, 2GB / system
		#   Maximum Memory: 64GB / system board, 256GB / system
		$untested=0;
		@simmsizes=(256,512,1024,2048);
		foreach $cab ("C0S","C1S") {
			foreach $brd ("00".."07") {
				if ($gotcpuboards =~ /\b${cab}${brd}\b/) {
					foreach $j ("A","B") {
						foreach $i ("00".."15") {
							push(@socketstr, ("${cab}${brd}-SLOT#$j$i"));
						}
					}
				}
			}
		}
	}
}
if ($model =~ /COMPstation.10/) {
	# Tatung Science and Technology, http://www.tsti.com
	# Accepts 16MB and 64MB SIMMs on motherboard
	# Bank 0 must be filled first
	# Layout is like SPARCstation-10, but I don't know if it can accept
	# 32MB SIMMs or NVSIMMs
	$untested=0;
	$simmrangex="00000040";
	$simmbanks=8;
	$simmsperbank=1;
	@simmsizes=(16,64);
	@socketstr=("J0201","J0203","J0302","J0304","J0202","J0301","J0303","J0305");
	@bankstr=(0,2,4,6,1,3,5,7);
}
if ($model =~ /COMPstation-20A\b/) {
	# Tatung Science and Technology, http://www.tsti.com
	# Accepts 16MB, 32MB and 64MB SIMMs on motherboard
	$untested=1;
	$simmrangex="00000040";
	$simmbanks=8;
	$simmsperbank=1;
	@simmsizes=(16,32,64);
	@socketstr=("J0201","J0304","J0203","J0302","J0303","J0301","J0305","J0202");
	@orderstr=("1st","2nd","3rd","4th","5th","6th","7th","8th");
	@bankstr=(1..8);
}
if ($model =~ /COMPstation-20AL/) {
	# Tatung Science and Technology, http://www.tsti.com
	# Accepts 16MB, 32MB and 64MB SIMMs on motherboard
	$untested=0;
	$simmrangex="00000040";
	$simmbanks=8;
	$simmsperbank=1;
	@simmsizes=(16,32,64);
	@socketstr=("J0201","J0203","J0302","J0304","J0202","J0301","J0303","J0305");
	@orderstr=("1st","2nd","3rd","4th","5th","6th","7th","8th");
	@bankstr=(0..7);
}
if ($banner =~ /COMPstation_U60_Series/ | $banner =~ /COMPstation_U80D_Series/) {
	# Tatung Science and Technology, http://www.tsti.com
	# Accepts 16MB, 32MB, 64MB, 128MB or 256MB DIMMs on motherboard
	# 4 banks with 4 DIMMs per bank
	$untested=0;
	$simmrangex="00000200"; # use "00000400" with 256MB DIMMs
	$simmbanks=6;	# Count the skipped address range
	$simmsperbank=4;
	@simmsizes=(16,32,64,128,256);
}
if ($model =~ /\bVoyagerIIi\b/) {
	# Tadpole Voyager IIi has 8 DIMM slots, but otherwise appears
	# to look like an Ultra 5. It allows 256MB to 1GB of memory.
	$untested=0;
	$simmrangex="00000100";
	$simmbanks=4;
	$simmsperbank=2;
	@simmsizes=(16,32,64,128);
	@socketstr=("DIMM1","DIMM2","DIMM5","DIMM6","DIMM3","DIMM4","DIMM7","DIMM8");
	$sortslots=1;
}

#
# systems below may have memory information available in prtdiag output
#
if ($model eq "SPARCserver-1000" | $model eq "SPARCcenter-2000") {
	$devname="Scorpion" if ($model eq "SPARCserver-1000");
	$devname="Dragon" if ($model eq "SPARCcenter-2000");
	# Accepts 8MB and 32MB SIMMs on motherboard
	$untested=0;
	@simmsizes=(8,32);
	$prtdiag_has_mem=1;
	&check_prtdiag;
	if ($boardfound_mem) {
		foreach $line (@boards_mem) {
			if ($line =~ /Board/) {
				$boardslot_mem=substr($line,5,1);
				$simmsize=int substr($line,46,3) / 4;
				if ($simmsize == 0) {
					&found_empty_bank("Group 0");
				} elsif ($simmsize == 1) {
					&found_nvsimm_bank("Group 0");
				} else {
					push(@simmsizesfound, "$simmsize");
				}
				$simmsize=int substr($line,54,3) / 4;
				if ($simmsize == 0) {
					&found_empty_bank("Group 1");
				} elsif ($simmsize == 1) {
					&found_nvsimm_bank("Group 1");
				} else {
					push(@simmsizesfound, "$simmsize");
				}
				$simmsize=int substr($line,62,3) / 4;
				if ($simmsize == 0) {
					&found_empty_bank("Group 2");
				} elsif ($simmsize == 1) {
					&found_nvsimm_bank("Group 2");
				} else {
					push(@simmsizesfound, "$simmsize");
				}
				$simmsize=int substr($line,70,3) / 4;
				if ($simmsize == 0) {
					&found_empty_bank("Group 3");
				} elsif ($simmsize == 1) {
					&found_nvsimm_bank("Group 3");
				} else {
					push(@simmsizesfound, "$simmsize");
				}
			}
		}
		&show_header;
		print @boards_mem;
		print "Each memory unit group is comprised of 4 SIMMs\n";
		$empty_banks=" None" if ($empty_banks eq "");
		print "empty memory groups:$empty_banks\n";
	} else {
		&show_header;
		$recognized=0;
	}
	$totmem=$installed_memory;
	&finish;
	exit;
}
if ($model eq "Ultra-4" | $ultra eq 450 | $model eq "Ultra-4FT" | $ultra eq "Netra ft1800") {
	# Accepts 32MB, 64MB, 128MB or 256MB DIMMs on motherboard
	# 16MB DIMMs are not supported and may cause correctable ECC errors
	#   501-2622 (32MB), 501-2480 or 501-5691 (64MB), 501-3136 (128MB),
	#   501-4743 or 501-5896 (256MB)
	#   200-pin 60ns Fast Page Mode ECC
	# Netra ft1800 is based on Ultra 450
	$devname="Tazmo (Tazmax/Tazmin)";
	$untested=0;
	$simmrangex="00000400";
	$simmbanks=4;
	$simmsperbank=4;
	@simmsizes=(16,32,64,128,256);
	@socketstr=("U1901".."U1904","U1801".."U1804","U1701".."U1704","U1601".."U1604");
	@groupstr=("A","A","A","A","B","B","B","B","C","C","C","C","D","D","D","D");
	@bankstr=(2,2,2,2,3,3,3,3,0,0,0,0,1,1,1,1);
}
if ($model eq "Ultra-250" | $ultra eq 250) {
	# Accepts 16MB, 32MB, 64MB, or 128MB DIMMs on motherboard
	#   501-2479 (16MB), 501-2622 (32MB), 501-2480 or 501-5691 (64MB),
	#   501-3136 (128MB)
	#   200-pin 60ns Fast Page Mode ECC
	$devname="Javelin";
	$untested=0;
	$simmrangex="00000200";
	$simmbanks=4;
	$simmsperbank=4;
	@simmsizes=(16,32,64,128);
	@socketstr=("U0701","U0801","U0901","U1001","U0702","U0802","U0902","U1002","U0703","U0803","U0903","U1003","U0704","U0804","U0904","U1004");
	@bankstr=("A","A","A","A","B","B","B","B","C","C","C","C","D","D","D","D");
}
if ($model eq "Ultra-80" | $ultra eq 80 | $ultra eq "420R" | $ultra eq "Netra t140x") {
	# Accepts 32MB, 64MB, 128MB or 256MB DIMMs on motherboard, but Sun
	# only supports 64MB or 256MB DIMMs on motherboard
	#   501-5691 (64MB), 501-4743 (256MB)
	#   200-pin 60ns 5V Fast Page Mode ECC, 576 bits data width
	# 64MB DIMMs same as in Ultra-60, 256MB DIMMs same as in Enterprise-450
	# U0403,U0404,U1403,U1404 bank 3 address 0xc0000000-0xffffffff
	# U0303,U0304,U1303,U1304 bank 2 address 0x80000000-0xbfffffff
	# U0401,U0402,U1401,U1402 bank 1 address 0x40000000-0x7fffffff
	# U0301,U0302,U1301,U1302 bank 0 address 0x00000000-0x3fffffff
	# The minimum requirement is four DIMMs in any bank. DIMMs can be
	# installed in any bank order. DIMMs are required on both the Riser
	# Board (U0[34]0?) and the System Board (U1[34]0?). Two-way and
	# four-way memory bank interleaving is supported.
	#
	# prtconf does not reliably show the size of DIMMs in each slot.
	# It shows this:
	#  4096MB system: 00000000.00000000.00000001.00000000
	#  1536MB system: 00000000.00000000.00000000.60000000
	#  1024MB system: 00000000.00000000.00000000.40000000
	#   512MB system: 00000000.00000000.00000000.20000000
	#   256MB system: 00000000.00000000.00000000.10000000
	# which is useless! A system with 4GB is reported as having
	# 4 1GB DIMMs instead of 16 256MB DIMMs.
	# This is apparently an issue that Sun may fix in the OBP.
	# It is broken with OBP 3.33.0 2003/10/07 (patch 109082-06) and older.
	#
	# prtfru (Solaris 8 and later) also does not work!
	#
	# Sun ships U80 1GB configurations w/ 4x256MB DIMMs
	# Sun ships U80 256MB configurations w/ 4x64MB DIMMs
	# 64MB DIMM 501-2480 and 128MB DIMM 501-3136 are not supported.
	# 16MB and 32MB DIMMs are not sold for the Ultra 80.
	#
	$devname="Quasar (U80), Quahog (420R), Lightweight 3 (Netra t140x)";
	$devname="Quasar" if ($ultra eq 80);
	$devname="Quahog" if ($ultra eq "420R");
	$devname="Lightweight 3" if ($ultra eq "Netra t140x");
	$untested=0;
	$recognized=-1;
	$simmrangex="00000400";
	$simmbanks=4;
	$simmsperbank=4;
	@simmsizes=(32,64,128,256); # Sun only supports 64MB and 256MB DIMMs
	@socketstr=("U0301","U0302","U1301","U1302","U0401","U0402","U1401","U1402","U0303","U0304","U1303","U1304","U0403","U0404","U1403","U1404");
	@bankstr=(0,0,0,0,1,1,1,1,2,2,2,2,3,3,3,3);
}
if ($ultra eq "Sun Blade 1000" | $ultra eq "Sun Blade 2000" | $ultra eq "Sun Fire 280R" | $ultra eq "Netra 20") {
	# Accepts up to 8 128MB, 256MB, 512MB, 1GB or 2GB DIMMs installed in
	#  groups of four DIMMs per bank on motherboard
	# Uses 232-pin 3.3V ECC 7ns SDRAM
	# J0407 Group 1 Bank 1/3 address 0x0fa000000 - 0x1f3ffffff
	# J0406 Group 0 Bank 0/2 address 0x000000000 - 0x0f9ffffff
	# J0305 Group 1 Bank 1/3 address 0x0fa000000 - 0x1f3ffffff
	# J0304 Group 0 Bank 0/2 address 0x000000000 - 0x0f9ffffff
	# J0203 Group 1 Bank 1/3 address 0x0fa000000 - 0x1f3ffffff
	# J0202 Group 0 Bank 0/2 address 0x000000000 - 0x0f9ffffff
	# J0101 Group 1 Bank 1/3 address 0x0fa000000 - 0x1f3ffffff
	# J0100 Group 0 Bank 0/2 address 0x000000000 - 0x0f9ffffff
	# The minimum memory requirement is four DIMMs in any Group
	# DIMMs can be installed in any group order
	# Each group addresses 4GB of memory
	# Memory slots (Jxxxx) map to same-numbered DIMMs (Uxxxx)
	# For maximum 4-way interleaving, install 8 DIMMs of identical sizes
	$devname="Excalibur (Sun Blade 1000), Littleneck (Sun Fire 280R), Lightweight 2+ (Netra 20/Netra T4), Sun Blade 2000 (Sun Blade 2000)";
	$devname="Excalibur" if ($ultra eq "Sun Blade 1000");
	$devname="Littleneck" if ($ultra eq "Sun Fire 280R");
	$devname="Lightweight 2+" if ($ultra eq "Netra 20");
	$devname="Sun Blade 2000" if ($ultra eq "Sun Blade 2000");
	$untested=0;
	# SB1000/2000 uses 501-4143, 501-5938, 501-6230 or 501-6560 motherboards
	# SB1000 can use 600, 750 and 900MHz UltraSPARC-III CPUs
	# SB1000 can use 900MHz and faster UltraSPARC-III+ Cu CPUs
	# SB2000 only shipped with 900MHz and faster UltraSPARC-III+ Cu CPUs
	# assume all SB2000 use 501-6230 or 501-6560 motherboard
	if (($motherboard =~ /501-6230/ | $motherboard =~ /501-6560/) & $ultra eq "Sun Blade 1000") {
		$modelmore=$banner;
		$modelmore=~s/Sun-Blade-1000/or Sun-Blade-2000/g;
		while (($cf,$cnt) = each(%cpucnt)) {
			$cf=~/^(.*) (.*)$/;
			$cfreq=$2;
			$modelmore=~s/\)/ ${cfreq}MHz\)/g if ($cfreq);
		}
	}
	$prtdiag_has_mem=1;
	$simmrangex="00001000";
	$simmbanks=2;
	$simmsperbank=4;
	@simmsizes=(128,256,512,1024,2048);
	@socketstr=("J0100","J0202","J0304","J0406","J0101","J0203","J0305","J0407");
	@bankstr=(0,0,0,0,1,1,1,1);
}
if ($model eq "Sun-Blade-100" | $ultra eq "Sun Blade 100" | $ultra eq "Sun Blade 150") {
	# Accepts 128MB, 256MB or 512MB DIMMs on motherboard
	# Uses 168-pin 3.3V ECC PC133 CL=3 SDRAM
	# U5 DIMM3 address 0x60000000 - 0x7fffffff or 0xc0000000 - 0xffffffff
	# U4 DIMM2 address 0x40000000 - 0x5fffffff or 0x80000000 - 0xbfffffff
	# U3 DIMM1 address 0x20000000 - 0x3fffffff or 0x40000000 - 0x7fffffff
	# U2 DIMM0 address 0x00000000 - 0x1fffffff or 0x00000000 - 0x3fffffff
	# The minimum memory requirement is one DIMM in U2
	# The memory installation sequence is U2, U3, U4, U5
	# Each bank addresses 512MB of memory with 500MHz UltraSPARC
	# Each bank addresses 1GB of memory with >= 550MHz UltraSPARC
	$devname="Grover" if ($model eq "Sun-Blade-100" | $ultra eq "Sun Blade 100");
	$devname="Grover Plus" if ($ultra eq "Sun Blade 150");
	$untested=0;
	$prtdiag_has_mem=1;
	$simmrangex=($cpufreq > 520) ? "00000400" : "00000200";
	$simmbanks=4;
	$simmsperbank=1;
	@simmsizes=(128,256,512);
	@socketstr=("DIMM0".."DIMM3");
	@bankstr=(0..3);
}
if ($ultra eq "Sun Fire" | $ultra eq "Sun Fire 15K" | $ultra eq "Sun Fire 12K" | $ultra =~ /Sun Fire [346]8[01]0\b/ | $ultra =~ /Sun Fire E[246]900\b/ | $ultra =~ /Sun Fire E2[05]K\b/) {
	# Sun Fire 3800 system
	#   2-8 UltraSPARC-III processors
	#   Up to 2 CPU/Memory boards
	# Sun Fire 4800, 4810 and 6800 system
	#   2-12 UltraSPARC-III processors
	#   Up to 3 CPU/Memory boards
	# Sun Fire 6800 system
	#   2-24 UltraSPARC-III processors
	#   Up to 6 CPU/Memory boards
	# Sun Fire 15K system
	#   16-106 UltraSPARC-III+ processors
	#   Up to 18 CPU/Memory boards
	# Sun Fire 12K system
	#   up to 56 UltraSPARC-III+ processors and 288GB memory
	# Sun Fire E2900 & E4900 system
	#   4, 8, or 12 UltraSPARC-IV or IV+ processors, up to 3 Uniboards
	#   E4900 adds dynamic system domains when compared to E2900
	# Sun Fire E6900 system
	#   4-24 UltraSPARC-IV or IV+ processors, up to 6 Uniboards
	# Sun Fire E20K system
	#   4-36 UltraSPARC-IV or IV+ processors, up to 9 Uniboards
	# Sun Fire E25K system
	#   Up to 72 UltraSPARC-IV or IV+ processors, up to 18 Uniboards
	# Each CPU/Memory board holds up to 4 processors and up to 32GB memory
	#  (32 DIMMs per board, 8 banks of 4 DIMMs)
	# Accepts 256MB, 512MB or 1GB DIMMs
	#  1GB DIMM not supported at 750MHz
	#  256MB DIMM only supported on US-III
	# System Board slots are labeled SB0 and higher
	# A populated DIMM bank requires an UltraSPARC CPU.
	# DIMMs are 232-pin 3.3V ECC 7ns SDRAM
	# prtdiag output shows the memory installed.
	#
	# CPU1 and CPU0 Memory  CPU3 and CPU2 Memory
	# --------------------  --------------------
	# Socket CPU Bank DIMM  Socket CPU Bank DIMM
	# ------ --- ---- ----  ------ --- ---- ----
	# J14600  P1  B0   D3   J16600  P3  B0   D3
	# J14601  P1  B1   D3   J16601  P3  B1   D3
	# J14500  P1  B0   D2   J16500  P3  B0   D2
	# J14501  P1  B1   D2   J16501  P3  B1   D2
	# J14400  P1  B0   D1   J16400  P3  B0   D1
	# J14401  P1  B1   D1   J16401  P3  B1   D1
	# J14300  P1  B0   D0   J16300  P3  B0   D0
	# J14301  P1  B1   D0   J16301  P3  B1   D0
	# J13600  P0  B0   D3   J15600  P2  B0   D3
	# J13601  P0  B1   D3   J15601  P2  B1   D3
	# J13500  P0  B0   D2   J15500  P2  B0   D2
	# J13501  P0  B1   D2   J15501  P2  B1   D2
	# J13400  P0  B0   D1   J15400  P2  B0   D1
	# J13401  P0  B1   D1   J15401  P2  B1   D1
	# J13300  P0  B0   D0   J15300  P2  B0   D0
	# J13301  P0  B1   D0   J15301  P2  B1   D0
	#
	$devname="Serengeti" if ($ultra eq "Sun Fire");
	$devname="Serengeti8, SF3800 or SP" if ($banner =~ /Sun Fire 3800\b/ | $diagbanner =~ /Sun Fire 3800\b/);
	$devname="Serengeti12, SF4800 or MD" if ($banner =~ /Sun Fire 4800\b/ | $diagbanner =~ /Sun Fire 4800\b/);
	$devname="Serengeti12i, SF4810 or ME" if ($banner =~ /Sun Fire 4810\b/ | $diagbanner =~ /Sun Fire 4810\b/);
	$devname="Serengeti24, SF6800 or DC" if ($banner =~ /Sun Fire 6800\b/ | $diagbanner =~ /Sun Fire 6800\b/);
	$devname="Starcat, Serengeti72" if ($ultra eq "Sun Fire 15K");
	$devname="Starkitty" if ($ultra eq "Sun Fire 12K");
	$devname="Amazon 2" if ($banner =~ /Sun Fire E2900\b/ | $diagbanner eq "Sun Fire E2900");
	$devname="Amazon 4" if ($banner =~ /Sun Fire E4900\b/ | $diagbanner eq "Sun Fire E4900");
	$devname="Amazon 6" if ($banner =~ /Sun Fire E6900\b/ | $diagbanner eq "Sun Fire E6900");
	$devname="Amazon 20" if ($banner =~ /Sun Fire E20K\b/ | $diagbanner eq "Sun Fire E20K");
	$devname="Amazon 25" if ($banner =~ /Sun Fire E25K\b/ | $diagbanner eq "Sun Fire E25K");
	$untested=0;
	$untested=1 if ($devname =~ /Amazon/);
	$untested=0 if ($devname eq "Amazon 2");
	$prtdiag_has_mem=1;
	@simmsizes=(256,512,1024);
}
if ($ultra eq "Sun Fire V880") {
	# Accepts 128MB, 256MB, 512MB or 1GB DIMMs in groups of four per CPU
	# 128MB DIMMs only supported on 750MHz CPU/memory boards
	# 1GB DIMMs only supported on 900MHz or faster CPU/memory boards
	# 2-8 UltraSPARC-III processors, 750MHz or faster
	# Up to 64GB memory, 8GB max per CPU, 4 DIMMs per CPU, 2 CPUs per board
	# DIMMs must be added four-at-a-time within the same group of DIMM
	#  slots; every fourth slot belongs to the same DIMM group.
	# Each CPU/Memory board must be populated with a minimum of eight DIMMs,
	#  installed in groups A0 and B0.
	# For 1050MHz and higher system boards, each CPU/Memory board must be
	#  populated with all sixteen DIMMs, installed in groups A0,A1,B0,B1.
	# Each group used must have four identical DIMMs installed (all four
	#  DIMMs must be from the same manufacturing vendor and must have the
	#  same capacity).
	# DIMMs are 232-pin 3.3V ECC 7ns SDRAM
	# Uses 128-bit-wide path to memory, 150MHz DIMM modules, 2.4GB/sec
	#   bandwidth to processor and an aggregate memory bw of 9.6GB/sec
	# prtdiag output shows the memory installed.
	#
	# CPU CPU/Memory Slot Associated DIMM Group
	# --- --------------- ---------------------
	#  0      Slot A             A0,A1
	#  2      Slot A             B0,B1
	#  1      Slot B             A0,A1
	#  3      Slot B             B0,B1
	#  4      Slot C             A0,A1
	#  6      Slot C             B0,B1
	#  5      Slot D             A0,A1
	#  7      Slot D             B0,B1
	#
	$devname="Daktari";
	$untested=0;
	@simmsizes=($cpufreq < 800) ? (128,256,512) : (256,512,1024,2048);
	@banksstr=("A0","A1","B0","B1");
	$prtdiag_has_mem=1;
}
if ($ultra eq "Sun Fire V480") {
	# Accepts 256MB, 512MB or 1GB DIMMs in groups of four per CPU
	# 2 or 4 UltraSPARC-III processors, 900MHz or faster
	# Up to 32GB memory, 8GB max per CPU, 4 DIMMs per CPU, 2 CPUs per board
	# Smaller version of Sun Fire V880 above
	$devname="Cherrystone, cstone";
	$untested=0;
	@simmsizes=(256,512,1024,2048);
	@banksstr=("A0","A1","B0","B1");
	$prtdiag_has_mem=1;
}
if ($ultra eq "Sun Fire V490" | $ultra eq "Sun Fire V890") {
	# Accepts 512MB or 1GB DIMMs in groups of four per CPU
	# 2 or 4 UltraSPARC-III, IV or IV+ processors, 1050MHz or faster
	# Up to 32GB memory, 8GB max per CPU, 4 DIMMs per CPU, 2 CPUs per board
	# Similar memory contraints as Sun Fire V880 above
	$devname="Sebring" if ($ultra eq "Sun Fire V490");
	$devname="Silverstone" if ($ultra eq "Sun Fire V890");
	$untested=0;
	@simmsizes=(512,1024,2048);
	@banksstr=("A0","A1","B0","B1");
	$prtdiag_has_mem=1;
}
if ($ultra eq "Netra T12") {
	# Sun Fire V1280, Netra 1280
	# Essentially the same as a Sun Fire 4810, but is marketed as a low cost
	# single domain system.
	# 2-12 UltraSPARC-IIIcu processors using up to 3 CPU/Memory boards
	# Each CPU/Memory board holds up to 4 processors and up to 32GB memory
	#  (32 DIMMs per board, 8 banks of 4 DIMMs)
	# Accepts 256MB, 512MB or 1GB DIMMs
	# System Board slots are labeled SB0 and higher
	# A populated DIMM bank requires an UltraSPARC III CPU.
	# DIMMs are 232-pin 3.3V ECC 7ns SDRAM
	# prtdiag output shows the memory installed.
	$devname="Lightweight_8";
	$untested=0;
	$prtdiag_has_mem=1;
	@simmsizes=(256,512,1024);
}
if ($ultra eq "Enchilada") {
	# Sun Fire V210, V240, Netra 240
	# 1-2 UltraSPARC-IIIi (Jalapeno) processors
	# UltraSPARC IIIi supports 128MB to 1GB single bank DIMMs.
	# UltraSPARC IIIi supports 256MB to 2GB dual bank DIMMs.
	# DDR-1 SDRAM PC2100 DIMMs, 8 DIMM slots, 4 DIMMs per processor,
	#  2 banks per processor, 2 DIMMs per bank
	# V210 accepts 1GB & 2GB DIMMs by installing Fan Upgrade Kit, X7418A
	# Mixing DIMM sizes and capacities is not supported.
	# prtdiag output can show the memory installed.
	$devname="Enchilada";	# Enxs
	$devname="Enchilada 1U" if ($banner =~ /Sun Fire V210\b/ | $model =~ /Sun-Fire-V210/);
	$devname="Enchilada 2U" if ($banner =~ /Sun Fire V240\b/ | $model =~ /Sun-Fire-V240/);
	$devname="Enchilada 19" if ($model =~ /Netra-240\b/);
	$untested=0 if ($banner =~ /Sun Fire V210\b/ | $model =~ /Sun-Fire-V210/ | $banner =~ /Sun Fire 240\b/ | $model =~ /Sun-Fire-V240/ | $model =~ /Netra-240\b/);
	$prtdiag_has_mem=1;
	$prtdiag_banktable_has_dimms=1;
	$simmrangex="00002000";
	# Count the skipped address range for dual CPU
	$simmbanks=($ncpu > 1) ? 10 : 2;
	$simmsperbank=2;
	@simmsizes=(128,256,512,1024,2048);
	@socketstr=("MB/P0/B0/D0","MB/P0/B0/D1","MB/P0/B1/D0","MB/P0/B1/D1","?","?","?","?","?","?","?","?","?","?","?","?");
	push(@socketstr, "MB/P1/B0/D0","MB/P1/B0/D1","MB/P1/B1/D0","MB/P1/B1/D1") if ($ncpu > 1);
}
if ($ultra eq "Sun Fire V440" | $ultra eq "Netra 440") {
	# 1-4 UltraSPARC-IIIi (Jalapeno) processors
	# UltraSPARC IIIi supports 128MB to 1GB single bank DIMMs.
	# UltraSPARC IIIi supports 256MB to 2GB dual bank DIMMs.
	# DDR-1 SDRAM PC2100 DIMMs, 16 DIMM slots, 4 DIMMs per processor,
	#  2 banks per processor, 2 DIMMs per bank
	# prtdiag output can show the memory installed.
	$devname="Chalupa";
	$devname="Chalupa 19" if ($ultra eq "Netra 440");
	$untested=0;
	$prtdiag_has_mem=1;
	$prtdiag_banktable_has_dimms=1;
	$simmrangex="00002000";
	$simmbanks=26;	# Count the skipped address range for each CPU
	$simmsperbank=2;
	@simmsizes=(128,256,512,1024,2048);
	# Each CPU card has 4 DIMM slots labeled J0601 (B0/D0), J0602 (B0/D1),
	#  J0701 (B1/D0) and J0702 (B1/D1).
	@socketstr=("C0/P0/B0/D0","C0/P0/B0/D1","C0/P0/B1/D0","C0/P0/B1/D1","?","?","?","?","?","?","?","?","?","?","?","?");
	push(@socketstr, "C1/P0/B0/D0","C1/P0/B0/D1","C1/P0/B1/D0","C1/P0/B1/D1","?","?","?","?","?","?","?","?","?","?","?","?") if ($ncpu > 1);
	push(@socketstr, "C2/P0/B0/D0","C2/P0/B0/D1","C2/P0/B1/D0","C2/P0/B1/D1","?","?","?","?","?","?","?","?","?","?","?","?") if ($ncpu > 2);
	push(@socketstr, "C3/P0/B0/D0","C3/P0/B0/D1","C3/P0/B1/D0","C3/P0/B1/D1") if ($ncpu > 3);
}
if ($ultra eq "Sun Fire V450") {
	# untested ??? guesses below
	# 1-2 UltraSPARC-IIIi (Jalapeno) processors
	# UltraSPARC IIIi supports 128MB to 1GB single bank DIMMs.
	# UltraSPARC IIIi supports 256MB to 2GB dual bank DIMMs.
	# DDR-1 SDRAM PC2100 DIMMs, 8 DIMM slots, 4 DIMMs per processor,
	#  2 banks per processor, 2 DIMMs per bank
	# prtdiag output shows the memory installed.
#	$devname="Chalupa"; # ???
	$untested=1;
	$prtdiag_has_mem=1;
	$prtdiag_banktable_has_dimms=1;
	$simmbanks=4;
	$simmsperbank=2;
	@simmsizes=(128,256,512,1024,2048);
	# To Do: only print empty sockets for processors that are installed
#	@socketstr=("C0/P0/B0/D0","C0/P0/B0/D1","C0/P0/B1/D0","C0/P0/B1/D1","C0/P1/B0/D0","C0/P1/B0/D1","C0/P1/B1/D0","C0/P1/B1/D1");
}
if ($ultra eq "Sun Blade 1500") {
	# 1 UltraSPARC-IIIi (Jalapeno) processor
	# UltraSPARC IIIi supports 128MB to 1GB single bank DIMMs.
	# UltraSPARC IIIi supports 256MB to 2GB dual bank DIMMs.
	# 184-pin DDR-1 SDRAM PC2100 DIMMs installed in pairs, 4 DIMM slots
	# prtdiag output can show the memory installed.
	$devname="Taco";
	$untested=0;
	$prtdiag_has_mem=1;
	$prtdiag_banktable_has_dimms=1;
	$simmrangex="00002000";
	$simmbanks=2;
	$simmsperbank=2;
	@simmsizes=(128,256,512,1024,2048);
	@socketstr=("DIMM0".."DIMM3");	# DIMM1-DIMM4 on prototype
}
if ($ultra eq "Sun Blade 2500" | $ultra eq "Sun Fire V250") {
	# 1-2 UltraSPARC-IIIi (Jalapeno) processors
	# UltraSPARC IIIi supports 128MB to 1GB single bank DIMMs.
	# UltraSPARC IIIi supports 256MB to 2GB dual bank DIMMs.
	# 184-pin DDR-1 SDRAM PC2100 DIMMs, 8 DIMM slots, 4 DIMMs per processor,
	#  2 banks per processor, 2 DIMMs per bank
	# prtdiag output can show the memory installed.
	$devname="Enchilada Workstation" if ($ultra eq "Sun Blade 2500");
	$devname="Enchilada 2P Tower" if ($ultra eq "Sun Fire V250");
	$untested=0;
	$prtdiag_has_mem=1;
	$prtdiag_banktable_has_dimms=1;
	$simmrangex="00002000";
	# Count the skipped address range for dual CPU
	$simmbanks=($ncpu > 1) ? 20 : 2;
	$simmsperbank=2;
	@simmsizes=(128,256,512,1024,2048);
	if ($ultra eq "Sun Blade 2500") {
		@socketstr=("DIMM0".."DIMM3");
		push(@socketstr, "?", "?", "?", "?", "?", "?", "?", "?", "?", "?", "?", "?", "DIMM4".."DIMM7") if ($ncpu > 1);
	} else {
		@socketstr=("MB/DIMM0","MB/DIMM1","MB/DIMM2","MB/DIMM3");
		push(@socketstr, "?", "?", "?", "?", "?", "?", "?", "?", "?", "?", "?", "?", "MB/DIMM4","MB/DIMM5","MB/DIMM6","MB/DIMM7") if ($ncpu > 1);
	}
}
if ($ultra eq "Serverblade1") {
	# Sun Fire B100s Blade Server
	# 1 UltraSPARC-IIi 650MHz processors
	# Two PC-133 DIMM slots holding up to 2GB memory
	# Up to 16 Blade Servers in a single B1600 Intelligent Shelf
	# prtdiag output shows the memory installed.
	$bannermore="(Sun Fire B100s Blade Server)";
	$modelmore=$bannermore;
	$devname="Stiletto";
	$untested=0;
	$prtdiag_has_mem=1;
	$simmrangex="00000400";
	$simmbanks=2;
	$simmsperbank=1;
	@simmsizes=(256,512,1024);
	@socketstr=("Blade/DIMM0","Blade/DIMM1");
}
if ($ultra eq "Sun Fire T2000") {
	# 1 UltraSPARC-T1 (Niagara) processor with "CoolThreads" multithreading
	# 8 core 1.2GHz (9.6GHz clock speed rating) or 4, 6, or 8 core 1.0GHz
	# Up to 32GB DDR2 memory in 16 slots w/ Chipkill and DRAM sparing, ECC
	#  registered DIMMs. Supports 512MB, 1GB and 2GB DIMMs.
	# Option X7800A - 1GB (2x512MB DDR2) 370-6207, 512MB DDR2 DIMM, 533MHz
	# Option X7801A - 2GB (2x1GB DDR2) 370-6208, 1GB DDR2 DIMM, 533MHz
	# Option X7802A - 4GB (2x2GB DDR2) 370-6209, 2GB DDR2 DIMM, 533MHz
	# DIMMs must be installed in sets of 8. Two basic memory configurations
	#  are supported: 8-DIMM or 16-DIMM. All DIMMs must have identical
	#  capacity. An 8 DIMM configuration fully populates Rank 0 (R0) slots.
	# Base configurations sold by Sun use all 16 DIMM slots.
	# 4 memory controllers embedded in UltraSPARC-T1 (CH0-CH3)
	$devname="Ontario";
	$untested=0;
	$simmrangex="00002000";
	if (scalar(@slots) == 8) {
		# Two ranks reported
		$simmbanks=2;
		$simmsperbank=8;
	} else {
		# One rank reported, but default base configurations ship with
		# two ranks (16 DIMMs)
		$simmbanks=1;
		$simmsperbank=16;
	}
	@simmsizes=(512,1024,2048);
	@socketstr=("MB/CMP0/CH0/R0/D0","MB/CMP0/CH0/R0/D1","MB/CMP0/CH1/R0/D0","MB/CMP0/CH1/R0/D1","MB/CMP0/CH2/R0/D0","MB/CMP0/CH2/R0/D1","MB/CMP0/CH3/R0/D0","MB/CMP0/CH3/R0/D1","MB/CMP0/CH0/R1/D0","MB/CMP0/CH0/R1/D1","MB/CMP0/CH1/R1/D0","MB/CMP0/CH1/R1/D1","MB/CMP0/CH2/R1/D0","MB/CMP0/CH2/R1/D1","MB/CMP0/CH3/R1/D0","MB/CMP0/CH3/R1/D1");
}
if ($ultra eq "Sun Fire T1000") {
	# 1 UltraSPARC-T1 (Niagara) processor with "CoolThreads" multithreading
	# 6 or 8 core 1.0GHz
	# Up to 16GB DDR2 memory in 8 slots w/ Chipkill and DRAM sparing, ECC
	#  registered DIMMs. Supports 512MB, 1GB and 2GB DIMMs.
	# DIMMs must be installed in sets of 8.
	# 4 memory controllers embedded in UltraSPARC-T1 (CH0-CH3)
	$devname="Erie";
	$untested=1;
	$simmrangex="00002000";
	$simmbanks=1;
	$simmsperbank=8;
	@simmsizes=(512,1024,2048);
	@socketstr=("MB/CMP0/CH0/D0","MB/CMP0/CH0/D1","MB/CMP0/CH1/D0","MB/CMP0/CH1/D1","MB/CMP0/CH2/D0","MB/CMP0/CH2/D1","MB/CMP0/CH3/D0","MB/CMP0/CH3/D1");
}

if ($model =~ /-Enterprise/ | $ultra eq "e") {
	# E3x00/E4x00/E5x00/E6x00 accepts 8MB, 32MB, 128MB or 256MB DIMMs on
	#  motherboard, 2 banks of 8 DIMMs per board.
	#  256MB DIMMs (2GB kit X7026A) can be used with OBP 3.2.24 or later and
	#  Solaris 2.5.1 11/97, Solaris 2.6 3/98 or later
	#   501-2652 (8MB), 501-2653 (32MB), 501-2654 (128MB), 501-5658 (256MB)
	#   168-pin 60ns 3.3V ECC
	# E10000 accepts 32MB or 128MB DIMMs on motherboard,
	#  using 2 or 4 banks of 8 DIMMs per board.
	#   501-2653 (32MB), 501-2654 (128MB)
	#   168-pin 60ns 3.3V ECC
	$devname="Duraflame" if ($banner =~ /\bE?3[05]00\b/);
	$devname="Campfire Rack" if ($banner =~ /\bE?5[05]00\b/);
	$devname="Campfire" if ($banner =~ /\bE?4[05]00\b/);
	$devname="Sunfire" if ($banner =~ /\bE?6[05]00\b/);
	$devname .= "+" if ($banner =~ /\bE?[3-6]500\b/);
	$devname="Starfire" if ($model =~ /-10000\b/);
	$untested=1;
	if ($banner =~ /\bE?[3-6][05]00\b/ | $model =~ /-Enterprise-E?[3-6][05]00/ | $model eq "Ultra-Enterprise" ) {
		$untested=0;
		@simmsizes=(8,32,128,256);
	}
	if ($model =~ /-Enterprise-10000\b/) {
		$untested=0;
		@simmsizes=(32,128);
	}
	$prtdiag_has_mem=1;
	@prtdiag=`$prtdiag_exec` if ($filename eq "");
	$i=0;
	foreach $line (@prtdiag) {
		$line=~s/\015//g;	# Remove any DOS carriage returns
		if ($line =~ /Memory Units:/) {
			# Start of memory section, Solaris 2.5.1 format
			$flag_mem=1;
			$format_mem=1;
			$flag_cpu=0;	# End of CPU section
		}
		if ($line =~ /===== Memory /) {
			# Start of memory section, Solaris 2.6 and later format
			$flag_mem=1;
			$format_mem=2;
			$flag_cpu=0;	# End of CPU section
		}
		if ($line =~ /Factor/) {
			# No interleave factor on E10000
			$format_mem += 2 if ($format_mem == 1 | $format_mem == 2);
		}
		if ($line =~ /IO Cards/) {
			$flag_cpu=0;	# End of CPU section
			$flag_mem=0;	# End of memory section
		}
		if ($flag_cpu >= 1 & $line ne "\n") {
			push(@boards_cpu, "$line");
			$boardfound_cpu=1;
			if ($line =~ /Board/) {
				$boardslot_cpu=substr($line,6,2);
			} else {
				$boardslot_cpu=substr($line,0,2);
			}
			$boardslot_cpu=~s/[: ]//g;
			if ($flag_cpu == 2 & $boardslot_cpus !~ /\s$boardslot_cpu\s/ & $boardslot_cpu ne "") {
				push(@boardslot_cpus, "$boardslot_cpu");
				$boardslot_cpus .= $boardslot_cpu . " ";
			}
		}
		if ($line =~ /CPU Units:/) {
			$flag_cpu=1;	# Start of CPU section
			$flag_mem=0;	# End of memory section
			$format_cpu=1;
		}
		if ($line =~ /===== CPUs =====/) {
			$flag_cpu=1;	# Start of CPU section
			$flag_mem=0;	# End of memory section
			$format_cpu=2;
		}
		if ($flag_mem == 2 & $line ne "\n") {
			if ($line =~ /Board/) {
				$boardslot_mem=substr($line,5,2);
			} else {
				$boardslot_mem=substr($line,0,2);
			}
			$boardslot_mem=~s/[: ]//g;
			if ($boardslot_mems !~ /\s$boardslot_mem\s/) {
				push(@boardslot_mems, "$boardslot_mem");
				$boardslot_mems .= $boardslot_mem . " ";
			}
			if ($format_mem == 1) {
				# Memory on each system board, E10000
				$mem0=substr($line,12,4);
				$mem0=0 if ($mem0 !~ /\d+/);
				$dimm0=$mem0 / 8;
				if ($dimm0 > 0) {
					$dimms0=sprintf("8x%3d", $dimm0);
					push(@simmsizesfound, "$dimm0");
				} else {
					$dimms0="     ";
					&found_empty_bank("Bank 0");
				}
				$mem1=substr($line,20,4);
				$mem1=0 if ($mem1 !~ /\d+/);
				$dimm1=$mem1 / 8;
				if ($dimm1 > 0) {
					$dimms1=sprintf("8x%3d", $dimm1);
					push(@simmsizesfound, "$dimm1");
				} else {
					$dimms1="     ";
					&found_empty_bank("Bank 1");
				}
				$mem2=substr($line,28,4);
				$mem2=0 if ($mem2 !~ /\d+/);
				$dimm2=$mem2 / 8;
				if ($dimm2 > 0) {
					$dimms2=sprintf("8x%3d", $dimm2);
					push(@simmsizesfound, "$dimm2");
				} else {
					$dimms2="     ";
					&found_empty_bank("Bank 2");
				}
				$mem3=substr($line,36,4);
				$mem3=0 if ($mem3 !~ /\d+/);
				$dimm3=$mem3 / 8;
				if ($dimm3 > 0) {
					$dimms3=sprintf("8x%3d", $dimm3);
					push(@simmsizesfound, "$dimm3");
				} else {
					$dimms3="     ";
					&found_empty_bank("Bank 3");
				}
				$newline=substr($line,0,10);
				$newline .= "  " . $mem0 . "  " . $dimms0;
				$newline .= "  " . $mem1 . "  " . $dimms1;
				$newline .= "  " . $mem2 . "  " . $dimms2;
				$newline .= "  " . $mem3 . "  " . $dimms3;
				$newline .= "\n";
				push(@boards_mem, "$newline");
				$boardfound_mem=1;
			}
			if ($format_mem == 2) {
				# Memory on each system board, E10000
				# untested ??? reporting of empty banks
				$untested=1;
				$bank_slot=substr($line,6,2);
				$mem=substr($line,12,4);
				$mem=0 if ($mem !~ /\d+/);
				$dimm=$mem / 8;
				if ($dimm > 0) {
					$dimms=sprintf("8x%3d", $dimm);
					push(@simmsizesfound, "$dimm");
					$newline=substr($line,0,18) . $dimms;
					$newline .= substr($line,16,47);
					push(@boards_mem, "$newline");
					$boardfound_mem=1;
					$failed_memory += $mem if ($newline =~ /\b\bFailed\b\b/);
					$spare_memory += $mem if ($newline =~ /\b\bSpare\b\b/);
				} else {
					$flag_mem=0;
					&found_empty_bank("Bank $bank_slot");
				}
				if ($bank_slot == 0) {
					$next_boardslot_mem=substr($prtdiag[$i + 1],0,2);
					$next_boardslot_mem=~s/[: ]//g;
					if ($next_boardslot_mem ne $boardslot_mem) {
						&found_empty_bank("Bank 1");
					}
				}
				if ($bank_slot == 1) {
					$prev_boardslot_mem=substr($prtdiag[$i - 1],0,2);
					$prev_boardslot_mem=~s/[: ]//g;
					if ($prev_boardslot_mem ne $boardslot_mem) {
						&found_empty_bank("Bank 0");
					}
				}
			}
			if ($format_mem == 3) {
				# Memory on each system board, E[3456]x00
				$mem0=substr($line,10,4);
				$mem0=0 if ($mem0 !~ /\d+/);
				$dimm0=$mem0 / 8;
				if ($dimm0 > 0) {
					$dimms0=sprintf("8x%3d", $dimm0);
					push(@simmsizesfound, "$dimm0");
				} else {
					$dimms0="     ";
					&found_empty_bank("Bank 0");
				}
				$memlength=length($line);
				if ($memlength > 34) {
					$mem1=substr($line,34,4);
				} else {
					$mem1=0;
				}
				$mem1=0 if ($mem1 !~ /\d+/);
				$dimm1=$mem1 / 8;
				if ($dimm1 > 0) {
					$dimms1=sprintf("8x%3d", $dimm1);
					push(@simmsizesfound, "$dimm1");
				} else {
					$dimms1="     ";
					&found_empty_bank("Bank 1");
				}
				$newline=substr($line,0,16) . $dimms0;
				$newline .= substr($line,16,24);
				if ($dimm1 > 0) {
					$newline .= $dimms1;
					$newline .= substr($line,39,16);
				}
				push(@boards_mem, "$newline");
				$boardfound_mem=1;
			}
			if ($format_mem == 4) {
				# Memory on each system board, E[3456]x00
				$bank_slot=substr($line,7,1);
				$mem=substr($line,12,4);
				$mem=0 if ($mem !~ /\d+/);
				$dimm=$mem / 8;
				if ($dimm > 0) {
					$dimms=sprintf("8x%3d", $dimm);
					push(@simmsizesfound, "$dimm");
					$newline=substr($line,0,18) . $dimms;
					$newline .= substr($line,16,47);
					push(@boards_mem, "$newline");
					$boardfound_mem=1;
					$failed_memory += $mem if ($newline =~ /\b\bFailed\b\b/);
					$spare_memory += $mem if ($newline =~ /\b\bSpare\b\b/);
				} else {
					$flag_mem=0;
					&found_empty_bank("Bank $bank_slot");
				}
				if ($bank_slot == 0) {
					$next_boardslot_mem=substr($prtdiag[$i + 1],0,2);
					$next_boardslot_mem=~s/[: ]//g;
					if ($next_boardslot_mem ne $boardslot_mem) {
						&found_empty_bank("Bank 1");
					}
				}
				if ($bank_slot == 1) {
					$prev_boardslot_mem=substr($prtdiag[$i - 1],0,2);
					$prev_boardslot_mem=~s/[: ]//g;
					if ($prev_boardslot_mem ne $boardslot_mem) {
						&found_empty_bank("Bank 0");
					}
				}
			}
		}
		if ($flag_cpu == 1 & $line =~ /-----/) {
			# Next lines are the CPUs on each system board
			$flag_cpu=2;
		}
		if ($flag_mem == 1 & $line =~ /-----/) {
			# Next lines are the memory on each system board
			$flag_mem=2;
		}
		$i++;
	}
	&show_header;
	if ($boardfound_mem) {
		if ($boardfound_cpu) {
			foreach $board (@boardslot_cpus) {
				if ($boardslot_mems !~ /\s$board\s/) {
					$boardslot_mem=$board;
					if ($format_mem <= 2) {
						# E10000
						&found_empty_bank("Bank 0");
						&found_empty_bank("Bank 1");
						&found_empty_bank("Bank 2");
						&found_empty_bank("Bank 3");
					} else {
						# E3x00/E4x00/E5x00/E6x00
						&found_empty_bank("Bank 0");
						&found_empty_bank("Bank 1");
					}
				}
			}
		}
		if ($format_mem == 1) {
			# E10000 running Solaris 2.5.1
			print "               Bank 0       Bank 1       Bank 2       Bank 3\n";
			print "             MB   DIMMs   MB   DIMMs   MB   DIMMs   MB   DIMMs\n";
			print "            ----  -----  ----  -----  ----  -----  ----  -----\n";
			print @boards_mem;
		}
		if ($format_mem == 2) {
			# E10000 running Solaris 2.6 or later
			print "Brd   Bank   MB   DIMMs   Status   Condition  Speed\n";
			print "---  -----  ----  -----  -------  ----------  -----\n";
			print @boards_mem;
		}
		if ($format_mem == 3) {
			# E3x00/E4x00/E5x00/E6x00 running Solaris 2.5.1
			print "                   Bank 0                       Bank 1\n";
			print "          J3100-J3800   Interleave     J3101-J3801   Interleave\n";
			print "           MB   DIMMs  Factor  With     MB   DIMMs  Factor  With\n";
			print "          ----  -----  ------  ----    ----  -----  ------  ----\n";
			print @boards_mem;
		}
		if ($format_mem == 4) {
			# E3x00/E4x00/E5x00/E6x00 running Solaris 2.6 or later
			print "                                                     Intrlv.  Intrlv.\n";
			print "Brd   Bank   MB   DIMMs   Status   Condition  Speed   Factor   With\n";
			print "---  -----  ----  -----  -------  ----------  -----  -------  -------\n";
			print @boards_mem;
			print "Bank 0 uses sockets J3100-J3800, Bank 1 uses sockets J3101-J3801\n";
		}
		$empty_banks=" None" if ($empty_banks eq "");
		print "empty memory banks:$empty_banks\n";
	}
	$totmem=$installed_memory;
	&finish;
	exit;
}

#
# Check to see if this system has memory defined in the prtdiag output
#
&check_prtdiag;
# Don't use prtdiag data on this clone
$boardfound_mem=0 if ($manufacturer eq "AXUS");

#
# Check to see if this system has module information in prtconf output
# (Seen on Fujitsu GP7000, GP7000F, PrimePower)
#
if ($gotmodule ne "" | $gotmodulenames ne "") {
	if ($gotmodulenames) {
		@simmslots=split(/\./, $gotmodulenames);
	} else {
		@simmslots=split(/\./, $gotmodule);
	}
	for($val=0; $val < scalar(@simmslots); $val += 2) {
		if ($gotmodulenames) {
			$socket=$simmslots[$val];
		} else {
			$socket="SLOT" . $val / 2;
		}
		$simmsz=$simmslots[$val + 1];
		$simmsize=hex("0x$simmsz") / $meg;
		$perlhexbug=1 if ($simmsize <= 0 & $simmsz ne "00000000");
		$totmem += $simmsize;
		if ($simmsize > 0) {
			push(@simmsizesfound, "$simmsize");
			if (! $boardfound_mem) {
				push(@memorylines, "$socket has a ${simmsize}MB");
				if ($simmsize > 1023) {
					push(@memorylines, " (");
					push(@memorylines, $simmsize/1024);
					push(@memorylines, "GB)");
				}
				push(@memorylines, " $memtype\n");
			}
			$sockets_used .= " $socket";
		}
	}
	&show_header;
	if ($boardfound_mem) {
		print @boards_mem;
	} else {
		print @memorylines;
	}
	$totmem=$installed_memory;
	&finish;
	exit;
}

#
# Display memory if found in prtdiag output
#
if ($boardfound_mem) {
	&show_header;
	print @boards_mem;
	$totmem=$installed_memory;
}
#
# Look for empty memory banks on Sun Fire 3800, 4800, 4810, 6800, 12K, 15K and
# Netra T12 systems. Also Sun Fire E2900, E4900, E6900, E20K and E25K.
#
if ($ultra eq "Sun Fire" | $ultra eq "Sun Fire 15K" | $ultra eq "Sun Fire 12K" | $ultra eq "Netra T12" | $ultra =~ /Sun Fire [346]8[01]0\b/ | $ultra =~ /Sun Fire E[246]900\b/ | $ultra =~ /Sun Fire E2[05]K\b/) {
	foreach $cpu (@boardslot_cpus) {
		if ($boardslot_mems !~ /$cpu\/B0/) {
			$empty_banks .= " $cpu/B0";
		}
		if ($boardslot_mems !~ /$cpu\/B1/) {
			$empty_banks .= " $cpu/B1";
		}
	}
	$empty_banks=" None" if ($empty_banks eq "");
	if ($boardslot_mems eq " ") {
		$empty_banks=" Unknown";
		$exitstatus=1;
	}
	print "empty memory banks:$empty_banks\n";
}
if ($boardfound_mem) {
	&finish;
	exit;
}

#
# OK, get ready to print out results
#
for($val=$val0; $val < scalar(@slots); $val += $valinc) {
	$newaddrmsb=substr($slots[$val - $valaddr - 1],3,5);
	$newaddrlsb=substr($slots[$val - $valaddr],0,3);
	if ($valinc == 4) {
		$newsizemsb=substr($slots[$val - 1],3,5);
	} else {
		$newsizemsb="";
	}
	$newsizelsb=substr($slots[$val],0,3);
	# Round up for DIMM value seen on US-T1 Niagara systems
	# Two Ranks of DIMMs appear as one in prtconf
	if ($newsizelsb eq "ff8") {
		if ($newsizemsb eq "00000") {
			$newsizemsb="00001";	# 512MB
			if ($ultra eq "Sun Fire T2000") {
				# Hack: 1 rank of smallest DIMMs
				$simmbanks=2;
				$simmsperbank=8;
			}
		} elsif ($newsizemsb eq "00001") {
			$newsizemsb="00002";	# 1GB
			# Hack: Could be 1 Rank of 1GB on T2000
			$recognized=-1 if ($ultra eq "Sun Fire T2000" & scalar(@slots) == 4);
		} elsif ($newsizemsb eq "00003") {
			$newsizemsb="00004";	# 2GB
			# Hack: Could be 1 Rank of 2GB on T2000
			$recognized=-1 if ($ultra eq "Sun Fire T2000" & scalar(@slots) == 4);
		} elsif ($newsizemsb eq "00007") {
			$newsizemsb="00008";	# Fully stuffed 2 Ranks of 2GB
		}
		$newsizelsb="000";
		$installed_memory+=8;
	}
	if ($sortslots) {
		$mods{"$newaddrmsb$newaddrlsb"}="$newsizemsb$newsizelsb";
	} else {
		push(@newslots, "$newaddrmsb$newaddrlsb");
		push(@newslots, "$newsizemsb$newsizelsb");
	}
}
if ($sortslots) {
	for(sort keys %mods) {
		push(@newslots, $_);
		push(@newslots, $mods{$_});
	}
}

# For Ultra-30, determine if interleaving of banks using four DIMMs
if ($model eq "Ultra-30" | $ultra eq 30) {
	$interleave=2;
	# pairs show up in odd numbered address ranges
	for($val=0; $val < scalar(@newslots); $val += 2) {
		$interleave=1 if ($newslots[$val] =~ /00000[1357]00/);
	}
	if ($interleave eq 2) {
		$simmrangex="00000200";
		$simmbanks=4;
		$simmsperbank=4;
	} else {
		$simmrangex="00000100";
		$simmbanks=8;
		$simmsperbank=2;
	}
}

# Check if SPARCsystem-600 has VME memory expansion boards
if ($model eq "SPARCsystem-600" | $model =~ /Sun.4.600/) {
	for($val=0; $val < scalar(@newslots); $val += 2) {
		if ($newslots[$val] =~ /00000[4-9ab]00/) {
			@simmsizes=(1,4,16);
			push(@socketstr, @socketstr_exp);
			push(@bankstr, @bankstr_exp);
			push(@bytestr, @bytestr_exp);
			if ($newslots[$val] =~ /00000[4-7]00/) {
				$exp="Expansion board 0 bank";
			} else {
				$exp="Expansion board 1 bank";
			}
			push(@banksstr, ("$exp B0","$exp B1", "$exp B2","$exp B3"));
		}
	}
}

# Hack: Try to rewrite memory line for Ultra-80 or Enterprise 420R
if ($model eq "Ultra-80" | $ultra eq 80 | $ultra eq "420R" | $ultra eq "Netra t140x") {
	# 4GB of memory (maximum allowed)
	if ($newslots[1] eq "00001000") {
		$newslots[1]="00000400";
		$newslots[2]="00000400";
		$newslots[3]="00000400";
		$newslots[4]="00000800";
		$newslots[5]="00000400";
		$newslots[6]="00000c00";
		$newslots[7]="00000400";
		$recognized=-2;
	}
	# 2GB of memory (eliminate unsupported 512MB DIMM error)
	if ($newslots[1] eq "00000800") {
		$newslots[1]="00000400";
		$newslots[2]="00000400";
		$newslots[3]="00000400";
	}
}

# Hack: Fix address ranges for Tatung COMPstation U60 and U80D
if ($banner =~ /COMPstation_U60_Series/ | $banner =~ /COMPstation_U80D_Series/) {
	# Tatung Science and Technology, http://www.tsti.com
	for($val=0; $val < scalar(@newslots); $val += 2) {
		if ($newslots[$val] =~ /00000[46]00/) {
			$simmbanks=4;
		}
		# Check for 256MB DIMMs or 256MB address range per bank
		if ($newslots[$val+1] =~ /00000400/ | $newslots[$val] =~ /00000c00/) {
			$simmrangex="00000400";
			$simmbanks=4;
		}
	}
	if ($simmbanks eq 6) {
		# Skipped address range similar to Sun Ultra 60
		@socketstr=("J17","J32","J36","J40","J18","J33","J37","J41","?","?","?","?","?","?","?","?","J19","J34","J38","J42","J20","J35","J39","J43");
		@slotstr=(1..8,"?","?","?","?","?","?","?","?",9..16);
		@bankstr=(0,0,0,0,1,1,1,1,"?","?","?","?","?","?","?","?",2,2,2,2,3,3,3,3);
	} else {
		@socketstr=("J17","J32","J36","J40","J18","J33","J37","J41","J19","J34","J38","J42","J20","J35","J39","J43");
		@slotstr=(1..16);
		@bankstr=(0,0,0,0,1,1,1,1,2,2,2,2,3,3,3,3);
	}
}

# Hack: Try to rewrite memory line for Sun Blade 1000 & 2000 if prtdiag output
#       did not show the memory. This does not expect 2GB DIMMs to be used.
if (($ultra eq "Sun Blade 1000" | $ultra eq "Sun Blade 2000" | $ultra eq "Sun Fire 280R") & ! $boardfound_mem) {
	# Assume 8GB is 8x1GB instead of 4x2GB
	if ($newslots[1] eq "00002000") {
		$newslots[1]="00001000";
		$newslots[2]="00001000";
		$newslots[3]="00001000";
		$recognized=-2;
	}
	# Assume 6GB is 4x1GB + 4x512MB instead of 4x1.5GB
	if ($newslots[1] eq "00001800") {
		$newslots[1]="00001000";
		$newslots[2]="00001000";
		$newslots[3]="00000800";
		$recognized=-1;
	}
	# Assume 5GB is 4x1GB + 4x256MB instead of 4x1280MB
	if ($newslots[1] eq "00001400") {
		$newslots[1]="00001000";
		$newslots[2]="00001000";
		$newslots[3]="00000400";
		$recognized=-1;
	}
	# Assume 4.5GB is 4x1GB + 4x128MB instead of 4x1152MB
	if ($newslots[1] eq "00001200") {
		$newslots[1]="00001000";
		$newslots[2]="00001000";
		$newslots[3]="00000200";
		$recognized=-1;
	}
	# Assume 3GB is 4x512MB + 4x256MB instead of 4x768MB
	if ($newslots[1] eq "00000c00") {
		$newslots[1]="00000800";
		$newslots[2]="00001000";
		$newslots[3]="00000400";
		$recognized=-1;
	}
	# Assume 2.5GB is 4x512MB + 4x128MB instead of 4x640MB
	if ($newslots[1] eq "00000a00") {
		$newslots[1]="00000800";
		$newslots[2]="00001000";
		$newslots[3]="00000200";
		$recognized=-1;
	}
	# Assume 1.5GB is 4x256MB + 4x128MB instead of 4x384MB
	if ($newslots[1] eq "00000600") {
		$newslots[1]="00000400";
		$newslots[2]="00001000";
		$newslots[3]="00000200";
		$recognized=-1;
	}
}

# Check for dual bank DIMMs on Ultra AXmp+
if ($ultra eq "AXmp+") {
	if ($#newslots eq 1 & $newslots[0] eq "00000c00") {
		$simmsperbank=4;
		$dualbank=1;
	}
	if ($#newslots eq 3) {
		if ($newslots[2] =~ /00000[8c]00/) {
			$simmrangex="00000800";
			$dualbank=1 if ($newslots[1] eq $newslots[3]);
		}
	}
	if ($#newslots ge 5) {
		$dualbank=1 if ($newslots[4] =~ /00000[8c]00/);
	}
	if ($dualbank eq 1) {
		@bankstr=("0,2","0,2","0,2","0,2","0,2","0,2","0,2","0,2","1,3","1,3","1,3","1,3","1,3","1,3","1,3","1,3");
		# Rearrange slots if necessary
		if ($#newslots ge 5) {
			if ($newslots[4] eq "00000800") {
				$temp1=$newslots[2];
				$temp2=$newslots[3];
				$newslots[2]=$newslots[4];
				$newslots[3]=$newslots[5];
				$newslots[4]=$temp1;
				$newslots[5]=$temp2;
			}
		}
	}
}

for($val=0; $val < scalar(@newslots); $val += 2) {
	$simmaddr=$newslots[$val];
	$simmsz=$newslots[$val + 1];
	$simmsize=hex("0x$simmsz");
	$perlhexbug=1 if ($simmsize <= 0 & $simmsz ne "00000000");
	$totmem += $simmsize;

	if (($model eq "Sun 4/75" | $model eq "SS-2") & $simmbanks < $bankcnt + 2) {
		# SS2 SBus memory card
		if ($simmaddr eq "00000080") {
			$buffer .= "SBus primary contains ";
		} else {
			$buffer .= "SBus secondary contains ";
		}
		$start1=hex("0x$simmaddr") * $meg;
		$perlhexbug=1 if ($start1 < 0);
		$simmrange=hex("0x$simmrangex") * $meg;
		$perlhexbug=1 if ($simmrange <= 0 & $simmrangex ne "00000000");
		$start1x=sprintf("%08lx", $start1);
		$stop1x=sprintf("%08lx", $start1 + (2 * $simmrange) - 1);
		$totmem += $simmsize;
		$simmsize *= 2;
		$val += 2;
		$buffer .= "${simmsize}MB";
		$buffer .= " (address 0x${start1x}-0x$stop1x)" if ($verbose);
		$buffer .= "\n";
	} elsif ($simmbanks > 0) {
		$start1=hex("0x$simmaddr") * $meg;
		$perlhexbug=1 if ($start1 < 0);
		if ($simmrangex ne "0") {
			$simmrange=hex("0x$simmrangex") * $meg;
			$perlhexbug=1 if ($simmrange <= 0 & $simmrangex ne "00000000");
			if ($simmrange < hex("0x00001000") * $meg) {
				$start1x=sprintf("%08lx", $start1);
				$stop1x=sprintf("%08lx", $start1 + ($simmsize * $meg) - 1);
			} else {
				# Systems with > 4GB of memory
				$start1x=$simmaddr . "00000";
				$start1x=~s/^0000//g;
				$stop1x=sprintf("%08lx", ($start1 / $meg) + $simmsize - 1) . "fffff";
				$stop1x=~s/^0000//g;
			}
		}
		$cnt=0;
		$maxcnt=$simmbanks * $simmsperbank / $simmspergroup;
		while ($cnt < $maxcnt) {
			if ($start1 >= ($simmrange * $cnt) & $start1 < ($simmrange * ($cnt + 1))) {
				$bankcnt=$cnt;
				$cnt3=($bankcnt * $simmsperbank / $simmspergroup);
				if ($#socketstr) {
					$socket=$socketstr[$cnt3];
					$socket=$socketstr[$cnt3+4] if ($found10bit & $newslots[$val] !~ /00000[0-3]00/);
				}
				$order=$orderstr[$cnt3] if ($#orderstr);
				$group=$groupstr[$cnt3] if ($#groupstr);
				$slotnum=$slotstr[$cnt3] if ($#slotstr);
				if ($#bankstr) {
					$bank=$bankstr[$cnt3];
					$bank=$bankstr[$cnt3+4] if ($found10bit & $newslots[$val] !~ /00000[0-3]00/);
				}
				$banks=$banksstr[$cnt3/$simmsperbank] if ($#banksstr);
				$byte=$bytestr[$cnt3] if ($#bytestr);
			}
			$cnt++;
		}
		#
		# Check for stacked DIMMs. A 128MB DIMM is sometimes seen as 2
		# 64MB DIMMs with a hole in the address range. This may report
		# more slots than are really in a system. (i.e. a SS20 with
		# 8 32MB SIMMs reports 16 slots of 16MB each).
		# Special handling for $sortslots == 0 systems (Ultra 5/10,
		# Netra t1, Ultra CP 1400/1500, Ultra AXi/AXe/AXmp/AXmp+)
		#
		$stacked=0;
		if ($val < $#newslots - 2) {
			if ($sortslots == 0) {
				$start2=$start1 + ($simmrange * 2);
				if ($banner =~ /Ultra CP 1400\b/ | $ultra eq "cp1400") {
					$start2=$start1 + ($simmrange * 4);
				}
				$start2x=sprintf("%08lx", $start2 / $meg);
				$stacked=2 if ($stacked == 0 & $newslots[$val + 2] eq $start2x & $newslots[$val + 3] eq $simmsz);
				if ($memtype eq "memory card") {
					# Some 256MB mezzanine boards are seen
					# as 4 64MB memory blocks with holes in
					# the address range.
					if ($simmsize eq 64) {
						$start3=$start1 + ($simmsize * 2 * $meg);
					}
					# Some 512MB mezzanine boards are seen
					# as 4 128MB memory blocks.
					if ($simmsize eq 128 & $banner !~ /Ultra CP 1400\b/ & $ultra ne "cp1400") {
						$start3=$start1 + ($simmsize * $meg);
					}
					$start3x=sprintf("%08lx", $start3 / $meg);
					if ($val < $#newslots - 6 & $stacked != 0) {
						$stacked=4 if ($newslots[$val + 4] eq $start3x & $newslots[$val + 5] eq $simmsz & $simmrange != $start3);
					}
				}
				if ($ultra eq "AXi") {
					# Check for 10-bit column address DIMMs
					if ($newslots[$val] =~ /00000[0-3]80/) {
						$found10bit=1;
					} elsif ($stacked == 0) {
						$found11bit=1;
					}
					if ($found10bit & $newslots[$val] !~ /00000[0-3]00/) {
						$socket=$socketstr[$cnt3+4];
						$bank=$bankstr[$cnt3+4];
					}
				}
			} else {
				$start2=$start1 + ($simmrange / 2);
				$start2x=sprintf("%08lx", $start2 / $meg);
				$stacked=2 if ($newslots[$val + 2] eq $start2x & $newslots[$val + 3] eq $simmsz & ($simmsize ne 64));
			}
			#
			# Check for 32MB SIMMs in bank 1 on Classic or LX.
			# They look like 16MB SIMMs at 0x0000000 and 0x06000000
			# Also check for 8MB SIMMs in bank 1 on Classic or LX.
			# They look like 4MB SIMMs at 0x0000000 and 0x06000000
			#
			if ($model =~ /SPARCclassic/ | $model =~ /SPARCstation-LX/) {
				if ($start1 == 0 & ($simmsize == 32 | $simmsize == 8)) {
					if ($newslots[$#newslots - 1] eq "00000060") {
						$totmem += $simmsize;
						$start2=hex("0x$newslots[$#newslots - 1]") * $meg;
						$start2x=sprintf("%08lx", $start2);
						$stop2x=sprintf("%08lx", $start2 + ($simmsize * $meg) - 1);
						$stop1x .= ", 0x${start2x}-0x$stop2x";
						$simmsize *= 2;
						pop(@newslots);
						pop(@newslots);
					}
				}
			}
			if ($stacked == 2) {
				$totmem += $simmsize;
				$start2=hex("0x$newslots[$val + 2]") * $meg;
				if ($simmrange < hex("0x00001000") * $meg) {
					$start2x=sprintf("%08lx", $start2);
					$stop2x=sprintf("%08lx", $start2 + ($simmsize * $meg) - 1);
				} else {
					# Systems with > 4GB of memory
					$start2x=sprintf("%08lx", ($start2 / $meg)) . "00000";
					$start2x=~s/^0000//g;
					$stop2x=sprintf("%08lx", ($start2 / $meg) + $simmsize - 1) . "fffff";
					$stop2x=~s/^0000//g;
				}
				$stop1x .= ", 0x${start2x}-0x$stop2x";
				$simmsize *= 2;
				$val += 2;
			}
			if ($stacked == 4) {
				$totmem += $simmsize * 3;
				$start2=hex("0x$newslots[$val + 2]") * $meg;
				$start2x=sprintf("%08lx", $start2);
				$stop2x=sprintf("%08lx", $start2 + ($simmsize * $meg) - 1);
				$stop1x .= ", 0x${start2x}-0x$stop2x";
				$start3=hex("0x$newslots[$val + 4]") * $meg;
				$start3x=sprintf("%08lx", $start3);
				$stop3x=sprintf("%08lx", $start3 + ($simmsize * $meg) - 1);
				$stop1x .= ", 0x${start3x}-0x$stop3x";
				$start4=hex("0x$newslots[$val + 6]") * $meg;
				$start4x=sprintf("%08lx", $start4);
				$stop4x=sprintf("%08lx", $start4 + ($simmsize * $meg) - 1);
				$stop1x .= ", 0x${start4x}-0x$stop4x";
				$simmsize *= 4;
				$val += 6;
			}
		}
		#
		# Check for Voyager memory cards. A 32MB memory card is seen
		# as 4 8MB memory blocks with holes in the address range.
		#
		if ($model eq "S240" & $start1 > 0 & $simmsize == 16 & $val < $#newslots - 4) {
			$start=hex("0x$newslots[$val + 4]") - hex("0x$newslots[$val]");
			$perlhexbug=1 if ($start < 0);
			$startx=sprintf("%08lx", $start);
			if ($newslots[$val + 1] eq "008" & $newslots[$val + 3] eq "008" & $startx eq "00000040") {
				$totmem += $simmsize;
				$startx=$newslots[$val + 2];
				$start=hex("0x$startx") * $meg;
				$startx=sprintf("%08lx", $start);
				$perlhexbug=1 if ($start < 0);
				$stopx=sprintf("%08lx", $start + ($simmsize * $meg) - 1);
				$stop1x .= ", 0x${startx}-0x$stopx";
				$startx=$newslots[$val + 4];
				$start=hex("0x$startx") * $meg;
				$startx=sprintf("%08lx", $start);
				$perlhexbug=1 if ($start < 0);
				$stopx=sprintf("%08lx", $start + ($simmsize * $meg) - 1);
				$stop1x .= ", 0x${startx}-0x$stopx";
				$simmsize *= 2;
				$val += 4;
			}
		}
		$slot0=$simmsize if ($start1 == 0);
		$simmsizeperbank=$simmsize / $simmsperbank;
		$smallestsimm=$simmsizeperbank if ($simmsize < $smallestsimm);
		$largestsimm=$simmsizeperbank if ($simmsize > $largestsimm);
		$found8mb=1 if ($simmsizeperbank == 8);
		$found16mb=1 if ($simmsizeperbank == 16);
		$found32mb=1 if ($simmsizeperbank == 32);
		push(@simmsizesfound, "$simmsizeperbank");

		$cnt2=0;
		$maxcnt2=$simmsperbank / $simmspergroup;
		while ($cnt2 < $maxcnt2) {
			$socket='?' if !defined($socket);
			$bank='' if !defined($bank);
			$byte='' if !defined($byte);
			$socket='?' if ($socket eq "");
			$recognized=0 if ($socket eq "?");
			$sockets_used .= " $socket";
			if ($simmspergroup > 1) {
				$buffer .= "${sockettype}s $socket have $simmsperbank ";
				$buffer .= $simmsize/$simmsperbank . "MB ${memtype}s";
			} else {
				if ($socket eq "motherboard") {
					$buffer .= "$socket has ";
					$buffer .= $simmsize/$simmsperbank . "MB";
				} else {
					if ($model eq "SPARCsystem-600" | $model =~ /Sun.4.600/) {
						if ($newslots[$val] =~ /00000[4-7]00/) {
							$exp="Expansion board 0";
						}
						if ($newslots[$val] =~ /00000[89ab]00/) {
							$exp="Expansion board 1";
						}
						if ($newslots[$val] =~ /00000[4-9ab]00/) {
							$buffer .= "$exp ";
							$banks="$exp bank $bank";
						}
						$banks_used .= " $banks" if ($banks ne "" & $banks_used !~ /$banks/);
					}
					if ($sockettype) {
						$buffer .= "${sockettype} $socket has a ";
					} else {
						$buffer .= "$socket is a ";
					}
					$buffer .= $simmsize/$simmsperbank . "MB";
					$buffer .= " (" . $simmsize/$simmsperbank/1024 . "GB)" if ($simmsize/$simmsperbank > 1023);
					$buffer .= " $memtype";
					push(@simmsizesfound, $simmsize/$simmsperbank);
				}
			}
			if ($verbose) {
				$buf="";
				if ($order ne "") {
					$buf .= "$order";
					$buf .= " $memtype" if ($memtype !~ /memory card/);
				}
				$buf .= "slot $slotnum" if ($slotnum ne "");
				$buf .= ", " if ($order ne "" | $slotnum ne "");
				$buf .= "group $group, " if ($group ne "");
				if ($bank ne "") {
					if ($bank =~ /Quad/) {
						$buf .= "$bank, ";
					} elsif ($dualbank eq 1) {
						$buf .= "banks $bank, ";
					} else {
						$buf .= "bank $bank, ";
					}
					$foundbank1or3=1 if ($bank eq 1 | $bank eq 3);
				}
				$buf .= "byte $byte, " if ($byte ne "");
				$buf .= "address 0x${start1x}-0x$stop1x" if ($start1x ne "");
				$buffer .= " ($buf)" if ($buf ne "");
			}
			$buffer .= "\n";
			$cnt2++;
			$cnt3=($bankcnt * $simmsperbank / $simmspergroup) + $cnt2;
			if ($#socketstr) {
				$socket=$socketstr[$cnt3];
				$socket=$socketstr[$cnt3+4] if ($found10bit & $newslots[$val] !~ /00000[0-3]00/);
				# DEBUG
				#print "socketstr[$cnt3], bankcnt=$bankcnt, cnt2=$cnt2\n";
			}
			$order=$orderstr[$cnt3] if ($#orderstr);
			$group=$groupstr[$cnt3] if ($#groupstr);
			$slotnum=$slotstr[$cnt3] if ($#slotstr);
			if ($#bankstr) {
				$bank=$bankstr[$cnt3];
				$bank=$bankstr[$cnt3+4] if ($found10bit & $newslots[$val] !~ /00000[0-3]00/);
			}
			$banks=$banksstr[$cnt3/$simmsperbank] if ($#banksstr);
			$byte=$bytestr[$cnt3] if ($#bytestr);
		}
	} elsif ($ultra eq 1 | $ultra eq 5 | $ultra eq 10 | $ultra eq 30) {
		$buffer .= "bank $slot has a pair of " . $simmsize/2 . "MB DIMMs\n";
		push(@simmsizesfound, $simmsize/2);
	} elsif ($ultra eq 2 | $ultra eq 250 | $ultra eq 450 | $ultra eq 80 | $ultra eq "420R" | $ultra eq "Netra t140x" | $ultra eq "Netra ft1800") {
		$buffer .= "group $slot has four " . $simmsize/4 . "MB DIMMs\n";
		push(@simmsizesfound, $simmsize/4);
	} elsif ($ultra eq 60 | $ultra eq "220R") {
		$buffer .= "group $slot has four " . $simmsize/2 . "MB DIMMs\n";
		push(@simmsizesfound, $simmsize/2);
	} elsif ($ultra eq "e") {
		$buffer .= "group $slot has eight " . $simmsize/8 . "MB DIMMs\n";
		push(@simmsizesfound, $simmsize/8);
	} elsif ($socket eq "motherboard") {
		$buffer .= "$slot has ${simmsize}MB\n";
		push(@simmsizesfound, $simmsize);
	} else {
		$buffer .= "slot $slot has a ${simmsize}MB";
		$buffer .= " (" . $simmsize/1024 . "GB)" if ($simmsize > 1023);
		$buffer .= " $memtype\n";
		push(@simmsizesfound, $simmsize);
	}
	$slot++;
}

#
# Try to distinguish Ultra 5 from Ultra 10
# Cannot distinguish Ultra 5/333MHz from Ultra 10/333MHz (375-0066 motherboard)
# Cannot distinguish Ultra 5/440MHz from Ultra 10/440MHz (375-0079 motherboard)
#
if ($model eq "Ultra-5_10" | $ultra eq "5_10" | $ultra eq 5 | $ultra eq 10) {
	if ($motherboard =~ /375-0009/) {
		$ultra=($sysfreq > 91) ? 10 : 5;
		$realmodel=($ultra eq 5) ? "(Ultra 5)" : "(Ultra 10)";
	}
	# Determine if interleaving of banks using four identical sized DIMMs
	# Assume 1-way interleaving with mix of stacked and unstacked DIMMs
	$interleave=1;
	if ($#newslots == 3 & $stacked == 0) {
		$interleave=2 if ($newslots[1] eq $newslots[3]);
	}
	if ($#newslots == 7 & $stacked == 2) {
		$interleave=2 if ($newslots[1] eq $newslots[5]);
	}
}
&finish;
exit;

sub finish {
	&show_header;
	#print "newslots=@newslots\n" if ($#newslots > 0 & $verbose > 1);
	print $buffer if ($buffer ne "");
	#
	# Special memory options
	#
	if ($sxmem) {
		# Currently assumes only one VSIMM is installed.
		# Auxiliary Video Board 501-2020 (SS10SX) or 501-2488 (SS20)
		# required if two VSIMMs are installed.
		if ($model eq "SPARCstation-20" | $model eq "SuperCOMPstation-20S") {
			# SS20 1st VSIMM in J0304/J0407, 2nd in J0305/J0406
			print "sockets J0304/J0407 have";
			$sockets_used .= " J0304";
		} elsif ($model =~ /COMPstation-20A\b/) {
			# 1st VSIMM in J0202, 2nd in J0301
			print "socket J0202 has";
			$sockets_used .= " J0202";
		} else {
			# SS10SX 1st VSIMM in J0301/J1203, 2nd in J0202/J1201
			print "sockets J0301/J1203 have";
			$sockets_used .= " J0301";
		}
		print " a ${sxmem}MB VSIMM installed for SX (CG14) graphics\n";
	}
	if ($nvmem) {
		# NVSIMMs for Prestoserve
		if ($model eq "SPARCstation-20" | $model eq "SuperCOMPstation-20S") {
			# SS20 1st 2MB NVSIMM in J0305/J0406, 2nd in J0304/J0407
			if ($nvmem1) {
				$sockets_used .= " J0305";
				print "sockets J0305/J0406 have a 2MB NVSIMM";
				print " installed for Prestoserve\n";
			}
			if ($nvmem2) {
				$sockets_used .= " J0304";
				print "sockets J0304/J0407 have a 2MB NVSIMM";
				print " installed for Prestoserve\n";
			}
		} elsif ($model =~ /COMPstation-20A\b/) {
			# 1st 2MB NVSIMM in J0301, 2nd in J0202
			if ($nvmem1) {
				$sockets_used .= " J0301";
				print "socket J0301 has a 2MB NVSIMM";
				print " installed for Prestoserve\n";
			}
			if ($nvmem2) {
				$sockets_used .= " J0202";
				print "socket J0202 has a 2MB NVSIMM";
				print " installed for Prestoserve\n";
			}
		} elsif ($model =~ /SPARCstation-10/ | $model eq "Premier-24") {
			# SS10 1st 2MB NVSIMM in J0202/J1201, 2nd in J0301/J1203
			if ($nvmem1) {
				$sockets_used .= " J0202";
				print "sockets J0202/J1201 have a 2MB NVSIMM";
				print " installed for Prestoserve\n";
			}
			if ($nvmem2) {
				$sockets_used .= " J0301";
				print "sockets J0301/J1203 have a 2MB NVSIMM";
				print " installed for Prestoserve\n";
			}
		} else {
			# SS1000 supports two banks of four 1MB NVSIMMs
			# SC2000 supports one bank of eight 1MB NVSIMMs
			print "Has ${nvmem}MB of NVSIMM installed for Prestoserve ";
			if ($model eq "SPARCserver-1000") {
				print "(1 bank of 4" if ($nvmem == 4);
				print "(2 banks of 4" if ($nvmem == 8);
			} else {
				print "(1 bank of 8";
			}
			print " 1MB NVSIMMs$nvsimm_banks)\n";
		}
	}

	#
	# Check for empty banks or sockets
	#
	if ($#banksstr > 0) {
		print "empty $bankname:";
		foreach $banks (@banksstr) {
			if ($banks ne "?") {
				if ($banks_used !~ /\b$banks\b/ &
				    $sockets_empty !~ /\b$banks\b/) {
					if ($sockets_empty ne "") {
						$sockets_empty .= ", $banks";
					} else {
						$sockets_empty .= " $banks";
					}
				}
			}
		}
		if ($sockets_empty ne "") {
			print "$sockets_empty\n";
		} else {
			print " None\n";
		}
	} elsif ($#socketstr > 0) {
		if ($sockettype) {
			print "empty ${sockettype}s:";
		} else {
			print "empty memory slots:";
		}
		foreach $socket (@socketstr) {
			if ($socket ne "?") {
				if ($sockets_used !~ /\b$socket\b/ &
				    $sockets_empty !~ /\b$socket\b/) {
					if ($memtype =~ /memory card/ &
					    $sockets_empty ne "") {
						$sockets_empty .= ", $socket";
					} else {
						$sockets_empty .= " $socket";
					}
				}
			}
		}
		if ($sockets_empty ne "") {
			print "$sockets_empty\n";
		} else {
			print " None\n";
		}
	} elsif ($verbose > 1 & $sockets_used ne "") {
		print "memory sockets used: ${sockets_used}\n";
	}
	# Look for duplicate sockets
	if ($sockets_used ne "" & $prtdiag_exec ne "") {
		$dup_sockets="";
		foreach $socket (sort split(' ', $sockets_used)) {
			next if ($socket eq "board" | $socket eq "mezzanine");
			next if ($model eq "SPARCsystem-600" | $model =~ /Sun.4.600/);
			$pos=-1;
			$cnt=0;
			while (($pos=index(" $sockets_used ", " $socket ", $pos)) > -1) {
				$pos++;
				$cnt++;
				if ($cnt == 2 & $socket ne "-" & $socket ne "?") {
					if ($dup_sockets !~ /\b$socket\b/) {
						$dup_sockets .= " $socket";
						print "ERROR: Duplicate socket $socket found\n";
						$exitstatus=1;
					}
				}
			}
		}
		if ($dup_sockets ne "") {
			print "WARNING: Memory was not properly reported by";
			print " the 'prtdiag' command.\n";
			&recommend_prtdiag_patch;
		}
	}
	# Look for unlabeled sockets
	if ( $sockets_used =~ /\s-\s|^-\s|\s-$|^-$/) {
		print "WARNING: Unlabeled socket found";
		if ($prtdiag_exec ne "") {
			print " in the 'prtdiag' command output";
		}
		print ".\n         This may cause the reported empty sockets";
		print " to be incorrect.\n";
		&recommend_prtdiag_patch;
	}
	# Make sure Sun Fire V480/V490/V880/V890 is fully stuffed if >= 1050MHz
	if ($ultra =~ /Sun Fire V[48][89]0\b/) {
		if ($cpufreq >= 1050 & $banks_used ne "A0 A1 B0 B1") {
			print "ERROR: System should not have any empty banks since CPU is >= 1050MHz.\n";
		}
	}

	#
	# Print total memory
	#
	print "total memory = ${totmem}MB";
	print " (", $totmem / 1024, "GB)" if ($totmem > 1023);
	print "\n";
	print "$permission_error" if ($permission_error);
	if ($prtconf_warn ne "") {
		print "WARNING: $prtconf_warn\n";
		print "         This may be corrected by installing ";
		print "a Sun patch on this system.\n";
	}

	#
	# Check for illegal memory stuffings
	#
	if ($model eq "Sun 4/50" | $model eq "Sun 4/25") {	# IPX, ELC
		if ($slot0 != 16 & $largestsimm == 16 & $osrel =~ /4.1.1/) {
			print "ERROR: Install the highest capacity 16MB SIMM";
			print " in socket $socketstr[0] under SunOS 4.1.1.\n";
			$exitstatus=1;
		}
	}
	if ($model =~ /SPARCclassic/ | $model =~ /SPARCstation-LX/) {
		if ($found32mb) {
			# Reportedly can accept 32MB SIMMs in bank 1, allowing
			# 128MB total (2x32, 4x16)
			print "NOTICE: The 32MB SIMM is not supported in the";
			print " $model according to\n    Sun. However it does";
			print " appear to work in bank 1 only, allowing a";
			print " maximum of\n    128MB of total memory (2x32MB";
			print " bank 1 + 4x16MB banks 2 & 3).\n";
		}
		if ($found8mb) {
			# Possibly can accept 8MB SIMMs in bank 1
			print "NOTICE: The 8MB SIMM is not supported in the";
			print " $model according to\n    Sun. However it does";
			print " appear to work in bank 1 only.\n";
		}
	}
	if ($model =~ /SPARCstation-10/ | $model eq "Premier-24") {
		if ($slot0 < $largestsimm & $BSD) {
			print "ERROR: Install the highest capacity SIMM in";
			print " socket $socketstr[0] under Solaris 1.X.\n";
			$exitstatus=1;
		}
		if (! $found32mb & $found16mb & $romvermajor eq 2 & $romverminor < 19) {
			print "WARNING: The 32MB SIMM is not supported in the";
			print " SS10 or SS10SX according to\n    Sun. However";
			print " it does work correctly depending on the Open";
			print " Boot PROM\n    version. This system is running";
			print " OBP $romvernum, so 32MB SIMMs will only be\n";
			print "    recognized as 16MB SIMMs. You should";
			print " upgrade to OBP 2.19 or later in order\n    to";
			print " be able to detect and utilize 32MB SIMMs.\n";
			# OBP 2.14 and earlier see the 32MB SIMM as 16MB.
			# OBP 2.15 on a SS20 does see the 32MB SIMM as 32MB.
			# Have not tested 32MB SIMMs on SS10 with OBP 2.15-2.18
			if ($romverminor > 14) {
				$untested=1;
				$untested_type="OBP";
			}
		}
		if ($found32mb & $romvermajor eq 2 & $romverminor < 19) {
			print "NOTICE: The 32MB SIMM is not supported in the";
			print " SS10 or SS10SX according to\n    Sun. However";
			print " it does work correctly depending on the Open";
			print " Boot PROM\n    version. This system is running";
			print " OBP $romvernum, and 32MB SIMMs were properly\n";
			print "    recognized.\n";
			@simmsizes=(16,32,64);
			if ($romvernum ne "2.X") {
				$untested=1;
				$untested_type="OBP";
			}
		}
		if (! $nvmem1 & $nvmem2) {
			print "ERROR: First NVSIMM should be installed in";
			print " socket J0202, not socket J0301\n";
			$exitstatus=1;
		}
	}
	if ($model eq "SPARCstation-20" | $model eq "SuperCOMPstation-20S") {
		if (! $nvmem1 & $nvmem2) {
			print "ERROR: First NVSIMM should be installed in";
			print " socket J0305, not socket J0304\n";
			$exitstatus=1;
		}
	}
	if ($model eq "SPARCstation-5") {
		if ($slot0 < $largestsimm & $BSD) {
			print "ERROR: Install the highest capacity SIMM in";
			print " socket $socketstr[0] under Solaris 1.X.\n";
			$exitstatus=1;
		}
		if ($osrel eq "4.1.3_U1" & $found32mb) {
			# Look to see if patch 101508-07 or later is installed
			# for 32MB SIMMs to work properly (bug 1176458)
			$what=&mychomp(`/usr/ucb/what /sys/sun4m/OBJ/module_vik.o`);
			if ($what !~ /module_vik.c 1.38 94\/08\/22 SMI/) {
				print "WARNING: Install SunOS 4.1.3_U1 patch";
				print " 101508-07 or later in order for 32MB\n";
				print "    SIMMs to work reliably on the";
				print " SPARCstation 5.\n";
			}
		}
	}
	if ($model eq "Ultra-5_10" | $ultra eq "5_10" | $ultra eq 5 | $ultra eq 10) {
		if ($smallestsimm == 16 & $largestsimm > 16) {
			print "ERROR: 16MB DIMMs cannot be mixed with larger";
			print " DIMMs on Ultra 5/10 systems.\n";
			$exitstatus=1;
		}
	}
	if ($ultra eq 5) {
		if ($largestsimm == 256) {
			print "NOTICE: The 256MB DIMM is not supported in the";
			print " Ultra 5 according to\n    Sun. However it does";
			print " work correctly as long as you use low-profile";
			print "\n    DIMMs or take out the floppy drive.\n";
		}
	}
	if ($ultra eq "AXi") {
		# DIMMs should be chosen as all 10-bit or all 11-bit column
		# address type. If using 11-bit, then only use Bank 0 & 2.
		if ($found10bit & $found11bit) {
			print "ERROR: You should not mix 10-bit and 11-bit";
			print " column address type DIMMs in the\n    ";
			print "SPARCengine Ultra AXi.\n";
			$exitstatus=1;
		}
		if ($found11bit) {
			if ($foundbank1or3) {
				print "ERROR";
				$exitstatus=1;
			} else {
				print "WARNING";
			}
			print ": Do not use Bank 1 (sockets U0402 & U0401) &";
			print " Bank 3 (sockets U0302 &\n    U0301) since";
			print " 11-bit column address type DIMMs are";
			print " installed. You should\n    only use Bank 0";
			print " (sockets U0404 & U0403) & Bank 2 (sockets";
			print " U0304 & U0303).\n";
		}
	}
	if ($model eq "Ultra-4" | $ultra eq 450 | $model eq "Ultra-4FT" | $ultra eq "Netra ft1800") {
		if ($found16mb) {
			print "WARNING: 16MB DIMMs are not supported and may";
			print " cause correctable ECC errors.\n";
		}
	}

	#
	# Check for unsupported memory sizes
	#
	foreach $i (@simmsizesfound) {
		$smallestsimm=$i if ($i < $smallestsimm);
		$largestsimm=$i if ($i > $largestsimm);
		$simmsizelegal=0;
		foreach $j (@simmsizes) {
			if ($i == $j) {
				$simmsizelegal=1;
			}
		}
		if ($simmsizelegal == 0 & $simmsizes[0] > 0) {
			print "ERROR: Unsupported ${i}MB $memtype found (supported ";
			if ($#simmsizes == 0) {
				print "size is @{simmsizes}MB)\n";
			} else {
				print "MB sizes are: @simmsizes)\n";
			}
			$exitstatus=1;
		}
	}
	if ($smallestsimm < $simmsizes[0]) {
		print "ERROR: Smaller than expected $memtype found ";
		print "(found ${smallestsimm}MB, smallest expected ";
		print "${simmsizes[0]}MB)\n";
		$exitstatus=1;
	}
	if ($largestsimm > $simmsizes[$#simmsizes]) {
		print "ERROR: Larger than expected $memtype found ";
		print "(found ${largestsimm}MB, largest expected ";
		print "${simmsizes[$#simmsizes]}MB)\n";
		$exitstatus=1;
	}

	#
	# Check for buggy perl version
	#
	if ($perlhexbug) {
		print "ERROR: This Perl V$PERL_VERSION is buggy in hex number";
		print " conversions.\n";
		$exitstatus=1;
	}
	if ($PERL_VERSION == 5.001) {
		print "WARNING: Perl V5.001 is known to be buggy in hex number";
		print " conversions.\n";
	}
	if ($PERL_VERSION < 5.002) {
		print "WARNING: Perl V5.002 or later is recommended for best";
		print " results.\n";
		print "         You are running Perl V${PERL_VERSION}\n";
	}

	#
	# Check for bad eeprom banner-name. This happens sometimes when OBP 3.23
	# or later is installed on Ultra-60/E220R and Ultra-80/E420R systems.
	#
	if ($banner =~ /^ \(/) {
		print "ERROR: banner-name not set in EEPROM (BugID 4257412).";
		print " Cannot distinguish an\n       ";
		print "Ultra 60 from an Enterprise 220R" if ($model eq "Ultra-60");
		print "Ultra 80 from an Enterprise 420R or Netra t 1400/1405" if ($model eq "Ultra-80");
		print "Sun Blade 1000/2000 from a Sun Fire 280R or Netra 20" if ($ultra eq "Sun Blade 1000" | $ultra eq "Sun Blade 2000" | $ultra eq "Sun Fire 280R" | $ultra eq "Netra 20");
		print ".\n       To correct this problem, please run one of ";
		print "the following commands as\n       root depending on ";
		print "the system you have:\n";
		if ($model eq "Ultra-60") {
			print "            eeprom banner-name='Sun Ultra 60 UPA/PCI'\n";
			print "            eeprom banner-name='Sun Enterprise 220R'\n";
			print "Note: Netra t1120/1125 systems may also use the 'Sun Ultra 60 UPA/PCI' banner\n";
		}
		if ($model eq "Ultra-80") {
			print "            eeprom banner-name='Sun Ultra 80 UPA/PCI'\n";
			print "            eeprom banner-name='Sun Enterprise 420R'\n";
			print "            eeprom banner-name='Netra t 1400/1405'\n";
			print "Note: Netra t1400/1405 systems may also use the 'Sun Ultra 80 UPA/PCI' banner\n";
		}
		if ($ultra eq "Sun Blade 1000" | $ultra eq "Sun Blade 2000" | $ultra eq "Sun Fire 280R" | $ultra eq "Netra 20") {
			print "            eeprom banner-name='Sun-Blade-1000'\n";
			print "            eeprom banner-name='Sun Fire 280R'\n";
			print "            eeprom banner-name='Netra 20'\n";
			print "Note: Netra 20 systems may also use the 'Sun-Blade-1000' banner\n";
		}
		$exitstatus=1;
	}

	#
	# Check for possible memory detection errors by this program
	#
	if ($prtdiag_failed == 2) {
		# non-global zone
		print "NOTICE: More details would be reported if memconf was run in the global zone\n";
		$prtdiag_has_mem=0;
	}
	if (! $boardfound_mem & $prtdiag_has_mem) {
		print "WARNING: Memory should have been reported in the output from\n";
		if ($prtdiag_cmd) {
			print "       $prtdiag_cmd";
		} else {
			print "       prtdiag, which was not found";
			if (-d '/usr/platform') {
				print " in /usr/platform/$machine/sbin";
			}
		}
		print "\nERROR: prtdiag failed!" if ($prtdiag_failed == 1);
		print "\n       This system may be misconfigured, or may be";
		print " missing software packages\n       like SUNWpiclr,";
		print " SUNWpiclu and SUNWpiclx, or may need the latest\n";
		print "       recommended Sun patches installed from";
		print " http://www.sunsolve.com/\n";
		if ($ultra eq "Sun Fire V880") {
			print "       This may be corrected by installing ";
			print "Sun patch 112186-19 or 119231-01 or later.\n";
		}
		print "       Check my website at $URL\n";
		print "       to get the latest version of memconf.\n";
		$exitstatus=1;
	}
	if ($recognized == 0) {
		print "ERROR: Layout of memory ${sockettype}s not completely ";
		print "recognized on this system.\n";
		$exitstatus=1;
	}
	if ($recognized < 0) {
		print "WARNING: Layout of memory ${sockettype}s not completely";
		print " recognized on this system.\n";
		if ($model eq "Ultra-80" | $ultra eq 80 | $ultra eq "420R" | $ultra eq "Netra t140x") {
			if ($recognized == -2) {
				# Hack: If Ultra-80 or Enterprise 420R has 4GB
				# of memory (maximum allowed), then memory line
				# was rewritten to show memory stuffing.
				print "       The memory configuration displayed should be";
				print " correct though since this\n";
				print "       is a fully stuffed system.\n";
			} else {
				print "       The memory configuration displayed is a guess which may be incorrect.\n";
				if ($totmem eq 2048) {
					print "       The 2GB of memory installed may be 8 256MB DIMMs populating any 2 of\n";
					print "       the 4 banks, or 16 128MB DIMMs populating all 4 banks.\n";
				}
				if ($totmem eq 1024) {
					print "       The 1GB of memory installed may be 4 256MB DIMMs populating any 1 of\n";
					print "       the 4 banks, 8 128MB DIMMs populating any 2 of the 4 banks, or 16 64MB\n";
					print "       DIMMs populating all 4 banks.\n";
				}
				if ($totmem eq 512) {
					print "       The 512MB of memory installed may be 4 128MB DIMMs populating any 1 of\n";
					print "       the 4 banks, 8 64MB DIMMs populating any 2 of the 4 banks, or 16 32MB\n";
					print "       DIMMs populating all 4 banks.\n";
				}
				if ($totmem eq 256) {
					print "       The 256MB of memory installed may be 4 64MB DIMMs populating any 1 of\n";
					print "       the 4 banks, or 8 32MB DIMMs populating any 2 of the 4 banks.\n";
				}
			}
			print "       This is a known bug due to Sun's 'prtconf', 'prtdiag' and 'prtfru'\n";
			print "       commands not providing enough detail for the memory layout of this\n";
			print "       SunOS $osrel $platform system to be accurately determined.\n";
			print "       This is a bug in Sun's OBP, not a bug in memconf.\n";
			print "       The latest release (OBP 3.33.0 2003/10/07) still has this bug.\n";
			print "       This system is using $romver\n";
			$exitstatus=1;
			&show_request if ($prtfru_cmd ne "" | $prtpicl_cmd ne "");
		}
		if ($ultra eq "Sun Blade 1000" | $ultra eq "Sun Blade 2000" | $ultra eq "Sun Fire 280R" | $ultra eq "Netra 20") {
			# Do this if memory was not in the output of prtdiag
			if ($recognized == -2) {
				# Hack: If Sun Blade 1000 has 8GB of memory (maximum
				# allowed), then memory line was rewritten to show
				# memory stuffing.
				print "       The memory configuration displayed should be";
				print " correct though since this\n";
				print "       is a fully stuffed system.\n";
			} else {
				print "       The memory configuration displayed is a guess which may be incorrect.\n";
			}
		}
		if ($ultra eq "Sun Fire T2000") {
			# Do this if memory was not in the output of prtdiag
			# Hack: If Sun Fire T2000 has 8GB or 16GB of memory
			# then it may be two ranks of DIMMs
			print "       The memory configuration displayed is a guess which may be incorrect.\n";
			print "       Base Sun configurations ship with two ranks of modules installed.\n";
			print "       This system may have one rank of " . $simmsizesfound[0]*2 . "MB DIMM modules installed instead\n";
			print "       of two ranks of " . $simmsizesfound[0] . "MB DIMM modules as shown.\n";
			print "       This is a known bug due to Sun's 'prtconf', 'prtdiag' and 'prtfru'\n";
			print "       commands not providing enough detail for the memory layout of this\n";
			print "       SunOS $osrel $platform system to be accurately determined.\n";
			print "       This is a Sun bug, not a bug in memconf.\n";
			$exitstatus=1;
			&show_request if ($prtfru_cmd ne "" | $prtpicl_cmd ne "");
		}
	}
	if ($banner =~ /Netra t1\b/ | $ultra eq "Netra t1" | $model eq "Netra t1") {
		if ($totmem eq 1024) {
			print "WARNING: Cannot distinguish between four";
			print " 370-4155 256MB mezzanine boards and\n";
			print "         two 512MB mezzanine boards.\n";
		}
	}
	if ($installed_memory > 0) {
		if ($installed_memory != $totmem) {
			print "ERROR: Total memory installed (${installed_memory}MB) ";
			print "does not match total memory found.\n";
			$recognized=0;
			$exitstatus=1;
		}
	}
	if ($failed_memory > 0) {
		print "ERROR: Failed memory (${failed_memory}MB) was detected.\n";
		print "       You should consider replacing the failed memory.\n";
		$exitstatus=1;
	}
	if ($spare_memory > 0) {
		print "NOTICE: Spare memory (${spare_memory}MB) was detected.\n";
		print "        You can configure the spare memory using the 'cfgadm' command.\n";
	}
	if ($failing_memory > 0) {
		print "ERROR: Some of the installed memory may be failing.\n";
		print "       You should consider replacing the failed memory.\n";
		$exitstatus=1;
	}
	&show_unrecognized if ($recognized == 0);
	# Tested on SunOS 4.X - 5.10 (Solaris 1.0 through Solaris 10)
	# Flag Future/Beta SunOS releases as untested
	if ($osrel =~ /^5.1[1-9]/ | $osrel =~ /^[6-9]/) {
		$untested=1;
		$untested_type="OS" if ("$untested_type" eq "");
	}
	# Flag untested CPU types:
	# US-IV+ (Panther), US-III+ (Serrano)
	if ($cputype =~ /UltraSPARC-IV\+/ | $cputype =~ /UltraSPARC-IIIi\+/) {
		$untested=1;
		$untested_type="CPU" if ("$untested_type" eq "");
	}
	&show_untested if ($untested);
	&mailmaintainer if ($verbose == 3);
	exit $exitstatus;
}

sub mailmaintainer {
	# E-mail information of system to maintainer. Use system call to
	# mail instead of Mail::Send module so that this works for perl4
	print "\nSending E-mail to memconf maintainer tschmidt\@micron.com";
	print " with output of:\n            memconf -d  (seen above)\n";
	print "            $config_cmd\n";
	if ("$operating_system" eq "SunOS") {
		print "            $prtdiag_cmd -v\n" if ($prtdiag_exec ne "");
		print "            $prtfru_cmd -x\n" if ($prtfru_cmd ne "");
		print "            $prtpicl_cmd -v\n" if ($prtpicl_cmd ne "");
	}
	if ($filename) {
		if ($SUNWexplo == 1) {
			$mail_from="Sun Explorer directory $filename";
		} else {
			$mail_from="filename $filename";
		}
	} else {
		$mail_from="$hostname";
	}
	$mail_from="memconf output from $mail_from";
	if (-x '/usr/bin/mailx') {
		$mail_prog='/usr/bin/mailx -s "' . $mail_from . '"';
	} elsif (-x '/usr/ucb/mail') {
		$mail_prog='/usr/ucb/mail -s "' . $mail_from . '"';
	} else {
		$mail_prog='mail';
	}
	# Rewrite fully-qualified hostnames so that attachment filename has
	# only one extension.
	$newhostname=$hostname;
	$newhostname=~s/\./_/g;
	close(STDOUT);
	open(MAILFILE, ">>/tmp/memconf.output") || die "can't open /tmp/memconf.output: $!";
	print MAILFILE "\n";
	print MAILFILE "------------------------------------------------------------------------------\n";
	print MAILFILE "Attaching uuencoded output from '" . $config_cmd . "'\n";
	if ("$operating_system" eq "SunOS") {
		if ($prtdiag_exec ne "") {
			print MAILFILE "Attaching uuencoded output from '" . $prtdiag_cmd . " -v'\n";
		}
		if ($prtfru_cmd ne "") {
			print MAILFILE "Attaching uuencoded output from '" . $prtfru_cmd . " -x'\n";
		}
		if ($prtpicl_cmd ne "") {
			print MAILFILE "Attaching uuencoded output from '" . $prtpicl_cmd . " -v'\n";
		}
	}
	print MAILFILE "------------------------------------------------------------------------------\n";
	close(MAILFILE);
	open(MAILFILE, "| /usr/bin/uuencode ${config_command}_${newhostname}.txt >>/tmp/memconf.output") || die "can't open /tmp/memconf.output: $!";
	print MAILFILE @config;
	close(MAILFILE);
	if ("$operating_system" eq "SunOS") {
		if ($prtdiag_exec ne "") {
			close(MAILFILE);
			open(MAILFILE, "| /usr/bin/uuencode prtdiag_${newhostname}.txt >>/tmp/memconf.output") || die "can't open /tmp/memconf.output: $!";
			print MAILFILE @prtdiag;
			close(MAILFILE);
		}
		if ($prtfru_cmd ne "") {
			close(MAILFILE);
			open(MAILFILE, "| /usr/bin/uuencode prtfru_${newhostname}.txt >>/tmp/memconf.output") || die "can't open /tmp/memconf.output: $!";
			print MAILFILE @prtfru;
			close(MAILFILE);
		}
		if ($prtpicl_cmd ne "") {
			close(MAILFILE);
			open(MAILFILE, "| /usr/bin/uuencode prtpicl_${newhostname}.txt >>/tmp/memconf.output") || die "can't open /tmp/memconf.output: $!";
			print MAILFILE @prtpicl;
			close(MAILFILE);
		}
	}
	`$mail_prog tschmidt\@micron.com < /tmp/memconf.output`;
	unlink "/tmp/memconf.output";
}

sub hpux_cstm {
	$HPUX=1;
	$config_cmd="echo 'selclass qualifier memory;info;wait;infolog'|/usr/sbin/cstm";
	$config_command="cstm";
	$model=$machine;
	if ($filename eq "") {
		if (-x '/usr/bin/model') {
			$model=&mychomp(`/usr/bin/model`);
		}
	} else {
		$model="";
		$machine="";
		$platform="";
		$operating_system="HP-UX";
	}
	$model="HP $model" if ($model !~ /^HP/);
	&show_header;
	# Use HP-UX Support Tool Manager software to attempt to report memory
	if ($filename eq "") {
		@config=`$config_cmd`;
	}
	foreach $line (@config) {
		$line=~s/\015//g;	# Remove any DOS carriage returns
		if ($flag_mem == 1) {
			next if ($line eq "\n" | $line =~ /^ +$/);
			next if ($line =~ /Log creation time/);
			if ($line =~ /^-- Information Tool Log for /) {
				$flag_mem=0;	# End of memory section
				next;
			}
			push(@boards_mem, "$line");
			$boardfound_mem=1;
		}
		if ($line =~ /^-- Information Tool Log for MEMORY / & $flag_mem == 0) {
			$flag_mem=1;	# Start of memory section
		}
	}
	if ($boardfound_mem) {
		print "@boards_mem";
	} else {
		if (-r '/var/adm/syslog/syslog.log') {
			open(FILE, "</var/adm/syslog/syslog.log");
			@syslog=<FILE>;
			close(FILE);
			@physical=grep(/Physical:/,@syslog);
			foreach $line (@physical) {
				@linearr=split(' ', $line);
				$totmem=$linearr[6] / 1024;
				next;
			}
			print "     Total Physical Memory     : ${totmem} MB\n" if ($totmem > 0);
		}
		print "ERROR: /usr/sbin/cstm did not report the memory installed in this HP-UX system.\n";
		print "       Cannot display detailed memory configuration. Aborting.\n";
		$exitstatus=1;
	}
	&mailmaintainer if ($verbose == 3);
	exit $exitstatus;
}
