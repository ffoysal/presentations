provider "aws" {
  #access_key = "${var.aws_access_key}"
  #secret_key = "${var.aws_secret_key}"
  region     = "${var.aws_region}"
}


module "meetup_s3" {
  source = "./s3"
  environment_name = "${var.environment_name}"
  aws_region = "${var.aws_region}"
  lambda_function_arn = "${module.meetup_lambda.lambda_arn}"
}

module "meetup_lambda" {
  source = "./lambda"
  environment_name = "${var.environment_name}"
  ecs_task_definition_arn = "${module.meetup_ecs.ecs_task_definition_arn}"
  meetup_cluster_name = "${module.meetup_ecs.ecs_cluster_name}"
  sqs_id = "${aws_sqs_queue.gracenote_epg_event_queue.id}"
  gracenote_epg_bucket_arn = "${module.mage_s3.gracenote_epg_bucket_arn}"
}

module "meetup_ecs" {
  source = "./ecs"
  environment_name = "${var.environment_name}"
  aws_ecs_amis = "${var.aws_ecs_amis}"
  aws_region = "${var.aws_region}"
  instance_type = "${var.instance_type}"
  sqs_id = "${aws_sqs_queue.meetup_queue.id}"
  container_name = "${var.container_name}"
  container_image = "${var.container_image}"
  mpm_key_pair = "${var.mpm_key_pair}"
}

# Queue used to store S3 bucket upload events
resource "aws_sqs_queue" "meetup_queue" {
  name = "tf-meetup-${var.environment_name}"
}