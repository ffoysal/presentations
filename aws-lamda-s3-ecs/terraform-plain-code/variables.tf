# The AWS account access key
# variable "aws_access_key" {}

# The AWS account secret key
# variable "aws_secret_key" {}

# The AWS region
variable "aws_region" {}

# Lab environment name
variable "environment_name" {}

variable "container_image_url" {
  default = "665670730843.dkr.ecr.us-east-1.amazonaws.com/lazy:2.2.2"
}

variable "aws_ecs_amis" {
  description ="ECS optimized AMIs for different regions"
  type = "map"
  default = {
    us-east-1 = "ami-ba722dc0"
    us-east-2 = "ami-13af8476"
    us-west-1 = "ami-9df0f0fd"
    us-west-2 = "ami-c9c87cb1"
    eu-west-1 = "ami-acb020d5"
    eu-west-2 = "ami-4d809829"
    eu-central-1 = "ami-eacf5d85"
    ap-northeast-1 = "ami-72f36a14"
    ap-southeast-1 = "ami-e782f29b"
    ap-southeast-2 = "ami-7aa15c18"
    ca-central-1 = "ami-9afc79fe"
  }
}