# Running a Fedimint with Docker

This repo contains a downloader script and various docker-compose configurations for running a Fedimint Guardian or a Fedimint Lightning Gateway.

The downloader script can be run on a fresh linux box and will install all the required software (docker, etc.) , then step you through selecting:

1. Whether you're installing a Guardian or a Lightning Gateway
2. Which network you're using (mainnet or mutinynet)
3. How you're getting your block data / lightning connection and whether to start a local bitcoin/lightning node or use a remote source

For a Guardian, the script will also step you through configuring your DNS records to ensure your fedimint is accessible over the web.

## Example: Guardian + Local Pruned Bitcoind on Mainnet

### Prerequisites

1. You have a Domain name purchased through a registrar like Cloudflare or Namecheap, for example `fedimintnow.com`
2. You have a Linux box configured on DigitalOcean, AWS, Linode, or some other cloud provider, for this example a $12/month Basic Ubuntu 24.04 box with `2` CPU, `4GB` RAM, and `80GB` SSD.
3. You can run terminal commands on the linux box.

### Step 1: Run the downloader script on the linux box

This script will create and configure a docker-compose.yaml file and a .env file in a directory named `fedimint-service`

```bash
curl -sSf https://raw.githubusercontent.com/fedimint/fedimint/master/scripts/downloader.sh | bash
```

### Step 2: Configuring the Docker Compose

Within the script, select in order:

- `1` for Guardian
- `1` for Mainnet
- `1` for Bitcoind
- `1` for Local Pruned Node

Which will download the docker-compose.yml file and a .env in a directory named `fedimint-service`

### Step 3: Verify the DNS configuration

Follow the instructions in the script to verify your DNS configuration. This consists of creating a CNAME record pointing to the ipv4 address of the machine fedimintd is being deployed to

### Step 3: Configure the .env file

The script will then prompt you and configure the following variable in the .env file:

- `FM_DOMAIN=`: The domain name you configured to point at this machine (e.g. `fedimintnow.org`)

The bitcoind RPC url and kind will already be configured to use the local bitcoind node.

### Step 4: Start the Guardian Service

The script will start the fedimint service by running `docker-compose up -d`, and you'll be able to access the guardian UI at your domain name (e.g. `https://fedimintnow.org`).
If you want want to stop the service, you can run `docker-compose down` in the `fedimint-service` directory, then start it again by running `docker-compose up -d`.

You're now ready to start using your Fedimint Guardian and perform the initial setup ceremony to create your federation.

## Recommended Hardware for Guardian/Gateway Configurations

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
