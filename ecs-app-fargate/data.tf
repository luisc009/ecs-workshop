data "aws_caller_identity" "current" {}
data "aws_region" "current" {}
data "aws_vpc" "default" {}

data "aws_security_group" "allow_22" {
  name = "allow"
}
data "aws_ecs_cluster" "ecs" {
  cluster_name = var.cluster_name
}

data "aws_lb" "ecs" {
  name = "${var.cluster_name}-lb"
}

data "aws_subnet_ids" "subnets" {
  vpc_id = data.aws_vpc.default.id
}