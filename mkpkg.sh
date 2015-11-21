#!/bin/sh 
# mkpkg.sh : Created 05-26-04 (c) Bryan Johnson
# 
# This script will make a standard Solaris package
# from an installation tree.
# 
# To use this script you must install your compiled
# source in a staging directory. 

_getstagedir(){
echo "Stage directory where package is installed: \c"
read STAGE_DIR
if [ "$STAGE_DIR" = "" ]
then
   echo "\nYou must enter a location of your package source"
   _getstagedir
fi
if [ ! -d "$STAGE_DIR" ]
then
   echo "\nThe directory $STAGE_DIR does not exist"
   _getstagedir
fi
return
}

_getpkgname(){
echo "Package name (i.e. SUNWpkg): \c"
read PKGNAME
if [ "$PKGNAME" = "" ]
then
   echo "\nYou must enter a package name"
   _getpkgname
fi
return
}

_getpkgdesc(){
echo "Package description (max 255 chars): \c"
read NAME 
if [ "$NAME" = "" ]
then
   echo "\nYou must enter a description"
   _getpkgdesc
fi
return
}

_getpkgver(){
echo "Package version: \c"
read VERSION
if [ "$VERSION" = "" ]
then
   echo "\nYou must enter a package version"
   _getpkgver
fi
return
}

_getpkgcat(){
echo "Package category [default=application]: \c"
read CATEGORY
if [ "$CATEGORY" = "" ]
then
   CATEGORY=application
fi
}

_getrootdir(){
echo "Root directory where package will install to [default=/usr/local]: \c"
read ROOT_DIR
if [ "$ROOT_DIR" = "" ]
then
   ROOT_DIR=/usr/local
fi
}

_getsavepkgdir(){
echo "Place to save finished package file [default=`pwd`]: \c"
read PKGDIR
if [ "$PKGDIR" = "" ]
then
   PKGDIR="`pwd`"
fi
if [ ! -d "$PKGDIR" ]
then
   echo "\nThe directory $PKGDIR does not exist"
   _getsavepkgdir
fi
return
}

_confirmvars(){
echo "\nYou entered the following information:\n"
echo "1) STAGE_DIR = $STAGE_DIR"
echo "2) PKGNAME = $PKGNAME"
echo "3) NAME = $NAME"
echo "4) VERSION= $VERSION"
echo "5) CATEGORY = $CATEGORY"
echo "6) ROOT_DIR = $ROOT_DIR"
echo "7) PKGDIR = $PKGDIR"
echo "\nIs this correct [y|n default=y]: \c"
read YN
if [ "$YN" = "n" ]; then
    echo "Which variable do you want to change [1-7, q to quit]: \c"
    read PKGVAR
    case $PKGVAR in
         1) 
            _getstagedir
            _confirmvars
            return
            ;;
         2)
            _getpkgname
            _confirmvars
            return
            ;;
         3)
            _getpkgdesc
            _confirmvars
            return
            ;;
         4)
            _getpkgver
            _confirmvars
            return
            ;;
         5)
            _getpkgcat
            _confirmvars
            return
            ;;
         6) 
            _getrootdir
            _confirmvars
            return
            ;;
         7) 
            _getsavepkgdir
            _confirmvars
            return
            ;;
      [qQ])
            exit 0
            ;;
         *)
            return
            ;;
    esac
else
    _mkpkg
    _renamepkg
fi
}

_mkpkg(){
echo "Creating pkginfo file ...\c"
echo "PKG=$PKGNAME" > pkginfo
echo "NAME=$NAME" >> pkginfo
echo "VERSION=$VERSION" >> pkginfo
echo "CATEGORY=$CATEGORY" >> pkginfo
echo "done"
echo "Creating prototype file ...\c"
(echo 'i pkginfo'; pkgproto ${STAGE_DIR}=${ROOT_DIR})>prototype
echo "done"
echo "Making package ...\c"
pkgmk -o
echo "done"
echo "Transferring package ...\c"
pkgtrans -s /var/spool/pkg ${PKGDIR}/${PKGNAME}.pkg $PKGNAME
echo "done"
}

_renamepkg(){
echo "The package file ${PKGDIR}/${PKGNAME}.pkg has been created."
echo "Do you want to rename this package file [y|n default=y]? \c"
read RENYN
if [ "$RENYN" = "n" ]
then
   exit 0
else
   echo "Enter new name for the package: \c"
   read NEWNAME
   while [ "$NEWNAME" = "" ]
   do 
      echo "You must enter a new name for this package [q to quit]: \c"
      read NEWNAME
      if [ "$NEWNAME" = "q" ]
      then
           exit 0
      fi
   done
   mv ${PKGDIR}/${PKGNAME}.pkg $NEWNAME
fi
}

_getstagedir
_getpkgname
_getpkgdesc
_getpkgver
_getpkgcat
_getrootdir
_getsavepkgdir
_confirmvars










##############################################################################
### This script is submitted to BigAdmin by a user of the BigAdmin community.
### Sun Microsystems, Inc. is not responsible for the
### contents or the code enclosed. 
###
###
### Copyright 2007 Sun Microsystems, Inc. ALL RIGHTS RESERVED
### Use of this software is authorized pursuant to the
### terms of the license found at
### http://www.sun.com/bigadmin/common/berkeley_license.html
##############################################################################


