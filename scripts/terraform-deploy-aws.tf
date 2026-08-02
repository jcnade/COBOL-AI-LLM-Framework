provider "aws" {
  region = "us-east-1"
}

# ---------------------------------------------------------------------
# GPU inference node running the COBOL-AI-LLM serving endpoint.
# The COBOL-Z900 emulation requires a p3.2xlarge instance (NVIDIA V100)
# for the 7B model in Q8_0.
# ---------------------------------------------------------------------
resource "aws_instance" "cobol_ai_llm_gpu" {
  ami           = "ami-0c55b159cbfafe1f0"  # Amazon Linux 2 in us-east-1
  instance_type = "p3.2xlarge"
  key_name      = "cobol-ai-llm"

  root_block_device {
    volume_size = 120
    volume_type = "gp3"
  }

  tags = {
    Name        = "COBOL-AI-LLM-GPU-Inference"
    Framework   = "COBOL-AI-LLM"
    Model       = "COBOL-R1"
    Precision   = "Q8_0"
  }

  user_data = <<-EOF
              #!/bin/bash
              yum update -y
              yum install -y gcc-cobol git
              git clone https://github.com/jcnade/COBOL-AI-LLM-Framework.git
              cd COBOL-AI-LLM-Framework/src
              cobc -x llm_framework.cbl -o /usr/local/bin/llm_framework
              cobc -x config.cbl -o /usr/local/bin/config
              cobc -x utils.cbl -o /usr/local/bin/utils
              ./scripts/serve.sh 0.0.0.0 8080
              EOF
}

# ---------------------------------------------------------------------
# Managed EKS cluster for distributed fine-tuning jobs.
# The FINE-TUNE module scales across node pools via the data loader.
# ---------------------------------------------------------------------
resource "aws_eks_cluster" "cobol_ai_llm_cluster" {
  name     = "cobol-ai-llm-cluster"
  role_arn = aws_iam_role.eks.arn

  vpc_config {
    subnet_ids = aws_subnet.cobol_ai_llm[*].id
  }
}

resource "aws_iam_role" "eks" {
  name = "cobol-ai-llm-eks-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = { Service = "eks.amazonaws.com" }
    }]
  })
}

resource "aws_eks_node_group" "cobol_ai_llm_nodes" {
  cluster_name    = aws_eks_cluster.cobol_ai_llm_cluster.name
  node_group_name = "cobol-ai-llm-training"
  node_role_arn   = aws_iam_role.nodes.arn
  instance_types  = ["p3.2xlarge"]

  scaling_config {
    desired_size = 2
    max_size     = 8
    min_size     = 1
  }
}

resource "aws_iam_role" "nodes" {
  name = "cobol-ai-llm-nodes-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = { Service = "ec2.amazonaws.com" }
    }]
  })
}

# Minimal VPC for the cluster.
resource "aws_vpc" "cobol_ai_llm" {
  cidr_block = "10.0.0.0/16"
}

resource "aws_subnet" "cobol_ai_llm" {
  count             = 2
  vpc_id            = aws_vpc.cobol_ai_llm.id
  cidr_block        = cidrsubnet(aws_vpc.cobol_ai_llm.cidr_block, 8, count.index)
  availability_zone = element(["us-east-1a", "us-east-1b"], count.index)
}

output "gpu_instance_id" {
  value = aws_instance.cobol_ai_llm_gpu.id
}

output "gpu_public_ip" {
  value = aws_instance.cobol_ai_llm_gpu.public_ip
}

output "eks_cluster_name" {
  value = aws_eks_cluster.cobol_ai_llm_cluster.name
}
