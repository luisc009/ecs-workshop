#Creates the role for that is going to be assigned to the instances in the cluster.
resource "aws_iam_role" "ecs_ec2_cluster" {
  name               = "ecs_ec2_cluster"
  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      },
      "Effect": "Allow"
    }
  ]
}
EOF
}

#Add permissions to create and puts logs to the instance.
#so we can see all system logs + ecs Logs in CloudWatch Logs.
data "aws_iam_policy_document" "awslogs" {
  statement {
    effect    = "Allow"
    resources = ["*"]
    actions = ["logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents",
      "logs:DescribeLogStreams"
    ]
  }
}
resource "aws_iam_policy" "awslogs" {
  name   = "ec2-aws-logs"
  policy = data.aws_iam_policy_document.awslogs.json
}

resource "aws_iam_role_policy_attachment" "ecs_ec2" {
  role       = aws_iam_role.ecs_ec2_cluster.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEC2ContainerServiceforEC2Role"
}

resource "aws_iam_role_policy_attachment" "logs_ec2" {
  role       = aws_iam_role.ecs_ec2_cluster.name
  policy_arn = aws_iam_policy.awslogs.arn
}


resource "aws_iam_instance_profile" "cluster" {
  name = "cluster"
  role = aws_iam_role.ecs_ec2_cluster.name
}
