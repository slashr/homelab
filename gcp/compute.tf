resource "google_compute_instance" "gcp1" {
  name         = "gcp1"
  machine_type = var.machine_type
  zone         = var.zone

  boot_disk {
    initialize_params {
      image = "ubuntu-os-cloud/ubuntu-2204-lts"
      size  = 30
      type  = "pd-standard"
    }
  }

  metadata = {
    "ssh-keys" = "${var.ssh_username}:${var.ssh_public_key} ${var.ssh_username}"
  }

  network_interface {
    network = "default"
    
    access_config {
      // Ephemeral public IP - required for initial Tailscale setup
      // Will be removed after Tailscale is configured
    }
  }
}
