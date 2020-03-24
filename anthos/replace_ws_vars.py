import json
import ipaddress
import os
from subprocess import Popen

private_subnets = '${private_subnets}'
vsphere_network = '${vsphere_network}'
domain_name = '${domain_name}'
hostname = 'admin-workstation'

subnets = json.loads(private_subnets)

for subnet in subnets:
    if subnet['name'] == vsphere_network:
        workstation_ip = list(ipaddress.ip_network(subnet['cidr']).hosts())[2].compressed
        gateway_ip = list(ipaddress.ip_network(subnet['cidr']).hosts())[0].compressed
        prefix_length = int(subnet['cidr'].split('/')[1])
        netmask =  ipaddress.netmask('cidr')
        print (netmask)

os.system("sed -i 's/__IP_ADDRESS__/{}/g' /root/anthos/terraform.tfvars".format(workstation_ip))
os.system("sed -i 's/__IP_PREFIX_LENGTH__/{}/g' /root/anthos/terraform.tfvars".format(prefix_length))
os.system("sed -i 's/__GATEWAY__/{}/g' /root/anthos/terraform.tfvars".format(gateway_ip))

os.system("sed -i 's/__IP_ADDRESS__/{}/g' /root/anthos/admin-ws-config.yaml".format(workstation_ip))
os.system("sed -i 's/__NETMASK__/{}/g' /root/anthos/admin-ws-config.yaml".format(prefix_length))
os.system("sed -i 's/__GATEWAY__/{}/g' /root/anthos/admin-ws-config.yaml".format(gateway_ip))

# Reserve IP in dnsmasq
dnsmasq_conf = open('/etc/dnsmasq.d/dhcp.conf', 'a+')
dnsmasq_conf.write("dhcp-host=00:00:00:00:00:98, {} # {} IP\n".format(workstation_ip, hostname))
dnsmasq_conf.close()

# DNS record for Admin Workstation
etc_hosts = open('/etc/hosts', 'a+')
etc_hosts.write('{}\t{}\t{}.{}\n'.format(workstation_ip, hostname, hostname, domain_name))
etc_hosts.close()

# Restart dnsmasq service
Popen(["systemctl restart dnsmasq"], shell=True, stdin=None, stdout=None, stderr=None, close_fds=True)



# Tell future Terraform Script where the admin workstation is
try:
    os.makedirs('/root/anthos/cluster/')
except OSError as e:
    if e.errno != errno.EEXIST:
        raise

cluster_tf_var = '/root/anthos/cluster/terraform.tfvars'

if os.path.exists(cluster_tf_var):
    append_write = 'a'
else:
    append_write = 'w'

cluster_tf_vars = open(cluster_tf_var, append_write)
cluster_tf_vars.write('admin_workstation_ip="{}"'.format(workstation_ip))
cluster_tf_vars.close()

