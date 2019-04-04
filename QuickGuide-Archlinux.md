# A quick and dirty guide for installing and configuring Arch Linux

Before starting, you should thoroughly read the [official installation guide](https://wiki.archlinux.org/index.php/installation_guide), as it explains the basic aspects of the installation. For an in-depth guide into configuring and working with Arch after installation, you should also read the [general recommendations](https://wiki.archlinux.org/index.php/General_recommendations).


## Installation

The basic gist of it is:

1. Set up the network connection (if necessary)
2. Partition, format, and mount the disks (`/mnt`, `/mnt/boot`, etc.)
3. Select the fastest/closest mirror in `/etc/pacman.d/mirrorlist`

Be sure to read the page on [Bootloaders](https://wiki.archlinux.org/index.php/Category:Boot_loaders) for considerations about using UEFI/BIOS with GPT/MBR disks. Some configurations will require very specific boot partitions. Next, install and configure the base system and populate the `fstab` file:

```sh
pacstrap /mnt base base-devel
genfstab -U /mnt >> /mnt/etc/fstab
```

You can also install individual packages or package groups using `pacstrap`, although this is entirely optional. Switch over to the newly installed system by issuing `arch-chroot /mnt`, and complete basic configuration. Go ahead and configure the system locale and root password while in the `chroot` environment:

```sh
## keyboard
echo KEYMAP=us > /etc/vconsole.conf

## locale
sed -i 's/#en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/g' /etc/locale.gen
locale-gen
echo LANG=en_US.UTF-8 > /etc/locale.conf

## timezone
ln -sf /usr/share/zoneinfo/America/Mexico_City /etc/localtime
# timedatectl set-ntp true # will this work in chroot?

## hostname
echo yourhostname > /etc/hostname

## Set the root password
passwd
```

I will assume you will use [GRUB](https://wiki.archlinux.org/index.php/GRUB) to boot the system:

```sh
## Install the GRUB bootloader
pacman -S grub os-prober
grub-install /dev/sda
grub-mkconfig -o /boot/grub/grub.cfg
```

Finally, exit the `chroot` environment, unmount all partitions (`umount -R /mnt`), and reboot your machine into your freshly installed system.


## Post-installation

### Wireless setup
```sh
wifi-menu -o
netctl enable wlan0-sihnon
netctl start wlan0-sihnon
#ip link set wlan0 up
#systemctl enable dhcpcd@wlan0.service
#ip link set wlan0 down
#systemctl disable dhcpcd@wlan0.service
```

### Add user, change password, add to sudo
```shell
useradd -m -g users -s /bin/bash -d /home/sma sma
sed -i 's/root ALL=(ALL) ALL/root ALL=(ALL) ALL\nsma ALL=(ALL) ALL/g' /etc/sudoers
passwd sma
```


## Software

### Update system and install software
```sh
pacman -Syu --noconfirm # updates system
pacman -S ack git htop mlocate tree vim wget --noconfirm # useful utils

pacman -S ttf-dejavu ttf-inconsolata --noconfirm
pacman -S adobe-source-code-pro-fonts adobe-source-sans-pro-fonts --noconfirm # fonts

pacman -S dialog wpa_supplicant --noconfirm # wireless utils
pacman -S alsa-utils --noconfirm # sound driver and tools

pacman -S rxvt-unicode --noconfirm ## terminals
pacman -S firefox --noconfirm
pacman -S feh lxappearance --noconfirm

pacman -S xorg-server xorg-server-utils xorg-xinit --noconfirm # x11 stuff
pacman -S dmenu dunst i3 --noconfirm
#pacman -S xfce4 xfce4-goodies --noconfirm

pacman -S texlive-most gnuplot --noconfirm # academic tools
```

## Some miscellaneous topics

### Creating SD Cards on Mac OS X, with coreutils installed

```shell
diskutil list
diskutil unmountDisk /dev/diskX
sudo dd bs=1M if=linux.img of=/dev/rdiskX
diskutil eject /dev/diskX
```


### When installed as Virtualbox guest

```shell
ip link set enp0s3 up
systemctl enable dhcpcd@enp0s3.service
pacman -S dkms linux-headers virtualbox-guest-utils-nox
systemctl enable vboxservice
reboot
```


### RasPi specific

```sh
# Graphics hardware settings
sed -i 's/#disable_overscan=1/disable_overscan=1/g' /boot/config.txt
sed -i 's/gpu_mem=64/gpu_mem=128/g' /boot/config.txt

# Partitioning and formatting a 32 GB card
printf "d\n2\nn\np\n2\n\n+26.5G\nn\np\n3\n\n\nt\n3\n82\nw\n" | fdisk /dev/mmcblk0
reboot
resize2fs /dev/mmcblk0p2
mkswap /dev/mmcblk0p3
swapon /dev/mmcblk0p3

# Video driver for X11
pacman -S xf86-video-fbturbo
```
