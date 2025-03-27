#!/bin/bash
set -e

# Initialize essential services
sudo /etc/init.d/dbus start
sudo service udev start

# Load hardware monitoring modules
sudo modprobe coretemp nct6775 it87

# Set up configuration
sudo mkdir -p /etc/coolercontrol
sudo chown cooleruser:cooleruser /etc/coolercontrol

if [ ! -f /etc/coolercontrol/config.toml ]; then
    echo "Initializing configuration..."
    sudo cp /etc/coolercontrol/default-config/default-config.toml /etc/coolercontrol/config.toml
    
    # Apply configuration modifications
    echo "Applying configuration adjustments..."
    sudo sed -i '/^ipv4_address = .*/d' /etc/coolercontrol/config.toml
    sudo sed -i '/^\[settings\]/a ipv4_address = "0.0.0.0"' /etc/coolercontrol/config.toml
    
    sudo chown cooleruser:cooleruser /etc/coolercontrol/config.toml
    echo "Configuration initialized successfully"
fi

# Reload udev rules
sudo udevadm control --reload
sudo udevadm trigger

# Initialize sensors
sudo sensors-detect --auto

# Start CoolerControl
echo "Starting CoolerControl..."
exec sudo -u cooleruser ./CoolerControlD-x86_64.AppImage --appimage-extract-and-run
