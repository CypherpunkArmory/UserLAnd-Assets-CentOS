#! /bin/bash

export ARCH_DIR=output/${1}
export ROOTFS_DIR=$ARCH_DIR/rootfs

case "$1" in
    arm) export DEBOOTSTRAP_ARCH=armhf
        ;;
    arm64) export DEBOOTSTRAP_ARCH=arm64
        ;;
    x86) export DEBOOTSTRAP_ARCH=i386
        ;;
    x86_64) export DEBOOTSTRAP_ARCH=amd64
        ;;
    all) exit
        ;;
    *) echo "unsupported arch"
        exit
        ;;
esac

rm -rf $ARCH_DIR
mkdir -p $ARCH_DIR
rm -rf $ROOTFS_DIR
mkdir -p $ROOTFS_DIR

# Building Will Go Here

echo "127.0.0.1 localhost" > $ROOTFS_DIR/etc/hosts
echo "nameserver 8.8.8.8" > $ROOTFS_DIR/etc/resolv.conf
echo "nameserver 8.8.4.4" >> $ROOTFS_DIR/etc/resolv.conf

echo "#!/bin/sh" > $ROOTFS_DIR/etc/profile.d/userland.sh
echo "unset LD_PRELOAD" >> $ROOTFS_DIR/etc/profile.d/userland.sh
echo "unset LD_LIBRARY_PATH" >> $ROOTFS_DIR/etc/profile.d/userland.sh
echo "export LIBGL_ALWAYS_SOFTWARE=1" >> $ROOTFS_DIR/etc/profile.d/userland.sh
chmod +x $ROOTFS_DIR/etc/profile.d/userland.sh

# Mirrors Will Go Here (If Needed)

# Shrink Rootfs
cp scripts/shrinkRootfs.sh $ROOTFS_DIR
chmod 777 $ROOTFS_DIR/shrinkRootfs.sh
LC_ALL=C LANGUAGE=C LANG=C chroot $ROOTFS_DIR ./shrinkRootfs.sh
rm $ROOTFS_DIR/shrinkRootfs.sh

tar --exclude='dev/*' -czvf $ARCH_DIR/rootfs.tar.gz -C $ROOTFS_DIR .

LC_ALL=C LANGUAGE=C LANG=C chroot $ROOTFS_DIR yum -y update
LC_ALL=C LANGUAGE=C LANG=C chroot $ROOTFS_DIR yum -y install build-essential

#build disableselinux to go with this release
cp scripts/disableselinux.c $ROOTFS_DIR
LC_ALL=C LANGUAGE=C LANG=C chroot $ROOTFS_DIR gcc -shared -fpic disableselinux.c -o libdisableselinux.so 
cp $ROOTFS_DIR/libdisableselinux.so $ARCH_DIR/libdisableselinux.so

#get busybox to go with the release
LC_ALL=C LANGUAGE=C LANG=C chroot $ROOTFS_DIR yum -y install busybox-static 
cp $ROOTFS_DIR/bin/busybox $ARCH_DIR/busybox
