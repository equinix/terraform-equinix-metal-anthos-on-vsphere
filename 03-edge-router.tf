data "template_file" "user_data" {
    template = "${file("templates/user_data.py")}"
    vars = {
        private_subnets = "${jsonencode(var.private_subnets)}"
        private_vlans = "${jsonencode(packet_vlan.private_vlans.*.vxlan)}"
        public_subnets = "${jsonencode(var.public_subnets)}"
        public_vlans = "${jsonencode(packet_vlan.public_vlans.*.vxlan)}"
        public_cidrs = "${jsonencode(packet_reserved_ip_block.ip_blocks.*.cidr_notation)}"
        domain_name = "${var.domain_name}"
    }
}

resource "packet_device" "router" {
    hostname         = "${var.router_hostname}"
    plan             = "${var.router_size}"
    facilities       = ["${var.facility}"]
    operating_system = "${var.router_os}"
    billing_cycle    = "${var.billing_cycle}"
    project_id       = "${packet_project.new_project.id}"
    user_data        = "${data.template_file.user_data.rendered}"
    network_type     = "hybrid"
}

resource "packet_port_vlan_attachment" "router_priv_vlan_attach" {
    count = "${length(packet_vlan.private_vlans)}"
    device_id = "${packet_device.router.id}"
    port_name = "eth1"
    vlan_vnid = "${jsonencode(element(packet_vlan.private_vlans.*.vxlan, count.index))}"
}

resource "packet_port_vlan_attachment" "router_pub_vlan_attach" {
    count = "${length(packet_vlan.public_vlans)}"
    device_id = "${packet_device.router.id}"
    port_name = "eth1"
    vlan_vnid = "${jsonencode(element(packet_vlan.public_vlans.*.vxlan, count.index))}"
}

resource "packet_ip_attachment" "block_assignment" {
    count = "${length(packet_reserved_ip_block.ip_blocks)}"
    device_id = "${packet_device.router.id}"
    cidr_notation = "${substr(jsonencode(element(packet_reserved_ip_block.ip_blocks.*.cidr_notation, count.index)),1,length(jsonencode(element(packet_reserved_ip_block.ip_blocks.*.cidr_notation, count.index)))-2)}"
}