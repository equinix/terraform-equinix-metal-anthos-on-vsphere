import json
import ipaddress
import os
import sys
import subprocess
import socket
from pyVmomi import vim, vmodl
from pyVim import connect


def get_ssl_thumbprint(host_ip):
    p1 = subprocess.Popen(('echo', '-n'), stdout=subprocess.PIPE, stderr=subprocess.PIPE)
    p2 = subprocess.Popen(('openssl', 's_client', '-connect', '{0}:443'.format(host_ip)),
                          stdin=p1.stdout, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
    p3 = subprocess.Popen(('openssl', 'x509', '-noout', '-fingerprint', '-sha1'),
                          stdin=p2.stdout, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
    out = p3.stdout.read()
    ssl_thumbprint = out.split(b'=')[-1].strip()
    return ssl_thumbprint.decode("utf-8")


# Vars from Terraform
private_subnets = '${private_subnets}'
esx_passwords = '${esx_passwords}'
sso_password = '${sso_password}'
dc_name = '${dc_name}'
cluster_name = '${cluster_name}'
vcenter_network = '${vcenter_network}'

# Parse TF Vars
subnets = json.loads(private_subnets)
esx_passes = json.loads(esx_passwords)
esx = []
for pw in esx_passes:
    esx.append({"password": pw})

for subnet in subnets:
    if subnet['name'] == vcenter_network:
        vcenter_ip = list(ipaddress.ip_network(subnet['cidr']).hosts())[1].compressed
        esx_ip = list(ipaddress.ip_network(subnet['cidr']).hosts())[3].compressed
        gateway_ip = list(ipaddress.ip_network(subnet['cidr']).hosts())[0].compressed
        prefix_length = int(subnet['cidr'].split('/')[1])
        for i in range(len(esx)):
            esx[i]['private_ip'] = list(ipaddress.ip_network(subnet['cidr']).hosts())[i + 3].compressed
        break

os.system("sed -i 's/__ESXI_IP__/{}/g' /root/vcva_template.json".format(esx_ip))
os.system("sed -i 's/__VCENTER_IP__/{}/g' /root/vcva_template.json".format(vcenter_ip))
os.system("sed -i 's/__MGMT_GATEWAY__/{}/g' /root/vcva_template.json".format(gateway_ip))
os.system("sed -i 's/__MGMT_PREFIX_LENGTH__/{}/g' /root/vcva_template.json".format(prefix_length))
os.system("/mnt/vcsa-cli-installer/lin64/vcsa-deploy install --accept-eula --acknowledge-ceip "
          "--no-esx-ssl-verify /root/vcva_template.json")



# Connect to vCenter
for i in range(1, 30):
    si = None
    try:
        si = connect.SmartConnectNoSSL(host=vcenter_ip, user="Administrator@vsphere.local", pwd=sso_password, port=443)
        break
    except Exception:
        sleep(10)
if si == None:
    print("Couldn't connect to vCenter!!!")
    sys.exit(1)

# Create Datacenter in the root folder
folder = si.content.rootFolder
dc = folder.CreateDatacenter(name=dc_name)

# Create cluster config
cluster_config = vim.cluster.ConfigSpecEx()

# Create DRS config
drs_config=vim.cluster.DrsConfigInfo()
drs_config.enabled = True
cluster_config.drsConfig=drs_config

# Create vSan config
vsan_config=vim.vsan.cluster.ConfigInfo()
vsan_config.enabled = True
vsan_config.defaultConfig = vim.vsan.cluster.ConfigInfo.HostDefaultInfo(
                                autoClaimStorage = True
                            )
cluster_config.vsanConfig = vsan_config

# Create HA config
ha_config = vim.cluster.DasConfigInfo()
ha_config.enabled = True
ha_config.hostMonitoring = vim.cluster.DasConfigInfo.ServiceState.enabled
ha_config.failoverLevel = 1
cluster_config.dasConfig = ha_config

# Create the cluster
host_folder = dc.hostFolder
cluster = host_folder.CreateClusterEx(name=cluster_name, spec=cluster_config)

# Join hosts to the cluster
for host in esx:
    dns_name = socket.gethostbyaddr(host['private_ip'])[0]
    host_connect_spec = vim.host.ConnectSpec()
    host_connect_spec.hostName = dns_name
    host_connect_spec.userName = 'root'
    host_connect_spec.password = host['password']
    host_connect_spec.force = True
    host_connect_spec.sslThumbprint = get_ssl_thumbprint(dns_name)
    cluster.AddHost(spec=host_connect_spec, asConnected=True)
