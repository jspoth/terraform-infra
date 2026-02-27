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

