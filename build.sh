#!/bin/sh

if test "`whoami`" != "root" ; then
	echo "You must be logged in as root to build (for loopback mounting)"
	echo "Enter 'su' or 'sudo bash' to switch to root"
	exit
fi

if [ ! -e disk_images/tinyschemeos.flp ]
then
	echo ">>> Creating new tinyschemeos floppy image..."
	mkdosfs -C disk_images/tinyschemeos.flp 1440 || exit
fi

echo ">>> Assembling bootloader..."

nasm -O0 -w+orphan-labels -f bin -o src/bootload.bin src/bootload.asm || exit


echo ">>> Assembling kernel..."
cd src
nasm -O0 -w+orphan-labels -f bin -o kernel.bin kernel.asm || exit
cd ..

echo ">>> Adding bootloader to floppy image..."
dd status=noxfer conv=notrunc if=src/bootload.bin of=disk_images/tinyschemeos.flp || exit

echo ">>> Copying tinyschemeos kernel and programs..."

rm -rf tmp-loop

mkdir tmp-loop && mount -o loop -t vfat disk_images/tinyschemeos.flp tmp-loop && cp src/kernel.bin tmp-loop/

sleep 0.2

echo ">>> Unmounting loopback floppy..."

umount tmp-loop || exit

rm -rf tmp-loop
