
# ============================ IAM ROLE ============================
resource "aws_iam_role" "cluster" {
  name = "eks-cluster-example"
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Principal = {
          Service = "eks.amazonaws.com"
        },
        Action = ["sts:AssumeRole", "sts:TagSession"]
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "cluster_AmazonEKSClusterPolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
  role       = aws_iam_role.cluster.name
}

# ============================ EKS CLUSTER ============================

resource "aws_eks_cluster" "Qualitilabs_eks_cluster" {
  name     = "qualitilabs"
  role_arn = aws_iam_role.cluster.arn
  version  = "1.31"

  vpc_config {
    subnet_ids = [
      aws_subnet.public_az1.id,
      aws_subnet.public_az2.id
    ]
    endpoint_public_access  = true
    endpoint_private_access = false
  }

  access_config {
    authentication_mode = "API"
  }

  depends_on = [
    aws_iam_role_policy_attachment.cluster_AmazonEKSClusterPolicy
  ]
}

# =============================================X IAM Role for EKS Node Group X=====================================
resource "aws_iam_role" "eks_node_role" {
  name = "eks-node-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Action    = "sts:AssumeRole",
      Effect    = "Allow",
      Principal = {
        Service = "ec2.amazonaws.com"
      }
    }]
  })
}

resource "aws_iam_role_policy_attachment" "eks_worker_node_AmazonEKSWorkerNodePolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
  role       = aws_iam_role.eks_node_role.name
}

resource "aws_iam_role_policy_attachment" "eks_worker_node_AmazonEC2ContainerRegistryReadOnly" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  role       = aws_iam_role.eks_node_role.name
}

resource "aws_iam_role_policy_attachment" "eks_cni_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
  role       = aws_iam_role.eks_node_role.name
}


#===============================================X EKS Node Group X==================================


resource "aws_eks_node_group" "devops_node_group" {
  cluster_name = aws_eks_cluster.Qualitilabs_eks_cluster.name
  node_group_name = "devops-ng"
  node_role_arn   = aws_iam_role.eks_node_role.arn
  subnet_ids      = [
    aws_subnet.public_az1.id,
    aws_subnet.public_az2.id
  ]

  scaling_config {
    desired_size = 2
    max_size     = 3
    min_size     = 1
  }

  instance_types = ["t3.medium"] # Adjust based on workload

  ami_type       = "AL2_x86_64" # Amazon Linux 2
  disk_size      = 20

  tags = {
    Name = "devops-ng"
  }

  depends_on = [
    aws_iam_role_policy_attachment.eks_worker_node_AmazonEKSWorkerNodePolicy,
    aws_iam_role_policy_attachment.eks_worker_node_AmazonEC2ContainerRegistryReadOnly,
    aws_iam_role_policy_attachment.eks_cni_policy
  ]
}

#===============================================X  IAM WORKER ROLE  X===========================================


resource "aws_iam_role" "eks_worker_role" {
  name = "eks-worker-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Principal = {
          Service = "ec2.amazonaws.com"
        },
        Action = "sts:AssumeRole"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "worker_node_AmazonEKSWorkerNodePolicy" {
  role       = aws_iam_role.eks_worker_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
}

resource "aws_iam_role_policy_attachment" "worker_node_AmazonEC2ContainerRegistryReadOnly" {
  role       = aws_iam_role.eks_worker_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
}

resource "aws_iam_role_policy_attachment" "worker_node_AmazonEKS_CNI_Policy" {
  role       = aws_iam_role.eks_worker_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
}



resource "aws_iam_instance_profile" "eks_worker_instance_profile" {
  name = "eks-worker-instance-profile"
  role = aws_iam_role.eks_worker_role.name
}


resource "aws_instance" "eks_worker" {
  ami                         = var.eks_worker_ami # Amazon EKS Optimized AMI for your region
  instance_type               = "t3.medium"
  subnet_id                   = aws_subnet.public_az1.id
  vpc_security_group_ids      = [aws_security_group.devops_sg.id]
  associate_public_ip_address = true
  iam_instance_profile        = aws_iam_instance_profile.eks_worker_instance_profile.name
  key_name                    = var.key_name

  tags = {
    Name = "eks-worker-node"
  }

  connection {
    type        = "ssh"
    user        = "ec2-user"
    private_key = file("~/.ssh/id_rsa")
    host        = self.public_ip
  }

  provisioner "remote-exec" {
    inline = [
      "sudo yum update -y",
      "sudo yum install -y docker",
      "sudo systemctl start docker",
      "sudo systemctl enable docker",
      "sudo usermod -aG docker ec2-user",

      # Install dependencies
      "curl -o aws-iam-authenticator https://amazon-eks.s3.us-west-2.amazonaws.com/1.31.0/2023-11-16/bin/linux/amd64/aws-iam-authenticator",
      "chmod +x ./aws-iam-authenticator",
      "sudo mv ./aws-iam-authenticator /usr/local/bin",

      # Setup kubelet/kubectl (if needed)
      # Here you typically join the node to the EKS cluster via a bootstrap.sh or kubeadm
    ]
  }
}
