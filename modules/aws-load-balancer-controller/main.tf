resource "aws_iam_policy" "lbc" {
  name        = "AWSLoadBalancerControllerIAMPolicy${var.resource_suffix}"
  description = "IAM policy for the AWS Load Balancer Controller"
  policy      = file("${path.module}/files/iam_policy.json")
}

module "irsa" {
  source = "../irsa"

  role_name         = "aws-load-balancer-controller${var.resource_suffix}"
  oidc_provider_arn = var.oidc_provider_arn
  oidc_provider     = var.oidc_provider
  namespace         = "kube-system"
  service_account   = "aws-load-balancer-controller"
  policy_arns       = [aws_iam_policy.lbc.arn]
}

resource "helm_release" "lbc" {
  name       = "aws-load-balancer-controller"
  repository = "https://aws.github.io/eks-charts"
  chart      = "aws-load-balancer-controller"
  namespace  = "kube-system"
  version    = "3.1.0"

  set = [
    {
      name  = "clusterName"
      value = var.cluster_name
    },
    {
      name  = "serviceAccount.create"
      value = "true"
    },
    {
      name  = "serviceAccount.name"
      value = "aws-load-balancer-controller"
    },
    {
      name  = "serviceAccount.annotations.eks\\.amazonaws\\.com/role-arn"
      value = module.irsa.role_arn
    },
    {
      name  = "region"
      value = var.region
    },
    {
      name  = "vpcId"
      value = var.vpc_id
    },
  ]

  depends_on = [module.irsa]
}
