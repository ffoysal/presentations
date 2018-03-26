# The Lambda function to trigger the ecs task
resource "aws_lambda_function" "meetup_lambda" {
  filename = "./taskLanuncher.zip"
  function_name = "tf-meetup-${var.environment}"
  role = "${aws_iam_role.lambda_role.arn}"
  handler = "taskLauncher.handler"
  source_code_hash = "${data.archive_file.lambda_zip.output_base64sha256}"
  runtime = "nodejs4.3"
}

# Data for archiving lambda script
data "archive_file" "lambda_zip" {
  type = "zip"
  source {
    content  = "${data.template_file.lambda_script.rendered}"
    filename = "taskLauncher.js"
  }
  output_path = "./taskLauncher.zip"
}


# Data for lambda script
data "template_file" "lambda_script" {
  template = "${file("${path.module}/taskLauncher.js")}"

  vars {
    meetup_task_definition = "${var.meetup_task_definition_arn}"
    meetup_cluster = "${var.meetup_cluster_name}"
    event_queue = "${var.meetup_event_queue_id}"
  }
}


# Lambda role
resource "aws_iam_role" "lambda_role" {
  name = "tf-meetup-${var.environment_name}-lambda-role"
  assume_role_policy = "${file("${path.module}/lambda_role.json")}"
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
  source_arn    = "${var.meetup_bucket_arn}"
}