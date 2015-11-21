#!/bin/ksh

###=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
### Ed Arizona -001030
### Note:		The delimiter in the "cut" command is a 'tab',
###			not several spaces. If you cut and paste this
###			from your web browser the delimiter must be fixed.
###=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
### Questions or problems?  UnixAdmin@ArizonaEd.com
### Visit the unix archive at http://www.arizonaed.com/unix
### Check out the long list of links, http://www.arizonaed.com/unix/urls.html
###
### I am currently looking for work. I am an experienced Unix Admin
### with considerable knowledge of Networking, Firewalls, and
### Security.  Please contact me for my resume.  Thanks!  -Ed.
###
###=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

mt -f /dev/rmt/0 rewind

for i in `grep -v ^# /etc/vfstab | grep ufs | cut -d"	" -f1`
do
	ufsdump 0fu /dev/rmt/0un $i
done

for i in `grep -v ^# /etc/vfstab | grep vxfs | cut -d"	" -f1`
do
	vxdump 0fu /dev/rmt/0un $i
done
