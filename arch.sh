#!/usr/bin/env bash

CPU_VENDOR=""
UCODE=""
SYSTEM_DRIVE=""
EFI=""
ROOT=""
SWAP=""
ROOT_PASSWORD=""
HOSTNAME=""

BOOTLOADER=""

init() {

if [ "$USER" != "root" ]; then
    sudo "$0" || (
        print_error "Please run this script as root\n"
        exit 1
    )
    exit 0
fi

#echo "Device list"
#print_info "Device list: $(find /dev/ -regex "/dev/\([vs]d[a-z]\|nvme[0-9]n[0-9]\)")\n"
# loop as long as $device is a valid device
#while [ -z "$device" ] || [ ! -e "$device" ] || \
#    ! expr "$device" : '^/dev/\([sv]d[a-z]\|nvme[0-9]n[0-9]\)$' >/dev/null; do
#    print_info "Type the device name ('/dev/' required): "
#    read -r device
#    [ ! -e "$device" ] && print_error "This device doesn't exist\n"
#    if ! expr "$device" : '^/dev/\([sv]d[a-z]\|nvme[0-9]n[0-9]\)$' >/dev/null; then
#        print_error "You should type a device name, not a partition name\n"
#        device=""
#    fi
#done

# Ставим русскую раскладку
echo "Setting keyboard layout..."
loadkeys ru

# Добавим в консоль шрифт, поддерживающий кириллицу
echo "Setting cyrillic font..."
setfont cyr-sun16

#Добавляем русскую локаль
sed -i 's/#ru_RU.UTF-8 UTF-8/ru_RU.UTF-8 UTF-8/g' /etc/locale.gen
locale-gen
export LANG=ru_RU.UTF-8

up=`ping -c 1 -q raw.githubusercontent.com`
case $? in
0) echo -en "+ \033[32;1;49mInternet is available \033[0m\n";;
*) echo -en "- \033[31;1;49mWarning! \033[0m\033[31;1;5mInternet not available \033[0m\n"
   exit;;
esac

echo -e "Begin...................................................."

if lscpu | grep -q "GenuineIntel"; then
        CPU_VENDOR="intel"
        UCODE="intel-ucode"
    elif lscpu | grep -q "AuthenticAMD"; then
        CPU_VENDOR="amd"
        UCODE="amd-ucode"
    else
        CPU_VENDOR=""
fi
}

main() {

lsblk
echo "Enter the drive to install arch linux on it. (/dev/...)"
echo "Enter Drive (eg. /dev/sda or /dev/vda or /dev/nvme0n1 or something similar)"
read SYSTEM_DRIVE
sleep 2s

cfdisk $SYSTEM_DRIVE
echo "Getting ready for creating partitions!"
echo "root and boot partitions are mandatory."
echo "home and swap partitions are optional but recommended!"
echo "Also, you can create a separate partition for timeshift backup (optional)!"
echo "Getting ready in 5 seconds"
sleep 5s

echo "Please enter EFI paritition: (example /dev/sda1 or /dev/nvme0n1p1)"
read EFI

echo "Please enter SWAP paritition: (example /dev/sda2)"
read SWAP

echo "Please enter Root(/) paritition: (example /dev/sda3)"
read ROOT 

echo "Please password for root(superuser)"
read ROOT_PASSWORD

echo "Please enter your username"
read USER 

echo "Please enter your password"
read PASSWORD 

echo "Please enter hostname"
read HOSTNAME

echo "Please choose boot loader for you system"
echo "1. Grub2"
echo "2. Refind"
read BOOTLOADER

echo "Please choose Your Desktop Environment"
echo "1. GNOME"
echo "2. KDE"
echo "3. XFCE"
echo "4. i3"
echo "5, lxqt"
echo "6. NoDesktop"
read DESKTOP

# make filesystems

echo "Getting ready for creating partitions!"
echo "root and boot partitions are mandatory."
echo "home and swap partitions are optional but recommended!"
echo "Also, you can create a separate partition for timeshift backup (optional)!"
echo "Getting ready in 9 seconds"
sleep 9s

echo -e "\nCreating Filesystems...\n"

mkfs.vfat -F32 -n "EFISYSTEM" "${EFI}"
mkswap "${SWAP}"
swapon "${SWAP}"
mkfs.ext4 -L "ROOT" "${ROOT}"

# mount target
mount -t ext4 "${ROOT}" /mnt
mkdir /mnt/boot
mount -t vfat "${EFI}" /mnt/boot/

echo "--------------------------------------------------"
echo "-- Setting up $iso mirrors for faster downloads---"
echo "--------------------------------------------------"
cp /etc/pacman.d/mirrorlist /etc/pacman.d/mirrorlist.old
reflector --country 'Russia' -f 10  --protocol https --sort rate --save /etc/pacman.d/mirrorlist

echo "--------------------------------------"
echo "-- INSTALLING Arch Linux BASE on Main Drive       --"
echo "--------------------------------------"
pacstrap /mnt base base-devel  linux linux-firmware --noconfirm --needed

echo "--------------------------------------"
echo "-- Setup Dependencies               --"
echo "--------------------------------------"

pacstrap /mnt networkmanager network-manager-applet wireless_tools nano $ucode bluez bluez-utils blueman git wget yajl terminus-font --noconfirm --needed

# fstab
genfstab -U /mnt >> /mnt/etc/fstab
sleep 10s
cat //mnt/etc/fstab
sleep 10s

#bootctl install --path /mnt/boot
#echo "default arch.conf" >> /mnt/boot/loader/loader.conf
#cat <<EOF > /mnt/boot/loader/entries/arch.conf
#title Arch Linux
#linux /vmlinuz-linux
#initrd /initramfs-linux.img
#options root=${ROOT} rw
#EOF


cat <<REALEND > /mnt/next.sh
echo "Change password to root...."
echo root:$ROOT_PASSWORD | chpasswd

echo "Set new user...."
useradd -m $USER
usermod -aG wheel,storage,power,audio $USER
echo $USER:$PASSWORD | chpasswd
sed -i 's/^# %wheel ALL=(ALL:ALL) ALL/%wheel ALL=(ALL:ALL) ALL/' /etc/sudoers

echo "-------------------------------------------------"
echo "Setup Language to US and set locale"
echo "-------------------------------------------------"
sed -i 's/^#en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/' /etc/locale.gen
sed -i 's/^#ru_RU.UTF-8 UTF-8/ru_RU.UTF-8 UTF-8/' /etc/locale.gen
locale-gen
echo "LANG=ru_RU.UTF-8" >> /etc/locale.conf

ln -sf /usr/share/zoneinfo/Europe/Moscow /etc/localtime
hwclock --systohc

touch /etc/vconsole.conf
cat <<EOF > /etc/vconsole.conf
LOCALE="ru_RU.UTF-8"
KEYMAP="ru" # Или ru-mab для раскладки с переключением по Ctrl-Shift
FONT="cyr-sun16"
CONSOLEFONT="cyr-sun16" # Можно поэкспериментировать с другими шрифтами ter-v* из /usr/share/kbd/consolefonts
CONSOLEMAP=""
USECOLOR="yes"
EOF

echo "archpc" > /etc/hostname
cat <<EOF > /etc/hosts
127.0.0.1	localhost
::1			localhost
127.0.1.1	arch.localdomain	arch
EOF

echo "--------------------------------------"
echo "-- Bootloader Installation  --"
echo "--------------------------------------"
sleep 5s
pacman -Syy
pacman -S  grub  efibootmgr os-prober --noconfirm --needed
sleep 5s
grub-install --target=x86_64-efi --efi-directory=/boot    --bootloader-id=ARCH
sleep 5s
sed -i 's/#GRUB_DISABLE_OS_PROBER=false/GRUB_DISABLE_OS_PROBER=false/g' /etc/default/grub
grub-mkconfig -o /boot/grub/grub.cfg
sleep 5s

echo "-------------------------------------------------"
echo "Display and Audio Drivers"
echo "-------------------------------------------------"

pacman -S xorg
systemctl enable NetworkManager bluetooth

#DESKTOP ENVIRONMENT
if [[ $DESKTOP == '1' ]]
then 
    pacman -S gnome gdm --noconfirm --needed
    systemctl enable gdm
elif [[ $DESKTOP == '2' ]]
then
    #pacman -S plasma sddm kde-applications --noconfirm --needed
    pacman -S plasma sddm --noconfirm --needed
    systemctl enable sddm
elif [[ $DESKTOP == '3' ]]
then
    pacman -S xfce4 xfce4-goodies lightdm lightdm-gtk-greeter --noconfirm --needed
    systemctl enable lightdm
else
    echo "You have choosen to Install Desktop Yourself"
fi

echo "-------------------------------------------------"
echo "Install Complete, You can reboot now"
echo "-------------------------------------------------"

REALEND


arch-chroot /mnt sh next.sh
}

init
main
