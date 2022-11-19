#!/usr/bin/env bash

# NOTE: ct logs don't support self-signed certs, yet...

exit 1

CHAIN=$(grep -v 'CERT' server.pem | tr -d '\n')

curl \
    -X POST \
    -d "{\"chain\": [\"${CHAIN}\"]}" \
    -H "Content-Type: application/json" \
    -H "User-Agent: github.com/OllieJC/justselfsigned.org" \
   https://sapling.ct.letsencrypt.org/2022h2/ct/v1/add-pre-chain
