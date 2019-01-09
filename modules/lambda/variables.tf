variable "mattermost_webhook_url" {
  type        = "string"
  description = "the webhook endpoint to encrypt"
}

variable "mattermost_channel" {
  type        = "string"
  description = "the channel in which to post message"
}

variable "mattermost_username" {
  type        = "string"
  description = "the user to post as"
}

variable "mattermost_iconurl" {
  type        = "string"
  description = "the url for the bot user's profile picture"
  default     = "https://raw.githubusercontent.com/artur-sak13/unops/master/static/DeveloperTools_AWSCodePipeline_LARGE.png"
}

variable "lambda_name" {
  type        = "string"
  description = "the name of the lambda function"
}

variable "region" {
  type        = "string"
  description = "the AWS region in which the KMS key resides"
}

variable "kms_key_arn" {
  type        = "string"
  description = "the kms key arn to use for variable encryption"
}
