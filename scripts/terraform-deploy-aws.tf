provider "aws" {
  region = "us-east-1"
}

resource "aws_instance" "cobol_ai_llm_instance" {
  ami           = "ami-0c55b159cbfafe1f0"  # AMI for Amazon Linux 2 in us-east-1
  instance_type = "t2.micro"

  tags = {
    Name = "COBOL-AI-LLM-Framework-Instance"
  }

  user_data = <<-EOF
              #!/bin/bash
              # Install necessary packages
              yum update -y
              yum install -y gcc-cobol git

              # Clone the COBOL-AI-LLM-Framework repository
              git clone https://github.com/jcnade/COBOL-AI-LLM-Framework.git
              cd COBOL-AI-LLM-Framework/src

              # Compile the framework
              cobc -x llm_framework.cbl -o llm_framework
              cobc -x config.cbl -o config
              cobc -x utils.cbl -o utils

              # Run the framework
              ./llm_framework
              EOF
}

output "instance_id" {
  value = aws_instance.cobol_ai_llm_instance.id
}

output "public_ip" {
  value = aws_instance.cobol_ai_llm_instance.public_ip
}
