#!/usr/bin/ksh

TMPFILE=/tmp/` basename $0`.$$

CURDIR=`pwd`
VERSION=` basename ${CURDIR}` 
DUMMY=` dirname ${CURDIR}` 
PACKAGE=` basename ${DUMMY} ` 

PACKAGE_FILE="${CURDIR}/../${PACKAGE}_v${VERSION}.pkg"


die() {
  typeset THISRC=$1
  shift
  echo $*
  exit ${THISRC}
}


echo "Creating the package \"${PACKAGE}\" version \"${VERSION}\" ..."

[ ! -f ./pkginfo ] && die 2 "./pkginfo file missing"
[ ! -f ./pkgproto.template ] && die 2 "./pkgproto.template file missing"

echo "Changing the version info in the ./pkginfo file ..."
grep -v "^VERSION=" ./pkginfo >${TMPFILE}
echo "VERSION=${VERSION}" >./pkginfo
cat ${TMPFILE} >>./pkginfo
rm ${TMPFILE}

echo "Creating the pkgproto file ..."
cp pkgproto.template ./pkgproto
[ $? -ne 0 ]  && die 1 "Error creating the pkgproto file"

( cd root ; pkgproto . >>../pkgproto )
[ $? -ne 0 ]  && die 2 "Error creating the pkgproto file"

echo "Creating the package ..."
pkgmk -o -r ./root -f pkgproto ${PACKAGE}
[ $? -ne 0 ]  && die 1 "Error creating the package"

echo "Transfering the package into file format ..."
pkgtrans /var/spool/pkg ${PACKAGE_FILE} ${PACKAGE}
[ $? -ne 0 ]  && die 1 "Error tranfering the package"

echo "Package \"${PACKAGE}\" version \"${VERSION}\" created in the file \"${PACKAGE_FILE}\" ..."
