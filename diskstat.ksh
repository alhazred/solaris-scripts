#!/bin/ksh
# Korn Shell script
# Written by Jeff Turner of Context-Switch.com
# Dated: January, 2002
# Version: A.0
# Mail comments to: Jeff.Turner@context-switch.com

# BACKGROUND:
# Administrators may wish to determine just how busy their
# disks are and to also determine whether their systems are
# read-intensive or write-intensive
#
# This shell script uses the 'kstat' utility to determine 
# the number of disk reads/writes per disk slice in a specified
# time interval (see FREQUENCY & REPEATS variables, below)
#
# Output is structured on a per-slice basis, with a report output
# line for each FREQUENCY-interval
#
# Most of the work is carried out by the shell in which this script
# is executing, with minimal use of external utilities. Hopefully, this
# makes the script more efficient (with regard to system resource demand)
# and reduces the impact on the running system.

# assign variables for use in the script
integer COUNT=1 SAMPLE=0 # used as a counter for loops
integer READS=0 WRITES=0 TOTREADS=0 TOTWRITES=0 # used to store date
integer DIFFREADS=0 DIFFWRITES=0 # used to store the calculated differences

typeset -L10 SLICENAME=""	# used to format output
typeset -R15 READS # used to format output
typeset -R15 WRITES # used to format output
SLICENAME=""
TMPFILE=/tmp/kstat.$$

# HINT: Do not set the FREQUENCY value to be a number less than 5
# as this could impact on system performance
integer FREQUENCY=5 REPEATS=13	# used with the kstat command 
		# The first sample is used to obtain starting values
		# the remaining twelve samples provide...
		# 5 seconds x 12 repeats = 60 seconds sampling time

# assign kstat pathname to a variable
KSTAT="`which kstat`" export KSTAT

# determine that the kstat utility exists
if [ -f "$KSTAT" -a -x "$KSTAT" ] 
then
	# The kstat utility exists and is executable by this user
        # We now need to produce details for SCSI (sd) and IDE (dad) 
        # module reads and writes
	STARTTIME=$(date +"Started sampling at %T on %D")
	$KSTAT -m \*[sa]d -p $FREQUENCY  $REPEATS | 
	sed -n -e 's/:/ /g'  -e 's/\,/_/' -e '/_[abd-h] [rw][er][ai][dt][se]/p' > $TMPFILE
	ENDTIME=$(date +"Sampling ended at %T on %D")

	# verify that there has been some output, 
        # otherwise exit from the script
	if [ -z $TMPFILE ]
	then
		# file has zero contents
		echo "\nOutput file has zero contents. Aborting script now...\n"
		exit 1
	fi

	# now determine how many disk slices are reported on
	# obtain unique instances of each slice name
	SLICELIST=$( nawk '{ print $3 }' $TMPFILE | sort -u)

	# output the start time details
	echo "$STARTTIME"
	echo "Sample frequency is set to $FREQUENCY seconds"

	# now process the data
	for SLICENAME in $SLICELIST
	do
		grep $SLICENAME $TMPFILE | while read LINE
		do
			set -- $LINE
			if [[ $COUNT == 1 && $4 = "reads" ]]
			then
				READS=$5
				integer DIFFREADS=0 
			elif [[ $COUNT == 1 && $4 = "writes" ]]
			then
				WRITES=$5
				integer DIFFWRITES=0
				(( COUNT = $COUNT + 1 ))

				# produce report output
				echo "\nSAMPLE	$SLICENAME	    Reads	       Writes"

			elif  [[ $COUNT > 1 && $4 = "reads" ]]
			then
				integer NUMVAR=$5
				(( DIFFREADS = $NUMVAR - $READS ))
				if (( $DIFFREADS > 0 ))
				then
					READS=$NUMVAR
				fi
				(( TOTREADS = $TOTREADS + $DIFFREADS ))

			elif  [[ $COUNT > 1 && $4 = "writes" ]]
			then
				integer NUMVAR=$5
				(( DIFFWRITES = $NUMVAR - $WRITES ))
				if (( $DIFFWRITES > 0 ))
				then
					WRITES=$NUMVAR
				fi
				(( TOTWRITES = $TOTWRITES + $DIFFWRITES ))
				(( SAMPLE = $SAMPLE + 1 ))

				# produce report output
				typeset -L8 SAMPLE # used to format output
				typeset -R15 DIFFREADS # used to format output
				typeset -R15 DIFFWRITES # used to format output
				echo "$SAMPLE		$DIFFREADS $DIFFWRITES"
			fi
		done
		COUNT=1
		SAMPLE=0
	done
	echo "Total Reads:  $TOTREADS"
	echo "Total Writes: $TOTWRITES\n"

	# output the start time details
	echo "$ENDTIME"

else
	# either the kstat command dows not exist in the user's PATH list
	# or the user does not have permission to execute the kstat command

	echo "\aSorry."
	cat << EOF

	Either... 1. The 'kstat' utility can not be found in the \$PATH directories
	    or... 2. You do not have permission to execute the 'kstat' command
	Terminating the program now.

EOF
	exit 2
fi
