#!/usr/bin/python3
import json
import apt
import os
import ipaddress
import urllib.request as urllib2
import random

# Vars from Terraform
private_subnets = '${private_subnets}'
private_vlans = '${private_vlans}'
public_subnets = '${public_subnets}'
public_vlans = '${public_vlans}'
public_cidrs = '${public_cidrs}'
domain_name = '${domain_name}'


def words_list():
    word_site = "https://raw.githubusercontent.com/taikuukaits/SimpleWordlists/master/Wordlist-Nouns-Common-Audited-Len-3-6.txt"
    response = urllib2.urlopen(word_site)
    word_list = response.read().splitlines()
    words = []
    for word in word_list:
        if 4 <= len(word) <= 5:
            words.append(word.decode().lower())
    return words


# Get random word list
words = words_list()

# Allow
os.system("echo 'iptables-persistent iptables-persistent/autosave_v4 boolean true' | sudo debconf-set-selections")
os.system("echo 'iptables-persistent iptables-persistent/autosave_v6 boolean true' | sudo debconf-set-selections")
# Install Apt Packages
apt_packages = ['dnsmasq', 'vlan', 'iptables-persistent', 'conntrack', 'python3-pip']

cache = apt.cache.Cache()
cache.update()
cache.open()
for pkg_name in apt_packages:
    pkg = cache[pkg_name]
    if pkg.is_installed:
        print("{pkg_name} already installed".format(pkg_name=pkg_name))
    else:
        pkg.mark_install()
        try:
            cache.commit()
        except Exception as arg:
            print("Sorry, package installation failed [{err}]".format(err=str(arg)))
cache.close()

# Build single subnet map with all vlans, cidrs, etc...
subnets = json.loads(private_subnets)
private_vlans = json.loads(private_vlans)
public_subnets = json.loads(public_subnets)
public_vlans = json.loads(public_vlans)
public_cidrs = json.loads(public_cidrs)

for i in range(0, len(private_vlans)):
    subnets[i]['vlan'] = private_vlans[i]

for i in range(0, len(public_vlans)):
    public_subnets[i]['vlan'] = public_vlans[i]
    public_subnets[i]['cidr'] = public_cidrs[i]
    subnets.append(public_subnets[i])

# Wipe second Network Interface from config file
readFile = open("/etc/network/interfaces")
lines = readFile.readlines()
readFile.close()
for line in reversed(lines):
    if "auto" in line:
        split_line = line.split()
        interface = split_line[-1]
        break
lines = lines[:-5]

# Ensure 8021q and remove the second interface from the bond
os.system("modprobe 8021q")
os.system("ifdown {}".format(interface))

# Make sure 8021q is loaded at startup
modules_file = open("/etc/modules-load.d/modules.conf", "a+")
modules_file.write("\n8021q\n")
modules_file.close()

# Setup syctl parameters for routing
sysctl_file = open("/etc/sysctl.conf", "a+")
sysctl_file.write("\n\n#Routing parameters\n")
sysctl_file.write("net.ipv4.conf.all.rp_filter=0\n")
sysctl_file.write("net.ipv4.conf.default.rp_filter=0\n")
sysctl_file.write("net.ipv4.ip_forward=1\n")
sysctl_file.write("net.ipv4.tcp_mtu_probing=2\n")
sysctl_file.close()

# Apply sysctl parameters
os.system("sysctl -p")

# Remove old conf for second interface
interface_file = open('/etc/network/interfaces', 'w')
for line in lines:
    interface_file.write(line)

# Add new conf for second physical interface
interface_file.write("\nauto {}\n".format(interface))
interface_file.write("iface {} inet manual\n".format(interface))
interface_file.write("\tmtu 9000\n")

# Open dnsmasq config for writing
dnsmasq_conf = open('/etc/dnsmasq.d/dhcp.conf', 'w')

# Loop though all subnets and setup Interfaces, DNSMasq, & IPTables
for subnet in subnets:
    if subnet['routable']:
        # Find vCenter IP
        if subnet['vsphere_service_type'] == 'management':
            vcenter_ip = list(ipaddress.ip_network(subnet['cidr']).hosts())[1].compressed
        # Gather network facts about this subnet
        router_ip = list(ipaddress.ip_network(subnet['cidr']).hosts())[0].compressed
        low_ip = list(ipaddress.ip_network(subnet['cidr']).hosts())[1].compressed
        high_ip = list(ipaddress.ip_network(subnet['cidr']).hosts())[-1].compressed
        netmask = ipaddress.ip_network(subnet['cidr']).netmask.compressed

        # Setup vLan interface for this subnet
        interface_file.write("\nauto {}.{}\n".format(interface, subnet['vlan']))
        interface_file.write("iface {}.{} inet static\n".format(interface, subnet['vlan']))
        interface_file.write("\taddress {}\n".format(router_ip))
        interface_file.write("\tnetmask {}\n".format(netmask))
        interface_file.write("\tvlan-raw-device {}\n".format(interface))
        interface_file.write("\tmtu 9000\n")

        # Generate random name for the network
        word = random.choice(words)
        words.remove(word)

        # Write dnsmasq dhcp scopes
        dnsmasq_conf.write("dhcp-range=set:{},{},{},2h\n".format(word, low_ip, high_ip))
        dnsmasq_conf.write("dhcp-option=tag:{},option:router,{}\n".format(word, router_ip))

        # Create NAT rule for this network if the network is tagged as NAT
        if subnet['nat']:
            os.system("iptables -t nat -A POSTROUTING -o bond0 -j MASQUERADE -s {}".format(subnet['cidr']))

interface_file.close()

# Reserver the vCenter IP
dnsmasq_conf.write("\ndhcp-host=00:00:00:00:00:99, {} # vCenter IP\n".format(vcenter_ip))

dnsmasq_conf.close()

# DNS record for vCenter
etc_hosts = open('/etc/hosts', 'a+')
etc_hosts.write('\n{}\tvcva\tvcva.{}\n'.format(vcenter_ip, domain_name))
etc_hosts.close()

# Add domain to host
resolv_conf = open('/etc/resolv.conf', 'a+')
resolv_conf.write('\ndomain {}\nsearch {}\n'.format(domain_name, domain_name))
resolv_conf.close()

# Block DNSMasq out the WAN
os.system("iptables -I INPUT -p udp --dport 67 -i bond0 -j DROP")
os.system("iptables -I INPUT -p udp --dport 53 -i bond0 -j DROP")
os.system("iptables -I INPUT -p tcp --dport 53 -i bond0 -j DROP")

# Bring up newly configured interfaces
os.system("ifup --all")

# Remove a saftey measure from dnsmasq that blocks VPN users from using DNS
os.system("sed -i 's/ --local-service//g' /etc/init.d/dnsmasq")

# Restart dnsmasq service
os.system("systemctl restart dnsmasq")

# Save iptables rules
os.system("iptables-save > /etc/iptables/rules.v4")

# Install python modules
os.system("pip3 install --upgrade pip pyvmomi packet-python")
