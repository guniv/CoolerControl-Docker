FROM debian:stable-slim

# Install system dependencies
RUN apt-get update && \
    apt-get install -y \
        wget sudo curl jq \
        libfuse2 libdrm-amdgpu1 \
        udev dbus libglib2.0-0 libudev1 libdbus-1-3 libusb-1.0-0 \
        python3 python3-setuptools python3-usb python3-colorlog \
        python3-crcmod python3-hidapi python3-docopt python3-pil \
        python3-smbus i2c-tools lm-sensors kmod sed \
    && rm -rf /var/lib/apt/lists/*

# Create non-root user and configure permissions
RUN groupadd --system sensors && \
    useradd -m cooleruser && \
    usermod -a -G plugdev,i2c,sensors cooleruser && \
    echo "cooleruser ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers

# Configure sensors and hardware monitoring
RUN echo "coretemp" >> /etc/modules && \
    echo "nct6775" >> /etc/modules && \
    echo "it87" >> /etc/modules

# Set up directories and download default config
USER root
RUN mkdir -p /etc/coolercontrol/default-config && \
    CC_VERSION=$(curl -s "https://gitlab.com/api/v4/projects/coolercontrol%2Fcoolercontrol/releases" | jq -r '.[0].tag_name') && \
    wget -q -O /etc/coolercontrol/default-config/default-config.toml \
      "https://gitlab.com/coolercontrol/coolercontrol/-/raw/${CC_VERSION}/coolercontrold/resources/config-default.toml" && \
    echo "${CC_VERSION}" > /tmp/cc_version && \
    chown -R cooleruser:cooleruser /etc/coolercontrol

# Copy udev rules and entrypoint
COPY 99-coolercontrol.rules /etc/udev/rules.d/
COPY entrypoint.sh /home/cooleruser/
RUN chmod +x /home/cooleruser/entrypoint.sh && \
    chown cooleruser:cooleruser /home/cooleruser/entrypoint.sh

# Download CoolerControl AppImage
USER cooleruser
WORKDIR /home/cooleruser
RUN CC_VERSION=$(cat /tmp/cc_version) && \
    wget -q "https://gitlab.com/coolercontrol/coolercontrol/-/releases/${CC_VERSION}/downloads/packages/CoolerControlD-x86_64.AppImage" && \
    chmod +x CoolerControlD-x86_64.AppImage

EXPOSE 11987
ENTRYPOINT ["./entrypoint.sh"]
