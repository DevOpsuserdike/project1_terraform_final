resource "aws_iam_role" "lambda1_exec" {
  name = "lambda1_role_terraform"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "lambda.amazonaws.com"
      }
    }]
  })
}

variable "managed_policies" {
  description = "List of IAM policy ARNs to attach to the role"
  type        = list(string)
  default = [
    "arn:aws:iam::aws:policy/service-role/AmazonEC2RoleforSSM",
    "arn:aws:iam::aws:policy/AmazonSQSFullAccess",
    "arn:aws:iam::aws:policy/AmazonSQSReadOnlyAccess",
    "arn:aws:iam::aws:policy/service-role/AmazonSSMAutomationRole",
    "arn:aws:iam::aws:policy/AmazonSSMFullAccess",
    "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore",
    "arn:aws:iam::aws:policy/service-role/AWSLambdaSQSQueueExecutionRole"
  ]
}

resource "aws_iam_role_policy_attachment" "attachments1" {
  for_each   = toset(var.managed_policies)
  role       = aws_iam_role.lambda1_exec.name
  policy_arn = each.value
}


# Attach basic execution policy for CloudWatch Logs
resource "aws_iam_role_policy_attachment" "lambda1_logs" {
  role       = aws_iam_role.lambda1_exec.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_iam_role_policy" "custom_json_policy1" {
  name = "custom-lambda-ssm-sqs-policy"
  role       = aws_iam_role.lambda1_exec.name

  policy = jsonencode({
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": "logs:CreateLogGroup",
            "Resource": "arn:aws:logs:us-west-2:*:*"
        },
        {
            "Effect": "Allow",
            "Action": [
                "logs:CreateLogStream",
                "logs:PutLogEvents"
            ],
            "Resource": [
                "arn:aws:logs:us-west-2:*:log-group:/aws/lambda/lambda1:*"
            ]
        },
        {
            "Effect": "Allow",
            "Action": [
                "ssm:SendCommand",
                "ssm:GetCommandInvocation"
            ],
            "Resource": [
                "arn:aws:ec2:*:*:instance/*",
                "arn:aws:ssm:*:*:document/*",
                "arn:aws:ssm:*:*:command/*"
            ]
        },
        {
            "Effect": "Allow",
            "Action": "sqs:*",
            "Resource": "arn:aws:sqs:us-west-2:*:sqs"
        },
        {
            "Effect": "Allow",
            "Action": "s3:GetObject",
            "Resource": "arn:aws:s3:::s3-test-2026/data.json"
        }
    ]
  })
}


data "archive_file" "lambda1_zip" {
  type        = "zip"
  source_file = "${path.module}/lambda1_function.py"
  output_path = "${path.module}/lambda1_function_payload.zip"
}

resource "aws_lambda_function" "my_lambda1" {
  filename      = data.archive_file.lambda1_zip.output_path
  function_name = "lambda1_function"
  role          = aws_iam_role.lambda1_exec.arn
  handler       = "lambda1_function.lambda_handler"
  runtime       = "python3.12"

  # This triggers a redeploy if the code's hash changes
  source_code_hash = data.archive_file.lambda1_zip.output_base64sha256
}

