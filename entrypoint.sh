#!/bin/bash
# Initialize essential services
sudo /etc/init.d/dbus start
sudo service udev start

# Load hardware monitoring modules
sudo modprobe coretemp nct6775 it87

# Get stored version
CC_VERSION=$(cat /opt/coolercontrol/version)

# Initialize configuration
sudo mkdir -p /etc/coolercontrol
sudo chown cooleruser:cooleruser /etc/coolercontrol

if [ ! -f /etc/coolercontrol/config.toml ]; then
    echo "Initializing configuration for version ${CC_VERSION}..."
    
    # Download and modify config
    wget -q -O /tmp/default-config.toml \
      "https://gitlab.com/coolercontrol/coolercontrol/-/raw/${CC_VERSION}/coolercontrold/resources/config-default.toml"
    
    # Apply modifications
    sed -i '/^ipv4_address = .*/d' /tmp/default-config.toml
    sed -i '/^\[settings\]/a ipv4_address = "0.0.0.0"' /tmp/default-config.toml
    
    # Move to final location
    mv /tmp/default-config.toml /etc/coolercontrol/config.toml
    chmod 644 /etc/coolercontrol/config.toml
fi

# Reload udev rules
sudo udevadm control --reload
sudo udevadm trigger

# Initialize sensors
sudo sensors-detect --auto

# Start CoolerControl
exec sudo -u cooleruser ./CoolerControlD-x86_64.AppImage --appimage-extract-and-run
