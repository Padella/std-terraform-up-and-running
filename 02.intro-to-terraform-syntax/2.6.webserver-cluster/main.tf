provider "aws" {
	region = "us-east-2"
}

# ASG 를 설정하기 위한 "시작 구성(launch_configuration)" 생성
resource "aws_launch_configuration" "example" {
	image_id 				= "ami-0c55b159cbfafe1f0"
	instance_type 	= "t2.micro"
	security_groups = [aws_security_group.instance.id]

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

	min_size = 2
	max_size = 10

	tag {
		key 								= "Name"
		value 							= "terraform-asg-example"
		propagate_at_launch = true
	}
}

resource "aws_security_group" "instance" {
  name = var.instance_security_group_name

  ingress {
    from_port   = var.server_port
    to_port     = var.server_port
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# aws 기본 vpc 데이터 조회
data "aws_vpc" "default" {
  default = true
}

# default vpc id 를 통해 subnet 조회
data "aws_subnet_ids" "default" {
  vpc_id = data.aws_vpc.default.id
}

# ALB(ELB) 생성
resource "aws_lb" "example" {

  name               = var.alb_name

  load_balancer_type = "application"
  subnets            = data.aws_subnet_ids.default.ids
	# ALB 에 대한 security group 정의
  security_groups    = [aws_security_group.alb.id]
}

# ALB 의 listener 정의
resource "aws_lb_listener" "http" {
	# **ARN** 은 Amazon Resource Number 로 리소스의 일련번호
  load_balancer_arn = aws_lb.example.arn
  port              = 80
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

  name = var.alb_name

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

  name = var.alb_security_group_name

  # HTTP 인바운드 트래픽 허용
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # 모든 아웃바운트 트래픽 허용
	# lb 가 health check 을 수행하도록 함 
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}
