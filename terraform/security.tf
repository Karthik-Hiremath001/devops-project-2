# Jenkins EC2 Security Group
resource "aws_security_group" "jenkins" {
  name        = "trend-project2-jenkins-sg"
  description = "Restricted access to Jenkins"
  vpc_id      = aws_vpc.main.id

  # Jenkins dashboard - only accessible from your current public IP
  ingress {
    description = "Jenkins dashboard"
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = [var.my_ip]
  }

  # Outbound access for package downloads, Docker Hub, AWS APIs, etc.
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(local.common_tags, {
    Name = "trend-project2-jenkins-sg"
  })
}
# Allow Jenkins EC2 to communicate with the EKS Kubernetes API
resource "aws_vpc_security_group_ingress_rule" "jenkins_to_eks" {
  security_group_id            = aws_eks_cluster.main.vpc_config[0].cluster_security_group_id
  referenced_security_group_id = aws_security_group.jenkins.id

  description = "Allow Jenkins EC2 to access EKS API"
  ip_protocol = "tcp"
  from_port   = 443
  to_port     = 443
}
