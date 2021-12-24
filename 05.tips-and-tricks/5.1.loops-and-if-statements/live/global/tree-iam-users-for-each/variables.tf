variable "user_names" {
  description = "Creating IAM users with these names"
  type        = list(string)
  default     = ["neo", "trinity", "morpheus"]
}
