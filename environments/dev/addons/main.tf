module "karpenter" {
  source       = "../../../modules/karpenter"
  cluster_name = var.cluster_name
}

