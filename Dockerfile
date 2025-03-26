FROM debian:stable-slim

# Install required packages
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
    && rm -rf /var/lib/apt/lists/*

# Create non-root user and configure permissions
RUN useradd -m cooleruser && \
    usermod -a -G plugdev cooleruser && \
    echo "cooleruser ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers

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
ENTRYPOINT ["./entrypoint.sh"]
