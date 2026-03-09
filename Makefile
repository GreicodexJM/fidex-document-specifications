# FideX Document Specifications — Makefile
# Usage: make <target>

# Glob pattern passed to ajv -r. Must remain a quoted glob string (not an expanded
# Make variable) so that ajv-cli receives a single glob argument, not a
# space-joined file list that it cannot parse as individual paths.
SCHEMAS_COMMON_GLOB := schemas/_common/*.schema.json

SCHEMA_CUSTOMER   := schemas/customer-master/gs1-customer-master.schema.json
SCHEMA_CATALOG    := schemas/catalog/gs1-catalog.schema.json
SCHEMA_ORDER      := schemas/order/gs1-order.schema.json
SCHEMA_DESPATCH   := schemas/despatch-advice/gs1-despatch-advice.schema.json
SCHEMA_INVOICE    := schemas/invoice/gs1-invoice.schema.json
SCHEMA_RETENTION  := schemas/retention/gs1-retention.schema.json

AJV := node_modules/.bin/ajv
PRETTIER := node_modules/.bin/prettier

.DEFAULT_GOAL := help

##@ General

help: ## Display this help message
	@awk 'BEGIN {FS = ":.*##"; printf "\nUsage:\n  make \033[36m<target>\033[0m\n"} /^[a-zA-Z_0-9-]+:.*?##/ { printf "  \033[36m%-20s\033[0m %s\n", $$1, $$2 } /^##@/ { printf "\n\033[1m%s\033[0m\n", substr($$0, 5) } ' $(MAKEFILE_LIST)

##@ Setup

install: ## Install npm dependencies (ajv-cli, prettier)
	npm install

##@ Validation

validate: validate-customer validate-catalog validate-order validate-despatch validate-invoice validate-retention ## Validate ALL examples against their schemas
	@echo ""
	@echo "✅  All examples validated successfully."

# Common ajv flags used by all validate targets:
#   --spec draft2020     JSON Schema 2020-12 (supported by ajv-cli v5 / ajv v8.x)
#   --strict=false       allow properties without explicit type in allOf sub-schemas
#   -c ajv-formats       load ajv-formats plugin — enables date-time, email, uri format validation
AJV_FLAGS := --spec draft2020 --strict=false --errors=text -c ajv-formats

validate-customer: ## Validate customer master examples
	@echo "→ Validating customer master..."
	@$(AJV) validate -s $(SCHEMA_CUSTOMER) -d "examples/customer-master/*.json" \
		-r "$(SCHEMAS_COMMON_GLOB)" $(AJV_FLAGS)

validate-catalog: ## Validate catalog examples
	@echo "→ Validating catalog..."
	@$(AJV) validate -s $(SCHEMA_CATALOG) -d "examples/catalog/*.json" \
		-r "$(SCHEMAS_COMMON_GLOB)" $(AJV_FLAGS)

validate-order: ## Validate order examples
	@echo "→ Validating orders..."
	@$(AJV) validate -s $(SCHEMA_ORDER) -d "examples/order/*.json" \
		-r "$(SCHEMAS_COMMON_GLOB)" $(AJV_FLAGS)

validate-despatch: ## Validate despatch advice examples
	@echo "→ Validating despatch advice..."
	@$(AJV) validate -s $(SCHEMA_DESPATCH) -d "examples/despatch-advice/*.json" \
		-r "$(SCHEMAS_COMMON_GLOB)" $(AJV_FLAGS)

validate-invoice: ## Validate invoice examples
	@echo "→ Validating invoices..."
	@$(AJV) validate -s $(SCHEMA_INVOICE) -d "examples/invoice/*.json" \
		-r "$(SCHEMAS_COMMON_GLOB)" $(AJV_FLAGS)

validate-retention: ## Validate retention examples (IVA and ISLR)
	@echo "→ Validating retention documents..."
	@$(AJV) validate -s $(SCHEMA_RETENTION) -d "examples/retention/*.json" \
		-r "$(SCHEMAS_COMMON_GLOB)" $(AJV_FLAGS)

validate-one: ## Validate a single file. Usage: make validate-one FILE=examples/order/01-purchase-order.json
ifndef FILE
	$(error FILE is required. Usage: make validate-one FILE=examples/order/01-purchase-order.json)
endif
	@echo "→ Detecting schema for $(FILE)..."
	$(eval _FILE_NORM := $(patsubst ./%,%,$(FILE)))
	$(eval DOMAIN := $(word 2, $(subst /, ,$(_FILE_NORM))))
	@echo "→ Validating $(_FILE_NORM) against schemas/$(DOMAIN)/gs1-$(DOMAIN).schema.json..."
	@$(AJV) validate -s schemas/$(DOMAIN)/gs1-$(DOMAIN).schema.json -d $(_FILE_NORM) \
		-r "$(SCHEMAS_COMMON_GLOB)" $(AJV_FLAGS)

##@ Code Quality

lint: ## Check JSON formatting with prettier
	@$(PRETTIER) --check "schemas/**/*.json" "examples/**/*.json"
	@echo "✅  All JSON files are properly formatted."

format: ## Auto-format all JSON files with prettier
	@$(PRETTIER) --write "schemas/**/*.json" "examples/**/*.json"
	@echo "✅  All JSON files formatted."

##@ Utilities

list-schemas: ## List all schema files
	@find schemas/ -name "*.schema.json" | sort

list-examples: ## List all example files
	@find examples/ -name "*.json" | sort

check-deps: ## Check that required tools are installed
	@node --version
	@npm --version
	@$(AJV) --version || echo "❌ ajv-cli not found. Run: make install"
	@$(PRETTIER) --version || echo "❌ prettier not found. Run: make install"

.PHONY: help install validate validate-customer validate-catalog validate-order validate-despatch validate-invoice validate-retention validate-one lint format list-schemas list-examples check-deps
