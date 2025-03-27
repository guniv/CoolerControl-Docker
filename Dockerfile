FROM debian:stable-slim

# Install system dependencies
RUN apt-get update && \
    apt-get install -y \
        wget \
        sudo \
        jq \
        curl \
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

# Detect and store version
USER root
RUN mkdir -p /opt/coolercontrol && \
    CC_VERSION=$(curl -s "https://gitlab.com/api/v4/projects/coolercontrol%2Fcoolercontrol/releases" | jq -r '.[0].tag_name') && \
    echo "${CC_VERSION}" > /opt/coolercontrol/version && \
    chmod a+r /opt/coolercontrol/version

# Download CoolerControl AppImage
RUN CC_VERSION=$(cat /opt/coolercontrol/version) && \
    wget -q "https://gitlab.com/coolercontrol/coolercontrol/-/releases/${CC_VERSION}/downloads/packages/CoolerControlD-x86_64.AppImage" \
    -O /home/cooleruser/CoolerControlD-x86_64.AppImage && \
    chmod +x /home/cooleruser/CoolerControlD-x86_64.AppImage && \
    chown cooleruser:cooleruser /home/cooleruser/CoolerControlD-x86_64.AppImage

# Create config directory structure
RUN mkdir -p /etc/coolercontrol && \
    chown cooleruser:cooleruser /etc/coolercontrol

# Copy udev rules
COPY 99-coolercontrol.rules /etc/udev/rules.d/

# Switch to non-root user
USER cooleruser
WORKDIR /home/cooleruser

# Expose web interface port
EXPOSE 11987

# Entrypoint script
COPY entrypoint.sh .
USER root
RUN chmod +x entrypoint.sh && chown cooleruser:cooleruser entrypoint.sh
USER cooleruser

ENTRYPOINT ["./entrypoint.sh"]
