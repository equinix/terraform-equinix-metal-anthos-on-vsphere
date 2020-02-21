resource "random_string" "vcenter_password" {
  length = 16
  min_upper = 2 
  min_lower = 2 
  min_numeric = 2 
  min_special = 2 
  override_special = "$!?@*"
}

resource "random_string" "sso_password" {
  length = 16
  min_upper = 2 
  min_lower = 2 
  min_numeric = 2 
  min_special = 2 
  override_special = "$!?@*"
}

data "template_file" "vcva_template" {
    template = "${file("templates/vcva_template.json")}"
    vars = {
        vcenter_password = "${random_string.vcenter_password.result}"
        sso_password = "${random_string.sso_password.result}"
        first_esx_pass = "${packet_device.esxi_hosts.0.root_password}"
        domain_name = "${var.domain_name}" 
        vcenter_network = "${var.vcenter_portgroup_name}"
    }
}

resource "null_resource" "copy_vcva_template" {
    connection {
        type = "ssh"
        user = "root"
        private_key = "${file("~/.ssh/id_rsa")}"
        host = "${packet_device.router.access_public_ipv4}"
    }
    provisioner "file" {
        content = "${data.template_file.vcva_template.rendered}"
        destination = "/root/vcva_template.json"
    }
}
