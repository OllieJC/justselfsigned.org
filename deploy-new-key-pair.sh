#!/usr/bin/env bash

PRIMARY_DOMAIN="justselfsigned.org"
SERVER_PEM="server.pem"
KEY_PEM="key.pem"
LIGHTSAIL_PREFIX="lightsail-nodejs-"
REGION="eu-west-2"

# generate a new key pair

openssl req -config openssl.conf -batch -x509 -nodes -days 7 -newkey ec:<(openssl ecparam -name secp384r1) -keyout "$KEY_PEM" -out "$SERVER_PEM"

SERVER_PEM_STRING=$(cat "$SERVER_PEM")
KEY_PEM_STRING=$(cat "$KEY_PEM")

NEW_TLSA=$(openssl x509 -noout -fingerprint -sha256 -inform pem -in "$SERVER_PEM" | cut -d'=' -f2- | tr -d ':' | tr -d '[:space:]' | tr '[:upper:]' '[:lower:]')
echo "$NEW_TLSA" > cert.sig

# get existing TLSA signature, we'll need to remove this AFTER the new instances are deployed and ready

EXISTING_TLSA=$(dig +short "_443._tcp.$PRIMARY_DOMAIN" TLSA | cut -d ' ' -f4- | tr -d '[:space:]' | tr '[:upper:]' '[:lower:]')

# get current IP addresses from Lightsail instances, we'll remove these eventually

EXISTING_INSTANCES=$(aws lightsail get-instances --output json)
EXISTING_INSTANCES_NAMES=$(jq .instances[].name <<< "$EXISTING_INSTANCES")

EXISTING_AB_OR_CD=""
NEW_AB_OR_CD=""

EXISTING_IPV4S=""
EXISTING_IPV6S=""

while IFS=' ' read -r RAW_INST; do
  INSTANCE=$(echo "$RAW_INST" | tr -d '"' | tr -d '[:space:]' | tr '[:upper:]' '[:lower:]')

  if [ "$INSTANCE" = "${LIGHTSAIL_PREFIX}a" ] || [ "$INSTANCE" = "${LIGHTSAIL_PREFIX}b" ]; then
      EXISTING_AB_OR_CD="a
b"
      NEW_AB_OR_CD="c
d"
  else
      EXISTING_AB_OR_CD="c
d"
      NEW_AB_OR_CD="a
b"
  fi

  EXISTING_IPV4S+=$(jq -r ".instances[] | select(.name == \"$INSTANCE\") | .publicIpAddress" <<< "$EXISTING_INSTANCES")
  EXISTING_IPV4S+=" "

  EXISTING_IPV6S+=$(jq -r ".instances[] | select(.name == \"$INSTANCE\") | .ipv6Addresses[]" <<< "$EXISTING_INSTANCES")
  EXISTING_IPV6S+=" "
done <<< "$EXISTING_INSTANCES_NAMES"

EXISTING_IPV4S=$(echo "$EXISTING_IPV4S" | xargs | tr ' ' ',' | tr -d '[:space:]')
EXISTING_IPV6S=$(echo "$EXISTING_IPV6S" | xargs | tr ' ' ',' | tr -d '[:space:]')

# create new instances

python3 generate-instance-files.py

LIGHTSAIL_PORT_INFO=$(cat "lightsail-port-info.json" | tr -d '[:space:]')

while read -r NEW_INSTANCE; do
  echo "New instance: ${LIGHTSAIL_PREFIX}${NEW_INSTANCE}"

  NEW_INSTANCE_NAME="${LIGHTSAIL_PREFIX}${NEW_INSTANCE}"

  AZ="a"
  if [ "$NEW_INSTANCE" == "b" ] || [ "$NEW_INSTANCE" == "d" ]; then
    AZ="b"
  fi

  aws lightsail create-instances \
    --instance-names "$NEW_INSTANCE_NAME" \
    --availability-zone "${REGION}${AZ}" \
    --blueprint-id nodejs \
    --bundle-id nano_2_0 \
    --user-data file://generated-launch-script.sh \
    --ip-address-type dualstack \
    --key-pair-name "lightsail-edge"

  sleep 5s

  aws lightsail put-instance-public-ports \
    --port-infos "$LIGHTSAIL_PORT_INFO" \
    --instance-name "$NEW_INSTANCE_NAME"
done <<< "$NEW_AB_OR_CD"

sleep 10s
