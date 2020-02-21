resource "random_string" "ipsec_psk" {
  length = 20
  min_upper = 2
  min_lower = 2
  min_numeric = 2
  min_special = 2
  override_special = "$!?@*"
}

resource "random_string" "vpn_pass" {
  length = 16
  min_upper = 2
  min_lower = 2
  min_numeric = 2
  min_special = 2
  override_special = "$!?@*"
}

data "template_file" "vpn_installer" {
    template = file("templates/l2tp_vpn.sh")
    vars = {
        ipsec_psk = random_string.ipsec_psk.result
        vpn_user = var.vpn_user
        vpn_pass = random_string.vpn_pass.result
    }
}

resource "null_resource" "install_vpn_server" {
    depends_on = [null_resource.download_vcenter_iso]
    connection {
        type = "ssh"
        user = "root"
        private_key = file("~/.ssh/id_rsa")
        host = packet_device.router.access_public_ipv4
    }

    provisioner "file" {
        content = data.template_file.vpn_installer.rendered
        destination = "/root/vpn_installer.sh"
    }

    provisioner "remote-exec" {
        inline = [
            "cd /root",
            "chmod +x /root/vpn_installer.sh",
            "/root/vpn_installer.sh"
        ]
    }
}

