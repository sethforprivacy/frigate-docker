# frigate-docker
A simple Docker container for Frigate, a Silent Payment server.

## Running this image

In order to run this image, you will need to pass a config file at `/frigate/.frigate/config.toml`, with the format and necessary fields as mentioned in the [official readme](https://github.com/sparrowwallet/frigate#configuration). The file must be named `config.toml`: Frigate reads an extension-less `config` as legacy JSON.

The container starts Frigate with no arguments, so its home directory is the default `/frigate/.frigate` (config, index database and logs). Mount your data directory there.

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
tcp = "tcp://0.0.0.0:57001"      # the port this image EXPOSEs and health-checks
backendElectrumServer = "tcp://fulcrum:50001"

[limits]
# Defaults are tuned for a public server, e.g. maxConnectionsPerIp = 12.
# Clients that reach the container through a proxy share its address, so
# add that proxy's subnet here to exempt them from the per-IP limits.
# excludedSubnets = ["127.0.0.1/32", "::1/128"]
```

The image's `EXPOSE` and `HEALTHCHECK` use port `57001`, so keep the `tcp` listener there (the older `port = 57001` form still works). Without it, Frigate listens on its own default of `50001` and the container reports unhealthy.

To pass options to Frigate, override the command with each option and value as a separate argument, for example `["/opt/frigate/bin/frigate", "--network", "signet"]`. Frigate exits on any option it does not recognise.

Lastly, ensure that the data directory you specify has proper R/W permissions for the default UID/GID of `1000`.

## Credit

I did the easy work of Dockerizing these binaries, but Craig Raw is the magician behind Frigate. Please take a minute to send him a donation or thank you if you enjoy using Frigate!

- [Donate to Craig Raw](https://sparrowwallet.com/donate/)
