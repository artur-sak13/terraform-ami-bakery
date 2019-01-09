provider "aws" {
  access_key = "${var.access_key}"
  secret_key = "${var.secret_key}"

  region  = "${var.region}"
  version = "~> 1.54.0"
}

provider "archive" {
  version = "~> 1.1"
}

provider "null" {
  version = "~> 1.0"
}

module "vpc" {
  source          = "./modules/vpc"
  name            = "${var.repo}"
  region          = "${var.region}"
  vpc_cidr_prefix = "${var.vpc_cidr_prefix}"
}

module "pipeline" {
  source       = "./modules/pipeline"
  bucket_name  = "${var.bucket_name}"
  service_name = "${var.service_name}"
  region       = "${var.region}"
  image        = "${var.image}"
  vpc_id       = "${module.vpc.vpc_id}"
  subnet_id    = "${module.vpc.subnet_id}"
  repo_owner   = "${var.repo_owner}"
  repo         = "${var.repo}"
  branch       = "${var.branch}"
  github_token = "${var.github_token}"
}

module "lambda" {
  source                 = "./modules/lambda"
  region                 = "${var.region}"
  lambda_name            = "${var.lambda_name}"
  mattermost_webhook_url = "${var.mattermost_webhook_url}"
  mattermost_channel     = "${var.mattermost_channel}"
  mattermost_username    = "${var.mattermost_username}"
  mattermost_iconurl     = "${var.mattermost_iconurl}"
  kms_key_arn            = "${var.kms_key_arn}"
}

terraform {
  required_version = ">= 0.11.11"

  backend "s3" {
    bucket  = "twopoint-tf-state"
    encrypt = true
    key     = "unops/terraform.tfstate"
  }
}
