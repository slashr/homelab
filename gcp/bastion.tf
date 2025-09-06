# Bastion host for secure access to private instances
resource "google_compute_instance" "bastion" {
  name         = "bastion"
  machine_type = "e2-micro"
  zone         = var.zone

  boot_disk {
    initialize_params {
      image = "ubuntu-os-cloud/ubuntu-2204-lts"
      size  = 10
      type  = "pd-standard"
    }
  }

  metadata = {
    "ssh-keys" = "${var.ssh_username}:${var.ssh_public_key} ${var.ssh_username}"
  }

  network_interface {
    network = "default"
    
    access_config {
      // Bastion has public IP for access
    }
  }

  tags = ["bastion"]
}

# Firewall rule to allow SSH to bastion
resource "google_compute_firewall" "bastion_ssh" {
  name    = "bastion-ssh"
  network = "default"

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }

  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["bastion"]
}
