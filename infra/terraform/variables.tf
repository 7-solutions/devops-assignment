variable "project_id" {
  description = "Existing Google Cloud project ID."
  type        = string
}

variable "region" {
  description = "Region for the regional GKE control plane and VPC resources."
  type        = string
  default     = "asia-southeast1"
}

variable "cluster_name" {
  description = "GKE cluster name."
  type        = string
  default     = "devops-assignment"
}

variable "node_locations" {
  description = "Optional zones for the regional node pool. Empty uses GKE's regional defaults."
  type        = list(string)
  default     = []
}

variable "master_authorized_cidrs" {
  description = "CIDR ranges allowed to reach the public Kubernetes control-plane endpoint. Use your current public IP /32."
  type = list(object({
    display_name = string
    cidr_block   = string
  }))

  validation {
    condition     = length(var.master_authorized_cidrs) > 0
    error_message = "Set at least one trusted control-plane CIDR; do not expose the endpoint to 0.0.0.0/0."
  }
}

variable "pod_cidr" {
  description = "Secondary VPC range used for GKE Pods."
  type        = string
  default     = "10.10.0.0/16"
}

variable "service_cidr" {
  description = "Secondary VPC range used for GKE Services."
  type        = string
  default     = "10.20.0.0/20"
}

variable "machine_type" {
  description = "Machine type for the autoscaled GKE node pool."
  type        = string
  default     = "e2-standard-2"
}

variable "min_nodes_per_zone" {
  description = "Minimum nodes in each configured node-pool zone."
  type        = number
  default     = 1
}

variable "max_nodes_per_zone" {
  description = "Maximum nodes in each configured node-pool zone."
  type        = number
  default     = 4
}
