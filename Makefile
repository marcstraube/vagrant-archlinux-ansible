# Makefile for Arch Linux Ansible Box Builder (Packer)
#
# Usage: make [TARGET]
#
# This is a convenience wrapper around Packer commands.
# HCP credentials are retrieved from KeePassXC via Secret Service.

SHELL := /bin/bash
.SHELLFLAGS := -eu -o pipefail -c
.DEFAULT_GOAL := help

# KeePassXC entry title for HCP credentials
KEEPASS_ENTRY := HCP Packer Deploy

# Retrieve HCP credentials from KeePassXC via Secret Service
HCP_CLIENT_ID = $(shell secret-tool search Title "$(KEEPASS_ENTRY)" 2>&1 | grep "attribute.UserName" | cut -d' ' -f3-)
HCP_CLIENT_SECRET = $(shell secret-tool lookup Title "$(KEEPASS_ENTRY)")

.PHONY: help init validate build build-only release clean

help: ## Show this help message
	@echo "Arch Linux Ansible Box Builder (Packer)"
	@echo ""
	@echo "Usage: make [TARGET]"
	@echo ""
	@echo "Targets:"
	@awk 'BEGIN {FS = ":.*##"} /^[a-zA-Z_-]+:.*##/ {printf "  %-15s%s\n", $$1, $$2}' $(MAKEFILE_LIST)

init: ## Install required Packer plugins
	@packer init .

validate: ## Validate the Packer template
	@packer validate -except=vagrant-registry .

build: ## Build and deploy to HCP Registry (without release)
	@HCP_CLIENT_ID="$(HCP_CLIENT_ID)" HCP_CLIENT_SECRET="$(HCP_CLIENT_SECRET)" packer build .

build-only: ## Build locally without deploying to HCP
	@packer build -except=vagrant-registry .

release: ## Build, deploy, and release on HCP Registry
	@HCP_CLIENT_ID="$(HCP_CLIENT_ID)" HCP_CLIENT_SECRET="$(HCP_CLIENT_SECRET)" packer build -var="no_release=false" .

clean: ## Remove build artifacts
	@rm -rf output-*/
	@rm -f *.box
