DIR := ${CURDIR}
FUNCTIONS = $(shell ls functions)
WORK_FUNCTIONS = generate-document

NPM_TOKEN := $(shell echo ${NPM_TOKEN})

PURPLE 		:= $(shell tput setaf 129)
GRAY  		:= $(shell tput setaf 245)
GREEN  		:= $(shell tput setaf 34)
BLUE 		:= $(shell tput setaf 25)
YELLOW 		:= $(shell tput setaf 3)
WHITE  		:= $(shell tput setaf 7)
RESET  		:= $(shell tput sgr0)

.PHONY: help h
.DEFAULT_GOAL := help

help:

	@echo Stack Targets:
	@echo
	@awk '/^[a-zA-Z\/\-\_0-9]+:/ { \
		helpMessage = match(lastLine, /^## (.*)/); \
		if (helpMessage) { \
			helpCommand = substr($$1, 0, index($$1, ":")-1); \
			helpMessage = substr(lastLine, RSTART + 3, RLENGTH); \
			printf "  ${GREEN}%-10s${RESET} ${GRAY}%s${RESET}\n", helpCommand, helpMessage; \
		} \
	} \
	{ lastLine = $$0 }' $(MAKEFILE_LIST)
	@echo
	@echo Function Targets:
	@echo
	@awk '/^[a-zA-Z\/\-\_0-9]+:/ { \
		helpMessage = match(lastLine, /^### (.*)/); \
		if (helpMessage) { \
			helpCommand = substr($$1, 0, index($$1, ":")-1); \
			helpMessage = substr(lastLine, RSTART + 3, RLENGTH); \
			printf "  ${GREEN}%-30s${RESET} ${GRAY}%s${RESET}\n", helpCommand, helpMessage; \
		} \
	} \
	{ lastLine = $$0 }' $(MAKEFILE_LIST)
	@echo
	@echo Hasura Targets:
	@echo
	@awk '/^[a-zA-Z\/\-\_0-9]+:/ { \
		helpMessage = match(lastLine, /^#### (.*)/); \
		if (helpMessage) { \
			helpCommand = substr($$1, 0, index($$1, ":")-1); \
			helpMessage = substr(lastLine, RSTART + 3, RLENGTH); \
			printf "  ${GREEN}%-30s${RESET} ${GRAY}%s${RESET}\n", helpCommand, helpMessage; \
		} \
	} \
	{ lastLine = $$0 }' $(MAKEFILE_LIST)


guard-%:
	@ if [ "${${*}}" = "" ]; then \
		echo "Environment variable $* not set (make $*=.. target or export $*=.."; \
		exit 1; \
	fi

setup: stack/infra/install env/clone node/install/all stack/all/buildrestart

coreup: stack/infra/up stack/corefunctions/up

work: stack/infra/up stack/functions/up

leave: stack/infra/down stack/functions/down

## Creates the docker network (checks if it exists first).
stack/network/create:

	@docker network inspect hasurify_network > /dev/null || docker network create --ipam-driver default --subnet=172.0.0.0/16 --attachable hasurify_network

## Destroys and re-creates the docker network.
stack/network/recreate:

	@echo "Re-creating docker network.."

	#
	# Test if network exists, if so delete it.
	#
	@docker network inspect hasurify_network && docker network rm hasurify_network

	#
	# Create the network
	#
	@docker network create --ipam-driver default --subnet=172.0.0.0/16 --attachable hasurify_network

## Bring only the infrastructure containers UP
stack/infra/up: stack/network/create

	@echo "Bringing infrastructure containers up..."
	@docker-compose -f docker-compose.yml up -d

	@$(MAKE) stack/status

stack/infra/purge:
	@echo "Removing all containers and images..."
	@docker rm -f $(shell docker ps | grep "hasura-" | awk '{print $$1}')
	@docker rmi -f $(shell docker images | grep "hasura-" | awk "{print \$$3}")
	@docker rmi -f $(shell docker images | grep "<none>" | awk "{print \$$3}")

## Bring only the infrastructure containers DOWN (does not touch the module services).
stack/infra/down:

	@echo "Bringing infrastructure containers down..."
	@docker-compose -f docker-compose.yml down

	@$(MAKE) stack/status

## Restart only the infrastructure containers.
stack/infra/restart: stack/infra/down stack/infra/up

## Re-builds and re-starts ALL functions including infrastructure services.
stack/all/buildrestart: stack/infra/restart stack/functions/down stack/functions/buildup

## Bring only the infrastructure containers DOWN (does not touch the module services) + DELETE data volumes.
stack/infra/downdeletevolumes:

	@echo "Bringing infrastructure containers down..."
	@docker-compose -f docker-compose.yaml down -v

## Remove node_modules across all functions.
node/remove/all:
	@echo "Removing npm packages from all modules..."
	@for F in $(WORK_FUNCTIONS); do cd $(DIR)/functions/$$F && [ -d node_modules ] && echo "Removing npm packages for $$F..." && rm -rf node_modules; done
	@echo "Finished removing npm packages"

## Install node_modules across all functions.
node/install/all:
	@echo "Installing npm packages for all modules..."
	@for F in $(WORK_FUNCTIONS); do cd $(DIR)/functions/$$F && [ -f package.json ] && echo "Installing npm packages for $$F..." && yarn install; done
	@echo "Finished installing npm packages"

## Install a specific node module with @latest (requires PACKAGE p) across all functions
node/install/package: guard-p
	@echo "Installing npm package $(p) for all modules..."
	@for F in $(WORK_FUNCTIONS); do cd $(DIR)/functions/$$F && [ -f package.json ] && yarn install $(p); done
	@echo "Finished installing npm package $(p)"

## Uninstall a specific node module with @latest (requires PACKAGE p) across all functions
node/uninstall/package: guard-p
	@echo "Uninstalling npm package $(p) for all modules..."
	@for F in $(WORK_FUNCTIONS); do cd $(DIR)/functions/$$F && [ -f package.json ] && yarn uninstall $(p); done
	@echo "Finished uninstalling npm package $(p)"

## Clone env file
env/clone:
	@cp .env.example .env

## Displays the output of docker.
stack/status:

	@echo "${BLUE}########################################################################################################################${RESET}"
	@echo "${GREEN}CURRENT CONTAINER STATUS:${RESET}"
	@echo "----"
	@docker ps -a --format '{{.Names}};{{.Status}};{{.Ports}}' | grep hasurify | column -s";" -t
	@echo "----"
	@echo "TOTAL: ${GREEN}$(shell docker ps -a | grep hasurify | wc -l)${RESET}"
	@echo "${BLUE}########################################################################################################################${RESET}"

### Bring only the functions DOWN (not the main dependencies like postgres, elasticsearch, etc).
stack/functions/down:

	@echo "Bringing modules down.."
	@for F in $(WORK_FUNCTIONS); do echo "bringing down $$F.."; cd $(DIR)/functions/$$F && cp .env.example .env && [ -f docker-compose.yml ] && docker-compose down; done

### Bring only the functions UP (not the main dependencies like postgres, graphql-engine, etc).
stack/functions/up:
	@echo "Spinning up modules.."
	@for F in $(WORK_FUNCTIONS); do echo "spinning up $$F.."; cd $(DIR)/functions/$$F && cp .env.example .env && [ -f docker-compose.yml ] && docker-compose up -d; done

### Restart all functions
stack/functions/restart: stack/functions/down stack/functions/up

### Build and start all containers
stack/functions/buildup: stack/functions/build stack/functions/up
	@$(MAKE) stack/status

#### Install Hasura CLI	
hasura/install:
	@echo "Installing Hasura CLI..."
	@curl -L https://github.com/hasura/graphql-engine/raw/stable/cli/get.sh | bash

#### Apply Hasura and reload migrations and reload metadata
hasura/apply-all:
	@cd $(DIR)/hasura && hasura --database-name default --skip-update-check migrate apply && hasura --skip-update-check metadata apply && hasura --skip-update-check metadata reload

#### Apply and reload only Hasura metadata
hasura/apply-metadata:
	@cd $(DIR)/hasura && hasura --skip-update-check metadata apply && hasura --skip-update-check metadata reload