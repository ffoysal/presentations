# Define an ECS task definition
resource "aws_ecs_task_definition" "meetup_task_definition" {
  family = "tf-meetup-${var.environment_name}-task-definition"
  container_definitions = "${data.template_file.container_definitions.rendered}"
}

# Define an ECS cluster
resource "aws_ecs_cluster" "meetup_cluster" {
  name = "tf-meetup-${var.environment_name}-cluster"
}