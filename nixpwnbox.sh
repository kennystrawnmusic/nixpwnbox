#!/bin/bash

##################################
# Nixpwnbox installation script  #
##################################

if [ $UID -ne 0 ]; then
	echo "Error: this script must be run as root; please use sudo and try again"
	exit 1
fi

args=($1 $2 $3 $4 $5 $6 $7 $8 $9)

if [ ${#args[@]} -lt 9 ]; then

	cat <<-EOF
		Usage: nixpwnbox.sh DEVICE TIME_ZONE_CONTINENT TIME_ZONE_CITY LOCALE FILE_SYSTEM USERNAME NICKNAME HOSTNAME GIT_EMAIL

		where:
		 * DEVICE is the device to install to,
		 * TIME_ZONE_CONTINENT is the part of your time zone identifier before the slash,
		 * TIME_ZONE_CITY is the part of your time zone identifier after the slash,
		 * LOCALE is your language locale identifier,
		 * FILE_SYSTEM is the file system you intend to use to format DEVICE,
		 * USERNAME is your username,
		 * NICKNAME is your properly capitalized and spaced real name,
		 * HOSTNAME is what your computer will call itself on the network,
		 * and GIT_EMAIL is the email address to configure Git with.

		Example: sudo ./nixpwnbox.sh /dev/sda America Los_Angeles "en_US.UTF-8" btrfs someuser "Some User" some-host changethis@example.com

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
gitemail=$9

./reformat.sh $dest_device

set -euo pipefail

# Install nixpkgs on non-NixOS systems
if [ ! -f /etc/os-release ] || [ -z "$(grep 'NixOS' /etc/os-release)" ] || [ ! "$(which nix-env)" =~ ".*/bin/nix-env$" ]; then
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
sed -i "s/@@email@@/$gitemail/g" /mnt/etc/nixos/configuration.nix

# Count how many times 'options =' appears inside fileSystems."/": { ... };
count_fs_root_options() {
  awk '
    /fileSystems\."\/"[[:space:]]*=[[:space:]]*\{/ , /^\s*};/ {
      n += gsub(/(^|[[:space:]])options[[:space:]]*=/, "&")
    }
    END { print n+0 }
  ' /mnt/etc/nixos/hardware-configuration.nix
}

# Debug helper to show any lines with options= inside that block (with numbers)
show_fs_root_options() {
  nl -ba /mnt/etc/nixos/hardware-configuration.nix |
  awk '
    /fileSystems\."\/"[[:space:]]*=[[:space:]]*\{/ , /^\s*};/ {
      if ($0 ~ /(^|[[:space:]])options[[:space:]]*=/) print
    }'
}

# Actually install the target system
nixos-generate-config --root /mnt


count="$(count_fs_root_options || echo 0)"
if [ "${count}" -le 1 ]; then
  nixos-install \
    -I nixpkgs=https://github.com/NixOS/nixpkgs/archive/master.tar.gz \
    -I nixos=https://github.com/NixOS/nixpkgs/archive/master.tar.gz
else
  echo "Found ${count} 'options =' entries in fileSystems.\"/\" block:"
  show_fs_root_options
fi

# Cleanup if on a non-NixOS host
./cleanup.sh

# Unmount target
find /dev -regex "$(echo $dest_device | cut -d\/ -f3)[0-9]{1,}" -exec umount -lf {} \;
