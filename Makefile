PREFIX?=$(shell pwd)

NAME := terraform-ami-bakery
PYTHON := python3

AWS_ACCESS_KEY_ID := ${AWS_ACCESS_KEY_ID}
AWS_REGION := ${AWS_REGION}
AWS_SECRET_ACCESS_KEY := ${AWS_SECRET_ACCESS_KEY}

BUILD_BUCKET := ${BUILD_BUCKET}
STATE_BUCKET := ${STATE_BUCKET}
SUBNET_ID := ${SUBNET_ID}
VPC_ID := ${VPC_ID}

GITHUB_TOKEN := ${GITHUB_TOKEN}
MATTERMOST_WEBHOOK_URL := ${MATTERMOST_WEBHOOK_URL}
MATTERMOST_CHANNEL := ${MATTERMOST_CHANNEL}
MATTERMOST_USERNAME := ${MATTERMOST_USERNAME}
KMS_KEY_ARN := ${KMS_KEY_ARN}

REPO_OWNER := $(shell git config --get user.name 2>/dev/null)
REPO := unops
BRANCH := master

# REPO := $(shell git rev-parse --show-toplevel 2>/dev/null | xargs basename 2>/dev/null)
# BRANCH := $(shell git name-rev --name-only --no-undefined --always HEAD 2>/dev/null)

TERRAFORM_FLAGS = -var "access_key=$(AWS_ACCESS_KEY_ID)" \
					-var "region=$(AWS_REGION)" \
				  -var "secret_key=$(AWS_SECRET_ACCESS_KEY)" \
					-var "bucket_name=$(BUILD_BUCKET)" \
					-var "github_token=$(GITHUB_TOKEN)" \
					-var "kms_key_arn=$(KMS_KEY_ARN)" \
					-var "lambda_name=$(REPO)_notify" \
					-var "mattermost_channel=$(MATTERMOST_CHANNEL)" \
					-var "mattermost_username=$(MATTERMOST_USERNAME)" \
					-var "mattermost_webhook_url=$(MATTERMOST_WEBHOOK_URL)" \
					-var "name=$(NAME)" \
					-var "repo=$(REPO)" \
					-var "repo_owner=$(REPO_OWNER)" \
					-var "service_name=$(REPO)" \
				  -var "subnet_id="$(SUBNET_ID) \
				  -var "vpc_cidr_prefix=$(VPC_CIDR)"


check_defined = \
		$(strip $(foreach 1,$1, \
		$(call __check_defined,$1,$(strip $(value 2)))))
__check_defined = \
		$(if $(value $1),, \
		$(error Undefined $1$(if $2, ($2))$(if $(value @), \
		required by target `$@')))

all: plan apply ## Runs terraform plan and apply

.PHONY: init
init:
		@:$(call check_defined, AWS_ACCESS_KEY_ID, Amazon Access Key ID)
		@:$(call check_defined, AWS_REGION, Amazon Region)
		@:$(call check_defined, AWS_SECRET_ACCESS_KEY, Amazon Secret Access Key)
		@:$(call check_defined, GITHUB_TOKEN, Github OAuth Personal Access token)
		@:$(call check_defined, KMS_KEY_ARN, The KMS Key ARN to use for variable encryption)
		@:$(call check_defined, MATTERMOST_CHANNEL, The Mattermost channel in which to post message)
		@:$(call check_defined, MATTERMOST_USERNAME, The Mattermost username for the bot to use)
		@:$(call check_defined, MATTERMOST_WEBHOOK_URL, The Mattermost Webhook endpoint to encrypt)
		@:$(call check_defined, NAME, Name of the build environment)
		@:$(call check_defined, REPO, The Github repo containing the Packer templates used to build the AMI)
		@:$(call check_defined, REPO_OWNER, The Github organization or user who owns the repository)
		@:$(call check_defined, STATE_BUCKET, S3 bucket name in which to store the Terraform state)
		@:$(call check_defined, SUBNET_ID, Subnet in which to build the AMI)
		@:$(call check_defined, VPC_CIDR, The IP prefix to the CIDR block assigned to the VPC)
		@terraform init \
				-backend-config "bucket=$(STATE_BUCKET)" \
				-backend-config "region=$(AWS_REGION)" \
				$(TERRAFORM_FLAGS)

.PHONY: plan
plan: init ## Run terraform plan
		@terraform plan \
				$(TERRAFORM_FLAGS)

.PHONY: apply
apply: init ## Run terraform apply
		@terraform apply \
				$(TERRAFORM_FLAGS) \
				-auto-approve

.PHONY: refresh
refresh: init ## Refresh terraform state
		@terraform refresh \
				$(TERRAFORM_FLAGS)

.PHONY: destroy
destroy: init ## Run terraform destroy
		@terraform destroy \
				$(TERRAFORM_FLAGS)

.PHONY: run
run: ## Runs the lambda function locally
	@echo "+ $@"
	@$(PYTHON) $(CURDIR)/modules/lambda/function/notify.py

.PHONY: help
help:
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'
