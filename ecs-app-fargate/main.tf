#Create a IP target group, used in
#ECS Service Load Balancer's configuration
resource "aws_lb_target_group" "ecs" {
  vpc_id      = data.aws_vpc.default.id
  target_type = "ip"
  port        = 80
  protocol    = "HTTP"
}

#Create listener to forward traffic to the target group
resource "aws_lb_listener" "ecs" {
  load_balancer_arn = data.aws_lb.ecs.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.ecs.arn
  }
}

#Creates a task definition using the service.json
resource "aws_ecs_task_definition" "ecs_app" {
  family = "ecs_app_fargate"

  cpu          = 256
  memory       = 512
  network_mode = "awsvpc"

  task_role_arn      = aws_iam_role.task.arn
  execution_role_arn = aws_iam_role.execution.arn

  requires_compatibilities = ["FARGATE"]
  container_definitions    = file("service.json")
}

#Creates an ECS Services, it uses the previously created task definition
resource "aws_ecs_service" "ecs_app" {
  name    = "ecs_app"
  cluster = data.aws_ecs_cluster.ecs.arn

  desired_count   = 1
  launch_type     = "FARGATE"
  task_definition = aws_ecs_task_definition.ecs_app.arn

  network_configuration {
    security_groups = [data.aws_security_group.allow_22.id]
    subnets         = data.aws_subnet_ids.subnets.ids
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.ecs.arn
    container_name   = "ecs_app"
    container_port   = 80
  }
}
