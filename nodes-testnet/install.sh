#!/bin/bash

chain="$1"

cd "$chain"

if [[ "$chain" != "ripple" ]]; then
	password=$(openssl rand -hex 32)
	echo "password: $password"
	./rpcauth.py admin "$password"
fi

docker compose -p $chain up -d
