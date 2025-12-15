# Define Ubuntu LTS as base image
FROM ubuntu:latest

# Set Sparrow version and expected PGP signature
ARG FRIGATE_VERSION=1.3.2
ARG PGP_SIG=E94618334C674B40

# Update all packages and install requirements
RUN apt-get update \
    && apt-get upgrade -y
RUN DEBIAN_FRONTEND=noninteractive apt-get -y install --no-install-recommends curl \
    gnupg \
    wget \
    ca-certificates \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Switch to /tmp for verification and install
WORKDIR /tmp

# Detect and set architecture to properly download binaries
ARG TARGETARCH
RUN case ${TARGETARCH:-amd64} in \
    "arm64") FRIGATE_ARCH="aarch64";; \
    "amd64") FRIGATE_ARCH="x86_64";; \
    *) echo "Dockerfile does not support this platform"; exit 1 ;; \
    esac \
    # Download Frigate binaries and verification assets
    && wget --quiet https://github.com/sparrowwallet/frigate/releases/download/${FRIGATE_VERSION}/frigate-${FRIGATE_VERSION}-${FRIGATE_ARCH}.tar.gz \
                    https://github.com/sparrowwallet/frigate/releases/download/${FRIGATE_VERSION}/frigate-${FRIGATE_VERSION}-manifest.txt \
                    https://github.com/sparrowwallet/frigate/releases/download/${FRIGATE_VERSION}/frigate-${FRIGATE_VERSION}-manifest.txt.asc \
                    https://keybase.io/craigraw/pgp_keys.asc \
    # GPG verify, sha256sum verify, and unpack Frigate binaries
    && gpg --import pgp_keys.asc \
    && gpg --status-fd 1 --verify frigate-${FRIGATE_VERSION}-manifest.txt.asc \
    | grep -q "GOODSIG ${PGP_SIG}" \
    || exit 1 \
    && sha256sum --check frigate-${FRIGATE_VERSION}-manifest.txt --ignore-missing || exit 1 \
    && tar xf frigate-${FRIGATE_VERSION}-${FRIGATE_ARCH}.tar.gz -C /opt \
    && rm -rf /tmp/*

# Add user and setup directories for Sparrow
RUN useradd -ms /bin/bash frigate
USER frigate

# Switch to home directory
WORKDIR /home/frigate

# Run Frigate
CMD ["/opt/frigate/bin/frigate"]
