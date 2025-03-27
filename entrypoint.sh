#!/bin/bash

# Start essential services
dbus-daemon --system --fork
udevd --daemon

# Load hardware monitoring modules
modprobe coretemp nct6775 it87

# Ensure default configuration exists
mkdir -p /etc/coolercontrol
if [ ! -f /etc/coolercontrol/config.toml ]; then
    echo "Initializing default configuration..."
    cp /default-config/config.toml /etc/coolercontrol/
    chown cooleruser:cooleruser /etc/coolercontrol/config.toml
fi

# Reload udev rules
udevadm control --reload
udevadm trigger

# Start CoolerControl
exec ./CoolerControlD-x86_64.AppImage --appimage-extract-and-run
