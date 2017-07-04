#! /bin/sh
WORKDIR=$(pwd)
ROOTFSFILE="rootfs"
ROOTFS="ext3"
ROOTFSSIZE="102400" #100Mb
VERKERNEL="linux-4.11.7.tar.xz"
VERBUSYBOX="busybox-1.26.2.tar.bz2"
VERSYSLINUX="syslinux-6.03.zip"

# echo "$WORKDIR"

######################   Компиляция ядра   ######################
#cp "$WORKDIR/config/kernel.config" "$WORKDIR/src/$VERBUSYBOX"

echo $KERNELPATH
#sudo make bzImage
#sudo make modules
#sudo make INSTALL_MOD_PATH=$PWD/_pkg modules_install

