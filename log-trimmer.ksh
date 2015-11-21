#!/bin/ksh

########################################################
#
#  Shell Script: log-trimmer
#
#  1999, Michael Doran, doran@uta.edu
#  University of Texas at Arlington Libraries
#
#  Trims log files that tend to outgrow their
#  respective file systems.
#
########################################################


# Standard Variables
 script_name=$0
 sess_file=/tmp/log-trimmer.$$

# Function to add comments to session file
add ()
{
    /usr/bin/echo "$1" >> ${sess_file}
}

# Function to mail session file to operator
swoosh ()
{
    /usr/bin/mailx -s "$1" operator < ${sess_file}
}

# Give session file an identifying header
add "${script_name}\n `date`\n"

# Show current disk space
add "Starting disk space:\n`df -k`\n"

######################################################
#  TrimLog: Function to trim flat-file logs
#            (i.e. one line = one entry)
#  Requires two arguments:
#	$1 - full path name of log file
#	$2 - threshold size (in number of lines)
#  If the log file exceeds the threshold size, then it 
#  is trimmed to one-half of the threshold.

TrimLog ()
{
    # Check for presence of log file and threshold value
    if [ ! -w $1 -o -z $2 ]
    then
	# append note to session file
	add "\n\n *** Missing $1 and/or threshold value ***\n\n"
	# mail session file with error
	swoosh "ERROR: ${script_name}"
	# and exit script
	exit 1
    fi

    # Determine the size of the log file in lines
    lines=`wc -l < $1`		# Number of lines in log file
     keep=`expr $2 / 2`		# One half of threshold size
    tmp_f=/tmp/TrimLog.tmp

    # Include info in session file
    add "Threshold size for $1 is $2 lines."
    add "  Since it was at ${lines} lines,"
   
    if [ ${lines} -gt $2 ]  # If filesize is over threshold
	then
	    # skim off most recent records to temp file
	    /usr/bin/tail -${keep} $1 > ${tmp_f}
	    # copy them over the original file
	    /usr/bin/cat ${tmp_f} > $1
	    # remove the big temp file
	    /usr/bin/rm  ${tmp_f}
	    # report what was done
	    add "  the log was trimmed to ${keep} lines.\n"
	else
	    # otherwise report no action
	    add "  the log was not trimmed.\n"
    fi
    return 0
}

# Directory for Apache log files
apache=/opt/apache*/logs

# Show size of apache log files
add "Apache log files:\n`/usr/bin/ls -l ${apache} | grep log`\n"
# Call TrimLog and give filename and threshold size
# Both arguments are REQUIRED
TrimLog ${apache}/access_log 1000000 >> ${sess_file} 2>&1
TrimLog ${apache}/error_log 40000 >> ${sess_file} 2>&1

# Trim the AnswerBook access log
TrimLog /var/log/ab2/logs/access-8888.log 10000 >> ${sess_file} 2>&1


######################################################
# TrimWTMP: function to trim wtmp and wtmpx files
# 
# These are data files, not flat files and have to be 
# truncated according to their record size.
#   see: SunSolve FAQ article 0921
#   see: SunSolve Symptoms and Resolutions article 10516

TrimWTMP ()
{
    # wtmp files
     wtmp=/var/adm/wtmp
     tmp_wtmp=/tmp/wtmp 

    # wtmpx files
     wtmpx=/var/adm/wtmpx
     tmp_wtmpx=/tmp/wtmpx

    # Check for presence of log files
    # If they do not exist or are not writable
    if [ ! -w ${wtmp} -o ! -w ${wtmpx} ]
    then
	# append note to session file
	add "\n\n *** Missing ${wtmp} and/or ${wtmpx} ***\n\n"
	# mail session file with error
	swoosh "ERROR: ${script_name}"
	# and exit script
	exit 1
    fi

    # Display log sizes
    add "Wtmp log files:\n`/usr/bin/ls -l /var/adm | grep wtmp`\n"

    # Determine file size (in bytes) by awk'ing from long listing
    filesize=`ls -l ${wtmpx} | awk '{print $5}'`

    # Divide filesize by bytes-per-record to get number of records
    #  (wtmp and wtmpx should contain the same number of records
    #   so this is only done for one of the logs)
    # wtmp records are 36 bytes and wtmpx records are 372 bytes
    num_recs=`expr ${filesize} / 372`

    # Threshold limit in number of records
    threshold=20000
    # Retain 1/2 of the threshold size
    retain=`expr ${threshold} / 2`
    # Include info in session file
    add "Threshold size for ${wtmp} and ${wtmpx} is ${threshold} records."
    add "  Since they were at ${num_recs} records," 

    # If there are more than the threshold number of records
    if [ ${num_recs} -gt ${threshold} ]
	then
	    # determine amount of records to skip
	    skip=`expr ${num_recs} - ${retain}`
	    # Make copy of log files to be used as input files for dd
	    /usr/bin/cp ${wtmp}  ${tmp_wtmp}
	    /usr/bin/cp ${wtmpx} ${tmp_wtmpx}
	    # Do the truncation
	    /usr/bin/dd if=${tmp_wtmp}  \
		of=${wtmp}  ibs=36  obs=36  skip=${skip}
	    /usr/bin/dd if=${tmp_wtmpx} \
		of=${wtmpx} ibs=372 obs=372 skip=${skip}
	    # update session file
	    add "  the logs were trimmed to retain ${retain} records.\n"
	    add "Ending file size:\n`/usr/bin/ls -l /var/adm | grep wtmp`\n"
	    # Remove the temporary input files
	    /usr/bin/rm ${tmp_wtmp}
	    /usr/bin/rm ${tmp_wtmpx}
	else
	    add "  the logs were not trimmed.\n"
    fi
    return 0
}

TrimWTMP >> ${sess_file} 2>&1

# Show ending disk space
add "Ending disk space:\n`df -k`\n"

add "${script_name} complete.\n`date`"

# Send session file to operator
swoosh "`uname -n` logs trimmed"

exit 0