#!/bin/bash

mkdir -p credentials.prepared

WORKING_DIR="$(pwd)"

docker run -u root --rm \
    -v $WORKING_DIR/credentials:/app/attestation-suite-config \
    -v $WORKING_DIR/credentials.prepared:/app/credentials \
    flarefoundation/attestation-client:olympics-web2 \
    yarn ts-node src/install/secureConfigurations.ts -o ../credentials

