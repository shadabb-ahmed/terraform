
terraform {
#   backend "remote" {
#     hostname = "app.terraform.io"
#     organization = "shadab-terraform"

#     workspaces {
#       name = "test-workspace"
#     }
#   }
  required_providers {
    aws = {
      source = "hashicorp/aws"
      version = "3.64.2"
    }
  }
}

locals {
  project_name = "terraform_shadab"
  owner        = "shadab"
}


resource "aws_instance" "app_server" {  
    ami           = "ami-0f19d220602031aed"  
    instance_type = var.instance_type
  tags = {    
      Name = "MyServer-${local.project_name}"  
    }
    provisioner "remote-exec" {
    inline = [
        "echo ${self.private_ip} >> /home/ec2-user/rivate_ips.txt"
    ]
    connection {
        type = "ssh"
        user = "ec2-user"
        host = "${self.public_ip}"
        private_key = "${file("/local_file_path")}"
    }
  }
}

/*
module "vpc" {
  source = "terraform-aws-modules/vpc/aws"
  providers = {
      aws = aws.eu
  }

  name = "my-vpc"
  cidr = "10.0.0.0/16"

  azs             = ["eu-west-1a", "eu-west-1b", "eu-west-1c"]
  private_subnets = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
  public_subnets  = ["10.0.101.0/24", "10.0.102.0/24", "10.0.103.0/24"]

  enable_nat_gateway = true
  enable_vpn_gateway = true

  tags = {
    Terraform = "true"
    Environment = "dev"
  }
}
*/