data "template_file" "anthos_workstation_tf_vars" {
  template = file("anthos/static-ip.tfvars")
  vars = {
    vcenter_username = "Administrator@vsphere.local"
    vcenter_password = module.vsphere.vcenter_password
    vcenter_fqdn     = format("vcva.%s", var.domain_name)

    vsphere_datastore     = var.anthos_datastore
    vsphere_datacenter    = var.vcenter_datacenter_name
    vsphere_cluster       = var.vcenter_cluster_name
    vsphere_resource_pool = var.anthos_resource_pool_name
    vsphere_network       = format("%s Net", var.vcenter_portgroup_name)
    anthos_version        = var.anthos_version
  }
}

data "template_file" "anthos_upload_ova_template" {
  template = file("anthos/upload_ova.sh")
  vars = {
    anthos_version       = var.anthos_version
    vmware_fqdn          = format("vcva.%s", var.domain_name)
    vmware_username      = "Administrator@vsphere.local"
    vmware_password      = module.vsphere.vcenter_password
    vmware_datastore     = var.anthos_datastore
    vmware_resource_pool = var.anthos_resource_pool_name
  }
}

data "template_file" "anthos_replace_ws_vars" {
  template = file("anthos/replace_ws_vars.py")
  vars = {
    private_subnets = jsonencode(var.private_subnets)
    vsphere_network = var.vcenter_portgroup_name
    domain_name     = var.domain_name
  }
}

data "template_file" "anthos_workstation_config_yaml" {
  template = file("anthos/admin-ws-config.yaml")
  vars = {
    vcenter_username      = "Administrator@vsphere.local"
    vcenter_password      = module.vsphere.vcenter_password
    vcenter_fqdn          = format("vcva.%s", var.domain_name)
    vsphere_datastore     = var.anthos_datastore
    vsphere_datacenter    = var.vcenter_datacenter_name
    vsphere_cluster       = var.vcenter_cluster_name
    vsphere_resource_pool = var.anthos_resource_pool_name
    vsphere_network       = format("%s Net", var.vcenter_portgroup_name)
    whitelisted_key_name  = var.whitelisted_key_name
  }
}


data "template_file" "anthos_deploy_admin_ws_sh" {
  template = file("anthos/deploy_admin_ws.sh")
  vars = {
    vcenter_fqdn = format("vcva.%s", var.domain_name)
  }
}

resource "null_resource" "anthos_deploy_workstation" {
  count      = var.anthos_deploy_workstation_prereqs ? 1 : 0
  depends_on = [module.vsphere]
  connection {
    type        = "ssh"
    user        = "root"
    private_key = file(module.vsphere.ssh_key_path)
    host        = module.vsphere.bastion_host
  }

  provisioner "file" {
    content     = data.template_file.anthos_upload_ova_template.rendered
    destination = "/root/anthos/upload_ova.sh"
  }

  provisioner "file" {
    content     = file("anthos/static-ip.tf")
    destination = "/root/anthos/static-ip.tf"
  }

  provisioner "file" {
    content     = data.template_file.anthos_workstation_tf_vars.rendered
    destination = "/root/anthos/terraform.tfvars"
  }

  provisioner "file" {
    content     = data.template_file.anthos_replace_ws_vars.rendered
    destination = "/root/anthos/replace_ws_vars.py"
  }

  provisioner "file" {
    content     = data.template_file.anthos_workstation_config_yaml.rendered
    destination = "/root/anthos/admin-ws-config.yaml"
  }

  provisioner "file" {
    content     = data.template_file.anthos_deploy_admin_ws_sh.rendered
    destination = "/root/anthos/deploy_admin_ws.sh"
  }

  provisioner "remote-exec" {
    inline = [
      "cd /root/anthos/",
      "chmod +x /root/anthos/upload_ova.sh",
      "/root/anthos/upload_ova.sh",
      "python3 /root/anthos/replace_ws_vars.py",
      "chmod +x /root/anthos/deploy_admin_ws.sh",
      "/root/anthos/deploy_admin_ws.sh"
    ]
  }
}
