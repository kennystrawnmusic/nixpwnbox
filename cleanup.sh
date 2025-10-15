#!/bin/bash

###########################################################
# Nixpwnbox store cleanup helper                          #
# Uninstalls nixpkgs if we're running on a non-NixOS host #
###########################################################

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
