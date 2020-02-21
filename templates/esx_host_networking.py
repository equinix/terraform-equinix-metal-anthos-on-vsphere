import json
import ipaddress
import packet
import optparse
import sys
from time import sleep
from pyVmomi import vim, vmodl
from pyVim import connect
from subprocess import Popen


# Vars from Terraform
private_subnets = '${private_subnets}'
private_vlans = '${private_vlans}'
public_subnets = '${public_subnets}'
public_vlans = '${public_vlans}'
public_cidrs = '${public_cidrs}'
domain_name = '${domain_name}'
packet_token = '${packet_token}'

# Constants
vswitch_name = 'vSwitch1'
del_vswitch_name = 'vSwitch0'

# Build single subnet map with all vlans, cidrs, etc...
subnets = json.loads(private_subnets)
private_vlans = json.loads(private_vlans)
public_subnets = json.loads(public_subnets)
public_vlans = json.loads(public_vlans)
public_cidrs = json.loads(public_cidrs)

for i in range(len(private_vlans)):
    subnets[i]['vlan'] = private_vlans[i]

for i in range(len(public_vlans)):
    public_subnets[i]['vlan'] = public_vlans[i]
    public_subnets[i]['cidr'] = public_cidrs[i]
    subnets.append(public_subnets[i])


def create_vswitch(host_network_system, vss_name, num_ports, nic_name, mtu):
    vss_spec = vim.host.VirtualSwitch.Specification()
    vss_spec.numPorts = num_ports
    vss_spec.mtu = mtu
    vss_spec.bridge = vim.host.VirtualSwitch.BondBridge(nicDevice=[nic_name])

    host_network_system.AddVirtualSwitch(vswitchName=vss_name, spec=vss_spec)

    print("Successfully created vSwitch ",  vss_name)


def create_port_group(host_network_system, pg_name, vss_name, vlan_id):
    port_group_spec = vim.host.PortGroup.Specification()
    port_group_spec.name = pg_name
    port_group_spec.vlanId = vlan_id
    port_group_spec.vswitchName = vss_name

    security_policy = vim.host.NetworkPolicy.SecurityPolicy()
    security_policy.allowPromiscuous = True
    security_policy.forgedTransmits = True
    security_policy.macChanges = True

    port_group_spec.policy = vim.host.NetworkPolicy(security=security_policy)

    host_network_system.AddPortGroup(portgrp=port_group_spec)

    print("Successfully created PortGroup ",  pg_name)


def add_virtual_nic(host, host_network_system, pg_name, network_type, ip_address, subnet_mask, default_gateway,
                    dns_servers, domain_name, mtu):
    vnic_config = vim.host.VirtualNic.Specification()
    ip_spec = vim.host.IpConfig()
    if network_type == 'dhcp':
        ip_spec.dhcp = True
    else:
        ip_spec.dhcp = False
        ip_spec.ipAddress = ip_address
        ip_spec.subnetMask = subnet_mask
        if default_gateway:
            vnic_config.ipRouteSpec = vim.host.VirtualNic.IpRouteSpec()
            vnic_config.ipRouteSpec.ipRouteConfig = vim.host.IpRouteConfig()
            vnic_config.ipRouteSpec.ipRouteConfig.defaultGateway = default_gateway
            routespec = vim.host.IpRouteConfig()
            routespec.defaultGateway = default_gateway
            dns_config = host.configManager.networkSystem.dnsConfig
            if len(dns_servers) > 0:
                dns_config.dhcp = False
                dns_config.address = dns_servers
                if domain_name:
                    dns_config.domainName = domain_name
                    dns_config.searchDomain = domain_name

        else:
            vnic_config.ipRouteSpec = vim.host.VirtualNic.IpRouteSpec()
            vnic_config.ipRouteSpec.ipRouteConfig = vim.host.IpRouteConfig()

    vnic_config.ip = ip_spec
    vnic_config.mtu = mtu
    virtual_nic = host_network_system.AddVirtualNic(portgroup=pg_name, nic=vnic_config)
    if default_gateway:
        host.configManager.networkSystem.UpdateIpRouteConfig(config=routespec)
        host.configManager.networkSystem.UpdateDnsConfig(config=dns_config)

    return(virtual_nic)


def enable_service_on_virtual_nic(host, virtual_nic, service_type):
    if service_type == 'vsan':
        vsan_port = vim.vsan.host.ConfigInfo.NetworkInfo.PortConfig(device=virtual_nic)
        net_info = vim.vsan.host.ConfigInfo.NetworkInfo(port=[vsan_port])
        vsan_config = vim.vsan.host.ConfigInfo(networkInfo=net_info,)
        vsan_system = host.configManager.vsanSystem
        try:
            vsan_task = vsan_system.UpdateVsan_Task(vsan_config)
        except Exception as e:
            print("Failed to set service type to vsan: {}".format(str(e)))
    else:
        host.configManager.virtualNicManager.SelectVnicForNicType(service_type, virtual_nic)


def connect_to_host(esx_host, esx_user, esx_pass):
    for i in range(1, 30):
        si = None
        try:
            print("Trying to connect to ESX Host . . .")
            si = connect.SmartConnectNoSSL(host=esx_host, user=esx_user, pwd=esx_pass, port=443)
            break
        except Exception:
            print("There was a connection Error to host: {}. Sleeping 10 seconds and trying again.".format(esx_host))
            sleep(10)
        if i == 30:
            return None, None
    print("Connected to ESX Host !")
    content = si.RetrieveContent()
    host = content.viewManager.CreateContainerView(content.rootFolder, [vim.HostSystem], True).view[0]
    return host, si


def main():
    parser = optparse.OptionParser(usage="%prog --host <host_ip> --user <username> --pass <password> "
                                   "--vswitch <vswitch_name> --uplinks <comma_list_uplink_names>")
    parser.add_option('--host', dest="host", action="store", help="IP or FQDN of the ESXi host")
    parser.add_option('--user', dest="user", action="store", help="Username to authenticate to ESXi host")
    parser.add_option('--pass', dest="pw", action="store", help="Password to authenticarte to ESXi host")
    parser.add_option('--id', dest="id", action="store", help="Packet Device ID for Server")
    parser.add_option('--index', dest="index", action="store", help="Terraform index count, used for IPing")

    options, _ = parser.parse_args()
    if not (options.host and options.user and options.pw and options.id and options.index):
        print("ERROR: Missing arguments")
        parser.print_usage()
        sys.exit(1)
    print(options)

    host, si = connect_to_host(options.host, options.user, options.pw)
    if si is None or host is None:
        print("Couldn't connect to host: {} after 5 minutes. Skipping...".format(options.host))
        sys.exit(1)

    host_name = host.name
    host_network_system = host.configManager.networkSystem
    online_pnics = []

    for pnic in host.config.network.pnic:
        if pnic.linkSpeed:
            online_pnics.append(pnic)

    for vswitch in host_network_system.networkInfo.vswitch:
        for pnic in vswitch.pnic:
            for n in range(len(online_pnics)):
                if pnic == online_pnics[n].key:
                    del online_pnics[n]
                    break

    uplink = online_pnics[0].device
    create_vswitch(host_network_system, vswitch_name, 1024, uplink, 9000)
    for subnet in subnets:
        create_port_group(host_network_system, subnet['name'], vswitch_name, subnet['vlan'])
        if subnet['vsphere_service_type']:
            ip_address = list(ipaddress.ip_network(subnet['cidr']).hosts())[int(options.index) + 3].compressed
            subnet_mask = ipaddress.ip_network(subnet['cidr']).netmask.compressed
            default_gateway = None
            mtu = 9000
            if subnet['vsphere_service_type'] == 'management':
                create_port_group(host_network_system, "{} Net".format(subnet['name']), vswitch_name, subnet['vlan'])
                default_gateway = list(ipaddress.ip_network(subnet['cidr']).hosts())[0].compressed
                dns_servers = []
                dns_servers.append(default_gateway)
                dns_servers.append('8.8.8.8')
                mtu = 1500
                new_ip = ip_address

                # Reserve IP in dnsmasq
                dnsmasq_conf = open('/etc/dnsmasq.d/dhcp.conf', 'a+')
                dnsmasq_conf.write("dhcp-host=00:00:00:00:00:0{}, {} # {} IP\n".format(int(options.index),
                                                                                       ip_address,
                                                                                       host_name))
                dnsmasq_conf.close()

                # DNS record for ESX_Host
                etc_hosts = open('/etc/hosts', 'a+')
                etc_hosts.write('{}\t{}\t{}.{}\n'.format(ip_address, host_name, host_name, domain_name))
                etc_hosts.close()
                # Restart dnsmasq service
                Popen(["systemctl restart dnsmasq"], shell=True, stdin=None, stdout=None, stderr=None, close_fds=True)
            virtual_nic = add_virtual_nic(host, host_network_system, subnet['name'], 'static', ip_address,
                                          subnet_mask, default_gateway, dns_servers, domain_name, mtu)
            enable_service_on_virtual_nic(host, virtual_nic, subnet['vsphere_service_type'])
    connect.Disconnect(si)

    host = None
    si = None
    host, si = connect_to_host(new_ip, options.user, options.pw)
    if si is None or host is None:
        print("Couldn't connect to host: {}".format(new_ip))
        sys.exit(1)

    host_network_system = host.configManager.networkSystem
    active_uplinks = []
    backup_uplinks = []
    for vnic in host_network_system.networkInfo.vnic:
        if vnic.spec.ip.ipAddress == options.host or vnic.spec.ip.ipAddress[:3] == '10.':
            print("Removing vNic: {}".format(vnic.device))
            host_network_system.RemoveVirtualNic(vnic.device)
    for vswitch in host_network_system.networkInfo.vswitch:
        if vswitch.name == del_vswitch_name:
            for uplink in vswitch.spec.bridge.nicDevice:
                active_uplinks.append(uplink)
            for pgroup in vswitch.portgroup:
                print("Removing Port Group: {}".format(pgroup[23:]))
                host_network_system.RemovePortGroup(pgroup[23:])
        if vswitch.name == vswitch_name:
            vss_spec = vswitch.spec
            for uplink in vss_spec.bridge.nicDevice:
                backup_uplinks.append(uplink)

    print("Removing vSwitch: {}".format(del_vswitch_name))
    host_network_system.RemoveVirtualSwitch(del_vswitch_name)
    #vss_spec.bridge = vim.host.VirtualSwitch.BondBridge(nicDevice=new_uplinks)
    #vss_spec.policy.nicTeaming.nicOrder.activeNic = new_uplinks

    print("Updating vSwitch Uplinks...")
    str_active_uplinks = ",".join(map(str, active_uplinks))
    str_backup_uplinks = ",".join(map(str, backup_uplinks))
    cmd_str = "python3 /root/update_uplinks.py --host '{}' --user '{}' --pass '{}' --vswitch '{}' --active-uplinks '{}' --backup-uplinks '{}'".format(
                                            new_ip, options.user, options.pw, vswitch_name, str_active_uplinks, str_backup_uplinks)
    Popen([cmd_str], shell=True, stdin=None, stdout=None, stderr=None, close_fds=True)

    # Get Packet Deivce
    manager = packet.Manager(auth_token=packet_token)
    device = manager.get_device(options.id)
    for port in device.network_ports:
        if port['type'] == 'NetworkBondPort':
            print("Found {} port id".format(port['name']))
            bond_port = port['id']
        elif port['type'] == 'NetworkPort' and not port['data']['bonded']:
            print("Found {} port id".format(port['name']))
            unbonded_port = port['id']
        else:
            print("Found {} port id, but...".format(port['name']))
            print("This is not the port you're looking for...")

    for subnet in subnets:
        print("Removing vLan {} from unbonded port".format(subnet['vlan']))
        attempt = 0
        for attempt in range(1,5):
            try:
                manager.remove_port(unbonded_port, subnet['vlan'])
                break
            except Exception:
                if attempt == 5:
                    print("Tried to remove vLan five times and failed. Exiting...")
                    sys.exit(1)
                print("Failed to remove vlan, trying again...")
                sleep(5)
    print("Rebonding Ports...")
    attempt = 0
    for attempt in range(1,5):
        try:
            manager.bond_ports(bond_port, True)
            break
        except Exception:
            if attempt == 5:
                print("Tried to bond ports five times and failed. Exiting...")
                sys.exit(1)
            print("Failed to bond ports, trying again...")
            sleep(5)
    for n in range(len(subnets)):
        if n == 0:
            print("Adding vLan {} to bond".format(subnets[n]['vlan']))
            attempt = 0
            for attempt in range(1,5):
                try:
                    manager.convert_layer_2(bond_port, subnets[n]['vlan'])
                    break
                except Exception:
                    if attempt == 5:
                        print("Tried to convert bond to Layer 2 five times and failed. Exiting...")
                        sys.exit(1)
                    print("Failed to convert bond to Layer 2, trying again...")
                    sleep(5)
        else:
            print("Adding vLan {} to bond".format(subnets[n]['vlan']))
            attempt = 0
            for attempt in range(1,5):
                try:
                    manager.assign_port(bond_port, subnets[n]['vlan'])
                    break
                except Exception:
                    if attempt == 5:
                        print("Tried to add vLan to bond five times and failed. Exiting...")
                        sys.exit(1)
                    print("Failed to add vLan to bond, trying again...")
                    sleep(5)


# Start program
if __name__ == "__main__":
    main()
