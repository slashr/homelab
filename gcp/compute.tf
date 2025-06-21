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
    "ssh-keys" = <<EOT
      dev:ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJ5Ysv6PF3HbWQ/JfP2vWEBHtH8wPv6ysbyosEREXpO3 dev
     EOT
  }

  network_interface {
    network = "default"

    access_config {
      // Ephemeral public IP
    }
  }
}
