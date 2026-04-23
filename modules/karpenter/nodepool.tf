resource "kubernetes_manifest" "general_pool" {
  depends_on = [helm_release.karpenter]

  manifest = {
    apiVersion = "karpenter.sh/v1"
    kind       = "NodePool"

    metadata = { name = "general" }

    spec = {
      template = {
        metadata = {
          labels = { workload = "general" }
        }

        spec = {
          nodeClassRef = {
            group = "karpenter.k8s.aws"
            kind  = "EC2NodeClass"
            name  = kubernetes_manifest.default_nodeclass.manifest.metadata.name
          }

          expireAfter = "720h"

          requirements = [
            {
              key      = "karpenter.sh/capacity-type"
              operator = "In"
              values   = ["on-demand"]
            },
            {
              key      = "kubernetes.io/arch"
              operator = "In"
              values   = ["amd64"]
            },
            {
              key      = "karpenter.k8s.aws/instance-category"
              operator = "In"
              values   = ["t"]
            },
            {
              key      = "karpenter.k8s.aws/instance-size"
              operator = "In"
              values   = ["small", "medium", "large"]
            }
          ]
        }
      }

      disruption = {
        consolidationPolicy = "WhenEmptyOrUnderutilized"
        consolidateAfter    = "30s"
      }

      limits = { cpu = "1000" }
    }
  }
}

# 2. Non-Critical Pool: Spot Only (with Taint)
resource "kubernetes_manifest" "spot_pool" {
  depends_on = [helm_release.karpenter]

  manifest = {
    apiVersion = "karpenter.sh/v1"
    kind       = "NodePool"
    metadata   = { name = "non-critical" }
    spec = {
      template = {
        metadata = {
          labels = {
            workload = "non-critical"
          }
        }
        spec = {
          nodeClassRef = {
            group = "karpenter.k8s.aws"
            kind  = "EC2NodeClass"
            name  = kubernetes_manifest.default_nodeclass.manifest.metadata.name
          }
          # Adding a Taint ensures only pods that 'tolerate' spot can land here
          taints = [
            {
              key    = "capacity-type"
              value  = "spot"
              effect = "NoSchedule"
            }
          ]
          expireAfter = "720h"
          requirements = [
            {
              key      = "karpenter.sh/capacity-type"
              operator = "In"
              values   = ["spot"]
            },
            {
              key      = "karpenter.k8s.aws/instance-category"
              operator = "In"
              values   = ["c", "m", "r"]
            },
            {
              key      = "kubernetes.io/arch"
              operator = "In"
              values   = ["amd64"]
            }
          ]
        }
      }
      disruption = {
        consolidationPolicy = "WhenEmptyOrUnderutilized"
        consolidateAfter    = "30s"
      }
    }
  }
}