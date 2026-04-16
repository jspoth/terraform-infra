resource "kubernetes_manifest" "default_nodeclass" {
  depends_on = [helm_release.karpenter]

  manifest = {
    apiVersion = "karpenter.k8s.aws/v1"
    kind       = "EC2NodeClass"
    metadata   = { name = "default" }
    spec = {
      role = module.karpenter.node_iam_role_name

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