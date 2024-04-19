# Format and partition the sdcard and copy images to the partition
# This only works for sfdisk v2.5.3
#!/bin/bash

echo "Formatting the SD card"

# check if user is root
# id -u get the id of the user, if root, the id is 0 


if [ "$(id -u)" != "0" ]; then 
    echo "You are not rooted" && exit 1
fi

# Check the first commandline argument using $1, -z check if its empty
if [ -z "$1" ]; then
    echo "No disk device has been specified" && exit 1
elif [ "$1" = "/dev/sda" ]; then
    echo "System disk specified $1" && exit 1
fi

echo "Do you want to format ${1} ? Type Y/y"
read RESPONSE
if [ "$RESPONSE" != "Y" ] && [ "$RESPONSE" != "y" ]; then
    echo "Exiting now" && exit 1
fi

# -b checks if the file exit and is a block device
DEVICE=$1
if [ -b "$DEVICE" ]; then
    dd if=/dev/zero of=$DEVICE bs=1024 count=1024
    SIZE=`fdisk -l $DEVICE | grep Disk | awk '{print $5}'`
    echo "Disk Space - $SIZE bytes"
    CYLINDERS=`echo $SIZE/255/63/512 | bc`
    echo CYLINDERS - $CYLINDERS
    {
        echo ,9,0x0C,*
        echo ,200,0x83,-
        echo ,,0x83,-
    } | sfdisk -H 255 -S 63 -C $CYLINDERS $DEVICE
    if [[ $1 == /dev/sd* ]]; then
        mkfs.vfat -F 32 -n "BOOT" ${DEVICE}1
        mkfs.ext3 -L "ROOT" ${DEVICE}2
    else
        mkfs.vfat -F 32 -n "BOOT" ${DEVICE}p1
        mkfs.ext3 -L "ROOT" ${DEVICE}p2
    fi
else
    echo "$1 device doesn't exit" && exit 1
fi
echo "Done format and partition"

sudo mount /dev/sdb1 /media/$USER/BOOT
sudo mount /dev/sdb2 /media/$USER/ROOT

# Copy images to the partitions
if [ -z "$2" ]; then
    echo "you did not include the yocto_path" && exit 1
fi

YOCTO_PATH=$2
echo $YOCTO_PATH

if [ ! -e "$YOCTO_PATH/tmp/deploy/images/beaglebone-yocto/MLO" ]; then
    echo "MLO does not exit" && exit 1
fi
if [ ! -e "$YOCTO_PATH/tmp/deploy/images/beaglebone-yocto/u-boot.img" ]; then
    echo "uboot does not exit" && exit 1
fi
if [ ! -e "$YOCTO_PATH/tmp/deploy/images/beaglebone-yocto/zImage" ]; then
    echo "zImage does not exit" && exit 1
fi 
if [ ! -e "$YOCTO_PATH/tmp/deploy/images/beaglebone-yocto/am335x-boneblack.dtb" ]; then
    echo "DTB does not exit" && exit 1
fi 
if [ ! -e "$YOCTO_PATH/tmp/deploy/images/beaglebone-yocto/core-image-minimal-beaglebone-yocto.tar.bz2" ]; then
    echo "Rootfs does not exit" && exit 1
fi 

echo "All images exists"

if [ ! -e "/media/$USER/BOOT" ] && [ ! -e "/media/$USER/ROOT" ]; then
    echo "the boot and root path does not exits" && exit 1
fi

cd $YOCTO_PATH/tmp/deploy/images/beaglebone-yocto
sudo cp MLO /media/$USER/BOOT
sudo cp u-boot.img /media/$USER/BOOT
sudo cp zImage /media/$USER/BOOT
sudo cp am335x-boneblack.dtb /media/$USER/BOOT
sudo tar -xf core-image-minimal-beaglebone-yocto.tar.bz2 -C /media/$USER/ROOT
sync