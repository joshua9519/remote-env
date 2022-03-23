/**
* # Remote developement environment
*
* This module creates an OS Login-enabled VM instance that can be used as a
* remote environment for VSCode.
*
* In order to use this VM instance as a remote environment, run the following commands:
* ```
* terraform show -json | jq -r '.values.root_module.resources[] | select(.address=="tls_private_key.dev") | .values.public_key_openssh' > ~/.ssh/remote_dev.pub
* terraform show -json | jq -r '.values.root_module.resources[] | select(.address=="tls_private_key.dev") | .values.private_key_pem' > ~/.ssh/remote_dev
* terraform output -raw ssh_config >> ~/.ssh/config
*
*/

terraform {
  backend "gcs" {
    bucket = "josh-hill-pf-1-tfstate"
    prefix = "remote-env"
  }

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "4.14.0"
    }
    tls = {
      source  = "hashicorp/tls"
      version = "3.1.0"
    }
  }
}

provider "google" {
  project = var.project_id
}

locals {
  zone = "${var.region}-b"
}

data "google_client_openid_userinfo" "me" {}

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

resource "google_compute_disk" "default" {
  name = "docker-data"
  type = "pd-ssd"
  zone = local.zone
  size = 50
}

resource "google_compute_instance" "vm" {
  name                      = "remote-dev"
  machine_type              = "e2-standard-2"
  zone                      = local.zone
  allow_stopping_for_update = true

  boot_disk {
    initialize_params {
      image = "debian-10"
    }
  }

  attached_disk {
    source      = google_compute_disk.default.id
    device_name = "docker"
  }

  network_interface {
    subnetwork = google_compute_subnetwork.default.self_link
  }

  tags = ["remote-dev"]

  metadata_startup_script = <<EOF
mkfs.ext4 -m 0 -E lazy_itable_init=0,lazy_journal_init=0,discard /dev/sdb
mkdir -p /var/lib/docker
mount -o discard,defaults /dev/sdb /var/lib/docker
uuid=$(blkid -s UUID -o value /dev/sdb)
echo "UUID=$uuid /var/lib/docker ext4 discard,defaults,nofail 0 2" >> /etc/fstab
 
apt update
apt install -y ca-certificates curl gnupg lsb-release
curl -fsSL https://download.docker.com/linux/debian/gpg | gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/debian \
  $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
apt update
apt install -y docker-ce docker-ce-cli containerd.io

git config --global user.email "${data.google_client_openid_userinfo.me.email}"
git config --global user.name "${var.git_name}"
EOF

  metadata = {
    google-logging-enabled    = "true"
    google-monitoring-enabled = "true"
    enable-oslogin            = "TRUE"
  }

  service_account {
    email = var.service_account
    scopes = [
      "https://www.googleapis.com/auth/cloud-platform",
    ]
  }
}

resource "google_compute_instance_iam_member" "os_login" {
  instance_name = google_compute_instance.vm.name
  zone          = local.zone
  role          = "roles/compute.osAdminLogin"
  member        = "user:${data.google_client_openid_userinfo.me.email}"
}

resource "tls_private_key" "dev" {
  algorithm = "RSA"
  rsa_bits  = "4096"
}

resource "google_os_login_ssh_public_key" "dev" {
  user = data.google_client_openid_userinfo.me.email
  key  = tls_private_key.dev.public_key_openssh
}

# iap firewall
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

output "ssh_config" {
  value = <<EOF
Host remote-dev
  ForwardAgent yes
  User ext_josh_hill_cts_co
  IdentityFile ~/.ssh/remote_dev
  CheckHostIP no
  HashKnownHosts no
  IdentitiesOnly yes
  StrictHostKeyChecking no
  UserKnownHostsFile ~/.ssh/remote_dev_known_hosts
  ProxyCommand /usr/bin/python3 -S ~/google-cloud-sdk/lib/gcloud.py compute start-iap-tunnel remote-dev %p --listen-on-stdin --project=${var.project_id} --zone=${local.zone} --verbosity=warning
  ProxyUseFdpass no
EOF
}
