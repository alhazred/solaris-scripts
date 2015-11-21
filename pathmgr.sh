#
# (c) 1998-2002, Antonio Dell'elce (neaya@yahoo.com)
#
# Path Management Script
#
# Works with Korn Shell (ksh) and Bourn-Again Shell (bash)
# and derivatives.
#
# Updates 2002:
#
# Feb 28 - Changed lspath to sue IFS to split PATH variable.
#          Update email address.
#

#
# lspath 
# Lists all path items one by line. 
#

lspath()
{
 typeset IN OLDIFS

 OLDIFS="$IFS"
 IFS=:

 for IN in $PATH
 do
  echo $IN
 done

 IFS="$OLDIFS"
}

#
# pathfix 
# Removes duplicate entries in the PATH variable and reorders all entries. 
# Note: doesn't check if path items are directories or not.
#

pathfix()
{
 typeset _PATH=$(lspath | sort | uniq ) 

 typeset __PATH=$(for IN in $_PATH
 do
  printf "%s:" $IN
 done)
 
 export PATH=${__PATH%:}
}


#
# savepath 
# Saves path to the current configuration file. 
#

savepath()
{
 [ -z "$PATHFILE" ] && _err_misconfigured && return 1

 touch $PATHFILE ||
  {
   echo "Error writing to path file!" && return 1
  }

 lspath | sort | uniq  > $PATHFILE
}


#
# autosavepath 
# Disables/enables automatic save of the path after 
# any change.
#

autosavepath()
{
 [ -z "$1" ] &&
  {
   [ -z "$PATHFILE" ] && _err_misconfigured && return 1

   [ -z "$PATHAUTOSAVE" ] && export PATHAUTOSAVE=0

   [ "$PATHAUTOSAVE" == "0" ] && echo "Auto save is off" && return 0

   [ "$PATHAUTOSAVE" == "1" ] && echo "Auto save is on" && return 0

   echo "Misconfigured autosave variable. Fixing.";
   export PATHAUTOSAVE=0
   return 1
  }

 [ "$1" == "on" ] &&
  {
   export PATHAUTOSAVE=1; return 0
  }

 [ "$1" == "off" ] &&
  {
   export PATHAUTOSAVE=0; return 0
  }

# internal use only! (will save path only if AutoSave is on)

 [ "$1" == "do" ] &&
  {
   [ "$AUTOSAVEPATH" == "on" ] &&
    {
     savepath && return 0
     return 1
    }
  }
  
 echo "$1: Unsupported."
 return 1
}

#
# readpath 
# Reads the path from current configuration file. 
#

readpath ()
{

 [ ! -f "$PATHFILE" ] &&
  {
   echo "Path file is badly configured, check PATHFILE "
   echo "environment variable."
   return 1
  } ||
  {
   typeset IN

   typeset __PATH=$(
   for IN in $(cat $PATHFILE )
   do
    printf "%s:" "${IN}"
   done)

   export PATH=${__PATH%:}
  
  }

 
}

#
# rmpath 
# Removes a path entry. 
#

rmpath()
{
 [ -z "$1" ] &&
  {
   echo "$0 needs an entry to remove from path!"
   return 1
  }
 
 export PATH=$(lspath | sort | uniq | grep -v "$1" | /usr/bin/tr ' ' ':')

 autosavepath now
}

#
# addpath 
# Adds a directory to the path. 
#

addpath ()
{

 [ -z "$1" ] &&
  {
   echo "addpath: needs a directory!"
   return 1
  }

 [ ! -d "$1" ] &&
  {
   echo "addpath: $1 is not a directory" 
   return 1
  }

 export PATH=$PATH:$1
 pathfix
 
}


#
# Configures PathMgr with defaults
#

pathdefaults ()
{
 [ -z "$PATHFILE" ] &&
  {
   export PATHFILE="$HOME/.path" 

   [ -f "$PATHFILE" ] &&
    {
     # we found a path file ...
     # so we can try load it.

     typeset IN
     typeset __PATH=$(
     for IN in $(cat $PATHFILE)
      do
        echo "${IN}:"
      done
)
     # ok now remove stupid trailing semicolon and .... return!

     export PATH=${__PATH%:}
     return 0

    } ||
    {
     touch $PATHFILE || 
      {
       echo "Cannot create path file\!"
       echo "Exiting."
       return 1
      }
    } 
  }

#
# by default we dont want to save 
# the path automatically.
#

 autosavepath off
}


#
# _err_misconfigured
#

_err_misconfigured ()
{
cat << EOF

Path file not configured.
Use 'pathdefaults' to configure PathMgr or
set the environment variable PATHFILE to your
path file.

EOF
}





###				 EOF			 	###
