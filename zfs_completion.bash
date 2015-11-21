#
# CDDL HEADER START
#
# The contents of this file are subject to the terms of the
# Common Development and Distribution License (the "License").
# You may not use this file except in compliance with the License.
#
# You can obtain a copy of the license at usr/src/OPENSOLARIS.LICENSE
# or http://www.opensolaris.org/os/licensing.
# See the License for the specific language governing permissions
# and limitations under the License.
#
# When distributing Covered Code, include this CDDL HEADER in each
# file and include the License file at usr/src/OPENSOLARIS.LICENSE.
# If applicable, add the following below this CDDL HEADER, with the
# fields enclosed by brackets "[]" replaced with your own identifying
# information: Portions Copyright [yyyy] [name of copyright owner]
#
# CDDL HEADER END
#
# Copyright 2007 Sun Microsystems, Inc.  All rights reserved.
# Use is subject to license terms.
#
#----------------------------------------------------------------------

#
# bash command line completion for zfs and zpool
#
# There are a few restrictions to bash's ability to complete command
# lines, and there is at least one bug.
#
# * Command line arguments:
#	Most of zfs's commands take various arguments.  I decided
#	against writing a full command line parser for each command,
#	the completion code will complete some things that are not
#	actually allowed
#
# * Option lists
#	Some of the option arguments are in the form of lists (e.g.
#	option,option or even option=val,option=val).  There doesn't
#	seem to be a facility in base to handle this properly, so
#	this still has to be done manually.
#
# * @-sign bug
#	ZFS uses the '@' character for snapshot names.  This apparently
#	confuses the completion code.  To reproduce the bug, create
#	a snapshot of a filesystem, e.g. tank/foo@snap, and then
#	perform the following steps:
#		# zfs send tank/foo<TAB><BACKSPACE><TAB>
#	The first <TAB> will cause the snapshot's name to be expanded
#	properly.  The <BACKSPACE> will put the cursor at the end of the
#	name, and the second <TAB> will cause the completion code to
#	replace 'tank/foo@snap' with 'tank/footank/foo@snap'.  I suspect
#	the built-in hostname completion code is interfering with the
#	snapshot name.
#
# * Trailing spaces
#	Some arguments, such as the <dev> 'zpool create <pool> <dev>'
#	work better without trailing spaces, whereas they are expected
#	in others, such as the 'create' in that very same command.  There
#	does not seem to be a way in bash to specify which arguments
#	get spaces and which don't.  This can be frustrating for the user.
#


__zfs_get_iprops()
{
	# discover all inheritable properties
	zfs get 2>&1 | grep YES | awk '{ if ($3 == "YES") print $1 }'
}


__zfs_comp()
{
	local cur prev cmds iprops base cmd

	COMPREPLY=()
	cur="${COMP_WORDS[COMP_CWORD]}"
	prev="${COMP_WORDS[COMP_CWORD-1]}"
	base="${COMP_WORDS[1]}"

	# zfs commands
	cmds="create destroy snapshot rollback clone promote rename \
		list set get inherit mount unmount share unshare \
		send receive"
	
	if [ "${prev##*/}" = "zfs" ]
	then
		COMPREPLY=($(compgen -W "$cmds" -- "$cur"))
		return 0
	fi

	local results

	case "${base}" in
	create)
		#
		# To create a filesystem, we need at least a pool name.  We
		# use the "-S /" option to add trailing /'s to the names.  It
		# would be nice to selectively turn on '-o nospace' here, but
		# it doesn't appear possible.  It would also be nice to be
		# able to restrict the command line to a single filesystem or
		# volume, but that would require extensive command line
		# parsing.
		#
		results=$(/usr/sbin/zfs list -H -o name -t filesystem,volume)
		COMPREPLY=($(compgen -S / -W "$results" -- "$cur"))
		return 0
		;;
	destroy|list|set|get)
		#
		# Destroy differs from create in that we don't need to
		# restrict options to filesystems & volumes.  The list, set,
		# and get commands kinda fall into this category too.  As
		# these three commands can take multiple datasets, we don't
		# try to restrict them to one.
		#
		results=$(/usr/sbin/zfs list -H -o name)
		;;
	snapshot)
		#
		# We can only snapshot filesystems and volumes, and we
		# *dont* want to add trailing /'s.
		#
		results=$(/usr/sbin/zfs list -H -o name -t filesystem,volume)
		;;
	rollback)
		#
		# Rollback only works with snapshots.
		#
		results=$(/usr/sbin/zfs list -H -o name -t snapshot)
		;;
	clone)
		#
		# Clone takes no options, so this is easier to handle.  The
		# first argument (where $prev == $base) has to be a snapshot,
		# whereas the second argument has to be a filesystem in
		# the same pool.
		#
		if [ "x$prev" = "x$base" ]
		then
			results=$(/usr/sbin/zfs list -H -o name -t snapshot)
		else
			results=$(/usr/sbin/zfs list -H -ro name \
			    -t filesystem ${prev%%/*} 2>/dev/null)
		fi
		;;
	promote)
		#
		# Promotions can only be done of cloned filesystems.  We
		# check the 'origin' property to see if the filesystem is
		# a clone.
		#
		if [ "x$prev" = "x$base" ]
		then
			results=$(/usr/sbin/zfs get -rH -o name,value origin |
			    grep -v -- '-$' | awk '{print $1}')
		else
			return 1
		fi
		;;
	rename)
		#
		# The first argument to rename, besides the -r, can be
		# of any type.  The second argument has to be of the same
		# type as the first.  If -r is specified, then the first
		# and second type must be snapshots
		#
		if [ "x$prev" = "x-r" ]
		then
			results=$(/usr/sbin/zfs list -H -o name -t snapshot)
		else
			results=$(/usr/sbin/zfs list -H -o name)
		fi
		;;
	inherit)
		#
		# Inherit takes a property and one or more filesystems or
		# volumes.
		#
		if [ "x$prev" = "x-r" ] || [ "x$prev" = "x$base" ]
		then
			results=$(__zfs_get_iprops)
		else
			results=$(/usr/sbin/zfs list -H -o name \
			    -t filesystem,volume)
		fi
		;;
	mount|share)
		#
		# Mount and share can be -a, or a filesystem
		#
		results=$(/usr/sbin/zfs list -H -o name -t filesystem)
		;;
	unmount|unshare)
		#
		# Unmount and unshare can take a dataset filesystem, or a
		# mountpoint.  Happily, the output from 'zfs mount' lists
		# all of these without any cruft to strip off.
		#
		results=$(/usr/sbin/zfs mount)
		;;
	send)
		#
		# Send can only send snapshots
		#
		results=$(/usr/sbin/zfs list -H -o name -t snapshot)
		;;
	receive)
		#
		# Receive can take any dataset type

		results=$(/usr/sbin/zfs list -H -o name)
		;;
	*)
		return 1
		;;
	esac

	#
	# A quick filter until CR 6540584 is fixed
	#
	if [ "$results" = "no datasets available" ]
	then
		results=""
	fi

	COMPREPLY=($(compgen -W "$results" -- "$cur"))
	return 0
}

__zpool_devices()
{
	local line found

	found=""
	/usr/sbin/zpool status -v $1 | while read line
	do
		line="${line%% *}"
		if [ "${line}" = "NAME" ]
		then
			found=1
			continue
		elif [ ! -z "$found" ] && [ "${line}" = "" ]
		then
			return 0
		fi
		if [ ! -z "$found" ]
		then
			if [ "${line}" = "$1" ] || [ "${line}" = "mirror" ] ||
			    [ "${line}" = "raidz" ] ||
			    [ "${line}" = "raidz2" ] || [ "${line}" = "spares" ]
			then
				continue
			fi
			echo ${line}
		fi
	done
	return 0
}

__zpool_is_pool()
{
	/usr/sbin/zpool list -H -o name | while read pname
	do
		if [ $pname = $1 ]
		then
			echo yes
			break
		fi
	done
}

__zpool_comp()
{
	local cur prev cmds iprops base cmd

	COMPREPLY=()
	cur="${COMP_WORDS[COMP_CWORD]}"
	prev="${COMP_WORDS[COMP_CWORD-1]}"
	base="${COMP_WORDS[1]}"

	# zpool commands
	cmds="create destroy add remove list iostat status online offline \
	    clear attach detach replace scrub import export upgrade \
	    history get set"
	
	if [ "${prev##*/}" = "zpool" ]
	then
		COMPREPLY=($(compgen -W "$cmds" -- "$cur"))
		return 0
	fi

	local results xtra

	xtra=""

	case "${base}" in
	create)
		#
		# Pool creation can be a bit tricky to complete, so we just
		# go with the built-in options ('mirror', 'raidz', 'raidz2',
		# and 'spare') and filename completion (which unfortunately is
		# space-happy).
		#
		if [ "${cur%%/*}" = "" ]
		then
			results=$(compgen -f "${cur}")
		else
			results="mirror raidz raidz2 spare"
		fi
		;;
	destroy|history|set|upgrade)
		#
		# Pool names are only allowed here, plus the -f force option
		# for destroy.
		#
		if [ "x$prev" = "x$base" ] || [ "x$prev" = "x-f" ]
		then
			results=$(/usr/sbin/zpool list -H -o name)
		else
			return 1
		fi
		;;
	add)
		#
		# We can add vdevs to existing pools.  
		#
		local isopt
		isopt=${prev#-}
		if [ "x$prev" = "x$base" ] || [ "x$isopt" != "x$prev" ]
		then
			results=$(/usr/sbin/zpool list -H -o name)
		else
			results=$(compgen -f "${cur}")
		fi
		;;
	remove|online|offline|clear|detach)
		#
		# Removing a device from a pool gives us a little more room
		# for cleverness: once we know the pool name, we can
		# provide a list of devices.  Online, offline, clear, and
		# detach work similarly, except that offline takes a -t option
		# as well.
		#
		if [ "x$prev" = "x$base" ]
		then
			results=$(/usr/sbin/zpool list -H -o name)
		elif [ "$base" = "offline" ] && [ "x$prev" = "x-t" ]
		then
			results=$(/usr/sbin/zpool list -H -o name)
		else
			results=$(__zpool_devices $prev)
		fi
		;;
			
	list|scrub|export|get|iostat|status)
		#
		# These commands can take any number of pools.
		#
		results=$(/usr/sbin/zpool list -H -o name)
		;;

	attach|replace)
		#
		# Attach takes a pool, an existing pool's device, and a
		# new device.  Optional -f adds complexity, of course.
		# Replace looks nearly the same.
		#
		if [ "x$prev" = "x$base" ] || [ "x$prev" = "x-f" ]
		then
			results=$(/usr/sbin/zpool list -H -o name)
		elif [ "$(__zpool_is_pool ${prev})" = "yes" ]
		then
			results=$(__zpool_devices $prev)
		else
			results=$(compgen -f "${cur}")
		fi
		;;
	*)
		return 1
		;;
	esac

	#
	# A quick filter until CR 6540584 is fixed
	#
	if [ "$results" = "no pools available" ]
	then
		results=""
	fi

	COMPREPLY=($(compgen $xtra -W "$results" -- "$cur"))
	return 0
}

complete -F __zfs_comp zfs
complete -F __zpool_comp zpool


