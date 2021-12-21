variable "db_password" {
  description = "The password for the database"
  type        = string
  # 원래는 password 같은 내용은 default 옵션을 통해 평문으로 저장하면 안 되지만...
  # 공부하는 환경에서는 귀찮으니 일단..
  default     = "adminadmin"
}