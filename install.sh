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

#This is info we will need for the rest of the script, may as well collect it early
read -p 'Enter your desired hostname: ' hostname

read -p 'Enter your desired default username: ' user1
if ["$user1" == 'root']
then
    while["$user1" == 'root']
    do
        echo 'The default user cannot be root.'
        read -p 'Enter your desired default username: ' user1
    done
fi

read -sp 'Enter your desired password: ' pass1
read -sp 'Confirm your desired password: ' confirmPass1
if ["$pass1" == "$confirmPass1"]
then
    while["$pass1" == "$confirmPass1"]
    do
        echo 'Entered passwords do not match.'
        read -sp 'Enter your desired password: ' pass1
        read -sp 'Confirm your desired password: ' confirmPass1
    done
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
    do
        echo Enter the two-letter code for the language of your keyboard. 
        read -p '(If English, enter the keyboard style you will use [i.e. dvorak]): ' keymapSearch
        localectl list-keymaps | grep -i $keymapSearch
        read -p 'Enter the correct code for your keyboard, or if not available, leave blank to search again: ' keymap
        if [-n "$keymap"]
        then
            loadkeys $keymap
            keymapSet=1
        fi
    done
else
    loadkeys us
fi

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
echo - 512MB FAT32 boot partition  \(Boot partition must be in FAT32\)
echo - the remaining space of the drive \(File system type will be set later \)
read -p 'If you are unsure what this means, say yes (Y/n): ' defaultPartition
if ["$defaultPartition" == "n" -o "$defaultPartition" == "N"]
then
    echo From here, I assume you know what you are doing.
    echo I will temporarily drop you back into the shell. When you are done partitioning, exit the shell to continue.
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
    fdisk /dev/$drivePart1 -W always<<EOF
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
fi
## Explanation of fdisk commands:
# --------------------------------
# g creates a GPT partition table
# The first n, and all lines up to the next n, creates a new partition, with size 512MB
# The second n, and all lines to the t, create a second partition, taking up the rest of the drive.
# the first t, and following digits, labels the first partition as a boot partition.
# The second t, and the following digits, labels the second partition as a Linux root partition
# The w writes out the changes in memory to the disk.

### -----------------------
#   Format Partitions
### -----------------------

### -----------------------
#   Mount File Systems
### -----------------------

### -----------------------
#   Set Mirrors
### -----------------------

### -----------------------
#   Install packages
### -----------------------

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

