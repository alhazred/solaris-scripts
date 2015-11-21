#!/bin/ksh
#
# ==============================================================================
#  Filename : loc
#  Function:
#  This script is a handy command to get the total comment lines 
#  out of the source code. This script works for following type 
#  of comments only:
#                   Type		Description
#		     C			  C language type comments
#		     CPP		  C ++ type comments
#		     SHELL		  Unix Shell script comments
#	Exp: 	loc C hello.c
#		loc CPP hello.cpp
#		loc SHELL findAworld.ksh
# ==============================================================================
# Submitter : arjun.singh@hpsglobal.com
# ==============================================================================
#
#
# Tested on AIX 4.3. Some adjustments may be needed for your flavor of Unix.
#


#set -vx

USAGE="Usage:$0 <comment type {C|CPP|SHELL}> <Source program name>"

if [ $# -lt 2 ]
then
   echo ${USAGE}
   exit 1
fi

TIME=$(date)
awk -v type=$1 '
BEGIN { 
loc=0;
comment_line=0;
total_line=0;
stflag="F";
}
{
total_line++
if ( type == "C" )
{
if ( $0 ~ /^[ \t]*\/\*/ )
{
  stflag="T"
  if ( $0 ~ /\*\/$/ )
  {
  # print "comment line : ", $0
    comment_line++
    stflag="F"
  }
}
if ( stflag == "T" )
{
  comment_line++ 
# print "comment line : ", $0
  if ( $0 ~ /\*\/$/ )
  {
#   print "comment line : ", $0
    stflag="F"
  }
}
}
if ( type == "CPP" )
{
   if ( $0 ~ /^[ \t]*\/\// )
    comment_line++
}
if ( type == "SHELL" )
{
   if ( $0 ~ /^[ \t]*\#/ )
    comment_line++
}
}
END { 
print "Timestamp: ""'"${TIME}"'"
pct=(comment_line*100)/total_line
loc=total_line - comment_line
pct1=(loc*100)/total_line
print "Program statistics  --->"
print "-------------------------------"
print "Source Code Type : ", type 
print "Source Code Program Name : ",  ARGV[1]
print "Total number of lines : ", total_line 
print "Total number of commented lines : ", comment_line ,"("pct"%)" 
print "Total number of lines of code : ",loc, "("pct1"%)"
}
' $2
