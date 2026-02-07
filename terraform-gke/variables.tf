variable "project_id" {
  description = "GCP project ID to host the cluster."
  type        = string
}

variable "region" {
  description = "GCP region for the cluster resources."
  type        = string
  default     = "us-central1"
}

variable "zone" {
  description = "GCP zone for the cluster control plane."
  type        = string
  default     = "us-central1-c"
}

variable "cluster_name" {
  description = "Name of the GKE cluster."
  type        = string
  default     = "demo-gke-cluster"
}

variable "node_count" {
  description = "Number of nodes in the default node pool."
  type        = number
  default     = 2
}

variable "machine_type" {
  description = "Machine type for the default node pool."
  type        = string
  default     = "e2-medium"
}
