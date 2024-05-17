SHELL=bash

###################################################################################################
## INITIALISATION
###################################################################################################

export DOCKER_BUILDKIT=1
export COMPOSE_DOCKER_CLI_BUILD=1

COMPOSE_DEV_FILES = -f docker-compose.yml -f docker-compose.dev.yml
COMPOSE_PROD_FILES = -f docker-compose.yml

###################################################################################################
## DEV
###################################################################################################
.PHONY: build build-dev build-dev-no-cache start-prod start-prod-d start-dev start-dev-d stop shell logs

build: ##@dev Build the application for dev
	docker compose $(COMPOSE_PROD_FILES) build

build-no-cache: ##@dev Build the application for dev without using cache
	docker compose $(COMPOSE_PROD_FILES) build --no-cache

build-dev: ##@dev Build the application for dev
	docker compose $(COMPOSE_DEV_FILES) build

build-dev-no-cache: ##@dev Build the application for dev without using cache
	docker compose $(COMPOSE_DEV_FILES) build --no-cache

start-prod: ##@dev Start the development environment
	docker compose $(COMPOSE_PROD_FILES) up

start-prod-d: ##@dev Start the development environment (detached)
	docker compose $(COMPOSE_PROD_FILES) up -d

start-dev:
	docker compose $(COMPOSE_DEV_FILES) up

start-dev-d:
	docker compose $(COMPOSE_DEV_FILES) up -d

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