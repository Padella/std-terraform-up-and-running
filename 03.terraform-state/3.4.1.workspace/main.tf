provider "aws" {
  region = "us-east-2"
}

terraform {
  backend "s3" {
    // 3.2 코드에서 생성한 s3 bucket 및 dynamoDB table 을 사용한다.
    bucket = "example-tf-state"
    key    = "workspaces-example/terraform.tfstate"
    region = "us-east-2"

    dynamodb_table = "example-tf-locks"
    encrypt        = true
  }
}

resource "aws_instance" "example" {
  ami           = "ami-0c55b159cbfafe1f0"
  instance_type = "t2.micro"
}
