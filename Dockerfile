FROM debian:stable-slim

# Install system dependencies, including wget
RUN apt-get update && apt-get install -y --no-install-recommends \
        wget \ 
        libfuse2 \
        libdrm-amdgpu1 \
        udev \
        dbus \
        libglib2.0-0 \
        libudev1 \
        libdbus-1-3 \
        libusb-1.0-0 \
        python3 \
        python3-usb \
        python3-colorlog \
        python3-crcmod \
        python3-hidapi \
        python3-docopt \
        python3-pil \
        python3-smbus \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

# Create necessary groups before adding the user
RUN groupadd --system sensors && \
    groupadd --system i2c && \
    useradd -m -G plugdev,i2c,sensors cooleruser && \
    echo "cooleruser ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers

# Configure hardware monitoring modules
RUN echo -e "coretemp\nnct6775\nit87" > /etc/modules

# Set up default configuration
WORKDIR /default-config
RUN wget -q -O config.toml \
      https://gitlab.com/coolercontrol/coolercontrol/-/raw/main/coolercontrold/resources/config-default.toml && \
    sed -i '/^ipv4_address = .*/d' config.toml && \
    sed -i '/^\[settings\]/a ipv4_address = "0.0.0.0"' config.toml && \
    chown -R cooleruser:cooleruser /default-config

# Copy udev rules
COPY 99-coolercontrol.rules /etc/udev/rules.d/

# Switch to non-root user
USER cooleruser
WORKDIR /home/cooleruser

# Download CoolerControl AppImage
RUN wget -q https://gitlab.com/coolercontrol/coolercontrol/-/releases/permalink/latest/downloads/packages/CoolerControlD-x86_64.AppImage && \
    chmod +x CoolerControlD-x86_64.AppImage

# Expose web interface port
EXPOSE 11987

# Copy and set up entrypoint script
COPY entrypoint.sh /home/cooleruser/
RUN chmod +x /home/cooleruser/entrypoint.sh

ENTRYPOINT ["./entrypoint.sh"]
