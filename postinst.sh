sudo pacman -Suy

#Install ntfs support
sudo pacman -S ntfs-3g

#install yay
mkdir /home/user/tmp
cd /home/user/tmp
git clone https://aur.archlinux.org/yay.git
cd yay/
makepkg -si
cd ..
sudo rm -dR yay/

#install yaourt
mkdir /home/user/tmp
cd /home/user/tmp
git clone https://aur.archlinux.org/package-query.git
cd package-query/
makepkg -si
cd ..
git clone https://aur.archlinux.org/yaourt.git
cd yaourt/
makepkg -si
cd ..
sudo rm -dR yaourt/ package-query/

pacman -S xf86-video-nouveau optimus-manager --no-needed --confirm
git clone https://github.com/sh377c0d3/nvidia_proprietary_linux.git
sudo pacman -S whiptail
cd nvidia_proprietary_linux/
chmod  +x install.sh
./install.sh

vim /etc/pacman.conf 
#Add ILoveCandy to end of file

# Install Another auto nice daemon, with community rules support
yay -S auto-cpufreq
yaourt -Ss ananicy
sudo systemctl enable ananicy

sudo systemctl enable optimus-manager.service
sudo systemctl start optimus-manager.service

# Включаем службу Trim файловой системы (предназначена восновоном для SSD)
sudo systemctl enable fstrim.timer

# Установка Stacer
git clone https://aur.archlinux.org/stacer-bin.git
cd stacer-bin 
makepkg -sric

#Install visual studio code
pacman -S visual-studio-code-bin

pacman -S vlc gimp blender dolphin libreoffice-fresh rxvt-unicode firefox firefox-i18n-ru
yaourt -S telegram-desktop
