SHELL=bash

###################################################################################################
## INITIALISATION
###################################################################################################

export DOCKER_BUILDKIT=1
export COMPOSE_DOCKER_CLI_BUILD=1

###################################################################################################
## DEV
###################################################################################################
.PHONY: build build-no-cache start start-d stop shell logs

build: ##@dev Build the application for dev
	docker compose build

build-no-cache: ##@dev Build the application for dev without using cache
	docker compose build --no-cache

start: ##@dev Start the development environment
	docker compose up

start-d: ##@dev Start the development environment (detached)
	docker compose up -d

stop: ##@dev Stop the development environment
	docker compose down

shell: ##@dev Go into the running container (the app name should match what's in docker-compose.yml)
	docker compose exec app /bin/sh

logs: ##@dev Show the logs of the running containers
	docker compose logs -f

###################################################################################################
## HELP
###################################################################################################

.PHONY: default
default: help

GREEN  := $(shell tput -Txterm setaf 2)
WHITE  := $(shell tput -Txterm setaf 7)
YELLOW := $(shell tput -Txterm setaf 3)
RESET  := $(shell tput -Txterm sgr0)

HELP_FUN = \
	%help; \
	while(<>) { push @{$$help{$$2 // 'options'}}, [$$1, $$3] if /^([a-zA-Z\-]+)\s*:.*\#\#(?:@([a-zA-Z\-]+))?\s(.*)$$/ }; \
	print "usage: make [target]\n\n"; \
	for (sort keys %help) { \
	print "${WHITE}$$_:${RESET}\n"; \
	for (@{$$help{$$_}}) { \
	$$sep = " " x (32 - length $$_->[0]); \
	print "  ${YELLOW}$$_->[0]${RESET}$$sep${GREEN}$$_->[1]${RESET}\n"; \
	}; \
	print "\n"; }

help: ##@other Show this help
	@perl -e '$(HELP_FUN)' $(MAKEFILE_LIST)