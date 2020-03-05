output "VPN_Endpoint" {
  value = "${packet_device.router.access_public_ipv4}"
}

output "VPN_PSK" {
  value = "${random_string.ipsec_psk.result}"
}

output "VPN_User" {
  value = "${var.vpn_user}"
}

output "VPN_Pasword" {
  value = "${random_string.vpn_pass.result}"
}

output "vCenter_FQDN" {
  value = "vcva.packet.local"
}

output "vCenter_Username" {
  value = "Administrator@vsphere.local"
}

output "vCenter_Password" {
  value = "${random_string.sso_password.result}"
}

output "vCenter_Appliance_Root_Password" {
  value = "${random_string.vcenter_password.result}"
}

output "KSA_Token_Location" {
  value = "The user cluster KSA Token (for logging in from GCP) is located at ./ksa_token.txt"
}
