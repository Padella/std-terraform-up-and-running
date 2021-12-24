provider "aws" {
  region = "us-east-2"
}

resource "aws_instance" "example" {
  ami           = "ami-0c55b159cbfafe1f0"
  instance_type = "t2.micro"

  # 로컬 시스템에서 스크립트 실행
  provisioner "local-exec" {
    command = "echo \"Hello, World from $(uname -smp)\""
  }
}
