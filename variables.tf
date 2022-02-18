variable "cidr_block" {
  default = "10.20.30.0/24"
}

variable "public_subnets" {
  default = ["10.20.30.0/28", "10.20.30.16/28"]
}

variable "private_subnet" {
  default = "10.20.30.112/28"
}

variable "availability_zones" {
  description = "a comma-separated list of availability zones"
  default     = ["eu-central-1a", "eu-central-1b", "eu-central-1c"]
}

variable "environment" {}

variable "domain" {
  description = "Domain used in phishing campaign"
}
