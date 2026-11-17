# Latest Amazon Linux 2023 x86_64 AMI
data "aws_ssm_parameter" "al2023_ami" {
  name = "/aws/service/ami-amazon-linux-latest/al2023-ami-kernel-default-x86_64"
}

# Jenkins EC2 Instance
resource "aws_instance" "jenkins" {
  ami                    = data.aws_ssm_parameter.al2023_ami.value
  instance_type          = "t3.small"
  subnet_id              = aws_subnet.public_1.id
  vpc_security_group_ids = [aws_security_group.jenkins.id]
  iam_instance_profile   = aws_iam_instance_profile.jenkins.name

  associate_public_ip_address = true

  root_block_device {
    volume_size = 20
    volume_type = "gp3"
    encrypted   = true
  }

  user_data = <<-USERDATA
    #!/bin/bash
    set -eux

    dnf update -y
    dnf install -y java-21-amazon-corretto docker git wget

    systemctl enable --now docker

    wget -O /etc/yum.repos.d/jenkins.repo \
      https://pkg.jenkins.io/rpm-stable/jenkins.repo

    rpm --import https://pkg.jenkins.io/rpm-stable/jenkins.io-2023.key

    dnf install -y jenkins

    usermod -aG docker jenkins

    systemctl enable --now jenkins
  USERDATA

  tags = merge(local.common_tags, {
    Name = "trend-project2-jenkins"
  })

  depends_on = [
    aws_iam_role_policy_attachment.jenkins_ssm
  ]
}
