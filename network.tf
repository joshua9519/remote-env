resource "google_compute_network" "default" {
  name                    = "remote-dev"
  auto_create_subnetworks = false
}

resource "google_compute_subnetwork" "default" {
  name          = var.region
  ip_cidr_range = "10.0.0.0/16"
  region        = var.region
  network       = google_compute_network.default.id
}

module "cloud-nat" {
  source        = "terraform-google-modules/cloud-nat/google"
  version       = "~> 1.2"
  project_id    = var.project_id
  region        = var.region
  create_router = true
  router        = "remote-dev"
  name          = "remote-dev"
  network       = google_compute_network.default.id
}

resource "google_compute_firewall" "iap" {
  name    = "iap-ssh"
  network = google_compute_network.default.name

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }

  source_ranges = ["35.235.240.0/20"]
  target_tags   = ["remote-dev"]
}
