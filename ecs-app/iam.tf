# Service Role
data "aws_iam_policy_document" "ecs_service_policy" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ecs.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "ecs_service_role" {
  name               = "ecs-service-role"
  path               = "/"
  assume_role_policy = data.aws_iam_policy_document.ecs_service_policy.json
}

resource "aws_iam_role_policy_attachment" "ecs_service_role_attachment" {
  role       = aws_iam_role.ecs_service_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEC2ContainerServiceRole"
}

#Task Role allows containers to call AWS services
data "aws_iam_policy_document" "task" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "task" {
  name               = "ecs-task"
  path               = "/"
  assume_role_policy = data.aws_iam_policy_document.task.json
}

#Tasks can read S3
resource "aws_iam_role_policy_attachment" "task_s3" {
  role       = aws_iam_role.task.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonS3ReadOnlyAccess"
}

#Execution Role allows agents to call AWS services
data "aws_iam_policy_document" "execution" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "execution" {
  name               = "ecs-execution"
  path               = "/"
  assume_role_policy = data.aws_iam_policy_document.execution.json
}

#allow agents to pull from ECR and create logs
resource "aws_iam_role_policy_attachment" "task_execution" {
  role       = aws_iam_role.execution.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}
