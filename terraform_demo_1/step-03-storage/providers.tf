terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = ">= 7.7.0"
    }
  }
  required_version = ">= 1.13.0"
}

provider "google" {
  project     = var.project_id
  region      = var.region
  credentials = file(var.credentials_file)
}
