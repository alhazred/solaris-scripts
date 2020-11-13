#!/usr/bin/ksh
BASEDIR="/develop/packages"

PACKAGE=$1
PACKAGE_VERSION=$2

if [ "${PACKAGE}"x = ""x ] ; then
  echo "Usage: ` basename $0` name_of_the package [version {def. 1.0.0.0}]"
  exit 1
fi

[ "${PACKAGE_VERSION}"x = ""x ] && PACKAGE_VERSION="1.0.0.0"

PACKAGE_DIR="${BASEDIR}/${PACKAGE}/${PACKAGE_VERSION}"

echo "Creating the directory structure for ${PACKAGE} version ${PACKAGE_VERSION}"
echo "The target directory is \"${PACKAGE_DIR}\" "

if [ -d  ${PACKAGE_DIR} ] ; then
  echo "ERROR: The package ${PACKAGE} already exists!"
  exit 2
fi
  
echo "Creating the directories for the new package ${PACKAGE} ..."
mkdir -p ${PACKAGE_DIR}
mkdir -p ${PACKAGE_DIR}/root
mkdir -p ${PACKAGE_DIR}/scripts

cat <<EOT >>${PACKAGE_DIR}/pkgproto.template
i pkginfo=pkginfo
EOT

cat <<EOT >>${PACKAGE_DIR}/pkginfo
VERSION=${PACKAGE_VERSION}
PKG=${PACKAGE}
NAME=descrition missing yet
ARCH=sparc
CLASSES=none
CATEGORY=application
VENDOR=Sun
ISTATES=S s 1 2 3
RSTATES=S s 1 2 3..
BASEDIR=/

EOT

[ ! -L ${PACKAGE_DIR}/../create_package.sh ] && ln -s ../create_package.sh ${PACKAGE_DIR}/../create_package.sh

cp ${PACKAGE_DIR}/../../pkgtemplate.sh ${PACKAGE_DIR}/scripts

echo " ... done."
