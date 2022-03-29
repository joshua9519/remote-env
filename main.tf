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
locals {
  zone  = "${var.region}-b"
  email = data.google_client_openid_userinfo.me.email
  vm_iam = {
    "os_login" = {
      role   = "compute.osAdminLogin"
      member = "user:${local.email}"
    }
    "instance_admin" = {
      role   = "compute.instanceAdmin.v1"
      member = "serviceAccount:service-${data.google_project.default.number}@compute-system.iam.gserviceaccount.com"
    }
  }
}

data "google_client_openid_userinfo" "me" {}
data "google_project" "default" {
  project_id = var.project_id
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
    auto_delete = false
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

git config --system user.email "${local.email}"
git config --system user.name "${var.git_name}"

sysctl -w fs.inotify.max_user_watches=524288
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
      "https://www.googleapis.com/auth/userinfo.email"
    ]
  }

  resource_policies = [google_compute_resource_policy.vm.self_link]
}

resource "google_compute_resource_policy" "vm" {
  name        = "start-stop"
  region      = var.region
  description = "Start and stop remote dev instance at night"
  instance_schedule_policy {
    vm_start_schedule {
      schedule = "0 8 * * 1-5"
    }
    vm_stop_schedule {
      schedule = "0 18 * * 1-5"
    }
    time_zone = "Europe/London"
  }
}

resource "google_compute_instance_iam_member" "vm" {
  for_each      = local.vm_iam
  instance_name = google_compute_instance.vm.name
  zone          = local.zone
  role          = "roles/${each.value.role}"
  member        = each.value.member
}

resource "tls_private_key" "dev" {
  algorithm = "RSA"
  rsa_bits  = "4096"
}

resource "google_os_login_ssh_public_key" "dev" {
  user = local.email
  key  = tls_private_key.dev.public_key_openssh
}
