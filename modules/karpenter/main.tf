module "karpenter" {
  source  = "terraform-aws-modules/eks/aws//modules/karpenter"
  version = "~> 21.0"

  cluster_name = var.cluster_name # Use the output from your EKS module

  # --- Pod Identity ---
  create_pod_identity_association = true
  namespace                       = "karpenter" # Best practice for SRE projects

  # --- Node IAM Role ---
  create_node_iam_role = true
  node_iam_role_additional_policies = {
    AmazonSSMManagedInstanceCore = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
  }

  # --- Spot Support ---
  enable_spot_termination = true
}

# Karpenter must be installed via Helm before NodeClass/NodePool manifests can be applied.
# kubernetes_manifest resources require the CRDs (EC2NodeClass, NodePool) to exist at plan time,
# and those CRDs are only registered once the Karpenter Helm chart is deployed.
resource "helm_release" "karpenter" {
  name             = "karpenter"
  namespace        = "karpenter"
  create_namespace = true
  repository       = "oci://public.ecr.aws/karpenter"
  chart            = "karpenter"
  version          = "1.11.1"

  values = [
    jsonencode({
      replicas = 1
      serviceAccount = {
        name = module.karpenter.service_account
      }
      settings = {
        clusterName       = var.cluster_name
        interruptionQueue = module.karpenter.queue_name
      }
    })
  ]

  depends_on = [module.karpenter]
}


