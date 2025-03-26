#!/bin/bash
# Start essential services
sudo /etc/init.d/dbus start
sudo service udev start

# Load kernel modules
sudo modprobe coretemp nct6775 it87

# Reload udev rules and trigger
sudo udevadm control --reload
sudo udevadm trigger

# Initialize sensors
sudo sensors-detect --auto

# Run CoolerControl with AppImage extraction
exec sudo ./CoolerControlD-x86_64.AppImage --appimage-extract-and-run
