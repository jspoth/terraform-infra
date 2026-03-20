resource "kubernetes_manifest" "general_pool" {
  manifest = {
    apiVersion = "karpenter.sh/v1beta1"
    kind       = "NodePool"

    metadata = { name = "general" }

    spec = {
      template = {
        metadata = {
          labels = { workload = "general" }
        }

        spec = {
          nodeClassRef = { name = kubernetes_manifest.default_nodeclass.manifest.metadata.name }

          requirements = [
            {
              key      = "karpenter.sh/capacity-type"
              operator = "In"
              values   = ["on-demand"]
            }
          ]
        }
      }

      disruption = {
        consolidationPolicy = "WhenUnderutilized"
        expireAfter         = "720h"
      }

      limits = { cpu = "1000" }
    }
  }
}

# 2. Non-Critical Pool: Spot Only (with Taint)
resource "kubernetes_manifest" "spot_pool" {
  manifest = {
    apiVersion = "karpenter.sh/v1beta1"
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
            name = kubernetes_manifest.default_nodeclass.manifest.metadata.name
          }
          # Adding a Taint ensures only pods that 'tolerate' spot can land here
          taints = [
            {
              key    = "capacity-type"
              value  = "spot"
              effect = "NoSchedule"
            }
          ]
          requirements = [
            { key = "karpenter.sh/capacity-type", operator = "In", values = ["spot"] },
            { key = "karpenter.k8s.aws/instance-category", operator = "In", values = ["c", "m", "r"] }
          ]
        }
      }
      disruption = {
        consolidationPolicy = "WhenUnderutilized"
        expireAfter         = "720h"
      }
    }
  }
}