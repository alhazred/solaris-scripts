#!/bin/ksh

#  Filename : easySCCS.sh
#  Creation Date : 01/09/2003
#  Author/Submitter : arjun.singh@hpsglobal.com
#  Function : A utility script for automation of SCCS unix utility. 
#    A menu based command for easy version control using 
#    SCCS commands. Gives a better control over commands.
#  Pre-requisite : 
#    1. Set the SCCSDIR in your environment. This will point to the directory 
#       location for sccs files.
#       e.g. export SCCSDIR=$HOME/SCCS   here SCCS is the directory for files. 
#    2. A link 'SCCS' must exit in your working dir, pointing to SCCS dir
#		    e.g. $HOME/<work_dir>/SCCS -> $HOME/SCCS
#    3. create a backup directory 'bak' in working directory e.g
#			$HOME/<work_dir>/bak
#


checkSCCS()
{
   if [ -z "${SCCSDIR}" ]
   then
      echo "Env variable SCCSDIR not set\n"
      exit 1
   fi

   if [ ! -d ${SCCSDIR} ]   
   then
     echo "${SCCSDIR} directory doesn't exists\n"
     exit 1
   fi
}

showMenu()
{
echo "------------------------------------------------------------------------"
echo "SCCS - utility					$(date)"
echo "SCCS history files location: ${SCCSDIR}" 
echo "Username: ${LOGNAME}" 
echo "Logfile: ${LOGFILE}" 
echo "------------------------------------------------------------------------"
echo " 1) Place file(s) under SCCS control."
echo " 2) Checking Out a file(s) for editing."
echo " 3) Checking in a New Version."
echo " 4) Retrieving a Version (read-only)."
echo " 5) Retrieving a Version by SID."
echo " 6) Determining the most recent Version."
echo " 7) Determining who has a file checked out"
echo " 8) Comparing Checked-In Versions."
#echo "6) Retrieving to an Earlier Version(for back-track)."
echo " 9) Starting a new Release + checked out(editing)."
echo "10) Undo Checkout file(s)."
echo "11) Creating Reports."
#echo "13) Creating a project working directory and a link to SCCS directory."
echo " 0) Exit form SCCS."
echo "------------------------------------------------------------------------"
echo "    Enter your choice : \c"
read ans

x=$(echo $ans|awk ' $0 ~ /[A-Za-z]/ {print 1}')
if [ ${x:=0} -eq 1 ]
then
  echo "Character input not allowed. Choose from 0-11 only.Quiting...!!"
  exit 1
fi
}


# Main
#set -vx

trap "" 1 2 3 5 15

LOGFILE=/tmp/easySCCS.log
echo "Start Time: $(date)" >>${LOGFILE}
checkSCCS
showMenu
while  [ ${ans} -ne 0 ]
do
case ${ans} in
1) echo "Enter your source directory location : \c"
   read src_dir
   src_dir=`eval expr $src_dir`
   if [ -z "${src_dir}" ] || [ ! -d ${src_dir} ]
   then
      echo "${src_dir} doesn't exists or not supplied. Check your source directory\n"
      exit 1
   else
      echo "Source program directory : ${src_dir}" >>${LOGFILE} 2>&1
   fi

   echo "Source file name('ALL' for all files) : \c" 
   read file_name
   if [ ${file_name} != "ALL" ]
   then 
      if [ -L ${src_dir}/${file_name} ] || [ -d ${src_dir}/${file_name} ] 
      then
        echo "Hey!! don't be so smart,${file_name} is not a file.Quiting....."
        exit 1
      else
      echo "placing file ${file_name} under SCCS control....." >>${LOGFILE} 2>&1
      $(cd ${src_dir} ;sccs create ${file_name} >>${LOGFILE} 2>&1)
      if [ $? -ne 0 ]
      then
         echo "Failed....!!!" >>${LOGFILE} 2>&1
	 exit 1
      else 
         echo "Done! file ${file_name} placed under SCCS.\n"
         echo "Done! file ${file_name} placed under SCCS.\n" >>${LOGFILE} 2>&1
         eval mv -f "${src_dir}/?${file_name}" ${src_dir}/bak >>${LOGFILE} 2>&1
      fi
     fi
   fi
   if [ ${file_name} = "ALL" ]
   then
       echo "Enter specific pattern or . for ALL files: \c"
       read patt
       if [ ${patt} = "." ]
       then
          list="${src_dir}"
       else
          list="${src_dir}/${patt}"
       fi 

       echo "Please wait......!!"

       for file in $(ls ${list})
       do
         echo "placing ${file} under SCCS control.....\n" >>${LOGFILE} 2>&1
         file1=`basename $file`
         if [ ! -L ${src_dir}/${file1} ] && [ ! -d ${src_dir}/${file1} ]
         then
         $(cd ${src_dir};sccs create ${src_dir}/${file1} >>${LOGFILE} 2>&1)
         if [ $? -ne 0 ]
         then
            echo "Failed....!!!n" >>${LOGFILE} 2>&1
	    exit 1
         else 
           echo "Done! file ${file} placed under SCCS.\n" >>${LOGFILE} 2>&1
           eval mv -f "${src_dir}/?${file}" ${src_dir}/bak >>${LOGFILE} 2>&1
         fi
        fi
       done
    fi
    ;;
 2) echo "Enter your working directory location : \c"
    read wrk_dir
    wrk_dir=`eval expr $wrk_dir`
    if [ -z "${wrk_dir}" ] || [ ! -d ${wrk_dir} ]
    then
      echo "${wrk_dir} doesn't exists or not supplied. Check your working directory\n"
      exit 1
   else
      echo "Working directory : ${wrk_dir}" >>${LOGFILE} 2>&1
   fi
   echo "Source file name for editing('ALL' for all files) : \c" 
   read file_name
   if [ ${file_name} != "ALL" ]
   then 
      echo "Checking Out file ${file_name} for edit in ${wrk_dir}" >>${LOGFILE} 2>&1
      $(cd ${wrk_dir} ;sccs edit ${file_name} >>${LOGFILE} 2>&1)
      if [ $? -ne 0 ]
      then
         echo "Failed....!!!" >>${LOGFILE} 2>&1
	 exit 1
      else 
         echo "Done! file ${file_name} placed under ${wrk_dir}"
         echo "Done! file ${file_name} placed under ${wrk_dir}">>${LOGFILE} 2>&1
      fi
    fi
   if [ ${file_name} = "ALL" ]
   then
       echo "Enter specific pattern or . for ALL files: \c"
       read patt
       if [ ${patt} = "." ]
       then
          list="${SCCSDIR}"
       else
          list="${SCCSDIR}/?.${patt}"
       fi 

       echo "Please wait......!!"

       for file in $(ls ${list}|sed 's/s\.//')
       do
         echo "Checking Out file ${file} for editing in ${wrk_dir}" >>${LOGFILE} 2>&1
         file1=`basename $file`
         $(cd ${wrk_dir};sccs edit ${file1} >>${LOGFILE} 2>&1)
         if [ $? -ne 0 ]
         then
            echo "Failed....!!!n" >>${LOGFILE} 2>&1
	    exit 1
         else 
           echo "Done! file ${file1} placed under ${wrk_dir} for editing"
           echo "Done! file ${file1} placed under ${wrk_dir} for editing">>${LOGFILE} 2>&1
         fi
       done
    fi
    ;;
 3) echo "Enter your working directory location : \c"
    read wrk_dir
    wrk_dir=`eval expr $wrk_dir`
    if [ -z "${wrk_dir}" ] || [ ! -d ${wrk_dir} ]
    then
      echo "${wrk_dir} doesn't exists or not supplied. Check your working directory\n"
      exit 1
   else
      echo "Working directory : ${wrk_dir}" >>${LOGFILE} 2>&1
   fi
   echo "Source file name for Checking In('ALL' for all files) : \c" 
   read file_name
   if [ ${file_name} != "ALL" ]
   then 
      echo "Checking In file ${file_name} under SCCS. No comment supplied" >>${LOGFILE} 2>&1
      $(cd ${wrk_dir} ;sccs delta -y"" ${file_name} >>${LOGFILE} 2>&1)
      if [ $? -ne 0 ]
      then
         echo "Failed....!!! See the file is actually chkout."
	 exit 1
      else 
         echo "Done! file ${file_name} placed under SCCS"
         echo "Done! file ${file_name} placed under SCCS">>${LOGFILE} 2>&1
      fi
    fi
   if [ ${file_name} = "ALL" ]
   then
       echo "Enter specific pattern or . for ALL files: \c"
       read patt
       if [ ${patt} = "." ]
       then
          list="${wrk_dir}"
       else
          list="${wrk_dir}/${patt}"
       fi 
       echo "Please wait......!!"

       for file in $(ls ${list})
       do
         file1=`basename $file`
         if [ ! -L ${file1} ] && [ ! -d ${file1} ]
         then
         echo "Checking In file ${file1} under SCCS. No comment supplied" >>${LOGFILE} 2>&1
         $(cd ${wrk_dir};sccs delta -y"" ${file1} >>${LOGFILE} 2>&1)
         if [ $? -ne 0 ]
         then
            echo "Failed....!!!n" >>${LOGFILE} 2>&1
	    exit 1
         else 
           echo "Done! file ${file1} Checked In under SCCS"
           echo "Done! file ${file1} Checked In under SCCS">>${LOGFILE} 2>&1
         fi
       fi
     done
    fi
    ;;
 4) echo "Note: Do not change this copy of the file, since SCCS dones not"
    echo "      create a new delta unless the file has been checked out."
    echo "      The file permission mask will be -r--r--r--"
    echo "Enter your working directory location : \c"
    read wrk_dir
    wrk_dir=`eval expr $wrk_dir`
    if [ -z "${wrk_dir}" ] || [ ! -d ${wrk_dir} ]
    then
      echo "${wrk_dir} doesn't exists or not supplied. Check your working directory\n"
      exit 1
   else
      echo "Working directory : ${wrk_dir}" >>${LOGFILE} 2>&1
   fi
   echo "Source file name for editing('ALL' for all files) : \c" 
   read file_name
   if [ ${file_name} != "ALL" ]
   then 
      echo "Reteriving file ${file_name} (read-only) in ${wrk_dir}" >>${LOGFILE} 2>&1
      $(cd ${wrk_dir} ;sccs get ${file_name} >>${LOGFILE} 2>&1)
      if [ $? -ne 0 ]
      then
         echo "Failed....!!!" >>${LOGFILE} 2>&1
	 exit 1
      else 
         echo "Done! file ${file_name} reterived under ${wrk_dir}"
         echo "Done! file ${file_name} reterived under ${wrk_dir}">>${LOGFILE} 2>&1
      fi
    fi
   if [ ${file_name} = "ALL" ]
   then
       echo "Enter specific pattern or . for ALL files: \c"
       read patt
       if [ ${patt} = "." ]
       then
          list="${SCCSDIR}"
       else
          list="${SCCSDIR}/?.${patt}"
       fi 

       echo "Please wait......!!"

       for file in $(ls ${list}|sed 's/s\.//')
       do
         echo "Reteriving file ${file} (read-only) in ${wrk_dir}" >>${LOGFILE} 2>&1
         file1=`basename $file`
         $(cd ${wrk_dir};sccs get ${file1} >>${LOGFILE} 2>&1)
         if [ $? -ne 0 ]
         then
            echo "Failed....!!!n" >>${LOGFILE} 2>&1
	    exit 1
         else 
           echo "Done! file ${file1} reterived under ${wrk_dir} for editing"
           echo "Done! file ${file1} reterived under ${wrk_dir} for editing">>${LOGFILE} 2>&1
         fi
       done
    fi
    ;;
 5) echo "Enter your working directory location : \c"
    read wrk_dir
    wrk_dir=`eval expr $wrk_dir`
    if [ -z "${wrk_dir}" ] || [ ! -d ${wrk_dir} ]
    then
      echo "${wrk_dir} doesn't exists or not supplied. Check your working directory\n"
      exit 1
   else
      echo "Working directory : ${wrk_dir}" >>${LOGFILE} 2>&1
   fi
   echo "Source file name (read-only): \c" 
   read file_name
   echo "Release Version number (SID) of file: \c" 
   read sid
   echo "Reteriving a version-${sid} of file ${file_name}" >>${LOGFILE} 2>&1
      $(cd ${wrk_dir} ;sccs get -r${sid} ${file_name} >>${LOGFILE} 2>&1)
      if [ $? -ne 0 ]
      then
         echo "Failed....!!! Check the SID" >>${LOGFILE} 2>&1
         echo "Failed....!!! Check the SID"
	 exit 1
      else 
         echo "Done! file ${file_name} reterived under ${wrk_dir}"
         echo "Done! file ${file_name} reterived under ${wrk_dir}">>${LOGFILE} 2>&1
      fi
    ;;
 6) echo "Enter your working directory location : \c"
    read wrk_dir
    wrk_dir=`eval expr $wrk_dir`
    wrk_dir=`eval expr $wrk_dir`
    if [ -z "${wrk_dir}" ] || [ ! -d ${wrk_dir} ]
    then
      echo "${wrk_dir} doesn't exists or not supplied. Check your working directory\n"
      exit 1
   else
      echo "Working directory : ${wrk_dir}" >>${LOGFILE} 2>&1
   fi
   echo "Source file name: \c" 
   read file_name
   rect=$(cd ${wrk_dir} ;sccs get -g ${file_name})
   echo "The most recent Version : ${rect}" 
   echo "The most recent Version : ${rect}"  >>${LOGFILE} 2>&1
    ;;
 7) echo "Enter your working directory location : \c"
    read wrk_dir
    wrk_dir=`eval expr $wrk_dir`
    if [ -z "${wrk_dir}" ] || [ ! -d ${wrk_dir} ]
    then
      echo "${wrk_dir} doesn't exists or not supplied. Check your working directory\n"
      exit 1
   else
      echo "Working directory : ${wrk_dir}" >>${LOGFILE} 2>&1
   fi
   status=$(cd ${wrk_dir} ;sccs check)
   if [ -z "${status}" ]
   then
      echo "Nothing is being edited" 
   else
     cd ${wrk_dir}
     sccs info
   fi
   ;;
 8) echo "Enter your working directory location : \c"
    read wrk_dir
    wrk_dir=`eval expr $wrk_dir`
    if [ -z "${wrk_dir}" ] || [ ! -d ${wrk_dir} ]
    then
      echo "${wrk_dir} doesn't exists or not supplied. Check your working directory\n"
      exit 1
   else
      echo "Working directory : ${wrk_dir}" >>${LOGFILE} 2>&1
   fi
   echo "Source file name (read-only): \c" 
   read file_name
   echo "First Release Version number(SID): \c" 
   read sid1
   echo "Second Release Version number(SID): \c" 
   read sid2
   DIFILE=/tmp/${file_name}_${sid1}_${sid2}.diff
   echo "Comparing Checked In versions ${sid1} and ${sid2} of file ${file_name}. For output check the ${DIFILE}" >>${LOGFILE} 2>&1
   #$(cd ${wrk_dir} ;sccs sccsdiff -r${sid1} -r${sid2} ${file_name})
   cd ${wrk_dir}
   sccs sccsdiff -r${sid1} -r${sid2} ${file_name} >>${DIFILE} 2>&1
   ;;
 9) echo "Enter your working directory location : \c"
    read wrk_dir
    wrk_dir=`eval expr $wrk_dir`
    if [ -z "${wrk_dir}" ] || [ ! -d ${wrk_dir} ]
    then
      echo "${wrk_dir} doesn't exists or not supplied. Check your working directory\n"
      exit 1
   else
      echo "Working directory : ${wrk_dir}" >>${LOGFILE} 2>&1
   fi
   echo "Source file name for editing('ALL' for all files) : \c" 
   read file_name
   echo "New Release number(SID): \c" 
   read sid
   if [ ${file_name} != "ALL" ]
   then 
      echo "Checking Out file ${file_name} with new release ${sid} for editing in ${wrk_dir}" >>${LOGFILE} 2>&1
      $(cd ${wrk_dir} ;sccs edit -r${sid} ${file_name} >>${LOGFILE} 2>&1)
      if [ $? -ne 0 ]
      then
         echo "Failed....!!!" >>${LOGFILE} 2>&1
	 exit 1
      else 
         echo "Done! file ${file_name} checked out with new release"
         echo "Done! file ${file_name} checked out with new release">>${LOGFILE} 2>&1
      fi
    fi
   if [ ${file_name} = "ALL" ]
   then
    echo "Please wait......!!"
    echo "Checking Out file ${file} with new release in ${wrk_dir}" >>${LOGFILE} 2>&1
    $(cd ${wrk_dir};sccs edit -r${sid} SCCS >>${LOGFILE} 2>&1)
    if [ $? -ne 0 ]
    then
      echo "Failed....!!!n" >>${LOGFILE} 2>&1
      exit 1
    else 
      echo "Done! file ${file1} checked out with new release"
      echo "Done! file ${file1} checked out with new release">>${LOGFILE} 2>&1
     fi
  fi
    ;;
 10) echo "Enter your working directory location : \c"
    read wrk_dir
    wrk_dir=`eval expr $wrk_dir`
    if [ -z "${wrk_dir}" ] || [ ! -d ${wrk_dir} ]
    then
      echo "${wrk_dir} doesn't exists or not supplied. Check your working directory\n"
      exit 1
   else
      echo "Working directory : ${wrk_dir}" >>${LOGFILE} 2>&1
   fi
   echo "Source file name for editing('ALL' for all files) : \c" 
   read file_name
   if [ ${file_name} != "ALL" ]
   then 
      echo "Undo Checked out file ${file_name}" >>${LOGFILE} 2>&1
      $(cd ${wrk_dir} ;sccs unedit ${file_name} >>${LOGFILE} 2>&1)
      if [ $? -ne 0 ]
      then
         echo "Failed....!!!" >>${LOGFILE} 2>&1
	 exit 1
      else 
         echo "Done! undo checked out file ${file_name}"
         echo "Done! undo checked out file ${file_name}">>${LOGFILE} 2>&1
      fi
    fi
   if [ ${file_name} = "ALL" ]
   then
    echo "Please wait......!!"
    echo "Doing undo checked Out files" >>${LOGFILE} 2>&1
    $(cd ${wrk_dir};sccs unedit * >>${LOGFILE} 2>&1)
    if [ $? -ne 0 ]
    then
      echo "Failed....!!!n" >>${LOGFILE} 2>&1
      exit 1
    else 
      echo "Done! undo checked out files"
      echo "Done! undo checked out files">>${LOGFILE} 2>&1
     fi
  fi
    ;;
 11) echo "Enter your working directory location : \c"
    read wrk_dir
    wrk_dir=`eval expr $wrk_dir`
 
    if [ -z "${wrk_dir}" ] || [ ! -d ${wrk_dir} ]
    then
      echo "${wrk_dir} doesn't exists or not supplied. Check your working directory\n"
      exit 1
   else
      echo "Working directory : ${wrk_dir}" >>${LOGFILE} 2>&1
   fi
   echo "Source file name for editing('ALL' for all files) : \c" 
   read file_name
   if [ ${file_name} != "ALL" ]
   then 
      echo "Creating reports of file ${file_name}" 
      $(cd ${wrk_dir} ;sccs prs ${file_name} >>${LOGFILE} 2>&1)
      if [ $? -ne 0 ]
      then
         echo "Failed....!!!" >>${LOGFILE} 2>&1
	 exit 1
      else 
         echo "Done! Report generated for file ${file_name}"
         echo "Done! Report generated for file ${file_name}">>${LOGFILE} 2>&1
      fi
    fi
   if [ ${file_name} = "ALL" ]
   then
    echo "Please wait......!!"
    echo "Creating reports for the SCCS directory" >>${LOGFILE} 2>&1
    $(cd ${wrk_dir};sccs prs SCCS >>${LOGFILE} 2>&1)
    if [ $? -ne 0 ]
    then
      echo "Failed....!!!n" >>${LOGFILE} 2>&1
      exit 1
    else 
      echo "Done! Report generated for SCCS directory"
      echo "Done! Report generated for SCCS directory">>${LOGFILE} 2>&1
     fi
  fi
    ;;
 0) exit ;; 
 *) echo "Invalid choice.Choose from 0-11 only." ;;
 #   exit 1 ;;
 esac
showMenu
done
echo "Finished Time: $(date)" >>${LOGFILE}
