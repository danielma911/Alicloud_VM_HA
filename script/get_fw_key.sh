#!/bin/bash
set -e
eval "$(jq -r '@sh "export EIP=\(.eip) USERNAME=\(.username) PASSWORD=\(.password)"')"

function produce_output() {
  api=""
  while [[ -z "$api" ]]; do
  	export api=$(curl -k https://"${EIP}"/api/\?type\=keygen\&user\="${USERNAME}"\&password\="${PASSWORD}" | awk -F"<key>" '{print $2}' | awk -F"</key>" '{print $1}')
    sleep 30
  done
  
  jq -n \
    --arg api_key "$api" \
    '{"api_key":$api_key}'
}

produce_output