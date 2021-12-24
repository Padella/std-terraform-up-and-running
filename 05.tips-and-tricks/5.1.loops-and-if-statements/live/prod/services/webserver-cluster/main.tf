provider "aws" {
  region = "us-east-2"
}

module "webserver_cluster" {
  # module 경로를 local 환경에서 읽지 못 하는 문제로 인해 static 경로를 임시로 사용함
  source = "/Users/kimmuryeon/Desktop/std-terraform-up-and-running/05.tips-and-tricks/5.1.loops-and-if-statements/ modules/services/webserver-cluster"

  cluster_name  = "webservers-prod"
  instance_type = "t2.micro"
  min_size      = 2
  max_size      = 10

  custom_tags = {
    Owner      = "team-foo"
    DeployedBy = "terraform"
  }
}

resource "aws_autoscaling_schedule" "scale_out_during_business_hours" {
  scheduled_action_name = "scale-out-during-business-hours"
  min_size = 2
  max_size = 10
  desired_capacity = 10
  recurrence = "0 9 * * *"

  autoscaling_group_name = module.webserver_cluster.asg_name
}

resource "aws_autoscaling_schedule" "scale_in_at_night" {
  scheduled_action_name = "scale-in-at-night"
  min_size              = 2
  max_size              = 10
  desired_capacity      = 2
  recurrence            = "0 17 * * *"

  autoscaling_group_name = module.webserver_cluster.asg_name
}
