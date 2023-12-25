terraform {
  required_providers {
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = ">= 2.0.0"
    }
    aws = {
      source  = "hashicorp/aws"
      version = "5.25.0"
    }
  }
}


provider "kubernetes" {
  config_path = "~/.kube/config"
}

provider "aws" { region = "us-east-1" }



variable "cluster_name" {
  default = "aroon-cluster"
  type    = string
}

variable "vpc_id" {
  default = "vpc-0f7acbeb3b389d1df"
  type    = string
}

data "aws_internet_gateway" "default" {
  filter {
    name   = "attachment.vpc-id"
    values = [var.vpc_id]
  }
}

resource "aws_security_group" "allow_ssh" {
  name = "allow_ssh"
  description = "allow incoming ssh trafic"
  vpc_id = var.vpc_id
  
  ingress {
  from_port = 22
  to_port = 22
  protocol = "tcp"
  cidr_blocks = ["0.0.0.0/0"]
  }

}




resource "aws_subnet" "public-us-east-1a" {
  vpc_id                  = var.vpc_id
  cidr_block              = "10.0.208.0/24"
  availability_zone       = "us-east-1a"
  map_public_ip_on_launch = true
}
resource "aws_subnet" "public-us-east-1b" {
  vpc_id                  = var.vpc_id
  cidr_block              = "10.0.228.0/24"
  availability_zone       = "us-east-1b"
  map_public_ip_on_launch = true
}


# nat gateway




# routes


resource "aws_route_table" "public" {
  vpc_id = var.vpc_id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = data.aws_internet_gateway.default.id
  }

  tags = {
    Name = "public"
  }
}

resource "aws_route_table_association" "public-us-east-1a" {
  subnet_id      = aws_subnet.public-us-east-1a.id
  route_table_id = aws_route_table.public.id
}


resource "aws_route_table_association" "public-us-east-1b" {
  subnet_id      = aws_subnet.public-us-east-1b.id
  route_table_id = aws_route_table.public.id
}

# cluster

resource "aws_eks_cluster" "cluster-1" {
  name     = var.cluster_name
  version  = "1.28"
  role_arn = "arn:aws:iam::019050461780:role/eks-iam-role"


  vpc_config {
    subnet_ids = [
      aws_subnet.public-us-east-1a.id,
      aws_subnet.public-us-east-1b.id
    ]

    endpoint_private_access = false
    endpoint_public_access  = true
    public_access_cidrs     = ["0.0.0.0/0"]
  }

  enabled_cluster_log_types = ["api", "audit"]
}

output "endpoint" {
  value = aws_eks_cluster.cluster-1.endpoint
}

output "kubeconfig-certificate-authority-data" {
  value = aws_eks_cluster.cluster-1.certificate_authority[0].data
}

# node group

resource "aws_eks_node_group" "ar-nodes" {
  
  cluster_name    = aws_eks_cluster.cluster-1.name
  version         = "1.28"
  node_group_name = "aroun-nodes"
  node_role_arn   = "arn:aws:iam::019050461780:role/eksworkernodes-iam-role"
  subnet_ids      = [aws_subnet.public-us-east-1a.id, aws_subnet.public-us-east-1b.id]

  capacity_type  = "ON_DEMAND"
  instance_types = ["t2.small"]
  
  scaling_config {
    desired_size = 3
    max_size     = 5
    min_size     = 2
  }
  
  remote_access {
    ec2_ssh_key = "roo-key"
    source_security_group_ids = [aws_security_group.allow_ssh.id]
  }

  update_config {
    max_unavailable = 1
  }
  lifecycle {
    ignore_changes = [scaling_config[0].desired_size]
  }
}

