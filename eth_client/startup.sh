#! /bin/sh
set -eu

mix deps.get
iex --name eth_client@eth_client --cookie mycookie -S mix
