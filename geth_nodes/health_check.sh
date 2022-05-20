#! /usr/bin/env bash
set -euo pipefail

readonly GET_BLOCK_NUMBER_PAYLOAD='{"jsonrpc":"2.0","method":"eth_blockNumber","params":[],"id":83}'

get_block_number() {
    local url="${1}"

    curl \
            -s\
            -X POST \
            -H 'Content-Type: application/json' \
            --data "${GET_BLOCK_NUMBER_PAYLOAD}" \
            "${url}" \
        | jq -r '.result'
}

report_block_number() {
    local url="${1}"
    local block_number="$(get_block_number ${url})"

    echo "${url} ${block_number}"
}

report_block_number "http://localhost:8545"
report_block_number "http://localhost:8546"

