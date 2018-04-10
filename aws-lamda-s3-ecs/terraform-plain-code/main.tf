provider "aws" {
  #access_key = "${var.aws_access_key}"
  #secret_key = "${var.aws_secret_key}"
  region     = "${var.aws_region}"
}

# Create ECS cluster and Task

# Data for container definitions
data "template_file" "container_definitions" {
  template = "${file("container_definition.json")}"
  vars {
    region = "${var.aws_region}"
    sqs_url = "${aws_sqs_queue.meetup_q.id}"
    ddb_table = "${aws_dynamodb_table.meetup_table.id}"
    container_image_url = "${var.container_image_url}"
    log_group_name = "tf-meetup-${var.environment_name}"
  }
}

# Data for CloudWatch logs
data "template_file" "cloud_watch_log_config" {
  template = "${file("awslogs.userdata")}"
  vars {
    ecs_cluster_name = "${aws_ecs_cluster.meetup_cluster.name}"
    log_group_name = "tf-meetup-${var.environment_name}"
  }
}

# Define an ECS task definition
resource "aws_ecs_task_definition" "meetup_task_definition" {
  family = "tf-meetup-${var.environment_name}"
  container_definitions = "${data.template_file.container_definitions.rendered}"

}
# Define an ECS cluster
resource "aws_ecs_cluster" "meetup_cluster" {
  name = "tf-meetup${var.environment_name}-cluster"
}

# Define a container instance
resource "aws_instance" "ecs_instance" {
  ami = "${lookup(var.aws_ecs_amis, var.aws_region)}"
  instance_type = "${var.ec2_instance_type}"
  iam_instance_profile = "${aws_iam_instance_profile.instance_profile.name}"
  user_data = "${data.template_file.cloud_watch_log_config.rendered}"
  # Need public ip address so that can pull docker image from anywhere
  associate_public_ip_address = true

  tags {
    Name = "tf-meetup-${var.environment_name}"
  }
}

# ECS instance role
resource "aws_iam_role" "ecs_instance_role" {
  name = "tf-meetup-${var.environment_name}-instance-role"
  assume_role_policy = "${file("ecs_instance_role.json")}"
}

# ECS instance role policy
resource "aws_iam_role_policy" "ecs_instance_role_policy" {
  name   = "tf-meetup-${var.environment_name}-instance-role-policy"
  role   = "${aws_iam_role.ecs_instance_role.name}"
  policy = "${file("ecs_instance_role_policy.json")}"
}

# ECS instance profile
resource "aws_iam_instance_profile" "instance_profile" {
  name  = "tf-meetup-${var.environment_name}-instance-profile"
  path = "/"
  role = "${aws_iam_role.ecs_instance_role.name}"
}

# Create lambda function and related resources

# The Lambda function to trigger the ecs task
resource "aws_lambda_function" "meetup_lambda" {
  filename = "./taskLauncher.zip"
  function_name = "tf-meetup-${var.environment_name}"
  role = "${aws_iam_role.lambda_role.arn}"
  handler = "taskLauncher.handler"
  source_code_hash = "${data.archive_file.lambda_zip.output_base64sha256}"
  runtime = "nodejs4.3"
  environment {
    variables = {
      TD = "${aws_ecs_task_definition.meetup_task_definition.arn}"
      CLUSTER = "${aws_ecs_cluster.meetup_cluster.name}"
      QU= "${aws_sqs_queue.meetup_q.id}"
    }
  }
}

# Data for archiving lambda script
data "archive_file" "lambda_zip" {
  type = "zip"
  source_file="taskLauncher.js"
  output_path = "./taskLauncher.zip"
}

# Lambda role
resource "aws_iam_role" "lambda_role" {
  name = "tf-meetup-${var.environment_name}-lambda-role"
  assume_role_policy = "${file("./lambda_role.json")}"
}

# Lambda role policy
resource "aws_iam_role_policy" "lambda_role_policy" {
  name = "tf-meetup-${var.environment_name}-lambda-role-policy"
  role = "${aws_iam_role.lambda_role.name}"
  policy = "${file("${path.module}/lambda_role_policy.json")}"
}

resource "aws_lambda_permission" "allow_bucket" {
  statement_id  = "AllowExecutionFromS3Bucket"
  action        = "lambda:InvokeFunction"
  function_name = "${aws_lambda_function.meetup_lambda.function_name}"
  principal     = "s3.amazonaws.com"
  source_arn    = "${aws_s3_bucket.meetup_bucket.arn}"
}



# Create SQS
resource "aws_sqs_queue" "meetup_q" {
  name = "tf-meetup-${var.environment_name}"
  visibility_timeout_seconds = "10"
}


# Create a s3 bucket 
resource "aws_s3_bucket" "meetup_bucket" {
  bucket = "tf-meetup-${var.environment_name}"
  acl = "private"
  region = "${var.aws_region}"
  force_destroy = true
}


# Notification of the S3 bucket
resource "aws_s3_bucket_notification" "meetup_demo_bucket_notification" {
  bucket = "${aws_s3_bucket.meetup_bucket.id}"
  lambda_function {
    lambda_function_arn = "${aws_lambda_function.meetup_lambda.arn}"
    events = ["s3:ObjectCreated:*"]
    filter_suffix = ".txt"
  }
}


# DynamoDB
resource "aws_dynamodb_table" "meetup_table" {
  name           = "tf-meetup-${var.environment_name}"
  hash_key       = "id"
  read_capacity  = 10
  write_capacity = 5

  attribute {
    name = "id"
    type = "S"
  }
}

# Terraform backend setup
/*
terraform {
backend "s3" {
    bucket = "foysal-state"
    key    = "path/to/my/key"
    region = "us-east-1"
  }
}
*/

