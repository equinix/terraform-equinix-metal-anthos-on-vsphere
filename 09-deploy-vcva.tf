data "template_file" "deploy_vcva_script" {
  template = file("templates/deploy_vcva.py")
  vars = {
    private_subnets = jsonencode(var.private_subnets)
    vcenter_network = var.vcenter_portgroup_name
    esx_passwords   = jsonencode(packet_device.esxi_hosts.*.root_password)
    dc_name         = var.vcenter_datacenter_name
    sso_password    = random_string.sso_password.result
    cluster_name    = var.vcenter_cluster_name
  }
}

data "template_file" "claim_vsan_disks" {
  template = file("templates/vsan_claim.py")
  vars = {
    vcenter_fqdn = format("vcva.%s", var.domain_name)
    vcenter_user = "Administrator@vsphere.local"
    vcenter_pass = random_string.sso_password.result
  }
}

resource "null_resource" "deploy_vcva" {
  depends_on = [
    null_resource.apply_esx_network_config,
    null_resource.download_vcenter_iso
  ]
  connection {
    type        = "ssh"
    user        = "root"
    private_key = file("~/.ssh/${local.ssh_key_name}")
    host        = packet_device.router.access_public_ipv4
  }

  provisioner "file" {
    content     = data.template_file.claim_vsan_disks.rendered
    destination = "/root/vsan_claim.py"
  }

  provisioner "file" {
    content     = data.template_file.deploy_vcva_script.rendered
    destination = "/root/deploy_vcva.py"
  }

  provisioner "file" {
    source      = "templates/extend_datastore.sh"
    destination = "/root/extend_datastore.sh"
  }

  provisioner "remote-exec" {
    inline = [
      "python3 /root/deploy_vcva.py",
      "sleep 60",
    ]
  }
}


resource "null_resource" "vsan_claim" {
  depends_on = [null_resource.deploy_vcva]
  count      = var.esxi_host_count == 1 ? 0 : 1
  connection {
    type        = "ssh"
    user        = "root"
    private_key = file("~/.ssh/${local.ssh_key_name}")
    host        = packet_device.router.access_public_ipv4
  }

  provisioner "remote-exec" {
    inline = [
      "python3 /root/vsan_claim.py",
      "sleep 90"
    ]
  }
}
