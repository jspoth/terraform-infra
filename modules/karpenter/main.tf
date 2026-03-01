module "karpenter" {
  source  = "terraform-aws-modules/eks/aws//modules/karpenter"
  version = "~> 21.0"

  cluster_name = var.cluster_name

  # --- Pod Identity (The modern replacement for IRSA) ---
  enable_pod_identity             = true
  create_pod_identity_association = true
  # Note: The v21 module creates the association in kube-system by default.

  # --- Node IAM Role (For the EC2 instances Karpenter launches) ---
  create_node_iam_role = true
  node_iam_role_additional_policies = {
    AmazonSSMManagedInstanceCore = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
  }

  # --- Spot & Event Handling ---
  # This creates the SQS queue and EventBridge rules for Spot interruptions
  enable_spot_termination = true

  # --- Permissions ---
  enable_v1_permissions = true
}

resource "aws_eks_access_entry" "karpenter_node" {
  cluster_name      = var.cluster_name
  principal_arn     = module.karpenter.node_iam_role_arn
  type              = "EC2_LINUX" # Grants permission for nodes to join as workers
}

resource "aws_eks_access_policy_association" "karpenter_node" {
  cluster_name  = var.cluster_name
  policy_arn    = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
  principal_arn = module.karpenter.node_iam_role_arn

  access_scope {
    type = "cluster"
  }
}

