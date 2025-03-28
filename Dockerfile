# Stage 1: Builder
FROM debian:stable-slim AS builder

# Install build-time dependencies
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        curl \
        jq \
        ca-certificates \
    && rm -rf /var/lib/apt/lists/*

# Detect and store version
RUN mkdir -p /opt/coolercontrol && \
    CC_VERSION=$(curl -s "https://gitlab.com/api/v4/projects/coolercontrol%2Fcoolercontrol/releases" | jq -r '.[0].tag_name') && \
    echo "${CC_VERSION}" > /opt/coolercontrol/version

# Download CoolerControl AppImage
RUN CC_VERSION=$(cat /opt/coolercontrol/version) && \
    curl -s -L "https://gitlab.com/coolercontrol/coolercontrol/-/releases/${CC_VERSION}/downloads/packages/CoolerControlD-x86_64.AppImage" \
        -o /CoolerControlD-x86_64.AppImage && \
    chmod +x /CoolerControlD-x86_64.AppImage

# Stage 2: Runtime
FROM debian:stable-slim

# Install runtime dependencies
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        libdrm-amdgpu1 \
        libglib2.0-0 \
        libusb-1.0-0 \
        i2c-tools \
        lm-sensors \
        kmod \
        sed \
        ca-certificates \
    && rm -rf /var/lib/apt/lists/*

# Create non-root user and configure permissions
RUN groupadd --system sensors && \
    useradd -m cooleruser && \
    usermod -a -G plugdev,i2c,sensors,adm,dialout cooleruser

# Configure environment and directories
ENV XDG_RUNTIME_DIR=/tmp/runtime-cooleruser
RUN mkdir -p /etc/coolercontrol && \
    chown cooleruser:cooleruser /etc/coolercontrol

# Copy artifacts from builder
COPY --from=builder /CoolerControlD-x86_64.AppImage /
COPY --from=builder /opt/coolercontrol/version /opt/coolercontrol/version

# Entrypoint setup
COPY entrypoint.sh /
RUN chmod +x /entrypoint.sh && chown cooleruser:cooleruser /entrypoint.sh

USER cooleruser
WORKDIR /
EXPOSE 11987

ENTRYPOINT ["/entrypoint.sh"]
