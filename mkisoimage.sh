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

# Copy ISO image to current working directory on non-NixOS so it isn't lost when we clean up
if [ ! -f /etc/os-release ] || [ -z "$(grep 'NixOS' /etc/os-release)" ]; then
  cp result/iso/*.iso .
fi

# Cleanup if on a non-NixOS host
sudo ./cleanup.sh

# Cleanup PWD if running on live image
if [ -f /etc/nixos/configuration-template.nix ] && [ -f ./configuration.nix ] && [ ! -f ./README.md ]
then
  rm ./configuration.nix
fi
