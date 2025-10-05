output "gcp_instance_ip" {
  value       = google_compute_instance.gcp1.network_interface[0].access_config[0].nat_ip
  description = "Public IP address of the GCP instance"
}

output "gcp_instance_name" {
  value       = google_compute_instance.gcp1.name
  description = "Name of the GCP instance"
}

output "gcp_instance_zone" {
  value       = google_compute_instance.gcp1.zone
  description = "Zone where the GCP instance is deployed"
}

