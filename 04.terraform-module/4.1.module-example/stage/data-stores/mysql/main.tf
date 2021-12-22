provider "aws" {
  region = "us-east-2"
}

terraform {
  backend "s3" {
    bucket         = "padella-tf-state-example"
    key            = "stage/data-stores/mysql/terraform.tfstate"
    region         = "us-east-2"

    dynamodb_table = "padella-tf-locks-example"
    encrypt        = true
  }
}

resource "aws_db_instance" "example" {
  identifier_prefix = "terraform-up-and-running"
  # destroy 할 경우 다음 option 을 활성화
  # identify_prefix option 을 비활성화 한 뒤 apply > destroy 를 수행한다.
  // skip_final_snapshot = true
  engine            = "mysql"
  allocated_storage = 10
  instance_class    = "db.t2.micro"
  name              = "example_database"
  username          = "admin"

  # password 같은 secret 키를 관리하는 방법은 두 가지가 있다.
  # 1. terraform data source 를 사용하는 방법 (AWS Secrets Manager 등)
  # 2. environment variables 에서 로드하여 사용하는 방법
  #   + export TF_VAR_db_password 와 같이 TF_VAR_{var_name} 을 통해 terraform 에서 환경변수 로드가 가능하다.

  // password          = data.aws_secretsmanager_secret_version.db_password.secret_string
  password          = var.db_password
}

// data "aws_secretsmanager_secret_version" "db_password" {
//   secret_id = "mysql-master-password-stage"
// }
