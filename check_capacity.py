#import packet
import os
import subprocess
import requests
import json

##Capture default variables
# TODO: create a def to processes these
facility = subprocess.check_output("cat 00-vars.tf | awk '/facility/ { getline; print $3}'", shell=True, universal_newlines=True).strip().strip('"')
router_size = subprocess.check_output("cat 00-vars.tf | awk '/router_size/ { getline; print $3}'", shell=True, universal_newlines=True).strip().strip('"')
esxi_size =  subprocess.check_output("cat 00-vars.tf | awk '/esxi_size/ { getline; print $3}'", shell=True, universal_newlines=True).strip().strip('"')
esxi_host_count = subprocess.check_output("cat 00-vars.tf | awk '/esxi_host_count/ { getline; print $3}'", shell=True, universal_newlines=True).strip().strip('"')



##Check to see if the user has set different variables
# TODO: cerate a def to process these
with open("terraform.tfvars") as f:
  if 'facility' in f.read():
    facility = subprocess.check_output("cat terraform.tfvars | awk '/facility/ { print $3}'", shell=True, universal_newlines=True).strip().strip('"')
    print ("Using the user variable for facility")
  else:
    print ("Using the default value for facility")
  print (facility)
with open("terraform.tfvars") as f:
  if 'router_size' in f.read():
    router_size = subprocess.check_output("cat terraform.tfvars | awk '/router_size/ { print $3}'", shell=True, universal_newlines=True).strip().strip('"')
    print ("Using the user variabe for router size") 
  else:
    print ("Using the default value for router size")
  print (router_size)
with open("terraform.tfvars") as f:
  if 'esxi_size' in f.read():
    esxi_size = subprocess.check_output("cat terraform.tfvars | awk '/esxi_size/ { print $3}'", shell=True, universal_newlines=True).strip().strip('"')
    print ("Using the user variable for esxi size")
  else:
    print ("Using the default value for esxi size")
  print (esxi_size)
with open("terraform.tfvars") as f:
  if 'esxi_host_count' in f.read():
    esxi_host_count = subprocess.check_output("cat terraform.tfvars | awk '/esxi_host_count/ { print $3}'", shell=True, universal_newlines=True).strip().strip('"')
    print ("Using the user variable for esxi host count")
  else:
    print ("Using the default for esxi host count")
  print (esxi_host_count)



#capture packet token
packet_token = subprocess.check_output("cat terraform.tfvars | awk '/auth_token/ { print $3}'", shell=True, universal_newlines=True).strip().strip('"')

servers=[(facility, router_size, 1), (facility, esxi_size, esxi_host_count)]


##code to use the packet python should the method get fixed
#manager = packet.Manager(auth_token=packet_token)
#print ( manager.validate_capacity(servers))


## Using requests to validate capacity
servers_json = {"servers":[]} 
for server in servers: 
  servers_json["servers"].append( {"facility": server[0], "plan": server[1], "quantity": server[2]} )


url= "https://api.packet.net/capacity"
header= {"X-Auth-Token": packet_token}
r = requests.post(url, headers=header, json=servers_json)


##Print the results
# TDOO: color code the outputs
print ("Is there 1 " + router_size + " instance available for the router in " + facility + "?")
if (r.json()['servers'][0]['available']):
  print ("Yes")
else:
  print ("No, select another facility or router size.")

print ("Is there " + esxi_host_count + " " + esxi_size + " instance(s) available for ESXi in " + facility + "?")
if (r.json()['servers'][1]['available']):
  print ("Yes")
else:
  print ("No, select another facility, ESXi size, or number of ESXi hosts.")


