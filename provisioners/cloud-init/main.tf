terraform {
  backend "remote" {
    organization = "shadab-terraform"

    workspaces {
      name = "code-init"
    }
  }
  required_providers {
    aws = {
      source = "hashicorp/aws"
      version = "3.59.0"
    }
  }
}

provider "aws" {
  region = "us-east-1"
}

data "aws_vpc" "main" {
  id = "vpc-0d3adb31dd4ed7a90"
}


resource "aws_security_group" "sg_my_server" {
  name        = "sg_my_server"
  description = "MyServer Security Group"
  vpc_id      = data.aws_vpc.main.id

  ingress = [
    {
        description      = "HTTP"
        from_port        = 80
        to_port          = 80
        protocol         = "tcp"
        cidr_blocks      = ["0.0.0.0/0"]
        ipv6_cidr_blocks = []
        prefix_list_ids  = []
        security_groups = []
        self = false
    },
    {
        description      = "SSH"
        from_port        = 22
        to_port          = 22
        protocol         = "tcp"
        cidr_blocks      = ["0.0.0.0/0"]
        ipv6_cidr_blocks = []
        prefix_list_ids  = []
        security_groups = []
        self = false
    }
  ]

  egress = [
    {
        description = "outgoing traffic"
        from_port        = 0
        to_port          = 0
        protocol         = "-1"
        cidr_blocks      = ["0.0.0.0/0"]
        ipv6_cidr_blocks = ["::/0"]
        prefix_list_ids  = []
	    security_groups = []
		self = false
    }
  ]
}

resource "aws_key_pair" "deployer" {
  key_name   = "deployer-key"
  public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQDIX9ghpddWzDFLMTRSmLDoXWCKQwq5Lcr3rAHm5bdkasZebCaiaLnFmO/7jDghJvKPCxjgH1FSRpousBD4Gx2lJo2LrABaXxDyibVcak5qmPor8UA0ThB31WsEAd6wCU7DC6gjtPaIDa0MCSX5Ey90on+geY+rc1dAvd10OktGjeo1T+yeVCvmGUfvc+zGzS0zttpGvlYijGojTKeQ0HZlWozzoX/dbxRQbLb3oBXe+ZO9uaEi1NI03b+X59MAeWjf/cwPfq+0Rp6OSyfJ1EsXoilQxv5Eetf0q+Lp4mvCG2r/vAGj9GLzJCvp3yPukk/8Knki4bvx7gH6dwc8FScvjRHIaJ8ZaVqAlY3d2725y87Bamms8E9F3EG4O/kkQTeGV9i6iayBz07lbcyWKo+Abu77PWcHnsN3AZKHvAlMWv/v6NNNJBRJ42ddsoxmEGcietPhWXOPmlk8M3U+u8P81uLeVfPEBJCmqGh0EKVO5bzkE0ERZORw6Biou0f6r4U= ahmedshadab@Ahmeds-MacBook-Pro.local"
}

data "template_file" "user_data" {
	template = file("./userdata.yaml")
}


resource "aws_instance" "my_server" {
    ami           = "ami-087c17d1fe0178315"
    instance_type = "t2.micro"
    key_name = "${aws_key_pair.deployer.key_name}"
	vpc_security_group_ids = [aws_security_group.sg_my_server.id]
	user_data = data.template_file.user_data.rendered
    provisioner "file" {
        content     = "mytext content goes here"
        destination = "/home/ec2-user/abc.txt"
		connection {
			type     = "ssh"
			user     = "ec2-user"
			host     = "${self.public_ip}"
			private_key = "${file("./terraform")}"
		}
  }

  tags = {
    Name = "MyServer"
  }
}

resource "null_resource" "status" {
    provisioner "local-exec" {  
        command = "aws ec2 wait instance-status-ok --instance-ids ${aws_instance.my_server.id}"
    }
    depends_on = [
            aws_instance.my_server
        ]
}

output "public_ip"{
	value = aws_instance.my_server.public_ip
}