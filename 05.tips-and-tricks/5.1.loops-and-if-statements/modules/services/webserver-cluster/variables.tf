# -----------------------------------------------------------------------
# REQUIRES PARAMETERS
# -----------------------------------------------------------------------

variable "db_remote_state_bucket" {
  description = "The name of the S3 bucket used for the database's remote state storage"
  type        = string
  default     = "padella-tf-state-example"
}

variable "db_remote_state_key" {
  description = "The name of the key in the S3 bucket used for the database's remote state storage"
  type        = string
  default     = "stage/service/webserver-cluster/terraform.tfstate"
}

variable "cluster_name" {
  description = "The name to user for all the cluster resources"
  type        = string
}

variable "instance_type" {
  description = "The type of EC2 Instances to run (e.g. t2.micro)"
  type        = string
}

variable "min_size" {
  description = "The minimum number of EC2 Instances in the ASG"
  type        = number
}

variable "max_size" {
  description = "The maximum number of EC2 Instances in the ASG"
  type        = number
}

variable "enable_autoscaling" {
  description = "If set to true, enable auth scaling"
  type        = bool
}

# -----------------------------------------------------------------------
# OPTIONAL PARAMETERS
# -----------------------------------------------------------------------

variable "server_port" {
  description = "The port the server will use for HTTP requests"
  type        = number
  default     = 8080
}

variable "custom_tags" {
  description = "Custom tags to set on the Instances in the ASG"
  type        = map(string)
  default     = {}
}