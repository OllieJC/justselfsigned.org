terraform {
  required_providers {
    google = {
      source = "hashicorp/google"
      version = "4.45.0"
    }
  }
}

provider "google" {
  # credentials = file("justselfsigned-org-4ebae1f1eef1.json")
  project = "justselfsigned-org"
  region  = "europe-west2"
  zone    = "europe-west2-a"
}
