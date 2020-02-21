resource "null_resource" "copy_update_uplinks" {
    connection {
        type = "ssh"
        user = "root"
        private_key = "${file("~/.ssh/id_rsa")}"
        host = "${packet_device.router.access_public_ipv4}"
    }

    provisioner "file" {
        content = "${file("templates/update_uplinks.py")}"
        destination = "/root/update_uplinks.py"
    }
}

data "template_file" "esx_host_networking" {
    template = "${file("templates/esx_host_networking.py")}"
    vars = {
        private_subnets = "${jsonencode(var.private_subnets)}"
        private_vlans = "${jsonencode(packet_vlan.private_vlans.*.vxlan)}"
        public_subnets = "${jsonencode(var.public_subnets)}"
        public_vlans = "${jsonencode(packet_vlan.public_vlans.*.vxlan)}"
        public_cidrs = "${jsonencode(packet_reserved_ip_block.ip_blocks.*.cidr_notation)}"
        domain_name = "${var.domain_name}"
        packet_token = "${var.auth_token}"
    }
}

resource "null_resource" "esx_network_prereqs" {
    connection {
        type = "ssh"
        user = "root"
        private_key = "${file("~/.ssh/id_rsa")}"
        host = "${packet_device.router.access_public_ipv4}"
    }

    provisioner "file" {
        content = "${data.template_file.esx_host_networking.rendered}"
        destination = "/root/esx_host_networking.py"
    }
}

resource "null_resource" "apply_esx_network_config" {
    count = "${length(packet_device.esxi_hosts)}"
    depends_on = [
        packet_port_vlan_attachment.esxi_priv_vlan_attach,
        packet_port_vlan_attachment.esxi_pub_vlan_attach,
        null_resource.esx_network_prereqs,
        null_resource.copy_update_uplinks
    ]

    connection {
        type = "ssh"
        user = "root"
        private_key = "${file("~/.ssh/id_rsa")}"
        host = "${packet_device.router.access_public_ipv4}"
    }

    provisioner "remote-exec" {
        inline = ["python3 /root/esx_host_networking.py --host '${element(packet_device.esxi_hosts.*.access_public_ipv4,count.index)}' --user root --pass '${element(packet_device.esxi_hosts.*.root_password, count.index)}' --id '${element(packet_device.esxi_hosts.*.id, count.index)}' --index ${count.index}"]
        on_failure = "continue"

    }
}
