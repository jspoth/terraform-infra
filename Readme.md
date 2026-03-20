## 🏗️ Architectural Overview

The repository follows a **Decoupled Root Module** pattern to balance reusability with environment stability.

* **`/modules`**: Source of truth for infrastructure components (VPC, EKS, IAM). Versioned and reusable across environments.
* **`/environments`**: Contains live state definitions for `dev` and `prod`. Each environment maintains its own S3 backend and DynamoDB state lock.
* **`.github/workflows`**: The "Control Plane" of the repo. Uses **Reusable Workflows** to standardize CI/CD across all environments.

---

## 🗂 Repository Structure

```text
terraform-infra/
├── modules/              # Reusable infrastructure modules (VPC, EKS, IAM, etc.)
├── environments/
│   ├── dev/              # Development environment configs
│   └── prod/             # Production environment configs
├── .github/workflows/    # Reusable CI/CD workflows
└── README.md
```

---

## 🚀 Key Engineering Features

### 🔐 Zero-Trust OIDC Authentication

* Eliminates long-lived IAM keys.
* Roles are scoped by GitHub "Subject" claims.
* Keyless, short-lived tokens generated dynamically per job.

### 🔍 Active Drift Detection

* Detects out-of-band changes in AWS.
* Uses raw Terraform exit codes for accurate drift alerts.

### 🛠️ Standardized CI/CD (Reusable Workflows)

* Centralized workflows for Linting, Validation, and Costing.
* DRY architecture ensures changes propagate automatically across environments.

---

## 💡 Prerequisites

* Terraform CLI ≥ 1.7.0
* AWS CLI configured (optional for local testing)
* GitHub account for OIDC authentication
* Optional: Infracost CLI for local cost estimation

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
2. Check **GitHub Actions Summary** for drift alerts.
3. Merge to trigger automated deployment.

---

## ⚙️ Optional Add-ons

* **Karpenter**: Dynamic EKS node provisioning
* **CloudWatch Logging**: Centralized cluster logs
* **S3 Logging Buckets**: Store app logs and artifacts
* **Infracost**: Provides immediate visibility into financial impact of changes.
* **Security Scanning (Checkov)**: Add a "Security" job to your reusable workflow to catch misconfigured Security Groups or unencrypted EKS secrets before they reach AWS.

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
        │  CI/CD Control │
        └─────┬──────────┘
              │
     ┌────────┴─────────┐
     │ Terraform Apply   │
     │ (Modules + Env)   │
     └────────┬─────────┘
              │
   ┌──────────┴───────────┐
   │      AWS Infra        │
   │ VPC / Subnets / EKS   │
   │ IAM / Logging / Add-ons│
   └───────────────────────┘
```

---

## 📚 References

* Terraform docs: [https://developer.hashicorp.com/terraform](https://developer.hashicorp.com/terraform)
* AWS Terraform provider: [https://registry.terraform.io/providers/hashicorp/aws/latest/docs](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)
* Infracost docs: [https://www.infracost.io/docs/](https://www.infracost.io/docs/)

