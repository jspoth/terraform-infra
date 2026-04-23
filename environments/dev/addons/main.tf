module "karpenter" {
  source       = "../../../modules/karpenter"
  cluster_name = var.cluster_name
}

# ── External Secrets Operator ────────────────────────────────────────────────

data "aws_iam_role" "eso" {
  name = "eso-irsa-dev"
}

resource "helm_release" "external_secrets" {
  name             = "external-secrets"
  repository       = "https://charts.external-secrets.io"
  chart            = "external-secrets"
  namespace        = "external-secrets"
  create_namespace = true
  version          = "0.10.7"

  set = [
    {
      name  = "serviceAccount.annotations.eks\\.amazonaws\\.com/role-arn"
      value = data.aws_iam_role.eso.arn
    }
  ]
}

# ── Reloader ─────────────────────────────────────────────────────────────────
# Watches K8s Secrets and triggers rolling restarts when they change.

resource "helm_release" "reloader" {
  name             = "reloader"
  repository       = "https://stakater.github.io/stakater-charts"
  chart            = "reloader"
  namespace        = "reloader"
  create_namespace = true
  version          = "1.1.0"
}
