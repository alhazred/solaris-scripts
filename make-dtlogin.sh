#!/bin/sh

#
# CDE DtLogin Generator - version 1.1
# Copyright 2002 by Michael Peek (http://www.tiem.utk.edu/~peek)
#
# Use this script at your own risk.  I take no liability whatsoever for
# anything that this script does.
#

#
# GNU GENERAL PUBLIC LICENSE
# 
# Version 2, June 1991
# 
# Copyright (C) 1989, 1991 Free Software Foundation, Inc.  59 Temple Place -
# Suite 330, Boston, MA  02111-1307, USA
# 
# Everyone is permitted to copy and distribute verbatim copies of this license
# document, but changing it is not allowed.
# 
# Preamble
# 
# The licenses for most software are designed to take away your freedom to
# share and change it. By contrast, the GNU General Public License is intended
# to guarantee your freedom to share and change free software--to make sure
# the software is free for all its users. This General Public License applies
# to most of the Free Software Foundation's software and to any other program
# whose authors commit to using it. (Some other Free Software Foundation
# software is covered by the GNU Library General Public License instead.) You
# can apply it to your programs, too.
# 
# When we speak of free software, we are referring to freedom, not price. Our
# General Public Licenses are designed to make sure that you have the freedom
# to distribute copies of free software (and charge for this service if you
# wish), that you receive source code or can get it if you want it, that you
# can change the software or use pieces of it in new free programs; and that
# you know you can do these things.
# 
# To protect your rights, we need to make restrictions that forbid anyone to
# deny you these rights or to ask you to surrender the rights. These
# restrictions translate to certain responsibilities for you if you distribute
# copies of the software, or if you modify it.
# 
# For example, if you distribute copies of such a program, whether gratis or
# for a fee, you must give the recipients all the rights that you have. You
# must make sure that they, too, receive or can get the source code. And you
# must show them these terms so they know their rights.
# 
# We protect your rights with two steps: (1) copyright the software, and (2)
# offer you this license which gives you legal permission to copy, distribute
# and/or modify the software.
# 
# Also, for each author's protection and ours, we want to make certain that
# everyone understands that there is no warranty for this free software. If
# the software is modified by someone else and passed on, we want its
# recipients to know that what they have is not the original, so that any
# problems introduced by others will not reflect on the original authors'
# reputations.
# 
# Finally, any free program is threatened constantly by software patents. We
# wish to avoid the danger that redistributors of a free program will
# individually obtain patent licenses, in effect making the program
# proprietary. To prevent this, we have made it clear that any patent must be
# licensed for everyone's free use or not licensed at all.
# 
# The precise terms and conditions for copying, distribution and modification
# follow.  TERMS AND CONDITIONS FOR COPYING, DISTRIBUTION AND MODIFICATION
# 
# 0. This License applies to any program or other work which contains a notice
# placed by the copyright holder saying it may be distributed under the terms
# of this General Public License. The "Program", below, refers to any such
# program or work, and a "work based on the Program" means either the Program
# or any derivative work under copyright law: that is to say, a work
# containing the Program or a portion of it, either verbatim or with
# modifications and/or translated into another language. (Hereinafter,
# translation is included without limitation in the term "modification".) Each
# licensee is addressed as "you".
# 
# Activities other than copying, distribution and modification are not covered
# by this License; they are outside its scope. The act of running the Program
# is not restricted, and the output from the Program is covered only if its
# contents constitute a work based on the Program (independent of having been
# made by running the Program). Whether that is true depends on what the
# Program does.
# 
# 1. You may copy and distribute verbatim copies of the Program's source code
# as you receive it, in any medium, provided that you conspicuously and
# appropriately publish on each copy an appropriate copyright notice and
# disclaimer of warranty; keep intact all the notices that refer to this
# License and to the absence of any warranty; and give any other recipients of
# the Program a copy of this License along with the Program.
# 
# You may charge a fee for the physical act of transferring a copy, and you
# may at your option offer warranty protection in exchange for a fee.
# 
# 2. You may modify your copy or copies of the Program or any portion of it,
# thus forming a work based on the Program, and copy and distribute such
# modifications or work under the terms of Section 1 above, provided that you
# also meet all of these conditions:
# 
#     * a) You must cause the modified files to carry prominent notices
#     stating that you changed the files and the date of any change.
# 
#     * b) You must cause any work that you distribute or publish, that in
#     whole or in part contains or is derived from the Program or any part
#     thereof, to be licensed as a whole at no charge to all third parties
#     under the terms of this License.
# 
#     * c) If the modified program normally reads commands interactively when
#     run, you must cause it, when started running for such interactive use in
#     the most ordinary way, to print or display an announcement including an
#     appropriate copyright notice and a notice that there is no warranty (or
#     else, saying that you provide a warranty) and that users may
#     redistribute the program under these conditions, and telling the user
#     how to view a copy of this License. (Exception: if the Program itself is
#     interactive but does not normally print such an announcement, your work
#     based on the Program is not required to print an announcement.)
# 
# These requirements apply to the modified work as a whole. If identifiable
# sections of that work are not derived from the Program, and can be
# reasonably considered independent and separate works in themselves, then
# this License, and its terms, do not apply to those sections when you
# distribute them as separate works. But when you distribute the same sections
# as part of a whole which is a work based on the Program, the distribution of
# the whole must be on the terms of this License, whose permissions for other
# licensees extend to the entire whole, and thus to each and every part
# regardless of who wrote it.
# 
# Thus, it is not the intent of this section to claim rights or contest your
# rights to work written entirely by you; rather, the intent is to exercise
# the right to control the distribution of derivative or collective works
# based on the Program.
# 
# In addition, mere aggregation of another work not based on the Program with
# the Program (or with a work based on the Program) on a volume of a storage
# or distribution medium does not bring the other work under the scope of this
# License.
# 
# 3. You may copy and distribute the Program (or a work based on it, under
# Section 2) in object code or executable form under the terms of Sections 1
# and 2 above provided that you also do one of the following:
# 
#     * a) Accompany it with the complete corresponding machine-readable
#     source code, which must be distributed under the terms of Sections 1 and
#     2 above on a medium customarily used for software interchange; or,
# 
#     * b) Accompany it with a written offer, valid for at least three years,
#     to give any third party, for a charge no more than your cost of
#     physically performing source distribution, a complete machine-readable
#     copy of the corresponding source code, to be distributed under the terms
#     of Sections 1 and 2 above on a medium customarily used for software
#     interchange; or,
# 
#     * c) Accompany it with the information you received as to the offer to
#     distribute corresponding source code. (This alternative is allowed only
#     for noncommercial distribution and only if you received the program in
#     object code or executable form with such an offer, in accord with
#     Subsection b above.)
# 
# The source code for a work means the preferred form of the work for making
# modifications to it. For an executable work, complete source code means all
# the source code for all modules it contains, plus any associated interface
# definition files, plus the scripts used to control compilation and
# installation of the executable. However, as a special exception, the source
# code distributed need not include anything that is normally distributed (in
# either source or binary form) with the major components (compiler, kernel,
# and so on) of the operating system on which the executable runs, unless that
# component itself accompanies the executable.
# 
# If distribution of executable or object code is made by offering access to
# copy from a designated place, then offering equivalent access to copy the
# source code from the same place counts as distribution of the source code,
# even though third parties are not compelled to copy the source along with
# the object code.
# 
# 4. You may not copy, modify, sublicense, or distribute the Program except as
# expressly provided under this License. Any attempt otherwise to copy,
# modify, sublicense or distribute the Program is void, and will automatically
# terminate your rights under this License. However, parties who have received
# copies, or rights, from you under this License will not have their licenses
# terminated so long as such parties remain in full compliance.
# 
# 5. You are not required to accept this License, since you have not signed
# it. However, nothing else grants you permission to modify or distribute the
# Program or its derivative works. These actions are prohibited by law if you
# do not accept this License. Therefore, by modifying or distributing the
# Program (or any work based on the Program), you indicate your acceptance of
# this License to do so, and all its terms and conditions for copying,
# distributing or modifying the Program or works based on it.
# 
# 6. Each time you redistribute the Program (or any work based on the
# Program), the recipient automatically receives a license from the original
# licensor to copy, distribute or modify the Program subject to these terms
# and conditions. You may not impose any further restrictions on the
# recipients' exercise of the rights granted herein. You are not responsible
# for enforcing compliance by third parties to this License.
# 
# 7. If, as a consequence of a court judgment or allegation of patent
# infringement or for any other reason (not limited to patent issues),
# conditions are imposed on you (whether by court order, agreement or
# otherwise) that contradict the conditions of this License, they do not
# excuse you from the conditions of this License. If you cannot distribute so
# as to satisfy simultaneously your obligations under this License and any
# other pertinent obligations, then as a consequence you may not distribute
# the Program at all. For example, if a patent license would not permit
# royalty-free redistribution of the Program by all those who receive copies
# directly or indirectly through you, then the only way you could satisfy both
# it and this License would be to refrain entirely from distribution of the
# Program.
# 
# If any portion of this section is held invalid or unenforceable under any
# particular circumstance, the balance of the section is intended to apply and
# the section as a whole is intended to apply in other circumstances.
# 
# It is not the purpose of this section to induce you to infringe any patents
# or other property right claims or to contest validity of any such claims;
# this section has the sole purpose of protecting the integrity of the free
# software distribution system, which is implemented by public license
# practices. Many people have made generous contributions to the wide range of
# software distributed through that system in reliance on consistent
# application of that system; it is up to the author/donor to decide if he or
# she is willing to distribute software through any other system and a
# licensee cannot impose that choice.
# 
# This section is intended to make thoroughly clear what is believed to be a
# consequence of the rest of this License.
# 
# 8. If the distribution and/or use of the Program is restricted in certain
# countries either by patents or by copyrighted interfaces, the original
# copyright holder who places the Program under this License may add an
# explicit geographical distribution limitation excluding those countries, so
# that distribution is permitted only in or among countries not thus excluded.
# In such case, this License incorporates the limitation as if written in the
# body of this License.
# 
# 9. The Free Software Foundation may publish revised and/or new versions of
# the General Public License from time to time. Such new versions will be
# similar in spirit to the present version, but may differ in detail to
# address new problems or concerns.
# 
# Each version is given a distinguishing version number. If the Program
# specifies a version number of this License which applies to it and "any
# later version", you have the option of following the terms and conditions
# either of that version or of any later version published by the Free
# Software Foundation. If the Program does not specify a version number of
# this License, you may choose any version ever published by the Free Software
# Foundation.
# 
# 10. If you wish to incorporate parts of the Program into other free programs
# whose distribution conditions are different, write to the author to ask for
# permission. For software which is copyrighted by the Free Software
# Foundation, write to the Free Software Foundation; we sometimes make
# exceptions for this. Our decision will be guided by the two goals of
# preserving the free status of all derivatives of our free software and of
# promoting the sharing and reuse of software generally.
# 
# NO WARRANTY
# 
# 11. BECAUSE THE PROGRAM IS LICENSED FREE OF CHARGE, THERE IS NO WARRANTY FOR
# THE PROGRAM, TO THE EXTENT PERMITTED BY APPLICABLE LAW. EXCEPT WHEN
# OTHERWISE STATED IN WRITING THE COPYRIGHT HOLDERS AND/OR OTHER PARTIES
# PROVIDE THE PROGRAM "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER EXPRESSED
# OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF
# MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE. THE ENTIRE RISK AS TO
# THE QUALITY AND PERFORMANCE OF THE PROGRAM IS WITH YOU. SHOULD THE PROGRAM
# PROVE DEFECTIVE, YOU ASSUME THE COST OF ALL NECESSARY SERVICING, REPAIR OR
# CORRECTION.
# 
# 12. IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING
# WILL ANY COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MAY MODIFY AND/OR
# REDISTRIBUTE THE PROGRAM AS PERMITTED ABOVE, BE LIABLE TO YOU FOR DAMAGES,
# INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL OR CONSEQUENTIAL DAMAGES ARISING
# OUT OF THE USE OR INABILITY TO USE THE PROGRAM (INCLUDING BUT NOT LIMITED TO
# LOSS OF DATA OR DATA BEING RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR
# THIRD PARTIES OR A FAILURE OF THE PROGRAM TO OPERATE WITH ANY OTHER
# PROGRAMS), EVEN IF SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE
# POSSIBILITY OF SUCH DAMAGES.
# 
# END OF TERMS AND CONDITIONS How to Apply These Terms to Your New Programs
# 
# If you develop a new program, and you want it to be of the greatest possible
# use to the public, the best way to achieve this is to make it free software
# which everyone can redistribute and change under these terms.
# 
# To do so, attach the following notices to the program. It is safest to
# attach them to the start of each source file to most effectively convey the
# exclusion of warranty; and each file should have at least the "copyright"
# line and a pointer to where the full notice is found.
# 
# one line to give the program's name and an idea of what it does.  Copyright
# (C) 19yy  name of author
# 
# This program is free software; you can redistribute it and/or modify it
# under the terms of the GNU General Public License as published by the Free
# Software Foundation; either version 2 of the License, or (at your option)
# any later version.
# 
# This program is distributed in the hope that it will be useful, but WITHOUT
# ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
# FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License for
# more details.
# 
# You should have received a copy of the GNU General Public License along with
# this program; if not, write to the Free Software Foundation, Inc., 59 Temple
# Place - Suite 330, Boston, MA  02111-1307, USA.
# 
# Also add information on how to contact you by electronic and paper mail.
# 
# If the program is interactive, make it output a short notice like this when
# it starts in an interactive mode:
# 
# Gnomovision version 69, Copyright (C) 19yy name of author Gnomovision comes
# with ABSOLUTELY NO WARRANTY; for details type `show w'.  This is free
# software, and you are welcome to redistribute it under certain conditions;
# type `show c' for details.
# 
# The hypothetical commands `show w' and `show c' should show the appropriate
# parts of the General Public License. Of course, the commands you use may be
# called something other than `show w' and `show c'; they could even be
# mouse-clicks or menu items--whatever suits your program.
# 
# You should also get your employer (if you work as a programmer) or your
# school, if any, to sign a "copyright disclaimer" for the program, if
# necessary. Here is a sample; alter the names:
# 
# Yoyodyne, Inc., hereby disclaims all copyright interest in the program
# `Gnomovision' (which makes passes at compilers) written by James Hacker.
# 
# signature of Ty Coon, 1 April 1989 Ty Coon, President of Vice
# 
# This General Public License does not permit incorporating your program into
# proprietary programs. If your program is a subroutine library, you may
# consider it more useful to permit linking proprietary applications with the
# library. If this is what you want to do, use the GNU Library General Public
# License instead of this License. 
# 
#

set -h
set -u

test_binary () {
	if [ ! -x ${1} ]; then
		echo "*** ERROR: Cannot find ${1}"
		exit 1
	fi
}

puttext=/usr/sadm/bin/puttext
test_binary ${puttext}
ckpath=/usr/bin/ckpath
test_binary ${ckpath}
errpath=/usr/sadm/bin/errpath
test_binary ${errpath}
ckyorn=/usr/bin/ckyorn
test_binary ${ckyorn}
ckstr=/usr/bin/ckstr
test_binary ${ckstr}
errstr=/usr/sadm/bin/errstr
test_binary ${errstr}
grep=/usr/bin/grep
test_binary ${grep}
awk=/usr/bin/awk
test_binary ${awk}
sed=/usr/bin/sed
test_binary ${sed}
tr=/usr/bin/tr
test_binary ${tr}
cut=/usr/bin/cut
test_binary ${cut}
cat=/usr/bin/cat
test_binary ${cat}
pkginfo=/usr/bin/pkginfo
test_binary ${pkginfo}
head=/usr/bin/head
test_binary ${head}
tail=/usr/bin/tail
test_binary ${tail}
mkdir=/usr/bin/mkdir
test_binary ${mkdir}
chmod=/usr/bin/chmod
test_binary ${chmod}
chown=/usr/bin/chown
test_binary ${chown}
cp=/usr/bin/cp
test_binary ${cp}
pwd=/usr/bin/pwd
test_binary ${pwd}
find=/usr/bin/find
test_binary ${find}
pkgmk=/usr/bin/pkgmk
test_binary ${pkgmk}
pkgtrans=/usr/bin/pkgtrans
test_binary ${pkgtrans}
pkgchk=/usr/sbin/pkgchk
test_binary ${pkgchk}
pkgproto=/usr/bin/pkgproto
test_binary ${pkgproto}
rm=/usr/bin/rm
test_binary ${rm}
mv=/usr/bin/mv
test_binary ${mv}
wc=/usr/bin/wc
test_binary ${wc}

${cat} << EOF

CDE DtLogin Creator

This script will ask you a few questions about what kind of window manager you
would like to add to the CDE login screen, and then it will generate a Solaris
package datastream file for you that contains the new setup.

Before we begin, you will need the following:

1) A name for your new CDE login session. (Ex: FVWM)
2) The complete path to your window manager program. (Ex: /usr/local/bin/fvwm2)
3) Two 237x237 graphics files, one in XPM format, the other in XBM format.
4) If you intend to run the SSH agent along with your window manager, then you
   will need to know the full pathname to the ssh-agent program.  (Ex:
   /usr/bin/ssh-agent)

You should use your favorite graphics editor (such as the Gimp) to create a
pair of files to use as the logo for your new login.  (Your logos can look
like whatever you want, but you can also take a look at the files in
/usr/dt/appconfig/icons/C/ for examples.)

EOF

echo "At any prompt, you may enter '?' for help, or 'q' to quit."

default="y"
error="Please answer 'y' for yes, 'n' for no, 'q' for quit, or '?' for help 
	(y/n/q/?)."
help="If you can meet the above requirements then answer yes.  That is, if you
have chosen a name for your login session, you know the complete path to your
window manager (and optionally to your ssh-agent), and you have two, 237x237
graphics files, one in XPM format and the other in XBM format, then answer
yes.  Otherwise answer no to exit the script and re-run it later when you are
ready."
prompt="Are you ready to continue? (y/n/q/?) [${default}]:"
answer=`${ckyorn} -d "${default}" -e "${error}" -h "${help}" -p "${prompt}" \
| ${tr} '[A-Z]' '[a-z]' \
| ${cut} -b1 \
`
if [ "${answer}" = "q" ]; then
	${puttext} "Okay, see you later."
	exit 0
fi

if [ "${answer}" = "n" ]; then
	${puttext} ""
	${puttext} "Okay, come back later when you are ready."
	${puttext} ""
	exit 0
fi

get_name () {
	_done=0
	while [ ${_done} -ne 1 ]; do
		error="Please enter a uniqe name for this window manager
			login, or 'q' to quit, or '?' for help.  Please use
			only a-z, A-Z, 0-9, hyphen, period, and underscore
			characters."
		help="CDE's dtlgoin manager displays a name in the pull-down
			menu under Options-->Session to describe each login.
			This name should be unique from any other names
			listed.  For instance, you might use \"FVWM\" to
			describe the session that runs fvwm2.  But if your
			system also has version 1.x of fvwm installed as well,
			then you cannot call both logins \"FVWM\", you will
			have to come up with a different name for the new
			login (like \"FVWM2\")."
		prompt="What name would you like to use for this login?"
		altDtName=`${ckstr} -h "${help}" -e "${error}" -p "${prompt}"`
		if [ "${altDtName}" = "q" ]; then
			${puttext} "Okay, see you later."
			exit 0
		fi

		#
		# Check the format of the string returned
		#
		echo "${altDtName}" \
		| ${grep} "^[a-zA-Z0-9_\.-]\{1,\}$" \
		> /dev/null 2>&1
		if [ $? -ne 0 ]; then
			${errstr} -e "${error}"
			continue
		fi

		#
		# Assume that we're done and change that status if any
		# problems arrise below.
		#
		_done=1

		#
		# Check to see if this setup will overshadow one in /usr/dt.
		# If it will, warn the user and ask if they would like to
		# continue.
		#
		for file in /usr/dt/config/C/Xresources.d/* ; do
			${grep} "^Dtlogin\*altDtName:  *${altDtName}$" \
				${file} > /dev/null 2>&1
			if [ $? -eq 0 ]; then
				default="n"
				error="Plase answer 'y' for yes, 'n' for no,
					'q' for quit, or '?' for help
					(y/n/q/?)."
				help="The session name \"${altDtName}\" is 
					already listed in the file ${file}.
					If this is intentional, the you may
					continue.  But if not, then installing
					this login setup will overshadow
					(replace) the other."
				prompt="This session name overshadows another
					listed in ${file}, continue? (y/n/q/?)
					[${default}]:"
				answer=`${ckyorn} -d "${default}" \
					-e "${error}" -h "${help}" \
					-p "${prompt}" \
				| ${tr} '[A-Z]' '[a-z]' \
				| ${cut} -b1 \
				`
				if [ "${answer}" = "q" ]; then
					${puttext} "Okay, see you later"
					exit 0
				fi
				if [ "${answer}" = "n" ]; then
					${puttext} "Okay, let's try this again
						then."
					_done=0
					break
				fi
			fi
		done
		if [ ${_done} -eq 0 ]; then
			continue
		fi

		for file in /etc/dt/config/C/Xresources.d/* ; do
			${grep} "^Dtlogin\*altDtName:[ 	]*${altDtName}$" \
				${file} > /dev/null 2>&1
			if [ $? -eq 0 ]; then
				default="n"
				error="Plase answer 'y' for yes, 'n' for no,
					'q' for quit, or '?' for help
					(y/n/q/?)."
				help="The session name \"${altDtName}\" is 
					already listed in the file ${file}.
					If this is intentional, the you may
					continue.  But if not, then installing
					this login setup will conflict with
					the other."
				prompt="This session name conflicts with
					another listed in ${file}, continue?
					(y/n/q/?) [${default}]:"
				answer=`${ckyorn} -d "${default}" \
					-e "${error}" -h "${help}" \
					-p "${prompt}" \
				| ${tr} '[A-Z]' '[a-z]' \
				| ${cut} -b1 \
				`
				if [ "${answer}" = "q" ]; then
					${puttext} "Okay, see you later"
					exit 0
				fi
				if [ "${answer}" = "n" ]; then
					${puttext} "Okay, let's try this again
						then."
					_done=0
					break
				fi
			fi
		done
		if [ ${_done} -eq 0 ]; then
			continue
		fi

		#
		# Check for the existence of other entries in
		# /etc/dt/config/Xsession.* files that conflict with this one.
		# If any conflicts arrise, report a warning and ask the user
		# if they want to continue.
		#
		echo ""
		echo "Generating filenames..."

		altDtLogo="${altDtName}-logo"
		echo "- ${logoDir}/${altDtLogo}.pm"
		echo "- ${logoDir}/${altDtLogo}.bm"
		Xresources="/etc/dt/config/C/Xresources.d"
		Xresources="${Xresources}/Xresources.${altDtName}"
		echo "- ${Xresources}"
		altDtStart="/etc/dt/config/Xsession.${altDtName}-phase1"
		echo "- ${altDtStart}"
		phase2="/etc/dt/config/Xsession.${altDtName}-phase2"
		echo "- ${phase2}"
		Xinitrc="/etc/dt/config/Xinitrc.${altDtName}"
		echo "- ${Xinitrc}"

		echo ""
		echo "Generating package name..."

		pkg=`echo "Dt${altDtName}" \
			| ${sed} \
				-e 's,_,,g' \
				-e 's,\.,,g' \
				-e 's,-,,g' \
			| ${cut} -b1-9 \
			`
		echo "- Package Name: ${pkg}"
		echo ""
		${puttext} "If you agree with the given package name, simply
			press return, or enter your own package name below."

		_done2=0
		while [ ${_done2} -ne 1 ]; do
			default="${pkg}"
			error="Please enter a unique package name of nine
				characters or less, consisting of the
				characters A-Z, a-z, 0-9, and '-'.  Enter '?'
				for help or 'q' to quit."
			help="The default package name for this CDE login
				setup is ${pkg}.  If you are dissatisfied with
				this name, please enter a new name, consisting
				of nine or less characters, and made up of the
				characters A-Z, a-z, 0-9, and '-'.  Enter '?'
				for help or 'q' to quit."
			prompt="Package name for ${altDtName} CDE login? 
				[${default}]:"
			answer=`${ckstr} -d "${default}" -h "${help}" \
				-e "${error}" -p "${prompt}"`
			if [ "${answer}" = "q" ]; then
				${puttext} "Okay, see you later."
				exit 0
			fi

			_done2=1

			#
			# Check the format of the string returned
			#
			numChars=`echo "${answer}" | ${wc} -c`
			if [ ${numChars} -gt 9 ]; then
				err2="The string \"${answer}\" contains more"
				err2="${err2} than nine characters."
				${errstr} -e "${err2}  ${error}"
				_done2=0
				continue
			fi
		
			echo "${answer}" \
			| ${grep} "^[a-zA-Z0-9-]\{1,\}$" \
			> /dev/null 2>&1
			if [ $? -ne 0 ]; then
				err2="The string \"${answer}\" contains"
				err2="${err2} invalid characters."
				${errstr} -e "${err2}  ${error}"
				_done2=0
				continue
			fi
		done
		pkg="${answer}"

		#
		# Create from this string the filenames that we will use in
		# our setup.  Check our filenames against anything currently
		# in /etc/dt.  If any conflicts arrise, report a warning and
		# ask the user if they want to continue.
		#
		echo ""
		echo "Checking filenames..."

		if [ -f /etc/dt/appconfig/icons/C/${altDtLogo}.pm ]; then
			default="n"
			error="Please answer 'y' for yes, 'n' for no, 'q' for
				quit, or '?' for help (y/n/q/?)."
			help="This file already exists.  If a new package is
				created and installed on this host, it will
				overwrite the old file.  If this is
				intentional then you may continue, but if it
				is unintentional then this could screw things
				up for another login setup."
			prompt="${logoDir}/${altDtLogo}.pm already exists on 
				this system, continue? (y/n/q/?)
				[${default}]:"
			answer=`${ckyorn} -d "${default}" -e "${error}" \
				-h "${help}" -p "${prompt}" \
			| ${tr} '[A-Z]' '[a-z]' \
			| ${cut} -b1 \
			`
			if [ "${answer}" = "q" ]; then
				${puttext} "Okay, see you later."
				exit 0
			fi
			if [ "${answer}" = "n" ]; then
				_done=0
				${puttext} "Okay, let's try again then."
				continue
			fi
		fi
		
		if [ -f /etc/dt/appconfig/icons/C/${altDtLogo}.bm ]; then
			default="n"
			error="Please answer 'y' for yes, 'n' for no, 'q' for
				quit, or '?' for help (y/n/q/?)."
			help="This file already exists.  If a new package is
				created and installed on this host, it will
				overwrite the old file.  If this is
				intentional then you may continue, but if it
				is unintentional then this could screw things
				up for another login setup."
			prompt="${logoDir}/${altDtLogo}.bm already exists on
				this system, continue? (y/n/q/?)
				[${default}]:"
			answer=`${ckyorn} -d "${default}" -e "${error}" \
				-h "${help}" -p "${prompt}" \
			| ${tr} '[A-Z]' '[a-z]' \
			| ${cut} -b1 \
			`
			if [ "${answer}" = "q" ]; then
				${puttext} "Okay, see you later."
				exit 0
			fi
			if [ "${answer}" = "n" ]; then
				_done=0
				${puttext} "Okay, let's try this again then."
				continue
			fi
		fi

		if [ -f ${Xresources} ]; then
			default="n"
			error="Please answer 'y' for yes, 'n' for no, 'q' for
				quit, or '?' for help (y/n/q/?)."
			help="This file already exists.  If a new package is
				created and installed on this host, it will
				overwrite the old file.  If this is
				intentional then you may continue, but if it
				is unintentional then this could screw things
				up for another login setup."
			prompt="${Xresources} already exists on this system,
				continue? (y/n/q/?) [${default}]:"
			answer=`${ckyorn} -d "${default}" -e "${error}" \
				-h "${help}" -p "${prompt}" \
			| ${tr} '[A-Z]' '[a-z]' \
			| ${cut} -b1 \
			`
			if [ "${answer}" = "q" ]; then
				${puttext} "Okay, see you later."
				exit 0
			fi
			if [ "${answer}" = "n" ]; then
				_done=0
				${puttext} "Okay, let's try this again then."
				continue
			fi
		fi
		_check_Xresources="/usr/dt/config/C/Xresources.d"
		_check_Xresources="${_check_Xresources}/Xresources.${altDtName}"
		if [ -f "${_check_Xresources}" ]; then
			default="y"
			error="Please answer 'y' for yes, 'n' for no, 'q' for 
				quit, or '?' for help (y/n/q/?)."
			help="This file already exists in /usr/dt/.  If a new
				package is created and installed on this host,
				it will overshadow (replace) this one in the
				dtlogin session manager's menu.  If this is
				instentional then you may continue, but if it
				is not then this could screw things up for
				another login setup."
			prompt="${_check_Xresources} was found on this system, 
				continue? (y/n/q/?) [${default}]:"
			answer=`${ckyorn} -d "${default}" -e "${error}" \
				-h "${help}" -p "${prompt}" \
			| ${tr} '[A-Z]' '[a-z]' \
			| ${cut} -b1 \
			`
			if [ "${answer}" = "q" ]; then
				${puttext} "Okay, see you later."
				exit 0
			fi
			if [ "${answer}" = "n" ]; then
				_done=0
				${puttext} "Okay, let's try this again then."
				continue
			fi
		fi

		if [ -f ${altDtStart} ]; then
			default="n"
			error="Please answer 'y' for yes, 'n' for no, 'q' for
				quit, or '?' for help (y/n/q/?)."
			help="This file already exists.  If a new package is
				created and installed on this host, it will
				overwrite the old file.  If this is
				intentional then you may continue, but if it
				is unintentional then this could screw things
				up for another login setup."
			prompt="${altDtStart} already exists on this system,
				continue? (y/n/q/?) [${default}]:"
			answer=`${ckyorn} -d "${default}" -e "${error}" \
				-h "${help}" -p "${prompt}" \
			| ${tr} '[A-Z]' '[a-z]' \
			| ${cut} -b1 \
			`
			if [ "${answer}" = "q" ]; then
				${puttext} "Okay, see you later."
				exit 0
			fi
			if [ "${answer}" = "n" ]; then
				_done=0
				${puttext} "Okay, let's try this again then."
				continue
			fi
		fi

		if [ -f ${phase2} ]; then
			default="n"
			error="Please answer 'y' for yes, 'n' for no, 'q' for
				quit, or '?' for help (y/n/q/?)."
			help="This file already exists.  If a new package is
				created and installed on this host, it will
				overwrite the old file.  If this is
				intentional then you may continue, but if it
				is unintentional then this could screw things
				up for another login setup."
			prompt="${phase2} already exists on this system,
				continue? (y/n/q/?) [${default}]:"
			answer=`${ckyorn} -d "${default}" -e "${error}" \
				-h "${help}" -p "${prompt}" \
			| ${tr} '[A-Z]' '[a-z]' \
			| ${cut} -b1 \
			`
			if [ "${answer}" = "q" ]; then
				${puttext} "Okay, see you later."
				exit 0
			fi
			if [ "${answer}" = "n" ]; then
				_done=0
				${puttext} "Okay, let's try this again then."
				continue
			fi
		fi

		if [ -f ${Xinitrc} ]; then
			default="n"
			error="Please answer 'y' for yes, 'n' for no, 'q' for
				quit, or '?' for help (y/n/q/?)."
			help="This file already exists.  If a new package is
				created and installed on this host, it will
				overwrite the old file.  If this is
				intentional then you may continue, but if it
				is unintentional then this could screw things
				up for another login setup."
			prompt="${Xinitrc} already exists on this system,
				continue? (y/n/q/?) [${default}]:"
			answer=`${ckyorn} -d "${default}" -e "${error}" \
				-h "${help}" -p "${prompt}" \
			| ${tr} '[A-Z]' '[a-z]' \
			| ${cut} -b1 \
			`
			if [ "${answer}" = "q" ]; then
				${puttext} "Okay, see you later."
				exit 0
			fi
			if [ "${answer}" = "n" ]; then
				_done=0
				${puttext} "Okay, let's try this again then."
				continue
			fi
		fi

		echo ""
		echo "Checking package name..."

		${pkginfo} -q ${pkg}
		if [ $? -eq 0 ]; then
			default="n"
			error="Please answer 'y' for yes, 'n' for no, 'q' for
				quit, or '?' for help (y/n/q/?)."
			help="This package name already exists on this system.
				If a new package is created and installed on
				this host, it will overwrite the old one.  If
				this is intentional then you may continue, but
				if it is unintentional then this could screw
				something up on the system."
			prompt="The package ${pkg} already exists on this
				system, continue? (y/n/q/?) [${default}]:"
			answer=`${ckyorn} -d "${default}" -e "${error}" \
				-h "${help}" -p "${prompt}" \
			| ${tr} '[A-Z]' '[a-z]' \
			| ${cut} -b1 \
			`
			if [ "${answer}" = "q" ]; then
				${puttext} "Okay, see you later."
				exit 0
			fi
			if [ "${answer}" = "n" ]; then
				_done=0
				${puttext} "Okay, let's try again then."
				continue
			fi
			if [ "${answer}" = "y" ]; then
				${puttext} "Okay, but I hope you know what
					you're doing!"
			fi
		fi

		echo ""
	done
}

get_xpm () {
	_done=0
	while [ ${_done} -ne 1 ]; do
		error="Please enter a valid pathname to the XPM graphic logo
			file, 'q' to quit, or '?' for help."
		help="For color monitors, CDE's dtlogin manager displays an
			XPM-format graphic image as the logo for your new
			login in the box to the right of the login prompt once
			a session is selected from the Options-->Session
			pull-down menu.  To create a new login session, a new,
			237x237, XPM-format graphics file must be provided to
			insert into the package that we create, to represent
			your new login session."
		prompt="What is the full path to the XPM graphic logo file?"
		xpmFile=`${ckpath} -e "${error}" -h "${help}" -p "${prompt}"`
		if [ "${xpmFile}" = "q" ]; then
			${puttext} "Okay, see you later."
			exit 0
		fi
	
		#
		# Assume that we're done and change that status if any
		# problems arrise below.
		#
		_done=1
	
		#
		# Check to see if this is a valid file.  If not, don't ask
		# questions, just print an error and make the user enter it
		# again.
		#
		if [ ! -f ${xpmFile} ]; then
			${errpath} -e "Error finding file ${xpmFile}"
			_done=0
			${puttext} "Let's try that one again..."
			continue
		fi
	
		#
		# Check to see if it's really an XPM file.  If not, print a
		# warning and ask the user if they want to continue.
		#
		${head} -1 ${xpmFile} | ${grep} '^\/\* XPM \*\/$' \
		> /dev/null 2>&1
		if [ $? -ne 0 ]; then
			default="n"
			error="Please answer 'y' for yes, 'n' for no, 'q' for 
				quit, or '?' for help (y/n/q/?)."
			help="This file does not appear to be a valid XPM
				graphics file (i.e. the string '/* XPM */'
				does not appear as the first line in the
				file).  You may continue on and use this file
				as your XPM graphics file if you like, but if
				it is not really an XPM graphics file, or if it
				is corrupted, then this may cause problems
				for your CDE login setup."
			prompt="${xpmFile} does not appear to be a valid XPM
				graphics file, continue? (y/n/q/?)
				[${default}]:"
			answer=`${ckyorn} -d "${default}" -e "${error}" \
				-h "${help}" -p "${prompt}" \
			| ${tr} '[A-Z]' '[a-z]' \
			| ${cut} -b1 \
			`
			if [ "${answer}" = "q" ]; then
				${puttext} "Okay, see you later."
				exit 0
			fi
			if [ "${answer}" = "n" ]; then
				_done=0
				${puttext} "Okay, let's try again then."
				continue
			fi
			if [ "${answer}" = "y" ]; then
				${puttext} "Okay, but I hope you know what
					you're doing!"
				continue
			fi
		fi
	
		#
		# If it's really an XPM file, check to see if it has the
		# correct dimensions.  If not, print a warning and ask the
		# user if they want to continue.
		#
		_width=`${cat} ${xpmFile} \
			| ${grep} '^"[0-9]* [0-9]* [0-9]* [0-9]*",$' \
			| ${head} -1 \
			| ${awk} '{print $1}' \
			| ${sed} 's,",,g' \
			`
		_height=`${cat} ${xpmFile} \
			| ${grep} '^"[0-9]* [0-9]* [0-9]* [0-9]*",$' \
			| ${head} -1 \
			| ${awk} '{print $2}' \
			| ${sed} 's,",,g' \
			`
		if [ "${_width}" != "237" -o "${_height}" != "237" ]; then
			default="n"
			error="Please answer 'y' for yes, 'n' for no, 'q' for
				quit, or '?' for help (y/n/q/?)."
			help="This file does not appear to be 237x237 in size.
				You may continue to use it if you like, but
				files larger than 237 in either direction may
				be truncated when displayed."
			prompt="${xpmFile} does not appear to be an XPM file
				that is 237x237 in size, continue? (y/n/q/?)
				[${default}]:"
			answer=`${ckyorn} -d "${default}" -e "${error}" \
				-h "${help}" -p "${prompt}" \
			| ${tr} '[A-Z]' '[a-z]' \
			| ${cut} -b1 \
			`
			if [ "${answer}" = "q" ]; then
				${puttext} "Okay, see you later."
				exit 0
			fi
			if [ "${answer}" = "n" ]; then
				_done=0
				${puttext} "Okay, let's try that again then."
				continue
			fi
		fi
	done
}

get_xbm () {
	_done=0
	while [ ${_done} -ne 1 ]; do
		error="Please enter a valid pathname to the XBM graphic logo
			file, 'q' to quit, or '?' for help."
		help="For monochrome monitors, CDE's dtlogin manager displays
			an XBM-format graphic image as the logo for your new
			login in the box to the right of the login prompt once
			a session is selected from the Options-->Session
			pull-down menu.  To create a new login session, a new,
			237x237, XBM-format graphics file must be provided to
			insert into the package that we create, to represent
			your new login session."
		prompt="What is the full path to the XBM graphic logo file?"
		xbmFile=`${ckpath} -e "${error}" -h "${help}" -p "${prompt}"`
		if [ "${xbmFile}" = "q" ]; then
			${puttext} "Okay, see you later."
			exit 0
		fi
	
		#
		# Assume that we're done and change that status if any
		# problems arrise.
		#
		_done=1
	
		#
		# Check to see if this is a valid file.  If not, don't ask
		# questions, just print an error and make the user enter it
		# again.
		#
		if [ ! -f ${xbmFile} ]; then
			${errpath} -e "Error finding file ${xbmFile}"
			_done=0
			${puttext} "Let's try that one again..."
			continue
		fi
	
		#
		# Check to see if it's really an XBM file.  If not, print a
		# warning and ask the user if they want to continue.
		#
		${head} -3 ${xbmFile} \
		| ${tail} -1 \
		| ${grep} '^static char .*_bits\[\] = {$' > /dev/null 2>&1
		if [ $? -ne 0 ]; then
			default="n"
			error="Please answer 'y' for yes, 'n' for no, 'q' for
				quit, or '?' for help (y/n/q/?)."
			help="This file does not appear to be a valid XBM
				graphics file (i.e. the string 'static char
				..._bits[] = {' does not appear as the third
				line in the file).  You may continue on and
				use this file as your XBM graphics file if you
				like, but if it is not really an XBM graphics
				file, or if it is corrupted, then this may
				cause problems for your CDE login setup."
			prompt="${xbmFile} does not appear to be a valid XBM
				graphics file, continue? (y/n/q/?)
				[${default}]:"
			answer=`${ckyorn} -d "${default}" -e "${error}" \
				-h "${help}" -p "${prompt}" \
			| ${tr} '[A-Z]' '[a-z]' \
			| ${cut} -b1 \
			`
			if [ "${answer}" = "q" ]; then
				${puttext} "Okay, see you later."
				exit 0
			fi
			if [ "${answer}" = "n" ]; then
				_done=0
				${puttext} "Okay, let's try that again then."
				continue
			fi
			if [ "${answer}" = "y" ]; then
				${puttext} "Okay, but I hope you know what
					you're doing!"
				continue
			fi
		fi
		
		#
		# If it's really an XBM file, check to see if it has the
		# correct dimensions.  If not, print a warning and ask the
		# user if they want to continue.
		#
		_width=`${head} -1 ${xbmFile} \
			| ${grep} '^#define .*_width [0-9]*$' \
			| ${awk} '{print $3}' \
			`
		_height=`${head} -2 ${xbmFile} \
			| ${tail} -1 \
			| ${grep} '^#define .*_height [0-9]*$' \
			| ${awk} '{print $3}' \
			`
		if [ "${_width}" != "237" -o "${_height}" != "237" ]; then
			default="n"
			error="Please answer 'y' for yes, 'n' for no, 'q' for
				quit, or '?' for help (y/n/q/?)."
			help="This file does not appear to be 237x237 in size.
				You may continue to use it if you like, but
				files larger than 237 in either direction may
				be truncated when displayed."
			prompt="${xbmFile} does not appear to be an XBM file
				that is 237x237 in size, continue? (y/n/q/?)
				[${default}]:"
			answer=`${ckyorn} -d "${default}" -e "${error}" \
				-h "${help}" -p "${prompt}" \
			| ${tr} '[A-Z]' '[a-z]' \
			| ${cut} -b1 \
			`
			if [ "${answer}" = "q" ]; then
				${puttext} "Okay, see you later."
				exit 0
			fi
			if [ "${answer}" = "n" ]; then
				_done=0
				${puttext} "Okay, let's try that again then."
				continue
			fi
		fi
	done
}

get_wm () {
	_done=0
	while [ ${_done} -ne 1 ]; do
		error="Please enter a valid pathname to the window manager
			binary file, 'q' to quit, or '?' for help."
		help="CDE's dtlogin manager (eventually) shells out to run
			another program as the window manager for this
			session.  This should be a valid pathname to a real
			window manager program that is available on the
			system."
		prompt="What is the full path to the window manager program?"
		altDtKey=`${ckpath} -a -e "${error}" -h "${help}" \
			-p "${prompt}"`
		if [ "${altDtKey}" = "q" ]; then
			${puttext} "Okay, see you later."
			exit 0
		fi
	
		#
		# Assume that we're done and change if problems arrise.
		#
		_done=1
	
		#
		# Check to see if this is a valid file.  If not, print a
		# warning and ask the user if they want to continue.
		#
		if [ ! -f ${altDtKey} ]; then
			default="n"
			error="Please enter 'y' for yes, 'n' for no, 'q' for 
				quit, and '?' for help (y/n/q/?)."
			help="The file ${altDtKey} could not be found on the
				system.  This file is what dtlogin will
				attempt to execute as the window manager
				program.  If it doesn't exist at the time that
				this CDE login package is installed, then this
				login setup will not appear in dtlogin's list
				of alternative sessions.  If this is
				intentional then you may continue, but if not
				then answer no and check your pathname to the
				window manager program."
			prompt="${altDtKey} could not be found, continue?
				(y/n/q/?) [${default}]:"
			answer=`${ckyorn} -d "${default}" -e "${error}" \
				-h "${help}" -p "${prompt}" \
			| ${tr} '[A-Z]' '[a-z]' \
			| ${cut} -b1 \
			`
			if [ "${answer}" = "q" ]; then
				${puttext} "Okay, see you later."
				exit 0
			fi
			if [ "${answer}" = "n" ]; then
				_done=0
				${puttext} "Okay, let's try that again then."
				continue
			fi
			if [ "${answer}" = "y" ]; then
				${puttext} "Okay, but I hope you know what
					you're doing!"
				continue
			fi
		fi
	
		#
		# If it is a valid file, check to see that it is executable.
		# If not, print a warning and ask the user if they want to
		# continue.
		#
		if [ ! -x ${altDtKey} ]; then
			default="n"
			error="Please enter 'y' for yes, 'n' for no, 'q' for 
				quit, and '?' for help (y/n/q/?)."
			help="The file ${altDtKey} exists, but it's
				permissions are set such that we are not
				allowed to execute it as a program.  This file
				is what dtlogin will attempt to execute as the
				window manager program.  If it doesn't exist
				at the time that this CDE login package is
				installed, then this login setup will not
				appear in dtlogin's list of alternative
				sessions.  If this is intentional then you may
				continue, but if not then answer no and check
				your pathname to the window manager program."
			prompt="${altDtKey} is not executable, continue?
				(y/n/q/?) [${default}]:"
			answer=`${ckyorn} -d "${default}" -e "${error}" \
				-h "${help}" -p "${prompt}" \
			| ${tr} '[A-Z]' '[a-z]' \
			| ${cut} -b1 \
			`
			if [ "${answer}" = "q" ]; then
				${puttext} "Okay, see you later."
				exit 0
			fi
			if [ "${answer}" = "n" ]; then
				_done=0
				${puttext} "Okay, let's try that again then."
				continue
			fi
			if [ "${answer}" = "y" ]; then
				${puttext} "Okay, but I hope you know what
					you're doing!"
				continue
			fi
		fi
	done
}

get_ssh () {
	default="y"
	error="Please answer 'y' for yes, 'n' for no, 'q' to quit, or '?' for
		help (y/n/q/?)."
	help="If you use SSH for secure logins to other computers, and you
		would like to have your new CDE login session run the
		ssh-agent inline with the window manager, answer yes and you
		will be prompted for the path to the ssh-agent program.  If
		not, or if you don't know, answer no and SSH support will be
		left out of your new login session."
	prompt="Would you like to run the SSH agent inline with this window
		manager?  (y/n/q/?) [${default}]:"
	useSSH=`${ckyorn} -d "${default}" -e "${error}" -h "${help}" \
		-p "${prompt}" \
	| ${tr} '[A-Z]' '[a-z]' \
	| ${cut} -b1 \
	`
	if [ "${useSSH}" = "q" ]; then
		${puttext} "Okay, see you later."
		exit 0
	fi

	_done=0
	if [ "${useSSH}" = "n" ]; then
		sshAgent="n/a"
		_done=1
	fi
	while [ ${_done} -ne 1 ]; do
		error="Please enter a valid pathname to the ssh-agent program,
			'q' to quit, or '?' for help."
		help="If you want to use the SSH agent along with your window
			manager, enter the full pathname to the ssh-agent
			program.  Otherwise, enter 'q' to quit the script."
		prompt="What is the full path to the ssh-agent program?"
		sshAgent=`${ckpath} -a -e "${error}" -h "${help}" \
			-p "${prompt}"`
		if [ "${sshAgent}" = "q" ]; then
			${puttext} "Okay, see you later."
			exit 0
		fi
	
		#
		# Assume that we're done and change if any problems arrise.
		#
		_done=1
	
		#
		# Check to see if this is a valid file.  If not, print a
		# warning and ask the user if they want to continue.
		#
		if [ ! -f ${sshAgent} ]; then
			default="n"
			error="Please enter 'y' for yes, 'n' for no, 'q' for 
				quit, and '?' for help (y/n/q/?)."
			help="The file ${sshAgent} could not be found on the
				system.  This file is what dtlogin will
				attempt to execute as the SSH agent for secure
				X11 connections to the window manager.
				If it doesn't exist at the time that
				this CDE login package is installed, then the
				window manager will simply be run withouth it.
				Although you may be able to log in and use
				this setup, any attempts to add SSH
				authentication will result in an error."
			prompt="${sshAgent} could not be found, continue?
				(y/n/q/?) [${default}]:"
			answer=`${ckyorn} -d "${default}" -e "${error}" \
				-h "${help}" -p "${prompt}" \
			| ${tr} '[A-Z]' '[a-z]' \
			| ${cut} -b1 \
			`
			if [ "${answer}" = "q" ]; then
				${puttext} "Okay, see you later."
				exit 0
			fi
			if [ "${answer}" = "n" ]; then
				_done=0
				${puttext} "Okay, let's try that again then."
				continue
			fi
			if [ "${answer}" = "y" ]; then
				${puttext} "Okay, but I hope you know what
					you're doing!"
				continue
			fi
		fi

		#
		# If it is a valid file, check to see that it is executable.
		# If not, print a warning and ask the user if they want to
		# continue.
		#
		if [ ! -x ${sshAgent} ]; then
			default="n"
			error="Please enter 'y' for yes, 'n' for no, 'q' for 
				quit, and '?' for help (y/n/q/?)."
			help="The file ${sshAgent} exists, but it's
				permissions are set such that we are not
				allowed to execute it as a program.  This file
				is what dtlogin will attempt to execute as the
				SSH agent for secure connections to the window
				manager.  If it doesn't exist at the time that
				this CDE login package is installed, then the
				window manager will simply be run without it.
				Although you will still be able to log in
				under this setup, any attempts to add SSH
				authentication will result in an error."
			prompt="${sshAgent} is not executable, continue?
				(y/n/q/?) [${default}]:"
			answer=`${ckyorn} -d "${default}" -e "${error}" \
				-h "${help}" -p "${prompt}" \
			| ${tr} '[A-Z]' '[a-z]' \
			| ${cut} -b1 \
			`
			if [ "${answer}" = "q" ]; then
				${puttext} "Okay, see you later."
				exit 0
			fi
			if [ "${answer}" = "n" ]; then
				_done=0
				${puttext} "Okay, let's try that again then."
				continue
			fi
			if [ "${answer}" = "y" ]; then
				${puttext} "Okay, but I hope you know what
					you're doing!"
				continue
			fi
		fi
	done
}

sshAgent="n/a"
logoDir=/etc/dt/appconfig/icons/C
_request_loop_done=0
while [ ${_request_loop_done} -ne 1 ]; do
	get_name
	get_xpm
	get_xbm
	get_wm
	get_ssh

	echo ""
	echo ""
	echo ""
	echo "Okay, here's what I have for your new CDE login:"
	echo ""
	echo "Session name: ${altDtName}"
	echo "XPM graphic logo: ${xpmFile}"
	echo "XBM graphic logo: ${xbmFile}"
	echo "Window manager: ${altDtKey}"
	echo "Use SSH's ssh-agent along with the window manager: ${useSSH}"
	echo "ssh-agent: ${sshAgent}"
	echo ""
	echo ""
	echo ""

	default="y"
	error="Please answer 'y' for yes, 'n' for no, 'q' to quit, or '?' for
		help (y/n/q/?)."
	help="If all the above information is correct, answer yes and a CDE
		dtlogin setup will be generated for you in the form of a
		Solaris package.  If not, answer no and the script will
		terminate."
	prompt="Is the above information correct? (y/n/?) [${default}]:"
	answer=`${ckyorn} -d "${default}" -e "${error}" -h "${help}" \
		-p "${prompt}" \
	| ${tr} '[A-Z]' '[a-z]' \
	| ${cut} -b1 \
	`
	if [ "${answer}" = "q" ]; then
		${puttext} "Okay, see you later."
		exit 0
	fi
	if [ "${answer}" = "y" ]; then
		_request_loop_done=1
	fi
done

set_permissions () {
	${chown} ${2} ${1} > /dev/null 2>&1
	if [ $? -ne 0 ]; then
		echo "*** ERROR: Could not chown ${1} to ${2}"
		exit 1
	fi
	${chmod} ${3} ${1} > /dev/null 2>&1
	if [ $? -ne 0 ]; then
		echo "*** ERROR: Could not chmod ${1} to ${3}"
		exit 1
	fi
}

create_directory () {
	${puttext} -- "- Making ${1}"
	${mkdir} ${1} > /dev/null 2>&1
	if [ $? -ne 0 ]; then
		echo "*** ERROR: Could not create directory: ${1}"
		exit 1
	fi
	set_permissions ${1} ${2} ${3}
}

copy_file () {
	echo "- Copying ${1}"
	echo "  to ${2}"
	${cp} ${1} ${2} > /dev/null 2>&1
	if [ $? -ne 0 ]; then
		echo "*** ERROR: Could not copy file ${1} to ${2}"
		exit 1
	fi
	set_permissions ${2} ${3} ${4}
}

echo ""
echo ""
echo ""
echo "Creating package..."
echo "- Creating package in /tmp"
if [ -d /tmp/${pkg} ]; then
	echo "- Deleting old directory: /tmp/${pkg}"
	${rm} -fr /tmp/${pkg}
fi

echo "- Making /tmp/${pkg}"
${mkdir} /tmp/${pkg} > /dev/null 2>&1
if [ $? -ne 0 ]; then
	echo "*** ERROR: Could not create directory: /tmp/${pkg}"
	exit 1
fi

create_directory /tmp/${pkg}/etc root:sys 0755
create_directory /tmp/${pkg}/etc/dt root:root 0755
create_directory /tmp/${pkg}/etc/dt/appconfig root:root 0755
create_directory /tmp/${pkg}/etc/dt/appconfig/icons bin:bin 0755
create_directory /tmp/${pkg}/etc/dt/appconfig/icons/C bin:bin 0755
create_directory /tmp/${pkg}/etc/dt/config root:bin 0755
create_directory /tmp/${pkg}/etc/dt/config/C root:bin 0755
create_directory /tmp/${pkg}/etc/dt/config/C/Xresources.d root:bin 0755

copy_file ${xpmFile} /tmp/${pkg}/etc/dt/appconfig/icons/C/${altDtLogo}.pm \
	root:other 0644
copy_file ${xbmFile} /tmp/${pkg}/etc/dt/appconfig/icons/C/${altDtLogo}.bm \
	root:other 0644

file="/tmp/${pkg}/${Xresources}"
echo "- Creating"
echo "  ${file}"
${cat} > ${file} << EOF
Dtlogin*altDtsIncrement:	True
Dtlogin*altDtName:		${altDtName}
Dtlogin*altDtKey:		${altDtKey}
Dtlogin*altDtStart:		${altDtStart}
Dtlogin*altDtLogo:		${altDtLogo}
EOF
set_permissions ${file} bin:bin 0444

file="/tmp/${pkg}/${altDtStart}"
echo "- Creating"
echo "  ${file}"
${cat} > ${file} << EOF
#!/bin/ksh 

DTDSPMSG=/usr/dt/bin/dtdspmsg

if [ -z "\$SESSIONTYPE" ]
then
	export SESSIONTYPE="altDt"
fi

if [ -z "\$DTSTARTIMS" ]
then
	export DTSTARTIMS="False"
fi

if [ -z "\$SDT_ALT_SESSION" ]
then
	export SDT_ALT_SESSION="${phase2}"
fi

if [ -z "\$SDT_ALT_HELLO" ]
then
  if [ -x \$DTDSPMSG ]; then 
     export SDT_ALT_HELLO="/usr/dt/bin/dthello -string '\`\$DTDSPMSG -s 37 /usr/dt/lib/nls/msg/\$LANG/dthello.cat 1 'Starting the ${altDtName} Desktop'\`' &"
  else
     export SDT_ALT_HELLO="/usr/dt/bin/dthello -string 'Starting the ${altDtName} Desktop' &"
  fi
fi

export SDT_NO_DSDM=""

SSH_AGENT="${sshAgent}"
if [ ! -z "\${SSH_AGENT}" ]; then
	if [ ! -x "\${SSH_AGENT}" ]; then
		SSH_AGENT=""
		errMsg="*** ERROR: ${altDtName} CDE login did not find the ssh-agent as \"\${SSH_AGENT}\" -- starting window manager without it"
		echo "\${errMsg}" > /dev/console
		echo "\${errMsg}" | /usr/bin/logger -p user.err
	fi
fi

\${SSH_AGENT} /usr/dt/bin/Xsession

EOF
set_permissions ${file} bin:bin 0555

file="/tmp/${pkg}/${phase2}"
echo "- Creating"
echo "  ${file}"
${cat} > ${file} << EOF
#!/bin/ksh 
# First a little namespace cleanup of vars associated with this
# (and /usr/dt/bin/Xsession.ow) scripts.

unset SDT_ALT_SESSION
unset SDT_ALT_HELLO
unset SDT_NO_DSDM

#
# Find "xinitrc" file by standard precedence rules and start 
# the user's OpenWindows Desktop.
#

DEFAULT_XINITRC="${Xinitrc}"
HOME_XINITRC="\$HOME/.xinitrc"
PATH=/usr/local/bin:/usr/dt/bin:\$PATH:/usr/openwin/bin
export PATH

    if [ -z "\$XINITRC" ]; then
	if [ -f \$HOME_XINITRC ]; then
	    XINITRC=\$HOME_XINITRC
	else
	    XINITRC=\$DEFAULT_XINITRC
	fi
    fi

    echo "${altDtName} Desktop Login"

    if [ -f \$XINITRC ]; then
	echo "using xinitrc file: \$XINITRC"
        /bin/ksh \$XINITRC
    else
	echo "xinitrc file: \$XINITRC not found"
	if [ -f \$DEFAULT_XINITRC ]; then
	    echo "using xinitrc: \$DEFAULT_XINITRC"
	    /bin/ksh \$DEFAULT_XINITRC 
	fi
    fi

EOF
set_permissions ${file} bin:bin 0555

file="/tmp/${pkg}/${Xinitrc}"
echo "- Creating"
echo "  ${file}"
${cat} > ${file} << EOF
if [ -f \$HOME/.Xdefaults ]; then
    xrdb -merge \$HOME/.Xdefaults	# Load Users X11 resource database
fi

eval `locale_env -env`			# Set Locale Environment

if [ ! -x "${altDtKey}" ]; then
	errMsg="*** ERROR: ${altDtKey} window manager not found"
	echo "\${errMsg}" > /dev/console
	echo "\${errMsg}" | /usr/bin/logger -p user.err
else
${altDtKey}
fi

EOF
set_permissions ${file} bin:bin 0444

file="/tmp/${pkg}/checkinstall"
echo "- Creating ${file}"
${cat} > ${file} << EOF
#!/bin/sh

files_ok=1
for file in \
	/etc/dt/appconfig/icons/C/${altDtLogo}.pm \
	/etc/dt/appconfig/icons/C/${altDtLogo}.bm \
	${Xresources} \
	${altDtStart} \
	${phase2} \
	${Xinitrc} \
	; do
	if [ -f \${file} ]; then
		files_ok=0
	fi
done

if [ \${files_ok} -ne 1 ]; then
	${puttext} "*** ERROR: The following file(s) already exist:"
	for file in \
		/etc/dt/appconfig/icons/C/${altDtLogo}.pm \
		/etc/dt/appconfig/icons/C/${altDtLogo}.bm \
		${Xresources} \
		${altDtStart} \
		${phase2} \
		${Xinitrc} \
		; do
		if [ -f \${file} ]; then
			${puttext} -- "- \${file}"
		fi
	done
	exit 3
fi

for file in /etc/dt/config/C/Xresources.d/* ; do
	${grep} "^Dtlogin\*altDtName:[ 	]*${altDtName}\$" \
		\${file} > /dev/null 2>&1
	if [ \$? -eq 0 ]; then
		${puttext} ""
		${puttext} "*** ERROR: The session name ${altDtName} appears in
			the file \${file}.  This installation would cause a
			conflict with another session.
			"
		exit 3
	fi
done

for file in /usr/dt/config/C/Xresources.d/* ; do
	${grep} "^Dtlogin\*altDtName:[ 	]*${altDtName}\$" \
		\${file} > /dev/null 2>&1
	if [ \$? -eq 0 ]; then
		${puttext} ""
		${puttext} "NOTICE: The session name ${altDtName} appears in
			the file \${file}.  This installation will overshadow
			(non-destructively replace) this session in the
			dtlogin sessions menu.
			"
		${puttext} ""
	fi
done

exit 0

EOF

echo "- Creating pkginfo file"
arch=sparc
os=Solaris
vers=x
category=system
vendor=
desc="CDE DtLogin configuration files for ${altDtName}"
pstamp=
email=
basedir=/
classes=none
pkgFile=${pkg}-${os}-root

echo "PKG=\"${pkg}\"" > /tmp/${pkg}/pkginfo
echo "NAME=\"${altDtName}\"" >> /tmp/${pkg}/pkginfo
echo "ARCH=\"${arch}\"" >> /tmp/${pkg}/pkginfo
echo "VERSION=\"${vers}\"" >> /tmp/${pkg}/pkginfo
echo "CATEGORY=\"${category}\"" >> /tmp/${pkg}/pkginfo
echo "VENDOR=\"${vendor}\"" >> /tmp/${pkg}/pkginfo
echo "DESC=\"${desc}\"" >> /tmp/${pkg}/pkginfo
echo "PSTAMP=\"${pstamp}\"" >> /tmp/${pkg}/pkginfo
echo "EMAIL=\"${email}\"" >> /tmp/${pkg}/pkginfo
echo "BASEDIR=\"${basedir}\"" >> /tmp/${pkg}/pkginfo
echo "CLASSES=\"${classes}\"" >> /tmp/${pkg}/pkginfo

echo "- Creating prototype file"
echo "i pkginfo=./pkginfo" > /tmp/${pkg}/prototype
echo "i checkinstall=./checkinstall" >> /tmp/${pkg}/prototype
(cd /tmp/${pkg} && \
	${find} . -print \
	| ${grep} -v "./prototype" \
	| ${grep} -v "./checkinstall" \
	| ${grep} -v "./pkginfo" \
	| ${pkgproto} \
	>> prototype \
	)

echo "- Creating package spool directory"
(cd /tmp/${pkg} && ${pkgmk} -o -r `${pwd}`)

echo "- Transfering spool directory to datastream file"
${pkgtrans} -s /var/spool/pkg ${pkgFile} ${pkg}

echo "- Checking datastream file: /var/spool/pkg/${pkgFile}"
${pkgchk} -d /var/spool/pkg/${pkgFile} ${pkg}

echo "- Removing /tmp/${pkg}"
${rm} -fr /tmp/${pkg}

echo "- Removing /var/spool/pkg/${pkg}"
${rm} -fr /var/spool/pkg/${pkg}

echo ""
echo "Done."
echo ""

${cat} << EOF
There is now a file on this host named:

	/var/spool/pkg/${pkgFile}
	
This file is a datastream-format Solaris package that contains your new CDE
login session setup.  To install this file, type:

	pkgadd -d /var/spool/pkg/${pkgFile} ${pkg}

And then notify dtlogin of the changes by selecting "Options" from the dtlogin
screen and then "Reset Login Screen" from the Options pull-down menu.

After this, you should be able to click on "Options" from the dtlogin screen,
and then "Session" from the Options pull-down menu to see your new CDE login
(which will be listed as "${altDtName}").

EOF
