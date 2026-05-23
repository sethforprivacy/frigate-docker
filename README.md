# frigate-docker
A simple Docker container for Frigate, a Silent Payments server.

---

## 🚀 Quick Start

### 1. Create data directory

```
mkdir -p ./data
```

Set correct permissions (required):

```
sudo chown -R 1001:1001 ./data
```

---

### 2. Create config file

Create:

```
./data/config.toml
```

In order to run this image, you will need to pass a config file at `/frigate/.frigate/config`, with the format and necessary fields as mentioned in the [official readme](https://github.com/sparrowwallet/frigate#configuration).

Specifically, the following is an example config, and will likely be populated in a similar way to the below example config file:

```toml
# Frigate configuration

[core]
connect = true
# server = "http://127.0.0.1:8332"
# authType = "COOKIE"            # COOKIE or USERPASS
# dataDir = "/home/bitcoin/.bitcoin"
# auth = "user:password"         # only needed for USERPASS
# zmqSequenceEndpoint = "tcp://127.0.0.1:28336"   # bitcoind -zmqpubsequence endpoint for low-latency mempool ingestion
# rpcRequestTimeoutSeconds = 60                   # per-RPC read timeout (raise on slow/remote bitcoind, lower on fast LAN)
# rpcBatchSize = 100                              # max sub-requests per JSON-RPC array batch (mempool fill)

[index]
# startHeight = 0                # default: 709632 on mainnet (Taproot activation), 0 on testnet
# cacheSize = "10M"              # scriptPubKey cache entries (default: 10M, ~4GB RAM)

[scan]
# batchSize = 300000             # rows per GPU dispatch (reduce if scanning hangs on older GPUs)
# computeBackend = "AUTO"        # AUTO, GPU, or CPU
# dbThreads = 4                  # limit DuckDB threads (reduces CPU load when computeBackend = "CPU")
# memoryLimit = "8GB"            # cap DuckDB memory usage (default: 80% of system RAM)
# maxLabels = 10                 # maximum number of labels accepted per silent payments subscription
# maxSubscriptions = 100         # maximum number of silent payments subscriptions per connection

[server]
# host = "localhost"             # advertised in server.features (set to public hostname for public-facing deployments)
# tcp = "tcp://0.0.0.0:50001"    # plaintext listener bind URL; omit (or "") to disable. Default if neither tcp nor ssl is set.
# ssl = "ssl://0.0.0.0:50002"    # SSL listener bind URL; omit to disable
# sslCert = "cert.pem"           # PEM certificate (chain allowed); bare filename resolves under Frigate's home dir, or use an absolute path
# sslKey  = "key.pem"            # PEM-encoded PKCS#8 private key; bare filename resolves under Frigate's home dir, or use an absolute path
# backendElectrumServer = "tcp://localhost:60001"   # backend must listen on a port distinct from Frigate's tcp/ssl listeners above
```

Lastly, ensure that the data directory you specify has proper R/W permissions for the default UID/GID of `1001`.


---

### 3. Basic docker-compose (CPU only)

```yaml
services:
  frigate:
    image: ghcr.io/sethforprivacy/frigate:latest
    container_name: frigate
    restart: unless-stopped
    ports:
      - "50001:50001"
      - "50002:50002"
    volumes:
      - ./data:/frigate/.frigate
```

---

## ⚡ GPU Acceleration

Frigate supports:
- NVIDIA (CUDA)
- Intel (OpenCL)
- AMD (OpenCL via ROCm)
- For more details, see the [Official Frigate README](https://github.com/sparrowwallet/frigate#gpu-requirements)

Set in config:

```
computeBackend = "AUTO"
```

---

## 🧠 Important: GPU Permissions

Linux requires access to GPU devices.

Add your user to required groups:

```
sudo usermod -aG render $USER
sudo usermod -aG video $USER
```

Then log out and back in (or reboot).

---

## 🔍 Find your render group ID

```
getent group render
```

Example output:

```
render:x:109:
```

Your `RENDER_GID` is `109`.

---

---

## 🧩 Docker Compose GPU Examples

### 🟢 Intel iGPU (OpenCL)

Requirements:
- `/dev/dri` available
- OpenCL working on host (`clinfo` shows GPU)
- On Linux, the ocl-icd-libopencl1 ICD loader is required
- For more intel details, see the [Enabling Intel iGPU on Linux](https://github.com/sparrowwallet/frigate#enabling-intel-igpu-on-linux)

```yaml
services:
  frigate:
    image: ghcr.io/sethforprivacy/frigate:latest
    container_name: frigate
    restart: unless-stopped
    ports:
      - "50001:50001"
      - "50002:50002"
    volumes:
      - ./data:/frigate/.frigate
    devices:
      - /dev/dri:/dev/dri
    group_add:
      - "109"
```

---

### 🟢 NVIDIA GPU (CUDA)

Requirements:
- NVIDIA driver installed
- nvidia-container-toolkit installed

```yaml
services:
  frigate:
    image: ghcr.io/sethforprivacy/frigate:latest
    container_name: frigate
    restart: unless-stopped
    ports:
      - "50001:50001"
      - "50002:50002"
    volumes:
      - ./data:/frigate/.frigate
    deploy:
      resources:
        reservations:
          devices:
            - driver: nvidia
              count: 1
              capabilities: [gpu]
```

Alternative (simpler setups may use):

```
docker compose run --gpus all
```

---

### 🟢 AMD GPU (ROCm / OpenCL)

Requirements:
- OpenCL working on host (`clinfo` shows GPU)
- Requires ROCm or AMDGPU-PRO OpenCL runtime
- On Linux, the ocl-icd-libopencl1 ICD loader is required
- User running the container must be in the 'render' and 'video' groups

```yaml
services:
  frigate:
    image: ghcr.io/sethforprivacy/frigate:latest
    container_name: frigate
    restart: unless-stopped
    ports:
      - "50001:50001"
      - "50002:50002"
    volumes:
      - ./data:/frigate/.frigate
      - /etc/OpenCL/vendors:/etc/OpenCL/vendors:ro
    devices:
      - /dev/dri:/dev/dri
      - /dev/kfd:/dev/kfd
    group_add:
      - "109"
```

## 💾 Data Directory

Frigate stores data in:

```
/frigate/.frigate
```

Ensure:

```
sudo chown -R 1001:1001 ./data
```

---

## ❤️ Credit

I did the easy work of Dockerizing these binaries, but Craig Raw is the magician behind Frigate.

https://sparrowwallet.com/donate/
