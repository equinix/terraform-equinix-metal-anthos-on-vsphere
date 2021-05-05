variable "auth_token" {
  description = "This is your Equinix Metal API Auth token. This can also be specified with the TF_VAR_PACKET_AUTH_TOKEN shell environment variable."
  type        = string
  sensitive   = true
}

variable "organization_id" {
  description = "Your Equinix Metal Organization Id"
  type        = string
}

variable "project_name" {
  type        = string
  description = "If 'create_project' is true this will be the project name used."
  default     = "anthos-on-metal-1"
}


variable "create_project" {
  type        = bool
  description = "if true create the Equinix Metal project, if not skip and use the provided project"
  default     = true
}

variable "project_id" {
  type        = string
  description = "Equinix Metal Project ID to use in case create_project is false"
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
  type = list(object({
    name                 = string,
    nat                  = bool,
    vsphere_service_type = string,
    routable             = bool,
    cidr                 = string,
    reserved_ip_count    = optional(number)
  }))
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
  type = list(object({
    name                 = string,
    nat                  = bool,
    vsphere_service_type = optional(string),
    routable             = bool,
    ip_count             = number
  }))

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
  type        = string
  description = "This is the hostname for the router."
  default     = "edge-gateway01"
}

variable "esxi_hostname" {
  type        = string
  description = "This is the hostname prefix for your esxi hosts. A number will be added to the end."
  default     = "esx"
}

variable "router_size" {
  type        = string
  description = "This is the size/plan/flavor of your router machine"
  default     = "c3.medium.x86"
}

variable "esxi_size" {
  type        = string
  description = "This is the size/plan/flavor of your ESXi machine(s)"
  default     = "c3.medium.x86"
}

variable "facility" {
  type        = string
  description = "This is the Region/Location of your deployment."
  default     = ""
}

variable "router_os" {
  type        = string
  description = "This is the operating System for you router machine (Only Ubuntu 18.04 has been tested)"
  default     = "ubuntu_18_04"
}

variable "vmware_os" {
  type        = string
  description = "This is the version of vSphere that you want to deploy (ESXi 6.5, 6.7, & 7.0 have been tested)"
  default     = "vmware_esxi_6_7"
}

variable "billing_cycle" {
  type        = string
  description = "This is billing cycle to use. The hasn't beend built to allow reserved isntances yet."
  default     = "hourly"
}

variable "esxi_host_count" {
  type        = number
  description = "This is the number of ESXi host you'd like in your cluster."
  default     = 3
}

variable "vcenter_portgroup_name" {
  type        = string
  description = "This is the VM Portgroup you would like vCenter to be deployed to. See 'private_subnets' & 'public_subnets' above. By deploying on a public subnet, you will not need to use the VPN to access vCenter."
  default     = "Management"
}

variable "vcenter_domain" {
  type        = string
  description = "This will be the vSphere SSO domain."
  default     = "vsphere.local"
}

variable "domain_name" {
  type        = string
  description = "This is the domain to use for internal DNS"
  default     = "metal.local"
}

variable "vpn_user" {
  type        = string
  description = "This is the username for the L2TP VPN"
  default     = "vm_admin"
}

variable "vcenter_datacenter_name" {
  type        = string
  description = "This will be the name of the vCenter Datacenter object."
  default     = "Metal"
}

variable "vcenter_cluster_name" {
  type        = string
  description = "This will be the name of the vCenter Cluster object."
  default     = "Metal-1"
}

variable "vcenter_user_name" {
  type        = string
  description = "This will be the admin user for vSphere SSO"
  default     = "Administrator"
}

variable "s3_url" {
  type        = string
  description = "This is the URL endpoint to connect your s3 client to"
  default     = "https://s3.example.com"
}

variable "s3_access_key" {
  type        = string
  default     = "S3_ACCESS_KEY"
  description = "This is the access key for your S3 endpoint"
  sensitive   = true
}

variable "s3_secret_key" {
  type        = string
  default     = "S3_SECRET_KEY"
  description = "This is the secret key for your S3 endpoint"
  sensitive   = true
}

variable "s3_version" {
  type        = string
  description = "S3 API Version (S3v2, S3v4)"
  default     = "S3v4"
}

variable "object_store_tool" {
  type        = string
  description = "Which tool should you use to download objects from the object store? ('mc' and 'gcs' have been tested.)"
  default     = "mc"
}

variable "object_store_bucket_name" {
  type        = string
  description = "This is the name of the bucket on your Object Store"
  default     = "vmware"
}

variable "relative_path_to_gcs_key" {
  type        = string
  description = "If you are using GCS to download you vCenter ISO this is the path to the GCS key"
  default     = "storage-reader-key.json"
}

variable "vcenter_iso_name" {
  type        = string
  description = "The name of the vCenter ISO in your Object Store"
}

variable "whitelisted_key_name" {
  type    = string
  default = "whitelisted-key.json"
}

variable "connect_key_name" {
  type    = string
  default = "connect-key.json"
}

variable "register_key_name" {
  type    = string
  default = "register-key.json"
}

variable "stackdriver_key_name" {
  type    = string
  default = "stackdriver-key.json"
}

