output "VPN_Endpoint" {
  description = "L2TP VPN Endpoint"
  value       = module.vsphere.bastion_host
}

output "VPN_PSK" {
  description = "L2TP VPN Pre-Shared Key"
  value       = module.vsphere.vpn_psk
}

output "VPN_User" {
  description = "L2TP VPN username"
  value       = module.vsphere.vpn_user
}

output "VPN_Password" {
  description = "L2TP VPN Password"
  value       = module.vsphere.vpn_password
}

output "vCenter_FQDN" {
  description = "The FQDN of vCenter (Private DNS only)"
  value       = module.vsphere.vcenter_fqdn
}

output "vCenter_Username" {
  description = "The username to login to vCenter"
  value       = module.vsphere.vcenter_username
}

output "vCenter_Password" {
  description = "The SSO Password to login to vCenter"
  value       = module.vsphere.vcenter_password
}

output "vCenter_Appliance_Root_Password" {
  description = "The root password to ssh or login at the console of vCanter."
  value       = module.vsphere.vcenter_root_password
}

output "KSA_Token_Location" {
  description = "The user cluster KSA Token (for logging in from GCP)"
  value       = "${path.module}/ksa_token.txt"
}

output "SSH_Key_Location" {
  description = "An SSH Key was created for this environment"
  value       = module.vsphere.ssh_key_path
}
