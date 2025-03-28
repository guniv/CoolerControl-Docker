# Stage 1: Builder
FROM debian:stable-slim AS builder

# Set non-interactive frontend for debian packages
ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        curl \
        jq \
        ca-certificates \
    && rm -rf /var/lib/apt/lists/*

RUN mkdir -p /opt/coolercontrol && \
    CC_VERSION=$(curl -s "https://gitlab.com/api/v4/projects/coolercontrol%2Fcoolercontrol/releases" | jq -r '.[0].tag_name') && \
    echo "${CC_VERSION}" > /opt/coolercontrol/version

RUN CC_VERSION=$(cat /opt/coolercontrol/version) && \
    curl -s -L "https://gitlab.com/coolercontrol/coolercontrol/-/releases/${CC_VERSION}/downloads/packages/CoolerControlD-x86_64.AppImage" \
        -o /CoolerControlD-x86_64.AppImage && \
    chmod +x /CoolerControlD-x86_64.AppImage

# Stage 2: Runtime
FROM debian:stable-slim

# Create required system groups first
RUN groupadd --system -f sensors && \
    groupadd --system -f i2c && \
    groupadd --system -f plugdev && \
    groupadd --system -f dialout && \
    groupadd --system -f audio && \
    groupadd --system -f video

# Install packages with proper cleanup
ENV DEBIAN_FRONTEND=noninteractive
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        libdrm-amdgpu1 \
        libglib2.0-0 \
        libusb-1.0-0 \
        libfuse2 \
        sudo \
        dbus \
        curl \
        ca-certificates \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Configure user and permissions
RUN useradd -m cooleruser && \
    usermod -a -G plugdev,i2c,sensors,dialout,audio,video cooleruser && \
    echo "cooleruser ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers

# Set non-interactive frontend and install packages
ENV DEBIAN_FRONTEND=noninteractive
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        libdrm-amdgpu1 \
        libglib2.0-0 \
        libusb-1.0-0 \
        libfuse2 \
        sudo \
        dbus \
        curl \
    && rm -rf /var/lib/apt/lists/*

# Create essential directories
RUN mkdir -p \
    /etc/coolercontrol \
    /run/dbus \
    /var/run/dbus && \
    chown cooleruser:cooleruser /etc/coolercontrol

COPY --from=builder /CoolerControlD-x86_64.AppImage /
COPY --from=builder /opt/coolercontrol/version /opt/coolercontrol/version

COPY entrypoint.sh /
RUN chmod +x /entrypoint.sh && chown cooleruser:cooleruser /entrypoint.sh

USER cooleruser
WORKDIR /
EXPOSE 11987

ENTRYPOINT ["/entrypoint.sh"]
