# Infrastructure Setup Overview
## 1️⃣ Setup S3 + DynamoDB for Terraform Remote State

### 🔹 Purpose
Configure remote state management to enable safe, collaborative infrastructure deployments.
### 🔹 Components
* **S3 Bucket**
  * Stores the Terraform state file remotely
* **DynamoDB Table**
  * Provides state locking to prevent concurrent modifications

### 🔹 Prevents
* Concurrent `terraform apply`
* State corruption
* Accidental overwrites

### 🔹 Enables
* Team collaboration
* Safe CI/CD execution
* Centralized state management

---

## 2️⃣ Setup VPC & Subnets (Prerequisite for EKS)

### 🔹 Purpose
Provision networking infrastructure required for deploying Amazon EKS.

### 🔹 Requirements
* VPC
* Subnets (across multiple Availability Zones)
* Security Groups

### 🔹 Key Notes
* Worker nodes must reside in subnets
* Pods receive IP addresses from the VPC (via AWS CNI plugin)

---

## 3 Setup karpenter

### Purpose
Eliminate the need for static Auto Scaling Groups (ASGs) by implementing just-in-time, pod-aware node provisioning. Karpenter observes unschedulable pods and launches the most optimal EC2 instance (size, type, and billing model) to meet their requirements.

### 🔹 Components
* Karpenter Controller: Runs as a pod in the kube-system or karpenter namespace.
* EC2NodeClass: AWS-specific configuration (Subnets, Security Groups, AMIs, and IAM Roles).
* NodePool: The logic layer that defines which instance types and zones Karpenter is allowed to use.
* SQS & EventBridge: Handles "Spot Interruption" notices to gracefully drain nodes before AWS reclaims them.

### 🔹 Key Advantages
* Cost Efficiency: Automatically prioritizes EC2 Spot Instances with a 70-90% discount over On-Demand.
* Performance: Launches new nodes in milliseconds vs minutes for traditional ASGs.
* Bin-packing: Consolidates workloads onto fewer nodes to minimize "wasted" CPU/RAM.

---

