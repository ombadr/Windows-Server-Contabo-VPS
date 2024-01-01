#!/bin/bash

apt update -y && apt upgrade -y

apt install filezilla grub2 wimtools -y

parted /dev/sda --script -- mklabel gpt

disk_size=$(parted /dev/sda --script print | awk '/^Disk/ \/dev\/sda:/ {print int($3)}')

part_size=$((disk_size / 4))

parted /dev/sda --script -- mklabel gpt

parted /dev/sda --script -- mkpart primary 1MB "${part_size}"MB

parted /dev/sda --script -- mkpart primary "$(($part_size + 1))MB" "$(($part_size * 2))MB"

gdisk /dev/sda <<EOF
spawn gdisk /dev/sad
expect "Command (? for help):"
send "r\n"
expect "Recovery/transformation command (? for help):"
send "g\n"
expect "MBR command (? for help):"
send "p\n"
expect "MBR command (? for help):"
send "w\n"
expect "Converted 2 partitions. Finalize and exit? (Y/N):"
send "Y\n"
EOF

mount /dev/sda1 /mnt

cd ~
mkdir windisk

mount /dev/sda2 windisk

grub-install --root-directory=/mnt /dev/sda

#Edit GRUB configuration
cd /mnt/boot/grub
cat <<EOF > grub.cgf
menuentry "windows installer" {
	insmod ntfs
	search --set=root --file=/bootmgr
	ntldr /bootmgr
	boot
}
EOF

cd /root/windisk
mkdir winfile

wget -O win10.iso https://shorturl.at/qTUX1

mount -p loop win10.iso winfile

rsync -avz --progress winfile/* /mnt

umount winfile

wget -O virtio.iso https://shorturl.at/lsOU3

mount -o loop virtio.iso winfile

mkdir /mnt/sources/virtio

rsync -avz --progress winfile/* /mnt/sources/virtio

cd /mnt/sources

touch cmd.txt

echo 'add virtio /virtio_drivers' >> cmd.txt

wimlib-imagex update boot.wim 2 < cmd.txt

reboot


