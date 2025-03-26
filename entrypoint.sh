#!/bin/bash
# Initialize essential services
sudo /etc/init.d/dbus start
sudo service udev start

# Load hardware monitoring modules
sudo modprobe coretemp nct6775 it87

# Initialize configuration
sudo mkdir -p /etc/coolercontrol
if [ ! -f /etc/coolercontrol/config.toml ]; then
    echo "Initializing default configuration..."
    sudo cp /default-config/config.toml /etc/coolercontrol/
    sudo chown cooleruser:cooleruser /etc/coolercontrol/config.toml
fi

# Reload udev rules
sudo udevadm control --reload
sudo udevadm trigger

# Initialize sensors
sudo sensors-detect --auto

# Start CoolerControl
exec sudo ./CoolerControlD-x86_64.AppImage --appimage-extract-and-run
