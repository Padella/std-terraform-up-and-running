// terraform {
//   backend "s3" {
//     bucket = "example-tf-state"
//     key    = "global/s3/terraform.tfstate"
//     region = "us-east-2"

//     dynamodb_table = "example-tf-locks"
//     encrypt        = true
//   }
// }

provider "aws" {
  region = "us-east-2"
}

resource "aws_s3_bucket" "terraform_state" {
  bucket = var.bucket_name

  # 실수로 S3 버킷을 삭제하는 것을 방지
  lifecycle {
    // prevent_destroy = true
  }

  # 코드 이력을 관리하기 위해 상태 파일의 버전 관리를 활성화
  versioning {
    enabled = true
  }

  # 서버 측 암호화 활성화
  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        sse_algorithm = "AES256"
      }
    }
  }
}

resource "aws_dynamodb_table" "terraform_locks" {
  name         = var.table_name
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "LockID"

  attribute {
    name = "LockID"
    type = "S"
  }
}