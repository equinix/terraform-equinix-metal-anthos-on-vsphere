terraform {
  required_providers {
    metal = {
      source  = "equinix/metal"
      version = "~> 2.0"
    }
    local = {
      source = "hashicorp/local"
    }
    null = {
      source = "hashicorp/null"
    }
    random = {
      source = "hashicorp/random"
    }
    template = {
      source = "hashicorp/template"
    }
    tls = {
      source = "hashicorp/tls"
    }
  }
}

provider "metal" {
  auth_token = var.auth_token
}

