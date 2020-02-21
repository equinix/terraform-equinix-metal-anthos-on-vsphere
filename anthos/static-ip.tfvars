vsphere_user = "${vcenter_username}"
vsphere_password = "${vcenter_password}"
vsphere_server = "${vcenter_fqdn}"
ssh_public_key_path = "/root/anthos/ssh_key.pub"

vm_name = "admin-workstation"

datastore = "${vsphere_datastore}"
datacenter = "${vsphere_datacenter}"
cluster = "${vsphere_cluster}"
resource_pool = "${vsphere_resource_pool}"
network = "${vsphere_network}"

num_cpus = 4
memory = 8192
vm_template = "gke-on-prem-admin-appliance-vsphere-${anthos_version}"

ipv4_address = "__IP_ADDRESS__"
ipv4_netmask_prefix_length = "__IP_PREFIX_LENGTH__"
ipv4_gateway = "__GATEWAY__"
dns_nameservers = "__GATEWAY__,8.8.8.8,8.8.4.4"

