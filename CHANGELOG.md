2026-04-05: Environment Refactor - Split dev into general & datastores
- Split flat environments/dev/ into environments/dev/general/ (VPC, EKS, LBC) and environments/dev/datastores/ (DynamoDB)
- Reused existing dev/terraform.tfstate for general to avoid state migration
- Added new isolated state file for datastores (dev/datastores/terraform.tfstate)
- Added variables.tf, outputs.tf, and terraform.tfvars to datastores environment
- Updated CI workflows: terraform-dev.yml targets general, terraform-dev-dynamo.yml targets datastores
- Updated Infracost workflow to run on both environments and post a combined cost estimate
- Fixed module source paths after directory restructure

2026-04-05: Bug Fixes & EKS Access
- Added EKS access entry and policy association for github-actions-terraform role to fix kubectl auth in CI
- Added elasticloadbalancing:DescribeListenerAttributes to LBC IAM policy (missing permission blocking ALB provisioning)
- Added before_compute = true to CoreDNS addon to fix LBC webhook ordering issue on fresh cluster apply
- Bumped Helm provider to ~> 3.1 and updated provider syntax
- Added DynamoDB range_key and timestamp attribute
- Added dev-dynamo environment workspace to isolate DynamoDB from EKS destroy lifecycle

2026-04-04: AWS Load Balancer Controller Module
- Added AWS Load Balancer Controller Terraform module
- Added IRSA role and IAM policy for LBC
- Added Helm release resource for LBC deployment
- Made region configurable via variable (DR-ready)

2026-04-03: Documentation & Cleanup
- Added and iteratively improved README
- General cleanup and formatting

2026-04-02: Cost Estimation
- Integrated Infracost into CI pipeline for pull request cost visibility
- Added Infracost configuration and GitHub Actions workflow step

2026-04-02: DynamoDB Module
- Added DynamoDB Terraform module
- Added supporting HCL variable and output files

2026-03-20: Drift Detection
- Added scheduled drift detection GitHub Actions workflow
- Configured workflow to extract, analyze, and alert on infrastructure drift
- Improved drift output handling and secrets management

2026-03-20: Code Quality & Linting
- Added Terraform linter (`tflint`) to CI workflow
- Added auto-formatting checks
- Fixed various lint and syntax issues

2026-03-05: CI/CD Pipeline
- Added GitHub Actions workflow for Terraform plan/apply
- Set up remote state bootstrapping (S3 + DynamoDB locking)
- Configured IAM roles and permissions for CI
- Added `tfvars` support for CI environment targeting
- Scoped to `us-east-2` region

2026-02-26: Infrastructure Foundations
- Initial Terraform project setup with modular structure
- Added EKS cluster module with working configuration
- Added VPC module with environment-based networking
- Added Karpenter module for node autoscaling
- Configured providers and namespace resources
