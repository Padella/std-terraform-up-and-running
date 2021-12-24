variable "user_names" {
  description = "Create IAM users with three names"
  type        = list(string)
  default     = ["neo", "trinity", "morpheus"]
}
