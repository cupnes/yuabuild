#!/bin/bash

set -uex

if [ $# -ne 2 ]; then
	echo "usage: $0 FS_DIR WORK_DIR" >&2
	exit 1
fi

FS_DIR=$1
WORK_DIR=$2

mkdir -p ${WORK_DIR}
cd ${WORK_DIR}

rm -rf disk.img mnt

dd if=/dev/zero of=disk.img bs=G seek=4 count=0

sudo gdisk disk.img <<EOF
o
Y
n



ef00
w
Y
EOF
sudo gdisk -l disk.img

sudo kpartx -a disk.img
EFI_PART="/dev/mapper/$(sudo kpartx -l disk.img | cut -d' ' -f1)"
while [ ! -e /dev/mapper/loop0p1 ]; do
	sleep 1
done

sudo mkfs.vfat -F 32 ${EFI_PART}

mkdir mnt
sudo mount ${EFI_PART} mnt
mount | grep mnt

sudo cp -r ${FS_DIR}/* mnt/
tree mnt

sudo umount mnt

sudo kpartx -d disk.img

qemu-img convert -f raw -O qcow2 disk.img disk.qcow2
