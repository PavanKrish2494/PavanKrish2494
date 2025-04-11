

# ============================ VARIABLES ============================
variable "ami" {
  description = "AMI ID for EC2 instance"
  type        = string
}

variable "volume_size" {
  description = "Volume size"
  type        = number
}

variable "server_name" {
  description = "EC2 Server Name"
  type        = string
}

variable "subnet_cidr" {
  default = "10.0.2.0/24"
}

variable "subnet_cidr_az2" {
  default = "10.0.3.0/24"
}

variable "subnet_cidr_az3" {
  default = "10.0.4.0/24"
}

variable "availability_zone" {
  default = "us-east-1a"
}

variable "availability_zone_az2" {
  default = "us-east-1b"
}

variable "availability_zone_az3" {
  default = "us-east-1c"
}

variable "instance_type" {
  default = "t2.medium"
}

variable "key_name" {
  description = "Key Pair"
  type        = string
}

variable "region" {
  default = "us-east-1"
}

variable "vpc_cidr" {
  default = "10.0.0.0/16"
}

variable "public_subnet_az1_cidr" {
  default = "10.0.1.0/24"
}

variable "public_subnet_az2_cidr" {
  default = "10.0.2.0/24"
}

variable "availability_zone_1" {
  default = "us-east-1a"
}

variable "availability_zone_2" {
  default = "us-east-1b"
}





variable "eks_worker_ami" {
  default = "ami-0e86e20dae9224db8"
}