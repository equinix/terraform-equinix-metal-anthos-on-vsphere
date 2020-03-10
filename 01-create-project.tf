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

