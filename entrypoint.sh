#!/bin/bash
# Initialize essential services
sudo mkdir -p /var/run/dbus
sudo dbus-daemon --system --fork
sudo udevd --daemon
sudo service udev start

# Create runtime directory
mkdir -p ${XDG_RUNTIME_DIR}
chmod 0700 ${XDG_RUNTIME_DIR}

# Load hardware monitoring modules
sudo modprobe coretemp nct6775 it87 || true

# Initialize configuration
sudo mkdir -p /etc/coolercontrol
sudo chown cooleruser:cooleruser /etc/coolercontrol

if [ ! -f /etc/coolercontrol/config.toml ]; then
    echo "Initializing configuration..."
    CC_VERSION=$(cat /opt/coolercontrol/version)
    wget -q -O /tmp/default-config.toml \
      "https://gitlab.com/coolercontrol/coolercontrol/-/raw/${CC_VERSION}/coolercontrold/resources/config-default.toml"
    sed -i '/^ipv4_address = .*/d' /tmp/default-config.toml
    sed -i '/^\[settings\]/a ipv4_address = "0.0.0.0"' /tmp/default-config.toml
    mv /tmp/default-config.toml /etc/coolercontrol/config.toml
    chmod 644 /etc/coolercontrol/config.toml
fi

# Reload udev rules
sudo udevadm control --reload
sudo udevadm trigger

# Fix permissions for runtime directory
sudo chown -R cooleruser:cooleruser ${XDG_RUNTIME_DIR}

# Start CoolerControl with necessary privileges
exec sudo -E ./CoolerControlD-x86_64.AppImage --appimage-extract-and-run
