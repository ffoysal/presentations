# Define a s3 bucket to upload files
resource "aws_s3_bucket" "meetup_demo_bucket" {
  bucket = "tf-meetup-${var.environment_name}"
  acl = "private"
  region = "${var.aws_region}"
  force_destroy = true
  tags {
    Name = "tf-meetup-${var.environment_name}"
  }
}

# Notification of the S3 bucket
resource "aws_s3_bucket_notification" "meetup_demo_bucket_notification" {
  bucket = "${aws_s3_bucket.meetup_demo_bucket.id}"

  lambda_function {
    lambda_function_arn = "${var.lambda_function_arn}"
    events = ["s3:ObjectCreated:*"]
    filter_suffix = ".txt"
  }
}