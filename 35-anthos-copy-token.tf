resource "null_resource" "anthos_copy_token" {
  count      = var.anthos_deploy_workstation_prereqs ? 1 : 0
  depends_on = [null_resource.anthos_deploy_cluster]

  provisioner "local-exec" {
    command = "scp -i ${module.vsphere.ssh_key_path} -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null  root@${module.vsphere.bastion_host}:/root/anthos/ksa_token.txt ."

  }
}


