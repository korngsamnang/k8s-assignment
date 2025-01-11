provider "aws" {
    region = "ap-southeast-1"
}

resource "aws_vpc" "custom_vpc" {
    cidr_block       = "10.0.0.0/16" # IP range available inside the VPC
    instance_tenancy = "default"     # Default tenancy

    tags = {
        Name = "custom_vpc"
    }
}
