output "cluster_name" {
  description = "GKE cluster name."
  value       = google_container_cluster.primary.name
}

output "cluster_region" {
  description = "GKE region."
  value       = google_container_cluster.primary.location
}

output "network_name" {
  description = "VPC network name."
  value       = google_compute_network.gke.name
}

output "connect_command" {
  description = "Command to add the cluster to the current kubeconfig."
  value       = "gcloud container clusters get-credentials ${google_container_cluster.primary.name} --region ${google_container_cluster.primary.location} --project ${var.project_id}"
}
