resource "kubernetes_manifest" "default_nodeclass" {
  manifest = {
    apiVersion = "karpenter.k8s.aws/v1beta1"
    kind       = "EC2NodeClass"
    metadata   = { name = "default" }
    spec = {
      amiFamily = "AL2"
      role      = module.karpenter.node_iam_role_name

      # Karpenter needs to know which AMIs are allowed
      amiSelectorTerms = [
        { alias = "al2@latest" }
      ]

      subnetSelectorTerms = [
        { tags = { "karpenter.sh/discovery" = var.cluster_name } }
      ]

      securityGroupSelectorTerms = [
        { tags = { "karpenter.sh/discovery" = var.cluster_name } }
      ]
    }
  }
}