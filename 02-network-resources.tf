resource "packet_reserved_ip_block" "ip_blocks" {
    count = "${length(var.public_subnets)}"
    project_id = "${packet_project.new_project.id}"
    facility = "${var.facility}"
    quantity = "${jsonencode(element(var.public_subnets.*.ip_count, count.index))}"
}

resource "packet_reserved_ip_block" "esx_ip_blocks" {
    count = var.esxi_host_count
    project_id = packet_project.new_project.id
    facility = var.facility
    quantity = 8 
}

resource "packet_vlan" "private_vlans" {
    count = "${length(var.private_subnets)}"
    facility    = "${var.facility}"
    project_id  = "${packet_project.new_project.id}"
    description = "${jsonencode(element(var.private_subnets.*.name, count.index))}"
}

resource "packet_vlan" "public_vlans" {
    count = "${length(var.public_subnets)}"
    facility = "${var.facility}"
    project_id = "${packet_project.new_project.id}"
    description = "${jsonencode(element(var.public_subnets.*.name, count.index))}"
}
