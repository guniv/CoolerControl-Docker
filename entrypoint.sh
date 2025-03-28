#!/bin/bash
# Initialize runtime directory
mkdir -p "${XDG_RUNTIME_DIR}"
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

# Fix permissions for runtime directory
sudo chown -R cooleruser:cooleruser "${XDG_RUNTIME_DIR}"

# Start CoolerControl with necessary privileges
exec sudo -E ./CoolerControlD-x86_64.AppImage --appimage-extract-and-run
