variable "environment_name" {
  description = "The environment name, i.e. production, staging, foysal"
}

variable "aws_region" {
  description = "EC2 Region for the VPC"
}

variable "lambda_function_arn" {
  description = "The ECS task initiator lambda ARN"
}