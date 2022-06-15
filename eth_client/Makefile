SHELL := /bin/bash

.PHONY: test dev.up deps

dev.up:
	iex -S mix

tilt.up: 
	docker exec -it ethereum_war_game_tooling_eth_client_1 iex -S mix

deps:
	mix deps.get

test:
	source ../.envrc
	mix test
