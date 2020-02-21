import optparse
import sys
from time import sleep
from pyVmomi import vim, vmodl
from pyVim import connect


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
            return None
    print("Connected to ESX Host !")
    content = si.RetrieveContent()
    host = content.viewManager.CreateContainerView(content.rootFolder, [vim.HostSystem], True).view[0]
    return host


def main():
    parser = optparse.OptionParser(usage="%prog --host <host_ip> --user <username> --pass <password> "
                                   "--vswitch <vswitch_name> --active-uplinks <comma_list_uplink_names> "
                                   "--backup-uplinks <comma_list_uplink_names>")
    parser.add_option('--host', dest="host", action="store", help="IP or FQDN of the ESXi host")
    parser.add_option('--user', dest="user", action="store", help="Username to authenticate to ESXi host")
    parser.add_option('--pass', dest="pw", action="store", help="Password to authenticarte to ESXi host")
    parser.add_option('--vswitch', dest="vswitch", action="store", help="vSwitch name to be modified")
    parser.add_option('--active-uplinks', dest="active_uplinks", action="store", help="A comma seperated sting of active "
                                                                                      "uplinks to be added to the vSwitch")
    parser.add_option('--backup-uplinks', dest="backup_uplinks", action="store", help="A comma seperated sting of backup "
                                                                                      "uplinks to be added to the vSwitch")

    options, _ = parser.parse_args()
    if not (options.host and options.user and options.pw and options.vswitch and options.active_uplinks):
        print("ERROR: Missing arguments")
        parser.print_usage()
        sys.exit(1)

    host = connect_to_host(options.host, options.user, options.pw)
    host_network_system = host.configManager.networkSystem
    for vswitch in host_network_system.networkInfo.vswitch:
        if vswitch.name == options.vswitch:
            vss_spec = vswitch.spec
            print("Found correct vSwitch.")
            break
    if vss_spec is None:
        print("Couldn't find the correct vSwitch.")
    active_uplinks = options.active_uplinks.split(',')
    backup_uplinks = options.backup_uplinks.split(',')
    all_uplinks = active_uplinks + backup_uplinks
    vss_spec.bridge = vim.host.VirtualSwitch.BondBridge(nicDevice=all_uplinks)
    vss_spec.policy.nicTeaming.nicOrder.activeNic = active_uplinks
    vss_spec.policy.nicTeaming.nicOrder.standbyNic = backup_uplinks
    host_network_system.UpdateVirtualSwitch(vswitchName=options.vswitch, spec=vss_spec)


if __name__ == "__main__":
    main()
