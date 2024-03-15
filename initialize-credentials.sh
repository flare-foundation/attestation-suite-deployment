#!/bin/bash

mkdir -p credentials

WORKING_DIR="$(pwd)"
USER_UID=$(id -u)
USER_GID=$(id -g)

docker run -u root --rm \
    -v $WORKING_DIR/credentials:/app/attestation-client/credentials \
    flarefoundation/attestation-client \
    yarn ts-node src/install/installCredentials.ts

docker run -u root --rm \
    -v $WORKING_DIR/credentials:/app/attestation-client/credentials \
    flarefoundation/attestation-client \
    cp configs/.install/configurations.json credentials/

docker run -u root --rm \
    -v $WORKING_DIR/credentials:/app/attestation-client/credentials \
    flarefoundation/attestation-client \
    chown -R $USER_UID:$USER_GID credentials
