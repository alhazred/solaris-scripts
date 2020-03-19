#!/bin/csh

### find-user.csh
###
### This script is designed to give the NIS+ Admin a tool
### for viewing information about users in an all-in-one place.
###
### Submitted By: Marc Jacquard
###               Marc.Jacquard@firstdatacorp.com

set nisuser = $1

if (-r /tmp/$nisuser.grps) then
	rm /tmp/$nisuser.grps
endif

if ("$1" == "") then
	echo USAGE: user.info "<"user name">"
else

# Set all the necessary variables for a user's information
niscat group.org_dir|grep -w "$nisuser"|awk -F":" '{print $1}'|tr -s "\n" "," >/tmp/$nisuser.grps
set usrid = `niscat passwd.org_dir|grep -w "$nisuser"|awk -F":" '{print $3}'`
#set upass = `nisgrep "^$nisuser" passwd.org_dir|awk -F":" '{print $2}'|awk-F"*" '{print $2}'`
set upass = `niscat passwd.org_dir|grep -w "$nisuser"|awk -F":" '{print $2}'|awk -F"*" '{print $2}'`
set defgrp = `niscat passwd.org_dir|grep -w "$nisuser"|awk -F":" '{print $4}'`
set realname = `niscat passwd.org_dir|grep -w "$nisuser"|awk -F":" '{print $5}'`
set defshell = `niscat passwd.org_dir|grep -w "$nisuser"|awk -F":" '{print $7}'`
set homedir = `niscat auto_home.org_dir|grep -w "$nisuser"|awk -F" " '{print $2}'`
set mailid = `niscat Mail_aliases.org_dir| grep "$nisuser@"|tr -s " " ":"`
set credent1 = `niscat cred.org_dir|grep -v DES|grep -w "$nisuser"`
set credent2 = `niscat cred.org_dir|grep -v LOCAL|grep -w "$nisuser"`
set check = `niscat passwd.org_dir|grep -w "$nisuser"|awk -F":" '{print $1}'`
set homedir = `niscat auto_home.org_dir|grep -w "$nisuser"|awk -F" " '{print $2}'`
#
# Make sure the user is in the NIS+ database

if ( "$check" == "")then
     echo The user "("$nisuser")" does not exist in NIS+ !
      exit
# Check to see if the account is locked

    else if ( "$upass" != "LK" ) then

       echo $nisuser is the User name for $realname":"
        echo User ID = $usrid
         echo Default group = $defgrp
          echo Home Dir = $homedir
           echo Default shell = $defshell
         echo User"'"s mail address"("es")" = $mailid
             echo The credential table for $nisuser is listed below:
              echo $credent1
               echo $credent2
                echo $nisuser is in the following secondary groups:
                 more /tmp/$nisuser.grps
           else
               echo This account is Locked!
              echo $nisuser is $realname
             echo User ID=$usrid
            echo Default group=$defgrp
           echo Home Dir=$homedir
          echo Default shell=$defshell
#        echo This $nisuser has no credential table entry!
        echo $credent1
       echo $credent2
      echo $nisuser is in the following secondary groups:
     more /tmp/$nisuser.grps
   endif
endif

if (-r /tmp/$nisuser.grps) then
    rm /tmp/$nisuser.grps
endif


exit(0)


##############################################################################
### This script is submitted to BigAdmin by a user of the BigAdmin community.
### Sun Microsystems, Inc. is not responsible for the
### contents or the code enclosed. 
###
###
### Copyright 2005 Sun Microsystems, Inc. ALL RIGHTS RESERVED
### Use of this software is authorized pursuant to the
### terms of the license found at
### http://www.sun.com/bigadmin/common/berkeley_license.html
##############################################################################


