# ASG 를 설정하기 위한 "시작 구성(launch_configuration)" 생성
resource "aws_launch_configuration" "example" {
	image_id 				= "ami-0c55b159cbfafe1f0"
	instance_type 	= "t2.micro"
	security_groups = [aws_security_group.instance.id]
	
  // user_data       = data.template_file.user_data.rendered 
  user_data = <<-EOF
							#!/bin/bash
							echo "Hello, World" > index.html
							nohup busybox httpd -f -p ${var.server_port} &
							EOF

	# ASG 의 시작 구성 참조로 인해 리소스를 삭제할 수 없는 문제 해결
	# 수명 주기 설정으로 create 및 참조 업데이트 후 삭제
	lifecycle {
		create_before_destroy = true
	}
}

# ASG 생성
resource "aws_autoscaling_group" "example" {
	launch_configuration = aws_launch_configuration.example.name
	# ec2 를 배포할 subnet 설정
	vpc_zone_identifier  = data.aws_subnet_ids.default.ids

	# 대상 그룹 지정
	target_group_arns  = [aws_lb_target_group.asg.arn]
	# type ELB 는 대상 그룹에 대한 상태확인
	# type EC2 는 vm 이 완전히 다운되었거나 하는 경우에 대해서만 비정상으로 판단
	health_check_type = "ELB"

	min_size = var.min_size
	max_size = var.max_size

	tag {
		key 								= "Name"
		value 							= var.cluster_name
		propagate_at_launch = true
	}

  dynamic "tag" {
    // for_each = var.custom_tags
    # for_each 구문 내에 for if 구문을 통해 중복 key 제거
    for_each = {
      for key, value in var.custom_tags:
      key => upper(value)
      if key != "Name"
    }

    content {
      key                 = tag.key
      value               = tag.value
      propagate_at_launch = true
    }
  }
}

resource "aws_autoscaling_schedule" "scale_out_during_business_hours" {
  # terraform 에서는 resource 내 count 값이 0 인 경우 리소스를 생성하지 않음
  # 1 인 경우 해당 리소스의 사본 하나를 얻음
  count = var.enable_autoscaling ? 1 : 0

  scheduled_action_name  = "${var.cluster_name}-scale-out-during-business-hours"
  min_size               = 2
  max_size               = 10
  desired_capacity       = 10
  recurrence             = "0 9 * * *"
  autoscaling_group_name = aws_autoscaling_group.example.name
}

resource "aws_autoscaling_schedule" "scale_in_at_night" {
  count = var.enable_autoscaling ? 1 : 0

  scheduled_action_name  = "${var.cluster_name}-scale-in-at-night"
  min_size               = 2
  max_size               = 10
  desired_capacity       = 2
  recurrence             = "0 17 * * *"
  autoscaling_group_name = aws_autoscaling_group.example.name
}

resource "aws_security_group" "instance" {
  name = "${var.cluster_name}-instance"

  ingress {
    from_port   = var.server_port
    to_port     = var.server_port
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# ALB(ELB) 생성
resource "aws_lb" "example" {

  name               = var.cluster_name

  load_balancer_type = "application"
  subnets            = data.aws_subnet_ids.default.ids
	# ALB 에 대한 security group 정의
  security_groups    = [aws_security_group.alb.id]
}

# ALB 의 listener 정의
resource "aws_lb_listener" "http" {
	# **ARN** 은 Amazon Resource Number 로 리소스의 일련번호
  load_balancer_arn = aws_lb.example.arn
  port              = local.http_port
  protocol          = "HTTP"

  # By default, return a simple 404 page
  default_action {
    type = "fixed-response"

    fixed_response {
      content_type = "text/plain"
      message_body = "404: page not found"
      status_code  = 404
    }
  }
}

# target group 을 정의해 ALB 가 인스턴스 상태를 점검할 수 있게 한다
resource "aws_lb_target_group" "asg" {

  name = var.cluster_name

  port     = var.server_port
  protocol = "HTTP"
  vpc_id   = data.aws_vpc.default.id

  health_check {
    path                = "/"
    protocol            = "HTTP"
    matcher             = "200"
    interval            = 15
    timeout             = 3
    healthy_threshold   = 2
    unhealthy_threshold = 2
  }
}

# 리스너 규칙 생성
# 모든 경로와 일치하는 요청을 ASG 가 포함된 대상 그룹으로 보내는 리스너 규칙
resource "aws_lb_listener_rule" "asg" {
  listener_arn = aws_lb_listener.http.arn
  priority     = 100

  condition {
    path_pattern {
      values = ["*"]
    }
  }

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.asg.arn
  }
}

# ALB 를 위한 security group
resource "aws_security_group" "alb" {

  name = "${var.cluster_name}-alb"

  # HTTP 인바운드 트래픽 허용
  ingress {
    from_port   = local.http_port
    to_port     = local.http_port
    protocol    = local.tcp_protocol
    cidr_blocks = local.all_ips
  }

  # 모든 아웃바운트 트래픽 허용
	# lb 가 health check 을 수행하도록 함 
  egress {
    from_port   = local.any_port
    to_port     = local.any_port
    protocol    = local.any_protocol
    cidr_blocks = local.all_ips
  }
}

resource "aws_cloudwatch_metric_alarm" "high_cpu_utilization" {
  # 클러스터의 평균 CPU 사용률이 5분 동안 90% 이상인 경우 cloudwatch 경보 생성
  alarm_name = "${var.cluster_name}-high-cpu-utilization"
  namespace   = "AWS/EC2"
  metric_name = "CPUUtilization"

  dimensions = {
    AuthScalingGroupName = aws_autoscaling_group.example.name
  }

  comparison_operator = "GreaterThanThreshold"
  evaluation_periods   = 1
  period               = 300
  statistic            = "Average"
  threshold            = 90
  unit                 = "Percent"
}

resource "aws_cloudwatch_metric_alarm" "low_cpu_credit_balance" {
  # instance type 에 따른 조건분기
  count = format("%.1s", var.instance_type) == "t" ? 1 : 0
  
  # CPU Credit 부족에 대한 경보 생성
  alarm_name = "${var.cluster_name}-low-cpu-credit-balance"
  namespace = "AWS/EC2"
  metric_name = "CPUCreditBalance"

  dimensions = {
    AuthScalingGroupName = aws_autoscaling_group.example.name
  }

  comparison_operator = "LessThanThreshold"
  evaluation_periods   = 1
  period               = 300
  statistic            = "Minimum"
  threshold            = 10
  unit                 = "Count"
}

# 테스트 환경에서 local state 를 사용
// data "terraform_remote_state" "db" {
//   backend = "s3"

//   config = {
//     # bucket = var.db_remote_state_bucket
//     # key    = var.db_remote_state_key
//     bucket = "padella-tf-state-example"
//     key    = "stage/data-stores/mysql/terraform.tfstate"
//     region = "us-east-2"
//   }
// }

# local 값 지정
locals {
  http_port    = 80
  any_port     = 0
  any_protocol = "-1"
  tcp_protocol = "tcp"
  all_ips      = ["0.0.0.0/0"]
}

// # shell script 파일 분리
// data "template_file" "user_data" {
//   template = file("user-data.sh")
// }

# aws 기본 vpc 데이터 조회
data "aws_vpc" "default" {
  default = true
}

# default vpc id 를 통해 subnet 조회
data "aws_subnet_ids" "default" {
  vpc_id = data.aws_vpc.default.id
}