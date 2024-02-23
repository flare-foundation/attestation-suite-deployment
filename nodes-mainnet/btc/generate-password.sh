#!/bin/bash

password=$(openssl rand -hex 32)
echo "password: $password"
./rpcauth.py admin "$password"
