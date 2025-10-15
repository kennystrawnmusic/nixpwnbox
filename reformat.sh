#!/bin/bash

#################################
# Nixpwnbox disk format helper  #
#################################

if [ $UID -ne 0 ]; then
	echo "Error: this script must be run as root; please use sudo and try again"
	exit 1
fi

args=($1 $2)

if [ ${#args[@]} -lt 2 ]; then
	cat <<-EOF
		Usage: reformat.sh DEVICE FS,

		where:
		 * DEVICE is the device to format
		 * FS is the file system to use

		Example: sudo ./reformat.sh /dev/sda btrfs

	EOF

	exit 1
fi

# Need to use extended globbing
shopt -s extglob

# Independent Variables
dest_device=$1
file_system=$2

# Partitions
sed -e 's/\s*\([\+0-9a-zA-Z]*\).*/\1/' << EOF | fdisk $dest_device
	g # GPT
	n
		# default
		# default
	+512M
	t # change partition type
	1 # EFI System
	n
		# default
		# default
		# default
	p
	w
EOF

# Dependent Variables
partitions=($(fdisk -l $dest_device | cut -d' ' -f1 | tail -n-2 | tr '\n' ' '))
root_uuid=$(blkid | grep ${partitions[1]} | cut -d' ' -f6 | cut -d\" -f2)

partition1=${partitions[0]}
partition2=${partitions[1]}

script_working_directory=$PWD

# Formatting
mkfs.vfat -F32 $partition1
mkfs.$file_system -f $partition2

if [ ! -d /mnt ]; then
  mkdir /mnt
fi

# Mount points
mount -t $file_system $partition2 /mnt

if [ "$file_system" == "btrfs" ]
then
  cd /mnt
  btrfs subvolume create '@'
  btrfs subvolume create '@home'
  cd $script_working_directory
  umount -lf /mnt
  mount -t $file_system -o subvol='@' $partition2 /mnt
  mkdir /mnt/home
  mount -t $file_system -o subvol='@home' $partition2 /mnt/home
  cd $script_working_directory
fi

if [ $? -ne 0 ]; then
  echo "Error: failed to mount file systems"
  exit 1
fi

mkdir /mnt/boot
mount -t vfat $partition1 -o umask=0077 /mnt/boot
