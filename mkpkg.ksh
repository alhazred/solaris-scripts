#******* mkpkg.sh *************
#  mkpkg.sh - ksh script for 
#  making siple packages
#******************************
#!/bin/ksh
pkg="`pwd | sed '{ s/.*\///
		  s/-.*//
		}'`"
echo Package [$pkg]:"\c"
read s
[ -n "$s" ] && pkg="$s"

name="$pkg"
echo Package name [$name]:"\c"
read s
[ -n "$s" ] && name="$s"

arch="sparc"
echo Architecture [$arch]:"\c"
read s
[ -n "$s" ] && arch="$s"

version="`pwd | sed '{ s/.*\///
		  s/.*-//
		}'`"
echo Version [$version]:"\c"
read s
[ -n "$s" ] && version="$s"

basedir="/usr/local"
echo Base directory [$basedir]:"\c"
read s
[ -n "$s" ] && basedir="$s"

category="application"
echo Category [$category]:"\c"
read s
[ -n "$s" ] && category="$s"

vendor="Your company"
echo Vendor [$vendor]:"\c"
read s
[ -n "$s" ] && vendor="$s"

classes="none"
echo Classes [$classes]:"\c"
read s
[ -n "$s" ] && classes="$s"

hotline="Your contact info"
echo Hotline [$hotline]:"\c"
read s
[ -n "$s" ] && hotline="$s"

(
  echo PKG="${pkg}"
  echo NAME="${name}"
  echo ARCH="${arch}"
  echo VERSION="${version}"
  echo BASEDIR="${basedir}"
  echo CATEGORY="${category}"
  echo VENDOR="${vendor}"
  echo CLASSES="${classes}"
  echo HOTLINE="${hotline}"
) > pkginfo

( 
  ID=`/usr/bin/id|awk -F\( '{print $2}'|awk -F\) '{print $1}'`
  GID=`/usr/bin/id|awk -F\( '{print $3}'|awk -F\) '{print $1}'`
  echo i pkginfo
  pkgproto -c none .=. | sed "{ s/$ID/root/g
  				s/$GID/other/g
  			      }" | 
    egrep -v "prototype=prototype|pkginfo=pkginfo"
) > prototype
pkgmk -d .
