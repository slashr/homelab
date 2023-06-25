resource "google_compute_instance" "gcp1" {
  name         = "gcp1"
  machine_type = "e2-micro"
  zone         = "us-central1-c"
  cpu_platform = "AMD Rome"

  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-11"
      size  = 30
      type  = "pd-standard"
    }
  }

  network_interface {
    network = "default"

    access_config {
      // Ephemeral public IP
    }
  }

  service_account {
    # Google recommends custom service accounts that have cloud-platform scope and permissions granted via IAM Roles.
    email  = google_service_account.default.email
    scopes = ["cloud-platform"]
  }
}
