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
