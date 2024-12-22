# NixPwnBox: A [Hack the Box](https://academy.hackthebox.com)-style NixOS configuration (plus more modern software than what their cloud VM offers)

Although Hack the Box does a fantastic job with providing a cloud VM with Parrot OS on it for interacting with Academy machines, and although Parrot and Kali are fantastic pentesting operating systems, there are a few things they lack:

1. New software in realtime (Parrot, for example, is stuck on version 2.14 of OWASP ZAP which is a year and a half old, only updates the kernel about every 6 months, and ships with a version of Hashcat that lacks CUDA support for the RTX 4070, among other things, while Kali, being Debian-based, isn't any better)
2. The ability to atomically and declaratively reproduce an entire OS using one configuration file to rule them all

Alas, [NixOS](https://nixos.org) offers both of these things, and also has more than enough pentest tools in the official repositories for most use cases. As such, I've come up with the perfect solution for those who want to take their CPTS role path and/or exam with a more modern toolset and better graphics: a NixOS configuration file that mimics almost everything that HTB's official PwnBox presents people ― everything from a Bash prompt identical to that offered in the PwnBox (complete with the VPN IP address if you're connected through the Academy) along with the use of dark theming, HTB-style fonts, and even, thanks to [Plasma-Manager](https://nix-community.github.io/plasma-manager), the exact same desktop background as what's on the PwnBox as well as an identical "start here" menu icon, and of course all the pentest tools needed to pwn every module and exam possible.

Unlike the official HTB PwnBox, however, NixPwnBox uses KDE Plasma 6 instead of MATE, and this offers several distinct advantages:

1. Wayland instead of X11 by default, and along with that better support for modern graphics in general
2. [Nvidia-Open](https://developer.nvidia.com/blog/nvidia-transitions-fully-towards-open-source-gpu-kernel-modules/) graphics drivers out of the box, meaning that machines with Nvidia cards should just work (and, most importantly, should support high refresh rates on 4K displays)
3. MacOS-style window grouping without the need to install third party docks such as Plank (personal pet peeve, because having MATE's old Windows XP/Vista-style labeled window list during a penetration test makes for a very messy, disorganized experience and wastes a lot of your time when you're trying to switch from terminal windows to RDPs and back)
4. Global menu ribbon, which keeps all the context menus in one place when you're trying to do work inside graphical tools such as Ghidra

## What it looks like

### Desktop:
![desktop](https://github.com/user-attachments/assets/ca1886e7-1633-4d9a-b207-213a0c1c2469)

### Desktop with Kickoff (app menu) and Konsole (terminal) open:
![kickoff](https://github.com/user-attachments/assets/3beab073-3c4a-44ef-a6ec-5ecd87bb0a0f)

### `uname -a` output (note the 6.12 kernel):
![uname](https://github.com/user-attachments/assets/181d730e-b362-4c16-b66d-78ef0a4ff5f1)

### ZAP 2.15
![zaproxy215](https://github.com/user-attachments/assets/6fe79986-cef6-42b8-8899-c0d293a01b43)

### Overview Mode
![overview](https://github.com/user-attachments/assets/f48b4957-d74b-4e48-bc3c-4fd22fc5e099)

## Installation (from existing Linux systems)

Simply open a terminal from any existing Linux system and run `sudo ./nixpwnbox.sh` while passing in arguments for:

1. The device (e.g. /dev/sda, /dev/sdb) that you plan to install to
2. First half of your time zone path (e.g. "America")
3. Second half of your time zone path (e.g. "Los_Angeles", "New_York")
4. Locale (e.g. "en_US.UTF-8")
5. File system you plan to use for the root (e.g. "btrfs", "bcachefs", "ext4")
6. Username (e.g. "htb-ac-`ID`")
7. Full name
8. Computer name

Example: `sudo ./nixpwnbox.sh /dev/sda America Los_Angeles "en_US.UTF-8" btrfs someuser "Some User" some-host`

## Installation from ISO image

`./mkisoimage.sh` (unlike the install script, this one doesn't need any arguments), then flash the resulting ISO image to a drive using `dd` and install either with `/etc/htb/install.sh` (same command-line syntax as `nixpwnbox.sh` above) or with Calamares (untested!) from it.

## Contributing

1. If you find that there's a tool missing from the default configuration that should be in it, feel free to either submit a pull request or report an issue. I'll gladly take as much feedback as possible.
2. Feel free to report any bugs or installation failures that may arise under the Issues tab, as well as ask any questions under the Discussions tab
