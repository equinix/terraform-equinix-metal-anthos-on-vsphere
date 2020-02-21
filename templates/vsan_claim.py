import json
import ipaddress
import os
import sys
import subprocess
import socket
from pyVmomi import vim, vmodl
from pyVim import connect
import vsanapiutils
from operator import itemgetter, attrgetter
import requests
import ssl


# A large portion of this code was lifted from: https://github.com/storage-code/vsanDeploy/blob/master/vsanDeploy.py


def sizeof_fmt(num, suffix='B'):
   for unit in ['', 'Ki', 'Mi', 'Gi', 'Ti', 'Pi', 'Ei', 'Zi']:
      if abs(num) < 1024.0:
         return "%3.1f%s%s" % (num, unit, suffix)
      num /= 1024.0
   return "%.1f%s%s" % (num, 'Yi', suffix)


def getClusterInstance(clusterName, serviceInstance):
    content = serviceInstance.RetrieveContent()
    searchIndex = content.searchIndex
    datacenters = content.rootFolder.childEntity
    for datacenter in datacenters:
       cluster = searchIndex.FindChild(datacenter.hostFolder, clusterName)
       if cluster is not None:
           return cluster
    return None


def CollectMultiple(content, objects, parameters, handleNotFound=True):
    if len(objects) == 0:
        return {}
    result = None
    pc = content.propertyCollector
    propSet = [vim.PropertySpec(
        type=objects[0].__class__,
        pathSet=parameters
    )]

    while result == None and len(objects) > 0:
        try:
            objectSet = []
            for obj in objects:
                objectSet.append(vim.ObjectSpec(obj=obj))
            specSet = [vim.PropertyFilterSpec(objectSet=objectSet, propSet=propSet)]
            result = pc.RetrieveProperties(specSet=specSet)
        except vim.ManagedObjectNotFound as ex:
            objects.remove(ex.obj)
            result = None

    out = {}
    for x in result:
        out[x.obj] = {}
        for y in x.propSet:
            out[x.obj][y.name] = y.val
    return out


# Terraform Vars
vcenter_fqdn = '${vcenter_fqdn}'
vcenter_user = '${vcenter_user}'
vcenter_pass = '${vcenter_pass}'


# Workaround for SSL verification for vSan API
requests.packages.urllib3.disable_warnings()
ssl._create_default_https_context = ssl._create_unverified_context
context = ssl.create_default_context()
context.check_hostname = False
context.verify_mode = ssl.CERT_NONE


si = connect.SmartConnectNoSSL(host=vcenter_fqdn, user=vcenter_user, pwd=vcenter_pass, port=443)
cluster = getClusterInstance('Packet-1', si)
vcMos = vsanapiutils.GetVsanVcMos(si._stub, context=context)
vsanClusterSystem = vcMos['vsan-cluster-config-system']
vsanVcDiskManagementSystem = vcMos['vsan-disk-management-system']
hostProps = CollectMultiple(si.content, cluster.host, ['name', 'configManager.vsanSystem', 'configManager.storageSystem'])
hosts = hostProps.keys()

diskmap = {host: {'cache':[],'capacity':[]} for host in hosts}
cacheDisks = []
capacityDisks = []

for host in hosts:
    ssds = [result.disk for result in hostProps[host]['configManager.vsanSystem'].QueryDisksForVsan() if
        result.state == 'eligible' and result.disk.ssd]
    smallerSize = min([disk.capacity.block * disk.capacity.blockSize for disk in ssds])
    for ssd in ssds:
        size = ssd.capacity.block * ssd.capacity.blockSize
        if size == smallerSize:
            diskmap[host]['cache'].append(ssd)
            cacheDisks.append((ssd.displayName, sizeof_fmt(size), hostProps[host]['name']))
        else:
            diskmap[host]['capacity'].append(ssd)
            capacityDisks.append((ssd.displayName, sizeof_fmt(size), hostProps[host]['name']))

tasks = []
for host,disks in diskmap.items():
    if len(disks['cache']) > len(disks['capacity']):
        disks['cache'] = disks['cache'][:len(disks['capacity'])]

    dm = vim.VimVsanHostDiskMappingCreationSpec(
             cacheDisks=disks['cache'],
             capacityDisks=disks['capacity'],
             creationType='allFlash',
             host=host
         )

    task = vsanVcDiskManagementSystem.InitializeDiskMappings(dm)
    tasks.append(task)

