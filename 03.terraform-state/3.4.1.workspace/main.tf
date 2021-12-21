provider "aws" {
  region = "us-east-2"
}

terraform {
  backend "s3" {
    // 3.2 코드에서 생성한 s3 bucket 및 dynamoDB table 을 사용한다.
    bucket = "padella-tf-state-example"
    key    = "workspaces-example/terraform.tfstate"
    region = "us-east-2"

    dynamodb_table = "padella-tf-locks-example"
    encrypt        = true
  }
}

resource "aws_instance" "example" {
  ami           = "ami-0c55b159cbfafe1f0"
  // instance_type = "t2.micro"
  instance_type = terraform.workspaces == "default" ? "t2.medium" : "t2.micro"
}
