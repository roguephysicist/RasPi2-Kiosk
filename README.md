Installing a lightweight kiosk on a RasPi 2 with Arch Linux
==================================================

Arch Linux is both lightweight and highly customizable, and is the perfect
distro for creating a kiosk using the low-powered RasPi 2. Full details about
Arch Linux on the RasPi 2 can be found on the [Official Arch Linux ARM wiki]
(https://archlinuxarm.org/platforms/armv7/broadcom/raspberry-pi-2).


Getting started
--------------------------------------------------

For this guide we will use the pre-made Arch Linux RasPi 2
[image](https://sourceforge.net/projects/archlinux-rpi2/). You can copy the
image to your microSD card using any of the [standard methods]
(https://www.raspberrypi.org/documentation/installation/installing-images/README.md)
available for your OS.

After booting into the RasPi 2, we are presented with a virtual console. We
login to the superuser:

```
user: root
pass: root
```

Now's a good time to change the root password to something very secure.

We should first expand the root filesystem to the full size of the microSD card.
Any partitioning utility will work for this purpose; I will use `fdisk` here. We
run 

```sh
fdisk /dev/mmcblk0
```

to open the utility acting on our microSD card. We need to delete the root
partition and then recreate it with the desired size. There are [many]
(http://elinux.org/RPi_Resize_Flash_Partitions#Manually_resizing_the_SD_card_on_Raspberry_Pi)
[tutorials]
(https://raspberry-hosting.com/en/faq/how-expand-arch-linux-root-partition)
available for this procedure. I suggest creating a primary partition, but an
extended partition is also perfectly fine. This is also a good time to make a
swap partition but for this application I do not consider it necessary.

After creating the new partition over the full card size, you need to restart
the computer by issuing the `reboot` command. After you are logged into root
again, expand the partition to fill the newly assigned space by running

```sh
resize2fs /dev/mmcblk0p2
```

which assumes that your new root partition is located at `/dev/mmcblk0p2`.


Basic system configuration
--------------------------------------------------

Now that we have the bare-bones system in place, we can configure it and install
the necessary software. First, we should configure some basic system aspects. In
this example, I'll call the new system `oracle`:

```sh
loadkeys us # loads US keyboard keymap
sed -i 's/#en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/g' /etc/locale.gen
locale-gen # generates en_US.UTF-8 locale
ln -sf /usr/share/zoneinfo/America/Mexico_City /etc/localtime # sets time zone
echo LANG=en_US.UTF-8 > /etc/locale.conf # sets en_US.UTF-8 as default locale
echo KEYMAP=us > /etc/vconsole.conf # sets US keymap as default
echo oracle > /etc/hostname # changes the hostname of the machine
```

Next, we should create a user with standard privileges. In this example, we
create an account for `pi`,

```sh
useradd -m -g users -s /bin/bash -d /home/pi pi
```

and we can change the password for `pi` by issuing `passwd pi`.


### RasPi specific options

Lastly, we configure a few RasPi specific options. See the
[official documentation]
(https://www.raspberrypi.org/documentation/configuration/config-txt.md) 
for full details on editing the `config.txt` file. We run

```sh
sed -i 's/#disable_overscan=1/disable_overscan=1/g' /boot/config.txt
sed -i 's/gpu_mem=64/gpu_mem=128/g' /boot/config.txt
```

This disables overscanning so that the display image goes edge-to-edge. It also
increase the GPU memory from 64 MB to 128 MB.

It may be desirable to rotate the screen so that it is in portrait mode, useful
for displaying a long page without scrolling. This can be accomplished by
editing the `/boot/config.txt` file and changing `display_rotate=0` to
`display_rotate=1` or `display_rotate=3` depending on the orientation of your
monitor. It may also be necessary to increase the GPU memory from 128 MB to 256
MB. 

This is a convenient point to restart the machine again by issuing the `reboot`
command. Everything we have set up so far will take effect after restarting. 


Setting up the kiosk
--------------------------------------------------

We now have a fully configured RasPi, and we are ready to install the necessary
packages for the kiosk. To do this, I have selected some lightweight
applications:

* `xorg`, the standard GUI display server and utilities,
* `matchbox-window-manager`, an ultra-lightweight WM with limited interface,
* `midori`, a lightweight web browser with a CLI, and
* `xterm`, a basic and lightweight terminal emulator.

Log in as `root` once again. The following commands will install these packages;
make sure you have a good internet connection.

```sh
pacman -Syu --noconfirm # system updates, may take a little while
pacman -S htop vim wget --noconfirm # useful utils
pacman -S xorg-server xorg-server-utils xorg-xinit --noconfirm # basic X11 packages
pacman -S alsa-utils xf86-video-fbturbo --noconfirm # RasPi 2 sound and video drivers
pacman -S matchbox-window-manager --noconfirm # super lightweight WM
pacman -S midori unclutter xterm --noconfirm # unclutter hides your cursor
pacman -S ttf-dejavu --noconfirm # set of nice fonts
```

These packages only weigh in at only a few hundred MB, and are very low on
resource consumption. Installing them should only take a few minutes. Now that
our system is fully installed we need to set it up to run as an automated kiosk.


### Auto-login to unprivileged user

We want the system to automatically log in as the unprivileged user. We simply
follow the [documentation]
(https://wiki.archlinux.org/index.php/automatic_login_to_virtual_console), 
which can be summed up as

```sh
$ cat /etc/systemd/system/getty@tty1.service.d/override.conf

[Service]
ExecStart=
ExecStart=-/usr/bin/agetty --autologin pi --noclear %I $TERM
```

You can restart the machine to test this out. It should log in directly to the
`pi` user.

### Autostarting X at login

There are several ways autostart the WM at login. Refer to the [documentation]
(https://wiki.archlinux.org/index.php/Xinitrc#Autostart_X_at_login) for more
details on accomplishing this. I opted for a simple script that will execute
from the `.bash_profile` of the user when logged in. This approach does not
require the superuser and is very flexible.

We first create a shell script in our home directory. I call it `startkiosk.sh`
here, but you can use whatever you want. The script contains the following:

```sh
$ cat ~/startkiosk.sh

#!/bin/sh
xset -dpms      # disable DPMS (Energy Star) features.
xset s off      # disable screen saver
xset s noblank  # don't blank the video device
unclutter &     # hides your cursor after inactivity
matchbox-window-manager & # starts the WM
xterm &         # launches a helpful terminal
midori -e Fullscreen -a https://www.raspberrypi.org # opens midori fullscreen
```

I also include the script in this repo that you can copy directly to your home
directory. It does not need to be executable. You should try the script out with

```sh
xinit ./startkiosk.sh
```

This should open up a fullscreen terminal window and then a fullscreen instance
of Midori, loading the website of your choice. You can `alt + tab` into the
terminal at any moment to install a program, modify the scripts, or even restart
or shutdown the machine. The way the script is organized causes the terminal
window to end up behind Midori, so you can boot into the machine knowing that it
will display the correct thing without any interaction from your part. When you
are done with the test, you can kill the X session with

```sh
pkill -15 Xorg
```

This will dump you back at the command line. So, now all we have to do is to run
the script at login time. The easiest way of doing this can also be found in the
[documentation]
(https://wiki.archlinux.org/index.php/Xinitrc#Autostart_X_at_login). We'll 
simply add a line to the end of your .bash_profile that tells the system to run
the appropriate command. We can do this with a nice one liner like

```
printf '[[ -z $DISPLAY && $XDG_VTNR -eq 1 ]] && xinit ./startkiosk.sh\n' >> .bash_profile
```

Restart one last time and your RasPi should boot directly into your fullscreen
browser!


Conclusions
--------------------------------------------------

### Achievements: 
* Using a RasPi 2 is a cost-effective way to create a simple kiosk machine
  capable of displaying a website. 
* Simple script approach does not require superuser access nor changing any
  system files. If you don't want to use it anymore you can simple comment one
  line in the .bash_profile.
* WM and web browser are super lightweight and will not tax your RasPi, unless
  you purposely load some heavy web-content. Memory usage is around 125 MB with
  a simple website loaded.
* You can simple plug your RasPi in and everything will load automatically. No
  user input, keyboard, or mouse needed.

### Deficiencies:
* The RasPi will never sleep or shut off the display. The settings should be
  tweaked so that it turns on and shuts off the display at certain hours.
* As is, it only displays one website. It would be nice to have several open
  that can be cycled through automatically.
