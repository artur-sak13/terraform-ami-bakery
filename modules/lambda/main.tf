resource "aws_cloudwatch_event_rule" "custom_event" {
  name        = "UnopsEvent"
  description = "Notify on AMI build completion"

  event_pattern = <<PATTERN
  {
    "source"     : [
      "com.unops.build"
    ],
    "detail-type": [
      "Unops Build"
    ],
    "detail"     : {
      "AmiStatus": [
        "Created"
      ]
    }
  }
  PATTERN
}

resource "aws_cloudwatch_event_target" "lambda" {
  rule      = "${aws_cloudwatch_event_rule.custom_event.name}"
  target_id = "${aws_cloudwatch_event_rule.custom_event.name}"
  arn       = "${data.aws_lambda_function.notify_mattermost.arn}"
}

resource "aws_kms_key" "matter_key" {
  description = "mattermost webhook url encryption key"
  is_enabled  = true
}

resource "aws_kms_alias" "matter_key_alias" {
  name          = "alias/mattermost-lambda"
  target_key_id = "${aws_kms_key.matter_key.key_id}"
}

data "aws_kms_ciphertext" "kms_cipher" {
  key_id    = "${aws_kms_alias.matter_key_alias.target_key_id}"
  plaintext = "${var.mattermost_webhook_url}"
}

data "null_data_source" "lambda_file" {
  inputs {
    filename = "${substr("${path.module}/function/${var.lambda_name}/lambda_function.py", length(path.cwd) + 1, -1)}"
  }
}

data "null_data_source" "lambda_archive" {
  inputs {
    filename = "${substr("${path.module}/function/${var.lambda_name}/lambda_function.zip", length(path.cwd) + 1, -1)}"
  }
}

data "archive_file" "notify_mattermost" {
  type        = "zip"
  source_file = "${data.null_data_source.lambda_file.outputs.filename}"
  output_path = "${data.null_data_source.lambda_archive.outputs.filename}"
}

data "aws_iam_policy_document" "lambda_assume_role" {
  statement {
    effect = "Allow"

    actions = [
      "sts:AssumeRole",
    ]

    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "lambda_role" {
  name               = "LambdaMattermostExecute"
  assume_role_policy = "${data.aws_iam_policy_document.lambda_assume_role.json}"
}

resource "aws_iam_role_policy_attachment" "lambda_mattermost" {
  role       = "${aws_iam_role.lambda_role.name}"
  policy_arn = "${aws_iam_policy.lambda_mattermost_policy.arn}"
}

resource "aws_iam_policy" "lambda_mattermost_policy" {
  name   = "LambdaMattermostPolicy"
  policy = "${data.aws_iam_policy_document.lambda_mattermost_document.json}"
}

data "aws_iam_policy_document" "lambda_mattermost_document" {
  statement {
    effect = "Allow"

    actions = [
      "kms:Encrypt",
      "kms:Decrypt",
    ]

    resources = [
      "${aws_kms_key.matter_key.arn}",
    ]
  }

  statement {
    effect = "Allow"

    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents",
    ]

    resources = [
      "arn:aws:logs:*:*:*",
    ]
  }
}

data "aws_lambda_function" "notify_mattermost" {
  function_name = "${var.lambda_name}"
}

# resource "aws_lambda_function" "notify_mattermost" {
# filename         = "${data.archive_file.notify_mattermost.output_path}"
# source_code_hash = "${data.archive_file.notify_mattermost.output_base64sha256}"
# function_name    = "${var.lambda_name}"
# role             = "${aws_iam_role.lambda_role.arn}"
# handler          = "lambda_function.lambda_handler"
# runtime          = "python3.6"
# kms_key_arn      = "${var.kms_key_arn}"


#   environment {
#     variables {
# MATTERMOST_WEBHOOK_URL = "${data.aws_kms_ciphertext.kms_cipher.ciphertext_blob}"
# MATTERMOST_CHANNEL     = "${var.mattermost_channel}"
# MATTERMOST_USERNAME    = "${var.mattermost_username}"
# MATTERMOST_ICONURL     = "${var.mattermost_iconurl}"
#     }
#   }
# }


# resource "aws_lambda_permission" "allow_cloudwatch" {
# statement_id  = "AllowExecutionFromCloudWatch"
# action        = "lambda:InvokeFunction"
# function_name = "${aws_lambda_function.notify_mattermost.function_name}"
# principal     = "events.amazonaws.com"
# source_arn    = "${aws_cloudwatch_event_rule.custom_event.arn}"
# }

