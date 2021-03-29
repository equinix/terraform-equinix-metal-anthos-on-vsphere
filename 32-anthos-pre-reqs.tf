data "template_file" "anthos_pre_reqs_script" {
  template = file("anthos/pre_reqs.sh")
  vars = {
    anthos_version       = var.anthos_version
    whitelisted_key_name = var.whitelisted_key_name
    vcenter_fqdn         = format("vcva.%s", var.domain_name)
  }
}

resource "null_resource" "anthos_pre_reqs" {
  count      = var.anthos_deploy_workstation_prereqs ? 1 : 0
  depends_on = [module.vsphere]
  connection {
    type        = "ssh"
    user        = "root"
    private_key = file(module.vsphere.ssh_key_path)
    host        = module.vsphere.bastion_host
  }


  provisioner "file" {
    content     = chomp(tls_private_key.anthos_ssh_key.private_key_pem)
    destination = "/root/anthos/ssh_key"
  }

  provisioner "file" {
    content     = chomp(tls_private_key.anthos_ssh_key.public_key_openssh)
    destination = "/root/anthos/ssh_key.pub"
  }

  provisioner "file" {
    content     = data.template_file.anthos_pre_reqs_script.rendered
    destination = "/root/anthos/pre_reqs.sh"
  }

  provisioner "remote-exec" {
    inline = [
      "cd /root/anthos",
      "chmod 0400 /root/anthos/ssh_key",
      "chmod +x /root/anthos/pre_reqs.sh",
      "/root/anthos/pre_reqs.sh"
    ]
  }
}

