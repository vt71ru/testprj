#!/usr/bin/env bash

CPU_VENDOR=""
UCODE=""
SYSTEM_DRIVE=""
EFI=""
ROOT=""
SWAP=""

init() {

setfont ter-118n
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

echo "Please enter your username"
read USER 

echo "Please enter your password"
read PASSWORD 

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

pacstrap /mnt networkmanager network-manager-applet wireless_tools nano $ucode bluez bluez-utils blueman git wget yajl --noconfirm --needed

# fstab
genfstab -U /mnt >> /mnt/etc/fstab

echo "--------------------------------------"
echo "-- Bootloader Installation  --"
echo "--------------------------------------"
bootctl install --path /mnt/boot
echo "default arch.conf" >> /mnt/boot/loader/loader.conf
cat <<EOF > /mnt/boot/loader/entries/arch.conf
title Arch Linux
linux /vmlinuz-linux
initrd /initramfs-linux.img
options root=${ROOT} rw
EOF


cat <<REALEND > /mnt/next.sh
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

ln -sf /usr/share/zoneinfo/Asia/Kathmandu /etc/localtime
hwclock --systohc

touch /etc/vconsole.conf
cat <<EOF > /etc/vconsole.conf
LOCALE="ru_RU.UTF-8"
KEYMAP="ru" # Или ru-mab для раскладки с переключением по Ctrl-Shift
FONT="ter-v24n"
CONSOLEFONT="ter-v24n" # Можно поэкспериментировать с другими шрифтами ter-v* из /usr/share/kbd/consolefonts
CONSOLEMAP=""
USECOLOR="yes"
EOF

echo "archpc" > /etc/hostname
cat <<EOF > /etc/hosts
127.0.0.1	localhost
::1			localhost
127.0.1.1	arch.localdomain	arch
EOF

echo "-------------------------------------------------"
echo "Display and Audio Drivers"
echo "-------------------------------------------------"

#gpu_type=$(lspci)
#if grep -E "NVIDIA|GeForce" <<< ${gpu_type}; then
#    pacman -S --noconfirm --needed nvidia
#	nvidia-utils
#elif lspci | grep 'VGA' | grep -E "Radeon|AMD"; then
#    pacman -S --noconfirm --needed xf86-video-amdgpu
#elif grep -E "Integrated Graphics Controller" <<< ${gpu_type}; then
#    pacman -S --noconfirm --needed libva-intel-driver libvdpau-va-gl lib32-vulkan-intel vulkan-intel libva-intel-driver libva-utils lib32-mesa
#elif grep -E "Intel Corporation UHD" <<< ${gpu_type}; then
#    pacman -S --needed --noconfirm libva-intel-driver libvdpau-va-gl lib32-vulkan-intel vulkan-intel libva-intel-driver libva-utils lib32-mesa
#fi
pacman -S xorg
systemctl enable NetworkManager bluetooth

#DESKTOP ENVIRONMENT
if [[ $DESKTOP == '1' ]]
then 
    pacman -S gnome gdm --noconfirm --needed
    systemctl enable gdm
elif [[ $DESKTOP == '2' ]]
then
    pacman -S plasma sddm kde-applications --noconfirm --needed
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
