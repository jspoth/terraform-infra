Full documentation — design decisions, debugging lessons, DR test results: **[jspoth.com](https://jspoth.com)**

---

## 🏗️ Architectural Overview

The repository follows a **Decoupled Root Module** pattern to balance reusability with environment stability.

* **`/modules`**: Source of truth for infrastructure components. Versioned and reusable across environments.
* **`/environments`**: Contains live state definitions per environment. Each layer has its own S3 backend and DynamoDB state lock — isolated blast radius.
* **`.github/workflows`**: The "Control Plane" of the repo. Uses **Reusable Workflows** to standardize CI/CD across all environments.

---

## 🗂 Repository Structure

```text
terraform-infra/
├── modules/
│   ├── vpc/              # VPC, subnets, NAT gateway, route tables
│   ├── eks/              # EKS cluster, managed node groups, addons
│   ├── dynamodb/         # DynamoDB table with global replica + stream
│   ├── sqs/              # SQS queues + DLQs via for_each
│   ├── irsa/             # IAM Role for Service Accounts (reusable)
│   └── karpenter/        # Karpenter node autoscaler
├── environments/
│   ├── dev/              # Primary region (us-east-2)
│   │   ├── general/      # VPC, EKS, LBC, EKS access entries
│   │   ├── datastores/   # DynamoDB — persistent storage, prevent_destroy
│   │   ├── messaging/    # SQS queues and DLQs
│   │   ├── addons/       # Karpenter, ESO, Reloader
│   │   ├── dns/          # Route 53 PRIMARY failover record + health check
│   │   └── permissions/  # IRSA roles + all app IAM policies
│   └── DR/               # DR region (us-west-2) — pilot light
│       ├── general/      # VPC, EKS (min=0), LBC
│       ├── datastores/   # DynamoDB Global Table replica
│       ├── messaging/    # SQS queues + DLQs
│       ├── addons/       # Karpenter, ESO, Reloader
│       ├── dns/          # ACM cert + SECONDARY failover record + health check
│       └── permissions/  # IRSA roles scoped to DR cluster OIDC
├── bootstrap/            # One-time IAM/OIDC + S3 backend setup
└── .github/workflows/
    ├── lint.yml          # Reusable: fmt, validate, tflint
    ├── infracost.yml     # Reusable: cost estimation on PRs
    ├── terraform-dev.yml        # PR + push pipeline for dev/general
    ├── terraform-dev-dynamo.yml # PR + push pipeline for dev/datastores
    └── drift.yml         # Daily drift detection
```

---

## 🗄️ Environment Layers

Each layer has its own S3 state file and can be planned, applied, and destroyed independently. The dependency order matters — see the `deploy` Makefile target.

| Layer | Contains | Depends on |
|---|---|---|
| `general` | VPC, EKS, LBC, access entries | nothing |
| `permissions` | IRSA roles, IAM policies | `general` (EKS OIDC) |
| `addons` | Karpenter, ESO, Reloader | `general` + `permissions` (ESO IRSA role) |
| `messaging` | SQS queues, DLQs, SSM params | nothing |
| `datastores` | DynamoDB, SSM params | nothing — managed separately, `prevent_destroy` |
| `dns` | Route 53 records, health checks, ACM cert (DR) | `general` (ALB DNS name) |

`datastores` is intentionally excluded from the `deploy` target. The DynamoDB table was created once and has `prevent_destroy = true` — it's never part of a routine deploy.

State is split across two S3 buckets — `jsp-test-tfstate` (us-east-2) and `jsp-test-tfstate-dr` (us-west-2) — so DR state survives a primary region outage.

---

## 📨 SQS Module

The `modules/sqs` module provisions queue + DLQ pairs via `for_each`. Adding a new queue requires one line in `terraform.tfvars` — no module code changes, no IAM policy changes.

```hcl
# messaging/terraform.tfvars
queues = {
  app-events    = {}                          # all defaults
  another-queue = { visibility_timeout = 60 }
}
```

The IRSA policy in `permissions` uses a wildcard ARN (`dev-*`) to cover all queues matching the prefix — so it never needs updating as queues are added.

---

## 🔑 Config Management — SSM + ESO + Reloader

App configuration (queue URLs, table names) is stored in SSM Parameter Store and injected into pods via External Secrets Operator. No config values are passed through GitHub Actions secrets or baked into deployment manifests.

```text
Terraform → SSM Parameter Store
              ↓ (sync every 1m)
         ESO → Kubernetes Secret (go-app-config)
                      ↓
              Pod (envFrom: secretRef)
                      ↑
         Reloader watches secret → rolling restart on change
```

ESO has its own IRSA role (`eso-irsa-dev`) with `ssm:GetParameter` on `/dev/app/*`. The app's IRSA role (`go-app-irsa-primary`) has access to DynamoDB, SQS, and SSM under the same path.

---

## 🗄️ DynamoDB Module

The `modules/dynamodb` module provisions a production-grade DynamoDB table with:

* **On-demand billing** (`PAY_PER_REQUEST`) — no capacity planning required
* **DynamoDB Streams** (`NEW_AND_OLD_IMAGES`) — captures item-level changes for event-driven consumers or auditing
* **Global replica** — cross-region replica provisioned automatically (configured per environment, e.g. `us-west-2`)
* **Deletion protection** — `prevent_destroy = true` guards against accidental `terraform destroy`

---

## 🔧 Bootstrap

The `/bootstrap` directory contains a **one-time setup** that must be run before any environment can deploy via CI/CD. It provisions the foundational AWS resources that the rest of the repo depends on:

| Resource | Purpose |
|---|---|
| `aws_iam_openid_connect_provider` | Registers GitHub Actions as a trusted OIDC identity provider in AWS |
| `aws_iam_role` (`github-actions-terraform`) | Role assumed by GitHub Actions workflows via OIDC — no static keys required |
| IAM policies | Grants the role permissions to manage infrastructure and read/write Terraform state |

### Running Bootstrap

Bootstrap is run **once** with local AWS credentials (not via CI/CD):

```bash
cd bootstrap
terraform init
terraform apply -var="github_org=<your-org>" -var="github_repo=<your-repo>"
```

The role ARN output from this step should be set as a GitHub Actions secret (`AWS_ROLE_ARN`) used by the environment workflows.

---

## 🚀 Key Engineering Features

### 🔐 Zero-Trust OIDC Authentication

* Eliminates long-lived IAM keys.
* Roles are scoped by GitHub "Subject" claims.
* Keyless, short-lived tokens generated dynamically per job.

### 🔍 Active Drift Detection

* Runs daily via cron against live AWS state.
* Uses `terraform plan -detailed-exitcode` to detect out-of-band changes.
* Surfaces results in the GitHub Actions job summary.

### 💰 Infracost Cost Estimation

* Runs automatically on every PR.
* Generates cost breakdowns for both `general` and `datastores` environments and combines them into a single composite estimate.
* Posts the combined total as a PR comment, updated in-place on each new push — no spam.

### 🛠️ Standardized CI/CD (Reusable Workflows)

* **`lint.yml`**: Auto-formats HCL with `terraform fmt`, runs `terraform validate` and `tflint`. Commits formatting fixes back to the branch automatically.
* **`infracost.yml`**: Reusable cost estimation — parameterized by environment so it can be called from any environment pipeline.
* DRY architecture ensures changes to shared workflows propagate automatically.

---

## 💡 Prerequisites

* Terraform CLI ≥ 1.7.0
* AWS CLI configured (optional for local testing)
* GitHub account for OIDC authentication
* `INFRACOST_API_KEY` secret set in GitHub repo settings (free at [infracost.io](https://www.infracost.io))

---

## 📖 Getting Started

### Local Development

A `Makefile` at the repo root wraps the common Terraform commands. Use `ENV` for the environment and `RESOURCE` for the layer.

```bash
make init    RESOURCE=general       # terraform init
make plan    RESOURCE=general       # terraform plan
make apply   RESOURCE=general       # terraform apply
make destroy RESOURCE=general       # terraform destroy

make apply   RESOURCE=permissions   # IRSA + app IAM policies
make apply   RESOURCE=messaging     # SQS queues
make apply   RESOURCE=addons        # Karpenter + ESO + Reloader — two-pass apply handled automatically
make apply   RESOURCE=datastores    # DynamoDB — run once, managed separately

# target a different environment
make apply ENV=prod RESOURCE=general

# DR environment
make deploy-dr   # general → permissions → addons → messaging (us-west-2)
make dns-dr      # ACM cert + SECONDARY Route 53 failover record
```

To deploy all layers in dependency order:

```bash
make deploy      # dev: general → permissions → addons → messaging
make deploy-dr   # DR:  general → permissions → addons → messaging
```

`ENV` defaults to `dev`, `RESOURCE` defaults to `general`.

---

### CI/CD Workflow

1. Open a Pull Request to `main`.
2. The pipeline runs automatically:
   - **Lint** — formats code, validates config, runs tflint
   - **Plan** — authenticates via OIDC and runs `terraform plan`
   - **Infracost** — posts a cost estimate comment on the PR
3. Merge to `main` triggers the same pipeline without the cost comment.
4. Drift detection runs daily and flags any changes made outside Terraform.

---

## 🚢 Application Deployment

This infrastructure is designed to host containerized Go applications on EKS. A reference deployment ([go-app](https://github.com/jspoth/go-app)) is used to validate the stack end-to-end.

### IAM Role for Service Accounts (IRSA)

All pod-level AWS access uses IRSA — no static credentials stored in the cluster. Two roles are provisioned in `permissions/`:

* **`go-app-irsa-primary`** — scoped to the `go-app-sa` service account. Grants DynamoDB CRUD, SQS send/receive/delete, and SSM read on `/dev/app/*`.
* **`eso-irsa-dev`** — scoped to the `external-secrets` service account. Grants SSM read on `/dev/app/*` so ESO can sync parameters into Kubernetes Secrets.

### Event-Driven Application Flow

```text
Go app (SqsQueueWriter, 1m tick)
    └── publishes JSON event → SQS (dev-app-events)
              └── Go app (StartConsumer, long-poll)
                      └── reads message → writes to DynamoDB → deletes message
```

Config values are injected at runtime via ESO — the deployment manifest uses `envFrom: secretRef` and contains no hardcoded config. Reloader triggers a rolling restart when ESO updates the secret.

### Deploying the Application

The go-app follows a two-stage deployment process in the [go-app](https://github.com/jspoth/go-app) repository.

#### Stage 1 — Build & Push (triggered on merge to `main`)

1. Authenticates to ECR via OIDC (no static AWS keys)
2. Builds the Docker image using GitHub Actions cache (`--cache-from=type=gha`) to speed up builds
3. Tags the image with the git SHA for traceability
4. Pushes to ECR

#### Stage 2 — Deploy to EKS (triggered manually via `workflow_dispatch`)

1. Authenticates to AWS via OIDC and updates kubeconfig for `dev-eks-cluster`
2. Substitutes image placeholders in the deployment manifest (ECR registry, image tag)
3. Applies all manifests including `ClusterSecretStore` and `ExternalSecret` for ESO
4. Confirms a healthy rollout with `kubectl rollout status deployment/go-app`

---

## ⚙️ Add-ons

* **Karpenter**: Dynamic node provisioning. NodePool constrained to `t` family, `small`/`medium`/`large` to avoid undersized nodes.
* **External Secrets Operator (ESO)**: Syncs SSM Parameter Store values into Kubernetes Secrets on a 1-minute interval.
* **Reloader**: Watches Kubernetes Secrets and triggers rolling pod restarts when they change.

---

## 🌎 Multi-Region Disaster Recovery

A pilot light DR environment runs in **us-west-2** with Route 53 automatic failover. Traffic shifts regions when the primary health check fails — no manual intervention required.

| Property | Value |
|---|---|
| DR strategy | Pilot light (EKS scales from 0 on cutover) |
| RTO (measured) | ~83 seconds |
| RPO | ~60 seconds (DynamoDB ticker interval) |
| Failover trigger | Route 53 health check — 3 consecutive failures at 30s intervals |
| Data replication | DynamoDB Global Tables — automatic cross-region sync |
| Messaging | SQS is regional — DR queue starts empty on cutover |
| State isolation | Separate S3 bucket in us-west-2 (`jsp-test-tfstate-dr`) |

### How failover works

```text
Route 53 polls app.jspoth.com:443/health/live every 30s
  → 3 failures (~61s) → health check turns Unhealthy
  → Route 53 stops routing to PRIMARY record (us-east-2 ALB)
  → traffic automatically shifts to SECONDARY record (us-west-2 ALB)
  → DR Cutover GHA workflow scales EKS node group + deployment to handle load
```

The DR environment mirrors the dev layer structure exactly. Terragrunt would eliminate the copy-paste at scale; at two environments the duplication is an acceptable tradeoff. Full DR documentation at [jspoth.com/dr](https://jspoth.com/dr.html).

---

## 🖼 Architecture Diagram (ASCII)

```text
           ┌─────────────┐
           │  GitHub PR  │
           └─────┬───────┘
                 │
                 ▼
        ┌────────────────┐
        │ GitHub Actions │
        │  lint / plan   │
        │  infracost     │
        └─────┬──────────┘
              │
     ┌────────┴─────────┐
     │ Terraform Apply   │
     │ (Modules + Env)   │
     └────────┬─────────┘
              │
   ┌──────────┴────────────────────────────────────────┐
   │                    Route 53                        │
   │  app.jspoth.com — failover routing                 │
   │  health check: :443/health/live every 30s          │
   └──────────┬──────────────────────┬─────────────────┘
              │ PRIMARY               │ SECONDARY (auto on failure)
              ▼                       ▼
   ┌─────────────────────┐  ┌─────────────────────────┐
   │   us-east-2 (dev)   │  │    us-west-2 (DR)        │
   │  VPC / EKS          │  │  VPC / EKS (pilot light) │
   │  Karpenter          │  │  Karpenter               │
   │  SQS / DynamoDB ────┼──┼──► Global Table replica  │
   │  SSM / IRSA         │  │  SSM / IRSA              │
   │  Go App (3 pods)    │  │  Go App (1 pod, scales)  │
   └─────────────────────┘  └─────────────────────────┘
```

---

## 📚 References

* Project write-up: [jspoth.com](https://jspoth.com)
* DR documentation: [jspoth.com/dr.html](https://jspoth.com/dr.html)
* Terraform docs: [https://developer.hashicorp.com/terraform](https://developer.hashicorp.com/terraform)
* AWS Terraform provider: [https://registry.terraform.io/providers/hashicorp/aws/latest/docs](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)
* External Secrets Operator: [https://external-secrets.io](https://external-secrets.io)
* Infracost docs: [https://www.infracost.io/docs/](https://www.infracost.io/docs/)
