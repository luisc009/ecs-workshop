#Security Group that is going to be attached to the EC2
resource "aws_security_group" "allow" {
  name = "allow"

  ingress {
    description     = "Allow 80"
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = [aws_security_group.alb.id]
  }
  egress {
    description = "All output"
    from_port   = 0
    to_port     = 0
    protocol    = -1
    cidr_blocks = ["0.0.0.0/0"]
  }
}

#Security Group that is going to be attached to the Load Balancer.
resource "aws_security_group" "alb" {
  name = "alb"
  ingress {
    description = "Allow 80"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    description = "Allow 433"
    from_port   = 433
    to_port     = 433
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    description = "All output"
    from_port   = 0
    to_port     = 0
    protocol    = -1
    cidr_blocks = ["0.0.0.0/0"]
  }
}

#Launch template over launch configuration, as it is recommended by AWS so you can use
#all of the EC2 features.
resource "aws_launch_template" "cluster" {
  name_prefix   = var.cluster_name
  instance_type = "t2.micro"
  image_id      = data.aws_ami.ecs_ami.id

  iam_instance_profile {
    name = aws_iam_instance_profile.cluster.name
  }

  user_data              = data.template_cloudinit_config.config.rendered
  key_name               = "test2"
  vpc_security_group_ids = [aws_security_group.allow.id]
}

#Autoscaling group, the EC2s that are attached to the Cluster
resource "aws_autoscaling_group" "cluster" {
  launch_template {
    name = aws_launch_template.cluster.name
  }
  name_prefix        = var.cluster_name
  min_size           = 1
  max_size           = 2
  availability_zones = ["us-east-1a", "us-east-1b"]
}

#The application load balancer
resource "aws_lb" "lb_ecs" {
  name                       = "${var.cluster_name}-lb"
  load_balancer_type         = "application"
  security_groups            = [aws_security_group.alb.id]
  subnets                    = data.aws_subnet_ids.public_subnets.ids
  enable_deletion_protection = false
}

#The ECS Cluster
resource "aws_ecs_cluster" "cluster" {
  name = var.cluster_name
}


