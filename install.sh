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
# The following lines is temporarily commented out, as this script is being developed on Debian
#pacman -Syy
#pacman -S reflector

#This is info we will need for the rest of the script, may as well collect it early
echo 'What is your timezone offset?'
read -p 'Please enter either "+n" or "-n", where n is a number: ' timezoneOffset
timezoneOffset=GMT$timezoneOffset

echo 'Are you using an AMD or Intel processor?'
read -p '(a)MD/(i)ntel: ' processorType
if [ "$processorType" == 'a' -o "$processorType" == 'A' ]
then
    microcode=amd-ucode
elif [ "$processorType" == 'i' -o "$processorType" == 'I' ]
then
    microcode=intel-ucode
fi

read -p 'Are you using a graphics card? (y/N): ' iGPU
if [ "$iGPU" == 'y' -o "$iGPU" == 'Y' ]
then
    read -p 'Are you using an AMD or NVidia graphics card? (a/n): ' dGPU
    if [ "$dGPU" == 'a' -o "$dGPU" == 'A' ]
    then
        graphicsDriver=mesa lib-32mesa mesa-vdpau lib32-mesa-vdpau
    elif [ "$dGPU" == 'n' -o "$dGPU" == 'N' ]
    then
        graphicsDriver=nvidia lib31-nvidia-utils
    else
        graphicsDriver=mesa lib32-mesa
    fi
else
    graphicsDriver=mesa lib32-mesa
fi

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
'
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

read -sp 'Enter your desired ROOT password: ' rootPass
read -sp 'Confirm your desired ROOT password: ' confirmRootPass
if ["$rootPass" == "$confirmRootPass"]
then
    while[ "$rootPass" == "$confirmRootPass" ]
    do$'\r'
        echo 'Entered passwords do not match.'
        read -sp 'Enter your desired ROOT password: ' rootPass         
        read -sp 'Confirm your desired ROOT password: ' confirmRootPass
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
        localectl list-keymaps | grep -i "$keymapSearch"
        read -p 'Enter the correct code for your keyboard, or if not available, leave blank to search again: ' keymap
        if [-n "$keymap"]
        then
            loadkeys "$keymap"
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
    drivePart1=/dev/"$drivePart1"
    fdisk "$drivePart1" -W always<<EOF
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
bootPartition="${drivePart1}"1
rootDrivePart="${drivePart1}"2

### -----------------------
#   Format Partitions
### -----------------------
#   Because of the complexity of manually encrypting data, this is not currently supported. It may get implemented in the future.

echo Currently supported root file systems:
read -p '(b)trfs/(E)xt4' fileSystem
if [ "$fileSystem" == 'b' -o "$fileSystem" == 'B' ]
then
    mkfs.btrfs -L "Root Drive" "$rootDrivePart"
elif [ "$filesystem" == 'e' -o "$filesystem" == 'E' ]
then
    mkfs.ext4 "$rootDrivePart"
fi

### -----------------------
#   Mount File Systems
### -----------------------
mkdir /mnt/boot
mount "$rootDrivePart" /mnt
mount "$bootPartition" /mnt/boot
fi
### -----------------------
#   Set Mirrors
### -----------------------
reflector -c "$countryLocation" -p https -f 10 --sort rate --save /etc/pacman.d/mirrorlist
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
pacstrap /mnt base "$kernelVersion" "${kernelVersion}"-firmware "${kernelVersion}"-docs btrfs-progs networkmanager vim sed git man man-db man-pages texinfo bash zsh nano "$microcode" reflector

### -----------------------
#   Generate fstab
### -----------------------
genfstab -U /mnt >> mnt/etc/fstab

### -----------------------
#   Set Timezone
### -----------------------
## The ArchWiki has all following commands withi a chroot environment.
## However, you can't do this with a script, so every command is individually chroot-ed.

#Set local timezone, sync to hardware clock
#Make sure the hardware clock is UTC
arch-chroot /mnt ln -sf /usr/share/zoneinfo/Etc/"$timezoneOffset" /etc/localtime
arch-chroot /mnt hwclock --systohc
### -----------------------
#   Localization
### -----------------------
arch-chroot /mnt locale-gen
echo "$languageLocale" > /mnt/etc/locale.conf 
echo "$keymapDefault" > /mnt/etc/vconsole.conf

### -----------------------
#   Network Configuration
### -----------------------
#Set new hostname
echo "$hostname" > /mnt/etc/hostname

#Set networking defaults
cat >> /mnt/etc/hosts <<EOF
127.0.0.1   localhost
::1         localhost
127.0.1.1   $hostname.localdomain   $hostname
EOF

echo I will drop you back into a shell so that you can reconfigure your networking preferences.
echo Once this is done \( or, if you are using ethernet, and it is already working\), exit the shell
echo to continue the script.
arch-chroot /mnt

### -----------------------
#   Set Root Password
### -----------------------
echo "${rootPass}\n${rootPass}" | arch-chroot /mnt passwd root

### -----------------------
#   Bootloader
### -----------------------
# Install grub
arch-chroot /mnt grub-install --target=x86_64-efi --efi-directory=/boot --bootloader-id=GRUB

### -----------------------
#   Create User
### -----------------------
#Create user
arch-chroot /mnt useradd -m -G wheel $user1

# Add password
arch-chroot /mnt echo "${pass1}\n${pass1}" | passwd $user1

### -----------------------
#   Enable Sudo
### -----------------------
sed -i "/^# %wheel ALL=(ALL) ALL/ c%wheel ALL=(ALL) ALL" /mnt/etc/sudoers

### -----------------------
#   Pacman Config
### -----------------------
#Turn on colors in Pacman
sed -i "/^#Color/ cColor" /mnt/etc/pacman.conf

#Allow use of the multilib repo
sed -i "/^#\[multilib\]\n#Include/ c\[multilib\]\nInclude" /mnt/etc/pacman.conf

#Update Mirrorlist
arch-chroot /mnt reflector -c "$countryLocation" -p https -f 10 --sort rate --save /etc/pacman.d/mirrorlist

#Update mirrors
arch-chroot /mnt pacman -Sy

### -----------------------
#   Yay Installation
### -----------------------

curl https://aur.archlinux.org/cgit/aur.git/snapshot/yay.tar.gz -o /mnt/home/"$user1"/yay.tar.gz
tar xvf /mnt/home/"$user1"/yay.tar.gz -C /mnt/home/"$user1"
arch-chroot /mnt chown "$user1":"$user1" /home/"$user1"/yay.tar.gz /home/"$user1"/yay
arch-chroot /mnt su - "$user1" -c "cd yay && yes | makepkg -si"
rm /mnt/home/"$user1"/yay.tar.gz
rm -rf /mnt/home/"$user1"/yay


### --------------------------------------
#   Desktop Environment/Window Managers
### --------------------------------------

#Install drivers (These are not pacstrapped, as the boot drive does not give access to the multilib repo
#Also installs display manager (may be overwritten if installing another DE/WM)
arch-chroot /mnt su - "$user1" yay -S --noconfirm "$graphicsDriver" lightdm lightdm-gtk-greeter

echo What Desktop Environment or Window Managers would you like installed?
echo Available DE/WMs:
echo '- (k)DE'
echo '- (g)NOME'
echo '- LX(d)E'
echo '- LXQ(t)'
echo '- (x)fce'
echo '- (q)Tile'
echo '- (i)3'
echo '- (a)wesome'
echo '- x(m)onad'

read -p "Enter a letter in parenthesis to install that DE/WM: " wmAbbr
if [ "$wmAbbr" == 'k' -o "$wmAbbr" == 'K' ]
then
    arch-chroot /mnt su - "$user1" yay -S --noconfirm plasma plasma-wayland-session kde-applications
    if [ "$dGPU" == 'n' -o "$dGPU" == 'N' ]
    then
        arch-chroot /mnt su - "$user1" yay -S --noconfirm egl-wayland
    fi
elif [ "$wmAbbr" == 'g' -o "$wmAbbr" == 'G' ]
    arch-chroot /mnt su - "$user1" yay -S --noconfirm gnome
elif [ "$wmAbbr" == 'd' -o "$wmAbbr" == 'D' ]
    arch-chroot /mnt su - "$user1" yay -S --noconfirm lxde
elif [ "$wmAbbr" == 't' -o "$wmAbbr" == 'T' ]
    arch-chroot /mnt su - "$user1" yay -S --noconfirm lxqt xorg-server breeze-icons lxqt-connman-applet sddm 
elif [ "$wmAbbr" == 'x' -o "$wmAbbr" == 'X' ]
    arch-chroot /mnt su - "$user1" yay -S --noconfirm xfce4 xfce4-goodies
elif [ "$wmAbbr" == 'q' -o "$wmAbbr" == 'Q' ]
    arch-chroot /mnt su - "$user1" yay -S --noconfirm qtile
elif [ "$wmAbbr" == 'i' -o "$wmAbbr" == 'I' ]
    arch-chroot /mnt su - "$user1" yay -S --noconfirm i3
elif [ "$wmAbbr" == 'a' -o "$wmAbbr" == 'A' ]
    arch-chroot /mnt su - "$user1" yay -S --noconfirm awesome
elif [ "$wmAbbr" == 'm' -o "$wmAbbr" == 'M' ]
    arch-chroot /mnt su - "$user1" yay -S --noconfirm xmonad xmonad-contrib
fi

exit 0
