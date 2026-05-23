# ---------- Builder stage ----------
FROM debian:trixie-slim AS builder

ARG TARGETPLATFORM
ARG FRIGATE_VERSION=1.5.2
ARG FRIGATE_PGP_SIG=E94618334C674B40

RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates \
    gnupg \
    wget \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /tmp

# Download, verify, and extract Frigate
RUN if [ "${TARGETPLATFORM}" = "linux/arm64" ]; then \
        ARCH="aarch64"; \
    else \
        ARCH="x86_64"; \
    fi && \
    wget \
      https://github.com/sparrowwallet/frigate/releases/download/${FRIGATE_VERSION}/frigate-${FRIGATE_VERSION}-${ARCH}.tar.gz \
      https://github.com/sparrowwallet/frigate/releases/download/${FRIGATE_VERSION}/frigate-${FRIGATE_VERSION}-manifest.txt \
      https://github.com/sparrowwallet/frigate/releases/download/${FRIGATE_VERSION}/frigate-${FRIGATE_VERSION}-manifest.txt.asc \
      https://keybase.io/craigraw/pgp_keys.asc && \
    gpg --import pgp_keys.asc && \
    gpg --status-fd 1 --verify frigate-${FRIGATE_VERSION}-manifest.txt.asc \
      | grep -q "GOODSIG ${FRIGATE_PGP_SIG}" && \
    sha256sum --check frigate-${FRIGATE_VERSION}-manifest.txt --ignore-missing && \
    tar xf frigate-${FRIGATE_VERSION}-${ARCH}.tar.gz -C /opt && \
    rm -rf /tmp/*

# ---------- Runtime stage ----------
FROM debian:trixie-slim

ARG TARGETPLATFORM
ARG USER_ID=1001
ARG GROUP_ID=1001

ARG INTEL_COMPUTE_RUNTIME_VERSION=26.18.38308.1
ARG INTEL_IGC_VERSION=2.34.4+21428
ARG INTEL_IGC_VERSION_SHORT=2.34.4

# Base dependencies + OpenCL loader
RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates \
    ocl-icd-libopencl1 \
    wget \
    && rm -rf /var/lib/apt/lists/*

# Intel OpenCL (amd64 only)
RUN if [ "${TARGETPLATFORM}" = "linux/amd64" ]; then \
    wget -q \
      "https://github.com/intel/intel-graphics-compiler/releases/download/v${INTEL_IGC_VERSION_SHORT}/intel-igc-core-2_${INTEL_IGC_VERSION}_amd64.deb" \
      "https://github.com/intel/intel-graphics-compiler/releases/download/v${INTEL_IGC_VERSION_SHORT}/intel-igc-opencl-2_${INTEL_IGC_VERSION}_amd64.deb" \
      "https://github.com/intel/compute-runtime/releases/download/${INTEL_COMPUTE_RUNTIME_VERSION}/libigdgmm12_22.10.0_amd64.deb" \
      "https://github.com/intel/compute-runtime/releases/download/${INTEL_COMPUTE_RUNTIME_VERSION}/intel-opencl-icd_${INTEL_COMPUTE_RUNTIME_VERSION}-0_amd64.deb" && \
    dpkg -i \
      intel-igc-core-2_${INTEL_IGC_VERSION}_amd64.deb \
      intel-igc-opencl-2_${INTEL_IGC_VERSION}_amd64.deb \
      libigdgmm12_22.10.0_amd64.deb \
      intel-opencl-icd_${INTEL_COMPUTE_RUNTIME_VERSION}-0_amd64.deb && \
    rm -f *.deb && \
    apt-get autoremove -y wget && \
    apt-get autoclean && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*; \
fi

# Copy Frigate from builder
COPY --from=builder /opt/frigate /opt/frigate

# Create non-root user (configurable, default 1001)
RUN groupadd -g ${GROUP_ID} frigate \
    && useradd -u ${USER_ID} -g ${GROUP_ID} -m -d /frigate frigate

USER frigate
WORKDIR /frigate

VOLUME /frigate/.frigate

CMD ["/opt/frigate/bin/frigate", "--dir /frigate/.frigate"]
