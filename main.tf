terraform {
  required_providers {
    packet = {
      source  = "packethost/packet"
      version = "~> 3.0.1"
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

provider "packet" {
  auth_token = var.auth_token
}

