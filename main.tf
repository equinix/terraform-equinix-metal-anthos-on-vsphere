terraform {
  required_providers {
    packet = "~> 2.10.1"
  }
}

provider "packet" {
  auth_token = var.auth_token
}

