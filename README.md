# Running a Fedimint with Docker

This repo contains a downloader script and various docker-compose configurations for running a Fedimint Guardian or a Fedimint Lightning Gateway.

The downloader script can be run on a fresh linux box and will install all the required software (docker, etc.) , then step you through selecting:

1. Whether you're installing a Guardian or a Lightning Gateway
2. Which network you're using (mainnet or mutinynet)
3. How you're getting your block data / lightning connection and whether to start a local bitcoin/lightning node or use a remote source

For a Guardian, the script will also step you through configuring your DNS records to ensure your fedimint is accessible over the web.

## Recommended Hardware to run a Guardian/Gateway

### Guardian w/remote Bitcoind or Esplora

- A Linux box with at least:
  - 2-4GB RAM
  - 50GB Storage

### Guardian + Local Pruned Bitcoind

- A Linux box with at least:
  - 4-8GB RAM
  - 50GB Storage

### Gateway w/remote LND or local LDK

- A Linux box with at least:
  - 2-4GB RAM
  - 50GB Storage

### Gateway + Local LND

- A Linux box with at least:
  - 4-8GB RAM
  - 50GB Storage
