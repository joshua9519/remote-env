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