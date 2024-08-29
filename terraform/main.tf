provider "aws" {
  region     = "ap-south-1"
  access_key = var.access_key
  secret_key = var.secret_key
}

# Data source to get the default VPC
data "aws_vpc" "default" {
  default = true
}

resource "aws_security_group" "allow_all" {
  description = "Security group allowing all traffic"
  vpc_id      = data.aws_vpc.default.id

  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_instance" "Terra_EC2-1" {
  ami                    = "ami-0c2af51e265bd5e0e"
  instance_type          = "t2.micro"
  vpc_security_group_ids = [aws_security_group.allow_all.id]

  user_data = templatefile("docker_install.sh", {
    github_repo_url = var.github_repo_url
  })

  tags = {
    Name = "React"
  }
}

output "instance_public_ip" {
  description = "The public IP of the EC2 instance"
  value       = aws_instance.Terra_EC2-1.public_ip
}

variable "secret_key" {}
variable "access_key" {}

variable "github_repo_url" {
  description = "The URL of the GitHub repository to deploy"
  type        = string
}
