# ALIS (Arch Linux Install Script)

## Install unattended, automated and customized Arch Linux system.

This repository is forked from picodotdev/alis with certains changes. You can read this changes on [CHANGES](https://github.com/aramcap/alis/blob/master/CHANGES) file. Thanks to Picotodev for your work!

This a simple bash script for an easy and fast way of installing Arch Linux, follow the [Arch Way](https://wiki.archlinux.org/index.php/Arch_Linux) of doing things and learn what this script does. This will allow you to know what is happening. 

Please, don't ask for support for this script in Arch Linux forums, first read the [Arch Linux wiki](https://wiki.archlinux.org), the [Installation Guide](https://wiki.archlinux.org/index.php/Installation_guide) and the [General Recomendations](https://wiki.archlinux.org/index.php/General_recommendations), later compare the those commands with the commands of this script.

For new features, improvements or bugs (in real or virtual hardware) fill an issue in GitHub or make a pull request.

### Features

* Autodetect UEFI or BIOS
* Autodetect HDD or SSD (with periodic TRIM for SSD storage)
* Optional erase and format disk (ext4, btrfs (no swap), xfs)
* Optional _root_ partition encrypt with LUKS
* Optional file swap
* Optional kernels installation (linux-lts, linux-hardened, linux-zen) and compression
* Support installation with LVM
* WPA WiFi network installation
* Intel processors microcode
* Users creation and add to sudoers
* Custom packages installation
* AUR utility installation (aurman, yay)
* Desktop environments (GDM, KDE, XFCE, Mate, Cinnamon, LXDE or Deepin), display managers (GDM, SDDM, Lightdm, lxdm) or no desktop environments
* Graphics controllers (intel, nvidia, amd) with optionaly early KMS start
* GRUB, rEFInd, systemd-boot bootloaders
* Save installation log in a file

### Installation

Start the system with Arch Linux installation media and execute this commands:

```bash
loadkeys [keymap]

# If you have 4K monitor
# setfont latarcyrheb-sun32

# If you want set custom disk format
# parted, pvcreate, vgcreate, lvcreate, mkfs.vfat, mkfs.ext4, ...

# If you use WiFi
# wifi-menu -o

wget https://raw.githubusercontent.com/aramcap/alis/master/download.sh

bash download.sh
```

In ViM editor you can customize your installation. When you save and exit, the install will start immediately.

The install log is save in same directory that installer, but when the computer will be rebooted the log file will moved to `/root/alis.log`.


### Arch Linux Installation Media

https://www.archlinux.org/download/