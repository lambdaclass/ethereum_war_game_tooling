SHELL := /bin/bash

.PHONY: test dev.up deps

dev.up:
	iex -S mix

deps:
	mix deps.get

test:
	source ../.envrc
	mix test
