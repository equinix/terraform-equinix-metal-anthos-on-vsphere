import json
import ipaddress
import os
from subprocess import Popen

private_subnets = '${private_subnets}'
vsphere_network = '${vsphere_network}'
create_anthos_cluster = ${create_anthos_cluster}
subnets = json.loads(private_subnets)
filepath = "/root/anthos/cluster/"
files = ["admin-lb-ipblock.yaml", "usercluster-1-lb-ipblock.yaml", "bundled-lb-admin-uc1-config.yaml", "admin-cluster-config.yaml", "user-cluster1-config.yaml"]

for subnet in subnets:
    if subnet['name'] == vsphere_network:
        subnet_mask = ipaddress.ip_network(subnet['cidr']).netmask.compressed 
        gateway_ip = list(ipaddress.ip_network(subnet['cidr']).hosts())[0].compressed
        admin_lb_vip = list(ipaddress.ip_network(subnet['cidr']).hosts())[11].compressed
        admin_lb_1_ip = list(ipaddress.ip_network(subnet['cidr']).hosts())[12].compressed
        admin_lb_2_ip = list(ipaddress.ip_network(subnet['cidr']).hosts())[13].compressed
        admin_k8s_api_vip = list(ipaddress.ip_network(subnet['cidr']).hosts())[14].compressed
        admin_k8s_ingress_vip = list(ipaddress.ip_network(subnet['cidr']).hosts())[15].compressed
        admin_k8s_addon_vip = list(ipaddress.ip_network(subnet['cidr']).hosts())[16].compressed
        user_lb_vip = list(ipaddress.ip_network(subnet['cidr']).hosts())[17].compressed
        user_lb_1_ip = list(ipaddress.ip_network(subnet['cidr']).hosts())[18].compressed
        user_lb_2_ip = list(ipaddress.ip_network(subnet['cidr']).hosts())[19].compressed
        user_k8s_api_vip = list(ipaddress.ip_network(subnet['cidr']).hosts())[20].compressed
        user_k8s_ingress_vip = list(ipaddress.ip_network(subnet['cidr']).hosts())[21].compressed

# Replace a ton of vars in a few files
for f in files:
  os.system("sed -i 's/__DNS_SERVER__/{}/g' {}{}".format(gateway_ip, path, f))
  os.system("sed -i 's/__NETMASK__/{}/g' {}{}".format(subnet_mask, path, f))
  os.system("sed -i 's/__GATEWAY__/{}/g' {}{}".format(gateway_ip, path, f))
  os.system("sed -i 's/__ADMIN_LB_1_IP__/{}/g' {}{}".format(admin_lb_1_ip, path, f))
  os.system("sed -i 's/__ADMIN_LB_2_IP__/{}/g' {}{}".format(admin_lb_2_ip, path, f))
  os.system("sed -i 's/__DNS_SERVER__/{}/g' {}{}".format(gateway_ip, path, f))
  os.system("sed -i 's/__NETMASK__/{}/g' {}{}".format(subnet_mask, path, f))
  os.system("sed -i 's/__GATEWAY__/{}/g' {}{}".format(gateway_ip, path, f))
  os.system("sed -i 's/__USER_LB_1_IP__/{}/g' {}{}".format(user_lb_1_ip, path, f))
  os.system("sed -i 's/__USER_LB_2_IP__/{}/g' {}{}".format(user_lb_2_ip, path, f))
  os.system("sed -i 's/__ADMIN_LB_VIP__/{}/g' {}{}".format(admin_lb_vip, path, f))
  os.system("sed -i 's/__ADMIN_K8S_API_VIP__/{}/g' {}{}".format(admin_k8s_api_vip, path, f))
  os.system("sed -i 's/__ADMIN_K8S_INGRESS_VIP__/{}/g' {}{}".format(admin_k8s_ingress_vip, path, f))
  os.system("sed -i 's/__ADMIN_K8S_ADDON_VIP__/{}/g' {}{}".format(admin_k8s_addon_vip, path, f))
  os.system("sed -i 's/__USER_LB_VIP__/{}/g' {}{}".format(user_lb_vip, path, f))
  os.system("sed -i 's/__USER_K8S_API_VIP__/{}/g' {}{}".format(user_k8s_api_vip, path, f))
  os.system("sed -i 's/__USER_K8S_INGRESS_VIP__/{}/g' {}{}".format(user_k8s_ingress_vip, path, f))

# Reserve IPs in dnsmasq
dnsmasq_conf = open('/etc/dnsmasq.d/dhcp.conf', 'a+')
dnsmasq_conf.write("dhcp-host=00:00:00:00:01:00, {} # {} IP\n".format(admin_lb_vip, "admin_lb_vip"))
dnsmasq_conf.write("dhcp-host=00:00:00:00:01:01, {} # {} IP\n".format(admin_lb_1_ip, "admin_lb_1_ip"))
dnsmasq_conf.write("dhcp-host=00:00:00:00:01:02, {} # {} IP\n".format(admin_lb_2_ip, "admin_lb_2_ip"))
dnsmasq_conf.write("dhcp-host=00:00:00:00:01:03, {} # {} IP\n".format(admin_k8s_api_vip, "admin_k8s_api_vip"))
dnsmasq_conf.write("dhcp-host=00:00:00:00:01:04, {} # {} IP\n".format(admin_k8s_ingress_vip, "admin_k8s_ingress_vip"))
dnsmasq_conf.write("dhcp-host=00:00:00:00:01:05, {} # {} IP\n".format(admin_k8s_addon_vip, "admin_k8s_addon_vip"))
dnsmasq_conf.write("dhcp-host=00:00:00:00:01:06, {} # {} IP\n".format(user_lb_vip, "user_lb_vip"))
dnsmasq_conf.write("dhcp-host=00:00:00:00:01:07, {} # {} IP\n".format(user_lb_1_ip, "user_lb_1_ip"))
dnsmasq_conf.write("dhcp-host=00:00:00:00:01:08, {} # {} IP\n".format(user_lb_2_ip, "user_lb_2_ip"))
dnsmasq_conf.write("dhcp-host=00:00:00:00:01:09, {} # {} IP\n".format(user_k8s_api_vip, "user_k8s_api_vip"))
dnsmasq_conf.write("dhcp-host=00:00:00:00:01:10, {} # {} IP\n".format(user_k8s_ingress_vip, "user_k8s_ingress_vip"))
dnsmasq_conf.close()

# Restart dnsmasq service
Popen(["systemctl restart dnsmasq"], shell=True, stdin=None, stdout=None, stderr=None, close_fds=True)

