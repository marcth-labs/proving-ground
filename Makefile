# The front door. Every gate CI runs is a target here, and every target here is
# runnable by a human on a clean clone.
#
# This exists for a structural reason rather than for ergonomics. The work spans
# three execution contexts -- the application's Composer root inside the app
# container, the acceptance suite's own Composer root, and the host shell for
# bin/check-provenance, which must run with no container up and no PHP
# installed. No single `composer <verb>` spans all three, so something has to,
# and a Makefile is the smallest thing that does.
#
# CI invokes these targets and implements nothing itself: any workflow `run:`
# block longer than a single command is a defect. That rule is what keeps the
# gate reproducible on a laptop.

SHELL := /bin/sh
COMPOSE := docker compose
EXEC := $(COMPOSE) exec -T -e PAO_DISABLE=1 app

.DEFAULT_GOAL := help
.PHONY: help setup up down restart build logs shell test format provenance protection clean

help: ## Show this help
	@grep -hE '^[a-z-]+:.*?## ' $(MAKEFILE_LIST) \
		| awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[36m%-12s\033[0m %s\n", $$1, $$2}'

setup: ## Wire up the git hooks (everything else happens in `make up`)
	git config core.hooksPath .githooks
	git config gpg.ssh.allowedSignersFile .github/allowed_signers
	@echo "hooks and offline signature verification configured"

up: ## Bring the stack up and wait for it to be ready
	$(COMPOSE) up -d --wait

down: ## Stop the stack, keeping volumes
	$(COMPOSE) down

restart: down up ## Stop and start the stack

build: ## Build the ci and prod images
	$(COMPOSE) build
	docker build --target ci   -t proving-ground:ci   .
	docker build --target prod -t proving-ground:prod .

logs: ## Follow the application log
	$(COMPOSE) logs -f app

shell: ## Open a shell in the app container
	$(COMPOSE) exec app sh

test: ## Run the test suite
	$(EXEC) php artisan test

format: ## Apply the code style
	$(EXEC) vendor/bin/pint

provenance: ## Verify the provenance of every commit from the root
	./bin/check-provenance --all

protection: ## Apply the committed branch and tag protection (needs an admin token)
	./bin/apply-protection

clean: ## Stop the stack and delete its volumes
	$(COMPOSE) down -v
