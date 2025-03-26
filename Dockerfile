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
    && rm -rf /var/lib/apt/lists/*

# Create a non-root user and add to sudoers
RUN useradd -m cooleruser && \
    echo "cooleruser ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers

# Switch to non-root user
USER cooleruser
WORKDIR /home/cooleruser

# Download CoolerControl AppImage
RUN wget https://gitlab.com/coolercontrol/coolercontrol/-/releases/permalink/latest/downloads/packages/CoolerControlD-x86_64.AppImage

# Make AppImage executable
RUN chmod +x CoolerControlD-x86_64.AppImage

# Expose web interface port
EXPOSE 11987

# Start CoolerControl daemon
CMD sudo ./CoolerControlD-x86_64.AppImage --appimage-extract-and-run
