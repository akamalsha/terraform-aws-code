variable "aws_region" {
    default = "us-west-2"
}
variable "prod_environment" {
    default = "prod-hub"
}
variable "spoke_01_environmet" {
  default = "spoke-01"
}
variable "spoke_02_environmet" {
    default = "spoke-02"
}
variable "prod_hub_vpc_cidr" {
    default = "10.13.0.0/24"
    description = "prod-hub"
}
variable "spoke_01_vpc_cidr" {
  default = "10.14.0.0/24"
  description = "spoke-01"
}
variable "spoke_02_vpc_cidr" {
    default = "10.15.0.0/24"
    description = "spoke-02"
}
variable "prod_public_subnets_cidr" {
    type        = list(any)
    default = ["10.13.0.112/28"]
    description = "prod-hub-public-subnet"
}
variable "prod_hub_private_subnets_cidr" {
    type        = list(any)
    default =  ["10.13.0.64/28"]   
    description = "prod-hub-private-subnet"
}
variable "spoke_01_private_subnets_cidr" {
    type        = list(any)
    default = ["10.14.0.64/28"]
    description = "spoke-01-private-subnet"
}
variable "spoke_02_private_subnets_cidr" {
   type        = list(any)
    default = ["10.15.0.64/28"]
    description = "spoke-02-private-subnet"
}

variable "availability_zone" {
    type = list
  default = ["us-west-2a", "us-west-2b"]
}
