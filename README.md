# frigate-docker
A simple Docker container for Frigate, a Silent Payment server.

## Running this image

In order to run this image, you will need to pass a config file at `/frigate/.frigate/config`, with the format and necessary fields as mentioned in the [official readme](https://github.com/sparrowwallet/frigate#configuration).

Specifically, the following is an example config, and will likely be populated in a similar way to the below example config file:

```toml
# Frigate configuration

[core]
connect = true
server = "http://bitcoind:8332"
authType = "USERPASS"
auth = "{{ rpc_user }}:{{ rpc_password }}"
zmqSequenceEndpoint = "tcp://bitcoind:8435"

[index]
# startHeight = 0                # default: 709632 on mainnet (Taproot activation), 0 on testnet
# cacheSize = "10M"              # scriptPubKey cache entries (default: 10M, ~4GB RAM)

[scan]
# batchSize = 300000             # rows per GPU dispatch (reduce if scanning hangs on older GPUs)
# computeBackend = "AUTO"        # AUTO, GPU, or CPU
# dbThreads = 4                  # limit DuckDB threads (reduces CPU load when computeBackend = "CPU")

[server]
port = 57001
backendElectrumServer = "tcp://fulcrum:50001"
```

Lastly, ensure that the data directory you specify has proper R/W permissions for the default UID/GID of `1001`.

## Credit

I did the easy work of Dockerizing these binaries, but Craig Raw is the magician behind Frigate. Please take a minute to send him a donation or thank you if you enjoy using Frigate!

- [Donate to Craig Raw](https://sparrowwallet.com/donate/)
