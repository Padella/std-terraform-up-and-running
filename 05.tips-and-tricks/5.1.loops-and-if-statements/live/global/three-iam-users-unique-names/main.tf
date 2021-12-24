provider "aws" {
  region = "us-east-02"
}

resource "aws_iam_user" "example" {
  # list variable 의 length 를 이용해 IAM name 을 지정하는 방법
  # 다음은 array lookup 구문의 예제
  count = length(var.user_names)
  name  = var.user_names[count.index]
}
