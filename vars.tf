variable "REGION" {
  type = map(string)
  default = {
    "london" = "eu-west-2"
    "paris"  = "eu-west-3"
  }
}

variable "CIDR" {
  type = string
  default = "10.100.0.0/16"
}

variable "CIDR2" {
  type = string
  default = "20.100.0.0/16"
}

variable "PUBSUBNET1" {
  type = string
  default = "10.100.1.0/24"
}

variable "PVTSUB1" {
  type = string
  default = "20.100.1.0/24"
}

variable "INT_CIDR" {
  type = string
  default = "0.0.0.0/0"
}

# variable "AWS_ACCESS_KEY_ID" {
#   description = "The AWS Access Key ID for authentication"
#   type        = string
# }
#
# variable "AWS_SECRET_ACCESS_KEY" {
#   description = "The AWS Secret Access Key for authentication"
#   type        = string
# }
