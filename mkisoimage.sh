#!/bin/bash

########################################
# Nixpwnbox ISO image creation script  #
########################################

# Install nixpkgs on non-NixOS systems
if [ ! -f /etc/os-release ] || [ -z "$(grep 'NixOS' /etc/os-release)" ]; then
  bash <(curl -L https://nixos.org/nix/install) --no-channel-add --daemon --yes
  source /etc/bashrc || source /etc/bash.bashrc
  nix-channel --add https://github.com/NixOS/nixpkgs/archive/master.tar.gz nixpkgs
  nix-channel --update nixpkgs
  nix-env -iA nixpkgs.nixos-install-tools
fi

# Detect if we're running on a live image and update location of configuration.nix accordingly
if [ ! -f ./README.md ] && [ ! -f ./configuration.nix ] && [ -f /etc/nixos/configuration-template.nix ]
then
  cp /etc/nixos/configuration-template.nix ./configuration.nix
fi

# Generate the ISO image
nix-build '<nixpkgs/nixos>' -A config.system.build.isoImage -I nixos-config=iso.nix

# Cleanup if on a non-NixOS host
if [ ! -f /etc/os-release ] || [ -z "$(grep 'NixOS' /etc/os-release)" ]; then

  # Disable nix-daemon services/sockets
  systemctl disable --now nix-daemon.socket nix-daemon.service
  systemctl daemon-reload

  # Remove "nixbld*" users
  for i in $(seq 1 $(nproc)); do
      userdel nixbld$i
  done
  groupdel nixbld

  # Delete "*.backup-before-nix" files
  find /etc -iname "*.backup-before-nix" -delete

  # Uninstall Nix packages from host
  rm -rf /etc/nix /etc/profile.d/nix.sh /etc/tmpfiles.d/nix-daemon.conf /nix ~root/.nix-channels ~root/.nix-defexpr ~root/.nix-profile
fi

# Cleanup PWD if running on live image
if [ -f /etc/nixos/configuration-template.nix ] && [ -f ./configuration.nix ] && [ ! -f ./README.md ]
then
  rm ./configuration.nix
fi
