# EKS Cluster Trust Policy
data "aws_iam_policy_document" "eks_cluster_assume_role" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["eks.amazonaws.com"]
    }
  }
}

# EKS Cluster IAM Role
resource "aws_iam_role" "eks_cluster" {
  name               = "trend-project2-eks-cluster-role"
  assume_role_policy = data.aws_iam_policy_document.eks_cluster_assume_role.json

  tags = local.common_tags
}

resource "aws_iam_role_policy_attachment" "eks_cluster_policy" {
  role       = aws_iam_role.eks_cluster.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
}

# EKS Worker Node Trust Policy
data "aws_iam_policy_document" "eks_node_assume_role" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

# EKS Worker Node IAM Role
resource "aws_iam_role" "eks_node" {
  name               = "trend-project2-eks-node-role"
  assume_role_policy = data.aws_iam_policy_document.eks_node_assume_role.json

  tags = local.common_tags
}

resource "aws_iam_role_policy_attachment" "eks_node_worker_policy" {
  role       = aws_iam_role.eks_node.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
}

resource "aws_iam_role_policy_attachment" "eks_node_cni_policy" {
  role       = aws_iam_role.eks_node.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
}

resource "aws_iam_role_policy_attachment" "eks_node_ecr_policy" {
  role       = aws_iam_role.eks_node.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
}

# Jenkins EC2 Trust Policy
data "aws_iam_policy_document" "jenkins_assume_role" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

# Jenkins EC2 IAM Role
resource "aws_iam_role" "jenkins" {
  name               = "trend-project2-jenkins-role"
  assume_role_policy = data.aws_iam_policy_document.jenkins_assume_role.json

  tags = local.common_tags
}

# Jenkins permission to retrieve EKS cluster details
resource "aws_iam_policy" "jenkins_eks_describe" {
  name        = "trend-project2-jenkins-eks-describe"
  description = "Allows Jenkins to retrieve EKS cluster connection details"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect   = "Allow"
      Action   = ["eks:DescribeCluster"]
      Resource = "*"
    }]
  })
}

resource "aws_iam_role_policy_attachment" "jenkins_eks_describe" {
  role       = aws_iam_role.jenkins.name
  policy_arn = aws_iam_policy.jenkins_eks_describe.arn
}

# Jenkins EC2 Instance Profile
resource "aws_iam_instance_profile" "jenkins" {
  name = "trend-project2-jenkins-profile"
  role = aws_iam_role.jenkins.name

  tags = local.common_tags
}

# Allow Jenkins EC2 to be managed through AWS Systems Manager
resource "aws_iam_role_policy_attachment" "jenkins_ssm" {
  role       = aws_iam_role.jenkins.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}
