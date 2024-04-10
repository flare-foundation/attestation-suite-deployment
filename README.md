# Dockerized Installation

## Hardware Requirements

The recommended hardware requirements for running only the Attestation Suite are:

- CPU: 4 cores @ 2.2GHz
- DISK: 50 GB SSD disk
- MEMORY: 4 GB

The minimal hardware requirements for a complete `testnet` configuration are:

- CPU: 8 cores @ 2.2GHz
- DISK: 100 GB SSD disk
- MEMORY: 8 GB

The minimal hardware requirements for a complete `mainnet` configuration are:

- CPU: 16/32 cores/threads @ 2.2GHz
- DISK: 4 TB NVMe disk
- MEMORY: 64 GB

Most of this power is required for the Ripple node.

## Software Requirements

The Attestation Suite was tested on Debian 12 and Ubuntu 22.04.

Additional required software:

- *Docker* version 24.0.0 or higher
- *Docker Compose* version 2.18.0 or higher

## Prerequisites

- A machine(s) with `docker` and `docker compose` installed.
- A deployment user in the `docker` group.
- The Docker folder set to a mount point that has sufficient disk space for Docker volumes. The installation creates several Docker volumes.

## Installation

The deployment is made of different components:

- Blockchain nodes:
    - Bitcoin - `flarefoundation/bitcoin`
    - Dogecoin - `flarefoundation/dogecoin`
    - Ripple - `flarefoundation/rippled`
    - Ethereum
    - Flare - `flarefoundation/go-flare`
- Indexers and verification servers for:
    - BTC - `flarefoundation/attestation-client`
    - DOGE - `flarefoundation/attestation-client` and `flarefoundation/doge-indexer`
    - XRP - `flarefoundation/attestation-client`
- EVM verifier which doesn't need indexer - `flarefoundation/evm-verifier`
- Attestation client - `flarefoundation/attestation-client`

## Step 1 Clone deployment Repository

``` bash
git clone https://github.com/flare-foundation/attestation-suite-deployment.git
cd attestation-suite-deployment

```

### 1.2 (Optional) Build docker images

Docker images are automatically built and published to dockerhub. By default the deployment will download the images automatically. If you need to build them manually:

``` bash
git clone https://github.com/flare-foundation/attestation-client.git
cd attestation-client
docker build -t flarefoundation/attestation-client .
```

``` bash
git clone https://github.com/flare-foundation/doge-indexer.git
cd doge-indexer
docker build -t flarefoundation/doge-indexer -f docker/remote/Dockerfile .
```

``` bash
git clone https://github.com/flare-foundation/evm-verifier.git
cd evm-verifier
docker build -t flarefoundation/evm-verifier .
```


## Step 2 Credential Configs Generation

### 2.1 Initialize Credentials

Initialize credentials first:

``` bash
./initialize-credentials.sh
```

This creates the subfolder `credentials`.

> **Important**:
> Using this command again will overwrite your credentials!

### 2.2 Update Credentials

The file `credentials/configurations.json` contains the keys used to encrypt the credentials.
Provide relevant definition of the encryption keys in the `key` variables.

Use:

- `direct:<key>` to specify the key directly in place of `<key>`.
- `GoogleCloudSecretManager:<path>` to specify the Google Cloud Secret (More details can be found at [Google Cloud Secret Manager](./docs/GoogleCloudSecretManager.md) ). Enter the manager path in place of `<path>`.

Beside the `configuration.json` file, the `credentials` folder contains several credential configuration files of the form `<******>-credentials.json`.
Update these files with relevant credentials. Note that some passwords (with values `$(GENERATE_RANDOM_PASSWORD_<**>)`) are randomly generated with a secure random password generator. You may change those to suit your needs.

Some of the more important settings and credentials include:

- In `networks-credentials.json`:

    - `Network` - Set to desired network (e.g., `songbird`, `flare`).
    - `NetworkPrivateKey` - Set `0x`-prefixed private key from which an attestation client submits attestations to the Flare network. A private key can also be specified as a Google Cloud Secret Manager variable. To do that use this syntax:

        ```bash
        "NetworkPrivateKey":"$(GoogleCloudSecretManager:projects/<project>/secrets/<name>/versions/<version>)"
        ```

    - `StateConnectorContractAddress` - The `StateConnector` contract address on the specific network.
    - `RPC` - Update the network RPC to desired network.
- In `verifier-client-credentials.json` - Instead of `localhost`, use the IP address of the host machine. On Linux Ubuntu, get it by running:

    ```bash
    ip addr show docker0 | grep -Po 'inet \K[\d.]+'
    ```

- In `verifier-server-credentials.json` - Set API keys for supported external blockchains (currently BTC, DOGE and XRP). Default templates are configured
for two API keys.

### 2.3 Prepare Credentials

After credentials have been set up they must be prepared for deployment:

``` bash
./prepare-credentials.sh
```

This script creates secure credential configs in the subfolder `credentials.prepared`, which contains subfolders that are to be mounted to specific Docker containers on the deployment machine.

Each subfolder (Docker credentials mount) contains the following:

- `credentials.json.secure` - encrypted credentials (using encryption key as defined in `credentials/configuration.json`).
- `credentials.key` - decryption instructions.
- `templates` - subfolder with configurations as templates where credentials are indicated by stubs of the form `${credential_name}`. Parts of configs that don't concern credentials can be edited directly.

Secure credential configs work as follows: A process in a Docker container first identifies how the credentials in `filecredentials.json.secure` can be decrypted from the file `credentials.key`. Then the credential stubs in templates are filled in. The process reads configs and credentials from the rendered template structure in memory.

### 2.4 Copying Credentials

If the installation is done on a different deployment machine than the credential generation, proceed with steps 1.1 and 1.2 (cloning the repo and building the Docker image on the deployment machine). Copy the folder `deployment/credentials.prepared` from the secure machine to the deployment machine into the `<git-repo-root>/deployment` folder.

### 2.5 Configure external services

Services that are not part of the `attestation-client` container image / repository are configured with config files or environment variables.

## Step 3 Configuration

### 3.1 Configuring blockchain nodes

#### BTC

The only required configuration is setting the authentication for the node. To generate a password for admin user run:
``` bash
cd nodes-mainnet/btc
./generate-password.sh
```
example output:
```
password: c021cae645db6d3371b26ced94c8d17a5d9f3accbf3591d8b4c0be19623e5662
String to be appended to bitcoin.conf:
rpcauth=admin:a0956d81a2344f1602d9ed7b82ef3118$2caf19c9cf27937f728f600fc14e8db97f80218d727e331a57c3cfc55b3e17fe
Your password:
c021cae645db6d3371b26ced94c8d17a5d9f3accbf3591d8b4c0be19623e5662
```

or configure the username and password manually:

``` bash
./rpcauth.py <USERNAME> <PASSWORD>
```

#### DOGE

Configuration works like BTC.

For example, to generate a password for admin user run:
``` bash
cd nodes-mainnet/doge
./generate-password.sh
```

#### XRP

Default configuration doesn't need any additional configuration.

#### ETH

Configure the jwt.hex for authentication. Create the file `nodes-mainnet/eth/jwt.hex`. Or generate the password randomly:
``` bash
openssl rand -hex 32 > nodes-mainnet/eth/jwt.hex
```

### 3.2 Configuring indexers and verifier servers

To configure indexers, edit configuration files in `credentials` subfolder:
- `chain-credentials.json` - configure rpc urls and credentials for chain nodes
- `database-credentials.json` - configure database credentials, if you are using provided database deployment only change the passwords or use default random generated ones
- `verifier-server-credentials.json` - configure api keys that will be able to access apis on verifier servers or use default random generated ones

If you are only deploying indexers, you don't need to configure other configurations in `credentials` subfolder. Then generate configs as described in step 2.

Database credentials for indexers are configured in `*.env` files in `indexers` subfolder. Copy the `btc-indexer.env.example` to `btc-indexer.env` and configure database with the same credentials set in `database-credentials.json`. Configuration is the same for btc and xrp.

Dogecoin indexer is special, Dogecoin node rpc parameters and database credentials need to be set not only in json files in `credentials` folder but also in `doge-indexer.env`.

To configure if indexers are running on mainnet or testnet copy `indexers/env.example` to `indexers/.env` and set `TESTNET` variable.

### 3.3 Configuring attestation client

To configure attestation client, edit the configuration files in `credentials` subfolder:
- `database-credentials.json` - configure database credentials, if you are using provided database deployment only change the passwords or use default random generated ones
- `networks-credentials.json` - configure the private key, network name and contract addresses
- `verifier-server-credentials.json` - configure the urls and api keys to access verifier servers (set in previous step in `verifier-server-credentials.json`)
- `webserver-credentials.json` - configure the webserver port

If you are only deploying attestation client, you don't need to configure other configurations in `credentials` subfolder. Then generate configs as described in step 2.

Database credentials for attestation-client are configured in `attestation-client-db.env` files in `attestation-client` subfolder. Copy the `attestation-client-db.env.example` to `attestation-client-db.env` and configure database with the same credentials you have set in `database-credentials.json`.

Network name must also be set in `attestation-client.env`.

### 3.4 Configuring EVM verifier

EVM verifier is configured with env variables. Example values are provided in `evm-verifier/env.example`

## Step 4 Running


### 3.1 Starting blockchain nodes

cd into correct directory (example `nodes-mainnet/btc`) and run `docker compose up -d`.

### 3.2 Starting indexers

when starting with docker compose be careful to set the docker compose file and project name correctly. For example to start doge indexer:
``` bash
docker compose -f docker-compose-indexer-doge.yaml -p indexer-doge up -d
```
`start.sh` and `stop.sh` scripts are provided for convenience. Run:
``` bash
./start.sh doge
```

### 4.3 Starting attestation client

cd into correct directory (`attestation-client`) and run `docker compose up -d`.


## Indexer Syncing Times

To be ready for use, each network must sync its blocks and transactions with the Flare database indexer.
For two days worth of data, these are the times that each network requires:

- BTC ~20 min
- DOGE ~45 min
- XRP ~2 h
