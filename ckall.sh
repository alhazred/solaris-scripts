#
# (c) 2000 by Antonio Dell'elce
#
# Notice the ESC variable must be set to ^[ i.e. char n. 27!
#
# This script is supposed to work with a Bourne shell variant
# that supports Functions and 'typeset -f'.
#
# ckall_default and ckall_log use AIX commands (errpt)
# ckall itself will work on any unix with the above requirements.
#

#
# Only configuration parameter will be CKHOSTS variable
# It will point to a file containg a list of hosts (our "cluster")
# on which ckall will execute it's "verifications"
#

export CKHOSTS=${CKHOSTS:-$HOME/.ckhosts}

#
#  Standard args for a functions
#
#  function_name Options Hostname
#

ckall_default ()
{
 uptime
 return 0
}

#
# Following 
#

ckall_log ()
{
[ $(errpt | wc -l | xargs echo) -eq 0 ] && echo "Error log is empty" &&
return 1
typeset LEDT=$(errpt | head -2 | tail -1 | awk '{print $2}'| cut -c1-4)
typeset MONTH=$(echo $LEDT | cut -c1-2)
typeset DAY=$(echo $LEDT | cut -c3-4)
echo "Last error on $MONTH / $DAY (Month/Day)"
}

ckall_testlog ()
{
echo Errpt size : $(errpt | wc -l )
}

#
# - core function - should work any platform -
#

ckall ()
{
 typeset PAUSE_FLAG=0
 typeset DEFAULT_FUNC=ckall_null
 typeset ESC=""
 typeset RED="$ESC[31m"
 typeset RESET="$ESC[0m"


 [ -z "$1" ] &&
  {
   ACTION=ckall_default
  } ||
  {
   ACTION=ckall_$1
  }

 case $1 in 
  -p)
    PAUSE_FLAG=1;
    shift
    ;;


   *)
 
 esac

 [ ! -f "$CKHOSTS" ] &&
  {
   echo "Missing hosts file"
   return
  }

 for IN in $(cat $CKHOSTS)
  do
   echo ====== ${RED}$IN${RESET} ======
 
(cat &lt;&lt; EOF
    $(typeset -f $ACTION );
    $ACTION
EOF
) | rsh $IN ksh

    [ "$PAUSE_FLAG" = 1 ] &&
     {
      echo
      printf "%s" Type return to continue.;read
      echo
     }
  done
}