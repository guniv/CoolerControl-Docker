FROM debian:stable-slim

# Install system dependencies
RUN apt-get update && \
    apt-get install -y \
        wget \
        sudo \
        libfuse2 \
        libdrm-amdgpu1 \
        udev \
        dbus \
        libglib2.0-0 \
        libudev1 \
        libdbus-1-3 \
        libusb-1.0-0 \
        python3 \
        python3-setuptools \
        python3-usb \
        python3-colorlog \
        python3-crcmod \
        python3-hidapi \
        python3-docopt \
        python3-pil \
        python3-smbus \
        i2c-tools \
        lm-sensors \
        kmod \
        sed \
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

# Set up configuration files
USER root
RUN mkdir -p /etc/coolercontrol/default-config && \
    wget -q -O /etc/coolercontrol/default-config/default-config.toml \
      https://gitlab.com/coolercontrol/coolercontrol/-/raw/main/coolercontrold/resources/config-default.toml && \
    cp /etc/coolercontrol/default-config/default-config.toml \
       /etc/coolercontrol/default-config/edited-default-config.toml && \
    # Apply edits to the copied config
    sed -i '/^ipv4_address = .*/d' /etc/coolercontrol/default-config/edited-default-config.toml && \
    sed -i '/^\[settings\]/a ipv4_address = "0.0.0.0"' /etc/coolercontrol/default-config/edited-default-config.toml && \
    chown -R cooleruser:cooleruser /etc/coolercontrol/default-config

# Copy udev rules
COPY 99-coolercontrol.rules /etc/udev/rules.d/

# Switch to non-root user
USER cooleruser
WORKDIR /home/cooleruser

# Download CoolerControl AppImage
RUN wget -q https://gitlab.com/coolercontrol/coolercontrol/-/releases/permalink/latest/downloads/packages/CoolerControlD-x86_64.AppImage

# Make AppImage executable
RUN chmod +x CoolerControlD-x86_64.AppImage

# Expose web interface port
EXPOSE 11987

# Entrypoint script - ensure permissions
COPY entrypoint.sh .
USER root
RUN chmod +x entrypoint.sh && chown cooleruser:cooleruser entrypoint.sh
USER cooleruser

ENTRYPOINT ["./entrypoint.sh"]
