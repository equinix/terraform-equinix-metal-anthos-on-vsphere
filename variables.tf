variable "auth_token" {
  description = "This is your Equinix MetalAPI Auth token. This can also be specified with the TF_VAR_PACKET_AUTH_TOKEN shell environment variable."
  type        = string
}

variable "organization_id" {
    description = "Your Equinix Metal Organization Id"
  type        = string
}

variable "project_name" {
  default = "anthos-on-packet-1"
}


variable "create_project" {
  description = "if true create the packet project, if not skip and use the provided project"
  default     = true
}

variable "project_id" {
  description = "Equinix MetalProject ID to use in case create_project is false"
  default     = "null"
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
  description = "This is the network topology for your vSphere Env"
  default = [
    {
      "name"                 = "Management",
      "nat"                  = true,
      "vsphere_service_type" = "management",
      "routable"             = true,
      "cidr"                 = "172.16.0.0/24"
    },
    {
      "name"                 = "vMotion",
      "nat"                  = false,
      "vsphere_service_type" = "vmotion",
      "routable"             = false,
      "cidr"                 = "172.16.1.0/24"
    },
    {
      "name"                 = "vSAN",
      "nat"                  = false,
      "vsphere_service_type" = "vsan",
      "routable"             = false,
      "cidr"                 = "172.16.2.0/24"
    },
    {
      "name"                 = "VM Private Net",
      "nat"                  = true,
      "vsphere_service_type" = null,
      "routable"             = true,
      "cidr"                 = "172.16.3.0/24",
      "reserved_ip_count"    = 100
    }
  ]
}

variable "public_subnets" {
  description = "This will dynamically create public subnets in vSphere"
  default = [
    {
      "name"                 = "VM Public Net",
      "nat"                  = false,
      "vsphere_service_type" = null,
      "routable"             = true,
      "ip_count"             = 4
    }
  ]
}

variable "router_hostname" {
    description = "This is the hostname for the router."
  default = "edge-gateway01"
}

variable "esxi_hostname" {
  description = "This is the hostname prefix for your esxi hosts. A number will be added to the end."
  default = "esx"
}

variable "router_size" {
  description = "This is the size/plan/flavor of your router machine"
  default = "c3.medium.x86"
}

variable "esxi_size" {
    description = "This is the size/plan/flavor of your ESXi machine(s)"
  default = "c3.medium.x86"
}

variable "facility" {
    description = "This is the Region/Location of your deployment."
  default = "ny5"
}

variable "router_os" {
    description = "This is the operating System for you router machine (Only Ubuntu 18.04 has been tested)"
  default = "ubuntu_18_04"
}

variable "vmware_os" {
    description = "This is the version of vSphere that you want to deploy (ESXi 6.5, 6.7, & 7.0 have been tested)"
  default = "vmware_esxi_6_7"
}

variable "billing_cycle" {
    description = "This is billing cycle to use. The hasn't beend built to allow reserved isntances yet."
  default = "hourly"
}

variable "esxi_host_count" {
    description = "This is the number of ESXi host you'd like in your cluster."
  default = 3
}

variable "vcenter_portgroup_name" {
    description = "This is the VM Portgroup you would like vCenter to be deployed to. See 'private_subnets' & 'public_subnets' above. By deploying on a public subnet, you will not need to use the VPN to access vCenter."
  default = "Management"
}

variable "vcenter_domain" {
  description = "This will be the vSphere SSO domain."
  default     = "vsphere.local"
}

variable "domain_name" {
    description = "This is the domain to use for internal DNS"
  default = "packet.local"
}

variable "vpn_user" {
  description = "This is the username for the L2TP VPN"
  default = "vm_admin"
}

variable "vcenter_datacenter_name" {
  description = "This will be the name of the vCenter Datacenter object."
  default = "Packet"
}

variable "vcenter_cluster_name" {
    description = "This will be the name of the vCenter Cluster object."
  default = "Packet-1"
}

variable "vcenter_user_name" {
  description = "This will be the admin user for vSphere SSO"
  default     = "Administrator"
}

variable "gcs_bucket_name" {
  default = "vmware"
}

variable "s3_url" {
  default = "https://s3.example.com"
}

variable "s3_bucket_name" {
  default = "vmware"
}

variable "s3_access_key" {
  default = "S3_ACCESS_KEY"
}

variable "s3_secret_key" {
  default = "S3_SECRET_KEY"
}

variable "s3_boolean" {
  default = "false"
}

variable "s3_version" {
  description = "S3 API Version (S3v2, S3v4)"
  default     = "S3v4"
}

variable "object_store_tool" {
  description = "Which tool should you use to download objects from the object store? ('mc' and 'gcs' have been tested.)"
  default     = "mc"
}

variable "object_store_bucket_name" {
  description = "This is the name of the bucket on your Object Store"
  default     = "vmware"
}

variable "relative_path_to_gcs_key" {
  description = "If you are using GCS to download you vCenter ISO this is the path to the GCS key"
  default     = "storage-reader-key.json"
}

variable "vcenter_iso_name" {
}

variable "storage_reader_key_name" {
  default = "storage-reader-key.json"
}

variable "whitelisted_key_name" {
  default = "whitelisted-key.json"
}

variable "connect_key_name" {
  default = "connect-key.json"
}

variable "register_key_name" {
  default = "register-key.json"
}

variable "stackdriver_key_name" {
  default = "stackdriver-key.json"
}

