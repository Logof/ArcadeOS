#! /bin/sh
unzipp () {
    if [ "$1" ] ; then
    case "$1" in
      *.tar.bz2)   tar -xjf "$1" -d "$2"  ;;
      *.tar.gz)    tar -xzf "$1" -d "$2"  ;;
      *.tar.xz)    tar -xJf "$1" -d "$2"  ;;
      *.bz2)       bunzip2 "$1"  -d "$2"   ;;
      *.gz)        gunzip "$1"  -d "$2"    ;;
      *.tar)       tar -xf "$1"  -d "$2"   ;;
      *.tbz2)      tar -xjf "$1"  -d "$2"  ;;
      *.tgz)       tar -xzf "$1"  -d "$2" ;;
      *.ZIP|*.zip)       unzip "$1"  -d "$2"     ;;
      *.xz)        unxz "$1"  -d "$2"     ;;
    esac
    else
      echo "Применение: unpack имя_архива"
    fi
    exit  0
}

WORKDIR=$(pwd)
ROOTFSFILE="rootfs"
ROOTFS="ext3"
ROOTFSSIZE="102400" #100Mb
VERKERNEL="linux-4.11.7.tar.xz"
VERBUSYBOX="busybox-1.26.2.tar.bz2"
VERSYSLINUX="syslinux-6.03.zip"

# echo "$WORKDIR"
mkdir -p "$WORKDIR/config"
mkdir -p "$WORKDIR/src"
# downloading source code
if [ ! -f "$WORKDIR/src/$VERKERNEL" ]; then
    wget -P "$WORKDIR/src" https://www.kernel.org/pub/linux/kernel/v4.x/"$VERKERNEL"
    tar -xJf "$WORKDIR/src/$VERKERNEL" -C "$WORKDIR/src"
#else
#    tar -xJf "$WORKDIR/src/$VERKERNEL" -C "$WORKDIR/src"
fi

if [ ! -f "$WORKDIR/src/$VERBUSYBOX" ]; then
    wget -P "$WORKDIR/src" http://busybox.net/downloads/"$VERBUSYBOX" 
    tar -xjf "$WORKDIR/src/$VERBUSYBOX" -C "$WORKDIR/src"
#else
#    tar -xjf "$WORKDIR/src/$VERBUSYBOX" -C "$WORKDIR/src"
fi

if [ ! -f "$WORKDIR/src/$VERSYSLINUX" ]; then
    wget -P "$WORKDIR/src" https://www.kernel.org/pub/linux/utils/boot/syslinux/"$VERSYSLINUX"
    mkdir -p "$WORKDIR/src/syslinux"
    unzip "$WORKDIR/src/$VERSYSLINUX" -d "$WORKDIR/src/syslinux"
#else
#    mkdir -p "$WORKDIR/src/syslinux"
#    unzip "$WORKDIR/src/$VERSYSLINUX" -d "$WORKDIR/src/syslinux"
fi

mkdir -p "$WORKDIR/rootfs"
mkdir -p "$WORKDIR/rootcd"

# create file rootfs
sudo dd if=/dev/zero of="$ROOTFSFILE.$ROOTFS" bs=1k count=$ROOTFSSIZE
sudo mkfs -t "$ROOTFS" -F -m 0 "$ROOTFSFILE.$ROOTFS"
#sudo mount -o loop "$ROOTFSFILE.$ROOTFS" "$WORKDIR/rootfs"


######################   Компиляция ядра   ######################
#cp "$WORKDIR/config/kernel.config" "$WORKDIR/src/$VERBUSYBOX"
KERNELPATH=$(ls -d "$WORKDIR"/src/*/ | grep /linux)
cd "$KERNELPATH"
#sudo make bzImage
#sudo make modules
#sudo make INSTALL_MOD_PATH=$KERNELPATH/_pkg modules_install
cd "$WORKDIR"
###################### Компиляция  Busybox ######################
BUSYPATH=$(ls -d "$WORKDIR"/src/*/ | grep /busybox)
cd "$BUSYPATH"
sudo make
sudo make install
chmod 4755 _install/bin/busybox
cp -a _install/* "$WORKDIR/rootfs"
rm "$WORKDIR/rootfs/linuxrc"
ln -s "$WORKDIR/rootfs/linuxrc/bin/busybox" "$WORKDIR/rootfs/init"
cd "$WORKDIR/rootfs"

###### создаем lib
mkdir -p "$WORKDIR/rootfs/lib"

cp /lib32/libcrypt.so.1 "$WORKDIR/rootfs/lib"
cp /lib32/libm.so.6 "$WORKDIR/rootfs/lib"
cp /lib32/libc.so.6 "$WORKDIR/rootfs/lib"
cp /lib32/ld-linux.so.2 "$WORKDIR/rootfs/lib"

strip -v "$WORKDIR"/rootfs/lib/*


################# файловая структура
mkdir -p "$WORKDIR"/rootfs/dev "$WORKDIR"/rootfs/etc "$WORKDIR"/rootfs/root "$WORKDIR"/rootfs/home "$WORKDIR"/rootfs/proc "$WORKDIR"/rootfs/media "$WORKDIR"/rootfs/mnt "$WORKDIR"/rootfs/sys "$WORKDIR"/rootfs/tmp "$WORKDIR"/rootfs/var

mkdir -p "$WORKDIR"/rootfs/usr/usr/lib
mkdir -p "$WORKDIR"/rootfs/usr/usr/local
mkdir -p "$WORKDIR"/rootfs/usr/usr/games
mkdir -p "$WORKDIR"/rootfs/usr/usr/share
mkdir -p "$WORKDIR"/rootfs/var/cache
mkdir -p "$WORKDIR"/rootfs/var/lib
mkdir -p "$WORKDIR"/rootfs/var/lock
mkdir -p "$WORKDIR"/rootfs/var/log
mkdir -p "$WORKDIR"/rootfs/var/games
mkdir -p "$WORKDIR"/rootfs/var/run
mkdir -p "$WORKDIR"/rootfs/var/spool
mkdir -p "$WORKDIR"/rootfs/media/cdrom
mkdir -p "$WORKDIR"/rootfs/media/flash
mkdir -p "$WORKDIR"/rootfs/media/usbdisk
chmod 1777 "$WORKDIR"/rootfs/tmp


touch "$WORKDIR"/rootfs/etc/ld.so.conf
cp /etc/rpc "$WORKDIR"/rootfs/etc

###################### Create the devices in /dev
cp "$BUSYPATH"/examples/bootfloppy/mkdevs.sh "$WORKDIR"/rootfs/bin
"$WORKDIR"/rootfs/bin/mkdevs.sh "$WORKDIR"/rootfs/dev
mkdir -p "$WORKDIR"/rootfs/dev/pts
mkdir -p "$WORKDIR"/rootfs/dev/input
mkdir -p "$WORKDIR"/rootfs/dev/shm
mkdir -p "$WORKDIR"/rootfs/dev/net
mkdir -p "$WORKDIR"/rootfs/dev/usb


cp /lib32/libnss_dns.so.2 "$WORKDIR"/rootfs/lib
cp /lib32/libnss_files.so.2  "$WORKDIR"/rootfs/lib
cp /lib32/libresolv.so.2  "$WORKDIR"/rootfs/lib
strip -v  "$WORKDIR"/rootfs/lib/*.so*

echo "127.0.0.1      localhost" > "$WORKDIR"/rootfs/etc/hosts
echo "localnet    127.0.0.1" > "$WORKDIR"/rootfs/etc/networks
echo "slitaz" > "$WORKDIR"/rootfs/etc/hostname
echo "order hosts,bind" > "$WORKDIR"/rootfs/etc/host.conf
echo "multi on" >> "$WORKDIR"/rootfs/etc/host.conf

cp "$WORKDIR"/config/nsswitch.conf "$WORKDIR"/rootfs/etc/
cp "$WORKDIR"/config/securetty "$WORKDIR"/rootfs/etc/
cp "$WORKDIR"/config/shells "$WORKDIR"/rootfs/etc/

################/etc/issue and /etc/motd
echo "SliTaz GNU/Linux 1.0 Kernel \r \l" > "$WORKDIR"/rootfs/etc/issue
echo "" >> "$WORKDIR"/rootfs/etc/issue
cp "$WORKDIR"/config/motd "$WORKDIR"/rootfs/etc/

############### /etc/busybox.conf
cp "$WORKDIR"/config/busybox.conf "$WORKDIR"/rootfs/etc/
chmod 600 "$WORKDIR"/rootfs/etc/busybox.conf

############### /etc/inittab
cp "$WORKDIR"/config/inittab "$WORKDIR"/rootfs/etc/

############### /etc/profile
cp "$WORKDIR"/config/profile "$WORKDIR"/rootfs/etc/

############### Users, groups and passwords
sudo echo "root:x:0:0:root:/root:/bin/sh" > "$WORKDIR"/rootfs/etc/passwd
sudo echo "root::13525:0:99999:7:::" > "$WORKDIR"/rootfs/etc/shadow
sudo echo "root:x:0:" > "$WORKDIR"/rootfs/etc/group
sudo echo "root:*::" > "$WORKDIR"/rootfs/etc/gshadow
sudo chmod 640 "$WORKDIR"/rootfs/etc/shadow
sudo chmod 640 "$WORKDIR"/rootfs/etc/gshadow


############### /etc/fstab or /etc/mtab
cp "$WORKDIR"/config/fstab "$WORKDIR"/rootfs/etc/


###################### Компиляция Syslinux ######################
SYSLPATH=$(ls -d "$WORKDIR"/src/*/ | grep /syslinux)
cd "$SYSLPATH"
#sudo make bzImage
#sudo make modules
#sudo make INSTALL_MOD_PATH=$PWD/_pkg modules_install
cd "$WORKDIR"


#sudo umount rootfs
