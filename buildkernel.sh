#! /bin/bash
ROOTDIR=$(pwd)

if [ ! ${1} ]
then
  KERNELDIR=$(pwd)
else 
  KERNELDIR=${1}
fi

cd $KERNELDIR
sudo make bzImage
sudo make modules
sudo make INSTALL_MOD_PATH=$KERNELPATH/_pkg modules_install
