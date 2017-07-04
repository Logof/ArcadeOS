#! /bin/sh
if [ ! ${1} ]
then
  DIR=$(pwd)
else 
  DIR=${1}
fi

cd $DIR
rm -Rf ./*
mkdir -p dev etc root home proc media mnt sys tmp var
mkdir -p usr/lib usr/local usr/games usr/share var/cache var/lib var/lock var/log var/games var/run var/spool media/cdrom media/flash media/usbdisk
chmod 1777 tmp
