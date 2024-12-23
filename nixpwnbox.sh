#!/bin/bash

##################################
# Nixpwnbox installation script  #
##################################

if [ $UID -ne 0 ]; then
	echo "Error: this script must be run as root; please use sudo and try again"
	exit 1
fi

args=($1 $2 $3 $4 $5 $6 $7 $8)

if [ ${#args[@]} -lt 8 ]; then

	cat <<-EOF
		Usage: nixpwnbox.sh DEVICE TIME_ZONE_CONTINENT TIME_ZONE_CITY LOCALE FILE_SYSTEM USERNAME NICKNAME HOSTNAME

		where:
		 * DEVICE is the device to install to,
		 * TIME_ZONE_CONTINENT is the part of your time zone identifier before the slash,
		 * TIME_ZONE_CITY is the part of your time zone identifier after the slash,
		 * LOCALE is your language locale identifier,
		 * FILE_SYSTEM is the file system you intend to use to format DEVICE,
		 * USERNAME is your username,
		 * NICKNAME is your properly capitalized and spaced real name,
		 * and HOSTNAME is what your computer will call itself on the network.

		Example: sudo ./nixpwnbox.sh /dev/sda America Los_Angeles "en_US.UTF-8" btrfs someuser "Some User" some-host

	EOF

	exit 1
fi

# Need to use extended globbing
shopt -s extglob

# Independent Variables
dest_device=$1
tz_major=$2
tz_minor=$3
locale=$4
file_system=$5
user=$6
nickname=$7
hostname=$8

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

# Install nixpkgs on non-NixOS systems
if [ ! -f /etc/os-release ] || [ -z "$(grep 'NixOS' /etc/os-release)" ]; then
  bash <(curl -L https://nixos.org/nix/install) --no-channel-add --daemon --yes
  source /etc/bashrc || source /etc/bash.bashrc
  nix-channel --add https://github.com/NixOS/nixpkgs/archive/master.tar.gz nixpkgs
  nix-channel --update nixpkgs
  nix-env -iA nixpkgs.nixos-install-tools
fi

# Copy configuration template
mkdir -p /mnt/etc/nixos
cp ./configuration.nix /mnt/etc/nixos/configuration.nix

sed -i "s/@@username@@/$user/g" /mnt/etc/nixos/configuration.nix
sed -i "s/@@tz-major@@\/@@tz-minor@@/$tz_major\/$tz_minor/g" /mnt/etc/nixos/configuration.nix
sed -i "s/@@lang@@/$locale/g" /mnt/etc/nixos/configuration.nix
sed -i "s/@@fullname@@/$nickname/g" /mnt/etc/nixos/configuration.nix
sed -i "s/@@hostname@@/$hostname/g" /mnt/etc/nixos/configuration.nix

if [ "$file_system" != "btrfs" ]; then
  sed -i "s/btrfs/$file_system/g" /mnt/etc/nixos/configuration.nix
fi

# Actually install the target system
nixos-generate-config --root /mnt
nixos-install -I nixpkgs=https://github.com/NixOS/nixpkgs/archive/master.tar.gz -I nixos=https://github.com/NixOS/nixpkgs/archive/master.tar.gz

# Cleanup if on a non-NixOS host
if [ ! -f /etc/os-release ] || [ -z "$(grep 'NixOS' /etc/os-release)" ]; then

  # Disable nix-daemon services/sockets
  systemctl disable --now nix-daemon.socket nix-daemon.service
  systemctl daemon-reload

  # Remove "nixbld*" users
  for i in $(seq 1 32); do
      userdel nixbld$i
  done
  groupdel nixbld

  # Delete "*.backup-before-nix" files
  find /etc -iname "*.backup-before-nix" -delete

  # Uninstall Nix packages from host
  rm -rf /etc/nix /etc/profile.d/nix.sh /etc/tmpfiles.d/nix-daemon.conf /nix ~root/.nix-channels ~root/.nix-defexpr ~root/.nix-profile
fi

# Unmount target
umount -lf /mnt/{boot,.}
