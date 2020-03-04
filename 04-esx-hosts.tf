resource "packet_device" "esxi_hosts" {
  count            = "${var.esxi_host_count}"
  hostname         = "${format("%s%02d", var.esxi_hostname, count.index + 1)}"
  plan             = "${var.esxi_size}"
  facilities       = ["${var.facility}"]
  operating_system = "${var.vmware_os}"
  billing_cycle    = "${var.billing_cycle}"
  project_id       = "${packet_project.new_project.id}"
  network_type     = "hybrid"
  ip_address {
    type            = "public_ipv4"
    cidr            = 29
    reservation_ids = [element(packet_reserved_ip_block.esx_ip_blocks.*.id, count.index)]
  }
  ip_address {
    type  = "private_ipv4"
  }
  ip_address  {
    type  = "public_ipv6"
  }
}


resource "packet_port_vlan_attachment" "esxi_priv_vlan_attach" {
    count = "${length(packet_device.esxi_hosts) * length(packet_vlan.private_vlans)}"
    device_id = "${element(packet_device.esxi_hosts.*.id, ceil(count.index / length(packet_vlan.private_vlans)))}"
    port_name = "eth1"
    vlan_vnid = "${jsonencode(element(packet_vlan.private_vlans.*.vxlan, count.index))}"
}


resource "packet_port_vlan_attachment" "esxi_pub_vlan_attach" {
    count = "${length(packet_device.esxi_hosts) * length(packet_vlan.public_vlans)}"
    device_id = "${element(packet_device.esxi_hosts.*.id, ceil(count.index / length(packet_vlan.public_vlans)))}"
    port_name = "eth1"
    vlan_vnid = "${element(packet_vlan.public_vlans.*.vxlan, count.index)}"
}
