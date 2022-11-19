#!/usr/bin/env bash

PRIMARY_DOMAIN="justselfsigned.org"
SERVER_PEM="server.pem"
KEY_PEM="key.pem"
LIGHTSAIL_PREFIX="lightsail-nodejs-"
AWS_REGION="eu-west-2"
export AWS_REGION="$AWS_REGION"

CWD="$(pwd)"

ARGS=$(echo "$1,$2" | tr -d '-' | tr -d '[:space:]' | tr '[:upper:]' '[:lower:]')

DEBUG=0; if [[ "$ARGS" =~ "debug" ]]; then DEBUG=1; fi
JSON=0; if [[ "$ARGS" =~ "json" ]]; then JSON=1; fi

log () {
  message=$(echo "$1")
  colour=$(echo "$2" | tr -d '\n' | tr '[:upper:]' '[:lower:]')
  needs_debug=$(echo "$3" | tr -d '\n')

  RED='\033[0;31m'
  GREEN='\033[0;32m'
  ORANGE='\033[0;33m'
  BLUE='\033[0;34m'

  START_COLOUR=''
  END_COLOUR=''
  if [ "$JSON" == "0" ]; then
    if [ "$colour" == "red" ]; then START_COLOUR="$RED";
    elif [ "$colour" == "green" ]; then START_COLOUR="$GREEN";
    elif [ "$colour" == "orange" ]; then START_COLOUR="$ORANGE";
    elif [ "$colour" == "blue" ]; then START_COLOUR="$BLUE"; fi
    END_COLOUR='\033[0m' # No Color
  fi

  MSG=""
  if [ "$needs_debug" == "1" ]; then
    if [ "$DEBUG" == "1" ]; then
      MSG="${START_COLOUR}${message}${END_COLOUR}"
    fi
  else
    MSG="${START_COLOUR}${message}${END_COLOUR}"
  fi

  if [ "$MSG" != "" ]; then
    epoch=$(date +%s\.%3N)
    if [ "$JSON" == "1" ]; then
      MSG=$(echo "$MSG" | tr -d '\n' | xargs)
      printf "{\"time\": \"${epoch}\", \"message\": \"${MSG}\", \"debug\": \"${DEBUG}\"}\n"
    else
      printf "${epoch}: ${MSG}\n"
    fi
  fi
}

if [[ "$CWD" =~ /deploy$ ]]; then
  log "Running from: $CWD" "red" 1
else
  log "Not in 'deploy' folder" "red"
  exit 1
fi

NOEXES="0"
if [ "$(command -v terraform)" == "" ]; then
  log "terraform not found!" "red"
  NOEXES="1"
fi
if [ "$(command -v python3)" == "" ]; then
  log "python3 not found!" "red"
  NOEXES="1"
fi
if [ "$(command -v openssl)" == "" ]; then
  log "openssl not found!" "red"
  NOEXES="1"
fi
if [ "$(command -v aws)" == "" ]; then
  log "aws-cli not found!" "red"
  NOEXES="1"
fi
if [ "$(command -v jq)" == "" ]; then
  log "jq not found!" "red"
  NOEXES="1"
fi
if [ "$NOEXES" == "1" ]; then
  exit 1
fi

AWS_CHECK=$(aws sts get-caller-identity 2>&1 | tr -d '\n')
if [[ "$AWS_CHECK" =~ "error" ]]; then
  log "Failed to authenticate to AWS: $AWS_CHECK" "red"
  exit 1
else
  log "$AWS_CHECK" "blue" 1
fi

log "== 0-new.sh ==" "orange"

# generate a new key
log "generating new private key" "green"
private_key_output=$(openssl ecparam -name secp384r1 -genkey -noout -out "$KEY_PEM" 2>&1)
log "openssl ecparam: $private_key_output" "red" 1

# generate the pre-certificate
log "generating new SSC pre-certificate" "green"

# generate the server SSC
log "generating new SSC certificate" "green"
ssc_output=$(openssl req -config openssl.conf -batch -x509 -nodes -days 7 -key "$KEY_PEM" -out "$SERVER_PEM" -verbose 2>&1)
log "openssl req: $ssc_output" "red" 1

SERVER_PEM_STRING=$(cat "$SERVER_PEM")
log "SERVER PEM: $SERVER_PEM_STRING" "red" 1

KEY_PEM_STRING=$(cat "$KEY_PEM")

NEW_TLSA=$(openssl x509 -noout -fingerprint -sha256 -inform pem -in "$SERVER_PEM" | cut -d'=' -f2- | tr -d ':' | tr -d '[:space:]' | tr '[:upper:]' '[:lower:]')
echo "$NEW_TLSA" > cert.sig
log "NEW_TLSA: $NEW_TLSA" "red" 1

# get existing TLSA signature, we'll need to remove this AFTER the new instances are deployed and ready

EXISTING_TLSA=$(dig +short "_443._tcp.$PRIMARY_DOMAIN" TLSA | cut -d ' ' -f4- | tr -d '[:space:]' | tr '[:upper:]' '[:lower:]')
log "EXISTING_TLSA: $EXISTING_TLSA" "red" 1

# get current IP addresses from Lightsail instances, we'll remove these eventually

EXISTING_INSTANCES=$(aws lightsail get-instances --output json)
EXISTING_INSTANCES_NAMES=$(jq .instances[].name <<< "$EXISTING_INSTANCES")

EXISTING_AB_OR_CD=""
NEW_AB_OR_CD=""

EXISTING_IPV4S=""
EXISTING_IPV6S=""

while IFS=' ' read -r RAW_INST; do
  INSTANCE=$(echo "$RAW_INST" | tr -d '"' | tr -d '[:space:]' | tr '[:upper:]' '[:lower:]')
  log "EXISTING INSTANCE: $INSTANCE" "red" 1

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
log "EXISTING_IPV4S: $EXISTING_IPV4S" "red" 1
log "EXISTING_IPV6S: $EXISTING_IPV6S" "red" 1

# create new instances
python3 1-generate-instance-files.py

LIGHTSAIL_PORT_INFO=$(cat "lightsail-port-info.json" | tr -d '[:space:]')

NEW_IPV4S=""
NEW_IPV6S=""

while read -r NEW_INSTANCE; do
  log "aws lightsail create-instances: ${LIGHTSAIL_PREFIX}${NEW_INSTANCE}" "red" 1

  NEW_INSTANCE_NAME="${LIGHTSAIL_PREFIX}${NEW_INSTANCE}"

  AZ="a"
  if [ "$NEW_INSTANCE" == "b" ] || [ "$NEW_INSTANCE" == "d" ]; then
    AZ="b"
  fi

  creation=$(aws lightsail create-instances \
    --instance-names "$NEW_INSTANCE_NAME" \
    --availability-zone "${AWS_REGION}${AZ}" \
    --blueprint-id nodejs \
    --bundle-id nano_2_0 \
    --user-data file://generated-launch-script.sh \
    --ip-address-type dualstack \
    --key-pair-name "lightsail-edge" 2>&1)
  if [[ "$creation" =~ "error" ]]; then
    log "aws lightsail create-instances failed: $creation" "red"
    exit 1
  else
    log "aws lightsail create-instances: $creation" "red" 1
  fi

  log "Sleeping for 1 minute while instance starts" "red" 1
  sleep 60s

  publicports=$(aws lightsail put-instance-public-ports \
    --port-infos "$LIGHTSAIL_PORT_INFO" \
    --instance-name "$NEW_INSTANCE_NAME" 2>&1)
  if [[ "$publicports" =~ "error" ]]; then
    log "aws lightsail put-instance-public-ports failed: $publicports" "red"
    exit 1
  else
    log "aws lightsail put-instance-public-ports: $publicports" "red" 1
  fi

  INSTANCES_DETAILS=$(aws lightsail get-instance --instance-name "$NEW_INSTANCE_NAME" --output json)

  NEW_IPV4S+=$(jq -r ".instance | select(.name == \"$NEW_INSTANCE_NAME\") | .publicIpAddress" <<< "$INSTANCES_DETAILS")
  NEW_IPV4S+=" "

  NEW_IPV6S+=$(jq -r ".instance | select(.name == \"$NEW_INSTANCE_NAME\") | .ipv6Addresses[]" <<< "$INSTANCES_DETAILS")
  NEW_IPV6S+=" "
done <<< "$NEW_AB_OR_CD"

NEW_IPV4S=$(echo "$NEW_IPV4S" | xargs | tr ' ' ',' | tr -d '[:space:]')
NEW_IPV6S=$(echo "$NEW_IPV6S" | xargs | tr ' ' ',' | tr -d '[:space:]')
log "NEW_IPV4S: $NEW_IPV4S" "red" 1
log "NEW_IPV6S: $NEW_IPV6S" "red" 1

FIRST_IP=$(echo "$NEW_IPV4S" | cut -d',' -f1 | tr -d '[:space:]')
if [ "$FIRST_IP" == "" ]; then
  log "Didn't find new IPs, quitting!" "red"
  exit 1
fi

log "Sleeping for 10 seconds" "red" 1
sleep 10s

cd ../terraform/google_dns/
terraform init
terraform apply -auto-approve \
  -var="cert_sig=${NEW_TLSA}" \
  -var="existing_sig=${EXISTING_TLSA}" \
  -var="a_ipv4s=[\"${EXISTING_IPV4S/,/\",\"}\"]" \
  -var="aaaa_ipv6s=[\"${EXISTING_IPV6S/,/\",\"}\"]"

ready_check() {
  local CHECK=$(curl -s \
    --retry 1 \
    --retry-delay 1 \
    --retry-max-time 20 \
    --connect-timeout 10 \
    --retry-all-errors \
    -k "https://$1/ready.html" | tr -d '[:space:]')
  if [ "$CHECK" == "YES" ]; then
    echo "YES"
  else
    echo "NO"
  fi
}

READY_COUNTER=0
until [ "$(ready_check "$FIRST_IP")" == "YES" ]; do
  ((READY_COUNTER=READY_COUNTER+1))
  if [ $READY_COUNTER -gt 10 ]; then
    log "$FIRST_IP wasn't ready in time!" "red"
    exit 1
  else
    log "$READY_COUNTER: $FIRST_IP still not ready..." "red" 1
  fi
  sleep 10
done

terraform apply -auto-approve \
  -var="cert_sig=${NEW_TLSA}" \
  -var="existing_sig=${EXISTING_TLSA}" \
  -var="a_ipv4s=[\"${NEW_IPV4S/,/\",\"}\"]" \
  -var="aaaa_ipv6s=[\"${NEW_IPV6S/,/\",\"}\"]"

log "Sleeping for 10 seconds" "red" 1
sleep 10s

while IFS=' ' read -r RAW_INST; do
  INSTANCE=$(echo "$RAW_INST" | tr -d '"' | tr -d '[:space:]' | tr '[:upper:]' '[:lower:]')
  log "Removing: $INSTANCE" "red" 1
  removal=$(aws lightsail delete-instance --instance-name "$INSTANCE" 2>&1)
  if [[ "$removal" =~ "error" ]]; then
    log "aws lightsail delete-instance failed: $removal" "red"
    exit 1
  else
    log "aws lightsail delete-instance: $removal" "red" 1
  fi
done <<< "$EXISTING_INSTANCES_NAMES"

log "Finished!" "green"
