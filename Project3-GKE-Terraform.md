## Project 3: GKE Cluster Using Terraform

This project provisions a single Google Kubernetes Engine (GKE) cluster using Terraform.

### Prerequisites
- Terraform >= 1.3
- A GCP project with billing enabled
- gcloud authenticated (`gcloud auth application-default login`)

### Files
- `terraform-gke/versions.tf`: Terraform and provider requirements
- `terraform-gke/providers.tf`: Google provider configuration
- `terraform-gke/variables.tf`: Input variables
- `terraform-gke/main.tf`: GKE cluster + node pool
- `terraform-gke/outputs.tf`: Outputs
- `terraform-gke/terraform.tfvars`: Environment-specific values

### Usage
Update `terraform.tfvars` with your project values before running Terraform.

```bash
cd terraform-gke
terraform init
terraform plan
terraform apply
```

### Clean up
```bash
terraform destroy
```
