#!/usr/bin/env bash
set -e

# Arch Linux Install Script (alis)
# Copyright (C) 2019 aramcap (https://github.com/aramcap/alis), forked from picodotdev/alis
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program. If not, see <http://www.gnu.org/licenses/>.
# 
#
#
#
#
#
#
#
#
#
#
#
#
#
#
#
#
#
#
#
# Not modify this software! It's can be produce corruption!
#
#
#
#
#
#
#
#
#
#
#
#
#
#
#
#
#
#
#

# global variables (no configuration, don't edit)
BIOS_TYPE=""
PARTITION_ESP=""
PARTITION_BOOT=""
PARTITION_ROOT=""
FORMATDISK="false"
LVM_VOLUME_GROUP="vg"
LVM_VOLUME_LOGICAL="root"
DIRECTORY_BOOT="/boot"
DIRECTORY_ESP="/esp"
UUID_BOOT=""
UUID_ROOT=""
DEVICE_SATA=""
DEVICE_NVME=""
CPU_INTEL=""
VIRTUALBOX=""
CMDLINE_LINUX_ROOT=""
CMDLINE_LINUX_DEFAULT=""
CMDLINE_LINUX=""
ADDITIONAL_USER_NAMES_ARRAY=()
ADDITIONAL_USER_PASSWORDS_ARRAY=()
KMS="false"
DISPLAY_DRIVER_DDX="false"
VULKAN="false"
DISPLAY_DRIVER_HARDWARE_ACCELERATION="false"
PACKAGES_PACMAN=""

LOG="true"
RED='\033[0;31m'
GREEN='\033[0;32m'
LIGHT_BLUE='\033[1;34m'
NC='\033[0m'

function configuration_install() {
    source alis.conf
    ADDITIONAL_USER_NAMES_ARRAY=($ADDITIONAL_USER_NAMES)
    ADDITIONAL_USER_PASSWORDS_ARRAY=($ADDITIONAL_USER_PASSWORDS)
}

function sanitize_variables() {
    DEVICE=$(sanitize_variable "$DEVICE")
    FILE_SYSTEM_TYPE=$(sanitize_variable "$FILE_SYSTEM_TYPE")
    SWAP_SIZE=$(sanitize_variable "$SWAP_SIZE")
    KERNELS=$(sanitize_variable "$KERNELS")
    KERNELS_COMPRESSION=$(sanitize_variable "$KERNELS_COMPRESSION")
    BOOTLOADER=$(sanitize_variable "$BOOTLOADER")
    DESKTOP_ENVIRONMENT=$(sanitize_variable "$DESKTOP_ENVIRONMENT")
    DISPLAY_DRIVER=$(sanitize_variable "$DISPLAY_DRIVER")
    DISPLAY_DRIVER_HARDWARE_ACCELERATION_INTEL=$(sanitize_variable "$DISPLAY_DRIVER_HARDWARE_ACCELERATION_INTEL")
    PACKAGES_PACMAN=$(sanitize_variable "$PACKAGES_PACMAN")
    AUR=$(sanitize_variable "$AUR")
    PACKAGES_AUR=$(sanitize_variable "$PACKAGES_AUR")
}

function sanitize_variable() {
    VARIABLE=$1
    VARIABLE=$(echo $VARIABLE | sed "s/![^ ]*//g") # remove disabled
    VARIABLE=$(echo $VARIABLE | sed "s/ {2,}/ /g") # remove unnecessary white spaces
    VARIABLE=$(echo $VARIABLE | sed 's/^[[:space:]]*//') # trim leading
    VARIABLE=$(echo $VARIABLE | sed 's/[[:space:]]*$//') # trim trailing
    echo "$VARIABLE"
}

function check_variables() {
    check_variables_value "KEYS" "$KEYS"
    check_variables_boolean "LOG" "$LOG"
    check_variables_value "DEVICE" "$DEVICE"
    check_variables_boolean "LVM" "$LVM"
    check_variables_equals "PARTITION_ROOT_ENCRYPTION_PASSWORD" "PARTITION_ROOT_ENCRYPTION_PASSWORD_RETYPE" "$PARTITION_ROOT_ENCRYPTION_PASSWORD" "$PARTITION_ROOT_ENCRYPTION_PASSWORD_RETYPE"
    check_variables_list "FILE_SYSTEM_TYPE" "$FILE_SYSTEM_TYPE" "ext4 btrfs xfs"
    check_variables_value "PING_HOSTNAME" "$PING_HOSTNAME"
    check_variables_value "PACMAN_MIRROR" "$PACMAN_MIRROR"
    check_variables_list "KERNELS" "$KERNELS" "linux-lts linux-lts-headers linux-hardened linux-hardened-headers linux-zen linux-zen-headers" "false"
    check_variables_list "KERNELS_COMPRESSION" "$KERNELS_COMPRESSION" "gzip bzip2 lzma xz lzop lz4" "false"
    check_variables_value "TIMEZONE" "$TIMEZONE"
    check_variables_value "LOCALE" "$LOCALE"
    check_variables_value "LANG" "$LANG"
    check_variables_value "KEYMAP" "$KEYMAP"
    check_variables_value "HOSTNAME" "$HOSTNAME"
    check_variables_value "USER_NAME" "$USER_NAME"
    check_variables_value "USER_PASSWORD" "$USER_PASSWORD"
    check_variables_equals "ROOT_PASSWORD" "ROOT_PASSWORD_RETYPE" "$ROOT_PASSWORD" "$ROOT_PASSWORD_RETYPE"
    check_variables_equals "USER_PASSWORD" "USER_PASSWORD_RETYPE" "$USER_PASSWORD" "$USER_PASSWORD_RETYPE"
    check_variables_size "ADDITIONAL_USER_PASSWORDS" "${#ADDITIONAL_USER_NAMES_ARRAY[@]}" "${#ADDITIONAL_USER_PASSWORDS_ARRAY[@]}"
    check_variables_list "BOOTLOADER" "$BOOTLOADER" "grub refind systemd"
    check_variables_list "AUR" "$AUR" "aurman yay"
    check_variables_list "DESKTOP_ENVIRONMENT" "$DESKTOP_ENVIRONMENT" "gnome kde xfce mate cinnamon lxde deepin" "false"
    check_variables_list "DISPLAY_DRIVER" "$DISPLAY_DRIVER" "intel amdgpu ati nvidia nvidia-lts nvidia-390xx nvidia-390xx-lts nvidia-340xx nvidia-340xx-lts nouveau" "false"
    check_variables_boolean "KMS" "$KMS"
    check_variables_boolean "DISPLAY_DRIVER_DDX" "$DISPLAY_DRIVER_DDX"
    check_variables_boolean "DISPLAY_DRIVER_HARDWARE_ACCELERATION" "$DISPLAY_DRIVER_HARDWARE_ACCELERATION"
    check_variables_list "DISPLAY_DRIVER_HARDWARE_ACCELERATION_INTEL" "$DISPLAY_DRIVER_HARDWARE_ACCELERATION_INTEL" "intel-media-driver libva-intel-driver" "false"
    check_variables_boolean "REBOOT" "$REBOOT"
}

function check_variables_value() {
    NAME=$1
    VALUE=$2
    if [ -z "$VALUE" ]; then
        echo "$NAME environment variable must have a value."
        exit
    fi
}

function check_variables_boolean() {
    NAME=$1
    VALUE=$2
    check_variables_list "$NAME" "$VALUE" "true false"
}

function check_variables_list() {
    NAME=$1
    VALUE=$2
    VALUES=$3
    REQUIRED=$4
    if [ "$REQUIRED" == "" -o "$REQUIRED" == "true" ]; then
        check_variables_value "$NAME" "$VALUE"
    fi

    if [ "$VALUE" != "" -a -z "$(echo "$VALUES" | grep -F -w "$VALUE")" ]; then
        echo "$NAME environment variable value [$VALUE] must be in [$VALUES]."
        exit
    fi
}

function check_variables_equals() {
    NAME1=$1
    NAME2=$2
    VALUE1=$3
    VALUE2=$4
    if [ "$VALUE1" != "$VALUE2" ]; then
        echo "$NAME1 and $NAME2 must be equal [$VALUE1, $VALUE2]."
        exit
    fi
}

function check_variables_size() {
    NAME=$1
    SIZE_EXPECT=$2
    SIZE=$3
    if [ "$SIZE_EXPECT" != "$SIZE" ]; then
        echo "$NAME array size [$SIZE] must be [$SIZE_EXPECT]."
        exit
    fi
}

function warning() {
    echo -e "${LIGHT_BLUE}Welcome to ALIS v0.1 (Arch Linux Install Script) ${NC}"
    echo ""
    echo -e "${LIGHT_BLUE} ALIS v0.1  Copyright (C) 2019  https://github.com/aramcap ${NC}"
    echo -e "${LIGHT_BLUE} This program is under the terms of the GNU GPL v3 and comes with ABSOLUTELY NO WARRANTY. ${NC}"
    echo ""

    echo -e "${LIGHT_BLUE}BIOS type: $BIOS_TYPE ${NC}"

    if [ "$FORMATDISK" == "true" ]; then
        echo -e "${RED}Warning"'!'"${NC}"
        echo -e "${RED}This script deletes all partitions of the persistent${NC}"
        echo -e "${RED}storage and continuing all your data in it will be lost.${NC}"
    else
        if [ "$BIOS_TYPE" == "uefi" ]; then
            echo -e "${GREEN}ESP partition: $PARTITION_ESP ${NC}"
        fi
        echo -e "${GREEN}BOOT partition: $PARTITION_BOOT ${NC}"
        if [ "$LVM" == "true" ]; then
            echo -e "${GREEN}LVM phisical volume: $LVM_VOLUME_PHISICAL ${NC}"
        fi
        echo -e "${GREEN}ROOT partition: $PARTITION_ROOT ${NC}"
    fi
    echo ""
    read -p "Do you want to continue? [y/N] " yn
    case $yn in
        [Yy]* )
            ;;
        [Nn]* )
            exit
            ;;
        * )
            exit
            ;;
    esac
}

function init() {
    echo ""
    echo -e "${LIGHT_BLUE}# init() step${NC}"
    echo ""

    init_log
    loadkeys $KEYS
}

function init_log() {
    if [ "$LOG" == "true" ]; then
        exec > >(tee -a alis.log)
        exec 2> >(tee -a alis.log >&2)
    fi
    #set -o xtrace
}

function facts() {
    echo ""
    echo -e "${LIGHT_BLUE}# facts() step${NC}"
    echo ""

    if [ -d /sys/firmware/efi ]; then
        BIOS_TYPE="uefi"
    else
        BIOS_TYPE="bios"
    fi

    DEVICE_SATA="false"
    DEVICE_NVME="false"
    if [ -n "$(echo $DEVICE | grep "^/dev/sda")" ]; then
        DEVICE_SATA="true"
    elif [ -n "$(echo $DEVICE | grep "^/dev/nvme")" ]; then
        DEVICE_NVME="true"
    fi

    if [ -n "$(lscpu | grep GenuineIntel)" ]; then
        CPU_INTEL="true"
    fi

    if [ -n "$(lspci | grep -i virtualbox)" ]; then
        VIRTUALBOX="true"
    fi
}

function check_facts() {
    if [ "$BOOTLOADER" == "refind" ]; then
        check_variables_list "BIOS_TYPE" "$BIOS_TYPE" "uefi"
    fi
    if [ "$BOOTLOADER" == "systemd" ]; then
        check_variables_list "BIOS_TYPE" "$BIOS_TYPE" "uefi"
    fi
}

function prepare() {
    echo ""
    echo -e "${LIGHT_BLUE}# prepare() step${NC}"

    configure_time
    umount_partitions
    configure_network

    echo ""
}

function configure_time() {
    echo -e "${LIGHT_BLUE}# - configure_time() step${NC}"
    timedatectl set-ntp true
}

function umount_partitions() {
    echo -e "${LIGHT_BLUE}# - umount_partitions() step${NC}"

    if [ ! -z "$(mount | grep "/mnt$DIRECTORY_ESP")" ]; then
        umount /mnt$DIRECTORY_ESP
    fi
    if [ ! -z "$(mount | grep "/mnt$DIRECTORY_BOOT")" ]; then
        umount /mnt$DIRECTORY_BOOT
    fi
    if [ ! -z "$(mount | grep "/mnt")" ]; then
        umount /mnt
    fi
}

function configure_network() {
    echo -e "${LIGHT_BLUE}# - configure_network() step${NC}"
    if [ -n "$WIFI_INTERFACE" ]; then
        cp /etc/netctl/examples/wireless-wpa /etc/netctl
      	chmod 600 /etc/netctl

      	sed -i 's/^Interface=.*/Interface='"$WIFI_INTERFACE"'/' /etc/netctl
      	sed -i 's/^ESSID=.*/ESSID='"$WIFI_ESSID"'/' /etc/netctl
      	sed -i 's/^Key=.*/Key='\''$WIFI_KEY'\''/' /etc/netctl
      	if [ "$WIFI_HIDDEN" == "true" ]; then
      		sed -i 's/^#Hidden=.*/Hidden=yes/' /etc/netctl
      	fi

      	netctl start wireless-wpa
    fi

    ping -c 5 $PING_HOSTNAME
    if [ $? -ne 0 ]; then
        echo "Network ping check failed. Cannot continue."
        exit
    fi
}

function format_disk() {
    echo ""
    echo -e "${LIGHT_BLUE}# format_disk() step${NC}"
    echo ""

    if [ -e "/dev/mapper/$LVM_VOLUME_GROUP-$LVM_VOLUME_LOGICAL" ]; then
        if [ -n "$PARTITION_ROOT_ENCRYPTION_PASSWORD" ]; then
            cryptsetup close "/dev/mapper/$LVM_VOLUME_GROUP-$LVM_VOLUME_LOGICAL"
        fi
        lvremove --force "/dev/mapper/$LVM_VOLUME_GROUP-$LVM_VOLUME_LOGICAL"
        vgremove --force "$LVM_VOLUME_GROUP"
    fi

    wipefs -a $DEVICE
    partprobe $DEVICE

    if [ "$BIOS_TYPE" == "uefi" ]; then
        if [ "$DEVICE_SATA" == "true" ]; then
            PARTITION_ESP="${DEVICE}1"
            PARTITION_BOOT="${DEVICE}2"
            PARTITION_ROOT="${DEVICE}3"
        fi

        if [ "$DEVICE_NVME" == "true" ]; then
            PARTITION_ESP="${DEVICE}p1"
            PARTITION_BOOT="${DEVICE}p2"
            PARTITION_ROOT="${DEVICE}p3"
        fi

        parted -a opt -s $DEVICE mklabel gpt
        parted -a opt -s $DEVICE mkpart p1 fat32 1MiB 100MiB set 1 esp on mkpart p2 ext4 100MiB 600MiB mkpart p3 ext4 600MiB 100%
    fi

    if [ "$BIOS_TYPE" == "bios" ]; then
        if [ "$DEVICE_SATA" == "true" ]; then
            PARTITION_BOOT="${DEVICE}1"
            PARTITION_ROOT="${DEVICE}2"
        fi

        if [ "$DEVICE_NVME" == "true" ]; then
            PARTITION_BOOT="${DEVICE}p1"
            PARTITION_ROOT="${DEVICE}p2"
        fi

        parted -a opt -s $DEVICE mklabel msdos
        parted -a opt -s $DEVICE mkpart primary ext4 1MiB 500MiB set 1 boot on mkpart primary ext4 500MiB 100%
    fi

    if [ "$LVM" == "true" ]; then
        LVM_VOLUME_PHISICAL=$PARTITION_ROOT

        pvcreate -f $LVM_VOLUME_PHISICAL
        vgcreate -f $LVM_VOLUME_GROUP $LVM_VOLUME_PHISICAL
        lvcreate -y -l 100%FREE -n $LVM_VOLUME_LOGICAL $LVM_VOLUME_GROUP

        PARTITION_ROOT="/dev/mapper/$LVM_VOLUME_GROUP-$LVM_VOLUME_LOGICAL"
    fi

    if [ -n "$PARTITION_ROOT_ENCRYPTION_PASSWORD" ]; then
        echo -n "$PARTITION_ROOT_ENCRYPTION_PASSWORD" | cryptsetup --key-size=512 --key-file=- luksFormat --type luks2 $PARTITION_ROOT
        sleep 5
    fi

    if [ "$BIOS_TYPE" == "uefi" ]; then
        mkfs.vfat -n ESP $PARTITION_ESP
        mkfs.$FILE_SYSTEM_TYPE -F -L boot $PARTITION_BOOT
        mkfs.$FILE_SYSTEM_TYPE -F -L root $PARTITION_ROOT
    fi

    if [ "$BIOS_TYPE" == "bios" ]; then
        mkfs.$FILE_SYSTEM_TYPE -F -L boot $PARTITION_BOOT
        mkfs.$FILE_SYSTEM_TYPE -F -L root $PARTITION_ROOT
    fi

}

function partition() {
    echo ""
    echo -e "${LIGHT_BLUE}# partition() step${NC}"
    echo ""

    partprobe $DEVICE

    PARTITION_OPTIONS=""

    if [ "$DEVICE_TRIM" == "true" ]; then
        PARTITION_OPTIONS="-o defaults,noatime"
    fi

    mount $PARTITION_OPTIONS $PARTITION_ROOT /mnt

    mkdir /mnt$DIRECTORY_BOOT
    mount $PARTITION_OPTIONS $PARTITION_BOOT /mnt$DIRECTORY_BOOT

    if [ "$BIOS_TYPE" == "uefi" ]; then
        mkdir /mnt$DIRECTORY_ESP
        mount $PARTITION_OPTIONS $PARTITION_ESP /mnt$DIRECTORY_ESP
    fi

    if [ -n "$SWAP_SIZE" -a "$FILE_SYSTEM_TYPE" != "btrfs" ]; then
        fallocate -l $SWAP_SIZE /mnt/swap
        chmod 600 /mnt/swap
        mkswap /mnt/swap
    fi
}

function install() {
    echo ""
    echo -e "${LIGHT_BLUE}# install() step${NC}"
    echo ""

    sed -i 's/#Color/Color/' /etc/pacman.conf
    sed -i 's/#TotalDownload/TotalDownload/' /etc/pacman.conf

    pacstrap /mnt base base-devel

    cp -f /etc/pacman.d/mirrorlist /mnt/etc/pacman.d/mirrorlist
    sed -i 's/#Color/Color/' /mnt/etc/pacman.conf
    sed -i 's/#TotalDownload/TotalDownload/' /mnt/etc/pacman.conf

    if [ "$DEVICE_TRIM" == "true" ]; then
        arch-chroot /mnt systemctl enable fstrim.timer
    fi
}

function kernels() {
    echo ""
    echo -e "${LIGHT_BLUE}# kernels() step${NC}"
    echo ""

    pacman_install "linux-headers"
    if [ -n "$KERNELS" ]; then
        pacman_install "$KERNELS"
    fi
}

function configuration() {
    echo ""
    echo -e "${LIGHT_BLUE}# configuration() step${NC}"
    echo ""

    # fstab generate
    genfstab -U /mnt >> /mnt/etc/fstab

    # fstab include swap
    if [ -n "$SWAP_SIZE" -a "$FILE_SYSTEM_TYPE" != "btrfs" ]; then
        echo "# swap" >> /mnt/etc/fstab
        echo "/swap none swap defaults 0 0" >> /mnt/etc/fstab
        echo "" >> /mnt/etc/fstab
    fi

    # set swappiness
    if [ -n "$SWAP_SIZE" ]; then
        echo "vm.swappiness=10" > /mnt/etc/sysctl.d/99-sysctl.conf
    fi

    # trim setup
    if [ "$DEVICE_TRIM" == "true" ]; then
        sed -i 's/relatime/noatime/' /mnt/etc/fstab
        sed -i 's/issue_discards = 0/issue_discards = 1/' /mnt/etc/lvm/lvm.conf
    fi

    # set timezone
    arch-chroot /mnt ln -s -f $TIMEZONE /etc/localtime
    arch-chroot /mnt hwclock --systohc

    # set locale
    sed -i "s/#$LOCALE/$LOCALE/" /mnt/etc/locale.gen
    arch-chroot /mnt locale-gen
    echo -e "$LANG\n$LANGUAGE" > /mnt/etc/locale.conf

    # set vconsole configs
    echo -e "$KEYMAP\n$FONT\n$FONT_MAP" > /mnt/etc/vconsole.conf

    # set hostname
    echo $HOSTNAME > /mnt/etc/hostname

    printf "$ROOT_PASSWORD\n$ROOT_PASSWORD" | arch-chroot /mnt passwd

    # custom ntp servers
    echo "NTP=0.arch.pool.ntp.org 1.arch.pool.ntp.org 2.arch.pool.ntp.org 3.arch.pool.ntp.org
FallbackNTP=0.pool.ntp.org 1.pool.ntp.org 0.fr.pool.ntp.org" >> /mnt/etc/systemd/timesyncd.conf

    # auto on num lock for root user
    echo "setleds -D +num" >> /mnt/root/.bash_profile

    # custom aliases and colors
    echo "alias ls='ls --color'
    alias ll='ls -l --color'
    LS_COLORS='di=1:fi=0:ln=31:pi=5:so=5:bd=5:cd=5:or=31:mi=0:ex=35:*.rpm=90'
    export LS_COLORS" >> /mnt/root/.bashrc

    # reflector
    arch-chroot /mnt pacman -Sy --noconfirm reflector
    cp -f /mnt/etc/pacman.d/mirrorlist /mnt/etc/pacman.d/mirrorlist.backup
    arch-chroot /mnt reflector --sort rate --save /etc/pacman.d/mirrorlist
}

function network() {
    echo ""
    echo -e "${LIGHT_BLUE}# network() step${NC}"
    echo ""

    pacman_install "networkmanager"
    arch-chroot /mnt systemctl enable NetworkManager.service
}

function virtualbox() {
    echo ""
    echo -e "${LIGHT_BLUE}# virtualbox() step${NC}"
    echo ""

    if [ -z "$KERNELS" ]; then
        pacman_install "virtualbox-guest-utils virtualbox-guest-modules-arch"
    else
        pacman_install "virtualbox-guest-utils virtualbox-guest-dkms"
    fi
}

function users() {
    create_user $USER_NAME $USER_PASSWORD

    for i in ${!ADDITIONAL_USER_NAMES_ARRAY[@]}; do
        create_user ${ADDITIONAL_USER_NAMES_ARRAY[$i]} ${ADDITIONAL_USER_PASSWORDS_ARRAY[$i]}
    done

	arch-chroot /mnt sed -i 's/# %wheel ALL=(ALL) ALL/%wheel ALL=(ALL) ALL/' /etc/sudoers
}

function mkinitcpio() {
    echo ""
    echo -e "${LIGHT_BLUE}# mkinitcpio() step${NC}"
    echo ""

    if [ "$KMS" == "true" ]; then
        MODULES=""
        case "$DISPLAY_DRIVER" in
            "intel" )
                MODULES="i915"
                ;;
            "nvidia" | "nvidia-390xx" | "nvidia-390xx-lts" )
                MODULES="nvidia nvidia_modeset nvidia_uvm nvidia_drm"
                ;;
            "amdgpu" )
                MODULES="amdgpu"
                ;;
            "ati" )
                MODULES="radeon"
                ;;
            "nouveau" )
                MODULES="nouveau"
                ;;
        esac
        arch-chroot /mnt sed -i "s/MODULES=()/MODULES=($MODULES)/" /etc/mkinitcpio.conf
    fi

    if [ "$LVM" == "true" -a -n "$PARTITION_ROOT_ENCRYPTION_PASSWORD" ]; then
        arch-chroot /mnt sed -i 's/ block / block keyboard keymap /' /etc/mkinitcpio.conf
        arch-chroot /mnt sed -i 's/ filesystems keyboard / encrypt lvm2 filesystems /' /etc/mkinitcpio.conf
    elif [ "$LVM" == "true" ]; then
        arch-chroot /mnt sed -i 's/ keyboard / keyboard keymap /' /etc/mkinitcpio.conf
        arch-chroot /mnt sed -i 's/ filesystems / lvm2 filesystems /' /etc/mkinitcpio.conf
    elif [ -n "$PARTITION_ROOT_ENCRYPTION_PASSWORD" ]; then
        arch-chroot /mnt sed -i 's/ block / block keyboard keymap /' /etc/mkinitcpio.conf
        arch-chroot /mnt sed -i 's/ filesystems keyboard / encrypt filesystems /' /etc/mkinitcpio.conf
    else
        arch-chroot /mnt sed -i 's/ keyboard / keyboard keymap /' /etc/mkinitcpio.conf
    fi

    if [ "$KERNELS_COMPRESSION" != "" ]; then
        arch-chroot /mnt sed -i "s/#COMPRESSION=\"$KERNELS_COMPRESSION\"/COMPRESSION=\"$KERNELS_COMPRESSION\"/" /etc/mkinitcpio.conf
    fi

    arch-chroot /mnt mkinitcpio -P
}

function bootloader() {
    echo ""
    echo -e "${LIGHT_BLUE}# bootloader() step${NC}"
    echo ""

    UUID_BOOT=$(blkid -s UUID -o value $PARTITION_BOOT)
    UUID_ROOT=$(blkid -s UUID -o value $PARTITION_ROOT)

    BOOTLOADER_ALLOW_DISCARDS=""

    if [ "$CPU_INTEL" == "true" -a "$VIRTUALBOX" != "true" ]; then
        pacman_install "intel-ucode"
    fi
    if [ "$LVM" == "true" ]; then
        CMDLINE_LINUX_ROOT="root=$PARTITION_ROOT"
    else
        CMDLINE_LINUX_ROOT="root=UUID=$UUID_ROOT"
    fi
    if [ -n "$PARTITION_ROOT_ENCRYPTION_PASSWORD" ]; then
        if [ "$DEVICE_TRIM" == "true" ]; then
            BOOTLOADER_ALLOW_DISCARDS=":allow-discards"
        fi
        CMDLINE_LINUX="$CMDLINE_LINUX cryptdevice=UUID=$UUID_ROOT:$LVM_VOLUME_PHISICAL$BOOTLOADER_ALLOW_DISCARDS"
    fi
    if [ "$KMS" == "true" ]; then
        case "$DISPLAY_DRIVER" in
            "nvidia" | "nvidia-390xx" | "nvidia-390xx-lts" )
                CMDLINE_LINUX="$CMDLINE_LINUX nvidia-drm.modeset=1"
                ;;
        esac
    fi

    case "$BOOTLOADER" in
        "grub" )
            grub
            ;;
        "refind" )
            refind
            ;;
        "systemd" )
            systemd
            ;;
    esac
}

function grub() {
    pacman_install "grub os-prober"

    cp /mnt/etc/default/grub /mnt/etc/default/grub.bkp

    echo -e "GRUB_DEFAULT=0
GRUB_TIMEOUT=5
GRUB_DISTRIBUTOR=\"Arch\"
GRUB_CMDLINE_LINUX_DEFAULT=\""$CMDLINE_LINUX_DEFAULT"\"
GRUB_CMDLINE_LINUX=\""$CMDLINE_LINUX"\"
GRUB_PRELOAD_MODULES=\"part_gpt part_msdos\"
GRUB_TERMINAL_INPUT=console
GRUB_GFXMODE=auto
GRUB_GFXPAYLOAD_LINUX=keep
GRUB_DISABLE_RECOVERY=true" > /mnt/etc/default/grub

    if [ -n "$PARTITION_ROOT_ENCRYPTION_PASSWORD" ]; then
        echo -e "GRUB_ENABLE_CRYPTODISK=y" >> /mnt/etc/default/grub
    fi

    if [ "$BIOS_TYPE" == "uefi" ]; then
        pacman_install "efibootmgr"
        arch-chroot /mnt grub-install --target=x86_64-efi --bootloader-id=grub --efi-directory=$DIRECTORY_ESP --boot-directory=$DIRECTORY_BOOT --recheck
        if [ "$VIRTUALBOX" == "true" ]; then
            echo -n "\EFI\grub\grubx64.efi" > "/mnt$DIRECTORY_ESP/startup.nsh"
        fi
    fi
    if [ "$BIOS_TYPE" == "bios" ]; then
        arch-chroot /mnt grub-install --target=i386-pc --recheck $DEVICE
    fi

    mkdir /mnt/hostlvm
    mount --bind /run/lvm /mnt/hostlvm
    echo "ln -s /hostlvm /run/lvm; grub-mkconfig -o \"$DIRECTORY_BOOT/grub/grub.cfg\"" > /mnt/grub-mkconfig
    arch-chroot /mnt bash /grub-mkconfig
    rm -f /mnt/grub-mkconfig
    umount /mnt/hostlvm
    rmdir /mnt/hostlvm
}

function refind() {
    pacman_install "refind-efi"
    arch-chroot /mnt refind-install

    arch-chroot /mnt rm /boot/refind_linux.conf
    arch-chroot /mnt sed -i 's/^timeout.*/timeout 5/' "$DIRECTORY_ESP/EFI/refind/refind.conf"
    arch-chroot /mnt sed -i 's/^#scan_all_linux_kernels.*/scan_all_linux_kernels false/' "$DIRECTORY_ESP/EFI/refind/refind.conf"

    #arch-chroot /mnt sed -i 's/^#default_selection "+,bzImage,vmlinuz"/default_selection "+,bzImage,vmlinuz"/' "$DIRECTORY_ESP/EFI/refind/refind.conf"

    REFIND_MICROCODE=""

    if [ "$CPU_INTEL" == "true" -a "$VIRTUALBOX" != "true" ]; then
        REFIND_MICROCODE="initrd=/intel-ucode.img"
    fi

    echo "" >> "/mnt$DIRECTORY_ESP/EFI/refind/refind.conf"
    echo "# alis" >> "/mnt$DIRECTORY_ESP/EFI/refind/refind.conf"
    echo "menuentry \"Arch Linux\" {" >> "/mnt$DIRECTORY_ESP/EFI/refind/refind.conf"
    echo "    volume   $UUID_BOOT" >> "/mnt$DIRECTORY_ESP/EFI/refind/refind.conf"
    echo "    loader   /vmlinuz-linux" >> "/mnt$DIRECTORY_ESP/EFI/refind/refind.conf"
    echo "    initrd   /initramfs-linux.img" >> "/mnt$DIRECTORY_ESP/EFI/refind/refind.conf"
    echo "    icon     /EFI/refind/icons/os_arch.png" >> "/mnt$DIRECTORY_ESP/EFI/refind/refind.conf"
    echo "    options  \"$REFIND_MICROCODE $CMDLINE_LINUX_ROOT rw $CMDLINE_LINUX\"" >> "/mnt$DIRECTORY_ESP/EFI/refind/refind.conf"
    echo "    submenuentry \"Boot using fallback initramfs\" {" >> "/mnt$DIRECTORY_ESP/EFI/refind/refind.conf"
    echo "	      initrd /initramfs-linux-fallback.img" >> "/mnt$DIRECTORY_ESP/EFI/refind/refind.conf"
    echo "    }" >> "/mnt$DIRECTORY_ESP/EFI/refind/refind.conf"
    echo "    submenuentry \"Boot to terminal\" {" >> "/mnt$DIRECTORY_ESP/EFI/refind/refind.conf"
    echo "	      add_options \"systemd.unit=multi-user.target\"" >> "/mnt$DIRECTORY_ESP/EFI/refind/refind.conf"
    echo "    }" >> "/mnt$DIRECTORY_ESP/EFI/refind/refind.conf"
    echo "}" >> "/mnt$DIRECTORY_ESP/EFI/refind/refind.conf"
    echo "" >> "/mnt$DIRECTORY_ESP/EFI/refind/refind.conf"
    if [[ $KERNELS =~ .*linux-lts.* ]]; then
        echo "menuentry \"Arch Linux (lts)\" {" >> "/mnt$DIRECTORY_ESP/EFI/refind/refind.conf"
        echo "    volume   $UUID_BOOT" >> "/mnt$DIRECTORY_ESP/EFI/refind/refind.conf"
        echo "    loader   /vmlinuz-linux-lts" >> "/mnt$DIRECTORY_ESP/EFI/refind/refind.conf"
        echo "    initrd   /initramfs-linux-lts.img" >> "/mnt$DIRECTORY_ESP/EFI/refind/refind.conf"
        echo "    icon     /EFI/refind/icons/os_arch.png" >> "/mnt$DIRECTORY_ESP/EFI/refind/refind.conf"
        echo "    options  \"$REFIND_MICROCODE $CMDLINE_LINUX_ROOT rw $CMDLINE_LINUX\"" >> "/mnt$DIRECTORY_ESP/EFI/refind/refind.conf"
        echo "    submenuentry \"Boot using fallback initramfs\" {" >> "/mnt$DIRECTORY_ESP/EFI/refind/refind.conf"
        echo "	      initrd /initramfs-linux-lts-fallback.img" >> "/mnt$DIRECTORY_ESP/EFI/refind/refind.conf"
        echo "    }" >> "/mnt$DIRECTORY_ESP/EFI/refind/refind.conf"
        echo "    submenuentry \"Boot to terminal\" {" >> "/mnt$DIRECTORY_ESP/EFI/refind/refind.conf"
        echo "	      add_options \"systemd.unit=multi-user.target\"" >> "/mnt$DIRECTORY_ESP/EFI/refind/refind.conf"
        echo "    }" >> "/mnt$DIRECTORY_ESP/EFI/refind/refind.conf"
        echo "}" >> "/mnt$DIRECTORY_ESP/EFI/refind/refind.conf"
        echo "" >> "/mnt$DIRECTORY_ESP/EFI/refind/refind.conf"
    fi
    if [[ $KERNELS =~ .*linux-hardened.* ]]; then
        echo "menuentry \"Arch Linux (hardened)\" {" >> "/mnt$DIRECTORY_ESP/EFI/refind/refind.conf"
        echo "    volume   $UUID_BOOT" >> "/mnt$DIRECTORY_ESP/EFI/refind/refind.conf"
        echo "    loader   /vmlinuz-linux-hardened" >> "/mnt$DIRECTORY_ESP/EFI/refind/refind.conf"
        echo "    initrd   /initramfs-linux-hardened.img" >> "/mnt$DIRECTORY_ESP/EFI/refind/refind.conf"
        echo "    icon     /EFI/refind/icons/os_arch.png" >> "/mnt$DIRECTORY_ESP/EFI/refind/refind.conf"
        echo "    options  \"$REFIND_MICROCODE $CMDLINE_LINUX_ROOT rw $CMDLINE_LINUX\"" >> "/mnt$DIRECTORY_ESP/EFI/refind/refind.conf"
        echo "    submenuentry \"Boot using fallback initramfs\" {" >> "/mnt$DIRECTORY_ESP/EFI/refind/refind.conf"
        echo "	      initrd /initramfs-linux-hardened-fallback.img" >> "/mnt$DIRECTORY_ESP/EFI/refind/refind.conf"
        echo "    }" >> "/mnt$DIRECTORY_ESP/EFI/refind/refind.conf"
        echo "    submenuentry \"Boot to terminal\" {" >> "/mnt$DIRECTORY_ESP/EFI/refind/refind.conf"
        echo "	      add_options \"systemd.unit=multi-user.target\"" >> "/mnt$DIRECTORY_ESP/EFI/refind/refind.conf"
        echo "    }" >> "/mnt$DIRECTORY_ESP/EFI/refind/refind.conf"
        echo "}" >> "/mnt$DIRECTORY_ESP/EFI/refind/refind.conf"
        echo "" >> "/mnt$DIRECTORY_ESP/EFI/refind/refind.conf"
    fi
    if [[ $KERNELS =~ .*linux-zen.* ]]; then
        echo "menuentry \"Arch Linux (zen)\" {" >> "/mnt$DIRECTORY_ESP/EFI/refind/refind.conf"
        echo "    volume   $UUID_BOOT" >> "/mnt$DIRECTORY_ESP/EFI/refind/refind.conf"
        echo "    loader   /vmlinuz-linux-zen" >> "/mnt$DIRECTORY_ESP/EFI/refind/refind.conf"
        echo "    initrd   /initramfs-linux-zen.img" >> "/mnt$DIRECTORY_ESP/EFI/refind/refind.conf"
        echo "    icon     /EFI/refind/icons/os_arch.png" >> "/mnt$DIRECTORY_ESP/EFI/refind/refind.conf"
        echo "    options  \"$REFIND_MICROCODE $CMDLINE_LINUX_ROOT rw $CMDLINE_LINUX\"" >> "/mnt$DIRECTORY_ESP/EFI/refind/refind.conf"
        echo "    submenuentry \"Boot using fallback initramfs\" {" >> "/mnt$DIRECTORY_ESP/EFI/refind/refind.conf"
        echo "	      initrd /initramfs-linux-zen-fallback.img" >> "/mnt$DIRECTORY_ESP/EFI/refind/refind.conf"
        echo "    }" >> "/mnt$DIRECTORY_ESP/EFI/refind/refind.conf"
        echo "    submenuentry \"Boot to terminal\" {" >> "/mnt$DIRECTORY_ESP/EFI/refind/refind.conf"
        echo "	      add_options \"systemd.unit=multi-user.target\"" >> "/mnt$DIRECTORY_ESP/EFI/refind/refind.conf"
        echo "    }" >> "/mnt$DIRECTORY_ESP/EFI/refind/refind.conf"
        echo "}" >> "/mnt$DIRECTORY_ESP/EFI/refind/refind.conf"
        echo "" >> "/mnt$DIRECTORY_ESP/EFI/refind/refind.conf"
    fi

    if [ "$VIRTUALBOX" == "true" ]; then
        echo -n "\EFI\refind\refind_x64.efi" > "/mnt$DIRECTORY_ESP/startup.nsh"
    fi
}

function systemd() {
    arch-chroot /mnt bootctl --path="$DIRECTORY_ESP" install

    arch-chroot /mnt mkdir -p "$DIRECTORY_ESP/loader/"
    arch-chroot /mnt mkdir -p "$DIRECTORY_ESP/loader/entries/"

    echo "# alis" > "/mnt$DIRECTORY_ESP/loader/loader.conf"
    echo "timeout 5" >> "/mnt$DIRECTORY_ESP/loader/loader.conf"
    echo "default archlinux" >> "/mnt$DIRECTORY_ESP/loader/loader.conf"
    echo "editor 0" >> "/mnt$DIRECTORY_ESP/loader/loader.conf"

    arch-chroot /mnt mkdir -p "/etc/pacman.d/hooks/"

    echo "[Trigger]" >> /mnt/etc/pacman.d/hooks/systemd-boot.hook
    echo "Type = Package" >> /mnt/etc/pacman.d/hooks/systemd-boot.hook
    echo "Operation = Upgrade" >> /mnt/etc/pacman.d/hooks/systemd-boot.hook
    echo "Target = systemd" >> /mnt/etc/pacman.d/hooks/systemd-boot.hook
    echo "" >> /mnt/etc/pacman.d/hooks/systemd-boot.hook
    echo "[Action]" >> /mnt/etc/pacman.d/hooks/systemd-boot.hook
    echo "Description = Updating systemd-boot..." >> /mnt/etc/pacman.d/hooks/systemd-boot.hook
    echo "When = PostTransaction" >> /mnt/etc/pacman.d/hooks/systemd-boot.hook
    echo "Exec = /usr/bin/bootctl update" >> /mnt/etc/pacman.d/hooks/systemd-boot.hook

    SYSTEMD_MICROCODE=""
    SYSTEMD_OPTIONS=""

    if [ "$CPU_INTEL" == "true" -a "$VIRTUALBOX" != "true" ]; then
        SYSTEMD_MICROCODE="/intel-ucode.img"
    fi

    if [ -n "$PARTITION_ROOT_ENCRYPTION_PASSWORD" ]; then
       SYSTEMD_OPTIONS="rd.luks.options=discard"
    fi

    echo "title Arch Linux" >> "/mnt$DIRECTORY_ESP/loader/entries/archlinux.conf"
    echo "efi /vmlinuz-linux" >> "/mnt$DIRECTORY_ESP/loader/entries/archlinux.conf"
    if [ -n "$SYSTEMD_MICROCODE" ]; then
        echo "initrd $SYSTEMD_MICROCODE" >> "/mnt$DIRECTORY_ESP/loader/entries/archlinux.conf"
    fi
    echo "initrd /initramfs-linux.img" >> "/mnt$DIRECTORY_ESP/loader/entries/archlinux.conf"
    echo "options initrd=initramfs-linux.img $CMDLINE_LINUX_ROOT rw $CMDLINE_LINUX $SYSTEMD_OPTIONS" >> "/mnt$DIRECTORY_ESP/loader/entries/archlinux.conf"

    echo "title Arch Linux (fallback)" >> "/mnt$DIRECTORY_ESP/loader/entries/archlinux-fallback.conf"
    echo "efi /vmlinuz-linux" >> "/mnt$DIRECTORY_ESP/loader/entries/archlinux-fallback.conf"
    if [ -n "$SYSTEMD_MICROCODE" ]; then
        echo "initrd $SYSTEMD_MICROCODE" >> "/mnt$DIRECTORY_ESP/loader/entries/archlinux-fallback.conf"
    fi
    echo "initrd /initramfs-linux-fallback.img" >> "/mnt$DIRECTORY_ESP/loader/entries/archlinux-fallback.conf"
    echo "options initrd=initramfs-linux-fallback.img $CMDLINE_LINUX_ROOT rw $CMDLINE_LINUX $SYSTEMD_OPTIONS" >> "/mnt$DIRECTORY_ESP/loader/entries/archlinux-fallback.conf"

    if [[ $KERNELS =~ .*linux-lts.* ]]; then
        echo "title Arch Linux (lts)" >> "/mnt$DIRECTORY_ESP/loader/entries/archlinux-lts.conf"
        echo "efi /vmlinuz-linux-lts" >> "/mnt$DIRECTORY_ESP/loader/entries/archlinux-lts.conf"
        if [ -n "$SYSTEMD_MICROCODE" ]; then
            echo "initrd $SYSTEMD_MICROCODE" >> "/mnt$DIRECTORY_ESP/loader/entries/archlinux.conf"
        fi
        echo "initrd /initramfs-linux-lts.img" >> "/mnt$DIRECTORY_ESP/loader/entries/archlinux-lts.conf"
        echo "options initrd=initramfs-linux-lts.img $CMDLINE_LINUX_ROOT rw $CMDLINE_LINUX $SYSTEMD_OPTIONS" >> "/mnt$DIRECTORY_ESP/loader/entries/archlinux-lts.conf"

        echo "title Arch Linux (lts-fallback)" >> "/mnt$DIRECTORY_ESP/loader/entries/archlinux-lts-fallback.conf"
        echo "efi /vmlinuz-linux-lts" >> "/mnt$DIRECTORY_ESP/loader/entries/archlinux-lts-fallback.conf"
        if [ "$CPU_INTEL" == "true" -a "$VIRTUALBOX" != "true" ]; then
            echo "initrd $SYSTEMD_MICROCODE" >> "/mnt$DIRECTORY_ESP/loader/entries/archlinux-lts-fallback.conf"
        fi
        echo "initrd /initramfs-linux-lts-fallback.img" >> "/mnt$DIRECTORY_ESP/loader/entries/archlinux-lts-fallback.conf"
        echo "options initrd=initramfs-linux-lts-fallback.img $CMDLINE_LINUX_ROOT rw $CMDLINE_LINUX $SYSTEMD_OPTIONS" >> "/mnt$DIRECTORY_ESP/loader/entries/archlinux-lts-fallback.conf"
    fi

    if [[ $KERNELS =~ .*linux-hardened.* ]]; then
        echo "title Arch Linux (hardened)" >> "/mnt$DIRECTORY_ESP/loader/entries/archlinux-hardened.conf"
        echo "efi /vmlinuz-linux-hardened" >> "/mnt$DIRECTORY_ESP/loader/entries/archlinux-hardened.conf"
        if [ -n "$SYSTEMD_MICROCODE" ]; then
            echo "initrd $SYSTEMD_MICROCODE" >> "/mnt$DIRECTORY_ESP/loader/entries/archlinux.conf"
        fi
        echo "initrd /initramfs-linux-hardened.img" >> "/mnt$DIRECTORY_ESP/loader/entries/archlinux-hardened.conf"
        echo "options initrd=initramfs-linux-hardened.img $CMDLINE_LINUX_ROOT rw $CMDLINE_LINUX $SYSTEMD_OPTIONS" >> "/mnt$DIRECTORY_ESP/loader/entries/archlinux-hardened.conf"

        echo "title Arch Linux (hardened-fallback)" >> "/mnt$DIRECTORY_ESP/loader/entries/archlinux-hardened-fallback.conf"
        echo "efi /vmlinuz-linux-hardened" >> "/mnt$DIRECTORY_ESP/loader/entries/archlinux-hardened-fallback.conf"
        if [ -n "$SYSTEMD_MICROCODE" ]; then
            echo "initrd $SYSTEMD_MICROCODE" >> "/mnt$DIRECTORY_ESP/loader/entries/archlinux-hardened-fallback.conf"
        fi
        echo "initrd /initramfs-linux-hardened-fallback.img" >> "/mnt$DIRECTORY_ESP/loader/entries/archlinux-hardened-fallback.conf"
        echo "options initrd=initramfs-linux-hardened-fallback.img $CMDLINE_LINUX_ROOT rw $CMDLINE_LINUX $SYSTEMD_OPTIONS" >> "/mnt$DIRECTORY_ESP/loader/entries/archlinux-hardened-fallback.conf"
    fi

    if [[ $KERNELS =~ .*linux-zen.* ]]; then
        echo "title Arch Linux (zen)" >> "/mnt$DIRECTORY_ESP/loader/entries/archlinux-zen.conf"
        echo "efi /vmlinuz-linux-zen" >> "/mnt$DIRECTORY_ESP/loader/entries/archlinux-zen.conf"
        if [ -n "$SYSTEMD_MICROCODE" ]; then
            echo "initrd $SYSTEMD_MICROCODE" >> "/mnt$DIRECTORY_ESP/loader/entries/archlinux.conf"
        fi
        echo "initrd /initramfs-linux-zen.img" >> "/mnt$DIRECTORY_ESP/loader/entries/archlinux-zen.conf"
        echo "options initrd=initramfs-linux-zen.img $CMDLINE_LINUX_ROOT rw $CMDLINE_LINUX $SYSTEMD_OPTIONS" >> "/mnt$DIRECTORY_ESP/loader/entries/archlinux-zen.conf"

        echo "title Arch Linux (zen-fallback)" >> "/mnt$DIRECTORY_ESP/loader/entries/archlinux-zen-fallback.conf"
        echo "efi /vmlinuz-linux-zen" >> "/mnt$DIRECTORY_ESP/loader/entries/archlinux-zen-fallback.conf"
        if [ -n "$SYSTEMD_MICROCODE" ]; then
            echo "initrd $SYSTEMD_MICROCODE" >> "/mnt$DIRECTORY_ESP/loader/entries/archlinux-zen-fallback.conf"
        fi
        echo "initrd /initramfs-linux-zen-fallback.img" >> "/mnt$DIRECTORY_ESP/loader/entries/archlinux-zen-fallback.conf"
        echo "options initrd=initramfs-linux-zen-fallback.img $CMDLINE_LINUX_ROOT rw $CMDLINE_LINUX $SYSTEMD_OPTIONS" >> "/mnt$DIRECTORY_ESP/loader/entries/archlinux-zen-fallback.conf"
    fi

    if [ "$VIRTUALBOX" == "true" ]; then
        echo -n "\EFI\systemd\systemd-bootx64.efi" > "/mnt$DIRECTORY_ESP/startup.nsh"
    fi
}

function desktop_environment() {
    echo ""
    echo -e "${LIGHT_BLUE}# desktop_environment() step${NC}"
    echo ""

    PACKAGES_DRIVER=""
    PACKAGES_DDX=""
    PACKAGES_VULKAN=""
    PACKAGES_HARDWARE_ACCELERATION=""
    case "$DISPLAY_DRIVER" in
        "nvidia" )
            PACKAGES_DRIVER="nvidia nvidia-dkms"
            ;;
        "nvidia-lts" )
            PACKAGES_DRIVER="nvidia-lts nvidia-dkms"
            ;;
        "nvidia-390xx" )
            PACKAGES_DRIVER="nvidia-390xx nvidia-390xx-dkms"
            ;;
        "nvidia-390xx-lts" )
            PACKAGES_DRIVER="nvidia-390xx-lts nvidia-390xx-dkms"
            ;;
        "nvidia-340xx" )
            PACKAGES_DRIVER="nvidia-340xx nvidia-340xx-dkms"
            ;;
        "nvidia-340xx-lts" )
            PACKAGES_DRIVER="nvidia-340xx-lts nvidia-340xx-dkms"
            ;;
    esac
    if [ "$DISPLAY_DRIVER_DDX" == "true" ]; then
        case "$DISPLAY_DRIVER" in
            "intel" )
                PACKAGES_DDX="xf86-video-intel"
                ;;
            "amdgpu" )
                PACKAGES_DDX="xf86-video-amdgpu"
                ;;
            "ati" )
                PACKAGES_DDX="xf86-video-ati"
                ;;
            "nouveau" )
                PACKAGES_DDX="xf86-video-nouveau"
                ;;
        esac
    fi
    if [ "$VULKAN" == "true" ]; then
        case "$DISPLAY_DRIVER" in
            "intel" )
                PACKAGES_VULKAN="vulkan-icd-loader vulkan-intel"
                ;;
            "amdgpu" )
                PACKAGES_VULKAN="vulkan-icd-loader vulkan-radeon"
                ;;
            "ati" )
                PACKAGES_VULKAN=""
                ;;
            "nouveau" )
                PACKAGES_VULKAN=""
                ;;
        esac
    fi
    if [ "$DISPLAY_DRIVER_HARDWARE_ACCELERATION" == "true" ]; then
        case "$DISPLAY_DRIVER" in
            "intel" )
                PACKAGES_HARDWARE_ACCELERATION="intel-media-driver"
                if [ -n "$DISPLAY_DRIVER_HARDWARE_ACCELERATION_INTEL" ]; then
                    PACKAGES_HARDWARE_ACCELERATION=$DISPLAY_DRIVER_HARDWARE_ACCELERATION_INTEL
                fi
                ;;
            "amdgpu" )
                PACKAGES_HARDWARE_ACCELERATION="libva-mesa-driver"
                ;;
            "ati" )
                PACKAGES_HARDWARE_ACCELERATION="mesa-vdpau"
                ;;
            "nouveau" )
                PACKAGES_HARDWARE_ACCELERATION="libva-mesa-driver"
                ;;
        esac
    fi
    pacman_install "mesa $PACKAGES_DRIVER $PACKAGES_DDX $PACKAGES_VULKAN $PACKAGES_HARDWARE_ACCELERATION"

    case "$DESKTOP_ENVIRONMENT" in
        "gnome" )
            desktop_environment_gnome
            ;;
        "kde" )
            desktop_environment_kde
            ;;
        "xfce" )
            desktop_environment_xfce
            ;;
        "mate" )
            desktop_environment_mate
            ;;
        "cinnamon" )
            desktop_environment_cinnamon
            ;;
        "lxde" )
            desktop_environment_lxde
            ;;
        "deepin" )
            desktop_environment_deepin
            ;;
    esac
}

function desktop_environment_gnome() {
    pacman_install "gnome gnome-extra"
    arch-chroot /mnt systemctl enable gdm.service
}

function desktop_environment_kde() {
    pacman_install "plasma-meta kde-applications-meta"
    arch-chroot /mnt sed -i 's/Current=.*/Current=breeze/' /etc/sddm.conf
    arch-chroot /mnt systemctl enable sddm.service
}

function desktop_environment_xfce() {
    pacman_install "xfce4 xfce4-goodies lightdm lightdm-gtk-greeter"
    arch-chroot /mnt systemctl enable lightdm.service
}

function desktop_environment_mate() {
    pacman_install "mate mate-extra lightdm lightdm-gtk-greeter"
    arch-chroot /mnt systemctl enable lightdm.service
}

function desktop_environment_cinnamon() {
    pacman_install "cinnamon lightdm lightdm-gtk-greeter"
    arch-chroot /mnt systemctl enable lightdm.service
}

function desktop_environment_lxde() {
    pacman_install "clxde lxdm"
    arch-chroot /mnt systemctl enable lxdm.service
}

function desktop_environment_deepin() {
    pacman_install "deepin deepin-calculator deepin-community-wallpapers deepin-editor deepin-screen-recorder deepin-screenshot deepin-terminal"
    arch-chroot /mnt sed -i 's/#greeter-session.*/greeter-session=lightdm-deepin-greeter/' /etc/lightdm/lightdm.conf
    arch-chroot /mnt systemctl enable lightdm.service
}

function packages() {
    echo ""
    echo -e "${LIGHT_BLUE}# packages() step${NC}"
    echo ""

    if [ "$FILE_SYSTEM_TYPE" == "btrfs" ]; then
        pacman_install "btrfs-progs"
    fi

    if [ -n "$PACKAGES_PACMAN" ]; then
        pacman_install "$PACKAGES_PACMAN"
    fi

    packages_aur
}

function packages_aur() {
    if [ -n "$AUR" -o -n "$PACKAGES_AUR" ]; then
        pacman_install "git archlinux-keyring"
        arch-chroot /mnt pacman-key --populate archlinux

        arch-chroot /mnt sed -i 's/%wheel ALL=(ALL) ALL/%wheel ALL=(ALL) NOPASSWD: ALL/' /etc/sudoers
        case "$AUR" in
            "aurman" )
                arch-chroot /mnt bash -c "su $USER_NAME -c \"cd /home/$USER_NAME && git clone https://aur.archlinux.org/$AUR.git && (cd $AUR && makepkg -si --skippgpcheck --noconfirm) && rm -rf $AUR\""
                ;;
            "yay" )
                arch-chroot /mnt bash -c "su $USER_NAME -c \"cd /home/$USER_NAME && git clone https://aur.archlinux.org/$AUR.git && (cd $AUR && makepkg -si --skippgpcheck --noconfirm) && rm -rf $AUR\""
                ;;
        esac
        arch-chroot /mnt sed -i 's/%wheel ALL=(ALL) NOPASSWD: ALL/%wheel ALL=(ALL) ALL/' /etc/sudoers
    fi

    if [ -n "$PACKAGES_AUR" ]; then
        aur_install "$PACKAGES_AUR"
    fi
}

function terminate() {
    if [ "$LOG" == "true" ]; then
        mkdir -p /mnt/var/log
        cp "alis.log" "/mnt/var/log/alis.log"
    fi
    umount_partitions
}

function end() {
    if [ "$REBOOT" == "true" ]; then
        echo ""
        echo -e "${GREEN}Arch Linux installed successfully"'!'"${NC}"
        echo ""

        REBOOT="true"
        set +e
        for (( i = 15; i >= 1; i-- )); do
            read -r -s -n 1 -t 1 -p "Rebooting in $i seconds... Press any key to abort."$'\n' KEY
            if [ $? -eq 0 ]; then
                echo ""
                echo "Restart aborted. You have to do a reboot."
                echo ""
                REBOOT="false"
                break
            fi
        done
        set -e

        if [ "$REBOOT" == 'true' ]; then
            reboot
        fi
    else
        echo ""
        echo -e "${GREEN}Arch Linux installed successfully"'!'"${NC}"
        echo ""
        echo "You have to do a reboot."
        echo ""
    fi
}

function pacman_install() {
    PACKAGES=$1
    for VARIABLE in {1..5}
    do
        arch-chroot /mnt pacman -Syu --noconfirm $PACKAGES
        if [ $? == 0 ]; then
            break
        else
            sleep 10
        fi
    done
}

function aur_install() {
    PACKAGES=$1
    for VARIABLE in {1..5}
    do
        arch-chroot /mnt bash -c "su $USER_NAME -c \"$AUR -Syu --noconfirm --needed $PACKAGES\""
        if [ $? == 0 ]; then
            break
        else
            sleep 10
        fi
    done
}

function create_user() {
    echo ""
    echo -e "${LIGHT_BLUE}# create_user() step${NC}"
    echo ""

	USER_NAME=$1
	USER_PASSWORD=$2
    arch-chroot /mnt useradd -m -G wheel,storage -s /bin/bash $USER_NAME
    printf "$USER_PASSWORD\n$USER_PASSWORD" | arch-chroot /mnt passwd $USER_NAME
}

function main() {
    configuration_install
    sanitize_variables
    check_variables
    facts
    check_facts
    warning
    init
    prepare
    if [ "$FORMATDISK" == "true" ]; then
        format_disk
    fi
    partition
    install
    kernels
    configuration
    network
    if [ "$VIRTUALBOX" == "true" ]; then
        virtualbox
    fi
    users
    mkinitcpio
    bootloader
    if [ "$DESKTOP_ENVIRONMENT" != "" ]; then
        desktop_environment
    fi
    packages
    terminate
    end
}

main
