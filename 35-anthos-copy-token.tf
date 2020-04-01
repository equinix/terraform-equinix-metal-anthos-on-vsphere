resource "null_resource" "anthos_copy_token" {
  count      = var.anthos_deploy_workstation_prereqs ? 1 : 0
  depends_on = [null_resource.anthos_deploy_cluster]

  provisioner "local-exec" {
    command = "scp -i ~/.ssh/${local.ssh_key_name} -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null  root@${packet_device.router.access_public_ipv4}:/root/anthos/ksa_token.txt ."

  }
}


