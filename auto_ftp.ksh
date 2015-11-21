#!/bin/sh

### Sample Script and Method for FTP files from one 
### Machine/Host to another Machine.
###
### If you want to ftp few file from
### Host-A (location /b002/org_files/)
### to Host-B (location /u001/b_loc),
### here is the script and methods.
###
### 1) Login into Host-B
### 2) cd /u001/b_loc
### 3) Then run the following FTP scripts as follows
###    # auto_ftp.ksh > auto_ftp.lst &
###
###
ftp  -n	 host-A.com << !EOF
user unix-username  password
cd  /b002/org_files
prompt
bin

mget filename1
mget filename2
mget filename3



quit
!EOF


 


##############################################################################
### This script is submitted to BigAdmin by a user of the BigAdmin community.
### Sun Microsystems, Inc. is not responsible for the
### contents or the code enclosed. 
###
###
### Copyright 2008 Sun Microsystems, Inc. ALL RIGHTS RESERVED
### Use of this software is authorized pursuant to the
### terms of the license found at
### http://www.sun.com/bigadmin/common/berkeley_license.html
##############################################################################


