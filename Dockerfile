# Define Ubuntu LTS as base image
FROM ubuntu:26.04@sha256:2260313b31c8c011cd2eebe728008efac1b3982be73eb71348ea2648d2c0e09b

# Set Frigate version and expected PGP signature
# renovate: datasource=github-releases depName=sparrowwallet/frigate
ARG FRIGATE_VERSION=1.5.3
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

# Setup frigate user and group with static IDs
ARG GROUP_ID=1000
ARG USER_ID=1000
RUN (userdel ubuntu 2>/dev/null || true) \
    && groupadd -g ${GROUP_ID} frigate \
    && useradd -u ${USER_ID} -g frigate -d /frigate frigate
USER frigate

# Switch to home directory
WORKDIR /frigate

# Expose default TCP port
EXPOSE 57001

# Run Frigate
# Frigate is an Electrum JSON-RPC server (no HTTP API); probe the TCP
# listener on the documented [server] port (default/documented: 57001).
HEALTHCHECK --interval=30s --timeout=5s --start-period=60s CMD bash -c 'exec 3<>/dev/tcp/127.0.0.1/57001'

CMD ["/opt/frigate/bin/frigate", "--dir /frigate/.frigate"]
