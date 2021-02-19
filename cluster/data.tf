data "aws_caller_identity" "current" {}
data "aws_region" "current" {}
data "aws_vpc" "default" {
}

data "aws_subnet_ids" "public_subnets" {
  vpc_id = data.aws_vpc.default.id
}

#Retrieves the latest AMI ECS optimized
data "aws_ami" "ecs_ami" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn-ami-*-amazon-ecs-optimized"]
  }
}

#Create the cloudinit configuration
#Configures the ECS Cluster where the instance going to register.
#Configures the CloudWatch log configuration
data "template_cloudinit_config" "config" {
  gzip          = true
  base64_encode = true
  part {
    content_type = "text/x-shellscript"
    content      = <<EOT
#!/bin/bash
echo ECS_CLUSTER="${var.cluster_name}" >> /etc/ecs/ecs.config
echo ECS_ENABLE_CONTAINER_METADATA=true >> /etc/ecs/ecs.config
sudo yum update -y
sudo yum install -y awslogs
sudo service awslogs start
sudo chkconfig awslogs on
EOT
  }

  part {
    content_type = "text/cloud-config"
    content      = <<EOF
#cloud-config
write_files:
  - content: |
      [plugins]
      cwlogs = cwlogs
      [default]
      region = ${data.aws_region.current.name}
    owner: root:root
    path: /etc/awslogs/awscli.conf
    permissions: '000400'
EOF
  }

  part {
    content_type = "text/cloud-config"
    content      = <<EOF
#cloud-config
write_files:
  - content: |
      [general]
      state_file = /var/lib/awslogs/agent-state

      [/var/log/dmesg]
      file = /var/log/dmesg
      log_group_name = ${var.cluster_name}-/var/log/dmesg
      log_stream_name = ${var.cluster_name}

      [/var/log/messages]
      file = /var/log/messages
      log_group_name = ${var.cluster_name}-/var/log/messages
      log_stream_name = ${var.cluster_name}
      datetime_format = %b %d %H:%M:%S

      [/var/log/docker]
      file = /var/log/docker
      log_group_name = ${var.cluster_name}-/var/log/docker
      log_stream_name = ${var.cluster_name}
      datetime_format = %Y-%m-%dT%H:%M:%S.%f

      [/var/log/ecs/ecs-init.log]
      file = /var/log/ecs/ecs-init.log.*
      log_group_name = ${var.cluster_name}-/var/log/ecs/ecs-init.log
      log_stream_name = ${var.cluster_name}
      datetime_format = %Y-%m-%dT%H:%M:%SZ

      [/var/log/ecs/ecs-agent.log]
      file = /var/log/ecs/ecs-agent.log.*
      log_group_name = ${var.cluster_name}-/var/log/ecs/ecs-agent.log
      log_stream_name = ${var.cluster_name}
      datetime_format = %Y-%m-%dT%H:%M:%SZ

      [/var/log/ecs/audit.log]
      file = /var/log/ecs/audit.log.*
      log_group_name = ${var.cluster_name}-/var/log/ecs/audit.log
      log_stream_name = ${var.cluster_name}
      datetime_format = %Y-%m-%dT%H:%M:%SZ
    owner: root:root
    path: /etc/awslogs/awslogs.conf
    permissions: '000400'
EOF
  }
}

