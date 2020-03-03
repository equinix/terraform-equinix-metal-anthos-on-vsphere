variable "auth_token" {
}

variable "organization_id" {
}

variable "project_name" {
  default = "anthos-on-packet-1"
}

/*
Valid vsphere_service_types are:
  faultToleranceLogging
  vmotion
  vSphereReplication
  vSphereReplicationNFC
  vSphereProvisioning
  vsan
  management
*/

variable "private_subnets" {
    default = [
        {
            "name": "Management",
            "nat": true,
            "vsphere_service_type": "management",
            "routable": true,
            "cidr": "172.16.0.0/24"
        },
        {
            "name": "vMotion",
            "nat": false,
            "vsphere_service_type": "vmotion",
            "routable": false,
            "cidr": "172.16.1.0/24"
        },
        {
            "name": "vSAN",
            "nat": false,
            "vsphere_service_type": "vsan",
            "routable": false,
            "cidr": "172.16.2.0/24"
        },
        {
            "name": "VM Private Net",
            "nat": true,
            "vsphere_service_type": null,
            "routable": true,
            "cidr": "172.16.3.0/24"
        }
    ]
}

variable "public_subnets" {
    default = [
        {
            "name": "VM Public Net",
            "nat": false,
            "vsphere_service_type": null,
            "routable": true,
            "ip_count": 4
        }
    ]
}

variable "router_hostname" {
  default = "edge-gateway01"
}

variable "esxi_hostname" {
  default = "esx"
}

variable "router_size" {
  default = "c2.medium.x86"
}

variable "esxi_size" {
  default = "c2.medium.x86"
}

variable "facility" {
  default = "dfw2"
}

variable "router_os" {
  default = "ubuntu_16_04"
}

variable "vmware_os" {
  default = "vmware_esxi_6_5"
}

variable "billing_cycle" {
  default = "hourly"
}

variable "esxi_host_count" {
  default = 3
}

