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
    && rm -rf /var/lib/apt/lists/*

# Create non-root user and configure permissions
RUN useradd -m cooleruser && \
    usermod -a -G plugdev,i2c,sensors cooleruser && \
    echo "cooleruser ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers

# Configure sensors and hardware monitoring
RUN echo "coretemp" >> /etc/modules && \
    echo "nct6775" >> /etc/modules && \
    echo "it87" >> /etc/modules

# Copy udev rules and DBUS configuration
COPY 99-coolercontrol.rules /etc/udev/rules.d/
RUN udevadm control --reload-rules && \
    udevadm trigger

# Switch to non-root user
USER cooleruser
WORKDIR /home/cooleruser

# Download CoolerControl AppImage
RUN wget -q https://gitlab.com/coolercontrol/coolercontrol/-/releases/permalink/latest/downloads/packages/CoolerControlD-x86_64.AppImage

# Make AppImage executable
RUN chmod +x CoolerControlD-x86_64.AppImage

# Expose web interface port
EXPOSE 11987

# Entrypoint script to handle DBUS and permissions
COPY entrypoint.sh .
RUN sudo chmod +x entrypoint.sh
ENTRYPOINT ["./entrypoint.sh"]
