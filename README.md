# frigate-docker
A simple Docker container for Frigate, a Silent Payment server.

## Running this image

In order to run this image, you will need to pass a config file at `~/.frigate/config`, with the format and necessary fields as mentioned in the [official readme](https://github.com/sparrowwallet/frigate#configuration).

Specifically, the following fields are required, and will likely be populated in a similar way to the below example config file:

```json
{
  "coreServer": "http://bitcoind:8332",
  "coreDataDir": "/home/bitcoin/.bitcoin",
  "coreAuth": "bitcoin:password",
  "startIndexing": true,
  "backendElectrumServer": "tcp://fulcrum:50001"
}
```

In addition, you will need to map the `bitcoind` data directory into the container as well.

## Credit

I did the easy work of Dockerizing these binaries, but Craig Raw is the magician behind Frigate. Please take a minute to send him a donation or thank you if you enjoy using Frigate!

- [Donate to Craig Raw](https://sparrowwallet.com/donate/)
