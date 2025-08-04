#!/bin/bash

# ============================================================================
# DEPRECATION WARNING
# ============================================================================
echo "╔══════════════════════════════════════════════════════════════════════════════╗"
echo "║                              ⚠️  DEPRECATION WARNING ⚠️                        ║"
echo "╠══════════════════════════════════════════════════════════════════════════════╣"
echo "║ This unofficial Docker container is being SUNSET due to the release of an   ║"
echo "║ official CoolerControl Docker image.                                        ║"
echo "║                                                                              ║"
echo "║ 🚨 MIGRATION REQUIRED BY: November 1st, 2025                               ║"
echo "║                                                                              ║"
echo "║ Please update your Docker configuration to use the official image:          ║"
echo "║ 📦 coolercontrol/coolercontrold:latest                                      ║"
echo "║                                                                              ║"
echo "║ ⚠️  Continued maintenance of this container is NOT GUARANTEED past the      ║"
echo "║    migration deadline.                                                      ║"
echo "║                                                                              ║"
echo "╚══════════════════════════════════════════════════════════════════════════════╝"
echo ""
echo "Container will start in 10 seconds..."
sleep 10

# Initialize essential directories first
sudo mkdir -p "${XDG_RUNTIME_DIR}"
sudo chown cooleruser:cooleruser "${XDG_RUNTIME_DIR}"
sudo chmod 0700 "${XDG_RUNTIME_DIR}"

# Initialize DBUS
sudo mkdir -p /var/run/dbus
sudo dbus-daemon --system --fork

# Create essential runtime directories
mkdir -p "${XDG_RUNTIME_DIR}"
sudo chown cooleruser:cooleruser "${XDG_RUNTIME_DIR}"
chmod 0700 "${XDG_RUNTIME_DIR}"

# Initialize configuration
if [ ! -f /etc/coolercontrol/config.toml ]; then
    echo "Initializing configuration..."
    CC_VERSION=$(cat /opt/coolercontrol/version)
    curl -s -o /tmp/default-config.toml \
        "https://gitlab.com/coolercontrol/coolercontrol/-/raw/${CC_VERSION}/coolercontrold/resources/config-default.toml"
    sed -i '/^ipv4_address = .*/d' /tmp/default-config.toml
    sed -i '/^\[settings\]/a ipv4_address = "0.0.0.0"' /tmp/default-config.toml
    sudo mv /tmp/default-config.toml /etc/coolercontrol/config.toml
    sudo chmod 644 /etc/coolercontrol/config.toml
fi

# Start with direct hardware access
exec sudo -E ./CoolerControlD-x86_64.AppImage --appimage-extract-and-run
