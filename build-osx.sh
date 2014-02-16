#!/bin/sh

echo ">>> Tinyschemeos OS X build script - requires nasm 2.x"

if test "`whoami`" != "root" ; then
	echo "You must be logged in as root to build (for loopback mounting)"
	echo "Enter 'su' or 'sudo bash' to switch to root"
	exit
fi

echo ">>> Assembling bootloader..."

nasm -O0 -w+orphan-labels -f bin -o src/bootload.bin src/bootload.asm || exit

echo ">>> Assembling Tinyschemeos kernel..."

cd src
nasm -O0 -f bin -o kernel.bin kernel.asm || exit
cd ..

echo ">>> Creating floppy..."
cp disk_images/tinyschemeos.flp disk_images/tinyschemeos.dmg
chmod 666 disk_images/tinyschemeos.dmg

echo ">>> Adding bootloader to floppy image..."

dd conv=notrunc if=src/bootload.bin of=disk_images/tinyschemeos.dmg || exit

echo ">>> Copying Tinyschemeos kernel and programs..."

rm -rf tmp-loop

dev=`hdid -nobrowse -nomount disk_images/tinyschemeos.dmg`
mkdir tmp-loop && mount -t msdos ${dev} tmp-loop && cp src/kernel.bin tmp-loop/

echo ">>> Unmounting loopback floppy..."

umount tmp-loop || exit
hdiutil detach ${dev}

rm -rf tmp-loop

mv disk_images/tinyschemeos.dmg disk_images/tinyschemeos.flp

echo ">>> Tinyschemeos floppy image is disk_images/tinyschemeos.flp"
