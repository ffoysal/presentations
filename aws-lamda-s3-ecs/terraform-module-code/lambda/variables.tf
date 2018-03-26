variable "environment_name" {
  description = "The environment name"
}

variable "meetup_task_definition_arn" {
  description = "The ECS task definition ARN"
}

variable "ecs_cluster_name" {
  description = "The ECS cluster name"
}

variable "meetup_sqs_queue_id" {
  description = "The SQS id"
}

variable "meetup_bucket_arn" {
  description = "The bucket ARN"
}