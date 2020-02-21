#########################
####### VARIABLES #######
#########################

# vSphere username
variable "vsphere_user" { }
# vSphere password
variable "vsphere_password" { }
# vSphere server address
variable "vsphere_server" { }
# Install this public key in the created VM
variable "ssh_public_key_path" { default = "~/.ssh/vsphere_workstation.pub" }
# vSphere network to use for the VM
variable "network" { default = "VM Network"}
# Hostname for the VM
variable "vm_name" { default = "vsphere-workstation" }
# vSphere datacenter to create this VM in
variable "datacenter" { }
# vSphere datastore to create this VM in
variable "datastore" { }
# vSphere cluster to create this VM in
variable "cluster" { }
# vSphere resource pool to create this VM in
variable "resource_pool" { }
# Number of CPUs for this VM. Recommended minimum 4.
variable "num_cpus" { default = 4 }
# Memory in MB for this VM. Recommended minimum 8192.
variable "memory" { default = 8192 }
# The VM template to clone
variable "vm_template" { }
# The IP address to assign this this VM
variable "ipv4_address" { }
# Netmask prefix length
variable "ipv4_netmask_prefix_length" { }
# Default gateway to use
variable "ipv4_gateway" { }
# DNS resolvers to use
variable "dns_nameservers" { }
# Enable the provided Docker registry. If you use your own registry, set to "false"
variable "registry_enable" { default = "true" }
# Username to set for the Docker registry
variable "registry_username" { default = "gke" }
# Password to set for the Docker registry
variable "registry_password" { default = "password" }
# Optional DNS hostname for the registry's certificate
variable "registry_dns_hostname" { default = "" }

#########################
##### FOR UPGRADING #####
#########################
# Path on disk to the htpasswd file
variable "registry_htpasswd" { default = "" } // filepath
# Path on disk to the certificate for the Docker registry in the admin workstation
variable "registry_cert" { default = "" } // filepath
# Path on disk to the registry's CA
variable "registry_ca" { default = "" } // filepath
# Path on disk to the registry's private key
variable "registry_private_key" { default = "" } // filepath


##########################
##########################

provider "vsphere" {
  version        = "~> 1.5"
  user           = "${var.vsphere_user}"
  password       = "${var.vsphere_password}"
  vsphere_server = "${var.vsphere_server}"

  # if you have a self-signed cert
  allow_unverified_ssl = true
}

### vSphere Data ###

data "vsphere_datastore" "datastore" {
  name          = "${var.datastore}"
  datacenter_id = "${data.vsphere_datacenter.dc.id}"
}

data "vsphere_datacenter" "dc" {
  name = "${var.datacenter}"
}

data "vsphere_compute_cluster" "cluster" {
  name          = "${var.cluster}"
  datacenter_id = "${data.vsphere_datacenter.dc.id}"
}

data "vsphere_resource_pool" "pool" {
  name          = "${var.resource_pool}"
  datacenter_id = "${data.vsphere_datacenter.dc.id}"
}

data "vsphere_network" "network" {
  name          = "${var.network}"
  datacenter_id = "${data.vsphere_datacenter.dc.id}"
}

data "vsphere_virtual_machine" "template_from_ovf" {
  name          = "${var.vm_template}"
  datacenter_id = "${data.vsphere_datacenter.dc.id}"
}

##########################
### IF USING STATIC IP ###
##########################
data "template_file" "static_ip_config" {
  template = <<EOF
network:
  version: 2
  ethernets:
    ens192:
      dhcp4: no
      dhcp6: no
      addresses: ["${var.ipv4_address}/${var.ipv4_netmask_prefix_length}"]
      gateway4: ${var.ipv4_gateway}
      nameservers:
        addresses: [${var.dns_nameservers}]
EOF
}

data "template_file" "user_data" {
  template = <<EOF
#cloud-config
apt:
  primary:
    - arches: [default]
      uri: http://us-west1.gce.archive.ubuntu.com/ubuntu/
write_files:
  - path: /tmp/static-ip.yaml
    permissions: '0644'
    encoding: base64
    content: |
      $${static_ip_config}
runcmd:
  - /var/lib/gke/guest-startup.sh $${reg_enable} $${reg_username} $${reg_password} $${reg_dns_hostname} $${reg_htpasswd} $${reg_cert} $${reg_private_key} $${reg_ca}
EOF
  vars = {
    static_ip_config = "${base64encode(data.template_file.static_ip_config.rendered)}"

    reg_enable = "${var.registry_enable}"
    reg_username = "${var.registry_username}"
    reg_password = "${var.registry_password}"
    reg_dns_hostname = "${var.registry_dns_hostname}"

    reg_htpasswd = ""
    reg_cert = ""
    reg_private_key = ""
    reg_ca = ""

    ########################
    #### FOR UPGRADING #####
    # reg_htpasswd = "${file(var.registry_htpasswd)}"
    # reg_cert = "${file(var.registry_cert)}"
    # reg_private_key = "${file(var.registry_private_key)}"
    # reg_ca = "${file(var.registry_ca)}"
    ########################
  }
}
##########################
### IF USING STATIC IP ###
##########################

### vSphere Resources ###

resource "vsphere_virtual_machine" "vm" {
  name             = "${var.vm_name}"
  resource_pool_id = "${data.vsphere_resource_pool.pool.id}"
  datastore_id     = "${data.vsphere_datastore.datastore.id}"
  num_cpus         = "${var.num_cpus}"
  memory           = "${var.memory}"
  guest_id         = "${data.vsphere_virtual_machine.template_from_ovf.guest_id}"
  enable_disk_uuid = "true"
  scsi_type = "${data.vsphere_virtual_machine.template_from_ovf.scsi_type}"
  network_interface {
    network_id   = "${data.vsphere_network.network.id}"
    adapter_type = "${data.vsphere_virtual_machine.template_from_ovf.network_interface_types[0]}"
  }

  wait_for_guest_net_timeout = 15

  nested_hv_enabled = true
  cpu_performance_counters_enabled = true

  disk {
    label            = "disk0"
    size             = "${max(50, data.vsphere_virtual_machine.template_from_ovf.disks.0.size)}"
    eagerly_scrub    = "${data.vsphere_virtual_machine.template_from_ovf.disks.0.eagerly_scrub}"
    thin_provisioned = "${data.vsphere_virtual_machine.template_from_ovf.disks.0.thin_provisioned}"
  }

  cdrom {
    client_device = true
  }

  vapp {
    properties = {
      hostname    = "${var.vm_name}"
      public-keys = "${file(var.ssh_public_key_path)}"
      user-data   = "${base64encode(data.template_file.user_data.rendered)}"
    }
  }

  clone {
    template_uuid = "${data.vsphere_virtual_machine.template_from_ovf.id}"
  }
}

output "ip_address" {
  value = "${vsphere_virtual_machine.vm.default_ip_address}"
}
