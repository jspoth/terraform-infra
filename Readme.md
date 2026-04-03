## 🏗️ Architectural Overview

The repository follows a **Decoupled Root Module** pattern to balance reusability with environment stability.

* **`/modules`**: Source of truth for infrastructure components (VPC, EKS, DynamoDB, Karpenter). Versioned and reusable across environments.
* **`/environments`**: Contains live state definitions per environment. Each environment maintains its own S3 backend and DynamoDB state lock.
* **`.github/workflows`**: The "Control Plane" of the repo. Uses **Reusable Workflows** to standardize CI/CD across all environments.

---

## 🗂 Repository Structure

```text
terraform-infra/
├── modules/
│   ├── vpc/              # VPC, subnets, NAT gateway, route tables
│   ├── eks/              # EKS cluster, managed node groups, addons
│   ├── dynamodb/         # DynamoDB table with global replica + stream
│   └── karpenter/        # Karpenter node autoscaler (optional)
├── environments/
│   └── dev/              # Development environment configs
├── bootstrap/            # One-time IAM/OIDC + S3 backend setup
└── .github/workflows/
    ├── lint.yml          # Reusable: fmt, validate, tflint
    ├── infracost.yml     # Reusable: cost estimation on PRs
    ├── terraform-dev.yml # PR + push pipeline for dev
    └── drift.yml         # Daily drift detection
```

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
* Generates a cost breakdown from the Terraform plan and posts it as a PR comment.
* Comment is updated in-place on each new push — no spam.

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

1. Navigate to the environment:

```bash
cd environments/dev
```

2. Initialize Terraform:

```bash
terraform init
```

3. Preview changes:

```bash
terraform plan -out=tfplan.binary
```

4. Apply changes:

```bash
terraform apply tfplan.binary
```

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

To allow pods to access AWS resources without static credentials, an IAM role (`go-app-irsa-primary`) is provisioned with a trust policy scoped to the `go-app-sa` Kubernetes service account in the `default` namespace.

The role grants the application least-privilege access to DynamoDB:

* `GetItem`, `PutItem`, `DeleteItem`, `BatchGetItem`, `BatchWriteItem` — standard CRUD
* `Scan`, `Query` — read operations
* `UpdateTable` — for schema/TTL changes

The Kubernetes `ServiceAccount` is annotated with the role ARN:

```yaml
eks.amazonaws.com/role-arn: arn:aws:iam::<account-id>:role/go-app-irsa-primary
```

AWS injects short-lived credentials into the pod automatically — no IAM keys stored in the cluster.

### Deploying the Application

The go-app follows a two-stage deployment process, each handled by a separate GitHub Actions workflow in the [go-app](https://github.com/jspoth/go-app) repository.

#### Stage 1 — Build & Push (triggered on merge to `main`)

1. Authenticates to ECR via OIDC (no static AWS keys)
2. Builds the Docker image using GitHub Actions cache (`--cache-from=type=gha`) to speed up builds
3. Tags the image with the git SHA for traceability
4. Pushes to ECR

#### Stage 2 — Deploy to EKS (triggered manually via `workflow_dispatch`)

The deploy workflow is intentionally manual — the git SHA of the image to deploy is passed as an input, giving full control over which version is rolled out.

1. Authenticates to AWS via OIDC and updates kubeconfig for `dev-eks-cluster`
2. Substitutes placeholders in the Kubernetes manifests (ECR registry, image tag, DynamoDB table, account ID)
3. Runs `kubectl apply -f k8s/`
4. Confirms a healthy rollout with `kubectl rollout status deployment/go-app`

#### End-to-End Flow

```text
PR opened
    └── CI: go fmt + golangci-lint

Merge to main
    └── deploy.yml: Build image → tag with git SHA → push to ECR

Manual trigger (workflow_dispatch)
    └── k8s-deploy.yml: Pull image by SHA → apply manifests → rollout status
```

---

## ⚙️ Optional Add-ons

* **Karpenter**: Dynamic EKS node provisioning (module present, disabled in dev)
* **Security Scanning (Checkov)**: Add a "Security" job to the reusable lint workflow to catch misconfigured security groups or unencrypted secrets before they reach AWS.

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
   ┌──────────┴────────────┐
   │       AWS Infra        │
   │  VPC / Subnets / EKS   │
   │  DynamoDB / IAM        │
   └────────────────────────┘
```

---

## 📚 References

* Terraform docs: [https://developer.hashicorp.com/terraform](https://developer.hashicorp.com/terraform)
* AWS Terraform provider: [https://registry.terraform.io/providers/hashicorp/aws/latest/docs](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)
* Infracost docs: [https://www.infracost.io/docs/](https://www.infracost.io/docs/)
