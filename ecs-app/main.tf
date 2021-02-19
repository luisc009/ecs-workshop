## Create target group
resource "aws_lb_target_group" "ecs" {
  vpc_id      = data.aws_vpc.default.id
  target_type = "instance"
  port        = 80
  protocol    = "HTTP"
}

## Create listener
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
  family = "service"

  task_role_arn      = aws_iam_role.task.arn
  execution_role_arn = aws_iam_role.execution.arn

  container_definitions = file("service.json")
}

#Creates an ECS Services, it uses the previously created task definition
resource "aws_ecs_service" "ecs_app" {
  name            = "ecs_app"
  cluster         = data.aws_ecs_cluster.ecs.arn
  task_definition = aws_ecs_task_definition.ecs_app.arn
  desired_count   = 1
  iam_role        = aws_iam_role.ecs_service_role.arn

  load_balancer {
    target_group_arn = aws_lb_target_group.ecs.arn
    container_name   = "ecs_app"
    container_port   = 80
  }
}
