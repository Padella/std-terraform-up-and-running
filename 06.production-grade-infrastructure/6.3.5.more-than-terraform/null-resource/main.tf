provider "aws" {
  region = "us-east-2"
}

resource "null_resource" "example" {
  # uuid 를 사용하여 이 null_resource 를 매번 다시 만들도록 한다.
  # terraform apply 실행 시
  triggers = {
    uuid = uuid()
  }

  provisioner "local-exec" {
    command = "echo \"Hello, World from $(uname -smp)\""
  }
}
