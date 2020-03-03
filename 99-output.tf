output "VPN_Endpoint" {
  value = "${packet_device.router.access_public_ipv4}"
}

