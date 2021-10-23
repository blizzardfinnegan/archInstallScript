#!/bin/bash
# Generalized arch install script
# NOTE: This script will not work on older BIOS boot computers. 
# NOTE: This script assumes you already have networking access, and that it is being run on x86-64 hardware.

#Error-catching: Any error will cancel out of the script, and tell you what line caused the crash
set -e
trap 'echo "An error has occurred on line $LINENO. Exiting script..."' ERR

### ------------------
#   Variable naming
### ------------------
languageLocale="LANG=en_US.UTF-8"
countryLocation="United States"
keymapDefault="KEYMAP=us"

## Ensure Reflector is installed for later
pacman -Syy
pacman -S reflector

#This is info we will need for the rest of the script, may as well collect it early
read -p 'Enter your desired hostname: ' hostname

read -p 'Enter your desired default username: ' user1
if ["$user1" == 'root']
then
    while[ "$user1" == 'root' ]
    do$'\r'
        echo 'The default user cannot be root.'
        read -p 'Enter your desired default username: ' user1
    done$'\r'
fi

read -sp 'Enter your desired password: ' pass1
read -sp 'Confirm your desired password: ' confirmPass1
if ["$pass1" == "$confirmPass1"]
then
    while[ "$pass1" == "$confirmPass1" ]
    do$'\r'
        echo 'Entered passwords do not match.'
        read -sp 'Enter your desired password: ' pass1
        read -sp 'Confirm your desired password: ' confirmPass1
    done$'\r'
fi

### -----------------------
#   Set Keyboard Layout
### -----------------------
read -p 'Do you use a non-QWERTY keyboard? (y/N): ' qwertyness
#This checks with the user for keyboard type, defaulting to QWERTY-US
if ["$qwertyness" == "y" -o "$qwertyness" == "Y"]
then
    keymapSet=0
    while [keymapSet -eq 0]
    do$'\r'
        echo Enter the two-letter code for the language of your keyboard. 
        read -p '(If English, enter the keyboard style you will use [i.e. dvorak]): ' keymapSearch
        localectl list-keymaps | grep -i $keymapSearch
        read -p 'Enter the correct code for your keyboard, or if not available, leave blank to search again: ' keymap
        if [-n "$keymap"]
        then
            loadkeys $keymap
            keymapSet=1
        fi
    done$'\r'
else$'\r'
    loadkeys us
fi$'\r'

### -----------------------
#   Boot Mode Verification
### -----------------------
#   If the script crashes here, you have booted into BIOS mode rather than UEFI.
#   Ensure that your system supports UEFI boot before continuing.
ls /sys/firmware/efi/efivars

### -----------------------
#   Update System Clock
### -----------------------
timedatectl set-ntp true

### -----------------------
#   Partition Disk
### -----------------------
echo Do you want to use the default disk partition scheme?
echo Default partition scheme:
echo '- 512MB FAT32 boot partition  (Boot partition must be in FAT32)'
echo '- the remaining space of the drive File system type will be set later )'
read -p 'If you are unsure what this means, say yes (Y/n): ' defaultPartition
if ["$defaultPartition" == "n" -o "$defaultPartition" == "N"]
then
    echo From here, I assume you know what you are doing.
    echo For this script to work properly, you will need to manually
    echo partition the drives, as well as format the partitions 
    echo and mount the drives.
    echo When you are done, exit the shell to continue.
    bash
else
    lsblk | grep -v '-' | grep -v 'rom'| awk -v OFS='\t' '{pring $1, $4}'
    # This prints the major disks, and their storage sizes.
    # The grep portion of the command removes all lines that have a '-' in it
    #   This leaves us only with high-level drive names.
    # The second grep command removes 'rom' devices (read as: DVD/Blu-Ray drives)
    # The awk command only prints the first and 4th columns (name and size). 
    #   The -v OFS changes the Output Field Separator to be "\t", the escape character for Tab
    read -p 'Enter a drive to be partitioned.' drivePart1
    drivePart1=/dev/$drivePart1
    fdisk $drivePart1 -W always<<EOF
g
n
1

+512M
n
2


t
1
1
t
2
23
w
EOF
## Explanation of fdisk commands:
# --------------------------------
# g creates a GPT partition table
# The first n, and all lines up to the next n, creates a new partition, with size 512MB
# The second n, and all lines to the t, create a second partition, taking up the rest of the drive.
# the first t, and following digits, labels the first partition as a boot partition.
# The second t, and the following digits, labels the second partition as a Linux root partition
# The w writes out the changes in memory to the disk.

## Internal variable shifting
bootPartition=${drivePart1}1
rootDrivePart=${drivePart1}2

### -----------------------
#   Format Partitions
### -----------------------
#   Because of the complexity of manually encrypting data, this is not currently supported. It may get implemented in the future.

echo Currently supported root file systems:
read -p '(b)trfs/(E)xt4' fileSystem
if [ "$fileSystem" == 'b' -o "$fileSystem" == 'B' ]
then
    mkfs.btrfs -L "Root Drive" $rootDrivePart
elif [ "$filesystem" == 'e' -o "$filesystem" == 'E' ]
then
    mkfs.ext4 $rootDrivePart
fi

### -----------------------
#   Mount File Systems
### -----------------------
mkdir /mnt/boot
mount $rootDrivePart /mnt
mount $bootPartition /mnt/boot
fi
### -----------------------
#   Set Mirrors
### -----------------------
reflector -c $countryLocation -p https -f 10 --sort rate --save /etc/pacman.d/mirrorlist
pacman -Syy

### -----------------------
#   Install packages
### -----------------------
echo What version of the kernel would you like to use?
echo "- linux: This is the most up to date version of the kernel."
echo "- linux-lts: This is the long-term-service kernel."
echo "- linux-hardened: This is a security focused linux kernel."
echo "- linux-zen: This is a kernel that is slightly slower to update than the stable version, but has some creature comforts."
echo "(Note: If you enter an invalid character, this will default to LTS, for safety.)"
read -p '(l)inux/linux-l(T)s/linux-(h)ardened/linux-(z)en: ' kernelVersionShort
if [ "$kernelVersionShort" == 'l' -o "$kernelVersionShort" == 'L' ]
then
    kernelVersion=linux
elif [ "$kernelVersionShort" == 'h' -o "$kernelVersionShort" == 'H' ]
then
    kernelVersion=linux-hardened
elif [ "$kernelVersionShort" == 'z' -o "$kernelVersionShort" == 'Z' ]
then
    kernelVersion=linux-zen
else
    kernelVersion=linux-lts
fi
pacstrap /mnt base $kernelVersion ${kernelVersion}-firmware ${kernelVersion}-docs btrfs-progs iwd vim sed git man man-db man-pages texinfo bash zsh nano

### -----------------------
#   Configure fstab
### -----------------------


### -----------------------
#   Set Timezone
### -----------------------

### -----------------------
#   Localization
### -----------------------

### -----------------------
#   Network Configuration
### -----------------------

### -----------------------
#   Initramfs
### -----------------------

### -----------------------
#   Set Root Password
### -----------------------

### -----------------------
#   Create User
### -----------------------

### -----------------------
#   Enable Sudo
### -----------------------

### -----------------------
#   Pacman Config
### -----------------------

### -----------------------
#   Repository Config
### -----------------------

### -----------------------
#   Yay Installation
### -----------------------
exit 0
