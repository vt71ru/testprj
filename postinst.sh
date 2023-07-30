sudo pacman -Suy

#Install ntfs support
sudo pacman -S ntfs-3g

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

vim /etc/pacman.conf 
#Add ILoveCandy to end of file

# Install Another auto nice daemon, with community rules support
yaourt -Ss ananicy
sudo systemctl enable ananicy

pacman -S nvidia-dkms nvidia-settings xf86-video-nouveau optimus-manager

sudo systemctl enable optimus-manager.service
sudo systemctl start optimus-manager.service

# Включаем службу Trim файловой системы (предназначена восновоном для SSD)
sudo systemctl enable fstrim.timer

# Установка Stacer
git clone https://aur.archlinux.org/stacer-bin.git
cd stacer-bin 
makepkg -sric
