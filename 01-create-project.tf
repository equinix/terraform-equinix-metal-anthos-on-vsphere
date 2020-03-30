locals {
  timestamp           = "${timestamp()}"
  timestamp_sanitized = "${replace("${local.timestamp}", "/[-| |T|Z|:]/", "")}"

}

provider "packet" {
  auth_token = var.auth_token
}

resource "packet_project" "new_project" {
  name            = var.project_name
  organization_id = var.organization_id

}


resource "tls_private_key" "ssh_key_pair" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "packet_project_ssh_key" "ssh_pub_key" {
  depends_on = [packet_project.new_project]
  project_id = packet_project.new_project.id
  name       = var.project_name
  public_key = chomp(tls_private_key.ssh_key_pair.public_key_openssh)
}

resource "local_file" "project_private_key_pem" {
  content         = chomp(tls_private_key.ssh_key_pair.private_key_pem)
  filename        = pathexpand("~/.ssh/${var.project_name}-${local.timestamp_sanitized}-key")
  file_permission = "0600"

  provisioner "local-exec" {
    command = "cp ~/.ssh/${var.project_name}-${local.timestamp_sanitized}-key ~/.ssh/${var.project_name}-${local.timestamp_sanitized}-key.bak"
  }
}


