#!/bin/bash
# Start DBUS system bus
sudo /etc/init.d/dbus start

# Ensure proper permissions for devices
sudo udevadm control --reload && sudo udevadm trigger

# Run CoolerControl with AppImage extraction
exec sudo ./CoolerControlD-x86_64.AppImage --appimage-extract-and-run
