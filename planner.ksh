#!/bin/ksh
# Korn shell script
# Script authors: Context-Switch Limited, November 2003
# Version A.2


# This script was developed on a Solaris UNIX system and should
# work on most UNIX/Linux systems. However, this it not guaranteed.
# You should read the accompanying REAME_FIRST file before executing this script!
# If no README_FIRST script ws supplied, then this script did not come from
# the original authors!


# DECLARE FUNCTIONS
function printusage
{
MSG1="Usage:
	planner  -option  year  month  day  hour  minute duration 'args'
where:
	option is one of the following options:
	-a   to add a calendar event
	-d   to delete a calendar event
	-p   to print/display the calendar event file pathname
	-v   to view all the calendar events on a given day	
	(NOTE: Only the options shown above are valid)
"

MSG2="and	year is the 4-digit year number
		(for example: 2003)
and	month is the 2-digit month number
		(for example: 03 would be March)
and	day is the 2-digit day number
		(for example: 12 would be the 12th day of the month)
and	hour is the 2-digit hour number
		(for example: 00 is midnight, 15 is 3pm, 08 is 8am)
and	minute is the 2-digit minute number
		(for example: 00 is on the hour and 15 is 15 minutes past the hour)
and	duration is a numeric value stating the duration of the event (in minutes)
		(for example: 120 signifies a duration of 2 hours (120 minutes))
and	args is a text string used the describe the calendar event.
	NOTE: The args text string must be enclosed in single quotes.

Here is an example command line:

planner -a 2003 11 21 08 30 120 'UNIX Shell Programming 1'"

MSG3="
***** IMPORTANT *****
It is important that leading zeros are used. 
For example, if the event time is 8am then the 
value 08 must be used rather than just using 
the value 8.

End of Usage message."

if (( $DISPVAL == 0 ))
then
	echo "$MSG1"
	echo "$MSG2"
	echo "$MSG3"
	exit 1

elif (( $DISPVAL == 1 ))
then
	echo "$MSG1"
	return

elif (( $DISPVAL == 3 ))
then
	echo "$MSG3"

fi
}
# End OF FUNCTION

# TRAP ERROR STATES AND EXIT
trap 'clear ; echo "An error has occurred with one of the values used" ; sleep 2 ; exit 1' ERR

# DECLARE REQUIRED VARIABLES
PLANDIR=$HOME/.planner
integer COUNTARGS=${#@}
integer DISPVAL=0

if (( $COUNTARGS <= 5 || $COUNTARGS > 8 ))
then
	printusage
	# call the function

elif (( $COUNTARGS == 8 ))
then
	CMDOPTION=$1
	integer YEAR=$2
	integer MONTH=$3
	integer DAY=$4
	integer HOUR=$5
	integer MINUTE=$6
	integer DURATION=$7
	typeset -R4 YEAR
	typeset -ZR2 MONTH DAY HOUR MINUTE
	shift 7		# now remove the first seven arguments
	EVENTTITLE=$*

elif (( $COUNTARGS == 6 ))
then
	CMDOPTION=$1
	integer YEAR=$2
	integer MONTH=$3
	integer DAY=$4
	integer HOUR=$5
	integer MINUTE=$6
	typeset -R4 YEAR
	typeset -ZR2 MONTH DAY HOUR MINUTE
	shift 6		# now remove the argument list

else
	echo "An incorrect number of command line arguments was used"
	exit 1
fi

# NOW, VERIFY THAT ALL OF THE OPTIONS ARE CORRECTLY STRUCTURED
case "$CMDOPTION" in
	-a|-d|-p|-v)	CHECK=valid ;;
	*)		DISPVAL=1 ; printusage ;;
esac

if (( $YEAR >= 2000 ))
then
	CHECK=valid
else
	echo "Problem with the value: $YEAR"
	echo ""
	echo "The value for the year should be a 4-digit value"
	echo "that is greater than 2000"
	exit 1
fi

if (( $MONTH >= 01 && $MONTH <= 12 ))
then
	CHECK=valid
else
	echo "Problem with the value: $MONTH"
	echo ""
	echo "The value for the month should be a 2-digit value"
	echo "that is between 01 and 12"
	exit 1
fi

if (( $HOUR >= 00 && $HOUR <= 24 ))
then
	CHECK=valid
else
	echo "Problem with the value: $HOUR"
	echo ""
	echo "The value for the hour should be a 2-digit value"
	echo "that is between 00 and 24"
	exit 1
fi

if (( $MINUTE >= 00 && $MINUTE <= 60 ))
then
	CHECK=valid
else
	echo "Problem with the value: $MINUTE"
	echo ""
	echo "The value for the minute should be a 2-digit value"
	echo "that is between 00 and 60"
	exit 1
fi

# IF WE HAVE REACHED THIS POINT IN THE SCRIPT, WE CAN ASSUME THAT ALL
# OF THE COMMAND-LINE ARGUMENTS ARE CORRECT.
# NOW, WE START TO PROCESS THE COMMAND APPROPRIATELY

case "${CMDOPTION}" in
-a)	# The ADD Routine

# First, check for the existence of the required directory
if [[ ! -d ${PLANDIR}/${YEAR}/${MONTH}/${DAY} ]]
then
	echo "\aA required directory does not yet exist!"
	echo ""
	echo "It can be created now, if you like."
	echo "If it is not created, the script will be forced to terminate"
	echo "and you will have to run the planner command again."
	echo ""
	echo "Should I create the directory? (y/n) :\c"

	read RESPONSE1 OTHERS

	if [[ "${RESPONSE1}" = [yY]* ]]
	then
		mkdir -p ${PLANDIR}/${YEAR}/${MONTH}/${DAY} && echo "Directory created"
	else
		echo "Directory not created. Exiting the program"
		sleep 2
		exit 1
	fi
fi

# Create a variable to store the event file pathname
EVENTFILE=${PLANDIR}/${YEAR}/${MONTH}/${DAY}/${HOUR}.${MINUTE}

# Verify that the file does not yet exist. It it DOES exist, inform the user and exit
if [[ -f $EVENTFILE ]]
then
	echo "A Calendar Event file already exists for that date & time"
	echo "Please check the command line arguments you used or"
	echo "use the -p option to verify the file name is correct"
else
# Now prompt the user for some text to store in the calendar event file
	echo "Please enter some text to store in this file."
	echo "This text is commonly used to describe the calendar event"
	echo "and can be any text of your choice."
	echo ""
	echo "Keep typing the text as lines and press RETURN/ENTER at the"
	echo "end of each line of text (including the last line of text)"
	echo ""
	echo "When you have finished typing all the lines of text, press Ctrl-D"
	echo ""

	cat > $EVENTFILE && echo "\nDuration: $DURATION minutes" >> $EVENTFILE
	if (( $? == 0 ))
	then
		echo "Calendar event saved to file: $EVENTFILE"
	else
		echo "Error encountered when creating the calendar event"
		exit 1
	fi
fi
;;
####################
# END OF ADD Routine
####################

-d)	# The DELETE Routine
# Create a variable to store the event file pathname
EVENTFILE=${PLANDIR}/${YEAR}/${MONTH}/${DAY}/${HOUR}.${MINUTE}

# Verify that the file does not exist. It it DOES exist, remove the file and inform the user
if [[ ! -f $EVENTFILE ]]
then
	echo "No such event"
	exit 1
else
	rm $EVENTFILE && echo "Event file removed" && exit $?
fi
;;
####################
# END OF DELETE Routine
####################

-p)	# The PRINT Routine
# Create a variable to store the event file pathname
EVENTFILE=${PLANDIR}/${YEAR}/${MONTH}/${DAY}/${HOUR}.${MINUTE}

# Verify that the file DOES exist. If it DOES exist, display the pathname
if [[ -f ${EVENTFILE} ]]
then
	echo "${EVENTFILE}"
	exit 0
else
	#echo "Event file was either never created of has been removed"
	CHECK=invalid
fi
;;
####################
# END OF PRINT Routine
####################

-v)	# The VIEW Routine
# Create a variable to store the event file pathname
EVENTDIR=${PLANDIR}/${YEAR}/${MONTH}/${DAY}

# Verify that the directory DOES exist. If it DOES exist, display the contexts of files
# in that directory
if [[ -d ${EVENTDIR} ]]
then
	echo "Events for ${DAY} / ${MONTH} / ${YEAR}"
	echo ""
	cd $EVENTDIR && for EVENTS in *
	do
		echo "Event at: $EVENTS"
		echo "======================="
		echo ""
		cat $EVENTS
		echo ""
	done 
	exit 0
else
	#echo "Event the directory for that date does not exist"
	CHECK=invalid
	exit 1
fi
;;
####################
# END OF VIEW Routine
####################

esac
############################
# END OF OPTION VERIFICATION
############################

# THIS IS THE END OF THE PROGRAM
