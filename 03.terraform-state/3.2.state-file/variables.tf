variable "bucket_name" {
  description = "example-tf-state"
  type        = string
  default     = "padella-tf-state-example"
}

variable "table_name" {
  description = "example-tf-locks"
  type        = string
  default     = "padella-tf-locks-example"
}