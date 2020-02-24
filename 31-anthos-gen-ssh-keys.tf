resource "tls_private_key" "anthos_ssh_key" {
  count = var.anthos_deploy_worksation_prereqs ? 1 : 0
  algorithm = "RSA"
  rsa_bits = 4096
}

resource "local_file" "anthos_priv_key" {
    count = var.anthos_deploy_worksation_prereqs ? 1 : 0
    content = chomp(tls_private_key.anthos_ssh_key.private_key_pem)
    filename = "anthos_ssh_priv_key"
    file_permission = "0600"
}

