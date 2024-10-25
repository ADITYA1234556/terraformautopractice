variable "REGION" {
  type = map(string)
  default = {
    "london" = "eu-west-2"
    "paris"  = "eu-west-3"
  }
}

variable "CIDR" {
  default = "10.100.0.0/16"
}

variable "CIDR2" {
  default = "20.100.0.0/16"
}

variable "PUBSUBNET1" {
  default = "10.100.1.0/24"
}

variable "PVTSUB1" {
  default = "20.100.1.0/24"
}

variable "INT_CIDR" {
  default = "0.0.0.0/0"
}