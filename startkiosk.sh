#!/bin/sh
xset -dpms      # disable DPMS (Energy Star) features.
xset s off      # disable screen saver
xset s noblank  # don't blank the video device
unclutter &     # hides your cursor after inactivity
matchbox-window-manager & # starts the WM
xterm &         # launches a helpful terminal
midori -e Fullscreen -a https://www.raspberrypi.org # opens midori fullscreen
