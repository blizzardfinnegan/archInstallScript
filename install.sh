#!/bin/bash
# Generalized arch install script
# NOTE: This script will not work on older BIOS boot computers. 

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
        read -p 'Enter the two-letter code for the language of your keyboard. (If English, enter the keyboard style you will use [i.e. dvorak]): ' keymapSearch
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

### -----------------------
#   Partition Disk
### -----------------------
# Notes for later
# lsblk | grep -v '-' | awk -v OFS='\t' '{pring $1, $4}'
# This prints the major disks, and their storage sizes.

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

