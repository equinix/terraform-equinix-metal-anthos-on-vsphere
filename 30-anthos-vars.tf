variable "anthos_gcp_project_id" {
  description = "The GCP Project ID to use for Anthos"
}

variable "anthos_version" {
  description = "Version of Google Anthos to install"
  default     = "1.1.2-gke.0"
}

# Must be True or False (Case matters)
variable "anthos_deploy_clusters" {
  description = "Deploy Google Anthos clusters automatically"
  default     = "True"
}


variable "anthos_deploy_workstation_prereqs" {
  description = "Deploy Google Anthos workstation and prereqs"
  type        = bool
  default     = true
}

variable "anthos_resource_pool_name" {
  description = "Resource Pool Name for Anthos"
  default     = "Anthos"
}

variable "anthos_deploy_network" {
  description = "The network used to deploy Anthos clusters"
  default     = "VM Private Net"
}

variable "anthos_admin_service_cidr" {
  description = "The k8s service CIDR for the Anthos Admin Cluster"
  default     = "172.31.0.0/16"
}

variable "anthos_admin_pod_cidr" {
  description = "The k8s pod CIDR for the Anthos Admin Cluster"
  default     = "172.30.0.0/16"
}

variable "anthos_user_service_cidr" {
  description = "The k8s service CIDR for the Anthos User Cluster"
  default     = "172.29.0.0/16"
}

variable "anthos_user_pod_cidr" {
  description = "The k8s pod CIDR for the Anthos User Cluster"
  default     = "172.28.0.0/16"
}

variable "anthos_user_cluster_name" {
  description = "The name for the Anthos User Cluster"
  default     = "user-cluster1"
}

variable "anthos_gcp_region" {
  description = "The GCP Region to use for Anthos Logs"
  default     = "us-central1"
}


variable "anthos_user_master_replicas" {
  description = "The number of user masters to deploy (1 or 3)"
  default     = "3"
}

variable "anthos_user_worker_replicas" {
  description = "The number of user worker nodes to deploy (minimum 3)"
  default     = "3"
}

variable "anthos_user_vcpu" {
  description = "The number vcpu per user worker node (minimum 4)"
  default     = "4"
}

variable "anthos_user_memory_mb" {
  description = "The amount of RAM (in MB) per user worker node (minimum 8192)"
  default     = "8192"
}
